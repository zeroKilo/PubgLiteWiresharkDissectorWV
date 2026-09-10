local actorHandler={}
local registry=require 'actors/relite_actor_handler_registry'
local loadedHandlers={}

local function state(relite) return relite.getConnectionState(relite.currentConnectionKey) end
local function isDynamicGuid(g) return g~=nil and g>0 and (g%2)==0 end

local function resolveHandlerName(relite,name)
	if not name then return nil end
	if registry.paths[name] then
		local c=relite.netDefines.getClass(name); return c and c.name or relite.netDefines.resolveClassName(name)
	end
	local alias=registry.aliases[name]
	if alias then return alias end
	return relite.netDefines.resolveClassName(name)
end

function actorHandler.getActorHandler(relite,name)
	local cname=resolveHandlerName(relite,name)
	if not cname then return nil,nil end
	if loadedHandlers[cname]~=nil then return loadedHandlers[cname] or nil,cname end
	local moduleName=registry.classes[cname]
	if not moduleName then loadedHandlers[cname]=false; return nil,cname end
	local ok,handler=pcall(require,moduleName)
	if not ok then loadedHandlers[cname]=false; return nil,cname,tostring(handler) end
	loadedHandlers[cname]=handler
	return handler,cname
end

function actorHandler.resolveGuid(relite,guid)
	if not guid or guid==0 then return nil end
	local e=state(relite).guidCache[guid]
	return e and (e.FullPath or e.Path) or nil
end

local function cacheGuid(relite,e)
	if not e or not e.Guid or e.Guid==0 then return end
	local st=state(relite)
	local outer=e.OuterGuid and actorHandler.resolveGuid(relite,e.OuterGuid) or nil
	if e.Path and e.Path~='' then
		if outer and outer~='' then e.FullPath=outer..'.'..e.Path else e.FullPath=e.Path end
	end
	st.guidCache[e.Guid]=e
end

function actorHandler.readNetGuid(relite,stream,exportContext)
	local utils=relite.utils
	local result={Guid=utils.readintpacked(stream)}
	if result.Guid==0 or stream:isError() then return result end
	if exportContext or result.Guid==1 then
		result.ExportFlags=stream:readBits(8)
		result.HasPath=(result.ExportFlags%2)~=0
		result.NoLoad=(math.floor(result.ExportFlags/2)%2)~=0
		result.HasChecksum=(math.floor(result.ExportFlags/4)%2)~=0
	else
		result.HasPath=false; result.NoLoad=false; result.HasChecksum=false
	end
	if result.HasPath then
		result.Child=actorHandler.readNetGuid(relite,stream,exportContext)
		result.OuterGuid=result.Child and result.Child.Guid or 0
		result.Path=utils.readstring(stream)
		if result.HasChecksum then result.Checksum=stream:readBits(32) end
	end
	cacheGuid(relite,result)
	return result
end

local function readNetFieldExport(relite,stream)
	local utils=relite.utils
	local e={IsExported=stream:readBool()}
	if not e.IsExported or stream:isError() then return e end
	e.Handle=utils.readintpacked(stream)
	e.CompatibleChecksum=utils.readUInt32(stream)
	e.Name=utils.readstring(stream)
	e.Type=utils.readstring(stream)
	return e
end

local function readNetFieldExportsCompat(relite,payload,stream)
	local utils=relite.utils; local st=state(relite)
	local count=utils.readUInt32(stream)
	payload.NumNetFieldExports=count
	payload.NetFieldExports={}
	if count>65536 then
		payload.PackageMapExportError='Invalid NetField export count: '..tostring(count)
		stream.error=true; return
	end
	for _=1,count do
		local item={}
		item.PathNameIndex=utils.readintpacked(stream)
		item.IsNewGroup=stream:readBool()
		local group=st.netFieldExportGroupsByIndex[item.PathNameIndex]
		if item.IsNewGroup then
			item.PathName=utils.readstring(stream)
			item.NumExports=utils.readUInt32(stream)
			if item.NumExports>65536 then
				item.Error='Invalid NetField group size: '..tostring(item.NumExports)
				stream.error=true
			else
				group={PathName=item.PathName,PathNameIndex=item.PathNameIndex,NumExports=item.NumExports,Fields={}}
				st.netFieldExportGroupsByIndex[item.PathNameIndex]=group
				if item.PathName and item.PathName~='' then st.netFieldExportGroupsByPath[item.PathName]=group end
			end
		elseif not group then item.Error='NetField export references unknown group index '..tostring(item.PathNameIndex) end
		if not stream:isError() then
			item.Field=readNetFieldExport(relite,stream)
			if group and item.Field and item.Field.IsExported and item.Field.Handle~=nil then
				if item.Field.Handle>=group.NumExports then item.Error='NetField handle exceeds declared group size'
				else group.Fields[item.Field.Handle]=item.Field end
			end
		end
		payload.NetFieldExports[#payload.NetFieldExports+1]=item
		if stream:isError() then break end
	end
end

function actorHandler.readExports(relite,payload,stream)
	payload.PackageMapExports={}
	payload.SetupHasRepLayoutExport=stream:readBool()
	if payload.SetupHasRepLayoutExport then
		payload.PackageMapExportType='NetFieldExportsCompat'
		readNetFieldExportsCompat(relite,payload,stream)
		return
	end
	local count=relite.utils.readInt32(stream)
	payload.NumGuidsExport=count
	if count<0 or count>2048 then
		payload.PackageMapExportError='Invalid NetGUID export count: '..tostring(count)
		stream.error=true
		return
	end
	for _=1,count do
		local e=actorHandler.readNetGuid(relite,stream,true)
		payload.PackageMapExports[#payload.PackageMapExports+1]=e
		if stream:isError() then break end
	end
	payload.ExportedNetGUIDs=payload.PackageMapExports
end

function actorHandler.readMustGuids(relite,payload,stream,channelInfo)
	local count=stream:readBits(16)
	payload.NumGuidsMapped=count
	payload.MustBeMappedGUIDs={}
	for _=1,count do
		local guid=relite.utils.readintpacked(stream)
		payload.MustBeMappedGUIDs[#payload.MustBeMappedGUIDs+1]=guid
		if channelInfo then channelInfo.MustBeMappedGUIDs[#channelInfo.MustBeMappedGUIDs+1]=guid end
		if stream:isError() then break end
	end
end

function actorHandler.serializeNewActor(relite,payload,stream,channelInfo)
	local utils=relite.utils
	local actor={}
	actor.ActorNetGuid=utils.readintpacked(stream)
	actor.ActorPath=actorHandler.resolveGuid(relite,actor.ActorNetGuid)
	if isDynamicGuid(actor.ActorNetGuid) then
		actor.ArchetypeNetGuid=utils.readintpacked(stream)
		actor.ArchetypePath=actorHandler.resolveGuid(relite,actor.ArchetypeNetGuid)
		actor.SerializeLocation=stream:readBool()
		if actor.SerializeLocation then actor.Location=utils.readPackedVector(stream,10,24) end
		actor.SerializeRotation=stream:readBool()
		if actor.SerializeRotation then actor.Rotation=utils.readRotator(stream) end
		actor.SerializeScale=stream:readBool()
		if actor.SerializeScale then actor.Scale=utils.readPackedVector(stream,10,24) end
		actor.SerializeVelocity=stream:readBool()
		if actor.SerializeVelocity then actor.Velocity=utils.readPackedVector(stream,10,24) end
	end
	local objectName=actor.ArchetypePath or actor.ActorPath or channelInfo.ChannelObjectName
	if objectName then channelInfo.ChannelObjectName=objectName end
	channelInfo.ActorNetGuid=actor.ActorNetGuid
	channelInfo.ArchetypeNetGuid=actor.ArchetypeNetGuid
	payload.NewActor=actor
	payload.ChannelObjectName=channelInfo.ChannelObjectName

	local handler,resolved,loadError=actorHandler.getActorHandler(relite,channelInfo.ChannelObjectName)
	payload.ResolvedClassName=resolved
	channelInfo.ResolvedClassName=resolved
	if loadError then payload.GameActorSetupError='Actor handler load failed for '..tostring(resolved)..': '..loadError end
	if handler and handler.serializeNewActor and stream:bitsLeft()>0 then
		local probe=stream:clone()
		local ok,data=pcall(handler.serializeNewActor,relite,probe,{ChannelInfo=channelInfo,NewActor=actor})
		if ok and not probe:isError() then
			stream.pos=probe.pos
			payload.ActorSpecificSetup=data or {}
			for k,v in pairs(data or {}) do payload[k]=v end
		elseif not ok then payload.GameActorSetupError=tostring(data) end
	end
	return actor
end

function actorHandler.processActorPacket(relite,payload,stream,bunchHeader)
	local st=state(relite)
	local idx=bunchHeader.channelIndex
	local channelInfo=st.channels[idx]
	if bunchHeader.isOpen or not channelInfo then
		channelInfo={SetupDone=false,MustBeMappedGUIDs={},ChannelObjectName=nil,ResolvedClassName=nil}
		st.channels[idx]=channelInfo
		payload.MakeSetup=true
	else payload.MakeSetup=false end
	channelInfo.IsServerSource=bunchHeader.isServerSource
	payload.ChannelObjectName=channelInfo.ChannelObjectName
	payload.ResolvedClassName=channelInfo.ResolvedClassName

	if bunchHeader.hasMustBeMappedGUIDs then actorHandler.readMustGuids(relite,payload,stream,channelInfo) end
	if payload.MakeSetup and stream:bitsLeft()>0 and not stream:isError() then
		actorHandler.serializeNewActor(relite,payload,stream,channelInfo)
		channelInfo.SetupDone=not stream:isError()
	end
	payload.ChannelObjectName=channelInfo.ChannelObjectName
	payload.ResolvedClassName=channelInfo.ResolvedClassName or relite.netDefines.resolveClassName(channelInfo.ChannelObjectName)
	channelInfo.ResolvedClassName=payload.ResolvedClassName
	if stream:bitsLeft()>1 and not stream:isError() then relite.utils.readContentBlocks(relite,payload,stream,channelInfo) end
	if stream:isError() then payload.ParseError='Actor payload ended while decoding' end
	payload.RemainingBits=stream:bitsLeft()
	if payload.RemainingBits>0 then payload.RemainingRaw=relite.utils.streamHex(stream) end
	if bunchHeader.isClosed then channelInfo.Closed=true; st.channels[idx]=nil end
end

return actorHandler

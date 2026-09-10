local actorMaker={}
local registry=require 'actors/relite_actor_maker_registry'
local loadedMakers={}

local function addError(fields,r,root,msg) if msg then root:add_le(fields.ParseError,r,tostring(msg)) end end
local function vec(v) if not v then return nil end return string.format('X=%g Y=%g Z=%g',v.X or 0,v.Y or 0,v.Z or 0) end
local function rot(v) if not v then return nil end return string.format('Pitch=%g Yaw=%g Roll=%g',v.Pitch or 0,v.Yaw or 0,v.Roll or 0) end

function actorMaker.getActorMaker(relite,name)
	local cname=relite.netDefines.resolveClassName(name)
	if not cname and registry.aliases[name] then cname=registry.aliases[name] end
	if not cname then return nil,nil end
	if loadedMakers[cname]~=nil then return loadedMakers[cname] or nil,cname end
	local moduleName=registry.classes[cname]
	if not moduleName then loadedMakers[cname]=false; return nil,cname end
	local ok,maker=pcall(require,moduleName)
	if not ok then loadedMakers[cname]=false; return nil,cname,tostring(maker) end
	loadedMakers[cname]=maker
	return maker,cname
end

function actorMaker.makeNetGuid(relite,r,root,e)
	if not e then return end
	local f=relite.const.FIELDS
	local n=root:add_le(f.NetGUID,r)
	n:add_le(f.GUID,r,e.Guid or 0)
	if (e.Guid or 0)==0 then return end
	if e.HasPath~=nil then n:add_le(f.NetGUIDHasPath,r,e.HasPath) end
	if e.NoLoad~=nil then n:add_le(f.NetGUIDNoLoad,r,e.NoLoad) end
	if e.HasChecksum~=nil then n:add_le(f.NetGUIDHasNetworkChecksum,r,e.HasChecksum) end
	if e.Child then actorMaker.makeNetGuid(relite,r,n,e.Child) end
	if e.Path then n:add_le(f.NetGUIDPath,r,e.Path) end
	if e.FullPath then n:add_le(f.NetGUIDResolvedPath,r,e.FullPath) end
	if e.Checksum then n:add_le(f.NetGUIDChecksum,r,e.Checksum) end
end

local function makeExports(relite,r,payload,root)
	local f=relite.const.FIELDS
	if payload.SetupHasRepLayoutExport~=nil then root:add_le(f.ActSetupHasRepLayoutExport,r,payload.SetupHasRepLayoutExport) end
	if payload.PackageMapExportRaw then root:add_le(f.PackageMapExportRaw,r,payload.PackageMapExportRaw) end
	if payload.NumNetFieldExports then
		local exports=root:add_le(f.NetFieldExportCount,r,payload.NumNetFieldExports)
		for _,item in ipairs(payload.NetFieldExports or {}) do
			local label=item.PathName or ('Group '..tostring(item.PathNameIndex or '?'))
			local n=exports:add_le(f.NetFieldExportGroup,r,label)
			n:add_le(f.NetFieldExportPathIndex,r,item.PathNameIndex or 0)
			n:add_le(f.NetFieldExportIsNewGroup,r,item.IsNewGroup or false)
			if item.PathName then n:add_le(f.NetFieldExportPath,r,item.PathName) end
			if item.NumExports then n:add_le(f.NetFieldExportNumExports,r,item.NumExports) end
			local e=item.Field
			if e then
				n:add_le(f.NetFieldExportIsExported,r,e.IsExported or false)
				if e.Handle~=nil then n:add_le(f.NetFieldExportHandle,r,e.Handle) end
				if e.CompatibleChecksum~=nil then n:add_le(f.NetFieldExportChecksum,r,e.CompatibleChecksum) end
				if e.Name then n:add_le(f.NetFieldExportName,r,e.Name) end
				if e.Type then n:add_le(f.NetFieldExportType,r,e.Type) end
			end
			addError(f,r,n,item.Error)
		end
	end
	if payload.NumGuidsExport then
		local n=root:add_le(f.ActSetupExportNetGUIDsCount,r,payload.NumGuidsExport)
		for _,e in ipairs(payload.PackageMapExports or {}) do actorMaker.makeNetGuid(relite,r,n,e) end
	end
	addError(f,r,root,payload.PackageMapExportError)
end

function actorMaker.makeRecoveredNewActor(relite,r,payload,root,className)
	local f=relite.const.FIELDS
	if className=='STExtraPlayerController' then
		if payload.NetPlayerVersion then root:add_le(f.STEPlayerControllerNetPlayerVersion,r,payload.NetPlayerVersion) end
		if payload.NetPlayerIndex~=nil then root:add_le(f.STEPlayerControllerNetPlayerIndex,r,payload.NetPlayerIndex) end
	end
end

local function makeActorIdentity(relite,r,payload,root)
	local f=relite.const.FIELDS; local a=payload.NewActor
	if not a then return end
	local label=payload.ChannelObjectName or a.ArchetypePath or a.ActorPath or 'Actor'
	local n=root:add_le(f.Actor,r,label)
	n:add_le(f.ActorNetGuid,r,a.ActorNetGuid or 0)
	if a.ArchetypeNetGuid then n:add_le(f.ActorArchetypeGuid,r,a.ArchetypeNetGuid) end
	if payload.ResolvedClassName then n:add_le(f.ActorResolvedClass,r,payload.ResolvedClassName) end
	if a.ActorPath then n:add_le(f.NetGUIDResolvedPath,r,a.ActorPath) end
	if a.ArchetypePath then n:add_le(f.ChannelObject,r,a.ArchetypePath) end
	if a.SerializeLocation~=nil then n:add_le(f.ActorSerializeLocation,r,a.SerializeLocation) end
	if a.SerializeRotation~=nil then n:add_le(f.ActorSerializeRotation,r,a.SerializeRotation) end
	if a.SerializeScale~=nil then n:add_le(f.ActorSerializeScale,r,a.SerializeScale) end
	if a.SerializeVelocity~=nil then n:add_le(f.ActorSerializeVelocity,r,a.SerializeVelocity) end
	if a.Location then n:add_le(f.ActorLocation,r,vec(a.Location)) end
	if a.Rotation then n:add_le(f.ActorRotation,r,rot(a.Rotation)) end
	if a.Scale then n:add_le(f.ActorScale,r,vec(a.Scale)) end
	if a.Velocity then n:add_le(f.ActorVelocity,r,vec(a.Velocity)) end
	local maker,cname,loadError=actorMaker.getActorMaker(relite,payload.ResolvedClassName or payload.ChannelObjectName)
	if cname then n:add_le(f.ActorHandlerClass,r,cname) end
	if loadError then addError(f,r,n,'Actor tree-maker load failed: '..loadError) end
	if maker and maker.makeNewActor then
		local ok,err=pcall(maker.makeNewActor,relite,r,payload,n)
		if not ok then addError(f,r,n,'Actor-specific new-actor tree failed: '..tostring(err)) end
	end
end

local function makeRepLayout(relite,r,block,root)
	local f=relite.const.FIELDS
	if block.PayloadRep then
		local p=root:add_le(f.Payload,r)
		p:add_le(f.RepPropertiesDoChecksum,r,block.PayloadRep.DoChecksum or false)
		local props=p:add_le(f.RepPropertiesProperties,r)
		for _,prop in ipairs(block.PayloadRep.Properties or {}) do relite.utils.makePropertyNode(relite,r,props,prop) end
		if block.PayloadRep.UnknownHandle then p:add_le(f.ParseError,r,'Unknown RepLayout wire handle '..tostring(block.PayloadRep.UnknownHandle)) end
		if block.PayloadRep.UnsupportedType then p:add_le(f.ParseError,r,'Unsupported replicated property type '..tostring(block.PayloadRep.UnsupportedType)) end
	elseif block.RepLayoutUnknown then
		root:add_le(f.ParseError,r,'No validated RepLayout wire-handle map for this class; payload kept raw')
	end
end

local function makeNetField(relite,r,nf,root)
	local f=relite.const.FIELDS
	local label=nf.FieldName or nf.FieldPath or ('NetField '..tostring(nf.FieldNetIndex or '?'))
	local actorField=relite.const.getActorField(nf.Field)
	local p=actorField and root:add_le(actorField,r) or root:add_le(f.Payload,r,label)
	if nf.FieldNetIndex~=nil then p:add_le(f.NetFieldIndex,r,nf.FieldNetIndex) end
	if nf.FieldKind then p:add_le(f.NetFieldKind,r,nf.FieldKind) end
	if nf.FieldPath then p:add_le(f.NetFieldPath,r,nf.FieldPath) end
	if nf.RpcCall then p:add_le(f.RpcCall,r,nf.RpcCall); p:add_le(f.RpcSignature,r,nf.RpcCall) end
	if nf.RpcDirection and nf.RpcDirection~='' then p:add_le(f.RpcDirection,r,nf.RpcDirection) end
	if nf.RpcReliable~=nil then p:add_le(f.RpcReliable,r,nf.RpcReliable) end
	if nf.RpcValidate~=nil then p:add_le(f.RpcValidate,r,nf.RpcValidate) end
	if nf.RpcFlags and nf.RpcFlags~='' then p:add_le(f.RpcFlags,r,nf.RpcFlags) end
	if nf.RpcWrapperRva and nf.RpcWrapperRva~='' then p:add_le(f.RpcWrapperRva,r,nf.RpcWrapperRva) end
	if nf.PropertyInfo then p:add_le(f.PropertyInfo,r,nf.PropertyInfo) end
	if nf.PropertyRepIndex~=nil then p:add_le(f.PropertyRepIndex,r,nf.PropertyRepIndex) end
	if nf.PropertyRepCondition and nf.PropertyRepCondition~='' then p:add_le(f.PropertyRepCondition,r,nf.PropertyRepCondition) end
	if nf.PropertyRepNotify and nf.PropertyRepNotify~='' then p:add_le(f.PropertyRepNotify,r,nf.PropertyRepNotify) end
	if nf.DecodedValue~=nil then
		local valueField=relite.const.getActorValueField(nf.Field)
		if valueField then p:add_le(valueField,r,nf.DecodedValue) end
	end
	if nf.DecodedParameters and nf.Field and nf.Field.declaringClass then
		local params=relite.const.ACTOR_RPC_PARAM_FIELDS[nf.Field.declaringClass]
		params=params and params[nf.Field.netIndex] or nil
		for key,value in pairs(nf.DecodedParameters) do
			local pf=params and params[key]
			if pf then p:add_le(pf,r,value) end
		end
	end
	if nf.NumPayloadBits then p:add_le(f.NumPayloadBits,r,nf.NumPayloadBits) end
	if nf.PayloadHex then p:add_le(f.PayloadRaw,r,nf.PayloadHex) end
	addError(f,r,p,nf.Error)
end

function actorMaker.makeRecoveredClassPayload(relite,r,block,root,className,context)
	local f=relite.const.FIELDS
	if className then root:add_le(f.ActorHandlerClass,r,className) end
	makeRepLayout(relite,r,block,root)
	if block.NetFieldUnknownClass then root:add_le(f.ParseError,r,'Class is unresolved; NetField payload kept raw') end
	for _,nf in ipairs(block.PayloadFields or (block.PayloadField and {block.PayloadField} or {})) do makeNetField(relite,r,nf,root) end
end

function actorMaker.makeContentPayload(relite,r,block,root)
	local f=relite.const.FIELDS
	local n=root:add_le(f.ContentBlockPayload,r)
	n:add_le(f.ContentBlockPayloadHasRepLayout,r,block.HasRepLayout or false)
	n:add_le(f.ContentBlockPayloadIsActor,r,block.IsActor or false)
	if block.NumPayloadBits~=nil then n:add_le(f.ContentBlockPayloadNumPayloadBits,r,block.NumPayloadBits) end
	if block.ClassObjectName then n:add_le(f.ChannelObject,r,block.ClassObjectName) end
	if block.ResolvedClassName then n:add_le(f.ActorResolvedClass,r,block.ResolvedClassName) end
	if not block.IsActor then
		if block.SubObjectGuid~=nil then n:add_le(f.GUID,r,block.SubObjectGuid) end
		if block.SubObjectPath then n:add_le(f.NetGUIDResolvedPath,r,block.SubObjectPath) end
		if block.SubObjectClassPath then n:add_le(f.ChannelObject,r,block.SubObjectClassPath) end
		if block.SubObjectDeleted then n:add_le(f.ParseError,r,'Subobject deletion block') end
	end
	local maker,cname,loadError=actorMaker.getActorMaker(relite,block.ResolvedClassName or block.ClassObjectName)
	if loadError then addError(f,r,n,'Actor tree-maker load failed: '..loadError) end
	if maker and maker.makePayload then
		local ok,err=pcall(maker.makePayload,relite,r,block,n,{IsActor=block.IsActor})
		if not ok then addError(f,r,n,'Actor-specific tree failed: '..tostring(err)) end
	else actorMaker.makeRecoveredClassPayload(relite,r,block,n,cname or block.ResolvedClassName,{IsActor=block.IsActor}) end
	addError(f,r,n,block.ActorHandlerError)
	addError(f,r,n,block.Error)
	if block.RemainingBits and block.RemainingBits>0 then n:add_le(f.RemainingBits,r,block.RemainingBits) end
	if block.RemainingRaw then n:add_le(f.PayloadRaw,r,block.RemainingRaw)
	elseif block.PayloadHex and ((block.RemainingBits or 0)>0 or block.RepLayoutUnknown or block.NetFieldUnknownClass) then n:add_le(f.PayloadRaw,r,block.PayloadHex) end
end

function actorMaker.makeActorUpdatePacket(relite,r,payload,root,bunchHeader)
	local f=relite.const.FIELDS
	local n=root:add_le(payload.MakeSetup and f.ActSetup or f.ActUpdate,r)
	if payload.ChannelObjectName then n:add_le(f.ChannelObject,r,payload.ChannelObjectName) end
	if payload.ResolvedClassName then n:add_le(f.ActorResolvedClass,r,payload.ResolvedClassName) end
	if bunchHeader.hasPackageMapExports then makeExports(relite,r,payload,n) end
	if bunchHeader.hasMustBeMappedGUIDs and payload.NumGuidsMapped then
		local g=n:add_le(payload.MakeSetup and f.ActSetupNumMustBeMappedGUIDs or f.ActUpdateNumMustBeMappedGUIDs,r,payload.NumGuidsMapped)
		for _,guid in ipairs(payload.MustBeMappedGUIDs or {}) do g:add_le(f.GUID,r,guid) end
	end
	if payload.MakeSetup then makeActorIdentity(relite,r,payload,n) end
	for _,block in ipairs(payload.ContentBlocks or {}) do actorMaker.makeContentPayload(relite,r,block,n) end
	addError(f,r,n,payload.GameActorSetupError)
	addError(f,r,n,payload.ParseError)
	if payload.RemainingBits and payload.RemainingBits>0 then n:add_le(f.RemainingBits,r,payload.RemainingBits) end
	if payload.RemainingRaw then n:add_le(f.PayloadRaw,r,payload.RemainingRaw) end
end

actorMaker.makeExports=makeExports
return actorMaker

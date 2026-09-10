local utils={}
local trickle=require 'trickle'

function utils.tableHasKey(t,key) return t~=nil and t[key]~=nil end

-- UE FArchive::SerializeInt/FBitReader bounded integer. This is value-dependent for non-powers of two.
function utils.readintwrapped(stream,max)
	max=math.floor(tonumber(max) or 0)
	if max<=1 then return 0 end
	local value=0; local mask=1; local guard=0
	while value+mask<max and not stream:isError() do
		if stream:readBool() then value=value+mask end
		mask=mask*2; guard=guard+1
		if guard>32 then stream.error=true; break end
	end
	return value
end

function utils.readintpacked(stream)
	local result=0; local shift=0
	for _=1,5 do
		local b=stream:readBits(8)
		result=result+math.floor(b/2)*(2^shift)
		if b%2==0 then return result end
		shift=shift+7
		if stream:isError() then return result end
	end
	stream.error=true
	return result
end

function utils.readUInt32(stream) return stream:readBits(32) end
function utils.readInt32(stream)
	local v=stream:readBits(32)
	if v>=2147483648 then return v-4294967296 end
	return v
end

local function float32(v)
	local sign=(v>=2147483648) and -1 or 1
	if sign<0 then v=v-2147483648 end
	local exp=math.floor(v/8388608); local frac=v%8388608
	if exp==255 then return frac==0 and sign*math.huge or 0/0 end
	if exp==0 then return sign*(frac/8388608)*(2^-126) end
	return sign*(1+frac/8388608)*(2^(exp-127))
end
function utils.readFloat32(stream) return float32(stream:readBits(32)) end

function utils.readbitarray(stream,n)
	n=math.max(0,math.floor(tonumber(n) or 0))
	local out={}; local left=math.min(n,stream:bitsLeft())
	while left>0 do
		local take=math.min(left,8)
		out[#out+1]=string.format('%02X',stream:readBits(take))
		left=left-take
	end
	if n>0 and n%8~=0 then out[#out+1]=string.format('[%db]',n) end
	return table.concat(out,' ')
end
function utils.streamHex(stream)
	local c=stream:clone()
	return utils.readbitarray(c,c:bitsLeft())
end

local function utf8char(cp)
	if cp<0x80 then return string.char(cp) end
	if cp<0x800 then return string.char(0xC0+math.floor(cp/64),0x80+cp%64) end
	if cp<0x10000 then return string.char(0xE0+math.floor(cp/4096),0x80+math.floor(cp/64)%64,0x80+cp%64) end
	if cp<=0x10FFFF then return string.char(0xF0+math.floor(cp/262144),0x80+math.floor(cp/4096)%64,0x80+math.floor(cp/64)%64,0x80+cp%64) end
	return '?'
end
function utils.readstring(stream)
	local count=utils.readInt32(stream)
	if stream:isError() or count==0 then return '' end
	local wide=count<0
	local n=math.abs(count)
	if n>1048576 then stream.error=true; return '<invalid FString length '..tostring(count)..'>' end
	local out={}
	if not wide then
		for i=1,n do
			local b=stream:readBits(8)
			if i<n and b~=0 then out[#out+1]=string.char(b) end
			if stream:isError() then break end
		end
	else
		local i=1
		while i<=n do
			local w=stream:readBits(16)
			if i<n and w~=0 then
				if w>=0xD800 and w<=0xDBFF and i+1<=n then
					local w2=stream:readBits(16); i=i+1
					if w2>=0xDC00 and w2<=0xDFFF then w=0x10000+(w-0xD800)*0x400+(w2-0xDC00) end
				end
				out[#out+1]=utf8char(w)
			end
			if stream:isError() then break end
			i=i+1
		end
	end
	return table.concat(out)
end

-- Historical UE packed FVector format used by the 4.x network serializers.
function utils.readPackedVector(stream,scaleFactor,maxBits)
	scaleFactor=scaleFactor or 1; maxBits=maxBits or 24
	local bits=utils.readintwrapped(stream,maxBits)+1
	if bits<1 or bits>maxBits then stream.error=true; return {X=0,Y=0,Z=0,Error=true} end
	local bias=2^(bits-1); local max=2^bits
	local function component() return (utils.readintwrapped(stream,max)-bias)/scaleFactor end
	return {X=component(),Y=component(),Z=component(),Bits=bits}
end
function utils.readRotator(stream)
	local function axis()
		if not stream:readBool() then return 0 end
		return stream:readBits(16)*360/65536
	end
	return {Pitch=axis(),Yaw=axis(),Roll=axis()}
end

local function maxIndex(map)
	local m=-1
	for k,_ in pairs(map or {}) do if type(k)=='number' and k>m then m=k end end
	return m
end

function utils.readRepArray(relite,stream,repDef,count)
	local result={}; local typeMap=relite.netDefines.REP_LAYOUT_DICT[repDef.SubType]
	if not typeMap then return result end
	for _=1,count do
		local element={}; local guard=0
		while not stream:isError() and guard<256 do
			guard=guard+1
			local handle=utils.readintpacked(stream)
			if handle==0 then break end
			local def=typeMap[handle]
			if not def then stream.error=true; break end
			element[#element+1]=utils.readRepProp(relite,stream,def)
		end
		result[#result+1]={Type=repDef.SubType,Name='['..tostring(#result)..']',Value=element}
	end
	return result
end
function utils.readRepProp(relite,stream,repDef)
	local prop={Type=repDef.Type,Name=repDef.Name}
	local t=prop.Type
	if t=='Int32' then prop.Value=utils.readInt32(stream)
	elseif t=='Float' then prop.Value=utils.readFloat32(stream)
	elseif t=='Byte' or t=='UByteProperty' or t=='UEnumProperty' or t=='UBoolProperty' then prop.Value=stream:readBits(repDef.Size or 1)
	elseif t=='UObjectProperty' then prop.Value=utils.readintpacked(stream)
	elseif t=='TArrayProperty' then
		prop.Size=stream:readBits(16); prop.Value=utils.readRepArray(relite,stream,repDef,prop.Size)
	else prop.Unsupported=true end
	return prop
end
function utils.readReplicatedProperties(relite,stream,repLayout)
	local result={DoChecksum=stream:readBool(),Properties={}}
	local guard=0
	while not stream:isError() and guard<2048 do
		guard=guard+1
		local handle=utils.readintpacked(stream)
		if handle==0 then break end
		local def=repLayout[handle]
		if not def then result.UnknownHandle=handle; break end
		local prop=utils.readRepProp(relite,stream,def); prop.Handle=handle
		result.Properties[#result.Properties+1]=prop
		if prop.Unsupported then result.UnsupportedType=prop.Type; break end
	end
	return result
end

function utils.readNetField(relite,stream,channelObjectName)
	local result={Payload={}}
	local resolved=relite.netDefines.resolveClassName(channelObjectName) or channelObjectName
	local map=relite.netDefines.getNetFieldMap(resolved)
	result.ResolvedClassName=resolved
	if not map then
		result.Error='No recovered NetField map for '..tostring(channelObjectName)
		result.PayloadHex=utils.streamHex(stream); stream:skipBits(stream:bitsLeft()); return result
	end
	local maxNet=maxIndex(map)+1
	if maxNet<=0 then result.Error='Recovered class has no effective NetFields'; return result end
	result.FieldNetIndex=utils.readintwrapped(stream,maxNet)
	result.NumPayloadBits=utils.readintpacked(stream)
	if stream:isError() then result.Error='Truncated NetField header'; return result end
	if result.NumPayloadBits>stream:bitsLeft() then result.Error='NetField payload exceeds content block'; result.NumPayloadBits=stream:bitsLeft() end
	local p=stream:readSubstream(result.NumPayloadBits)
	result.PayloadHex=utils.streamHex(p)
	result.Field=map[result.FieldNetIndex]
	if result.Field then
		result.FieldName=result.Field.name; result.FieldKind=result.Field.kind; result.FieldPath=result.Field.path
		result.DeclaringClass=result.Field.declaringClass
		if result.Field.kind=='RPC' then
			result.RpcCall=(result.Field.signature and result.Field.signature~='') and result.Field.signature or result.Field.path
			result.RpcParameters=result.Field.params
			result.RpcDirection=result.Field.rpcDirection
			result.RpcReliable=result.Field.rpcReliable
			result.RpcValidate=result.Field.rpcValidate
			result.RpcFlags=result.Field.rpcFlagLabels
			result.RpcWrapperRva=result.Field.wrapperRva
		else
			result.PropertyRepIndex=result.Field.repIndex
			result.PropertyRepCondition=result.Field.repCondition
			result.PropertyRepNotify=result.Field.repNotify
			result.PropertyInfo=string.format('%s (%s%s)',result.Field.name or '?',result.Field.fieldType or '?',(result.Field.valueType and result.Field.valueType~='') and ': '..result.Field.valueType or '')
		end
	else result.Error='Recovered class has no NetField index '..tostring(result.FieldNetIndex) end
	return result
end

function utils.readNetFields(relite,stream,channelObjectName)
	local result={}; local guard=0
	while stream:bitsLeft()>0 and not stream:isError() and guard<1024 do
		guard=guard+1; local before=stream:getPosBits()
		local f=utils.readNetField(relite,stream,channelObjectName); result[#result+1]=f
		if f.Error or stream:getPosBits()<=before then break end
	end
	if guard>=1024 then result.Error='NetField guard reached' end
	return result
end

-- Shared parser mechanics used by every generated actor-class handler. The class module chooses
-- the class identity; this helper performs only the UE/recovered-metadata mechanics common to all classes.
function utils.readRecoveredClassPayload(relite,stream,context,className)
	context=context or {}
	local result={ResolvedClassName=className}
	if context.HasRepLayout then
		local layout=relite.netDefines.getRepLayout(className)
		if layout then
			result.PayloadRep=utils.readReplicatedProperties(relite,stream,layout)
			if not stream:isError() and stream:bitsLeft()>0 then result.PayloadFields=utils.readNetFields(relite,stream,className) end
		else result.RepLayoutUnknown=true end
	else
		local map=relite.netDefines.getNetFieldMap(className)
		if map then result.PayloadFields=utils.readNetFields(relite,stream,className)
		else result.NetFieldUnknownClass=true end
	end
	result.RemainingBits=stream:bitsLeft()
	if result.RemainingBits>0 then result.RemainingRaw=utils.streamHex(stream) end
	return result
end

local function mergeParsed(dst,src)
	for k,v in pairs(src or {}) do dst[k]=v end
end

function utils.readContentBlockPayload(relite,stream,channelInfo)
	local result={}; local before=stream:getPosBits()
	result.HasRepLayout=stream:readBool(); result.IsActor=stream:readBool()
	if stream:isError() then result.Error='Truncated content-block header'; return result end
	local objectName=result.IsActor and (channelInfo and channelInfo.ChannelObjectName or nil) or nil
	if not result.IsActor then
		result.SubObject=relite.actorHandler.readNetGuid(relite,stream,false)
		result.SubObjectGuid=result.SubObject and result.SubObject.Guid or 0
		result.SubObjectPath=relite.actorHandler.resolveGuid(relite,result.SubObjectGuid)
		if stream:isError() then result.Error='Truncated subobject NetGUID'; return result end
		if channelInfo and channelInfo.IsServerSource then
			result.SubObjectStablyNamed=stream:readBool()
			if stream:isError() then result.Error='Truncated subobject stable-name flag'; return result end
			if not result.SubObjectStablyNamed then
				result.SubObjectClass=relite.actorHandler.readNetGuid(relite,stream,false)
				result.SubObjectClassGuid=result.SubObjectClass and result.SubObjectClass.Guid or 0
				result.SubObjectClassPath=relite.actorHandler.resolveGuid(relite,result.SubObjectClassGuid)
				objectName=result.SubObjectClassPath
				if result.SubObjectClassGuid==0 then result.SubObjectDeleted=true; return result end
			else objectName=result.SubObjectPath end
		else objectName=result.SubObjectPath end
		result.SubObjectClassName=relite.netDefines.resolveClassName(objectName)
	end
	result.NumPayloadBits=utils.readintpacked(stream)
	if stream:isError() then result.Error='Truncated content-block payload size'; return result end
	if result.NumPayloadBits>stream:bitsLeft() then result.Error='Content-block payload exceeds remaining actor data'; result.NumPayloadBits=stream:bitsLeft() end
	local p=stream:readSubstream(result.NumPayloadBits)
	result.PayloadHex=utils.streamHex(p)
	result.ClassObjectName=objectName
	result.ResolvedClassName=relite.netDefines.resolveClassName(objectName)
	local handler,cname,loadError=relite.actorHandler.getActorHandler(relite,result.ResolvedClassName or objectName)
	if cname then result.ResolvedClassName=cname end
	if loadError then result.ActorHandlerError=loadError end
	if handler and handler.parsePayload then
		result.ActorHandlerClass=handler.ClassName or cname
		local ok,parsed=pcall(handler.parsePayload,relite,p,{HasRepLayout=result.HasRepLayout,IsActor=result.IsActor,ChannelInfo=channelInfo,Block=result})
		if ok then mergeParsed(result,parsed)
		else result.ActorHandlerError=tostring(parsed) end
	else
		mergeParsed(result,utils.readRecoveredClassPayload(relite,p,{HasRepLayout=result.HasRepLayout,IsActor=result.IsActor,ChannelInfo=channelInfo,Block=result},result.ResolvedClassName or objectName))
	end
	result.RemainingBits=p:bitsLeft()
	if result.RemainingBits>0 then result.RemainingRaw=utils.streamHex(p) end
	if stream:getPosBits()<=before then result.Error='Content parser made no progress' end
	return result
end
function utils.readContentBlocks(relite,payload,stream,channelInfo)
	payload.ContentBlocks={}; local guard=0
	while stream:bitsLeft()>1 and not stream:isError() and guard<256 do
		guard=guard+1; local before=stream:getPosBits()
		local block=utils.readContentBlockPayload(relite,stream,channelInfo)
		payload.ContentBlocks[#payload.ContentBlocks+1]=block
		if block.Error or stream:getPosBits()<=before then break end
	end
	if guard>=256 then payload.ParseError='Content-block guard reached' end
end

function utils.makePropertyNode(relite,r,root,prop)
	local fields=relite.const.FIELDS
	local text=(prop.Name or '?')..' ('..(prop.Type or '?')..')'
	if prop.Value~=nil and type(prop.Value)~='table' then text=text..' = '..tostring(prop.Value) end
	local node=root:add_le(fields.Property,r,text)
	if type(prop.Value)=='table' then
		for _,v in ipairs(prop.Value) do
			if v.Value and type(v.Value)=='table' then for _,sub in ipairs(v.Value) do utils.makePropertyNode(relite,r,node,sub) end
			else utils.makePropertyNode(relite,r,node,v) end
		end
	end
	return node
end

return utils

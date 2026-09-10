local controlHandler={}

local function detail(p,s) p.Details=p.Details or {}; p.Details[#p.Details+1]=s end
local function readBytes(stream,count)
	local out={}; local hex={}
	if count<0 or count>1048576 or count*8>stream:bitsLeft() then stream.error=true; return '', '' end
	for i=1,count do
		local b=stream:readBits(8); hex[#hex+1]=string.format('%02X',b)
		if b~=0 then out[#out+1]=string.char(b) end
	end
	return table.concat(out),table.concat(hex,' ')
end
local function readByteArray(relite,stream)
	local count=relite.utils.readInt32(stream)
	local text,hex=readBytes(stream,count)
	return {Count=count,Text=text,Hex=hex}
end
local function readUniqueId(relite,stream)
	local size=relite.utils.readInt32(stream)
	local contents=''
	if size>0 and not stream:isError() then contents=relite.utils.readstring(stream) end
	return {Size=size,Contents=contents}
end
local function readGuid(relite,stream)
	local u=relite.utils
	return {A=u.readUInt32(stream),B=u.readUInt32(stream),C=u.readUInt32(stream),D=u.readUInt32(stream)}
end
local function guidText(g) return string.format('%08X-%08X-%08X-%08X',g.A or 0,g.B or 0,g.C or 0,g.D or 0) end

local function readNMT_Hello(relite,stream,p,isServer)
	local u=relite.utils
	-- Keep the observed PUBG Lite server-side compatibility form from the original dissector.
	if isServer then
		p.A=u.readUInt32(stream); p.B=u.readUInt32(stream); p.C=u.readUInt32(stream); p.D=u.readUInt32(stream)
		detail(p,string.format('PUBG server hello words: %08X %08X %08X %08X',p.A,p.B,p.C,p.D))
	else
		p.Endianess=stream:readBits(8); p.NetworkVersion=u.readUInt32(stream); p.EncryptionToken=u.readstring(stream)
		detail(p,'Little endian: '..tostring(p.Endianess~=0)); detail(p,'Network version: '..tostring(p.NetworkVersion))
		if p.EncryptionToken~='' then detail(p,'Encryption token: '..p.EncryptionToken) end
	end
end
local function readNMT_Welcome(relite,stream,p)
	local u=relite.utils; p.MapURL=u.readstring(stream); p.GameName=u.readstring(stream); p.RedirectURL=u.readstring(stream)
	detail(p,'Map: '..p.MapURL); detail(p,'Game: '..p.GameName); if p.RedirectURL~='' then detail(p,'Redirect: '..p.RedirectURL) end
end
local function readNMT_Upgrade(relite,stream,p) p.NetworkVersion=relite.utils.readUInt32(stream); detail(p,'Required network version: '..tostring(p.NetworkVersion)) end
local function readNMT_Challenge(relite,stream,p) p.Challenge=relite.utils.readstring(stream); detail(p,'Challenge: '..p.Challenge) end
local function readNMT_NetSpeed(relite,stream,p) p.NetSpeed=relite.utils.readInt32(stream); detail(p,'Requested rate: '..tostring(p.NetSpeed)) end
local function readNMT_Login(relite,stream,p)
	local u=relite.utils
	p.ClientResponse=u.readstring(stream)
	local request=readByteArray(relite,stream); p.RequestUrlBytes=request.Text; p.RequestUrlHex=request.Hex; p.RequestUrlByteCount=request.Count
	local uid=readUniqueId(relite,stream); p.UIDSize=uid.Size; p.UIDContent=uid.Contents
	p.OnlinePlatformName=u.readstring(stream)
	detail(p,'Client response: '..p.ClientResponse); detail(p,'Request URL: '..p.RequestUrlBytes); detail(p,'Unique ID: '..(p.UIDContent~='' and p.UIDContent or '<invalid>')); detail(p,'Platform: '..p.OnlinePlatformName)
end
local function readNMT_Failure(relite,stream,p) p.Failure=relite.utils.readstring(stream); detail(p,'Failure: '..p.Failure) end
local function readNMT_Join() end
local function readNMT_JoinSplit(relite,stream,p)
	p.URL=relite.utils.readstring(stream); local uid=readUniqueId(relite,stream); p.UIDSize=uid.Size; p.UIDContent=uid.Contents
	detail(p,'URL: '..p.URL); detail(p,'Unique ID: '..(p.UIDContent~='' and p.UIDContent or '<invalid>'))
end
local function readNMT_Guid(relite,stream,p) p.PackageGuid=readGuid(relite,stream); detail(p,'GUID: '..guidText(p.PackageGuid)) end
local function readNMT_Int(relite,stream,p) p.Value=relite.utils.readInt32(stream); detail(p,'Value: '..tostring(p.Value)) end
local function readNMT_DebugText(relite,stream,p) p.Text=relite.utils.readstring(stream); detail(p,p.Text) end
local function readNMT_NetGUIDAssign(relite,stream,p)
	p.NetGUID=relite.utils.readintpacked(stream); p.Path=relite.utils.readstring(stream); detail(p,'NetGUID: '..tostring(p.NetGUID)); detail(p,'Path: '..p.Path)
end
local function readNMT_SecurityViolation(relite,stream,p) p.Text=relite.utils.readstring(stream); detail(p,'Violation: '..p.Text); p.StopAfter=true end
local function readNMT_GameSpecific(relite,stream,p) p.MessageByte=stream:readBits(8); p.Text=relite.utils.readstring(stream); detail(p,'Message byte: '..tostring(p.MessageByte)); detail(p,p.Text) end
local function readNMT_Empty() end
local function readNMT_BeaconJoin(relite,stream,p)
	p.BeaconType=relite.utils.readstring(stream); local uid=readUniqueId(relite,stream); p.UIDSize=uid.Size; p.UIDContent=uid.Contents
	detail(p,'Beacon type: '..p.BeaconType); detail(p,'Unique ID: '..(p.UIDContent~='' and p.UIDContent or '<invalid>'))
end
local function readNMT_NetGUID(relite,stream,p) p.NetGUID=relite.utils.readintpacked(stream); detail(p,'NetGUID: '..tostring(p.NetGUID)) end
local function readNMT_String(relite,stream,p) p.Text=relite.utils.readstring(stream); detail(p,p.Text) end

local handlers={
	[0]=readNMT_Hello,[1]=readNMT_Welcome,[2]=readNMT_Upgrade,[3]=readNMT_Challenge,[4]=readNMT_NetSpeed,[5]=readNMT_Login,
	[6]=readNMT_Failure,[9]=readNMT_Join,[10]=readNMT_JoinSplit,[12]=readNMT_Guid,[13]=readNMT_Guid,[15]=readNMT_Int,
	[16]=readNMT_Int,[17]=readNMT_DebugText,[18]=readNMT_NetGUIDAssign,[19]=readNMT_SecurityViolation,[20]=readNMT_GameSpecific,
	[21]=readNMT_Empty,[25]=readNMT_Empty,[26]=readNMT_BeaconJoin,[27]=readNMT_NetGUID,[28]=readNMT_String,
}

function controlHandler.processPayload(relite,stream,payload,isServer)
	payload.ControlMessages={}
	local guard=0
	while stream:bitsLeft()>=8 and not stream:isError() and guard<64 do
		guard=guard+1
		local before=stream:getPosBits(); local p={}
		local id=stream:readBits(8); p.MsgID=id; p.MsgName='('..id..') '..(relite.const.MSG_NAMES[id] or 'Unknown')
		local fn=handlers[id]
		if not fn then
			p.ParseError='Unknown control message; remainder retained raw'
			payload.ControlMessages[#payload.ControlMessages+1]=p
			break
		end
		fn(relite,stream,p,isServer)
		if stream:isError() then p.ParseError='Control message ended while decoding' end
		payload.ControlMessages[#payload.ControlMessages+1]=p
		if p.StopAfter or p.ParseError or stream:getPosBits()<=before then break end
	end
	if guard>=64 then payload.ParseError='Control-message guard reached' end
	local first=payload.ControlMessages[1]
	if first then for k,v in pairs(first) do if payload[k]==nil then payload[k]=v end end end
	if stream:isError() and not payload.ParseError then payload.ParseError='Control message ended while decoding' end
	payload.RemainingBits=stream:bitsLeft()
	if payload.RemainingBits>0 then payload.RemainingRaw=relite.utils.streamHex(stream) end
end
return controlHandler

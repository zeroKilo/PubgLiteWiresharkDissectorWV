local controlMaker={}
local function add(node,field,r,value) if value~=nil then node:add_le(field,r,value) end end
local function hello(relite,r,p,n,isServer)
	local f=relite.const.FIELDS
	if isServer then add(n,f.NMT0A,r,p.A); add(n,f.NMT0B,r,p.B); add(n,f.NMT0C,r,p.C); add(n,f.NMT0D,r,p.D)
	else add(n,f.NMT0Endianess,r,p.Endianess); add(n,f.NMT0NetworkVersion,r,p.NetworkVersion); add(n,f.NMT0EncryptionToken,r,p.EncryptionToken) end
end
local function welcome(relite,r,p,n) local f=relite.const.FIELDS; add(n,f.NMT1MapURL,r,p.MapURL); add(n,f.NMT1GameName,r,p.GameName); add(n,f.NMT1RedirectURL,r,p.RedirectURL) end
local function challenge(relite,r,p,n) add(n,relite.const.FIELDS.NMT3Challenge,r,p.Challenge) end
local function netspeed(relite,r,p,n) add(n,relite.const.FIELDS.NMT4NetSpeed,r,p.NetSpeed) end
local function login(relite,r,p,n)
	local f=relite.const.FIELDS; add(n,f.NMT5ClientResponse,r,p.ClientResponse); add(n,f.NMT5RequestUrlBytes,r,p.RequestUrlBytes); add(n,f.NMT5UIDSize,r,p.UIDSize); add(n,f.NMT5UIDContent,r,p.UIDContent); add(n,f.NMT5OnlinePlatformName,r,p.OnlinePlatformName)
end
local handlers={[0]=hello,[1]=welcome,[3]=challenge,[4]=netspeed,[5]=login}
local function makeOne(relite,r,p,root,isServer)
	local f=relite.const.FIELDS
	local n=root:add_le(f.ControlMessage)
	add(n,f.PMsgID,r,p.MsgName)
	local fn=handlers[p.MsgID]; if fn then fn(relite,r,p,n,isServer) end
	for _,v in ipairs(p.Details or {}) do add(n,f.ControlDetail,r,v) end
	if p.ParseError then add(n,f.ParseError,r,p.ParseError) end
end
function controlMaker.makeControlMessage(relite,r,payload,root,isServer)
	local f=relite.const.FIELDS
	if payload.ControlMessages and #payload.ControlMessages>0 then
		for _,p in ipairs(payload.ControlMessages) do makeOne(relite,r,p,root,isServer) end
	else
		makeOne(relite,r,payload,root,isServer)
	end
	if payload.ParseError then add(root,f.ParseError,r,payload.ParseError) end
	if payload.RemainingBits and payload.RemainingBits>0 then add(root,f.RemainingBits,r,payload.RemainingBits) end
	if payload.RemainingRaw then add(root,f.PayloadRaw,r,payload.RemainingRaw) end
end
return controlMaker

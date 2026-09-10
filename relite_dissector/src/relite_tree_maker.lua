local treeMaker={}

local function addError(f,r,node,msg) if msg then node:add_le(f.ParseError,r,tostring(msg)) end end

function treeMaker.makeNormalBunch(relite,r,bunch,root,isServer)
	local f=relite.const.FIELDS; local h=bunch.Header or {}; local payload=bunch.Payload or {}
	local bn=root:add_le(f.Bunch); local hn=bn:add_le(f.Header)
	hn:add_le(f.HIsAck,r,h.isAck or false)
	if h.isAck then
		if h.ackID~=nil then hn:add_le(f.HAckPacketID,r,h.ackID) end
		hn:add_le(f.HHasServerFrameTime,r,h.hasServerFrameTime or false)
		if h.serverFrameTime~=nil then hn:add_le(f.HServerFrameTime,r,h.serverFrameTime) end
		if h.inKBytesPerSecond~=nil then hn:add_le(f.HInKBytesPerSecond,r,h.inKBytesPerSecond) end
		return
	end
	hn:add_le(f.HOpenOrClose,r,h.openOrClose or false)
	if h.openOrClose then
		hn:add_le(f.HIsOpen,r,h.isOpen or false); hn:add_le(f.HIsClosed,r,h.isClosed or false)
		if h.isClosed then hn:add_le(f.HIsDormant,r,h.isDormant or false) end
	end
	hn:add_le(f.HIsReplicationPaused,r,h.isReplicationPaused or false)
	hn:add_le(f.HIsReliable,r,h.isReliable or false)
	if h.channelIndex~=nil then hn:add_le(f.HChannelIndex,r,h.channelIndex) end
	hn:add_le(f.HHasPackageMapExports,r,h.hasPackageMapExports or false)
	hn:add_le(f.HHasMustBeMappedGUIDs,r,h.hasMustBeMappedGUIDs or false)
	hn:add_le(f.HIsPartial,r,h.isPartial or false)
	if h.channelSequence~=nil then hn:add_le(f.HChannelSequence,r,h.channelSequence) end
	if h.isPartial then hn:add_le(f.HIsPartialInitial,r,h.isPartialInit or false); hn:add_le(f.HIsPartialFinal,r,h.isPartialFinal or false) end
	if h.channelType and h.channelType~=0 then hn:add_le(f.HChannelType,r,h.HChannelTypeName or tostring(h.channelType)) end
	if h.numBits~=nil then hn:add_le(f.HNumBits,r,h.numBits) end
	if bunch.PartialStatus then hn:add_le(f.PartialStatus,r,bunch.PartialStatus) end
	addError(f,r,bn,bunch.PartialError); addError(f,r,bn,bunch.ParseError)
	local pn=bn:add_le(f.Payload)
	if bunch.PayloadRaw then pn:add_le(f.PayloadRaw,r,bunch.PayloadRaw) end
	local chtype=(bunch.EffectiveHeader and bunch.EffectiveHeader.channelType) or h.channelType
	if bunch.Decoded or bunch.Reassembled then
		if chtype==1 then relite.controlMaker.makeControlMessage(relite,r,payload,pn,isServer)
		elseif chtype==2 then relite.actorMaker.makeActorUpdatePacket(relite,r,payload,pn,bunch.EffectiveHeader or h) end
	elseif chtype==2 and h.hasPackageMapExports then
		-- Partial-initial export fragments are meaningful even though their actor data is not decoded yet.
		relite.actorMaker.makeExports(relite,r,payload,pn)
	end
	addError(f,r,pn,payload.ParseError)
	if payload.RemainingBits and payload.RemainingBits>0 then pn:add_le(f.RemainingBits,r,payload.RemainingBits) end
	if payload.RemainingRaw then pn:add_le(f.PayloadRaw,r,payload.RemainingRaw) end
end

function treeMaker.makeTree(relite,buffer,packet,root)
	local f=relite.const.FIELDS; local r=buffer(0,0)
	root:add_le(f.IsServer,r,packet.IsServer or false)
	if packet.ConnectionKey then root:add_le(f.ConnectionKey,r,packet.ConnectionKey) end
	root:add_le(f.IsHandshake,r,packet.IsHandshakePacket or false)
	if packet.IsHandshakePacket then
		local b=packet.Bunches and packet.Bunches[1]
		if b then local n=root:add_le(f.Bunch):add_le(f.HandshakeData); if b.HSChallengeData then n:add_le(f.HSChallengeData,r,b.HSChallengeData) end; if b.HSTerminationBit~=nil then n:add_le(f.HSTerminationBit,r,b.HSTerminationBit) end end
	else
		if not packet.IsServer and packet.ClientID~=nil then root:add_le(f.HClientID,r,packet.ClientID) end
		if packet.HEncryptionEnabled~=nil then root:add_le(f.HEncryptionEnabled,r,packet.HEncryptionEnabled) end
		if packet.HOutPacketID~=nil then root:add_le(f.HOutPacketID,r,packet.HOutPacketID) end
		for _,b in ipairs(packet.Bunches or {}) do treeMaker.makeNormalBunch(relite,r,b,root,packet.IsServer) end
	end
	addError(f,r,root,packet.ParseError)
	if packet.RemainingBits and packet.RemainingBits>0 then root:add_le(f.RemainingBits,r,packet.RemainingBits) end
end

return treeMaker

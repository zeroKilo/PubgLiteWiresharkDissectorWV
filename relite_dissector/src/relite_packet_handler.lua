local packetHandler = {}
local trickle = require 'trickle'

local function dirName(packet) return packet.IsServer and 'server' or 'client' end
local function cloneHeader(h)
	local r={}
	for k,v in pairs(h) do r[k]=v end
	return r
end
local function appendReader(writer,reader)
	local left=reader:bitsLeft()
	while left>0 do
		local n=math.min(left,24)
		writer:writeBits(reader:readBits(n),n)
		left=left-n
	end
end
local function seqValid(prev,cur,reliable,maxseq)
	if prev==nil or cur==nil then return true end
	if reliable then return cur==((prev+1)%maxseq) end
	return cur==prev or cur==prev+1
end
local function unwrapSequence(last,raw,max)
	if last==nil then return raw end
	local base=last-(last%max); local v=base+raw; local half=max/2
	if v<last-half then v=v+max elseif v>last+half then v=v-max end
	return v
end


local function processDecoded(relite,bunch,stream,header,packet)
	local chtype=header.channelType or 0
	bunch.Decoded=true
	bunch.EffectiveHeader=header
	header.isServerSource=packet.IsServer
	if chtype==1 then
		relite.controlHandler.processPayload(relite,stream,bunch.Payload,packet.IsServer)
	elseif chtype==2 then
		relite.actorHandler.processActorPacket(relite,bunch.Payload,stream,header)
	else
		bunch.Payload.RemainingBits=stream:bitsLeft()
		if stream:bitsLeft()>0 then bunch.Payload.RemainingRaw=relite.utils.streamHex(stream) end
	end
	if stream:isError() and not bunch.Payload.ParseError then bunch.Payload.ParseError='Payload decode overflow' end
end

local function processPartial(relite,bunch,payloadStream,header,packet,conn)
	local partials=conn.partials[dirName(packet)]
	local idx=header.channelIndex
	if header.isPartialInit then
		local p={writer=trickle.createWriter(),header=cloneHeader(header),lastSeq=header.channelSequence,reliable=header.isReliable,invalid=false,totalBits=0}
		partials[idx]=p
		bunch.PartialStatus=header.hasPackageMapExports and 'initial(exports-only)' or 'initial'
		-- UE partial-initial bunches that carry PackageMap exports use that fragment only for exports; payload data begins in later fragments.
		if not header.hasPackageMapExports then appendReader(p.writer,payloadStream) end
		p.totalBits=p.writer:getNumBits()
		if header.isPartialFinal then
			partials[idx]=nil
			processDecoded(relite,bunch,p.writer:toReader(),p.header,packet)
			bunch.Reassembled=true
		end
		return
	end
	local p=partials[idx]
	if not p then bunch.PartialError='Continuation without initial partial bunch'; return end
	if p.reliable~=header.isReliable then p.invalid=true; bunch.PartialError='Partial reliability changed' end
	if not seqValid(p.lastSeq,header.channelSequence,header.isReliable,relite.const.MAX_CHSEQUENCE) then
		p.invalid=true; bunch.PartialError='Partial sequence discontinuity'
	end
	p.lastSeq=header.channelSequence or p.lastSeq
	if header.hasPackageMapExports then p.invalid=true; bunch.PartialError='PackageMap exports are only valid on the initial partial fragment' end
	appendReader(p.writer,payloadStream); p.totalBits=p.writer:getNumBits()
	if p.totalBits>65536*8 then p.invalid=true; bunch.PartialError='Reassembled partial exceeds 64 KiB' end
	bunch.PartialStatus=header.isPartialFinal and 'final' or 'continuation'
	if header.isPartialFinal then
		partials[idx]=nil
		local effective=p.header
		effective.isClosed=header.isClosed
		effective.isDormant=header.isDormant
		effective.isReplicationPaused=header.isReplicationPaused
		effective.hasMustBeMappedGUIDs=header.hasMustBeMappedGUIDs
		effective.isPartialFinal=true
		effective.channelSequence=header.channelSequence or effective.channelSequence
		bunch.Header.channelType=effective.channelType
		bunch.Header.HChannelTypeName=effective.HChannelTypeName
		if not p.invalid then
			processDecoded(relite,bunch,p.writer:toReader(),effective,packet)
			bunch.Reassembled=true
		end
	end
end

function packetHandler.readNormalBunch(relite,stream,packet)
	local consts=relite.const
	local utils=relite.utils
	local conn=relite.getConnectionState(packet.ConnectionKey)
	if packet.IsServer==false then packet.ClientID=stream:readBits(32) end
	packet.HEncryptionEnabled=stream:readBool()
	packet.HOutPacketID=utils.readintwrapped(stream,consts.MAX_PACKETID)
	conn.packetIds=conn.packetIds or {server=nil,client=nil}
	local d=dirName(packet); packet.PacketID=unwrapSequence(conn.packetIds[d],packet.HOutPacketID,consts.MAX_PACKETID); conn.packetIds[d]=packet.PacketID
	local guard=0
	while stream:bitsLeft()>0 and not stream:isError() and guard<1024 do
		guard=guard+1
		local before=stream:getPosBits()
		local bunch={Payload={}}
		local h={}
		h.isAck=stream:readBool()
		if h.isAck then
			h.ackID=utils.readintwrapped(stream,consts.MAX_PACKETID)
			h.hasServerFrameTime=stream:readBool()
			if packet.IsServer and h.hasServerFrameTime then h.serverFrameTime=stream:readBits(8) end
			h.inKBytesPerSecond=utils.readintpacked(stream)
			bunch.Header=h
			packet.Bunches[#packet.Bunches+1]=bunch
		else
			h.isControl=stream:readBool()
			h.openOrClose=h.isControl
			h.isOpen=false; h.isClosed=false; h.isDormant=false
			if h.isControl then
				h.isOpen=stream:readBool()
				h.isClosed=stream:readBool()
				if h.isClosed then h.isDormant=stream:readBool() end
			end
			h.isReplicationPaused=stream:readBool()
			h.isReliable=stream:readBool()
			h.channelIndex=utils.readintwrapped(stream,consts.MAX_CHANNELS)
			h.hasPackageMapExports=stream:readBool()
			h.hasMustBeMappedGUIDs=stream:readBool()
			h.isPartial=stream:readBool()
			if h.isReliable then h.channelSequence=utils.readintwrapped(stream,consts.MAX_CHSEQUENCE)
			elseif h.isPartial then h.channelSequence=packet.PacketID end
			h.isPartialInit=false; h.isPartialFinal=false
			if h.isPartial then h.isPartialInit=stream:readBool(); h.isPartialFinal=stream:readBool() end

			local serializedType=nil
			if h.isReliable or h.isOpen then serializedType=utils.readintwrapped(stream,consts.CHTYPE_MAX) end
			if serializedType~=nil and serializedType~=0 then conn.channelTypes[h.channelIndex]=serializedType end
			h.channelType=serializedType or conn.channelTypes[h.channelIndex] or 0
			local chname=consts.CHANNEL_TYPES[h.channelType] or 'Invalid'
			h.HChannelTypeName=string.format('%01x %s',h.channelType,chname)
			h.numBits=utils.readintwrapped(stream,consts.MAX_PACKET_BITS)
			bunch.Header=h
			if h.numBits>stream:bitsLeft() then
				bunch.ParseError='Bunch payload exceeds remaining packet bits'
				h.numBits=stream:bitsLeft()
			end
			local rawPayload=stream:readSubstream(h.numBits)
			bunch.PayloadRaw=utils.streamHex(rawPayload)
			local payloadStream=trickle.create(rawPayload.str,rawPayload.bitlen)

			if h.hasPackageMapExports and payloadStream:bitsLeft()>0 then
				relite.actorHandler.readExports(relite,bunch.Payload,payloadStream)
				if payloadStream:isError() then bunch.Payload.ParseError=bunch.Payload.PackageMapExportError or 'PackageMap export decode overflow' end
			end
			if h.isPartial then processPartial(relite,bunch,payloadStream,h,packet,conn)
			else processDecoded(relite,bunch,payloadStream,h,packet) end
			packet.Bunches[#packet.Bunches+1]=bunch
			if h.isClosed then
				conn.channelTypes[h.channelIndex]=nil
				conn.partials.server[h.channelIndex]=nil
				conn.partials.client[h.channelIndex]=nil
			end
		end
		if stream:getPosBits()<=before then packet.ParseError='Parser made no progress'; break end
	end
	if guard>=1024 then packet.ParseError='Bunch guard reached' end
	packet.RemainingBits=stream:bitsLeft()
end

function packetHandler.readHandshakeBunch(relite,stream,packet)
	local utils=relite.utils
	local bunch={}
	local n=math.min(193,stream:bitsLeft())
	bunch.HSChallengeData=utils.readbitarray(stream,n)
	if stream:bitsLeft()>0 then bunch.HSTerminationBit=stream:readBool() end
	packet.Bunches[#packet.Bunches+1]=bunch
end

function packetHandler.readPacket(relite,stream,isServer,connectionKey)
	local packet={IsServer=isServer,Bunches={},ConnectionKey=connectionKey}
	relite.currentConnectionKey=connectionKey
	packet.IsHandshakePacket=stream:readBool()
	if packet.IsHandshakePacket then
		packetHandler.readHandshakeBunch(relite,stream,packet)
	else
		-- UE packets end with a single high termination bit followed by zero padding.
		local last=stream.str:byte(#stream.str) or 0
		if last~=0 then
			local high=0; local v=last
			while v>=2 do v=math.floor(v/2); high=high+1 end
			local logicalBits=(#stream.str-1)*8+high
			if logicalBits>=stream:getPosBits() then stream:setBitLength(logicalBits); packet.TerminationBit=true end
		end
		packetHandler.readNormalBunch(relite,stream,packet)
	end
	return packet
end

return packetHandler

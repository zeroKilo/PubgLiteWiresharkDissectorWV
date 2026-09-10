-- Small LSB-first bit reader/writer used by the UE4 packet parser.
local trickle={}
local Reader={}; Reader.__index=Reader
local Writer={}; Writer.__index=Writer

local function pow2(n) return 2^n end
local function lowbits(v,n)
	if n<=0 then return 0 end
	return v % pow2(n)
end

function trickle.create(str,bitlen)
	str=str or ''
	local max=#str*8
	if bitlen==nil or bitlen>max then bitlen=max end
	if bitlen<0 then bitlen=0 end
	return setmetatable({str=str,bitlen=bitlen,pos=0,error=false},Reader)
end

function Reader:getPosBits() return self.pos end
function Reader:bitsLeft() return math.max(0,self.bitlen-self.pos) end
function Reader:isError() return self.error end
function Reader:setBitLength(n)
	n=math.max(0,math.min(n,#self.str*8))
	self.bitlen=n
	if self.pos>n then self.pos=n; self.error=true end
	return self
end
function Reader:clone()
	return setmetatable({str=self.str,bitlen=self.bitlen,pos=self.pos,error=self.error},Reader)
end
function Reader:skipBits(n)
	if n<0 then self.error=true; return self end
	if n>self:bitsLeft() then self.pos=self.bitlen; self.error=true else self.pos=self.pos+n end
	return self
end
function Reader:readBits(n)
	n=math.floor(tonumber(n) or 0)
	if n<0 then self.error=true; return 0 end
	if n==0 then return 0 end
	local wanted=n
	if n>self:bitsLeft() then n=self:bitsLeft(); self.error=true end
	local value=0; local shift=0
	while n>0 do
		local byteIndex=math.floor(self.pos/8)+1
		local bitIndex=self.pos%8
		local take=math.min(n,8-bitIndex)
		local b=self.str:byte(byteIndex) or 0
		local part=math.floor(b/pow2(bitIndex)) % pow2(take)
		value=value+part*pow2(shift)
		self.pos=self.pos+take; shift=shift+take; n=n-take
	end
	-- Missing high bits are intentionally zero if an overflow happened.
	return value
end
function Reader:readBool() return self:readBits(1)~=0 end
function Reader:read(kind)
	if kind=='bool' then return self:readBool() end
	local n=type(kind)=='string' and tonumber(kind:match('(%d+)bit')) or nil
	if n then return self:readBits(n) end
	self.error=true; return nil
end
function Reader:readSubstream(n)
	n=math.floor(tonumber(n) or 0)
	if n<0 then self.error=true; return trickle.create('',0) end
	if n>self:bitsLeft() then n=self:bitsLeft(); self.error=true end
	local w=trickle.createWriter()
	local left=n
	while left>0 do
		local take=math.min(left,24)
		w:writeBits(self:readBits(take),take)
		left=left-take
	end
	return w:toReader()
end

function trickle.createWriter()
	return setmetatable({bytes={},byte=0,byteLen=0,bitlen=0},Writer)
end
function Writer:getNumBits() return self.bitlen end
function Writer:writeBits(v,n)
	n=math.floor(tonumber(n) or 0); v=tonumber(v) or 0
	local consumed=0
	while consumed<n do
		local take=math.min(n-consumed,8-self.byteLen)
		local part=lowbits(math.floor(v/pow2(consumed)),take)
		self.byte=self.byte+part*pow2(self.byteLen)
		self.byteLen=self.byteLen+take; self.bitlen=self.bitlen+take; consumed=consumed+take
		if self.byteLen==8 then self.bytes[#self.bytes+1]=string.char(self.byte); self.byte=0; self.byteLen=0 end
	end
	return self
end
function Writer:writeBool(v) return self:writeBits(v and 1 or 0,1) end
function Writer:toString()
	local s=table.concat(self.bytes)
	if self.byteLen>0 then s=s..string.char(self.byte) end
	return s
end
function Writer:truncate() return self:toString() end
function Writer:toReader() return trickle.create(self:toString(),self.bitlen) end

return trickle

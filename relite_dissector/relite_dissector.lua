local source=(debug.getinfo(1,'S') or {}).source or ''
local root='.'
if source:sub(1,1)=='@' then root=source:sub(2):match('^(.*)[/\\][^/\\]+$') or '.' end
package.path=table.concat({
	root..'/src/?.lua',
	root..'/src/handler/?.lua',
	root..'/src/handler/actors/?.lua',
	root..'/src/treemaker/?.lua',
	root..'/src/treemaker/actors/?.lua',
	package.path
},';')

local trickle=require 'trickle'
local relite=require 'relite'
local proto=relite.const.proto

function proto.init() relite.resetState() end

function proto.dissector(buffer,pinfo,tree)
	if tree==nil then return end
	pinfo.cols.protocol='relite'
	local packetNumber=tonumber(pinfo.number)
	local key=relite.connectionKey(pinfo.src,pinfo.src_port,pinfo.dst,pinfo.dst_port)
	local cacheKey=key..'#'..tostring(packetNumber)
	local packet=relite.processedPackets[cacheKey]
	if not packet then
		local stream=trickle.create(buffer:raw())
		local isServer=tonumber(pinfo.src_port)==7777
		packet=relite.packetHandler.readPacket(relite,stream,isServer,key)
		relite.processedPackets[cacheKey]=packet
	end
	local node=tree:add(proto,buffer(),'PUBG Lite / UE4 Network Data')
	relite.treeMaker.makeTree(relite,buffer,packet,node)
end

local udp_table=DissectorTable.get('udp.port')
udp_table:add(7777,proto)

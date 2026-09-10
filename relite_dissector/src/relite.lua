local relite = {}

relite.const = require 'relite_const'
relite.utils = require 'relite_utils'
relite.netDefines = require 'relite_net_defines'
relite.packetHandler = require 'relite_packet_handler'
relite.actorHandler = require 'relite_actor_handler'
relite.controlHandler = require 'relite_control_handler'
relite.treeMaker = require 'relite_tree_maker'
relite.actorMaker = require 'relite_actor_maker'
relite.controlMaker = require 'relite_control_maker'

relite.processedPackets = {}
relite.connections = {}
relite.currentConnectionKey = nil
relite.logPath = 'relite.log'
relite.logEnabled = false

function relite.connectionKey(a,aport,b,bport)
	local x=tostring(a)..':'..tostring(aport)
	local y=tostring(b)..':'..tostring(bport)
	if x>y then x,y=y,x end
	return x..' <-> '..y
end

function relite.getConnectionState(key)
	key=key or relite.currentConnectionKey or 'default'
	local state=relite.connections[key]
	if not state then
		state={channels={},channelTypes={},guidCache={},partials={server={},client={}},netFieldExportGroupsByIndex={},netFieldExportGroupsByPath={}}
		relite.connections[key]=state
	end
	return state
end

function relite.resetState()
	relite.processedPackets={}
	relite.connections={}
	relite.currentConnectionKey=nil
	if relite.logEnabled then pcall(os.remove,relite.logPath) end
end

function relite.print(fmt)
	if not relite.logEnabled then return end
	local f=io.open(relite.logPath,'a')
	if not f then return end
	f:write(tostring(fmt),'\n')
	f:close()
end

relite.resetState()
return relite

-- Generated class parser scaffold from recovered NetField metadata.
local handler={ClassName="STExtraPlayerController",ClassPath="/Script/ShadowTrackerExtra.STExtraPlayerController",SuperClass="UAEPlayerController"}
function handler.getNetFields(relite)
	return relite.netDefines.getNetFieldMap(handler.ClassName)
end
function handler.readNetField(relite,stream)
	return relite.utils.readNetField(relite,stream,handler.ClassName)
end
function handler.parsePayload(relite,stream,context)
	context=context or {}
	context.ClassName=handler.ClassName
	return relite.utils.readRecoveredClassPayload(relite,stream,context,handler.ClassName)
end

-- STExtraPlayerController has an additional game-specific new-actor tail after UE's generic actor identity.
function handler.serializeNewActor(relite,stream,context)
	local result={}
	if stream:bitsLeft()<=0 then return result end
	local probe=stream:clone()
	local version=relite.utils.readstring(probe)
	if probe:isError() then return result end
	result.NetPlayerVersion=version
	if probe:bitsLeft()>=8 then result.NetPlayerIndex=probe:readBits(8) end
	stream.pos=probe.pos
	return result
end
return handler

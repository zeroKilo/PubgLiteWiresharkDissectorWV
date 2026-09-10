-- Generated class parser scaffold from recovered NetField metadata.
local handler={ClassName="PointLightComponent",ClassPath="/Script/Engine.PointLightComponent",SuperClass="LightComponent"}
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
return handler

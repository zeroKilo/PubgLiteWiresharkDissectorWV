-- Generated class tree-maker scaffold from recovered NetField metadata.
local maker={ClassName="STExtraVehicleBase",ClassPath="/Script/ShadowTrackerExtra.STExtraVehicleBase",SuperClass="Pawn"}
function maker.makePayload(relite,r,parsed,root,context)
	return relite.actorMaker.makeRecoveredClassPayload(relite,r,parsed,root,maker.ClassName,context)
end
function maker.makeNewActor(relite,r,payload,root)
	return relite.actorMaker.makeRecoveredNewActor(relite,r,payload,root,maker.ClassName)
end
return maker

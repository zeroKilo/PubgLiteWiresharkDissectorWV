-- Generated class tree-maker scaffold from recovered NetField metadata.
local maker={ClassName="TirggerItem_TriggerBox",ClassPath="/Script/ShadowTrackerExtra.TirggerItem_TriggerBox",SuperClass="TriggerBox"}
function maker.makePayload(relite,r,parsed,root,context)
	return relite.actorMaker.makeRecoveredClassPayload(relite,r,parsed,root,maker.ClassName,context)
end
function maker.makeNewActor(relite,r,payload,root)
	return relite.actorMaker.makeRecoveredNewActor(relite,r,payload,root,maker.ClassName)
end
return maker

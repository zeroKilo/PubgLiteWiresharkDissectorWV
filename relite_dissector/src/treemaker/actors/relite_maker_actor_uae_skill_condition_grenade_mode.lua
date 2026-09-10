-- Generated class tree-maker scaffold from recovered NetField metadata.
local maker={ClassName="UAESkillCondition_GrenadeMode",ClassPath="/Script/ShadowTrackerExtra.UAESkillCondition_GrenadeMode",SuperClass="UAESkillCondition"}
function maker.makePayload(relite,r,parsed,root,context)
	return relite.actorMaker.makeRecoveredClassPayload(relite,r,parsed,root,maker.ClassName,context)
end
function maker.makeNewActor(relite,r,payload,root)
	return relite.actorMaker.makeRecoveredNewActor(relite,r,payload,root,maker.ClassName)
end
return maker

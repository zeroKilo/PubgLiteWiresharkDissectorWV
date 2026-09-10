-- Generated class tree-maker scaffold from recovered NetField metadata.
local maker={ClassName="WrapperOverlapManagerComponent",ClassPath="/Script/ShadowTrackerExtra.WrapperOverlapManagerComponent",SuperClass="BoxComponent"}
function maker.makePayload(relite,r,parsed,root,context)
	return relite.actorMaker.makeRecoveredClassPayload(relite,r,parsed,root,maker.ClassName,context)
end
function maker.makeNewActor(relite,r,payload,root)
	return relite.actorMaker.makeRecoveredNewActor(relite,r,payload,root,maker.ClassName)
end
return maker

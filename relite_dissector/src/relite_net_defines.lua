local net_defines={}
local generated=require 'relite_generated_net_fields'

net_defines.generated=generated

-- Known RepLayout wire-handle evidence. These handles are intentionally not generated
-- from reflection RepIndex: the two number spaces are different.
net_defines.layout_Default__BP_STExtraPlayerControllerPC_C={
	[4]={Type='UByteProperty',Size=2,Name='RemoteRole'},
	[17]={Type='UObjectProperty',Size=0,Name='PlayerState'},
	[25]={Type='UEnumProperty',Size=1,Name='DefaultCharacterGender'},
	[26]={Type='TArrayProperty',Size=0,Name='InitialItemList',SubType='FGameModePlayerItem'},
	[34]={Type='UBoolProperty',Size=1,Name='bIsTrainingMode'},
	[38]={Type='UBoolProperty',Size=1,Name='bIsAutoAimEnabled'},
	[48]={Type='UObjectProperty',Size=0,Name='BackpackComponent'},
}
net_defines.layout_FGameModePlayerItem={
	[1]={Type='Int32',Size=32,Name='ItemTableID'},
	[2]={Type='Int32',Size=32,Name='Count'},
}
net_defines.layout_FViewTargetTransitionParams={
	[1]={Type='Float',Size=32,Name='BlendTime'},
	[2]={Type='Byte',Size=8,Name='BlendFunction'},
	[3]={Type='Float',Size=32,Name='BlendExp'},
}
net_defines.layout_FVector={
	[1]={Type='Float',Size=32,Name='X'},[2]={Type='Float',Size=32,Name='Y'},[3]={Type='Float',Size=32,Name='Z'},
}
net_defines.layout_FRotator={
	[1]={Type='Float',Size=32,Name='Pitch'},[2]={Type='Float',Size=32,Name='Yaw'},[3]={Type='Float',Size=32,Name='Roll'},
}
net_defines.REP_LAYOUT_DICT={
	Default__BP_STExtraPlayerControllerPC_C=net_defines.layout_Default__BP_STExtraPlayerControllerPC_C,
	BP_STExtraPlayerControllerPC_C=net_defines.layout_Default__BP_STExtraPlayerControllerPC_C,
	STExtraPlayerController=net_defines.layout_Default__BP_STExtraPlayerControllerPC_C,
	FGameModePlayerItem=net_defines.layout_FGameModePlayerItem,
	FViewTargetTransitionParams=net_defines.layout_FViewTargetTransitionParams,
	FVector=net_defines.layout_FVector,
	FRotator=net_defines.layout_FRotator,
}

local aliases={
	Default__BP_STExtraPlayerControllerPC_C='STExtraPlayerController',
	BP_STExtraPlayerControllerPC_C='STExtraPlayerController',
}
local effective={}
local function shortName(s)
	if not s then return nil end
	local x=tostring(s):gsub('^Default__','')
	x=x:match('([^/]+)$') or x
	x=x:match('([^%.]+)$') or x
	return x
end

function net_defines.resolveClassName(name)
	if not name then return nil end
	if generated.paths[name] then return generated.paths[name].name end
	if generated.classes[name] then return name end
	local s=shortName(name)
	if aliases[s] then return aliases[s] end
	if generated.classes[s] then return s end
	local base=s and s:gsub('_C$','') or nil
	if aliases[base] then return aliases[base] end
	if generated.classes[base] then return base end
	local best=nil
	if s then
		for cname,_ in pairs(generated.classes) do
			if #cname>=5 and s:find(cname,1,true) and (not best or #cname>#best) then best=cname end
		end
	end
	return best
end

local function buildEffective(cname,seen)
	if effective[cname] then return effective[cname] end
	seen=seen or {}; if seen[cname] then return {} end; seen[cname]=true
	local c=generated.classes[cname]
	if not c then return {} end
	local map={}
	if c.super and c.super~='' then
		for k,v in pairs(buildEffective(c.super,seen)) do map[k]=v end
	end
	for k,v in pairs(c.fields) do map[k]=v end
	effective[cname]=map
	return map
end

function net_defines.getClass(name)
	local n=net_defines.resolveClassName(name)
	return n and generated.classes[n] or nil
end
function net_defines.getNetFieldMap(name)
	local n=net_defines.resolveClassName(name)
	return n and buildEffective(n) or nil
end
function net_defines.getNetField(name,index)
	local m=net_defines.getNetFieldMap(name)
	return m and m[index] or nil
end
function net_defines.getRepLayout(name)
	if not name then return nil end
	return net_defines.REP_LAYOUT_DICT[name] or net_defines.REP_LAYOUT_DICT[shortName(name)] or net_defines.REP_LAYOUT_DICT[net_defines.resolveClassName(name)]
end

-- Compatibility dictionary for older callers, now populated from the recovered metadata.
net_defines.NET_FIELD_DICT={}
for cname,_ in pairs(generated.classes) do net_defines.NET_FIELD_DICT[cname]=buildEffective(cname) end
net_defines.NET_FIELD_DICT.Default__BP_STExtraPlayerControllerPC_C=buildEffective('STExtraPlayerController')
net_defines.NET_FIELD_DICT.BP_STExtraPlayerControllerPC_C=buildEffective('STExtraPlayerController')

return net_defines

local const = {}

const.MAX_PACKETID = 16384
const.MAX_CHANNELS = 10240
const.MAX_CHSEQUENCE = 4096
const.MAX_PACKET_BITS = 4096
const.CHTYPE_MAX = 8

const.MSG_NAMES = {
	[0]="NMT_Hello",[1]="NMT_Welcome",[2]="NMT_Upgrade",[3]="NMT_Challenge",[4]="NMT_Netspeed",[5]="NMT_Login",
	[6]="NMT_Failure",[9]="NMT_Join",[10]="NMT_JoinSplit",[12]="NMT_Skip",[13]="NMT_Abort",[15]="NMT_PCSwap",
	[16]="NMT_ActorChannelFailure",[17]="NMT_DebugText",[18]="NMT_NetGUIDAssign",[19]="NMT_SecurityViolation",
	[20]="NMT_GameSpecific",[21]="NMT_EncryptionAck",[25]="NMT_BeaconWelcome",[26]="NMT_BeaconJoin",
	[27]="NMT_BeaconAssignGUID",[28]="NMT_BeaconNetGUIDAck"
}

const.CHANNEL_TYPES = {
	[0] = "Invalid",
	[1] = "Connection Control",
	[2] = "Actor Updates",
	[3] = "Binary File Transfer",
	[4] = "VoIP Data"
}

const.FIELDS = {
	NumPayloadBits							= ProtoField.uint32	("relite.numpayloadbits",					"Num Payload Bits", base.HEX),
	PayloadRaw								= ProtoField.string	("relite.payloadraw", 						"Payload Raw"),
	IsServer 								= ProtoField.bool	("relite.isserver", 						"Is Server"),
	Bunch		 							= ProtoField.none	("relite.bunch", 							"Bunch"),
	-- Handshake stuff			
	IsHandshake 							= ProtoField.bool	("relite.ishandshake", 						"Is Handshake"),
	HandshakeData 							= ProtoField.none	("relite.handshake", 						"Handshake Data"),
	HSChallengeData 						= ProtoField.string	("relite.handshake.challengedata", 			"Challenge Data"),
	HSTerminationBit 						= ProtoField.bool	("relite.handshake.terminationbit",			"Termination Bit"),
	-- Bunch Header			
	Header		 							= ProtoField.none	("relite.header", 							"Header"),
	HClientID		 						= ProtoField.uint32	("relite.header.clientid", 					"Client ID", base.HEX),
	HEncryptionEnabled						= ProtoField.bool	("relite.header.encryptionenabled",			"Encryption enabled"),
	HOutPacketID							= ProtoField.uint32	("relite.header.outpacketid",				"Out Packet ID", base.HEX),
	HIsAck									= ProtoField.bool	("relite.header.isack",						"Is ACK"),
	HAckPacketID							= ProtoField.uint32	("relite.header.ackpacketid",				"ACK Packet ID", base.HEX),
	HHasServerFrameTime						= ProtoField.bool	("relite.header.hasserverframetime",		"Has Server Frame Time"),
	HServerFrameTime						= ProtoField.uint32	("relite.header.serverframetime",			"Server Frame Time"),
	HInKBytesPerSecond						= ProtoField.uint32	("relite.header.inkbytespersecond",			"In KBytes Per Second", base.HEX),
	HSizeInBits								= ProtoField.uint32	("relite.header.sizeinbits",				"Size In Bits", base.HEX),
	HOpenOrClose							= ProtoField.bool	("relite.header.openorclose",				"Open Or Close"),
	HIsOpen									= ProtoField.bool	("relite.header.isopen",					"Is Open"),
	HIsClosed								= ProtoField.bool	("relite.header.isclosed",					"Is Closed"),
	HIsDormant								= ProtoField.bool	("relite.header.isdormant",					"Is Dormant"),
	HIsReplicationPaused					= ProtoField.bool	("relite.header.isreplicationpaused",		"Is Replication Paused"),
	HIsReliable								= ProtoField.bool	("relite.header.isreliable",				"Is Reliable"),
	HChannelIndex							= ProtoField.uint32	("relite.header.channelindex",				"Channel Index", base.HEX),
	HHasPackageMapExports					= ProtoField.bool	("relite.header.haspackagemapexports",		"Has Package Map Exports"),
	HHasMustBeMappedGUIDs					= ProtoField.bool	("relite.header.hasmustbemappedguids",		"Has Must-Be Mapped GUIDs"),
	HIsPartial								= ProtoField.bool	("relite.header.ispartial",					"Is Partial"),
	HChannelSequence						= ProtoField.uint32	("relite.header.channelsequence",			"Channel Sequence", base.HEX),
	HIsPartialInitial						= ProtoField.bool	("relite.header.ispartialinitial",			"Is Partial Initial"),
	HIsPartialFinal							= ProtoField.bool	("relite.header.ispartialfinal",			"Is Partial Final"),
	HChannelType							= ProtoField.string	("relite.header.channeltype",				"Channel Type"),
	HNumBits								= ProtoField.uint32	("relite.header.numbits",					"Number of Bits", base.HEX),
	-- Bunch Payload			
	Payload									= ProtoField.none	("relite.payload",							"Payload"),
	PMsgID									= ProtoField.string	("relite.payload.msgid",					"Msg ID"),
	ControlMessage                          = ProtoField.none    ("relite.controlmessage",                   "Control Message"),
	ControlDetail                           = ProtoField.string  ("relite.control.detail",                  "Detail"),
	-- Net Message Type			
	NMT0A									= ProtoField.uint32	("relite.nmt0.a",							"A", base.HEX),
	NMT0B									= ProtoField.uint32	("relite.nmt0.b",							"B", base.HEX),
	NMT0C									= ProtoField.uint32	("relite.nmt0.c",							"C", base.HEX),
	NMT0D									= ProtoField.uint32	("relite.nmt0.d",							"D", base.HEX),
	NMT0Endianess							= ProtoField.uint32	("relite.nmt0.endianess",					"Endianess", base.HEX),
	NMT0NetworkVersion						= ProtoField.uint32	("relite.nmt0.networkversion",				"Network Version", base.HEX),
	NMT0EncryptionToken						= ProtoField.string	("relite.nmt0.encryptiontoken",				"Encryption Token"),
	NMT1MapURL								= ProtoField.string	("relite.nmt1.mapurl",						"Map URL"),
	NMT1GameName							= ProtoField.string	("relite.nmt1.gamename",					"Game Name"),
	NMT1RedirectURL							= ProtoField.string	("relite.nmt1.redirecturl",					"Redirect URL"),
	NMT3Challenge							= ProtoField.string	("relite.nmt3.challenge",					"Challenge"),
	NMT4NetSpeed							= ProtoField.uint32	("relite.nmt4.netspeed",					"Net Speed", base.HEX),
	NMT5ClientResponse						= ProtoField.string	("relite.nmt5.clientresponse",				"Client Response"),
	NMT5RequestUrlBytes						= ProtoField.string	("relite.nmt5.requesturlbytes",				"Request Url Bytes"),
	NMT5UIDSize								= ProtoField.uint32	("relite.nmt5.uidsize",						"User ID Size", base.HEX),
	NMT5UIDContent							= ProtoField.string	("relite.nmt5.uidcontent",					"User ID Content"),
	NMT5OnlinePlatformName					= ProtoField.string	("relite.nmt5.onlineplatformname",			"Online Platform Name"),
	-- Actor Setup			
	ActSetup								= ProtoField.none	("relite.actsetup",							"Actor Setup"),
	ActSetupHasRepLayoutExport				= ProtoField.bool	("relite.actsetup.hasreplayoutexport",		"Has Replication Layout exported"),
	ActSetupExportNetGUIDsCount				= ProtoField.uint32	("relite.actsetup.exportnetguidscount",		"Exported NetGUIDs Count"),
	ActSetupNumMustBeMappedGUIDs			= ProtoField.uint32	("relite.actsetup.nummustbemappedguids",	"Must Be Mapped NetGUIDs Count"),
	-- Actor Update	
	ActUpdate								= ProtoField.none	("relite.actupdate",						"Actor Update"),
	ActUpdateHasRepLayoutExport				= ProtoField.bool	("relite.actupdate.hasreplayoutexport",		"Has Replication Layout exported"),
	ActUpdateExportNetGUIDsCount			= ProtoField.uint32	("relite.actupdate.exportnetguidscount",	"Exported NetGUIDs Count"),
	ActUpdateNumMustBeMappedGUIDs			= ProtoField.uint32	("relite.actupdate.nummustbemappedguids",	"Must Be Mapped NetGUIDs Count"),
	-- Net GUIDs			
	GUID									= ProtoField.uint32	("relite.guid",								"GUID", base.HEX),
	NetGUID									= ProtoField.none	("relite.netguid",							"Net GUID"),
	NetGUIDHasPath							= ProtoField.bool	("relite.netguidhaspath",					"Has Path"),
	NetGUIDNoLoad							= ProtoField.bool	("relite.netguidnoload",					"No load"),
	NetGUIDHasNetworkChecksum				= ProtoField.bool	("relite.netguidhasnetworkchecksum",		"Has Network Checksum"),
	NetGUIDPath								= ProtoField.string	("relite.netguidpath",						"Path"),
	NetGUIDChecksum							= ProtoField.uint32	("relite.netguidchecksum",					"Checksum", base.HEX),
	-- Actor 			
	Actor									= ProtoField.string	("relite.actor",							"Actor"),
	ActorNetGuid                            = ProtoField.uint32  ("relite.actor.netguid",                     "Actor NetGUID", base.HEX),
	ActorArchetypeGuid                      = ProtoField.uint32  ("relite.actor.archetypeguid",               "Actor Archetype NetGUID", base.HEX),
	ActorResolvedClass                      = ProtoField.string  ("relite.actor.class",                       "Resolved Actor Class"),
	ActorSerializeLocation                  = ProtoField.bool    ("relite.actor.serializelocation",           "Serialize Location"),
	ActorSerializeRotation                  = ProtoField.bool    ("relite.actor.serializerotation",           "Serialize Rotation"),
	ActorSerializeScale                     = ProtoField.bool    ("relite.actor.serializescale",              "Serialize Scale"),
	ActorSerializeVelocity                  = ProtoField.bool    ("relite.actor.serializevelocity",           "Serialize Velocity"),
	ActorLocation                           = ProtoField.string  ("relite.actor.location",                    "Location"),
	ActorRotation                           = ProtoField.string  ("relite.actor.rotation",                    "Rotation"),
	ActorScale                              = ProtoField.string  ("relite.actor.scale",                       "Scale"),
	ActorVelocity                           = ProtoField.string  ("relite.actor.velocity",                    "Velocity"),
	ActorHandlerClass                       = ProtoField.string  ("relite.actor.handlerclass",                "Actor Handler Class"),
	STEPlayerControllerActorGuid			= ProtoField.uint32	("relite.stepc.actorguid",					"Actor GUID", base.HEX),
	STEPlayerControllerArchetypeGuid		= ProtoField.uint32	("relite.stepc.archetypeguid",				"Archetype GUID", base.HEX),
	STEPlayerControllerSerializeLocation	= ProtoField.bool	("relite.stepc.serializelocation",			"Serialize Location"),
	STEPlayerControllerSerializeRotation	= ProtoField.bool	("relite.stepc.serializerotation",			"Serialize Rotation"),
	STEPlayerControllerSerializeScale		= ProtoField.bool	("relite.stepc.serializescale",				"Serialize Scale"),
	STEPlayerControllerSerializeVelocity	= ProtoField.bool	("relite.stepc.serializevelocity",			"Serialize Velocity"),
	STEPlayerControllerNetPlayerVersion		= ProtoField.string	("relite.stepc.netplayerversion",			"Netplayer Version"),
	STEPlayerControllerNetPlayerIndex		= ProtoField.uint32	("relite.stepc.netplayerindex",				"Netplayer Index", base.HEX),
	-- Content Block Payload	
	ContentBlockPayload						= ProtoField.none	("relite.contentblockpayload",				"Content Block Payload"),
	ContentBlockPayloadHasRepLayout			= ProtoField.bool	("relite.cbp.hasreplayout",					"Has Replication Layout"),
	ContentBlockPayloadIsActor				= ProtoField.bool	("relite.cbp.isactor",						"Is Actor"),
	ContentBlockPayloadNumPayloadBits		= ProtoField.uint32	("relite.cbp.numpayloadbits",				"Num Payload Bits", base.HEX),
	RepPropertiesDoChecksum					= ProtoField.bool	("relite.repprop.dochecksum",				"Do Checksum"),
	RepPropertiesProperties					= ProtoField.none	("relite.repprop.properties",				"Replicated Properties"),
	Property								= ProtoField.string	("relite.property",							"Property"),
	NetFieldIndex							= ProtoField.uint32	("relite.netfieldindex",					"Net Field Index", base.HEX),
	RpcCall									= ProtoField.string	("relite.rpccall",							"RPC Call"),
	ConnectionKey                           = ProtoField.string  ("relite.connection",                       "Connection"),
	ParseError                              = ProtoField.string  ("relite.error",                            "Parse Error"),
	PartialStatus                           = ProtoField.string  ("relite.partialstatus",                    "Partial Status"),
	RemainingBits                           = ProtoField.uint32  ("relite.remainingbits",                    "Remaining Bits", base.DEC),
	ChannelObject                           = ProtoField.string  ("relite.channelobject",                    "Channel Object / Class"),
	NetFieldKind                            = ProtoField.string  ("relite.netfieldkind",                     "Net Field Kind"),
	NetFieldPath                            = ProtoField.string  ("relite.netfieldpath",                     "Net Field Path"),
	RpcSignature                            = ProtoField.string  ("relite.rpcsignature",                     "RPC Signature"),
	RpcDirection                            = ProtoField.string  ("relite.rpcdirection",                     "RPC Direction"),
	RpcReliable                             = ProtoField.bool    ("relite.rpcreliable",                      "RPC Reliable"),
	RpcValidate                             = ProtoField.bool    ("relite.rpcvalidate",                      "RPC Validate"),
	RpcFlags                                = ProtoField.string  ("relite.rpcflags",                         "RPC Flags"),
	RpcWrapperRva                           = ProtoField.string  ("relite.rpcwrapperrva",                    "Recovered Wrapper RVA"),
	PropertyInfo                            = ProtoField.string  ("relite.propertyinfo",                     "Property Metadata"),
	PropertyRepIndex                        = ProtoField.uint32  ("relite.property.repindex",                "Property RepIndex", base.DEC),
	PropertyRepCondition                    = ProtoField.string  ("relite.property.repcondition",            "Replication Condition"),
	PropertyRepNotify                       = ProtoField.string  ("relite.property.repnotify",               "RepNotify Function"),
	PackageMapExportRaw                     = ProtoField.string  ("relite.packagemap.exportraw",             "PackageMap Export Raw"),
	NetFieldExportGroup                     = ProtoField.none    ("relite.netfieldexport.group",              "NetField Export Group"),
	NetFieldExportCount                     = ProtoField.uint32  ("relite.netfieldexport.count",              "NetField Export Count", base.DEC),
	NetFieldExportPathIndex                 = ProtoField.uint32  ("relite.netfieldexport.pathindex",          "Path Name Index", base.DEC),
	NetFieldExportIsNewGroup                = ProtoField.bool    ("relite.netfieldexport.isnewgroup",         "Is New Group"),
	NetFieldExportPath                      = ProtoField.string  ("relite.netfieldexport.path",               "Group Path"),
	NetFieldExportNumExports                = ProtoField.uint32  ("relite.netfieldexport.numexports",         "Group Field Count", base.DEC),
	NetFieldExportIsExported                = ProtoField.bool    ("relite.netfieldexport.isexported",         "Field Is Exported"),
	NetFieldExportHandle                    = ProtoField.uint32  ("relite.netfieldexport.handle",             "Field Handle", base.DEC),
	NetFieldExportChecksum                  = ProtoField.uint32  ("relite.netfieldexport.checksum",           "Compatible Checksum", base.HEX),
	NetFieldExportName                      = ProtoField.string  ("relite.netfieldexport.name",               "Field Name"),
	NetFieldExportType                      = ProtoField.string  ("relite.netfieldexport.type",               "Field Type"),
	NetGUIDResolvedPath                     = ProtoField.string  ("relite.netguidresolvedpath",              "Resolved NetGUID Path"),
}

-- Actor-specific Wireshark fields are generated here from the recovered reflection/NetField metadata.
-- This keeps ProtoField ownership centralized even though parsing/rendering is split into per-class modules.
const.ACTOR_FIELDS={}
const.ACTOR_FIELDS_BY_PATH={}
const.ACTOR_VALUE_FIELDS={}
const.ACTOR_VALUE_FIELDS_BY_PATH={}
const.ACTOR_RPC_PARAM_FIELDS={}
local generatedActorFields=require 'relite_generated_net_fields'
local function fieldSlug(v)
	return tostring(v or ''):gsub('[^%w]+','_'):gsub('^_+',''):gsub('_+$',''):lower()
end
local function actorValueField(abbrev,label,fieldType,valueType)
	local t=tostring(fieldType or '')
	if t=='BoolProperty' then return ProtoField.bool(abbrev,label)
	elseif t=='IntProperty' then return ProtoField.int32(abbrev,label,base.DEC)
	elseif t=='UInt32Property' then return ProtoField.uint32(abbrev,label,base.DEC)
	elseif t=='FloatProperty' then return ProtoField.float(abbrev,label)
	elseif t=='ByteProperty' then return ProtoField.uint8(abbrev,label,base.DEC)
	elseif t=='EnumProperty' then return ProtoField.uint32(abbrev,label,base.DEC)
	else return ProtoField.string(abbrev,label) end
end
local function rpcParamField(abbrev,label,paramType)
	local t=tostring(paramType or ''):gsub('const%s+',''):gsub('[%*&]',''):gsub('%s+','')
	if t=='bool' then return ProtoField.bool(abbrev,label)
	elseif t=='int8_t' or t=='int8' then return ProtoField.int8(abbrev,label,base.DEC)
	elseif t=='uint8_t' or t=='uint8' then return ProtoField.uint8(abbrev,label,base.DEC)
	elseif t=='int16_t' or t=='int16' then return ProtoField.int16(abbrev,label,base.DEC)
	elseif t=='uint16_t' or t=='uint16' then return ProtoField.uint16(abbrev,label,base.DEC)
	elseif t=='int32_t' or t=='int32' or t=='int' then return ProtoField.int32(abbrev,label,base.DEC)
	elseif t=='uint32_t' or t=='uint32' then return ProtoField.uint32(abbrev,label,base.DEC)
	elseif t=='int64_t' or t=='int64' then return ProtoField.int64(abbrev,label,base.DEC)
	elseif t=='uint64_t' or t=='uint64' then return ProtoField.uint64(abbrev,label,base.DEC)
	elseif t=='float' then return ProtoField.float(abbrev,label)
	elseif t=='double' then return ProtoField.double(abbrev,label)
	else return ProtoField.string(abbrev,label) end
end
local actorRegistered={}
local classNames={}
for cname,_ in pairs(generatedActorFields.classes) do classNames[#classNames+1]=cname end
table.sort(classNames)
for _,cname in ipairs(classNames) do
	local c=generatedActorFields.classes[cname]
	const.ACTOR_FIELDS[cname]={}; const.ACTOR_VALUE_FIELDS[cname]={}; const.ACTOR_RPC_PARAM_FIELDS[cname]={}
	local indices={}; for idx,_ in pairs(c.fields or {}) do indices[#indices+1]=idx end; table.sort(indices)
	for _,idx in ipairs(indices) do
		local info=c.fields[idx]
		local stem='relite.actor.'..fieldSlug(cname)..'.'..fieldSlug(info.name)
		local label=cname..'.'..tostring(info.name or ('Field '..tostring(idx)))
		local node=ProtoField.none(stem,label)
		const.ACTOR_FIELDS[cname][idx]=node; const.ACTOR_FIELDS_BY_PATH[info.path]=node; actorRegistered[#actorRegistered+1]=node
		if info.kind=='Property' then
			local value=actorValueField(stem..'.value',label..' Value',info.fieldType,info.valueType)
			const.ACTOR_VALUE_FIELDS[cname][idx]=value; const.ACTOR_VALUE_FIELDS_BY_PATH[info.path]=value; actorRegistered[#actorRegistered+1]=value
		elseif info.kind=='RPC' then
			local params={}
			for pi,param in ipairs(info.params or {}) do
				local pname=(param.name and param.name~='') and param.name or ('arg'..tostring(pi))
				local pf=rpcParamField(stem..'.arg'..tostring(pi)..'_'..fieldSlug(pname),label..' '..pname,param.type)
				params[pi]=pf; if params[pname]==nil then params[pname]=pf end; actorRegistered[#actorRegistered+1]=pf
			end
			const.ACTOR_RPC_PARAM_FIELDS[cname][idx]=params
		end
	end
end
function const.getActorField(info)
	if not info then return nil end
	if info.path and const.ACTOR_FIELDS_BY_PATH[info.path] then return const.ACTOR_FIELDS_BY_PATH[info.path] end
	local c=info.declaringClass and const.ACTOR_FIELDS[info.declaringClass] or nil
	return c and c[info.netIndex] or nil
end
function const.getActorValueField(info)
	if not info then return nil end
	if info.path and const.ACTOR_VALUE_FIELDS_BY_PATH[info.path] then return const.ACTOR_VALUE_FIELDS_BY_PATH[info.path] end
	local c=info.declaringClass and const.ACTOR_VALUE_FIELDS[info.declaringClass] or nil
	return c and c[info.netIndex] or nil
end

const.proto = Proto("relite", "Relite Protocol for PUBG Lite")
local registered={}
for _,field in pairs(const.FIELDS) do registered[#registered+1]=field end
for _,field in ipairs(actorRegistered) do registered[#registered+1]=field end
const.proto.fields=registered
return const

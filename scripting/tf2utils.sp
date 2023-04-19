/**
 * TF2 Utils Shared Plugin
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <sdkhooks>
#include <tf2_stocks>

#include <stocksoup/convars>
#include <stocksoup/functions>
#include <stocksoup/memory>

#define PLUGIN_VERSION "1.3.2"
public Plugin myinfo = {
	name = "TF2 Utils",
	author = "nosoop",
	description = "A plugin utility library for Team Fortress 2.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFUtils"
}

Handle g_SDKCallUpdatePlayerSpeed;
bool g_bDeferredSpeedUpdate[MAXPLAYERS + 1];

Handle g_SDKCallPlayerGetMaxAmmo;
Handle g_SDKCallPlayerTakeHealth;
Handle g_SDKCallPlayerGetShootPosition;
Handle g_SDKCallPlayerGetEntityForLoadoutSlot;
Handle g_SDKCallPlayerWeaponSwitch;

Handle g_SDKCallEntityGetMaxHealth;
Handle g_SDKCallPlayerSharedGetMaxHealth;

Handle g_SDKCallIsEntityWeapon;
Handle g_SDKCallWeaponGetSlot;
Handle g_SDKCallWeaponGetID;
Handle g_SDKCallWeaponGetMaxClip;
Handle g_SDKCallWeaponCanAttack;

Handle g_SDKCallIsEntityWearable;
Handle g_SDKCallPlayerEquipWearable;

Handle g_SDKCallPointInRespawnRoom;
Handle g_SDKCallPlayerSharedImmuneToPushback;
Handle g_SDKCallPlayerSharedBurn;
Handle g_SDKCallPlayerSharedMakeBleed;

Address offs_ConditionNames;
Address offs_CTFPlayer_aObjects;
Address offs_CTFPlayer_aHealers;
any offs_CTFPlayer_flRespawnTimeOverride;
any offs_CTFPlayer_flLastDamageTime;

float g_flRespawnTimeOverride[MAXPLAYERS + 1] = { -1.0, ... };

Address offs_CTFPlayer_hMyWearables;

Address offs_CTFPlayerShared_flBurnDuration;
Address offs_CTFPlayerShared_BleedList;
Address offs_CTFPlayerShared_ConditionData;
Address offs_CTFPlayerShared_pOuter;

Address offs_TFCondInfo_flDuration;
Address offs_TFCondInfo_hProvider;

Address offs_BleedStruct_t_hAttacker;
Address offs_BleedStruct_t_hWeapon;
Address offs_BleedStruct_t_flNextBleedTime;
Address offs_BleedStruct_t_flBleedEndTime;
Address offs_BleedStruct_t_nDamage;
Address offs_BleedStruct_t_bPermanent;
Address offs_BleedStruct_t_nCustomDmg;
int sizeof_BleedStruct_t;

Address offs_CEconWearable_bAlwaysValid;

int sizeof_TFCondInfo;

int g_nConditions;

#define MAX_DOT_DAMAGE_TYPES    16
int g_nDOTDamageTypes, g_DOTDamageTypes[MAX_DOT_DAMAGE_TYPES];

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen) {
	RegPluginLibrary("nosoop_tf2utils");
	
	CreateNative("TF2Util_UpdatePlayerSpeed", Native_UpdatePlayerSpeed);
	CreateNative("TF2Util_TakeHealth", Native_TakeHealth);
	CreateNative("TF2Util_GetEntityMaxHealth", Native_GetMaxHealth);
	CreateNative("TF2Util_GetPlayerMaxHealthBoost", Native_GetMaxHealthBoost);
	CreateNative("TF2Util_GetPlayerMaxAmmo", Native_GetMaxAmmo);
	CreateNative("TF2Util_SetPlayerActiveWeapon", Native_SetPlayerActiveWeapon);
	
	CreateNative("TF2Util_GetConditionCount", Native_GetConditionCount);
	CreateNative("TF2Util_GetConditionName", Native_GetConditionName);
	CreateNative("TF2Util_GetPlayerConditionDuration", Native_GetPlayerConditionDuration);
	CreateNative("TF2Util_SetPlayerConditionDuration", Native_SetPlayerConditionDuration);
	CreateNative("TF2Util_GetPlayerConditionProvider", Native_GetPlayerConditionProvider);
	CreateNative("TF2Util_SetPlayerConditionProvider", Native_SetPlayerConditionProvider);
	CreateNative("TF2Util_GetPlayerBurnDuration", Native_GetPlayerBurnDuration);
	CreateNative("TF2Util_SetPlayerBurnDuration", Native_SetPlayerBurnDuration);
	CreateNative("TF2Util_IgnitePlayer", Native_IgnitePlayer);
	CreateNative("TF2Util_GetPlayerActiveBleedCount", Native_GetPlayerActiveBleedCount);
	CreateNative("TF2Util_GetPlayerBleedAttacker", Native_GetPlayerBleedAttacker);
	CreateNative("TF2Util_GetPlayerBleedWeapon", Native_GetPlayerBleedWeapon);
	CreateNative("TF2Util_GetPlayerBleedNextDamageTick", Native_GetPlayerBleedNextDamageTick);
	CreateNative("TF2Util_GetPlayerBleedDuration", Native_GetPlayerBleedDuration);
	CreateNative("TF2Util_GetPlayerBleedDamage", Native_GetPlayerBleedDamage);
	CreateNative("TF2Util_GetPlayerBleedCustomDamageType", Native_GetPlayerBleedDamageType);
	CreateNative("TF2Util_MakePlayerBleed", Native_MakeBleed);
	CreateNative("TF2Util_IsPlayerImmuneToPushback", Native_IsPlayerImmuneToPushback);
	
	CreateNative("TF2Util_GetPlayerRespawnTimeOverride", Native_GetPlayerRespawnTimeOverride);
	CreateNative("TF2Util_SetPlayerRespawnTimeOverride", Native_SetPlayerRespawnTimeOverride);
	
	CreateNative("TF2Util_GetPlayerObject", Native_GetPlayerObject);
	CreateNative("TF2Util_GetPlayerObjectCount", Native_GetPlayerObjectCount);
	
	CreateNative("TF2Util_GetPlayerHealer", Native_GetPlayerHealer);
	
	CreateNative("TF2Util_GetPlayerLastDamageReceivedTime", Native_GetPlayerLastDamageTime);
	
	CreateNative("TF2Util_IsEntityWearable", Native_IsEntityWearable);
	CreateNative("TF2Util_GetPlayerWearable", Native_GetPlayerWearable);
	CreateNative("TF2Util_GetPlayerWearableCount", Native_GetPlayerWearableCount);
	CreateNative("TF2Util_EquipPlayerWearable", Native_EquipPlayerWearable);
	CreateNative("TF2Util_SetWearableAlwaysValid", Native_SetWearableAlwaysValid);
	
	CreateNative("TF2Util_IsEntityWeapon", Native_IsEntityWeapon);
	CreateNative("TF2Util_GetWeaponSlot", Native_GetWeaponSlot);
	CreateNative("TF2Util_GetWeaponID", Native_GetWeaponID);
	CreateNative("TF2Util_GetWeaponMaxClip", Native_GetWeaponMaxClip);
	CreateNative("TF2Util_CanWeaponAttack", Native_CanWeaponAttack);
	
	CreateNative("TF2Util_GetPlayerLoadoutEntity", Native_GetPlayerLoadoutEntity);
	
	CreateNative("TF2Util_GetPlayerShootPosition", Native_GetPlayerShootPosition);
	
	CreateNative("TF2Util_IsPointInRespawnRoom", Native_IsPointInRespawnRoom);
	
	CreateNative("TF2Util_IsCustomDamageTypeDOT", Native_IsCustomDamageTypeDOT);
	
	CreateNative("TF2Util_GetPlayerFromSharedAddress", Native_GetPlayerFromSharedAddress);
	
	// deprecated name for backcompat
	CreateNative("TF2Util_GetPlayerMaxHealth", Native_GetMaxHealthBoost);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.utils.nosoop");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.utils.nosoop).");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed()");
	g_SDKCallUpdatePlayerSpeed = EndPrepSDKCall();
	if (!g_SDKCallUpdatePlayerSpeed) {
		SetFailState("Failed to set up call to " ... "CTFPlayer::TeamFortress_SetSpeed()");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::TakeHealth()");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerTakeHealth = EndPrepSDKCall();
	if (!g_SDKCallPlayerTakeHealth) {
		SetFailState("Failed to set up call to " ... "CBaseEntity::TakeHealth()");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayer::GetMaxAmmo()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerGetMaxAmmo = EndPrepSDKCall();
	if (!g_SDKCallPlayerGetMaxAmmo) {
		SetFailState("Failed to set up call to " ... "CTFPlayer::GetMaxAmmo()");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual,
			"CBaseCombatCharacter::Weapon_Switch()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerWeaponSwitch = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual,
			"CBaseCombatCharacter::Weapon_ShootPosition()");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	g_SDKCallPlayerGetShootPosition = EndPrepSDKCall();
	if (!g_SDKCallPlayerGetShootPosition) {
		SetFailState("Failed to set up call to "
				... "CBaseCombatCharacter::Weapon_ShootPosition()");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFPlayerShared::GetMaxBuffedHealth()");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_SDKCallPlayerSharedGetMaxHealth = EndPrepSDKCall();
	if (!g_SDKCallPlayerSharedGetMaxHealth) {
		SetFailState("Failed to set up call to " ... "CTFPlayerShared::GetMaxBuffedHealth()");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayerShared::Burn()");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_SDKCallPlayerSharedBurn = EndPrepSDKCall();
	if (!g_SDKCallPlayerSharedBurn) {
		SetFailState("Failed to set up call to " ... "CTFPlayerShared::Burn()");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayerShared::MakeBleed()");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerSharedMakeBleed = EndPrepSDKCall();
	if (!g_SDKCallPlayerSharedMakeBleed) {
		SetFailState("Failed to set up call to " ... "CTFPlayerShared::MakeBleed()");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFPlayerShared::IsImmuneToPushback()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCallPlayerSharedImmuneToPushback = EndPrepSDKCall();
	if (!g_SDKCallPlayerSharedImmuneToPushback) {
		SetFailState("Failed to set up call to " ... "CTFPlayerShared::IsImmuneToPushback()");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::GetMaxHealth()");
	g_SDKCallEntityGetMaxHealth = EndPrepSDKCall();
	if (!g_SDKCallEntityGetMaxHealth) {
		SetFailState("Failed to set up call to " ... "CBaseEntity::GetMaxHealth()");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::IsBaseCombatWeapon()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCallIsEntityWeapon = EndPrepSDKCall();
	if (!g_SDKCallIsEntityWeapon) {
		SetFailState("Failed to set up call to " ... "CBaseEntity::IsBaseCombatWeapon()");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::IsWearable()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCallIsEntityWearable = EndPrepSDKCall();
	if (!g_SDKCallIsEntityWearable) {
		SetFailState("Failed to set up call to " ... "CBaseEntity::IsWearable()");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseCombatWeapon::GetSlot()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallWeaponGetSlot = EndPrepSDKCall();
	if (!g_SDKCallWeaponGetSlot) {
		SetFailState("Failed to set up call to " ... "CBaseCombatWeapon::GetSlot()");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFWeaponBase::GetWeaponID()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallWeaponGetID = EndPrepSDKCall();
	if (!g_SDKCallWeaponGetID) {
		SetFailState("Failed to set up call to " ... "CTFWeaponBase::GetWeaponID()");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallWeaponGetMaxClip = EndPrepSDKCall();
	if (!g_SDKCallWeaponGetMaxClip) {
		SetFailState("Failed to set up call to " ... "CTFWeaponBase::GetMaxClip1()");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFWeaponBase::CanAttack()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCallWeaponCanAttack = EndPrepSDKCall();
	if (!g_SDKCallWeaponCanAttack) {
		SetFailState("Failed to set up call to " ... "CTFWeaponBase::CanAttack()");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFPlayer::GetEntityForLoadoutSlot()");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_SDKCallPlayerGetEntityForLoadoutSlot = EndPrepSDKCall();
	if (!g_SDKCallPlayerGetEntityForLoadoutSlot) {
		SetFailState("Failed to set up call to " ... "CTFPlayer::GetEntityForLoadoutSlot()");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable()");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_SDKCallPlayerEquipWearable = EndPrepSDKCall();
	if (!g_SDKCallPlayerEquipWearable) {
		SetFailState("Failed to set up call to " ... "CTFPlayer::EquipWearable()");
	}
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "PointInRespawnRoom()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_SDKCallPointInRespawnRoom = EndPrepSDKCall();
	if (!g_SDKCallPointInRespawnRoom) {
		SetFailState("Failed to set up call to " ... "PointInRespawnRoom()");
	}
	
	// GameConfGetAddressOffset throws fail state if invalid; no need to validate here
	
	// networked CUtlVector offset support landed in 1.11; try to locate an offset there first
	offs_CTFPlayer_hMyWearables =
			view_as<Address>(FindSendPropInfo("CTFPlayer", "m_hMyWearables"));
	if (offs_CTFPlayer_hMyWearables <= Address_Null) {
		offs_CTFPlayer_hMyWearables = GameConfGetAddressOffset(hGameConf,
				"CTFPlayer::m_hMyWearables");
	}
	
	int offs_CTFPlayer_Shared = FindSendPropInfo("CTFPlayer", "m_Shared");
	int offs_CTFPlayer_ConditionData = FindSendPropInfo("CTFPlayer", "m_ConditionData");
	if (0 < offs_CTFPlayer_Shared < offs_CTFPlayer_ConditionData) {
		/**
		 * This works in 1.11; on 1.10, both properties' offsets point to CTFPlayer::m_Shared
		 * instead, which is incorrect.
		 */
		offs_CTFPlayerShared_ConditionData =
				view_as<Address>(offs_CTFPlayer_ConditionData - offs_CTFPlayer_Shared);
	} else {
		offs_CTFPlayerShared_ConditionData = GameConfGetAddressOffset(hGameConf,
				"CTFPlayerShared::m_ConditionData");
	}
	
	offs_CTFPlayerShared_flBurnDuration = GameConfGetAddressOffset(hGameConf,
			"CTFPlayerShared::m_flBurnDuration");
	
	offs_CTFPlayerShared_pOuter = GameConfGetAddressOffset(hGameConf,
			"CTFPlayerShared::m_pOuter");
	
	sizeof_TFCondInfo = GameConfGetOffset(hGameConf, "sizeof(TFCondInfo_t)");
	
	offs_TFCondInfo_flDuration = GameConfGetAddressOffset(hGameConf,
			"TFCondInfo_t::m_flDuration");
	
	offs_TFCondInfo_hProvider = GameConfGetAddressOffset(hGameConf,
			"TFCondInfo_t::m_hProvider");
	
	offs_CTFPlayerShared_BleedList = GameConfGetAddressOffset(hGameConf,
			"CTFPlayerShared::m_BleedList");
	offs_BleedStruct_t_hAttacker = GameConfGetAddressOffset(hGameConf,
			"BleedStruct_t::m_hAttacker");
	offs_BleedStruct_t_hWeapon = GameConfGetAddressOffset(hGameConf,
			"BleedStruct_t::m_hWeapon");
	offs_BleedStruct_t_flNextBleedTime = GameConfGetAddressOffset(hGameConf,
			"BleedStruct_t::m_flNextTickTime");
	offs_BleedStruct_t_flBleedEndTime = GameConfGetAddressOffset(hGameConf,
			"BleedStruct_t::m_flExpireTime");
	offs_BleedStruct_t_nDamage = GameConfGetAddressOffset(hGameConf,
			"BleedStruct_t::m_nDamage");
	offs_BleedStruct_t_bPermanent = GameConfGetAddressOffset(hGameConf,
			"BleedStruct_t::m_bPermanent");
	offs_BleedStruct_t_nCustomDmg = GameConfGetAddressOffset(hGameConf,
			"BleedStruct_t::m_nCustomDamageType");
	sizeof_BleedStruct_t = GameConfGetOffset(hGameConf, "sizeof(BleedStruct_t)");
	
	Address pNumConds = GameConfGetAddress(hGameConf, "&TF_COND_LAST");
	if (!pNumConds) {
		LogError("Could not determine location to read TF_COND_LAST from.  "
				... "Condition bounds checking will produce false positives and condition "
				... "count native will report incorrect values.");
		g_nConditions = 0xFF;
	} else if (!(g_nConditions = LoadFromAddress(pNumConds, NumberType_Int32))
			|| g_nConditions != g_nConditions & 0xFF) {
		// we expect the value to be within [1, 255]; if it isn't, then our address is invalid
		LogError("TF_COND_LAST is not within expected bounds (found %08x).  "
				... "Condition bounds checking will produce false positives and condition "
				... "count native will report incorrect values.", g_nConditions);
		g_nConditions = 0xFF;
	}
	offs_ConditionNames = GameConfGetAddress(hGameConf, "g_aConditionNames");
	
	Address pOffsPlayerObjects = GameConfGetAddress(hGameConf,
			"offsetof(CTFPlayer::m_aObjects)");
	if (!pOffsPlayerObjects) {
		SetFailState("Could not determine location to read CTFPlayer::m_aObjects from.");
	}
	
	offs_CTFPlayer_aObjects = view_as<Address>(
			LoadFromAddress(pOffsPlayerObjects, NumberType_Int32));
	if (view_as<int>(offs_CTFPlayer_aObjects) & ~0xFFFF) {
		// high bits are set - bad read?
		SetFailState("Could not determine offset of CTFPlayer::m_aObjects (received %08x)",
				offs_CTFPlayer_aObjects);
	}
	
	offs_CTFPlayer_aHealers = view_as<Address>(FindSendPropInfo("CTFPlayer", "m_nNumHealers") + 0xC);
	
	Address pOffsPlayerRespawnOverride = GameConfGetAddress(hGameConf,
			"offsetof(CTFPlayer::m_flRespawnTimeOverride)");
	if (!pOffsPlayerRespawnOverride) {
		SetFailState("Could not determine location to read CTFPlayer::m_flRespawnTimeOverride "
				... "from.");
	}
	
	offs_CTFPlayer_flRespawnTimeOverride =
			LoadFromAddress(pOffsPlayerRespawnOverride, NumberType_Int32);
	if (offs_CTFPlayer_flRespawnTimeOverride & 0xFFFF0000) {
		// high bits are set - bad read?
		SetFailState("Could not determine offset of CTFPlayer::m_flRespawnTimeOverride "
				... " (received %08x)", offs_CTFPlayer_flRespawnTimeOverride);
	}

	offs_CEconWearable_bAlwaysValid = GameConfGetAddressOffset(hGameConf,
			"CEconWearable::m_bAlwaysValid");
	
	offs_CTFPlayer_flLastDamageTime = GameConfGetAddressOffset(hGameConf,
			"CTFPlayer::m_flLastDamageTime");
	
	// allocate 5 chars for each value + delimiter
	char damageTypes[MAX_DOT_DAMAGE_TYPES * 5];
	if (!GameConfGetKeyValue(hGameConf, "DOTDamageTypes", damageTypes, sizeof(damageTypes))) {
		SetFailState("Could not retrieve DOTDamageTypes values");
	} else for (int c, i, res; (i = StringToIntEx(damageTypes[c], res, 0x10)); c += i) {
		/**
		 * Parse numeric values from the list.
		 * I don't expect the game to ever have as many DOT damage types as the hardcoded
		 * limit of 16 I've initally assigned here, but if it does, don't silently fail.
		 */
		if (g_nDOTDamageTypes == MAX_DOT_DAMAGE_TYPES) {
			SetFailState("Not enough space allocated to parse damage types (limit %d) - "
					... "update MAX_DOT_DAMAGE_TYPES and recompile", MAX_DOT_DAMAGE_TYPES);
		} else if (res == 0) {
			continue;
		}
		
		g_DOTDamageTypes[g_nDOTDamageTypes++] = res;
	}
	
	delete hGameConf;
	
	CreateVersionConVar("tf2utils_version", "TF2 Utils version.");
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	g_bDeferredSpeedUpdate[client] = false;
	g_flRespawnTimeOverride[client] = -1.0;
	
	SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
}

void OnPreThinkPost(int client) {
	if (g_bDeferredSpeedUpdate[client]) {
		ForceSpeedUpdate(client);
	}
	
	if (!IsPlayerAlive(client) && g_flRespawnTimeOverride[client] != -1.0) {
		SetPlayerRespawnTimeOverrideInternal(client, g_flRespawnTimeOverride[client]);
		g_flRespawnTimeOverride[client] = -1.0;
	}
}

// force speed update; any previous deferred calls are now fulfilled
void ForceSpeedUpdate(int client) {
	SDKCall(g_SDKCallUpdatePlayerSpeed, client);
	g_bDeferredSpeedUpdate[client] = false;
}

// void(int client, bool immediate = false)
int Native_UpdatePlayerSpeed(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	bool immediate = GetNativeCell(2);
	
	g_bDeferredSpeedUpdate[client] = !immediate;
	if (immediate) {
		ForceSpeedUpdate(client);
	}
}

// int(int client, float amount, int bitsHealType = 0);
int Native_TakeHealth(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	float amount = GetNativeCell(2);
	int bitsHealType = GetNativeCell(3);
	
	return SDKCall(g_SDKCallPlayerTakeHealth, client, amount, bitsHealType);
}

// int(int client, int ammoIndex, TFClassType playerClass = TFClass_Unknown);
int Native_GetMaxAmmo(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	int ammoIndex = GetNativeCell(2);
	int playerClass = GetNativeCell(3);
	
	if (playerClass < 1 || playerClass > 9) {
		playerClass = -1;
	}
	
	return SDKCall(g_SDKCallPlayerGetMaxAmmo, client, ammoIndex, playerClass);
}

// bool(int client, int weapon);
int Native_SetPlayerActiveWeapon(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	int weapon = GetNativeWeaponEntity(2, .allowNull = true);
	
	return SDKCall(g_SDKCallPlayerWeaponSwitch, client,
			weapon, 0 /* viewmodelindex; unused */) != 0;
}

// int(int entity);
int Native_GetMaxHealth(Handle plugin, int nParams) {
	int entity = GetNativeEntity(1);
	
	return SDKCall(g_SDKCallEntityGetMaxHealth, entity);
}

// int(int client, bool bIgnoreAttributes, bool bIgnoreOverheal);
int Native_GetMaxHealthBoost(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	bool bIgnoreAttributes = !!GetNativeCell(2);
	bool bIgnoreOverheal = !!GetNativeCell(3);
	
	return SDKCall(g_SDKCallPlayerSharedGetMaxHealth, GetPlayerSharedAddress(client),
			bIgnoreAttributes, bIgnoreOverheal);
}

// void(int client, int wearable);
int Native_EquipPlayerWearable(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int wearable = GetNativeWearableEntity(2);
	
	if (GetEntPropEnt(wearable, Prop_Send, "m_hOuter") != EntRefToEntIndex(wearable)) {
		ThrowNativeError(SP_ERROR_NATIVE,
				"Wearable entity index %d is not initialized correctly - was it not spawned?",
				wearable);
	}
	
	SDKCall(g_SDKCallPlayerEquipWearable, client, wearable);
	
	if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") != client) {
		// make sure owner is correct; if not, then gamedata is probably out of date
		ThrowNativeError(SP_ERROR_NATIVE,
				"Assertion failed - wearable entity %d not attached to player. "
				... "Gamedata may need to be updated", wearable);
	}
}

// void(int wearable, bool alwaysValid);
int Native_SetWearableAlwaysValid(Handle plugin, int numParams) {
	int wearable = GetNativeWearableEntity(1);
	bool alwaysValid = GetNativeCell(2) != 0;
	
	SetEntData(wearable, view_as<int>(offs_CEconWearable_bAlwaysValid), alwaysValid, 1);
}

// int(int client, int index);
int Native_GetPlayerWearable(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	int count = GetEntData(client, view_as<int>(offs_CTFPlayer_hMyWearables) + 0x0C);
	if (index < 0 || index >= count) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid index %d (count: %d)", index, count);
	}
	
	Address pData = DereferencePointer(GetEntityAddress(client)
			+ view_as<Address>(offs_CTFPlayer_hMyWearables));
	return LoadEntityHandleFromAddress(pData + view_as<Address>(0x04 * index));
}

// int(int client);
int Native_GetPlayerWearableCount(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	
	return GetEntData(client, view_as<int>(offs_CTFPlayer_hMyWearables) + 0x0C);
}

// void(int client, float result[3]);
int Native_GetPlayerShootPosition(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	
	float vecResult[3];
	SDKCall(g_SDKCallPlayerGetShootPosition, client, vecResult);
	SetNativeArray(2, vecResult, sizeof(vecResult));
}

// int(int client, int index);
int Native_GetPlayerObject(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	int count = GetEntData(client, view_as<int>(offs_CTFPlayer_aObjects) + 0x0C);
	if (index < 0 || index >= count) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid index %d (count: %d)", index, count);
	}
	
	Address pData = DereferencePointer(GetEntityAddress(client)
			+ view_as<Address>(offs_CTFPlayer_aObjects));
	return EntRefToEntIndex(
			LoadEntityHandleFromAddress(pData + view_as<Address>(0x04 * index)));
}

// int(int client);
int Native_GetPlayerObjectCount(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	
	return GetEntData(client, view_as<int>(offs_CTFPlayer_aObjects) + 0x0C);
}

// int(int client, int index);
int Native_GetPlayerHealer(Handle plugin, int nParams) {
	// Pelipoika did this ages ago https://forums.alliedmods.net/showthread.php?t=306854
	// it's bundled here for consistency's sake, and in case it needs maintenance in the future
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	int count = GetEntProp(client, Prop_Send, "m_nNumHealers");
	if (index < 0 || index >= count) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid index %d (count: %d)", index, count);
	}
	
	Address pData = DereferencePointer(GetEntityAddress(client)
			+ view_as<Address>(offs_CTFPlayer_aHealers));
	return EntRefToEntIndex(LoadEntityHandleFromAddress(pData + view_as<Address>(0x24 * index)));
}

// float(int client);
any Native_GetPlayerLastDamageTime(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	
	return GetEntDataFloat(client, offs_CTFPlayer_flLastDamageTime);
}

// bool(int entity);
int Native_IsEntityWeapon(Handle plugin, int nParams) {
	int entity = GetNativeEntity(1);
	return IsEntityWeapon(entity);
}

// bool(int entity);
int Native_IsEntityWearable(Handle plugin, int nParams) {
	int entity = GetNativeEntity(1);
	return IsEntityWearable(entity);
}

// int(int entity);
int Native_GetWeaponSlot(Handle plugin, int nParams) {
	int entity = GetNativeWeaponEntity(1);
	return SDKCall(g_SDKCallWeaponGetSlot, entity);
}

// int(int entity);
int Native_GetWeaponID(Handle plugin, int nParams) {
	int entity = GetNativeWeaponEntity(1);
	return SDKCall(g_SDKCallWeaponGetID, entity);
}

// int(int entity);
int Native_GetWeaponMaxClip(Handle plugin, int nParams) {
	int entity = GetNativeWeaponEntity(1);
	return SDKCall(g_SDKCallWeaponGetMaxClip, entity);
}

// bool(int weapon);
int Native_CanWeaponAttack(Handle plugin, int nParams) {
	int entity = GetNativeWeaponEntity(1);
	return SDKCall(g_SDKCallWeaponCanAttack, entity);
}

// bool(int client);
int Native_IsPlayerImmuneToPushback(Handle plugin, int nParams) {
	int client = GetNativeInGameClient(1);
	
	return SDKCall(g_SDKCallPlayerSharedImmuneToPushback, GetPlayerSharedAddress(client));
}

// bool(const float[3] position, int entity, bool bRestrictToSameTeam)
int Native_IsPointInRespawnRoom(Handle plugin, int nParams) {
	if (IsNativeParamNullVector(1)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Cannot use NULL_VECTOR as origin");
	}
	
	float origin[3];
	GetNativeArray(1, origin, sizeof(origin));
	
	int entity = GetNativeEntity(2, .allowNull = true);
	bool bRestrictToSameTeam = GetNativeCell(3);
	
	return SDKCall(g_SDKCallPointInRespawnRoom, entity, origin, bRestrictToSameTeam);
}

// int(int client, int loadoutSlot, bool includeWearableWeapons);
int Native_GetPlayerLoadoutEntity(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	
	int loadoutSlot = GetNativeCell(2);
	bool check_wearable = numParams <3 ? true : GetNativeCell(3);
	
	return SDKCall(g_SDKCallPlayerGetEntityForLoadoutSlot, client, loadoutSlot, check_wearable);
}

// int();
int Native_GetConditionCount(Handle plugin, int numParams) {
	return g_nConditions;
}

// int(TFCond cond, char[] buffer, int maxlen);
int Native_GetConditionName(Handle plugin, int numParams) {
	any cond = GetNativeCell(1);
	if (!IsConditionValid(cond)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Condition index %d is invalid", cond);
	}
	
	int buflen = GetNativeCell(3);
	if (buflen <= 0) {
		return 0;
	}
	
	char[] buffer = new char[buflen];
	int written = LoadStringFromAddress(
			DereferencePointer(offs_ConditionNames + view_as<Address>(cond * 4)),
			buffer, buflen);
	int actually_written;
	
	SetNativeString(2, buffer, ++written, .bytes = actually_written);
	return actually_written;
}

// float(int client, TFCond cond);
any Native_GetPlayerConditionDuration(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	TFCond cond = GetNativeCell(2);
	
	if (!IsConditionValid(cond)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Condition index %d is invalid", cond);
	} else if (!TF2_IsPlayerInCondition(client, cond)) {
		return 0.0;
	}
	
	Address pData = GetConditionData(client, cond);
	return LoadFromAddress(pData + offs_TFCondInfo_flDuration, NumberType_Int32);
}

// void(int client, TFCond cond, float duration);
any Native_SetPlayerConditionDuration(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	TFCond cond = GetNativeCell(2);
	float duration = GetNativeCell(3);
	
	if (!IsConditionValid(cond)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Condition index %d is invalid", cond);
	} else if (!TF2_IsPlayerInCondition(client, cond)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Player is not in condition %d", cond);
	}
	
	Address pData = GetConditionData(client, cond);
	StoreToAddress(pData + offs_TFCondInfo_flDuration, view_as<any>(duration),
			NumberType_Int32);
}

// int(int client, TFCond cond);
any Native_GetPlayerConditionProvider(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	TFCond cond = GetNativeCell(2);
	
	if (!IsConditionValid(cond)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Condition index %d is invalid", cond);
	} else if (!TF2_IsPlayerInCondition(client, cond)) {
		return INVALID_ENT_REFERENCE;
	}
	
	Address pData = GetConditionData(client, cond);
	return LoadEntityHandleFromAddress(pData + offs_TFCondInfo_hProvider);
}

// void(int client, TFCond cond, int provider);
any Native_SetPlayerConditionProvider(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	TFCond cond = GetNativeCell(2);
	int provider = GetNativeEntity(3);
	
	if (!IsConditionValid(cond)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Condition index %d is invalid", cond);
	} else if (!TF2_IsPlayerInCondition(client, cond)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Player is not in condition %d", cond);
	}
	
	Address pData = GetConditionData(client, cond);
	StoreEntityHandleToAddress(pData + offs_TFCondInfo_hProvider, provider);
}

// float(int client);
any Native_GetPlayerBurnDuration(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	
	if (!TF2_IsPlayerInCondition(client, TFCond_OnFire)) {
		return 0.0;
	}
	int pOffsSharedBurnDuration = FindSendPropInfo("CTFPlayer", "m_Shared")
			+ view_as<int>(offs_CTFPlayerShared_flBurnDuration);
	return GetEntDataFloat(client, pOffsSharedBurnDuration);
}

// void(int client, float duration);
any Native_SetPlayerBurnDuration(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	float duration = GetNativeCell(2);
	
	if (!TF2_IsPlayerInCondition(client, TFCond_OnFire)) {
		return;
	}
	int pOffsSharedBurnDuration = FindSendPropInfo("CTFPlayer", "m_Shared")
			+ view_as<int>(offs_CTFPlayerShared_flBurnDuration);
	SetEntDataFloat(client, pOffsSharedBurnDuration, duration);
}

// void(int client, int attacker, float duration, int weapon = INVALID_ENT_REFERENCE);
any Native_IgnitePlayer(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int attacker = GetNativeCell(2);
	float duration = GetNativeCell(3);
	int weapon = GetNativeWeaponEntity(4, .allowNull = true);
	
	// NULL is allowed for attacker
	if (attacker != INVALID_ENT_REFERENCE) {
		if (attacker < 1 || attacker > MaxClients) {
			ThrowNativeError(SP_ERROR_NATIVE, "Client %d index is not valid", attacker);
		} else if (!IsClientInGame(attacker)) {
			ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", attacker);
		}
	}
	
	SDKCall(g_SDKCallPlayerSharedBurn, GetPlayerSharedAddress(client), attacker, weapon,
			duration);
}

// int(int client);
any Native_GetPlayerActiveBleedCount(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	
	return GetPlayerBleedCount(client);
}

// int(int client, int index);
any Native_GetPlayerBleedAttacker(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	Address pBleedInfo = GetPlayerBleedInfo(client, index);
	return LoadEntityHandleFromAddress(pBleedInfo + offs_BleedStruct_t_hAttacker);
}

// int(int client, int index);
any Native_GetPlayerBleedWeapon(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	Address pBleedInfo = GetPlayerBleedInfo(client, index);
	return LoadEntityHandleFromAddress(pBleedInfo + offs_BleedStruct_t_hWeapon);
}

// float(int client, int index);
any Native_GetPlayerBleedNextDamageTick(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	Address pBleedInfo = GetPlayerBleedInfo(client, index);
	float flNextBleedTime = view_as<float>(LoadFromAddress(
			pBleedInfo + offs_BleedStruct_t_flNextBleedTime, NumberType_Int32));
	return flNextBleedTime - GetGameTime();
}

// float(int client, int index);
any Native_GetPlayerBleedDuration(Handle plugin, int numParams) {
	// TODO if is permanent, return -1
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	Address pBleedInfo = GetPlayerBleedInfo(client, index);
	
	if (LoadFromAddress(pBleedInfo + offs_BleedStruct_t_bPermanent, NumberType_Int8)) {
		return -1.0;
	}
	float flBleedEndTime = view_as<float>(LoadFromAddress(
			pBleedInfo + offs_BleedStruct_t_flBleedEndTime, NumberType_Int32));
	return flBleedEndTime - GetGameTime();
}

// int(int client, int index);
any Native_GetPlayerBleedDamage(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	Address pBleedInfo = GetPlayerBleedInfo(client, index);
	return LoadFromAddress(pBleedInfo + offs_BleedStruct_t_nDamage, NumberType_Int32);
}

// int(int client, int index);
any Native_GetPlayerBleedDamageType(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int index = GetNativeCell(2);
	
	Address pBleedInfo = GetPlayerBleedInfo(client, index);
	return LoadFromAddress(pBleedInfo + offs_BleedStruct_t_nCustomDmg, NumberType_Int32);
}

// int(int client, int attacker, float duration, int weapon = INVALID_ENT_REFERENCE, int damage = 4, int damagecustom = TF_CUSTOM_BLEEDING);
any Native_MakeBleed(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	int attacker = GetNativeInGameClient(2);
	float duration = GetNativeCell(3);
	int weapon = GetNativeWeaponEntity(4, .allowNull = true);
	int damage = GetNativeCell(5);
	int damagecustom = GetNativeCell(6);
	
	SDKCall(g_SDKCallPlayerSharedMakeBleed, GetPlayerSharedAddress(client), attacker, weapon,
			duration, damage, duration == TFCondDuration_Infinite, damagecustom);
	
	int weaponIndex = EntRefToEntIndex(weapon);
	for (int i, n = GetPlayerBleedCount(client); i < n; i++) {
		Address pBleedInfo = GetPlayerBleedInfo(client, i);
		
		// search the bleed list for the index of the bleed
		if (LoadEntityHandleFromAddress(pBleedInfo + offs_BleedStruct_t_hWeapon) != weaponIndex
				|| LoadEntityHandleFromAddress(pBleedInfo + offs_BleedStruct_t_hAttacker) != attacker) {
			continue;
		}
		return i;
	}
	return -1;
}

// float(int client);
any Native_GetPlayerRespawnTimeOverride(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	return GetEntDataFloat(client, offs_CTFPlayer_flRespawnTimeOverride);
}

// void(int client, float time);
any Native_SetPlayerRespawnTimeOverride(Handle plugin, int numParams) {
	int client = GetNativeInGameClient(1);
	float time = GetNativeCell(2);
	
	if (!IsPlayerAlive(client)) {
		SetPlayerRespawnTimeOverrideInternal(client, time);
		g_flRespawnTimeOverride[client] = -1.0;
	} else {
		g_flRespawnTimeOverride[client] = time;
	}
	return;
}

// bool(int damagecustom);
any Native_IsCustomDamageTypeDOT(Handle plugin, int numParams) {
	int damagecustom = GetNativeCell(1);
	for (int i; i < g_nDOTDamageTypes; i++) {
		if (g_DOTDamageTypes[i] == damagecustom) {
			return true;
		}
	}
	return false;
}

// int(Address pShared);
any Native_GetPlayerFromSharedAddress(Handle plugin, int numParams) {
	Address pShared = GetNativeCell(1);
	Address pOuter = DereferencePointer(pShared + offs_CTFPlayerShared_pOuter);
	return GetEntityFromAddress(pOuter);
}

bool IsEntityWeapon(int entity) {
	return SDKCall(g_SDKCallIsEntityWeapon, entity);
}

/**
 * Gets an entity index or reference from a native parameter.  If the entity is not a valid
 * weapon, the function throws a native error unless NULL entities are specifically allowed.
 */
int GetNativeWeaponEntity(int param, bool allowNull = false) {
	int entity = GetNativeEntity(param, allowNull);
	if (allowNull && entity == INVALID_ENT_REFERENCE) {
		return INVALID_ENT_REFERENCE;
	} else if (!IsEntityWeapon(entity)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity %d is not a weapon (param %d)", entity,
				param);
	}
	return entity;
}

bool IsEntityWearable(int entity) {
	return SDKCall(g_SDKCallIsEntityWearable, entity);
}

/**
 * Gets an entity index or reference from a native parameter.  If the entity is not a valid
 * wearable, the function throws a native error.
 */
int GetNativeWearableEntity(int param) {
	int entity = GetNativeEntity(param);
	if (!IsEntityWearable(entity)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity %d is not a wearable (param %d)", entity,
				param);
	}
	return entity;
}

static void SetPlayerRespawnTimeOverrideInternal(int client, float time) {
	SetEntDataFloat(client, offs_CTFPlayer_flRespawnTimeOverride, time);
}

static Address GetConditionData(int client, TFCond cond) {
	Address pCondMemory = DereferencePointer(GetEntityAddress(client)
			+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"))
			+ offs_CTFPlayerShared_ConditionData);
	return pCondMemory + view_as<Address>(view_as<int>(cond) * sizeof_TFCondInfo);
}

static int GetPlayerBleedCount(int client) {
	return GetEntData(client, FindSendPropInfo("CTFPlayer", "m_Shared")
			+ view_as<int>(offs_CTFPlayerShared_BleedList) + 0xC);
}

static Address GetPlayerBleedInfo(int client, int index) {
	int count = GetPlayerBleedCount(client);
	if (index < 0 || index >= count) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid index %d (count %d)", index, count);
	}
	
	Address pBleedMemory = DereferencePointer(GetEntityAddress(client)
			+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"))
			+ offs_CTFPlayerShared_BleedList);
	return pBleedMemory + view_as<Address>(view_as<int>(index) * sizeof_BleedStruct_t);
}

static Address GetPlayerSharedAddress(int client) {
	return GetEntityAddress(client)
			+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"));
}

static bool IsConditionValid(TFCond cond) {
	return 0 <= view_as<any>(cond) < g_nConditions;
}

static Address GameConfGetAddressOffset(Handle gamedata, const char[] key) {
	Address offs = view_as<Address>(GameConfGetOffset(gamedata, key));
	if (offs == view_as<Address>(-1)) {
		SetFailState("Failed to get member offset %s", key);
	}
	return offs;
}

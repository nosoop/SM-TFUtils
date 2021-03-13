/**
 * TF2 Utils Shared Plugin
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <sdkhooks>
#include <sdktools>

#include <stocksoup/memory>

#define PLUGIN_VERSION "0.11.0"
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

Handle g_SDKCallPlayerSharedGetMaxHealth;

Handle g_SDKCallIsEntityWeapon;
Handle g_SDKCallWeaponGetSlot;
Handle g_SDKCallWeaponGetID;
Handle g_SDKCallWeaponGetMaxClip;

Handle g_SDKCallIsEntityWearable;
Handle g_SDKCallPlayerEquipWearable;

Handle g_SDKCallPointInRespawnRoom;

Address offs_CTFPlayer_hMyWearables;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen) {
	RegPluginLibrary("nosoop_tf2utils");
	
	CreateNative("TF2Util_UpdatePlayerSpeed", Native_UpdatePlayerSpeed);
	CreateNative("TF2Util_TakeHealth", Native_TakeHealth);
	CreateNative("TF2Util_GetPlayerMaxHealth", Native_GetMaxHealth);
	CreateNative("TF2Util_GetPlayerMaxAmmo", Native_GetMaxAmmo);
	
	CreateNative("TF2Util_IsEntityWearable", Native_IsEntityWearable);
	CreateNative("TF2Util_GetPlayerWearable", Native_GetPlayerWearable);
	CreateNative("TF2Util_GetPlayerWearableCount", Native_GetPlayerWearableCount);
	CreateNative("TF2Util_EquipPlayerWearable", Native_EquipPlayerWearable);
	
	CreateNative("TF2Util_IsEntityWeapon", Native_IsEntityWeapon);
	CreateNative("TF2Util_GetWeaponSlot", Native_GetWeaponSlot);
	CreateNative("TF2Util_GetWeaponID", Native_GetWeaponID);
	CreateNative("TF2Util_GetWeaponMaxClip", Native_GetWeaponMaxClip);
	
	CreateNative("TF2Util_GetPlayerLoadoutEntity", Native_GetPlayerLoadoutEntity);
	
	CreateNative("TF2Util_GetPlayerShootPosition", Native_GetPlayerShootPosition);
	
	CreateNative("TF2Util_IsPointInRespawnRoom", Native_IsPointInRespawnRoom);
	
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
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::TakeHealth()");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerTakeHealth = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayer::GetMaxAmmo()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerGetMaxAmmo = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual,
			"CBaseCombatCharacter::Weapon_ShootPosition()");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	g_SDKCallPlayerGetShootPosition = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFPlayerShared::GetMaxBuffedHealth()");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_SDKCallPlayerSharedGetMaxHealth = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::IsBaseCombatWeapon()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCallIsEntityWeapon = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::IsWearable()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKCallIsEntityWearable = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseCombatWeapon::GetSlot()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallWeaponGetSlot = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFWeaponBase::GetWeaponID()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallWeaponGetID = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallWeaponGetMaxClip = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFPlayer::GetEntityForLoadoutSlot()");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_SDKCallPlayerGetEntityForLoadoutSlot = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable()");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_SDKCallPlayerEquipWearable = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "PointInRespawnRoom()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_SDKCallPointInRespawnRoom = EndPrepSDKCall();
	
	// networked CUtlVector offset support landed in 1.11; try to locate an offset there first
	offs_CTFPlayer_hMyWearables =
			view_as<Address>(FindSendPropInfo("CTFPlayer", "m_hMyWearables"));
	if (offs_CTFPlayer_hMyWearables <= Address_Null) {
		offs_CTFPlayer_hMyWearables = GameConfGetAddressOffset(hGameConf,
				"CTFPlayer::m_hMyWearables");
	}
	
	delete hGameConf;
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
	
	SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
}

public void OnPreThinkPost(int client) {
	if (g_bDeferredSpeedUpdate[client]) {
		ForceSpeedUpdate(client);
	}
}

// force speed update; any previous deferred calls are now fulfilled
void ForceSpeedUpdate(int client) {
	SDKCall(g_SDKCallUpdatePlayerSpeed, client);
	g_bDeferredSpeedUpdate[client] = false;
}

// void(int client, bool immediate = false)
public int Native_UpdatePlayerSpeed(Handle plugin, int nParams) {
	int client = GetNativeCell(1);
	bool immediate = GetNativeCell(2);
	
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	
	g_bDeferredSpeedUpdate[client] = !immediate;
	if (immediate) {
		ForceSpeedUpdate(client);
	}
}

// int(int client, float amount, int bitsHealType = 0);
public int Native_TakeHealth(Handle plugin, int nParams) {
	int client = GetNativeCell(1);
	float amount = GetNativeCell(2);
	int bitsHealType = GetNativeCell(3);
	
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	
	return SDKCall(g_SDKCallPlayerTakeHealth, client, amount, bitsHealType);
}

// int(int client, int ammoIndex, TFClassType playerClass = TFClass_Unknown);
public int Native_GetMaxAmmo(Handle plugin, int nParams) {
	int client = GetNativeCell(1);
	int ammoIndex = GetNativeCell(2);
	int playerClass = GetNativeCell(3);
	
	if (playerClass < 1 || playerClass > 9) {
		playerClass = -1;
	}
	
	return SDKCall(g_SDKCallPlayerGetMaxAmmo, client, ammoIndex, playerClass);
}

// int(int client, bool bIgnoreAttributes, bool bIgnoreOverheal);
public int Native_GetMaxHealth(Handle plugin, int nParams) {
	int client = GetNativeCell(1);
	bool bIgnoreAttributes = !!GetNativeCell(2);
	bool bIgnoreOverheal = !!GetNativeCell(3);
	
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	
	Address offs_Shared = view_as<Address>(GetEntSendPropOffs(client, "m_Shared", true));
	
	return SDKCall(g_SDKCallPlayerSharedGetMaxHealth, GetEntityAddress(client) + offs_Shared,
			bIgnoreAttributes, bIgnoreOverheal);
}

public int Native_EquipPlayerWearable(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	
	int wearable = GetNativeCell(2);
	if (!IsEntityWearable(wearable)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity index %d is not a wearable",
				EntRefToEntIndex(wearable));
	}
	SDKCall(g_SDKCallPlayerEquipWearable, client, wearable);
}

// int(int client, int index);
public int Native_GetPlayerWearable(Handle plugin, int nParams) {
	int client = GetNativeCell(1);
	int index = GetNativeCell(2);
	
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	
	int count = GetEntData(client, view_as<int>(offs_CTFPlayer_hMyWearables) + 0x0C);
	if (index < 0 || index >= count) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid index %d (count: %d)", index, count);
	}
	
	Address pData = DereferencePointer(GetEntityAddress(client)
			+ view_as<Address>(offs_CTFPlayer_hMyWearables));
	return LoadEntityHandleFromAddress(pData + view_as<Address>(0x04 * index));
}

// int(int client);
public int Native_GetPlayerWearableCount(Handle plugin, int nParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	return GetEntData(client, view_as<int>(offs_CTFPlayer_hMyWearables) + 0x0C);
}

// void(int client, float result[3]);
public int Native_GetPlayerShootPosition(Handle plugin, int nParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	float vecResult[3];
	SDKCall(g_SDKCallPlayerGetShootPosition, client, vecResult);
	SetNativeArray(2, vecResult, sizeof(vecResult));
}

// bool(int entity);
public int Native_IsEntityWeapon(Handle plugin, int nParams) {
	int entity = GetNativeCell(1);
	return IsEntityWeapon(entity);
}

// bool(int entity);
public int Native_IsEntityWearable(Handle plugin, int nParams) {
	int entity = GetNativeCell(1);
	return IsEntityWearable(entity);
}

// int(int entity);
public int Native_GetWeaponSlot(Handle plugin, int nParams) {
	int entity = GetNativeCell(1);
	if (!IsEntityWeapon(entity)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity index %d (%d) is not a weapon", entity,
				EntRefToEntIndex(entity));
	}
	return SDKCall(g_SDKCallWeaponGetSlot, entity);
}

// int(int entity);
public int Native_GetWeaponID(Handle plugin, int nParams) {
	int entity = GetNativeCell(1);
	if (!IsEntityWeapon(entity)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity index %d (%d) is not a weapon", entity,
				EntRefToEntIndex(entity));
	}
	return SDKCall(g_SDKCallWeaponGetID, entity);
}

// int(int entity);
public int Native_GetWeaponMaxClip(Handle plugin, int nParams) {
	int entity = GetNativeCell(1);
	if (!IsEntityWeapon(entity)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity index %d (%d) is not a weapon", entity,
				EntRefToEntIndex(entity));
	}
	return SDKCall(g_SDKCallWeaponGetMaxClip, entity);
}

// bool(const float[3] position, int entity, bool bRestrictToSameTeam)
public int Native_IsPointInRespawnRoom(Handle plugin, int nParams) {
	if (IsNativeParamNullVector(1)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Cannot use NULL_VECTOR as origin");
	}
	
	float origin[3];
	GetNativeArray(1, origin, sizeof(origin));
	
	int entity = GetNativeCell(2);
	if (entity != INVALID_ENT_REFERENCE && !IsValidEntity(entity)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Entity %d (%d) is invalid", entity,
				EntRefToEntIndex(entity));
	}
	
	bool bRestrictToSameTeam = GetNativeCell(3);
	
	return SDKCall(g_SDKCallPointInRespawnRoom, entity, origin, bRestrictToSameTeam);
}

// int(int client, int loadoutSlot, bool includeWearableWeapons);
int Native_GetPlayerLoadoutEntity(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	}
	int loadoutSlot = GetNativeCell(2);
	bool check_wearable = numParams <3 ? true : GetNativeCell(3);
	
	return SDKCall(g_SDKCallPlayerGetEntityForLoadoutSlot, client, loadoutSlot, check_wearable);
}

bool IsEntityWeapon(int entity) {
	if (!IsValidEntity(entity)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity %d (%d) is invalid", entity,
				EntRefToEntIndex(entity));
	}
	return SDKCall(g_SDKCallIsEntityWeapon, entity);
}

bool IsEntityWearable(int entity) {
	if (!IsValidEntity(entity)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity %d (%d) is invalid", entity,
				EntRefToEntIndex(entity));
	}
	return SDKCall(g_SDKCallIsEntityWearable, entity);
}

static Address GameConfGetAddressOffset(Handle gamedata, const char[] key) {
	Address offs = view_as<Address>(GameConfGetOffset(gamedata, key));
	if (offs == view_as<Address>(-1)) {
		SetFailState("Failed to get member offset %s", key);
	}
	return offs;
}

/**
 * Calls every TF2 Utils native on a live server and says what came back.
 *
 * Needs two players that are alive, bots will do:
 *     sv_cheats 1; bot -team red -class scout; bot -team red -class soldier
 *     test_tf2utils
 *
 * Every line it prints starts with "T2U". "ok" is a value that was as expected, "WRONG" one
 * that was not, "ERROR" a native that threw, "note" something that could not be set up and so
 * was not checked. Some of it runs three seconds later (what needs the game to tick first), and
 * the last line is "T2U DONE".
 *
 * "test_tf2utils <part>" runs one part by itself: conditions, health, weapons, wearables,
 * conddata, burn, bleed, state, objsetup, then a few seconds later bleedlater, objects,
 * lastdamage, lagcomp, and done for the totals.
 */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#pragma newdecls required

#include <tf2utils>

public Plugin myinfo = {
	name = "TF2 Utils native test",
	author = "kingo",
	description = "Calls every TF2 Utils native.",
	version = "1.0.0",
	url = ""
}

#define TEST_COND    TFCond_SpeedBuffAlly

int g_Target, g_Other;
int g_Dispenser = INVALID_ENT_REFERENCE;
int g_nOk, g_nWrong, g_nErrors, g_nNotes;
int g_offsAlwaysValid = -1;

public void OnPluginStart() {
	RegServerCmd("test_tf2utils", Command_Test, "Calls every TF2 Utils native");

	Handle conf = LoadGameConfigFile("tf2.utils.nosoop");
	if (conf) {
		g_offsAlwaysValid = GameConfGetOffset(conf, "CEconWearable::m_bAlwaysValid");
		delete conf;
	}
}

Action Command_Test(int args) {
	g_Target = g_Other = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}
		if (!g_Target) {
			g_Target = i;
		} else if (!g_Other) {
			g_Other = i;
		}
	}
	if (!g_Target || !g_Other) {
		PrintToServer("T2U FAILED: needs two players that are alive");
		return Plugin_Handled;
	}
	
	// "test_tf2utils <part>" runs one part only, to tell which one a server went down in
	if (args >= 1) {
		char part[32];
		GetCmdArg(1, part, sizeof(part));
		if (StrEqual(part, "conditions")) {
			g_nOk = g_nWrong = g_nErrors = g_nNotes = 0;
			Run("conditions", Test_Conditions);
		}
		else if (StrEqual(part, "health")) Run("health and ammo", Test_HealthAmmo);
		else if (StrEqual(part, "weapons")) Run("weapons", Test_Weapons);
		else if (StrEqual(part, "wearables")) Run("wearables", Test_Wearables);
		else if (StrEqual(part, "conddata")) Run("player condition data", Test_ConditionData);
		else if (StrEqual(part, "burn")) Run("burning", Test_Burn);
		else if (StrEqual(part, "bleed")) Run("bleeding", Test_Bleed);
		else if (StrEqual(part, "state")) Run("player state", Test_PlayerState);
		else if (StrEqual(part, "objsetup")) Run("objects: setup", Test_ObjectsSetup);
		else if (StrEqual(part, "objects")) Run("objects and healers", Test_ObjectsHealers);
		else if (StrEqual(part, "bleedlater")) Run("bleeding, later", Test_BleedLater);
		else if (StrEqual(part, "lastdamage")) Run("last damage time", Test_LastDamage);
		else if (StrEqual(part, "lagcomp")) Run("lag compensation", Test_LagCompensation);
		else if (StrEqual(part, "done")) {
			if (IsValidEntity(g_Dispenser)) {
				RemoveEntity(g_Dispenser);
			}
			PrintToServer("T2U DONE: %d ok, %d wrong, %d errors, %d notes", g_nOk, g_nWrong,
					g_nErrors, g_nNotes);
		} else {
			PrintToServer("T2U FAILED: no part \"%s\"", part);
		}
		return Plugin_Handled;
	}
	
	g_nOk = g_nWrong = g_nErrors = g_nNotes = 0;
	PrintToServer("T2U START: target %N (%d), other %N (%d)", g_Target, g_Target, g_Other,
			g_Other);
	
	Run("conditions", Test_Conditions);
	Run("health and ammo", Test_HealthAmmo);
	Run("weapons", Test_Weapons);
	Run("wearables", Test_Wearables);
	Run("player condition data", Test_ConditionData);
	Run("burning", Test_Burn);
	Run("bleeding", Test_Bleed);
	Run("player state", Test_PlayerState);
	Run("objects: setup", Test_ObjectsSetup);
	
	CreateTimer(3.0, Timer_Later);
	return Plugin_Handled;
}

Action Timer_Later(Handle timer) {
	if (!IsClientInGame(g_Target) || !IsClientInGame(g_Other)) {
		PrintToServer("T2U FAILED: a player left");
		return Plugin_Stop;
	}
	Run("bleeding, later", Test_BleedLater);
	Run("objects and healers", Test_ObjectsHealers);
	Run("last damage time", Test_LastDamage);
	Run("lag compensation", Test_LagCompensation);
	
	if (IsValidEntity(g_Dispenser)) {
		RemoveEntity(g_Dispenser);
	}
	PrintToServer("T2U DONE: %d ok, %d wrong, %d errors, %d notes", g_nOk, g_nWrong, g_nErrors,
			g_nNotes);
	PrintToChatAll("[T2U] DONE: %d ok, %d wrong, %d errors, %d notes", g_nOk, g_nWrong, g_nErrors,
			g_nNotes);
	return Plugin_Stop;
}

void Run(const char[] name, Function fn) {
	Call_StartFunction(null, fn);
	int err = Call_Finish();
	if (err != SP_ERROR_NONE) {
		g_nErrors++;
		PrintToServer("T2U ERROR  %s: stopped by an error (%d), see SourceMod's error log", name,
				err);
	}
}

void Check(bool right, const char[] fmt, any ...) {
	char text[192];
	VFormat(text, sizeof(text), fmt, 3);
	if (right) {
		g_nOk++;
	} else {
		g_nWrong++;
	}
	PrintToServer("T2U %s  %s", right ? "ok   " : "WRONG", text);
	PrintToChatAll("[T2U] %s %s", right ? "ok" : "WRONG", text);
}

void Note(const char[] fmt, any ...) {
	char text[192];
	VFormat(text, sizeof(text), fmt, 2);
	g_nNotes++;
	PrintToServer("T2U note   %s", text);
	PrintToChatAll("[T2U] note %s", text);
}

bool Near(float a, float b, float within) {
	return FloatAbs(a - b) <= within;
}

// TF2Util_GetConditionCount, _GetConditionName, _GetConditionFromName, _IsCustomDamageTypeDOT
void Test_Conditions() {
	int count = TF2Util_GetConditionCount();
	Check(100 < count < 255, "GetConditionCount = %d", count);
	Check(view_as<int>(TF2Util_GetLastCondition()) == count - 1, "GetLastCondition = %d",
			TF2Util_GetLastCondition());

	char name[64];
	int written = TF2Util_GetConditionName(TFCond_Ubercharged, name, sizeof(name));
	Check(StrEqual(name, "TF_COND_INVULNERABLE"), "GetConditionName(5) = \"%s\" (%d bytes)",
			name, written);

	TF2Util_GetConditionName(view_as<TFCond>(count - 1), name, sizeof(name));
	Check(name[0] != '\0', "GetConditionName(last) = \"%s\"", name);

	TFCond back = TF2Util_GetConditionFromName(name);
	Check(view_as<int>(back) == count - 1, "GetConditionFromName(\"%s\") = %d", name, back);
	Check(TF2Util_GetConditionFromName("tf_cond_invulnerable") == TFCond_Ubercharged,
			"GetConditionFromName is case-insensitive");
	Check(view_as<int>(TF2Util_GetConditionFromName("no such condition")) == -1,
			"GetConditionFromName of an unknown name = -1");

	Check(TF2Util_IsCustomDamageTypeDOT(TF_CUSTOM_BLEEDING)
			&& TF2Util_IsCustomDamageTypeDOT(TF_CUSTOM_BURNING)
			&& !TF2Util_IsCustomDamageTypeDOT(TF_CUSTOM_HEADSHOT),
			"IsCustomDamageTypeDOT: bleeding and burning yes, headshot no");
}

// TF2Util_GetEntityMaxHealth, _GetPlayerMaxHealthBoost, _GetPlayerMaxHealth, _TakeHealth,
// _GetPlayerMaxAmmo
void Test_HealthAmmo() {
	int maxHealth = TF2Util_GetEntityMaxHealth(g_Target);
	int resource = GetPlayerResourceEntity();
	int expected = resource != -1
			? GetEntProp(resource, Prop_Send, "m_iMaxHealth", _, g_Target) : maxHealth;
	Check(maxHealth > 0 && maxHealth == expected, "GetEntityMaxHealth = %d (player resource %d)",
			maxHealth, expected);

	int boost = TF2Util_GetPlayerMaxHealthBoost(g_Target);
	Check(boost > maxHealth, "GetPlayerMaxHealthBoost = %d", boost);
	Check(TF2Util_GetPlayerMaxHealthBoost(g_Target, true, true) > 0,
			"GetPlayerMaxHealthBoost(ignore attributes, ignore overheal) = %d",
			TF2Util_GetPlayerMaxHealthBoost(g_Target, true, true));

	int old = CallDeprecatedMaxHealth(g_Target);
	Check(old == boost, "GetPlayerMaxHealth (old name) = %d", old);

	SetEntityHealth(g_Target, maxHealth - 30);
	int given = TF2Util_TakeHealth(g_Target, 20.0);
	Check(given == 20 && GetClientHealth(g_Target) == maxHealth - 10,
			"TakeHealth(20) gave %d, health now %d of %d", given, GetClientHealth(g_Target),
			maxHealth);
	SetEntityHealth(g_Target, maxHealth);

	int primary = GetPlayerWeaponSlot(g_Target, TFWeaponSlot_Primary);
	int ammoType = primary != -1 ? GetEntProp(primary, Prop_Send, "m_iPrimaryAmmoType") : 1;
	int maxAmmo = TF2Util_GetPlayerMaxAmmo(g_Target, ammoType);
	Check(maxAmmo > 0, "GetPlayerMaxAmmo(type %d) = %d", ammoType, maxAmmo);
	Check(TF2Util_GetPlayerMaxAmmo(g_Target, ammoType, TFClass_Heavy) > 0,
			"GetPlayerMaxAmmo(type %d, heavy) = %d", ammoType,
			TF2Util_GetPlayerMaxAmmo(g_Target, ammoType, TFClass_Heavy));
}

int CallDeprecatedMaxHealth(int client) {
	Function fn = GetFunctionByName(null, "DeprecatedMaxHealth");
	int result;
	Call_StartFunction(null, fn);
	Call_PushCell(client);
	Call_Finish(result);
	return result;
}

#pragma deprecated Only here so that the deprecated native is called too
public int DeprecatedMaxHealth(int client) {
	return TF2Util_GetPlayerMaxHealth(client);
}

// TF2Util_IsEntityWeapon, _IsEntityWearable, _GetWeaponSlot, _GetWeaponID, _GetWeaponMaxClip,
// _CanWeaponAttack, _SetPlayerActiveWeapon, _GetPlayerLoadoutEntity
void Test_Weapons() {
	int primary = GetPlayerWeaponSlot(g_Target, TFWeaponSlot_Primary);
	int melee = GetPlayerWeaponSlot(g_Target, TFWeaponSlot_Melee);
	if (primary == -1 || melee == -1) {
		Note("the target has no primary or melee weapon; weapon natives not checked");
		return;
	}

	Check(TF2Util_IsEntityWeapon(primary) && !TF2Util_IsEntityWeapon(g_Target),
			"IsEntityWeapon: the primary yes, the player no");
	Check(!TF2Util_IsEntityWearable(primary), "IsEntityWearable: the primary no");
	Check(TF2Util_GetWeaponSlot(primary) == TFWeaponSlot_Primary
			&& TF2Util_GetWeaponSlot(melee) == TFWeaponSlot_Melee,
			"GetWeaponSlot: primary %d, melee %d", TF2Util_GetWeaponSlot(primary),
			TF2Util_GetWeaponSlot(melee));

	int id = TF2Util_GetWeaponID(primary), meleeId = TF2Util_GetWeaponID(melee);
	Check(id > 0 && meleeId > 0 && id != meleeId, "GetWeaponID: primary %d, melee %d", id,
			meleeId);

	int clip = TF2Util_GetWeaponMaxClip(primary);
	Check(clip > 0 && clip >= GetEntProp(primary, Prop_Send, "m_iClip1"),
			"GetWeaponMaxClip(primary) = %d (holds %d now)", clip,
			GetEntProp(primary, Prop_Send, "m_iClip1"));
	Check(TF2Util_CanWeaponAttack(primary), "CanWeaponAttack(primary) = true");

	bool switched = TF2Util_SetPlayerActiveWeapon(g_Target, melee);
	Check(switched && GetEntPropEnt(g_Target, Prop_Send, "m_hActiveWeapon") == melee,
			"SetPlayerActiveWeapon(melee) = %d, active weapon is the melee", switched);
	TF2Util_SetPlayerActiveWeapon(g_Target, primary);
	Check(!TF2Util_SetPlayerActiveWeapon(g_Target, INVALID_ENT_REFERENCE),
			"SetPlayerActiveWeapon(no weapon) = false");

	// loadout slots 0 and 2 are primary and melee
	Check(TF2Util_GetPlayerLoadoutEntity(g_Target, 0) == primary
			&& TF2Util_GetPlayerLoadoutEntity(g_Target, 2, false) == melee,
			"GetPlayerLoadoutEntity: slot 0 = %d (primary %d), slot 2 = %d (melee %d)",
			TF2Util_GetPlayerLoadoutEntity(g_Target, 0), primary,
			TF2Util_GetPlayerLoadoutEntity(g_Target, 2, false), melee);
}

// TF2Util_EquipPlayerWearable, _GetPlayerWearableCount, _GetPlayerWearable,
// _IsEntityWearable, _SetWearableAlwaysValid
void Test_Wearables() {
	int before = TF2Util_GetPlayerWearableCount(g_Target);
	Check(before >= 0 && before < 64, "GetPlayerWearableCount = %d", before);

	int wearable = CreateEntityByName("tf_wearable");
	if (wearable == -1 || !DispatchSpawn(wearable)) {
		Note("could not create a tf_wearable; wearable natives not checked");
		return;
	}
	Check(TF2Util_IsEntityWearable(wearable), "IsEntityWearable: a tf_wearable yes");

	TF2Util_EquipPlayerWearable(g_Target, wearable);
	int after = TF2Util_GetPlayerWearableCount(g_Target);
	Check(after == before + 1, "EquipPlayerWearable: wearable count %d -> %d", before, after);

	bool found;
	for (int i; i < after; i++) {
		if (TF2Util_GetPlayerWearable(g_Target, i) == wearable) {
			found = true;
		}
	}
	Check(found, "GetPlayerWearable: the new wearable (%d) is in the player's list", wearable);

	TF2Util_SetWearableAlwaysValid(wearable, true);
	if (g_offsAlwaysValid > 0) {
		bool set = GetEntData(wearable, g_offsAlwaysValid, 1) != 0;
		TF2Util_SetWearableAlwaysValid(wearable, false);
		bool cleared = GetEntData(wearable, g_offsAlwaysValid, 1) == 0;
		Check(set && cleared, "SetWearableAlwaysValid: flag at offset %d went on (%d) and off (%d)",
				g_offsAlwaysValid, set, cleared);
		TF2Util_SetWearableAlwaysValid(wearable, true);
	} else {
		Note("SetWearableAlwaysValid called, but the offset to read it back is not known");
	}
}

// TF2Util_GetPlayerConditionDuration, _SetPlayerConditionDuration,
// _GetPlayerConditionProvider, _SetPlayerConditionProvider
void Test_ConditionData() {
	TF2_RemoveCondition(g_Target, TEST_COND);
	Check(TF2Util_GetPlayerConditionDuration(g_Target, TEST_COND) == 0.0
			&& TF2Util_GetPlayerConditionProvider(g_Target, TEST_COND) == INVALID_ENT_REFERENCE,
			"condition not active: duration 0, no provider");

	TF2_AddCondition(g_Target, TEST_COND, 10.0, g_Other);
	float duration = TF2Util_GetPlayerConditionDuration(g_Target, TEST_COND);
	Check(Near(duration, 10.0, 0.5), "GetPlayerConditionDuration = %.2f (added for 10)", duration);

	int provider = TF2Util_GetPlayerConditionProvider(g_Target, TEST_COND);
	Check(provider == g_Other, "GetPlayerConditionProvider = %d (added by %d)", provider,
			g_Other);

	TF2Util_SetPlayerConditionDuration(g_Target, TEST_COND, 5.0);
	duration = TF2Util_GetPlayerConditionDuration(g_Target, TEST_COND);
	Check(Near(duration, 5.0, 0.01), "SetPlayerConditionDuration(5) -> %.2f", duration);

	TF2Util_SetPlayerConditionProvider(g_Target, TEST_COND, g_Target);
	provider = TF2Util_GetPlayerConditionProvider(g_Target, TEST_COND);
	Check(provider == g_Target, "SetPlayerConditionProvider(%d) -> %d", g_Target, provider);

	// the neighbouring conditions must be untouched: this is what a wrong element size breaks
	Check(TF2Util_GetPlayerConditionDuration(g_Target, view_as<TFCond>(view_as<int>(TEST_COND) + 1))
			== 0.0, "the next condition's duration is still 0");
	TF2_RemoveCondition(g_Target, TEST_COND);
}

// TF2Util_IgnitePlayer, _GetPlayerBurnDuration, _SetPlayerBurnDuration
void Test_Burn() {
	Check(TF2Util_GetPlayerBurnDuration(g_Target) == 0.0, "not burning: burn duration 0");

	int weapon = GetPlayerWeaponSlot(g_Other, TFWeaponSlot_Primary);
	TF2Util_IgnitePlayer(g_Target, g_Other, 6.0,
			weapon == -1 ? INVALID_ENT_REFERENCE : weapon);
	if (!TF2_IsPlayerInCondition(g_Target, TFCond_OnFire)) {
		// teammates do not burn each other; no attacker at all still does
		TF2Util_IgnitePlayer(g_Target, INVALID_ENT_REFERENCE, 6.0);
	}
	if (!TF2_IsPlayerInCondition(g_Target, TFCond_OnFire)) {
		Note("IgnitePlayer called twice, but the target is not on fire; burn duration not checked");
		return;
	}

	float duration = TF2Util_GetPlayerBurnDuration(g_Target);
	Check(duration > 0.0 && duration <= 10.0, "IgnitePlayer(6): burn duration %.2f", duration);

	TF2Util_SetPlayerBurnDuration(g_Target, 3.0);
	duration = TF2Util_GetPlayerBurnDuration(g_Target);
	Check(Near(duration, 3.0, 0.01), "SetPlayerBurnDuration(3) -> %.2f", duration);
}

// TF2Util_MakePlayerBleed, _GetPlayerActiveBleedCount, _GetPlayerBleedAttacker, _Weapon,
// _NextDamageTick, _Duration, _Damage, _CustomDamageType
void Test_Bleed() {
	int before = TF2Util_GetPlayerActiveBleedCount(g_Target);
	Check(before == 0, "GetPlayerActiveBleedCount = %d before bleeding", before);

	int weapon = GetPlayerWeaponSlot(g_Other, TFWeaponSlot_Melee);
	int index = TF2Util_MakePlayerBleed(g_Target, g_Other, 8.0,
			weapon == -1 ? INVALID_ENT_REFERENCE : weapon, 3);
	int count = TF2Util_GetPlayerActiveBleedCount(g_Target);
	Check(index == 0 && count == 1, "MakePlayerBleed = index %d, bleed count %d", index, count);
	if (count < 1) {
		return;
	}

	Check(TF2Util_GetPlayerBleedAttacker(g_Target, 0) == g_Other,
			"GetPlayerBleedAttacker = %d (is %d)", TF2Util_GetPlayerBleedAttacker(g_Target, 0),
			g_Other);
	Check(TF2Util_GetPlayerBleedWeapon(g_Target, 0) == weapon,
			"GetPlayerBleedWeapon = %d (is %d)", TF2Util_GetPlayerBleedWeapon(g_Target, 0),
			weapon);

	float duration = TF2Util_GetPlayerBleedDuration(g_Target, 0);
	Check(Near(duration, 8.0, 0.5), "GetPlayerBleedDuration = %.2f (made for 8)", duration);
	Check(TF2Util_GetPlayerBleedDamage(g_Target, 0) == 3, "GetPlayerBleedDamage = %d (made 3)",
			TF2Util_GetPlayerBleedDamage(g_Target, 0));
	Check(TF2Util_GetPlayerBleedCustomDamageType(g_Target, 0) == TF_CUSTOM_BLEEDING,
			"GetPlayerBleedCustomDamageType = %d (bleeding is %d)",
			TF2Util_GetPlayerBleedCustomDamageType(g_Target, 0), TF_CUSTOM_BLEEDING);
}

void Test_BleedLater() {
	if (TF2Util_GetPlayerActiveBleedCount(g_Target) < 1) {
		Note("the bleed is gone after three seconds; its remaining time not checked");
		return;
	}
	float duration = TF2Util_GetPlayerBleedDuration(g_Target, 0);
	Check(Near(duration, 5.0, 0.6), "GetPlayerBleedDuration three seconds on = %.2f", duration);

	// not right after MakePlayerBleed: until the first tick the game keeps something else there.
	// A tick every half second; just below zero when one has come due and the game is yet to act
	float tick = TF2Util_GetPlayerBleedNextDamageTick(g_Target, 0);
	Check(tick > -0.1 && tick <= 0.6, "GetPlayerBleedNextDamageTick = %.2f", tick);
}

// TF2Util_IsPlayerImmuneToPushback, _GetPlayerRespawnTimeOverride,
// _SetPlayerRespawnTimeOverride, _GetPlayerShootPosition, _UpdatePlayerSpeed,
// _IsPointInRespawnRoom, _GetPlayerFromSharedAddress
void Test_PlayerState() {
	Check(!TF2Util_IsPlayerImmuneToPushback(g_Target), "IsPlayerImmuneToPushback = false");

	float respawn = TF2Util_GetPlayerRespawnTimeOverride(g_Target);
	Check(respawn == -1.0, "GetPlayerRespawnTimeOverride = %.1f while alive", respawn);
	// buffered while the player is alive; put back at once
	TF2Util_SetPlayerRespawnTimeOverride(g_Target, 7.5);
	TF2Util_SetPlayerRespawnTimeOverride(g_Target, -1.0);
	Check(TF2Util_GetPlayerRespawnTimeOverride(g_Target) == -1.0,
			"SetPlayerRespawnTimeOverride while alive leaves the stored value alone");

	float shoot[3], eyes[3];
	TF2Util_GetPlayerShootPosition(g_Target, shoot);
	GetClientEyePosition(g_Target, eyes);
	Check(GetVectorDistance(shoot, eyes) < 32.0,
			"GetPlayerShootPosition = %.0f %.0f %.0f (eyes %.0f %.0f %.0f)", shoot[0], shoot[1],
			shoot[2], eyes[0], eyes[1], eyes[2]);

	float speed = GetEntPropFloat(g_Target, Prop_Send, "m_flMaxspeed");
	SetEntPropFloat(g_Target, Prop_Send, "m_flMaxspeed", 1.0);
	TF2Util_UpdatePlayerSpeed(g_Target, true);
	Check(GetEntPropFloat(g_Target, Prop_Send, "m_flMaxspeed") == speed,
			"UpdatePlayerSpeed(immediate) put max speed back to %.0f", speed);
	TF2Util_UpdatePlayerSpeed(g_Target);

	float origin[3];
	GetClientAbsOrigin(g_Target, origin);
	bool inRoom = TF2Util_IsPointInRespawnRoom(origin, g_Target, true);
	float far[3] = { 16000.0, 16000.0, 16000.0 };
	Check(!TF2Util_IsPointInRespawnRoom(far),
			"IsPointInRespawnRoom: far outside the map no (the player's position: %s)",
			inRoom ? "yes" : "no");

	Address pShared = GetEntityAddress(g_Target)
			+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"));
	int owner = TF2Util_GetPlayerFromSharedAddress(pShared);
	Check(owner == g_Target, "GetPlayerFromSharedAddress = %d (is %d)", owner, g_Target);
}

// A dispenser at the target's feet, built by the target, is an object in their list
void Test_ObjectsSetup() {
	Check(TF2Util_GetPlayerObjectCount(g_Target) == 0, "GetPlayerObjectCount = %d before building",
			TF2Util_GetPlayerObjectCount(g_Target));

	int dispenser = CreateEntityByName("obj_dispenser");
	if (dispenser == -1) {
		Note("could not create an obj_dispenser; objects and healers not checked");
		return;
	}
	float origin[3];
	GetClientAbsOrigin(g_Target, origin);
	TeleportEntity(dispenser, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(dispenser);
	AcceptEntityInput(dispenser, "SetBuilder", g_Target);
	SetVariantInt(GetClientTeam(g_Target));
	AcceptEntityInput(dispenser, "SetTeam");
	g_Dispenser = EntIndexToEntRef(dispenser);

}

// TF2Util_GetPlayerObjectCount, _GetPlayerObject, _GetPlayerHealer
void Test_ObjectsHealers() {
	int dispenser = EntRefToEntIndex(g_Dispenser);
	int objects = TF2Util_GetPlayerObjectCount(g_Target);
	if (dispenser == -1 || objects < 1) {
		Note("the dispenser did not become the target's object (count %d); GetPlayerObject not "
				... "checked", objects);
	} else {
		Check(objects == 1 && TF2Util_GetPlayerObject(g_Target, 0) == dispenser,
				"GetPlayerObjectCount = %d, GetPlayerObject(0) = %d (the dispenser is %d)", objects,
				TF2Util_GetPlayerObject(g_Target, 0), dispenser);
	}

	// this condition has the player heal themselves, which puts them in their own healer list.
	// It also cures bleeding, which is why it is not added before this
	TF2_AddCondition(g_Target, TFCond_HalloweenQuickHeal, 10.0);

	int healers = GetEntProp(g_Target, Prop_Send, "m_nNumHealers");
	if (healers < 1) {
		Note("nothing is healing the target (m_nNumHealers %d); GetPlayerHealer not checked",
				healers);
		return;
	}
	bool found;
	for (int i; i < healers; i++) {
		if (TF2Util_GetPlayerHealer(g_Target, i) == g_Target) {
			found = true;
		}
	}
	Check(found, "GetPlayerHealer: the target (%d) is among their %d healer(s), first is %d",
			g_Target, healers, TF2Util_GetPlayerHealer(g_Target, 0));
	TF2_RemoveCondition(g_Target, TFCond_HalloweenQuickHeal);
}

// TF2Util_GetPlayerLastDamageReceivedTime
void Test_LastDamage() {
	SDKHooks_TakeDamage(g_Target, g_Other, g_Other, 1.0, DMG_GENERIC);
	float last = TF2Util_GetPlayerLastDamageReceivedTime(g_Target);
	Check(Near(last, GetGameTime(), 0.1),
			"GetPlayerLastDamageReceivedTime = %.2f (game time %.2f)", last, GetGameTime());
}

// TF2Util_StartLagCompensation, _FinishLagCompensation
void Test_LagCompensation() {
	// logged first: if the server goes down here, this is the last line
	LogMessage("T2U about to call StartLagCompensation / FinishLagCompensation");
	TF2Util_StartLagCompensation(g_Target);
	TF2Util_FinishLagCompensation(g_Target);
	Check(IsClientInGame(g_Target), "StartLagCompensation and FinishLagCompensation returned");
}

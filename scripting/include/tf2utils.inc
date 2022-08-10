/**
 * Provides a number of TF2-specific utilities that depend on gamedata to function without
 * potentially breaking on future updates.  An assortment of things that don't really belong in
 * their own specifically categorized library.
 * 
 * This includes calls to game functions and accessing various memory locations, as well as
 * provides helper functions for pointers.
 * 
 * This excludes things that require extensions not bundled with SourceMod
 * (such as DHooks, Source Scramble).
 */

#if defined __nosoop_tf2_utils_included
	#endinput
#endif

#define __nosoop_tf2_utils_included

#include <tf2_stocks>

#define TAKEHEALTH_IGNORE_MAXHEALTH		(DMG_BULLET) // Player can be overhealed with this bit set.
#define TAKEHEALTH_IGNORE_DEBUFFS		(DMG_SLASH)  // Currently unused?  Looks like it was originally for Pyro's FT healing debuff mechanism

/**
 * Attempts to heal the player for the specified amount.  This does not provide any indicators;
 * you will need to fire any related events yourself.
 * 
 * @param flHealth        Amount of health to heal.
 * @param bitsHealType    TakeHealth flags.  See TAKEHEALTH_* constants.
 * 
 * @return Amount of health granted after modifiers.
 */
native int TF2Util_TakeHealth(int client, float flHealth, int bitsHealType = 0);

/**
 * Returns the maximum amount of ammo a player can hold for the given ammo type.
 * 
 * @param iAmmoIndex      Ammo type.
 * @param playerClass     Player class.  If TFClass_Unknown, use the player's current class.
 * 
 * @return Maximum amount of ammo.
 */
native int TF2Util_GetPlayerMaxAmmo(int client, int iAmmoIndex,
		TFClassType playerClass = TFClass_Unknown);

/**
 * Returns the current maximum allowed health of an entity.
 */
native int TF2Util_GetEntityMaxHealth(int entity);

/**
 * Returns the maximum allowed overhealed health of a player, taking into account the amount
 * it can gain through overhealing by mediguns.
 * 
 * @param bIgnoreAttributes    
 * @param bIgnoreOverheal      Ignores excessive overheal.
 */
native int TF2Util_GetPlayerMaxHealthBoost(int client, bool bIgnoreAttributes = false,
		bool bIgnoreOverheal = false);

/**
 * Returns the number of conditions currently available in the game.  This value will be one
 * higher than the last valid condition.
 */
native int TF2Util_GetConditionCount();

/**
 * Returns the last valid condition.  Convenience function intended for loop termination.
 */
stock TFCond TF2Util_GetLastCondition() {
	return view_as<TFCond>(TF2Util_GetConditionCount() - 1);
}

/**
 * Given a valid condition index, stores its name in the given buffer.
 * 
 * @param cond         Condition index.
 * @param buffer       Buffer to store name.
 * @param maxlen       Maximum length of buffer.
 * @return             Number of bytes written.
 * @error              Condition index is invalid.
 */
native int TF2Util_GetConditionName(TFCond cond, char[] buffer, int maxlen);

/**
 * Returns the remaining time on a player condition, or 0.0 if the condition is not active.
 * 
 * This is just a wrapper around the internal condition list; some conditions may not accurately
 * report their duration here (such as burning).
 */
native float TF2Util_GetPlayerConditionDuration(int client, TFCond cond);

/**
 * Sets the remaining time on a player condition without reapplying the condition.
 * 
 * @error Condition is not active.
 */
native void TF2Util_SetPlayerConditionDuration(int client, TFCond cond, float duration);

/**
 * Returns the entity providing a player condition, or INVALID_ENT_REFERENCE if the condition is
 * not active.  0 is returned for "no inflictor".
 * 
 * (This is the entity described as the "inflictor" for `TF2_AddCondition`.)
 */
native int TF2Util_GetPlayerConditionProvider(int client, TFCond cond);

/**
 * Sets the entity providing a player condition without reapplying the condition.
 * 
 * (This is the entity described as the "inflictor" for `TF2_AddCondition`.)
 * 
 * @error Condition is not active.
 */
native void TF2Util_SetPlayerConditionProvider(int client, TFCond cond, int inflictor);

/**
 * Returns the remaining burn time on a given player.  By default this decreases at a fixed rate
 * over time; the rate may change based on fire resistances (such as while cloaked).
 * 
 * If the player is not burning, 0.0 is returned.
 */
native float TF2Util_GetPlayerBurnDuration(int client);

/**
 * Updates the remaining burn time on a given player.  This does not ignite players.  This
 * bypasses the 10 second maximum burn duration limitation added in Jungle Inferno; however,
 * the burn duration will be clamped the next time the player is (re)ignited.
 * 
 * @error Player is not already burning.
 */
native void TF2Util_SetPlayerBurnDuration(int client, float duration);

/**
 * Sets a client on fire.  This is effectively the same as `TF2_IgnitePlayer` but with the
 * additional ability to set the weapon (allowing attribute modifiers to take effect).
 * 
 * @param client      Target client index.
 * @param attacker    Attacker client index, or INVALID_ENT_REFERENCE for none.
 * @param duration    Duration of fire, in seconds.
 * @param weapon      Weapon entity, or INVALID_ENT_REFERENCE for none.
 * 
 * @note              As of Jungle Inferno, fire duration is capped to 10 seconds.
 * @error             Invalid clients, or non-weapon entity.
 */
native void TF2Util_IgnitePlayer(int client, int attacker, float duration,
		int weapon = INVALID_ENT_REFERENCE);

/**
 * @param client    Client index.
 * @return          Number of entries within the bleed list.
 * @error           Invalid client index, or bleed list index is out of bounds.
 */
native int TF2Util_GetPlayerActiveBleedCount(int client);

/**
 * @param client    Client index.
 * @param index     Index into the player's bleed list.
 * @return          Attacker client associated with the bleed effect.
 * @error           Invalid client index, or bleed list index is out of bounds.
 */
native int TF2Util_GetPlayerBleedAttacker(int client, int index);

/**
 * @param client    Client index.
 * @param index     Index into the player's bleed list.
 * @return          Weapon associated with the bleed effect, or INVALID_ENT_REFERENCE if invalid.
 * @error           Invalid client index, or bleed list index is out of bounds.
 */
native int TF2Util_GetPlayerBleedWeapon(int client, int index);

/**
 * @param client    Client index.
 * @param index     Index into the player's bleed list.
 * @return          Time remaining until this bleed effect deals damage to the given client.
 * @error           Invalid client index, or bleed list index is out of bounds.
 */
native float TF2Util_GetPlayerBleedNextDamageTick(int client, int index);

/**
 * @param client    Client index.
 * @param index     Index into the player's bleed list.
 * @return          Time remaining for the bleed effect.
 * @error           Invalid client index, or bleed list index is out of bounds.
 */
native float TF2Util_GetPlayerBleedDuration(int client, int index);

/**
 * @param client    Client index.
 * @param index     Index into the player's bleed list.
 * @return          Amount of damage inflicted per bleed 'tick'.
 * @error           Invalid client index, or bleed list index is out of bounds.
 */
native int TF2Util_GetPlayerBleedDamage(int client, int index);

/**
 * @param client    Client index.
 * @param index     Index into the player's bleed list.
 * @return          Custom damage type associated with the given bleed effect.
 * @error           Invalid client index, or bleed list index is out of bounds.
 */
native int TF2Util_GetPlayerBleedCustomDamageType(int client, int index);

/**
 * Induces the bleed effect on a client.  This is effectively the same as `TF2_MakeBleed`, with
 * support for additional parameters that the game provides.
 * 
 * If the player already has a matching attacker / weapon combination, that entry will be
 * updated instead.
 * 
 * @param client          Client index.
 * @param attacker        Attacking client's index.
 * @param duration        Duration of the effect.  If this is TFCondDuration_Infinite,
 *                        bleeding continues until the player removes it via medkit or
 *                        resupply.
 * @param weapon          Weapon associated with the bleed effect, or INVALID_ENT_REFERENCE to
 *                        not provide a weapon (behaving the same as `TF2_MakeBleed`).
 * @param damage          Amount of damage inflicted per bleed 'tick'.
 * @param damagecustom    Custom damage type (see TF_CUSTOM_* constants).
 * @return                Index into the player's bleed list where the effect was added, or -1
 *                        if the plugin could not determine the index.
 */
native int TF2Util_MakePlayerBleed(int client, int attacker, float duration,
		int weapon = INVALID_ENT_REFERENCE, int damage = 4,
		int damagecustom = TF_CUSTOM_BLEEDING);

/**
 * Returns true if the given player is immune to pushback.
 * 
 * @param client    Client index.
 * 
 * @error           Invalid client or not in game.
 */
native bool TF2Util_IsPlayerImmuneToPushback(int client);

/**
 * Returns the player's respawn time override, if any.  This is the number of seconds that a
 * player will spend waiting to be respawned after their last death (CTFPlayer::m_flDeathTime).
 * 
 * When a player dies, the game will set this value to -1.0 or the RespawnTime value of an
 * active trigger_player_respawn_override entity that the player died in, if one exists.
 * (This happens *after* the `player_death` event is fired, so you cannot retrieve their respawn
 * time override during a hook on that event.)
 * 
 * The amount of time remaining can be computed as follows:
 * 
 *     flRemainingTime = flDeathTime + flRespawnTimeOverride - GetGameTime();
 * 
 * If the player does not have an override on their respawn time (i.e. they are part of normal
 * respawn waves), this will return -1.0.  If the player is alive, this will return whatever is
 * stored on the entity (normally -1.0), and *not* any buffered value that was set using
 * `TF2Util_SetPlayerRespawnTimeOverride`.
 * 
 * @error Invalid client.
 */
native float TF2Util_GetPlayerRespawnTimeOverride(int client);

/**
 * Changes the player's respawn time override.  See `TF2Util_GetPlayerRespawnTimeOverride` above
 * for an explanation of the value.
 * 
 * If the player is not alive, setting this value to -1.0 will remove any existing respawn time
 * overrides, and the player will respawn in the next wave they are allowed to spawn in.
 * 
 * If the player is alive, setting this value to one other than -1.0 will cause TF2Utils to
 * buffer the value and update the player's respawn time override at some point after they die
 * (allowing plugins to set a respawn time override while the player is alive or during a
 * `player_death` event hook).
 * 
 * @error Invalid client.
 */
native void TF2Util_SetPlayerRespawnTimeOverride(int client, float time);

/**
 * Returns the player's shoot position.
 */
native void TF2Util_GetPlayerShootPosition(int client, float result[3]);

/**
 * @return    Object (building) entity index at the given array index, or -1 on invalid object
 *            entity reference.
 * @error     Invalid client or index is out of bounds.
 */
native int TF2Util_GetPlayerObject(int client, int index);

/**
 * @return    Number of objects (buildings) in a given client's object array.
 * @error     Invalid client.
 */
native int TF2Util_GetPlayerObjectCount(int client);

/**
 * Returns the healer entity index at the given index in the player's healer array.
 * To get the number of healers available, use the m_nNumHealers netprop.
 * 
 * @return    Healer entity index at the given array index, or -1 on invalid healer entity
 *            reference.
 * @error     Index is out of bounds.
 */
native int TF2Util_GetPlayerHealer(int client, int index);

/**
 * Returns the time that the player was last damaged.
 * 
 * @error    Invalid client, or index is out of bounds.
 */
native float TF2Util_GetPlayerLastDamageReceivedTime(int client);

/**
 * Returns whether or not the given entity is a weapon.
 * 
 * @error Entity is not valid.
 */
native bool TF2Util_IsEntityWeapon(int entity);

/**
 * Returns whether or not the given entity is a wearable.
 * 
 * @error Entity is not valid.
 */
native bool TF2Util_IsEntityWearable(int entity);

/**
 * Returns the weapon entity's designated weapon slot.  This corresponds to the TFWeaponSlot_*
 * constants in tf2_stocks.
 * 
 * @error Entity is not valid or not a weapon.
 */
native int TF2Util_GetWeaponSlot(int entity);

/**
 * Returns the weapon entity's weapon ID.  This corresponds to the TF_WEAPON_* constants in
 * tf2_stocks, *not* the item definition index.
 * 
 * @error Entity is not valid or not a weapon.
 */
native int TF2Util_GetWeaponID(int entity);

/**
 * Returns the weapon entity's maximum clip (that is, the maximum number of times it can be
 * fired before reloading).
 * 
 * @error Entity is not valid or not a weapon.
 */
native int TF2Util_GetWeaponMaxClip(int entity);

/**
 * @return    Client's wearable entity index at the given wearable array index, or -1 on invalid
 *            wearable entity reference.
 * @error     Invalid client, or index is negative or out of bounds.
 */
native int TF2Util_GetPlayerWearable(int client, int index);

/**
 * @return    Number of items in the player's wearable array.
 * @error     Invalid client.
 */
native int TF2Util_GetPlayerWearableCount(int client);

/**
 * If `includeWearableWeapons` is true, weapon slots (primary, secondary, melee, utility,
 * building, pda, pda2) are also checked for wearable items.  Otherwise, wearables in those
 * slots (Sniper / Demoman shields) are ignored.
 * 
 * Note that the game validates that the player is using a class that can equip the given item;
 * any items not applicable to the class are ignored.
 * 
 * This also does not differentiate between different cosmetic slots (all cosmetics will match
 * on the first loadout slot).  If you want to get cosmetic entities on a given player, you will
 * instead want to use `TF2Util_GetPlayerWearable` / `TF2Util_GetPlayerWearableCount`.
 * Identifying specific occupied cosmetic loadout slots is currently not supported.
 * 
 * @return    Entity index on the given client occupying the given loadout slot, or -1 on
 *            invalid entity reference or no entity matched.
 */
native int TF2Util_GetPlayerLoadoutEntity(int client, int loadoutSlot,
		bool includeWearableWeapons = true);

/**
 * Equips the given wearable entity onto the given client.
 * 
 * @error Client is invalid, entity is not a wearable, wearable was not spawned, or assertion
 *        failed to verify that the wearable was successfully attached (outdated gamedata).
 */
native void TF2Util_EquipPlayerWearable(int client, int wearable);

/**
 * Marks a wearable as "always valid", preventing it from removal during resupply events.
 * 
 * @error Entity is not a wearable.
 */
native void TF2Util_SetWearableAlwaysValid(int wearable, bool alwaysValid);

/**
 * Forces an update to the given player's speed.
 * 
 * @param immediate    Whether or not the speed is updated immediately.  If this is set to
 *                     false, the call will be defered and batched so all non-immediate calls
 *                     will only trigger one update to the player's speed at most per frame.
 *                     (This is designed to accomodate plugins using detours on player speed
 *                     calculations.)
 */
native void TF2Util_UpdatePlayerSpeed(int client, bool immediate = false);

/**
 * Returns whether or not a position / entity is in an active respawn room.  If an entity is
 * passed in, this also checks if the entity is touching an active respawn room, instead of just
 * the given position.
 * 
 * @param position               Position to check; should be the center / origin of an entity.
 * @param entity                 An optional entity to check.
 * @param bRestrictToSameTeam    Whether or not the respawn room must either match the entity's
 *                               team, or not be assigned to a team.  Always treated as true if
 *                               the position is in an active spawn room.  Has no effect if no
 *                               entity is provided.
 */
native bool TF2Util_IsPointInRespawnRoom(const float position[3],
		int entity = INVALID_ENT_REFERENCE, bool bRestrictToSameTeam = false);

/**
 * Returns whether or not the given custom damage type is for a "damage over time" effect.
 * This is provided to allow plugins to identify periodic damage events without hardcoding that
 * information themselves.
 * 
 * @param damagecustom    Custom damage type.  This is provided by the SDKHooks OnTakeDamage
 *                        set of hooks as 'damagecustom', among other places.
 * @return                True if the given value matches a known DOT effect; false otherwise.
 */
native bool TF2Util_IsCustomDamageTypeDOT(int damagecustom);

/**
 * Given the address of a CTFPlayerShared instance, returns the player associated with it.
 * 
 * Here be dragons.
 * 
 * @param pShared    Address of CTFPlayerShared instance.
 */
native int TF2Util_GetPlayerFromSharedAddress(Address pShared);

/**
 * Returns the current maximum health of the player.
 */
#pragma deprecated Misnamed; use TF2Util_GetEntityMaxHealth or TF2Util_GetPlayerMaxHealthBoost.
native int TF2Util_GetPlayerMaxHealth(int client, bool bIgnoreAttributes = false,
		bool bIgnoreOverheal = false);

// compile-time compatibility shim for tf2wearables natives
#if defined USE_TF2WEARABLE_FUNCTION_SHIMS
	#define TF2_GetPlayerLoadoutSlot    TF2Util_GetPlayerLoadoutEntity
	#define TF2_EquipPlayerWearable     TF2Util_EquipPlayerWearable
	#define TF2_IsWearable              TF2Util_IsEntityWearable
#endif

public SharedPlugin __pl_tf2utils = {
	name = "nosoop_tf2utils",
	file = "tf2utils.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

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
 * Attempts to heal the player for the specified amount.
 * 
 * @param flHealth        Amount of health to heal.
 * @param bitsHealType    TakeHealth flags.  See TAKEHEALTH_* constants.
 * 
 * @return Amount of health granted after modifiers.
 */
native int TF2Util_TakeHealth(int client, float flHealth, int bitsHealType = 0);

/**
 * Returns the maximum amount of ammo for the given ammo type.
 * 
 * @param iAmmoIndex      Ammo type.
 * @param playerClass     Player class.  If TFClass_Unknown, use the player's current class.
 * 
 * @return Maximum amount of ammo.
 */
native int TF2Util_GetPlayerMaxAmmo(int client, int iAmmoIndex,
		TFClassType playerClass = TFClass_Unknown);

/**
 * Returns the current maximum health of the player.
 */
native int TF2Util_GetPlayerMaxHealth(int client, bool bIgnoreAttributes = false,
		bool bIgnoreOverheal = false);

/**
 * Returns whether or not the given entity is a weapon.
 * 
 * @error Entity is not valid.
 */
native bool TF2Util_IsEntityWeapon(int entity);

/**
 * Returns the slot for the given weapon entity.
 * 
 * @error Entity is not valid or not a weapon.
 */
native int TF2Util_GetWeaponSlot(int entity);

/**
 * Returns the weapon entity's weapon ID.  This corresponds to the TF_WEAPON_* weapon codes in
 * tf2_stocks, *not* the item definition index.
 * 
 * @error Entity is not valid or not a weapon.
 */
native int TF2Util_GetWeaponID(int entity);

/**
 * @return Wearable entity at the given index.
 * @error Index is negative or out of bounds.
 */
native int TF2Util_GetPlayerWearable(int client, int index);

/**
 * @return Number of items in the player's wearable array.
 */
native int TF2Util_GetPlayerWearableCount(int client);

/**
 * Forces an update to the given player's speed.
 * 
 * @param immediate Whether or not the speed is updated immediately.  If this is set to false,
 * the call will be defered in a way that any number of calls to this native in the same frame
 * will only result in at most one update more than the number of immediate calls (intended to
 * reduce the number of calls forwarded to plugins that detour the maximum speed calculation).
 */
native void TF2Util_UpdatePlayerSpeed(int client, bool immediate = false);

public SharedPlugin __pl_tf2utils = {
	name = "nosoop_tf2utils",
	file = "tf2utils.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

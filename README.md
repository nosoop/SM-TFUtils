# TF2 Utils

SourceMod utility natives for Team Fortress 2.  Mainly focused around gameplay-related
functionality that require gamedata that may break during updates, including calls to game
functions and raw memory accessors that aren't already in some other library.

One of the design decisions is to only use dependencies built-in to SourceMod.  That means this
excludes most hooks (handled by [DHooks][]), and `SDKCall`s that require allocation of some
structure (which can be done with [Source Scramble][]).

[DHooks]: https://github.com/peace-maker/DHooks2/
[Source Scramble]: https://github.com/nosoop/SMExt-SourceScramble/

## Installation

Go to the releases page and get the following from the topmost release:

- Copy `tf2utils.smx` to `plugins/`
- Copy `tf2.utils.nosoop.txt` to `gamedata/`
- Copy `tf2utils.inc` to `scripting/include/`

## Similar plugins

There are a number of shared plugins for TF2 that are focused on specific aspects.
These include:

- [TF2Attributes][], which handles runtime application of attributes on players and weapons
- [Econ Data][], which provides low-level read access to schema properties
- [DamageInfo Tools][], which provides a small set of functionality to deal with
`CTakeDamageInfo` and `CTFRadiusDamageInfo` types.  (Requires [Source Scramble][].)
- [TF2-API][], a set of global hooks for TF2.  (Requires [DHooks][].)
- [TakeHealth Proxy][], a single-purpose plugin to override the amount of health given to a
player.  (Requires [DHooks][].)
- [Calculate Max Speed Detour][], a single-purpose extension to override the player's max speed.

[TF2Attributes]: https://github.com/nosoop/tf2attributes
[Econ Data]: https://github.com/nosoop/SM-TFEconData
[DamageInfo Tools]: https://github.com/nosoop/SM-TFDamageInfo
[TF2-API]: https://github.com/Drixevel/TF2-API
[TakeHealth Proxy]: https://github.com/nosoop/SM-TFTakeHealthProxy
[Calculate Max Speed Detour]: https://github.com/nosoop/SMExt-TFMaxSpeedDetour

## Merged plugins

The following plugins have some of their functionality merged in.

- [TF2 Wearable Tools][], which provides some functionality to access currently equipped
wearable entities or attach new ones.

[TF2 Wearable Tools]: https://github.com/nosoop/sourcemod-tf2wearables

## Building

This plugin depends on [stocksoup][] for compilation.  This project is also configured for
building via [Ninja][]; see `BUILD.md` for detailed instructions on how to build it. tl;dr:

    git clone --recurse-submodules ${repo_url} ${repo_local_dir}
    cd ${repo_local_dir}
    python3 configure.py --spcomp-dir ${spcomp_dir}
    ninja

If you'd like to use the build system for your own projects,
[the template is available here](https://github.com/nosoop/NinjaBuild-SMPlugin).

[Ninja]: https://ninja-build.org/

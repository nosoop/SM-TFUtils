# TF2 Utils

SourceMod utility natives for Team Fortress 2.  Mainly focused around things that require
gamedata that may break during updates, including calls to game functions and raw memory
accessors that aren't already in some other library.

One of the design decisions is to only use dependencies built-in to SourceMod.  That means this
excludes all hooks (handled by [DHooks][]), and `SDKCall`s that require allocation of some
structure (which can be done with [Source Scramble][]).

[DHooks]: https://github.com/peace-maker/DHooks2/
[Source Scramble]: https://github.com/nosoop/SMExt-SourceScramble/

## Similar plugins

There are a number of shared plugins for TF2 that are focused on specific aspects.
These include:

- [TF2Attributes][], which handles runtime application of attributes on players and weapons
- [Econ Data][], which provides low-level read access to schema properties
- [TF2 Wearable Tools][], which provides some functionality to access currently equipped
wearable entities or attach new ones.

[TF2Attributes]: https://github.com/nosoop/tf2attributes
[Econ Data]: https://github.com/nosoop/SM-TFEconData
[TF2 Wearable Tools]: https://github.com/nosoop/sourcemod-tf2wearables

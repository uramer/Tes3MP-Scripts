This script requires a recent version of CoreScripts that you can find at https://github.com/TES3MP/CoreScripts
([commit](https://github.com/TES3MP/CoreScripts/commit/8b43e179c0d5eb0756dc315f43fa58246462eaa1) or later).

To install it:
* paste the contents of this folder into your *mp-stuff/* folder, found in your tes3mp installation
* add the following line to your *mp-stuff/scripts/customScripts.lua*: *require("urm_cellReset")*.

This script simply removes all but specified cells' files on server startup, if enough time has passed since they were last visited. This allows creatures to spawn in a way most similar to the single player game.

You can find the configuration file in *mp-stuff/data/config/urm_cellReset.json*.
* "excludeCells" is a list of cells you don't want to be reset at all. Keep in mind that the names are case sensitive.
* "resetTime" is the amount of time that will have to pass until a cell is reset. Units are game hours or real time minutes, depending on the "useGameTime" setting.
* "useGameTime" switches between game time and real time for cell reset purposes.
* "dataPath" is a filepath to the file used by this script to store reset times. Only change this if you know what you are doing.
This script requires a recent version of CoreScripts that you can find at https://github.com/TES3MP/CoreScripts
([commit](https://github.com/TES3MP/CoreScripts/commit/8b43e179c0d5eb0756dc315f43fa58246462eaa1) or later).

To install it:
* paste the contents of this folder into your `mp-stuff/` folder, found in your tes3mp installation
* add the following line to your `mp-stuff/scripts/customScripts.lua`: `require("urm_doubleTrouble")`.

This script only handles cells whose files have not existed in `mp-stuff/data/cells` at server startup, to avoid processing the same cell twice. That means, that only cell reset scripts that actually remove those files will cause creatures to be re-duplicated. One such script is my own [**cellReset**](https://github.com/uramer/Tes3MP-Scripts/tree/master/CellReset).

You can find the configuration file in `mp-stuff/data/config/urm_doubleTrouble.json`.
* `"copies"` how many copies of the same creature you want to have. The default value is 5.
* `"creatures"` a list of all creatures' refIds that should be duplicated. This is largely arbitrary, feel free to change it.
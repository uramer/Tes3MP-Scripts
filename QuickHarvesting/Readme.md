This script requires a recent version of CoreScripts that you can find at https://github.com/TES3MP/CoreScripts
([commit](https://github.com/TES3MP/CoreScripts/commit/8b43e179c0d5eb0756dc315f43fa58246462eaa1) or later).

To install it:
* paste the contents of this folder into your `mp-stuff/` (or whatever your `home` is set to in `tes3mp-server-default.cfg`) folder, found in your tes3mp installation
* add the following line to your `mp-stuff/scripts/customScripts.lua`: `require("urm_quickHarvesting")`.

This is essentially a tes3mp version of graphic herbalism. Players can activate plants, removing them from the world and gaining ingredients. Whenever a cell is loaded, all the harvested plants respawn, if enough time has passed.

You can find the configuration file in `mp-stuff/data/config/urm_quickHarvesting.json`.
* `"dataPath"` path to a file used to store plant data
* `"alchemyDeterminesChance"` default value is `true`. Determines, whether the amount of ingredients gathered depends purely on chance, or also on the player's alchemy skill.
* `"menuId"` should only be changed if another script is using the same `menuId`
* `"respawnTime"` how much time (in game hours) should pass until a plant grows again. By default is set to 720 = 24*30, same as vanilla Morrowind
* `"plants"` data on what ingredients you can gather from various plants. You can find the syntax below:
    
```
"<container refId>": {
    "ingredient": "<ingredient refId>",
    "amount": {
        "0": <highest roll taht gives 0 ingredients>",
        "1": <highest roll taht gives 0 ingredients>",
        ...
    }
}```
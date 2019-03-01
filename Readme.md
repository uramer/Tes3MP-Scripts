Every folder in this repository corresponds to a separate script for the tes3mp server, version **0.7-alpha**.

All of them require the **EventManager** you can find in the folder with the same name.

Some of the might require additional dependencies on other scripts, those will be listed in the appropriate readme files.

They can also have a configuration file in `data/config/<script_filename>.json` or store some additional data in `data/scripts/<data_filename>.json` with the latter path available to be changed in the configuration file.

All you need to install a script is copy the contents of its folder into your `mp-stuff/` folder and add a `require('<script_filename>')` line to your `plugins.lua` file (comes with the **EventManager**).
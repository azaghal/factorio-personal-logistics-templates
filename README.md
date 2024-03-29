Personal Logistics Templates
============================


About
-----

*Personal Logistics Templates* allows players to quickly and easily import and export personal logistics requests as blueprints. Such blueprints can be easily shared, stored, and managed using the blueprint library.


Features
--------

Character logistics requests technology effect must be researched prior to using any of the listed features - otherwise none of the buttons will be shown to the player.


### Create templates

Hold an empty blueprint while the character or spidetron windows are open, and an export button will be shown at bottom-left of the window. Clicking on the button while holding an empty blueprint will read information about currently configured personal logistics requests, and export them to blueprint in the form of constant combinators (see below section on format). The export button is visible _only_ when an empty, non-library blueprint is held.


### Set requests from templates

Hold a personal logistics requests template (blueprint) while the character or spidetron windows are open, and import buttons will be shown at bottom-left of the window. Buttons are shown _only_ when valid personal logistics template blueprints are held. Each button provides different mode of operation:

-   Import held template, _replacing all existing_ personal logistics requests (button with an arrow pointing up). Slot layout from the template is preserved.
-   Append held template,  _appending and replacing_ logistics requests (button with a circled plus sign). Slot layout from the template is preserved.
-   Set requests using held template, _adding new and overwriting existing_ personal logistics requests (button with an equals sign). New requests are appended at the end, starting from a first blank row. Slot layout from the template is not preserved. This mode is useful for combining modular set of templates and reseting to default template request values.
-   Increment requests using held template, _adding to existing and appending new_ personal logistics requests (button with a plus sign). New requests are appended at the end, starting from a first blank row. Slot layout from the template is not preserved. This mode is useful for increasing the amounts of existing requested items.
-   Decrement requests using held template, _substracting from existing_ personal logistics requests (button with a minus sign). If request minimum is already zero, and maximum would be decreased to zero as well, the request is cleared. This mode is useful for decreasing the amounts of existing requested items.


### Auto-trash unrequested items or clear all requests

Hold a blank deconstruction planner while the character or spidertron windows are open, and buttons for more destructive operations will be shown at bottom-left of the window:

-   Auto-trash all unrequested items by setting up requests with maximum amount set to zero (button with a filled-in trash can). This is useful when used for construction spidertrons to ensure their main inventory does not get clogged-up with unwanted items (such as stone, wood etc). Blueprints, deconstruction planners, upgrade planners, and blueprint books are always excluded from auto-trashing. Auto-trash requests are separated from regular requests by two (if possible) or one (at minimum) blank rows of requests.
-   Clear auto-trash personal logistics requests (button with an empty trash can).
-   Clear all personal logistics requests (button with a crossed-out circle). Single-click solution.


### Template format

Valid personal logistics requests blueprints contain only constant combinators, with signals specifying minimum and maximum values for personal logistics requests.

Each constant combinator represents a single slot in the personal logistics requests configuration. Constant combinators are read from top to bottom and from left to right. Normally they will be laid-out aligned rows, with each row consisting out of 10 combinators (mapping directly to the layout in personal logistics requests window).

Each constant combinator has minimum and maximum values specified in the first slot of the first and second row (respectively). The mod will tolerate if minimum/maximum values are swapped around. Both slots must be defined, and must have the matching items. No other slots can be defined.

Since constant combinators use _signed_ 32-bit integers, and personal logistics slots use _unsigned_ 32-bit integers, overflowing values are stored as negative values, with -1 corresponding to 2147483648, and -2147483648 corresponding to 4294967296. The 4294967296 (-2147483648) value specifically corresponds to infinte amount in a personal logistics request.


Known issues
------------

-   Button tooltips have extra spacing on the top. The extra spacing is added on purpose in order to make the tooltip text readable when holding a blueprint with a name. Otherwise the blueprint name is drawn on top of the tooltip, rendering it unreadable due to overlap. Unfortunately, there is nothing that can be done for this on the mod side - see [this post](https://forums.factorio.com/viewtopic.php?f=7&t=105698) for more details.


Contributions
-------------

Bugs and feature requests can be reported through discussion threads or through project's issue tracker. For general questions, please use discussion threads.

Pull requests for implementing new features and fixing encountered issues are always welcome.


Credits
-------

Creation of this mod has been inspired by [Quickbar Templates](https://mods.factorio.com/mod/QuickbarTemplates), mod which implements import and export of quickbar filters as blueprint templates.


License
-------

All code, documentation, and assets implemented as part of this mod are released under the terms of MIT license (see the accompanying `LICENSE` file), with the following exceptions:

-   [assets/delivery-drone.svg](https://game-icons.net/1x1/delapouite/delivery-drone.html), by Delapouite, under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/), used in creation of modpack thumbnail.
-   [build.sh (factorio_development.sh)](https://code.majic.rs/majic-scripts/), by Branko Majic, under [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html).
-   `graphics/icons/append-template-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/auto-trash-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/clear-auto-trash-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/clear-requests-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/decrement-requests-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/export-template-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/import-template-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/increment-requests-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/set-requests-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).

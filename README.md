Personal Logistics Templates
============================


About
-----

*Personal Logistics Templates* allows players to quickly and easily import and export personal logistics requests as blueprints. Such blueprints can be easily shared, stored, and managed using the blueprint library.


Features
--------


### Create templates

Hold an empty blueprint while the character or spidetron windows are open, and an export button will be shown at bottom-left of the window. Clicking on the button while holding an empty blueprint will read information about currently configured personal logistics requests, and export them to blueprint in the form of constant combinators (see below section on format). The export button is visible _only_ when an empty, non-library blueprint is held.


### Set requests from templates

Hold a personal logistics requests template (blueprint) while the character or spidetron windows are open, and import buttons will be shown at bottom-left of the window. Buttons are shown _only_ when valid personal logistics template blueprints are held. Each button provides different mode of operation:

-   Import held template, _replacing_ all existing personal logistics requests (button with arrow pointing up). Slot layout from the template is preserved.
-   Append held template, _preserving_ all existing personal logistics requests (button with a plus sign). New requests are appended at the end, starting from a first blank row. This mode is useful for having a modular set of templates that can be combined as desired.


### Auto-trash unrequested items or clear all requests

Hold a blank deconstruction planner while the character or spidertron windows are open, and buttons for more destructive operations will be shown at bottom-left of the window:

-   Auto-trash all unrequested items by setting up requests with maximum amount set to zero. These requests are appended at the end, with an extra blank line above them. This is useful when used for construction spidertrons to ensure their main inventory does not get clogged-up with unwanted items (such as stone, wood etc). Blueprints, deconstruction planners, upgrade planners, and blueprint books are always excluded from auto-trashing.
-   Clear all personal logistics requests. Single-click solution.


### Template format

Valid personal logistics requests blueprints contain only constant combinators, with signals specifying minimum and maximum values for personal logistics requests.

Each constant combinator represents a single line of slots in the personal logistics requests configuration. Constant combinators are laid-out in columns of up to ten, and each column is read from left to right. For example:

- Constant combinator in first column, first row corresponds to first row of personal logistics requests slots.
- Constant combinator in first column, second row corresponds to second row of personal logistics requests slots.
- Constant combinator in second column, first row corresponds to eleventh row of personal logistics requests slots.

In an individual constant combinator, the top ten signals correspond to minimum values, while bottom ten signals correspond to maximum values for a particular item request slot (in a single row). The item type for top and bottom slot in a column must match.

Since constant combinators use _signed_ 32-bit integers, and personal logistics slots use _unsigned_ 32-bit integers, overflowing values are stored as negative values, with -1 corresponding to 2147483648, and -2147483648 corresponding to 4294967296. The 4294967296 (-2147483648) value specifically corresponds to infinte amount in a personal logistics request.


Tips and tricks
---------------

-   Create an empty template blueprint, and use it to reset all personal logistics requests when needed.


Known issues
------------

There are no known issues at this time.


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

-   [assets/bookshelf.svg](https://game-icons.net/1x1/delapouite/bookshelf.html), by Delapouite, under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/), used in creation of modpack thumbnail.
-   [assets/delivery-drone.svg](https://game-icons.net/1x1/delapouite/delivery-drone.html), by Delapouite, under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/), used in creation of modpack thumbnail.
-   [build.sh (factorio_development.sh)](https://code.majic.rs/majic-scripts/), by Branko Majic, under [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html).
-   `graphics/icons/export-template-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/import-template-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).
-   `graphics/icons/append-template-button.png`, which is a derivative based on Factorio game assets as provided by *Wube Software Ltd*. For details, see [Factorio Terms of Service](https://www.factorio.com/terms-of-service).

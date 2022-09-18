Personal Logistics Templates
============================


About
-----

*Personal Logistics Templates* allows players to quickly and easily import and export personal logistics requests as blueprints. Such blueprints can be easily shared, stored, and managed using the blueprint library.


Features
--------

-   Export personal logistics requests by opening up the character screen/spidetron window, picking up an empty blueprint and clicking with it onto the export button attached to the bottom-left of window.
-   Import personal logistics requests blueprint by opening up the character screen/spidetron window, picking up a blueprint, and clicking with it onto the import button attached to the bottom-left of the window.
-   Export/import buttons are hidden when holding an invalid personal logistics requests blueprint.


### Template format

Valid personal logistics requests blueprints contain only constant combinators, with signals specifying minimum and maximum values for personal logistics requests.

Each constant combinator represents a single line of slots in the personal logistics requests configuration. Constant combinators are laid-out in columns of up to ten, and each column is read from left to right. For example:

- Constant combinator in first column, first row corresponds to first row of personal logistics requests slots.
- Constant combinator in first column, second row corresponds to second row of personal logistics requests slots.
- Constant combinator in second column, first row corresponds to eleventh row of personal logistics requests slots.

In an individual constant combinator, the top ten signals correspond to minimum values, while bottom ten signals correspond to maximum values for a particular item request slot (in a single row). The item type for top and bottom slot in a column must match.

Since constant combinators use _signed_ 32-bit integers, and personal logistics slots use _unsigned_ 32-bit integers, overflowing values are stored as negative values, with -1 corresponding to 2147483648, and -2147483648 corresponding to 4294967296. The 4294967296 (-2147483648) value specifically corresponds to infinte amount in a personal logistics request.


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

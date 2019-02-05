# easydb-custom-data-type-dante

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeDante` for references to entities of the [DANTE-Vokabulary-Server (https://dante.gbv.de)](https://dante.gbv.de).

The Plugins uses <https://api.dante.gbv.de/> for the communication with DANTE.

## configuration

As defined in `CustomDataTypeDante.config.yml` this datatype can be configured:

### Schema options

* which "vocabulary_name" to use. List of Vocabularys [in DANTE](https://dante.gbv.de/search?ot=vocabulary) or [as JSKOS via API](https://api.dante.gbv.de/voc) or [uri.gbv.de/terminology](http://uri.gbv.de/terminology/)
  * for the popup-modes multible vocabularys can be set as a "|"-splitted list
* which mapbox-access-token to use

### Mask options

* whether to use as dropdown or as popup or popup with treeview
* whether to use the cache
* whether to use default values

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptFulltext
    * fulltext-string which contains: PrefLabels, AltLabels, HiddenLabels, Notations
* conceptAncestors
    * URI's of all given ancestors
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard
## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-dante>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-dante/issues) for bug reports and feature requests!


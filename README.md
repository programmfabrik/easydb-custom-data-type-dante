# easydb-custom-data-type-dante

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeDante` for references to entities of the [DANTE-Vokabulary-Server (https://dante.gbv.de)](https://dante.gbv.de).

The Plugins uses <https://api.dante.gbv.de/> for the communication with DANTE.

## configuration

As defined in `CustomDataTypeDante.config.yml` this datatype can be configured:

### Schema options

* which "vocabulary_name" to use. List of Vocabularys [in DANTE](https://dante.gbv.de/search?ot=vocabulary) or [as JSKOS via API](https://api.dante.gbv.de/voc)
* which mapbox-access-token to use

### Mask options

* whether to use as dropdown or as popup or popup with treeview
* whether to use the cache
* whether to use default values

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-dante>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-dante/issues) for bug reports and feature requests!


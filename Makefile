PLUGIN_NAME = custom-data-type-dante

L10N_FILES = l10n/$(PLUGIN_NAME).csv
L10N_GOOGLE_KEY = 1ux8r_kpskdAwTaTjqrk92up5eyyILkpsv4k96QltmI0
L10N_GOOGLE_GID = 578343553
L10N2JSON = python easydb-library/tools/l10n2json.py

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(JS) \
	CustomDataTypeDante.config.yml

# XXX: missing languages, so the following files are not installable
#	$(WEB)/l10n/es-ES.json \
#	$(WEB)/l10n/it-IT.json \

MAPBOX1 = src/external/geojson-extent.js
MAPBOX2 = src/external/geo-viewport.js

COFFEE_FILES = easydb-library/src/commons.coffee \
	src/webfrontend/CustomDataTypeDante.coffee \
  src/webfrontend/CustomDataTypeDanteParseJSKOS.coffee \
  src/webfrontend/CustomDataTypeDanteTreeview.coffee

all: build

include easydb-library/tools/base-plugins.make

build: code $(L10N)

code: $(subst .coffee,.coffee.js,${COFFEE_FILES})
	mkdir -p build
	mkdir -p build/webfrontend
	cat $^ > build/webfrontend/custom-data-type-dante.js
	cat $(MAPBOX1) $(MAPBOX2) >> build/webfrontend/custom-data-type-dante.js

clean: clean-base

wipe: wipe-base

.PHONY: clean wipe

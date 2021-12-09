PLUGIN_NAME = custom-data-type-dante
PLUGIN_PATH = easydb-custom-data-type-dante

L10N_FILES = easydb-library/src/commons.l10n.csv \
    l10n/$(PLUGIN_NAME).csv
L10N_GOOGLE_KEY = 1ux8r_kpskdAwTaTjqrk92up5eyyILkpsv4k96QltmI0
L10N_GOOGLE_GID = 578343553

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(JS) \
	$(CSS) \
	build/updater/dante-update.js \
	manifest.yml


MAPBOX1 = src/external/geojson-extent.js
MAPBOX2 = src/external/geo-viewport.js

COFFEE_FILES = easydb-library/src/commons.coffee \
	src/webfrontend/CustomDataTypeDante.coffee \
  src/webfrontend/CustomDataTypeDanteParseJSKOS.coffee \
  src/webfrontend/CustomDataTypeDanteTreeview.coffee \
	src/webfrontend/DANTEUtil.coffee

CSS_FILE = src/webfrontend/css/main.css

UPDATE_SCRIPT_COFFEE_FILES = \
	src/webfrontend/DANTEUtil.coffee \
	src/updater/DANTEUpdate.coffee


all: build

include easydb-library/tools/base-plugins.make

build: code buildinfojson buildupdater

code: $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(L10N)
	mkdir -p build
	mkdir -p build/webfrontend
	cat $^ > build/webfrontend/custom-data-type-dante.js
	cat $(MAPBOX1) $(MAPBOX2) >> build/webfrontend/custom-data-type-dante.js
	mkdir -p build/webfrontend/css
	cat $(CSS_FILE) >> build/webfrontend/custom-data-type-dante.css

	# workaround
buildupdater: $(subst .coffee,.coffee.js,${UPDATE_SCRIPT_COFFEE_FILES})
	mkdir -p build/updater
	cat $^ > build/updater/dante-update.js

clean: clean-base

wipe: wipe-base

.PHONY: clean wipe

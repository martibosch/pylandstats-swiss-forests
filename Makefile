.PHONY: lulc dem

#################################################################################
# GLOBALS                                                                       #
#################################################################################

CODE_DIR = swiss_alpine_forests

DATA_DIR = data
DATA_RAW_DIR := $(DATA_DIR)/raw
DATA_INTERIM_DIR := $(DATA_DIR)/interim

## rules
define MAKE_DATA_SUB_DIR
$(DATA_SUB_DIR): | $(DATA_DIR)
	mkdir $$@
endef
$(DATA_DIR):
	mkdir $@
$(foreach DATA_SUB_DIR, \
	$(DATA_RAW_DIR) $(DATA_INTERIM_DIR) $(DATA_PROCESSED_DIR), \
	$(eval $(MAKE_DATA_SUB_DIR)))

#################################################################################
# COMMANDS                                                                      #
#################################################################################

# https://www.bfs.admin.ch/bfsstatic/dam/assets/1421007/master
SLS_URI = https://www.bfs.admin.ch/bfsstatic/dam/assets/6646411/master
SLS_DIR := $(DATA_RAW_DIR)/sls
SLS_CSV := $(SLS_DIR)/AREA_NOAS04_17_181029.csv

### rules
$(SLS_DIR): | $(DATA_RAW_DIR)
	mkdir $@
$(SLS_DIR)/%.zip: $(DOWNLOAD_URI_PY) | $(SLS_DIR)
	wget $(SLS_URI) -O $@
$(SLS_DIR)/%.csv: $(SLS_DIR)/%.zip
	unzip -j $< '*.csv' -d $(SLS_DIR)
	touch $@
lulc: $(SLS_CSV)

DHM200_DIR := $(DATA_RAW_DIR)/dhm200
DHM200_URI = \
	https://data.geo.admin.ch/ch.swisstopo.digitales-hoehenmodell_25/data.zip
DHM200_ASC := $(DHM200_DIR)/DHM200.asc
SWISS_DEM_TIF := $(DHM200_DIR)/DHM200.tif
#### reproject ASCII grid. See https://bit.ly/2WEBxoL
TEMP_VRT := $(DATA_INTERIM_DIR)/temp.vrt

### rules
$(DHM200_DIR): | $(DATA_RAW_DIR)
	mkdir $@
$(DHM200_DIR)/%.zip: | $(DHM200_DIR)
	wget $(DHM200_URI) -O $@
$(DHM200_DIR)/%.asc: $(DHM200_DIR)/%.zip
	unzip -j $< 'data/DHM200*' -d $(DHM200_DIR)
	touch $@
$(DHM200_DIR)/%.tif: $(DHM200_DIR)/%.asc
	gdalwarp -s_srs EPSG:21781 -t_srs EPSG:2056 -of vrt $< $(TEMP_VRT)
	gdal_translate -of GTiff $(TEMP_VRT) $@
	rm $(TEMP_VRT)
dem: $(SWISS_DEM_TIF)


#################################################################################
# PROJECT RULES                                                                 #
#################################################################################



#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')

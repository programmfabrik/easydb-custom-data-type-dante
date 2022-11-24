
# build _standard and _fulltext according to
#   https://docs.easydb.de/en/technical/plugins/customdatatype/#general-keys

class ez5.DANTEUtil

  ###
  @name         getFullTextFromJSKOSObject
  @description  This function generates the _fulltext-Object, which is required for search
                   Structure is documented here: https://docs.easydb.de/en/technical/plugins/customdatatype/#general-keys
  @param        {object}                JSKOS                 a jskos-object
  @param        {array}                 databaseLanguages     a list of easydb5-languages
  @return       {object}                returns _standard-Object
  ###

  @getFullTextFromJSKOSObject: (object, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getLanguageControl().getLanguages()

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    if Array.isArray(object)
      object = object[0]

    _fulltext = {}
    fullTextString = ''
    l10nObject = {}
    l10nObjectWithShortenedLanguages = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    for language in shortenedDatabaseLanguages
      l10nObjectWithShortenedLanguages[language] = ''

    objectKeys = [
      'prefLabel'
      'altLabel'
      'hiddenLabel'
      'identifier'
      'notation'
      'uri'
      'scopeNote'
      'definition'
      'startDate'
      'endDate'
      'example'
      'historyNote'
      'note'
      'changeNote'
      'startPlace'
      'endPlace'
    ]

    # parse all object-keys and add all values to fulltext
    for key, value of object
      if objectKeys.includes(key)
        propertyType = typeof value

        # string
        if propertyType == 'string'
          fullTextString += value + ' '
          # add to each language in l10n
          for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
            l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + value + ' '

        # object / array
        if propertyType == 'object'
          # array?
          if Array.isArray(object[key])
            for arrayValue in object[key]
              if typeof arrayValue == 'string'
                fullTextString += arrayValue + ' '
                # no language: add to every l10n-fulltext
                for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
                  l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + arrayValue + ' '
              # startPlace, endPlace
              else if typeof arrayValue == 'object'
                if arrayValue?.prefLabel
                  for prefLabelOfArrayKey, prefLabelOfArrayValue of arrayValue.prefLabel
                    fullTextString += prefLabelOfArrayValue + ' '
                    # no language: add to every l10n-fulltext
                    for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
                      l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + prefLabelOfArrayValue + ' '
          else
            # object?
            for objectKey, objectValue of object[key]
              if Array.isArray(objectValue)
                for arrayValueOfObject in objectValue
                  fullTextString += arrayValueOfObject + ' '
                  # check key and also add to l10n
                  if l10nObjectWithShortenedLanguages.hasOwnProperty objectKey
                    l10nObjectWithShortenedLanguages[objectKey] += arrayValueOfObject + ' '
              if typeof objectValue == 'string'
                fullTextString += objectValue + ' '
                # check key and also add to l10n
                if l10nObjectWithShortenedLanguages[objectKey]
                  l10nObjectWithShortenedLanguages[objectKey] += objectValue + ' '
    # finally give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # get shortened version
      shortenedLanguage = l10nObjectKey.split('-')[0]
      # add to l10n
      if l10nObjectWithShortenedLanguages[shortenedLanguage]
        l10nObject[l10nObjectKey] = l10nObjectWithShortenedLanguages[shortenedLanguage]

    _fulltext.text = fullTextString
    _fulltext.l10ntext = l10nObject

    return _fulltext


  ###
  @name         getStandardFromJSKOSObject
  @description  This function generates the _standard-Object, which is required for display-purposes
                   Structure is documented here: https://docs.easydb.de/en/technical/plugins/customdatatype/#general-keys
  @param        {object}     JSKOS     a jskos-object
  @return       {object}              returns _standard-Object
  ###
  @getStandardFromJSKOSObject: (JSKOS, databaseLanguages = false) ->

    if databaseLanguages == false
      databaseLanguages = ez5.loca.getLanguageControl().getLanguages()

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    if Array.isArray(JSKOS)
      JSKOS = JSKOS[0]

    _standard = {}
    l10nObject = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    hasl10n = false

    #  give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # get shortened version
      shortenedLanguage = l10nObjectKey.split('-')[0]
      # add to l10n
      if JSKOS.prefLabel[shortenedLanguage]
        l10nObject[l10nObjectKey] = JSKOS.prefLabel[shortenedLanguage]
        hasl10n = true

    # if l10n, yet not in all languages
    #   --> fill the other languages with something as fallback
    if hasl10n
      for l10nObjectKey, l10nObjectValue of l10nObject
        if l10nObject[l10nObjectKey] == ''
          l10nObject[l10nObjectKey] = JSKOS.prefLabel[Object.keys(JSKOS.prefLabel)[0]]

    # if no l10n yet
    if ! hasl10n
      for l10nObjectKey, l10nObjectValue of l10nObject
        if JSKOS.prefLabel['und']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['und']
        else if JSKOS.prefLabel['zxx']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['zxx']
        else if JSKOS.prefLabel['mis']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['mis']
        else if JSKOS.prefLabel['mul']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['mul']

    # if l10n-object is not empty
    _standard.l10ntext = l10nObject

    return _standard


  ###
  @name         getFacetTermFromJSKOSObject
  @description  generates a json-structure, which is only used for facetting (aka filter) in frontend
  ###
  @getFacetTermFromJSKOSObject: (JSKOS) ->
    console.log "f:getFacetTermFromJSKOSObject"

    databaseLanguages = ez5.loca.getLanguageControl().getLanguages()

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    if Array.isArray(JSKOS)
      JSKOS = JSKOS[0]

    _facet_term = {}

    l10nObject = {}

    # init l10nObject
    for language in databaseLanguages
      l10nObject[language] = ''

    # build facetTerm upon prefLabels and uri!

    hasl10n = false

    #  give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # get shortened version
      shortenedLanguage = l10nObjectKey.split('-')[0]
      # add to l10n
      if JSKOS.prefLabel[shortenedLanguage]
        l10nObject[l10nObjectKey] = JSKOS.prefLabel[shortenedLanguage]
        l10nObject[l10nObjectKey] = l10nObject[l10nObjectKey] + '@$@' + JSKOS.uri
        hasl10n = true

    # if l10n, yet not in all languages
    #   --> fill the other languages with something as fallback
    if hasl10n
      for l10nObjectKey, l10nObjectValue of l10nObject
        if l10nObject[l10nObjectKey] == ''
          l10nObject[l10nObjectKey] = JSKOS.prefLabel[Object.keys(JSKOS.prefLabel)[0]]
          l10nObject[l10nObjectKey] = l10nObject[l10nObjectKey] + '@$@' + JSKOS.uri

    # if no l10n yet
    if ! hasl10n
      for l10nObjectKey, l10nObjectValue of l10nObject
        if JSKOS.prefLabel['und']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['und']
        else if JSKOS.prefLabel['zxx']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['zxx']
        else if JSKOS.prefLabel['mis']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['mis']
        else if JSKOS.prefLabel['mul']
          l10nObject[l10nObjectKey] = JSKOS.prefLabel['mul']

        l10nObject[l10nObjectKey] = l10nObject[l10nObjectKey] + '@$@' + JSKOS.uri

    # if l10n-object is not empty
    _facet_term = l10nObject

    #_facet_term = JSON.stringify(_facet_term)
    console.log "_facet_term", _facet_term

    return _facet_term

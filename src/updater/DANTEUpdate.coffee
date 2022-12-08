class DANTEUpdate

  __start_update: ({server_config, plugin_config}) ->
      # Check if DANTE-API is fully available. This will take at least 10 seconds. Dont panic.
      testURL = 'https://api.dante.gbv.de/testAPICalls'
      availabilityCheck_xhr = new (CUI.XHR)(url: testURL)
      availabilityCheck_xhr.start()
      .done((data, status, statusText) ->
        if data?.status == true
          ez5.respondSuccess({
            state: {
                "start_update": new Date().toUTCString()
                "databaseLanguages" : server_config.base.system.languages.database
                "default_language" : server_config.base.system.update_interval_dante.default_language
            }
          })
        else
          ez5.respondError("custom.data.type.dante.update.error.generic", {error: "Test on DANTE-API was not successfull!"})
      )

  __updateData: ({objects, plugin_config, state}) ->
    #console.error "DANTE: f__updateData"
    that = @
    objectsMap = {}
    DANTEUris = []
    databaseLanguages = state.databaseLanguages
    default_language = state.default_language

    # check and set default-language
    defaultLanguage = false
    if default_language
      if (typeof default_language == 'string' || default_language instanceof String)
        if default_language.length == 2
          defaultLanguage = default_language

    for object in objects
      if not (object.identifier and object.data)
        continue
      DANTEUri = object.data.conceptURI
      if CUI.util.isEmpty(DANTEUri)
        continue
      if not objectsMap[DANTEUri]
        objectsMap[DANTEUri] = [] # It is possible to have more than one object with the same ID in different objects.
      objectsMap[DANTEUri].push(object)
      DANTEUris.push(DANTEUri)

    if DANTEUris.length == 0
      return ez5.respondSuccess({payload: []})

    # unique dante-uris
    DANTEUris = DANTEUris.filter((x, i, a) => a.indexOf(x) == i)

    #console.error "DANTEUris", DANTEUris

    objectsToUpdate = []

    # update the uri's one after the other
    chunkWorkPromise = CUI.chunkWork.call(@,
      items: DANTEUris
      chunk_size: 1
      call: (items) =>
        #for uri in items
        uri = items[0]
        originalDANTEUri = uri
        uri = 'https://api.dante.gbv.de/data?cache=1&uri='  + CUI.encodeURIComponentNicely(uri) + '&properties=+ancestors,altLabel,hiddenLabel,notation,scopeNote,definition,identifier,example,startDate,endDate,startPlace,endPlace'
        #console.error "DANTE: ask for " + uri
        deferred = new CUI.Deferred()
        extendedInfo_xhr = new (CUI.XHR)(url: uri)
        extendedInfo_xhr.start()
        .done((data, status, statusText) ->
          # skip, if a record was not found / empty
          if data?.length == 1
            data = data[0]

            # validation-test on data.preferredName (obligatory)
            if data?.prefLabel
              resultsDANTEUri = data.uri
              # parse every record of this URI
              for cdataFromObjectsMap, objectsMapKey in objectsMap[originalDANTEUri]
                cdataFromObjectsMap = cdataFromObjectsMap.data

                # init updated cdata
                updatedDANTEcdata = {}

                # conceptUri
                updatedDANTEcdata.conceptURI = data.uri
                #console.error "DANTE: now parsing " + data.uri

                # conceptAncestors
                updatedDANTEcdata.conceptAncestors = ''
                if data?.ancestors.length > 0
                  #console.error "DANTE: data?.ancestors.length" + data?.ancestors.length
                  conceptAncestors = []
                  for ancestor in data.ancestors
                    conceptAncestors.push ancestor.uri
                  if conceptAncestors.length > 0
                    # add own uri to ancestor-uris
                    conceptAncestors.push data.uri
                    # make string from array
                    conceptAncestorsString = conceptAncestors.join(' ')
                    # to result
                    updatedDANTEcdata.conceptAncestors = conceptAncestorsString
                #console.error "DANTE: conceptAncestors is " + updatedDANTEcdata.conceptAncestors

                # conceptName
                # change only, if a frontendLanguage is set AND it is not a manually chosen label
                if cdataFromObjectsMap?.frontendLanguage?.length == 2
                  updatedDANTEcdata.frontendLanguage = cdataFromObjectsMap.frontendLanguage
                  if cdataFromObjectsMap?.conceptNameChosenByHand == false || ! cdataFromObjectsMap.hasOwnProperty('conceptNameChosenByHand')
                    updatedDANTEcdata.conceptNameChosenByHand = false
                    if data['prefLabel']
                      # if a preflabel exists in given frontendLanguage or without language (person / corporate)
                      if data['prefLabel'][cdataFromObjectsMap.frontendLanguage] || data['prefLabel']['zxx'] || data['prefLabel']['und'] || data['prefLabel']['mus'] || data['prefLabel']['mil']
                        if data['prefLabel']?[cdataFromObjectsMap.frontendLanguage]
                          updatedDANTEcdata.conceptName = data['prefLabel'][cdataFromObjectsMap.frontendLanguage]
                        else if data['prefLabel']['zxx']
                          updatedDANTEcdata.conceptName = data['prefLabel']['zxx']
                        else if data['prefLabel']['und']
                          updatedDANTEcdata.conceptName = data['prefLabel']['und']
                        else if data['prefLabel']['mis']
                          updatedDANTEcdata.conceptName = data['prefLabel']['mis']
                        else if data['prefLabel']['mul']
                          updatedDANTEcdata.conceptName = data['prefLabel']['mul']

                # if conceptName is obviously chosen by hand
                if cdataFromObjectsMap?.conceptNameChosenByHand == true
                  updatedDANTEcdata.conceptName = cdataFromObjectsMap.conceptName
                  updatedDANTEcdata.conceptNameChosenByHand = true

                # if no frontendLanguage is given, set the default value from base_config (if given)
                if defaultLanguage
                  validFrontendLanguageGiven = false
                  if cdataFromObjectsMap?.frontendLanguage
                    if cdataFromObjectsMap.frontendLanguage.length == 2
                      validFrontendLanguageGiven = true
                  if ! validFrontendLanguageGiven
                    updatedDANTEcdata.frontendLanguage = defaultLanguage

                # if no conceptName is given yet (f.e. via scripted imports..)
                #   --> choose a label and prefer the configured default language
                if ! updatedDANTEcdata?.conceptName
                  # defaultLanguage given?
                  if defaultLanguage
                    if data['prefLabel']?[defaultLanguage]
                      updatedDANTEcdata.conceptName = data['prefLabel'][defaultLanguage]
                    else
                      if data.prefLabel?.de
                        updatedDANTEcdata.conceptName = data.prefLabel.de
                      else if data.prefLabel?.en
                        updatedDANTEcdata.conceptName = data.prefLabel.en
                      else
                        updatedDANTEcdata.conceptName = data.prefLabel[Object.keys(data.prefLabel)[0]]
                  else
                    if data.prefLabel?.de
                      updatedDANTEcdata.conceptName = data.prefLabel.de
                    else if data.prefLabel?.en
                      updatedDANTEcdata.conceptName = data.prefLabel.en
                    else
                      updatedDANTEcdata.conceptName = data.prefLabel[Object.keys(data.prefLabel)[0]]

                # _standard & _fulltext
                updatedDANTEcdata._standard = ez5.DANTEUtil.getStandardFromJSKOSObject data, databaseLanguages
                updatedDANTEcdata._fulltext = ez5.DANTEUtil.getFullTextFromJSKOSObject data, databaseLanguages

                # TODO   # _facet ????

                # aggregate in objectsMap
                if not that.__hasChanges(objectsMap[originalDANTEUri][objectsMapKey].data, updatedDANTEcdata)
                  #console.error "DANTE: no changes!"
                  continue
                else
                  #console.error "DANTE: has changes!"
                  objectsMap[originalDANTEUri][objectsMapKey].data = updatedDANTEcdata
                  objectsToUpdate.push(objectsMap[originalDANTEUri][objectsMapKey])
          deferred.resolve()
        ).fail( =>
         deferred.reject()
        )
        return deferred.promise()
    )

    chunkWorkPromise.done(=>
     ez5.respondSuccess({payload: objectsToUpdate})
    ).fail(=>
     ez5.respondError("custom.data.type.dante.update.error.generic", {error: "Error connecting to DANTE"})
    )

  __hasChanges: (objectOne, objectTwo) ->
    for key in ["conceptName", "conceptURI", "_standard", "_fulltext", "conceptAncestors", "frontendLanguage", "conceptNameChosenByHand"]
      if not CUI.util.isEqual(objectOne[key], objectTwo[key])
        return true
    return false

  main: (data) ->
    if not data
      ez5.respondError("custom.data.type.dante.update.error.payload-missing")
      return

    for key in ["action", "server_config", "plugin_config"]
      if (!data[key])
        ez5.respondError("custom.data.type.dante.update.error.payload-key-missing", {key: key})
        return

    if (data.action == "start_update")
      @__start_update(data)
      return
    else if (data.action == "update")
      if (!data.objects)
        ez5.respondError("custom.data.type.dante.update.error.objects-missing")
        return

      if (!(data.objects instanceof Array))
        ez5.respondError("custom.data.type.dante.update.error.objects-not-array")
        return

      # NOTE: state for all batches
      # this contains any arbitrary data the update script might need between batches
      # it should be sent to the server during 'start_update' and is included in each batch
      if (!data.state)
        ez5.respondError("custom.data.type.dante.update.error.state-missing")
        return

      # NOTE: information for this batch
      # this contains information about the current batch, espacially:
      #   - offset: start offset of this batch in the list of all collected values for this custom type
      #   - total: total number of all collected custom values for this custom type
      # it is included in each batch
      if (!data.batch_info)
        ez5.respondError("custom.data.type.dante.update.error.batch_info-missing")
        return

      # TODO: check validity of config, plugin (timeout), objects...
      @__updateData(data)
      return
    else
      ez5.respondError("custom.data.type.dante.update.error.invalid-action", {action: data.action})

module.exports = new DANTEUpdate()

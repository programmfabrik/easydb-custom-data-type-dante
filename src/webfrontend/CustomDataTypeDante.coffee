class CustomDataTypeDANTE extends CustomDataTypeWithCommons

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-dante.dante"

  #######################################################################
  # overwrite getCustomMaskSettings
  getCustomMaskSettings: ->
    if @ColumnSchema
      return @FieldSchema.custom_settings || {};
    else
      return {}

  #######################################################################
  # overwrite getCustomSchemaSettings
  getCustomSchemaSettings: ->
    if @ColumnSchema
      return @ColumnSchema.custom_settings || {};
    else
      return {}

  #######################################################################
  # overwrite getCustomSchemaSettings
  name: (opts = {}) ->
    if ! @ColumnSchema
      if opts?.callfrompoolmanager && opts?.name != ''
        return opts.name
      else
        return "noNameSet"
    else
      return @ColumnSchema?.name

  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.dante.name")


  #######################################################################
  # returns name of the given vocabulary from datamodel
  getVocabularyNameFromDatamodel: (opts = {}) ->
    xreturn = @getCustomSchemaSettings().vocabulary_name?.value
    if ! xreturn
      # maybe the call is from poolmanagerplugin?
      if opts?.callfrompoolmanager
        if opts?.voc
          return opts?.voc
      xreturn = 'gender'
    xreturn

  #######################################################################
  # returns, if user is allowed and correctly configured to add new records
  ###
  getIngestPermissionStatus: ->
    status = false;
    if @getCustomSchemaSettings()?.insert_allowed
      if @getCustomSchemaSettings()?.insert_username
        if @getCustomSchemaSettings()?.insert_token
          if @getCustomSchemaSettings().insert_username != '' && @getCustomSchemaSettings().insert_token != ''
            status = true
    status
  ###
  #######################################################################
  # returns an entry for the three-dots-button-bar for addition of new records
  ###
  getCustomButtonBarEntryForNewRecordAddition: ->
    that = @
    addNew =
        text: $$('custom.data.type.commons.controls.addnew.label')
        value: 'new'
        name: 'addnewValueFromDANTEPlugin'
        class: 'addnewValueFromDANTEPlugin'
        icon_left: new CUI.Icon(class: "fa-plus")
        onClick: ->
          console.log "clicked on add-button"
          # open modal with form for entering of basic record information
          modal = new CUI.Modal
              placement: "c"
              pane:
                  content: "No Content. Fill it."
                  header_left: new CUI.Label( text: "LEFT" )
                  header_right: new CUI.Label( text: "RIGHT" )
                  footer_right: =>
                    [
                      new CUI.Button
                        text: "Fill"
                        class: "cui-dialog"
                        onClick: =>
                          @mod.append(@getBlindText())
                    ,
                      new CUI.Button
                        text: "Cancel"
                        class: "cui-dialog"
                        onClick: =>
                          @mod.destroy()
                    ,
                      new CUI.Button
                        text: "Ok"
                        class: "cui-dialog"
                        primary: true
                        onClick: =>
                          @mod.destroy()
                    ]
          modal.show()
          #that.__updateResult(cdata, layout, opts)

  ###
  #######################################################################
  # render popup as treeview?
  renderPopupAsTreeview: ->
    result = false
    if @.getCustomMaskSettings().editor_style?.value == 'popover_with_treeview'
      result = true
    result


  #######################################################################
  # get the active vocabular
  #   a) from vocabulary-dropdown (POPOVER)
  #   b) return all given vocs (inline)
  getActiveVocabularyName: (cdata) ->
    that = @
    # is the voc set in dropdown?
    if cdata.dante_PopoverVocabularySelect && that.popover?.isShown()
      vocParameter = cdata.dante_PopoverVocabularySelect
    else
      # else all given vocs
      vocParameter = that.getVocabularyNameFromDatamodel();
    vocParameter


  #######################################################################
  # returns markup to display in expert search
  #######################################################################
  renderSearchInput: (data, opts) ->
      that = @
      if not data[@name()]
          data[@name()] = {}

      that.callFromExpertSearch = true

      form = @renderEditorInput(data, '', {})

      CUI.Events.listen
            type: "data-changed"
            node: form
            call: =>
                CUI.Events.trigger
                    type: "search-input-change"
                    node: form
                CUI.Events.trigger
                    type: "editor-changed"
                    node: form
                CUI.Events.trigger
                    type: "change"
                    node: form
                CUI.Events.trigger
                    type: "input"
                    node: form

      form.DOM

  needsDirectRender: ->
    return true

  #######################################################################
  # make searchfilter for expert-search
  #######################################################################
  getSearchFilter: (data, key=@name()) ->
      that = @

      objecttype = @path()
      objecttype = objecttype.split('.')
      objecttype = objecttype[0]

      # search for empty values
      if data[key+":unset"]
          filter =
              type: "in"
              fields: [ @fullName()+".conceptName" ]
              in: [ null ]
          filter._unnest = true
          filter._unset_filter = true
          return filter

      # dropdown or popup without tree or use of searchbar: use sameas
      if ! that.renderPopupAsTreeview() || ! data[key]?.experthierarchicalsearchmode
        filter =
            type: "complex"
            search: [
                type: "in"
                mode: "fulltext"
                bool: "must"
                phrase: false
                fields: [ @path() + '.' + @name() + ".conceptURI" ]
            ]
        if ! data[@name()]
            filter.search[0].in = [ null ]
        else if data[@name()]?.conceptURI
            filter.search[0].in = [data[@name()].conceptURI]
        else
            filter = null

      # popup with tree: 3 Modes
      if that.renderPopupAsTreeview()
        # 1. find all records which have the given uri in their ancestors
        if data[key].experthierarchicalsearchmode == 'include_children'
          filter =
              type: "complex"
              search: [
                  type: "in"
                  bool: "must"
                  fields: [ @path() + '.' + @name() + ".conceptAncestors" ]
              ]
          if ! data[@name()]
              filter.search[0].in = [ null ]
          else if data[@name()]?.conceptURI
              filter.search[0].in = [data[@name()].conceptURI]
          else
              filter = null
        # 2. find all records which have exact that match
        if data[key].experthierarchicalsearchmode == 'exact'
          filter =
              type: "complex"
              search: [
                  type: "in"
                  mode: "fulltext"
                  bool: "must"
                  phrase: false
                  fields: [ @path() + '.' + @name() + ".conceptURI" ]
              ]
          if ! data[@name()]
              filter.search[0].in = [ null ]
          else if data[@name()]?.conceptURI
              filter.search[0].in = [data[@name()].conceptURI]
          else
              filter = null

      filter


  #######################################################################
  # make tag for expert-search
  #######################################################################
  getQueryFieldBadge: (data) ->
      if ! data[@name()]
          value = $$("field.search.badge.without")
      else if ! data[@name()]?.conceptURI
          value = $$("field.search.badge.without")
      else
          value = data[@name()].conceptName

      if data[@name()]?.experthierarchicalsearchmode == 'exact' || data[@name()]?.experthierarchicalsearchmode == 'include_children'
        searchModeAddition = $$("custom.data.type.dante.modal.form.popup.choose_expertsearchmode_." + data[@name()].experthierarchicalsearchmode + "_short")
        value = searchModeAddition + ': ' + value


      name: @nameLocalized()
      value: value

  #######################################################################
  # choose label manually from popup
  #######################################################################
  __chooseLabelManually: (cdata,  layout, resultJSKOS, anchor, opts) ->
      that = @
      choiceLabels = []
      #preflabels
      for key, value of resultJSKOS.prefLabel
        choiceLabels.push value
      # altlabels
      for key, value of resultJSKOS.altLabel
        for key2, value2 of value
          choiceLabels.push value2
      prefLabelButtons = []
      for key, value of choiceLabels
        button = new CUI.Button
          text: value
          appearance: "flat"
          icon_left: new CUI.Icon(class: "fa-arrow-circle-o-right")
          class: 'dantePlugin_SearchButton'
          onClick: (evt,button) =>
            # lock choosen conceptName in savedata
            cdata.conceptName = button.opts.text
            # update the layout in form
            that.__updateResult(cdata, layout, opts)
            # close popovers
            if that.popover
              that.popover.hide()
            if chooseLabelPopover
              chooseLabelPopover.hide()
            @
        prefLabelButtons.push button

      # init popover
      chooseLabelPopover = new CUI.Popover
          element: anchor
          placement: "wn"
          class: "commonPlugin_Popover"
      chooseLabelContent = new  CUI.VerticalLayout
          class: "cui-pane"
          top:
            content: [
                new CUI.PaneHeader
                    left:
                        content:
                            new CUI.Label(text: $$('custom.data.type.dante.modal.form.popup.choose_manual_label'))
            ]
          center:
            content: [
              prefLabelButtons
            ]
          bottom: null
      chooseLabelPopover.setContent(chooseLabelContent)
      chooseLabelPopover.show()

  #######################################################################
  # choose search mode for the hierarchical expert search
  #   ("exact" or "with children")
  #######################################################################
  __chooseExpertHierarchicalSearchMode: (cdata,  layout, resultJSKOS, anchor, opts) ->
      that = @

      ConfirmationDialog = new CUI.ConfirmationDialog
        text: $$('custom.data.type.dante.modal.form.popup.choose_expertsearchmode_label2') + '\n\n' +  $$('custom.data.type.dante.modal.form.popup.choose_expertsearchmode_label3') + ': ' + cdata.conceptURI +  '\n'
        title: $$('custom.data.type.dante.modal.form.popup.choose_expertsearchmode_label')
        icon: "question"
        cancel: false
        buttons: [
          text: $$('custom.data.type.dante.modal.form.popup.choose_expertsearchmode_.exact')
          onClick: =>
            # lock choosen searchmode in savedata
            cdata.experthierarchicalsearchmode = 'exact'
            # update the layout in form
            that.__updateResult(cdata, layout, opts)
            ConfirmationDialog.destroy()
        ,
          text: $$('custom.data.type.dante.modal.form.popup.choose_expertsearchmode_.include_children')
          primary: true
          onClick: =>
            # lock choosen searchmode in savedata
            cdata.experthierarchicalsearchmode = 'include_children'
            # update the layout in form
            that.__updateResult(cdata, layout, opts)
            ConfirmationDialog.destroy()
        ]
      ConfirmationDialog.show()


  #######################################################################
  # handle suggestions-menu  (POPOVER)
  #######################################################################
  __updateSuggestionsMenu: (cdata, cdata_form, dante_searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 50

    # show loader
    menu_items = [
        text: $$('custom.data.type.dante.modal.form.loadingSuggestions')
        icon_left: new CUI.Icon(class: "fa-spinner fa-spin")
        disabled: true
    ]
    itemList =
      items: menu_items
    suggest_Menu.setItemList(itemList)

    setTimeout ( ->

        dante_searchstring = dante_searchstring.replace /^\s+|\s+$/g, ""
        if dante_searchstring.length == 0
            return

        suggest_Menu.show()

        # limit-Parameter
        dante_countSuggestions = 50

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        # cache?
        cache = '&cache=0'
        if that.getCustomMaskSettings().use_cache?.value
            cache = '&cache=1'

        # voc parameter
        vocParameter = that.getActiveVocabularyName(cdata)
        # voc parameter if called from poolmanagerplugin
        if opts?.callfrompoolmanager
          vocParameter = that.getVocabularyNameFromDatamodel(opts)

        # start request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=' + dante_searchstring + '&voc=' + vocParameter + '&language=' + that.getFrontendLanguage() + '&limit=' + dante_countSuggestions + cache)
        searchsuggest_xhr.xhr.start().done((data_1, status, statusText) ->

            extendedInfo_xhr = { "xhr" : undefined }

            # show voc-headlines in selectmenu? default: no headlines
            showHeadlines = false;

            # are there multible vocs in datamodel?
            multibleVocs = false
            vocTest = that.getVocabularyNameFromDatamodel()
            vocTestArr = vocTest.split('|')
            if vocTestArr.length > 1
              multibleVocs = true

            # conditions for headings in searchslot (for documentation reasons very detailed)

            #A. If only search slot (inlineform, popup invisible)
            if ! that.popover?.isShown()
              # A.1. If only 1 vocabulary, then no subheadings
              if multibleVocs == false
                showHeadlines = false
              else
              # A.2. If several vocabularies, then necessarily and always subheadings
              if multibleVocs == true
                showHeadlines = true
            #B. When popover (popup visible)
            else if that.popover?.isShown()
              # B.1. If several vocabularies
              if multibleVocs == true
                # B.1.1 If vocabulary selected from dropdown, then no subheadings
                if cdata?.dante_PopoverVocabularySelect != '' && cdata?.dante_PopoverVocabularySelect != vocTest
                  showHeadlines = false
                else
                # B.2.2 If "All vocabularies" in dropdown, then necessarily and always subheadings
                if cdata?.dante_PopoverVocabularySelect == vocTest
                  showHeadlines = true
              else
                # B.2. If only one vocabulary
                if multibleVocs == false
                  # B.2.1 Don't show subheadings
                  showHeadlines = false

            # the actual vocab (if multible, add headline + divider)
            actualVocab = ''

            # sort by voc/uri-part in tmp-array
            tmp_items = []
            # a list of the unique text suggestions for treeview-suggest
            unique_text_suggestions = []
            unique_text_items = []
            for suggestion, key in data_1[1]
              vocab = 'default'
              if showHeadlines
                vocab = data_1[3][key]
                vocab = vocab.replace('https://', '')
                vocab = vocab.replace('http://', '')
                vocab = vocab.replace('uri.gbv.de/terminology/', '')
                vocab = vocab.split('/').shift()
              if ! Array.isArray tmp_items[vocab]
                tmp_items[vocab] = []
              do(key) ->
                # default item
                item =
                  text: suggestion
                  value: data_1[3][key]
                  tooltip:
                    markdown: true
                    placement: "ne"
                    content: (tooltip) ->
                      # show infopopup
                      encodedURI = encodeURIComponent(data_1[3][key])
                      that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
                tmp_items[vocab].push item
                # unique item for treeview
                if suggestion not in unique_text_suggestions
                  unique_text_suggestions.push suggestion
                  item =
                    text: suggestion
                    value: suggestion
                  unique_text_items.push item
            # create new menu with suggestions
            menu_items = []

            actualVocab = ''
            for vocab, part of tmp_items
              if showHeadlines
                if ((actualVocab == '' || actualVocab != vocab) && vocab != 'default')
                     actualVocab = vocab
                     item =
                          divider: true
                     menu_items.push item
                     item =
                          label: actualVocab
                     menu_items.push item
                     item =
                          divider: true
                     menu_items.push item
              for suggestion,key2 in part
                menu_items.push suggestion

            # set new items to menu
            itemList =
              onClick: (ev2, btn) ->

                # if inline or treeview without popup
                if ! that.renderPopupAsTreeview() || ! that.popover?.isShown()
                  searchUri = btn.getOpt("value")
                  if that.popover
                    # put a loader to popover
                    newLoaderPanel = new CUI.Pane
                        class: "cui-pane"
                        top:
                            content: [
                                new CUI.PaneHeader
                                    left:
                                        content:
                                            new CUI.Label(text: $$('custom.data.type.dante.modal.form.popup.choose'))
                                    right:
                                        content:
                                            new CUI.EmptyLabel
                                              text: that.getVocabularyNameFromDatamodel()
                            ]
                        center:
                            content: [
                                new CUI.HorizontalLayout
                                  maximize: true
                                  left: null
                                  center:
                                    content:
                                      new CUI.Label
                                        centered: true
                                        size: "big"
                                        icon: "spinner"
                                        text: $$('custom.data.type.dante.modal.form.popup.loadingstring')
                                  right: null
                            ]
                    that.popover.setContent(newLoaderPanel)

                  # else set loader to suggest menu
                  ###
                  ###

                  # if treeview in popup also get the ancestors
                  ancestors = '';
                  #if that.renderPopupAsTreeview() && ! that.popover
                  if that.renderPopupAsTreeview()
                    ancestors = ',ancestors'

                  # get full record to get correct preflabel in desired language
                  searchUri = encodeURIComponent(searchUri)
                  suggestAPIPath = location.protocol + '//api.dante.gbv.de/data?uri=' + searchUri + cache + '&properties=+hiddenLabel,notation,scopeNote,definition,identifier,example,location,depiction,startDate,endDate,startPlace,endPlace' + ancestors
                  console.log "suggestAPIPath", suggestAPIPath
                  # start suggest-XHR
                  dataEntry_xhr = new (CUI.XHR)(url: suggestAPIPath)
                  dataEntry_xhr.start().done((data_suggest, status, statusText) ->
                    resultJSKOS = data_suggest[0]
                    cdata.conceptAncestors = []
                    # if treeview, add ancestors
                    if that.renderPopupAsTreeview()
                      if resultJSKOS?.ancestors?.length > 0
                        # save ancestor-uris to cdata
                        for jskos in resultJSKOS.ancestors
                          cdata.conceptAncestors.push jskos.uri
                      # add own uri to ancestor-uris
                      cdata.conceptAncestors.push searchUri

                    console.log "resultJSKOS", resultJSKOS
                    console.log "resultJSKOS.uri", resultJSKOS.uri

                    if resultJSKOS.uri
                      # lock conceptURI in savedata
                      cdata.conceptURI = resultJSKOS.uri
                      # lock _fulltext in savedata
                      cdata._fulltext = ez5.DANTEUtil.getFullTextFromJSKOSObject resultJSKOS
                      cdata._standard = ez5.DANTEUtil.getStandardFromJSKOSObject resultJSKOS

                      # is user allowed to choose label manually from list and not in expert-search?!
                      if that.getCustomMaskSettings().allow_label_choice?.value && opts?.mode == 'editor'
                        if newLoaderPanel
                          anchor = newLoaderPanel
                        else
                          anchor = input
                        that.__chooseLabelManually(cdata, layout, resultJSKOS, anchor, opts)
                      # user is not allowed to choose-label manually --> choose prefLabel in default language
                      else
                        if resultJSKOS.prefLabel?[that.getFrontendLanguage()]
                          cdata.conceptName = resultJSKOS.prefLabel?[that.getFrontendLanguage()]
                        else
                          cdata.conceptName = resultJSKOS.prefLabel[Object.keys(resultJSKOS.prefLabel)[0]]
                        # update the layout in form
                        that.__updateResult(cdata, layout, opts)
                        # close popover
                        if that.popover
                          that.popover.hide()
                        @
                  )

                # if treeview: set choosen suggest-entry to searchbar
                if that.renderPopupAsTreeview() && that.popover
                  if cdata_form
                    cdata_form.getFieldsByName("searchbarInput")[0].setValue(btn.getText())

              items: menu_items

            # if treeview in popup: use unique suggestlist (only one voc and text-search)
            if that.renderPopupAsTreeview() && that.popover?.isShown()
              itemList.items = unique_text_items

            # if no suggestions: set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: $$('custom.data.type.dante.modal.form.popup.suggest.nohit')
                  value: undefined
                ]
            suggest_Menu.setItemList(itemList)
            suggest_Menu.show()
        )
    ), delayMillisseconds


  #######################################################################
  # render editorinputform
  renderEditorInput: (data, top_level_data, opts) ->
    #console.error @, data, top_level_data, opts, @name(), @fullName()

    that = @

    # if not called from poolmanagerplugin
    if ! opts?.callfrompoolmanager
      if not data[@name()]
          cdata = {
              conceptName : ''
              conceptURI : ''
          }
          # if default values are set in masksettings
          if @getCustomMaskSettings().default_concept_uri?.value && @getCustomMaskSettings().default_concept_name?.value
              cdata = {
                  conceptName : @getCustomMaskSettings().default_concept_name?.value
                  conceptURI : @getCustomMaskSettings().default_concept_uri?.value
                  # TODO TODO TODO
                  _fulltext : {}
                  # TODO TODO TODO
                  _standard : {}
                  # TODO TODO TODO
                  conceptAncestors: []
              }
          data[@name()] = cdata
      else
          cdata = data[@name()]
    # if called from poolmanagerplugin
    else
        cdata = data[@name(opts)]
        if ! cdata?.conceptURI
          cdata = {}

    # inline or popover?
    dropdown = false
    if opts?.editorstyle
      editorStyle = opts.editorstyle
    else
      if @getCustomMaskSettings().editor_style?.value == 'dropdown'
        editorStyle = 'dropdown'
      else
        editorStyle = 'popup'

    if editorStyle == 'dropdown'
        @__renderEditorInputInline(data, cdata, opts)
    else
        #opts.customButtonBarEntrys = []
        #opts.customButtonBarEntrys.push that.getCustomButtonBarEntryForNewRecordAddition()
        @__renderEditorInputPopover(data, cdata, opts)


  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5?.loca?.getLanguage()
    if desiredLanguage
      desiredLanguage = desiredLanguage.split('-')
      desiredLanguage = desiredLanguage[0]
    else
      desiredLanguage = false

    desiredLanguage


  #######################################################################
  # render form as DROPDOWN
  __renderEditorInputInline: (data, cdata, opts = {}) ->
        that = @

        fields = []
        select = {
            type: CUI.Select
            undo_and_changed_support: false
            empty_text: $$('custom.data.type.dante.modal.form.dropdown.loadingentries')
            # read select-items from dante-api
            options: (thisSelect) =>
                  dfr = new CUI.Deferred()
                  values = []

                  # cache on?
                  cache = '&cache=0'
                  if @getCustomMaskSettings()?.use_cache?.value
                      cache = '&cache=1'

                  # if multible vocabularys are given, show only the first one in dropdown
                  vocTest = @getVocabularyNameFromDatamodel(opts)
                  vocTest = vocTest.split('|')
                  if(vocTest.length > 1)
                    voc = vocTest[0]
                  else
                    voc = @getVocabularyNameFromDatamodel(opts)

                  # start new request
                  searchsuggest_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=&voc=' + voc + '&language=' + @getFrontendLanguage() + '&limit=1000' + cache)
                  searchsuggest_xhr.start().done((data, status, statusText) ->
                      # read options for select
                      select_items = []
                      item = (
                        text: $$('custom.data.type.dante.modal.form.dropdown.choose')
                        value: null
                      )
                      select_items.push item
                      for suggestion, key in data[1]
                          item = (
                            text: suggestion
                            value: data[3][key]
                          )
                          select_items.push item

                      # if cdata is already set, choose correspondending option from select
                      if cdata?.conceptURI != ''
                          # is this a dante-uri or another "world"-uri?
                          if cdata.conceptURI?.indexOf('uri.gbv.de/terminology') > 0
                            # uuid of already saved entry
                            givenUUID = cdata?.conceptURI.split('/')
                            givenUUID = givenUUID.pop()
                            for givenOpt in select_items
                              if givenOpt.value != null
                                testUUID = givenOpt.value.split('/')
                                testUUID = testUUID.pop()
                                if testUUID == givenUUID
                                  thisSelect.setValue(givenOpt.value)
                                  thisSelect.setText(givenOpt.text)
                          else
                            for givenOpt in select_items
                              if givenOpt.value != null
                                if givenOpt.value == cdata?.conceptURI
                                  thisSelect.setValue(givenOpt.value)
                                  thisSelect.setText(givenOpt.text)
                      thisSelect.enable()
                      dfr.resolve(select_items)
                  )
                  dfr.promise()

            name: 'dante_InlineSelect'
        }

        fields.push select
        if cdata.length == 0
          cdata = {}
        cdata_form = new CUI.Form
                data: cdata
                # dropdown changed!?
                onDataChanged: =>
                      element = cdata_form.getFieldsByName("dante_InlineSelect")[0]
                      cdata.conceptURI = element.getValue()
                      element.displayValue()
                      cdata.conceptName = element.getText()
                      cdata.conceptAncestors = []
                      if cdata.conceptURI != null
                        # download data from dante for fulltext
                        fulltext_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/data?uri=' + cdata.conceptURI + '&cache=1&properties=+ancestors,hiddenLabel,notation,scopeNote,definition,identifier,example,location,depiction,startDate,endDate,startPlace,endPlace')
                        fulltext_xhr.start().done((detail_data, status, statusText) ->
                            cdata._fulltext = ez5.DANTEUtil.getFullTextFromJSKOSObject detail_data
                            cdata._standard= ez5.DANTEUtil.getStandardFromJSKOSObject detail_data
                            if ! cdata?.conceptURI
                              cdata = {}
                            data[that.name(opts)] = cdata
                            data.lastsaved = Date.now()
                            CUI.Events.trigger
                                    node: element
                                    type: "editor-changed"
                        )
                fields: fields
        .start()
        cdata_form.getFieldsByName("dante_InlineSelect")[0].disable()

        cdata_form

  #######################################################################
  # show tooltip with loader and then additional info (for extended mode)
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr, context = null) ->
    that = @

    if context
      that = context

    # abort eventually running request
    if extendedInfo_xhr.xhr != undefined
      extendedInfo_xhr.xhr.abort()

    if that.getCustomSchemaSettings().mapbox_access_token?.value
      mapbox_access_token = that.getCustomSchemaSettings().mapbox_access_token.value
    # start new request to DANTE-API
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/data?uri=' + uri + '&format=json&properties=+ancestors,hiddenLabel,notation,scopeNote,definition,identifier,example,location,depiction,startDate,endDate,startPlace,endPlace&cache=1')
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = that.getJSKOSPreview(data, mapbox_access_token)
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return

  #######################################################################
  # build treeview-Layout with treeview
  buildAndSetTreeviewLayout: (popover, layout, cdata, cdata_form, that, topMethod = 0, returnDfr = false, opts) ->
    # is this a call from expert-search? --> save in opts..
    if @?.callFromExpertSearch
      opts.callFromExpertSearch = @.callFromExpertSearch
    else
      opts.callFromExpertSearch = false

    if topMethod
      # get vocparameter from dropdown, if available...
      popoverVocabularySelectTest = cdata_form.getFieldsByName("dante_PopoverVocabularySelect")[0]
      if popoverVocabularySelectTest?.getValue()
        vocParameter = popoverVocabularySelectTest?.getValue()
      else
        # else get first voc from given voclist (1-n)
        vocParameter = that.getActiveVocabularyName(cdata)
        vocParameter = vocParameter.split('|')
        vocParameter = vocParameter[0]

      treeview = new DANTE_ListViewTree(popover, layout, cdata, cdata_form, that, opts, vocParameter)

      # maybe deferred is wanted?
      if returnDfr == false
        treeview.getTopTreeView(vocParameter, 1)
      else
        treeviewDfr = treeview.getTopTreeView(vocParameter, 1)

    treeviewPane = new CUI.Pane
        class: "cui-pane dante_treeviewPane"
        top:
            content: [
                new CUI.PaneHeader
                    left:
                        content:
                            new CUI.Label(text: $$('custom.data.type.dante.modal.form.popup.choose'))
                    right:
                        content:
                            new CUI.EmptyLabel
                              text: that.getVocabularyNameFromDatamodel()
            ]
        center:
            content: [
                treeview.treeview
              ,
                cdata_form
            ]

    @popover.setContent(treeviewPane)

    # maybe deferred is wanted?
    if returnDfr == false
      return treeview
    else
      return treeviewDfr

  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, data, cdata, layout, opts) ->
    that = @

    # if "reset"-button is pressed, dont use cache for this popup
    that.resettedPopup = false;

    suggest_Menu
    cdata_form

    # init popover
    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"
      onHide: =>
        # reset voc-dropdown
        delete cdata.dante_PopoverVocabularySelect
        vocDropdown = cdata_form.getFieldsByName("dante_PopoverVocabularySelect")[0]
        if vocDropdown
          vocDropdown.reload()
        # reset searchbar
        searchbar = cdata_form.getFieldsByName("searchbarInput")[0]
        if searchbar
          searchbar.reset()

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }
    cdata_form = new CUI.Form
      class: "danteFormWithPadding"
      data: cdata
      fields: that.__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        that.__updateResult(cdata, layout, opts)
        # update tree, if voc changed
        if elem.opts.name == 'dante_PopoverVocabularySelect' && that.renderPopupAsTreeview()
          @buildAndSetTreeviewLayout(@popover, layout, cdata, cdata_form, that, 1, false, opts)
        that.__setEditorFieldStatus(cdata, layout)
        if elem.opts.name == 'searchbarInput' || elem.opts.name == 'dante_PopoverVocabularySelect'
          that.__updateSuggestionsMenu(cdata, cdata_form, data.searchbarInput, elem, suggest_Menu, searchsuggest_xhr, layout, opts)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element : cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true

    # treeview?
    if that.renderPopupAsTreeview()
      # do search-request for all the top-entrys of vocabulary
      @buildAndSetTreeviewLayout(@popover, layout, cdata, cdata_form, that, 1, false, opts)

      # cache on?
      cache = 0
      if @getCustomMaskSettings().use_cache?.value
          cache = 1

      # append button after autocomplete-input
      searchButton =  new CUI.Button
                      text: $$('custom.data.type.dante.modal.form.popup.treeviewsearch')
                      icon_left: new CUI.Icon(class: "fa-search")
                      class: 'dantePlugin_SearchButton'
                      onClick: (evt,button) =>
                        # hide suggest-menü
                        suggest_Menu.hide()
                        # attach info to cdata_form
                        searchTerm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
                        if searchTerm.length > 2
                          # disable search + reset-buttons
                          searchButton.setEnabled(false)
                          resetButton.setEnabled(false)

                          button.setIcon(new CUI.Icon(class: "fa-spinner fa-spin"))

                          newTreeview = @buildAndSetTreeviewLayout(@popover, layout, cdata, cdata_form, that, 0, false, opts)

                          vocParameter = that.getActiveVocabularyName(cdata)

                          newTreeview.getSearchResultTree(searchTerm, vocParameter, cache)
                          .done =>
                            # enable search + reset-buttons
                            searchButton.setEnabled(true)
                            resetButton.setEnabled(true)

                            button.setIcon(new CUI.Icon(class: "fa-search"))

                            that.popover.position()
                            setTimeout ( ->
                              # refresh popup, because its content has changed (new height etc)
                              CUI.Events.trigger
                                node: that.popover
                                type: "content-resize"
                            ), 50


                            setTimeout ( ->
                              # refresh popup, because its content has changed (new height etc)
                              CUI.Events.trigger
                                node: that.popover
                                type: "content-resize"
                            ), 100

                          @
      # append "search"-Button
      cdata_form.getFieldsByName("searchbarInput")[0].append(searchButton)

      # append button after autocomplete-input
      resetButton =  new CUI.Button
                      text: $$('custom.data.type.dante.modal.form.popup.treeviewreset')
                      icon_left: new CUI.Icon(class: "fa-undo")
                      class: 'dantePlugin_ResetButton'
                      onClick: (evt,button) =>
                        that.resettedPopup = true

                        # clear searchbar
                        cdata_form.getFieldsByName("searchbarInput")[0].setValue('').displayValue()

                        # disable search + reset-buttons
                        searchButton.setEnabled(false)
                        resetButton.setEnabled(false)

                        button.setIcon(new CUI.Icon(class: "fa-spinner fa-spin"))

                        # attach info to cdata_form
                        newTreeviewDfr = @buildAndSetTreeviewLayout(@popover, layout, cdata, cdata_form, that, 1, true, opts)

                        # if reset complete
                        newTreeviewDfr.done =>
                          # enable search + reset-buttons
                          searchButton.setEnabled(true)
                          resetButton.setEnabled(true)
                          button.setIcon(new CUI.Icon(class: "fa-undo"))

      # append "reset"-Button
      cdata_form.getFieldsByName("searchbarInput")[0].append(resetButton)
    # else not treeview, but default search-popup
    else
      defaultPane = new CUI.Pane
          class: "cui-pane"
          top:
              content: [
                  new CUI.PaneHeader
                      left:
                          content:
                              new CUI.Label(text: $$('custom.data.type.dante.modal.form.popup.choose'))
                      right:
                          content:
                              new CUI.EmptyLabel
                                text: that.getVocabularyNameFromDatamodel(opts)
              ]
          center:
              content: [
                  cdata_form
              ]
      @popover.setContent(defaultPane)

    @popover.show()

  #######################################################################
  # create form (POPOVER)
  #######################################################################
  __getEditorFields: (cdata) ->
    that = @
    fields = []
    # dropdown for vocabulary-selection if more then 1 voc
    vocTest = that.getVocabularyNameFromDatamodel()
    vocTestArr = vocTest.split('|')
    if vocTestArr.length > 1 or vocTest == '*'
      select =  {
          type: CUI.Select
          undo_and_changed_support: false
          name: 'dante_PopoverVocabularySelect'
          form:
            label: $$("custom.data.type.dante.modal.form.dropdown.selectvocabularyLabel")
          # read select-items from dante-api
          options: (thisSelect) =>
            dfr = new CUI.Deferred()
            values = []

            # search for the wanted vocs or all vocs
            notationStr = '&notation=' + that.getVocabularyNameFromDatamodel()
            if that.getVocabularyNameFromDatamodel() == '*'
              notationStr = '';
            # start new request
            searchsuggest_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/voc?cache=1' + notationStr)
            searchsuggest_xhr.start().done((data, status, statusText) ->
                # read options for select
                select_items = []
                # allow to choose all vocs only, if not treeview
                if ! that.renderPopupAsTreeview()
                  item = (
                    text: $$('custom.data.type.dante.modal.form.dropdown.choosefromvocall')
                    value: that.getVocabularyNameFromDatamodel()
                  )
                  select_items.push item
                # add vocs to select
                for entry, key in data
                    item = (
                      text: entry.prefLabel.de
                      value: entry.notation[0]
                    )
                    select_items.push item

                thisSelect.enable()
                dfr.resolve(select_items)
            )
            dfr.promise()
      }
      fields.push select

    # searchfield (autocomplete)
    option =  {
          type: CUI.Input
          class: "commonPlugin_Input"
          undo_and_changed_support: false
          form:
              label: $$("custom.data.type.dante.modal.form.text.searchbar")
          placeholder: $$("custom.data.type.dante.modal.form.text.searchbar.placeholder")
          name: "searchbarInput"
        }
    fields.push option

    fields


  #######################################################################
  # renders the "resultmask" (outside popover)
  __renderButtonByData: (cdata) ->
    that = @
    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.dante.edit.no_dante")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.dante.edit.no_valid_dante")).DOM

    extendedInfo_xhr = { "xhr" : undefined }

    # output Button with Name of picked dante-Entry and URI
    encodedURI = encodeURIComponent(cdata.conceptURI)
    new CUI.HorizontalLayout
      maximize: true
      left:
        content:
          new CUI.Label
            centered: false
            text: cdata.conceptName
      center:
        content:
          new CUI.ButtonHref
            name: "outputButtonHref"
            class: "pluginResultButton"
            appearance: "link"
            size: "normal"
            href: 'https://uri.gbv.de/terminology/?uri=' + encodedURI
            target: "_blank"
            class: "cdt_dante_smallMarginTop"
            tooltip:
              markdown: true
              placement: 'nw'
              content: (tooltip) ->
                # get jskos-details-data
                that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                # loader, until details are xhred
                new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
      right: null
    .DOM

  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.vocabulary_name?.value
      tags.push $$("custom.data.type.dante.name") + ': ' + custom_settings.vocabulary_name.value
    else
      tags.push $$("custom.data.type.dante.setting.schema.no_choosen_vocabulary")

    if custom_settings.mapbox_access_token?.value
      tags.push "✓ Mapbox-Access-Token"
    else
      tags.push "✘ Mapbox-Access-Token"

    tags


CustomDataType.register(CustomDataTypeDANTE)

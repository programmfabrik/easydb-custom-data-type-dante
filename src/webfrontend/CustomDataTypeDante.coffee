class CustomDataTypeDANTE extends CustomDataTypeWithCommons

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-dante.dante"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.dante.name")


  #######################################################################
  # returns name of the given vocabulary from datamodel
  getVocabularyNameFromDatamodel: ->
    xreturn = @getCustomSchemaSettings().vocabulary_name?.value
    if ! xreturn
      xreturn = 'gender'
    xreturn


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
  # handle suggestions-menu  (POPOVER)
  #######################################################################
  __updateSuggestionsMenu: (cdata, cdata_form, dante_searchstring, input, suggest_Menu, searchsuggest_xhr, layout) ->
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

        # start request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=' + dante_searchstring + '&voc=' + vocParameter + '&language=' + that.getFrontendLanguage() + '&limit=' + dante_countSuggestions + cache)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

            extendedInfo_xhr = { "xhr" : undefined }

            # show voc-headlines in selectmenu?

            # default: no headlines
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
            for suggestion, key in data[1]
              vocab = 'default'
              if showHeadlines
                vocab = data[3][key]
                vocab = vocab.replace('https://', '')
                vocab = vocab.replace('http://', '')
                vocab = vocab.replace('uri.gbv.de/terminology/', '')
                vocab = vocab.split('/').shift()
              if ! Array.isArray tmp_items[vocab]
                tmp_items[vocab] = []
              do(key) ->
                item =
                  text: suggestion
                  value: data[3][key]
                  tooltip:
                    markdown: true
                    placement: "ne"
                    content: (tooltip) ->
                      # show infopopup
                      encodedURI = encodeURIComponent(data[3][key])
                      that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
                tmp_items[vocab].push item
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
                if that.getCustomMaskSettings().editor_style?.value != 'popover_with_treeview' || ! that.popover?.isShown()
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

                  # get full record to get correct preflabel in desired language
                  dataEntry_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/data?uri=' + searchUri + cache)
                  dataEntry_xhr.start().done((data, status, statusText) ->
                    if data.length == 1
                      if data[0].uri
                        # lock conceptURI in savedata
                        cdata.conceptURI = data[0].uri

                        # lock conceptName in savedata, but before that

                        # is user allowed to choose label manually?
                        choiceLabels = []
                        #preflabels
                        for key, value of data[0].prefLabel
                          choiceLabels.push value
                        # altlabels
                        for key, value of data[0].altLabel
                          for key2, value2 of value
                            choiceLabels.push value2
                        if that.getCustomMaskSettings().allow_label_choice?.value
                          prefLabelButtons = []
                          for key, value of choiceLabels
                            button = new CUI.Button
                              text: value
                              appearance: "flat"
                              icon_left: new CUI.Icon(class: "fa-arrow-circle-o-right")
                              class: 'dantePlugin_SearchButton'
                              onClick: (evt,button) =>
                                cdata.conceptName = button.opts.text
                                # update the layout in form
                                that.__updateResult(cdata, layout)
                                # close popovers
                                if that.popover
                                  that.popover.hide()
                                if chooseLabelPopover
                                  chooseLabelPopover.hide()
                                @
                            prefLabelButtons.push button

                          # init popover
                          if newLoaderPanel
                            chooseHangElem = newLoaderPanel
                          else
                            chooseHangElem = input
                          chooseLabelPopover = new CUI.Popover
                              element: chooseHangElem
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
                        else
                          # else choose prefLabel in default language
                          if data[0].prefLabel?[that.getFrontendLanguage()]
                            cdata.conceptName = data[0].prefLabel?[that.getFrontendLanguage()]
                          else
                            cdata.conceptName = data[0].prefLabel[Object.keys(data[0].prefLabel)[0]]
                          # update the layout in form
                          that.__updateResult(cdata, layout)
                          # close popover
                          if that.popover
                            that.popover.hide()
                          @
                  )

                # if treeview: set choosen suggest-entry to searchbar
                if that.getCustomMaskSettings().editor_style?.value == 'popover_with_treeview' && that.popover
                  if cdata_form
                    cdata_form.getFieldsByName("searchbarInput")[0].setValue(btn.getText())

              items: menu_items

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
            }
        data[@name()] = cdata
    else
        cdata = data[@name()]

    # inline or popover?
    if @getCustomMaskSettings().editor_style?.value == 'dropdown'
        @__renderEditorInputInline(data, cdata)
    else
        @__renderEditorInputPopover(data, cdata, opts)


  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5.loca.getLanguage()
    desiredLanguage = desiredLanguage.split('-')
    desiredLanguage = desiredLanguage[0]

    desiredLanguage


  #######################################################################
  # render form as DROPDOWN
  __renderEditorInputInline: (data, cdata) ->
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
                  if @getCustomMaskSettings().use_cache?.value
                      cache = '&cache=1'

                  # if multible vocabularys are given, show only the first one in dropdown
                  vocTest = @getVocabularyNameFromDatamodel()
                  vocTest = vocTest.split('|')
                  if(vocTest.length > 1)
                    voc = vocTest[0]
                  else
                    voc = @getVocabularyNameFromDatamodel()

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

        cdata_form = new CUI.Form
                data: cdata
                onDataChanged: =>

                      element = cdata_form.getFieldsByName("dante_InlineSelect")[0]

                      cdata.conceptURI = element.getValue()
                      element.displayValue()
                      cdata.conceptName = element.getText()

                      CUI.Events.trigger
                              node: element
                              type: "editor-changed"
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
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/data?uri=' + uri + '&format=json&properties=+ancestors,hiddenLabel,notation,scopeNote,definition,identifier,example,location,depiction&cache=1')
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = that.getJSKOSPreview(data, mapbox_access_token)
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return

  #######################################################################
  # build treeview-Layout with treeview
  buildAndSetTreeviewLayout: (popover, cdata, cdata_form, that, topMethod = 0, returnDfr = false) ->
    treeview = new DANTE_ListViewTree(popover, cdata, cdata_form, that)
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
  showEditPopover: (btn, cdata, layout, search_token) ->
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
      data: cdata
      fields: that.__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        if !search_token
          that.__updateResult(cdata, layout)
          # update tree, if voc changed
          if elem.opts.name == 'dante_PopoverVocabularySelect' && that.getCustomMaskSettings().editor_style?.value == 'popover_with_treeview'
            @buildAndSetTreeviewLayout(@popover, cdata, cdata_form, that, 1, false)
        else
          # disabled till further development ...
          # that.__updateExtendedSearch(cdata, layout, search_token)
        that.__setEditorFieldStatus(cdata, layout)
        if elem.opts.name == 'searchbarInput' || elem.opts.name == 'dante_PopoverVocabularySelect'
          that.__updateSuggestionsMenu(cdata, cdata_form, data.searchbarInput, elem, suggest_Menu, searchsuggest_xhr, layout)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element : cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true

    # treeview?
    if that.getCustomMaskSettings().editor_style?.value == 'popover_with_treeview'
      # do search-request for all the top-entrys of vocabulary
      @buildAndSetTreeviewLayout(@popover, cdata, cdata_form, that, 1, false)

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

                          newTreeview = @buildAndSetTreeviewLayout(@popover, cdata, cdata_form, that, 0, false)

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
                        newTreeviewDfr = @buildAndSetTreeviewLayout(@popover, cdata, cdata_form, that, 1, true)

                        # if reset complete
                        newTreeviewDfr.done =>
                          # enable search + reset-buttons
                          searchButton.setEnabled(true)
                          resetButton.setEnabled(true)
                          button.setIcon(new CUI.Icon(class: "fa-undo"))

      # append "reset"-Button
      cdata_form.getFieldsByName("searchbarInput")[0].append(resetButton)
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
                                text: that.getVocabularyNameFromDatamodel()
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
                if that.getCustomMaskSettings().editor_style?.value != 'popover_with_treeview'
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
            centered: true
            text: cdata.conceptName
      center:
        content:
          new CUI.ButtonHref
            name: "outputButtonHref"
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

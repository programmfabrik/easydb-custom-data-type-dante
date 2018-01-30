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
  # returns name of the used vocabulary
  getUsedVocabularyName: ->
    xreturn = @getCustomSchemaSettings().vocabulary_name?.value
    if ! xreturn
      xreturn = 'gender'
    xreturn


  #######################################################################
  # handle editorinput
  renderEditorInput: (data, top_level_data, opts) ->
    #console.error @, data, top_level_data, opts, @name(), @fullName()

    if not data[@name()]
        cdata = {
            conceptName : ''
            conceptURI : ''
        }
        # if default values are set in masksettings
        if @getCustomMaskSettings().default_concept_uuid?.value && @getCustomMaskSettings().default_concept_name?.value
            cdata = {
                conceptName : @getCustomMaskSettings().default_concept_name?.value
                conceptURI : 'https://uri.gbv.de/terminology/dante/' + @getCustomMaskSettings().default_concept_uuid?.value
            }
        data[@name()] = cdata
    else
        cdata = data[@name()]

    # inline or popover?
    if @getCustomMaskSettings().use_inline?.value
        @__renderEditorInputInline(data, cdata)
    else
        @__renderEditorInputPopover(data, cdata)


  #######################################################################
  # render form (INLINE, with Dropdown)
  __renderEditorInputInline: (data, cdata) ->
        fields = []
        select = {
            type: CUI.Select
            undo_and_changed_support: false
            empty_text: $$('custom.data.type.dante.modal.form.dropdown.loadingentries')
            options: [
              (
                  text: $$('custom.data.type.dante.modal.form.dropdown.loadingentries')
                  value: undefined
              )
            ]
            name: 'dante_InlineSelect'
        }
        fields.push select

        ##################################################################
        # read entries from suggest and place as select / dropdown

        # start new request

        # cache on?
        cache = '&cache=0'
        if @getCustomMaskSettings().use_cache?.value
            cache = '&cache=1'

        # language
        desiredLanguage = ez5.loca.getLanguage()
        desiredLanguage = desiredLanguage.split('-')
        desiredLanguage = desiredLanguage[0]

        searchsuggest_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=&voc=' + @getUsedVocabularyName() + '&language=' + desiredLanguage + '&limit=1000' + cache)
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

            # if no hits set "empty" message to menu
            if select_items.length == 0
              itemList =
                items: [
                  text: "kein Treffer, Administrator kontaktieren!"
                  value: null
                ]

            # if xhr is done, fill existing empty select with the values
            cdata_form.getFieldsByName("dante_InlineSelect")[0]
            cdata_form.getFieldsByName("dante_InlineSelect")[0].opts.options = select_items
            cdata_form.getFieldsByName("dante_InlineSelect")[0]._options = select_items
            cdata_form.getFieldsByName("dante_InlineSelect")[0]._empty_text = $$('custom.data.type.dante.modal.form.dropdown.choose')
            cdata_form.getFieldsByName("dante_InlineSelect")[0].setValue(null)

            cdata_form.getFieldsByName("dante_InlineSelect")[0].reset()
            cdata_form.getFieldsByName("dante_InlineSelect")[0].reload()
            cdata_form.getFieldsByName("dante_InlineSelect")[0].displayValue()

            cdata_form.getFieldsByName("dante_InlineSelect")[0].enable()

            # if cdata is already set, choose correspondending option from select
            if cdata?.conceptURI != ''
                # read given options
                givenOpts = cdata_form.getFieldsByName("dante_InlineSelect")[0].opts.options
                # uuid of already saved entry
                givenUUID = cdata?.conceptURI.split('/')
                givenUUID = givenUUID.pop()
                for givenOpt in givenOpts
                  if givenOpt.value != null
                    testUUID = givenOpt.value.split('/')
                    testUUID = testUUID.pop()
                    if testUUID == givenUUID
                      cdata_form.getFieldsByName("dante_InlineSelect")[0].opts.options
                      cdata_form.getFieldsByName("dante_InlineSelect")[0].setValue(givenOpt.value)
                      cdata_form.getFieldsByName("dante_InlineSelect")[0].displayValue()
                      cdata_form.getFieldsByName("dante_InlineSelect")[0].setText(givenOpt.text)
                      cdata_form.getFieldsByName("dante_InlineSelect")[0].getValue()
        )

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
  # show tooltip with loader and then additional info
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
  # handle suggestions-menu  (POPOVER)
  #######################################################################
  __updateSuggestionsMenu: (cdata, cdata_form, suggest_Menu, searchsuggest_xhr) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        dante_searchstring = cdata_form.getFieldsByName("searchbarInput")[0].getValue()

        if ! that.getCustomMaskSettings().use_tree_view?.value
          dante_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()
        else
          dante_countSuggestions = 50

        if dante_searchstring.length == 0
            return

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        # start new request

        # cache?
        cache = '&cache=0'
        if that.getCustomMaskSettings().use_cache?.value
            cache = '&cache=1'
        # language
        desiredLanguage = ez5.loca.getLanguage()
        desiredLanguage = desiredLanguage.split('-')
        desiredLanguage = desiredLanguage[0]
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=' + dante_searchstring + '&voc=' + that.getUsedVocabularyName() + '&language=' + desiredLanguage + '&limit=' + dante_countSuggestions + cache)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

            extendedInfo_xhr = { "xhr" : undefined }

            # create new menu with suggestions
            menu_items = []
            for suggestion, key in data[1]
              do(key) ->
                item =
                  text: suggestion
                  value: data[3][key]
                  tooltip:
                    markdown: true
                    placement: "ne"
                    content: (tooltip) ->
                      # show infopopup
                      that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
                menu_items.push item

            # set new items to menu
            itemList =
              onClick: (ev2, btn) ->

                # if not treeview
                if ! that.getCustomMaskSettings().use_tree_view?.value
                  console.log "log new resuilt"
                  # lock result in variables
                  conceptName = btn.getText()
                  conceptURI = btn.getOpt("value")

                  # lock in save data
                  cdata.conceptURI = conceptURI
                  cdata.conceptName = conceptName

                  # lock in form
                  cdata_form.getFieldsByName("conceptName")[0].storeValue(conceptName).displayValue()
                  displayURI = conceptURI
                  if conceptURI.indexOf('uri.gbv.de/terminology') > 0
                    displayURI = 'https://uri.gbv.de/terminology/...'
                  cdata_form.getFieldsByName("conceptURI")[0].setText(displayURI)
                  cdata_form.getFieldsByName("conceptURI")[0].show()

                  # clear searchbar
                  cdata_form.getFieldsByName("searchbarInput")[0].setValue('')

                # if treeview
                if that.getCustomMaskSettings().use_tree_view?.value == true
                  # set choosen suggest-entry to searchbar
                  cdata_form.getFieldsByName("searchbarInput")[0].setValue(btn.getText())

              items: menu_items

            # if no hits set "empty" message to menu
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
  # set visibility of popover-form-result-fields

  # eh, this is very dirty...
  __setResultFieldVisibility: (elem, cdata, cdata_form) ->
    if elem.getName() == 'conceptName' || elem.getName() == 'conceptURI'
      if cdata.conceptURI != '' && cdata.conceptName != ''

        if cdata_form.DOM.children[0].children[0].children[1].getElementsByClassName("cui-data-field-hidden").length > 0
          cdata_form.DOM.children[0].children[0].children[1].getElementsByClassName("cui-data-field-hidden")[0].classList.remove("cui-data-field-hidden")

        if cdata_form.DOM.children[0].children[0].children[2].getElementsByClassName("cui-data-field-hidden").length > 0
          cdata_form.DOM.children[0].children[0].children[2].getElementsByClassName("cui-data-field-hidden")[0].classList.remove("cui-data-field-hidden")

        cdata_form.DOM.children[0].children[0].children[1].style.display = "table-row"
        cdata_form.DOM.children[0].children[0].children[2].style.display = "table-row"
        if cdata_form.DOM.children[0].children[0].children[3]
          cdata_form.DOM.children[0].children[0].children[3].style.display = "table-row"

    @


  #######################################################################
  # show popover and fill it with the form-elements
  # https://github.com/programmfabrik/coffeescript-ui-demo/blob/master/src/demos/ListView/ListViewDemo.coffee
  # https://github.com/programmfabrik/coffeescript-ui-demo/blob/master/src/demos/ListView/ListViewTreeDemo.coffee
  # https://programmfabrik.github.io/coffeescript-ui-demo/public/#ListView
  showEditPopover: (btn, cdata, layout) ->
    that = @

    that.resettedPopup = false;

    # init popover
    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }

    # set default value for count of suggestions
    cdata.countOfSuggestions = 20
    cdata_form = new CUI.Form
      data: cdata
      fields: @__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        @__updateResult(cdata, layout)
        @__setEditorFieldStatus(cdata, layout)
        if elem.opts.name == 'searchbarInput'
          @__updateSuggestionsMenu(cdata, cdata_form, suggest_Menu, searchsuggest_xhr)
        @__setResultFieldVisibility(elem, cdata, cdata_form)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element : cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true

    # treeview
    if that.getCustomMaskSettings().use_tree_view?.value == true

      style = CUI.dom.element("style")
      style.innerHTML = ".dantePlugin_ResetButton { margin-left: 4px; } .dantePlugin_SearchButton { margin-left: 4px; } .dantePlugin_Treeview {border-bottom: 1px solid #efefef; padding: 10px 0px; max-height: 500px; overflow-y: auto;}"
      document.head.appendChild(style)

      # do search-request for all the top-entrys of vocabulary
      topTree_xhr = { "xhr" : undefined }
      # abort eventually running request
      if topTree_xhr.xhr != undefined
        topTree_xhr.xhr.abort()

      treeview = new DANTE_ListViewTree(@popover, cdata, cdata_form, that)

      treeview.getTopTreeView(that.getUsedVocabularyName(), 1)

      treeviewPane = new CUI.Pane
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
                                text: that.getUsedVocabularyName()
              ]
          center:
              content: [
                  treeview.treeview
                ,
                  cdata_form
              ]

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

                          newTreeview = new DANTE_ListViewTree(that.popover, cdata, cdata_form, that)

                          newTreeviewPane = new CUI.Pane
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
                                                    text: that.getUsedVocabularyName()
                                  ]
                              center:
                                  content: [
                                      newTreeview.treeview
                                    ,
                                      cdata_form
                                  ]
                          that.popover.setContent(newTreeviewPane)

                          newTreeview.getSearchResultTree(searchTerm, that.getUsedVocabularyName(), cache)
                          .done =>
                            # enable search + reset-buttons
                            searchButton.setEnabled(true)
                            resetButton.setEnabled(true)

                            button.setIcon(new CUI.Icon(class: "fa-search"))

                            that.popover.setContent(newTreeviewPane)

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

      # append button after autocomplete-input
      resetButton =  new CUI.Button
                      text: $$('custom.data.type.dante.modal.form.popup.treeviewreset')
                      icon_left: new CUI.Icon(class: "fa-undo")
                      class: 'dantePlugin_ResetButton'
                      onClick: (evt,button) =>

                        # if reset is pressed, dont use cache for this popup!
                        that.resettedPopup = true

                        # clear searchbar
                        cdata_form.getFieldsByName("searchbarInput")[0].setValue('').displayValue()

                        # disable search + reset-buttons
                        searchButton.setEnabled(false)
                        resetButton.setEnabled(false)

                        button.setIcon(new CUI.Icon(class: "fa-spinner fa-spin"))

                        # attach info to cdata_form
                        newTreeview = new DANTE_ListViewTree(that.popover, cdata, cdata_form, that)

                        newTreeviewPane = new CUI.Pane
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
                                                  text: that.getUsedVocabularyName()
                                ]
                            center:
                                content: [
                                    newTreeview.treeview
                                  ,
                                    cdata_form
                                ]
                        that.popover.setContent(newTreeviewPane)

                        newTreeview.getTopTreeView(that.getUsedVocabularyName(), 0)
                        .done =>
                          # enable search + reset-buttons
                          searchButton.setEnabled(true)
                          resetButton.setEnabled(true)

                          button.setIcon(new CUI.Icon(class: "fa-undo"))

                          that.popover.setContent(newTreeviewPane)

                          @

      # append "search"-Button
      cdata_form.getFieldsByName("searchbarInput")[0].append(searchButton)
      # append "reset"-Button
      cdata_form.getFieldsByName("searchbarInput")[0].append(resetButton)

      @popover.setContent(treeviewPane)
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
                                text: that.getUsedVocabularyName()
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
    # count of suggestions (not for treeview)
    if ! that.getCustomMaskSettings().use_tree_view?.value
        option =  {
          type: CUI.Select
          class: "commonPlugin_Select"
          undo_and_changed_support: false
          form:
              label: $$('custom.data.type.dante.modal.form.text.count')
          options: [
            (
                value: 10
                text: '10 ' + $$("custom.data.type.dante.modal.form.text.count")
            )
            (
                value: 20
                text: '20 ' + $$("custom.data.type.dante.modal.form.text.count")
            )
            (
                value: 50
                text: '50 ' + $$("custom.data.type.dante.modal.form.text.count")
            )
            (
                value: 100
                text: '100 ' + $$("custom.data.type.dante.modal.form.text.count")
            )
          ]
          name: 'countOfSuggestions'
        }
        fields.push option
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
    # result name (must)
    option =  {
          form:
            label: $$("custom.data.type.dante.modal.form.text.result.label")
          type: CUI.Output
          name: "conceptName"
          data: {conceptName: cdata.conceptName}
          onInit : (elem) =>
            if cdata.conceptName == ''
              elem.hide()
            else
              elem.show()
        }
    fields.push option
    # result uri (must)
    displayURI = cdata.conceptURI
    if cdata.conceptURI.indexOf('uri.gbv.de/terminology') > 0
      displayURI = 'https://uri.gbv.de/terminology/...'
    option =  {
          form:
            label: $$("custom.data.type.dante.modal.form.text.uri.label")
          type: CUI.FormButton
          name: "conceptURI"
          icon: new CUI.Icon(class: "fa-external-link")
          text: displayURI
          onClick: (evt,button) =>
            window.open 'https://uri.gbv.de/terminology/?uri=' + cdata.conceptURI, "_blank"
          onInit : (elem) =>
            if cdata.conceptURI == ''
              elem.hide()
            else
              elem.show()
          onDataChanged : (button) =>
            console.log "onDataChanged"
        }

    fields.push option

    fields



  #######################################################################
  # renders the "result" in original form (outside popover)
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
    new CUI.ButtonHref
      name: "outputButtonHref"
      appearance: "link"
      href: 'https://uri.gbv.de/terminology/?uri=' + encodedURI
      target: "_blank"
      icon_left: new CUI.Icon(class: "fa-commenting-o")
      tooltip:
        markdown: true
        placement: 'nw'
        content: (tooltip) ->
          # get jskos-details-data
          that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
          # loader, unteil details are xhred
          new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
      text: cdata.conceptName
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

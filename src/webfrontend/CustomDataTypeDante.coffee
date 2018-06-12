# there are only 2 use-cases which can be configured by config
#   1. use as a dropdown
#   2. use as a searchfield with popover (extended mode)
#       a) for treeview 
#       b) for more details (f.e. categorie, type ..) --> (not needed in dante!!!)

class CustomDataTypeDANTE extends CustomDataTypeWithCommons

  #######################################################################
  # load  css
  #CUI.ready =>
  #  cssLoader = new CUI.CSSLoader()
  #  cssLoader.load(url: '/api/v1/plugin/static/extension/custom-data-type-dante/css/CustomDataTypeDante.css')

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
  # layout with searchbar and vertical-dots-button for menu 
  #     for popover-use
  
  # !!! function is in library! move it back, if development is done
  # because it works for all plugins except "georef"
  __renderEditorInputPopover: (data, cdata, opts={}) ->

    that = @

    layout

    # if treeview?
    if that.getCustomMaskSettings().editor_style?.value == 'popover_with_treeview'
      #cdata = {
      #      conceptName : ''
      #      conceptURI : ''
      #}
      # make searchfield
      
      # kann das eventuell raus!?!? 
      # oder für extended suche?
      search_token = new SearchToken
          column: @
          data: data
          fields: opts.fields
      search_token.element.readOnly = true
      search_token.element.placeholder = '<--'
      # disable till further dev...
      search_token = null

    # build layout for editor
    layout = new CUI.HorizontalLayout
        class: ''
        center:
          class: ''
        right:
          content:
              new CUI.Buttonbar
                buttons: [
                  new CUI.Button
                    text: ''
                    icon: new CUI.Icon(class: "fa-ellipsis-v")
                    class: 'pluginDirectSelectEditSearch'
                    # show "dots"-menu on click on 3 vertical dots
                    onClick: (e, dotsButton) =>
                      dotsButtonMenu = new CUI.Menu
                          element : dotsButton
                          menu_items = [
                              #search
                              text: 'Suchen'
                              value: 'search'
                              icon_left: new CUI.Icon(class: "fa-search")
                              onClick: (e2, btn2) -> 
                                that.showEditPopover(dotsButton, cdata, layout, search_token)
                            ,
                              #detailinfo
                              text: 'Detailinfo'
                              value: 'detail'
                              icon_left: new CUI.Icon(class: "fa-info-circle")
                              disabled: that.isEmpty(data, 0, 0)
                              tooltip:
                                markdown: true
                                placement: 'w'
                                content: (tooltip) ->
                                  if !that.isEmpty(data, 0, 0)
                                    # get jskos-details-data
                                    encodedURI = encodeURIComponent(cdata.conceptURI)
                                    extendedInfo_xhr = { "xhr" : undefined }
                                    that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                                    # loader, until details are xhred
                                    new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))                                      
                            ,
                              # call uri
                              text: 'URI aufrufen'
                              value: 'uri'
                              icon_left: new CUI.Icon(class: "fa-external-link")
                              disabled: that.isEmpty(data, 0, 0)
                              onClick: -> 
                                window.open cdata.conceptURI, "_blank"
                            ,
                              #delete / clear
                              text: 'Löschen'
                              value: 'delete'
                              icon_left: new CUI.Icon(class: "fa-trash")
                              disabled: that.isEmpty(data, 0, 0)
                              onClick: ->
                                cdata = {
                                    conceptName : ''
                                    conceptURI : ''
                                }
                                data[that.name()] = cdata
                                that.__updateResult(cdata, layout)
                          ]
                          itemList = 
                            items: menu_items
                      dotsButtonMenu.setItemList(itemList)
                      dotsButtonMenu.show()                          
                ]
    @__updateResult(cdata, layout)
    layout

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

        # read "count of suggestion" --> limit-Parameter
        dante_countSuggestions = 50

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        # start new request

        # cache?
        cache = '&cache=0'
        if that.getCustomMaskSettings().use_cache?.value
            cache = '&cache=1'
        
        # start request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=' + dante_searchstring + '&voc=' + that.getUsedVocabularyName() + '&language=' + that.getFrontendLanguage() + '&limit=' + dante_countSuggestions + cache)
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
                console.log "clicked on suggest"
                console.log that.popover
                # if not treeview
                if that.getCustomMaskSettings().editor_style?.value != 'popover_with_treeview' || ! that.popover
                  console.log "111"
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
                                              text: that.getUsedVocabularyName()
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

                  # start request for the choosen record
                  dataEntry_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/data?uri=' + searchUri + cache)
                  dataEntry_xhr.start().done((data, status, statusText) ->
                    if data.length == 1
                      if data[0].uri 
                        # lock result in variables
                        if data[0].prefLabel?[that.getFrontendLanguage()]                        
                          conceptName = data[0].prefLabel?[that.getFrontendLanguage()]
                        else
                          conceptName = data[0].prefLabel[Object.keys(data[0].prefLabel)[0]]
                        conceptURI = data[0].uri
                        
                        # lock in save data
                        cdata.conceptURI = conceptURI
                        cdata.conceptName = conceptName
                        # update the layout in form
                        console.log "2222"
                        that.__updateResult(cdata, layout)
                        
                        # close popover
                        if that.popover
                          that.popover.hide()
                        
                        @
                  )
                  
                # if treeview
                if that.getCustomMaskSettings().editor_style?.value == 'popover_with_treeview' && that.popover
                  if cdata_form
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
  # update result in Masterform (funktion auch in lib schon drin, aber eben anders)
  __updateResult: (cdata, layout) ->
    that = @
    # if field is not empty
    if cdata?.conceptURI 
      # die uuid einkürzen..
      displayURI = cdata.conceptURI
      displayURI = displayURI.replace('http://', '')
      displayURI = displayURI.replace('https://', '')
      uriParts = displayURI.split('/')
      uuid = uriParts.pop()
      if uuid.length > 10 
        uuid = uuid.substring(0,5) + '…'
        uriParts.push(uuid)
        displayURI = uriParts.join('/')
        
      info = new CUI.VerticalLayout
        class: 'ez5-info_dante'
        top:
          content:
              new CUI.Label
                text: cdata.conceptName
        bottom:
          content:
            new CUI.Button
              name: "outputButtonHref"
              appearance: "flat"
              size: "normal"
              text: displayURI
              tooltip:
                markdown: true
                placement: 'nw'
                content: (tooltip) ->
                  # get jskos-details-data
                  encodedURI = encodeURIComponent(cdata.conceptURI)
                  extendedInfo_xhr = { "xhr" : undefined }
                  that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                  # loader, unteil details are xhred
                  new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))   
              onClick: (evt,button) =>
                  window.open cdata.conceptURI, "_blank"

      layout.replace(info, 'center')
      layout.addClass('ez5-linked-object-edit')                    
      options =
        class: 'ez5-linked-object-container'
      layout.__initPane(options, 'center') 
      
    # if field is empty, display searchfield
    if ! cdata?.conceptURI
      suggest_Menu_directInput

      inputX = new CUI.Input
                  class: "pluginDirectSelectEditInput"
                  undo_and_changed_support: false
                  name: "directSelectInput"
                  content_size: false
                  onKeyup: (input) =>
                    # do suggest request and show suggestions
                    searchstring = input.getValueForInput()
                    @__updateSuggestionsMenu(cdata, 0, searchstring, input, suggest_Menu_directInput, searchsuggest_xhr, layout)
      inputX.render()

      # init suggestmenu
      suggest_Menu_directInput = new CUI.Menu
          element : inputX
          use_element_width_as_min_width: true

      # init xhr-object to abort running xhrs
      searchsuggest_xhr = { "xhr" : undefined }
      
      layout.replace(inputX, 'center')
      layout.removeClass('ez5-linked-object-edit')                    
      options =
        class: ''
      layout.__initPane(options, 'center')   
      
    # did data change?
    that.__setEditorFieldStatus(cdata, layout)
    

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

                  # start new request
                  searchsuggest_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=&voc=' + @getUsedVocabularyName() + '&language=' + @getFrontendLanguage() + '&limit=1000' + cache)
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
  # show popover and fill it with the form-elements
  # https://github.com/programmfabrik/coffeescript-ui-demo/blob/master/src/demos/ListView/ListViewDemo.coffee
  # https://github.com/programmfabrik/coffeescript-ui-demo/blob/master/src/demos/ListView/ListViewTreeDemo.coffee
  # https://programmfabrik.github.io/coffeescript-ui-demo/public/#ListView
  showEditPopover: (btn, cdata, layout, search_token) ->
    that = @

    that.resettedPopup = false;
    
    suggest_Menu

    # init popover
    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }
    
    cdata_form = new CUI.Form
      data: cdata
      fields: that.__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        console.log "f onDataChanged"
        console.log(data)
        console.log(elem)
        console.log search_token
        if !search_token
          console.log ("f __updateResult")
          that.__updateResult(cdata, layout)
        else
          # disabled till further dev ...
          that.__updateExtendedSearch(cdata, layout, search_token)
        that.__setEditorFieldStatus(cdata, layout)
        if elem.opts.name == 'searchbarInput'
          that.__updateSuggestionsMenu(cdata, cdata_form, data.searchbarInput, elem, suggest_Menu, searchsuggest_xhr, layout)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element : cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true

    # treeview?
    if that.getCustomMaskSettings().editor_style?.value == 'popover_with_treeview'

      style = CUI.dom.element("style")
      style.innerHTML = ".commonPlugin_Input { max-width: 100%; } .commonPlugin_Input .cui-input { max-width: 50%; } .dantePlugin_ResetButton { margin-left: 4px; } .dantePlugin_SearchButton { margin-left: 4px; } .dantePlugin_Treeview {border-bottom: 1px solid #efefef; padding: 10px 0px; max-height: 500px; overflow-y: auto;}"
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
    # evt. dropdown for vocabularyschoose ...
    # evt. dropdown for vocabularyschoose ...
    # evt. dropdown for vocabularyschoose ...
    # evt. dropdown for vocabularyschoose ...    
    
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

    new CUI.ButtonHref
      name: "outputButtonHref"
      appearance: "link"
      size: "normal"
      href: 'https://uri.gbv.de/terminology/?uri=' + encodedURI
      target: "_blank"
      #icon_left: new CUI.Icon(class: "fa-commenting-o")
      #icon_right: new CUI.Icon(class: "fa-external-link-square-alt")
      class: "cdt_dante_smallMarginTop"
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

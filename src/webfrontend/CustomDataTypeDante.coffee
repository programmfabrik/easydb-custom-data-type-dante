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
  # render form (INLINE)
  __renderEditorInputInline: (data, cdata) ->
        fields = []
        select = {
            type: Select
            undo_and_changed_support: false
            empty_text: "Einträge werden geladen .."
            options: [
              (
                  text: "Einträge werden geladen .."
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

        searchsuggest_xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=&danteuris&voc=' + @getUsedVocabularyName() + '&limit=1000' + cache)
        searchsuggest_xhr.start().done((data, status, statusText) ->
            # read options for select
            select_items = []
            item = (
              text: 'auswählen ..'
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
            cdata_form.getFieldsByName("dante_InlineSelect")[0]._empty_text = 'auswählen ..'
            cdata_form.getFieldsByName("dante_InlineSelect")[0].setValue(null)

            cdata_form.getFieldsByName("dante_InlineSelect")[0].reset()
            cdata_form.getFieldsByName("dante_InlineSelect")[0].reload()
            cdata_form.getFieldsByName("dante_InlineSelect")[0].displayValue()

            cdata_form.getFieldsByName("dante_InlineSelect")[0].enable()

            # if cdata is already set, choose correspondending option from select
            if cdata?.conceptURI != ''
                cdata_form.getFieldsByName("dante_InlineSelect")[0].opts.options
                cdata_form.getFieldsByName("dante_InlineSelect")[0].setValue(cdata.conceptURI)
                cdata_form.getFieldsByName("dante_InlineSelect")[0].displayValue()
                cdata_form.getFieldsByName("dante_InlineSelect")[0].setText(cdata.conceptName)
                cdata_form.getFieldsByName("dante_InlineSelect")[0].getValue()
        )

        # generate preview-button
        if ! @getCustomMaskSettings().hide_result_info.value
            btn = @__renderButtonByData(cdata)
            preview = new DataFieldProxy(
                    element: btn
            )

        if preview
            fields.push(preview)

        cdata_form = new Form
                data: cdata
                onDataChanged: =>
                        element = cdata_form.getFieldsByName("dante_InlineSelect")[0]
                        cdata.conceptURI = element.getValue()
                        element.displayValue()
                        cdata.conceptName = element.getText()
                        if preview
                            preview.replace(@__renderButtonByData(cdata))

                        Events.trigger
                                node: element
                                type: "editor-changed"
                fields: fields
        .start()

        cdata_form.getFieldsByName("dante_InlineSelect")[0].disable()

        cdata_form


  #######################################################################
  # read info from dante-terminology
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr) ->
    # extract danteID from uri
    danteID = uri
    danteID = danteID.split "/"
    danteID = danteID.pop()
    # download infos
    if extendedInfo_xhr.xhr != undefined
      # abort eventually running request
      extendedInfo_xhr.xhr.abort()
    # start new request
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//uri.gbv.de/terminology/dante/' + danteID + '?format=json')
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = '<span style="font-weight: bold">Informationen über den Eintrag</span>'
      tooltip.DOM.html(htmlContent)
      tooltip.autoSize()
    )
    .fail (data, status, statusText) ->
        CUI.debug 'FAIL', extendedInfo_xhr.xhr.getXHR(), extendedInfo_xhr.xhr.getResponseHeaders()

    return


  #######################################################################
  # handle suggestions-menu  (POPOVER)
  #######################################################################
  __updateSuggestionsMenu: (cdata, cdata_form, suggest_Menu, searchsuggest_xhr) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        dante_searchstring = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
        dante_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

        if dante_searchstring.length == 0
            return

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        # start new request
        cache = '&cache=0'
        if that.getCustomMaskSettings().use_cache?.value
            cache = '&cache=1'
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.dante.gbv.de/suggest?search=' + dante_searchstring + '&danteuris&voc=' + that.getUsedVocabularyName() + '&limit=' + dante_countSuggestions + cache)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

            CUI.debug 'OK', searchsuggest_xhr.xhr.getXHR(), searchsuggest_xhr.xhr.getResponseHeaders()

            extendedInfo_xhr = { "xhr" : undefined }

            # create new menu with suggestions
            menu_items = []
            # the actual Featureclass
            for suggestion, key in data[1]
              do(key) ->
                # the actual Featureclass...
                #aktType = data[2][key]
                #lastType = ''
                #if key > 0
                #  lastType = data[2][key-1]
                #if aktType != lastType
                #  item =
                #    divider: true
                #  menu_items.push item
                #  item =
                #    label: aktType
                #  menu_items.push item
                #  item =
                #    divider: true
                #  menu_items.push item
                item =
                  text: suggestion
                  value: data[3][key]
                  tooltip:
                    markdown: true
                    placement: "e"
                    content: (tooltip) ->
                      # if enabled in mask-config
                      if that.getCustomMaskSettings().show_infopopup?.value
                        that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                        new Label(icon: "spinner", text: "lade Informationen")
                menu_items.push item

            # set new items to menu
            itemList =
              onClick: (ev2, btn) ->

                # lock result in variables
                conceptName = btn.getText()
                conceptURI = btn.getOpt("value")

                # lock in save data
                cdata.conceptURI = conceptURI
                cdata.conceptName = conceptName
                # lock in form
                cdata_form.getFieldsByName("conceptName")[0].storeValue(conceptName).displayValue()
                # nach eadb5-Update durch "setText" ersetzen und "__checkbox" rausnehmen
                cdata_form.getFieldsByName("conceptURI")[0].__checkbox.setText(conceptURI)
                cdata_form.getFieldsByName("conceptURI")[0].show()

                # clear searchbar
                cdata_form.getFieldsByName("searchbarInput")[0].setValue('')
              items: menu_items

            # if no hits set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: "kein Treffer"
                  value: undefined
                ]
            suggest_Menu.setItemList(itemList)
            suggest_Menu.show()

        )
        #.fail (data, status, statusText) ->
            #CUI.debug 'FAIL', searchsuggest_xhr.getXHR(), searchsuggest_xhr.getResponseHeaders()
    ), delayMillisseconds



  #######################################################################
  # create form (POPOVER)
  #######################################################################
  __getEditorFields: (cdata) ->
    fields = [
      {
        type: Select
        class: "commonPlugin_Select"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.dante.modal.form.text.count')
        options: [
          (
              value: 10
              text: '10 Vorschläge'
          )
          (
              value: 20
              text: '20 Vorschläge'
          )
          (
              value: 50
              text: '50 Vorschläge'
          )
          (
              value: 100
              text: '100 Vorschläge'
          )
        ]
        name: 'countOfSuggestions'
      }
      {
        type: Input
        class: "commonPlugin_Input"
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.dante.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.dante.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
      }
      {
        form:
          label: "Gewählter Eintrag"
        type: Output
        name: "conceptName"
        data: {conceptName: cdata.conceptName}
      }
      {
        form:
          label: "Verknüpfte URI"
        type: FormButton
        name: "conceptURI"
        icon: new Icon(class: "fa-lightbulb-o")
        text: cdata.conceptURI
        onClick: (evt,button) =>
          window.open cdata.conceptURI, "_blank"
        onRender : (_this) =>
          if cdata.conceptURI == ''
            _this.hide()
      }]

    fields



  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->
    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new EmptyLabel(text: $$("custom.data.type.dante.edit.no_dante")).DOM
      when "invalid"
        return new EmptyLabel(text: $$("custom.data.type.dante.edit.no_valid_dante")).DOM

    # output Button with Name of picked dante-Entry and URI
    new ButtonHref
      name: "outputButtonHref"
      appearance: "flat"
      href: cdata.conceptURI
      target: "_blank"
      icon_left: new Icon(class: "fa-commenting-o")
      tooltip:
        markdown: true
        placement: 'n'
        content: () ->
          uri = cdata.conceptURI
          danteUUID = uri.split('/')
          danteUUID = danteUUID.pop()
          # get jskos-details-data
          # ...
          # ...
          uri
      text: cdata.conceptName
    .DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    console.log custom_settings

    if custom_settings.vocabulary_name?.value
      tags.push "DANTE-Vok: " + custom_settings.vocabulary_name.value
    else
      tags.push "Kein DANTE-Vokabular hinterlegt"

    tags


CustomDataType.register(CustomDataTypeDANTE)
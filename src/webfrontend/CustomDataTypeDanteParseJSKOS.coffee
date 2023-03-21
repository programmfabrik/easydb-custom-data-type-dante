# generates a html-preview for a given jskos-record
CustomDataTypeDANTE.prototype.getJSKOSPreview = (data, mapbox_access_token = false) ->
  that = @
  html = ''
  ancestors = ''
  spaces = ''
  namewithpath = ''

  # wenn deutsches prefLabel
  if data instanceof Array
    data = data[0]

  prefLabel = $$('custom.data.type.dante.modal.form.popup.jskospreview.nopreflabel')
  if data?.prefLabel
    prefLabel = that.getPrefLabelFromJSKOS(data)

  xuri = data.uri.replace(/terminology/g, '...')

  html += '<div style="font-size: 12px; color: #999;"><span class="cui-label-icon"><i class="fa  fa-external-link"></i></span>&nbsp;' + xuri + '</div>'

  html += '<h3><span class="cui-label-icon"><i class="fa  fa-info-circle"></i></span>&nbsp;' + prefLabel + '</h3>'

  # build ancestors-hierarchie
  if data.ancestors
    data.ancestors = data.ancestors.reverse()
    for key, val of data.ancestors
      if val != null
        tmpPrefLabel = that.getPrefLabelFromJSKOS(val)
        spaces = ''
        i = 0
        while i < key
          spaces += '&nbsp;&nbsp;'
          i++
        namewithpath += tmpPrefLabel + ' > '
        ancestors += spaces + '<span class="danteTooltipAncestors"><span class="cui-label-icon"><i class="fa fa-sitemap" aria-hidden="true"></i></span> ' + tmpPrefLabel + '</span><br />'
  if ancestors != ''
    html += ancestors + spaces + '<span class="danteTooltipAncestors">&nbsp;&nbsp;<span class="cui-label-icon"><i class="fa fa-arrow-circle-o-right" aria-hidden="true"></i></span> ' + prefLabel + '</span><br />'
    namewithpath += prefLabel

  if namewithpath == ''
    namewithpath = prefLabel

  # Preflabels in other languages
  prefLabels = ''
  if data?.prefLabel
    for key, val of data.prefLabel
        if val != prefLabel
          prefLabels = ' - ' + val + ' (' + key + ')<br />' + prefLabels
  if prefLabels
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.terms') + '</h4>' + prefLabels

  # Alternative Labels  (any language)
  altLabels = ''
  if data.altLabel
    for key, val of data.altLabel
      for key2, val2 of val
        altLabels = ' - ' + val2 + '<br />' + altLabels
  if altLabels
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.altterms') + '</h4>' + altLabels

  # Hidden Labels (any language)
  hiddenLabels = []
  if data.hiddenLabel
    for key, val of data.hiddenLabel
      for key2, val2 of val
        hiddenLabels.push val2
  if hiddenLabels.length > 0
    hiddenLabels = hiddenLabels.join(', ')
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.keywords') + '</h4>' + hiddenLabels

  # Notations
  notations = ''
  if data.notation
    for key, val of data.notation
      notations = ' &#8226; ' + val + '<br />' + notations
  if notations
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.notations') + '</h4>' + notations

  # startDate + startPlace
  startPlaces = []
  if data.startDate || data.startPlace
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.startDate') + '</h4>'
    if data.startDate
      html += data.startDate + '<br />'
    if data.startPlace
      for key, val of data.startPlace
        startPlaces.push ' &#8226; ' + val.prefLabel.und
      startPlaces = startPlaces.filter((item, i, ar) ->
        ar.indexOf(item) == i
      )
      html += startPlaces.join('<br />')

  # endDate + endPlace
  endPlaces = []
  if data.endDate || data.endPlace
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.endDate') + '</h4>'
    if data.endDate
      html += data.endDate + '<br />'
    if data.endPlace
      for key, val of data.endPlace
        endPlaces.push ' &#8226; ' + val.prefLabel.und
      endPlaces = endPlaces.filter (item, i, ar) ->
        ar.indexOf(item) == i
      html += endPlaces.join('<br />')

  # Depiction
  if data.depiction
    depictionPreview = ''
    for key, value of data.depiction
      depictionPreview += '<div class="depictionPreview" style="background-image: url(' + value + ')"></div>'
    if depictionPreview != ''
      html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.depiction') + '</h4>' + depictionPreview

  # Farbe (wenn notation=hexcode)
  if notations != ''
    colorPreview = ''
    for key, value of data.notation
      if /^#[0-9a-f]{6}/i.test(value)
        colorPreview += '<div class="colorPreview" style="background-color: ' + value + '"></div>'
    if colorPreview != ''
      html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.colors') + '</h4>' + colorPreview

  # Karte, zeige nur einen Ort
  location = ''
  if data.location
    if data.location.length > 0
    # if mapbox-token given
      if mapbox_access_token
        for key, value of data.location
          # wrap value in "geometry"
          value = JSON.parse('{"geometry": ' + JSON.stringify(value) + '}')

          # generates static mapbox-map via geojson
          htmlContent = '{"type": "FeatureCollection","features": []}'

          # compare to https://www.mapbox.com/mapbox.js/example/v1.0.0/static-map-from-geojson-with-geo-viewport/
          jsonStr = '{"type": "FeatureCollection","features": []}'
          json = JSON.parse(jsonStr)

          json.features.push value

          bounds = geojsonExtent(json)
          if bounds
            size = [
              500
              300
            ]
            vp = geoViewport.viewport(bounds, size)
            encodedGeoJSON = value
            encodedGeoJSON.properties = {}
            encodedGeoJSON.type = "Feature"
            encodedGeoJSON.properties['stroke-width'] = 4
            encodedGeoJSON.properties['stroke'] = '#C20000'
            encodedGeoJSON = JSON.stringify(encodedGeoJSON)
            encodedGeoJSON = encodeURIComponent(encodedGeoJSON)
            if vp.zoom > 16
              vp.zoom = 15;
            imageSrc = window.location.protocol + '//api.mapbox.com/v4/mapbox.streets-satellite/geojson(' + encodedGeoJSON + ')/' +  vp.center.join(',') + ',' + vp.zoom + '/' + size.join('x') + '@2x.png?access_token=' + mapbox_access_token
            htmlContent = "<div class=\"mapImage\" style=\"background-image: url('" + imageSrc  + "');\"></div>"
            location += htmlContent
        if location != ''
          html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.georef') + '</h4>' + location

  # Definitions ("de" first)
  definition = ''
  if data.definition
    if data.definition.de
      for key, value of data.definition.de
        definition += value + '<br />'
    # if no entry in german, find entrys in english
    if definition == ''
      if data.definition.en
        for key, value of data.definition.en
          definition += value + '<br />'
    # else find entrys in any language
    if definition == ''
      for key, value of data.definition
        for key2, value2 of data.definition.key
          definition += value2 + '<br />'
  if definition
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.definition') + '</h4>' + definition

  # scopeNote
  scopeNote = ''
  if data.scopeNote
    if data.scopeNote.de
      for key, value of data.scopeNote.de
        scopeNote += value + '<br />'
    # if no entry in german, find entrys in english
    if scopeNote == ''
      if data.scopeNote.en
        for key, value of data.scopeNote.en
          scopeNote += value + '<br />'
    # else find entrys in any language
    if scopeNote == ''
      for key, value of data.scopeNote
        for key2, value2 of data.scopeNote.key
          scopeNote += value2 + '<br />'
  if scopeNote
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.scopenote') + '</h4>' + scopeNote

  # example
  example = ''
  if data.example
    if data.example.de
      for key, value of data.example.de
        example += value + '<br />'
    # if no entry in german, find entrys in english
    if example == ''
      if data.example.en
        for key, value of data.example.en
          example += value + '<br />'
    # else find entrys in any language
    if example == ''
      for key, value of data.example
        for key2, value2 of data.example.key
          example += value2 + '<br />'
  if example
    html += '<h4>' + $$('custom.data.type.dante.modal.form.popup.jskospreview.example') + '</h4>' + example

  html = '<style>.danteTooltip { padding: 10px; min-width:200px; } .danteTooltip h4 { margin-bottom: 0px; } .danteTooltip .danteTooltipAncestors { font-size: 13px; font-weight: bold; margin-top: 0px;} .danteTooltip .mapImage {background-color: #EFEFEF; position: relative; width: 100%; height: 150px; background-size: cover; background-repeat: no-repeat; margin-bottom: 6px; border-radius: 2px;} .danteTooltip .colorPreview{ width:100%; height: 100px; } .depictionPreview {background-size: contain; background-repeat: no-repeat; background-position: center center; width: 100%; height:150px; background-color: #EFEFEF;}</style><div class="danteTooltip">' + html + '</div>'
  return html


#############################################################################
# get prefLabel from JSKOS (preferred in active Frontend-Language)
#############################################################################
CustomDataTypeDANTE.prototype.getPrefLabelFromJSKOS = (jskos) ->
    prefLabelFallback = $$("custom.data.type.dante.modal.form.popup.treeview.nopreflabel")

    if !jskos.prefLabel
      return prefLabelFallback

    prefLabels = jskos.prefLabel

    prefLabel = prefLabelFallback;

    desiredLanguage = ez5.loca.getLanguage()
    desiredLanguage = desiredLanguage.split('-')
    desiredLanguage = desiredLanguage[0]

    frontendLanguages = ez5.session.getConfigFrontendLanguages().slice()
    for key, value of frontendLanguages
      tmp = value.split('-')
      tmp = tmp[0]
      frontendLanguages[key] = tmp

    if prefLabels instanceof Array or prefLabels instanceof Object
      if prefLabels.count == 0
        prefLabels = undefined
      # wenn desiredLanguage prefLabel
      if prefLabels.hasOwnProperty(desiredLanguage)
        prefLabel = prefLabels[desiredLanguage]
      # wenn kein desiredLanguage prefLabel
      if !prefLabel or prefLabel == undefined or prefLabel == 'undefined' or prefLabel == prefLabelFallback
        # gibt es ein anderes Label in einer der frontendsprachen
        for key, value of frontendLanguages
          if prefLabels.hasOwnProperty(value)
            prefLabel = prefLabels[value]
        # ansonsten irgendeine Sprache
        if !prefLabel or prefLabel == undefined or prefLabel == 'undefined' or prefLabel == prefLabelFallback
          for key, value of prefLabels
            prefLabel = prefLabels[key];
            break

      prefLabel

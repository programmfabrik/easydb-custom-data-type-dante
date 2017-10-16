# generates a html-preview for a given jskos-record
CustomDataTypeDANTE.prototype.getJSKOSPreview = (data) ->
  that = @
  html = ''
  ancestors = ''
  spaces = ''
  namewithpath = ''

  # wenn deutsches prefLabel
  if data instanceof Array
    data = data[0]
  prefLabel = that.getPrefLabelPrefGermanFromJSKOS(data.prefLabel)

  xuri = data.uri.replace(/terminology/g, '...')

  html += '<div style="font-size: 12px; color: #999;"><span class="cui-label-icon"><i class="fa  fa-external-link"></i></span>&nbsp;' + xuri + '</div>'

  html += '<h3><span class="cui-label-icon"><i class="fa  fa-info-circle"></i></span>&nbsp;' + prefLabel + '</h3>'

  # build ancestors-hierarchie
  if data.ancestors
    data.ancestors = data.ancestors.reverse()
    for key, val of data.ancestors
      if val != null
        tmpPrefLabel = that.getPrefLabelPrefGermanFromJSKOS(val.prefLabel)
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

  # Alternative Labels
  altLabels = ''
  if data.altLabel
    for key, val of data.altLabel
      for key2, val2 of val
        altLabels = ' - ' + val2 + '<br />' + altLabels
  if altLabels
    html += '<h4>Andere Bezeichnungen</h4>' + altLabels

  # Notations
  notations = ''
  if data.notation
    for key, val of data.notation
      notations = ' &#8226; ' + val + '<br />' + notations
  if notations
    html += '<h4>Notationen</h4>' + notations + '<br />'

  # Farbe (wenn notation=hexcode)
  if notations != ''
    colorPreview = ''
    for key, value of data.notation
      if /^#[0-9a-f]{6}/i.test(value)
        colorPreview += '<div class="colorPreview" style="background-color: ' + value + '"></div>'
    if colorPreview != ''
      html += '<h4>Farben</h4>' + colorPreview + '<br />'

  # Karte, zeige nur einen Ort
  location = ''
  if data.location
    #console.log data.location
    #console.log JSON.stringify(data.location[0].coordinates)
    #console.log data.location.length
    if data.location.length > 0
      # gehe die Koordinaten durch und bilde nach folgender Reihenfolge eine ab: 1. Polygon, 2. Linestring oder Point
      for key, value of data.location
        `var imageUrl`
        if value.type == 'XXPoint'
          imageUrl = 'https://api.mapbox.com/v4/mapbox.streets-satellite/'
          imageUrl = imageUrl + 'geojson(%7B%22'
          imageUrl = imageUrl + 'coordinates%22%3A' + JSON.stringify(data.location[key].coordinates)
          imageUrl = imageUrl + '%2C%22type%22%3A%22Point'
          imageUrl = imageUrl + '%22%7D)'
          imageUrl = imageUrl + '/' + data.location[key].coordinates[0] + ',' + data.location[key].coordinates[1] + ',12/367x220@2x.png?access_token=pk.eyJ1IjoibGlydW1nYnYiLCJhIjoiY2lobjRzamkyMDBnM3U5bTR4cHp0NDdyeCJ9.AjNCRBlBb57j-dziFxf58A'
          location = '<div class="mapImage" style="background-image: url(\'' + imageUrl + '\');"></div>'
        if value.type == 'Polygon'
          # mittelpunkt von polygon errechnen
          positionTL = data.location[key].coordinates[0][0]
          positionBR = data.location[key].coordinates[0][2]
          lng = positionTL[0] + (positionBR[0] - (positionTL[0])) / 2
          lat = positionTL[1] + (positionBR[1] - (positionTL[1])) / 2
          # ZOOM ERRECHNEN AN HAND VON ABSTAND LINKS RECHTS!
          # ZOOM ERRECHNEN AN HAND VON ABSTAND LINKS RECHTS!
          # ZOOM ERRECHNEN AN HAND VON ABSTAND LINKS RECHTS!
          # ZOOM ERRECHNEN AN HAND VON ABSTAND LINKS RECHTS!
          imageUrl = 'https://api.mapbox.com/v4/mapbox.streets-satellite/'
          imageUrl = imageUrl + 'geojson(%7B%22'
          imageUrl = imageUrl + 'coordinates%22%3A' + JSON.stringify(data.location[key].coordinates)
          imageUrl = imageUrl + '%2C%22type%22%3A%22Polygon'
          imageUrl = imageUrl + '%22%7D)'
          imageUrl = imageUrl + '/' + lng + ',' + lat + ',12/367x220@2x.png?access_token=pk.eyJ1IjoibGlydW1nYnYiLCJhIjoiY2lobjRzamkyMDBnM3U5bTR4cHp0NDdyeCJ9.AjNCRBlBb57j-dziFxf58A'
          location = '<div class="mapImage" style="background-image: url(\'' + imageUrl + '\');"></div>'
        # LINIE DASDASDAS DAS=D/ ()AS/D) (AS/D)( /AS)(D/ )(AS/D)/AS
        # LINIE DASDASDAS DAS=D/ ()AS/D) (AS/D)( /AS)(D/ )(AS/D)/AS
        # LINIE DASDASDAS DAS=D/ ()AS/D) (AS/D)( /AS)(D/ )(AS/D)/AS
        # LINIE DASDASDAS DAS=D/ ()AS/D) (AS/D)( /AS)(D/ )(AS/D)/AS
        # LINIE DASDASDAS DAS=D/ ()AS/D) (AS/D)( /AS)(D/ )(AS/D)/AS
        # LINIE DASDASDAS DAS=D/ ()AS/D) (AS/D)( /AS)(D/ )(AS/D)/AS
        #return
      if location == ''
      else
      if location != ''
        html += '<u>Georeferenzierung</u><br />' + location + '<br />'

  # Definitions
  definition = ''
  if data.definition
    if data.definition.de
      definition = data.definition.de
  if definition
    html += '<h4>Definition</h4>' + definition + '<br />'

  # scopeNote
  scopeNote = ''
  if data.scopeNote
    if data.scopeNote.de
      scopeNote = data.scopeNote.de
  if scopeNote
    html += '<h4>Verwendungshinweis</h4>' + scopeNote + '<br />'

  # example
  example = ''
  if data.example
    if data.example.de
      example = data.example.de
  if example
    html += '<h4>Beispiel</h4>' + example + '<br />'

  html = '<style>.danteTooltip { padding: 10px; min-width:200px; } .danteTooltip h4 { margin-bottom: 0px; } .danteTooltip .danteTooltipAncestors { font-size: 13px; font-weight: bold; margin-top: 0px;}</style><div class="danteTooltip">' + html + '</div>'
  return html

# redas the prefLabel in german language from prefLabelsArr of JSKOS.
# if german doesnt exit, english is fallback and then any other language
CustomDataTypeDANTE.prototype.getPrefLabelPrefGermanFromJSKOS = (prefLabels) ->
  prefLabel = ''
  prefLabelFallback = '&rsaquo; ohne Begriff &lsaquo;'
  prefLabel = prefLabelFallback
  if prefLabels instanceof Array or prefLabels instanceof Object
    if prefLabels.count == 0
      prefLabels = undefined
    # wenn deutsches prefLabel
    if prefLabels.hasOwnProperty('de')
      prefLabel = prefLabels.de
    # wenn kein deutsches prefLabel
    if !prefLabel or prefLabel == undefined or prefLabel == 'undefined' or prefLabel == prefLabelFallback
      # gibt es ein englisches Label
      if prefLabels.hasOwnProperty('en')
        prefLabel = prefLabels.en
      # ansonsten irgendeine Sprache
      if !prefLabel or prefLabel == undefined or prefLabel == 'undefined' or prefLabel == prefLabelFallback
        for key, val of prefLabels
          prefLabel = val
          break
  prefLabel

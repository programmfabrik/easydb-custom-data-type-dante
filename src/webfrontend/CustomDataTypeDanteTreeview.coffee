##################################################################################
#  1. Class for use of ListViewTree
#   - uses the DANTE-API as source for the treeview
#   - allows searches in DANTE-API and displays results in treeview
#
#  2. extends CUI.ListViewTreeNode
#   - offers preview and selection of DANTE-records for treeview-nodes
##################################################################################

class DANTE_ListViewTree

    #############################################################################
    # construct
    #############################################################################
    constructor: (@popover = null, @editor_layout = null, @cdata = null, @cdata_form = null, @context = null, @dante_opts = {}, @vocParameter = 'test') ->

        options =
          class: "dantePlugin_Treeview"
          cols: ["maximize", "auto"]
          fixedRows: 0
          fixedCols: 0
          no_hierarchy : false

        that = @

        treeview = new CUI.ListViewTree(options)
        treeview.render()
        treeview.root.open()

        # append loader-row
        row = new CUI.ListViewRow()
        column = new CUI.ListViewColumn(
          colspan: 2
          element: new CUI.Label(icon: "spinner", appearance: "title",text: $$("custom.data.type.dante.modal.form.popup.loadingstringtreeview"))
        )
        row.addColumn(column)
        treeview.appendRow(row)
        treeview.root.open()

        @treeview = treeview
        @treeview


    #############################################################################
    # get top hierarchy
    #############################################################################
    getTopTreeView: (vocName, cache=1) ->

        dfr = new CUI.Deferred()

        that = @
        topTree_xhr = { "xhr" : undefined }

        if cache != 1 && cache != 0
          cache = 1

        # start new request to DANTE-API
        url = location.protocol + '//api.dante.gbv.de/voc/' + vocName + '/top?format=json&properties=+notation&limit=100&cache=' + cache
        topTree_xhr.xhr = new (CUI.XHR)(url: url)
        topTree_xhr.xhr.start().done((data, status, statusText) ->
          # remove loading row (if there is one)
          if that.treeview.getRow(0)
            that.treeview.removeRow(0)

          # add lines from request
          for jskos, key in data
            prefLabel = CustomDataTypeDANTE.prototype.getPrefLabelFromJSKOS(jskos)

            # narrower?
            if jskos.narrower?.length > 0
              hasNarrowers = true
            else
              hasNarrowers = false

            newNode = new DANTE_ListViewTreeNode
                selectable: false
                prefLabel: prefLabel
                uri: jskos.uri
                hasNarrowers: hasNarrowers
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                guideTerm: DANTE_ListViewTreeNode.prototype.isGuideTerm(jskos)
                context: that.context
                vocParameter: that.vocParameter
                dante_opts: that.dante_opts
                editor_layout: that.editor_layout

            that.treeview.addNode(newNode)
          # refresh popup, because its content has changed (new height etc)
          CUI.Events.trigger
            node: that.popover
            type: "content-resize"
          dfr.resolve()
          dfr.promise()
        )

        dfr

    #############################################################################
    # get search result hierarchie
    #############################################################################
    getSearchResultTree: (searchTerm, vocName, cache = 1) ->

        dfr = new CUI.Deferred()

        that = @
        topTree_xhr = { "xhr" : undefined }

        # start new request to DANTE-API

        url = location.protocol + '//api.dante.gbv.de/search?voc=' + vocName + '&query=' + searchTerm + '&format=json&limit=100&cache=' + cache + '&properties=+ancestors,notation&offset=0'
        topTree_xhr.xhr = new (CUI.XHR)(url: url)
        topTree_xhr.xhr.start().done((data, status, statusText) ->

          # parse search result and build virtual tree from result
          virtualTree = []
          counter = 0
          maxCount = 10000

          ######################################################################
          # recursive-function: add a node to the virtual tree
          ######################################################################
          addToVirtualTree = (treePart, newNode, parentUri) ->
            if counter > maxCount
              exit;
            for nodeKey, nodeValue of treePart
              if nodeKey == parentUri
                if !nodeValue['children'][newNode.uri]
                  nodeValue['children'][newNode.uri] = newNode
                return
              else
                addToVirtualTree(nodeValue['children'], newNode, parentUri)
            return
          # \\
          ######################################################################

          # Build virtual treeview from DANTE-API-Response
          for value, key in data
            if data[key] != null
              jskos = value

              # push entry itself to ancestor-hierarchy
              itselfAsAncestor = {
                prefLabel: jskos.prefLabel
                uri : jskos.uri
                type : jskos.type
              }

              # add record itself to its ancestors
              jskos.ancestors.unshift(itselfAsAncestor)

              # if record has a hierarchy
              if jskos.ancestors.length > 0
                jskos.ancestors = jskos.ancestors.reverse()
                # parse each entry in ancestors-Hierarchy
                for ancestorValue, ancestorLevel in jskos.ancestors

                  node = {
                    prefLabel: CustomDataTypeDANTE.prototype.getPrefLabelFromJSKOS(ancestorValue)
                    uri : ancestorValue.uri
                    guideTerm : DANTE_ListViewTreeNode.prototype.isGuideTerm(ancestorValue)
                    children : {}
                  }

                  # is top hierarchy?
                  if ancestorLevel == 0
                    if !virtualTree[ancestorValue.uri]
                      virtualTree[ancestorValue.uri] = node
                  # level > 0 ?!
                  else if ancestorLevel > 0
                    # add to children-property of level
                    addToVirtualTree(virtualTree, node, jskos.ancestors[ancestorLevel-1].uri)

          # parse virtual tree and build treeview

          ######################################################################
          # recursive-function: read child-Nodes from Virtual Tree
          ######################################################################
          counter = 0
          getChildNodesFromVirtualTree = (treePart) ->
            nodes = []
            counter++
            if counter > maxCount
              exit;

            # parse each entry of given object and make a node from it
            for nodeKey, nodeValue of treePart

              # narrower?
              childrenCount = Object.keys(nodeValue.children).length
              hasNarrowers = if childrenCount > 0 then true else false

              newNode = new DANTE_ListViewTreeNode
                  selectable: false
                  open: hasNarrowers
                  children : getChildNodesFromVirtualTree(nodeValue.children)
                  prefLabel: nodeValue.prefLabel
                  uri: nodeValue.uri
                  vocParameter: that.vocParameter
                  hasNarrowers: hasNarrowers
                  guideTerm: nodeValue.guideTerm
                  popover: that.popover
                  cdata: that.cdata
                  cdata_form: that.cdata_form
                  context: that.context
                  dante_opts: that.dante_opts
                  editor_layout: that.editor_layout

              nodes.push(newNode)
            return nodes
          # \\
          ######################################################################

          # push virtual tree to CUI-treeview
          for key, value of virtualTree

            # narrower?
            childrenCount = Object.keys(value.children).length
            hasNarrowers = if childrenCount > 0 then true else false

            # children?
            children = []
            if hasNarrowers
              children = getChildNodesFromVirtualTree(value.children)

            newNode = new DANTE_ListViewTreeNode
                selectable: false
                open: hasNarrowers
                hasChildren: hasNarrowers
                children : children
                prefLabel: value.prefLabel
                uri: value.uri
                vocParameter: that.vocParameter
                hasNarrowers: hasNarrowers
                guideTerm: value.guideTerm
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                context: that.context
                dante_opts: that.dante_opts
                editor_layout: that.editor_layout

            that.treeview.addNode(newNode)
          # remove loading  row
          that.treeview.removeRow(0)

          dfr.resolve()
          dfr.promise()
        )

        dfr


##############################################################################
# custom tree-view-node
##############################################################################
class DANTE_ListViewTreeNode extends CUI.ListViewTreeNode

    prefLabel = ''
    uri = ''

    initOpts: ->
       super()

       @addOpts
          prefLabel:
             check: String
          uri:
             check: String
          vocParameter:
             check: String
          children:
             check: Array
          guideTerm:
             check: Boolean
             default: false
          hasNarrowers:
             check: Boolean
             default: false
          popover:
             check: CUI.Popover
          cdata:
             check: "PlainObject"
             default: {}
          cdata_form:
             check: CUI.Form
          context:
             check: CustomDataTypeDANTE
          dante_opts:
             check: "PlainObject"
             default: {}
          editor_layout:
             check: CUI.HorizontalLayout

    readOpts: ->
       super()

    #########################################
    # function isGuideTerm
    isGuideTerm: (jskos) =>
        if 'http://vocab.getty.edu/ontology#GuideTerm' in jskos.type
          return true
        else
          return false


    #########################################
    # function getChildren
    getChildren: =>
        that = @
        dfr = new CUI.Deferred()
        children = []

        # start new request to DANTE-API

        # default cache is on
        cache = '1'
        # but if "reset"-button was pressed, disable cache for the active popup
        if that._context.resettedPopup
          cache = '0'

        url = location.protocol + '//api.dante.gbv.de/narrower?format=json&uri=' + @_uri + '&limit=100&cache=' + cache + '&voc=' + @_vocParameter
        getChildren_xhr ={ "xhr" : undefined }
        getChildren_xhr.xhr = new (CUI.XHR)(url: url)
        getChildren_xhr.xhr.start().done((data, status, statusText) ->
          for jskos, key in data
            prefLabel = CustomDataTypeDANTE.prototype.getPrefLabelFromJSKOS(jskos)

            # narrowers?
            if jskos.narrower?.length > 0
              hasNarrowers = true
            else
              hasNarrowers = false

            newNode = new DANTE_ListViewTreeNode
                selectable: false
                prefLabel: prefLabel
                uri: jskos.uri
                vocParameter: that._vocParameter
                hasNarrowers: hasNarrowers
                popover: that._popover
                cdata: that._cdata
                cdata_form: that._cdata_form
                guideTerm: that.isGuideTerm(jskos)
                context: that._context
                dante_opts: that._dante_opts
                editor_layout: that._editor_layout
            children.push(newNode)
          dfr.resolve(children)
        )

        dfr.promise()

    #########################################
    # function isLeaf
    isLeaf: =>
        if @opts.hasNarrowers == true
            return false
        else
          return true

    #########################################
    # function renderContent
    renderContent: =>
        that = @
        extendedInfo_xhr = { "xhr" : undefined }
        d = CUI.dom.div()

        buttons = []

        # '+'-Button
        # guideterm?
        icon = 'fa-plus-circle'
        tooltipText = $$('custom.data.type.dante.modal.form.popup.add_choose')
        if that._guideTerm
          icon = 'fa-sitemap'
          tooltipText = $$('custom.data.type.dante.modal.form.popup.add_sitemap')

        plusButton =  new CUI.Button
                            text: ""
                            icon_left: new CUI.Icon(class: icon)
                            active: false
                            group: "default"
                            tooltip:
                              text: tooltipText
                            onClick: =>
                              # get the ancestors and labels for fulltext

                              # cache?
                              cache = '&cache=0'
                              if that._context.resettedPopup
                                  cache = '&cache=1'

                              allDataAPIPath = location.protocol + '//api.dante.gbv.de/data?uri=' + that._uri + cache + '&properties=+ancestors'

                              # start XHR
                              dataEntry_xhr = new (CUI.XHR)(url: allDataAPIPath)
                              dataEntry_xhr.start().done((data_response, status, statusText) ->
                                resultJSKOS = data_response[0];
                                # if treeview, add ancestors
                                that._cdata.conceptAncestors = []
                                if resultJSKOS.ancestors.length > 0
                                  # save ancestor-uris to cdata
                                  for jskos in resultJSKOS.ancestors
                                    that._cdata.conceptAncestors.push jskos.uri
                                # add own uri to ancestor-uris
                                that._cdata.conceptAncestors.push that._uri

                                # is user allowed to choose label manually from list and not in expert-search?!
                                if that._context?.FieldSchema?.custom_settings?.allow_label_choice?.value == true && that._dante_opts?.mode == 'editor'
                                  CustomDataTypeDANTE.prototype.__chooseLabelManually(that._cdata, that._editor_layout, resultJSKOS, that._editor_layout, that._dante_opts)

                                # attach info to cdata_form
                                that._cdata.conceptName = that._prefLabel
                                that._cdata.conceptURI = that._uri
                                # save _fulltext
                                that._cdata._fulltext = ez5.DANTEUtil.getFullTextFromJSKOSObject resultJSKOS
                                # save _standard
                                that._cdata._standard = ez5.DANTEUtil.getStandardFromJSKOSObject resultJSKOS

                                # is this from exact search and user has to choose exact-search-mode?!
                                if that._dante_opts?.callFromExpertSearch == true
                                  CustomDataTypeDANTE.prototype.__chooseExpertHierarchicalSearchMode(that._cdata, that._editor_layout, resultJSKOS, that._editor_layout, that._dante_opts)

                                # update form
                                CustomDataTypeDANTE.prototype.__updateResult(that._cdata, that._editor_layout, that._dante_opts)
                                # hide popover
                                that._popover.hide()
                              )


        # add '+'-Button, if not guideterm
        plusButton.setEnabled(!that._guideTerm)

        buttons.push(plusButton)

        # infoIcon-Button
        infoButton = new CUI.Button
                        text: ""
                        icon_left: new CUI.Icon(class: "fa-info-circle")
                        active: false
                        group: "default"
                        tooltip:
                          markdown: true
                          placement: "e"
                          content: (tooltip) ->
                            # show infopopup
                            CustomDataTypeDANTE.prototype.__getAdditionalTooltipInfo(that._uri, tooltip, extendedInfo_xhr, that._context)
                            new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
        buttons.push(infoButton)

        # button-bar for each row
        buttonBar = new CUI.Buttonbar
                          buttons: buttons

        CUI.dom.append(d, CUI.dom.append(CUI.dom.div(), buttonBar.DOM))

        @addColumn(new CUI.ListViewColumn(element: d, colspan: 1))

        CUI.Events.trigger
          node: that._popover
          type: "content-resize"

        new CUI.Label(text: @_prefLabel)

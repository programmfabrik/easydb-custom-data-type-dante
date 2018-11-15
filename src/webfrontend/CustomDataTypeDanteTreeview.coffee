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
    constructor: (@popover = null, @cdata = null, @cdata_form = null, @context = null) ->

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
              ,
                prefLabel: prefLabel
                uri: jskos.uri
                hasNarrowers: hasNarrowers
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                guideTerm: DANTE_ListViewTreeNode.prototype.isGuideTerm(jskos)
                context: that.context

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
                ,
                  prefLabel: nodeValue.prefLabel
                  uri: nodeValue.uri
                  hasNarrowers: hasNarrowers
                  guideTerm: nodeValue.guideTerm
                  popover: that.popover
                  cdata: that.cdata
                  cdata_form: that.cdata_form
                  context: that.context

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
                children : children
              ,
                prefLabel: value.prefLabel
                uri: value.uri
                hasNarrowers: hasNarrowers
                guideTerm: value.guideTerm
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                context: that.context

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

    constructor: (@opts={}, @additionalOpts={}) ->

        super(@opts)

        @prefLabel = @additionalOpts.prefLabel
        @uri = @additionalOpts.uri
        @guideTerm = @additionalOpts.guideTerm
        @popover = @additionalOpts.popover
        @cdata = @additionalOpts.cdata
        @cdata_form = @additionalOpts.cdata_form
        @context = @additionalOpts.context

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
        if that.context.resettedPopup
          cache = '0'

        url = location.protocol + '//api.dante.gbv.de/narrower?format=json&uri=' + @uri + '&limit=100&cache=' + cache
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
              ,
                prefLabel: prefLabel
                uri: jskos.uri
                hasNarrowers: hasNarrowers
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                guideTerm: that.isGuideTerm(jskos)
                context: that.context
            children.push(newNode)
          dfr.resolve(children)
        )

        dfr.promise()

    #########################################
    # function isLeaf
    isLeaf: =>
        if @additionalOpts.hasNarrowers == true
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
        if that.guideTerm
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
                              # attach info to cdata_form
                              that.cdata.conceptName = that.prefLabel
                              that.cdata.conceptURI = that.uri
                              # trigger change on form
                              that.cdata_form.getFieldsByName("searchbarInput")[0].storeValue(that.prefLabel + ' teee222st')     
                                
                              # hide popover
                              that.popover.hide()

        # add '+'-Button, if not guideterm
        plusButton.setEnabled(!that.guideTerm)

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
                            CustomDataTypeDANTE.prototype.__getAdditionalTooltipInfo(that.uri, tooltip, extendedInfo_xhr, that.context)
                            new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
        buttons.push(infoButton)

        # button-bar for each row
        buttonBar = new CUI.Buttonbar
                          buttons: buttons

        CUI.dom.append(d, CUI.dom.append(CUI.dom.div(), buttonBar.DOM))

        @addColumn(new CUI.ListViewColumn(element: d, colspan: 1))

        CUI.Events.trigger
          node: that.popover
          type: "content-resize"

        new CUI.Label(text: @prefLabel)
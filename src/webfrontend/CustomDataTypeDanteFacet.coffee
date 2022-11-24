class CustomDataTypeDANTEFacet extends FieldFacet

  initOpts: ->
      super()
      @addOpts
          field:
              mandatory: true
              check: Field

  requestFacetWithLimit: (obj) ->
      limit: @getLimit()
      field: @_field.fullName()+".facetTerm"
      sort: "count"
      type: "term"

  getObjects: (key=@name(), data=@data()) ->
      data[key]?.terms or []

  renderObjectText: (object) ->
      console.log object
      console.log object.term
      parts = object.term.split('@$@')
      label = '---'
      if parts.length == 2
        if parts[0] != ''
          label = parts[0]
      label

  getObjectPath: (obj) ->
      [obj.term]

  name: ->
      @_field.fullName()+".facetTerm"

  requestSearchFilter: (obj) ->
      bool: "must"
      fields: [ @_field.fullName()+".facetTerm" ]
      type: "in"
      in: [ obj.term ]

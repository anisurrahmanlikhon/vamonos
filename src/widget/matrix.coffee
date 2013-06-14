class Matrix

    constructor: ({container, @defaultInput, @varName,
                    showChanges, @cssRules, @showIndices, cellFormat}) ->

        @$container     = Vamonos.jqueryify(container)
        @defaultInput  ?= {}
        @rawToTxt       = cellFormat ? Vamonos.rawToTxt
        @showChanges    = Vamonos.arrayify(showChanges ? "next")

        @cssRules      ?= []
        @showIndices   ?= []

        @rows           = []
        @cols           = []

        @$cells         = {}
        @$rows          = {}

        @$colAnnotations = {}
        @$rowAnnotations = {}

        @$table = $("<table>", {class: "matrix"})
        @$container.append(@$table)


    event: (event, options...) -> switch event
        when "setup"
            [@stash, visualizer] = options

            # setup defaults in the stash (in case no edit mode happens)
            @theMatrix = @stash[@varName] = @shallowCopy( @defaultInput )

            # register varName as an input if needed
            @stash._inputVars.push(@varName) unless @displayOnly
            
            # ensure array indices exist in the stash
            for [_,_,i,_] in @cssRules
                @stash[v] ?= null for v in @virtualIndexDependents(i)
            for [_,i] in @showIndices
                @stash[v] ?= null for v in @virtualIndexDependents(i)
           

        when "editStart"
            @$table.hide()

        when "displayStart"
            @matrixReset()
            @$table.show()

        when "render"
            @render(options...)


    render: (frame, type) ->
        newMatrix = frame[@varName] ? {}

        @$table.find("td").removeClass()

        for r in @getRows(newMatrix)
            @matrixEnsureRow(r)

        for c in @getCols(newMatrix)
            @matrixEnsureColumn(c)

        newRows = @getRows(newMatrix)
        for r in @rows
            @matrixRemoveRow(r) unless r in newRows

        newCols = @getCols(newMatrix)
        for c in @cols
            @matrixRemoveCol(c) unless c in newCols


        # apply CSS rules
        for [type, compare, indexName, className] in @cssRules
            index = @virtualIndex(frame, indexName)
#            if Vamonos.isNumber(index) and @firstIndex <= index < newArray.length
#
#                if type is "row"
#                    $row = @getNthColumn(index)
#                    $selector = switch compare 
#                        when "<"        then $col.prevAll() 
#                        when "<="       then $col.prevAll().add($col)
#                        when "=", "=="  then $col
#                        when ">"        then $col.nextAll()
#                        when ">="       then $col.nextAll().add($col)
#                    $selector.addClass(className)

        # apply the "changed" class after applying the other css rules
        showChange = type in @showChanges

        for r in @rows
            for c in @cols
                @matrixSetFromRaw(r, c, newMatrix[r]?[c], showChange)

        rowIndices = {}
        colIndices = {}
        
        for [type, i] in @showIndices
            home = if type is "row" then rowIndices else colIndices
            target = "" + @virtualIndex(frame, i)

            if home[target]?
                home[target].push(i)
            else
                home[target] = [i]

        for r in @rows
            @$rowAnnotations[r].html( if rowIndices[r]? then rowIndices[r].join(", ") else "" )
        for c in @cols
            @$colAnnotations[c].html( if colIndices[c]? then colIndices[c].join(", ") else "" )


    virtualIndex: (frame, indexStr) ->
        return null unless indexStr.match(/^([a-zA-Z_]+|\d+)((-|\+)([a-zA-Z_]+|\d+))*$/g)
        tokens = indexStr.match(/[a-zA-Z_]+|-|\+|\d+/g)

        if tokens.length is 1
            return frame[tokens[0]]

        prevOp = "+"
        total  = 0

        for t in tokens
            if prevOp?  # expecting a varname or constant
                thisTerm = if Vamonos.isNumber(t) then parseInt(t) else parseInt(frame[t])
                return null unless thisTerm?
                switch prevOp
                    when "+" then total += thisTerm
                    when "-" then total -= thisTerm
                prevOp = null
            else prevOp = t
        return total
                    
    virtualIndexDependents: (indexStr) ->
        return [] unless indexStr.match(/^([a-zA-Z_]+|\d+)((-|\+)([a-zA-Z_]+|\d+))*$/g)
        return indexStr.match(/([a-zA-Z_]+)/g)


    getRows: (matrix) ->
        r = ("" + v for v of matrix)
        return @smartSort(r)

    getCols: (matrix) ->
        c = []
        for r of matrix
            for k of matrix[r]
                c.push("" + k) unless k in c
        return @smartSort(c)

    smartSort: (list) ->
        if list.filter( (z) -> ! Vamonos.isNumber(z) ).length
            return list.sort( (a,b) -> a.localeCompare(b) )
        else
            return list.sort( (a,b) -> parseInt(a) - parseInt(b) )



    # these are the only "approved" ways to edit the matrix

    matrixEnsureRow: (newRowName, showChanges) ->
        newRowName = "" + newRowName
        return if newRowName in @rows

        @rows.push(newRowName)
        @smartSort(@rows)

        newPos = @rows.indexOf(newRowName)

        @theMatrix[newRowName] = {}
        @$rows[newRowName] = $newRow = $("<tr>").append(
            $("<th>", {class: "matrix-row-label", text: newRowName})
        )

        @$cells[newRowName] = {}
        for c in @cols
            $newRow.append( @$cells[newRowName][c] = $("<td>") )

        $newRow.append( @$rowAnnotations[newRowName] = $("<th>", {class: "matrix-row-annotation"}) )
        @$table.find("tr:nth-child(#{ newPos+1 })").after( $newRow )

        $newRow.find("td").addClass('changed') if showChanges

    matrixEnsureColumn: (newColName, showChanges) ->
        newColName = "" + newColName
        return if newColName in @cols

        @cols.push(newColName)
        @smartSort(@cols)

        newPos = @cols.indexOf(newColName)

        @$table.find("tr > :nth-child(#{ newPos + 1 })").each( (i,e) =>
            if i is 0
                $(e).after( $("<th>", {class: "matrix-col-label", text: newColName}) )
            else if i == @rows.length + 1
                $(e).after( @$colAnnotations[newColName] = $("<th>", {class: "matrix-col-annotation"}) )
            else
                $(e).after( @$cells[ @rows[i-1] ][ newColName ] = $("<td>") )
        )

        if showChanges
            for r in @rows
                @$cells[r][newColName].addClass("changed")

    matrixRemoveRow: (rowName) ->
        rowName = "" + rowName
        return unless rowName in @rows
        pos = @rows.indexOf(rowName)
        
        @rows.splice(pos, 1)

        @$table.find("tr:nth-child(#{ pos + 2 })").remove()

        delete @$rowAnnotations[rowName]
        delete @$cells[rowName]
        delete @theMatrix[rowName]


    matrixRemoveCol: (colName) ->
        colName = "" + colName
        return unless colName in @cols
        pos = @cols.indexOf(colName)
        
        @cols.splice(pos, 1)

        @$table.find("tr > :nth-child(#{ pos + 2 })").remove()

        delete @$colAnnotations[colName]
        for r in @rows
            delete @$cells[r][colName]
            delete @theMatrix[r][colName]


    matrixSetFromRaw: (i , j, rawVal, showChanges) ->
        @theMatrix[i][j] = rawVal
        $cell = @$cells[i][j]
        return unless $cell?

        oldhtml = $cell.html()

        # we must always cast to strings, or else comparison will fail
        # between integer 1 and string "1"

        newhtml = if rawVal? then "" + @rawToTxt(rawVal) else ""

        if oldhtml isnt newhtml
            $cell.html(newhtml)
            @markChanged(i,j) if showChanges

    matrixReset: () ->
        @theMatrix       = {}
        @$cells          = {}
        @rows            = []
        @$rows           = {}
        @cols            = []
        @$rowAnnotations = {}
        @$colAnnotations = {}

        # start with 4 empty corners
        @$table.html(
            "<tr><th></th><th></th></tr><tr><th></th><th></th></tr>"
        )


    markChanged: (i,j) ->
        @$cells[i][j].addClass("changed")
        # "refresh" DOM element so that CSS transitions can restart
        dup = @$cells[i][j].clone()
        @$cells[i][j].replaceWith(dup)
        @$cells[i][j] = dup

    shallowCopy: (matrix) ->
        rows = @getRows(matrix)
        cols = @getCols(matrix)
        res = {}
        for r in rows
            res[r] = {}
            for c in cols
                res[r][c] = matrix[r][c]
        return res
        

Vamonos.export { Widget: { Matrix } }

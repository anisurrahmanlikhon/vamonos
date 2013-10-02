class CallStack

    @spec =
        container:
            type: "String"
            description: "id of the div within which this widget should draw itself"
        procedureNames:
            type: "Object"
            defaultValue: {}
            description: 
                "an object mapping procedure names (those in the Visualizer's
                 'algorithm' argument) to their fully capitalized and formatted
                 display forms."
            example:  
                    "procedureNames: {\n" +
                    "    main: \"DFS\",\n" +
                    "    visit: \"DFS-Visit\",\n" +
                    "}"
        animate:
            type: "Array"
            defaultValue: ["next"]
            description: "types of frame changes to show an animation on"
        resizable:
            type: "Boolean"
            defaultValue: true
            description: "whether the widget should have a resize triangle"

    constructor: (args) ->

        Vamonos.handleArguments
            widgetObject   : this
            givenArgs      : args

        @$container      = Vamonos.jqueryify(@container)

        @$inner = $("<div>", {class: "callstack"}).appendTo(@$container)
        @$table = $("<table>", {class: "callstack"}).appendTo(@$inner)

        @$container.hide()

        if @resizable
            @$container.resizable(
                handles: "se"
                alsoResize: @$inner
            )
            @$container.addClass("ui-resizable-roomforscrollbar")

        @$argRows  = []
        @$procRows = []

    event: (event, options...) -> switch event
        when "setup"
            [@viz] = options

        when "render"
            [frame, type] = options
            @render(frame, type)
        when "displayStop"
            @$argRows  = []
            @$procRows = []
            @$table.empty()
            @$container.hide()
        when "displayStart"
            @$container.show()


    render: (frame, type) ->
        @$inner.stop()

        stack = frame._callStack[..]
        stack.reverse()
        stack = (f for f in stack when f.procName isnt "input")

        if frame._returnStack?
            stack.push(r) for r in frame._returnStack

        while stack.length > @$argRows.length
            @$argRows.push( $("<tr>").appendTo(@$table) )
            @$procRows.push( $("<tr>").appendTo(@$table) )

        for i,scope of stack
            @setArgRow( @$argRows[i], scope )
            @setProcRow( @$procRows[i], scope )

        tgt = @$procRows[ stack.length - 1 ]
        newScrollTop = @$inner.scrollTop() - @$inner.offset().top \
                     - @$inner.height() + tgt.height() \
                     + tgt.offset().top + 1
                    
        if type in @animate and newScrollTop > 0
            @$inner.animate { scrollTop: newScrollTop }, 500, =>
                while stack.length < @$argRows.length
                    @$argRows.pop().remove()
                    @$procRows.pop().remove()
        else 
            while stack.length < @$argRows.length
                @$argRows.pop().remove()
                @$procRows.pop().remove()

            @$inner.scrollTop( @$inner.prop("scrollHeight") )


    setArgRow: ($tr, scope) ->
        $tr.html("<td class='callstack-args'>" +
          "#{@argStr(scope)}</td><td class='callstack-return'>"  +
          "#{@retStr(scope)}</td>")

    setProcRow: ($tr, scope) ->
        procName = @procedureNames[scope.procName] ? scope.procName
        $tr.html("<td><td><div class='callstack-proc-container'><div class='callstack-proc'>#{procName}</div></div></td>")
        $tr.find("div.callstack-proc").addClass("callstack-returned") if "returnValue" of scope
        $tr.find("div.callstack-proc").addClass("callstack-active")   if scope.activeStackFrame

    argStr: (scope) ->
        ("#{k}=#{Vamonos.rawToTxt(v)}" for k,v of scope.args when not /^_/.test(k)).join(",") + "<span class='callstack-arrow'>&darr;</span>"

    retStr: (scope) ->
        return "&nbsp;" unless "returnValue" of scope
        ret = Vamonos.arrayify(scope.returnValue)
        "<span class='callstack-arrow'>&uarr;</span>" + (Vamonos.rawToTxt(r) for r in ret).join(",")


@Vamonos.export { Widget: { CallStack } }

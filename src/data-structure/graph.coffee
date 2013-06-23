class Graph
    constructor: ({vertices, edges, @directed}) ->
        
        @vertices  = []
        @type      = 'graph'
        @directed ?= yes
        @adjHash   = {}
        @edges     = []

        for v in Vamonos.arrayify(vertices)
            @addVertex(v)

        for e in Vamonos.arrayify(edges)
            @addEdge(e.source, e.target)

    # ---------- edge functions ----------- #

    edge: (source, target) ->
        sourceId = @_idify(source) 
        targetId = @_idify(target) 
        @edges.filter((e) ->
            e.source.id is sourceId and e.target.id is targetId
        )[0]

    addEdge: (sourceId, targetId) ->
        return if @edge(sourceId, targetId)
        s = @vertex(sourceId) 
        t = @vertex(targetId)
        return unless s? and t?
        edge = { source: s, target: t, type: 'edge' }
        @adjHash[sourceId] ?= {}
        @adjHash[sourceId][targetId] = edge
        @edges.push(edge)
        @addEdge(targetId, sourceId) unless @directed

    removeEdge: (sourceId, targetId) ->
        edge = @edge(sourceId, targetId)
        return unless edge?
        index = @edges.indexOf(edge)
        @edges.splice(@edges.indexOf(edge), 1)
        @adjHash[sourceId][targetId] = undefined
        @removeEdge(targetId, sourceId) unless @directed 

    # ----------- vertex functions ---------- #

    vertex: (id_str) ->
        return id_str unless typeof id_str is 'string'
        @vertices.filter(({id}) -> id is id_str)[0]

    addVertex: (vtx) ->
        vtx.type  = 'vertex'
        vtx.name ?= @nextVertexName()
        @vertices.push(vtx)

    removeVertex: (vid) ->
        vtx = @vertex(vid)
        return unless vtx?
        @returnVertexName(vtx.name)
        affectedEdges = @edges.filter (e) ->
            e.source.id is vid or e.target.id is vid
        @removeEdge(e.source.id, e.target.id) for e in affectedEdges
        @vertices.splice(@vertices.indexOf(vtx), 1)

    eachVertex: (f) ->
        f(v) for v in @vertices when v?

    returnVertexName: (n) ->
        @availableNames.unshift(n)

    nextVertexName: () ->
        @availableNames ?= "abcdefghijklmnopqrstuvwxyz".split("")
        return @availableNames.shift()

    # ----------- edge and vertex functions ---------- #

    neighbors: (v) ->
        v = @_idify(v)
        @vertex(target) for target, edge of @adjHash[v]

    eachNeighbor: (v, f) ->
        f(neighbor) for neighbor in @neighbors(v) when neighbor?

    outgoingEdges: (v) ->
        v = @_idify(v)
        @edges.filter(({source}) -> source.id is v)

    incomingEdges: (v) ->
        v = @_idify(v)
        @edges.filter(({target}) -> target.id is v)

    # ------------ utility ----------- #

    _idify: (v) ->
        return v if typeof v is 'string' or not v?
        v.id

    clone: () ->
        r = new Vamonos.DataStructure.Graph
            vertices: Vamonos.clone(@vertices)
            directed: @directed
            edges: []
        Vamonos.mixin(r, this, Vamonos.clone)


Vamonos.export { DataStructure: { Graph } }

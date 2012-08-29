$ = jQuery

graphSettings = 
    vertex_min_radius: 5
    vertex_max_radius: 20
    height: 500

graph_metadata = ($el, data) ->
    if data?
        $el.data "graphMetadata", data
    else
        $el.data "graphMetadata"

graph_data = ($el, data) ->
    if data?
        $el.data "graphData", data
    else
        $el.data "graphData"

graphDemo = 
    init: (options) ->
        # Merge the options into the default settings. These are global, used
        # for each element in the following `each`. Element/graph-specific data
        # is stored in the element's `data`.
        $.extend graphSettings, options
        
        # Processing for each element.
        return @each () ->
            $chart = $(this)
            metadata = graph_metadata $chart

            if !metadata?
                console.log "Initializing on element", @

                # Now we calculate the element-specific settings, like the
                # width. The width is set to the width of the parent of the
                # element that will house the SVG, less two to allow for the
                # border. We set it this way to allow for responsive layouts.
                graph_metadata $chart,
                    graph_width: $chart.parent().width() - 2
                    graph_height: graphSettings.height

                # If the graph contains an .initiate anchor, change its click
                # behavior time initiate the run method.
                $("a.initiate", $chart).click () -> $chart.graphDemo "run"

    run: () ->
        # Processing for each element.
        return @each () ->
            # TODO: Add error checking to ensure the element was initialized.
            $chart = $(this)
            metadata = graph_metadata $chart
            if metadata.running
                $.error "The graph demo is already running!"
                return
            else
                graph_metadata $chart, running: true

            console.log "Running the plugin on element", @

            # Remove any initite links inside the graph.
            $("a.initiate", $chart).remove()

            # Add the active class to apply special styling.
            $chart.addClass "active"

            # Create the SVG element that is the visualization.
            vis = d3.select(this).append("svg:svg")
                .attr("width", metadata.graph_width)
                .attr("height", metadata.graph_height)
                
            # TODO add loading indicator

            console.log "Fetching data for element ", @
            d3.json "demo_graph_data.json", (json) ->
                edgeIndex = []
                max_weight = 1

                # Create an index of edges so we can know which nodes are directly connected
                # to which other nodes. [source,target] = [target,source] 1
                for e in json.edges
                    edgeIndex["#{e.source},#{e.target}"] = 1
                    edgeIndex["#{e.target},#{e.source}"] = 1

                # Create the force-directed graph.
                graph = d3.layout.force()
                    .charge(-500)
                    .linkDistance(graphSettings.vertex_max_radius * 5)
                    .gravity(.1)
                    .size([metadata.graph_width,metadata.graph_height])
                    .nodes(json.vertices)
                    .links(json.edges)

                graph.on "tick", (v) ->
                    json.vertices[0].x = metadata.graph_width / 2
                    json.vertices[0].y = metadata.graph_height / 2

                    vertices.attr "transform", (v) -> 
                        r = parseInt(d3.select(this.parentNode).select("circle").attr("r"))
                        x = Math.max(r, Math.min(metadata.graph_width - r, v.x))
                        y = Math.max(r, Math.min(metadata.graph_height - r, v.y))
                        v.x = x
                        v.y = y
                        "translate(" + x + "," + y + ")"

                    edges.attr "x1", (e) -> e.source.x
                    edges.attr "x2", (e) -> e.target.x
                    edges.attr "y1", (e) -> e.source.y
                    edges.attr "y2", (e) -> e.target.y

                graph.start()

                for v in json.vertices
                    max_weight = v.weight if v.weight > max_weight

                # Draw all of the edges from the data
                edges = vis.selectAll("line.link")
                    .data(json.edges)
                    .enter().append("svg:line")
                    .attr("class", "edge")
                    .attr("x1", (e) -> e.source.x)
                    .attr("x2", (e) -> e.target.x)
                    .attr("y1", (e) -> e.source.y)
                    .attr("y2", (e) -> e.target.y)
                    .attr("title", (e) -> e.label)

                # Create container nodes for the vertices.
                vertices = vis.selectAll("g.node")
                    .data(json.vertices)
                    .enter().append("svg:g")
                    .attr("class", "vertex")
                    .call(graph.drag)

                # Add a circle to the vertices to act as the node.
                circles = vertices.append("svg:circle")
                    .attr("class", "vcircle")
                    .attr("r", (v) -> 
                        v.weight / max_weight * (graphSettings.vertex_max_radius - graphSettings.vertex_min_radius) + graphSettings.vertex_min_radius
                    )
                    .attr("title", (v) -> v.label)
                    
                # Add a text label to the vertices.
                vertices.append("svg:text")
                    .attr("class", "vlabel")
                    .attr("dx", (v, i) ->
                        n = parseFloat(d3.select(this.parentNode).select("circle").attr("r"))
                        n + 5.0
                    )
                    .attr("dy", 5)
                    .text (v) -> return v.label

                
                # On mouseover of a node's circle, dim all others. Remove on mouseout.
                circles.on "mouseover", (d, i) ->
                    vis.classed "hover", true
                    vertices.classed "active", (v) ->
                        edgeIndex[d.index + "," + v.index] || edgeIndex[v.index + "," + d.index] || d.index == v.index
                    edges.classed "active", (e) ->
                        e.source == d || e.target == d
                circles.on "mouseout", () ->
                    vis.classed "hover", false
                    edges.classed "active", false

                # Now that we're done, store all information back into the data.
                #graph_data $chart, 
                #    edgeIndex       : edgeIndex
                #    raw_vertices    : json.vertices
                #    raw_edges       : json.edges
                #    vertices        : vertices
                #    edges           : edges
                #    max_weight      : max_weight
 


$.fn.graphDemo = (method) ->
    # global processing, applies to all elements

    if method of graphDemo
        graphDemo[method].apply this, Array.prototype.slice.call( arguments, 1 )
    else if  !method? || typeof method is 'object'
        graphDemo.init.apply this, arguments
    else
        $.error "Method #{method} is undefined on jQuery.graphDemo."


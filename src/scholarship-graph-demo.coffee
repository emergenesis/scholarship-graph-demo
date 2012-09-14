$ = jQuery

defaultGraphSettings = 
    vertex_min_radius: 5
    vertex_max_radius: 20
    height: 500
    initial_data: "demo_initial_data.json"

get_or_edit_data = ($el, data, key) ->
    if (k for own k of data).length is 0    
        $el.data key
    else
        data = $.extend {}, $el.data(key), data
        $el.data key, data

graph_metadata = ($el, data) ->
    get_or_edit_data $el, data, "graphMetadata"

graph_data = ($el, data) ->
    get_or_edit_data $el, data, "graphData"

load_data = ($chart) ->
    return (newdata) ->
        metadata        = graph_metadata $chart
        data            = graph_data $chart
        edgeIndex       = []
        max_weight      = 1
        vis             = data.vis_element
        graphSettings   = metadata.graph_settings
        initial         = false
        graph           = metadata.graph
        
        # If we already have data, combine the two. Otherwise, we just use what
        # was passed, but also initialize the graph.
        if graph?
            json = 
                edges: data.raw_edges.concat newdata.edges
                vertices: data.raw_vertices.concat newdata.vertices
        else
            json = newdata

            # This is our first data load, so set up the force-directed graph.
            # Create the force-directed graph.
            graph = d3.layout.force()
                .charge(-500)
                .linkDistance(graphSettings.vertex_max_radius * 5)
                .gravity(.1)
                .size([metadata.graph_width,metadata.graph_height])

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
        

        # Add our data and start the graph.
        graph
            .nodes(json.vertices)
            .links(json.edges)
            .start()
        
        # Create an index of edges so we can know which nodes are directly connected
        # to which other nodes. [source,target] = [target,source] 1
        for e in json.edges
            edgeIndex["#{e.source.index},#{e.target.index}"] = 1
            edgeIndex["#{e.target.index},#{e.source.index}"] = 1

        # Calculate the maximum weight of the vertices for use in calculating
        # their relative radii later.
        for v in json.vertices
            max_weight = v.weight if v.weight > max_weight

        # Draw all of the edges from the new data.
        new_edges = vis.selectAll("line.link")
            .data(newdata.edges)
            .enter().append("svg:line")
            .attr("class", "edge")
            .attr("x1", (e) -> e.source.x)
            .attr("x2", (e) -> e.target.x)
            .attr("y1", (e) -> e.source.y)
            .attr("y2", (e) -> e.target.y)
            .attr("title", (e) -> e.label)

        # Create container nodes for all new vertices.
        new_vertices = vis.selectAll("g.node")
            .data(newdata.vertices)
            .enter().append("svg:g")
            .attr("class", "vertex")
            .call(graph.drag)


        # Add circles to act as the node for all new vertices.
        new_vertices.append("svg:circle")
            .attr("class", "vcircle")

        # Add a text labe for all new vertices.
        new_vertices.append("svg:text")
            .attr("class", "vlabel")

        # Select all vertices and edges for later use.
        vertices = vis.selectAll("g.vertex")
        edges = vis.selectAll("line.edge")
        circles = vis.selectAll("circle.vcircle")
        labels = vis.selectAll("text.vlabel")

        # Position and size new and old vertices' circles.
        circles
            .attr("r", (v) -> 
                v.weight / max_weight * (graphSettings.vertex_max_radius - graphSettings.vertex_min_radius) + graphSettings.vertex_min_radius
            )
            .attr("title", (v) -> v.label)
            
        # Position new and old labels elements appropriately.
        labels
            .attr("dx", (v, i) ->
                n = parseFloat(d3.select(this.parentNode).select("circle").attr("r"))
                n + 5.0
            )
            .attr("dy", 5)
            .text (v) -> return v.label

        # Unfortunately, any new edges will be drawn atop existing circles and
        # labels, so now we cycle through the vertices and put them at the end
        # of the SVG element. Since the vertices are now drawn after the lines,
        # we have essentially moved the vertices to the top of the drawing.
        for v in vertices[0]
            v.parentNode.appendChild(v)
        
        # Now that we're done, store all information back into the data.
        graph_data $chart, 
            edge_index      : edgeIndex
            raw_vertices    : json.vertices
            raw_edges       : json.edges
            vertices        : vertices
            edges           : edges
            max_weight      : max_weight
        graph_metadata $chart,
            settings        : graphSettings
            graph           : graph

        # On mouseover of a node's circle, dim all others. Remove on mouseout.
        circles.on "mouseover", (d, i) ->
            data = graph_data $(@).parents(".graph")
            vis.classed "hover", true
            vertices.classed "active", (v) ->
                edgeIndex[d.index + "," + v.index] || edgeIndex[v.index + "," + d.index] || d.index == v.index
            edges.classed "active", (e) ->
                e.source == d || e.target == d
        circles.on "mouseout", () ->
            vis.classed "hover", false
            edges.classed "active", false

graphDemo = 
    init: (options) ->
        # Merge the options into the default settings. These are global, used
        # for each element in the following `each`. Element/graph-specific data
        # is stored in the element's `data`.
        graphSettings = $.extend {}, defaultGraphSettings, options
        
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
                    graph_width     : $chart.parent().width() - 2
                    graph_height    : graphSettings.height
                    graph_settings  : graphSettings

                # If the graph contains an .initiate anchor, change its click
                # behavior time initiate the run method.
                $("a.initiate", $chart).click () -> $chart.graphDemo "start"

    start: () ->
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

            graph_data $chart,
                vis_element: vis
                
            # TODO add loading indicator
            
            # Load the initial data set
            $chart.graphDemo "add", metadata.graph_settings.initial_data


    toggleState: (state) ->
        # Processing for each element.
        return @each () ->
            $chart = $(this)
            $chart.toggleClass(state)

    stop: () ->
        return @each () ->
            $chart = $(this)
            graph_metadata $chart,
                running: false
            $chart.empty()
            $chart.removeClass "active linked highlighted"

    add: (uri) ->
        return @each () ->
            # TODO ensure uri exists
            $chart = $(this)
            metadata = graph_data $chart
            console.log "Adding data from #{uri}"
            d3.json uri, load_data($chart)


$.fn.graphDemo = (method) ->
    # global processing, applies to all elements

    if method of graphDemo
        graphDemo[method].apply this, Array.prototype.slice.call( arguments, 1 )
    else if  !method? || typeof method is 'object'
        graphDemo.init.apply this, arguments
    else
        $.error "Method #{method} is undefined on jQuery.graphDemo."


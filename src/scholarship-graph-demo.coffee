$ = jQuery

graphSettings = 
    vertex_min_radius: 5
    vertex_max_radius: 20
    height: 500

graphDemo = 
    init: (options) ->
        # Merge the options into the default settings. These are global, used
        # for each element in the following `each`. Element/graph-specific data
        # is stored in the element's `data`.
        $.extend graphSettings, options
        
        # Processing for each element.
        return @each () ->
            $chart = $(this)
            data = $chart.data "graphDemo"

            if !data?
                console.log "Initializing on element", @

                # Now we calculate the element-specific settings, like the
                # width. The width is set to the width of the parent of the
                # element that will house the SVG, less two to allow for the
                # border. We set it this way to allow for responsive layouts.
                $chart.data
                    "graphDemo":
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
            data = $chart.data "graphDemo"
            console.log "Running the plugin on element", @

            # Remove any initite links inside the graph.
            $("a.initiate", $chart).remove()

            # Add the active class to apply special styling.
            $chart.addClass "active"

            # Create the SVG element that is the visualization.
            d3.select(this).append("svg:svg")
                .attr("width", data.graph_width)
                .attr("height", data.graph_height)

$.fn.graphDemo = (method) ->
    # global processing, applies to all elements

    if method of graphDemo
        graphDemo[method].apply this, Array.prototype.slice.call( arguments, 1 )
    else if  !method? || typeof method is 'object'
        graphDemo.init.apply this, arguments
    else
        $.error "Method #{method} is undefined on jQuery.graphDemo."


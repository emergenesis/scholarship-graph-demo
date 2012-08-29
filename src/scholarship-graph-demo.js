// Generated by CoffeeScript 1.3.3
var $, graphDemo, graphSettings;

$ = jQuery;

graphSettings = {
  vertex_min_radius: 5,
  vertex_max_radius: 20,
  height: 500
};

graphDemo = {
  init: function(options) {
    $.extend(graphSettings, options);
    return this.each(function() {
      var $chart, data;
      $chart = $(this);
      data = $chart.data("graphDemo");
      if (!(data != null)) {
        console.log("Initializing on element", this);
        $chart.data({
          "graphDemo": {
            graph_width: $chart.parent().width() - 2,
            graph_height: graphSettings.height
          }
        });
        return $("a.initiate", $chart).click(function() {
          return $chart.graphDemo("run");
        });
      }
    });
  },
  run: function() {
    return this.each(function() {
      var $chart, data;
      $chart = $(this);
      data = $chart.data("graphDemo");
      console.log("Running the plugin on element", this);
      $("a.initiate", $chart).remove();
      $chart.addClass("active");
      return d3.select(this).append("svg:svg").attr("width", data.graph_width).attr("height", data.graph_height);
    });
  }
};

$.fn.graphDemo = function(method) {
  if (method in graphDemo) {
    return graphDemo[method].apply(this, Array.prototype.slice.call(arguments, 1));
  } else if (!(method != null) || typeof method === 'object') {
    return graphDemo.init.apply(this, arguments);
  } else {
    return $.error("Method " + method + " is undefined on jQuery.graphDemo.");
  }
};

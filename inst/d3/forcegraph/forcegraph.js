// !preview r2d3 data = jsonlite::read_json("inst/d3/forcegraph/merged.json"), d3_version = 4, dependencies = "inst/d3/tooltip/tooltip.js"
// Based on: https://bl.ocks.org/mbostock/4063570

var radius = 5;

var simulation = d3.forceSimulation()
.force("link", d3.forceLink().id(function(d) { return d.id; }))
.force("charge", d3.forceManyBody())
.force("center", d3.forceCenter(width / 2, height / 2));

r2d3.onRender(function(graph, svg, width, height, options) {

  // setup fill color
  var cValue = function(d) { return -d["log10 p-value"];};
  var extents = [
    d3.extent(graph.nodes.filter((d) => d.analysis === 0).map(cValue)),
    d3.extent(graph.nodes.filter((d) => d.analysis === 1).map(cValue)),
    d3.extent(graph.nodes.filter((d) => d.analysis === 2).map(cValue))
    ];

  var palettes = [
    d3.scaleLinear().domain(extents[0]).range(["#FFEEDD", "#FF9933"]),
    d3.scaleLinear().domain(extents[1]).range(["#E7FFDB", "#55FF00"]),
    d3.scaleLinear().domain(extents[2]).range(["#E7C6FF", "#9500FF"]),
    ];

  var myColor = function(d) {
    let anal = d.analysis ? d.analysis : 0;
    return palettes[anal](cValue(d));
  };


  var link = svg.append("g")
  .attr("class", "links")
  .selectAll("line")
  .data(graph.links)
  .enter().append("line")
  .attr("stroke-width", function(d) { return Math.sqrt(d.value); });

  var node = svg.append("g")
  .attr("class", "nodes")
  .selectAll("circle")
  .data(graph.nodes)
  .enter().append("circle")
  .attr("r", radius)
  .attr("fill", myColor)
  .call(d3.drag()
        .on("start", dragstarted)
        .on("drag", dragged)
        .on("end", dragended))
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave);

  simulation
  .nodes(graph.nodes)
  .on("tick", ticked);

  simulation.force("link")
  .links(graph.links)
  .strength(function(d) {return d.value*d.value;});

  function ticked() {
    //constrains the nodes to be within a box
    node
    .attr("cx", function(d) { return d.x = Math.max(radius, Math.min(width - radius, d.x)); })
    .attr("cy", function(d) { return d.y = Math.max(radius, Math.min(height - radius, d.y)); });

    link
    .attr("x1", function(d) { return d.source.x; })
    .attr("y1", function(d) { return d.source.y; })
    .attr("x2", function(d) { return d.target.x; })
    .attr("y2", function(d) { return d.target.y; });

    node
    .attr("cx", function(d) { return d.x; })
    .attr("cy", function(d) { return d.y; });
  }
});

function dragstarted(d) {
  if (!d3.event.active) simulation.alphaTarget(0.3).restart();
  d.fx = d.x;
  d.fy = d.y;
}

function dragged(d) {
  d.fx = d3.event.x;
  d.fy = d3.event.y;
}

function dragended(d) {
  if (!d3.event.active) simulation.alphaTarget(0);
  d.fx = null;
  d.fy = null;
}

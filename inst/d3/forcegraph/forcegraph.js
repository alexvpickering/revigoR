// !preview r2d3 data = jsonlite::read_json("inst/d3/forcegraph/miserables.json"), d3_version = 4, container = "div"

// Based on: https://bl.ocks.org/mbostock/4063570

var color = d3.scaleOrdinal(d3.schemeCategory20);
var radius = 5;

var simulation = d3.forceSimulation()
.force("link", d3.forceLink().id(function(d) { return d.id; }))
.force("charge", d3.forceManyBody())
.force("center", d3.forceCenter(width / 2, height / 2));

r2d3.onRender(function(graph, svg, width, height, options) {


  // create the tooltip
  var tooltip = d3.select("body")
    .append("div")
      .style("position", "absolute")
      .style("opacity", 0)
      .attr("class", "tooltip")
      .style("background", "white")
      .style("border-radius", "0px")
      .style("border", "1px solid #ddd")
      .style("box-shadow", "2px 2px 5px 0px rgba(0,0,0,0.1)");

  var tooltipTitle = tooltip
    .append("div")
    .style("padding", "5px");

  // Labels of row and columns
  var myGroups = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

  // Build X scales and axis:
  var x = d3.scaleBand()
    .range([ 0, 200 ])
    .domain(myGroups)
    .padding(0.01);

  svgHeat = tooltip.append("svg");

  svgHeat.append("g")
    .call(d3.axisBottom(x))

  // Build color scale
  var myColor = d3.scaleLinear()
    .range(["white", "#69b3a2"])
    .domain([1,200])

  //Read the data
  data = [{"group": "A", "value": 30},
          {"group": "B", "value": 40},
          {"group": "J", "value": 99}]


  svgHeat.selectAll()
      .data(data, function(d) {return d.group;})
      .enter()
      .append("rect")
      .attr("x", function(d) { return x(d.group) })
      .attr("y", function(d) { return x.bandwidth() })
      .attr("width", x.bandwidth() )
      .attr("height", x.bandwidth() )
      .style("fill", function(d) { return myColor(d.value)} )






  // Three function that change the tooltip when user hover / move / leave a cell
  var mouseover = function(d) {
    tooltip
      .style("display", "block")
      .style("opacity", 1)
    d3.select(this)
      .style("stroke", "black")
      .style("opacity", 1)
  };

  var mousemove = function(d) {

    tooltipTitle.html(d.label);


    tooltip
      .style("left", (d3.mouse(this)[0]+40) + "px")
      .style("top", (d3.mouse(this)[1]) + "px");
  };

  var mouseleave = function(d) {
    tooltip
      .style("display", "none")
      .style("opacity", 0)
    d3.select(this)
      .style("stroke", "none")
      .style("opacity", 0.8)
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
  .attr("fill", function(d) { return d.fill; })
  .call(d3.drag()
        .on("start", dragstarted)
        .on("drag", dragged)
        .on("end", dragended));

  node
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
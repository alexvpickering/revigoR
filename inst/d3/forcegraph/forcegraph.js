// !preview r2d3 data = jsonlite::read_json("inst/d3/forcegraph/go_res.json"), d3_version = 4
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


  // containers for heatmap and its x-axis
  var margin = {top: 10, right: 30, bottom: 10, left: 70},
  heatWidth = 300 - margin.left - margin.right;

  svgHeat = tooltip
  .append("svg")
    .attr("width", heatWidth + margin.left + margin.right);

  svgHeatG = svgHeat
  .append("g")
      .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

  yAxis = svgHeatG
    .append("g")

  // Build Y scales and axis:
  var y = d3.scaleBand()
    .padding(0.01);

  // Build color scale
  var palette = d3.scaleLinear().range(["green", "white", "red"]);

  // Three function that change the tooltip when user hover / move / leave a cell
  var mouseover = function(d) {
    // show the tooltip
    tooltip
      .style("display", "block")
      .style("opacity", 1)
    d3.select(this)
      .style("stroke", "black")
      .style("opacity", 1)

    // add GO name to tooltip
    tooltipTitle.html(d.label);

    // format the heatmap data
    var gene_data = d.merged_genes.map((item, i) => {
      return {'group': item, 'value': d.logFC[i]};
      });

    // extent of logfc values
    var extent = d3.extent(gene_data, d => d.value);
    palette.domain([extent[0], 0, extent[1]]);

    // update the y axis domain and redraw
    var groups = gene_data.map(item => item.group);

    // height of tooltip svg
    var maxHeatHeight = window.innerHeight - tooltipTitle.node().getBoundingClientRect().height;
    var heatHeight = (groups.length*18) + margin.top + margin.bottom;
    heatHeight = Math.min(maxHeatHeight, heatHeight);
    svgHeat.attr("height", heatHeight)

    y.domain(groups).range([ heatHeight-margin.top-margin.bottom, 0 ])

    yAxis.call(d3.axisLeft(y).tickSizeOuter(0))

    svgHeatG.selectAll("rect").remove()

    svgHeatG.selectAll()
        .data(gene_data, function(d) {return d.group;})
        .enter()
        .append("rect")
        .attr("x", function(d) { return 1 })
        .attr("y", function(d) { return y(d.group) })
        .attr("width", y.bandwidth() )
        .attr("height", y.bandwidth() )
        .style("fill", function(d) { return palette(d.value)} )

    };


  var mousemove = function(d) {

    // if position from top and half height are more than window height, move up
    let visibleHeight = window.innerHeight;
    let mousetop = d3.mouse(this)[1];
    let halftipHeight = tooltip.node().getBoundingClientRect().height/2;


    let topto = mousetop - halftipHeight;
    let bottomto = topto + (halftipHeight*2);
    let overflowBottom = bottomto - visibleHeight;

    if (topto < 0) {
      topto = 0;

    } else if (overflowBottom > 0) {
      topto = topto - overflowBottom;
    }

    tooltip
      .style("left", (d3.mouse(this)[0]+70) + "px")
      .style("top", topto + "px");
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

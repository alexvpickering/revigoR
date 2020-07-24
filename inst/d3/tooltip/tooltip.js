// create the tooltip
var tooltip = d3.select("body")
  .append("div")
    .style("position", "absolute")
    .style("pointer-events", "none")
    .style("opacity", 0)
    .style("width", "200px")
    .attr("class", "tooltip")
    .style("background", "white")
    .style("border-radius", "0px")
    .style("border", "1px solid #ddd")
    .style("box-shadow", "2px 2px 5px 0px rgba(0,0,0,0.1)");

var tooltipTitle = tooltip
  .append("div")
  .style("padding", "5px");


// containers for heatmap and its x-axis
var margin = {top: 10, right: 10, bottom: 10, left: 70},
heatWidth = 100 - margin.left - margin.right;

svgHeatUp = tooltip
.append("svg")
  .attr("width", heatWidth + margin.left + margin.right)
   .style("vertical-align", "top");

svgHeatDown = tooltip
.append("svg")
  .attr("width", heatWidth + margin.left + margin.right)
  .style("vertical-align", "top");

svgHeatUpG = svgHeatUp
.append("g")
    .attr("transform",
          "translate(" + margin.left + "," + margin.top + ")");

 svgHeatDownG = svgHeatDown
.append("g")
    .attr("transform",
          "translate(" + margin.left + "," + margin.top + ")");

yAxisUp = svgHeatUpG
  .append("g");

yAxisDown = svgHeatDownG
  .append("g");

// Build Y scales and axis:
var yUp = d3.scaleBand().padding(0.01);
var yDown = d3.scaleBand().padding(0.01);

// Build color scale
var palette = d3.scaleLinear().range(["blue", "white", "red"]);


// Three function that change the tooltip when user hover / move / leave a cell
var mouseover = function(d) {
  // show the tooltip
  tooltip
    .style("display", "block")
    .style("opacity", 0.8)
  d3.select(this)
    .style("stroke", "black")
    .style("opacity", 1)

  // add GO name to tooltip
  tooltipTitle.html(d.description);

  // format the heatmap data
  var geneData = d.merged_genes.map((item, i) => {
    return {'group': item, 'value': d.logFC[i]};
    });

  // 70 up or down genes is most that is practical to fit
  var geneDataUp = geneData
    .filter(item => item.value > 0)
    .filter((item, idx) => idx < 70)
    .sort((a,b) => a.value - b.value);

  var geneDataDown = geneData
    .filter(item => item.value <= 0)
    .filter((item, idx) => idx < 70)
    .sort((a,b) => b.value - a.value);

  // extent of logfc values
  var extent = d3.extent(geneData, d => d.value);
  palette.domain([extent[0], 0, extent[1]]);

  // update the y axis domain and redraw
  var groupsUp = geneDataUp.map(item => item.group);
  var groupsDown = geneDataDown.map(item => item.group);

  // height of tooltip svg
  var maxHeatHeight = window.innerHeight - tooltipTitle.node().getBoundingClientRect().height;
  var heatHeightUp = (groupsUp.length*18) + margin.top + margin.bottom;
  var heatHeightDown = (groupsDown.length*18) + margin.top + margin.bottom;
  heatHeightUp = Math.min(maxHeatHeight, heatHeightUp);
  heatHeightDown = Math.min(maxHeatHeight, heatHeightDown);
  svgHeatUp.attr("height", heatHeightUp)
  svgHeatDown.attr("height", heatHeightDown)

  yUp.domain(groupsUp).range([ heatHeightUp-margin.top-margin.bottom, 0 ])
  yDown.domain(groupsDown).range([ heatHeightDown-margin.top-margin.bottom, 0 ])

  yAxisUp.call(d3.axisLeft(yUp).tickSizeOuter(0))
  yAxisDown.call(d3.axisLeft(yDown).tickSizeOuter(0))

  svgHeatUpG.selectAll("rect").remove()
  svgHeatDownG.selectAll("rect").remove()

  svgHeatUpG.selectAll()
      .data(geneDataUp, function(d) {return d.group;})
      .enter()
      .append("rect")
      .attr("x", function(d) { return 1 })
      .attr("y", function(d) { return yUp(d.group) })
      .attr("width", yUp.bandwidth() )
      .attr("height", yUp.bandwidth() )
      .style("fill", function(d) { return palette(d.value)} )

  svgHeatDownG.selectAll()
      .data(geneDataDown, function(d) {return d.group;})
      .enter()
      .append("rect")
      .attr("x", function(d) { return 1 })
      .attr("y", function(d) { return yDown(d.group) })
      .attr("width", yDown.bandwidth() )
      .attr("height", yDown.bandwidth() )
      .style("fill", function(d) { return palette(d.value)} )

  };

var mousemove = function(d) {

  // if position from top and half height are more than window height, move up
  let visibleHeight = window.innerHeight;
  let visibleWidth = window.innerHeight;
  let mousetop = d3.event.pageY;
  let mouseright = d3.event.pageX;
  let tooltipBB = tooltip.node().getBoundingClientRect();
  let halftipHeight = tooltipBB.height/2;
  let tooltipWidth = tooltipBB.width;


  let topto = mousetop - halftipHeight;
  let bottomto = topto + (halftipHeight*2);
  let overflowBottom = bottomto - visibleHeight;

  if (topto < 0) {
    topto = 0;

  } else if (overflowBottom > 0) {
    topto = topto - overflowBottom;
  }

  let leftto = mouseright + 20;
  let rightto = mouseright + tooltipWidth;
  let overflowRight = rightto - visibleWidth;

  if (overflowRight > 0) {
    leftto = mouseright - tooltipWidth - 20;
  }

  tooltip
    .style("left", leftto + "px")
    .style("top", topto + "px");
};

var mouseleave = function(d) {
  tooltip
    .style("display", "none")
    .style("opacity", 0);

  d3.select(this)
    .style("stroke", "#ddd");
};

// create the tooltip
var tooltip = d3.select("body")
  .append("div")
    .style("position", "absolute")
    .style("pointer-events", "none")
    .style("background-color", "rgba(255,255,255,0.75)")
    .style("opacity", 0)
    .style("width", "250px")
    .attr("class", "tooltip")
    .style("border-radius", "0px")
    .style("border", "1px solid #ddd")
    .style("box-shadow", "2px 2px 5px 0px rgba(0,0,0,0.1)");

var tooltipTitle = tooltip
  .append("div")
  .style("padding", "5px");


// containers for heatmap and its x-axis
var margin = {top: 20, right: 10, bottom: 10, left: 70},
heatWidth = 120 - margin.left - margin.right;

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

yAxisUp = svgHeatUpG.append("g");
xAxisUp = svgHeatUpG.append("g");

yAxisDown = svgHeatDownG.append("g");
xAxisDown = svgHeatDownG.append("g");

// Build Y scales and axis:
var yUp = d3.scaleBand().padding(0.01);
var yDown = d3.scaleBand().padding(0.01);

// Build X scales and axis:
var xUp = d3.scaleBand().padding(0);
var xDown = d3.scaleBand().padding(0);

// Build color scale
var palette = d3.scaleLinear().range(["blue", "white", "red"]);


// Three function that change the tooltip when user hover / move / leave a cell
var mouseover = function(d) {
  // show the tooltip
  tooltip
    .style("display", "block")
    .style("opacity", 1);
  d3.select(this)
    .style("stroke", "black")
    .style("opacity", 1);

  // add GO name to tooltip
  tooltipTitle.html(d.description);

  // format the heatmap data

  // genes that are common between both analyses
  var common = d.genes0.filter(gene => d.genes1.includes(gene));

  // data for analysis 0 and 1
  var geneData = [
    d.genes0.map((gene, i) =>  ({
      'gene': gene,
      'logfc': d.logFC0[i],
      'analysis': 0,
      'common': common.includes(gene)
    })),

    d.genes1.map((gene, i) =>  ({
      'gene': gene,
      'logfc': d.logFC1[i],
      'analysis': 1,
      'common': common.includes(gene)
    }))
  ];

  // only show genes upregulated in current analysis (analysis 0 if point is merged)
  var anal = d.analysis === 2 ? 0 : d.analysis;
  var twoanals = geneData[1].length;
  var genesUpAnal = geneData[anal].filter(item => item.logfc > 0).map(item => item.gene);
  var genesDownAnal = geneData[anal].filter(item => item.logfc <= 0).map(item => item.gene);

  // 70 up or down genes is most that is practical to fit
  // so prefer genes that are common to analysis 0 and 1
  var compareUp = function(a, b) {
    // sort gene that is common upwards
    if (a.common & !b.common) return -1;
    else if (b.common & !a.common) return 1;
    else return b.logfc - a.logfc;
  };

  var compareDown = function(a, b) {
    if (a.common & !b.common) return -1;
    else if (b.common & !a.common) return 1;
    else return a.logfc - b.logfc;
  };

  geneData = [...geneData[0], ...geneData[1]];

  var geneDataUp = geneData
    .filter(item => genesUpAnal.includes(item.gene))
    .sort(compareUp);

  var first70Up = geneDataUp
    .map(item => item.gene)
    .filter((v, i, a) => a.indexOf(v) === i)
    .filter((v, i) => i < 70);

  geneDataUp = geneDataUp.filter(item => first70Up.includes(item.gene));

  var geneDataDown = geneData
    .filter(item => genesDownAnal.includes(item.gene))
    .sort(compareDown);

  var first70Down = geneDataDown
    .map(item => item.gene)
    .filter((v, i, a) => a.indexOf(v) === i)
    .filter((v, i) => i < 70);

  geneDataDown = geneDataDown.filter(item => first70Down.includes(item.gene));

  // extent of logfc values
  var extent = d3.extent([...geneDataUp, ...geneDataDown], d => d.logfc);
  palette.domain([extent[0], 0, extent[1]]);

  // update the y axis domain ad redraw
  var genesUp = geneDataUp
    .filter(item => item.analysis === anal)
    .sort((a,b) => b.logfc - a.logfc)
    .map(item => item.gene);

  var genesDown = geneDataDown
    .filter(item => item.analysis === anal)
    .sort((a,b) => a.logfc - b.logfc)
    .map(item => item.gene);

  // height of tooltip svg
  var maxHeatHeight = window.innerHeight - tooltipTitle.node().getBoundingClientRect().height;
  var heatHeightUp = (genesUp.length*18) + margin.top + margin.bottom;
  var heatHeightDown = (genesDown.length*18) + margin.top + margin.bottom;
  heatHeightUp = Math.min(maxHeatHeight, heatHeightUp);
  heatHeightDown = Math.min(maxHeatHeight, heatHeightDown);
  svgHeatUp.attr("height", heatHeightUp)
  svgHeatDown.attr("height", heatHeightDown)

  yUp.domain(genesUp).range([ 0, heatHeightUp-margin.top-margin.bottom ]);
  yDown.domain(genesDown).range([ 0, heatHeightDown-margin.top-margin.bottom]);

  xUp.domain([0, 1]).range([0, yUp.bandwidth()*2]);
  xDown.domain([0, 1]).range([0, yDown.bandwidth()*2]);

  yAxisUp.call(d3.axisLeft(yUp).tickSizeOuter(0));
  yAxisDown.call(d3.axisLeft(yDown).tickSizeOuter(0));

  if (twoanals && yUp.bandwidth()) xAxisUp.call(d3.axisTop(xUp).tickSizeOuter(0));
  if (twoanals && yDown.bandwidth()) xAxisDown.call(d3.axisTop(xDown).tickSizeOuter(0));

  svgHeatUpG.selectAll("rect").remove();
  svgHeatDownG.selectAll("rect").remove();

  svgHeatUpG.selectAll()
      .data(geneDataUp, function(d) {return d.gene;})
      .enter()
      .append("rect")
      .attr("x", function(d) { return xUp(d.analysis) + 1})
      .attr("y", function(d) { return yUp(d.gene) + 1 })
      .attr("width", yUp.bandwidth() )
      .attr("height", yUp.bandwidth() )
      .style("fill", function(d) { return palette(d.logfc)} );

  svgHeatDownG.selectAll()
      .data(geneDataDown, function(d) {return d.gene;})
      .enter()
      .append("rect")
      .attr("x", function(d) { return xDown(d.analysis) + 1 })
      .attr("y", function(d) { return yDown(d.gene) + 1 })
      .attr("width", yDown.bandwidth() )
      .attr("height", yDown.bandwidth() )
      .style("fill", function(d) { return palette(d.logfc)} );

  };

var mousemove = function(d) {

  // if position from top and half height are more than window height, move up
  let visibleHeight = window.innerHeight;
  let visibleWidth = window.innerWidth;
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

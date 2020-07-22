// !preview r2d3 data = jsonlite::read_json("inst/d3/scatterplot/scatterplot.json"), d3_version = 4, dependencies = "inst/d3/tooltip/tooltip.js"


r2d3.onRender(function(data, svg, width, height, options) {


  var margin = {top: 20, right: 20, bottom: 50, left: 50};
  width = width - margin.left - margin.right;
  height = height - margin.top - margin.bottom;


  // setup x
  var xValue = function(d) { return d.plot_X;}, // data -> value
      xScale = d3.scaleLinear().range([0, width]), // value -> display
      xMap = function(d) { return xScale(xValue(d));}, // data -> display
      xAxis = svg.append("g");

  // setup y
  var yValue = function(d) { return d.plot_Y;}, // data -> value
      yScale = d3.scaleLinear().range([height, 0]), // value -> display
      yMap = function(d) { return yScale(yValue(d));}, // data -> display
      yAxis = svg.append("g");

  // setup fill color
  var cValue = function(d) { return -d["log10 p-value"];};
  var extent = d3.extent(data.map(cValue));
  var palettes = [d3.scaleLinear().domain([extent[0],extent[1]]).range(["#FFF5F0", "#EF3B2C"]),
                  d3.scaleLinear().domain([extent[0],extent[1]]).range(["#F7FBFF", "#2171B5"]),
                  d3.scaleLinear().domain([extent[0],extent[1]]).range(["#FCFBFD", "#6A51A3"])];
  var myColor = function(d) {
    let anal = d.analysis ? d.analysis : 0;
    return palettes[anal](cValue(d));
  };

  // add the graph canvas to the body of the webpage
  var svgG = svg
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  // remove null values
  data = data.filter(d => d.plot_X !== 'null');

  // change string (from CSV) into number format
  data.forEach(function(d) {
    d.plot_X = +d.plot_X;
    d.plot_Y = +d.plot_Y;
  });


  // don't want dots overlapping axis, so add in buffer to data domain
  xScale.domain([d3.min(data, xValue)-1, d3.max(data, xValue)+1]);
  yScale.domain([d3.min(data, yValue)-1, d3.max(data, yValue)+1]);

  // x-axis and label
  svgG.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.axisBottom(xScale));

    svgG.append("text")
      .attr("class", "label")
      .attr("transform",
            "translate(" + (width/2) + " ," + (height + margin.top + 20) + ")")
      .style("text-anchor", "middle")
      .text("Semantic Space X");

  // y-axis and label
  svgG.append("g")
      .attr("class", "y axis")
      .call(d3.axisLeft(yScale));

  svgG.append("text")
    .attr("class", "label")
    .attr("transform", "rotate(-90)")
    .attr("y", 0 - margin.left)
    .attr("x", 0 - (height/2))
    .attr("dy", "1em")
    .style("text-anchor", "middle")
    .text("Semantic Space Y");

    // draw dots
  svgG.selectAll(".dot")
      .data(data)
    .enter().append("circle")
      .attr("class", "dot")
      .attr("r", 6)
      .attr("cx", xMap)
      .attr("cy", yMap)
      .style("fill", function(d) { return myColor(d);})
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave);


});

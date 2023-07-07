// ignore_for_file: avoid_returning_null
// ignore_for_file: camel_case_types
// ignore_for_file: cascade_invocations
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: unnecessary_string_interpolations
// ignore_for_file: unused_local_variable

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:googleapis/sheets/v4.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAddBandingRequest = 0;
api.AddBandingRequest buildAddBandingRequest() {
  var o = api.AddBandingRequest();
  buildCounterAddBandingRequest++;
  if (buildCounterAddBandingRequest < 3) {
    o.bandedRange = buildBandedRange();
  }
  buildCounterAddBandingRequest--;
  return o;
}

void checkAddBandingRequest(api.AddBandingRequest o) {
  buildCounterAddBandingRequest++;
  if (buildCounterAddBandingRequest < 3) {
    checkBandedRange(o.bandedRange! as api.BandedRange);
  }
  buildCounterAddBandingRequest--;
}

core.int buildCounterAddBandingResponse = 0;
api.AddBandingResponse buildAddBandingResponse() {
  var o = api.AddBandingResponse();
  buildCounterAddBandingResponse++;
  if (buildCounterAddBandingResponse < 3) {
    o.bandedRange = buildBandedRange();
  }
  buildCounterAddBandingResponse--;
  return o;
}

void checkAddBandingResponse(api.AddBandingResponse o) {
  buildCounterAddBandingResponse++;
  if (buildCounterAddBandingResponse < 3) {
    checkBandedRange(o.bandedRange! as api.BandedRange);
  }
  buildCounterAddBandingResponse--;
}

core.int buildCounterAddChartRequest = 0;
api.AddChartRequest buildAddChartRequest() {
  var o = api.AddChartRequest();
  buildCounterAddChartRequest++;
  if (buildCounterAddChartRequest < 3) {
    o.chart = buildEmbeddedChart();
  }
  buildCounterAddChartRequest--;
  return o;
}

void checkAddChartRequest(api.AddChartRequest o) {
  buildCounterAddChartRequest++;
  if (buildCounterAddChartRequest < 3) {
    checkEmbeddedChart(o.chart! as api.EmbeddedChart);
  }
  buildCounterAddChartRequest--;
}

core.int buildCounterAddChartResponse = 0;
api.AddChartResponse buildAddChartResponse() {
  var o = api.AddChartResponse();
  buildCounterAddChartResponse++;
  if (buildCounterAddChartResponse < 3) {
    o.chart = buildEmbeddedChart();
  }
  buildCounterAddChartResponse--;
  return o;
}

void checkAddChartResponse(api.AddChartResponse o) {
  buildCounterAddChartResponse++;
  if (buildCounterAddChartResponse < 3) {
    checkEmbeddedChart(o.chart! as api.EmbeddedChart);
  }
  buildCounterAddChartResponse--;
}

core.int buildCounterAddConditionalFormatRuleRequest = 0;
api.AddConditionalFormatRuleRequest buildAddConditionalFormatRuleRequest() {
  var o = api.AddConditionalFormatRuleRequest();
  buildCounterAddConditionalFormatRuleRequest++;
  if (buildCounterAddConditionalFormatRuleRequest < 3) {
    o.index = 42;
    o.rule = buildConditionalFormatRule();
  }
  buildCounterAddConditionalFormatRuleRequest--;
  return o;
}

void checkAddConditionalFormatRuleRequest(
    api.AddConditionalFormatRuleRequest o) {
  buildCounterAddConditionalFormatRuleRequest++;
  if (buildCounterAddConditionalFormatRuleRequest < 3) {
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    checkConditionalFormatRule(o.rule! as api.ConditionalFormatRule);
  }
  buildCounterAddConditionalFormatRuleRequest--;
}

core.int buildCounterAddDataSourceRequest = 0;
api.AddDataSourceRequest buildAddDataSourceRequest() {
  var o = api.AddDataSourceRequest();
  buildCounterAddDataSourceRequest++;
  if (buildCounterAddDataSourceRequest < 3) {
    o.dataSource = buildDataSource();
  }
  buildCounterAddDataSourceRequest--;
  return o;
}

void checkAddDataSourceRequest(api.AddDataSourceRequest o) {
  buildCounterAddDataSourceRequest++;
  if (buildCounterAddDataSourceRequest < 3) {
    checkDataSource(o.dataSource! as api.DataSource);
  }
  buildCounterAddDataSourceRequest--;
}

core.int buildCounterAddDataSourceResponse = 0;
api.AddDataSourceResponse buildAddDataSourceResponse() {
  var o = api.AddDataSourceResponse();
  buildCounterAddDataSourceResponse++;
  if (buildCounterAddDataSourceResponse < 3) {
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.dataSource = buildDataSource();
  }
  buildCounterAddDataSourceResponse--;
  return o;
}

void checkAddDataSourceResponse(api.AddDataSourceResponse o) {
  buildCounterAddDataSourceResponse++;
  if (buildCounterAddDataSourceResponse < 3) {
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    checkDataSource(o.dataSource! as api.DataSource);
  }
  buildCounterAddDataSourceResponse--;
}

core.int buildCounterAddDimensionGroupRequest = 0;
api.AddDimensionGroupRequest buildAddDimensionGroupRequest() {
  var o = api.AddDimensionGroupRequest();
  buildCounterAddDimensionGroupRequest++;
  if (buildCounterAddDimensionGroupRequest < 3) {
    o.range = buildDimensionRange();
  }
  buildCounterAddDimensionGroupRequest--;
  return o;
}

void checkAddDimensionGroupRequest(api.AddDimensionGroupRequest o) {
  buildCounterAddDimensionGroupRequest++;
  if (buildCounterAddDimensionGroupRequest < 3) {
    checkDimensionRange(o.range! as api.DimensionRange);
  }
  buildCounterAddDimensionGroupRequest--;
}

core.List<api.DimensionGroup> buildUnnamed646() {
  var o = <api.DimensionGroup>[];
  o.add(buildDimensionGroup());
  o.add(buildDimensionGroup());
  return o;
}

void checkUnnamed646(core.List<api.DimensionGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionGroup(o[0] as api.DimensionGroup);
  checkDimensionGroup(o[1] as api.DimensionGroup);
}

core.int buildCounterAddDimensionGroupResponse = 0;
api.AddDimensionGroupResponse buildAddDimensionGroupResponse() {
  var o = api.AddDimensionGroupResponse();
  buildCounterAddDimensionGroupResponse++;
  if (buildCounterAddDimensionGroupResponse < 3) {
    o.dimensionGroups = buildUnnamed646();
  }
  buildCounterAddDimensionGroupResponse--;
  return o;
}

void checkAddDimensionGroupResponse(api.AddDimensionGroupResponse o) {
  buildCounterAddDimensionGroupResponse++;
  if (buildCounterAddDimensionGroupResponse < 3) {
    checkUnnamed646(o.dimensionGroups!);
  }
  buildCounterAddDimensionGroupResponse--;
}

core.int buildCounterAddFilterViewRequest = 0;
api.AddFilterViewRequest buildAddFilterViewRequest() {
  var o = api.AddFilterViewRequest();
  buildCounterAddFilterViewRequest++;
  if (buildCounterAddFilterViewRequest < 3) {
    o.filter = buildFilterView();
  }
  buildCounterAddFilterViewRequest--;
  return o;
}

void checkAddFilterViewRequest(api.AddFilterViewRequest o) {
  buildCounterAddFilterViewRequest++;
  if (buildCounterAddFilterViewRequest < 3) {
    checkFilterView(o.filter! as api.FilterView);
  }
  buildCounterAddFilterViewRequest--;
}

core.int buildCounterAddFilterViewResponse = 0;
api.AddFilterViewResponse buildAddFilterViewResponse() {
  var o = api.AddFilterViewResponse();
  buildCounterAddFilterViewResponse++;
  if (buildCounterAddFilterViewResponse < 3) {
    o.filter = buildFilterView();
  }
  buildCounterAddFilterViewResponse--;
  return o;
}

void checkAddFilterViewResponse(api.AddFilterViewResponse o) {
  buildCounterAddFilterViewResponse++;
  if (buildCounterAddFilterViewResponse < 3) {
    checkFilterView(o.filter! as api.FilterView);
  }
  buildCounterAddFilterViewResponse--;
}

core.int buildCounterAddNamedRangeRequest = 0;
api.AddNamedRangeRequest buildAddNamedRangeRequest() {
  var o = api.AddNamedRangeRequest();
  buildCounterAddNamedRangeRequest++;
  if (buildCounterAddNamedRangeRequest < 3) {
    o.namedRange = buildNamedRange();
  }
  buildCounterAddNamedRangeRequest--;
  return o;
}

void checkAddNamedRangeRequest(api.AddNamedRangeRequest o) {
  buildCounterAddNamedRangeRequest++;
  if (buildCounterAddNamedRangeRequest < 3) {
    checkNamedRange(o.namedRange! as api.NamedRange);
  }
  buildCounterAddNamedRangeRequest--;
}

core.int buildCounterAddNamedRangeResponse = 0;
api.AddNamedRangeResponse buildAddNamedRangeResponse() {
  var o = api.AddNamedRangeResponse();
  buildCounterAddNamedRangeResponse++;
  if (buildCounterAddNamedRangeResponse < 3) {
    o.namedRange = buildNamedRange();
  }
  buildCounterAddNamedRangeResponse--;
  return o;
}

void checkAddNamedRangeResponse(api.AddNamedRangeResponse o) {
  buildCounterAddNamedRangeResponse++;
  if (buildCounterAddNamedRangeResponse < 3) {
    checkNamedRange(o.namedRange! as api.NamedRange);
  }
  buildCounterAddNamedRangeResponse--;
}

core.int buildCounterAddProtectedRangeRequest = 0;
api.AddProtectedRangeRequest buildAddProtectedRangeRequest() {
  var o = api.AddProtectedRangeRequest();
  buildCounterAddProtectedRangeRequest++;
  if (buildCounterAddProtectedRangeRequest < 3) {
    o.protectedRange = buildProtectedRange();
  }
  buildCounterAddProtectedRangeRequest--;
  return o;
}

void checkAddProtectedRangeRequest(api.AddProtectedRangeRequest o) {
  buildCounterAddProtectedRangeRequest++;
  if (buildCounterAddProtectedRangeRequest < 3) {
    checkProtectedRange(o.protectedRange! as api.ProtectedRange);
  }
  buildCounterAddProtectedRangeRequest--;
}

core.int buildCounterAddProtectedRangeResponse = 0;
api.AddProtectedRangeResponse buildAddProtectedRangeResponse() {
  var o = api.AddProtectedRangeResponse();
  buildCounterAddProtectedRangeResponse++;
  if (buildCounterAddProtectedRangeResponse < 3) {
    o.protectedRange = buildProtectedRange();
  }
  buildCounterAddProtectedRangeResponse--;
  return o;
}

void checkAddProtectedRangeResponse(api.AddProtectedRangeResponse o) {
  buildCounterAddProtectedRangeResponse++;
  if (buildCounterAddProtectedRangeResponse < 3) {
    checkProtectedRange(o.protectedRange! as api.ProtectedRange);
  }
  buildCounterAddProtectedRangeResponse--;
}

core.int buildCounterAddSheetRequest = 0;
api.AddSheetRequest buildAddSheetRequest() {
  var o = api.AddSheetRequest();
  buildCounterAddSheetRequest++;
  if (buildCounterAddSheetRequest < 3) {
    o.properties = buildSheetProperties();
  }
  buildCounterAddSheetRequest--;
  return o;
}

void checkAddSheetRequest(api.AddSheetRequest o) {
  buildCounterAddSheetRequest++;
  if (buildCounterAddSheetRequest < 3) {
    checkSheetProperties(o.properties! as api.SheetProperties);
  }
  buildCounterAddSheetRequest--;
}

core.int buildCounterAddSheetResponse = 0;
api.AddSheetResponse buildAddSheetResponse() {
  var o = api.AddSheetResponse();
  buildCounterAddSheetResponse++;
  if (buildCounterAddSheetResponse < 3) {
    o.properties = buildSheetProperties();
  }
  buildCounterAddSheetResponse--;
  return o;
}

void checkAddSheetResponse(api.AddSheetResponse o) {
  buildCounterAddSheetResponse++;
  if (buildCounterAddSheetResponse < 3) {
    checkSheetProperties(o.properties! as api.SheetProperties);
  }
  buildCounterAddSheetResponse--;
}

core.int buildCounterAddSlicerRequest = 0;
api.AddSlicerRequest buildAddSlicerRequest() {
  var o = api.AddSlicerRequest();
  buildCounterAddSlicerRequest++;
  if (buildCounterAddSlicerRequest < 3) {
    o.slicer = buildSlicer();
  }
  buildCounterAddSlicerRequest--;
  return o;
}

void checkAddSlicerRequest(api.AddSlicerRequest o) {
  buildCounterAddSlicerRequest++;
  if (buildCounterAddSlicerRequest < 3) {
    checkSlicer(o.slicer! as api.Slicer);
  }
  buildCounterAddSlicerRequest--;
}

core.int buildCounterAddSlicerResponse = 0;
api.AddSlicerResponse buildAddSlicerResponse() {
  var o = api.AddSlicerResponse();
  buildCounterAddSlicerResponse++;
  if (buildCounterAddSlicerResponse < 3) {
    o.slicer = buildSlicer();
  }
  buildCounterAddSlicerResponse--;
  return o;
}

void checkAddSlicerResponse(api.AddSlicerResponse o) {
  buildCounterAddSlicerResponse++;
  if (buildCounterAddSlicerResponse < 3) {
    checkSlicer(o.slicer! as api.Slicer);
  }
  buildCounterAddSlicerResponse--;
}

core.List<api.RowData> buildUnnamed647() {
  var o = <api.RowData>[];
  o.add(buildRowData());
  o.add(buildRowData());
  return o;
}

void checkUnnamed647(core.List<api.RowData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRowData(o[0] as api.RowData);
  checkRowData(o[1] as api.RowData);
}

core.int buildCounterAppendCellsRequest = 0;
api.AppendCellsRequest buildAppendCellsRequest() {
  var o = api.AppendCellsRequest();
  buildCounterAppendCellsRequest++;
  if (buildCounterAppendCellsRequest < 3) {
    o.fields = 'foo';
    o.rows = buildUnnamed647();
    o.sheetId = 42;
  }
  buildCounterAppendCellsRequest--;
  return o;
}

void checkAppendCellsRequest(api.AppendCellsRequest o) {
  buildCounterAppendCellsRequest++;
  if (buildCounterAppendCellsRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkUnnamed647(o.rows!);
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterAppendCellsRequest--;
}

core.int buildCounterAppendDimensionRequest = 0;
api.AppendDimensionRequest buildAppendDimensionRequest() {
  var o = api.AppendDimensionRequest();
  buildCounterAppendDimensionRequest++;
  if (buildCounterAppendDimensionRequest < 3) {
    o.dimension = 'foo';
    o.length = 42;
    o.sheetId = 42;
  }
  buildCounterAppendDimensionRequest--;
  return o;
}

void checkAppendDimensionRequest(api.AppendDimensionRequest o) {
  buildCounterAppendDimensionRequest++;
  if (buildCounterAppendDimensionRequest < 3) {
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.length!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterAppendDimensionRequest--;
}

core.int buildCounterAppendValuesResponse = 0;
api.AppendValuesResponse buildAppendValuesResponse() {
  var o = api.AppendValuesResponse();
  buildCounterAppendValuesResponse++;
  if (buildCounterAppendValuesResponse < 3) {
    o.spreadsheetId = 'foo';
    o.tableRange = 'foo';
    o.updates = buildUpdateValuesResponse();
  }
  buildCounterAppendValuesResponse--;
  return o;
}

void checkAppendValuesResponse(api.AppendValuesResponse o) {
  buildCounterAppendValuesResponse++;
  if (buildCounterAppendValuesResponse < 3) {
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableRange!,
      unittest.equals('foo'),
    );
    checkUpdateValuesResponse(o.updates! as api.UpdateValuesResponse);
  }
  buildCounterAppendValuesResponse--;
}

core.int buildCounterAutoFillRequest = 0;
api.AutoFillRequest buildAutoFillRequest() {
  var o = api.AutoFillRequest();
  buildCounterAutoFillRequest++;
  if (buildCounterAutoFillRequest < 3) {
    o.range = buildGridRange();
    o.sourceAndDestination = buildSourceAndDestination();
    o.useAlternateSeries = true;
  }
  buildCounterAutoFillRequest--;
  return o;
}

void checkAutoFillRequest(api.AutoFillRequest o) {
  buildCounterAutoFillRequest++;
  if (buildCounterAutoFillRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
    checkSourceAndDestination(
        o.sourceAndDestination! as api.SourceAndDestination);
    unittest.expect(o.useAlternateSeries!, unittest.isTrue);
  }
  buildCounterAutoFillRequest--;
}

core.int buildCounterAutoResizeDimensionsRequest = 0;
api.AutoResizeDimensionsRequest buildAutoResizeDimensionsRequest() {
  var o = api.AutoResizeDimensionsRequest();
  buildCounterAutoResizeDimensionsRequest++;
  if (buildCounterAutoResizeDimensionsRequest < 3) {
    o.dataSourceSheetDimensions = buildDataSourceSheetDimensionRange();
    o.dimensions = buildDimensionRange();
  }
  buildCounterAutoResizeDimensionsRequest--;
  return o;
}

void checkAutoResizeDimensionsRequest(api.AutoResizeDimensionsRequest o) {
  buildCounterAutoResizeDimensionsRequest++;
  if (buildCounterAutoResizeDimensionsRequest < 3) {
    checkDataSourceSheetDimensionRange(
        o.dataSourceSheetDimensions! as api.DataSourceSheetDimensionRange);
    checkDimensionRange(o.dimensions! as api.DimensionRange);
  }
  buildCounterAutoResizeDimensionsRequest--;
}

core.int buildCounterBandedRange = 0;
api.BandedRange buildBandedRange() {
  var o = api.BandedRange();
  buildCounterBandedRange++;
  if (buildCounterBandedRange < 3) {
    o.bandedRangeId = 42;
    o.columnProperties = buildBandingProperties();
    o.range = buildGridRange();
    o.rowProperties = buildBandingProperties();
  }
  buildCounterBandedRange--;
  return o;
}

void checkBandedRange(api.BandedRange o) {
  buildCounterBandedRange++;
  if (buildCounterBandedRange < 3) {
    unittest.expect(
      o.bandedRangeId!,
      unittest.equals(42),
    );
    checkBandingProperties(o.columnProperties! as api.BandingProperties);
    checkGridRange(o.range! as api.GridRange);
    checkBandingProperties(o.rowProperties! as api.BandingProperties);
  }
  buildCounterBandedRange--;
}

core.int buildCounterBandingProperties = 0;
api.BandingProperties buildBandingProperties() {
  var o = api.BandingProperties();
  buildCounterBandingProperties++;
  if (buildCounterBandingProperties < 3) {
    o.firstBandColor = buildColor();
    o.firstBandColorStyle = buildColorStyle();
    o.footerColor = buildColor();
    o.footerColorStyle = buildColorStyle();
    o.headerColor = buildColor();
    o.headerColorStyle = buildColorStyle();
    o.secondBandColor = buildColor();
    o.secondBandColorStyle = buildColorStyle();
  }
  buildCounterBandingProperties--;
  return o;
}

void checkBandingProperties(api.BandingProperties o) {
  buildCounterBandingProperties++;
  if (buildCounterBandingProperties < 3) {
    checkColor(o.firstBandColor! as api.Color);
    checkColorStyle(o.firstBandColorStyle! as api.ColorStyle);
    checkColor(o.footerColor! as api.Color);
    checkColorStyle(o.footerColorStyle! as api.ColorStyle);
    checkColor(o.headerColor! as api.Color);
    checkColorStyle(o.headerColorStyle! as api.ColorStyle);
    checkColor(o.secondBandColor! as api.Color);
    checkColorStyle(o.secondBandColorStyle! as api.ColorStyle);
  }
  buildCounterBandingProperties--;
}

core.int buildCounterBaselineValueFormat = 0;
api.BaselineValueFormat buildBaselineValueFormat() {
  var o = api.BaselineValueFormat();
  buildCounterBaselineValueFormat++;
  if (buildCounterBaselineValueFormat < 3) {
    o.comparisonType = 'foo';
    o.description = 'foo';
    o.negativeColor = buildColor();
    o.negativeColorStyle = buildColorStyle();
    o.position = buildTextPosition();
    o.positiveColor = buildColor();
    o.positiveColorStyle = buildColorStyle();
    o.textFormat = buildTextFormat();
  }
  buildCounterBaselineValueFormat--;
  return o;
}

void checkBaselineValueFormat(api.BaselineValueFormat o) {
  buildCounterBaselineValueFormat++;
  if (buildCounterBaselineValueFormat < 3) {
    unittest.expect(
      o.comparisonType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkColor(o.negativeColor! as api.Color);
    checkColorStyle(o.negativeColorStyle! as api.ColorStyle);
    checkTextPosition(o.position! as api.TextPosition);
    checkColor(o.positiveColor! as api.Color);
    checkColorStyle(o.positiveColorStyle! as api.ColorStyle);
    checkTextFormat(o.textFormat! as api.TextFormat);
  }
  buildCounterBaselineValueFormat--;
}

core.int buildCounterBasicChartAxis = 0;
api.BasicChartAxis buildBasicChartAxis() {
  var o = api.BasicChartAxis();
  buildCounterBasicChartAxis++;
  if (buildCounterBasicChartAxis < 3) {
    o.format = buildTextFormat();
    o.position = 'foo';
    o.title = 'foo';
    o.titleTextPosition = buildTextPosition();
    o.viewWindowOptions = buildChartAxisViewWindowOptions();
  }
  buildCounterBasicChartAxis--;
  return o;
}

void checkBasicChartAxis(api.BasicChartAxis o) {
  buildCounterBasicChartAxis++;
  if (buildCounterBasicChartAxis < 3) {
    checkTextFormat(o.format! as api.TextFormat);
    unittest.expect(
      o.position!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    checkTextPosition(o.titleTextPosition! as api.TextPosition);
    checkChartAxisViewWindowOptions(
        o.viewWindowOptions! as api.ChartAxisViewWindowOptions);
  }
  buildCounterBasicChartAxis--;
}

core.int buildCounterBasicChartDomain = 0;
api.BasicChartDomain buildBasicChartDomain() {
  var o = api.BasicChartDomain();
  buildCounterBasicChartDomain++;
  if (buildCounterBasicChartDomain < 3) {
    o.domain = buildChartData();
    o.reversed = true;
  }
  buildCounterBasicChartDomain--;
  return o;
}

void checkBasicChartDomain(api.BasicChartDomain o) {
  buildCounterBasicChartDomain++;
  if (buildCounterBasicChartDomain < 3) {
    checkChartData(o.domain! as api.ChartData);
    unittest.expect(o.reversed!, unittest.isTrue);
  }
  buildCounterBasicChartDomain--;
}

core.List<api.BasicSeriesDataPointStyleOverride> buildUnnamed648() {
  var o = <api.BasicSeriesDataPointStyleOverride>[];
  o.add(buildBasicSeriesDataPointStyleOverride());
  o.add(buildBasicSeriesDataPointStyleOverride());
  return o;
}

void checkUnnamed648(core.List<api.BasicSeriesDataPointStyleOverride> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBasicSeriesDataPointStyleOverride(
      o[0] as api.BasicSeriesDataPointStyleOverride);
  checkBasicSeriesDataPointStyleOverride(
      o[1] as api.BasicSeriesDataPointStyleOverride);
}

core.int buildCounterBasicChartSeries = 0;
api.BasicChartSeries buildBasicChartSeries() {
  var o = api.BasicChartSeries();
  buildCounterBasicChartSeries++;
  if (buildCounterBasicChartSeries < 3) {
    o.color = buildColor();
    o.colorStyle = buildColorStyle();
    o.dataLabel = buildDataLabel();
    o.lineStyle = buildLineStyle();
    o.pointStyle = buildPointStyle();
    o.series = buildChartData();
    o.styleOverrides = buildUnnamed648();
    o.targetAxis = 'foo';
    o.type = 'foo';
  }
  buildCounterBasicChartSeries--;
  return o;
}

void checkBasicChartSeries(api.BasicChartSeries o) {
  buildCounterBasicChartSeries++;
  if (buildCounterBasicChartSeries < 3) {
    checkColor(o.color! as api.Color);
    checkColorStyle(o.colorStyle! as api.ColorStyle);
    checkDataLabel(o.dataLabel! as api.DataLabel);
    checkLineStyle(o.lineStyle! as api.LineStyle);
    checkPointStyle(o.pointStyle! as api.PointStyle);
    checkChartData(o.series! as api.ChartData);
    checkUnnamed648(o.styleOverrides!);
    unittest.expect(
      o.targetAxis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterBasicChartSeries--;
}

core.List<api.BasicChartAxis> buildUnnamed649() {
  var o = <api.BasicChartAxis>[];
  o.add(buildBasicChartAxis());
  o.add(buildBasicChartAxis());
  return o;
}

void checkUnnamed649(core.List<api.BasicChartAxis> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBasicChartAxis(o[0] as api.BasicChartAxis);
  checkBasicChartAxis(o[1] as api.BasicChartAxis);
}

core.List<api.BasicChartDomain> buildUnnamed650() {
  var o = <api.BasicChartDomain>[];
  o.add(buildBasicChartDomain());
  o.add(buildBasicChartDomain());
  return o;
}

void checkUnnamed650(core.List<api.BasicChartDomain> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBasicChartDomain(o[0] as api.BasicChartDomain);
  checkBasicChartDomain(o[1] as api.BasicChartDomain);
}

core.List<api.BasicChartSeries> buildUnnamed651() {
  var o = <api.BasicChartSeries>[];
  o.add(buildBasicChartSeries());
  o.add(buildBasicChartSeries());
  return o;
}

void checkUnnamed651(core.List<api.BasicChartSeries> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBasicChartSeries(o[0] as api.BasicChartSeries);
  checkBasicChartSeries(o[1] as api.BasicChartSeries);
}

core.int buildCounterBasicChartSpec = 0;
api.BasicChartSpec buildBasicChartSpec() {
  var o = api.BasicChartSpec();
  buildCounterBasicChartSpec++;
  if (buildCounterBasicChartSpec < 3) {
    o.axis = buildUnnamed649();
    o.chartType = 'foo';
    o.compareMode = 'foo';
    o.domains = buildUnnamed650();
    o.headerCount = 42;
    o.interpolateNulls = true;
    o.legendPosition = 'foo';
    o.lineSmoothing = true;
    o.series = buildUnnamed651();
    o.stackedType = 'foo';
    o.threeDimensional = true;
    o.totalDataLabel = buildDataLabel();
  }
  buildCounterBasicChartSpec--;
  return o;
}

void checkBasicChartSpec(api.BasicChartSpec o) {
  buildCounterBasicChartSpec++;
  if (buildCounterBasicChartSpec < 3) {
    checkUnnamed649(o.axis!);
    unittest.expect(
      o.chartType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.compareMode!,
      unittest.equals('foo'),
    );
    checkUnnamed650(o.domains!);
    unittest.expect(
      o.headerCount!,
      unittest.equals(42),
    );
    unittest.expect(o.interpolateNulls!, unittest.isTrue);
    unittest.expect(
      o.legendPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(o.lineSmoothing!, unittest.isTrue);
    checkUnnamed651(o.series!);
    unittest.expect(
      o.stackedType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.threeDimensional!, unittest.isTrue);
    checkDataLabel(o.totalDataLabel! as api.DataLabel);
  }
  buildCounterBasicChartSpec--;
}

core.Map<core.String, api.FilterCriteria> buildUnnamed652() {
  var o = <core.String, api.FilterCriteria>{};
  o['x'] = buildFilterCriteria();
  o['y'] = buildFilterCriteria();
  return o;
}

void checkUnnamed652(core.Map<core.String, api.FilterCriteria> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterCriteria(o['x']! as api.FilterCriteria);
  checkFilterCriteria(o['y']! as api.FilterCriteria);
}

core.List<api.FilterSpec> buildUnnamed653() {
  var o = <api.FilterSpec>[];
  o.add(buildFilterSpec());
  o.add(buildFilterSpec());
  return o;
}

void checkUnnamed653(core.List<api.FilterSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterSpec(o[0] as api.FilterSpec);
  checkFilterSpec(o[1] as api.FilterSpec);
}

core.List<api.SortSpec> buildUnnamed654() {
  var o = <api.SortSpec>[];
  o.add(buildSortSpec());
  o.add(buildSortSpec());
  return o;
}

void checkUnnamed654(core.List<api.SortSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSortSpec(o[0] as api.SortSpec);
  checkSortSpec(o[1] as api.SortSpec);
}

core.int buildCounterBasicFilter = 0;
api.BasicFilter buildBasicFilter() {
  var o = api.BasicFilter();
  buildCounterBasicFilter++;
  if (buildCounterBasicFilter < 3) {
    o.criteria = buildUnnamed652();
    o.filterSpecs = buildUnnamed653();
    o.range = buildGridRange();
    o.sortSpecs = buildUnnamed654();
  }
  buildCounterBasicFilter--;
  return o;
}

void checkBasicFilter(api.BasicFilter o) {
  buildCounterBasicFilter++;
  if (buildCounterBasicFilter < 3) {
    checkUnnamed652(o.criteria!);
    checkUnnamed653(o.filterSpecs!);
    checkGridRange(o.range! as api.GridRange);
    checkUnnamed654(o.sortSpecs!);
  }
  buildCounterBasicFilter--;
}

core.int buildCounterBasicSeriesDataPointStyleOverride = 0;
api.BasicSeriesDataPointStyleOverride buildBasicSeriesDataPointStyleOverride() {
  var o = api.BasicSeriesDataPointStyleOverride();
  buildCounterBasicSeriesDataPointStyleOverride++;
  if (buildCounterBasicSeriesDataPointStyleOverride < 3) {
    o.color = buildColor();
    o.colorStyle = buildColorStyle();
    o.index = 42;
    o.pointStyle = buildPointStyle();
  }
  buildCounterBasicSeriesDataPointStyleOverride--;
  return o;
}

void checkBasicSeriesDataPointStyleOverride(
    api.BasicSeriesDataPointStyleOverride o) {
  buildCounterBasicSeriesDataPointStyleOverride++;
  if (buildCounterBasicSeriesDataPointStyleOverride < 3) {
    checkColor(o.color! as api.Color);
    checkColorStyle(o.colorStyle! as api.ColorStyle);
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    checkPointStyle(o.pointStyle! as api.PointStyle);
  }
  buildCounterBasicSeriesDataPointStyleOverride--;
}

core.List<api.DataFilter> buildUnnamed655() {
  var o = <api.DataFilter>[];
  o.add(buildDataFilter());
  o.add(buildDataFilter());
  return o;
}

void checkUnnamed655(core.List<api.DataFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilter(o[0] as api.DataFilter);
  checkDataFilter(o[1] as api.DataFilter);
}

core.int buildCounterBatchClearValuesByDataFilterRequest = 0;
api.BatchClearValuesByDataFilterRequest
    buildBatchClearValuesByDataFilterRequest() {
  var o = api.BatchClearValuesByDataFilterRequest();
  buildCounterBatchClearValuesByDataFilterRequest++;
  if (buildCounterBatchClearValuesByDataFilterRequest < 3) {
    o.dataFilters = buildUnnamed655();
  }
  buildCounterBatchClearValuesByDataFilterRequest--;
  return o;
}

void checkBatchClearValuesByDataFilterRequest(
    api.BatchClearValuesByDataFilterRequest o) {
  buildCounterBatchClearValuesByDataFilterRequest++;
  if (buildCounterBatchClearValuesByDataFilterRequest < 3) {
    checkUnnamed655(o.dataFilters!);
  }
  buildCounterBatchClearValuesByDataFilterRequest--;
}

core.List<core.String> buildUnnamed656() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed656(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterBatchClearValuesByDataFilterResponse = 0;
api.BatchClearValuesByDataFilterResponse
    buildBatchClearValuesByDataFilterResponse() {
  var o = api.BatchClearValuesByDataFilterResponse();
  buildCounterBatchClearValuesByDataFilterResponse++;
  if (buildCounterBatchClearValuesByDataFilterResponse < 3) {
    o.clearedRanges = buildUnnamed656();
    o.spreadsheetId = 'foo';
  }
  buildCounterBatchClearValuesByDataFilterResponse--;
  return o;
}

void checkBatchClearValuesByDataFilterResponse(
    api.BatchClearValuesByDataFilterResponse o) {
  buildCounterBatchClearValuesByDataFilterResponse++;
  if (buildCounterBatchClearValuesByDataFilterResponse < 3) {
    checkUnnamed656(o.clearedRanges!);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchClearValuesByDataFilterResponse--;
}

core.List<core.String> buildUnnamed657() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed657(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterBatchClearValuesRequest = 0;
api.BatchClearValuesRequest buildBatchClearValuesRequest() {
  var o = api.BatchClearValuesRequest();
  buildCounterBatchClearValuesRequest++;
  if (buildCounterBatchClearValuesRequest < 3) {
    o.ranges = buildUnnamed657();
  }
  buildCounterBatchClearValuesRequest--;
  return o;
}

void checkBatchClearValuesRequest(api.BatchClearValuesRequest o) {
  buildCounterBatchClearValuesRequest++;
  if (buildCounterBatchClearValuesRequest < 3) {
    checkUnnamed657(o.ranges!);
  }
  buildCounterBatchClearValuesRequest--;
}

core.List<core.String> buildUnnamed658() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed658(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterBatchClearValuesResponse = 0;
api.BatchClearValuesResponse buildBatchClearValuesResponse() {
  var o = api.BatchClearValuesResponse();
  buildCounterBatchClearValuesResponse++;
  if (buildCounterBatchClearValuesResponse < 3) {
    o.clearedRanges = buildUnnamed658();
    o.spreadsheetId = 'foo';
  }
  buildCounterBatchClearValuesResponse--;
  return o;
}

void checkBatchClearValuesResponse(api.BatchClearValuesResponse o) {
  buildCounterBatchClearValuesResponse++;
  if (buildCounterBatchClearValuesResponse < 3) {
    checkUnnamed658(o.clearedRanges!);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchClearValuesResponse--;
}

core.List<api.DataFilter> buildUnnamed659() {
  var o = <api.DataFilter>[];
  o.add(buildDataFilter());
  o.add(buildDataFilter());
  return o;
}

void checkUnnamed659(core.List<api.DataFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilter(o[0] as api.DataFilter);
  checkDataFilter(o[1] as api.DataFilter);
}

core.int buildCounterBatchGetValuesByDataFilterRequest = 0;
api.BatchGetValuesByDataFilterRequest buildBatchGetValuesByDataFilterRequest() {
  var o = api.BatchGetValuesByDataFilterRequest();
  buildCounterBatchGetValuesByDataFilterRequest++;
  if (buildCounterBatchGetValuesByDataFilterRequest < 3) {
    o.dataFilters = buildUnnamed659();
    o.dateTimeRenderOption = 'foo';
    o.majorDimension = 'foo';
    o.valueRenderOption = 'foo';
  }
  buildCounterBatchGetValuesByDataFilterRequest--;
  return o;
}

void checkBatchGetValuesByDataFilterRequest(
    api.BatchGetValuesByDataFilterRequest o) {
  buildCounterBatchGetValuesByDataFilterRequest++;
  if (buildCounterBatchGetValuesByDataFilterRequest < 3) {
    checkUnnamed659(o.dataFilters!);
    unittest.expect(
      o.dateTimeRenderOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.majorDimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.valueRenderOption!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchGetValuesByDataFilterRequest--;
}

core.List<api.MatchedValueRange> buildUnnamed660() {
  var o = <api.MatchedValueRange>[];
  o.add(buildMatchedValueRange());
  o.add(buildMatchedValueRange());
  return o;
}

void checkUnnamed660(core.List<api.MatchedValueRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMatchedValueRange(o[0] as api.MatchedValueRange);
  checkMatchedValueRange(o[1] as api.MatchedValueRange);
}

core.int buildCounterBatchGetValuesByDataFilterResponse = 0;
api.BatchGetValuesByDataFilterResponse
    buildBatchGetValuesByDataFilterResponse() {
  var o = api.BatchGetValuesByDataFilterResponse();
  buildCounterBatchGetValuesByDataFilterResponse++;
  if (buildCounterBatchGetValuesByDataFilterResponse < 3) {
    o.spreadsheetId = 'foo';
    o.valueRanges = buildUnnamed660();
  }
  buildCounterBatchGetValuesByDataFilterResponse--;
  return o;
}

void checkBatchGetValuesByDataFilterResponse(
    api.BatchGetValuesByDataFilterResponse o) {
  buildCounterBatchGetValuesByDataFilterResponse++;
  if (buildCounterBatchGetValuesByDataFilterResponse < 3) {
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    checkUnnamed660(o.valueRanges!);
  }
  buildCounterBatchGetValuesByDataFilterResponse--;
}

core.List<api.ValueRange> buildUnnamed661() {
  var o = <api.ValueRange>[];
  o.add(buildValueRange());
  o.add(buildValueRange());
  return o;
}

void checkUnnamed661(core.List<api.ValueRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValueRange(o[0] as api.ValueRange);
  checkValueRange(o[1] as api.ValueRange);
}

core.int buildCounterBatchGetValuesResponse = 0;
api.BatchGetValuesResponse buildBatchGetValuesResponse() {
  var o = api.BatchGetValuesResponse();
  buildCounterBatchGetValuesResponse++;
  if (buildCounterBatchGetValuesResponse < 3) {
    o.spreadsheetId = 'foo';
    o.valueRanges = buildUnnamed661();
  }
  buildCounterBatchGetValuesResponse--;
  return o;
}

void checkBatchGetValuesResponse(api.BatchGetValuesResponse o) {
  buildCounterBatchGetValuesResponse++;
  if (buildCounterBatchGetValuesResponse < 3) {
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    checkUnnamed661(o.valueRanges!);
  }
  buildCounterBatchGetValuesResponse--;
}

core.List<api.Request> buildUnnamed662() {
  var o = <api.Request>[];
  o.add(buildRequest());
  o.add(buildRequest());
  return o;
}

void checkUnnamed662(core.List<api.Request> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRequest(o[0] as api.Request);
  checkRequest(o[1] as api.Request);
}

core.List<core.String> buildUnnamed663() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed663(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterBatchUpdateSpreadsheetRequest = 0;
api.BatchUpdateSpreadsheetRequest buildBatchUpdateSpreadsheetRequest() {
  var o = api.BatchUpdateSpreadsheetRequest();
  buildCounterBatchUpdateSpreadsheetRequest++;
  if (buildCounterBatchUpdateSpreadsheetRequest < 3) {
    o.includeSpreadsheetInResponse = true;
    o.requests = buildUnnamed662();
    o.responseIncludeGridData = true;
    o.responseRanges = buildUnnamed663();
  }
  buildCounterBatchUpdateSpreadsheetRequest--;
  return o;
}

void checkBatchUpdateSpreadsheetRequest(api.BatchUpdateSpreadsheetRequest o) {
  buildCounterBatchUpdateSpreadsheetRequest++;
  if (buildCounterBatchUpdateSpreadsheetRequest < 3) {
    unittest.expect(o.includeSpreadsheetInResponse!, unittest.isTrue);
    checkUnnamed662(o.requests!);
    unittest.expect(o.responseIncludeGridData!, unittest.isTrue);
    checkUnnamed663(o.responseRanges!);
  }
  buildCounterBatchUpdateSpreadsheetRequest--;
}

core.List<api.Response> buildUnnamed664() {
  var o = <api.Response>[];
  o.add(buildResponse());
  o.add(buildResponse());
  return o;
}

void checkUnnamed664(core.List<api.Response> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResponse(o[0] as api.Response);
  checkResponse(o[1] as api.Response);
}

core.int buildCounterBatchUpdateSpreadsheetResponse = 0;
api.BatchUpdateSpreadsheetResponse buildBatchUpdateSpreadsheetResponse() {
  var o = api.BatchUpdateSpreadsheetResponse();
  buildCounterBatchUpdateSpreadsheetResponse++;
  if (buildCounterBatchUpdateSpreadsheetResponse < 3) {
    o.replies = buildUnnamed664();
    o.spreadsheetId = 'foo';
    o.updatedSpreadsheet = buildSpreadsheet();
  }
  buildCounterBatchUpdateSpreadsheetResponse--;
  return o;
}

void checkBatchUpdateSpreadsheetResponse(api.BatchUpdateSpreadsheetResponse o) {
  buildCounterBatchUpdateSpreadsheetResponse++;
  if (buildCounterBatchUpdateSpreadsheetResponse < 3) {
    checkUnnamed664(o.replies!);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    checkSpreadsheet(o.updatedSpreadsheet! as api.Spreadsheet);
  }
  buildCounterBatchUpdateSpreadsheetResponse--;
}

core.List<api.DataFilterValueRange> buildUnnamed665() {
  var o = <api.DataFilterValueRange>[];
  o.add(buildDataFilterValueRange());
  o.add(buildDataFilterValueRange());
  return o;
}

void checkUnnamed665(core.List<api.DataFilterValueRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilterValueRange(o[0] as api.DataFilterValueRange);
  checkDataFilterValueRange(o[1] as api.DataFilterValueRange);
}

core.int buildCounterBatchUpdateValuesByDataFilterRequest = 0;
api.BatchUpdateValuesByDataFilterRequest
    buildBatchUpdateValuesByDataFilterRequest() {
  var o = api.BatchUpdateValuesByDataFilterRequest();
  buildCounterBatchUpdateValuesByDataFilterRequest++;
  if (buildCounterBatchUpdateValuesByDataFilterRequest < 3) {
    o.data = buildUnnamed665();
    o.includeValuesInResponse = true;
    o.responseDateTimeRenderOption = 'foo';
    o.responseValueRenderOption = 'foo';
    o.valueInputOption = 'foo';
  }
  buildCounterBatchUpdateValuesByDataFilterRequest--;
  return o;
}

void checkBatchUpdateValuesByDataFilterRequest(
    api.BatchUpdateValuesByDataFilterRequest o) {
  buildCounterBatchUpdateValuesByDataFilterRequest++;
  if (buildCounterBatchUpdateValuesByDataFilterRequest < 3) {
    checkUnnamed665(o.data!);
    unittest.expect(o.includeValuesInResponse!, unittest.isTrue);
    unittest.expect(
      o.responseDateTimeRenderOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responseValueRenderOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.valueInputOption!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchUpdateValuesByDataFilterRequest--;
}

core.List<api.UpdateValuesByDataFilterResponse> buildUnnamed666() {
  var o = <api.UpdateValuesByDataFilterResponse>[];
  o.add(buildUpdateValuesByDataFilterResponse());
  o.add(buildUpdateValuesByDataFilterResponse());
  return o;
}

void checkUnnamed666(core.List<api.UpdateValuesByDataFilterResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUpdateValuesByDataFilterResponse(
      o[0] as api.UpdateValuesByDataFilterResponse);
  checkUpdateValuesByDataFilterResponse(
      o[1] as api.UpdateValuesByDataFilterResponse);
}

core.int buildCounterBatchUpdateValuesByDataFilterResponse = 0;
api.BatchUpdateValuesByDataFilterResponse
    buildBatchUpdateValuesByDataFilterResponse() {
  var o = api.BatchUpdateValuesByDataFilterResponse();
  buildCounterBatchUpdateValuesByDataFilterResponse++;
  if (buildCounterBatchUpdateValuesByDataFilterResponse < 3) {
    o.responses = buildUnnamed666();
    o.spreadsheetId = 'foo';
    o.totalUpdatedCells = 42;
    o.totalUpdatedColumns = 42;
    o.totalUpdatedRows = 42;
    o.totalUpdatedSheets = 42;
  }
  buildCounterBatchUpdateValuesByDataFilterResponse--;
  return o;
}

void checkBatchUpdateValuesByDataFilterResponse(
    api.BatchUpdateValuesByDataFilterResponse o) {
  buildCounterBatchUpdateValuesByDataFilterResponse++;
  if (buildCounterBatchUpdateValuesByDataFilterResponse < 3) {
    checkUnnamed666(o.responses!);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalUpdatedCells!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalUpdatedColumns!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalUpdatedRows!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalUpdatedSheets!,
      unittest.equals(42),
    );
  }
  buildCounterBatchUpdateValuesByDataFilterResponse--;
}

core.List<api.ValueRange> buildUnnamed667() {
  var o = <api.ValueRange>[];
  o.add(buildValueRange());
  o.add(buildValueRange());
  return o;
}

void checkUnnamed667(core.List<api.ValueRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValueRange(o[0] as api.ValueRange);
  checkValueRange(o[1] as api.ValueRange);
}

core.int buildCounterBatchUpdateValuesRequest = 0;
api.BatchUpdateValuesRequest buildBatchUpdateValuesRequest() {
  var o = api.BatchUpdateValuesRequest();
  buildCounterBatchUpdateValuesRequest++;
  if (buildCounterBatchUpdateValuesRequest < 3) {
    o.data = buildUnnamed667();
    o.includeValuesInResponse = true;
    o.responseDateTimeRenderOption = 'foo';
    o.responseValueRenderOption = 'foo';
    o.valueInputOption = 'foo';
  }
  buildCounterBatchUpdateValuesRequest--;
  return o;
}

void checkBatchUpdateValuesRequest(api.BatchUpdateValuesRequest o) {
  buildCounterBatchUpdateValuesRequest++;
  if (buildCounterBatchUpdateValuesRequest < 3) {
    checkUnnamed667(o.data!);
    unittest.expect(o.includeValuesInResponse!, unittest.isTrue);
    unittest.expect(
      o.responseDateTimeRenderOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responseValueRenderOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.valueInputOption!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchUpdateValuesRequest--;
}

core.List<api.UpdateValuesResponse> buildUnnamed668() {
  var o = <api.UpdateValuesResponse>[];
  o.add(buildUpdateValuesResponse());
  o.add(buildUpdateValuesResponse());
  return o;
}

void checkUnnamed668(core.List<api.UpdateValuesResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUpdateValuesResponse(o[0] as api.UpdateValuesResponse);
  checkUpdateValuesResponse(o[1] as api.UpdateValuesResponse);
}

core.int buildCounterBatchUpdateValuesResponse = 0;
api.BatchUpdateValuesResponse buildBatchUpdateValuesResponse() {
  var o = api.BatchUpdateValuesResponse();
  buildCounterBatchUpdateValuesResponse++;
  if (buildCounterBatchUpdateValuesResponse < 3) {
    o.responses = buildUnnamed668();
    o.spreadsheetId = 'foo';
    o.totalUpdatedCells = 42;
    o.totalUpdatedColumns = 42;
    o.totalUpdatedRows = 42;
    o.totalUpdatedSheets = 42;
  }
  buildCounterBatchUpdateValuesResponse--;
  return o;
}

void checkBatchUpdateValuesResponse(api.BatchUpdateValuesResponse o) {
  buildCounterBatchUpdateValuesResponse++;
  if (buildCounterBatchUpdateValuesResponse < 3) {
    checkUnnamed668(o.responses!);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalUpdatedCells!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalUpdatedColumns!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalUpdatedRows!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalUpdatedSheets!,
      unittest.equals(42),
    );
  }
  buildCounterBatchUpdateValuesResponse--;
}

core.int buildCounterBigQueryDataSourceSpec = 0;
api.BigQueryDataSourceSpec buildBigQueryDataSourceSpec() {
  var o = api.BigQueryDataSourceSpec();
  buildCounterBigQueryDataSourceSpec++;
  if (buildCounterBigQueryDataSourceSpec < 3) {
    o.projectId = 'foo';
    o.querySpec = buildBigQueryQuerySpec();
    o.tableSpec = buildBigQueryTableSpec();
  }
  buildCounterBigQueryDataSourceSpec--;
  return o;
}

void checkBigQueryDataSourceSpec(api.BigQueryDataSourceSpec o) {
  buildCounterBigQueryDataSourceSpec++;
  if (buildCounterBigQueryDataSourceSpec < 3) {
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    checkBigQueryQuerySpec(o.querySpec! as api.BigQueryQuerySpec);
    checkBigQueryTableSpec(o.tableSpec! as api.BigQueryTableSpec);
  }
  buildCounterBigQueryDataSourceSpec--;
}

core.int buildCounterBigQueryQuerySpec = 0;
api.BigQueryQuerySpec buildBigQueryQuerySpec() {
  var o = api.BigQueryQuerySpec();
  buildCounterBigQueryQuerySpec++;
  if (buildCounterBigQueryQuerySpec < 3) {
    o.rawQuery = 'foo';
  }
  buildCounterBigQueryQuerySpec--;
  return o;
}

void checkBigQueryQuerySpec(api.BigQueryQuerySpec o) {
  buildCounterBigQueryQuerySpec++;
  if (buildCounterBigQueryQuerySpec < 3) {
    unittest.expect(
      o.rawQuery!,
      unittest.equals('foo'),
    );
  }
  buildCounterBigQueryQuerySpec--;
}

core.int buildCounterBigQueryTableSpec = 0;
api.BigQueryTableSpec buildBigQueryTableSpec() {
  var o = api.BigQueryTableSpec();
  buildCounterBigQueryTableSpec++;
  if (buildCounterBigQueryTableSpec < 3) {
    o.datasetId = 'foo';
    o.tableId = 'foo';
    o.tableProjectId = 'foo';
  }
  buildCounterBigQueryTableSpec--;
  return o;
}

void checkBigQueryTableSpec(api.BigQueryTableSpec o) {
  buildCounterBigQueryTableSpec++;
  if (buildCounterBigQueryTableSpec < 3) {
    unittest.expect(
      o.datasetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableProjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBigQueryTableSpec--;
}

core.List<api.ConditionValue> buildUnnamed669() {
  var o = <api.ConditionValue>[];
  o.add(buildConditionValue());
  o.add(buildConditionValue());
  return o;
}

void checkUnnamed669(core.List<api.ConditionValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConditionValue(o[0] as api.ConditionValue);
  checkConditionValue(o[1] as api.ConditionValue);
}

core.int buildCounterBooleanCondition = 0;
api.BooleanCondition buildBooleanCondition() {
  var o = api.BooleanCondition();
  buildCounterBooleanCondition++;
  if (buildCounterBooleanCondition < 3) {
    o.type = 'foo';
    o.values = buildUnnamed669();
  }
  buildCounterBooleanCondition--;
  return o;
}

void checkBooleanCondition(api.BooleanCondition o) {
  buildCounterBooleanCondition++;
  if (buildCounterBooleanCondition < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkUnnamed669(o.values!);
  }
  buildCounterBooleanCondition--;
}

core.int buildCounterBooleanRule = 0;
api.BooleanRule buildBooleanRule() {
  var o = api.BooleanRule();
  buildCounterBooleanRule++;
  if (buildCounterBooleanRule < 3) {
    o.condition = buildBooleanCondition();
    o.format = buildCellFormat();
  }
  buildCounterBooleanRule--;
  return o;
}

void checkBooleanRule(api.BooleanRule o) {
  buildCounterBooleanRule++;
  if (buildCounterBooleanRule < 3) {
    checkBooleanCondition(o.condition! as api.BooleanCondition);
    checkCellFormat(o.format! as api.CellFormat);
  }
  buildCounterBooleanRule--;
}

core.int buildCounterBorder = 0;
api.Border buildBorder() {
  var o = api.Border();
  buildCounterBorder++;
  if (buildCounterBorder < 3) {
    o.color = buildColor();
    o.colorStyle = buildColorStyle();
    o.style = 'foo';
    o.width = 42;
  }
  buildCounterBorder--;
  return o;
}

void checkBorder(api.Border o) {
  buildCounterBorder++;
  if (buildCounterBorder < 3) {
    checkColor(o.color! as api.Color);
    checkColorStyle(o.colorStyle! as api.ColorStyle);
    unittest.expect(
      o.style!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterBorder--;
}

core.int buildCounterBorders = 0;
api.Borders buildBorders() {
  var o = api.Borders();
  buildCounterBorders++;
  if (buildCounterBorders < 3) {
    o.bottom = buildBorder();
    o.left = buildBorder();
    o.right = buildBorder();
    o.top = buildBorder();
  }
  buildCounterBorders--;
  return o;
}

void checkBorders(api.Borders o) {
  buildCounterBorders++;
  if (buildCounterBorders < 3) {
    checkBorder(o.bottom! as api.Border);
    checkBorder(o.left! as api.Border);
    checkBorder(o.right! as api.Border);
    checkBorder(o.top! as api.Border);
  }
  buildCounterBorders--;
}

core.int buildCounterBubbleChartSpec = 0;
api.BubbleChartSpec buildBubbleChartSpec() {
  var o = api.BubbleChartSpec();
  buildCounterBubbleChartSpec++;
  if (buildCounterBubbleChartSpec < 3) {
    o.bubbleBorderColor = buildColor();
    o.bubbleBorderColorStyle = buildColorStyle();
    o.bubbleLabels = buildChartData();
    o.bubbleMaxRadiusSize = 42;
    o.bubbleMinRadiusSize = 42;
    o.bubbleOpacity = 42.0;
    o.bubbleSizes = buildChartData();
    o.bubbleTextStyle = buildTextFormat();
    o.domain = buildChartData();
    o.groupIds = buildChartData();
    o.legendPosition = 'foo';
    o.series = buildChartData();
  }
  buildCounterBubbleChartSpec--;
  return o;
}

void checkBubbleChartSpec(api.BubbleChartSpec o) {
  buildCounterBubbleChartSpec++;
  if (buildCounterBubbleChartSpec < 3) {
    checkColor(o.bubbleBorderColor! as api.Color);
    checkColorStyle(o.bubbleBorderColorStyle! as api.ColorStyle);
    checkChartData(o.bubbleLabels! as api.ChartData);
    unittest.expect(
      o.bubbleMaxRadiusSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.bubbleMinRadiusSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.bubbleOpacity!,
      unittest.equals(42.0),
    );
    checkChartData(o.bubbleSizes! as api.ChartData);
    checkTextFormat(o.bubbleTextStyle! as api.TextFormat);
    checkChartData(o.domain! as api.ChartData);
    checkChartData(o.groupIds! as api.ChartData);
    unittest.expect(
      o.legendPosition!,
      unittest.equals('foo'),
    );
    checkChartData(o.series! as api.ChartData);
  }
  buildCounterBubbleChartSpec--;
}

core.List<api.CandlestickData> buildUnnamed670() {
  var o = <api.CandlestickData>[];
  o.add(buildCandlestickData());
  o.add(buildCandlestickData());
  return o;
}

void checkUnnamed670(core.List<api.CandlestickData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCandlestickData(o[0] as api.CandlestickData);
  checkCandlestickData(o[1] as api.CandlestickData);
}

core.int buildCounterCandlestickChartSpec = 0;
api.CandlestickChartSpec buildCandlestickChartSpec() {
  var o = api.CandlestickChartSpec();
  buildCounterCandlestickChartSpec++;
  if (buildCounterCandlestickChartSpec < 3) {
    o.data = buildUnnamed670();
    o.domain = buildCandlestickDomain();
  }
  buildCounterCandlestickChartSpec--;
  return o;
}

void checkCandlestickChartSpec(api.CandlestickChartSpec o) {
  buildCounterCandlestickChartSpec++;
  if (buildCounterCandlestickChartSpec < 3) {
    checkUnnamed670(o.data!);
    checkCandlestickDomain(o.domain! as api.CandlestickDomain);
  }
  buildCounterCandlestickChartSpec--;
}

core.int buildCounterCandlestickData = 0;
api.CandlestickData buildCandlestickData() {
  var o = api.CandlestickData();
  buildCounterCandlestickData++;
  if (buildCounterCandlestickData < 3) {
    o.closeSeries = buildCandlestickSeries();
    o.highSeries = buildCandlestickSeries();
    o.lowSeries = buildCandlestickSeries();
    o.openSeries = buildCandlestickSeries();
  }
  buildCounterCandlestickData--;
  return o;
}

void checkCandlestickData(api.CandlestickData o) {
  buildCounterCandlestickData++;
  if (buildCounterCandlestickData < 3) {
    checkCandlestickSeries(o.closeSeries! as api.CandlestickSeries);
    checkCandlestickSeries(o.highSeries! as api.CandlestickSeries);
    checkCandlestickSeries(o.lowSeries! as api.CandlestickSeries);
    checkCandlestickSeries(o.openSeries! as api.CandlestickSeries);
  }
  buildCounterCandlestickData--;
}

core.int buildCounterCandlestickDomain = 0;
api.CandlestickDomain buildCandlestickDomain() {
  var o = api.CandlestickDomain();
  buildCounterCandlestickDomain++;
  if (buildCounterCandlestickDomain < 3) {
    o.data = buildChartData();
    o.reversed = true;
  }
  buildCounterCandlestickDomain--;
  return o;
}

void checkCandlestickDomain(api.CandlestickDomain o) {
  buildCounterCandlestickDomain++;
  if (buildCounterCandlestickDomain < 3) {
    checkChartData(o.data! as api.ChartData);
    unittest.expect(o.reversed!, unittest.isTrue);
  }
  buildCounterCandlestickDomain--;
}

core.int buildCounterCandlestickSeries = 0;
api.CandlestickSeries buildCandlestickSeries() {
  var o = api.CandlestickSeries();
  buildCounterCandlestickSeries++;
  if (buildCounterCandlestickSeries < 3) {
    o.data = buildChartData();
  }
  buildCounterCandlestickSeries--;
  return o;
}

void checkCandlestickSeries(api.CandlestickSeries o) {
  buildCounterCandlestickSeries++;
  if (buildCounterCandlestickSeries < 3) {
    checkChartData(o.data! as api.ChartData);
  }
  buildCounterCandlestickSeries--;
}

core.List<api.TextFormatRun> buildUnnamed671() {
  var o = <api.TextFormatRun>[];
  o.add(buildTextFormatRun());
  o.add(buildTextFormatRun());
  return o;
}

void checkUnnamed671(core.List<api.TextFormatRun> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTextFormatRun(o[0] as api.TextFormatRun);
  checkTextFormatRun(o[1] as api.TextFormatRun);
}

core.int buildCounterCellData = 0;
api.CellData buildCellData() {
  var o = api.CellData();
  buildCounterCellData++;
  if (buildCounterCellData < 3) {
    o.dataSourceFormula = buildDataSourceFormula();
    o.dataSourceTable = buildDataSourceTable();
    o.dataValidation = buildDataValidationRule();
    o.effectiveFormat = buildCellFormat();
    o.effectiveValue = buildExtendedValue();
    o.formattedValue = 'foo';
    o.hyperlink = 'foo';
    o.note = 'foo';
    o.pivotTable = buildPivotTable();
    o.textFormatRuns = buildUnnamed671();
    o.userEnteredFormat = buildCellFormat();
    o.userEnteredValue = buildExtendedValue();
  }
  buildCounterCellData--;
  return o;
}

void checkCellData(api.CellData o) {
  buildCounterCellData++;
  if (buildCounterCellData < 3) {
    checkDataSourceFormula(o.dataSourceFormula! as api.DataSourceFormula);
    checkDataSourceTable(o.dataSourceTable! as api.DataSourceTable);
    checkDataValidationRule(o.dataValidation! as api.DataValidationRule);
    checkCellFormat(o.effectiveFormat! as api.CellFormat);
    checkExtendedValue(o.effectiveValue! as api.ExtendedValue);
    unittest.expect(
      o.formattedValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hyperlink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.note!,
      unittest.equals('foo'),
    );
    checkPivotTable(o.pivotTable! as api.PivotTable);
    checkUnnamed671(o.textFormatRuns!);
    checkCellFormat(o.userEnteredFormat! as api.CellFormat);
    checkExtendedValue(o.userEnteredValue! as api.ExtendedValue);
  }
  buildCounterCellData--;
}

core.int buildCounterCellFormat = 0;
api.CellFormat buildCellFormat() {
  var o = api.CellFormat();
  buildCounterCellFormat++;
  if (buildCounterCellFormat < 3) {
    o.backgroundColor = buildColor();
    o.backgroundColorStyle = buildColorStyle();
    o.borders = buildBorders();
    o.horizontalAlignment = 'foo';
    o.hyperlinkDisplayType = 'foo';
    o.numberFormat = buildNumberFormat();
    o.padding = buildPadding();
    o.textDirection = 'foo';
    o.textFormat = buildTextFormat();
    o.textRotation = buildTextRotation();
    o.verticalAlignment = 'foo';
    o.wrapStrategy = 'foo';
  }
  buildCounterCellFormat--;
  return o;
}

void checkCellFormat(api.CellFormat o) {
  buildCounterCellFormat++;
  if (buildCounterCellFormat < 3) {
    checkColor(o.backgroundColor! as api.Color);
    checkColorStyle(o.backgroundColorStyle! as api.ColorStyle);
    checkBorders(o.borders! as api.Borders);
    unittest.expect(
      o.horizontalAlignment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hyperlinkDisplayType!,
      unittest.equals('foo'),
    );
    checkNumberFormat(o.numberFormat! as api.NumberFormat);
    checkPadding(o.padding! as api.Padding);
    unittest.expect(
      o.textDirection!,
      unittest.equals('foo'),
    );
    checkTextFormat(o.textFormat! as api.TextFormat);
    checkTextRotation(o.textRotation! as api.TextRotation);
    unittest.expect(
      o.verticalAlignment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.wrapStrategy!,
      unittest.equals('foo'),
    );
  }
  buildCounterCellFormat--;
}

core.int buildCounterChartAxisViewWindowOptions = 0;
api.ChartAxisViewWindowOptions buildChartAxisViewWindowOptions() {
  var o = api.ChartAxisViewWindowOptions();
  buildCounterChartAxisViewWindowOptions++;
  if (buildCounterChartAxisViewWindowOptions < 3) {
    o.viewWindowMax = 42.0;
    o.viewWindowMin = 42.0;
    o.viewWindowMode = 'foo';
  }
  buildCounterChartAxisViewWindowOptions--;
  return o;
}

void checkChartAxisViewWindowOptions(api.ChartAxisViewWindowOptions o) {
  buildCounterChartAxisViewWindowOptions++;
  if (buildCounterChartAxisViewWindowOptions < 3) {
    unittest.expect(
      o.viewWindowMax!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.viewWindowMin!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.viewWindowMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterChartAxisViewWindowOptions--;
}

core.int buildCounterChartCustomNumberFormatOptions = 0;
api.ChartCustomNumberFormatOptions buildChartCustomNumberFormatOptions() {
  var o = api.ChartCustomNumberFormatOptions();
  buildCounterChartCustomNumberFormatOptions++;
  if (buildCounterChartCustomNumberFormatOptions < 3) {
    o.prefix = 'foo';
    o.suffix = 'foo';
  }
  buildCounterChartCustomNumberFormatOptions--;
  return o;
}

void checkChartCustomNumberFormatOptions(api.ChartCustomNumberFormatOptions o) {
  buildCounterChartCustomNumberFormatOptions++;
  if (buildCounterChartCustomNumberFormatOptions < 3) {
    unittest.expect(
      o.prefix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.suffix!,
      unittest.equals('foo'),
    );
  }
  buildCounterChartCustomNumberFormatOptions--;
}

core.int buildCounterChartData = 0;
api.ChartData buildChartData() {
  var o = api.ChartData();
  buildCounterChartData++;
  if (buildCounterChartData < 3) {
    o.aggregateType = 'foo';
    o.columnReference = buildDataSourceColumnReference();
    o.groupRule = buildChartGroupRule();
    o.sourceRange = buildChartSourceRange();
  }
  buildCounterChartData--;
  return o;
}

void checkChartData(api.ChartData o) {
  buildCounterChartData++;
  if (buildCounterChartData < 3) {
    unittest.expect(
      o.aggregateType!,
      unittest.equals('foo'),
    );
    checkDataSourceColumnReference(
        o.columnReference! as api.DataSourceColumnReference);
    checkChartGroupRule(o.groupRule! as api.ChartGroupRule);
    checkChartSourceRange(o.sourceRange! as api.ChartSourceRange);
  }
  buildCounterChartData--;
}

core.int buildCounterChartDateTimeRule = 0;
api.ChartDateTimeRule buildChartDateTimeRule() {
  var o = api.ChartDateTimeRule();
  buildCounterChartDateTimeRule++;
  if (buildCounterChartDateTimeRule < 3) {
    o.type = 'foo';
  }
  buildCounterChartDateTimeRule--;
  return o;
}

void checkChartDateTimeRule(api.ChartDateTimeRule o) {
  buildCounterChartDateTimeRule++;
  if (buildCounterChartDateTimeRule < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChartDateTimeRule--;
}

core.int buildCounterChartGroupRule = 0;
api.ChartGroupRule buildChartGroupRule() {
  var o = api.ChartGroupRule();
  buildCounterChartGroupRule++;
  if (buildCounterChartGroupRule < 3) {
    o.dateTimeRule = buildChartDateTimeRule();
    o.histogramRule = buildChartHistogramRule();
  }
  buildCounterChartGroupRule--;
  return o;
}

void checkChartGroupRule(api.ChartGroupRule o) {
  buildCounterChartGroupRule++;
  if (buildCounterChartGroupRule < 3) {
    checkChartDateTimeRule(o.dateTimeRule! as api.ChartDateTimeRule);
    checkChartHistogramRule(o.histogramRule! as api.ChartHistogramRule);
  }
  buildCounterChartGroupRule--;
}

core.int buildCounterChartHistogramRule = 0;
api.ChartHistogramRule buildChartHistogramRule() {
  var o = api.ChartHistogramRule();
  buildCounterChartHistogramRule++;
  if (buildCounterChartHistogramRule < 3) {
    o.intervalSize = 42.0;
    o.maxValue = 42.0;
    o.minValue = 42.0;
  }
  buildCounterChartHistogramRule--;
  return o;
}

void checkChartHistogramRule(api.ChartHistogramRule o) {
  buildCounterChartHistogramRule++;
  if (buildCounterChartHistogramRule < 3) {
    unittest.expect(
      o.intervalSize!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.maxValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.minValue!,
      unittest.equals(42.0),
    );
  }
  buildCounterChartHistogramRule--;
}

core.List<api.GridRange> buildUnnamed672() {
  var o = <api.GridRange>[];
  o.add(buildGridRange());
  o.add(buildGridRange());
  return o;
}

void checkUnnamed672(core.List<api.GridRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGridRange(o[0] as api.GridRange);
  checkGridRange(o[1] as api.GridRange);
}

core.int buildCounterChartSourceRange = 0;
api.ChartSourceRange buildChartSourceRange() {
  var o = api.ChartSourceRange();
  buildCounterChartSourceRange++;
  if (buildCounterChartSourceRange < 3) {
    o.sources = buildUnnamed672();
  }
  buildCounterChartSourceRange--;
  return o;
}

void checkChartSourceRange(api.ChartSourceRange o) {
  buildCounterChartSourceRange++;
  if (buildCounterChartSourceRange < 3) {
    checkUnnamed672(o.sources!);
  }
  buildCounterChartSourceRange--;
}

core.List<api.FilterSpec> buildUnnamed673() {
  var o = <api.FilterSpec>[];
  o.add(buildFilterSpec());
  o.add(buildFilterSpec());
  return o;
}

void checkUnnamed673(core.List<api.FilterSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterSpec(o[0] as api.FilterSpec);
  checkFilterSpec(o[1] as api.FilterSpec);
}

core.List<api.SortSpec> buildUnnamed674() {
  var o = <api.SortSpec>[];
  o.add(buildSortSpec());
  o.add(buildSortSpec());
  return o;
}

void checkUnnamed674(core.List<api.SortSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSortSpec(o[0] as api.SortSpec);
  checkSortSpec(o[1] as api.SortSpec);
}

core.int buildCounterChartSpec = 0;
api.ChartSpec buildChartSpec() {
  var o = api.ChartSpec();
  buildCounterChartSpec++;
  if (buildCounterChartSpec < 3) {
    o.altText = 'foo';
    o.backgroundColor = buildColor();
    o.backgroundColorStyle = buildColorStyle();
    o.basicChart = buildBasicChartSpec();
    o.bubbleChart = buildBubbleChartSpec();
    o.candlestickChart = buildCandlestickChartSpec();
    o.dataSourceChartProperties = buildDataSourceChartProperties();
    o.filterSpecs = buildUnnamed673();
    o.fontName = 'foo';
    o.hiddenDimensionStrategy = 'foo';
    o.histogramChart = buildHistogramChartSpec();
    o.maximized = true;
    o.orgChart = buildOrgChartSpec();
    o.pieChart = buildPieChartSpec();
    o.scorecardChart = buildScorecardChartSpec();
    o.sortSpecs = buildUnnamed674();
    o.subtitle = 'foo';
    o.subtitleTextFormat = buildTextFormat();
    o.subtitleTextPosition = buildTextPosition();
    o.title = 'foo';
    o.titleTextFormat = buildTextFormat();
    o.titleTextPosition = buildTextPosition();
    o.treemapChart = buildTreemapChartSpec();
    o.waterfallChart = buildWaterfallChartSpec();
  }
  buildCounterChartSpec--;
  return o;
}

void checkChartSpec(api.ChartSpec o) {
  buildCounterChartSpec++;
  if (buildCounterChartSpec < 3) {
    unittest.expect(
      o.altText!,
      unittest.equals('foo'),
    );
    checkColor(o.backgroundColor! as api.Color);
    checkColorStyle(o.backgroundColorStyle! as api.ColorStyle);
    checkBasicChartSpec(o.basicChart! as api.BasicChartSpec);
    checkBubbleChartSpec(o.bubbleChart! as api.BubbleChartSpec);
    checkCandlestickChartSpec(o.candlestickChart! as api.CandlestickChartSpec);
    checkDataSourceChartProperties(
        o.dataSourceChartProperties! as api.DataSourceChartProperties);
    checkUnnamed673(o.filterSpecs!);
    unittest.expect(
      o.fontName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hiddenDimensionStrategy!,
      unittest.equals('foo'),
    );
    checkHistogramChartSpec(o.histogramChart! as api.HistogramChartSpec);
    unittest.expect(o.maximized!, unittest.isTrue);
    checkOrgChartSpec(o.orgChart! as api.OrgChartSpec);
    checkPieChartSpec(o.pieChart! as api.PieChartSpec);
    checkScorecardChartSpec(o.scorecardChart! as api.ScorecardChartSpec);
    checkUnnamed674(o.sortSpecs!);
    unittest.expect(
      o.subtitle!,
      unittest.equals('foo'),
    );
    checkTextFormat(o.subtitleTextFormat! as api.TextFormat);
    checkTextPosition(o.subtitleTextPosition! as api.TextPosition);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    checkTextFormat(o.titleTextFormat! as api.TextFormat);
    checkTextPosition(o.titleTextPosition! as api.TextPosition);
    checkTreemapChartSpec(o.treemapChart! as api.TreemapChartSpec);
    checkWaterfallChartSpec(o.waterfallChart! as api.WaterfallChartSpec);
  }
  buildCounterChartSpec--;
}

core.int buildCounterClearBasicFilterRequest = 0;
api.ClearBasicFilterRequest buildClearBasicFilterRequest() {
  var o = api.ClearBasicFilterRequest();
  buildCounterClearBasicFilterRequest++;
  if (buildCounterClearBasicFilterRequest < 3) {
    o.sheetId = 42;
  }
  buildCounterClearBasicFilterRequest--;
  return o;
}

void checkClearBasicFilterRequest(api.ClearBasicFilterRequest o) {
  buildCounterClearBasicFilterRequest++;
  if (buildCounterClearBasicFilterRequest < 3) {
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterClearBasicFilterRequest--;
}

core.int buildCounterClearValuesRequest = 0;
api.ClearValuesRequest buildClearValuesRequest() {
  var o = api.ClearValuesRequest();
  buildCounterClearValuesRequest++;
  if (buildCounterClearValuesRequest < 3) {}
  buildCounterClearValuesRequest--;
  return o;
}

void checkClearValuesRequest(api.ClearValuesRequest o) {
  buildCounterClearValuesRequest++;
  if (buildCounterClearValuesRequest < 3) {}
  buildCounterClearValuesRequest--;
}

core.int buildCounterClearValuesResponse = 0;
api.ClearValuesResponse buildClearValuesResponse() {
  var o = api.ClearValuesResponse();
  buildCounterClearValuesResponse++;
  if (buildCounterClearValuesResponse < 3) {
    o.clearedRange = 'foo';
    o.spreadsheetId = 'foo';
  }
  buildCounterClearValuesResponse--;
  return o;
}

void checkClearValuesResponse(api.ClearValuesResponse o) {
  buildCounterClearValuesResponse++;
  if (buildCounterClearValuesResponse < 3) {
    unittest.expect(
      o.clearedRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterClearValuesResponse--;
}

core.int buildCounterColor = 0;
api.Color buildColor() {
  var o = api.Color();
  buildCounterColor++;
  if (buildCounterColor < 3) {
    o.alpha = 42.0;
    o.blue = 42.0;
    o.green = 42.0;
    o.red = 42.0;
  }
  buildCounterColor--;
  return o;
}

void checkColor(api.Color o) {
  buildCounterColor++;
  if (buildCounterColor < 3) {
    unittest.expect(
      o.alpha!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.blue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.green!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.red!,
      unittest.equals(42.0),
    );
  }
  buildCounterColor--;
}

core.int buildCounterColorStyle = 0;
api.ColorStyle buildColorStyle() {
  var o = api.ColorStyle();
  buildCounterColorStyle++;
  if (buildCounterColorStyle < 3) {
    o.rgbColor = buildColor();
    o.themeColor = 'foo';
  }
  buildCounterColorStyle--;
  return o;
}

void checkColorStyle(api.ColorStyle o) {
  buildCounterColorStyle++;
  if (buildCounterColorStyle < 3) {
    checkColor(o.rgbColor! as api.Color);
    unittest.expect(
      o.themeColor!,
      unittest.equals('foo'),
    );
  }
  buildCounterColorStyle--;
}

core.int buildCounterConditionValue = 0;
api.ConditionValue buildConditionValue() {
  var o = api.ConditionValue();
  buildCounterConditionValue++;
  if (buildCounterConditionValue < 3) {
    o.relativeDate = 'foo';
    o.userEnteredValue = 'foo';
  }
  buildCounterConditionValue--;
  return o;
}

void checkConditionValue(api.ConditionValue o) {
  buildCounterConditionValue++;
  if (buildCounterConditionValue < 3) {
    unittest.expect(
      o.relativeDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userEnteredValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterConditionValue--;
}

core.List<api.GridRange> buildUnnamed675() {
  var o = <api.GridRange>[];
  o.add(buildGridRange());
  o.add(buildGridRange());
  return o;
}

void checkUnnamed675(core.List<api.GridRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGridRange(o[0] as api.GridRange);
  checkGridRange(o[1] as api.GridRange);
}

core.int buildCounterConditionalFormatRule = 0;
api.ConditionalFormatRule buildConditionalFormatRule() {
  var o = api.ConditionalFormatRule();
  buildCounterConditionalFormatRule++;
  if (buildCounterConditionalFormatRule < 3) {
    o.booleanRule = buildBooleanRule();
    o.gradientRule = buildGradientRule();
    o.ranges = buildUnnamed675();
  }
  buildCounterConditionalFormatRule--;
  return o;
}

void checkConditionalFormatRule(api.ConditionalFormatRule o) {
  buildCounterConditionalFormatRule++;
  if (buildCounterConditionalFormatRule < 3) {
    checkBooleanRule(o.booleanRule! as api.BooleanRule);
    checkGradientRule(o.gradientRule! as api.GradientRule);
    checkUnnamed675(o.ranges!);
  }
  buildCounterConditionalFormatRule--;
}

core.int buildCounterCopyPasteRequest = 0;
api.CopyPasteRequest buildCopyPasteRequest() {
  var o = api.CopyPasteRequest();
  buildCounterCopyPasteRequest++;
  if (buildCounterCopyPasteRequest < 3) {
    o.destination = buildGridRange();
    o.pasteOrientation = 'foo';
    o.pasteType = 'foo';
    o.source = buildGridRange();
  }
  buildCounterCopyPasteRequest--;
  return o;
}

void checkCopyPasteRequest(api.CopyPasteRequest o) {
  buildCounterCopyPasteRequest++;
  if (buildCounterCopyPasteRequest < 3) {
    checkGridRange(o.destination! as api.GridRange);
    unittest.expect(
      o.pasteOrientation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pasteType!,
      unittest.equals('foo'),
    );
    checkGridRange(o.source! as api.GridRange);
  }
  buildCounterCopyPasteRequest--;
}

core.int buildCounterCopySheetToAnotherSpreadsheetRequest = 0;
api.CopySheetToAnotherSpreadsheetRequest
    buildCopySheetToAnotherSpreadsheetRequest() {
  var o = api.CopySheetToAnotherSpreadsheetRequest();
  buildCounterCopySheetToAnotherSpreadsheetRequest++;
  if (buildCounterCopySheetToAnotherSpreadsheetRequest < 3) {
    o.destinationSpreadsheetId = 'foo';
  }
  buildCounterCopySheetToAnotherSpreadsheetRequest--;
  return o;
}

void checkCopySheetToAnotherSpreadsheetRequest(
    api.CopySheetToAnotherSpreadsheetRequest o) {
  buildCounterCopySheetToAnotherSpreadsheetRequest++;
  if (buildCounterCopySheetToAnotherSpreadsheetRequest < 3) {
    unittest.expect(
      o.destinationSpreadsheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCopySheetToAnotherSpreadsheetRequest--;
}

core.int buildCounterCreateDeveloperMetadataRequest = 0;
api.CreateDeveloperMetadataRequest buildCreateDeveloperMetadataRequest() {
  var o = api.CreateDeveloperMetadataRequest();
  buildCounterCreateDeveloperMetadataRequest++;
  if (buildCounterCreateDeveloperMetadataRequest < 3) {
    o.developerMetadata = buildDeveloperMetadata();
  }
  buildCounterCreateDeveloperMetadataRequest--;
  return o;
}

void checkCreateDeveloperMetadataRequest(api.CreateDeveloperMetadataRequest o) {
  buildCounterCreateDeveloperMetadataRequest++;
  if (buildCounterCreateDeveloperMetadataRequest < 3) {
    checkDeveloperMetadata(o.developerMetadata! as api.DeveloperMetadata);
  }
  buildCounterCreateDeveloperMetadataRequest--;
}

core.int buildCounterCreateDeveloperMetadataResponse = 0;
api.CreateDeveloperMetadataResponse buildCreateDeveloperMetadataResponse() {
  var o = api.CreateDeveloperMetadataResponse();
  buildCounterCreateDeveloperMetadataResponse++;
  if (buildCounterCreateDeveloperMetadataResponse < 3) {
    o.developerMetadata = buildDeveloperMetadata();
  }
  buildCounterCreateDeveloperMetadataResponse--;
  return o;
}

void checkCreateDeveloperMetadataResponse(
    api.CreateDeveloperMetadataResponse o) {
  buildCounterCreateDeveloperMetadataResponse++;
  if (buildCounterCreateDeveloperMetadataResponse < 3) {
    checkDeveloperMetadata(o.developerMetadata! as api.DeveloperMetadata);
  }
  buildCounterCreateDeveloperMetadataResponse--;
}

core.int buildCounterCutPasteRequest = 0;
api.CutPasteRequest buildCutPasteRequest() {
  var o = api.CutPasteRequest();
  buildCounterCutPasteRequest++;
  if (buildCounterCutPasteRequest < 3) {
    o.destination = buildGridCoordinate();
    o.pasteType = 'foo';
    o.source = buildGridRange();
  }
  buildCounterCutPasteRequest--;
  return o;
}

void checkCutPasteRequest(api.CutPasteRequest o) {
  buildCounterCutPasteRequest++;
  if (buildCounterCutPasteRequest < 3) {
    checkGridCoordinate(o.destination! as api.GridCoordinate);
    unittest.expect(
      o.pasteType!,
      unittest.equals('foo'),
    );
    checkGridRange(o.source! as api.GridRange);
  }
  buildCounterCutPasteRequest--;
}

core.int buildCounterDataExecutionStatus = 0;
api.DataExecutionStatus buildDataExecutionStatus() {
  var o = api.DataExecutionStatus();
  buildCounterDataExecutionStatus++;
  if (buildCounterDataExecutionStatus < 3) {
    o.errorCode = 'foo';
    o.errorMessage = 'foo';
    o.lastRefreshTime = 'foo';
    o.state = 'foo';
  }
  buildCounterDataExecutionStatus--;
  return o;
}

void checkDataExecutionStatus(api.DataExecutionStatus o) {
  buildCounterDataExecutionStatus++;
  if (buildCounterDataExecutionStatus < 3) {
    unittest.expect(
      o.errorCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastRefreshTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataExecutionStatus--;
}

core.int buildCounterDataFilter = 0;
api.DataFilter buildDataFilter() {
  var o = api.DataFilter();
  buildCounterDataFilter++;
  if (buildCounterDataFilter < 3) {
    o.a1Range = 'foo';
    o.developerMetadataLookup = buildDeveloperMetadataLookup();
    o.gridRange = buildGridRange();
  }
  buildCounterDataFilter--;
  return o;
}

void checkDataFilter(api.DataFilter o) {
  buildCounterDataFilter++;
  if (buildCounterDataFilter < 3) {
    unittest.expect(
      o.a1Range!,
      unittest.equals('foo'),
    );
    checkDeveloperMetadataLookup(
        o.developerMetadataLookup! as api.DeveloperMetadataLookup);
    checkGridRange(o.gridRange! as api.GridRange);
  }
  buildCounterDataFilter--;
}

core.List<core.Object> buildUnnamed676() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed676(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o[0]) as core.Map;
  unittest.expect(casted1, unittest.hasLength(3));
  unittest.expect(
    casted1['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted1['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted1['string'],
    unittest.equals('foo'),
  );
  var casted2 = (o[1]) as core.Map;
  unittest.expect(casted2, unittest.hasLength(3));
  unittest.expect(
    casted2['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted2['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted2['string'],
    unittest.equals('foo'),
  );
}

core.List<core.List<core.Object>> buildUnnamed677() {
  var o = <core.List<core.Object>>[];
  o.add(buildUnnamed676());
  o.add(buildUnnamed676());
  return o;
}

void checkUnnamed677(core.List<core.List<core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed676(o[0]);
  checkUnnamed676(o[1]);
}

core.int buildCounterDataFilterValueRange = 0;
api.DataFilterValueRange buildDataFilterValueRange() {
  var o = api.DataFilterValueRange();
  buildCounterDataFilterValueRange++;
  if (buildCounterDataFilterValueRange < 3) {
    o.dataFilter = buildDataFilter();
    o.majorDimension = 'foo';
    o.values = buildUnnamed677();
  }
  buildCounterDataFilterValueRange--;
  return o;
}

void checkDataFilterValueRange(api.DataFilterValueRange o) {
  buildCounterDataFilterValueRange++;
  if (buildCounterDataFilterValueRange < 3) {
    checkDataFilter(o.dataFilter! as api.DataFilter);
    unittest.expect(
      o.majorDimension!,
      unittest.equals('foo'),
    );
    checkUnnamed677(o.values!);
  }
  buildCounterDataFilterValueRange--;
}

core.int buildCounterDataLabel = 0;
api.DataLabel buildDataLabel() {
  var o = api.DataLabel();
  buildCounterDataLabel++;
  if (buildCounterDataLabel < 3) {
    o.customLabelData = buildChartData();
    o.placement = 'foo';
    o.textFormat = buildTextFormat();
    o.type = 'foo';
  }
  buildCounterDataLabel--;
  return o;
}

void checkDataLabel(api.DataLabel o) {
  buildCounterDataLabel++;
  if (buildCounterDataLabel < 3) {
    checkChartData(o.customLabelData! as api.ChartData);
    unittest.expect(
      o.placement!,
      unittest.equals('foo'),
    );
    checkTextFormat(o.textFormat! as api.TextFormat);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataLabel--;
}

core.List<api.DataSourceColumn> buildUnnamed678() {
  var o = <api.DataSourceColumn>[];
  o.add(buildDataSourceColumn());
  o.add(buildDataSourceColumn());
  return o;
}

void checkUnnamed678(core.List<api.DataSourceColumn> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceColumn(o[0] as api.DataSourceColumn);
  checkDataSourceColumn(o[1] as api.DataSourceColumn);
}

core.int buildCounterDataSource = 0;
api.DataSource buildDataSource() {
  var o = api.DataSource();
  buildCounterDataSource++;
  if (buildCounterDataSource < 3) {
    o.calculatedColumns = buildUnnamed678();
    o.dataSourceId = 'foo';
    o.sheetId = 42;
    o.spec = buildDataSourceSpec();
  }
  buildCounterDataSource--;
  return o;
}

void checkDataSource(api.DataSource o) {
  buildCounterDataSource++;
  if (buildCounterDataSource < 3) {
    checkUnnamed678(o.calculatedColumns!);
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
    checkDataSourceSpec(o.spec! as api.DataSourceSpec);
  }
  buildCounterDataSource--;
}

core.int buildCounterDataSourceChartProperties = 0;
api.DataSourceChartProperties buildDataSourceChartProperties() {
  var o = api.DataSourceChartProperties();
  buildCounterDataSourceChartProperties++;
  if (buildCounterDataSourceChartProperties < 3) {
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.dataSourceId = 'foo';
  }
  buildCounterDataSourceChartProperties--;
  return o;
}

void checkDataSourceChartProperties(api.DataSourceChartProperties o) {
  buildCounterDataSourceChartProperties++;
  if (buildCounterDataSourceChartProperties < 3) {
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataSourceChartProperties--;
}

core.int buildCounterDataSourceColumn = 0;
api.DataSourceColumn buildDataSourceColumn() {
  var o = api.DataSourceColumn();
  buildCounterDataSourceColumn++;
  if (buildCounterDataSourceColumn < 3) {
    o.formula = 'foo';
    o.reference = buildDataSourceColumnReference();
  }
  buildCounterDataSourceColumn--;
  return o;
}

void checkDataSourceColumn(api.DataSourceColumn o) {
  buildCounterDataSourceColumn++;
  if (buildCounterDataSourceColumn < 3) {
    unittest.expect(
      o.formula!,
      unittest.equals('foo'),
    );
    checkDataSourceColumnReference(
        o.reference! as api.DataSourceColumnReference);
  }
  buildCounterDataSourceColumn--;
}

core.int buildCounterDataSourceColumnReference = 0;
api.DataSourceColumnReference buildDataSourceColumnReference() {
  var o = api.DataSourceColumnReference();
  buildCounterDataSourceColumnReference++;
  if (buildCounterDataSourceColumnReference < 3) {
    o.name = 'foo';
  }
  buildCounterDataSourceColumnReference--;
  return o;
}

void checkDataSourceColumnReference(api.DataSourceColumnReference o) {
  buildCounterDataSourceColumnReference++;
  if (buildCounterDataSourceColumnReference < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataSourceColumnReference--;
}

core.int buildCounterDataSourceFormula = 0;
api.DataSourceFormula buildDataSourceFormula() {
  var o = api.DataSourceFormula();
  buildCounterDataSourceFormula++;
  if (buildCounterDataSourceFormula < 3) {
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.dataSourceId = 'foo';
  }
  buildCounterDataSourceFormula--;
  return o;
}

void checkDataSourceFormula(api.DataSourceFormula o) {
  buildCounterDataSourceFormula++;
  if (buildCounterDataSourceFormula < 3) {
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataSourceFormula--;
}

core.int buildCounterDataSourceObjectReference = 0;
api.DataSourceObjectReference buildDataSourceObjectReference() {
  var o = api.DataSourceObjectReference();
  buildCounterDataSourceObjectReference++;
  if (buildCounterDataSourceObjectReference < 3) {
    o.chartId = 42;
    o.dataSourceFormulaCell = buildGridCoordinate();
    o.dataSourcePivotTableAnchorCell = buildGridCoordinate();
    o.dataSourceTableAnchorCell = buildGridCoordinate();
    o.sheetId = 'foo';
  }
  buildCounterDataSourceObjectReference--;
  return o;
}

void checkDataSourceObjectReference(api.DataSourceObjectReference o) {
  buildCounterDataSourceObjectReference++;
  if (buildCounterDataSourceObjectReference < 3) {
    unittest.expect(
      o.chartId!,
      unittest.equals(42),
    );
    checkGridCoordinate(o.dataSourceFormulaCell! as api.GridCoordinate);
    checkGridCoordinate(
        o.dataSourcePivotTableAnchorCell! as api.GridCoordinate);
    checkGridCoordinate(o.dataSourceTableAnchorCell! as api.GridCoordinate);
    unittest.expect(
      o.sheetId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataSourceObjectReference--;
}

core.List<api.DataSourceObjectReference> buildUnnamed679() {
  var o = <api.DataSourceObjectReference>[];
  o.add(buildDataSourceObjectReference());
  o.add(buildDataSourceObjectReference());
  return o;
}

void checkUnnamed679(core.List<api.DataSourceObjectReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceObjectReference(o[0] as api.DataSourceObjectReference);
  checkDataSourceObjectReference(o[1] as api.DataSourceObjectReference);
}

core.int buildCounterDataSourceObjectReferences = 0;
api.DataSourceObjectReferences buildDataSourceObjectReferences() {
  var o = api.DataSourceObjectReferences();
  buildCounterDataSourceObjectReferences++;
  if (buildCounterDataSourceObjectReferences < 3) {
    o.references = buildUnnamed679();
  }
  buildCounterDataSourceObjectReferences--;
  return o;
}

void checkDataSourceObjectReferences(api.DataSourceObjectReferences o) {
  buildCounterDataSourceObjectReferences++;
  if (buildCounterDataSourceObjectReferences < 3) {
    checkUnnamed679(o.references!);
  }
  buildCounterDataSourceObjectReferences--;
}

core.int buildCounterDataSourceParameter = 0;
api.DataSourceParameter buildDataSourceParameter() {
  var o = api.DataSourceParameter();
  buildCounterDataSourceParameter++;
  if (buildCounterDataSourceParameter < 3) {
    o.name = 'foo';
    o.namedRangeId = 'foo';
    o.range = buildGridRange();
  }
  buildCounterDataSourceParameter--;
  return o;
}

void checkDataSourceParameter(api.DataSourceParameter o) {
  buildCounterDataSourceParameter++;
  if (buildCounterDataSourceParameter < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.namedRangeId!,
      unittest.equals('foo'),
    );
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterDataSourceParameter--;
}

core.int buildCounterDataSourceRefreshDailySchedule = 0;
api.DataSourceRefreshDailySchedule buildDataSourceRefreshDailySchedule() {
  var o = api.DataSourceRefreshDailySchedule();
  buildCounterDataSourceRefreshDailySchedule++;
  if (buildCounterDataSourceRefreshDailySchedule < 3) {
    o.startTime = buildTimeOfDay();
  }
  buildCounterDataSourceRefreshDailySchedule--;
  return o;
}

void checkDataSourceRefreshDailySchedule(api.DataSourceRefreshDailySchedule o) {
  buildCounterDataSourceRefreshDailySchedule++;
  if (buildCounterDataSourceRefreshDailySchedule < 3) {
    checkTimeOfDay(o.startTime! as api.TimeOfDay);
  }
  buildCounterDataSourceRefreshDailySchedule--;
}

core.List<core.int> buildUnnamed680() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed680(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterDataSourceRefreshMonthlySchedule = 0;
api.DataSourceRefreshMonthlySchedule buildDataSourceRefreshMonthlySchedule() {
  var o = api.DataSourceRefreshMonthlySchedule();
  buildCounterDataSourceRefreshMonthlySchedule++;
  if (buildCounterDataSourceRefreshMonthlySchedule < 3) {
    o.daysOfMonth = buildUnnamed680();
    o.startTime = buildTimeOfDay();
  }
  buildCounterDataSourceRefreshMonthlySchedule--;
  return o;
}

void checkDataSourceRefreshMonthlySchedule(
    api.DataSourceRefreshMonthlySchedule o) {
  buildCounterDataSourceRefreshMonthlySchedule++;
  if (buildCounterDataSourceRefreshMonthlySchedule < 3) {
    checkUnnamed680(o.daysOfMonth!);
    checkTimeOfDay(o.startTime! as api.TimeOfDay);
  }
  buildCounterDataSourceRefreshMonthlySchedule--;
}

core.int buildCounterDataSourceRefreshSchedule = 0;
api.DataSourceRefreshSchedule buildDataSourceRefreshSchedule() {
  var o = api.DataSourceRefreshSchedule();
  buildCounterDataSourceRefreshSchedule++;
  if (buildCounterDataSourceRefreshSchedule < 3) {
    o.dailySchedule = buildDataSourceRefreshDailySchedule();
    o.enabled = true;
    o.monthlySchedule = buildDataSourceRefreshMonthlySchedule();
    o.nextRun = buildInterval();
    o.refreshScope = 'foo';
    o.weeklySchedule = buildDataSourceRefreshWeeklySchedule();
  }
  buildCounterDataSourceRefreshSchedule--;
  return o;
}

void checkDataSourceRefreshSchedule(api.DataSourceRefreshSchedule o) {
  buildCounterDataSourceRefreshSchedule++;
  if (buildCounterDataSourceRefreshSchedule < 3) {
    checkDataSourceRefreshDailySchedule(
        o.dailySchedule! as api.DataSourceRefreshDailySchedule);
    unittest.expect(o.enabled!, unittest.isTrue);
    checkDataSourceRefreshMonthlySchedule(
        o.monthlySchedule! as api.DataSourceRefreshMonthlySchedule);
    checkInterval(o.nextRun! as api.Interval);
    unittest.expect(
      o.refreshScope!,
      unittest.equals('foo'),
    );
    checkDataSourceRefreshWeeklySchedule(
        o.weeklySchedule! as api.DataSourceRefreshWeeklySchedule);
  }
  buildCounterDataSourceRefreshSchedule--;
}

core.List<core.String> buildUnnamed681() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed681(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterDataSourceRefreshWeeklySchedule = 0;
api.DataSourceRefreshWeeklySchedule buildDataSourceRefreshWeeklySchedule() {
  var o = api.DataSourceRefreshWeeklySchedule();
  buildCounterDataSourceRefreshWeeklySchedule++;
  if (buildCounterDataSourceRefreshWeeklySchedule < 3) {
    o.daysOfWeek = buildUnnamed681();
    o.startTime = buildTimeOfDay();
  }
  buildCounterDataSourceRefreshWeeklySchedule--;
  return o;
}

void checkDataSourceRefreshWeeklySchedule(
    api.DataSourceRefreshWeeklySchedule o) {
  buildCounterDataSourceRefreshWeeklySchedule++;
  if (buildCounterDataSourceRefreshWeeklySchedule < 3) {
    checkUnnamed681(o.daysOfWeek!);
    checkTimeOfDay(o.startTime! as api.TimeOfDay);
  }
  buildCounterDataSourceRefreshWeeklySchedule--;
}

core.List<api.DataSourceColumnReference> buildUnnamed682() {
  var o = <api.DataSourceColumnReference>[];
  o.add(buildDataSourceColumnReference());
  o.add(buildDataSourceColumnReference());
  return o;
}

void checkUnnamed682(core.List<api.DataSourceColumnReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceColumnReference(o[0] as api.DataSourceColumnReference);
  checkDataSourceColumnReference(o[1] as api.DataSourceColumnReference);
}

core.int buildCounterDataSourceSheetDimensionRange = 0;
api.DataSourceSheetDimensionRange buildDataSourceSheetDimensionRange() {
  var o = api.DataSourceSheetDimensionRange();
  buildCounterDataSourceSheetDimensionRange++;
  if (buildCounterDataSourceSheetDimensionRange < 3) {
    o.columnReferences = buildUnnamed682();
    o.sheetId = 42;
  }
  buildCounterDataSourceSheetDimensionRange--;
  return o;
}

void checkDataSourceSheetDimensionRange(api.DataSourceSheetDimensionRange o) {
  buildCounterDataSourceSheetDimensionRange++;
  if (buildCounterDataSourceSheetDimensionRange < 3) {
    checkUnnamed682(o.columnReferences!);
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterDataSourceSheetDimensionRange--;
}

core.List<api.DataSourceColumn> buildUnnamed683() {
  var o = <api.DataSourceColumn>[];
  o.add(buildDataSourceColumn());
  o.add(buildDataSourceColumn());
  return o;
}

void checkUnnamed683(core.List<api.DataSourceColumn> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceColumn(o[0] as api.DataSourceColumn);
  checkDataSourceColumn(o[1] as api.DataSourceColumn);
}

core.int buildCounterDataSourceSheetProperties = 0;
api.DataSourceSheetProperties buildDataSourceSheetProperties() {
  var o = api.DataSourceSheetProperties();
  buildCounterDataSourceSheetProperties++;
  if (buildCounterDataSourceSheetProperties < 3) {
    o.columns = buildUnnamed683();
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.dataSourceId = 'foo';
  }
  buildCounterDataSourceSheetProperties--;
  return o;
}

void checkDataSourceSheetProperties(api.DataSourceSheetProperties o) {
  buildCounterDataSourceSheetProperties++;
  if (buildCounterDataSourceSheetProperties < 3) {
    checkUnnamed683(o.columns!);
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataSourceSheetProperties--;
}

core.List<api.DataSourceParameter> buildUnnamed684() {
  var o = <api.DataSourceParameter>[];
  o.add(buildDataSourceParameter());
  o.add(buildDataSourceParameter());
  return o;
}

void checkUnnamed684(core.List<api.DataSourceParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceParameter(o[0] as api.DataSourceParameter);
  checkDataSourceParameter(o[1] as api.DataSourceParameter);
}

core.int buildCounterDataSourceSpec = 0;
api.DataSourceSpec buildDataSourceSpec() {
  var o = api.DataSourceSpec();
  buildCounterDataSourceSpec++;
  if (buildCounterDataSourceSpec < 3) {
    o.bigQuery = buildBigQueryDataSourceSpec();
    o.parameters = buildUnnamed684();
  }
  buildCounterDataSourceSpec--;
  return o;
}

void checkDataSourceSpec(api.DataSourceSpec o) {
  buildCounterDataSourceSpec++;
  if (buildCounterDataSourceSpec < 3) {
    checkBigQueryDataSourceSpec(o.bigQuery! as api.BigQueryDataSourceSpec);
    checkUnnamed684(o.parameters!);
  }
  buildCounterDataSourceSpec--;
}

core.List<api.DataSourceColumnReference> buildUnnamed685() {
  var o = <api.DataSourceColumnReference>[];
  o.add(buildDataSourceColumnReference());
  o.add(buildDataSourceColumnReference());
  return o;
}

void checkUnnamed685(core.List<api.DataSourceColumnReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceColumnReference(o[0] as api.DataSourceColumnReference);
  checkDataSourceColumnReference(o[1] as api.DataSourceColumnReference);
}

core.List<api.FilterSpec> buildUnnamed686() {
  var o = <api.FilterSpec>[];
  o.add(buildFilterSpec());
  o.add(buildFilterSpec());
  return o;
}

void checkUnnamed686(core.List<api.FilterSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterSpec(o[0] as api.FilterSpec);
  checkFilterSpec(o[1] as api.FilterSpec);
}

core.List<api.SortSpec> buildUnnamed687() {
  var o = <api.SortSpec>[];
  o.add(buildSortSpec());
  o.add(buildSortSpec());
  return o;
}

void checkUnnamed687(core.List<api.SortSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSortSpec(o[0] as api.SortSpec);
  checkSortSpec(o[1] as api.SortSpec);
}

core.int buildCounterDataSourceTable = 0;
api.DataSourceTable buildDataSourceTable() {
  var o = api.DataSourceTable();
  buildCounterDataSourceTable++;
  if (buildCounterDataSourceTable < 3) {
    o.columnSelectionType = 'foo';
    o.columns = buildUnnamed685();
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.dataSourceId = 'foo';
    o.filterSpecs = buildUnnamed686();
    o.rowLimit = 42;
    o.sortSpecs = buildUnnamed687();
  }
  buildCounterDataSourceTable--;
  return o;
}

void checkDataSourceTable(api.DataSourceTable o) {
  buildCounterDataSourceTable++;
  if (buildCounterDataSourceTable < 3) {
    unittest.expect(
      o.columnSelectionType!,
      unittest.equals('foo'),
    );
    checkUnnamed685(o.columns!);
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
    checkUnnamed686(o.filterSpecs!);
    unittest.expect(
      o.rowLimit!,
      unittest.equals(42),
    );
    checkUnnamed687(o.sortSpecs!);
  }
  buildCounterDataSourceTable--;
}

core.int buildCounterDataValidationRule = 0;
api.DataValidationRule buildDataValidationRule() {
  var o = api.DataValidationRule();
  buildCounterDataValidationRule++;
  if (buildCounterDataValidationRule < 3) {
    o.condition = buildBooleanCondition();
    o.inputMessage = 'foo';
    o.showCustomUi = true;
    o.strict = true;
  }
  buildCounterDataValidationRule--;
  return o;
}

void checkDataValidationRule(api.DataValidationRule o) {
  buildCounterDataValidationRule++;
  if (buildCounterDataValidationRule < 3) {
    checkBooleanCondition(o.condition! as api.BooleanCondition);
    unittest.expect(
      o.inputMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(o.showCustomUi!, unittest.isTrue);
    unittest.expect(o.strict!, unittest.isTrue);
  }
  buildCounterDataValidationRule--;
}

core.int buildCounterDateTimeRule = 0;
api.DateTimeRule buildDateTimeRule() {
  var o = api.DateTimeRule();
  buildCounterDateTimeRule++;
  if (buildCounterDateTimeRule < 3) {
    o.type = 'foo';
  }
  buildCounterDateTimeRule--;
  return o;
}

void checkDateTimeRule(api.DateTimeRule o) {
  buildCounterDateTimeRule++;
  if (buildCounterDateTimeRule < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDateTimeRule--;
}

core.int buildCounterDeleteBandingRequest = 0;
api.DeleteBandingRequest buildDeleteBandingRequest() {
  var o = api.DeleteBandingRequest();
  buildCounterDeleteBandingRequest++;
  if (buildCounterDeleteBandingRequest < 3) {
    o.bandedRangeId = 42;
  }
  buildCounterDeleteBandingRequest--;
  return o;
}

void checkDeleteBandingRequest(api.DeleteBandingRequest o) {
  buildCounterDeleteBandingRequest++;
  if (buildCounterDeleteBandingRequest < 3) {
    unittest.expect(
      o.bandedRangeId!,
      unittest.equals(42),
    );
  }
  buildCounterDeleteBandingRequest--;
}

core.int buildCounterDeleteConditionalFormatRuleRequest = 0;
api.DeleteConditionalFormatRuleRequest
    buildDeleteConditionalFormatRuleRequest() {
  var o = api.DeleteConditionalFormatRuleRequest();
  buildCounterDeleteConditionalFormatRuleRequest++;
  if (buildCounterDeleteConditionalFormatRuleRequest < 3) {
    o.index = 42;
    o.sheetId = 42;
  }
  buildCounterDeleteConditionalFormatRuleRequest--;
  return o;
}

void checkDeleteConditionalFormatRuleRequest(
    api.DeleteConditionalFormatRuleRequest o) {
  buildCounterDeleteConditionalFormatRuleRequest++;
  if (buildCounterDeleteConditionalFormatRuleRequest < 3) {
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterDeleteConditionalFormatRuleRequest--;
}

core.int buildCounterDeleteConditionalFormatRuleResponse = 0;
api.DeleteConditionalFormatRuleResponse
    buildDeleteConditionalFormatRuleResponse() {
  var o = api.DeleteConditionalFormatRuleResponse();
  buildCounterDeleteConditionalFormatRuleResponse++;
  if (buildCounterDeleteConditionalFormatRuleResponse < 3) {
    o.rule = buildConditionalFormatRule();
  }
  buildCounterDeleteConditionalFormatRuleResponse--;
  return o;
}

void checkDeleteConditionalFormatRuleResponse(
    api.DeleteConditionalFormatRuleResponse o) {
  buildCounterDeleteConditionalFormatRuleResponse++;
  if (buildCounterDeleteConditionalFormatRuleResponse < 3) {
    checkConditionalFormatRule(o.rule! as api.ConditionalFormatRule);
  }
  buildCounterDeleteConditionalFormatRuleResponse--;
}

core.int buildCounterDeleteDataSourceRequest = 0;
api.DeleteDataSourceRequest buildDeleteDataSourceRequest() {
  var o = api.DeleteDataSourceRequest();
  buildCounterDeleteDataSourceRequest++;
  if (buildCounterDeleteDataSourceRequest < 3) {
    o.dataSourceId = 'foo';
  }
  buildCounterDeleteDataSourceRequest--;
  return o;
}

void checkDeleteDataSourceRequest(api.DeleteDataSourceRequest o) {
  buildCounterDeleteDataSourceRequest++;
  if (buildCounterDeleteDataSourceRequest < 3) {
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteDataSourceRequest--;
}

core.int buildCounterDeleteDeveloperMetadataRequest = 0;
api.DeleteDeveloperMetadataRequest buildDeleteDeveloperMetadataRequest() {
  var o = api.DeleteDeveloperMetadataRequest();
  buildCounterDeleteDeveloperMetadataRequest++;
  if (buildCounterDeleteDeveloperMetadataRequest < 3) {
    o.dataFilter = buildDataFilter();
  }
  buildCounterDeleteDeveloperMetadataRequest--;
  return o;
}

void checkDeleteDeveloperMetadataRequest(api.DeleteDeveloperMetadataRequest o) {
  buildCounterDeleteDeveloperMetadataRequest++;
  if (buildCounterDeleteDeveloperMetadataRequest < 3) {
    checkDataFilter(o.dataFilter! as api.DataFilter);
  }
  buildCounterDeleteDeveloperMetadataRequest--;
}

core.List<api.DeveloperMetadata> buildUnnamed688() {
  var o = <api.DeveloperMetadata>[];
  o.add(buildDeveloperMetadata());
  o.add(buildDeveloperMetadata());
  return o;
}

void checkUnnamed688(core.List<api.DeveloperMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeveloperMetadata(o[0] as api.DeveloperMetadata);
  checkDeveloperMetadata(o[1] as api.DeveloperMetadata);
}

core.int buildCounterDeleteDeveloperMetadataResponse = 0;
api.DeleteDeveloperMetadataResponse buildDeleteDeveloperMetadataResponse() {
  var o = api.DeleteDeveloperMetadataResponse();
  buildCounterDeleteDeveloperMetadataResponse++;
  if (buildCounterDeleteDeveloperMetadataResponse < 3) {
    o.deletedDeveloperMetadata = buildUnnamed688();
  }
  buildCounterDeleteDeveloperMetadataResponse--;
  return o;
}

void checkDeleteDeveloperMetadataResponse(
    api.DeleteDeveloperMetadataResponse o) {
  buildCounterDeleteDeveloperMetadataResponse++;
  if (buildCounterDeleteDeveloperMetadataResponse < 3) {
    checkUnnamed688(o.deletedDeveloperMetadata!);
  }
  buildCounterDeleteDeveloperMetadataResponse--;
}

core.int buildCounterDeleteDimensionGroupRequest = 0;
api.DeleteDimensionGroupRequest buildDeleteDimensionGroupRequest() {
  var o = api.DeleteDimensionGroupRequest();
  buildCounterDeleteDimensionGroupRequest++;
  if (buildCounterDeleteDimensionGroupRequest < 3) {
    o.range = buildDimensionRange();
  }
  buildCounterDeleteDimensionGroupRequest--;
  return o;
}

void checkDeleteDimensionGroupRequest(api.DeleteDimensionGroupRequest o) {
  buildCounterDeleteDimensionGroupRequest++;
  if (buildCounterDeleteDimensionGroupRequest < 3) {
    checkDimensionRange(o.range! as api.DimensionRange);
  }
  buildCounterDeleteDimensionGroupRequest--;
}

core.List<api.DimensionGroup> buildUnnamed689() {
  var o = <api.DimensionGroup>[];
  o.add(buildDimensionGroup());
  o.add(buildDimensionGroup());
  return o;
}

void checkUnnamed689(core.List<api.DimensionGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionGroup(o[0] as api.DimensionGroup);
  checkDimensionGroup(o[1] as api.DimensionGroup);
}

core.int buildCounterDeleteDimensionGroupResponse = 0;
api.DeleteDimensionGroupResponse buildDeleteDimensionGroupResponse() {
  var o = api.DeleteDimensionGroupResponse();
  buildCounterDeleteDimensionGroupResponse++;
  if (buildCounterDeleteDimensionGroupResponse < 3) {
    o.dimensionGroups = buildUnnamed689();
  }
  buildCounterDeleteDimensionGroupResponse--;
  return o;
}

void checkDeleteDimensionGroupResponse(api.DeleteDimensionGroupResponse o) {
  buildCounterDeleteDimensionGroupResponse++;
  if (buildCounterDeleteDimensionGroupResponse < 3) {
    checkUnnamed689(o.dimensionGroups!);
  }
  buildCounterDeleteDimensionGroupResponse--;
}

core.int buildCounterDeleteDimensionRequest = 0;
api.DeleteDimensionRequest buildDeleteDimensionRequest() {
  var o = api.DeleteDimensionRequest();
  buildCounterDeleteDimensionRequest++;
  if (buildCounterDeleteDimensionRequest < 3) {
    o.range = buildDimensionRange();
  }
  buildCounterDeleteDimensionRequest--;
  return o;
}

void checkDeleteDimensionRequest(api.DeleteDimensionRequest o) {
  buildCounterDeleteDimensionRequest++;
  if (buildCounterDeleteDimensionRequest < 3) {
    checkDimensionRange(o.range! as api.DimensionRange);
  }
  buildCounterDeleteDimensionRequest--;
}

core.List<api.DimensionRange> buildUnnamed690() {
  var o = <api.DimensionRange>[];
  o.add(buildDimensionRange());
  o.add(buildDimensionRange());
  return o;
}

void checkUnnamed690(core.List<api.DimensionRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionRange(o[0] as api.DimensionRange);
  checkDimensionRange(o[1] as api.DimensionRange);
}

core.int buildCounterDeleteDuplicatesRequest = 0;
api.DeleteDuplicatesRequest buildDeleteDuplicatesRequest() {
  var o = api.DeleteDuplicatesRequest();
  buildCounterDeleteDuplicatesRequest++;
  if (buildCounterDeleteDuplicatesRequest < 3) {
    o.comparisonColumns = buildUnnamed690();
    o.range = buildGridRange();
  }
  buildCounterDeleteDuplicatesRequest--;
  return o;
}

void checkDeleteDuplicatesRequest(api.DeleteDuplicatesRequest o) {
  buildCounterDeleteDuplicatesRequest++;
  if (buildCounterDeleteDuplicatesRequest < 3) {
    checkUnnamed690(o.comparisonColumns!);
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterDeleteDuplicatesRequest--;
}

core.int buildCounterDeleteDuplicatesResponse = 0;
api.DeleteDuplicatesResponse buildDeleteDuplicatesResponse() {
  var o = api.DeleteDuplicatesResponse();
  buildCounterDeleteDuplicatesResponse++;
  if (buildCounterDeleteDuplicatesResponse < 3) {
    o.duplicatesRemovedCount = 42;
  }
  buildCounterDeleteDuplicatesResponse--;
  return o;
}

void checkDeleteDuplicatesResponse(api.DeleteDuplicatesResponse o) {
  buildCounterDeleteDuplicatesResponse++;
  if (buildCounterDeleteDuplicatesResponse < 3) {
    unittest.expect(
      o.duplicatesRemovedCount!,
      unittest.equals(42),
    );
  }
  buildCounterDeleteDuplicatesResponse--;
}

core.int buildCounterDeleteEmbeddedObjectRequest = 0;
api.DeleteEmbeddedObjectRequest buildDeleteEmbeddedObjectRequest() {
  var o = api.DeleteEmbeddedObjectRequest();
  buildCounterDeleteEmbeddedObjectRequest++;
  if (buildCounterDeleteEmbeddedObjectRequest < 3) {
    o.objectId = 42;
  }
  buildCounterDeleteEmbeddedObjectRequest--;
  return o;
}

void checkDeleteEmbeddedObjectRequest(api.DeleteEmbeddedObjectRequest o) {
  buildCounterDeleteEmbeddedObjectRequest++;
  if (buildCounterDeleteEmbeddedObjectRequest < 3) {
    unittest.expect(
      o.objectId!,
      unittest.equals(42),
    );
  }
  buildCounterDeleteEmbeddedObjectRequest--;
}

core.int buildCounterDeleteFilterViewRequest = 0;
api.DeleteFilterViewRequest buildDeleteFilterViewRequest() {
  var o = api.DeleteFilterViewRequest();
  buildCounterDeleteFilterViewRequest++;
  if (buildCounterDeleteFilterViewRequest < 3) {
    o.filterId = 42;
  }
  buildCounterDeleteFilterViewRequest--;
  return o;
}

void checkDeleteFilterViewRequest(api.DeleteFilterViewRequest o) {
  buildCounterDeleteFilterViewRequest++;
  if (buildCounterDeleteFilterViewRequest < 3) {
    unittest.expect(
      o.filterId!,
      unittest.equals(42),
    );
  }
  buildCounterDeleteFilterViewRequest--;
}

core.int buildCounterDeleteNamedRangeRequest = 0;
api.DeleteNamedRangeRequest buildDeleteNamedRangeRequest() {
  var o = api.DeleteNamedRangeRequest();
  buildCounterDeleteNamedRangeRequest++;
  if (buildCounterDeleteNamedRangeRequest < 3) {
    o.namedRangeId = 'foo';
  }
  buildCounterDeleteNamedRangeRequest--;
  return o;
}

void checkDeleteNamedRangeRequest(api.DeleteNamedRangeRequest o) {
  buildCounterDeleteNamedRangeRequest++;
  if (buildCounterDeleteNamedRangeRequest < 3) {
    unittest.expect(
      o.namedRangeId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteNamedRangeRequest--;
}

core.int buildCounterDeleteProtectedRangeRequest = 0;
api.DeleteProtectedRangeRequest buildDeleteProtectedRangeRequest() {
  var o = api.DeleteProtectedRangeRequest();
  buildCounterDeleteProtectedRangeRequest++;
  if (buildCounterDeleteProtectedRangeRequest < 3) {
    o.protectedRangeId = 42;
  }
  buildCounterDeleteProtectedRangeRequest--;
  return o;
}

void checkDeleteProtectedRangeRequest(api.DeleteProtectedRangeRequest o) {
  buildCounterDeleteProtectedRangeRequest++;
  if (buildCounterDeleteProtectedRangeRequest < 3) {
    unittest.expect(
      o.protectedRangeId!,
      unittest.equals(42),
    );
  }
  buildCounterDeleteProtectedRangeRequest--;
}

core.int buildCounterDeleteRangeRequest = 0;
api.DeleteRangeRequest buildDeleteRangeRequest() {
  var o = api.DeleteRangeRequest();
  buildCounterDeleteRangeRequest++;
  if (buildCounterDeleteRangeRequest < 3) {
    o.range = buildGridRange();
    o.shiftDimension = 'foo';
  }
  buildCounterDeleteRangeRequest--;
  return o;
}

void checkDeleteRangeRequest(api.DeleteRangeRequest o) {
  buildCounterDeleteRangeRequest++;
  if (buildCounterDeleteRangeRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
    unittest.expect(
      o.shiftDimension!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteRangeRequest--;
}

core.int buildCounterDeleteSheetRequest = 0;
api.DeleteSheetRequest buildDeleteSheetRequest() {
  var o = api.DeleteSheetRequest();
  buildCounterDeleteSheetRequest++;
  if (buildCounterDeleteSheetRequest < 3) {
    o.sheetId = 42;
  }
  buildCounterDeleteSheetRequest--;
  return o;
}

void checkDeleteSheetRequest(api.DeleteSheetRequest o) {
  buildCounterDeleteSheetRequest++;
  if (buildCounterDeleteSheetRequest < 3) {
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterDeleteSheetRequest--;
}

core.int buildCounterDeveloperMetadata = 0;
api.DeveloperMetadata buildDeveloperMetadata() {
  var o = api.DeveloperMetadata();
  buildCounterDeveloperMetadata++;
  if (buildCounterDeveloperMetadata < 3) {
    o.location = buildDeveloperMetadataLocation();
    o.metadataId = 42;
    o.metadataKey = 'foo';
    o.metadataValue = 'foo';
    o.visibility = 'foo';
  }
  buildCounterDeveloperMetadata--;
  return o;
}

void checkDeveloperMetadata(api.DeveloperMetadata o) {
  buildCounterDeveloperMetadata++;
  if (buildCounterDeveloperMetadata < 3) {
    checkDeveloperMetadataLocation(
        o.location! as api.DeveloperMetadataLocation);
    unittest.expect(
      o.metadataId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.metadataKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metadataValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visibility!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeveloperMetadata--;
}

core.int buildCounterDeveloperMetadataLocation = 0;
api.DeveloperMetadataLocation buildDeveloperMetadataLocation() {
  var o = api.DeveloperMetadataLocation();
  buildCounterDeveloperMetadataLocation++;
  if (buildCounterDeveloperMetadataLocation < 3) {
    o.dimensionRange = buildDimensionRange();
    o.locationType = 'foo';
    o.sheetId = 42;
    o.spreadsheet = true;
  }
  buildCounterDeveloperMetadataLocation--;
  return o;
}

void checkDeveloperMetadataLocation(api.DeveloperMetadataLocation o) {
  buildCounterDeveloperMetadataLocation++;
  if (buildCounterDeveloperMetadataLocation < 3) {
    checkDimensionRange(o.dimensionRange! as api.DimensionRange);
    unittest.expect(
      o.locationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
    unittest.expect(o.spreadsheet!, unittest.isTrue);
  }
  buildCounterDeveloperMetadataLocation--;
}

core.int buildCounterDeveloperMetadataLookup = 0;
api.DeveloperMetadataLookup buildDeveloperMetadataLookup() {
  var o = api.DeveloperMetadataLookup();
  buildCounterDeveloperMetadataLookup++;
  if (buildCounterDeveloperMetadataLookup < 3) {
    o.locationMatchingStrategy = 'foo';
    o.locationType = 'foo';
    o.metadataId = 42;
    o.metadataKey = 'foo';
    o.metadataLocation = buildDeveloperMetadataLocation();
    o.metadataValue = 'foo';
    o.visibility = 'foo';
  }
  buildCounterDeveloperMetadataLookup--;
  return o;
}

void checkDeveloperMetadataLookup(api.DeveloperMetadataLookup o) {
  buildCounterDeveloperMetadataLookup++;
  if (buildCounterDeveloperMetadataLookup < 3) {
    unittest.expect(
      o.locationMatchingStrategy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metadataId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.metadataKey!,
      unittest.equals('foo'),
    );
    checkDeveloperMetadataLocation(
        o.metadataLocation! as api.DeveloperMetadataLocation);
    unittest.expect(
      o.metadataValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visibility!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeveloperMetadataLookup--;
}

core.int buildCounterDimensionGroup = 0;
api.DimensionGroup buildDimensionGroup() {
  var o = api.DimensionGroup();
  buildCounterDimensionGroup++;
  if (buildCounterDimensionGroup < 3) {
    o.collapsed = true;
    o.depth = 42;
    o.range = buildDimensionRange();
  }
  buildCounterDimensionGroup--;
  return o;
}

void checkDimensionGroup(api.DimensionGroup o) {
  buildCounterDimensionGroup++;
  if (buildCounterDimensionGroup < 3) {
    unittest.expect(o.collapsed!, unittest.isTrue);
    unittest.expect(
      o.depth!,
      unittest.equals(42),
    );
    checkDimensionRange(o.range! as api.DimensionRange);
  }
  buildCounterDimensionGroup--;
}

core.List<api.DeveloperMetadata> buildUnnamed691() {
  var o = <api.DeveloperMetadata>[];
  o.add(buildDeveloperMetadata());
  o.add(buildDeveloperMetadata());
  return o;
}

void checkUnnamed691(core.List<api.DeveloperMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeveloperMetadata(o[0] as api.DeveloperMetadata);
  checkDeveloperMetadata(o[1] as api.DeveloperMetadata);
}

core.int buildCounterDimensionProperties = 0;
api.DimensionProperties buildDimensionProperties() {
  var o = api.DimensionProperties();
  buildCounterDimensionProperties++;
  if (buildCounterDimensionProperties < 3) {
    o.dataSourceColumnReference = buildDataSourceColumnReference();
    o.developerMetadata = buildUnnamed691();
    o.hiddenByFilter = true;
    o.hiddenByUser = true;
    o.pixelSize = 42;
  }
  buildCounterDimensionProperties--;
  return o;
}

void checkDimensionProperties(api.DimensionProperties o) {
  buildCounterDimensionProperties++;
  if (buildCounterDimensionProperties < 3) {
    checkDataSourceColumnReference(
        o.dataSourceColumnReference! as api.DataSourceColumnReference);
    checkUnnamed691(o.developerMetadata!);
    unittest.expect(o.hiddenByFilter!, unittest.isTrue);
    unittest.expect(o.hiddenByUser!, unittest.isTrue);
    unittest.expect(
      o.pixelSize!,
      unittest.equals(42),
    );
  }
  buildCounterDimensionProperties--;
}

core.int buildCounterDimensionRange = 0;
api.DimensionRange buildDimensionRange() {
  var o = api.DimensionRange();
  buildCounterDimensionRange++;
  if (buildCounterDimensionRange < 3) {
    o.dimension = 'foo';
    o.endIndex = 42;
    o.sheetId = 42;
    o.startIndex = 42;
  }
  buildCounterDimensionRange--;
  return o;
}

void checkDimensionRange(api.DimensionRange o) {
  buildCounterDimensionRange++;
  if (buildCounterDimensionRange < 3) {
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
  }
  buildCounterDimensionRange--;
}

core.int buildCounterDuplicateFilterViewRequest = 0;
api.DuplicateFilterViewRequest buildDuplicateFilterViewRequest() {
  var o = api.DuplicateFilterViewRequest();
  buildCounterDuplicateFilterViewRequest++;
  if (buildCounterDuplicateFilterViewRequest < 3) {
    o.filterId = 42;
  }
  buildCounterDuplicateFilterViewRequest--;
  return o;
}

void checkDuplicateFilterViewRequest(api.DuplicateFilterViewRequest o) {
  buildCounterDuplicateFilterViewRequest++;
  if (buildCounterDuplicateFilterViewRequest < 3) {
    unittest.expect(
      o.filterId!,
      unittest.equals(42),
    );
  }
  buildCounterDuplicateFilterViewRequest--;
}

core.int buildCounterDuplicateFilterViewResponse = 0;
api.DuplicateFilterViewResponse buildDuplicateFilterViewResponse() {
  var o = api.DuplicateFilterViewResponse();
  buildCounterDuplicateFilterViewResponse++;
  if (buildCounterDuplicateFilterViewResponse < 3) {
    o.filter = buildFilterView();
  }
  buildCounterDuplicateFilterViewResponse--;
  return o;
}

void checkDuplicateFilterViewResponse(api.DuplicateFilterViewResponse o) {
  buildCounterDuplicateFilterViewResponse++;
  if (buildCounterDuplicateFilterViewResponse < 3) {
    checkFilterView(o.filter! as api.FilterView);
  }
  buildCounterDuplicateFilterViewResponse--;
}

core.int buildCounterDuplicateSheetRequest = 0;
api.DuplicateSheetRequest buildDuplicateSheetRequest() {
  var o = api.DuplicateSheetRequest();
  buildCounterDuplicateSheetRequest++;
  if (buildCounterDuplicateSheetRequest < 3) {
    o.insertSheetIndex = 42;
    o.newSheetId = 42;
    o.newSheetName = 'foo';
    o.sourceSheetId = 42;
  }
  buildCounterDuplicateSheetRequest--;
  return o;
}

void checkDuplicateSheetRequest(api.DuplicateSheetRequest o) {
  buildCounterDuplicateSheetRequest++;
  if (buildCounterDuplicateSheetRequest < 3) {
    unittest.expect(
      o.insertSheetIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.newSheetId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.newSheetName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceSheetId!,
      unittest.equals(42),
    );
  }
  buildCounterDuplicateSheetRequest--;
}

core.int buildCounterDuplicateSheetResponse = 0;
api.DuplicateSheetResponse buildDuplicateSheetResponse() {
  var o = api.DuplicateSheetResponse();
  buildCounterDuplicateSheetResponse++;
  if (buildCounterDuplicateSheetResponse < 3) {
    o.properties = buildSheetProperties();
  }
  buildCounterDuplicateSheetResponse--;
  return o;
}

void checkDuplicateSheetResponse(api.DuplicateSheetResponse o) {
  buildCounterDuplicateSheetResponse++;
  if (buildCounterDuplicateSheetResponse < 3) {
    checkSheetProperties(o.properties! as api.SheetProperties);
  }
  buildCounterDuplicateSheetResponse--;
}

core.List<core.String> buildUnnamed692() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed692(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed693() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed693(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterEditors = 0;
api.Editors buildEditors() {
  var o = api.Editors();
  buildCounterEditors++;
  if (buildCounterEditors < 3) {
    o.domainUsersCanEdit = true;
    o.groups = buildUnnamed692();
    o.users = buildUnnamed693();
  }
  buildCounterEditors--;
  return o;
}

void checkEditors(api.Editors o) {
  buildCounterEditors++;
  if (buildCounterEditors < 3) {
    unittest.expect(o.domainUsersCanEdit!, unittest.isTrue);
    checkUnnamed692(o.groups!);
    checkUnnamed693(o.users!);
  }
  buildCounterEditors--;
}

core.int buildCounterEmbeddedChart = 0;
api.EmbeddedChart buildEmbeddedChart() {
  var o = api.EmbeddedChart();
  buildCounterEmbeddedChart++;
  if (buildCounterEmbeddedChart < 3) {
    o.border = buildEmbeddedObjectBorder();
    o.chartId = 42;
    o.position = buildEmbeddedObjectPosition();
    o.spec = buildChartSpec();
  }
  buildCounterEmbeddedChart--;
  return o;
}

void checkEmbeddedChart(api.EmbeddedChart o) {
  buildCounterEmbeddedChart++;
  if (buildCounterEmbeddedChart < 3) {
    checkEmbeddedObjectBorder(o.border! as api.EmbeddedObjectBorder);
    unittest.expect(
      o.chartId!,
      unittest.equals(42),
    );
    checkEmbeddedObjectPosition(o.position! as api.EmbeddedObjectPosition);
    checkChartSpec(o.spec! as api.ChartSpec);
  }
  buildCounterEmbeddedChart--;
}

core.int buildCounterEmbeddedObjectBorder = 0;
api.EmbeddedObjectBorder buildEmbeddedObjectBorder() {
  var o = api.EmbeddedObjectBorder();
  buildCounterEmbeddedObjectBorder++;
  if (buildCounterEmbeddedObjectBorder < 3) {
    o.color = buildColor();
    o.colorStyle = buildColorStyle();
  }
  buildCounterEmbeddedObjectBorder--;
  return o;
}

void checkEmbeddedObjectBorder(api.EmbeddedObjectBorder o) {
  buildCounterEmbeddedObjectBorder++;
  if (buildCounterEmbeddedObjectBorder < 3) {
    checkColor(o.color! as api.Color);
    checkColorStyle(o.colorStyle! as api.ColorStyle);
  }
  buildCounterEmbeddedObjectBorder--;
}

core.int buildCounterEmbeddedObjectPosition = 0;
api.EmbeddedObjectPosition buildEmbeddedObjectPosition() {
  var o = api.EmbeddedObjectPosition();
  buildCounterEmbeddedObjectPosition++;
  if (buildCounterEmbeddedObjectPosition < 3) {
    o.newSheet = true;
    o.overlayPosition = buildOverlayPosition();
    o.sheetId = 42;
  }
  buildCounterEmbeddedObjectPosition--;
  return o;
}

void checkEmbeddedObjectPosition(api.EmbeddedObjectPosition o) {
  buildCounterEmbeddedObjectPosition++;
  if (buildCounterEmbeddedObjectPosition < 3) {
    unittest.expect(o.newSheet!, unittest.isTrue);
    checkOverlayPosition(o.overlayPosition! as api.OverlayPosition);
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterEmbeddedObjectPosition--;
}

core.int buildCounterErrorValue = 0;
api.ErrorValue buildErrorValue() {
  var o = api.ErrorValue();
  buildCounterErrorValue++;
  if (buildCounterErrorValue < 3) {
    o.message = 'foo';
    o.type = 'foo';
  }
  buildCounterErrorValue--;
  return o;
}

void checkErrorValue(api.ErrorValue o) {
  buildCounterErrorValue++;
  if (buildCounterErrorValue < 3) {
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterErrorValue--;
}

core.int buildCounterExtendedValue = 0;
api.ExtendedValue buildExtendedValue() {
  var o = api.ExtendedValue();
  buildCounterExtendedValue++;
  if (buildCounterExtendedValue < 3) {
    o.boolValue = true;
    o.errorValue = buildErrorValue();
    o.formulaValue = 'foo';
    o.numberValue = 42.0;
    o.stringValue = 'foo';
  }
  buildCounterExtendedValue--;
  return o;
}

void checkExtendedValue(api.ExtendedValue o) {
  buildCounterExtendedValue++;
  if (buildCounterExtendedValue < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    checkErrorValue(o.errorValue! as api.ErrorValue);
    unittest.expect(
      o.formulaValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numberValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterExtendedValue--;
}

core.List<core.String> buildUnnamed694() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed694(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterFilterCriteria = 0;
api.FilterCriteria buildFilterCriteria() {
  var o = api.FilterCriteria();
  buildCounterFilterCriteria++;
  if (buildCounterFilterCriteria < 3) {
    o.condition = buildBooleanCondition();
    o.hiddenValues = buildUnnamed694();
    o.visibleBackgroundColor = buildColor();
    o.visibleBackgroundColorStyle = buildColorStyle();
    o.visibleForegroundColor = buildColor();
    o.visibleForegroundColorStyle = buildColorStyle();
  }
  buildCounterFilterCriteria--;
  return o;
}

void checkFilterCriteria(api.FilterCriteria o) {
  buildCounterFilterCriteria++;
  if (buildCounterFilterCriteria < 3) {
    checkBooleanCondition(o.condition! as api.BooleanCondition);
    checkUnnamed694(o.hiddenValues!);
    checkColor(o.visibleBackgroundColor! as api.Color);
    checkColorStyle(o.visibleBackgroundColorStyle! as api.ColorStyle);
    checkColor(o.visibleForegroundColor! as api.Color);
    checkColorStyle(o.visibleForegroundColorStyle! as api.ColorStyle);
  }
  buildCounterFilterCriteria--;
}

core.int buildCounterFilterSpec = 0;
api.FilterSpec buildFilterSpec() {
  var o = api.FilterSpec();
  buildCounterFilterSpec++;
  if (buildCounterFilterSpec < 3) {
    o.columnIndex = 42;
    o.dataSourceColumnReference = buildDataSourceColumnReference();
    o.filterCriteria = buildFilterCriteria();
  }
  buildCounterFilterSpec--;
  return o;
}

void checkFilterSpec(api.FilterSpec o) {
  buildCounterFilterSpec++;
  if (buildCounterFilterSpec < 3) {
    unittest.expect(
      o.columnIndex!,
      unittest.equals(42),
    );
    checkDataSourceColumnReference(
        o.dataSourceColumnReference! as api.DataSourceColumnReference);
    checkFilterCriteria(o.filterCriteria! as api.FilterCriteria);
  }
  buildCounterFilterSpec--;
}

core.Map<core.String, api.FilterCriteria> buildUnnamed695() {
  var o = <core.String, api.FilterCriteria>{};
  o['x'] = buildFilterCriteria();
  o['y'] = buildFilterCriteria();
  return o;
}

void checkUnnamed695(core.Map<core.String, api.FilterCriteria> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterCriteria(o['x']! as api.FilterCriteria);
  checkFilterCriteria(o['y']! as api.FilterCriteria);
}

core.List<api.FilterSpec> buildUnnamed696() {
  var o = <api.FilterSpec>[];
  o.add(buildFilterSpec());
  o.add(buildFilterSpec());
  return o;
}

void checkUnnamed696(core.List<api.FilterSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterSpec(o[0] as api.FilterSpec);
  checkFilterSpec(o[1] as api.FilterSpec);
}

core.List<api.SortSpec> buildUnnamed697() {
  var o = <api.SortSpec>[];
  o.add(buildSortSpec());
  o.add(buildSortSpec());
  return o;
}

void checkUnnamed697(core.List<api.SortSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSortSpec(o[0] as api.SortSpec);
  checkSortSpec(o[1] as api.SortSpec);
}

core.int buildCounterFilterView = 0;
api.FilterView buildFilterView() {
  var o = api.FilterView();
  buildCounterFilterView++;
  if (buildCounterFilterView < 3) {
    o.criteria = buildUnnamed695();
    o.filterSpecs = buildUnnamed696();
    o.filterViewId = 42;
    o.namedRangeId = 'foo';
    o.range = buildGridRange();
    o.sortSpecs = buildUnnamed697();
    o.title = 'foo';
  }
  buildCounterFilterView--;
  return o;
}

void checkFilterView(api.FilterView o) {
  buildCounterFilterView++;
  if (buildCounterFilterView < 3) {
    checkUnnamed695(o.criteria!);
    checkUnnamed696(o.filterSpecs!);
    unittest.expect(
      o.filterViewId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.namedRangeId!,
      unittest.equals('foo'),
    );
    checkGridRange(o.range! as api.GridRange);
    checkUnnamed697(o.sortSpecs!);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilterView--;
}

core.int buildCounterFindReplaceRequest = 0;
api.FindReplaceRequest buildFindReplaceRequest() {
  var o = api.FindReplaceRequest();
  buildCounterFindReplaceRequest++;
  if (buildCounterFindReplaceRequest < 3) {
    o.allSheets = true;
    o.find = 'foo';
    o.includeFormulas = true;
    o.matchCase = true;
    o.matchEntireCell = true;
    o.range = buildGridRange();
    o.replacement = 'foo';
    o.searchByRegex = true;
    o.sheetId = 42;
  }
  buildCounterFindReplaceRequest--;
  return o;
}

void checkFindReplaceRequest(api.FindReplaceRequest o) {
  buildCounterFindReplaceRequest++;
  if (buildCounterFindReplaceRequest < 3) {
    unittest.expect(o.allSheets!, unittest.isTrue);
    unittest.expect(
      o.find!,
      unittest.equals('foo'),
    );
    unittest.expect(o.includeFormulas!, unittest.isTrue);
    unittest.expect(o.matchCase!, unittest.isTrue);
    unittest.expect(o.matchEntireCell!, unittest.isTrue);
    checkGridRange(o.range! as api.GridRange);
    unittest.expect(
      o.replacement!,
      unittest.equals('foo'),
    );
    unittest.expect(o.searchByRegex!, unittest.isTrue);
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterFindReplaceRequest--;
}

core.int buildCounterFindReplaceResponse = 0;
api.FindReplaceResponse buildFindReplaceResponse() {
  var o = api.FindReplaceResponse();
  buildCounterFindReplaceResponse++;
  if (buildCounterFindReplaceResponse < 3) {
    o.formulasChanged = 42;
    o.occurrencesChanged = 42;
    o.rowsChanged = 42;
    o.sheetsChanged = 42;
    o.valuesChanged = 42;
  }
  buildCounterFindReplaceResponse--;
  return o;
}

void checkFindReplaceResponse(api.FindReplaceResponse o) {
  buildCounterFindReplaceResponse++;
  if (buildCounterFindReplaceResponse < 3) {
    unittest.expect(
      o.formulasChanged!,
      unittest.equals(42),
    );
    unittest.expect(
      o.occurrencesChanged!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rowsChanged!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sheetsChanged!,
      unittest.equals(42),
    );
    unittest.expect(
      o.valuesChanged!,
      unittest.equals(42),
    );
  }
  buildCounterFindReplaceResponse--;
}

core.List<api.DataFilter> buildUnnamed698() {
  var o = <api.DataFilter>[];
  o.add(buildDataFilter());
  o.add(buildDataFilter());
  return o;
}

void checkUnnamed698(core.List<api.DataFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilter(o[0] as api.DataFilter);
  checkDataFilter(o[1] as api.DataFilter);
}

core.int buildCounterGetSpreadsheetByDataFilterRequest = 0;
api.GetSpreadsheetByDataFilterRequest buildGetSpreadsheetByDataFilterRequest() {
  var o = api.GetSpreadsheetByDataFilterRequest();
  buildCounterGetSpreadsheetByDataFilterRequest++;
  if (buildCounterGetSpreadsheetByDataFilterRequest < 3) {
    o.dataFilters = buildUnnamed698();
    o.includeGridData = true;
  }
  buildCounterGetSpreadsheetByDataFilterRequest--;
  return o;
}

void checkGetSpreadsheetByDataFilterRequest(
    api.GetSpreadsheetByDataFilterRequest o) {
  buildCounterGetSpreadsheetByDataFilterRequest++;
  if (buildCounterGetSpreadsheetByDataFilterRequest < 3) {
    checkUnnamed698(o.dataFilters!);
    unittest.expect(o.includeGridData!, unittest.isTrue);
  }
  buildCounterGetSpreadsheetByDataFilterRequest--;
}

core.int buildCounterGradientRule = 0;
api.GradientRule buildGradientRule() {
  var o = api.GradientRule();
  buildCounterGradientRule++;
  if (buildCounterGradientRule < 3) {
    o.maxpoint = buildInterpolationPoint();
    o.midpoint = buildInterpolationPoint();
    o.minpoint = buildInterpolationPoint();
  }
  buildCounterGradientRule--;
  return o;
}

void checkGradientRule(api.GradientRule o) {
  buildCounterGradientRule++;
  if (buildCounterGradientRule < 3) {
    checkInterpolationPoint(o.maxpoint! as api.InterpolationPoint);
    checkInterpolationPoint(o.midpoint! as api.InterpolationPoint);
    checkInterpolationPoint(o.minpoint! as api.InterpolationPoint);
  }
  buildCounterGradientRule--;
}

core.int buildCounterGridCoordinate = 0;
api.GridCoordinate buildGridCoordinate() {
  var o = api.GridCoordinate();
  buildCounterGridCoordinate++;
  if (buildCounterGridCoordinate < 3) {
    o.columnIndex = 42;
    o.rowIndex = 42;
    o.sheetId = 42;
  }
  buildCounterGridCoordinate--;
  return o;
}

void checkGridCoordinate(api.GridCoordinate o) {
  buildCounterGridCoordinate++;
  if (buildCounterGridCoordinate < 3) {
    unittest.expect(
      o.columnIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rowIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterGridCoordinate--;
}

core.List<api.DimensionProperties> buildUnnamed699() {
  var o = <api.DimensionProperties>[];
  o.add(buildDimensionProperties());
  o.add(buildDimensionProperties());
  return o;
}

void checkUnnamed699(core.List<api.DimensionProperties> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionProperties(o[0] as api.DimensionProperties);
  checkDimensionProperties(o[1] as api.DimensionProperties);
}

core.List<api.RowData> buildUnnamed700() {
  var o = <api.RowData>[];
  o.add(buildRowData());
  o.add(buildRowData());
  return o;
}

void checkUnnamed700(core.List<api.RowData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRowData(o[0] as api.RowData);
  checkRowData(o[1] as api.RowData);
}

core.List<api.DimensionProperties> buildUnnamed701() {
  var o = <api.DimensionProperties>[];
  o.add(buildDimensionProperties());
  o.add(buildDimensionProperties());
  return o;
}

void checkUnnamed701(core.List<api.DimensionProperties> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionProperties(o[0] as api.DimensionProperties);
  checkDimensionProperties(o[1] as api.DimensionProperties);
}

core.int buildCounterGridData = 0;
api.GridData buildGridData() {
  var o = api.GridData();
  buildCounterGridData++;
  if (buildCounterGridData < 3) {
    o.columnMetadata = buildUnnamed699();
    o.rowData = buildUnnamed700();
    o.rowMetadata = buildUnnamed701();
    o.startColumn = 42;
    o.startRow = 42;
  }
  buildCounterGridData--;
  return o;
}

void checkGridData(api.GridData o) {
  buildCounterGridData++;
  if (buildCounterGridData < 3) {
    checkUnnamed699(o.columnMetadata!);
    checkUnnamed700(o.rowData!);
    checkUnnamed701(o.rowMetadata!);
    unittest.expect(
      o.startColumn!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startRow!,
      unittest.equals(42),
    );
  }
  buildCounterGridData--;
}

core.int buildCounterGridProperties = 0;
api.GridProperties buildGridProperties() {
  var o = api.GridProperties();
  buildCounterGridProperties++;
  if (buildCounterGridProperties < 3) {
    o.columnCount = 42;
    o.columnGroupControlAfter = true;
    o.frozenColumnCount = 42;
    o.frozenRowCount = 42;
    o.hideGridlines = true;
    o.rowCount = 42;
    o.rowGroupControlAfter = true;
  }
  buildCounterGridProperties--;
  return o;
}

void checkGridProperties(api.GridProperties o) {
  buildCounterGridProperties++;
  if (buildCounterGridProperties < 3) {
    unittest.expect(
      o.columnCount!,
      unittest.equals(42),
    );
    unittest.expect(o.columnGroupControlAfter!, unittest.isTrue);
    unittest.expect(
      o.frozenColumnCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.frozenRowCount!,
      unittest.equals(42),
    );
    unittest.expect(o.hideGridlines!, unittest.isTrue);
    unittest.expect(
      o.rowCount!,
      unittest.equals(42),
    );
    unittest.expect(o.rowGroupControlAfter!, unittest.isTrue);
  }
  buildCounterGridProperties--;
}

core.int buildCounterGridRange = 0;
api.GridRange buildGridRange() {
  var o = api.GridRange();
  buildCounterGridRange++;
  if (buildCounterGridRange < 3) {
    o.endColumnIndex = 42;
    o.endRowIndex = 42;
    o.sheetId = 42;
    o.startColumnIndex = 42;
    o.startRowIndex = 42;
  }
  buildCounterGridRange--;
  return o;
}

void checkGridRange(api.GridRange o) {
  buildCounterGridRange++;
  if (buildCounterGridRange < 3) {
    unittest.expect(
      o.endColumnIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.endRowIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startColumnIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startRowIndex!,
      unittest.equals(42),
    );
  }
  buildCounterGridRange--;
}

core.List<api.HistogramSeries> buildUnnamed702() {
  var o = <api.HistogramSeries>[];
  o.add(buildHistogramSeries());
  o.add(buildHistogramSeries());
  return o;
}

void checkUnnamed702(core.List<api.HistogramSeries> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHistogramSeries(o[0] as api.HistogramSeries);
  checkHistogramSeries(o[1] as api.HistogramSeries);
}

core.int buildCounterHistogramChartSpec = 0;
api.HistogramChartSpec buildHistogramChartSpec() {
  var o = api.HistogramChartSpec();
  buildCounterHistogramChartSpec++;
  if (buildCounterHistogramChartSpec < 3) {
    o.bucketSize = 42.0;
    o.legendPosition = 'foo';
    o.outlierPercentile = 42.0;
    o.series = buildUnnamed702();
    o.showItemDividers = true;
  }
  buildCounterHistogramChartSpec--;
  return o;
}

void checkHistogramChartSpec(api.HistogramChartSpec o) {
  buildCounterHistogramChartSpec++;
  if (buildCounterHistogramChartSpec < 3) {
    unittest.expect(
      o.bucketSize!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.legendPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outlierPercentile!,
      unittest.equals(42.0),
    );
    checkUnnamed702(o.series!);
    unittest.expect(o.showItemDividers!, unittest.isTrue);
  }
  buildCounterHistogramChartSpec--;
}

core.int buildCounterHistogramRule = 0;
api.HistogramRule buildHistogramRule() {
  var o = api.HistogramRule();
  buildCounterHistogramRule++;
  if (buildCounterHistogramRule < 3) {
    o.end = 42.0;
    o.interval = 42.0;
    o.start = 42.0;
  }
  buildCounterHistogramRule--;
  return o;
}

void checkHistogramRule(api.HistogramRule o) {
  buildCounterHistogramRule++;
  if (buildCounterHistogramRule < 3) {
    unittest.expect(
      o.end!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.interval!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.start!,
      unittest.equals(42.0),
    );
  }
  buildCounterHistogramRule--;
}

core.int buildCounterHistogramSeries = 0;
api.HistogramSeries buildHistogramSeries() {
  var o = api.HistogramSeries();
  buildCounterHistogramSeries++;
  if (buildCounterHistogramSeries < 3) {
    o.barColor = buildColor();
    o.barColorStyle = buildColorStyle();
    o.data = buildChartData();
  }
  buildCounterHistogramSeries--;
  return o;
}

void checkHistogramSeries(api.HistogramSeries o) {
  buildCounterHistogramSeries++;
  if (buildCounterHistogramSeries < 3) {
    checkColor(o.barColor! as api.Color);
    checkColorStyle(o.barColorStyle! as api.ColorStyle);
    checkChartData(o.data! as api.ChartData);
  }
  buildCounterHistogramSeries--;
}

core.int buildCounterInsertDimensionRequest = 0;
api.InsertDimensionRequest buildInsertDimensionRequest() {
  var o = api.InsertDimensionRequest();
  buildCounterInsertDimensionRequest++;
  if (buildCounterInsertDimensionRequest < 3) {
    o.inheritFromBefore = true;
    o.range = buildDimensionRange();
  }
  buildCounterInsertDimensionRequest--;
  return o;
}

void checkInsertDimensionRequest(api.InsertDimensionRequest o) {
  buildCounterInsertDimensionRequest++;
  if (buildCounterInsertDimensionRequest < 3) {
    unittest.expect(o.inheritFromBefore!, unittest.isTrue);
    checkDimensionRange(o.range! as api.DimensionRange);
  }
  buildCounterInsertDimensionRequest--;
}

core.int buildCounterInsertRangeRequest = 0;
api.InsertRangeRequest buildInsertRangeRequest() {
  var o = api.InsertRangeRequest();
  buildCounterInsertRangeRequest++;
  if (buildCounterInsertRangeRequest < 3) {
    o.range = buildGridRange();
    o.shiftDimension = 'foo';
  }
  buildCounterInsertRangeRequest--;
  return o;
}

void checkInsertRangeRequest(api.InsertRangeRequest o) {
  buildCounterInsertRangeRequest++;
  if (buildCounterInsertRangeRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
    unittest.expect(
      o.shiftDimension!,
      unittest.equals('foo'),
    );
  }
  buildCounterInsertRangeRequest--;
}

core.int buildCounterInterpolationPoint = 0;
api.InterpolationPoint buildInterpolationPoint() {
  var o = api.InterpolationPoint();
  buildCounterInterpolationPoint++;
  if (buildCounterInterpolationPoint < 3) {
    o.color = buildColor();
    o.colorStyle = buildColorStyle();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterInterpolationPoint--;
  return o;
}

void checkInterpolationPoint(api.InterpolationPoint o) {
  buildCounterInterpolationPoint++;
  if (buildCounterInterpolationPoint < 3) {
    checkColor(o.color! as api.Color);
    checkColorStyle(o.colorStyle! as api.ColorStyle);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterInterpolationPoint--;
}

core.int buildCounterInterval = 0;
api.Interval buildInterval() {
  var o = api.Interval();
  buildCounterInterval++;
  if (buildCounterInterval < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterInterval--;
  return o;
}

void checkInterval(api.Interval o) {
  buildCounterInterval++;
  if (buildCounterInterval < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterInterval--;
}

core.int buildCounterIterativeCalculationSettings = 0;
api.IterativeCalculationSettings buildIterativeCalculationSettings() {
  var o = api.IterativeCalculationSettings();
  buildCounterIterativeCalculationSettings++;
  if (buildCounterIterativeCalculationSettings < 3) {
    o.convergenceThreshold = 42.0;
    o.maxIterations = 42;
  }
  buildCounterIterativeCalculationSettings--;
  return o;
}

void checkIterativeCalculationSettings(api.IterativeCalculationSettings o) {
  buildCounterIterativeCalculationSettings++;
  if (buildCounterIterativeCalculationSettings < 3) {
    unittest.expect(
      o.convergenceThreshold!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.maxIterations!,
      unittest.equals(42),
    );
  }
  buildCounterIterativeCalculationSettings--;
}

core.int buildCounterKeyValueFormat = 0;
api.KeyValueFormat buildKeyValueFormat() {
  var o = api.KeyValueFormat();
  buildCounterKeyValueFormat++;
  if (buildCounterKeyValueFormat < 3) {
    o.position = buildTextPosition();
    o.textFormat = buildTextFormat();
  }
  buildCounterKeyValueFormat--;
  return o;
}

void checkKeyValueFormat(api.KeyValueFormat o) {
  buildCounterKeyValueFormat++;
  if (buildCounterKeyValueFormat < 3) {
    checkTextPosition(o.position! as api.TextPosition);
    checkTextFormat(o.textFormat! as api.TextFormat);
  }
  buildCounterKeyValueFormat--;
}

core.int buildCounterLineStyle = 0;
api.LineStyle buildLineStyle() {
  var o = api.LineStyle();
  buildCounterLineStyle++;
  if (buildCounterLineStyle < 3) {
    o.type = 'foo';
    o.width = 42;
  }
  buildCounterLineStyle--;
  return o;
}

void checkLineStyle(api.LineStyle o) {
  buildCounterLineStyle++;
  if (buildCounterLineStyle < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterLineStyle--;
}

core.int buildCounterLink = 0;
api.Link buildLink() {
  var o = api.Link();
  buildCounterLink++;
  if (buildCounterLink < 3) {
    o.uri = 'foo';
  }
  buildCounterLink--;
  return o;
}

void checkLink(api.Link o) {
  buildCounterLink++;
  if (buildCounterLink < 3) {
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterLink--;
}

core.List<api.ManualRuleGroup> buildUnnamed703() {
  var o = <api.ManualRuleGroup>[];
  o.add(buildManualRuleGroup());
  o.add(buildManualRuleGroup());
  return o;
}

void checkUnnamed703(core.List<api.ManualRuleGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkManualRuleGroup(o[0] as api.ManualRuleGroup);
  checkManualRuleGroup(o[1] as api.ManualRuleGroup);
}

core.int buildCounterManualRule = 0;
api.ManualRule buildManualRule() {
  var o = api.ManualRule();
  buildCounterManualRule++;
  if (buildCounterManualRule < 3) {
    o.groups = buildUnnamed703();
  }
  buildCounterManualRule--;
  return o;
}

void checkManualRule(api.ManualRule o) {
  buildCounterManualRule++;
  if (buildCounterManualRule < 3) {
    checkUnnamed703(o.groups!);
  }
  buildCounterManualRule--;
}

core.List<api.ExtendedValue> buildUnnamed704() {
  var o = <api.ExtendedValue>[];
  o.add(buildExtendedValue());
  o.add(buildExtendedValue());
  return o;
}

void checkUnnamed704(core.List<api.ExtendedValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExtendedValue(o[0] as api.ExtendedValue);
  checkExtendedValue(o[1] as api.ExtendedValue);
}

core.int buildCounterManualRuleGroup = 0;
api.ManualRuleGroup buildManualRuleGroup() {
  var o = api.ManualRuleGroup();
  buildCounterManualRuleGroup++;
  if (buildCounterManualRuleGroup < 3) {
    o.groupName = buildExtendedValue();
    o.items = buildUnnamed704();
  }
  buildCounterManualRuleGroup--;
  return o;
}

void checkManualRuleGroup(api.ManualRuleGroup o) {
  buildCounterManualRuleGroup++;
  if (buildCounterManualRuleGroup < 3) {
    checkExtendedValue(o.groupName! as api.ExtendedValue);
    checkUnnamed704(o.items!);
  }
  buildCounterManualRuleGroup--;
}

core.List<api.DataFilter> buildUnnamed705() {
  var o = <api.DataFilter>[];
  o.add(buildDataFilter());
  o.add(buildDataFilter());
  return o;
}

void checkUnnamed705(core.List<api.DataFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilter(o[0] as api.DataFilter);
  checkDataFilter(o[1] as api.DataFilter);
}

core.int buildCounterMatchedDeveloperMetadata = 0;
api.MatchedDeveloperMetadata buildMatchedDeveloperMetadata() {
  var o = api.MatchedDeveloperMetadata();
  buildCounterMatchedDeveloperMetadata++;
  if (buildCounterMatchedDeveloperMetadata < 3) {
    o.dataFilters = buildUnnamed705();
    o.developerMetadata = buildDeveloperMetadata();
  }
  buildCounterMatchedDeveloperMetadata--;
  return o;
}

void checkMatchedDeveloperMetadata(api.MatchedDeveloperMetadata o) {
  buildCounterMatchedDeveloperMetadata++;
  if (buildCounterMatchedDeveloperMetadata < 3) {
    checkUnnamed705(o.dataFilters!);
    checkDeveloperMetadata(o.developerMetadata! as api.DeveloperMetadata);
  }
  buildCounterMatchedDeveloperMetadata--;
}

core.List<api.DataFilter> buildUnnamed706() {
  var o = <api.DataFilter>[];
  o.add(buildDataFilter());
  o.add(buildDataFilter());
  return o;
}

void checkUnnamed706(core.List<api.DataFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilter(o[0] as api.DataFilter);
  checkDataFilter(o[1] as api.DataFilter);
}

core.int buildCounterMatchedValueRange = 0;
api.MatchedValueRange buildMatchedValueRange() {
  var o = api.MatchedValueRange();
  buildCounterMatchedValueRange++;
  if (buildCounterMatchedValueRange < 3) {
    o.dataFilters = buildUnnamed706();
    o.valueRange = buildValueRange();
  }
  buildCounterMatchedValueRange--;
  return o;
}

void checkMatchedValueRange(api.MatchedValueRange o) {
  buildCounterMatchedValueRange++;
  if (buildCounterMatchedValueRange < 3) {
    checkUnnamed706(o.dataFilters!);
    checkValueRange(o.valueRange! as api.ValueRange);
  }
  buildCounterMatchedValueRange--;
}

core.int buildCounterMergeCellsRequest = 0;
api.MergeCellsRequest buildMergeCellsRequest() {
  var o = api.MergeCellsRequest();
  buildCounterMergeCellsRequest++;
  if (buildCounterMergeCellsRequest < 3) {
    o.mergeType = 'foo';
    o.range = buildGridRange();
  }
  buildCounterMergeCellsRequest--;
  return o;
}

void checkMergeCellsRequest(api.MergeCellsRequest o) {
  buildCounterMergeCellsRequest++;
  if (buildCounterMergeCellsRequest < 3) {
    unittest.expect(
      o.mergeType!,
      unittest.equals('foo'),
    );
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterMergeCellsRequest--;
}

core.int buildCounterMoveDimensionRequest = 0;
api.MoveDimensionRequest buildMoveDimensionRequest() {
  var o = api.MoveDimensionRequest();
  buildCounterMoveDimensionRequest++;
  if (buildCounterMoveDimensionRequest < 3) {
    o.destinationIndex = 42;
    o.source = buildDimensionRange();
  }
  buildCounterMoveDimensionRequest--;
  return o;
}

void checkMoveDimensionRequest(api.MoveDimensionRequest o) {
  buildCounterMoveDimensionRequest++;
  if (buildCounterMoveDimensionRequest < 3) {
    unittest.expect(
      o.destinationIndex!,
      unittest.equals(42),
    );
    checkDimensionRange(o.source! as api.DimensionRange);
  }
  buildCounterMoveDimensionRequest--;
}

core.int buildCounterNamedRange = 0;
api.NamedRange buildNamedRange() {
  var o = api.NamedRange();
  buildCounterNamedRange++;
  if (buildCounterNamedRange < 3) {
    o.name = 'foo';
    o.namedRangeId = 'foo';
    o.range = buildGridRange();
  }
  buildCounterNamedRange--;
  return o;
}

void checkNamedRange(api.NamedRange o) {
  buildCounterNamedRange++;
  if (buildCounterNamedRange < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.namedRangeId!,
      unittest.equals('foo'),
    );
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterNamedRange--;
}

core.int buildCounterNumberFormat = 0;
api.NumberFormat buildNumberFormat() {
  var o = api.NumberFormat();
  buildCounterNumberFormat++;
  if (buildCounterNumberFormat < 3) {
    o.pattern = 'foo';
    o.type = 'foo';
  }
  buildCounterNumberFormat--;
  return o;
}

void checkNumberFormat(api.NumberFormat o) {
  buildCounterNumberFormat++;
  if (buildCounterNumberFormat < 3) {
    unittest.expect(
      o.pattern!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterNumberFormat--;
}

core.int buildCounterOrgChartSpec = 0;
api.OrgChartSpec buildOrgChartSpec() {
  var o = api.OrgChartSpec();
  buildCounterOrgChartSpec++;
  if (buildCounterOrgChartSpec < 3) {
    o.labels = buildChartData();
    o.nodeColor = buildColor();
    o.nodeColorStyle = buildColorStyle();
    o.nodeSize = 'foo';
    o.parentLabels = buildChartData();
    o.selectedNodeColor = buildColor();
    o.selectedNodeColorStyle = buildColorStyle();
    o.tooltips = buildChartData();
  }
  buildCounterOrgChartSpec--;
  return o;
}

void checkOrgChartSpec(api.OrgChartSpec o) {
  buildCounterOrgChartSpec++;
  if (buildCounterOrgChartSpec < 3) {
    checkChartData(o.labels! as api.ChartData);
    checkColor(o.nodeColor! as api.Color);
    checkColorStyle(o.nodeColorStyle! as api.ColorStyle);
    unittest.expect(
      o.nodeSize!,
      unittest.equals('foo'),
    );
    checkChartData(o.parentLabels! as api.ChartData);
    checkColor(o.selectedNodeColor! as api.Color);
    checkColorStyle(o.selectedNodeColorStyle! as api.ColorStyle);
    checkChartData(o.tooltips! as api.ChartData);
  }
  buildCounterOrgChartSpec--;
}

core.int buildCounterOverlayPosition = 0;
api.OverlayPosition buildOverlayPosition() {
  var o = api.OverlayPosition();
  buildCounterOverlayPosition++;
  if (buildCounterOverlayPosition < 3) {
    o.anchorCell = buildGridCoordinate();
    o.heightPixels = 42;
    o.offsetXPixels = 42;
    o.offsetYPixels = 42;
    o.widthPixels = 42;
  }
  buildCounterOverlayPosition--;
  return o;
}

void checkOverlayPosition(api.OverlayPosition o) {
  buildCounterOverlayPosition++;
  if (buildCounterOverlayPosition < 3) {
    checkGridCoordinate(o.anchorCell! as api.GridCoordinate);
    unittest.expect(
      o.heightPixels!,
      unittest.equals(42),
    );
    unittest.expect(
      o.offsetXPixels!,
      unittest.equals(42),
    );
    unittest.expect(
      o.offsetYPixels!,
      unittest.equals(42),
    );
    unittest.expect(
      o.widthPixels!,
      unittest.equals(42),
    );
  }
  buildCounterOverlayPosition--;
}

core.int buildCounterPadding = 0;
api.Padding buildPadding() {
  var o = api.Padding();
  buildCounterPadding++;
  if (buildCounterPadding < 3) {
    o.bottom = 42;
    o.left = 42;
    o.right = 42;
    o.top = 42;
  }
  buildCounterPadding--;
  return o;
}

void checkPadding(api.Padding o) {
  buildCounterPadding++;
  if (buildCounterPadding < 3) {
    unittest.expect(
      o.bottom!,
      unittest.equals(42),
    );
    unittest.expect(
      o.left!,
      unittest.equals(42),
    );
    unittest.expect(
      o.right!,
      unittest.equals(42),
    );
    unittest.expect(
      o.top!,
      unittest.equals(42),
    );
  }
  buildCounterPadding--;
}

core.int buildCounterPasteDataRequest = 0;
api.PasteDataRequest buildPasteDataRequest() {
  var o = api.PasteDataRequest();
  buildCounterPasteDataRequest++;
  if (buildCounterPasteDataRequest < 3) {
    o.coordinate = buildGridCoordinate();
    o.data = 'foo';
    o.delimiter = 'foo';
    o.html = true;
    o.type = 'foo';
  }
  buildCounterPasteDataRequest--;
  return o;
}

void checkPasteDataRequest(api.PasteDataRequest o) {
  buildCounterPasteDataRequest++;
  if (buildCounterPasteDataRequest < 3) {
    checkGridCoordinate(o.coordinate! as api.GridCoordinate);
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.delimiter!,
      unittest.equals('foo'),
    );
    unittest.expect(o.html!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterPasteDataRequest--;
}

core.int buildCounterPieChartSpec = 0;
api.PieChartSpec buildPieChartSpec() {
  var o = api.PieChartSpec();
  buildCounterPieChartSpec++;
  if (buildCounterPieChartSpec < 3) {
    o.domain = buildChartData();
    o.legendPosition = 'foo';
    o.pieHole = 42.0;
    o.series = buildChartData();
    o.threeDimensional = true;
  }
  buildCounterPieChartSpec--;
  return o;
}

void checkPieChartSpec(api.PieChartSpec o) {
  buildCounterPieChartSpec++;
  if (buildCounterPieChartSpec < 3) {
    checkChartData(o.domain! as api.ChartData);
    unittest.expect(
      o.legendPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pieHole!,
      unittest.equals(42.0),
    );
    checkChartData(o.series! as api.ChartData);
    unittest.expect(o.threeDimensional!, unittest.isTrue);
  }
  buildCounterPieChartSpec--;
}

core.List<core.String> buildUnnamed707() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed707(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterPivotFilterCriteria = 0;
api.PivotFilterCriteria buildPivotFilterCriteria() {
  var o = api.PivotFilterCriteria();
  buildCounterPivotFilterCriteria++;
  if (buildCounterPivotFilterCriteria < 3) {
    o.condition = buildBooleanCondition();
    o.visibleByDefault = true;
    o.visibleValues = buildUnnamed707();
  }
  buildCounterPivotFilterCriteria--;
  return o;
}

void checkPivotFilterCriteria(api.PivotFilterCriteria o) {
  buildCounterPivotFilterCriteria++;
  if (buildCounterPivotFilterCriteria < 3) {
    checkBooleanCondition(o.condition! as api.BooleanCondition);
    unittest.expect(o.visibleByDefault!, unittest.isTrue);
    checkUnnamed707(o.visibleValues!);
  }
  buildCounterPivotFilterCriteria--;
}

core.int buildCounterPivotFilterSpec = 0;
api.PivotFilterSpec buildPivotFilterSpec() {
  var o = api.PivotFilterSpec();
  buildCounterPivotFilterSpec++;
  if (buildCounterPivotFilterSpec < 3) {
    o.columnOffsetIndex = 42;
    o.dataSourceColumnReference = buildDataSourceColumnReference();
    o.filterCriteria = buildPivotFilterCriteria();
  }
  buildCounterPivotFilterSpec--;
  return o;
}

void checkPivotFilterSpec(api.PivotFilterSpec o) {
  buildCounterPivotFilterSpec++;
  if (buildCounterPivotFilterSpec < 3) {
    unittest.expect(
      o.columnOffsetIndex!,
      unittest.equals(42),
    );
    checkDataSourceColumnReference(
        o.dataSourceColumnReference! as api.DataSourceColumnReference);
    checkPivotFilterCriteria(o.filterCriteria! as api.PivotFilterCriteria);
  }
  buildCounterPivotFilterSpec--;
}

core.List<api.PivotGroupValueMetadata> buildUnnamed708() {
  var o = <api.PivotGroupValueMetadata>[];
  o.add(buildPivotGroupValueMetadata());
  o.add(buildPivotGroupValueMetadata());
  return o;
}

void checkUnnamed708(core.List<api.PivotGroupValueMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotGroupValueMetadata(o[0] as api.PivotGroupValueMetadata);
  checkPivotGroupValueMetadata(o[1] as api.PivotGroupValueMetadata);
}

core.int buildCounterPivotGroup = 0;
api.PivotGroup buildPivotGroup() {
  var o = api.PivotGroup();
  buildCounterPivotGroup++;
  if (buildCounterPivotGroup < 3) {
    o.dataSourceColumnReference = buildDataSourceColumnReference();
    o.groupLimit = buildPivotGroupLimit();
    o.groupRule = buildPivotGroupRule();
    o.label = 'foo';
    o.repeatHeadings = true;
    o.showTotals = true;
    o.sortOrder = 'foo';
    o.sourceColumnOffset = 42;
    o.valueBucket = buildPivotGroupSortValueBucket();
    o.valueMetadata = buildUnnamed708();
  }
  buildCounterPivotGroup--;
  return o;
}

void checkPivotGroup(api.PivotGroup o) {
  buildCounterPivotGroup++;
  if (buildCounterPivotGroup < 3) {
    checkDataSourceColumnReference(
        o.dataSourceColumnReference! as api.DataSourceColumnReference);
    checkPivotGroupLimit(o.groupLimit! as api.PivotGroupLimit);
    checkPivotGroupRule(o.groupRule! as api.PivotGroupRule);
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    unittest.expect(o.repeatHeadings!, unittest.isTrue);
    unittest.expect(o.showTotals!, unittest.isTrue);
    unittest.expect(
      o.sortOrder!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceColumnOffset!,
      unittest.equals(42),
    );
    checkPivotGroupSortValueBucket(
        o.valueBucket! as api.PivotGroupSortValueBucket);
    checkUnnamed708(o.valueMetadata!);
  }
  buildCounterPivotGroup--;
}

core.int buildCounterPivotGroupLimit = 0;
api.PivotGroupLimit buildPivotGroupLimit() {
  var o = api.PivotGroupLimit();
  buildCounterPivotGroupLimit++;
  if (buildCounterPivotGroupLimit < 3) {
    o.applyOrder = 42;
    o.countLimit = 42;
  }
  buildCounterPivotGroupLimit--;
  return o;
}

void checkPivotGroupLimit(api.PivotGroupLimit o) {
  buildCounterPivotGroupLimit++;
  if (buildCounterPivotGroupLimit < 3) {
    unittest.expect(
      o.applyOrder!,
      unittest.equals(42),
    );
    unittest.expect(
      o.countLimit!,
      unittest.equals(42),
    );
  }
  buildCounterPivotGroupLimit--;
}

core.int buildCounterPivotGroupRule = 0;
api.PivotGroupRule buildPivotGroupRule() {
  var o = api.PivotGroupRule();
  buildCounterPivotGroupRule++;
  if (buildCounterPivotGroupRule < 3) {
    o.dateTimeRule = buildDateTimeRule();
    o.histogramRule = buildHistogramRule();
    o.manualRule = buildManualRule();
  }
  buildCounterPivotGroupRule--;
  return o;
}

void checkPivotGroupRule(api.PivotGroupRule o) {
  buildCounterPivotGroupRule++;
  if (buildCounterPivotGroupRule < 3) {
    checkDateTimeRule(o.dateTimeRule! as api.DateTimeRule);
    checkHistogramRule(o.histogramRule! as api.HistogramRule);
    checkManualRule(o.manualRule! as api.ManualRule);
  }
  buildCounterPivotGroupRule--;
}

core.List<api.ExtendedValue> buildUnnamed709() {
  var o = <api.ExtendedValue>[];
  o.add(buildExtendedValue());
  o.add(buildExtendedValue());
  return o;
}

void checkUnnamed709(core.List<api.ExtendedValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExtendedValue(o[0] as api.ExtendedValue);
  checkExtendedValue(o[1] as api.ExtendedValue);
}

core.int buildCounterPivotGroupSortValueBucket = 0;
api.PivotGroupSortValueBucket buildPivotGroupSortValueBucket() {
  var o = api.PivotGroupSortValueBucket();
  buildCounterPivotGroupSortValueBucket++;
  if (buildCounterPivotGroupSortValueBucket < 3) {
    o.buckets = buildUnnamed709();
    o.valuesIndex = 42;
  }
  buildCounterPivotGroupSortValueBucket--;
  return o;
}

void checkPivotGroupSortValueBucket(api.PivotGroupSortValueBucket o) {
  buildCounterPivotGroupSortValueBucket++;
  if (buildCounterPivotGroupSortValueBucket < 3) {
    checkUnnamed709(o.buckets!);
    unittest.expect(
      o.valuesIndex!,
      unittest.equals(42),
    );
  }
  buildCounterPivotGroupSortValueBucket--;
}

core.int buildCounterPivotGroupValueMetadata = 0;
api.PivotGroupValueMetadata buildPivotGroupValueMetadata() {
  var o = api.PivotGroupValueMetadata();
  buildCounterPivotGroupValueMetadata++;
  if (buildCounterPivotGroupValueMetadata < 3) {
    o.collapsed = true;
    o.value = buildExtendedValue();
  }
  buildCounterPivotGroupValueMetadata--;
  return o;
}

void checkPivotGroupValueMetadata(api.PivotGroupValueMetadata o) {
  buildCounterPivotGroupValueMetadata++;
  if (buildCounterPivotGroupValueMetadata < 3) {
    unittest.expect(o.collapsed!, unittest.isTrue);
    checkExtendedValue(o.value! as api.ExtendedValue);
  }
  buildCounterPivotGroupValueMetadata--;
}

core.List<api.PivotGroup> buildUnnamed710() {
  var o = <api.PivotGroup>[];
  o.add(buildPivotGroup());
  o.add(buildPivotGroup());
  return o;
}

void checkUnnamed710(core.List<api.PivotGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotGroup(o[0] as api.PivotGroup);
  checkPivotGroup(o[1] as api.PivotGroup);
}

core.Map<core.String, api.PivotFilterCriteria> buildUnnamed711() {
  var o = <core.String, api.PivotFilterCriteria>{};
  o['x'] = buildPivotFilterCriteria();
  o['y'] = buildPivotFilterCriteria();
  return o;
}

void checkUnnamed711(core.Map<core.String, api.PivotFilterCriteria> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotFilterCriteria(o['x']! as api.PivotFilterCriteria);
  checkPivotFilterCriteria(o['y']! as api.PivotFilterCriteria);
}

core.List<api.PivotFilterSpec> buildUnnamed712() {
  var o = <api.PivotFilterSpec>[];
  o.add(buildPivotFilterSpec());
  o.add(buildPivotFilterSpec());
  return o;
}

void checkUnnamed712(core.List<api.PivotFilterSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotFilterSpec(o[0] as api.PivotFilterSpec);
  checkPivotFilterSpec(o[1] as api.PivotFilterSpec);
}

core.List<api.PivotGroup> buildUnnamed713() {
  var o = <api.PivotGroup>[];
  o.add(buildPivotGroup());
  o.add(buildPivotGroup());
  return o;
}

void checkUnnamed713(core.List<api.PivotGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotGroup(o[0] as api.PivotGroup);
  checkPivotGroup(o[1] as api.PivotGroup);
}

core.List<api.PivotValue> buildUnnamed714() {
  var o = <api.PivotValue>[];
  o.add(buildPivotValue());
  o.add(buildPivotValue());
  return o;
}

void checkUnnamed714(core.List<api.PivotValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotValue(o[0] as api.PivotValue);
  checkPivotValue(o[1] as api.PivotValue);
}

core.int buildCounterPivotTable = 0;
api.PivotTable buildPivotTable() {
  var o = api.PivotTable();
  buildCounterPivotTable++;
  if (buildCounterPivotTable < 3) {
    o.columns = buildUnnamed710();
    o.criteria = buildUnnamed711();
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.dataSourceId = 'foo';
    o.filterSpecs = buildUnnamed712();
    o.rows = buildUnnamed713();
    o.source = buildGridRange();
    o.valueLayout = 'foo';
    o.values = buildUnnamed714();
  }
  buildCounterPivotTable--;
  return o;
}

void checkPivotTable(api.PivotTable o) {
  buildCounterPivotTable++;
  if (buildCounterPivotTable < 3) {
    checkUnnamed710(o.columns!);
    checkUnnamed711(o.criteria!);
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
    checkUnnamed712(o.filterSpecs!);
    checkUnnamed713(o.rows!);
    checkGridRange(o.source! as api.GridRange);
    unittest.expect(
      o.valueLayout!,
      unittest.equals('foo'),
    );
    checkUnnamed714(o.values!);
  }
  buildCounterPivotTable--;
}

core.int buildCounterPivotValue = 0;
api.PivotValue buildPivotValue() {
  var o = api.PivotValue();
  buildCounterPivotValue++;
  if (buildCounterPivotValue < 3) {
    o.calculatedDisplayType = 'foo';
    o.dataSourceColumnReference = buildDataSourceColumnReference();
    o.formula = 'foo';
    o.name = 'foo';
    o.sourceColumnOffset = 42;
    o.summarizeFunction = 'foo';
  }
  buildCounterPivotValue--;
  return o;
}

void checkPivotValue(api.PivotValue o) {
  buildCounterPivotValue++;
  if (buildCounterPivotValue < 3) {
    unittest.expect(
      o.calculatedDisplayType!,
      unittest.equals('foo'),
    );
    checkDataSourceColumnReference(
        o.dataSourceColumnReference! as api.DataSourceColumnReference);
    unittest.expect(
      o.formula!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceColumnOffset!,
      unittest.equals(42),
    );
    unittest.expect(
      o.summarizeFunction!,
      unittest.equals('foo'),
    );
  }
  buildCounterPivotValue--;
}

core.int buildCounterPointStyle = 0;
api.PointStyle buildPointStyle() {
  var o = api.PointStyle();
  buildCounterPointStyle++;
  if (buildCounterPointStyle < 3) {
    o.shape = 'foo';
    o.size = 42.0;
  }
  buildCounterPointStyle--;
  return o;
}

void checkPointStyle(api.PointStyle o) {
  buildCounterPointStyle++;
  if (buildCounterPointStyle < 3) {
    unittest.expect(
      o.shape!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals(42.0),
    );
  }
  buildCounterPointStyle--;
}

core.List<api.GridRange> buildUnnamed715() {
  var o = <api.GridRange>[];
  o.add(buildGridRange());
  o.add(buildGridRange());
  return o;
}

void checkUnnamed715(core.List<api.GridRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGridRange(o[0] as api.GridRange);
  checkGridRange(o[1] as api.GridRange);
}

core.int buildCounterProtectedRange = 0;
api.ProtectedRange buildProtectedRange() {
  var o = api.ProtectedRange();
  buildCounterProtectedRange++;
  if (buildCounterProtectedRange < 3) {
    o.description = 'foo';
    o.editors = buildEditors();
    o.namedRangeId = 'foo';
    o.protectedRangeId = 42;
    o.range = buildGridRange();
    o.requestingUserCanEdit = true;
    o.unprotectedRanges = buildUnnamed715();
    o.warningOnly = true;
  }
  buildCounterProtectedRange--;
  return o;
}

void checkProtectedRange(api.ProtectedRange o) {
  buildCounterProtectedRange++;
  if (buildCounterProtectedRange < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkEditors(o.editors! as api.Editors);
    unittest.expect(
      o.namedRangeId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectedRangeId!,
      unittest.equals(42),
    );
    checkGridRange(o.range! as api.GridRange);
    unittest.expect(o.requestingUserCanEdit!, unittest.isTrue);
    checkUnnamed715(o.unprotectedRanges!);
    unittest.expect(o.warningOnly!, unittest.isTrue);
  }
  buildCounterProtectedRange--;
}

core.int buildCounterRandomizeRangeRequest = 0;
api.RandomizeRangeRequest buildRandomizeRangeRequest() {
  var o = api.RandomizeRangeRequest();
  buildCounterRandomizeRangeRequest++;
  if (buildCounterRandomizeRangeRequest < 3) {
    o.range = buildGridRange();
  }
  buildCounterRandomizeRangeRequest--;
  return o;
}

void checkRandomizeRangeRequest(api.RandomizeRangeRequest o) {
  buildCounterRandomizeRangeRequest++;
  if (buildCounterRandomizeRangeRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterRandomizeRangeRequest--;
}

core.int buildCounterRefreshDataSourceObjectExecutionStatus = 0;
api.RefreshDataSourceObjectExecutionStatus
    buildRefreshDataSourceObjectExecutionStatus() {
  var o = api.RefreshDataSourceObjectExecutionStatus();
  buildCounterRefreshDataSourceObjectExecutionStatus++;
  if (buildCounterRefreshDataSourceObjectExecutionStatus < 3) {
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.reference = buildDataSourceObjectReference();
  }
  buildCounterRefreshDataSourceObjectExecutionStatus--;
  return o;
}

void checkRefreshDataSourceObjectExecutionStatus(
    api.RefreshDataSourceObjectExecutionStatus o) {
  buildCounterRefreshDataSourceObjectExecutionStatus++;
  if (buildCounterRefreshDataSourceObjectExecutionStatus < 3) {
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    checkDataSourceObjectReference(
        o.reference! as api.DataSourceObjectReference);
  }
  buildCounterRefreshDataSourceObjectExecutionStatus--;
}

core.int buildCounterRefreshDataSourceRequest = 0;
api.RefreshDataSourceRequest buildRefreshDataSourceRequest() {
  var o = api.RefreshDataSourceRequest();
  buildCounterRefreshDataSourceRequest++;
  if (buildCounterRefreshDataSourceRequest < 3) {
    o.dataSourceId = 'foo';
    o.force = true;
    o.isAll = true;
    o.references = buildDataSourceObjectReferences();
  }
  buildCounterRefreshDataSourceRequest--;
  return o;
}

void checkRefreshDataSourceRequest(api.RefreshDataSourceRequest o) {
  buildCounterRefreshDataSourceRequest++;
  if (buildCounterRefreshDataSourceRequest < 3) {
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.force!, unittest.isTrue);
    unittest.expect(o.isAll!, unittest.isTrue);
    checkDataSourceObjectReferences(
        o.references! as api.DataSourceObjectReferences);
  }
  buildCounterRefreshDataSourceRequest--;
}

core.List<api.RefreshDataSourceObjectExecutionStatus> buildUnnamed716() {
  var o = <api.RefreshDataSourceObjectExecutionStatus>[];
  o.add(buildRefreshDataSourceObjectExecutionStatus());
  o.add(buildRefreshDataSourceObjectExecutionStatus());
  return o;
}

void checkUnnamed716(core.List<api.RefreshDataSourceObjectExecutionStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRefreshDataSourceObjectExecutionStatus(
      o[0] as api.RefreshDataSourceObjectExecutionStatus);
  checkRefreshDataSourceObjectExecutionStatus(
      o[1] as api.RefreshDataSourceObjectExecutionStatus);
}

core.int buildCounterRefreshDataSourceResponse = 0;
api.RefreshDataSourceResponse buildRefreshDataSourceResponse() {
  var o = api.RefreshDataSourceResponse();
  buildCounterRefreshDataSourceResponse++;
  if (buildCounterRefreshDataSourceResponse < 3) {
    o.statuses = buildUnnamed716();
  }
  buildCounterRefreshDataSourceResponse--;
  return o;
}

void checkRefreshDataSourceResponse(api.RefreshDataSourceResponse o) {
  buildCounterRefreshDataSourceResponse++;
  if (buildCounterRefreshDataSourceResponse < 3) {
    checkUnnamed716(o.statuses!);
  }
  buildCounterRefreshDataSourceResponse--;
}

core.int buildCounterRepeatCellRequest = 0;
api.RepeatCellRequest buildRepeatCellRequest() {
  var o = api.RepeatCellRequest();
  buildCounterRepeatCellRequest++;
  if (buildCounterRepeatCellRequest < 3) {
    o.cell = buildCellData();
    o.fields = 'foo';
    o.range = buildGridRange();
  }
  buildCounterRepeatCellRequest--;
  return o;
}

void checkRepeatCellRequest(api.RepeatCellRequest o) {
  buildCounterRepeatCellRequest++;
  if (buildCounterRepeatCellRequest < 3) {
    checkCellData(o.cell! as api.CellData);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterRepeatCellRequest--;
}

core.int buildCounterRequest = 0;
api.Request buildRequest() {
  var o = api.Request();
  buildCounterRequest++;
  if (buildCounterRequest < 3) {
    o.addBanding = buildAddBandingRequest();
    o.addChart = buildAddChartRequest();
    o.addConditionalFormatRule = buildAddConditionalFormatRuleRequest();
    o.addDataSource = buildAddDataSourceRequest();
    o.addDimensionGroup = buildAddDimensionGroupRequest();
    o.addFilterView = buildAddFilterViewRequest();
    o.addNamedRange = buildAddNamedRangeRequest();
    o.addProtectedRange = buildAddProtectedRangeRequest();
    o.addSheet = buildAddSheetRequest();
    o.addSlicer = buildAddSlicerRequest();
    o.appendCells = buildAppendCellsRequest();
    o.appendDimension = buildAppendDimensionRequest();
    o.autoFill = buildAutoFillRequest();
    o.autoResizeDimensions = buildAutoResizeDimensionsRequest();
    o.clearBasicFilter = buildClearBasicFilterRequest();
    o.copyPaste = buildCopyPasteRequest();
    o.createDeveloperMetadata = buildCreateDeveloperMetadataRequest();
    o.cutPaste = buildCutPasteRequest();
    o.deleteBanding = buildDeleteBandingRequest();
    o.deleteConditionalFormatRule = buildDeleteConditionalFormatRuleRequest();
    o.deleteDataSource = buildDeleteDataSourceRequest();
    o.deleteDeveloperMetadata = buildDeleteDeveloperMetadataRequest();
    o.deleteDimension = buildDeleteDimensionRequest();
    o.deleteDimensionGroup = buildDeleteDimensionGroupRequest();
    o.deleteDuplicates = buildDeleteDuplicatesRequest();
    o.deleteEmbeddedObject = buildDeleteEmbeddedObjectRequest();
    o.deleteFilterView = buildDeleteFilterViewRequest();
    o.deleteNamedRange = buildDeleteNamedRangeRequest();
    o.deleteProtectedRange = buildDeleteProtectedRangeRequest();
    o.deleteRange = buildDeleteRangeRequest();
    o.deleteSheet = buildDeleteSheetRequest();
    o.duplicateFilterView = buildDuplicateFilterViewRequest();
    o.duplicateSheet = buildDuplicateSheetRequest();
    o.findReplace = buildFindReplaceRequest();
    o.insertDimension = buildInsertDimensionRequest();
    o.insertRange = buildInsertRangeRequest();
    o.mergeCells = buildMergeCellsRequest();
    o.moveDimension = buildMoveDimensionRequest();
    o.pasteData = buildPasteDataRequest();
    o.randomizeRange = buildRandomizeRangeRequest();
    o.refreshDataSource = buildRefreshDataSourceRequest();
    o.repeatCell = buildRepeatCellRequest();
    o.setBasicFilter = buildSetBasicFilterRequest();
    o.setDataValidation = buildSetDataValidationRequest();
    o.sortRange = buildSortRangeRequest();
    o.textToColumns = buildTextToColumnsRequest();
    o.trimWhitespace = buildTrimWhitespaceRequest();
    o.unmergeCells = buildUnmergeCellsRequest();
    o.updateBanding = buildUpdateBandingRequest();
    o.updateBorders = buildUpdateBordersRequest();
    o.updateCells = buildUpdateCellsRequest();
    o.updateChartSpec = buildUpdateChartSpecRequest();
    o.updateConditionalFormatRule = buildUpdateConditionalFormatRuleRequest();
    o.updateDataSource = buildUpdateDataSourceRequest();
    o.updateDeveloperMetadata = buildUpdateDeveloperMetadataRequest();
    o.updateDimensionGroup = buildUpdateDimensionGroupRequest();
    o.updateDimensionProperties = buildUpdateDimensionPropertiesRequest();
    o.updateEmbeddedObjectBorder = buildUpdateEmbeddedObjectBorderRequest();
    o.updateEmbeddedObjectPosition = buildUpdateEmbeddedObjectPositionRequest();
    o.updateFilterView = buildUpdateFilterViewRequest();
    o.updateNamedRange = buildUpdateNamedRangeRequest();
    o.updateProtectedRange = buildUpdateProtectedRangeRequest();
    o.updateSheetProperties = buildUpdateSheetPropertiesRequest();
    o.updateSlicerSpec = buildUpdateSlicerSpecRequest();
    o.updateSpreadsheetProperties = buildUpdateSpreadsheetPropertiesRequest();
  }
  buildCounterRequest--;
  return o;
}

void checkRequest(api.Request o) {
  buildCounterRequest++;
  if (buildCounterRequest < 3) {
    checkAddBandingRequest(o.addBanding! as api.AddBandingRequest);
    checkAddChartRequest(o.addChart! as api.AddChartRequest);
    checkAddConditionalFormatRuleRequest(
        o.addConditionalFormatRule! as api.AddConditionalFormatRuleRequest);
    checkAddDataSourceRequest(o.addDataSource! as api.AddDataSourceRequest);
    checkAddDimensionGroupRequest(
        o.addDimensionGroup! as api.AddDimensionGroupRequest);
    checkAddFilterViewRequest(o.addFilterView! as api.AddFilterViewRequest);
    checkAddNamedRangeRequest(o.addNamedRange! as api.AddNamedRangeRequest);
    checkAddProtectedRangeRequest(
        o.addProtectedRange! as api.AddProtectedRangeRequest);
    checkAddSheetRequest(o.addSheet! as api.AddSheetRequest);
    checkAddSlicerRequest(o.addSlicer! as api.AddSlicerRequest);
    checkAppendCellsRequest(o.appendCells! as api.AppendCellsRequest);
    checkAppendDimensionRequest(
        o.appendDimension! as api.AppendDimensionRequest);
    checkAutoFillRequest(o.autoFill! as api.AutoFillRequest);
    checkAutoResizeDimensionsRequest(
        o.autoResizeDimensions! as api.AutoResizeDimensionsRequest);
    checkClearBasicFilterRequest(
        o.clearBasicFilter! as api.ClearBasicFilterRequest);
    checkCopyPasteRequest(o.copyPaste! as api.CopyPasteRequest);
    checkCreateDeveloperMetadataRequest(
        o.createDeveloperMetadata! as api.CreateDeveloperMetadataRequest);
    checkCutPasteRequest(o.cutPaste! as api.CutPasteRequest);
    checkDeleteBandingRequest(o.deleteBanding! as api.DeleteBandingRequest);
    checkDeleteConditionalFormatRuleRequest(o.deleteConditionalFormatRule!
        as api.DeleteConditionalFormatRuleRequest);
    checkDeleteDataSourceRequest(
        o.deleteDataSource! as api.DeleteDataSourceRequest);
    checkDeleteDeveloperMetadataRequest(
        o.deleteDeveloperMetadata! as api.DeleteDeveloperMetadataRequest);
    checkDeleteDimensionRequest(
        o.deleteDimension! as api.DeleteDimensionRequest);
    checkDeleteDimensionGroupRequest(
        o.deleteDimensionGroup! as api.DeleteDimensionGroupRequest);
    checkDeleteDuplicatesRequest(
        o.deleteDuplicates! as api.DeleteDuplicatesRequest);
    checkDeleteEmbeddedObjectRequest(
        o.deleteEmbeddedObject! as api.DeleteEmbeddedObjectRequest);
    checkDeleteFilterViewRequest(
        o.deleteFilterView! as api.DeleteFilterViewRequest);
    checkDeleteNamedRangeRequest(
        o.deleteNamedRange! as api.DeleteNamedRangeRequest);
    checkDeleteProtectedRangeRequest(
        o.deleteProtectedRange! as api.DeleteProtectedRangeRequest);
    checkDeleteRangeRequest(o.deleteRange! as api.DeleteRangeRequest);
    checkDeleteSheetRequest(o.deleteSheet! as api.DeleteSheetRequest);
    checkDuplicateFilterViewRequest(
        o.duplicateFilterView! as api.DuplicateFilterViewRequest);
    checkDuplicateSheetRequest(o.duplicateSheet! as api.DuplicateSheetRequest);
    checkFindReplaceRequest(o.findReplace! as api.FindReplaceRequest);
    checkInsertDimensionRequest(
        o.insertDimension! as api.InsertDimensionRequest);
    checkInsertRangeRequest(o.insertRange! as api.InsertRangeRequest);
    checkMergeCellsRequest(o.mergeCells! as api.MergeCellsRequest);
    checkMoveDimensionRequest(o.moveDimension! as api.MoveDimensionRequest);
    checkPasteDataRequest(o.pasteData! as api.PasteDataRequest);
    checkRandomizeRangeRequest(o.randomizeRange! as api.RandomizeRangeRequest);
    checkRefreshDataSourceRequest(
        o.refreshDataSource! as api.RefreshDataSourceRequest);
    checkRepeatCellRequest(o.repeatCell! as api.RepeatCellRequest);
    checkSetBasicFilterRequest(o.setBasicFilter! as api.SetBasicFilterRequest);
    checkSetDataValidationRequest(
        o.setDataValidation! as api.SetDataValidationRequest);
    checkSortRangeRequest(o.sortRange! as api.SortRangeRequest);
    checkTextToColumnsRequest(o.textToColumns! as api.TextToColumnsRequest);
    checkTrimWhitespaceRequest(o.trimWhitespace! as api.TrimWhitespaceRequest);
    checkUnmergeCellsRequest(o.unmergeCells! as api.UnmergeCellsRequest);
    checkUpdateBandingRequest(o.updateBanding! as api.UpdateBandingRequest);
    checkUpdateBordersRequest(o.updateBorders! as api.UpdateBordersRequest);
    checkUpdateCellsRequest(o.updateCells! as api.UpdateCellsRequest);
    checkUpdateChartSpecRequest(
        o.updateChartSpec! as api.UpdateChartSpecRequest);
    checkUpdateConditionalFormatRuleRequest(o.updateConditionalFormatRule!
        as api.UpdateConditionalFormatRuleRequest);
    checkUpdateDataSourceRequest(
        o.updateDataSource! as api.UpdateDataSourceRequest);
    checkUpdateDeveloperMetadataRequest(
        o.updateDeveloperMetadata! as api.UpdateDeveloperMetadataRequest);
    checkUpdateDimensionGroupRequest(
        o.updateDimensionGroup! as api.UpdateDimensionGroupRequest);
    checkUpdateDimensionPropertiesRequest(
        o.updateDimensionProperties! as api.UpdateDimensionPropertiesRequest);
    checkUpdateEmbeddedObjectBorderRequest(
        o.updateEmbeddedObjectBorder! as api.UpdateEmbeddedObjectBorderRequest);
    checkUpdateEmbeddedObjectPositionRequest(o.updateEmbeddedObjectPosition!
        as api.UpdateEmbeddedObjectPositionRequest);
    checkUpdateFilterViewRequest(
        o.updateFilterView! as api.UpdateFilterViewRequest);
    checkUpdateNamedRangeRequest(
        o.updateNamedRange! as api.UpdateNamedRangeRequest);
    checkUpdateProtectedRangeRequest(
        o.updateProtectedRange! as api.UpdateProtectedRangeRequest);
    checkUpdateSheetPropertiesRequest(
        o.updateSheetProperties! as api.UpdateSheetPropertiesRequest);
    checkUpdateSlicerSpecRequest(
        o.updateSlicerSpec! as api.UpdateSlicerSpecRequest);
    checkUpdateSpreadsheetPropertiesRequest(o.updateSpreadsheetProperties!
        as api.UpdateSpreadsheetPropertiesRequest);
  }
  buildCounterRequest--;
}

core.int buildCounterResponse = 0;
api.Response buildResponse() {
  var o = api.Response();
  buildCounterResponse++;
  if (buildCounterResponse < 3) {
    o.addBanding = buildAddBandingResponse();
    o.addChart = buildAddChartResponse();
    o.addDataSource = buildAddDataSourceResponse();
    o.addDimensionGroup = buildAddDimensionGroupResponse();
    o.addFilterView = buildAddFilterViewResponse();
    o.addNamedRange = buildAddNamedRangeResponse();
    o.addProtectedRange = buildAddProtectedRangeResponse();
    o.addSheet = buildAddSheetResponse();
    o.addSlicer = buildAddSlicerResponse();
    o.createDeveloperMetadata = buildCreateDeveloperMetadataResponse();
    o.deleteConditionalFormatRule = buildDeleteConditionalFormatRuleResponse();
    o.deleteDeveloperMetadata = buildDeleteDeveloperMetadataResponse();
    o.deleteDimensionGroup = buildDeleteDimensionGroupResponse();
    o.deleteDuplicates = buildDeleteDuplicatesResponse();
    o.duplicateFilterView = buildDuplicateFilterViewResponse();
    o.duplicateSheet = buildDuplicateSheetResponse();
    o.findReplace = buildFindReplaceResponse();
    o.refreshDataSource = buildRefreshDataSourceResponse();
    o.trimWhitespace = buildTrimWhitespaceResponse();
    o.updateConditionalFormatRule = buildUpdateConditionalFormatRuleResponse();
    o.updateDataSource = buildUpdateDataSourceResponse();
    o.updateDeveloperMetadata = buildUpdateDeveloperMetadataResponse();
    o.updateEmbeddedObjectPosition =
        buildUpdateEmbeddedObjectPositionResponse();
  }
  buildCounterResponse--;
  return o;
}

void checkResponse(api.Response o) {
  buildCounterResponse++;
  if (buildCounterResponse < 3) {
    checkAddBandingResponse(o.addBanding! as api.AddBandingResponse);
    checkAddChartResponse(o.addChart! as api.AddChartResponse);
    checkAddDataSourceResponse(o.addDataSource! as api.AddDataSourceResponse);
    checkAddDimensionGroupResponse(
        o.addDimensionGroup! as api.AddDimensionGroupResponse);
    checkAddFilterViewResponse(o.addFilterView! as api.AddFilterViewResponse);
    checkAddNamedRangeResponse(o.addNamedRange! as api.AddNamedRangeResponse);
    checkAddProtectedRangeResponse(
        o.addProtectedRange! as api.AddProtectedRangeResponse);
    checkAddSheetResponse(o.addSheet! as api.AddSheetResponse);
    checkAddSlicerResponse(o.addSlicer! as api.AddSlicerResponse);
    checkCreateDeveloperMetadataResponse(
        o.createDeveloperMetadata! as api.CreateDeveloperMetadataResponse);
    checkDeleteConditionalFormatRuleResponse(o.deleteConditionalFormatRule!
        as api.DeleteConditionalFormatRuleResponse);
    checkDeleteDeveloperMetadataResponse(
        o.deleteDeveloperMetadata! as api.DeleteDeveloperMetadataResponse);
    checkDeleteDimensionGroupResponse(
        o.deleteDimensionGroup! as api.DeleteDimensionGroupResponse);
    checkDeleteDuplicatesResponse(
        o.deleteDuplicates! as api.DeleteDuplicatesResponse);
    checkDuplicateFilterViewResponse(
        o.duplicateFilterView! as api.DuplicateFilterViewResponse);
    checkDuplicateSheetResponse(
        o.duplicateSheet! as api.DuplicateSheetResponse);
    checkFindReplaceResponse(o.findReplace! as api.FindReplaceResponse);
    checkRefreshDataSourceResponse(
        o.refreshDataSource! as api.RefreshDataSourceResponse);
    checkTrimWhitespaceResponse(
        o.trimWhitespace! as api.TrimWhitespaceResponse);
    checkUpdateConditionalFormatRuleResponse(o.updateConditionalFormatRule!
        as api.UpdateConditionalFormatRuleResponse);
    checkUpdateDataSourceResponse(
        o.updateDataSource! as api.UpdateDataSourceResponse);
    checkUpdateDeveloperMetadataResponse(
        o.updateDeveloperMetadata! as api.UpdateDeveloperMetadataResponse);
    checkUpdateEmbeddedObjectPositionResponse(o.updateEmbeddedObjectPosition!
        as api.UpdateEmbeddedObjectPositionResponse);
  }
  buildCounterResponse--;
}

core.List<api.CellData> buildUnnamed717() {
  var o = <api.CellData>[];
  o.add(buildCellData());
  o.add(buildCellData());
  return o;
}

void checkUnnamed717(core.List<api.CellData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCellData(o[0] as api.CellData);
  checkCellData(o[1] as api.CellData);
}

core.int buildCounterRowData = 0;
api.RowData buildRowData() {
  var o = api.RowData();
  buildCounterRowData++;
  if (buildCounterRowData < 3) {
    o.values = buildUnnamed717();
  }
  buildCounterRowData--;
  return o;
}

void checkRowData(api.RowData o) {
  buildCounterRowData++;
  if (buildCounterRowData < 3) {
    checkUnnamed717(o.values!);
  }
  buildCounterRowData--;
}

core.int buildCounterScorecardChartSpec = 0;
api.ScorecardChartSpec buildScorecardChartSpec() {
  var o = api.ScorecardChartSpec();
  buildCounterScorecardChartSpec++;
  if (buildCounterScorecardChartSpec < 3) {
    o.aggregateType = 'foo';
    o.baselineValueData = buildChartData();
    o.baselineValueFormat = buildBaselineValueFormat();
    o.customFormatOptions = buildChartCustomNumberFormatOptions();
    o.keyValueData = buildChartData();
    o.keyValueFormat = buildKeyValueFormat();
    o.numberFormatSource = 'foo';
    o.scaleFactor = 42.0;
  }
  buildCounterScorecardChartSpec--;
  return o;
}

void checkScorecardChartSpec(api.ScorecardChartSpec o) {
  buildCounterScorecardChartSpec++;
  if (buildCounterScorecardChartSpec < 3) {
    unittest.expect(
      o.aggregateType!,
      unittest.equals('foo'),
    );
    checkChartData(o.baselineValueData! as api.ChartData);
    checkBaselineValueFormat(o.baselineValueFormat! as api.BaselineValueFormat);
    checkChartCustomNumberFormatOptions(
        o.customFormatOptions! as api.ChartCustomNumberFormatOptions);
    checkChartData(o.keyValueData! as api.ChartData);
    checkKeyValueFormat(o.keyValueFormat! as api.KeyValueFormat);
    unittest.expect(
      o.numberFormatSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scaleFactor!,
      unittest.equals(42.0),
    );
  }
  buildCounterScorecardChartSpec--;
}

core.List<api.DataFilter> buildUnnamed718() {
  var o = <api.DataFilter>[];
  o.add(buildDataFilter());
  o.add(buildDataFilter());
  return o;
}

void checkUnnamed718(core.List<api.DataFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilter(o[0] as api.DataFilter);
  checkDataFilter(o[1] as api.DataFilter);
}

core.int buildCounterSearchDeveloperMetadataRequest = 0;
api.SearchDeveloperMetadataRequest buildSearchDeveloperMetadataRequest() {
  var o = api.SearchDeveloperMetadataRequest();
  buildCounterSearchDeveloperMetadataRequest++;
  if (buildCounterSearchDeveloperMetadataRequest < 3) {
    o.dataFilters = buildUnnamed718();
  }
  buildCounterSearchDeveloperMetadataRequest--;
  return o;
}

void checkSearchDeveloperMetadataRequest(api.SearchDeveloperMetadataRequest o) {
  buildCounterSearchDeveloperMetadataRequest++;
  if (buildCounterSearchDeveloperMetadataRequest < 3) {
    checkUnnamed718(o.dataFilters!);
  }
  buildCounterSearchDeveloperMetadataRequest--;
}

core.List<api.MatchedDeveloperMetadata> buildUnnamed719() {
  var o = <api.MatchedDeveloperMetadata>[];
  o.add(buildMatchedDeveloperMetadata());
  o.add(buildMatchedDeveloperMetadata());
  return o;
}

void checkUnnamed719(core.List<api.MatchedDeveloperMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMatchedDeveloperMetadata(o[0] as api.MatchedDeveloperMetadata);
  checkMatchedDeveloperMetadata(o[1] as api.MatchedDeveloperMetadata);
}

core.int buildCounterSearchDeveloperMetadataResponse = 0;
api.SearchDeveloperMetadataResponse buildSearchDeveloperMetadataResponse() {
  var o = api.SearchDeveloperMetadataResponse();
  buildCounterSearchDeveloperMetadataResponse++;
  if (buildCounterSearchDeveloperMetadataResponse < 3) {
    o.matchedDeveloperMetadata = buildUnnamed719();
  }
  buildCounterSearchDeveloperMetadataResponse--;
  return o;
}

void checkSearchDeveloperMetadataResponse(
    api.SearchDeveloperMetadataResponse o) {
  buildCounterSearchDeveloperMetadataResponse++;
  if (buildCounterSearchDeveloperMetadataResponse < 3) {
    checkUnnamed719(o.matchedDeveloperMetadata!);
  }
  buildCounterSearchDeveloperMetadataResponse--;
}

core.int buildCounterSetBasicFilterRequest = 0;
api.SetBasicFilterRequest buildSetBasicFilterRequest() {
  var o = api.SetBasicFilterRequest();
  buildCounterSetBasicFilterRequest++;
  if (buildCounterSetBasicFilterRequest < 3) {
    o.filter = buildBasicFilter();
  }
  buildCounterSetBasicFilterRequest--;
  return o;
}

void checkSetBasicFilterRequest(api.SetBasicFilterRequest o) {
  buildCounterSetBasicFilterRequest++;
  if (buildCounterSetBasicFilterRequest < 3) {
    checkBasicFilter(o.filter! as api.BasicFilter);
  }
  buildCounterSetBasicFilterRequest--;
}

core.int buildCounterSetDataValidationRequest = 0;
api.SetDataValidationRequest buildSetDataValidationRequest() {
  var o = api.SetDataValidationRequest();
  buildCounterSetDataValidationRequest++;
  if (buildCounterSetDataValidationRequest < 3) {
    o.range = buildGridRange();
    o.rule = buildDataValidationRule();
  }
  buildCounterSetDataValidationRequest--;
  return o;
}

void checkSetDataValidationRequest(api.SetDataValidationRequest o) {
  buildCounterSetDataValidationRequest++;
  if (buildCounterSetDataValidationRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
    checkDataValidationRule(o.rule! as api.DataValidationRule);
  }
  buildCounterSetDataValidationRequest--;
}

core.List<api.BandedRange> buildUnnamed720() {
  var o = <api.BandedRange>[];
  o.add(buildBandedRange());
  o.add(buildBandedRange());
  return o;
}

void checkUnnamed720(core.List<api.BandedRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBandedRange(o[0] as api.BandedRange);
  checkBandedRange(o[1] as api.BandedRange);
}

core.List<api.EmbeddedChart> buildUnnamed721() {
  var o = <api.EmbeddedChart>[];
  o.add(buildEmbeddedChart());
  o.add(buildEmbeddedChart());
  return o;
}

void checkUnnamed721(core.List<api.EmbeddedChart> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEmbeddedChart(o[0] as api.EmbeddedChart);
  checkEmbeddedChart(o[1] as api.EmbeddedChart);
}

core.List<api.DimensionGroup> buildUnnamed722() {
  var o = <api.DimensionGroup>[];
  o.add(buildDimensionGroup());
  o.add(buildDimensionGroup());
  return o;
}

void checkUnnamed722(core.List<api.DimensionGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionGroup(o[0] as api.DimensionGroup);
  checkDimensionGroup(o[1] as api.DimensionGroup);
}

core.List<api.ConditionalFormatRule> buildUnnamed723() {
  var o = <api.ConditionalFormatRule>[];
  o.add(buildConditionalFormatRule());
  o.add(buildConditionalFormatRule());
  return o;
}

void checkUnnamed723(core.List<api.ConditionalFormatRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConditionalFormatRule(o[0] as api.ConditionalFormatRule);
  checkConditionalFormatRule(o[1] as api.ConditionalFormatRule);
}

core.List<api.GridData> buildUnnamed724() {
  var o = <api.GridData>[];
  o.add(buildGridData());
  o.add(buildGridData());
  return o;
}

void checkUnnamed724(core.List<api.GridData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGridData(o[0] as api.GridData);
  checkGridData(o[1] as api.GridData);
}

core.List<api.DeveloperMetadata> buildUnnamed725() {
  var o = <api.DeveloperMetadata>[];
  o.add(buildDeveloperMetadata());
  o.add(buildDeveloperMetadata());
  return o;
}

void checkUnnamed725(core.List<api.DeveloperMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeveloperMetadata(o[0] as api.DeveloperMetadata);
  checkDeveloperMetadata(o[1] as api.DeveloperMetadata);
}

core.List<api.FilterView> buildUnnamed726() {
  var o = <api.FilterView>[];
  o.add(buildFilterView());
  o.add(buildFilterView());
  return o;
}

void checkUnnamed726(core.List<api.FilterView> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterView(o[0] as api.FilterView);
  checkFilterView(o[1] as api.FilterView);
}

core.List<api.GridRange> buildUnnamed727() {
  var o = <api.GridRange>[];
  o.add(buildGridRange());
  o.add(buildGridRange());
  return o;
}

void checkUnnamed727(core.List<api.GridRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGridRange(o[0] as api.GridRange);
  checkGridRange(o[1] as api.GridRange);
}

core.List<api.ProtectedRange> buildUnnamed728() {
  var o = <api.ProtectedRange>[];
  o.add(buildProtectedRange());
  o.add(buildProtectedRange());
  return o;
}

void checkUnnamed728(core.List<api.ProtectedRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProtectedRange(o[0] as api.ProtectedRange);
  checkProtectedRange(o[1] as api.ProtectedRange);
}

core.List<api.DimensionGroup> buildUnnamed729() {
  var o = <api.DimensionGroup>[];
  o.add(buildDimensionGroup());
  o.add(buildDimensionGroup());
  return o;
}

void checkUnnamed729(core.List<api.DimensionGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionGroup(o[0] as api.DimensionGroup);
  checkDimensionGroup(o[1] as api.DimensionGroup);
}

core.List<api.Slicer> buildUnnamed730() {
  var o = <api.Slicer>[];
  o.add(buildSlicer());
  o.add(buildSlicer());
  return o;
}

void checkUnnamed730(core.List<api.Slicer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSlicer(o[0] as api.Slicer);
  checkSlicer(o[1] as api.Slicer);
}

core.int buildCounterSheet = 0;
api.Sheet buildSheet() {
  var o = api.Sheet();
  buildCounterSheet++;
  if (buildCounterSheet < 3) {
    o.bandedRanges = buildUnnamed720();
    o.basicFilter = buildBasicFilter();
    o.charts = buildUnnamed721();
    o.columnGroups = buildUnnamed722();
    o.conditionalFormats = buildUnnamed723();
    o.data = buildUnnamed724();
    o.developerMetadata = buildUnnamed725();
    o.filterViews = buildUnnamed726();
    o.merges = buildUnnamed727();
    o.properties = buildSheetProperties();
    o.protectedRanges = buildUnnamed728();
    o.rowGroups = buildUnnamed729();
    o.slicers = buildUnnamed730();
  }
  buildCounterSheet--;
  return o;
}

void checkSheet(api.Sheet o) {
  buildCounterSheet++;
  if (buildCounterSheet < 3) {
    checkUnnamed720(o.bandedRanges!);
    checkBasicFilter(o.basicFilter! as api.BasicFilter);
    checkUnnamed721(o.charts!);
    checkUnnamed722(o.columnGroups!);
    checkUnnamed723(o.conditionalFormats!);
    checkUnnamed724(o.data!);
    checkUnnamed725(o.developerMetadata!);
    checkUnnamed726(o.filterViews!);
    checkUnnamed727(o.merges!);
    checkSheetProperties(o.properties! as api.SheetProperties);
    checkUnnamed728(o.protectedRanges!);
    checkUnnamed729(o.rowGroups!);
    checkUnnamed730(o.slicers!);
  }
  buildCounterSheet--;
}

core.int buildCounterSheetProperties = 0;
api.SheetProperties buildSheetProperties() {
  var o = api.SheetProperties();
  buildCounterSheetProperties++;
  if (buildCounterSheetProperties < 3) {
    o.dataSourceSheetProperties = buildDataSourceSheetProperties();
    o.gridProperties = buildGridProperties();
    o.hidden = true;
    o.index = 42;
    o.rightToLeft = true;
    o.sheetId = 42;
    o.sheetType = 'foo';
    o.tabColor = buildColor();
    o.tabColorStyle = buildColorStyle();
    o.title = 'foo';
  }
  buildCounterSheetProperties--;
  return o;
}

void checkSheetProperties(api.SheetProperties o) {
  buildCounterSheetProperties++;
  if (buildCounterSheetProperties < 3) {
    checkDataSourceSheetProperties(
        o.dataSourceSheetProperties! as api.DataSourceSheetProperties);
    checkGridProperties(o.gridProperties! as api.GridProperties);
    unittest.expect(o.hidden!, unittest.isTrue);
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(o.rightToLeft!, unittest.isTrue);
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sheetType!,
      unittest.equals('foo'),
    );
    checkColor(o.tabColor! as api.Color);
    checkColorStyle(o.tabColorStyle! as api.ColorStyle);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterSheetProperties--;
}

core.int buildCounterSlicer = 0;
api.Slicer buildSlicer() {
  var o = api.Slicer();
  buildCounterSlicer++;
  if (buildCounterSlicer < 3) {
    o.position = buildEmbeddedObjectPosition();
    o.slicerId = 42;
    o.spec = buildSlicerSpec();
  }
  buildCounterSlicer--;
  return o;
}

void checkSlicer(api.Slicer o) {
  buildCounterSlicer++;
  if (buildCounterSlicer < 3) {
    checkEmbeddedObjectPosition(o.position! as api.EmbeddedObjectPosition);
    unittest.expect(
      o.slicerId!,
      unittest.equals(42),
    );
    checkSlicerSpec(o.spec! as api.SlicerSpec);
  }
  buildCounterSlicer--;
}

core.int buildCounterSlicerSpec = 0;
api.SlicerSpec buildSlicerSpec() {
  var o = api.SlicerSpec();
  buildCounterSlicerSpec++;
  if (buildCounterSlicerSpec < 3) {
    o.applyToPivotTables = true;
    o.backgroundColor = buildColor();
    o.backgroundColorStyle = buildColorStyle();
    o.columnIndex = 42;
    o.dataRange = buildGridRange();
    o.filterCriteria = buildFilterCriteria();
    o.horizontalAlignment = 'foo';
    o.textFormat = buildTextFormat();
    o.title = 'foo';
  }
  buildCounterSlicerSpec--;
  return o;
}

void checkSlicerSpec(api.SlicerSpec o) {
  buildCounterSlicerSpec++;
  if (buildCounterSlicerSpec < 3) {
    unittest.expect(o.applyToPivotTables!, unittest.isTrue);
    checkColor(o.backgroundColor! as api.Color);
    checkColorStyle(o.backgroundColorStyle! as api.ColorStyle);
    unittest.expect(
      o.columnIndex!,
      unittest.equals(42),
    );
    checkGridRange(o.dataRange! as api.GridRange);
    checkFilterCriteria(o.filterCriteria! as api.FilterCriteria);
    unittest.expect(
      o.horizontalAlignment!,
      unittest.equals('foo'),
    );
    checkTextFormat(o.textFormat! as api.TextFormat);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterSlicerSpec--;
}

core.List<api.SortSpec> buildUnnamed731() {
  var o = <api.SortSpec>[];
  o.add(buildSortSpec());
  o.add(buildSortSpec());
  return o;
}

void checkUnnamed731(core.List<api.SortSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSortSpec(o[0] as api.SortSpec);
  checkSortSpec(o[1] as api.SortSpec);
}

core.int buildCounterSortRangeRequest = 0;
api.SortRangeRequest buildSortRangeRequest() {
  var o = api.SortRangeRequest();
  buildCounterSortRangeRequest++;
  if (buildCounterSortRangeRequest < 3) {
    o.range = buildGridRange();
    o.sortSpecs = buildUnnamed731();
  }
  buildCounterSortRangeRequest--;
  return o;
}

void checkSortRangeRequest(api.SortRangeRequest o) {
  buildCounterSortRangeRequest++;
  if (buildCounterSortRangeRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
    checkUnnamed731(o.sortSpecs!);
  }
  buildCounterSortRangeRequest--;
}

core.int buildCounterSortSpec = 0;
api.SortSpec buildSortSpec() {
  var o = api.SortSpec();
  buildCounterSortSpec++;
  if (buildCounterSortSpec < 3) {
    o.backgroundColor = buildColor();
    o.backgroundColorStyle = buildColorStyle();
    o.dataSourceColumnReference = buildDataSourceColumnReference();
    o.dimensionIndex = 42;
    o.foregroundColor = buildColor();
    o.foregroundColorStyle = buildColorStyle();
    o.sortOrder = 'foo';
  }
  buildCounterSortSpec--;
  return o;
}

void checkSortSpec(api.SortSpec o) {
  buildCounterSortSpec++;
  if (buildCounterSortSpec < 3) {
    checkColor(o.backgroundColor! as api.Color);
    checkColorStyle(o.backgroundColorStyle! as api.ColorStyle);
    checkDataSourceColumnReference(
        o.dataSourceColumnReference! as api.DataSourceColumnReference);
    unittest.expect(
      o.dimensionIndex!,
      unittest.equals(42),
    );
    checkColor(o.foregroundColor! as api.Color);
    checkColorStyle(o.foregroundColorStyle! as api.ColorStyle);
    unittest.expect(
      o.sortOrder!,
      unittest.equals('foo'),
    );
  }
  buildCounterSortSpec--;
}

core.int buildCounterSourceAndDestination = 0;
api.SourceAndDestination buildSourceAndDestination() {
  var o = api.SourceAndDestination();
  buildCounterSourceAndDestination++;
  if (buildCounterSourceAndDestination < 3) {
    o.dimension = 'foo';
    o.fillLength = 42;
    o.source = buildGridRange();
  }
  buildCounterSourceAndDestination--;
  return o;
}

void checkSourceAndDestination(api.SourceAndDestination o) {
  buildCounterSourceAndDestination++;
  if (buildCounterSourceAndDestination < 3) {
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fillLength!,
      unittest.equals(42),
    );
    checkGridRange(o.source! as api.GridRange);
  }
  buildCounterSourceAndDestination--;
}

core.List<api.DataSourceRefreshSchedule> buildUnnamed732() {
  var o = <api.DataSourceRefreshSchedule>[];
  o.add(buildDataSourceRefreshSchedule());
  o.add(buildDataSourceRefreshSchedule());
  return o;
}

void checkUnnamed732(core.List<api.DataSourceRefreshSchedule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceRefreshSchedule(o[0] as api.DataSourceRefreshSchedule);
  checkDataSourceRefreshSchedule(o[1] as api.DataSourceRefreshSchedule);
}

core.List<api.DataSource> buildUnnamed733() {
  var o = <api.DataSource>[];
  o.add(buildDataSource());
  o.add(buildDataSource());
  return o;
}

void checkUnnamed733(core.List<api.DataSource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSource(o[0] as api.DataSource);
  checkDataSource(o[1] as api.DataSource);
}

core.List<api.DeveloperMetadata> buildUnnamed734() {
  var o = <api.DeveloperMetadata>[];
  o.add(buildDeveloperMetadata());
  o.add(buildDeveloperMetadata());
  return o;
}

void checkUnnamed734(core.List<api.DeveloperMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeveloperMetadata(o[0] as api.DeveloperMetadata);
  checkDeveloperMetadata(o[1] as api.DeveloperMetadata);
}

core.List<api.NamedRange> buildUnnamed735() {
  var o = <api.NamedRange>[];
  o.add(buildNamedRange());
  o.add(buildNamedRange());
  return o;
}

void checkUnnamed735(core.List<api.NamedRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNamedRange(o[0] as api.NamedRange);
  checkNamedRange(o[1] as api.NamedRange);
}

core.List<api.Sheet> buildUnnamed736() {
  var o = <api.Sheet>[];
  o.add(buildSheet());
  o.add(buildSheet());
  return o;
}

void checkUnnamed736(core.List<api.Sheet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSheet(o[0] as api.Sheet);
  checkSheet(o[1] as api.Sheet);
}

core.int buildCounterSpreadsheet = 0;
api.Spreadsheet buildSpreadsheet() {
  var o = api.Spreadsheet();
  buildCounterSpreadsheet++;
  if (buildCounterSpreadsheet < 3) {
    o.dataSourceSchedules = buildUnnamed732();
    o.dataSources = buildUnnamed733();
    o.developerMetadata = buildUnnamed734();
    o.namedRanges = buildUnnamed735();
    o.properties = buildSpreadsheetProperties();
    o.sheets = buildUnnamed736();
    o.spreadsheetId = 'foo';
    o.spreadsheetUrl = 'foo';
  }
  buildCounterSpreadsheet--;
  return o;
}

void checkSpreadsheet(api.Spreadsheet o) {
  buildCounterSpreadsheet++;
  if (buildCounterSpreadsheet < 3) {
    checkUnnamed732(o.dataSourceSchedules!);
    checkUnnamed733(o.dataSources!);
    checkUnnamed734(o.developerMetadata!);
    checkUnnamed735(o.namedRanges!);
    checkSpreadsheetProperties(o.properties! as api.SpreadsheetProperties);
    checkUnnamed736(o.sheets!);
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.spreadsheetUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterSpreadsheet--;
}

core.int buildCounterSpreadsheetProperties = 0;
api.SpreadsheetProperties buildSpreadsheetProperties() {
  var o = api.SpreadsheetProperties();
  buildCounterSpreadsheetProperties++;
  if (buildCounterSpreadsheetProperties < 3) {
    o.autoRecalc = 'foo';
    o.defaultFormat = buildCellFormat();
    o.iterativeCalculationSettings = buildIterativeCalculationSettings();
    o.locale = 'foo';
    o.spreadsheetTheme = buildSpreadsheetTheme();
    o.timeZone = 'foo';
    o.title = 'foo';
  }
  buildCounterSpreadsheetProperties--;
  return o;
}

void checkSpreadsheetProperties(api.SpreadsheetProperties o) {
  buildCounterSpreadsheetProperties++;
  if (buildCounterSpreadsheetProperties < 3) {
    unittest.expect(
      o.autoRecalc!,
      unittest.equals('foo'),
    );
    checkCellFormat(o.defaultFormat! as api.CellFormat);
    checkIterativeCalculationSettings(
        o.iterativeCalculationSettings! as api.IterativeCalculationSettings);
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    checkSpreadsheetTheme(o.spreadsheetTheme! as api.SpreadsheetTheme);
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterSpreadsheetProperties--;
}

core.List<api.ThemeColorPair> buildUnnamed737() {
  var o = <api.ThemeColorPair>[];
  o.add(buildThemeColorPair());
  o.add(buildThemeColorPair());
  return o;
}

void checkUnnamed737(core.List<api.ThemeColorPair> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkThemeColorPair(o[0] as api.ThemeColorPair);
  checkThemeColorPair(o[1] as api.ThemeColorPair);
}

core.int buildCounterSpreadsheetTheme = 0;
api.SpreadsheetTheme buildSpreadsheetTheme() {
  var o = api.SpreadsheetTheme();
  buildCounterSpreadsheetTheme++;
  if (buildCounterSpreadsheetTheme < 3) {
    o.primaryFontFamily = 'foo';
    o.themeColors = buildUnnamed737();
  }
  buildCounterSpreadsheetTheme--;
  return o;
}

void checkSpreadsheetTheme(api.SpreadsheetTheme o) {
  buildCounterSpreadsheetTheme++;
  if (buildCounterSpreadsheetTheme < 3) {
    unittest.expect(
      o.primaryFontFamily!,
      unittest.equals('foo'),
    );
    checkUnnamed737(o.themeColors!);
  }
  buildCounterSpreadsheetTheme--;
}

core.int buildCounterTextFormat = 0;
api.TextFormat buildTextFormat() {
  var o = api.TextFormat();
  buildCounterTextFormat++;
  if (buildCounterTextFormat < 3) {
    o.bold = true;
    o.fontFamily = 'foo';
    o.fontSize = 42;
    o.foregroundColor = buildColor();
    o.foregroundColorStyle = buildColorStyle();
    o.italic = true;
    o.link = buildLink();
    o.strikethrough = true;
    o.underline = true;
  }
  buildCounterTextFormat--;
  return o;
}

void checkTextFormat(api.TextFormat o) {
  buildCounterTextFormat++;
  if (buildCounterTextFormat < 3) {
    unittest.expect(o.bold!, unittest.isTrue);
    unittest.expect(
      o.fontFamily!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fontSize!,
      unittest.equals(42),
    );
    checkColor(o.foregroundColor! as api.Color);
    checkColorStyle(o.foregroundColorStyle! as api.ColorStyle);
    unittest.expect(o.italic!, unittest.isTrue);
    checkLink(o.link! as api.Link);
    unittest.expect(o.strikethrough!, unittest.isTrue);
    unittest.expect(o.underline!, unittest.isTrue);
  }
  buildCounterTextFormat--;
}

core.int buildCounterTextFormatRun = 0;
api.TextFormatRun buildTextFormatRun() {
  var o = api.TextFormatRun();
  buildCounterTextFormatRun++;
  if (buildCounterTextFormatRun < 3) {
    o.format = buildTextFormat();
    o.startIndex = 42;
  }
  buildCounterTextFormatRun--;
  return o;
}

void checkTextFormatRun(api.TextFormatRun o) {
  buildCounterTextFormatRun++;
  if (buildCounterTextFormatRun < 3) {
    checkTextFormat(o.format! as api.TextFormat);
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
  }
  buildCounterTextFormatRun--;
}

core.int buildCounterTextPosition = 0;
api.TextPosition buildTextPosition() {
  var o = api.TextPosition();
  buildCounterTextPosition++;
  if (buildCounterTextPosition < 3) {
    o.horizontalAlignment = 'foo';
  }
  buildCounterTextPosition--;
  return o;
}

void checkTextPosition(api.TextPosition o) {
  buildCounterTextPosition++;
  if (buildCounterTextPosition < 3) {
    unittest.expect(
      o.horizontalAlignment!,
      unittest.equals('foo'),
    );
  }
  buildCounterTextPosition--;
}

core.int buildCounterTextRotation = 0;
api.TextRotation buildTextRotation() {
  var o = api.TextRotation();
  buildCounterTextRotation++;
  if (buildCounterTextRotation < 3) {
    o.angle = 42;
    o.vertical = true;
  }
  buildCounterTextRotation--;
  return o;
}

void checkTextRotation(api.TextRotation o) {
  buildCounterTextRotation++;
  if (buildCounterTextRotation < 3) {
    unittest.expect(
      o.angle!,
      unittest.equals(42),
    );
    unittest.expect(o.vertical!, unittest.isTrue);
  }
  buildCounterTextRotation--;
}

core.int buildCounterTextToColumnsRequest = 0;
api.TextToColumnsRequest buildTextToColumnsRequest() {
  var o = api.TextToColumnsRequest();
  buildCounterTextToColumnsRequest++;
  if (buildCounterTextToColumnsRequest < 3) {
    o.delimiter = 'foo';
    o.delimiterType = 'foo';
    o.source = buildGridRange();
  }
  buildCounterTextToColumnsRequest--;
  return o;
}

void checkTextToColumnsRequest(api.TextToColumnsRequest o) {
  buildCounterTextToColumnsRequest++;
  if (buildCounterTextToColumnsRequest < 3) {
    unittest.expect(
      o.delimiter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.delimiterType!,
      unittest.equals('foo'),
    );
    checkGridRange(o.source! as api.GridRange);
  }
  buildCounterTextToColumnsRequest--;
}

core.int buildCounterThemeColorPair = 0;
api.ThemeColorPair buildThemeColorPair() {
  var o = api.ThemeColorPair();
  buildCounterThemeColorPair++;
  if (buildCounterThemeColorPair < 3) {
    o.color = buildColorStyle();
    o.colorType = 'foo';
  }
  buildCounterThemeColorPair--;
  return o;
}

void checkThemeColorPair(api.ThemeColorPair o) {
  buildCounterThemeColorPair++;
  if (buildCounterThemeColorPair < 3) {
    checkColorStyle(o.color! as api.ColorStyle);
    unittest.expect(
      o.colorType!,
      unittest.equals('foo'),
    );
  }
  buildCounterThemeColorPair--;
}

core.int buildCounterTimeOfDay = 0;
api.TimeOfDay buildTimeOfDay() {
  var o = api.TimeOfDay();
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    o.hours = 42;
    o.minutes = 42;
    o.nanos = 42;
    o.seconds = 42;
  }
  buildCounterTimeOfDay--;
  return o;
}

void checkTimeOfDay(api.TimeOfDay o) {
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    unittest.expect(
      o.hours!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minutes!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.seconds!,
      unittest.equals(42),
    );
  }
  buildCounterTimeOfDay--;
}

core.int buildCounterTreemapChartColorScale = 0;
api.TreemapChartColorScale buildTreemapChartColorScale() {
  var o = api.TreemapChartColorScale();
  buildCounterTreemapChartColorScale++;
  if (buildCounterTreemapChartColorScale < 3) {
    o.maxValueColor = buildColor();
    o.maxValueColorStyle = buildColorStyle();
    o.midValueColor = buildColor();
    o.midValueColorStyle = buildColorStyle();
    o.minValueColor = buildColor();
    o.minValueColorStyle = buildColorStyle();
    o.noDataColor = buildColor();
    o.noDataColorStyle = buildColorStyle();
  }
  buildCounterTreemapChartColorScale--;
  return o;
}

void checkTreemapChartColorScale(api.TreemapChartColorScale o) {
  buildCounterTreemapChartColorScale++;
  if (buildCounterTreemapChartColorScale < 3) {
    checkColor(o.maxValueColor! as api.Color);
    checkColorStyle(o.maxValueColorStyle! as api.ColorStyle);
    checkColor(o.midValueColor! as api.Color);
    checkColorStyle(o.midValueColorStyle! as api.ColorStyle);
    checkColor(o.minValueColor! as api.Color);
    checkColorStyle(o.minValueColorStyle! as api.ColorStyle);
    checkColor(o.noDataColor! as api.Color);
    checkColorStyle(o.noDataColorStyle! as api.ColorStyle);
  }
  buildCounterTreemapChartColorScale--;
}

core.int buildCounterTreemapChartSpec = 0;
api.TreemapChartSpec buildTreemapChartSpec() {
  var o = api.TreemapChartSpec();
  buildCounterTreemapChartSpec++;
  if (buildCounterTreemapChartSpec < 3) {
    o.colorData = buildChartData();
    o.colorScale = buildTreemapChartColorScale();
    o.headerColor = buildColor();
    o.headerColorStyle = buildColorStyle();
    o.hideTooltips = true;
    o.hintedLevels = 42;
    o.labels = buildChartData();
    o.levels = 42;
    o.maxValue = 42.0;
    o.minValue = 42.0;
    o.parentLabels = buildChartData();
    o.sizeData = buildChartData();
    o.textFormat = buildTextFormat();
  }
  buildCounterTreemapChartSpec--;
  return o;
}

void checkTreemapChartSpec(api.TreemapChartSpec o) {
  buildCounterTreemapChartSpec++;
  if (buildCounterTreemapChartSpec < 3) {
    checkChartData(o.colorData! as api.ChartData);
    checkTreemapChartColorScale(o.colorScale! as api.TreemapChartColorScale);
    checkColor(o.headerColor! as api.Color);
    checkColorStyle(o.headerColorStyle! as api.ColorStyle);
    unittest.expect(o.hideTooltips!, unittest.isTrue);
    unittest.expect(
      o.hintedLevels!,
      unittest.equals(42),
    );
    checkChartData(o.labels! as api.ChartData);
    unittest.expect(
      o.levels!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.minValue!,
      unittest.equals(42.0),
    );
    checkChartData(o.parentLabels! as api.ChartData);
    checkChartData(o.sizeData! as api.ChartData);
    checkTextFormat(o.textFormat! as api.TextFormat);
  }
  buildCounterTreemapChartSpec--;
}

core.int buildCounterTrimWhitespaceRequest = 0;
api.TrimWhitespaceRequest buildTrimWhitespaceRequest() {
  var o = api.TrimWhitespaceRequest();
  buildCounterTrimWhitespaceRequest++;
  if (buildCounterTrimWhitespaceRequest < 3) {
    o.range = buildGridRange();
  }
  buildCounterTrimWhitespaceRequest--;
  return o;
}

void checkTrimWhitespaceRequest(api.TrimWhitespaceRequest o) {
  buildCounterTrimWhitespaceRequest++;
  if (buildCounterTrimWhitespaceRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterTrimWhitespaceRequest--;
}

core.int buildCounterTrimWhitespaceResponse = 0;
api.TrimWhitespaceResponse buildTrimWhitespaceResponse() {
  var o = api.TrimWhitespaceResponse();
  buildCounterTrimWhitespaceResponse++;
  if (buildCounterTrimWhitespaceResponse < 3) {
    o.cellsChangedCount = 42;
  }
  buildCounterTrimWhitespaceResponse--;
  return o;
}

void checkTrimWhitespaceResponse(api.TrimWhitespaceResponse o) {
  buildCounterTrimWhitespaceResponse++;
  if (buildCounterTrimWhitespaceResponse < 3) {
    unittest.expect(
      o.cellsChangedCount!,
      unittest.equals(42),
    );
  }
  buildCounterTrimWhitespaceResponse--;
}

core.int buildCounterUnmergeCellsRequest = 0;
api.UnmergeCellsRequest buildUnmergeCellsRequest() {
  var o = api.UnmergeCellsRequest();
  buildCounterUnmergeCellsRequest++;
  if (buildCounterUnmergeCellsRequest < 3) {
    o.range = buildGridRange();
  }
  buildCounterUnmergeCellsRequest--;
  return o;
}

void checkUnmergeCellsRequest(api.UnmergeCellsRequest o) {
  buildCounterUnmergeCellsRequest++;
  if (buildCounterUnmergeCellsRequest < 3) {
    checkGridRange(o.range! as api.GridRange);
  }
  buildCounterUnmergeCellsRequest--;
}

core.int buildCounterUpdateBandingRequest = 0;
api.UpdateBandingRequest buildUpdateBandingRequest() {
  var o = api.UpdateBandingRequest();
  buildCounterUpdateBandingRequest++;
  if (buildCounterUpdateBandingRequest < 3) {
    o.bandedRange = buildBandedRange();
    o.fields = 'foo';
  }
  buildCounterUpdateBandingRequest--;
  return o;
}

void checkUpdateBandingRequest(api.UpdateBandingRequest o) {
  buildCounterUpdateBandingRequest++;
  if (buildCounterUpdateBandingRequest < 3) {
    checkBandedRange(o.bandedRange! as api.BandedRange);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateBandingRequest--;
}

core.int buildCounterUpdateBordersRequest = 0;
api.UpdateBordersRequest buildUpdateBordersRequest() {
  var o = api.UpdateBordersRequest();
  buildCounterUpdateBordersRequest++;
  if (buildCounterUpdateBordersRequest < 3) {
    o.bottom = buildBorder();
    o.innerHorizontal = buildBorder();
    o.innerVertical = buildBorder();
    o.left = buildBorder();
    o.range = buildGridRange();
    o.right = buildBorder();
    o.top = buildBorder();
  }
  buildCounterUpdateBordersRequest--;
  return o;
}

void checkUpdateBordersRequest(api.UpdateBordersRequest o) {
  buildCounterUpdateBordersRequest++;
  if (buildCounterUpdateBordersRequest < 3) {
    checkBorder(o.bottom! as api.Border);
    checkBorder(o.innerHorizontal! as api.Border);
    checkBorder(o.innerVertical! as api.Border);
    checkBorder(o.left! as api.Border);
    checkGridRange(o.range! as api.GridRange);
    checkBorder(o.right! as api.Border);
    checkBorder(o.top! as api.Border);
  }
  buildCounterUpdateBordersRequest--;
}

core.List<api.RowData> buildUnnamed738() {
  var o = <api.RowData>[];
  o.add(buildRowData());
  o.add(buildRowData());
  return o;
}

void checkUnnamed738(core.List<api.RowData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRowData(o[0] as api.RowData);
  checkRowData(o[1] as api.RowData);
}

core.int buildCounterUpdateCellsRequest = 0;
api.UpdateCellsRequest buildUpdateCellsRequest() {
  var o = api.UpdateCellsRequest();
  buildCounterUpdateCellsRequest++;
  if (buildCounterUpdateCellsRequest < 3) {
    o.fields = 'foo';
    o.range = buildGridRange();
    o.rows = buildUnnamed738();
    o.start = buildGridCoordinate();
  }
  buildCounterUpdateCellsRequest--;
  return o;
}

void checkUpdateCellsRequest(api.UpdateCellsRequest o) {
  buildCounterUpdateCellsRequest++;
  if (buildCounterUpdateCellsRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkGridRange(o.range! as api.GridRange);
    checkUnnamed738(o.rows!);
    checkGridCoordinate(o.start! as api.GridCoordinate);
  }
  buildCounterUpdateCellsRequest--;
}

core.int buildCounterUpdateChartSpecRequest = 0;
api.UpdateChartSpecRequest buildUpdateChartSpecRequest() {
  var o = api.UpdateChartSpecRequest();
  buildCounterUpdateChartSpecRequest++;
  if (buildCounterUpdateChartSpecRequest < 3) {
    o.chartId = 42;
    o.spec = buildChartSpec();
  }
  buildCounterUpdateChartSpecRequest--;
  return o;
}

void checkUpdateChartSpecRequest(api.UpdateChartSpecRequest o) {
  buildCounterUpdateChartSpecRequest++;
  if (buildCounterUpdateChartSpecRequest < 3) {
    unittest.expect(
      o.chartId!,
      unittest.equals(42),
    );
    checkChartSpec(o.spec! as api.ChartSpec);
  }
  buildCounterUpdateChartSpecRequest--;
}

core.int buildCounterUpdateConditionalFormatRuleRequest = 0;
api.UpdateConditionalFormatRuleRequest
    buildUpdateConditionalFormatRuleRequest() {
  var o = api.UpdateConditionalFormatRuleRequest();
  buildCounterUpdateConditionalFormatRuleRequest++;
  if (buildCounterUpdateConditionalFormatRuleRequest < 3) {
    o.index = 42;
    o.newIndex = 42;
    o.rule = buildConditionalFormatRule();
    o.sheetId = 42;
  }
  buildCounterUpdateConditionalFormatRuleRequest--;
  return o;
}

void checkUpdateConditionalFormatRuleRequest(
    api.UpdateConditionalFormatRuleRequest o) {
  buildCounterUpdateConditionalFormatRuleRequest++;
  if (buildCounterUpdateConditionalFormatRuleRequest < 3) {
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.newIndex!,
      unittest.equals(42),
    );
    checkConditionalFormatRule(o.rule! as api.ConditionalFormatRule);
    unittest.expect(
      o.sheetId!,
      unittest.equals(42),
    );
  }
  buildCounterUpdateConditionalFormatRuleRequest--;
}

core.int buildCounterUpdateConditionalFormatRuleResponse = 0;
api.UpdateConditionalFormatRuleResponse
    buildUpdateConditionalFormatRuleResponse() {
  var o = api.UpdateConditionalFormatRuleResponse();
  buildCounterUpdateConditionalFormatRuleResponse++;
  if (buildCounterUpdateConditionalFormatRuleResponse < 3) {
    o.newIndex = 42;
    o.newRule = buildConditionalFormatRule();
    o.oldIndex = 42;
    o.oldRule = buildConditionalFormatRule();
  }
  buildCounterUpdateConditionalFormatRuleResponse--;
  return o;
}

void checkUpdateConditionalFormatRuleResponse(
    api.UpdateConditionalFormatRuleResponse o) {
  buildCounterUpdateConditionalFormatRuleResponse++;
  if (buildCounterUpdateConditionalFormatRuleResponse < 3) {
    unittest.expect(
      o.newIndex!,
      unittest.equals(42),
    );
    checkConditionalFormatRule(o.newRule! as api.ConditionalFormatRule);
    unittest.expect(
      o.oldIndex!,
      unittest.equals(42),
    );
    checkConditionalFormatRule(o.oldRule! as api.ConditionalFormatRule);
  }
  buildCounterUpdateConditionalFormatRuleResponse--;
}

core.int buildCounterUpdateDataSourceRequest = 0;
api.UpdateDataSourceRequest buildUpdateDataSourceRequest() {
  var o = api.UpdateDataSourceRequest();
  buildCounterUpdateDataSourceRequest++;
  if (buildCounterUpdateDataSourceRequest < 3) {
    o.dataSource = buildDataSource();
    o.fields = 'foo';
  }
  buildCounterUpdateDataSourceRequest--;
  return o;
}

void checkUpdateDataSourceRequest(api.UpdateDataSourceRequest o) {
  buildCounterUpdateDataSourceRequest++;
  if (buildCounterUpdateDataSourceRequest < 3) {
    checkDataSource(o.dataSource! as api.DataSource);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateDataSourceRequest--;
}

core.int buildCounterUpdateDataSourceResponse = 0;
api.UpdateDataSourceResponse buildUpdateDataSourceResponse() {
  var o = api.UpdateDataSourceResponse();
  buildCounterUpdateDataSourceResponse++;
  if (buildCounterUpdateDataSourceResponse < 3) {
    o.dataExecutionStatus = buildDataExecutionStatus();
    o.dataSource = buildDataSource();
  }
  buildCounterUpdateDataSourceResponse--;
  return o;
}

void checkUpdateDataSourceResponse(api.UpdateDataSourceResponse o) {
  buildCounterUpdateDataSourceResponse++;
  if (buildCounterUpdateDataSourceResponse < 3) {
    checkDataExecutionStatus(o.dataExecutionStatus! as api.DataExecutionStatus);
    checkDataSource(o.dataSource! as api.DataSource);
  }
  buildCounterUpdateDataSourceResponse--;
}

core.List<api.DataFilter> buildUnnamed739() {
  var o = <api.DataFilter>[];
  o.add(buildDataFilter());
  o.add(buildDataFilter());
  return o;
}

void checkUnnamed739(core.List<api.DataFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataFilter(o[0] as api.DataFilter);
  checkDataFilter(o[1] as api.DataFilter);
}

core.int buildCounterUpdateDeveloperMetadataRequest = 0;
api.UpdateDeveloperMetadataRequest buildUpdateDeveloperMetadataRequest() {
  var o = api.UpdateDeveloperMetadataRequest();
  buildCounterUpdateDeveloperMetadataRequest++;
  if (buildCounterUpdateDeveloperMetadataRequest < 3) {
    o.dataFilters = buildUnnamed739();
    o.developerMetadata = buildDeveloperMetadata();
    o.fields = 'foo';
  }
  buildCounterUpdateDeveloperMetadataRequest--;
  return o;
}

void checkUpdateDeveloperMetadataRequest(api.UpdateDeveloperMetadataRequest o) {
  buildCounterUpdateDeveloperMetadataRequest++;
  if (buildCounterUpdateDeveloperMetadataRequest < 3) {
    checkUnnamed739(o.dataFilters!);
    checkDeveloperMetadata(o.developerMetadata! as api.DeveloperMetadata);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateDeveloperMetadataRequest--;
}

core.List<api.DeveloperMetadata> buildUnnamed740() {
  var o = <api.DeveloperMetadata>[];
  o.add(buildDeveloperMetadata());
  o.add(buildDeveloperMetadata());
  return o;
}

void checkUnnamed740(core.List<api.DeveloperMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeveloperMetadata(o[0] as api.DeveloperMetadata);
  checkDeveloperMetadata(o[1] as api.DeveloperMetadata);
}

core.int buildCounterUpdateDeveloperMetadataResponse = 0;
api.UpdateDeveloperMetadataResponse buildUpdateDeveloperMetadataResponse() {
  var o = api.UpdateDeveloperMetadataResponse();
  buildCounterUpdateDeveloperMetadataResponse++;
  if (buildCounterUpdateDeveloperMetadataResponse < 3) {
    o.developerMetadata = buildUnnamed740();
  }
  buildCounterUpdateDeveloperMetadataResponse--;
  return o;
}

void checkUpdateDeveloperMetadataResponse(
    api.UpdateDeveloperMetadataResponse o) {
  buildCounterUpdateDeveloperMetadataResponse++;
  if (buildCounterUpdateDeveloperMetadataResponse < 3) {
    checkUnnamed740(o.developerMetadata!);
  }
  buildCounterUpdateDeveloperMetadataResponse--;
}

core.int buildCounterUpdateDimensionGroupRequest = 0;
api.UpdateDimensionGroupRequest buildUpdateDimensionGroupRequest() {
  var o = api.UpdateDimensionGroupRequest();
  buildCounterUpdateDimensionGroupRequest++;
  if (buildCounterUpdateDimensionGroupRequest < 3) {
    o.dimensionGroup = buildDimensionGroup();
    o.fields = 'foo';
  }
  buildCounterUpdateDimensionGroupRequest--;
  return o;
}

void checkUpdateDimensionGroupRequest(api.UpdateDimensionGroupRequest o) {
  buildCounterUpdateDimensionGroupRequest++;
  if (buildCounterUpdateDimensionGroupRequest < 3) {
    checkDimensionGroup(o.dimensionGroup! as api.DimensionGroup);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateDimensionGroupRequest--;
}

core.int buildCounterUpdateDimensionPropertiesRequest = 0;
api.UpdateDimensionPropertiesRequest buildUpdateDimensionPropertiesRequest() {
  var o = api.UpdateDimensionPropertiesRequest();
  buildCounterUpdateDimensionPropertiesRequest++;
  if (buildCounterUpdateDimensionPropertiesRequest < 3) {
    o.dataSourceSheetRange = buildDataSourceSheetDimensionRange();
    o.fields = 'foo';
    o.properties = buildDimensionProperties();
    o.range = buildDimensionRange();
  }
  buildCounterUpdateDimensionPropertiesRequest--;
  return o;
}

void checkUpdateDimensionPropertiesRequest(
    api.UpdateDimensionPropertiesRequest o) {
  buildCounterUpdateDimensionPropertiesRequest++;
  if (buildCounterUpdateDimensionPropertiesRequest < 3) {
    checkDataSourceSheetDimensionRange(
        o.dataSourceSheetRange! as api.DataSourceSheetDimensionRange);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkDimensionProperties(o.properties! as api.DimensionProperties);
    checkDimensionRange(o.range! as api.DimensionRange);
  }
  buildCounterUpdateDimensionPropertiesRequest--;
}

core.int buildCounterUpdateEmbeddedObjectBorderRequest = 0;
api.UpdateEmbeddedObjectBorderRequest buildUpdateEmbeddedObjectBorderRequest() {
  var o = api.UpdateEmbeddedObjectBorderRequest();
  buildCounterUpdateEmbeddedObjectBorderRequest++;
  if (buildCounterUpdateEmbeddedObjectBorderRequest < 3) {
    o.border = buildEmbeddedObjectBorder();
    o.fields = 'foo';
    o.objectId = 42;
  }
  buildCounterUpdateEmbeddedObjectBorderRequest--;
  return o;
}

void checkUpdateEmbeddedObjectBorderRequest(
    api.UpdateEmbeddedObjectBorderRequest o) {
  buildCounterUpdateEmbeddedObjectBorderRequest++;
  if (buildCounterUpdateEmbeddedObjectBorderRequest < 3) {
    checkEmbeddedObjectBorder(o.border! as api.EmbeddedObjectBorder);
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals(42),
    );
  }
  buildCounterUpdateEmbeddedObjectBorderRequest--;
}

core.int buildCounterUpdateEmbeddedObjectPositionRequest = 0;
api.UpdateEmbeddedObjectPositionRequest
    buildUpdateEmbeddedObjectPositionRequest() {
  var o = api.UpdateEmbeddedObjectPositionRequest();
  buildCounterUpdateEmbeddedObjectPositionRequest++;
  if (buildCounterUpdateEmbeddedObjectPositionRequest < 3) {
    o.fields = 'foo';
    o.newPosition = buildEmbeddedObjectPosition();
    o.objectId = 42;
  }
  buildCounterUpdateEmbeddedObjectPositionRequest--;
  return o;
}

void checkUpdateEmbeddedObjectPositionRequest(
    api.UpdateEmbeddedObjectPositionRequest o) {
  buildCounterUpdateEmbeddedObjectPositionRequest++;
  if (buildCounterUpdateEmbeddedObjectPositionRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkEmbeddedObjectPosition(o.newPosition! as api.EmbeddedObjectPosition);
    unittest.expect(
      o.objectId!,
      unittest.equals(42),
    );
  }
  buildCounterUpdateEmbeddedObjectPositionRequest--;
}

core.int buildCounterUpdateEmbeddedObjectPositionResponse = 0;
api.UpdateEmbeddedObjectPositionResponse
    buildUpdateEmbeddedObjectPositionResponse() {
  var o = api.UpdateEmbeddedObjectPositionResponse();
  buildCounterUpdateEmbeddedObjectPositionResponse++;
  if (buildCounterUpdateEmbeddedObjectPositionResponse < 3) {
    o.position = buildEmbeddedObjectPosition();
  }
  buildCounterUpdateEmbeddedObjectPositionResponse--;
  return o;
}

void checkUpdateEmbeddedObjectPositionResponse(
    api.UpdateEmbeddedObjectPositionResponse o) {
  buildCounterUpdateEmbeddedObjectPositionResponse++;
  if (buildCounterUpdateEmbeddedObjectPositionResponse < 3) {
    checkEmbeddedObjectPosition(o.position! as api.EmbeddedObjectPosition);
  }
  buildCounterUpdateEmbeddedObjectPositionResponse--;
}

core.int buildCounterUpdateFilterViewRequest = 0;
api.UpdateFilterViewRequest buildUpdateFilterViewRequest() {
  var o = api.UpdateFilterViewRequest();
  buildCounterUpdateFilterViewRequest++;
  if (buildCounterUpdateFilterViewRequest < 3) {
    o.fields = 'foo';
    o.filter = buildFilterView();
  }
  buildCounterUpdateFilterViewRequest--;
  return o;
}

void checkUpdateFilterViewRequest(api.UpdateFilterViewRequest o) {
  buildCounterUpdateFilterViewRequest++;
  if (buildCounterUpdateFilterViewRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkFilterView(o.filter! as api.FilterView);
  }
  buildCounterUpdateFilterViewRequest--;
}

core.int buildCounterUpdateNamedRangeRequest = 0;
api.UpdateNamedRangeRequest buildUpdateNamedRangeRequest() {
  var o = api.UpdateNamedRangeRequest();
  buildCounterUpdateNamedRangeRequest++;
  if (buildCounterUpdateNamedRangeRequest < 3) {
    o.fields = 'foo';
    o.namedRange = buildNamedRange();
  }
  buildCounterUpdateNamedRangeRequest--;
  return o;
}

void checkUpdateNamedRangeRequest(api.UpdateNamedRangeRequest o) {
  buildCounterUpdateNamedRangeRequest++;
  if (buildCounterUpdateNamedRangeRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkNamedRange(o.namedRange! as api.NamedRange);
  }
  buildCounterUpdateNamedRangeRequest--;
}

core.int buildCounterUpdateProtectedRangeRequest = 0;
api.UpdateProtectedRangeRequest buildUpdateProtectedRangeRequest() {
  var o = api.UpdateProtectedRangeRequest();
  buildCounterUpdateProtectedRangeRequest++;
  if (buildCounterUpdateProtectedRangeRequest < 3) {
    o.fields = 'foo';
    o.protectedRange = buildProtectedRange();
  }
  buildCounterUpdateProtectedRangeRequest--;
  return o;
}

void checkUpdateProtectedRangeRequest(api.UpdateProtectedRangeRequest o) {
  buildCounterUpdateProtectedRangeRequest++;
  if (buildCounterUpdateProtectedRangeRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkProtectedRange(o.protectedRange! as api.ProtectedRange);
  }
  buildCounterUpdateProtectedRangeRequest--;
}

core.int buildCounterUpdateSheetPropertiesRequest = 0;
api.UpdateSheetPropertiesRequest buildUpdateSheetPropertiesRequest() {
  var o = api.UpdateSheetPropertiesRequest();
  buildCounterUpdateSheetPropertiesRequest++;
  if (buildCounterUpdateSheetPropertiesRequest < 3) {
    o.fields = 'foo';
    o.properties = buildSheetProperties();
  }
  buildCounterUpdateSheetPropertiesRequest--;
  return o;
}

void checkUpdateSheetPropertiesRequest(api.UpdateSheetPropertiesRequest o) {
  buildCounterUpdateSheetPropertiesRequest++;
  if (buildCounterUpdateSheetPropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkSheetProperties(o.properties! as api.SheetProperties);
  }
  buildCounterUpdateSheetPropertiesRequest--;
}

core.int buildCounterUpdateSlicerSpecRequest = 0;
api.UpdateSlicerSpecRequest buildUpdateSlicerSpecRequest() {
  var o = api.UpdateSlicerSpecRequest();
  buildCounterUpdateSlicerSpecRequest++;
  if (buildCounterUpdateSlicerSpecRequest < 3) {
    o.fields = 'foo';
    o.slicerId = 42;
    o.spec = buildSlicerSpec();
  }
  buildCounterUpdateSlicerSpecRequest--;
  return o;
}

void checkUpdateSlicerSpecRequest(api.UpdateSlicerSpecRequest o) {
  buildCounterUpdateSlicerSpecRequest++;
  if (buildCounterUpdateSlicerSpecRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.slicerId!,
      unittest.equals(42),
    );
    checkSlicerSpec(o.spec! as api.SlicerSpec);
  }
  buildCounterUpdateSlicerSpecRequest--;
}

core.int buildCounterUpdateSpreadsheetPropertiesRequest = 0;
api.UpdateSpreadsheetPropertiesRequest
    buildUpdateSpreadsheetPropertiesRequest() {
  var o = api.UpdateSpreadsheetPropertiesRequest();
  buildCounterUpdateSpreadsheetPropertiesRequest++;
  if (buildCounterUpdateSpreadsheetPropertiesRequest < 3) {
    o.fields = 'foo';
    o.properties = buildSpreadsheetProperties();
  }
  buildCounterUpdateSpreadsheetPropertiesRequest--;
  return o;
}

void checkUpdateSpreadsheetPropertiesRequest(
    api.UpdateSpreadsheetPropertiesRequest o) {
  buildCounterUpdateSpreadsheetPropertiesRequest++;
  if (buildCounterUpdateSpreadsheetPropertiesRequest < 3) {
    unittest.expect(
      o.fields!,
      unittest.equals('foo'),
    );
    checkSpreadsheetProperties(o.properties! as api.SpreadsheetProperties);
  }
  buildCounterUpdateSpreadsheetPropertiesRequest--;
}

core.int buildCounterUpdateValuesByDataFilterResponse = 0;
api.UpdateValuesByDataFilterResponse buildUpdateValuesByDataFilterResponse() {
  var o = api.UpdateValuesByDataFilterResponse();
  buildCounterUpdateValuesByDataFilterResponse++;
  if (buildCounterUpdateValuesByDataFilterResponse < 3) {
    o.dataFilter = buildDataFilter();
    o.updatedCells = 42;
    o.updatedColumns = 42;
    o.updatedData = buildValueRange();
    o.updatedRange = 'foo';
    o.updatedRows = 42;
  }
  buildCounterUpdateValuesByDataFilterResponse--;
  return o;
}

void checkUpdateValuesByDataFilterResponse(
    api.UpdateValuesByDataFilterResponse o) {
  buildCounterUpdateValuesByDataFilterResponse++;
  if (buildCounterUpdateValuesByDataFilterResponse < 3) {
    checkDataFilter(o.dataFilter! as api.DataFilter);
    unittest.expect(
      o.updatedCells!,
      unittest.equals(42),
    );
    unittest.expect(
      o.updatedColumns!,
      unittest.equals(42),
    );
    checkValueRange(o.updatedData! as api.ValueRange);
    unittest.expect(
      o.updatedRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updatedRows!,
      unittest.equals(42),
    );
  }
  buildCounterUpdateValuesByDataFilterResponse--;
}

core.int buildCounterUpdateValuesResponse = 0;
api.UpdateValuesResponse buildUpdateValuesResponse() {
  var o = api.UpdateValuesResponse();
  buildCounterUpdateValuesResponse++;
  if (buildCounterUpdateValuesResponse < 3) {
    o.spreadsheetId = 'foo';
    o.updatedCells = 42;
    o.updatedColumns = 42;
    o.updatedData = buildValueRange();
    o.updatedRange = 'foo';
    o.updatedRows = 42;
  }
  buildCounterUpdateValuesResponse--;
  return o;
}

void checkUpdateValuesResponse(api.UpdateValuesResponse o) {
  buildCounterUpdateValuesResponse++;
  if (buildCounterUpdateValuesResponse < 3) {
    unittest.expect(
      o.spreadsheetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updatedCells!,
      unittest.equals(42),
    );
    unittest.expect(
      o.updatedColumns!,
      unittest.equals(42),
    );
    checkValueRange(o.updatedData! as api.ValueRange);
    unittest.expect(
      o.updatedRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updatedRows!,
      unittest.equals(42),
    );
  }
  buildCounterUpdateValuesResponse--;
}

core.List<core.Object> buildUnnamed741() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed741(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o[0]) as core.Map;
  unittest.expect(casted3, unittest.hasLength(3));
  unittest.expect(
    casted3['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted3['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted3['string'],
    unittest.equals('foo'),
  );
  var casted4 = (o[1]) as core.Map;
  unittest.expect(casted4, unittest.hasLength(3));
  unittest.expect(
    casted4['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted4['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted4['string'],
    unittest.equals('foo'),
  );
}

core.List<core.List<core.Object>> buildUnnamed742() {
  var o = <core.List<core.Object>>[];
  o.add(buildUnnamed741());
  o.add(buildUnnamed741());
  return o;
}

void checkUnnamed742(core.List<core.List<core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed741(o[0]);
  checkUnnamed741(o[1]);
}

core.int buildCounterValueRange = 0;
api.ValueRange buildValueRange() {
  var o = api.ValueRange();
  buildCounterValueRange++;
  if (buildCounterValueRange < 3) {
    o.majorDimension = 'foo';
    o.range = 'foo';
    o.values = buildUnnamed742();
  }
  buildCounterValueRange--;
  return o;
}

void checkValueRange(api.ValueRange o) {
  buildCounterValueRange++;
  if (buildCounterValueRange < 3) {
    unittest.expect(
      o.majorDimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.range!,
      unittest.equals('foo'),
    );
    checkUnnamed742(o.values!);
  }
  buildCounterValueRange--;
}

core.int buildCounterWaterfallChartColumnStyle = 0;
api.WaterfallChartColumnStyle buildWaterfallChartColumnStyle() {
  var o = api.WaterfallChartColumnStyle();
  buildCounterWaterfallChartColumnStyle++;
  if (buildCounterWaterfallChartColumnStyle < 3) {
    o.color = buildColor();
    o.colorStyle = buildColorStyle();
    o.label = 'foo';
  }
  buildCounterWaterfallChartColumnStyle--;
  return o;
}

void checkWaterfallChartColumnStyle(api.WaterfallChartColumnStyle o) {
  buildCounterWaterfallChartColumnStyle++;
  if (buildCounterWaterfallChartColumnStyle < 3) {
    checkColor(o.color! as api.Color);
    checkColorStyle(o.colorStyle! as api.ColorStyle);
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
  }
  buildCounterWaterfallChartColumnStyle--;
}

core.int buildCounterWaterfallChartCustomSubtotal = 0;
api.WaterfallChartCustomSubtotal buildWaterfallChartCustomSubtotal() {
  var o = api.WaterfallChartCustomSubtotal();
  buildCounterWaterfallChartCustomSubtotal++;
  if (buildCounterWaterfallChartCustomSubtotal < 3) {
    o.dataIsSubtotal = true;
    o.label = 'foo';
    o.subtotalIndex = 42;
  }
  buildCounterWaterfallChartCustomSubtotal--;
  return o;
}

void checkWaterfallChartCustomSubtotal(api.WaterfallChartCustomSubtotal o) {
  buildCounterWaterfallChartCustomSubtotal++;
  if (buildCounterWaterfallChartCustomSubtotal < 3) {
    unittest.expect(o.dataIsSubtotal!, unittest.isTrue);
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subtotalIndex!,
      unittest.equals(42),
    );
  }
  buildCounterWaterfallChartCustomSubtotal--;
}

core.int buildCounterWaterfallChartDomain = 0;
api.WaterfallChartDomain buildWaterfallChartDomain() {
  var o = api.WaterfallChartDomain();
  buildCounterWaterfallChartDomain++;
  if (buildCounterWaterfallChartDomain < 3) {
    o.data = buildChartData();
    o.reversed = true;
  }
  buildCounterWaterfallChartDomain--;
  return o;
}

void checkWaterfallChartDomain(api.WaterfallChartDomain o) {
  buildCounterWaterfallChartDomain++;
  if (buildCounterWaterfallChartDomain < 3) {
    checkChartData(o.data! as api.ChartData);
    unittest.expect(o.reversed!, unittest.isTrue);
  }
  buildCounterWaterfallChartDomain--;
}

core.List<api.WaterfallChartCustomSubtotal> buildUnnamed743() {
  var o = <api.WaterfallChartCustomSubtotal>[];
  o.add(buildWaterfallChartCustomSubtotal());
  o.add(buildWaterfallChartCustomSubtotal());
  return o;
}

void checkUnnamed743(core.List<api.WaterfallChartCustomSubtotal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWaterfallChartCustomSubtotal(o[0] as api.WaterfallChartCustomSubtotal);
  checkWaterfallChartCustomSubtotal(o[1] as api.WaterfallChartCustomSubtotal);
}

core.int buildCounterWaterfallChartSeries = 0;
api.WaterfallChartSeries buildWaterfallChartSeries() {
  var o = api.WaterfallChartSeries();
  buildCounterWaterfallChartSeries++;
  if (buildCounterWaterfallChartSeries < 3) {
    o.customSubtotals = buildUnnamed743();
    o.data = buildChartData();
    o.dataLabel = buildDataLabel();
    o.hideTrailingSubtotal = true;
    o.negativeColumnsStyle = buildWaterfallChartColumnStyle();
    o.positiveColumnsStyle = buildWaterfallChartColumnStyle();
    o.subtotalColumnsStyle = buildWaterfallChartColumnStyle();
  }
  buildCounterWaterfallChartSeries--;
  return o;
}

void checkWaterfallChartSeries(api.WaterfallChartSeries o) {
  buildCounterWaterfallChartSeries++;
  if (buildCounterWaterfallChartSeries < 3) {
    checkUnnamed743(o.customSubtotals!);
    checkChartData(o.data! as api.ChartData);
    checkDataLabel(o.dataLabel! as api.DataLabel);
    unittest.expect(o.hideTrailingSubtotal!, unittest.isTrue);
    checkWaterfallChartColumnStyle(
        o.negativeColumnsStyle! as api.WaterfallChartColumnStyle);
    checkWaterfallChartColumnStyle(
        o.positiveColumnsStyle! as api.WaterfallChartColumnStyle);
    checkWaterfallChartColumnStyle(
        o.subtotalColumnsStyle! as api.WaterfallChartColumnStyle);
  }
  buildCounterWaterfallChartSeries--;
}

core.List<api.WaterfallChartSeries> buildUnnamed744() {
  var o = <api.WaterfallChartSeries>[];
  o.add(buildWaterfallChartSeries());
  o.add(buildWaterfallChartSeries());
  return o;
}

void checkUnnamed744(core.List<api.WaterfallChartSeries> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWaterfallChartSeries(o[0] as api.WaterfallChartSeries);
  checkWaterfallChartSeries(o[1] as api.WaterfallChartSeries);
}

core.int buildCounterWaterfallChartSpec = 0;
api.WaterfallChartSpec buildWaterfallChartSpec() {
  var o = api.WaterfallChartSpec();
  buildCounterWaterfallChartSpec++;
  if (buildCounterWaterfallChartSpec < 3) {
    o.connectorLineStyle = buildLineStyle();
    o.domain = buildWaterfallChartDomain();
    o.firstValueIsTotal = true;
    o.hideConnectorLines = true;
    o.series = buildUnnamed744();
    o.stackedType = 'foo';
    o.totalDataLabel = buildDataLabel();
  }
  buildCounterWaterfallChartSpec--;
  return o;
}

void checkWaterfallChartSpec(api.WaterfallChartSpec o) {
  buildCounterWaterfallChartSpec++;
  if (buildCounterWaterfallChartSpec < 3) {
    checkLineStyle(o.connectorLineStyle! as api.LineStyle);
    checkWaterfallChartDomain(o.domain! as api.WaterfallChartDomain);
    unittest.expect(o.firstValueIsTotal!, unittest.isTrue);
    unittest.expect(o.hideConnectorLines!, unittest.isTrue);
    checkUnnamed744(o.series!);
    unittest.expect(
      o.stackedType!,
      unittest.equals('foo'),
    );
    checkDataLabel(o.totalDataLabel! as api.DataLabel);
  }
  buildCounterWaterfallChartSpec--;
}

core.List<core.String> buildUnnamed745() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed745(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed746() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed746(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

void main() {
  unittest.group('obj-schema-AddBandingRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddBandingRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddBandingRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddBandingRequest(od as api.AddBandingRequest);
    });
  });

  unittest.group('obj-schema-AddBandingResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddBandingResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddBandingResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddBandingResponse(od as api.AddBandingResponse);
    });
  });

  unittest.group('obj-schema-AddChartRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddChartRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddChartRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddChartRequest(od as api.AddChartRequest);
    });
  });

  unittest.group('obj-schema-AddChartResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddChartResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddChartResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddChartResponse(od as api.AddChartResponse);
    });
  });

  unittest.group('obj-schema-AddConditionalFormatRuleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddConditionalFormatRuleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddConditionalFormatRuleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddConditionalFormatRuleRequest(
          od as api.AddConditionalFormatRuleRequest);
    });
  });

  unittest.group('obj-schema-AddDataSourceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddDataSourceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddDataSourceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddDataSourceRequest(od as api.AddDataSourceRequest);
    });
  });

  unittest.group('obj-schema-AddDataSourceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddDataSourceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddDataSourceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddDataSourceResponse(od as api.AddDataSourceResponse);
    });
  });

  unittest.group('obj-schema-AddDimensionGroupRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddDimensionGroupRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddDimensionGroupRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddDimensionGroupRequest(od as api.AddDimensionGroupRequest);
    });
  });

  unittest.group('obj-schema-AddDimensionGroupResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddDimensionGroupResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddDimensionGroupResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddDimensionGroupResponse(od as api.AddDimensionGroupResponse);
    });
  });

  unittest.group('obj-schema-AddFilterViewRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddFilterViewRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddFilterViewRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddFilterViewRequest(od as api.AddFilterViewRequest);
    });
  });

  unittest.group('obj-schema-AddFilterViewResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddFilterViewResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddFilterViewResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddFilterViewResponse(od as api.AddFilterViewResponse);
    });
  });

  unittest.group('obj-schema-AddNamedRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddNamedRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddNamedRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddNamedRangeRequest(od as api.AddNamedRangeRequest);
    });
  });

  unittest.group('obj-schema-AddNamedRangeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddNamedRangeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddNamedRangeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddNamedRangeResponse(od as api.AddNamedRangeResponse);
    });
  });

  unittest.group('obj-schema-AddProtectedRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddProtectedRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddProtectedRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddProtectedRangeRequest(od as api.AddProtectedRangeRequest);
    });
  });

  unittest.group('obj-schema-AddProtectedRangeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddProtectedRangeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddProtectedRangeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddProtectedRangeResponse(od as api.AddProtectedRangeResponse);
    });
  });

  unittest.group('obj-schema-AddSheetRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddSheetRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddSheetRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddSheetRequest(od as api.AddSheetRequest);
    });
  });

  unittest.group('obj-schema-AddSheetResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddSheetResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddSheetResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddSheetResponse(od as api.AddSheetResponse);
    });
  });

  unittest.group('obj-schema-AddSlicerRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddSlicerRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddSlicerRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddSlicerRequest(od as api.AddSlicerRequest);
    });
  });

  unittest.group('obj-schema-AddSlicerResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddSlicerResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddSlicerResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddSlicerResponse(od as api.AddSlicerResponse);
    });
  });

  unittest.group('obj-schema-AppendCellsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppendCellsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppendCellsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppendCellsRequest(od as api.AppendCellsRequest);
    });
  });

  unittest.group('obj-schema-AppendDimensionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppendDimensionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppendDimensionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppendDimensionRequest(od as api.AppendDimensionRequest);
    });
  });

  unittest.group('obj-schema-AppendValuesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppendValuesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppendValuesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppendValuesResponse(od as api.AppendValuesResponse);
    });
  });

  unittest.group('obj-schema-AutoFillRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutoFillRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AutoFillRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAutoFillRequest(od as api.AutoFillRequest);
    });
  });

  unittest.group('obj-schema-AutoResizeDimensionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutoResizeDimensionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AutoResizeDimensionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAutoResizeDimensionsRequest(od as api.AutoResizeDimensionsRequest);
    });
  });

  unittest.group('obj-schema-BandedRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBandedRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BandedRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBandedRange(od as api.BandedRange);
    });
  });

  unittest.group('obj-schema-BandingProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBandingProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BandingProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBandingProperties(od as api.BandingProperties);
    });
  });

  unittest.group('obj-schema-BaselineValueFormat', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBaselineValueFormat();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BaselineValueFormat.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBaselineValueFormat(od as api.BaselineValueFormat);
    });
  });

  unittest.group('obj-schema-BasicChartAxis', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasicChartAxis();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasicChartAxis.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasicChartAxis(od as api.BasicChartAxis);
    });
  });

  unittest.group('obj-schema-BasicChartDomain', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasicChartDomain();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasicChartDomain.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasicChartDomain(od as api.BasicChartDomain);
    });
  });

  unittest.group('obj-schema-BasicChartSeries', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasicChartSeries();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasicChartSeries.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasicChartSeries(od as api.BasicChartSeries);
    });
  });

  unittest.group('obj-schema-BasicChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasicChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasicChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasicChartSpec(od as api.BasicChartSpec);
    });
  });

  unittest.group('obj-schema-BasicFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasicFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasicFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasicFilter(od as api.BasicFilter);
    });
  });

  unittest.group('obj-schema-BasicSeriesDataPointStyleOverride', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasicSeriesDataPointStyleOverride();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasicSeriesDataPointStyleOverride.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasicSeriesDataPointStyleOverride(
          od as api.BasicSeriesDataPointStyleOverride);
    });
  });

  unittest.group('obj-schema-BatchClearValuesByDataFilterRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchClearValuesByDataFilterRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchClearValuesByDataFilterRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchClearValuesByDataFilterRequest(
          od as api.BatchClearValuesByDataFilterRequest);
    });
  });

  unittest.group('obj-schema-BatchClearValuesByDataFilterResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchClearValuesByDataFilterResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchClearValuesByDataFilterResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchClearValuesByDataFilterResponse(
          od as api.BatchClearValuesByDataFilterResponse);
    });
  });

  unittest.group('obj-schema-BatchClearValuesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchClearValuesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchClearValuesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchClearValuesRequest(od as api.BatchClearValuesRequest);
    });
  });

  unittest.group('obj-schema-BatchClearValuesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchClearValuesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchClearValuesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchClearValuesResponse(od as api.BatchClearValuesResponse);
    });
  });

  unittest.group('obj-schema-BatchGetValuesByDataFilterRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetValuesByDataFilterRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetValuesByDataFilterRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetValuesByDataFilterRequest(
          od as api.BatchGetValuesByDataFilterRequest);
    });
  });

  unittest.group('obj-schema-BatchGetValuesByDataFilterResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetValuesByDataFilterResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetValuesByDataFilterResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetValuesByDataFilterResponse(
          od as api.BatchGetValuesByDataFilterResponse);
    });
  });

  unittest.group('obj-schema-BatchGetValuesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetValuesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetValuesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetValuesResponse(od as api.BatchGetValuesResponse);
    });
  });

  unittest.group('obj-schema-BatchUpdateSpreadsheetRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateSpreadsheetRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateSpreadsheetRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateSpreadsheetRequest(
          od as api.BatchUpdateSpreadsheetRequest);
    });
  });

  unittest.group('obj-schema-BatchUpdateSpreadsheetResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateSpreadsheetResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateSpreadsheetResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateSpreadsheetResponse(
          od as api.BatchUpdateSpreadsheetResponse);
    });
  });

  unittest.group('obj-schema-BatchUpdateValuesByDataFilterRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateValuesByDataFilterRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateValuesByDataFilterRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateValuesByDataFilterRequest(
          od as api.BatchUpdateValuesByDataFilterRequest);
    });
  });

  unittest.group('obj-schema-BatchUpdateValuesByDataFilterResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateValuesByDataFilterResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateValuesByDataFilterResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateValuesByDataFilterResponse(
          od as api.BatchUpdateValuesByDataFilterResponse);
    });
  });

  unittest.group('obj-schema-BatchUpdateValuesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateValuesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateValuesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateValuesRequest(od as api.BatchUpdateValuesRequest);
    });
  });

  unittest.group('obj-schema-BatchUpdateValuesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateValuesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateValuesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateValuesResponse(od as api.BatchUpdateValuesResponse);
    });
  });

  unittest.group('obj-schema-BigQueryDataSourceSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigQueryDataSourceSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigQueryDataSourceSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigQueryDataSourceSpec(od as api.BigQueryDataSourceSpec);
    });
  });

  unittest.group('obj-schema-BigQueryQuerySpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigQueryQuerySpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigQueryQuerySpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigQueryQuerySpec(od as api.BigQueryQuerySpec);
    });
  });

  unittest.group('obj-schema-BigQueryTableSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigQueryTableSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigQueryTableSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigQueryTableSpec(od as api.BigQueryTableSpec);
    });
  });

  unittest.group('obj-schema-BooleanCondition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBooleanCondition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BooleanCondition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBooleanCondition(od as api.BooleanCondition);
    });
  });

  unittest.group('obj-schema-BooleanRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBooleanRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BooleanRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBooleanRule(od as api.BooleanRule);
    });
  });

  unittest.group('obj-schema-Border', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBorder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Border.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBorder(od as api.Border);
    });
  });

  unittest.group('obj-schema-Borders', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBorders();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Borders.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBorders(od as api.Borders);
    });
  });

  unittest.group('obj-schema-BubbleChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBubbleChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BubbleChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBubbleChartSpec(od as api.BubbleChartSpec);
    });
  });

  unittest.group('obj-schema-CandlestickChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCandlestickChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CandlestickChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCandlestickChartSpec(od as api.CandlestickChartSpec);
    });
  });

  unittest.group('obj-schema-CandlestickData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCandlestickData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CandlestickData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCandlestickData(od as api.CandlestickData);
    });
  });

  unittest.group('obj-schema-CandlestickDomain', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCandlestickDomain();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CandlestickDomain.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCandlestickDomain(od as api.CandlestickDomain);
    });
  });

  unittest.group('obj-schema-CandlestickSeries', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCandlestickSeries();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CandlestickSeries.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCandlestickSeries(od as api.CandlestickSeries);
    });
  });

  unittest.group('obj-schema-CellData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCellData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CellData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCellData(od as api.CellData);
    });
  });

  unittest.group('obj-schema-CellFormat', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCellFormat();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CellFormat.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCellFormat(od as api.CellFormat);
    });
  });

  unittest.group('obj-schema-ChartAxisViewWindowOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartAxisViewWindowOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChartAxisViewWindowOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChartAxisViewWindowOptions(od as api.ChartAxisViewWindowOptions);
    });
  });

  unittest.group('obj-schema-ChartCustomNumberFormatOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartCustomNumberFormatOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChartCustomNumberFormatOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChartCustomNumberFormatOptions(
          od as api.ChartCustomNumberFormatOptions);
    });
  });

  unittest.group('obj-schema-ChartData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ChartData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChartData(od as api.ChartData);
    });
  });

  unittest.group('obj-schema-ChartDateTimeRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartDateTimeRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChartDateTimeRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChartDateTimeRule(od as api.ChartDateTimeRule);
    });
  });

  unittest.group('obj-schema-ChartGroupRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartGroupRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChartGroupRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChartGroupRule(od as api.ChartGroupRule);
    });
  });

  unittest.group('obj-schema-ChartHistogramRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartHistogramRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChartHistogramRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChartHistogramRule(od as api.ChartHistogramRule);
    });
  });

  unittest.group('obj-schema-ChartSourceRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartSourceRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChartSourceRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChartSourceRange(od as api.ChartSourceRange);
    });
  });

  unittest.group('obj-schema-ChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ChartSpec.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChartSpec(od as api.ChartSpec);
    });
  });

  unittest.group('obj-schema-ClearBasicFilterRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClearBasicFilterRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClearBasicFilterRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClearBasicFilterRequest(od as api.ClearBasicFilterRequest);
    });
  });

  unittest.group('obj-schema-ClearValuesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClearValuesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClearValuesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClearValuesRequest(od as api.ClearValuesRequest);
    });
  });

  unittest.group('obj-schema-ClearValuesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClearValuesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClearValuesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClearValuesResponse(od as api.ClearValuesResponse);
    });
  });

  unittest.group('obj-schema-Color', () {
    unittest.test('to-json--from-json', () async {
      var o = buildColor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Color.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkColor(od as api.Color);
    });
  });

  unittest.group('obj-schema-ColorStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildColorStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ColorStyle.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkColorStyle(od as api.ColorStyle);
    });
  });

  unittest.group('obj-schema-ConditionValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConditionValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConditionValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConditionValue(od as api.ConditionValue);
    });
  });

  unittest.group('obj-schema-ConditionalFormatRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConditionalFormatRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConditionalFormatRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConditionalFormatRule(od as api.ConditionalFormatRule);
    });
  });

  unittest.group('obj-schema-CopyPasteRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCopyPasteRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CopyPasteRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCopyPasteRequest(od as api.CopyPasteRequest);
    });
  });

  unittest.group('obj-schema-CopySheetToAnotherSpreadsheetRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCopySheetToAnotherSpreadsheetRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CopySheetToAnotherSpreadsheetRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCopySheetToAnotherSpreadsheetRequest(
          od as api.CopySheetToAnotherSpreadsheetRequest);
    });
  });

  unittest.group('obj-schema-CreateDeveloperMetadataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateDeveloperMetadataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateDeveloperMetadataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateDeveloperMetadataRequest(
          od as api.CreateDeveloperMetadataRequest);
    });
  });

  unittest.group('obj-schema-CreateDeveloperMetadataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateDeveloperMetadataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateDeveloperMetadataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateDeveloperMetadataResponse(
          od as api.CreateDeveloperMetadataResponse);
    });
  });

  unittest.group('obj-schema-CutPasteRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCutPasteRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CutPasteRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCutPasteRequest(od as api.CutPasteRequest);
    });
  });

  unittest.group('obj-schema-DataExecutionStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataExecutionStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataExecutionStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataExecutionStatus(od as api.DataExecutionStatus);
    });
  });

  unittest.group('obj-schema-DataFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DataFilter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataFilter(od as api.DataFilter);
    });
  });

  unittest.group('obj-schema-DataFilterValueRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataFilterValueRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataFilterValueRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataFilterValueRange(od as api.DataFilterValueRange);
    });
  });

  unittest.group('obj-schema-DataLabel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataLabel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DataLabel.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataLabel(od as api.DataLabel);
    });
  });

  unittest.group('obj-schema-DataSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DataSource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataSource(od as api.DataSource);
    });
  });

  unittest.group('obj-schema-DataSourceChartProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceChartProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceChartProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceChartProperties(od as api.DataSourceChartProperties);
    });
  });

  unittest.group('obj-schema-DataSourceColumn', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceColumn();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceColumn.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceColumn(od as api.DataSourceColumn);
    });
  });

  unittest.group('obj-schema-DataSourceColumnReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceColumnReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceColumnReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceColumnReference(od as api.DataSourceColumnReference);
    });
  });

  unittest.group('obj-schema-DataSourceFormula', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceFormula();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceFormula.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceFormula(od as api.DataSourceFormula);
    });
  });

  unittest.group('obj-schema-DataSourceObjectReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceObjectReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceObjectReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceObjectReference(od as api.DataSourceObjectReference);
    });
  });

  unittest.group('obj-schema-DataSourceObjectReferences', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceObjectReferences();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceObjectReferences.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceObjectReferences(od as api.DataSourceObjectReferences);
    });
  });

  unittest.group('obj-schema-DataSourceParameter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceParameter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceParameter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceParameter(od as api.DataSourceParameter);
    });
  });

  unittest.group('obj-schema-DataSourceRefreshDailySchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceRefreshDailySchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceRefreshDailySchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceRefreshDailySchedule(
          od as api.DataSourceRefreshDailySchedule);
    });
  });

  unittest.group('obj-schema-DataSourceRefreshMonthlySchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceRefreshMonthlySchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceRefreshMonthlySchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceRefreshMonthlySchedule(
          od as api.DataSourceRefreshMonthlySchedule);
    });
  });

  unittest.group('obj-schema-DataSourceRefreshSchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceRefreshSchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceRefreshSchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceRefreshSchedule(od as api.DataSourceRefreshSchedule);
    });
  });

  unittest.group('obj-schema-DataSourceRefreshWeeklySchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceRefreshWeeklySchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceRefreshWeeklySchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceRefreshWeeklySchedule(
          od as api.DataSourceRefreshWeeklySchedule);
    });
  });

  unittest.group('obj-schema-DataSourceSheetDimensionRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceSheetDimensionRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceSheetDimensionRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceSheetDimensionRange(
          od as api.DataSourceSheetDimensionRange);
    });
  });

  unittest.group('obj-schema-DataSourceSheetProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceSheetProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceSheetProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceSheetProperties(od as api.DataSourceSheetProperties);
    });
  });

  unittest.group('obj-schema-DataSourceSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceSpec(od as api.DataSourceSpec);
    });
  });

  unittest.group('obj-schema-DataSourceTable', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceTable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceTable.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceTable(od as api.DataSourceTable);
    });
  });

  unittest.group('obj-schema-DataValidationRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataValidationRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataValidationRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataValidationRule(od as api.DataValidationRule);
    });
  });

  unittest.group('obj-schema-DateTimeRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDateTimeRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DateTimeRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDateTimeRule(od as api.DateTimeRule);
    });
  });

  unittest.group('obj-schema-DeleteBandingRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteBandingRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteBandingRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteBandingRequest(od as api.DeleteBandingRequest);
    });
  });

  unittest.group('obj-schema-DeleteConditionalFormatRuleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteConditionalFormatRuleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteConditionalFormatRuleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteConditionalFormatRuleRequest(
          od as api.DeleteConditionalFormatRuleRequest);
    });
  });

  unittest.group('obj-schema-DeleteConditionalFormatRuleResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteConditionalFormatRuleResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteConditionalFormatRuleResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteConditionalFormatRuleResponse(
          od as api.DeleteConditionalFormatRuleResponse);
    });
  });

  unittest.group('obj-schema-DeleteDataSourceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDataSourceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDataSourceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDataSourceRequest(od as api.DeleteDataSourceRequest);
    });
  });

  unittest.group('obj-schema-DeleteDeveloperMetadataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDeveloperMetadataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDeveloperMetadataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDeveloperMetadataRequest(
          od as api.DeleteDeveloperMetadataRequest);
    });
  });

  unittest.group('obj-schema-DeleteDeveloperMetadataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDeveloperMetadataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDeveloperMetadataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDeveloperMetadataResponse(
          od as api.DeleteDeveloperMetadataResponse);
    });
  });

  unittest.group('obj-schema-DeleteDimensionGroupRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDimensionGroupRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDimensionGroupRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDimensionGroupRequest(od as api.DeleteDimensionGroupRequest);
    });
  });

  unittest.group('obj-schema-DeleteDimensionGroupResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDimensionGroupResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDimensionGroupResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDimensionGroupResponse(od as api.DeleteDimensionGroupResponse);
    });
  });

  unittest.group('obj-schema-DeleteDimensionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDimensionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDimensionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDimensionRequest(od as api.DeleteDimensionRequest);
    });
  });

  unittest.group('obj-schema-DeleteDuplicatesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDuplicatesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDuplicatesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDuplicatesRequest(od as api.DeleteDuplicatesRequest);
    });
  });

  unittest.group('obj-schema-DeleteDuplicatesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteDuplicatesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteDuplicatesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteDuplicatesResponse(od as api.DeleteDuplicatesResponse);
    });
  });

  unittest.group('obj-schema-DeleteEmbeddedObjectRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteEmbeddedObjectRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteEmbeddedObjectRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteEmbeddedObjectRequest(od as api.DeleteEmbeddedObjectRequest);
    });
  });

  unittest.group('obj-schema-DeleteFilterViewRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteFilterViewRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteFilterViewRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteFilterViewRequest(od as api.DeleteFilterViewRequest);
    });
  });

  unittest.group('obj-schema-DeleteNamedRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteNamedRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteNamedRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteNamedRangeRequest(od as api.DeleteNamedRangeRequest);
    });
  });

  unittest.group('obj-schema-DeleteProtectedRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteProtectedRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteProtectedRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteProtectedRangeRequest(od as api.DeleteProtectedRangeRequest);
    });
  });

  unittest.group('obj-schema-DeleteRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteRangeRequest(od as api.DeleteRangeRequest);
    });
  });

  unittest.group('obj-schema-DeleteSheetRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteSheetRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteSheetRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteSheetRequest(od as api.DeleteSheetRequest);
    });
  });

  unittest.group('obj-schema-DeveloperMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeveloperMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeveloperMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeveloperMetadata(od as api.DeveloperMetadata);
    });
  });

  unittest.group('obj-schema-DeveloperMetadataLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeveloperMetadataLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeveloperMetadataLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeveloperMetadataLocation(od as api.DeveloperMetadataLocation);
    });
  });

  unittest.group('obj-schema-DeveloperMetadataLookup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeveloperMetadataLookup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeveloperMetadataLookup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeveloperMetadataLookup(od as api.DeveloperMetadataLookup);
    });
  });

  unittest.group('obj-schema-DimensionGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimensionGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DimensionGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDimensionGroup(od as api.DimensionGroup);
    });
  });

  unittest.group('obj-schema-DimensionProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimensionProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DimensionProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDimensionProperties(od as api.DimensionProperties);
    });
  });

  unittest.group('obj-schema-DimensionRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimensionRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DimensionRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDimensionRange(od as api.DimensionRange);
    });
  });

  unittest.group('obj-schema-DuplicateFilterViewRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDuplicateFilterViewRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DuplicateFilterViewRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDuplicateFilterViewRequest(od as api.DuplicateFilterViewRequest);
    });
  });

  unittest.group('obj-schema-DuplicateFilterViewResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDuplicateFilterViewResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DuplicateFilterViewResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDuplicateFilterViewResponse(od as api.DuplicateFilterViewResponse);
    });
  });

  unittest.group('obj-schema-DuplicateSheetRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDuplicateSheetRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DuplicateSheetRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDuplicateSheetRequest(od as api.DuplicateSheetRequest);
    });
  });

  unittest.group('obj-schema-DuplicateSheetResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDuplicateSheetResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DuplicateSheetResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDuplicateSheetResponse(od as api.DuplicateSheetResponse);
    });
  });

  unittest.group('obj-schema-Editors', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEditors();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Editors.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEditors(od as api.Editors);
    });
  });

  unittest.group('obj-schema-EmbeddedChart', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmbeddedChart();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EmbeddedChart.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEmbeddedChart(od as api.EmbeddedChart);
    });
  });

  unittest.group('obj-schema-EmbeddedObjectBorder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmbeddedObjectBorder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EmbeddedObjectBorder.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEmbeddedObjectBorder(od as api.EmbeddedObjectBorder);
    });
  });

  unittest.group('obj-schema-EmbeddedObjectPosition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmbeddedObjectPosition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EmbeddedObjectPosition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEmbeddedObjectPosition(od as api.EmbeddedObjectPosition);
    });
  });

  unittest.group('obj-schema-ErrorValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildErrorValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ErrorValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkErrorValue(od as api.ErrorValue);
    });
  });

  unittest.group('obj-schema-ExtendedValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExtendedValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExtendedValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExtendedValue(od as api.ExtendedValue);
    });
  });

  unittest.group('obj-schema-FilterCriteria', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterCriteria();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterCriteria.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterCriteria(od as api.FilterCriteria);
    });
  });

  unittest.group('obj-schema-FilterSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FilterSpec.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilterSpec(od as api.FilterSpec);
    });
  });

  unittest.group('obj-schema-FilterView', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterView();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FilterView.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilterView(od as api.FilterView);
    });
  });

  unittest.group('obj-schema-FindReplaceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFindReplaceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FindReplaceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFindReplaceRequest(od as api.FindReplaceRequest);
    });
  });

  unittest.group('obj-schema-FindReplaceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFindReplaceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FindReplaceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFindReplaceResponse(od as api.FindReplaceResponse);
    });
  });

  unittest.group('obj-schema-GetSpreadsheetByDataFilterRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetSpreadsheetByDataFilterRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetSpreadsheetByDataFilterRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetSpreadsheetByDataFilterRequest(
          od as api.GetSpreadsheetByDataFilterRequest);
    });
  });

  unittest.group('obj-schema-GradientRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGradientRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GradientRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGradientRule(od as api.GradientRule);
    });
  });

  unittest.group('obj-schema-GridCoordinate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGridCoordinate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GridCoordinate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGridCoordinate(od as api.GridCoordinate);
    });
  });

  unittest.group('obj-schema-GridData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGridData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GridData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGridData(od as api.GridData);
    });
  });

  unittest.group('obj-schema-GridProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGridProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GridProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGridProperties(od as api.GridProperties);
    });
  });

  unittest.group('obj-schema-GridRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGridRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GridRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGridRange(od as api.GridRange);
    });
  });

  unittest.group('obj-schema-HistogramChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistogramChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistogramChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistogramChartSpec(od as api.HistogramChartSpec);
    });
  });

  unittest.group('obj-schema-HistogramRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistogramRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistogramRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistogramRule(od as api.HistogramRule);
    });
  });

  unittest.group('obj-schema-HistogramSeries', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistogramSeries();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistogramSeries.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistogramSeries(od as api.HistogramSeries);
    });
  });

  unittest.group('obj-schema-InsertDimensionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertDimensionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertDimensionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertDimensionRequest(od as api.InsertDimensionRequest);
    });
  });

  unittest.group('obj-schema-InsertRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertRangeRequest(od as api.InsertRangeRequest);
    });
  });

  unittest.group('obj-schema-InterpolationPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInterpolationPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InterpolationPoint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInterpolationPoint(od as api.InterpolationPoint);
    });
  });

  unittest.group('obj-schema-Interval', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInterval();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Interval.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInterval(od as api.Interval);
    });
  });

  unittest.group('obj-schema-IterativeCalculationSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIterativeCalculationSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IterativeCalculationSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIterativeCalculationSettings(od as api.IterativeCalculationSettings);
    });
  });

  unittest.group('obj-schema-KeyValueFormat', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKeyValueFormat();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.KeyValueFormat.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkKeyValueFormat(od as api.KeyValueFormat);
    });
  });

  unittest.group('obj-schema-LineStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLineStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LineStyle.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLineStyle(od as api.LineStyle);
    });
  });

  unittest.group('obj-schema-Link', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Link.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLink(od as api.Link);
    });
  });

  unittest.group('obj-schema-ManualRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManualRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ManualRule.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkManualRule(od as api.ManualRule);
    });
  });

  unittest.group('obj-schema-ManualRuleGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManualRuleGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManualRuleGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManualRuleGroup(od as api.ManualRuleGroup);
    });
  });

  unittest.group('obj-schema-MatchedDeveloperMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMatchedDeveloperMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MatchedDeveloperMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMatchedDeveloperMetadata(od as api.MatchedDeveloperMetadata);
    });
  });

  unittest.group('obj-schema-MatchedValueRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMatchedValueRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MatchedValueRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMatchedValueRange(od as api.MatchedValueRange);
    });
  });

  unittest.group('obj-schema-MergeCellsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMergeCellsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MergeCellsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMergeCellsRequest(od as api.MergeCellsRequest);
    });
  });

  unittest.group('obj-schema-MoveDimensionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveDimensionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveDimensionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveDimensionRequest(od as api.MoveDimensionRequest);
    });
  });

  unittest.group('obj-schema-NamedRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNamedRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.NamedRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkNamedRange(od as api.NamedRange);
    });
  });

  unittest.group('obj-schema-NumberFormat', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNumberFormat();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NumberFormat.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNumberFormat(od as api.NumberFormat);
    });
  });

  unittest.group('obj-schema-OrgChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrgChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OrgChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrgChartSpec(od as api.OrgChartSpec);
    });
  });

  unittest.group('obj-schema-OverlayPosition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOverlayPosition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OverlayPosition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOverlayPosition(od as api.OverlayPosition);
    });
  });

  unittest.group('obj-schema-Padding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPadding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Padding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPadding(od as api.Padding);
    });
  });

  unittest.group('obj-schema-PasteDataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPasteDataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PasteDataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPasteDataRequest(od as api.PasteDataRequest);
    });
  });

  unittest.group('obj-schema-PieChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPieChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PieChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPieChartSpec(od as api.PieChartSpec);
    });
  });

  unittest.group('obj-schema-PivotFilterCriteria', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotFilterCriteria();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotFilterCriteria.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotFilterCriteria(od as api.PivotFilterCriteria);
    });
  });

  unittest.group('obj-schema-PivotFilterSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotFilterSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotFilterSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotFilterSpec(od as api.PivotFilterSpec);
    });
  });

  unittest.group('obj-schema-PivotGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PivotGroup.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPivotGroup(od as api.PivotGroup);
    });
  });

  unittest.group('obj-schema-PivotGroupLimit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotGroupLimit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotGroupLimit.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotGroupLimit(od as api.PivotGroupLimit);
    });
  });

  unittest.group('obj-schema-PivotGroupRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotGroupRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotGroupRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotGroupRule(od as api.PivotGroupRule);
    });
  });

  unittest.group('obj-schema-PivotGroupSortValueBucket', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotGroupSortValueBucket();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotGroupSortValueBucket.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotGroupSortValueBucket(od as api.PivotGroupSortValueBucket);
    });
  });

  unittest.group('obj-schema-PivotGroupValueMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotGroupValueMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotGroupValueMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotGroupValueMetadata(od as api.PivotGroupValueMetadata);
    });
  });

  unittest.group('obj-schema-PivotTable', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotTable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PivotTable.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPivotTable(od as api.PivotTable);
    });
  });

  unittest.group('obj-schema-PivotValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PivotValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPivotValue(od as api.PivotValue);
    });
  });

  unittest.group('obj-schema-PointStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPointStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PointStyle.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPointStyle(od as api.PointStyle);
    });
  });

  unittest.group('obj-schema-ProtectedRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProtectedRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProtectedRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProtectedRange(od as api.ProtectedRange);
    });
  });

  unittest.group('obj-schema-RandomizeRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRandomizeRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RandomizeRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRandomizeRangeRequest(od as api.RandomizeRangeRequest);
    });
  });

  unittest.group('obj-schema-RefreshDataSourceObjectExecutionStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRefreshDataSourceObjectExecutionStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RefreshDataSourceObjectExecutionStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRefreshDataSourceObjectExecutionStatus(
          od as api.RefreshDataSourceObjectExecutionStatus);
    });
  });

  unittest.group('obj-schema-RefreshDataSourceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRefreshDataSourceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RefreshDataSourceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRefreshDataSourceRequest(od as api.RefreshDataSourceRequest);
    });
  });

  unittest.group('obj-schema-RefreshDataSourceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRefreshDataSourceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RefreshDataSourceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRefreshDataSourceResponse(od as api.RefreshDataSourceResponse);
    });
  });

  unittest.group('obj-schema-RepeatCellRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepeatCellRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RepeatCellRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRepeatCellRequest(od as api.RepeatCellRequest);
    });
  });

  unittest.group('obj-schema-Request', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Request.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRequest(od as api.Request);
    });
  });

  unittest.group('obj-schema-Response', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Response.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResponse(od as api.Response);
    });
  });

  unittest.group('obj-schema-RowData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRowData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RowData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRowData(od as api.RowData);
    });
  });

  unittest.group('obj-schema-ScorecardChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScorecardChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScorecardChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScorecardChartSpec(od as api.ScorecardChartSpec);
    });
  });

  unittest.group('obj-schema-SearchDeveloperMetadataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchDeveloperMetadataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchDeveloperMetadataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchDeveloperMetadataRequest(
          od as api.SearchDeveloperMetadataRequest);
    });
  });

  unittest.group('obj-schema-SearchDeveloperMetadataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchDeveloperMetadataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchDeveloperMetadataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchDeveloperMetadataResponse(
          od as api.SearchDeveloperMetadataResponse);
    });
  });

  unittest.group('obj-schema-SetBasicFilterRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetBasicFilterRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetBasicFilterRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetBasicFilterRequest(od as api.SetBasicFilterRequest);
    });
  });

  unittest.group('obj-schema-SetDataValidationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetDataValidationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetDataValidationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetDataValidationRequest(od as api.SetDataValidationRequest);
    });
  });

  unittest.group('obj-schema-Sheet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSheet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Sheet.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSheet(od as api.Sheet);
    });
  });

  unittest.group('obj-schema-SheetProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSheetProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SheetProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSheetProperties(od as api.SheetProperties);
    });
  });

  unittest.group('obj-schema-Slicer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSlicer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Slicer.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSlicer(od as api.Slicer);
    });
  });

  unittest.group('obj-schema-SlicerSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSlicerSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SlicerSpec.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSlicerSpec(od as api.SlicerSpec);
    });
  });

  unittest.group('obj-schema-SortRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSortRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SortRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSortRangeRequest(od as api.SortRangeRequest);
    });
  });

  unittest.group('obj-schema-SortSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSortSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SortSpec.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSortSpec(od as api.SortSpec);
    });
  });

  unittest.group('obj-schema-SourceAndDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceAndDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceAndDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceAndDestination(od as api.SourceAndDestination);
    });
  });

  unittest.group('obj-schema-Spreadsheet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpreadsheet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Spreadsheet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpreadsheet(od as api.Spreadsheet);
    });
  });

  unittest.group('obj-schema-SpreadsheetProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpreadsheetProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpreadsheetProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpreadsheetProperties(od as api.SpreadsheetProperties);
    });
  });

  unittest.group('obj-schema-SpreadsheetTheme', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpreadsheetTheme();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpreadsheetTheme.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpreadsheetTheme(od as api.SpreadsheetTheme);
    });
  });

  unittest.group('obj-schema-TextFormat', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextFormat();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TextFormat.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTextFormat(od as api.TextFormat);
    });
  });

  unittest.group('obj-schema-TextFormatRun', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextFormatRun();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextFormatRun.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextFormatRun(od as api.TextFormatRun);
    });
  });

  unittest.group('obj-schema-TextPosition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextPosition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextPosition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextPosition(od as api.TextPosition);
    });
  });

  unittest.group('obj-schema-TextRotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextRotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextRotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextRotation(od as api.TextRotation);
    });
  });

  unittest.group('obj-schema-TextToColumnsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextToColumnsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextToColumnsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextToColumnsRequest(od as api.TextToColumnsRequest);
    });
  });

  unittest.group('obj-schema-ThemeColorPair', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThemeColorPair();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThemeColorPair.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThemeColorPair(od as api.ThemeColorPair);
    });
  });

  unittest.group('obj-schema-TimeOfDay', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeOfDay();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeOfDay.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeOfDay(od as api.TimeOfDay);
    });
  });

  unittest.group('obj-schema-TreemapChartColorScale', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTreemapChartColorScale();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TreemapChartColorScale.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTreemapChartColorScale(od as api.TreemapChartColorScale);
    });
  });

  unittest.group('obj-schema-TreemapChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTreemapChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TreemapChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTreemapChartSpec(od as api.TreemapChartSpec);
    });
  });

  unittest.group('obj-schema-TrimWhitespaceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrimWhitespaceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrimWhitespaceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrimWhitespaceRequest(od as api.TrimWhitespaceRequest);
    });
  });

  unittest.group('obj-schema-TrimWhitespaceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrimWhitespaceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrimWhitespaceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrimWhitespaceResponse(od as api.TrimWhitespaceResponse);
    });
  });

  unittest.group('obj-schema-UnmergeCellsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnmergeCellsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnmergeCellsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnmergeCellsRequest(od as api.UnmergeCellsRequest);
    });
  });

  unittest.group('obj-schema-UpdateBandingRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateBandingRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateBandingRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateBandingRequest(od as api.UpdateBandingRequest);
    });
  });

  unittest.group('obj-schema-UpdateBordersRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateBordersRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateBordersRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateBordersRequest(od as api.UpdateBordersRequest);
    });
  });

  unittest.group('obj-schema-UpdateCellsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateCellsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateCellsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateCellsRequest(od as api.UpdateCellsRequest);
    });
  });

  unittest.group('obj-schema-UpdateChartSpecRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateChartSpecRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateChartSpecRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateChartSpecRequest(od as api.UpdateChartSpecRequest);
    });
  });

  unittest.group('obj-schema-UpdateConditionalFormatRuleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateConditionalFormatRuleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateConditionalFormatRuleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateConditionalFormatRuleRequest(
          od as api.UpdateConditionalFormatRuleRequest);
    });
  });

  unittest.group('obj-schema-UpdateConditionalFormatRuleResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateConditionalFormatRuleResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateConditionalFormatRuleResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateConditionalFormatRuleResponse(
          od as api.UpdateConditionalFormatRuleResponse);
    });
  });

  unittest.group('obj-schema-UpdateDataSourceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDataSourceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDataSourceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDataSourceRequest(od as api.UpdateDataSourceRequest);
    });
  });

  unittest.group('obj-schema-UpdateDataSourceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDataSourceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDataSourceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDataSourceResponse(od as api.UpdateDataSourceResponse);
    });
  });

  unittest.group('obj-schema-UpdateDeveloperMetadataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDeveloperMetadataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDeveloperMetadataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDeveloperMetadataRequest(
          od as api.UpdateDeveloperMetadataRequest);
    });
  });

  unittest.group('obj-schema-UpdateDeveloperMetadataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDeveloperMetadataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDeveloperMetadataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDeveloperMetadataResponse(
          od as api.UpdateDeveloperMetadataResponse);
    });
  });

  unittest.group('obj-schema-UpdateDimensionGroupRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDimensionGroupRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDimensionGroupRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDimensionGroupRequest(od as api.UpdateDimensionGroupRequest);
    });
  });

  unittest.group('obj-schema-UpdateDimensionPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDimensionPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDimensionPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDimensionPropertiesRequest(
          od as api.UpdateDimensionPropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateEmbeddedObjectBorderRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateEmbeddedObjectBorderRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateEmbeddedObjectBorderRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateEmbeddedObjectBorderRequest(
          od as api.UpdateEmbeddedObjectBorderRequest);
    });
  });

  unittest.group('obj-schema-UpdateEmbeddedObjectPositionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateEmbeddedObjectPositionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateEmbeddedObjectPositionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateEmbeddedObjectPositionRequest(
          od as api.UpdateEmbeddedObjectPositionRequest);
    });
  });

  unittest.group('obj-schema-UpdateEmbeddedObjectPositionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateEmbeddedObjectPositionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateEmbeddedObjectPositionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateEmbeddedObjectPositionResponse(
          od as api.UpdateEmbeddedObjectPositionResponse);
    });
  });

  unittest.group('obj-schema-UpdateFilterViewRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateFilterViewRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateFilterViewRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateFilterViewRequest(od as api.UpdateFilterViewRequest);
    });
  });

  unittest.group('obj-schema-UpdateNamedRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateNamedRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateNamedRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateNamedRangeRequest(od as api.UpdateNamedRangeRequest);
    });
  });

  unittest.group('obj-schema-UpdateProtectedRangeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateProtectedRangeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateProtectedRangeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateProtectedRangeRequest(od as api.UpdateProtectedRangeRequest);
    });
  });

  unittest.group('obj-schema-UpdateSheetPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateSheetPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateSheetPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateSheetPropertiesRequest(od as api.UpdateSheetPropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateSlicerSpecRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateSlicerSpecRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateSlicerSpecRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateSlicerSpecRequest(od as api.UpdateSlicerSpecRequest);
    });
  });

  unittest.group('obj-schema-UpdateSpreadsheetPropertiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateSpreadsheetPropertiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateSpreadsheetPropertiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateSpreadsheetPropertiesRequest(
          od as api.UpdateSpreadsheetPropertiesRequest);
    });
  });

  unittest.group('obj-schema-UpdateValuesByDataFilterResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateValuesByDataFilterResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateValuesByDataFilterResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateValuesByDataFilterResponse(
          od as api.UpdateValuesByDataFilterResponse);
    });
  });

  unittest.group('obj-schema-UpdateValuesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateValuesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateValuesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateValuesResponse(od as api.UpdateValuesResponse);
    });
  });

  unittest.group('obj-schema-ValueRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValueRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ValueRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkValueRange(od as api.ValueRange);
    });
  });

  unittest.group('obj-schema-WaterfallChartColumnStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWaterfallChartColumnStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WaterfallChartColumnStyle.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWaterfallChartColumnStyle(od as api.WaterfallChartColumnStyle);
    });
  });

  unittest.group('obj-schema-WaterfallChartCustomSubtotal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWaterfallChartCustomSubtotal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WaterfallChartCustomSubtotal.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWaterfallChartCustomSubtotal(od as api.WaterfallChartCustomSubtotal);
    });
  });

  unittest.group('obj-schema-WaterfallChartDomain', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWaterfallChartDomain();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WaterfallChartDomain.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWaterfallChartDomain(od as api.WaterfallChartDomain);
    });
  });

  unittest.group('obj-schema-WaterfallChartSeries', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWaterfallChartSeries();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WaterfallChartSeries.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWaterfallChartSeries(od as api.WaterfallChartSeries);
    });
  });

  unittest.group('obj-schema-WaterfallChartSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWaterfallChartSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WaterfallChartSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWaterfallChartSpec(od as api.WaterfallChartSpec);
    });
  });

  unittest.group('resource-SpreadsheetsResource', () {
    unittest.test('method--batchUpdate', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets;
      var arg_request = buildBatchUpdateSpreadsheetRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchUpdateSpreadsheetRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchUpdateSpreadsheetRequest(
            obj as api.BatchUpdateSpreadsheetRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf(':batchUpdate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals(":batchUpdate"),
        );
        pathOffset += 12;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchUpdateSpreadsheetResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchUpdate(arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkBatchUpdateSpreadsheetResponse(
          response as api.BatchUpdateSpreadsheetResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets;
      var arg_request = buildSpreadsheet();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Spreadsheet.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSpreadsheet(obj as api.Spreadsheet);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v4/spreadsheets"),
        );
        pathOffset += 15;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSpreadsheet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkSpreadsheet(response as api.Spreadsheet);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets;
      var arg_spreadsheetId = 'foo';
      var arg_includeGridData = true;
      var arg_ranges = buildUnnamed745();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["includeGridData"]!.first,
          unittest.equals("$arg_includeGridData"),
        );
        unittest.expect(
          queryMap["ranges"]!,
          unittest.equals(arg_ranges),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSpreadsheet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_spreadsheetId,
          includeGridData: arg_includeGridData,
          ranges: arg_ranges,
          $fields: arg_$fields);
      checkSpreadsheet(response as api.Spreadsheet);
    });

    unittest.test('method--getByDataFilter', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets;
      var arg_request = buildGetSpreadsheetByDataFilterRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetSpreadsheetByDataFilterRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetSpreadsheetByDataFilterRequest(
            obj as api.GetSpreadsheetByDataFilterRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf(':getByDataFilter', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals(":getByDataFilter"),
        );
        pathOffset += 16;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSpreadsheet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getByDataFilter(arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkSpreadsheet(response as api.Spreadsheet);
    });
  });

  unittest.group('resource-SpreadsheetsDeveloperMetadataResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.developerMetadata;
      var arg_spreadsheetId = 'foo';
      var arg_metadataId = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/developerMetadata/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/developerMetadata/"),
        );
        pathOffset += 19;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_metadataId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDeveloperMetadata());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_spreadsheetId, arg_metadataId,
          $fields: arg_$fields);
      checkDeveloperMetadata(response as api.DeveloperMetadata);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.developerMetadata;
      var arg_request = buildSearchDeveloperMetadataRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchDeveloperMetadataRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchDeveloperMetadataRequest(
            obj as api.SearchDeveloperMetadataRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/developerMetadata:search', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("/developerMetadata:search"),
        );
        pathOffset += 25;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchDeveloperMetadataResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkSearchDeveloperMetadataResponse(
          response as api.SearchDeveloperMetadataResponse);
    });
  });

  unittest.group('resource-SpreadsheetsSheetsResource', () {
    unittest.test('method--copyTo', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.sheets;
      var arg_request = buildCopySheetToAnotherSpreadsheetRequest();
      var arg_spreadsheetId = 'foo';
      var arg_sheetId = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CopySheetToAnotherSpreadsheetRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCopySheetToAnotherSpreadsheetRequest(
            obj as api.CopySheetToAnotherSpreadsheetRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/sheets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/sheets/"),
        );
        pathOffset += 8;
        index = path.indexOf(':copyTo', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":copyTo"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSheetProperties());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.copyTo(
          arg_request, arg_spreadsheetId, arg_sheetId,
          $fields: arg_$fields);
      checkSheetProperties(response as api.SheetProperties);
    });
  });

  unittest.group('resource-SpreadsheetsValuesResource', () {
    unittest.test('method--append', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildValueRange();
      var arg_spreadsheetId = 'foo';
      var arg_range = 'foo';
      var arg_includeValuesInResponse = true;
      var arg_insertDataOption = 'foo';
      var arg_responseDateTimeRenderOption = 'foo';
      var arg_responseValueRenderOption = 'foo';
      var arg_valueInputOption = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ValueRange.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkValueRange(obj as api.ValueRange);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/values/"),
        );
        pathOffset += 8;
        index = path.indexOf(':append', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_range'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":append"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["includeValuesInResponse"]!.first,
          unittest.equals("$arg_includeValuesInResponse"),
        );
        unittest.expect(
          queryMap["insertDataOption"]!.first,
          unittest.equals(arg_insertDataOption),
        );
        unittest.expect(
          queryMap["responseDateTimeRenderOption"]!.first,
          unittest.equals(arg_responseDateTimeRenderOption),
        );
        unittest.expect(
          queryMap["responseValueRenderOption"]!.first,
          unittest.equals(arg_responseValueRenderOption),
        );
        unittest.expect(
          queryMap["valueInputOption"]!.first,
          unittest.equals(arg_valueInputOption),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAppendValuesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.append(
          arg_request, arg_spreadsheetId, arg_range,
          includeValuesInResponse: arg_includeValuesInResponse,
          insertDataOption: arg_insertDataOption,
          responseDateTimeRenderOption: arg_responseDateTimeRenderOption,
          responseValueRenderOption: arg_responseValueRenderOption,
          valueInputOption: arg_valueInputOption,
          $fields: arg_$fields);
      checkAppendValuesResponse(response as api.AppendValuesResponse);
    });

    unittest.test('method--batchClear', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildBatchClearValuesRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchClearValuesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchClearValuesRequest(obj as api.BatchClearValuesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values:batchClear', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/values:batchClear"),
        );
        pathOffset += 18;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchClearValuesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchClear(arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkBatchClearValuesResponse(response as api.BatchClearValuesResponse);
    });

    unittest.test('method--batchClearByDataFilter', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildBatchClearValuesByDataFilterRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchClearValuesByDataFilterRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchClearValuesByDataFilterRequest(
            obj as api.BatchClearValuesByDataFilterRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values:batchClearByDataFilter', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("/values:batchClearByDataFilter"),
        );
        pathOffset += 30;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildBatchClearValuesByDataFilterResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchClearByDataFilter(
          arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkBatchClearValuesByDataFilterResponse(
          response as api.BatchClearValuesByDataFilterResponse);
    });

    unittest.test('method--batchGet', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_spreadsheetId = 'foo';
      var arg_dateTimeRenderOption = 'foo';
      var arg_majorDimension = 'foo';
      var arg_ranges = buildUnnamed746();
      var arg_valueRenderOption = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values:batchGet', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/values:batchGet"),
        );
        pathOffset += 16;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["dateTimeRenderOption"]!.first,
          unittest.equals(arg_dateTimeRenderOption),
        );
        unittest.expect(
          queryMap["majorDimension"]!.first,
          unittest.equals(arg_majorDimension),
        );
        unittest.expect(
          queryMap["ranges"]!,
          unittest.equals(arg_ranges),
        );
        unittest.expect(
          queryMap["valueRenderOption"]!.first,
          unittest.equals(arg_valueRenderOption),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchGetValuesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchGet(arg_spreadsheetId,
          dateTimeRenderOption: arg_dateTimeRenderOption,
          majorDimension: arg_majorDimension,
          ranges: arg_ranges,
          valueRenderOption: arg_valueRenderOption,
          $fields: arg_$fields);
      checkBatchGetValuesResponse(response as api.BatchGetValuesResponse);
    });

    unittest.test('method--batchGetByDataFilter', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildBatchGetValuesByDataFilterRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchGetValuesByDataFilterRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchGetValuesByDataFilterRequest(
            obj as api.BatchGetValuesByDataFilterRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values:batchGetByDataFilter', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("/values:batchGetByDataFilter"),
        );
        pathOffset += 28;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildBatchGetValuesByDataFilterResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchGetByDataFilter(
          arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkBatchGetValuesByDataFilterResponse(
          response as api.BatchGetValuesByDataFilterResponse);
    });

    unittest.test('method--batchUpdate', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildBatchUpdateValuesRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchUpdateValuesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchUpdateValuesRequest(obj as api.BatchUpdateValuesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values:batchUpdate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/values:batchUpdate"),
        );
        pathOffset += 19;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchUpdateValuesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchUpdate(arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkBatchUpdateValuesResponse(response as api.BatchUpdateValuesResponse);
    });

    unittest.test('method--batchUpdateByDataFilter', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildBatchUpdateValuesByDataFilterRequest();
      var arg_spreadsheetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchUpdateValuesByDataFilterRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchUpdateValuesByDataFilterRequest(
            obj as api.BatchUpdateValuesByDataFilterRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values:batchUpdateByDataFilter', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 31),
          unittest.equals("/values:batchUpdateByDataFilter"),
        );
        pathOffset += 31;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildBatchUpdateValuesByDataFilterResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchUpdateByDataFilter(
          arg_request, arg_spreadsheetId,
          $fields: arg_$fields);
      checkBatchUpdateValuesByDataFilterResponse(
          response as api.BatchUpdateValuesByDataFilterResponse);
    });

    unittest.test('method--clear', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildClearValuesRequest();
      var arg_spreadsheetId = 'foo';
      var arg_range = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClearValuesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClearValuesRequest(obj as api.ClearValuesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/values/"),
        );
        pathOffset += 8;
        index = path.indexOf(':clear', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_range'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals(":clear"),
        );
        pathOffset += 6;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildClearValuesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.clear(
          arg_request, arg_spreadsheetId, arg_range,
          $fields: arg_$fields);
      checkClearValuesResponse(response as api.ClearValuesResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_spreadsheetId = 'foo';
      var arg_range = 'foo';
      var arg_dateTimeRenderOption = 'foo';
      var arg_majorDimension = 'foo';
      var arg_valueRenderOption = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/values/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_range'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["dateTimeRenderOption"]!.first,
          unittest.equals(arg_dateTimeRenderOption),
        );
        unittest.expect(
          queryMap["majorDimension"]!.first,
          unittest.equals(arg_majorDimension),
        );
        unittest.expect(
          queryMap["valueRenderOption"]!.first,
          unittest.equals(arg_valueRenderOption),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildValueRange());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_spreadsheetId, arg_range,
          dateTimeRenderOption: arg_dateTimeRenderOption,
          majorDimension: arg_majorDimension,
          valueRenderOption: arg_valueRenderOption,
          $fields: arg_$fields);
      checkValueRange(response as api.ValueRange);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.SheetsApi(mock).spreadsheets.values;
      var arg_request = buildValueRange();
      var arg_spreadsheetId = 'foo';
      var arg_range = 'foo';
      var arg_includeValuesInResponse = true;
      var arg_responseDateTimeRenderOption = 'foo';
      var arg_responseValueRenderOption = 'foo';
      var arg_valueInputOption = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ValueRange.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkValueRange(obj as api.ValueRange);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v4/spreadsheets/"),
        );
        pathOffset += 16;
        index = path.indexOf('/values/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_spreadsheetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/values/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_range'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["includeValuesInResponse"]!.first,
          unittest.equals("$arg_includeValuesInResponse"),
        );
        unittest.expect(
          queryMap["responseDateTimeRenderOption"]!.first,
          unittest.equals(arg_responseDateTimeRenderOption),
        );
        unittest.expect(
          queryMap["responseValueRenderOption"]!.first,
          unittest.equals(arg_responseValueRenderOption),
        );
        unittest.expect(
          queryMap["valueInputOption"]!.first,
          unittest.equals(arg_valueInputOption),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUpdateValuesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_spreadsheetId, arg_range,
          includeValuesInResponse: arg_includeValuesInResponse,
          responseDateTimeRenderOption: arg_responseDateTimeRenderOption,
          responseValueRenderOption: arg_responseValueRenderOption,
          valueInputOption: arg_valueInputOption,
          $fields: arg_$fields);
      checkUpdateValuesResponse(response as api.UpdateValuesResponse);
    });
  });
}

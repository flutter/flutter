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

import 'package:googleapis/doubleclicksearch/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAvailability = 0;
api.Availability buildAvailability() {
  var o = api.Availability();
  buildCounterAvailability++;
  if (buildCounterAvailability < 3) {
    o.advertiserId = 'foo';
    o.agencyId = 'foo';
    o.availabilityTimestamp = 'foo';
    o.segmentationId = 'foo';
    o.segmentationName = 'foo';
    o.segmentationType = 'foo';
  }
  buildCounterAvailability--;
  return o;
}

void checkAvailability(api.Availability o) {
  buildCounterAvailability++;
  if (buildCounterAvailability < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.agencyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.availabilityTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segmentationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segmentationName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segmentationType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAvailability--;
}

core.List<api.CustomDimension> buildUnnamed1716() {
  var o = <api.CustomDimension>[];
  o.add(buildCustomDimension());
  o.add(buildCustomDimension());
  return o;
}

void checkUnnamed1716(core.List<api.CustomDimension> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomDimension(o[0] as api.CustomDimension);
  checkCustomDimension(o[1] as api.CustomDimension);
}

core.List<api.CustomMetric> buildUnnamed1717() {
  var o = <api.CustomMetric>[];
  o.add(buildCustomMetric());
  o.add(buildCustomMetric());
  return o;
}

void checkUnnamed1717(core.List<api.CustomMetric> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomMetric(o[0] as api.CustomMetric);
  checkCustomMetric(o[1] as api.CustomMetric);
}

core.int buildCounterConversion = 0;
api.Conversion buildConversion() {
  var o = api.Conversion();
  buildCounterConversion++;
  if (buildCounterConversion < 3) {
    o.adGroupId = 'foo';
    o.adId = 'foo';
    o.advertiserId = 'foo';
    o.agencyId = 'foo';
    o.attributionModel = 'foo';
    o.campaignId = 'foo';
    o.channel = 'foo';
    o.clickId = 'foo';
    o.conversionId = 'foo';
    o.conversionModifiedTimestamp = 'foo';
    o.conversionTimestamp = 'foo';
    o.countMillis = 'foo';
    o.criterionId = 'foo';
    o.currencyCode = 'foo';
    o.customDimension = buildUnnamed1716();
    o.customMetric = buildUnnamed1717();
    o.deviceType = 'foo';
    o.dsConversionId = 'foo';
    o.engineAccountId = 'foo';
    o.floodlightOrderId = 'foo';
    o.inventoryAccountId = 'foo';
    o.productCountry = 'foo';
    o.productGroupId = 'foo';
    o.productId = 'foo';
    o.productLanguage = 'foo';
    o.quantityMillis = 'foo';
    o.revenueMicros = 'foo';
    o.segmentationId = 'foo';
    o.segmentationName = 'foo';
    o.segmentationType = 'foo';
    o.state = 'foo';
    o.storeId = 'foo';
    o.type = 'foo';
  }
  buildCounterConversion--;
  return o;
}

void checkConversion(api.Conversion o) {
  buildCounterConversion++;
  if (buildCounterConversion < 3) {
    unittest.expect(
      o.adGroupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.adId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.agencyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.attributionModel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.campaignId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clickId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.conversionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.conversionModifiedTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.conversionTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.countMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.criterionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    checkUnnamed1716(o.customDimension!);
    checkUnnamed1717(o.customMetric!);
    unittest.expect(
      o.deviceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dsConversionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.engineAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floodlightOrderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inventoryAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productCountry!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productGroupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.quantityMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revenueMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segmentationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segmentationName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segmentationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.storeId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterConversion--;
}

core.List<api.Conversion> buildUnnamed1718() {
  var o = <api.Conversion>[];
  o.add(buildConversion());
  o.add(buildConversion());
  return o;
}

void checkUnnamed1718(core.List<api.Conversion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConversion(o[0] as api.Conversion);
  checkConversion(o[1] as api.Conversion);
}

core.int buildCounterConversionList = 0;
api.ConversionList buildConversionList() {
  var o = api.ConversionList();
  buildCounterConversionList++;
  if (buildCounterConversionList < 3) {
    o.conversion = buildUnnamed1718();
    o.kind = 'foo';
  }
  buildCounterConversionList--;
  return o;
}

void checkConversionList(api.ConversionList o) {
  buildCounterConversionList++;
  if (buildCounterConversionList < 3) {
    checkUnnamed1718(o.conversion!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterConversionList--;
}

core.int buildCounterCustomDimension = 0;
api.CustomDimension buildCustomDimension() {
  var o = api.CustomDimension();
  buildCounterCustomDimension++;
  if (buildCounterCustomDimension < 3) {
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterCustomDimension--;
  return o;
}

void checkCustomDimension(api.CustomDimension o) {
  buildCounterCustomDimension++;
  if (buildCounterCustomDimension < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDimension--;
}

core.int buildCounterCustomMetric = 0;
api.CustomMetric buildCustomMetric() {
  var o = api.CustomMetric();
  buildCounterCustomMetric++;
  if (buildCounterCustomMetric < 3) {
    o.name = 'foo';
    o.value = 42.0;
  }
  buildCounterCustomMetric--;
  return o;
}

void checkCustomMetric(api.CustomMetric o) {
  buildCounterCustomMetric++;
  if (buildCounterCustomMetric < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals(42.0),
    );
  }
  buildCounterCustomMetric--;
}

core.int buildCounterReportFiles = 0;
api.ReportFiles buildReportFiles() {
  var o = api.ReportFiles();
  buildCounterReportFiles++;
  if (buildCounterReportFiles < 3) {
    o.byteCount = 'foo';
    o.url = 'foo';
  }
  buildCounterReportFiles--;
  return o;
}

void checkReportFiles(api.ReportFiles o) {
  buildCounterReportFiles++;
  if (buildCounterReportFiles < 3) {
    unittest.expect(
      o.byteCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportFiles--;
}

core.List<api.ReportFiles> buildUnnamed1719() {
  var o = <api.ReportFiles>[];
  o.add(buildReportFiles());
  o.add(buildReportFiles());
  return o;
}

void checkUnnamed1719(core.List<api.ReportFiles> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportFiles(o[0] as api.ReportFiles);
  checkReportFiles(o[1] as api.ReportFiles);
}

core.List<api.ReportRow> buildUnnamed1720() {
  var o = <api.ReportRow>[];
  o.add(buildReportRow());
  o.add(buildReportRow());
  return o;
}

void checkUnnamed1720(core.List<api.ReportRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportRow(o[0] as api.ReportRow);
  checkReportRow(o[1] as api.ReportRow);
}

core.int buildCounterReport = 0;
api.Report buildReport() {
  var o = api.Report();
  buildCounterReport++;
  if (buildCounterReport < 3) {
    o.files = buildUnnamed1719();
    o.id = 'foo';
    o.isReportReady = true;
    o.kind = 'foo';
    o.request = buildReportRequest();
    o.rowCount = 42;
    o.rows = buildUnnamed1720();
    o.statisticsCurrencyCode = 'foo';
    o.statisticsTimeZone = 'foo';
  }
  buildCounterReport--;
  return o;
}

void checkReport(api.Report o) {
  buildCounterReport++;
  if (buildCounterReport < 3) {
    checkUnnamed1719(o.files!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isReportReady!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkReportRequest(o.request! as api.ReportRequest);
    unittest.expect(
      o.rowCount!,
      unittest.equals(42),
    );
    checkUnnamed1720(o.rows!);
    unittest.expect(
      o.statisticsCurrencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.statisticsTimeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterReport--;
}

core.int buildCounterReportApiColumnSpec = 0;
api.ReportApiColumnSpec buildReportApiColumnSpec() {
  var o = api.ReportApiColumnSpec();
  buildCounterReportApiColumnSpec++;
  if (buildCounterReportApiColumnSpec < 3) {
    o.columnName = 'foo';
    o.customDimensionName = 'foo';
    o.customMetricName = 'foo';
    o.endDate = 'foo';
    o.groupByColumn = true;
    o.headerText = 'foo';
    o.platformSource = 'foo';
    o.productReportPerspective = 'foo';
    o.savedColumnName = 'foo';
    o.startDate = 'foo';
  }
  buildCounterReportApiColumnSpec--;
  return o;
}

void checkReportApiColumnSpec(api.ReportApiColumnSpec o) {
  buildCounterReportApiColumnSpec++;
  if (buildCounterReportApiColumnSpec < 3) {
    unittest.expect(
      o.columnName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customDimensionName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customMetricName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    unittest.expect(o.groupByColumn!, unittest.isTrue);
    unittest.expect(
      o.headerText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platformSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productReportPerspective!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.savedColumnName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportApiColumnSpec--;
}

core.List<api.ReportApiColumnSpec> buildUnnamed1721() {
  var o = <api.ReportApiColumnSpec>[];
  o.add(buildReportApiColumnSpec());
  o.add(buildReportApiColumnSpec());
  return o;
}

void checkUnnamed1721(core.List<api.ReportApiColumnSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportApiColumnSpec(o[0] as api.ReportApiColumnSpec);
  checkReportApiColumnSpec(o[1] as api.ReportApiColumnSpec);
}

core.List<core.Object> buildUnnamed1722() {
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

void checkUnnamed1722(core.List<core.Object> o) {
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

core.int buildCounterReportRequestFilters = 0;
api.ReportRequestFilters buildReportRequestFilters() {
  var o = api.ReportRequestFilters();
  buildCounterReportRequestFilters++;
  if (buildCounterReportRequestFilters < 3) {
    o.column = buildReportApiColumnSpec();
    o.operator = 'foo';
    o.values = buildUnnamed1722();
  }
  buildCounterReportRequestFilters--;
  return o;
}

void checkReportRequestFilters(api.ReportRequestFilters o) {
  buildCounterReportRequestFilters++;
  if (buildCounterReportRequestFilters < 3) {
    checkReportApiColumnSpec(o.column! as api.ReportApiColumnSpec);
    unittest.expect(
      o.operator!,
      unittest.equals('foo'),
    );
    checkUnnamed1722(o.values!);
  }
  buildCounterReportRequestFilters--;
}

core.List<api.ReportRequestFilters> buildUnnamed1723() {
  var o = <api.ReportRequestFilters>[];
  o.add(buildReportRequestFilters());
  o.add(buildReportRequestFilters());
  return o;
}

void checkUnnamed1723(core.List<api.ReportRequestFilters> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportRequestFilters(o[0] as api.ReportRequestFilters);
  checkReportRequestFilters(o[1] as api.ReportRequestFilters);
}

core.int buildCounterReportRequestOrderBy = 0;
api.ReportRequestOrderBy buildReportRequestOrderBy() {
  var o = api.ReportRequestOrderBy();
  buildCounterReportRequestOrderBy++;
  if (buildCounterReportRequestOrderBy < 3) {
    o.column = buildReportApiColumnSpec();
    o.sortOrder = 'foo';
  }
  buildCounterReportRequestOrderBy--;
  return o;
}

void checkReportRequestOrderBy(api.ReportRequestOrderBy o) {
  buildCounterReportRequestOrderBy++;
  if (buildCounterReportRequestOrderBy < 3) {
    checkReportApiColumnSpec(o.column! as api.ReportApiColumnSpec);
    unittest.expect(
      o.sortOrder!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportRequestOrderBy--;
}

core.List<api.ReportRequestOrderBy> buildUnnamed1724() {
  var o = <api.ReportRequestOrderBy>[];
  o.add(buildReportRequestOrderBy());
  o.add(buildReportRequestOrderBy());
  return o;
}

void checkUnnamed1724(core.List<api.ReportRequestOrderBy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportRequestOrderBy(o[0] as api.ReportRequestOrderBy);
  checkReportRequestOrderBy(o[1] as api.ReportRequestOrderBy);
}

core.int buildCounterReportRequestReportScope = 0;
api.ReportRequestReportScope buildReportRequestReportScope() {
  var o = api.ReportRequestReportScope();
  buildCounterReportRequestReportScope++;
  if (buildCounterReportRequestReportScope < 3) {
    o.adGroupId = 'foo';
    o.adId = 'foo';
    o.advertiserId = 'foo';
    o.agencyId = 'foo';
    o.campaignId = 'foo';
    o.engineAccountId = 'foo';
    o.keywordId = 'foo';
  }
  buildCounterReportRequestReportScope--;
  return o;
}

void checkReportRequestReportScope(api.ReportRequestReportScope o) {
  buildCounterReportRequestReportScope++;
  if (buildCounterReportRequestReportScope < 3) {
    unittest.expect(
      o.adGroupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.adId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.agencyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.campaignId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.engineAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.keywordId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportRequestReportScope--;
}

core.int buildCounterReportRequestTimeRange = 0;
api.ReportRequestTimeRange buildReportRequestTimeRange() {
  var o = api.ReportRequestTimeRange();
  buildCounterReportRequestTimeRange++;
  if (buildCounterReportRequestTimeRange < 3) {
    o.changedAttributesSinceTimestamp = 'foo';
    o.changedMetricsSinceTimestamp = 'foo';
    o.endDate = 'foo';
    o.startDate = 'foo';
  }
  buildCounterReportRequestTimeRange--;
  return o;
}

void checkReportRequestTimeRange(api.ReportRequestTimeRange o) {
  buildCounterReportRequestTimeRange++;
  if (buildCounterReportRequestTimeRange < 3) {
    unittest.expect(
      o.changedAttributesSinceTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.changedMetricsSinceTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportRequestTimeRange--;
}

core.int buildCounterReportRequest = 0;
api.ReportRequest buildReportRequest() {
  var o = api.ReportRequest();
  buildCounterReportRequest++;
  if (buildCounterReportRequest < 3) {
    o.columns = buildUnnamed1721();
    o.downloadFormat = 'foo';
    o.filters = buildUnnamed1723();
    o.includeDeletedEntities = true;
    o.includeRemovedEntities = true;
    o.maxRowsPerFile = 42;
    o.orderBy = buildUnnamed1724();
    o.reportScope = buildReportRequestReportScope();
    o.reportType = 'foo';
    o.rowCount = 42;
    o.startRow = 42;
    o.statisticsCurrency = 'foo';
    o.timeRange = buildReportRequestTimeRange();
    o.verifySingleTimeZone = true;
  }
  buildCounterReportRequest--;
  return o;
}

void checkReportRequest(api.ReportRequest o) {
  buildCounterReportRequest++;
  if (buildCounterReportRequest < 3) {
    checkUnnamed1721(o.columns!);
    unittest.expect(
      o.downloadFormat!,
      unittest.equals('foo'),
    );
    checkUnnamed1723(o.filters!);
    unittest.expect(o.includeDeletedEntities!, unittest.isTrue);
    unittest.expect(o.includeRemovedEntities!, unittest.isTrue);
    unittest.expect(
      o.maxRowsPerFile!,
      unittest.equals(42),
    );
    checkUnnamed1724(o.orderBy!);
    checkReportRequestReportScope(
        o.reportScope! as api.ReportRequestReportScope);
    unittest.expect(
      o.reportType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rowCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startRow!,
      unittest.equals(42),
    );
    unittest.expect(
      o.statisticsCurrency!,
      unittest.equals('foo'),
    );
    checkReportRequestTimeRange(o.timeRange! as api.ReportRequestTimeRange);
    unittest.expect(o.verifySingleTimeZone!, unittest.isTrue);
  }
  buildCounterReportRequest--;
}

api.ReportRow buildReportRow() {
  var o = api.ReportRow();
  o["a"] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o["b"] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkReportRow(api.ReportRow o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o["a"]!) as core.Map;
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
  var casted4 = (o["b"]!) as core.Map;
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

core.int buildCounterSavedColumn = 0;
api.SavedColumn buildSavedColumn() {
  var o = api.SavedColumn();
  buildCounterSavedColumn++;
  if (buildCounterSavedColumn < 3) {
    o.kind = 'foo';
    o.savedColumnName = 'foo';
    o.type = 'foo';
  }
  buildCounterSavedColumn--;
  return o;
}

void checkSavedColumn(api.SavedColumn o) {
  buildCounterSavedColumn++;
  if (buildCounterSavedColumn < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.savedColumnName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSavedColumn--;
}

core.List<api.SavedColumn> buildUnnamed1725() {
  var o = <api.SavedColumn>[];
  o.add(buildSavedColumn());
  o.add(buildSavedColumn());
  return o;
}

void checkUnnamed1725(core.List<api.SavedColumn> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSavedColumn(o[0] as api.SavedColumn);
  checkSavedColumn(o[1] as api.SavedColumn);
}

core.int buildCounterSavedColumnList = 0;
api.SavedColumnList buildSavedColumnList() {
  var o = api.SavedColumnList();
  buildCounterSavedColumnList++;
  if (buildCounterSavedColumnList < 3) {
    o.items = buildUnnamed1725();
    o.kind = 'foo';
  }
  buildCounterSavedColumnList--;
  return o;
}

void checkSavedColumnList(api.SavedColumnList o) {
  buildCounterSavedColumnList++;
  if (buildCounterSavedColumnList < 3) {
    checkUnnamed1725(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterSavedColumnList--;
}

core.List<api.Availability> buildUnnamed1726() {
  var o = <api.Availability>[];
  o.add(buildAvailability());
  o.add(buildAvailability());
  return o;
}

void checkUnnamed1726(core.List<api.Availability> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAvailability(o[0] as api.Availability);
  checkAvailability(o[1] as api.Availability);
}

core.int buildCounterUpdateAvailabilityRequest = 0;
api.UpdateAvailabilityRequest buildUpdateAvailabilityRequest() {
  var o = api.UpdateAvailabilityRequest();
  buildCounterUpdateAvailabilityRequest++;
  if (buildCounterUpdateAvailabilityRequest < 3) {
    o.availabilities = buildUnnamed1726();
  }
  buildCounterUpdateAvailabilityRequest--;
  return o;
}

void checkUpdateAvailabilityRequest(api.UpdateAvailabilityRequest o) {
  buildCounterUpdateAvailabilityRequest++;
  if (buildCounterUpdateAvailabilityRequest < 3) {
    checkUnnamed1726(o.availabilities!);
  }
  buildCounterUpdateAvailabilityRequest--;
}

core.List<api.Availability> buildUnnamed1727() {
  var o = <api.Availability>[];
  o.add(buildAvailability());
  o.add(buildAvailability());
  return o;
}

void checkUnnamed1727(core.List<api.Availability> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAvailability(o[0] as api.Availability);
  checkAvailability(o[1] as api.Availability);
}

core.int buildCounterUpdateAvailabilityResponse = 0;
api.UpdateAvailabilityResponse buildUpdateAvailabilityResponse() {
  var o = api.UpdateAvailabilityResponse();
  buildCounterUpdateAvailabilityResponse++;
  if (buildCounterUpdateAvailabilityResponse < 3) {
    o.availabilities = buildUnnamed1727();
  }
  buildCounterUpdateAvailabilityResponse--;
  return o;
}

void checkUpdateAvailabilityResponse(api.UpdateAvailabilityResponse o) {
  buildCounterUpdateAvailabilityResponse++;
  if (buildCounterUpdateAvailabilityResponse < 3) {
    checkUnnamed1727(o.availabilities!);
  }
  buildCounterUpdateAvailabilityResponse--;
}

void main() {
  unittest.group('obj-schema-Availability', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAvailability();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Availability.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAvailability(od as api.Availability);
    });
  });

  unittest.group('obj-schema-Conversion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConversion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Conversion.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkConversion(od as api.Conversion);
    });
  });

  unittest.group('obj-schema-ConversionList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConversionList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConversionList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConversionList(od as api.ConversionList);
    });
  });

  unittest.group('obj-schema-CustomDimension', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDimension();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDimension.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDimension(od as api.CustomDimension);
    });
  });

  unittest.group('obj-schema-CustomMetric', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomMetric();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomMetric.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomMetric(od as api.CustomMetric);
    });
  });

  unittest.group('obj-schema-ReportFiles', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportFiles();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportFiles.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportFiles(od as api.ReportFiles);
    });
  });

  unittest.group('obj-schema-Report', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Report.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReport(od as api.Report);
    });
  });

  unittest.group('obj-schema-ReportApiColumnSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportApiColumnSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportApiColumnSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportApiColumnSpec(od as api.ReportApiColumnSpec);
    });
  });

  unittest.group('obj-schema-ReportRequestFilters', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRequestFilters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRequestFilters.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRequestFilters(od as api.ReportRequestFilters);
    });
  });

  unittest.group('obj-schema-ReportRequestOrderBy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRequestOrderBy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRequestOrderBy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRequestOrderBy(od as api.ReportRequestOrderBy);
    });
  });

  unittest.group('obj-schema-ReportRequestReportScope', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRequestReportScope();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRequestReportScope.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRequestReportScope(od as api.ReportRequestReportScope);
    });
  });

  unittest.group('obj-schema-ReportRequestTimeRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRequestTimeRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRequestTimeRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRequestTimeRange(od as api.ReportRequestTimeRange);
    });
  });

  unittest.group('obj-schema-ReportRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRequest(od as api.ReportRequest);
    });
  });

  unittest.group('obj-schema-ReportRow', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ReportRow.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReportRow(od as api.ReportRow);
    });
  });

  unittest.group('obj-schema-SavedColumn', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSavedColumn();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SavedColumn.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSavedColumn(od as api.SavedColumn);
    });
  });

  unittest.group('obj-schema-SavedColumnList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSavedColumnList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SavedColumnList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSavedColumnList(od as api.SavedColumnList);
    });
  });

  unittest.group('obj-schema-UpdateAvailabilityRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateAvailabilityRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateAvailabilityRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateAvailabilityRequest(od as api.UpdateAvailabilityRequest);
    });
  });

  unittest.group('obj-schema-UpdateAvailabilityResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateAvailabilityResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateAvailabilityResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateAvailabilityResponse(od as api.UpdateAvailabilityResponse);
    });
  });

  unittest.group('resource-ConversionResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).conversion;
      var arg_agencyId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_engineAccountId = 'foo';
      var arg_endDate = 42;
      var arg_rowCount = 42;
      var arg_startDate = 42;
      var arg_startRow = 42;
      var arg_adGroupId = 'foo';
      var arg_adId = 'foo';
      var arg_campaignId = 'foo';
      var arg_criterionId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("doubleclicksearch/v2/agency/"),
        );
        pathOffset += 28;
        index = path.indexOf('/advertiser/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_agencyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/advertiser/"),
        );
        pathOffset += 12;
        index = path.indexOf('/engine/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/engine/"),
        );
        pathOffset += 8;
        index = path.indexOf('/conversion', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_engineAccountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/conversion"),
        );
        pathOffset += 11;

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
          core.int.parse(queryMap["endDate"]!.first),
          unittest.equals(arg_endDate),
        );
        unittest.expect(
          core.int.parse(queryMap["rowCount"]!.first),
          unittest.equals(arg_rowCount),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate"]!.first),
          unittest.equals(arg_startDate),
        );
        unittest.expect(
          core.int.parse(queryMap["startRow"]!.first),
          unittest.equals(arg_startRow),
        );
        unittest.expect(
          queryMap["adGroupId"]!.first,
          unittest.equals(arg_adGroupId),
        );
        unittest.expect(
          queryMap["adId"]!.first,
          unittest.equals(arg_adId),
        );
        unittest.expect(
          queryMap["campaignId"]!.first,
          unittest.equals(arg_campaignId),
        );
        unittest.expect(
          queryMap["criterionId"]!.first,
          unittest.equals(arg_criterionId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildConversionList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_agencyId,
          arg_advertiserId,
          arg_engineAccountId,
          arg_endDate,
          arg_rowCount,
          arg_startDate,
          arg_startRow,
          adGroupId: arg_adGroupId,
          adId: arg_adId,
          campaignId: arg_campaignId,
          criterionId: arg_criterionId,
          $fields: arg_$fields);
      checkConversionList(response as api.ConversionList);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).conversion;
      var arg_request = buildConversionList();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConversionList.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConversionList(obj as api.ConversionList);

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
          path.substring(pathOffset, pathOffset + 31),
          unittest.equals("doubleclicksearch/v2/conversion"),
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
        var resp = convert.json.encode(buildConversionList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, $fields: arg_$fields);
      checkConversionList(response as api.ConversionList);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).conversion;
      var arg_request = buildConversionList();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConversionList.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConversionList(obj as api.ConversionList);

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
          path.substring(pathOffset, pathOffset + 31),
          unittest.equals("doubleclicksearch/v2/conversion"),
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
        var resp = convert.json.encode(buildConversionList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, $fields: arg_$fields);
      checkConversionList(response as api.ConversionList);
    });

    unittest.test('method--updateAvailability', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).conversion;
      var arg_request = buildUpdateAvailabilityRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateAvailabilityRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateAvailabilityRequest(obj as api.UpdateAvailabilityRequest);

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
          path.substring(pathOffset, pathOffset + 50),
          unittest.equals("doubleclicksearch/v2/conversion/updateAvailability"),
        );
        pathOffset += 50;

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
        var resp = convert.json.encode(buildUpdateAvailabilityResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.updateAvailability(arg_request, $fields: arg_$fields);
      checkUpdateAvailabilityResponse(
          response as api.UpdateAvailabilityResponse);
    });
  });

  unittest.group('resource-ReportsResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).reports;
      var arg_request_1 = buildReportRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReportRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReportRequest(obj as api.ReportRequest);

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
          path.substring(pathOffset, pathOffset + 37),
          unittest.equals("doubleclicksearch/v2/reports/generate"),
        );
        pathOffset += 37;

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
        var resp = convert.json.encode(buildReport());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generate(arg_request_1, $fields: arg_$fields);
      checkReport(response as api.Report);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).reports;
      var arg_reportId = 'foo';
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
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("doubleclicksearch/v2/reports/"),
        );
        pathOffset += 29;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_reportId'),
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
        var resp = convert.json.encode(buildReport());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_reportId, $fields: arg_$fields);
      checkReport(response as api.Report);
    });

    unittest.test('method--getFile', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).reports;
      var arg_reportId = 'foo';
      var arg_reportFragment = 42;
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
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("doubleclicksearch/v2/reports/"),
        );
        pathOffset += 29;
        index = path.indexOf('/files/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_reportId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/files/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_reportFragment'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.getFile(arg_reportId, arg_reportFragment, $fields: arg_$fields);
    });

    unittest.test('method--request', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).reports;
      var arg_request_1 = buildReportRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReportRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReportRequest(obj as api.ReportRequest);

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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("doubleclicksearch/v2/reports"),
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
        var resp = convert.json.encode(buildReport());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.request(arg_request_1, $fields: arg_$fields);
      checkReport(response as api.Report);
    });
  });

  unittest.group('resource-SavedColumnsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DoubleclicksearchApi(mock).savedColumns;
      var arg_agencyId = 'foo';
      var arg_advertiserId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("doubleclicksearch/v2/agency/"),
        );
        pathOffset += 28;
        index = path.indexOf('/advertiser/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_agencyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/advertiser/"),
        );
        pathOffset += 12;
        index = path.indexOf('/savedcolumns', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/savedcolumns"),
        );
        pathOffset += 13;

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
        var resp = convert.json.encode(buildSavedColumnList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_agencyId, arg_advertiserId, $fields: arg_$fields);
      checkSavedColumnList(response as api.SavedColumnList);
    });
  });
}

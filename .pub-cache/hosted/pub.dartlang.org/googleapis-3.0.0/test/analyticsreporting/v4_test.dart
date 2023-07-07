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

import 'package:googleapis/analyticsreporting/v4.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.CustomDimension> buildUnnamed7091() {
  var o = <api.CustomDimension>[];
  o.add(buildCustomDimension());
  o.add(buildCustomDimension());
  return o;
}

void checkUnnamed7091(core.List<api.CustomDimension> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomDimension(o[0] as api.CustomDimension);
  checkCustomDimension(o[1] as api.CustomDimension);
}

core.int buildCounterActivity = 0;
api.Activity buildActivity() {
  var o = api.Activity();
  buildCounterActivity++;
  if (buildCounterActivity < 3) {
    o.activityTime = 'foo';
    o.activityType = 'foo';
    o.appview = buildScreenviewData();
    o.campaign = 'foo';
    o.channelGrouping = 'foo';
    o.customDimension = buildUnnamed7091();
    o.ecommerce = buildEcommerceData();
    o.event = buildEventData();
    o.goals = buildGoalSetData();
    o.hostname = 'foo';
    o.keyword = 'foo';
    o.landingPagePath = 'foo';
    o.medium = 'foo';
    o.pageview = buildPageviewData();
    o.source = 'foo';
  }
  buildCounterActivity--;
  return o;
}

void checkActivity(api.Activity o) {
  buildCounterActivity++;
  if (buildCounterActivity < 3) {
    unittest.expect(
      o.activityTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.activityType!,
      unittest.equals('foo'),
    );
    checkScreenviewData(o.appview! as api.ScreenviewData);
    unittest.expect(
      o.campaign!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelGrouping!,
      unittest.equals('foo'),
    );
    checkUnnamed7091(o.customDimension!);
    checkEcommerceData(o.ecommerce! as api.EcommerceData);
    checkEventData(o.event! as api.EventData);
    checkGoalSetData(o.goals! as api.GoalSetData);
    unittest.expect(
      o.hostname!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.keyword!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.landingPagePath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.medium!,
      unittest.equals('foo'),
    );
    checkPageviewData(o.pageview! as api.PageviewData);
    unittest.expect(
      o.source!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivity--;
}

core.int buildCounterCohort = 0;
api.Cohort buildCohort() {
  var o = api.Cohort();
  buildCounterCohort++;
  if (buildCounterCohort < 3) {
    o.dateRange = buildDateRange();
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterCohort--;
  return o;
}

void checkCohort(api.Cohort o) {
  buildCounterCohort++;
  if (buildCounterCohort < 3) {
    checkDateRange(o.dateRange! as api.DateRange);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCohort--;
}

core.List<api.Cohort> buildUnnamed7092() {
  var o = <api.Cohort>[];
  o.add(buildCohort());
  o.add(buildCohort());
  return o;
}

void checkUnnamed7092(core.List<api.Cohort> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCohort(o[0] as api.Cohort);
  checkCohort(o[1] as api.Cohort);
}

core.int buildCounterCohortGroup = 0;
api.CohortGroup buildCohortGroup() {
  var o = api.CohortGroup();
  buildCounterCohortGroup++;
  if (buildCounterCohortGroup < 3) {
    o.cohorts = buildUnnamed7092();
    o.lifetimeValue = true;
  }
  buildCounterCohortGroup--;
  return o;
}

void checkCohortGroup(api.CohortGroup o) {
  buildCounterCohortGroup++;
  if (buildCounterCohortGroup < 3) {
    checkUnnamed7092(o.cohorts!);
    unittest.expect(o.lifetimeValue!, unittest.isTrue);
  }
  buildCounterCohortGroup--;
}

core.List<core.String> buildUnnamed7093() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7093(core.List<core.String> o) {
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

core.int buildCounterColumnHeader = 0;
api.ColumnHeader buildColumnHeader() {
  var o = api.ColumnHeader();
  buildCounterColumnHeader++;
  if (buildCounterColumnHeader < 3) {
    o.dimensions = buildUnnamed7093();
    o.metricHeader = buildMetricHeader();
  }
  buildCounterColumnHeader--;
  return o;
}

void checkColumnHeader(api.ColumnHeader o) {
  buildCounterColumnHeader++;
  if (buildCounterColumnHeader < 3) {
    checkUnnamed7093(o.dimensions!);
    checkMetricHeader(o.metricHeader! as api.MetricHeader);
  }
  buildCounterColumnHeader--;
}

core.int buildCounterCustomDimension = 0;
api.CustomDimension buildCustomDimension() {
  var o = api.CustomDimension();
  buildCounterCustomDimension++;
  if (buildCounterCustomDimension < 3) {
    o.index = 42;
    o.value = 'foo';
  }
  buildCounterCustomDimension--;
  return o;
}

void checkCustomDimension(api.CustomDimension o) {
  buildCounterCustomDimension++;
  if (buildCounterCustomDimension < 3) {
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDimension--;
}

core.int buildCounterDateRange = 0;
api.DateRange buildDateRange() {
  var o = api.DateRange();
  buildCounterDateRange++;
  if (buildCounterDateRange < 3) {
    o.endDate = 'foo';
    o.startDate = 'foo';
  }
  buildCounterDateRange--;
  return o;
}

void checkDateRange(api.DateRange o) {
  buildCounterDateRange++;
  if (buildCounterDateRange < 3) {
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
  }
  buildCounterDateRange--;
}

core.List<api.PivotValueRegion> buildUnnamed7094() {
  var o = <api.PivotValueRegion>[];
  o.add(buildPivotValueRegion());
  o.add(buildPivotValueRegion());
  return o;
}

void checkUnnamed7094(core.List<api.PivotValueRegion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotValueRegion(o[0] as api.PivotValueRegion);
  checkPivotValueRegion(o[1] as api.PivotValueRegion);
}

core.List<core.String> buildUnnamed7095() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7095(core.List<core.String> o) {
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

core.int buildCounterDateRangeValues = 0;
api.DateRangeValues buildDateRangeValues() {
  var o = api.DateRangeValues();
  buildCounterDateRangeValues++;
  if (buildCounterDateRangeValues < 3) {
    o.pivotValueRegions = buildUnnamed7094();
    o.values = buildUnnamed7095();
  }
  buildCounterDateRangeValues--;
  return o;
}

void checkDateRangeValues(api.DateRangeValues o) {
  buildCounterDateRangeValues++;
  if (buildCounterDateRangeValues < 3) {
    checkUnnamed7094(o.pivotValueRegions!);
    checkUnnamed7095(o.values!);
  }
  buildCounterDateRangeValues--;
}

core.List<core.String> buildUnnamed7096() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7096(core.List<core.String> o) {
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

core.int buildCounterDimension = 0;
api.Dimension buildDimension() {
  var o = api.Dimension();
  buildCounterDimension++;
  if (buildCounterDimension < 3) {
    o.histogramBuckets = buildUnnamed7096();
    o.name = 'foo';
  }
  buildCounterDimension--;
  return o;
}

void checkDimension(api.Dimension o) {
  buildCounterDimension++;
  if (buildCounterDimension < 3) {
    checkUnnamed7096(o.histogramBuckets!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterDimension--;
}

core.List<core.String> buildUnnamed7097() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7097(core.List<core.String> o) {
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

core.int buildCounterDimensionFilter = 0;
api.DimensionFilter buildDimensionFilter() {
  var o = api.DimensionFilter();
  buildCounterDimensionFilter++;
  if (buildCounterDimensionFilter < 3) {
    o.caseSensitive = true;
    o.dimensionName = 'foo';
    o.expressions = buildUnnamed7097();
    o.not = true;
    o.operator = 'foo';
  }
  buildCounterDimensionFilter--;
  return o;
}

void checkDimensionFilter(api.DimensionFilter o) {
  buildCounterDimensionFilter++;
  if (buildCounterDimensionFilter < 3) {
    unittest.expect(o.caseSensitive!, unittest.isTrue);
    unittest.expect(
      o.dimensionName!,
      unittest.equals('foo'),
    );
    checkUnnamed7097(o.expressions!);
    unittest.expect(o.not!, unittest.isTrue);
    unittest.expect(
      o.operator!,
      unittest.equals('foo'),
    );
  }
  buildCounterDimensionFilter--;
}

core.List<api.DimensionFilter> buildUnnamed7098() {
  var o = <api.DimensionFilter>[];
  o.add(buildDimensionFilter());
  o.add(buildDimensionFilter());
  return o;
}

void checkUnnamed7098(core.List<api.DimensionFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionFilter(o[0] as api.DimensionFilter);
  checkDimensionFilter(o[1] as api.DimensionFilter);
}

core.int buildCounterDimensionFilterClause = 0;
api.DimensionFilterClause buildDimensionFilterClause() {
  var o = api.DimensionFilterClause();
  buildCounterDimensionFilterClause++;
  if (buildCounterDimensionFilterClause < 3) {
    o.filters = buildUnnamed7098();
    o.operator = 'foo';
  }
  buildCounterDimensionFilterClause--;
  return o;
}

void checkDimensionFilterClause(api.DimensionFilterClause o) {
  buildCounterDimensionFilterClause++;
  if (buildCounterDimensionFilterClause < 3) {
    checkUnnamed7098(o.filters!);
    unittest.expect(
      o.operator!,
      unittest.equals('foo'),
    );
  }
  buildCounterDimensionFilterClause--;
}

core.int buildCounterDynamicSegment = 0;
api.DynamicSegment buildDynamicSegment() {
  var o = api.DynamicSegment();
  buildCounterDynamicSegment++;
  if (buildCounterDynamicSegment < 3) {
    o.name = 'foo';
    o.sessionSegment = buildSegmentDefinition();
    o.userSegment = buildSegmentDefinition();
  }
  buildCounterDynamicSegment--;
  return o;
}

void checkDynamicSegment(api.DynamicSegment o) {
  buildCounterDynamicSegment++;
  if (buildCounterDynamicSegment < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkSegmentDefinition(o.sessionSegment! as api.SegmentDefinition);
    checkSegmentDefinition(o.userSegment! as api.SegmentDefinition);
  }
  buildCounterDynamicSegment--;
}

core.List<api.ProductData> buildUnnamed7099() {
  var o = <api.ProductData>[];
  o.add(buildProductData());
  o.add(buildProductData());
  return o;
}

void checkUnnamed7099(core.List<api.ProductData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProductData(o[0] as api.ProductData);
  checkProductData(o[1] as api.ProductData);
}

core.int buildCounterEcommerceData = 0;
api.EcommerceData buildEcommerceData() {
  var o = api.EcommerceData();
  buildCounterEcommerceData++;
  if (buildCounterEcommerceData < 3) {
    o.actionType = 'foo';
    o.ecommerceType = 'foo';
    o.products = buildUnnamed7099();
    o.transaction = buildTransactionData();
  }
  buildCounterEcommerceData--;
  return o;
}

void checkEcommerceData(api.EcommerceData o) {
  buildCounterEcommerceData++;
  if (buildCounterEcommerceData < 3) {
    unittest.expect(
      o.actionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ecommerceType!,
      unittest.equals('foo'),
    );
    checkUnnamed7099(o.products!);
    checkTransactionData(o.transaction! as api.TransactionData);
  }
  buildCounterEcommerceData--;
}

core.int buildCounterEventData = 0;
api.EventData buildEventData() {
  var o = api.EventData();
  buildCounterEventData++;
  if (buildCounterEventData < 3) {
    o.eventAction = 'foo';
    o.eventCategory = 'foo';
    o.eventCount = 'foo';
    o.eventLabel = 'foo';
    o.eventValue = 'foo';
  }
  buildCounterEventData--;
  return o;
}

void checkEventData(api.EventData o) {
  buildCounterEventData++;
  if (buildCounterEventData < 3) {
    unittest.expect(
      o.eventAction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventCategory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterEventData--;
}

core.List<api.ReportRequest> buildUnnamed7100() {
  var o = <api.ReportRequest>[];
  o.add(buildReportRequest());
  o.add(buildReportRequest());
  return o;
}

void checkUnnamed7100(core.List<api.ReportRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportRequest(o[0] as api.ReportRequest);
  checkReportRequest(o[1] as api.ReportRequest);
}

core.int buildCounterGetReportsRequest = 0;
api.GetReportsRequest buildGetReportsRequest() {
  var o = api.GetReportsRequest();
  buildCounterGetReportsRequest++;
  if (buildCounterGetReportsRequest < 3) {
    o.reportRequests = buildUnnamed7100();
    o.useResourceQuotas = true;
  }
  buildCounterGetReportsRequest--;
  return o;
}

void checkGetReportsRequest(api.GetReportsRequest o) {
  buildCounterGetReportsRequest++;
  if (buildCounterGetReportsRequest < 3) {
    checkUnnamed7100(o.reportRequests!);
    unittest.expect(o.useResourceQuotas!, unittest.isTrue);
  }
  buildCounterGetReportsRequest--;
}

core.List<api.Report> buildUnnamed7101() {
  var o = <api.Report>[];
  o.add(buildReport());
  o.add(buildReport());
  return o;
}

void checkUnnamed7101(core.List<api.Report> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReport(o[0] as api.Report);
  checkReport(o[1] as api.Report);
}

core.int buildCounterGetReportsResponse = 0;
api.GetReportsResponse buildGetReportsResponse() {
  var o = api.GetReportsResponse();
  buildCounterGetReportsResponse++;
  if (buildCounterGetReportsResponse < 3) {
    o.queryCost = 42;
    o.reports = buildUnnamed7101();
    o.resourceQuotasRemaining = buildResourceQuotasRemaining();
  }
  buildCounterGetReportsResponse--;
  return o;
}

void checkGetReportsResponse(api.GetReportsResponse o) {
  buildCounterGetReportsResponse++;
  if (buildCounterGetReportsResponse < 3) {
    unittest.expect(
      o.queryCost!,
      unittest.equals(42),
    );
    checkUnnamed7101(o.reports!);
    checkResourceQuotasRemaining(
        o.resourceQuotasRemaining! as api.ResourceQuotasRemaining);
  }
  buildCounterGetReportsResponse--;
}

core.int buildCounterGoalData = 0;
api.GoalData buildGoalData() {
  var o = api.GoalData();
  buildCounterGoalData++;
  if (buildCounterGoalData < 3) {
    o.goalCompletionLocation = 'foo';
    o.goalCompletions = 'foo';
    o.goalIndex = 42;
    o.goalName = 'foo';
    o.goalPreviousStep1 = 'foo';
    o.goalPreviousStep2 = 'foo';
    o.goalPreviousStep3 = 'foo';
    o.goalValue = 42.0;
  }
  buildCounterGoalData--;
  return o;
}

void checkGoalData(api.GoalData o) {
  buildCounterGoalData++;
  if (buildCounterGoalData < 3) {
    unittest.expect(
      o.goalCompletionLocation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.goalCompletions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.goalIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.goalName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.goalPreviousStep1!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.goalPreviousStep2!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.goalPreviousStep3!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.goalValue!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoalData--;
}

core.List<api.GoalData> buildUnnamed7102() {
  var o = <api.GoalData>[];
  o.add(buildGoalData());
  o.add(buildGoalData());
  return o;
}

void checkUnnamed7102(core.List<api.GoalData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoalData(o[0] as api.GoalData);
  checkGoalData(o[1] as api.GoalData);
}

core.int buildCounterGoalSetData = 0;
api.GoalSetData buildGoalSetData() {
  var o = api.GoalSetData();
  buildCounterGoalSetData++;
  if (buildCounterGoalSetData < 3) {
    o.goals = buildUnnamed7102();
  }
  buildCounterGoalSetData--;
  return o;
}

void checkGoalSetData(api.GoalSetData o) {
  buildCounterGoalSetData++;
  if (buildCounterGoalSetData < 3) {
    checkUnnamed7102(o.goals!);
  }
  buildCounterGoalSetData--;
}

core.int buildCounterMetric = 0;
api.Metric buildMetric() {
  var o = api.Metric();
  buildCounterMetric++;
  if (buildCounterMetric < 3) {
    o.alias = 'foo';
    o.expression = 'foo';
    o.formattingType = 'foo';
  }
  buildCounterMetric--;
  return o;
}

void checkMetric(api.Metric o) {
  buildCounterMetric++;
  if (buildCounterMetric < 3) {
    unittest.expect(
      o.alias!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetric--;
}

core.int buildCounterMetricFilter = 0;
api.MetricFilter buildMetricFilter() {
  var o = api.MetricFilter();
  buildCounterMetricFilter++;
  if (buildCounterMetricFilter < 3) {
    o.comparisonValue = 'foo';
    o.metricName = 'foo';
    o.not = true;
    o.operator = 'foo';
  }
  buildCounterMetricFilter--;
  return o;
}

void checkMetricFilter(api.MetricFilter o) {
  buildCounterMetricFilter++;
  if (buildCounterMetricFilter < 3) {
    unittest.expect(
      o.comparisonValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metricName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.not!, unittest.isTrue);
    unittest.expect(
      o.operator!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetricFilter--;
}

core.List<api.MetricFilter> buildUnnamed7103() {
  var o = <api.MetricFilter>[];
  o.add(buildMetricFilter());
  o.add(buildMetricFilter());
  return o;
}

void checkUnnamed7103(core.List<api.MetricFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricFilter(o[0] as api.MetricFilter);
  checkMetricFilter(o[1] as api.MetricFilter);
}

core.int buildCounterMetricFilterClause = 0;
api.MetricFilterClause buildMetricFilterClause() {
  var o = api.MetricFilterClause();
  buildCounterMetricFilterClause++;
  if (buildCounterMetricFilterClause < 3) {
    o.filters = buildUnnamed7103();
    o.operator = 'foo';
  }
  buildCounterMetricFilterClause--;
  return o;
}

void checkMetricFilterClause(api.MetricFilterClause o) {
  buildCounterMetricFilterClause++;
  if (buildCounterMetricFilterClause < 3) {
    checkUnnamed7103(o.filters!);
    unittest.expect(
      o.operator!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetricFilterClause--;
}

core.List<api.MetricHeaderEntry> buildUnnamed7104() {
  var o = <api.MetricHeaderEntry>[];
  o.add(buildMetricHeaderEntry());
  o.add(buildMetricHeaderEntry());
  return o;
}

void checkUnnamed7104(core.List<api.MetricHeaderEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricHeaderEntry(o[0] as api.MetricHeaderEntry);
  checkMetricHeaderEntry(o[1] as api.MetricHeaderEntry);
}

core.List<api.PivotHeader> buildUnnamed7105() {
  var o = <api.PivotHeader>[];
  o.add(buildPivotHeader());
  o.add(buildPivotHeader());
  return o;
}

void checkUnnamed7105(core.List<api.PivotHeader> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotHeader(o[0] as api.PivotHeader);
  checkPivotHeader(o[1] as api.PivotHeader);
}

core.int buildCounterMetricHeader = 0;
api.MetricHeader buildMetricHeader() {
  var o = api.MetricHeader();
  buildCounterMetricHeader++;
  if (buildCounterMetricHeader < 3) {
    o.metricHeaderEntries = buildUnnamed7104();
    o.pivotHeaders = buildUnnamed7105();
  }
  buildCounterMetricHeader--;
  return o;
}

void checkMetricHeader(api.MetricHeader o) {
  buildCounterMetricHeader++;
  if (buildCounterMetricHeader < 3) {
    checkUnnamed7104(o.metricHeaderEntries!);
    checkUnnamed7105(o.pivotHeaders!);
  }
  buildCounterMetricHeader--;
}

core.int buildCounterMetricHeaderEntry = 0;
api.MetricHeaderEntry buildMetricHeaderEntry() {
  var o = api.MetricHeaderEntry();
  buildCounterMetricHeaderEntry++;
  if (buildCounterMetricHeaderEntry < 3) {
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterMetricHeaderEntry--;
  return o;
}

void checkMetricHeaderEntry(api.MetricHeaderEntry o) {
  buildCounterMetricHeaderEntry++;
  if (buildCounterMetricHeaderEntry < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetricHeaderEntry--;
}

core.List<api.SegmentFilterClause> buildUnnamed7106() {
  var o = <api.SegmentFilterClause>[];
  o.add(buildSegmentFilterClause());
  o.add(buildSegmentFilterClause());
  return o;
}

void checkUnnamed7106(core.List<api.SegmentFilterClause> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSegmentFilterClause(o[0] as api.SegmentFilterClause);
  checkSegmentFilterClause(o[1] as api.SegmentFilterClause);
}

core.int buildCounterOrFiltersForSegment = 0;
api.OrFiltersForSegment buildOrFiltersForSegment() {
  var o = api.OrFiltersForSegment();
  buildCounterOrFiltersForSegment++;
  if (buildCounterOrFiltersForSegment < 3) {
    o.segmentFilterClauses = buildUnnamed7106();
  }
  buildCounterOrFiltersForSegment--;
  return o;
}

void checkOrFiltersForSegment(api.OrFiltersForSegment o) {
  buildCounterOrFiltersForSegment++;
  if (buildCounterOrFiltersForSegment < 3) {
    checkUnnamed7106(o.segmentFilterClauses!);
  }
  buildCounterOrFiltersForSegment--;
}

core.int buildCounterOrderBy = 0;
api.OrderBy buildOrderBy() {
  var o = api.OrderBy();
  buildCounterOrderBy++;
  if (buildCounterOrderBy < 3) {
    o.fieldName = 'foo';
    o.orderType = 'foo';
    o.sortOrder = 'foo';
  }
  buildCounterOrderBy--;
  return o;
}

void checkOrderBy(api.OrderBy o) {
  buildCounterOrderBy++;
  if (buildCounterOrderBy < 3) {
    unittest.expect(
      o.fieldName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sortOrder!,
      unittest.equals('foo'),
    );
  }
  buildCounterOrderBy--;
}

core.int buildCounterPageviewData = 0;
api.PageviewData buildPageviewData() {
  var o = api.PageviewData();
  buildCounterPageviewData++;
  if (buildCounterPageviewData < 3) {
    o.pagePath = 'foo';
    o.pageTitle = 'foo';
  }
  buildCounterPageviewData--;
  return o;
}

void checkPageviewData(api.PageviewData o) {
  buildCounterPageviewData++;
  if (buildCounterPageviewData < 3) {
    unittest.expect(
      o.pagePath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageTitle!,
      unittest.equals('foo'),
    );
  }
  buildCounterPageviewData--;
}

core.List<api.DimensionFilterClause> buildUnnamed7107() {
  var o = <api.DimensionFilterClause>[];
  o.add(buildDimensionFilterClause());
  o.add(buildDimensionFilterClause());
  return o;
}

void checkUnnamed7107(core.List<api.DimensionFilterClause> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionFilterClause(o[0] as api.DimensionFilterClause);
  checkDimensionFilterClause(o[1] as api.DimensionFilterClause);
}

core.List<api.Dimension> buildUnnamed7108() {
  var o = <api.Dimension>[];
  o.add(buildDimension());
  o.add(buildDimension());
  return o;
}

void checkUnnamed7108(core.List<api.Dimension> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimension(o[0] as api.Dimension);
  checkDimension(o[1] as api.Dimension);
}

core.List<api.Metric> buildUnnamed7109() {
  var o = <api.Metric>[];
  o.add(buildMetric());
  o.add(buildMetric());
  return o;
}

void checkUnnamed7109(core.List<api.Metric> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetric(o[0] as api.Metric);
  checkMetric(o[1] as api.Metric);
}

core.int buildCounterPivot = 0;
api.Pivot buildPivot() {
  var o = api.Pivot();
  buildCounterPivot++;
  if (buildCounterPivot < 3) {
    o.dimensionFilterClauses = buildUnnamed7107();
    o.dimensions = buildUnnamed7108();
    o.maxGroupCount = 42;
    o.metrics = buildUnnamed7109();
    o.startGroup = 42;
  }
  buildCounterPivot--;
  return o;
}

void checkPivot(api.Pivot o) {
  buildCounterPivot++;
  if (buildCounterPivot < 3) {
    checkUnnamed7107(o.dimensionFilterClauses!);
    checkUnnamed7108(o.dimensions!);
    unittest.expect(
      o.maxGroupCount!,
      unittest.equals(42),
    );
    checkUnnamed7109(o.metrics!);
    unittest.expect(
      o.startGroup!,
      unittest.equals(42),
    );
  }
  buildCounterPivot--;
}

core.List<api.PivotHeaderEntry> buildUnnamed7110() {
  var o = <api.PivotHeaderEntry>[];
  o.add(buildPivotHeaderEntry());
  o.add(buildPivotHeaderEntry());
  return o;
}

void checkUnnamed7110(core.List<api.PivotHeaderEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivotHeaderEntry(o[0] as api.PivotHeaderEntry);
  checkPivotHeaderEntry(o[1] as api.PivotHeaderEntry);
}

core.int buildCounterPivotHeader = 0;
api.PivotHeader buildPivotHeader() {
  var o = api.PivotHeader();
  buildCounterPivotHeader++;
  if (buildCounterPivotHeader < 3) {
    o.pivotHeaderEntries = buildUnnamed7110();
    o.totalPivotGroupsCount = 42;
  }
  buildCounterPivotHeader--;
  return o;
}

void checkPivotHeader(api.PivotHeader o) {
  buildCounterPivotHeader++;
  if (buildCounterPivotHeader < 3) {
    checkUnnamed7110(o.pivotHeaderEntries!);
    unittest.expect(
      o.totalPivotGroupsCount!,
      unittest.equals(42),
    );
  }
  buildCounterPivotHeader--;
}

core.List<core.String> buildUnnamed7111() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7111(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed7112() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7112(core.List<core.String> o) {
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

core.int buildCounterPivotHeaderEntry = 0;
api.PivotHeaderEntry buildPivotHeaderEntry() {
  var o = api.PivotHeaderEntry();
  buildCounterPivotHeaderEntry++;
  if (buildCounterPivotHeaderEntry < 3) {
    o.dimensionNames = buildUnnamed7111();
    o.dimensionValues = buildUnnamed7112();
    o.metric = buildMetricHeaderEntry();
  }
  buildCounterPivotHeaderEntry--;
  return o;
}

void checkPivotHeaderEntry(api.PivotHeaderEntry o) {
  buildCounterPivotHeaderEntry++;
  if (buildCounterPivotHeaderEntry < 3) {
    checkUnnamed7111(o.dimensionNames!);
    checkUnnamed7112(o.dimensionValues!);
    checkMetricHeaderEntry(o.metric! as api.MetricHeaderEntry);
  }
  buildCounterPivotHeaderEntry--;
}

core.List<core.String> buildUnnamed7113() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7113(core.List<core.String> o) {
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

core.int buildCounterPivotValueRegion = 0;
api.PivotValueRegion buildPivotValueRegion() {
  var o = api.PivotValueRegion();
  buildCounterPivotValueRegion++;
  if (buildCounterPivotValueRegion < 3) {
    o.values = buildUnnamed7113();
  }
  buildCounterPivotValueRegion--;
  return o;
}

void checkPivotValueRegion(api.PivotValueRegion o) {
  buildCounterPivotValueRegion++;
  if (buildCounterPivotValueRegion < 3) {
    checkUnnamed7113(o.values!);
  }
  buildCounterPivotValueRegion--;
}

core.int buildCounterProductData = 0;
api.ProductData buildProductData() {
  var o = api.ProductData();
  buildCounterProductData++;
  if (buildCounterProductData < 3) {
    o.itemRevenue = 42.0;
    o.productName = 'foo';
    o.productQuantity = 'foo';
    o.productSku = 'foo';
  }
  buildCounterProductData--;
  return o;
}

void checkProductData(api.ProductData o) {
  buildCounterProductData++;
  if (buildCounterProductData < 3) {
    unittest.expect(
      o.itemRevenue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.productName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productQuantity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productSku!,
      unittest.equals('foo'),
    );
  }
  buildCounterProductData--;
}

core.int buildCounterReport = 0;
api.Report buildReport() {
  var o = api.Report();
  buildCounterReport++;
  if (buildCounterReport < 3) {
    o.columnHeader = buildColumnHeader();
    o.data = buildReportData();
    o.nextPageToken = 'foo';
  }
  buildCounterReport--;
  return o;
}

void checkReport(api.Report o) {
  buildCounterReport++;
  if (buildCounterReport < 3) {
    checkColumnHeader(o.columnHeader! as api.ColumnHeader);
    checkReportData(o.data! as api.ReportData);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterReport--;
}

core.List<api.DateRangeValues> buildUnnamed7114() {
  var o = <api.DateRangeValues>[];
  o.add(buildDateRangeValues());
  o.add(buildDateRangeValues());
  return o;
}

void checkUnnamed7114(core.List<api.DateRangeValues> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDateRangeValues(o[0] as api.DateRangeValues);
  checkDateRangeValues(o[1] as api.DateRangeValues);
}

core.List<api.DateRangeValues> buildUnnamed7115() {
  var o = <api.DateRangeValues>[];
  o.add(buildDateRangeValues());
  o.add(buildDateRangeValues());
  return o;
}

void checkUnnamed7115(core.List<api.DateRangeValues> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDateRangeValues(o[0] as api.DateRangeValues);
  checkDateRangeValues(o[1] as api.DateRangeValues);
}

core.List<api.ReportRow> buildUnnamed7116() {
  var o = <api.ReportRow>[];
  o.add(buildReportRow());
  o.add(buildReportRow());
  return o;
}

void checkUnnamed7116(core.List<api.ReportRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportRow(o[0] as api.ReportRow);
  checkReportRow(o[1] as api.ReportRow);
}

core.List<core.String> buildUnnamed7117() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7117(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed7118() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7118(core.List<core.String> o) {
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

core.List<api.DateRangeValues> buildUnnamed7119() {
  var o = <api.DateRangeValues>[];
  o.add(buildDateRangeValues());
  o.add(buildDateRangeValues());
  return o;
}

void checkUnnamed7119(core.List<api.DateRangeValues> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDateRangeValues(o[0] as api.DateRangeValues);
  checkDateRangeValues(o[1] as api.DateRangeValues);
}

core.int buildCounterReportData = 0;
api.ReportData buildReportData() {
  var o = api.ReportData();
  buildCounterReportData++;
  if (buildCounterReportData < 3) {
    o.dataLastRefreshed = 'foo';
    o.isDataGolden = true;
    o.maximums = buildUnnamed7114();
    o.minimums = buildUnnamed7115();
    o.rowCount = 42;
    o.rows = buildUnnamed7116();
    o.samplesReadCounts = buildUnnamed7117();
    o.samplingSpaceSizes = buildUnnamed7118();
    o.totals = buildUnnamed7119();
  }
  buildCounterReportData--;
  return o;
}

void checkReportData(api.ReportData o) {
  buildCounterReportData++;
  if (buildCounterReportData < 3) {
    unittest.expect(
      o.dataLastRefreshed!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDataGolden!, unittest.isTrue);
    checkUnnamed7114(o.maximums!);
    checkUnnamed7115(o.minimums!);
    unittest.expect(
      o.rowCount!,
      unittest.equals(42),
    );
    checkUnnamed7116(o.rows!);
    checkUnnamed7117(o.samplesReadCounts!);
    checkUnnamed7118(o.samplingSpaceSizes!);
    checkUnnamed7119(o.totals!);
  }
  buildCounterReportData--;
}

core.List<api.DateRange> buildUnnamed7120() {
  var o = <api.DateRange>[];
  o.add(buildDateRange());
  o.add(buildDateRange());
  return o;
}

void checkUnnamed7120(core.List<api.DateRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDateRange(o[0] as api.DateRange);
  checkDateRange(o[1] as api.DateRange);
}

core.List<api.DimensionFilterClause> buildUnnamed7121() {
  var o = <api.DimensionFilterClause>[];
  o.add(buildDimensionFilterClause());
  o.add(buildDimensionFilterClause());
  return o;
}

void checkUnnamed7121(core.List<api.DimensionFilterClause> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionFilterClause(o[0] as api.DimensionFilterClause);
  checkDimensionFilterClause(o[1] as api.DimensionFilterClause);
}

core.List<api.Dimension> buildUnnamed7122() {
  var o = <api.Dimension>[];
  o.add(buildDimension());
  o.add(buildDimension());
  return o;
}

void checkUnnamed7122(core.List<api.Dimension> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimension(o[0] as api.Dimension);
  checkDimension(o[1] as api.Dimension);
}

core.List<api.MetricFilterClause> buildUnnamed7123() {
  var o = <api.MetricFilterClause>[];
  o.add(buildMetricFilterClause());
  o.add(buildMetricFilterClause());
  return o;
}

void checkUnnamed7123(core.List<api.MetricFilterClause> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricFilterClause(o[0] as api.MetricFilterClause);
  checkMetricFilterClause(o[1] as api.MetricFilterClause);
}

core.List<api.Metric> buildUnnamed7124() {
  var o = <api.Metric>[];
  o.add(buildMetric());
  o.add(buildMetric());
  return o;
}

void checkUnnamed7124(core.List<api.Metric> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetric(o[0] as api.Metric);
  checkMetric(o[1] as api.Metric);
}

core.List<api.OrderBy> buildUnnamed7125() {
  var o = <api.OrderBy>[];
  o.add(buildOrderBy());
  o.add(buildOrderBy());
  return o;
}

void checkUnnamed7125(core.List<api.OrderBy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrderBy(o[0] as api.OrderBy);
  checkOrderBy(o[1] as api.OrderBy);
}

core.List<api.Pivot> buildUnnamed7126() {
  var o = <api.Pivot>[];
  o.add(buildPivot());
  o.add(buildPivot());
  return o;
}

void checkUnnamed7126(core.List<api.Pivot> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPivot(o[0] as api.Pivot);
  checkPivot(o[1] as api.Pivot);
}

core.List<api.Segment> buildUnnamed7127() {
  var o = <api.Segment>[];
  o.add(buildSegment());
  o.add(buildSegment());
  return o;
}

void checkUnnamed7127(core.List<api.Segment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSegment(o[0] as api.Segment);
  checkSegment(o[1] as api.Segment);
}

core.int buildCounterReportRequest = 0;
api.ReportRequest buildReportRequest() {
  var o = api.ReportRequest();
  buildCounterReportRequest++;
  if (buildCounterReportRequest < 3) {
    o.cohortGroup = buildCohortGroup();
    o.dateRanges = buildUnnamed7120();
    o.dimensionFilterClauses = buildUnnamed7121();
    o.dimensions = buildUnnamed7122();
    o.filtersExpression = 'foo';
    o.hideTotals = true;
    o.hideValueRanges = true;
    o.includeEmptyRows = true;
    o.metricFilterClauses = buildUnnamed7123();
    o.metrics = buildUnnamed7124();
    o.orderBys = buildUnnamed7125();
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.pivots = buildUnnamed7126();
    o.samplingLevel = 'foo';
    o.segments = buildUnnamed7127();
    o.viewId = 'foo';
  }
  buildCounterReportRequest--;
  return o;
}

void checkReportRequest(api.ReportRequest o) {
  buildCounterReportRequest++;
  if (buildCounterReportRequest < 3) {
    checkCohortGroup(o.cohortGroup! as api.CohortGroup);
    checkUnnamed7120(o.dateRanges!);
    checkUnnamed7121(o.dimensionFilterClauses!);
    checkUnnamed7122(o.dimensions!);
    unittest.expect(
      o.filtersExpression!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hideTotals!, unittest.isTrue);
    unittest.expect(o.hideValueRanges!, unittest.isTrue);
    unittest.expect(o.includeEmptyRows!, unittest.isTrue);
    checkUnnamed7123(o.metricFilterClauses!);
    checkUnnamed7124(o.metrics!);
    checkUnnamed7125(o.orderBys!);
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed7126(o.pivots!);
    unittest.expect(
      o.samplingLevel!,
      unittest.equals('foo'),
    );
    checkUnnamed7127(o.segments!);
    unittest.expect(
      o.viewId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportRequest--;
}

core.List<core.String> buildUnnamed7128() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7128(core.List<core.String> o) {
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

core.List<api.DateRangeValues> buildUnnamed7129() {
  var o = <api.DateRangeValues>[];
  o.add(buildDateRangeValues());
  o.add(buildDateRangeValues());
  return o;
}

void checkUnnamed7129(core.List<api.DateRangeValues> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDateRangeValues(o[0] as api.DateRangeValues);
  checkDateRangeValues(o[1] as api.DateRangeValues);
}

core.int buildCounterReportRow = 0;
api.ReportRow buildReportRow() {
  var o = api.ReportRow();
  buildCounterReportRow++;
  if (buildCounterReportRow < 3) {
    o.dimensions = buildUnnamed7128();
    o.metrics = buildUnnamed7129();
  }
  buildCounterReportRow--;
  return o;
}

void checkReportRow(api.ReportRow o) {
  buildCounterReportRow++;
  if (buildCounterReportRow < 3) {
    checkUnnamed7128(o.dimensions!);
    checkUnnamed7129(o.metrics!);
  }
  buildCounterReportRow--;
}

core.int buildCounterResourceQuotasRemaining = 0;
api.ResourceQuotasRemaining buildResourceQuotasRemaining() {
  var o = api.ResourceQuotasRemaining();
  buildCounterResourceQuotasRemaining++;
  if (buildCounterResourceQuotasRemaining < 3) {
    o.dailyQuotaTokensRemaining = 42;
    o.hourlyQuotaTokensRemaining = 42;
  }
  buildCounterResourceQuotasRemaining--;
  return o;
}

void checkResourceQuotasRemaining(api.ResourceQuotasRemaining o) {
  buildCounterResourceQuotasRemaining++;
  if (buildCounterResourceQuotasRemaining < 3) {
    unittest.expect(
      o.dailyQuotaTokensRemaining!,
      unittest.equals(42),
    );
    unittest.expect(
      o.hourlyQuotaTokensRemaining!,
      unittest.equals(42),
    );
  }
  buildCounterResourceQuotasRemaining--;
}

core.int buildCounterScreenviewData = 0;
api.ScreenviewData buildScreenviewData() {
  var o = api.ScreenviewData();
  buildCounterScreenviewData++;
  if (buildCounterScreenviewData < 3) {
    o.appName = 'foo';
    o.mobileDeviceBranding = 'foo';
    o.mobileDeviceModel = 'foo';
    o.screenName = 'foo';
  }
  buildCounterScreenviewData--;
  return o;
}

void checkScreenviewData(api.ScreenviewData o) {
  buildCounterScreenviewData++;
  if (buildCounterScreenviewData < 3) {
    unittest.expect(
      o.appName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mobileDeviceBranding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mobileDeviceModel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenName!,
      unittest.equals('foo'),
    );
  }
  buildCounterScreenviewData--;
}

core.List<core.String> buildUnnamed7130() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7130(core.List<core.String> o) {
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

core.int buildCounterSearchUserActivityRequest = 0;
api.SearchUserActivityRequest buildSearchUserActivityRequest() {
  var o = api.SearchUserActivityRequest();
  buildCounterSearchUserActivityRequest++;
  if (buildCounterSearchUserActivityRequest < 3) {
    o.activityTypes = buildUnnamed7130();
    o.dateRange = buildDateRange();
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.user = buildUser();
    o.viewId = 'foo';
  }
  buildCounterSearchUserActivityRequest--;
  return o;
}

void checkSearchUserActivityRequest(api.SearchUserActivityRequest o) {
  buildCounterSearchUserActivityRequest++;
  if (buildCounterSearchUserActivityRequest < 3) {
    checkUnnamed7130(o.activityTypes!);
    checkDateRange(o.dateRange! as api.DateRange);
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    checkUser(o.user! as api.User);
    unittest.expect(
      o.viewId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchUserActivityRequest--;
}

core.List<api.UserActivitySession> buildUnnamed7131() {
  var o = <api.UserActivitySession>[];
  o.add(buildUserActivitySession());
  o.add(buildUserActivitySession());
  return o;
}

void checkUnnamed7131(core.List<api.UserActivitySession> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserActivitySession(o[0] as api.UserActivitySession);
  checkUserActivitySession(o[1] as api.UserActivitySession);
}

core.int buildCounterSearchUserActivityResponse = 0;
api.SearchUserActivityResponse buildSearchUserActivityResponse() {
  var o = api.SearchUserActivityResponse();
  buildCounterSearchUserActivityResponse++;
  if (buildCounterSearchUserActivityResponse < 3) {
    o.nextPageToken = 'foo';
    o.sampleRate = 42.0;
    o.sessions = buildUnnamed7131();
    o.totalRows = 42;
  }
  buildCounterSearchUserActivityResponse--;
  return o;
}

void checkSearchUserActivityResponse(api.SearchUserActivityResponse o) {
  buildCounterSearchUserActivityResponse++;
  if (buildCounterSearchUserActivityResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sampleRate!,
      unittest.equals(42.0),
    );
    checkUnnamed7131(o.sessions!);
    unittest.expect(
      o.totalRows!,
      unittest.equals(42),
    );
  }
  buildCounterSearchUserActivityResponse--;
}

core.int buildCounterSegment = 0;
api.Segment buildSegment() {
  var o = api.Segment();
  buildCounterSegment++;
  if (buildCounterSegment < 3) {
    o.dynamicSegment = buildDynamicSegment();
    o.segmentId = 'foo';
  }
  buildCounterSegment--;
  return o;
}

void checkSegment(api.Segment o) {
  buildCounterSegment++;
  if (buildCounterSegment < 3) {
    checkDynamicSegment(o.dynamicSegment! as api.DynamicSegment);
    unittest.expect(
      o.segmentId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSegment--;
}

core.List<api.SegmentFilter> buildUnnamed7132() {
  var o = <api.SegmentFilter>[];
  o.add(buildSegmentFilter());
  o.add(buildSegmentFilter());
  return o;
}

void checkUnnamed7132(core.List<api.SegmentFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSegmentFilter(o[0] as api.SegmentFilter);
  checkSegmentFilter(o[1] as api.SegmentFilter);
}

core.int buildCounterSegmentDefinition = 0;
api.SegmentDefinition buildSegmentDefinition() {
  var o = api.SegmentDefinition();
  buildCounterSegmentDefinition++;
  if (buildCounterSegmentDefinition < 3) {
    o.segmentFilters = buildUnnamed7132();
  }
  buildCounterSegmentDefinition--;
  return o;
}

void checkSegmentDefinition(api.SegmentDefinition o) {
  buildCounterSegmentDefinition++;
  if (buildCounterSegmentDefinition < 3) {
    checkUnnamed7132(o.segmentFilters!);
  }
  buildCounterSegmentDefinition--;
}

core.List<core.String> buildUnnamed7133() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7133(core.List<core.String> o) {
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

core.int buildCounterSegmentDimensionFilter = 0;
api.SegmentDimensionFilter buildSegmentDimensionFilter() {
  var o = api.SegmentDimensionFilter();
  buildCounterSegmentDimensionFilter++;
  if (buildCounterSegmentDimensionFilter < 3) {
    o.caseSensitive = true;
    o.dimensionName = 'foo';
    o.expressions = buildUnnamed7133();
    o.maxComparisonValue = 'foo';
    o.minComparisonValue = 'foo';
    o.operator = 'foo';
  }
  buildCounterSegmentDimensionFilter--;
  return o;
}

void checkSegmentDimensionFilter(api.SegmentDimensionFilter o) {
  buildCounterSegmentDimensionFilter++;
  if (buildCounterSegmentDimensionFilter < 3) {
    unittest.expect(o.caseSensitive!, unittest.isTrue);
    unittest.expect(
      o.dimensionName!,
      unittest.equals('foo'),
    );
    checkUnnamed7133(o.expressions!);
    unittest.expect(
      o.maxComparisonValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minComparisonValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operator!,
      unittest.equals('foo'),
    );
  }
  buildCounterSegmentDimensionFilter--;
}

core.int buildCounterSegmentFilter = 0;
api.SegmentFilter buildSegmentFilter() {
  var o = api.SegmentFilter();
  buildCounterSegmentFilter++;
  if (buildCounterSegmentFilter < 3) {
    o.not = true;
    o.sequenceSegment = buildSequenceSegment();
    o.simpleSegment = buildSimpleSegment();
  }
  buildCounterSegmentFilter--;
  return o;
}

void checkSegmentFilter(api.SegmentFilter o) {
  buildCounterSegmentFilter++;
  if (buildCounterSegmentFilter < 3) {
    unittest.expect(o.not!, unittest.isTrue);
    checkSequenceSegment(o.sequenceSegment! as api.SequenceSegment);
    checkSimpleSegment(o.simpleSegment! as api.SimpleSegment);
  }
  buildCounterSegmentFilter--;
}

core.int buildCounterSegmentFilterClause = 0;
api.SegmentFilterClause buildSegmentFilterClause() {
  var o = api.SegmentFilterClause();
  buildCounterSegmentFilterClause++;
  if (buildCounterSegmentFilterClause < 3) {
    o.dimensionFilter = buildSegmentDimensionFilter();
    o.metricFilter = buildSegmentMetricFilter();
    o.not = true;
  }
  buildCounterSegmentFilterClause--;
  return o;
}

void checkSegmentFilterClause(api.SegmentFilterClause o) {
  buildCounterSegmentFilterClause++;
  if (buildCounterSegmentFilterClause < 3) {
    checkSegmentDimensionFilter(
        o.dimensionFilter! as api.SegmentDimensionFilter);
    checkSegmentMetricFilter(o.metricFilter! as api.SegmentMetricFilter);
    unittest.expect(o.not!, unittest.isTrue);
  }
  buildCounterSegmentFilterClause--;
}

core.int buildCounterSegmentMetricFilter = 0;
api.SegmentMetricFilter buildSegmentMetricFilter() {
  var o = api.SegmentMetricFilter();
  buildCounterSegmentMetricFilter++;
  if (buildCounterSegmentMetricFilter < 3) {
    o.comparisonValue = 'foo';
    o.maxComparisonValue = 'foo';
    o.metricName = 'foo';
    o.operator = 'foo';
    o.scope = 'foo';
  }
  buildCounterSegmentMetricFilter--;
  return o;
}

void checkSegmentMetricFilter(api.SegmentMetricFilter o) {
  buildCounterSegmentMetricFilter++;
  if (buildCounterSegmentMetricFilter < 3) {
    unittest.expect(
      o.comparisonValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxComparisonValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metricName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operator!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scope!,
      unittest.equals('foo'),
    );
  }
  buildCounterSegmentMetricFilter--;
}

core.List<api.OrFiltersForSegment> buildUnnamed7134() {
  var o = <api.OrFiltersForSegment>[];
  o.add(buildOrFiltersForSegment());
  o.add(buildOrFiltersForSegment());
  return o;
}

void checkUnnamed7134(core.List<api.OrFiltersForSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrFiltersForSegment(o[0] as api.OrFiltersForSegment);
  checkOrFiltersForSegment(o[1] as api.OrFiltersForSegment);
}

core.int buildCounterSegmentSequenceStep = 0;
api.SegmentSequenceStep buildSegmentSequenceStep() {
  var o = api.SegmentSequenceStep();
  buildCounterSegmentSequenceStep++;
  if (buildCounterSegmentSequenceStep < 3) {
    o.matchType = 'foo';
    o.orFiltersForSegment = buildUnnamed7134();
  }
  buildCounterSegmentSequenceStep--;
  return o;
}

void checkSegmentSequenceStep(api.SegmentSequenceStep o) {
  buildCounterSegmentSequenceStep++;
  if (buildCounterSegmentSequenceStep < 3) {
    unittest.expect(
      o.matchType!,
      unittest.equals('foo'),
    );
    checkUnnamed7134(o.orFiltersForSegment!);
  }
  buildCounterSegmentSequenceStep--;
}

core.List<api.SegmentSequenceStep> buildUnnamed7135() {
  var o = <api.SegmentSequenceStep>[];
  o.add(buildSegmentSequenceStep());
  o.add(buildSegmentSequenceStep());
  return o;
}

void checkUnnamed7135(core.List<api.SegmentSequenceStep> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSegmentSequenceStep(o[0] as api.SegmentSequenceStep);
  checkSegmentSequenceStep(o[1] as api.SegmentSequenceStep);
}

core.int buildCounterSequenceSegment = 0;
api.SequenceSegment buildSequenceSegment() {
  var o = api.SequenceSegment();
  buildCounterSequenceSegment++;
  if (buildCounterSequenceSegment < 3) {
    o.firstStepShouldMatchFirstHit = true;
    o.segmentSequenceSteps = buildUnnamed7135();
  }
  buildCounterSequenceSegment--;
  return o;
}

void checkSequenceSegment(api.SequenceSegment o) {
  buildCounterSequenceSegment++;
  if (buildCounterSequenceSegment < 3) {
    unittest.expect(o.firstStepShouldMatchFirstHit!, unittest.isTrue);
    checkUnnamed7135(o.segmentSequenceSteps!);
  }
  buildCounterSequenceSegment--;
}

core.List<api.OrFiltersForSegment> buildUnnamed7136() {
  var o = <api.OrFiltersForSegment>[];
  o.add(buildOrFiltersForSegment());
  o.add(buildOrFiltersForSegment());
  return o;
}

void checkUnnamed7136(core.List<api.OrFiltersForSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrFiltersForSegment(o[0] as api.OrFiltersForSegment);
  checkOrFiltersForSegment(o[1] as api.OrFiltersForSegment);
}

core.int buildCounterSimpleSegment = 0;
api.SimpleSegment buildSimpleSegment() {
  var o = api.SimpleSegment();
  buildCounterSimpleSegment++;
  if (buildCounterSimpleSegment < 3) {
    o.orFiltersForSegment = buildUnnamed7136();
  }
  buildCounterSimpleSegment--;
  return o;
}

void checkSimpleSegment(api.SimpleSegment o) {
  buildCounterSimpleSegment++;
  if (buildCounterSimpleSegment < 3) {
    checkUnnamed7136(o.orFiltersForSegment!);
  }
  buildCounterSimpleSegment--;
}

core.int buildCounterTransactionData = 0;
api.TransactionData buildTransactionData() {
  var o = api.TransactionData();
  buildCounterTransactionData++;
  if (buildCounterTransactionData < 3) {
    o.transactionId = 'foo';
    o.transactionRevenue = 42.0;
    o.transactionShipping = 42.0;
    o.transactionTax = 42.0;
  }
  buildCounterTransactionData--;
  return o;
}

void checkTransactionData(api.TransactionData o) {
  buildCounterTransactionData++;
  if (buildCounterTransactionData < 3) {
    unittest.expect(
      o.transactionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.transactionRevenue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transactionShipping!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transactionTax!,
      unittest.equals(42.0),
    );
  }
  buildCounterTransactionData--;
}

core.int buildCounterUser = 0;
api.User buildUser() {
  var o = api.User();
  buildCounterUser++;
  if (buildCounterUser < 3) {
    o.type = 'foo';
    o.userId = 'foo';
  }
  buildCounterUser--;
  return o;
}

void checkUser(api.User o) {
  buildCounterUser++;
  if (buildCounterUser < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUser--;
}

core.List<api.Activity> buildUnnamed7137() {
  var o = <api.Activity>[];
  o.add(buildActivity());
  o.add(buildActivity());
  return o;
}

void checkUnnamed7137(core.List<api.Activity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActivity(o[0] as api.Activity);
  checkActivity(o[1] as api.Activity);
}

core.int buildCounterUserActivitySession = 0;
api.UserActivitySession buildUserActivitySession() {
  var o = api.UserActivitySession();
  buildCounterUserActivitySession++;
  if (buildCounterUserActivitySession < 3) {
    o.activities = buildUnnamed7137();
    o.dataSource = 'foo';
    o.deviceCategory = 'foo';
    o.platform = 'foo';
    o.sessionDate = 'foo';
    o.sessionId = 'foo';
  }
  buildCounterUserActivitySession--;
  return o;
}

void checkUserActivitySession(api.UserActivitySession o) {
  buildCounterUserActivitySession++;
  if (buildCounterUserActivitySession < 3) {
    checkUnnamed7137(o.activities!);
    unittest.expect(
      o.dataSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deviceCategory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platform!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sessionDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sessionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserActivitySession--;
}

void main() {
  unittest.group('obj-schema-Activity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Activity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkActivity(od as api.Activity);
    });
  });

  unittest.group('obj-schema-Cohort', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCohort();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Cohort.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCohort(od as api.Cohort);
    });
  });

  unittest.group('obj-schema-CohortGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCohortGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CohortGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCohortGroup(od as api.CohortGroup);
    });
  });

  unittest.group('obj-schema-ColumnHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildColumnHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ColumnHeader.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkColumnHeader(od as api.ColumnHeader);
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

  unittest.group('obj-schema-DateRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDateRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DateRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDateRange(od as api.DateRange);
    });
  });

  unittest.group('obj-schema-DateRangeValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDateRangeValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DateRangeValues.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDateRangeValues(od as api.DateRangeValues);
    });
  });

  unittest.group('obj-schema-Dimension', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimension();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Dimension.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDimension(od as api.Dimension);
    });
  });

  unittest.group('obj-schema-DimensionFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimensionFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DimensionFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDimensionFilter(od as api.DimensionFilter);
    });
  });

  unittest.group('obj-schema-DimensionFilterClause', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimensionFilterClause();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DimensionFilterClause.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDimensionFilterClause(od as api.DimensionFilterClause);
    });
  });

  unittest.group('obj-schema-DynamicSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicSegment(od as api.DynamicSegment);
    });
  });

  unittest.group('obj-schema-EcommerceData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEcommerceData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EcommerceData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEcommerceData(od as api.EcommerceData);
    });
  });

  unittest.group('obj-schema-EventData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.EventData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEventData(od as api.EventData);
    });
  });

  unittest.group('obj-schema-GetReportsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetReportsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetReportsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetReportsRequest(od as api.GetReportsRequest);
    });
  });

  unittest.group('obj-schema-GetReportsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetReportsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetReportsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetReportsResponse(od as api.GetReportsResponse);
    });
  });

  unittest.group('obj-schema-GoalData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoalData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoalData(od as api.GoalData);
    });
  });

  unittest.group('obj-schema-GoalSetData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalSetData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalSetData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalSetData(od as api.GoalSetData);
    });
  });

  unittest.group('obj-schema-Metric', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetric();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Metric.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMetric(od as api.Metric);
    });
  });

  unittest.group('obj-schema-MetricFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetricFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetricFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetricFilter(od as api.MetricFilter);
    });
  });

  unittest.group('obj-schema-MetricFilterClause', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetricFilterClause();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetricFilterClause.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetricFilterClause(od as api.MetricFilterClause);
    });
  });

  unittest.group('obj-schema-MetricHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetricHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetricHeader.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetricHeader(od as api.MetricHeader);
    });
  });

  unittest.group('obj-schema-MetricHeaderEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetricHeaderEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetricHeaderEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetricHeaderEntry(od as api.MetricHeaderEntry);
    });
  });

  unittest.group('obj-schema-OrFiltersForSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrFiltersForSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OrFiltersForSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrFiltersForSegment(od as api.OrFiltersForSegment);
    });
  });

  unittest.group('obj-schema-OrderBy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrderBy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OrderBy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOrderBy(od as api.OrderBy);
    });
  });

  unittest.group('obj-schema-PageviewData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPageviewData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PageviewData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPageviewData(od as api.PageviewData);
    });
  });

  unittest.group('obj-schema-Pivot', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivot();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Pivot.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPivot(od as api.Pivot);
    });
  });

  unittest.group('obj-schema-PivotHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotHeader.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotHeader(od as api.PivotHeader);
    });
  });

  unittest.group('obj-schema-PivotHeaderEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotHeaderEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotHeaderEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotHeaderEntry(od as api.PivotHeaderEntry);
    });
  });

  unittest.group('obj-schema-PivotValueRegion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPivotValueRegion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PivotValueRegion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPivotValueRegion(od as api.PivotValueRegion);
    });
  });

  unittest.group('obj-schema-ProductData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProductData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProductData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProductData(od as api.ProductData);
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

  unittest.group('obj-schema-ReportData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ReportData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReportData(od as api.ReportData);
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

  unittest.group('obj-schema-ResourceQuotasRemaining', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceQuotasRemaining();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceQuotasRemaining.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceQuotasRemaining(od as api.ResourceQuotasRemaining);
    });
  });

  unittest.group('obj-schema-ScreenviewData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScreenviewData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScreenviewData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScreenviewData(od as api.ScreenviewData);
    });
  });

  unittest.group('obj-schema-SearchUserActivityRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchUserActivityRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchUserActivityRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchUserActivityRequest(od as api.SearchUserActivityRequest);
    });
  });

  unittest.group('obj-schema-SearchUserActivityResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchUserActivityResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchUserActivityResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchUserActivityResponse(od as api.SearchUserActivityResponse);
    });
  });

  unittest.group('obj-schema-Segment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Segment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSegment(od as api.Segment);
    });
  });

  unittest.group('obj-schema-SegmentDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegmentDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SegmentDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSegmentDefinition(od as api.SegmentDefinition);
    });
  });

  unittest.group('obj-schema-SegmentDimensionFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegmentDimensionFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SegmentDimensionFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSegmentDimensionFilter(od as api.SegmentDimensionFilter);
    });
  });

  unittest.group('obj-schema-SegmentFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegmentFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SegmentFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSegmentFilter(od as api.SegmentFilter);
    });
  });

  unittest.group('obj-schema-SegmentFilterClause', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegmentFilterClause();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SegmentFilterClause.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSegmentFilterClause(od as api.SegmentFilterClause);
    });
  });

  unittest.group('obj-schema-SegmentMetricFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegmentMetricFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SegmentMetricFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSegmentMetricFilter(od as api.SegmentMetricFilter);
    });
  });

  unittest.group('obj-schema-SegmentSequenceStep', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegmentSequenceStep();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SegmentSequenceStep.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSegmentSequenceStep(od as api.SegmentSequenceStep);
    });
  });

  unittest.group('obj-schema-SequenceSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSequenceSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SequenceSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSequenceSegment(od as api.SequenceSegment);
    });
  });

  unittest.group('obj-schema-SimpleSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSimpleSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SimpleSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSimpleSegment(od as api.SimpleSegment);
    });
  });

  unittest.group('obj-schema-TransactionData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTransactionData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TransactionData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTransactionData(od as api.TransactionData);
    });
  });

  unittest.group('obj-schema-User', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.User.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUser(od as api.User);
    });
  });

  unittest.group('obj-schema-UserActivitySession', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserActivitySession();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserActivitySession.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserActivitySession(od as api.UserActivitySession);
    });
  });

  unittest.group('resource-ReportsResource', () {
    unittest.test('method--batchGet', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsReportingApi(mock).reports;
      var arg_request = buildGetReportsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetReportsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetReportsRequest(obj as api.GetReportsRequest);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("v4/reports:batchGet"),
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
        var resp = convert.json.encode(buildGetReportsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchGet(arg_request, $fields: arg_$fields);
      checkGetReportsResponse(response as api.GetReportsResponse);
    });
  });

  unittest.group('resource-UserActivityResource', () {
    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsReportingApi(mock).userActivity;
      var arg_request = buildSearchUserActivityRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchUserActivityRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchUserActivityRequest(obj as api.SearchUserActivityRequest);

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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("v4/userActivity:search"),
        );
        pathOffset += 22;

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
        var resp = convert.json.encode(buildSearchUserActivityResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(arg_request, $fields: arg_$fields);
      checkSearchUserActivityResponse(
          response as api.SearchUserActivityResponse);
    });
  });
}

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

import 'package:googleapis/doubleclickbidmanager/v1_1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Rule> buildUnnamed5889() {
  var o = <api.Rule>[];
  o.add(buildRule());
  o.add(buildRule());
  return o;
}

void checkUnnamed5889(core.List<api.Rule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRule(o[0] as api.Rule);
  checkRule(o[1] as api.Rule);
}

core.int buildCounterChannelGrouping = 0;
api.ChannelGrouping buildChannelGrouping() {
  var o = api.ChannelGrouping();
  buildCounterChannelGrouping++;
  if (buildCounterChannelGrouping < 3) {
    o.fallbackName = 'foo';
    o.name = 'foo';
    o.rules = buildUnnamed5889();
  }
  buildCounterChannelGrouping--;
  return o;
}

void checkChannelGrouping(api.ChannelGrouping o) {
  buildCounterChannelGrouping++;
  if (buildCounterChannelGrouping < 3) {
    unittest.expect(
      o.fallbackName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5889(o.rules!);
  }
  buildCounterChannelGrouping--;
}

core.List<api.EventFilter> buildUnnamed5890() {
  var o = <api.EventFilter>[];
  o.add(buildEventFilter());
  o.add(buildEventFilter());
  return o;
}

void checkUnnamed5890(core.List<api.EventFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventFilter(o[0] as api.EventFilter);
  checkEventFilter(o[1] as api.EventFilter);
}

core.int buildCounterDisjunctiveMatchStatement = 0;
api.DisjunctiveMatchStatement buildDisjunctiveMatchStatement() {
  var o = api.DisjunctiveMatchStatement();
  buildCounterDisjunctiveMatchStatement++;
  if (buildCounterDisjunctiveMatchStatement < 3) {
    o.eventFilters = buildUnnamed5890();
  }
  buildCounterDisjunctiveMatchStatement--;
  return o;
}

void checkDisjunctiveMatchStatement(api.DisjunctiveMatchStatement o) {
  buildCounterDisjunctiveMatchStatement++;
  if (buildCounterDisjunctiveMatchStatement < 3) {
    checkUnnamed5890(o.eventFilters!);
  }
  buildCounterDisjunctiveMatchStatement--;
}

core.int buildCounterEventFilter = 0;
api.EventFilter buildEventFilter() {
  var o = api.EventFilter();
  buildCounterEventFilter++;
  if (buildCounterEventFilter < 3) {
    o.dimensionFilter = buildPathQueryOptionsFilter();
  }
  buildCounterEventFilter--;
  return o;
}

void checkEventFilter(api.EventFilter o) {
  buildCounterEventFilter++;
  if (buildCounterEventFilter < 3) {
    checkPathQueryOptionsFilter(
        o.dimensionFilter! as api.PathQueryOptionsFilter);
  }
  buildCounterEventFilter--;
}

core.int buildCounterFilterPair = 0;
api.FilterPair buildFilterPair() {
  var o = api.FilterPair();
  buildCounterFilterPair++;
  if (buildCounterFilterPair < 3) {
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterFilterPair--;
  return o;
}

void checkFilterPair(api.FilterPair o) {
  buildCounterFilterPair++;
  if (buildCounterFilterPair < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilterPair--;
}

core.List<api.Query> buildUnnamed5891() {
  var o = <api.Query>[];
  o.add(buildQuery());
  o.add(buildQuery());
  return o;
}

void checkUnnamed5891(core.List<api.Query> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQuery(o[0] as api.Query);
  checkQuery(o[1] as api.Query);
}

core.int buildCounterListQueriesResponse = 0;
api.ListQueriesResponse buildListQueriesResponse() {
  var o = api.ListQueriesResponse();
  buildCounterListQueriesResponse++;
  if (buildCounterListQueriesResponse < 3) {
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.queries = buildUnnamed5891();
  }
  buildCounterListQueriesResponse--;
  return o;
}

void checkListQueriesResponse(api.ListQueriesResponse o) {
  buildCounterListQueriesResponse++;
  if (buildCounterListQueriesResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5891(o.queries!);
  }
  buildCounterListQueriesResponse--;
}

core.List<api.Report> buildUnnamed5892() {
  var o = <api.Report>[];
  o.add(buildReport());
  o.add(buildReport());
  return o;
}

void checkUnnamed5892(core.List<api.Report> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReport(o[0] as api.Report);
  checkReport(o[1] as api.Report);
}

core.int buildCounterListReportsResponse = 0;
api.ListReportsResponse buildListReportsResponse() {
  var o = api.ListReportsResponse();
  buildCounterListReportsResponse++;
  if (buildCounterListReportsResponse < 3) {
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.reports = buildUnnamed5892();
  }
  buildCounterListReportsResponse--;
  return o;
}

void checkListReportsResponse(api.ListReportsResponse o) {
  buildCounterListReportsResponse++;
  if (buildCounterListReportsResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5892(o.reports!);
  }
  buildCounterListReportsResponse--;
}

core.int buildCounterOptions = 0;
api.Options buildOptions() {
  var o = api.Options();
  buildCounterOptions++;
  if (buildCounterOptions < 3) {
    o.includeOnlyTargetedUserLists = true;
    o.pathQueryOptions = buildPathQueryOptions();
  }
  buildCounterOptions--;
  return o;
}

void checkOptions(api.Options o) {
  buildCounterOptions++;
  if (buildCounterOptions < 3) {
    unittest.expect(o.includeOnlyTargetedUserLists!, unittest.isTrue);
    checkPathQueryOptions(o.pathQueryOptions! as api.PathQueryOptions);
  }
  buildCounterOptions--;
}

core.List<api.FilterPair> buildUnnamed5893() {
  var o = <api.FilterPair>[];
  o.add(buildFilterPair());
  o.add(buildFilterPair());
  return o;
}

void checkUnnamed5893(core.List<api.FilterPair> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterPair(o[0] as api.FilterPair);
  checkFilterPair(o[1] as api.FilterPair);
}

core.List<core.String> buildUnnamed5894() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5894(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5895() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5895(core.List<core.String> o) {
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

core.int buildCounterParameters = 0;
api.Parameters buildParameters() {
  var o = api.Parameters();
  buildCounterParameters++;
  if (buildCounterParameters < 3) {
    o.filters = buildUnnamed5893();
    o.groupBys = buildUnnamed5894();
    o.includeInviteData = true;
    o.metrics = buildUnnamed5895();
    o.options = buildOptions();
    o.type = 'foo';
  }
  buildCounterParameters--;
  return o;
}

void checkParameters(api.Parameters o) {
  buildCounterParameters++;
  if (buildCounterParameters < 3) {
    checkUnnamed5893(o.filters!);
    checkUnnamed5894(o.groupBys!);
    unittest.expect(o.includeInviteData!, unittest.isTrue);
    checkUnnamed5895(o.metrics!);
    checkOptions(o.options! as api.Options);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterParameters--;
}

core.List<api.EventFilter> buildUnnamed5896() {
  var o = <api.EventFilter>[];
  o.add(buildEventFilter());
  o.add(buildEventFilter());
  return o;
}

void checkUnnamed5896(core.List<api.EventFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventFilter(o[0] as api.EventFilter);
  checkEventFilter(o[1] as api.EventFilter);
}

core.int buildCounterPathFilter = 0;
api.PathFilter buildPathFilter() {
  var o = api.PathFilter();
  buildCounterPathFilter++;
  if (buildCounterPathFilter < 3) {
    o.eventFilters = buildUnnamed5896();
    o.pathMatchPosition = 'foo';
  }
  buildCounterPathFilter--;
  return o;
}

void checkPathFilter(api.PathFilter o) {
  buildCounterPathFilter++;
  if (buildCounterPathFilter < 3) {
    checkUnnamed5896(o.eventFilters!);
    unittest.expect(
      o.pathMatchPosition!,
      unittest.equals('foo'),
    );
  }
  buildCounterPathFilter--;
}

core.List<api.PathFilter> buildUnnamed5897() {
  var o = <api.PathFilter>[];
  o.add(buildPathFilter());
  o.add(buildPathFilter());
  return o;
}

void checkUnnamed5897(core.List<api.PathFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPathFilter(o[0] as api.PathFilter);
  checkPathFilter(o[1] as api.PathFilter);
}

core.int buildCounterPathQueryOptions = 0;
api.PathQueryOptions buildPathQueryOptions() {
  var o = api.PathQueryOptions();
  buildCounterPathQueryOptions++;
  if (buildCounterPathQueryOptions < 3) {
    o.channelGrouping = buildChannelGrouping();
    o.pathFilters = buildUnnamed5897();
  }
  buildCounterPathQueryOptions--;
  return o;
}

void checkPathQueryOptions(api.PathQueryOptions o) {
  buildCounterPathQueryOptions++;
  if (buildCounterPathQueryOptions < 3) {
    checkChannelGrouping(o.channelGrouping! as api.ChannelGrouping);
    checkUnnamed5897(o.pathFilters!);
  }
  buildCounterPathQueryOptions--;
}

core.List<core.String> buildUnnamed5898() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5898(core.List<core.String> o) {
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

core.int buildCounterPathQueryOptionsFilter = 0;
api.PathQueryOptionsFilter buildPathQueryOptionsFilter() {
  var o = api.PathQueryOptionsFilter();
  buildCounterPathQueryOptionsFilter++;
  if (buildCounterPathQueryOptionsFilter < 3) {
    o.filter = 'foo';
    o.match = 'foo';
    o.values = buildUnnamed5898();
  }
  buildCounterPathQueryOptionsFilter--;
  return o;
}

void checkPathQueryOptionsFilter(api.PathQueryOptionsFilter o) {
  buildCounterPathQueryOptionsFilter++;
  if (buildCounterPathQueryOptionsFilter < 3) {
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.match!,
      unittest.equals('foo'),
    );
    checkUnnamed5898(o.values!);
  }
  buildCounterPathQueryOptionsFilter--;
}

core.int buildCounterQuery = 0;
api.Query buildQuery() {
  var o = api.Query();
  buildCounterQuery++;
  if (buildCounterQuery < 3) {
    o.kind = 'foo';
    o.metadata = buildQueryMetadata();
    o.params = buildParameters();
    o.queryId = 'foo';
    o.reportDataEndTimeMs = 'foo';
    o.reportDataStartTimeMs = 'foo';
    o.schedule = buildQuerySchedule();
    o.timezoneCode = 'foo';
  }
  buildCounterQuery--;
  return o;
}

void checkQuery(api.Query o) {
  buildCounterQuery++;
  if (buildCounterQuery < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkQueryMetadata(o.metadata! as api.QueryMetadata);
    checkParameters(o.params! as api.Parameters);
    unittest.expect(
      o.queryId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportDataEndTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportDataStartTimeMs!,
      unittest.equals('foo'),
    );
    checkQuerySchedule(o.schedule! as api.QuerySchedule);
    unittest.expect(
      o.timezoneCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterQuery--;
}

core.List<core.String> buildUnnamed5899() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5899(core.List<core.String> o) {
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

core.int buildCounterQueryMetadata = 0;
api.QueryMetadata buildQueryMetadata() {
  var o = api.QueryMetadata();
  buildCounterQueryMetadata++;
  if (buildCounterQueryMetadata < 3) {
    o.dataRange = 'foo';
    o.format = 'foo';
    o.googleCloudStoragePathForLatestReport = 'foo';
    o.googleDrivePathForLatestReport = 'foo';
    o.latestReportRunTimeMs = 'foo';
    o.locale = 'foo';
    o.reportCount = 42;
    o.running = true;
    o.sendNotification = true;
    o.shareEmailAddress = buildUnnamed5899();
    o.title = 'foo';
  }
  buildCounterQueryMetadata--;
  return o;
}

void checkQueryMetadata(api.QueryMetadata o) {
  buildCounterQueryMetadata++;
  if (buildCounterQueryMetadata < 3) {
    unittest.expect(
      o.dataRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.googleCloudStoragePathForLatestReport!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.googleDrivePathForLatestReport!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.latestReportRunTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportCount!,
      unittest.equals(42),
    );
    unittest.expect(o.running!, unittest.isTrue);
    unittest.expect(o.sendNotification!, unittest.isTrue);
    checkUnnamed5899(o.shareEmailAddress!);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryMetadata--;
}

core.int buildCounterQuerySchedule = 0;
api.QuerySchedule buildQuerySchedule() {
  var o = api.QuerySchedule();
  buildCounterQuerySchedule++;
  if (buildCounterQuerySchedule < 3) {
    o.endTimeMs = 'foo';
    o.frequency = 'foo';
    o.nextRunMinuteOfDay = 42;
    o.nextRunTimezoneCode = 'foo';
    o.startTimeMs = 'foo';
  }
  buildCounterQuerySchedule--;
  return o;
}

void checkQuerySchedule(api.QuerySchedule o) {
  buildCounterQuerySchedule++;
  if (buildCounterQuerySchedule < 3) {
    unittest.expect(
      o.endTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.frequency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextRunMinuteOfDay!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nextRunTimezoneCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeMs!,
      unittest.equals('foo'),
    );
  }
  buildCounterQuerySchedule--;
}

core.int buildCounterReport = 0;
api.Report buildReport() {
  var o = api.Report();
  buildCounterReport++;
  if (buildCounterReport < 3) {
    o.key = buildReportKey();
    o.metadata = buildReportMetadata();
    o.params = buildParameters();
  }
  buildCounterReport--;
  return o;
}

void checkReport(api.Report o) {
  buildCounterReport++;
  if (buildCounterReport < 3) {
    checkReportKey(o.key! as api.ReportKey);
    checkReportMetadata(o.metadata! as api.ReportMetadata);
    checkParameters(o.params! as api.Parameters);
  }
  buildCounterReport--;
}

core.int buildCounterReportFailure = 0;
api.ReportFailure buildReportFailure() {
  var o = api.ReportFailure();
  buildCounterReportFailure++;
  if (buildCounterReportFailure < 3) {
    o.errorCode = 'foo';
  }
  buildCounterReportFailure--;
  return o;
}

void checkReportFailure(api.ReportFailure o) {
  buildCounterReportFailure++;
  if (buildCounterReportFailure < 3) {
    unittest.expect(
      o.errorCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportFailure--;
}

core.int buildCounterReportKey = 0;
api.ReportKey buildReportKey() {
  var o = api.ReportKey();
  buildCounterReportKey++;
  if (buildCounterReportKey < 3) {
    o.queryId = 'foo';
    o.reportId = 'foo';
  }
  buildCounterReportKey--;
  return o;
}

void checkReportKey(api.ReportKey o) {
  buildCounterReportKey++;
  if (buildCounterReportKey < 3) {
    unittest.expect(
      o.queryId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportKey--;
}

core.int buildCounterReportMetadata = 0;
api.ReportMetadata buildReportMetadata() {
  var o = api.ReportMetadata();
  buildCounterReportMetadata++;
  if (buildCounterReportMetadata < 3) {
    o.googleCloudStoragePath = 'foo';
    o.reportDataEndTimeMs = 'foo';
    o.reportDataStartTimeMs = 'foo';
    o.status = buildReportStatus();
  }
  buildCounterReportMetadata--;
  return o;
}

void checkReportMetadata(api.ReportMetadata o) {
  buildCounterReportMetadata++;
  if (buildCounterReportMetadata < 3) {
    unittest.expect(
      o.googleCloudStoragePath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportDataEndTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportDataStartTimeMs!,
      unittest.equals('foo'),
    );
    checkReportStatus(o.status! as api.ReportStatus);
  }
  buildCounterReportMetadata--;
}

core.int buildCounterReportStatus = 0;
api.ReportStatus buildReportStatus() {
  var o = api.ReportStatus();
  buildCounterReportStatus++;
  if (buildCounterReportStatus < 3) {
    o.failure = buildReportFailure();
    o.finishTimeMs = 'foo';
    o.format = 'foo';
    o.state = 'foo';
  }
  buildCounterReportStatus--;
  return o;
}

void checkReportStatus(api.ReportStatus o) {
  buildCounterReportStatus++;
  if (buildCounterReportStatus < 3) {
    checkReportFailure(o.failure! as api.ReportFailure);
    unittest.expect(
      o.finishTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportStatus--;
}

core.List<api.DisjunctiveMatchStatement> buildUnnamed5900() {
  var o = <api.DisjunctiveMatchStatement>[];
  o.add(buildDisjunctiveMatchStatement());
  o.add(buildDisjunctiveMatchStatement());
  return o;
}

void checkUnnamed5900(core.List<api.DisjunctiveMatchStatement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDisjunctiveMatchStatement(o[0] as api.DisjunctiveMatchStatement);
  checkDisjunctiveMatchStatement(o[1] as api.DisjunctiveMatchStatement);
}

core.int buildCounterRule = 0;
api.Rule buildRule() {
  var o = api.Rule();
  buildCounterRule++;
  if (buildCounterRule < 3) {
    o.disjunctiveMatchStatements = buildUnnamed5900();
    o.name = 'foo';
  }
  buildCounterRule--;
  return o;
}

void checkRule(api.Rule o) {
  buildCounterRule++;
  if (buildCounterRule < 3) {
    checkUnnamed5900(o.disjunctiveMatchStatements!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterRule--;
}

core.int buildCounterRunQueryRequest = 0;
api.RunQueryRequest buildRunQueryRequest() {
  var o = api.RunQueryRequest();
  buildCounterRunQueryRequest++;
  if (buildCounterRunQueryRequest < 3) {
    o.dataRange = 'foo';
    o.reportDataEndTimeMs = 'foo';
    o.reportDataStartTimeMs = 'foo';
    o.timezoneCode = 'foo';
  }
  buildCounterRunQueryRequest--;
  return o;
}

void checkRunQueryRequest(api.RunQueryRequest o) {
  buildCounterRunQueryRequest++;
  if (buildCounterRunQueryRequest < 3) {
    unittest.expect(
      o.dataRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportDataEndTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportDataStartTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timezoneCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterRunQueryRequest--;
}

void main() {
  unittest.group('obj-schema-ChannelGrouping', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelGrouping();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelGrouping.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelGrouping(od as api.ChannelGrouping);
    });
  });

  unittest.group('obj-schema-DisjunctiveMatchStatement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDisjunctiveMatchStatement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DisjunctiveMatchStatement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDisjunctiveMatchStatement(od as api.DisjunctiveMatchStatement);
    });
  });

  unittest.group('obj-schema-EventFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventFilter(od as api.EventFilter);
    });
  });

  unittest.group('obj-schema-FilterPair', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterPair();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FilterPair.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilterPair(od as api.FilterPair);
    });
  });

  unittest.group('obj-schema-ListQueriesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListQueriesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListQueriesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListQueriesResponse(od as api.ListQueriesResponse);
    });
  });

  unittest.group('obj-schema-ListReportsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListReportsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListReportsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListReportsResponse(od as api.ListReportsResponse);
    });
  });

  unittest.group('obj-schema-Options', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Options.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOptions(od as api.Options);
    });
  });

  unittest.group('obj-schema-Parameters', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParameters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Parameters.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkParameters(od as api.Parameters);
    });
  });

  unittest.group('obj-schema-PathFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPathFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PathFilter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPathFilter(od as api.PathFilter);
    });
  });

  unittest.group('obj-schema-PathQueryOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPathQueryOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PathQueryOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPathQueryOptions(od as api.PathQueryOptions);
    });
  });

  unittest.group('obj-schema-PathQueryOptionsFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPathQueryOptionsFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PathQueryOptionsFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPathQueryOptionsFilter(od as api.PathQueryOptionsFilter);
    });
  });

  unittest.group('obj-schema-Query', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Query.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkQuery(od as api.Query);
    });
  });

  unittest.group('obj-schema-QueryMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryMetadata(od as api.QueryMetadata);
    });
  });

  unittest.group('obj-schema-QuerySchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuerySchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QuerySchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQuerySchedule(od as api.QuerySchedule);
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

  unittest.group('obj-schema-ReportFailure', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportFailure();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportFailure.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportFailure(od as api.ReportFailure);
    });
  });

  unittest.group('obj-schema-ReportKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ReportKey.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReportKey(od as api.ReportKey);
    });
  });

  unittest.group('obj-schema-ReportMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportMetadata(od as api.ReportMetadata);
    });
  });

  unittest.group('obj-schema-ReportStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportStatus(od as api.ReportStatus);
    });
  });

  unittest.group('obj-schema-Rule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Rule.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRule(od as api.Rule);
    });
  });

  unittest.group('obj-schema-RunQueryRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRunQueryRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RunQueryRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRunQueryRequest(od as api.RunQueryRequest);
    });
  });

  unittest.group('resource-QueriesResource', () {
    unittest.test('method--createquery', () async {
      var mock = HttpServerMock();
      var res = api.DoubleClickBidManagerApi(mock).queries;
      var arg_request = buildQuery();
      var arg_asynchronous = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Query.fromJson(json as core.Map<core.String, core.dynamic>);
        checkQuery(obj as api.Query);

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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("doubleclickbidmanager/v1.1/"),
        );
        pathOffset += 27;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("query"),
        );
        pathOffset += 5;

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
          queryMap["asynchronous"]!.first,
          unittest.equals("$arg_asynchronous"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildQuery());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.createquery(arg_request,
          asynchronous: arg_asynchronous, $fields: arg_$fields);
      checkQuery(response as api.Query);
    });

    unittest.test('method--deletequery', () async {
      var mock = HttpServerMock();
      var res = api.DoubleClickBidManagerApi(mock).queries;
      var arg_queryId = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("doubleclickbidmanager/v1.1/"),
        );
        pathOffset += 27;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("query/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_queryId'),
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
      await res.deletequery(arg_queryId, $fields: arg_$fields);
    });

    unittest.test('method--getquery', () async {
      var mock = HttpServerMock();
      var res = api.DoubleClickBidManagerApi(mock).queries;
      var arg_queryId = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("doubleclickbidmanager/v1.1/"),
        );
        pathOffset += 27;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("query/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_queryId'),
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
        var resp = convert.json.encode(buildQuery());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getquery(arg_queryId, $fields: arg_$fields);
      checkQuery(response as api.Query);
    });

    unittest.test('method--listqueries', () async {
      var mock = HttpServerMock();
      var res = api.DoubleClickBidManagerApi(mock).queries;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("doubleclickbidmanager/v1.1/"),
        );
        pathOffset += 27;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("queries"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListQueriesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listqueries(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListQueriesResponse(response as api.ListQueriesResponse);
    });

    unittest.test('method--runquery', () async {
      var mock = HttpServerMock();
      var res = api.DoubleClickBidManagerApi(mock).queries;
      var arg_request = buildRunQueryRequest();
      var arg_queryId = 'foo';
      var arg_asynchronous = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RunQueryRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRunQueryRequest(obj as api.RunQueryRequest);

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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("doubleclickbidmanager/v1.1/"),
        );
        pathOffset += 27;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("query/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_queryId'),
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
          queryMap["asynchronous"]!.first,
          unittest.equals("$arg_asynchronous"),
        );
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
      await res.runquery(arg_request, arg_queryId,
          asynchronous: arg_asynchronous, $fields: arg_$fields);
    });
  });

  unittest.group('resource-ReportsResource', () {
    unittest.test('method--listreports', () async {
      var mock = HttpServerMock();
      var res = api.DoubleClickBidManagerApi(mock).reports;
      var arg_queryId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("doubleclickbidmanager/v1.1/"),
        );
        pathOffset += 27;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("queries/"),
        );
        pathOffset += 8;
        index = path.indexOf('/reports', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_queryId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/reports"),
        );
        pathOffset += 8;

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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListReportsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listreports(arg_queryId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListReportsResponse(response as api.ListReportsResponse);
    });
  });
}

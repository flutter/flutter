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

import 'package:googleapis/admob/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed7165() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7165(core.List<core.String> o) {
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

core.int buildCounterAdUnit = 0;
api.AdUnit buildAdUnit() {
  var o = api.AdUnit();
  buildCounterAdUnit++;
  if (buildCounterAdUnit < 3) {
    o.adFormat = 'foo';
    o.adTypes = buildUnnamed7165();
    o.adUnitId = 'foo';
    o.appId = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
  }
  buildCounterAdUnit--;
  return o;
}

void checkAdUnit(api.AdUnit o) {
  buildCounterAdUnit++;
  if (buildCounterAdUnit < 3) {
    unittest.expect(
      o.adFormat!,
      unittest.equals('foo'),
    );
    checkUnnamed7165(o.adTypes!);
    unittest.expect(
      o.adUnitId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnit--;
}

core.int buildCounterApp = 0;
api.App buildApp() {
  var o = api.App();
  buildCounterApp++;
  if (buildCounterApp < 3) {
    o.appId = 'foo';
    o.linkedAppInfo = buildAppLinkedAppInfo();
    o.manualAppInfo = buildAppManualAppInfo();
    o.name = 'foo';
    o.platform = 'foo';
  }
  buildCounterApp--;
  return o;
}

void checkApp(api.App o) {
  buildCounterApp++;
  if (buildCounterApp < 3) {
    unittest.expect(
      o.appId!,
      unittest.equals('foo'),
    );
    checkAppLinkedAppInfo(o.linkedAppInfo! as api.AppLinkedAppInfo);
    checkAppManualAppInfo(o.manualAppInfo! as api.AppManualAppInfo);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platform!,
      unittest.equals('foo'),
    );
  }
  buildCounterApp--;
}

core.int buildCounterAppLinkedAppInfo = 0;
api.AppLinkedAppInfo buildAppLinkedAppInfo() {
  var o = api.AppLinkedAppInfo();
  buildCounterAppLinkedAppInfo++;
  if (buildCounterAppLinkedAppInfo < 3) {
    o.appStoreId = 'foo';
    o.displayName = 'foo';
  }
  buildCounterAppLinkedAppInfo--;
  return o;
}

void checkAppLinkedAppInfo(api.AppLinkedAppInfo o) {
  buildCounterAppLinkedAppInfo++;
  if (buildCounterAppLinkedAppInfo < 3) {
    unittest.expect(
      o.appStoreId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppLinkedAppInfo--;
}

core.int buildCounterAppManualAppInfo = 0;
api.AppManualAppInfo buildAppManualAppInfo() {
  var o = api.AppManualAppInfo();
  buildCounterAppManualAppInfo++;
  if (buildCounterAppManualAppInfo < 3) {
    o.displayName = 'foo';
  }
  buildCounterAppManualAppInfo--;
  return o;
}

void checkAppManualAppInfo(api.AppManualAppInfo o) {
  buildCounterAppManualAppInfo++;
  if (buildCounterAppManualAppInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppManualAppInfo--;
}

core.int buildCounterDate = 0;
api.Date buildDate() {
  var o = api.Date();
  buildCounterDate++;
  if (buildCounterDate < 3) {
    o.day = 42;
    o.month = 42;
    o.year = 42;
  }
  buildCounterDate--;
  return o;
}

void checkDate(api.Date o) {
  buildCounterDate++;
  if (buildCounterDate < 3) {
    unittest.expect(
      o.day!,
      unittest.equals(42),
    );
    unittest.expect(
      o.month!,
      unittest.equals(42),
    );
    unittest.expect(
      o.year!,
      unittest.equals(42),
    );
  }
  buildCounterDate--;
}

core.int buildCounterDateRange = 0;
api.DateRange buildDateRange() {
  var o = api.DateRange();
  buildCounterDateRange++;
  if (buildCounterDateRange < 3) {
    o.endDate = buildDate();
    o.startDate = buildDate();
  }
  buildCounterDateRange--;
  return o;
}

void checkDateRange(api.DateRange o) {
  buildCounterDateRange++;
  if (buildCounterDateRange < 3) {
    checkDate(o.endDate! as api.Date);
    checkDate(o.startDate! as api.Date);
  }
  buildCounterDateRange--;
}

core.int buildCounterGenerateMediationReportRequest = 0;
api.GenerateMediationReportRequest buildGenerateMediationReportRequest() {
  var o = api.GenerateMediationReportRequest();
  buildCounterGenerateMediationReportRequest++;
  if (buildCounterGenerateMediationReportRequest < 3) {
    o.reportSpec = buildMediationReportSpec();
  }
  buildCounterGenerateMediationReportRequest--;
  return o;
}

void checkGenerateMediationReportRequest(api.GenerateMediationReportRequest o) {
  buildCounterGenerateMediationReportRequest++;
  if (buildCounterGenerateMediationReportRequest < 3) {
    checkMediationReportSpec(o.reportSpec! as api.MediationReportSpec);
  }
  buildCounterGenerateMediationReportRequest--;
}

core.int buildCounterGenerateMediationReportResponse = 0;
api.GenerateMediationReportResponse buildGenerateMediationReportResponse() {
  var o = api.GenerateMediationReportResponse();
  buildCounterGenerateMediationReportResponse++;
  if (buildCounterGenerateMediationReportResponse < 3) {
    o.footer = buildReportFooter();
    o.header = buildReportHeader();
    o.row = buildReportRow();
  }
  buildCounterGenerateMediationReportResponse--;
  return o;
}

void checkGenerateMediationReportResponse(
    api.GenerateMediationReportResponse o) {
  buildCounterGenerateMediationReportResponse++;
  if (buildCounterGenerateMediationReportResponse < 3) {
    checkReportFooter(o.footer! as api.ReportFooter);
    checkReportHeader(o.header! as api.ReportHeader);
    checkReportRow(o.row! as api.ReportRow);
  }
  buildCounterGenerateMediationReportResponse--;
}

core.int buildCounterGenerateNetworkReportRequest = 0;
api.GenerateNetworkReportRequest buildGenerateNetworkReportRequest() {
  var o = api.GenerateNetworkReportRequest();
  buildCounterGenerateNetworkReportRequest++;
  if (buildCounterGenerateNetworkReportRequest < 3) {
    o.reportSpec = buildNetworkReportSpec();
  }
  buildCounterGenerateNetworkReportRequest--;
  return o;
}

void checkGenerateNetworkReportRequest(api.GenerateNetworkReportRequest o) {
  buildCounterGenerateNetworkReportRequest++;
  if (buildCounterGenerateNetworkReportRequest < 3) {
    checkNetworkReportSpec(o.reportSpec! as api.NetworkReportSpec);
  }
  buildCounterGenerateNetworkReportRequest--;
}

core.int buildCounterGenerateNetworkReportResponse = 0;
api.GenerateNetworkReportResponse buildGenerateNetworkReportResponse() {
  var o = api.GenerateNetworkReportResponse();
  buildCounterGenerateNetworkReportResponse++;
  if (buildCounterGenerateNetworkReportResponse < 3) {
    o.footer = buildReportFooter();
    o.header = buildReportHeader();
    o.row = buildReportRow();
  }
  buildCounterGenerateNetworkReportResponse--;
  return o;
}

void checkGenerateNetworkReportResponse(api.GenerateNetworkReportResponse o) {
  buildCounterGenerateNetworkReportResponse++;
  if (buildCounterGenerateNetworkReportResponse < 3) {
    checkReportFooter(o.footer! as api.ReportFooter);
    checkReportHeader(o.header! as api.ReportHeader);
    checkReportRow(o.row! as api.ReportRow);
  }
  buildCounterGenerateNetworkReportResponse--;
}

core.List<api.AdUnit> buildUnnamed7166() {
  var o = <api.AdUnit>[];
  o.add(buildAdUnit());
  o.add(buildAdUnit());
  return o;
}

void checkUnnamed7166(core.List<api.AdUnit> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdUnit(o[0] as api.AdUnit);
  checkAdUnit(o[1] as api.AdUnit);
}

core.int buildCounterListAdUnitsResponse = 0;
api.ListAdUnitsResponse buildListAdUnitsResponse() {
  var o = api.ListAdUnitsResponse();
  buildCounterListAdUnitsResponse++;
  if (buildCounterListAdUnitsResponse < 3) {
    o.adUnits = buildUnnamed7166();
    o.nextPageToken = 'foo';
  }
  buildCounterListAdUnitsResponse--;
  return o;
}

void checkListAdUnitsResponse(api.ListAdUnitsResponse o) {
  buildCounterListAdUnitsResponse++;
  if (buildCounterListAdUnitsResponse < 3) {
    checkUnnamed7166(o.adUnits!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAdUnitsResponse--;
}

core.List<api.App> buildUnnamed7167() {
  var o = <api.App>[];
  o.add(buildApp());
  o.add(buildApp());
  return o;
}

void checkUnnamed7167(core.List<api.App> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApp(o[0] as api.App);
  checkApp(o[1] as api.App);
}

core.int buildCounterListAppsResponse = 0;
api.ListAppsResponse buildListAppsResponse() {
  var o = api.ListAppsResponse();
  buildCounterListAppsResponse++;
  if (buildCounterListAppsResponse < 3) {
    o.apps = buildUnnamed7167();
    o.nextPageToken = 'foo';
  }
  buildCounterListAppsResponse--;
  return o;
}

void checkListAppsResponse(api.ListAppsResponse o) {
  buildCounterListAppsResponse++;
  if (buildCounterListAppsResponse < 3) {
    checkUnnamed7167(o.apps!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAppsResponse--;
}

core.List<api.PublisherAccount> buildUnnamed7168() {
  var o = <api.PublisherAccount>[];
  o.add(buildPublisherAccount());
  o.add(buildPublisherAccount());
  return o;
}

void checkUnnamed7168(core.List<api.PublisherAccount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPublisherAccount(o[0] as api.PublisherAccount);
  checkPublisherAccount(o[1] as api.PublisherAccount);
}

core.int buildCounterListPublisherAccountsResponse = 0;
api.ListPublisherAccountsResponse buildListPublisherAccountsResponse() {
  var o = api.ListPublisherAccountsResponse();
  buildCounterListPublisherAccountsResponse++;
  if (buildCounterListPublisherAccountsResponse < 3) {
    o.account = buildUnnamed7168();
    o.nextPageToken = 'foo';
  }
  buildCounterListPublisherAccountsResponse--;
  return o;
}

void checkListPublisherAccountsResponse(api.ListPublisherAccountsResponse o) {
  buildCounterListPublisherAccountsResponse++;
  if (buildCounterListPublisherAccountsResponse < 3) {
    checkUnnamed7168(o.account!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListPublisherAccountsResponse--;
}

core.int buildCounterLocalizationSettings = 0;
api.LocalizationSettings buildLocalizationSettings() {
  var o = api.LocalizationSettings();
  buildCounterLocalizationSettings++;
  if (buildCounterLocalizationSettings < 3) {
    o.currencyCode = 'foo';
    o.languageCode = 'foo';
  }
  buildCounterLocalizationSettings--;
  return o;
}

void checkLocalizationSettings(api.LocalizationSettings o) {
  buildCounterLocalizationSettings++;
  if (buildCounterLocalizationSettings < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocalizationSettings--;
}

core.List<api.MediationReportSpecDimensionFilter> buildUnnamed7169() {
  var o = <api.MediationReportSpecDimensionFilter>[];
  o.add(buildMediationReportSpecDimensionFilter());
  o.add(buildMediationReportSpecDimensionFilter());
  return o;
}

void checkUnnamed7169(core.List<api.MediationReportSpecDimensionFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMediationReportSpecDimensionFilter(
      o[0] as api.MediationReportSpecDimensionFilter);
  checkMediationReportSpecDimensionFilter(
      o[1] as api.MediationReportSpecDimensionFilter);
}

core.List<core.String> buildUnnamed7170() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7170(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed7171() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7171(core.List<core.String> o) {
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

core.List<api.MediationReportSpecSortCondition> buildUnnamed7172() {
  var o = <api.MediationReportSpecSortCondition>[];
  o.add(buildMediationReportSpecSortCondition());
  o.add(buildMediationReportSpecSortCondition());
  return o;
}

void checkUnnamed7172(core.List<api.MediationReportSpecSortCondition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMediationReportSpecSortCondition(
      o[0] as api.MediationReportSpecSortCondition);
  checkMediationReportSpecSortCondition(
      o[1] as api.MediationReportSpecSortCondition);
}

core.int buildCounterMediationReportSpec = 0;
api.MediationReportSpec buildMediationReportSpec() {
  var o = api.MediationReportSpec();
  buildCounterMediationReportSpec++;
  if (buildCounterMediationReportSpec < 3) {
    o.dateRange = buildDateRange();
    o.dimensionFilters = buildUnnamed7169();
    o.dimensions = buildUnnamed7170();
    o.localizationSettings = buildLocalizationSettings();
    o.maxReportRows = 42;
    o.metrics = buildUnnamed7171();
    o.sortConditions = buildUnnamed7172();
    o.timeZone = 'foo';
  }
  buildCounterMediationReportSpec--;
  return o;
}

void checkMediationReportSpec(api.MediationReportSpec o) {
  buildCounterMediationReportSpec++;
  if (buildCounterMediationReportSpec < 3) {
    checkDateRange(o.dateRange! as api.DateRange);
    checkUnnamed7169(o.dimensionFilters!);
    checkUnnamed7170(o.dimensions!);
    checkLocalizationSettings(
        o.localizationSettings! as api.LocalizationSettings);
    unittest.expect(
      o.maxReportRows!,
      unittest.equals(42),
    );
    checkUnnamed7171(o.metrics!);
    checkUnnamed7172(o.sortConditions!);
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterMediationReportSpec--;
}

core.int buildCounterMediationReportSpecDimensionFilter = 0;
api.MediationReportSpecDimensionFilter
    buildMediationReportSpecDimensionFilter() {
  var o = api.MediationReportSpecDimensionFilter();
  buildCounterMediationReportSpecDimensionFilter++;
  if (buildCounterMediationReportSpecDimensionFilter < 3) {
    o.dimension = 'foo';
    o.matchesAny = buildStringList();
  }
  buildCounterMediationReportSpecDimensionFilter--;
  return o;
}

void checkMediationReportSpecDimensionFilter(
    api.MediationReportSpecDimensionFilter o) {
  buildCounterMediationReportSpecDimensionFilter++;
  if (buildCounterMediationReportSpecDimensionFilter < 3) {
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    checkStringList(o.matchesAny! as api.StringList);
  }
  buildCounterMediationReportSpecDimensionFilter--;
}

core.int buildCounterMediationReportSpecSortCondition = 0;
api.MediationReportSpecSortCondition buildMediationReportSpecSortCondition() {
  var o = api.MediationReportSpecSortCondition();
  buildCounterMediationReportSpecSortCondition++;
  if (buildCounterMediationReportSpecSortCondition < 3) {
    o.dimension = 'foo';
    o.metric = 'foo';
    o.order = 'foo';
  }
  buildCounterMediationReportSpecSortCondition--;
  return o;
}

void checkMediationReportSpecSortCondition(
    api.MediationReportSpecSortCondition o) {
  buildCounterMediationReportSpecSortCondition++;
  if (buildCounterMediationReportSpecSortCondition < 3) {
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metric!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.order!,
      unittest.equals('foo'),
    );
  }
  buildCounterMediationReportSpecSortCondition--;
}

core.List<api.NetworkReportSpecDimensionFilter> buildUnnamed7173() {
  var o = <api.NetworkReportSpecDimensionFilter>[];
  o.add(buildNetworkReportSpecDimensionFilter());
  o.add(buildNetworkReportSpecDimensionFilter());
  return o;
}

void checkUnnamed7173(core.List<api.NetworkReportSpecDimensionFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNetworkReportSpecDimensionFilter(
      o[0] as api.NetworkReportSpecDimensionFilter);
  checkNetworkReportSpecDimensionFilter(
      o[1] as api.NetworkReportSpecDimensionFilter);
}

core.List<core.String> buildUnnamed7174() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7174(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed7175() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7175(core.List<core.String> o) {
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

core.List<api.NetworkReportSpecSortCondition> buildUnnamed7176() {
  var o = <api.NetworkReportSpecSortCondition>[];
  o.add(buildNetworkReportSpecSortCondition());
  o.add(buildNetworkReportSpecSortCondition());
  return o;
}

void checkUnnamed7176(core.List<api.NetworkReportSpecSortCondition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNetworkReportSpecSortCondition(
      o[0] as api.NetworkReportSpecSortCondition);
  checkNetworkReportSpecSortCondition(
      o[1] as api.NetworkReportSpecSortCondition);
}

core.int buildCounterNetworkReportSpec = 0;
api.NetworkReportSpec buildNetworkReportSpec() {
  var o = api.NetworkReportSpec();
  buildCounterNetworkReportSpec++;
  if (buildCounterNetworkReportSpec < 3) {
    o.dateRange = buildDateRange();
    o.dimensionFilters = buildUnnamed7173();
    o.dimensions = buildUnnamed7174();
    o.localizationSettings = buildLocalizationSettings();
    o.maxReportRows = 42;
    o.metrics = buildUnnamed7175();
    o.sortConditions = buildUnnamed7176();
    o.timeZone = 'foo';
  }
  buildCounterNetworkReportSpec--;
  return o;
}

void checkNetworkReportSpec(api.NetworkReportSpec o) {
  buildCounterNetworkReportSpec++;
  if (buildCounterNetworkReportSpec < 3) {
    checkDateRange(o.dateRange! as api.DateRange);
    checkUnnamed7173(o.dimensionFilters!);
    checkUnnamed7174(o.dimensions!);
    checkLocalizationSettings(
        o.localizationSettings! as api.LocalizationSettings);
    unittest.expect(
      o.maxReportRows!,
      unittest.equals(42),
    );
    checkUnnamed7175(o.metrics!);
    checkUnnamed7176(o.sortConditions!);
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterNetworkReportSpec--;
}

core.int buildCounterNetworkReportSpecDimensionFilter = 0;
api.NetworkReportSpecDimensionFilter buildNetworkReportSpecDimensionFilter() {
  var o = api.NetworkReportSpecDimensionFilter();
  buildCounterNetworkReportSpecDimensionFilter++;
  if (buildCounterNetworkReportSpecDimensionFilter < 3) {
    o.dimension = 'foo';
    o.matchesAny = buildStringList();
  }
  buildCounterNetworkReportSpecDimensionFilter--;
  return o;
}

void checkNetworkReportSpecDimensionFilter(
    api.NetworkReportSpecDimensionFilter o) {
  buildCounterNetworkReportSpecDimensionFilter++;
  if (buildCounterNetworkReportSpecDimensionFilter < 3) {
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    checkStringList(o.matchesAny! as api.StringList);
  }
  buildCounterNetworkReportSpecDimensionFilter--;
}

core.int buildCounterNetworkReportSpecSortCondition = 0;
api.NetworkReportSpecSortCondition buildNetworkReportSpecSortCondition() {
  var o = api.NetworkReportSpecSortCondition();
  buildCounterNetworkReportSpecSortCondition++;
  if (buildCounterNetworkReportSpecSortCondition < 3) {
    o.dimension = 'foo';
    o.metric = 'foo';
    o.order = 'foo';
  }
  buildCounterNetworkReportSpecSortCondition--;
  return o;
}

void checkNetworkReportSpecSortCondition(api.NetworkReportSpecSortCondition o) {
  buildCounterNetworkReportSpecSortCondition++;
  if (buildCounterNetworkReportSpecSortCondition < 3) {
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metric!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.order!,
      unittest.equals('foo'),
    );
  }
  buildCounterNetworkReportSpecSortCondition--;
}

core.int buildCounterPublisherAccount = 0;
api.PublisherAccount buildPublisherAccount() {
  var o = api.PublisherAccount();
  buildCounterPublisherAccount++;
  if (buildCounterPublisherAccount < 3) {
    o.currencyCode = 'foo';
    o.name = 'foo';
    o.publisherId = 'foo';
    o.reportingTimeZone = 'foo';
  }
  buildCounterPublisherAccount--;
  return o;
}

void checkPublisherAccount(api.PublisherAccount o) {
  buildCounterPublisherAccount++;
  if (buildCounterPublisherAccount < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publisherId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingTimeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterPublisherAccount--;
}

core.List<api.ReportWarning> buildUnnamed7177() {
  var o = <api.ReportWarning>[];
  o.add(buildReportWarning());
  o.add(buildReportWarning());
  return o;
}

void checkUnnamed7177(core.List<api.ReportWarning> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportWarning(o[0] as api.ReportWarning);
  checkReportWarning(o[1] as api.ReportWarning);
}

core.int buildCounterReportFooter = 0;
api.ReportFooter buildReportFooter() {
  var o = api.ReportFooter();
  buildCounterReportFooter++;
  if (buildCounterReportFooter < 3) {
    o.matchingRowCount = 'foo';
    o.warnings = buildUnnamed7177();
  }
  buildCounterReportFooter--;
  return o;
}

void checkReportFooter(api.ReportFooter o) {
  buildCounterReportFooter++;
  if (buildCounterReportFooter < 3) {
    unittest.expect(
      o.matchingRowCount!,
      unittest.equals('foo'),
    );
    checkUnnamed7177(o.warnings!);
  }
  buildCounterReportFooter--;
}

core.int buildCounterReportHeader = 0;
api.ReportHeader buildReportHeader() {
  var o = api.ReportHeader();
  buildCounterReportHeader++;
  if (buildCounterReportHeader < 3) {
    o.dateRange = buildDateRange();
    o.localizationSettings = buildLocalizationSettings();
    o.reportingTimeZone = 'foo';
  }
  buildCounterReportHeader--;
  return o;
}

void checkReportHeader(api.ReportHeader o) {
  buildCounterReportHeader++;
  if (buildCounterReportHeader < 3) {
    checkDateRange(o.dateRange! as api.DateRange);
    checkLocalizationSettings(
        o.localizationSettings! as api.LocalizationSettings);
    unittest.expect(
      o.reportingTimeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportHeader--;
}

core.Map<core.String, api.ReportRowDimensionValue> buildUnnamed7178() {
  var o = <core.String, api.ReportRowDimensionValue>{};
  o['x'] = buildReportRowDimensionValue();
  o['y'] = buildReportRowDimensionValue();
  return o;
}

void checkUnnamed7178(core.Map<core.String, api.ReportRowDimensionValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportRowDimensionValue(o['x']! as api.ReportRowDimensionValue);
  checkReportRowDimensionValue(o['y']! as api.ReportRowDimensionValue);
}

core.Map<core.String, api.ReportRowMetricValue> buildUnnamed7179() {
  var o = <core.String, api.ReportRowMetricValue>{};
  o['x'] = buildReportRowMetricValue();
  o['y'] = buildReportRowMetricValue();
  return o;
}

void checkUnnamed7179(core.Map<core.String, api.ReportRowMetricValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportRowMetricValue(o['x']! as api.ReportRowMetricValue);
  checkReportRowMetricValue(o['y']! as api.ReportRowMetricValue);
}

core.int buildCounterReportRow = 0;
api.ReportRow buildReportRow() {
  var o = api.ReportRow();
  buildCounterReportRow++;
  if (buildCounterReportRow < 3) {
    o.dimensionValues = buildUnnamed7178();
    o.metricValues = buildUnnamed7179();
  }
  buildCounterReportRow--;
  return o;
}

void checkReportRow(api.ReportRow o) {
  buildCounterReportRow++;
  if (buildCounterReportRow < 3) {
    checkUnnamed7178(o.dimensionValues!);
    checkUnnamed7179(o.metricValues!);
  }
  buildCounterReportRow--;
}

core.int buildCounterReportRowDimensionValue = 0;
api.ReportRowDimensionValue buildReportRowDimensionValue() {
  var o = api.ReportRowDimensionValue();
  buildCounterReportRowDimensionValue++;
  if (buildCounterReportRowDimensionValue < 3) {
    o.displayLabel = 'foo';
    o.value = 'foo';
  }
  buildCounterReportRowDimensionValue--;
  return o;
}

void checkReportRowDimensionValue(api.ReportRowDimensionValue o) {
  buildCounterReportRowDimensionValue++;
  if (buildCounterReportRowDimensionValue < 3) {
    unittest.expect(
      o.displayLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportRowDimensionValue--;
}

core.int buildCounterReportRowMetricValue = 0;
api.ReportRowMetricValue buildReportRowMetricValue() {
  var o = api.ReportRowMetricValue();
  buildCounterReportRowMetricValue++;
  if (buildCounterReportRowMetricValue < 3) {
    o.doubleValue = 42.0;
    o.integerValue = 'foo';
    o.microsValue = 'foo';
  }
  buildCounterReportRowMetricValue--;
  return o;
}

void checkReportRowMetricValue(api.ReportRowMetricValue o) {
  buildCounterReportRowMetricValue++;
  if (buildCounterReportRowMetricValue < 3) {
    unittest.expect(
      o.doubleValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.integerValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.microsValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportRowMetricValue--;
}

core.int buildCounterReportWarning = 0;
api.ReportWarning buildReportWarning() {
  var o = api.ReportWarning();
  buildCounterReportWarning++;
  if (buildCounterReportWarning < 3) {
    o.description = 'foo';
    o.type = 'foo';
  }
  buildCounterReportWarning--;
  return o;
}

void checkReportWarning(api.ReportWarning o) {
  buildCounterReportWarning++;
  if (buildCounterReportWarning < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportWarning--;
}

core.List<core.String> buildUnnamed7180() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7180(core.List<core.String> o) {
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

core.int buildCounterStringList = 0;
api.StringList buildStringList() {
  var o = api.StringList();
  buildCounterStringList++;
  if (buildCounterStringList < 3) {
    o.values = buildUnnamed7180();
  }
  buildCounterStringList--;
  return o;
}

void checkStringList(api.StringList o) {
  buildCounterStringList++;
  if (buildCounterStringList < 3) {
    checkUnnamed7180(o.values!);
  }
  buildCounterStringList--;
}

void main() {
  unittest.group('obj-schema-AdUnit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AdUnit.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdUnit(od as api.AdUnit);
    });
  });

  unittest.group('obj-schema-App', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApp();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.App.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkApp(od as api.App);
    });
  });

  unittest.group('obj-schema-AppLinkedAppInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppLinkedAppInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppLinkedAppInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppLinkedAppInfo(od as api.AppLinkedAppInfo);
    });
  });

  unittest.group('obj-schema-AppManualAppInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppManualAppInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppManualAppInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppManualAppInfo(od as api.AppManualAppInfo);
    });
  });

  unittest.group('obj-schema-Date', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Date.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDate(od as api.Date);
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

  unittest.group('obj-schema-GenerateMediationReportRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenerateMediationReportRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenerateMediationReportRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenerateMediationReportRequest(
          od as api.GenerateMediationReportRequest);
    });
  });

  unittest.group('obj-schema-GenerateMediationReportResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenerateMediationReportResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenerateMediationReportResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenerateMediationReportResponse(
          od as api.GenerateMediationReportResponse);
    });
  });

  unittest.group('obj-schema-GenerateNetworkReportRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenerateNetworkReportRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenerateNetworkReportRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenerateNetworkReportRequest(od as api.GenerateNetworkReportRequest);
    });
  });

  unittest.group('obj-schema-GenerateNetworkReportResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenerateNetworkReportResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenerateNetworkReportResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenerateNetworkReportResponse(
          od as api.GenerateNetworkReportResponse);
    });
  });

  unittest.group('obj-schema-ListAdUnitsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAdUnitsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAdUnitsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAdUnitsResponse(od as api.ListAdUnitsResponse);
    });
  });

  unittest.group('obj-schema-ListAppsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAppsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAppsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAppsResponse(od as api.ListAppsResponse);
    });
  });

  unittest.group('obj-schema-ListPublisherAccountsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPublisherAccountsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPublisherAccountsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPublisherAccountsResponse(
          od as api.ListPublisherAccountsResponse);
    });
  });

  unittest.group('obj-schema-LocalizationSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalizationSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocalizationSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocalizationSettings(od as api.LocalizationSettings);
    });
  });

  unittest.group('obj-schema-MediationReportSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMediationReportSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MediationReportSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMediationReportSpec(od as api.MediationReportSpec);
    });
  });

  unittest.group('obj-schema-MediationReportSpecDimensionFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMediationReportSpecDimensionFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MediationReportSpecDimensionFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMediationReportSpecDimensionFilter(
          od as api.MediationReportSpecDimensionFilter);
    });
  });

  unittest.group('obj-schema-MediationReportSpecSortCondition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMediationReportSpecSortCondition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MediationReportSpecSortCondition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMediationReportSpecSortCondition(
          od as api.MediationReportSpecSortCondition);
    });
  });

  unittest.group('obj-schema-NetworkReportSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkReportSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkReportSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkReportSpec(od as api.NetworkReportSpec);
    });
  });

  unittest.group('obj-schema-NetworkReportSpecDimensionFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkReportSpecDimensionFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkReportSpecDimensionFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkReportSpecDimensionFilter(
          od as api.NetworkReportSpecDimensionFilter);
    });
  });

  unittest.group('obj-schema-NetworkReportSpecSortCondition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkReportSpecSortCondition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkReportSpecSortCondition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkReportSpecSortCondition(
          od as api.NetworkReportSpecSortCondition);
    });
  });

  unittest.group('obj-schema-PublisherAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublisherAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PublisherAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPublisherAccount(od as api.PublisherAccount);
    });
  });

  unittest.group('obj-schema-ReportFooter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportFooter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportFooter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportFooter(od as api.ReportFooter);
    });
  });

  unittest.group('obj-schema-ReportHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportHeader.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportHeader(od as api.ReportHeader);
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

  unittest.group('obj-schema-ReportRowDimensionValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRowDimensionValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRowDimensionValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRowDimensionValue(od as api.ReportRowDimensionValue);
    });
  });

  unittest.group('obj-schema-ReportRowMetricValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRowMetricValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRowMetricValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRowMetricValue(od as api.ReportRowMetricValue);
    });
  });

  unittest.group('obj-schema-ReportWarning', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportWarning();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportWarning.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportWarning(od as api.ReportWarning);
    });
  });

  unittest.group('obj-schema-StringList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStringList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.StringList.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStringList(od as api.StringList);
    });
  });

  unittest.group('resource-AccountsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdMobApi(mock).accounts;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildPublisherAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkPublisherAccount(response as api.PublisherAccount);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdMobApi(mock).accounts;
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/accounts"),
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
        var resp = convert.json.encode(buildListPublisherAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPublisherAccountsResponse(
          response as api.ListPublisherAccountsResponse);
    });
  });

  unittest.group('resource-AccountsAdUnitsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdMobApi(mock).accounts.adUnits;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildListAdUnitsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAdUnitsResponse(response as api.ListAdUnitsResponse);
    });
  });

  unittest.group('resource-AccountsAppsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdMobApi(mock).accounts.apps;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildListAppsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAppsResponse(response as api.ListAppsResponse);
    });
  });

  unittest.group('resource-AccountsMediationReportResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.AdMobApi(mock).accounts.mediationReport;
      var arg_request = buildGenerateMediationReportRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GenerateMediationReportRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGenerateMediationReportRequest(
            obj as api.GenerateMediationReportRequest);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildGenerateMediationReportResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.generate(arg_request, arg_parent, $fields: arg_$fields);
      checkGenerateMediationReportResponse(
          response as api.GenerateMediationReportResponse);
    });
  });

  unittest.group('resource-AccountsNetworkReportResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.AdMobApi(mock).accounts.networkReport;
      var arg_request = buildGenerateNetworkReportRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GenerateNetworkReportRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGenerateNetworkReportRequest(
            obj as api.GenerateNetworkReportRequest);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildGenerateNetworkReportResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.generate(arg_request, arg_parent, $fields: arg_$fields);
      checkGenerateNetworkReportResponse(
          response as api.GenerateNetworkReportResponse);
    });
  });
}

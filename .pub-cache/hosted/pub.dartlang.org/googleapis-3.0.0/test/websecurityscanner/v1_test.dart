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

import 'package:googleapis/websecurityscanner/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAuthentication = 0;
api.Authentication buildAuthentication() {
  var o = api.Authentication();
  buildCounterAuthentication++;
  if (buildCounterAuthentication < 3) {
    o.customAccount = buildCustomAccount();
    o.googleAccount = buildGoogleAccount();
    o.iapCredential = buildIapCredential();
  }
  buildCounterAuthentication--;
  return o;
}

void checkAuthentication(api.Authentication o) {
  buildCounterAuthentication++;
  if (buildCounterAuthentication < 3) {
    checkCustomAccount(o.customAccount! as api.CustomAccount);
    checkGoogleAccount(o.googleAccount! as api.GoogleAccount);
    checkIapCredential(o.iapCredential! as api.IapCredential);
  }
  buildCounterAuthentication--;
}

core.int buildCounterCrawledUrl = 0;
api.CrawledUrl buildCrawledUrl() {
  var o = api.CrawledUrl();
  buildCounterCrawledUrl++;
  if (buildCounterCrawledUrl < 3) {
    o.body = 'foo';
    o.httpMethod = 'foo';
    o.url = 'foo';
  }
  buildCounterCrawledUrl--;
  return o;
}

void checkCrawledUrl(api.CrawledUrl o) {
  buildCounterCrawledUrl++;
  if (buildCounterCrawledUrl < 3) {
    unittest.expect(
      o.body!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.httpMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterCrawledUrl--;
}

core.int buildCounterCustomAccount = 0;
api.CustomAccount buildCustomAccount() {
  var o = api.CustomAccount();
  buildCounterCustomAccount++;
  if (buildCounterCustomAccount < 3) {
    o.loginUrl = 'foo';
    o.password = 'foo';
    o.username = 'foo';
  }
  buildCounterCustomAccount--;
  return o;
}

void checkCustomAccount(api.CustomAccount o) {
  buildCounterCustomAccount++;
  if (buildCounterCustomAccount < 3) {
    unittest.expect(
      o.loginUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomAccount--;
}

core.int buildCounterEmpty = 0;
api.Empty buildEmpty() {
  var o = api.Empty();
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
  return o;
}

void checkEmpty(api.Empty o) {
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
}

core.int buildCounterFinding = 0;
api.Finding buildFinding() {
  var o = api.Finding();
  buildCounterFinding++;
  if (buildCounterFinding < 3) {
    o.body = 'foo';
    o.description = 'foo';
    o.finalUrl = 'foo';
    o.findingType = 'foo';
    o.form = buildForm();
    o.frameUrl = 'foo';
    o.fuzzedUrl = 'foo';
    o.httpMethod = 'foo';
    o.name = 'foo';
    o.outdatedLibrary = buildOutdatedLibrary();
    o.reproductionUrl = 'foo';
    o.severity = 'foo';
    o.trackingId = 'foo';
    o.violatingResource = buildViolatingResource();
    o.vulnerableHeaders = buildVulnerableHeaders();
    o.vulnerableParameters = buildVulnerableParameters();
    o.xss = buildXss();
  }
  buildCounterFinding--;
  return o;
}

void checkFinding(api.Finding o) {
  buildCounterFinding++;
  if (buildCounterFinding < 3) {
    unittest.expect(
      o.body!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.finalUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.findingType!,
      unittest.equals('foo'),
    );
    checkForm(o.form! as api.Form);
    unittest.expect(
      o.frameUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fuzzedUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.httpMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOutdatedLibrary(o.outdatedLibrary! as api.OutdatedLibrary);
    unittest.expect(
      o.reproductionUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.trackingId!,
      unittest.equals('foo'),
    );
    checkViolatingResource(o.violatingResource! as api.ViolatingResource);
    checkVulnerableHeaders(o.vulnerableHeaders! as api.VulnerableHeaders);
    checkVulnerableParameters(
        o.vulnerableParameters! as api.VulnerableParameters);
    checkXss(o.xss! as api.Xss);
  }
  buildCounterFinding--;
}

core.int buildCounterFindingTypeStats = 0;
api.FindingTypeStats buildFindingTypeStats() {
  var o = api.FindingTypeStats();
  buildCounterFindingTypeStats++;
  if (buildCounterFindingTypeStats < 3) {
    o.findingCount = 42;
    o.findingType = 'foo';
  }
  buildCounterFindingTypeStats--;
  return o;
}

void checkFindingTypeStats(api.FindingTypeStats o) {
  buildCounterFindingTypeStats++;
  if (buildCounterFindingTypeStats < 3) {
    unittest.expect(
      o.findingCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.findingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterFindingTypeStats--;
}

core.List<core.String> buildUnnamed213() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed213(core.List<core.String> o) {
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

core.int buildCounterForm = 0;
api.Form buildForm() {
  var o = api.Form();
  buildCounterForm++;
  if (buildCounterForm < 3) {
    o.actionUri = 'foo';
    o.fields = buildUnnamed213();
  }
  buildCounterForm--;
  return o;
}

void checkForm(api.Form o) {
  buildCounterForm++;
  if (buildCounterForm < 3) {
    unittest.expect(
      o.actionUri!,
      unittest.equals('foo'),
    );
    checkUnnamed213(o.fields!);
  }
  buildCounterForm--;
}

core.int buildCounterGoogleAccount = 0;
api.GoogleAccount buildGoogleAccount() {
  var o = api.GoogleAccount();
  buildCounterGoogleAccount++;
  if (buildCounterGoogleAccount < 3) {
    o.password = 'foo';
    o.username = 'foo';
  }
  buildCounterGoogleAccount--;
  return o;
}

void checkGoogleAccount(api.GoogleAccount o) {
  buildCounterGoogleAccount++;
  if (buildCounterGoogleAccount < 3) {
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAccount--;
}

core.int buildCounterHeader = 0;
api.Header buildHeader() {
  var o = api.Header();
  buildCounterHeader++;
  if (buildCounterHeader < 3) {
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterHeader--;
  return o;
}

void checkHeader(api.Header o) {
  buildCounterHeader++;
  if (buildCounterHeader < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterHeader--;
}

core.int buildCounterIapCredential = 0;
api.IapCredential buildIapCredential() {
  var o = api.IapCredential();
  buildCounterIapCredential++;
  if (buildCounterIapCredential < 3) {
    o.iapTestServiceAccountInfo = buildIapTestServiceAccountInfo();
  }
  buildCounterIapCredential--;
  return o;
}

void checkIapCredential(api.IapCredential o) {
  buildCounterIapCredential++;
  if (buildCounterIapCredential < 3) {
    checkIapTestServiceAccountInfo(
        o.iapTestServiceAccountInfo! as api.IapTestServiceAccountInfo);
  }
  buildCounterIapCredential--;
}

core.int buildCounterIapTestServiceAccountInfo = 0;
api.IapTestServiceAccountInfo buildIapTestServiceAccountInfo() {
  var o = api.IapTestServiceAccountInfo();
  buildCounterIapTestServiceAccountInfo++;
  if (buildCounterIapTestServiceAccountInfo < 3) {
    o.targetAudienceClientId = 'foo';
  }
  buildCounterIapTestServiceAccountInfo--;
  return o;
}

void checkIapTestServiceAccountInfo(api.IapTestServiceAccountInfo o) {
  buildCounterIapTestServiceAccountInfo++;
  if (buildCounterIapTestServiceAccountInfo < 3) {
    unittest.expect(
      o.targetAudienceClientId!,
      unittest.equals('foo'),
    );
  }
  buildCounterIapTestServiceAccountInfo--;
}

core.List<api.CrawledUrl> buildUnnamed214() {
  var o = <api.CrawledUrl>[];
  o.add(buildCrawledUrl());
  o.add(buildCrawledUrl());
  return o;
}

void checkUnnamed214(core.List<api.CrawledUrl> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCrawledUrl(o[0] as api.CrawledUrl);
  checkCrawledUrl(o[1] as api.CrawledUrl);
}

core.int buildCounterListCrawledUrlsResponse = 0;
api.ListCrawledUrlsResponse buildListCrawledUrlsResponse() {
  var o = api.ListCrawledUrlsResponse();
  buildCounterListCrawledUrlsResponse++;
  if (buildCounterListCrawledUrlsResponse < 3) {
    o.crawledUrls = buildUnnamed214();
    o.nextPageToken = 'foo';
  }
  buildCounterListCrawledUrlsResponse--;
  return o;
}

void checkListCrawledUrlsResponse(api.ListCrawledUrlsResponse o) {
  buildCounterListCrawledUrlsResponse++;
  if (buildCounterListCrawledUrlsResponse < 3) {
    checkUnnamed214(o.crawledUrls!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCrawledUrlsResponse--;
}

core.List<api.FindingTypeStats> buildUnnamed215() {
  var o = <api.FindingTypeStats>[];
  o.add(buildFindingTypeStats());
  o.add(buildFindingTypeStats());
  return o;
}

void checkUnnamed215(core.List<api.FindingTypeStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFindingTypeStats(o[0] as api.FindingTypeStats);
  checkFindingTypeStats(o[1] as api.FindingTypeStats);
}

core.int buildCounterListFindingTypeStatsResponse = 0;
api.ListFindingTypeStatsResponse buildListFindingTypeStatsResponse() {
  var o = api.ListFindingTypeStatsResponse();
  buildCounterListFindingTypeStatsResponse++;
  if (buildCounterListFindingTypeStatsResponse < 3) {
    o.findingTypeStats = buildUnnamed215();
  }
  buildCounterListFindingTypeStatsResponse--;
  return o;
}

void checkListFindingTypeStatsResponse(api.ListFindingTypeStatsResponse o) {
  buildCounterListFindingTypeStatsResponse++;
  if (buildCounterListFindingTypeStatsResponse < 3) {
    checkUnnamed215(o.findingTypeStats!);
  }
  buildCounterListFindingTypeStatsResponse--;
}

core.List<api.Finding> buildUnnamed216() {
  var o = <api.Finding>[];
  o.add(buildFinding());
  o.add(buildFinding());
  return o;
}

void checkUnnamed216(core.List<api.Finding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFinding(o[0] as api.Finding);
  checkFinding(o[1] as api.Finding);
}

core.int buildCounterListFindingsResponse = 0;
api.ListFindingsResponse buildListFindingsResponse() {
  var o = api.ListFindingsResponse();
  buildCounterListFindingsResponse++;
  if (buildCounterListFindingsResponse < 3) {
    o.findings = buildUnnamed216();
    o.nextPageToken = 'foo';
  }
  buildCounterListFindingsResponse--;
  return o;
}

void checkListFindingsResponse(api.ListFindingsResponse o) {
  buildCounterListFindingsResponse++;
  if (buildCounterListFindingsResponse < 3) {
    checkUnnamed216(o.findings!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListFindingsResponse--;
}

core.List<api.ScanConfig> buildUnnamed217() {
  var o = <api.ScanConfig>[];
  o.add(buildScanConfig());
  o.add(buildScanConfig());
  return o;
}

void checkUnnamed217(core.List<api.ScanConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkScanConfig(o[0] as api.ScanConfig);
  checkScanConfig(o[1] as api.ScanConfig);
}

core.int buildCounterListScanConfigsResponse = 0;
api.ListScanConfigsResponse buildListScanConfigsResponse() {
  var o = api.ListScanConfigsResponse();
  buildCounterListScanConfigsResponse++;
  if (buildCounterListScanConfigsResponse < 3) {
    o.nextPageToken = 'foo';
    o.scanConfigs = buildUnnamed217();
  }
  buildCounterListScanConfigsResponse--;
  return o;
}

void checkListScanConfigsResponse(api.ListScanConfigsResponse o) {
  buildCounterListScanConfigsResponse++;
  if (buildCounterListScanConfigsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed217(o.scanConfigs!);
  }
  buildCounterListScanConfigsResponse--;
}

core.List<api.ScanRun> buildUnnamed218() {
  var o = <api.ScanRun>[];
  o.add(buildScanRun());
  o.add(buildScanRun());
  return o;
}

void checkUnnamed218(core.List<api.ScanRun> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkScanRun(o[0] as api.ScanRun);
  checkScanRun(o[1] as api.ScanRun);
}

core.int buildCounterListScanRunsResponse = 0;
api.ListScanRunsResponse buildListScanRunsResponse() {
  var o = api.ListScanRunsResponse();
  buildCounterListScanRunsResponse++;
  if (buildCounterListScanRunsResponse < 3) {
    o.nextPageToken = 'foo';
    o.scanRuns = buildUnnamed218();
  }
  buildCounterListScanRunsResponse--;
  return o;
}

void checkListScanRunsResponse(api.ListScanRunsResponse o) {
  buildCounterListScanRunsResponse++;
  if (buildCounterListScanRunsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed218(o.scanRuns!);
  }
  buildCounterListScanRunsResponse--;
}

core.List<core.String> buildUnnamed219() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed219(core.List<core.String> o) {
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

core.int buildCounterOutdatedLibrary = 0;
api.OutdatedLibrary buildOutdatedLibrary() {
  var o = api.OutdatedLibrary();
  buildCounterOutdatedLibrary++;
  if (buildCounterOutdatedLibrary < 3) {
    o.learnMoreUrls = buildUnnamed219();
    o.libraryName = 'foo';
    o.version = 'foo';
  }
  buildCounterOutdatedLibrary--;
  return o;
}

void checkOutdatedLibrary(api.OutdatedLibrary o) {
  buildCounterOutdatedLibrary++;
  if (buildCounterOutdatedLibrary < 3) {
    checkUnnamed219(o.learnMoreUrls!);
    unittest.expect(
      o.libraryName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterOutdatedLibrary--;
}

core.List<core.String> buildUnnamed220() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed220(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed221() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed221(core.List<core.String> o) {
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

core.int buildCounterScanConfig = 0;
api.ScanConfig buildScanConfig() {
  var o = api.ScanConfig();
  buildCounterScanConfig++;
  if (buildCounterScanConfig < 3) {
    o.authentication = buildAuthentication();
    o.blacklistPatterns = buildUnnamed220();
    o.displayName = 'foo';
    o.exportToSecurityCommandCenter = 'foo';
    o.ignoreHttpStatusErrors = true;
    o.managedScan = true;
    o.maxQps = 42;
    o.name = 'foo';
    o.riskLevel = 'foo';
    o.schedule = buildSchedule();
    o.startingUrls = buildUnnamed221();
    o.staticIpScan = true;
    o.userAgent = 'foo';
  }
  buildCounterScanConfig--;
  return o;
}

void checkScanConfig(api.ScanConfig o) {
  buildCounterScanConfig++;
  if (buildCounterScanConfig < 3) {
    checkAuthentication(o.authentication! as api.Authentication);
    checkUnnamed220(o.blacklistPatterns!);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.exportToSecurityCommandCenter!,
      unittest.equals('foo'),
    );
    unittest.expect(o.ignoreHttpStatusErrors!, unittest.isTrue);
    unittest.expect(o.managedScan!, unittest.isTrue);
    unittest.expect(
      o.maxQps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.riskLevel!,
      unittest.equals('foo'),
    );
    checkSchedule(o.schedule! as api.Schedule);
    checkUnnamed221(o.startingUrls!);
    unittest.expect(o.staticIpScan!, unittest.isTrue);
    unittest.expect(
      o.userAgent!,
      unittest.equals('foo'),
    );
  }
  buildCounterScanConfig--;
}

core.int buildCounterScanConfigError = 0;
api.ScanConfigError buildScanConfigError() {
  var o = api.ScanConfigError();
  buildCounterScanConfigError++;
  if (buildCounterScanConfigError < 3) {
    o.code = 'foo';
    o.fieldName = 'foo';
  }
  buildCounterScanConfigError--;
  return o;
}

void checkScanConfigError(api.ScanConfigError o) {
  buildCounterScanConfigError++;
  if (buildCounterScanConfigError < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldName!,
      unittest.equals('foo'),
    );
  }
  buildCounterScanConfigError--;
}

core.List<api.ScanRunWarningTrace> buildUnnamed222() {
  var o = <api.ScanRunWarningTrace>[];
  o.add(buildScanRunWarningTrace());
  o.add(buildScanRunWarningTrace());
  return o;
}

void checkUnnamed222(core.List<api.ScanRunWarningTrace> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkScanRunWarningTrace(o[0] as api.ScanRunWarningTrace);
  checkScanRunWarningTrace(o[1] as api.ScanRunWarningTrace);
}

core.int buildCounterScanRun = 0;
api.ScanRun buildScanRun() {
  var o = api.ScanRun();
  buildCounterScanRun++;
  if (buildCounterScanRun < 3) {
    o.endTime = 'foo';
    o.errorTrace = buildScanRunErrorTrace();
    o.executionState = 'foo';
    o.hasVulnerabilities = true;
    o.name = 'foo';
    o.progressPercent = 42;
    o.resultState = 'foo';
    o.startTime = 'foo';
    o.urlsCrawledCount = 'foo';
    o.urlsTestedCount = 'foo';
    o.warningTraces = buildUnnamed222();
  }
  buildCounterScanRun--;
  return o;
}

void checkScanRun(api.ScanRun o) {
  buildCounterScanRun++;
  if (buildCounterScanRun < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkScanRunErrorTrace(o.errorTrace! as api.ScanRunErrorTrace);
    unittest.expect(
      o.executionState!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hasVulnerabilities!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    unittest.expect(
      o.resultState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.urlsCrawledCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.urlsTestedCount!,
      unittest.equals('foo'),
    );
    checkUnnamed222(o.warningTraces!);
  }
  buildCounterScanRun--;
}

core.int buildCounterScanRunErrorTrace = 0;
api.ScanRunErrorTrace buildScanRunErrorTrace() {
  var o = api.ScanRunErrorTrace();
  buildCounterScanRunErrorTrace++;
  if (buildCounterScanRunErrorTrace < 3) {
    o.code = 'foo';
    o.mostCommonHttpErrorCode = 42;
    o.scanConfigError = buildScanConfigError();
  }
  buildCounterScanRunErrorTrace--;
  return o;
}

void checkScanRunErrorTrace(api.ScanRunErrorTrace o) {
  buildCounterScanRunErrorTrace++;
  if (buildCounterScanRunErrorTrace < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mostCommonHttpErrorCode!,
      unittest.equals(42),
    );
    checkScanConfigError(o.scanConfigError! as api.ScanConfigError);
  }
  buildCounterScanRunErrorTrace--;
}

core.int buildCounterScanRunWarningTrace = 0;
api.ScanRunWarningTrace buildScanRunWarningTrace() {
  var o = api.ScanRunWarningTrace();
  buildCounterScanRunWarningTrace++;
  if (buildCounterScanRunWarningTrace < 3) {
    o.code = 'foo';
  }
  buildCounterScanRunWarningTrace--;
  return o;
}

void checkScanRunWarningTrace(api.ScanRunWarningTrace o) {
  buildCounterScanRunWarningTrace++;
  if (buildCounterScanRunWarningTrace < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
  }
  buildCounterScanRunWarningTrace--;
}

core.int buildCounterSchedule = 0;
api.Schedule buildSchedule() {
  var o = api.Schedule();
  buildCounterSchedule++;
  if (buildCounterSchedule < 3) {
    o.intervalDurationDays = 42;
    o.scheduleTime = 'foo';
  }
  buildCounterSchedule--;
  return o;
}

void checkSchedule(api.Schedule o) {
  buildCounterSchedule++;
  if (buildCounterSchedule < 3) {
    unittest.expect(
      o.intervalDurationDays!,
      unittest.equals(42),
    );
    unittest.expect(
      o.scheduleTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchedule--;
}

core.int buildCounterStartScanRunRequest = 0;
api.StartScanRunRequest buildStartScanRunRequest() {
  var o = api.StartScanRunRequest();
  buildCounterStartScanRunRequest++;
  if (buildCounterStartScanRunRequest < 3) {}
  buildCounterStartScanRunRequest--;
  return o;
}

void checkStartScanRunRequest(api.StartScanRunRequest o) {
  buildCounterStartScanRunRequest++;
  if (buildCounterStartScanRunRequest < 3) {}
  buildCounterStartScanRunRequest--;
}

core.int buildCounterStopScanRunRequest = 0;
api.StopScanRunRequest buildStopScanRunRequest() {
  var o = api.StopScanRunRequest();
  buildCounterStopScanRunRequest++;
  if (buildCounterStopScanRunRequest < 3) {}
  buildCounterStopScanRunRequest--;
  return o;
}

void checkStopScanRunRequest(api.StopScanRunRequest o) {
  buildCounterStopScanRunRequest++;
  if (buildCounterStopScanRunRequest < 3) {}
  buildCounterStopScanRunRequest--;
}

core.int buildCounterViolatingResource = 0;
api.ViolatingResource buildViolatingResource() {
  var o = api.ViolatingResource();
  buildCounterViolatingResource++;
  if (buildCounterViolatingResource < 3) {
    o.contentType = 'foo';
    o.resourceUrl = 'foo';
  }
  buildCounterViolatingResource--;
  return o;
}

void checkViolatingResource(api.ViolatingResource o) {
  buildCounterViolatingResource++;
  if (buildCounterViolatingResource < 3) {
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterViolatingResource--;
}

core.List<api.Header> buildUnnamed223() {
  var o = <api.Header>[];
  o.add(buildHeader());
  o.add(buildHeader());
  return o;
}

void checkUnnamed223(core.List<api.Header> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHeader(o[0] as api.Header);
  checkHeader(o[1] as api.Header);
}

core.List<api.Header> buildUnnamed224() {
  var o = <api.Header>[];
  o.add(buildHeader());
  o.add(buildHeader());
  return o;
}

void checkUnnamed224(core.List<api.Header> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHeader(o[0] as api.Header);
  checkHeader(o[1] as api.Header);
}

core.int buildCounterVulnerableHeaders = 0;
api.VulnerableHeaders buildVulnerableHeaders() {
  var o = api.VulnerableHeaders();
  buildCounterVulnerableHeaders++;
  if (buildCounterVulnerableHeaders < 3) {
    o.headers = buildUnnamed223();
    o.missingHeaders = buildUnnamed224();
  }
  buildCounterVulnerableHeaders--;
  return o;
}

void checkVulnerableHeaders(api.VulnerableHeaders o) {
  buildCounterVulnerableHeaders++;
  if (buildCounterVulnerableHeaders < 3) {
    checkUnnamed223(o.headers!);
    checkUnnamed224(o.missingHeaders!);
  }
  buildCounterVulnerableHeaders--;
}

core.List<core.String> buildUnnamed225() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed225(core.List<core.String> o) {
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

core.int buildCounterVulnerableParameters = 0;
api.VulnerableParameters buildVulnerableParameters() {
  var o = api.VulnerableParameters();
  buildCounterVulnerableParameters++;
  if (buildCounterVulnerableParameters < 3) {
    o.parameterNames = buildUnnamed225();
  }
  buildCounterVulnerableParameters--;
  return o;
}

void checkVulnerableParameters(api.VulnerableParameters o) {
  buildCounterVulnerableParameters++;
  if (buildCounterVulnerableParameters < 3) {
    checkUnnamed225(o.parameterNames!);
  }
  buildCounterVulnerableParameters--;
}

core.List<core.String> buildUnnamed226() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed226(core.List<core.String> o) {
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

core.int buildCounterXss = 0;
api.Xss buildXss() {
  var o = api.Xss();
  buildCounterXss++;
  if (buildCounterXss < 3) {
    o.attackVector = 'foo';
    o.errorMessage = 'foo';
    o.stackTraces = buildUnnamed226();
    o.storedXssSeedingUrl = 'foo';
  }
  buildCounterXss--;
  return o;
}

void checkXss(api.Xss o) {
  buildCounterXss++;
  if (buildCounterXss < 3) {
    unittest.expect(
      o.attackVector!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    checkUnnamed226(o.stackTraces!);
    unittest.expect(
      o.storedXssSeedingUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterXss--;
}

void main() {
  unittest.group('obj-schema-Authentication', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthentication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Authentication.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuthentication(od as api.Authentication);
    });
  });

  unittest.group('obj-schema-CrawledUrl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCrawledUrl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CrawledUrl.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCrawledUrl(od as api.CrawledUrl);
    });
  });

  unittest.group('obj-schema-CustomAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomAccount(od as api.CustomAccount);
    });
  });

  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-Finding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Finding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFinding(od as api.Finding);
    });
  });

  unittest.group('obj-schema-FindingTypeStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFindingTypeStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FindingTypeStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFindingTypeStats(od as api.FindingTypeStats);
    });
  });

  unittest.group('obj-schema-Form', () {
    unittest.test('to-json--from-json', () async {
      var o = buildForm();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Form.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkForm(od as api.Form);
    });
  });

  unittest.group('obj-schema-GoogleAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAccount(od as api.GoogleAccount);
    });
  });

  unittest.group('obj-schema-Header', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Header.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHeader(od as api.Header);
    });
  });

  unittest.group('obj-schema-IapCredential', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIapCredential();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IapCredential.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIapCredential(od as api.IapCredential);
    });
  });

  unittest.group('obj-schema-IapTestServiceAccountInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIapTestServiceAccountInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IapTestServiceAccountInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIapTestServiceAccountInfo(od as api.IapTestServiceAccountInfo);
    });
  });

  unittest.group('obj-schema-ListCrawledUrlsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCrawledUrlsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCrawledUrlsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCrawledUrlsResponse(od as api.ListCrawledUrlsResponse);
    });
  });

  unittest.group('obj-schema-ListFindingTypeStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFindingTypeStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFindingTypeStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFindingTypeStatsResponse(od as api.ListFindingTypeStatsResponse);
    });
  });

  unittest.group('obj-schema-ListFindingsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFindingsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFindingsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFindingsResponse(od as api.ListFindingsResponse);
    });
  });

  unittest.group('obj-schema-ListScanConfigsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListScanConfigsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListScanConfigsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListScanConfigsResponse(od as api.ListScanConfigsResponse);
    });
  });

  unittest.group('obj-schema-ListScanRunsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListScanRunsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListScanRunsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListScanRunsResponse(od as api.ListScanRunsResponse);
    });
  });

  unittest.group('obj-schema-OutdatedLibrary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOutdatedLibrary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OutdatedLibrary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOutdatedLibrary(od as api.OutdatedLibrary);
    });
  });

  unittest.group('obj-schema-ScanConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScanConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ScanConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkScanConfig(od as api.ScanConfig);
    });
  });

  unittest.group('obj-schema-ScanConfigError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScanConfigError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScanConfigError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScanConfigError(od as api.ScanConfigError);
    });
  });

  unittest.group('obj-schema-ScanRun', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScanRun();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ScanRun.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkScanRun(od as api.ScanRun);
    });
  });

  unittest.group('obj-schema-ScanRunErrorTrace', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScanRunErrorTrace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScanRunErrorTrace.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScanRunErrorTrace(od as api.ScanRunErrorTrace);
    });
  });

  unittest.group('obj-schema-ScanRunWarningTrace', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScanRunWarningTrace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScanRunWarningTrace.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScanRunWarningTrace(od as api.ScanRunWarningTrace);
    });
  });

  unittest.group('obj-schema-Schedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Schedule.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSchedule(od as api.Schedule);
    });
  });

  unittest.group('obj-schema-StartScanRunRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStartScanRunRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StartScanRunRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStartScanRunRequest(od as api.StartScanRunRequest);
    });
  });

  unittest.group('obj-schema-StopScanRunRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStopScanRunRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StopScanRunRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStopScanRunRequest(od as api.StopScanRunRequest);
    });
  });

  unittest.group('obj-schema-ViolatingResource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildViolatingResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ViolatingResource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkViolatingResource(od as api.ViolatingResource);
    });
  });

  unittest.group('obj-schema-VulnerableHeaders', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVulnerableHeaders();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VulnerableHeaders.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVulnerableHeaders(od as api.VulnerableHeaders);
    });
  });

  unittest.group('obj-schema-VulnerableParameters', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVulnerableParameters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VulnerableParameters.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVulnerableParameters(od as api.VulnerableParameters);
    });
  });

  unittest.group('obj-schema-Xss', () {
    unittest.test('to-json--from-json', () async {
      var o = buildXss();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Xss.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkXss(od as api.Xss);
    });
  });

  unittest.group('resource-ProjectsScanConfigsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs;
      var arg_request = buildScanConfig();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ScanConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkScanConfig(obj as api.ScanConfig);

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
        var resp = convert.json.encode(buildScanConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkScanConfig(response as api.ScanConfig);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs;
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs;
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
        var resp = convert.json.encode(buildScanConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkScanConfig(response as api.ScanConfig);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs;
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
        var resp = convert.json.encode(buildListScanConfigsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListScanConfigsResponse(response as api.ListScanConfigsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs;
      var arg_request = buildScanConfig();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ScanConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkScanConfig(obj as api.ScanConfig);

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildScanConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkScanConfig(response as api.ScanConfig);
    });

    unittest.test('method--start', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs;
      var arg_request = buildStartScanRunRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StartScanRunRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStartScanRunRequest(obj as api.StartScanRunRequest);

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
        var resp = convert.json.encode(buildScanRun());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.start(arg_request, arg_name, $fields: arg_$fields);
      checkScanRun(response as api.ScanRun);
    });
  });

  unittest.group('resource-ProjectsScanConfigsScanRunsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs.scanRuns;
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
        var resp = convert.json.encode(buildScanRun());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkScanRun(response as api.ScanRun);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs.scanRuns;
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
        var resp = convert.json.encode(buildListScanRunsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListScanRunsResponse(response as api.ListScanRunsResponse);
    });

    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock).projects.scanConfigs.scanRuns;
      var arg_request = buildStopScanRunRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StopScanRunRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStopScanRunRequest(obj as api.StopScanRunRequest);

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
        var resp = convert.json.encode(buildScanRun());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.stop(arg_request, arg_name, $fields: arg_$fields);
      checkScanRun(response as api.ScanRun);
    });
  });

  unittest.group('resource-ProjectsScanConfigsScanRunsCrawledUrlsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock)
          .projects
          .scanConfigs
          .scanRuns
          .crawledUrls;
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
        var resp = convert.json.encode(buildListCrawledUrlsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCrawledUrlsResponse(response as api.ListCrawledUrlsResponse);
    });
  });

  unittest.group('resource-ProjectsScanConfigsScanRunsFindingTypeStatsResource',
      () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock)
          .projects
          .scanConfigs
          .scanRuns
          .findingTypeStats;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListFindingTypeStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkListFindingTypeStatsResponse(
          response as api.ListFindingTypeStatsResponse);
    });
  });

  unittest.group('resource-ProjectsScanConfigsScanRunsFindingsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock)
          .projects
          .scanConfigs
          .scanRuns
          .findings;
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
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.WebSecurityScannerApi(mock)
          .projects
          .scanConfigs
          .scanRuns
          .findings;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
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
        var resp = convert.json.encode(buildListFindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListFindingsResponse(response as api.ListFindingsResponse);
    });
  });
}

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

import 'package:googleapis/adsense/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed83() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed83(core.List<core.String> o) {
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

core.int buildCounterAccount = 0;
api.Account buildAccount() {
  var o = api.Account();
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    o.createTime = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
    o.pendingTasks = buildUnnamed83();
    o.premium = true;
    o.timeZone = buildTimeZone();
  }
  buildCounterAccount--;
  return o;
}

void checkAccount(api.Account o) {
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    unittest.expect(
      o.createTime!,
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
    checkUnnamed83(o.pendingTasks!);
    unittest.expect(o.premium!, unittest.isTrue);
    checkTimeZone(o.timeZone! as api.TimeZone);
  }
  buildCounterAccount--;
}

core.int buildCounterAdClient = 0;
api.AdClient buildAdClient() {
  var o = api.AdClient();
  buildCounterAdClient++;
  if (buildCounterAdClient < 3) {
    o.name = 'foo';
    o.productCode = 'foo';
    o.reportingDimensionId = 'foo';
  }
  buildCounterAdClient--;
  return o;
}

void checkAdClient(api.AdClient o) {
  buildCounterAdClient++;
  if (buildCounterAdClient < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingDimensionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdClient--;
}

core.int buildCounterAdClientAdCode = 0;
api.AdClientAdCode buildAdClientAdCode() {
  var o = api.AdClientAdCode();
  buildCounterAdClientAdCode++;
  if (buildCounterAdClientAdCode < 3) {
    o.adCode = 'foo';
    o.ampBody = 'foo';
    o.ampHead = 'foo';
  }
  buildCounterAdClientAdCode--;
  return o;
}

void checkAdClientAdCode(api.AdClientAdCode o) {
  buildCounterAdClientAdCode++;
  if (buildCounterAdClientAdCode < 3) {
    unittest.expect(
      o.adCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ampBody!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ampHead!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdClientAdCode--;
}

core.int buildCounterAdUnit = 0;
api.AdUnit buildAdUnit() {
  var o = api.AdUnit();
  buildCounterAdUnit++;
  if (buildCounterAdUnit < 3) {
    o.contentAdsSettings = buildContentAdsSettings();
    o.displayName = 'foo';
    o.name = 'foo';
    o.reportingDimensionId = 'foo';
    o.state = 'foo';
  }
  buildCounterAdUnit--;
  return o;
}

void checkAdUnit(api.AdUnit o) {
  buildCounterAdUnit++;
  if (buildCounterAdUnit < 3) {
    checkContentAdsSettings(o.contentAdsSettings! as api.ContentAdsSettings);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingDimensionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnit--;
}

core.int buildCounterAdUnitAdCode = 0;
api.AdUnitAdCode buildAdUnitAdCode() {
  var o = api.AdUnitAdCode();
  buildCounterAdUnitAdCode++;
  if (buildCounterAdUnitAdCode < 3) {
    o.adCode = 'foo';
  }
  buildCounterAdUnitAdCode--;
  return o;
}

void checkAdUnitAdCode(api.AdUnitAdCode o) {
  buildCounterAdUnitAdCode++;
  if (buildCounterAdUnitAdCode < 3) {
    unittest.expect(
      o.adCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnitAdCode--;
}

core.int buildCounterAlert = 0;
api.Alert buildAlert() {
  var o = api.Alert();
  buildCounterAlert++;
  if (buildCounterAlert < 3) {
    o.message = 'foo';
    o.name = 'foo';
    o.severity = 'foo';
    o.type = 'foo';
  }
  buildCounterAlert--;
  return o;
}

void checkAlert(api.Alert o) {
  buildCounterAlert++;
  if (buildCounterAlert < 3) {
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAlert--;
}

core.int buildCounterCell = 0;
api.Cell buildCell() {
  var o = api.Cell();
  buildCounterCell++;
  if (buildCounterCell < 3) {
    o.value = 'foo';
  }
  buildCounterCell--;
  return o;
}

void checkCell(api.Cell o) {
  buildCounterCell++;
  if (buildCounterCell < 3) {
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterCell--;
}

core.int buildCounterContentAdsSettings = 0;
api.ContentAdsSettings buildContentAdsSettings() {
  var o = api.ContentAdsSettings();
  buildCounterContentAdsSettings++;
  if (buildCounterContentAdsSettings < 3) {
    o.size = 'foo';
    o.type = 'foo';
  }
  buildCounterContentAdsSettings--;
  return o;
}

void checkContentAdsSettings(api.ContentAdsSettings o) {
  buildCounterContentAdsSettings++;
  if (buildCounterContentAdsSettings < 3) {
    unittest.expect(
      o.size!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterContentAdsSettings--;
}

core.int buildCounterCustomChannel = 0;
api.CustomChannel buildCustomChannel() {
  var o = api.CustomChannel();
  buildCounterCustomChannel++;
  if (buildCounterCustomChannel < 3) {
    o.displayName = 'foo';
    o.name = 'foo';
    o.reportingDimensionId = 'foo';
  }
  buildCounterCustomChannel--;
  return o;
}

void checkCustomChannel(api.CustomChannel o) {
  buildCounterCustomChannel++;
  if (buildCounterCustomChannel < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingDimensionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomChannel--;
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

core.int buildCounterHeader = 0;
api.Header buildHeader() {
  var o = api.Header();
  buildCounterHeader++;
  if (buildCounterHeader < 3) {
    o.currencyCode = 'foo';
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterHeader--;
  return o;
}

void checkHeader(api.Header o) {
  buildCounterHeader++;
  if (buildCounterHeader < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterHeader--;
}

core.Map<core.String, core.Object> buildUnnamed84() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed84(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o['x']!) as core.Map;
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
  var casted2 = (o['y']!) as core.Map;
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

core.List<core.Map<core.String, core.Object>> buildUnnamed85() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed84());
  o.add(buildUnnamed84());
  return o;
}

void checkUnnamed85(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed84(o[0]);
  checkUnnamed84(o[1]);
}

core.int buildCounterHttpBody = 0;
api.HttpBody buildHttpBody() {
  var o = api.HttpBody();
  buildCounterHttpBody++;
  if (buildCounterHttpBody < 3) {
    o.contentType = 'foo';
    o.data = 'foo';
    o.extensions = buildUnnamed85();
  }
  buildCounterHttpBody--;
  return o;
}

void checkHttpBody(api.HttpBody o) {
  buildCounterHttpBody++;
  if (buildCounterHttpBody < 3) {
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    checkUnnamed85(o.extensions!);
  }
  buildCounterHttpBody--;
}

core.List<api.Account> buildUnnamed86() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed86(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterListAccountsResponse = 0;
api.ListAccountsResponse buildListAccountsResponse() {
  var o = api.ListAccountsResponse();
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    o.accounts = buildUnnamed86();
    o.nextPageToken = 'foo';
  }
  buildCounterListAccountsResponse--;
  return o;
}

void checkListAccountsResponse(api.ListAccountsResponse o) {
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    checkUnnamed86(o.accounts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAccountsResponse--;
}

core.List<api.AdClient> buildUnnamed87() {
  var o = <api.AdClient>[];
  o.add(buildAdClient());
  o.add(buildAdClient());
  return o;
}

void checkUnnamed87(core.List<api.AdClient> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdClient(o[0] as api.AdClient);
  checkAdClient(o[1] as api.AdClient);
}

core.int buildCounterListAdClientsResponse = 0;
api.ListAdClientsResponse buildListAdClientsResponse() {
  var o = api.ListAdClientsResponse();
  buildCounterListAdClientsResponse++;
  if (buildCounterListAdClientsResponse < 3) {
    o.adClients = buildUnnamed87();
    o.nextPageToken = 'foo';
  }
  buildCounterListAdClientsResponse--;
  return o;
}

void checkListAdClientsResponse(api.ListAdClientsResponse o) {
  buildCounterListAdClientsResponse++;
  if (buildCounterListAdClientsResponse < 3) {
    checkUnnamed87(o.adClients!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAdClientsResponse--;
}

core.List<api.AdUnit> buildUnnamed88() {
  var o = <api.AdUnit>[];
  o.add(buildAdUnit());
  o.add(buildAdUnit());
  return o;
}

void checkUnnamed88(core.List<api.AdUnit> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdUnit(o[0] as api.AdUnit);
  checkAdUnit(o[1] as api.AdUnit);
}

core.int buildCounterListAdUnitsResponse = 0;
api.ListAdUnitsResponse buildListAdUnitsResponse() {
  var o = api.ListAdUnitsResponse();
  buildCounterListAdUnitsResponse++;
  if (buildCounterListAdUnitsResponse < 3) {
    o.adUnits = buildUnnamed88();
    o.nextPageToken = 'foo';
  }
  buildCounterListAdUnitsResponse--;
  return o;
}

void checkListAdUnitsResponse(api.ListAdUnitsResponse o) {
  buildCounterListAdUnitsResponse++;
  if (buildCounterListAdUnitsResponse < 3) {
    checkUnnamed88(o.adUnits!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAdUnitsResponse--;
}

core.List<api.Alert> buildUnnamed89() {
  var o = <api.Alert>[];
  o.add(buildAlert());
  o.add(buildAlert());
  return o;
}

void checkUnnamed89(core.List<api.Alert> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAlert(o[0] as api.Alert);
  checkAlert(o[1] as api.Alert);
}

core.int buildCounterListAlertsResponse = 0;
api.ListAlertsResponse buildListAlertsResponse() {
  var o = api.ListAlertsResponse();
  buildCounterListAlertsResponse++;
  if (buildCounterListAlertsResponse < 3) {
    o.alerts = buildUnnamed89();
  }
  buildCounterListAlertsResponse--;
  return o;
}

void checkListAlertsResponse(api.ListAlertsResponse o) {
  buildCounterListAlertsResponse++;
  if (buildCounterListAlertsResponse < 3) {
    checkUnnamed89(o.alerts!);
  }
  buildCounterListAlertsResponse--;
}

core.List<api.Account> buildUnnamed90() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed90(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterListChildAccountsResponse = 0;
api.ListChildAccountsResponse buildListChildAccountsResponse() {
  var o = api.ListChildAccountsResponse();
  buildCounterListChildAccountsResponse++;
  if (buildCounterListChildAccountsResponse < 3) {
    o.accounts = buildUnnamed90();
    o.nextPageToken = 'foo';
  }
  buildCounterListChildAccountsResponse--;
  return o;
}

void checkListChildAccountsResponse(api.ListChildAccountsResponse o) {
  buildCounterListChildAccountsResponse++;
  if (buildCounterListChildAccountsResponse < 3) {
    checkUnnamed90(o.accounts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListChildAccountsResponse--;
}

core.List<api.CustomChannel> buildUnnamed91() {
  var o = <api.CustomChannel>[];
  o.add(buildCustomChannel());
  o.add(buildCustomChannel());
  return o;
}

void checkUnnamed91(core.List<api.CustomChannel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomChannel(o[0] as api.CustomChannel);
  checkCustomChannel(o[1] as api.CustomChannel);
}

core.int buildCounterListCustomChannelsResponse = 0;
api.ListCustomChannelsResponse buildListCustomChannelsResponse() {
  var o = api.ListCustomChannelsResponse();
  buildCounterListCustomChannelsResponse++;
  if (buildCounterListCustomChannelsResponse < 3) {
    o.customChannels = buildUnnamed91();
    o.nextPageToken = 'foo';
  }
  buildCounterListCustomChannelsResponse--;
  return o;
}

void checkListCustomChannelsResponse(api.ListCustomChannelsResponse o) {
  buildCounterListCustomChannelsResponse++;
  if (buildCounterListCustomChannelsResponse < 3) {
    checkUnnamed91(o.customChannels!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCustomChannelsResponse--;
}

core.List<api.AdUnit> buildUnnamed92() {
  var o = <api.AdUnit>[];
  o.add(buildAdUnit());
  o.add(buildAdUnit());
  return o;
}

void checkUnnamed92(core.List<api.AdUnit> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdUnit(o[0] as api.AdUnit);
  checkAdUnit(o[1] as api.AdUnit);
}

core.int buildCounterListLinkedAdUnitsResponse = 0;
api.ListLinkedAdUnitsResponse buildListLinkedAdUnitsResponse() {
  var o = api.ListLinkedAdUnitsResponse();
  buildCounterListLinkedAdUnitsResponse++;
  if (buildCounterListLinkedAdUnitsResponse < 3) {
    o.adUnits = buildUnnamed92();
    o.nextPageToken = 'foo';
  }
  buildCounterListLinkedAdUnitsResponse--;
  return o;
}

void checkListLinkedAdUnitsResponse(api.ListLinkedAdUnitsResponse o) {
  buildCounterListLinkedAdUnitsResponse++;
  if (buildCounterListLinkedAdUnitsResponse < 3) {
    checkUnnamed92(o.adUnits!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLinkedAdUnitsResponse--;
}

core.List<api.CustomChannel> buildUnnamed93() {
  var o = <api.CustomChannel>[];
  o.add(buildCustomChannel());
  o.add(buildCustomChannel());
  return o;
}

void checkUnnamed93(core.List<api.CustomChannel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomChannel(o[0] as api.CustomChannel);
  checkCustomChannel(o[1] as api.CustomChannel);
}

core.int buildCounterListLinkedCustomChannelsResponse = 0;
api.ListLinkedCustomChannelsResponse buildListLinkedCustomChannelsResponse() {
  var o = api.ListLinkedCustomChannelsResponse();
  buildCounterListLinkedCustomChannelsResponse++;
  if (buildCounterListLinkedCustomChannelsResponse < 3) {
    o.customChannels = buildUnnamed93();
    o.nextPageToken = 'foo';
  }
  buildCounterListLinkedCustomChannelsResponse--;
  return o;
}

void checkListLinkedCustomChannelsResponse(
    api.ListLinkedCustomChannelsResponse o) {
  buildCounterListLinkedCustomChannelsResponse++;
  if (buildCounterListLinkedCustomChannelsResponse < 3) {
    checkUnnamed93(o.customChannels!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLinkedCustomChannelsResponse--;
}

core.List<api.Payment> buildUnnamed94() {
  var o = <api.Payment>[];
  o.add(buildPayment());
  o.add(buildPayment());
  return o;
}

void checkUnnamed94(core.List<api.Payment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPayment(o[0] as api.Payment);
  checkPayment(o[1] as api.Payment);
}

core.int buildCounterListPaymentsResponse = 0;
api.ListPaymentsResponse buildListPaymentsResponse() {
  var o = api.ListPaymentsResponse();
  buildCounterListPaymentsResponse++;
  if (buildCounterListPaymentsResponse < 3) {
    o.payments = buildUnnamed94();
  }
  buildCounterListPaymentsResponse--;
  return o;
}

void checkListPaymentsResponse(api.ListPaymentsResponse o) {
  buildCounterListPaymentsResponse++;
  if (buildCounterListPaymentsResponse < 3) {
    checkUnnamed94(o.payments!);
  }
  buildCounterListPaymentsResponse--;
}

core.List<api.SavedReport> buildUnnamed95() {
  var o = <api.SavedReport>[];
  o.add(buildSavedReport());
  o.add(buildSavedReport());
  return o;
}

void checkUnnamed95(core.List<api.SavedReport> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSavedReport(o[0] as api.SavedReport);
  checkSavedReport(o[1] as api.SavedReport);
}

core.int buildCounterListSavedReportsResponse = 0;
api.ListSavedReportsResponse buildListSavedReportsResponse() {
  var o = api.ListSavedReportsResponse();
  buildCounterListSavedReportsResponse++;
  if (buildCounterListSavedReportsResponse < 3) {
    o.nextPageToken = 'foo';
    o.savedReports = buildUnnamed95();
  }
  buildCounterListSavedReportsResponse--;
  return o;
}

void checkListSavedReportsResponse(api.ListSavedReportsResponse o) {
  buildCounterListSavedReportsResponse++;
  if (buildCounterListSavedReportsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed95(o.savedReports!);
  }
  buildCounterListSavedReportsResponse--;
}

core.List<api.Site> buildUnnamed96() {
  var o = <api.Site>[];
  o.add(buildSite());
  o.add(buildSite());
  return o;
}

void checkUnnamed96(core.List<api.Site> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSite(o[0] as api.Site);
  checkSite(o[1] as api.Site);
}

core.int buildCounterListSitesResponse = 0;
api.ListSitesResponse buildListSitesResponse() {
  var o = api.ListSitesResponse();
  buildCounterListSitesResponse++;
  if (buildCounterListSitesResponse < 3) {
    o.nextPageToken = 'foo';
    o.sites = buildUnnamed96();
  }
  buildCounterListSitesResponse--;
  return o;
}

void checkListSitesResponse(api.ListSitesResponse o) {
  buildCounterListSitesResponse++;
  if (buildCounterListSitesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed96(o.sites!);
  }
  buildCounterListSitesResponse--;
}

core.List<api.UrlChannel> buildUnnamed97() {
  var o = <api.UrlChannel>[];
  o.add(buildUrlChannel());
  o.add(buildUrlChannel());
  return o;
}

void checkUnnamed97(core.List<api.UrlChannel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUrlChannel(o[0] as api.UrlChannel);
  checkUrlChannel(o[1] as api.UrlChannel);
}

core.int buildCounterListUrlChannelsResponse = 0;
api.ListUrlChannelsResponse buildListUrlChannelsResponse() {
  var o = api.ListUrlChannelsResponse();
  buildCounterListUrlChannelsResponse++;
  if (buildCounterListUrlChannelsResponse < 3) {
    o.nextPageToken = 'foo';
    o.urlChannels = buildUnnamed97();
  }
  buildCounterListUrlChannelsResponse--;
  return o;
}

void checkListUrlChannelsResponse(api.ListUrlChannelsResponse o) {
  buildCounterListUrlChannelsResponse++;
  if (buildCounterListUrlChannelsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed97(o.urlChannels!);
  }
  buildCounterListUrlChannelsResponse--;
}

core.int buildCounterPayment = 0;
api.Payment buildPayment() {
  var o = api.Payment();
  buildCounterPayment++;
  if (buildCounterPayment < 3) {
    o.amount = 'foo';
    o.date = buildDate();
    o.name = 'foo';
  }
  buildCounterPayment--;
  return o;
}

void checkPayment(api.Payment o) {
  buildCounterPayment++;
  if (buildCounterPayment < 3) {
    unittest.expect(
      o.amount!,
      unittest.equals('foo'),
    );
    checkDate(o.date! as api.Date);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterPayment--;
}

core.List<api.Header> buildUnnamed98() {
  var o = <api.Header>[];
  o.add(buildHeader());
  o.add(buildHeader());
  return o;
}

void checkUnnamed98(core.List<api.Header> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHeader(o[0] as api.Header);
  checkHeader(o[1] as api.Header);
}

core.List<api.Row> buildUnnamed99() {
  var o = <api.Row>[];
  o.add(buildRow());
  o.add(buildRow());
  return o;
}

void checkUnnamed99(core.List<api.Row> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRow(o[0] as api.Row);
  checkRow(o[1] as api.Row);
}

core.List<core.String> buildUnnamed100() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed100(core.List<core.String> o) {
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

core.int buildCounterReportResult = 0;
api.ReportResult buildReportResult() {
  var o = api.ReportResult();
  buildCounterReportResult++;
  if (buildCounterReportResult < 3) {
    o.averages = buildRow();
    o.endDate = buildDate();
    o.headers = buildUnnamed98();
    o.rows = buildUnnamed99();
    o.startDate = buildDate();
    o.totalMatchedRows = 'foo';
    o.totals = buildRow();
    o.warnings = buildUnnamed100();
  }
  buildCounterReportResult--;
  return o;
}

void checkReportResult(api.ReportResult o) {
  buildCounterReportResult++;
  if (buildCounterReportResult < 3) {
    checkRow(o.averages! as api.Row);
    checkDate(o.endDate! as api.Date);
    checkUnnamed98(o.headers!);
    checkUnnamed99(o.rows!);
    checkDate(o.startDate! as api.Date);
    unittest.expect(
      o.totalMatchedRows!,
      unittest.equals('foo'),
    );
    checkRow(o.totals! as api.Row);
    checkUnnamed100(o.warnings!);
  }
  buildCounterReportResult--;
}

core.List<api.Cell> buildUnnamed101() {
  var o = <api.Cell>[];
  o.add(buildCell());
  o.add(buildCell());
  return o;
}

void checkUnnamed101(core.List<api.Cell> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCell(o[0] as api.Cell);
  checkCell(o[1] as api.Cell);
}

core.int buildCounterRow = 0;
api.Row buildRow() {
  var o = api.Row();
  buildCounterRow++;
  if (buildCounterRow < 3) {
    o.cells = buildUnnamed101();
  }
  buildCounterRow--;
  return o;
}

void checkRow(api.Row o) {
  buildCounterRow++;
  if (buildCounterRow < 3) {
    checkUnnamed101(o.cells!);
  }
  buildCounterRow--;
}

core.int buildCounterSavedReport = 0;
api.SavedReport buildSavedReport() {
  var o = api.SavedReport();
  buildCounterSavedReport++;
  if (buildCounterSavedReport < 3) {
    o.name = 'foo';
    o.title = 'foo';
  }
  buildCounterSavedReport--;
  return o;
}

void checkSavedReport(api.SavedReport o) {
  buildCounterSavedReport++;
  if (buildCounterSavedReport < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterSavedReport--;
}

core.int buildCounterSite = 0;
api.Site buildSite() {
  var o = api.Site();
  buildCounterSite++;
  if (buildCounterSite < 3) {
    o.autoAdsEnabled = true;
    o.domain = 'foo';
    o.name = 'foo';
    o.reportingDimensionId = 'foo';
    o.state = 'foo';
  }
  buildCounterSite--;
  return o;
}

void checkSite(api.Site o) {
  buildCounterSite++;
  if (buildCounterSite < 3) {
    unittest.expect(o.autoAdsEnabled!, unittest.isTrue);
    unittest.expect(
      o.domain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingDimensionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterSite--;
}

core.int buildCounterTimeZone = 0;
api.TimeZone buildTimeZone() {
  var o = api.TimeZone();
  buildCounterTimeZone++;
  if (buildCounterTimeZone < 3) {
    o.id = 'foo';
    o.version = 'foo';
  }
  buildCounterTimeZone--;
  return o;
}

void checkTimeZone(api.TimeZone o) {
  buildCounterTimeZone++;
  if (buildCounterTimeZone < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimeZone--;
}

core.int buildCounterUrlChannel = 0;
api.UrlChannel buildUrlChannel() {
  var o = api.UrlChannel();
  buildCounterUrlChannel++;
  if (buildCounterUrlChannel < 3) {
    o.name = 'foo';
    o.reportingDimensionId = 'foo';
    o.uriPattern = 'foo';
  }
  buildCounterUrlChannel--;
  return o;
}

void checkUrlChannel(api.UrlChannel o) {
  buildCounterUrlChannel++;
  if (buildCounterUrlChannel < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingDimensionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uriPattern!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrlChannel--;
}

core.List<core.String> buildUnnamed102() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed102(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed103() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed103(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed104() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed104(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed105() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed105(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed106() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed106(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed107() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed107(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed108() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed108(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed109() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed109(core.List<core.String> o) {
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
  unittest.group('obj-schema-Account', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Account.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAccount(od as api.Account);
    });
  });

  unittest.group('obj-schema-AdClient', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdClient();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AdClient.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdClient(od as api.AdClient);
    });
  });

  unittest.group('obj-schema-AdClientAdCode', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdClientAdCode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdClientAdCode.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdClientAdCode(od as api.AdClientAdCode);
    });
  });

  unittest.group('obj-schema-AdUnit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AdUnit.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdUnit(od as api.AdUnit);
    });
  });

  unittest.group('obj-schema-AdUnitAdCode', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnitAdCode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdUnitAdCode.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdUnitAdCode(od as api.AdUnitAdCode);
    });
  });

  unittest.group('obj-schema-Alert', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAlert();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Alert.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAlert(od as api.Alert);
    });
  });

  unittest.group('obj-schema-Cell', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCell();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Cell.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCell(od as api.Cell);
    });
  });

  unittest.group('obj-schema-ContentAdsSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContentAdsSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContentAdsSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContentAdsSettings(od as api.ContentAdsSettings);
    });
  });

  unittest.group('obj-schema-CustomChannel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomChannel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomChannel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomChannel(od as api.CustomChannel);
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

  unittest.group('obj-schema-Header', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Header.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHeader(od as api.Header);
    });
  });

  unittest.group('obj-schema-HttpBody', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHttpBody();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.HttpBody.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHttpBody(od as api.HttpBody);
    });
  });

  unittest.group('obj-schema-ListAccountsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAccountsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAccountsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAccountsResponse(od as api.ListAccountsResponse);
    });
  });

  unittest.group('obj-schema-ListAdClientsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAdClientsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAdClientsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAdClientsResponse(od as api.ListAdClientsResponse);
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

  unittest.group('obj-schema-ListAlertsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAlertsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAlertsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAlertsResponse(od as api.ListAlertsResponse);
    });
  });

  unittest.group('obj-schema-ListChildAccountsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListChildAccountsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListChildAccountsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListChildAccountsResponse(od as api.ListChildAccountsResponse);
    });
  });

  unittest.group('obj-schema-ListCustomChannelsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCustomChannelsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCustomChannelsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCustomChannelsResponse(od as api.ListCustomChannelsResponse);
    });
  });

  unittest.group('obj-schema-ListLinkedAdUnitsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLinkedAdUnitsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLinkedAdUnitsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLinkedAdUnitsResponse(od as api.ListLinkedAdUnitsResponse);
    });
  });

  unittest.group('obj-schema-ListLinkedCustomChannelsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLinkedCustomChannelsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLinkedCustomChannelsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLinkedCustomChannelsResponse(
          od as api.ListLinkedCustomChannelsResponse);
    });
  });

  unittest.group('obj-schema-ListPaymentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPaymentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPaymentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPaymentsResponse(od as api.ListPaymentsResponse);
    });
  });

  unittest.group('obj-schema-ListSavedReportsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSavedReportsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSavedReportsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSavedReportsResponse(od as api.ListSavedReportsResponse);
    });
  });

  unittest.group('obj-schema-ListSitesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSitesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSitesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSitesResponse(od as api.ListSitesResponse);
    });
  });

  unittest.group('obj-schema-ListUrlChannelsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListUrlChannelsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListUrlChannelsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListUrlChannelsResponse(od as api.ListUrlChannelsResponse);
    });
  });

  unittest.group('obj-schema-Payment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPayment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Payment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPayment(od as api.Payment);
    });
  });

  unittest.group('obj-schema-ReportResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportResult(od as api.ReportResult);
    });
  });

  unittest.group('obj-schema-Row', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Row.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRow(od as api.Row);
    });
  });

  unittest.group('obj-schema-SavedReport', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSavedReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SavedReport.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSavedReport(od as api.SavedReport);
    });
  });

  unittest.group('obj-schema-Site', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSite();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Site.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSite(od as api.Site);
    });
  });

  unittest.group('obj-schema-TimeZone', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeZone();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeZone.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeZone(od as api.TimeZone);
    });
  });

  unittest.group('obj-schema-UrlChannel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUrlChannel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UrlChannel.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUrlChannel(od as api.UrlChannel);
    });
  });

  unittest.group('resource-AccountsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts;
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
          unittest.equals("v2/accounts"),
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
        var resp = convert.json.encode(buildListAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAccountsResponse(response as api.ListAccountsResponse);
    });

    unittest.test('method--listChildAccounts', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListChildAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listChildAccounts(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListChildAccountsResponse(response as api.ListChildAccountsResponse);
    });
  });

  unittest.group('resource-AccountsAdclientsResource', () {
    unittest.test('method--getAdcode', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildAdClientAdCode());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getAdcode(arg_name, $fields: arg_$fields);
      checkAdClientAdCode(response as api.AdClientAdCode);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListAdClientsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAdClientsResponse(response as api.ListAdClientsResponse);
    });
  });

  unittest.group('resource-AccountsAdclientsAdunitsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.adunits;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildAdUnit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkAdUnit(response as api.AdUnit);
    });

    unittest.test('method--getAdcode', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.adunits;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildAdUnitAdCode());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getAdcode(arg_name, $fields: arg_$fields);
      checkAdUnitAdCode(response as api.AdUnitAdCode);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.adunits;
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
          unittest.equals("v2/"),
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

    unittest.test('method--listLinkedCustomChannels', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.adunits;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListLinkedCustomChannelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listLinkedCustomChannels(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLinkedCustomChannelsResponse(
          response as api.ListLinkedCustomChannelsResponse);
    });
  });

  unittest.group('resource-AccountsAdclientsCustomchannelsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.customchannels;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildCustomChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkCustomChannel(response as api.CustomChannel);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.customchannels;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListCustomChannelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCustomChannelsResponse(
          response as api.ListCustomChannelsResponse);
    });

    unittest.test('method--listLinkedAdUnits', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.customchannels;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListLinkedAdUnitsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listLinkedAdUnits(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLinkedAdUnitsResponse(response as api.ListLinkedAdUnitsResponse);
    });
  });

  unittest.group('resource-AccountsAdclientsUrlchannelsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.adclients.urlchannels;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListUrlChannelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListUrlChannelsResponse(response as api.ListUrlChannelsResponse);
    });
  });

  unittest.group('resource-AccountsAlertsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.alerts;
      var arg_parent = 'foo';
      var arg_languageCode = 'foo';
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
          unittest.equals("v2/"),
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
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListAlertsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          languageCode: arg_languageCode, $fields: arg_$fields);
      checkListAlertsResponse(response as api.ListAlertsResponse);
    });
  });

  unittest.group('resource-AccountsPaymentsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.payments;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListPaymentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkListPaymentsResponse(response as api.ListPaymentsResponse);
    });
  });

  unittest.group('resource-AccountsReportsResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.reports;
      var arg_account = 'foo';
      var arg_currencyCode = 'foo';
      var arg_dateRange = 'foo';
      var arg_dimensions = buildUnnamed102();
      var arg_endDate_day = 42;
      var arg_endDate_month = 42;
      var arg_endDate_year = 42;
      var arg_filters = buildUnnamed103();
      var arg_languageCode = 'foo';
      var arg_limit = 42;
      var arg_metrics = buildUnnamed104();
      var arg_orderBy = buildUnnamed105();
      var arg_reportingTimeZone = 'foo';
      var arg_startDate_day = 42;
      var arg_startDate_month = 42;
      var arg_startDate_year = 42;
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
          unittest.equals("v2/"),
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
          queryMap["currencyCode"]!.first,
          unittest.equals(arg_currencyCode),
        );
        unittest.expect(
          queryMap["dateRange"]!.first,
          unittest.equals(arg_dateRange),
        );
        unittest.expect(
          queryMap["dimensions"]!,
          unittest.equals(arg_dimensions),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.day"]!.first),
          unittest.equals(arg_endDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.month"]!.first),
          unittest.equals(arg_endDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.year"]!.first),
          unittest.equals(arg_endDate_year),
        );
        unittest.expect(
          queryMap["filters"]!,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          core.int.parse(queryMap["limit"]!.first),
          unittest.equals(arg_limit),
        );
        unittest.expect(
          queryMap["metrics"]!,
          unittest.equals(arg_metrics),
        );
        unittest.expect(
          queryMap["orderBy"]!,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["reportingTimeZone"]!.first,
          unittest.equals(arg_reportingTimeZone),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.day"]!.first),
          unittest.equals(arg_startDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.month"]!.first),
          unittest.equals(arg_startDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.year"]!.first),
          unittest.equals(arg_startDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReportResult());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generate(arg_account,
          currencyCode: arg_currencyCode,
          dateRange: arg_dateRange,
          dimensions: arg_dimensions,
          endDate_day: arg_endDate_day,
          endDate_month: arg_endDate_month,
          endDate_year: arg_endDate_year,
          filters: arg_filters,
          languageCode: arg_languageCode,
          limit: arg_limit,
          metrics: arg_metrics,
          orderBy: arg_orderBy,
          reportingTimeZone: arg_reportingTimeZone,
          startDate_day: arg_startDate_day,
          startDate_month: arg_startDate_month,
          startDate_year: arg_startDate_year,
          $fields: arg_$fields);
      checkReportResult(response as api.ReportResult);
    });

    unittest.test('method--generateCsv', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.reports;
      var arg_account = 'foo';
      var arg_currencyCode = 'foo';
      var arg_dateRange = 'foo';
      var arg_dimensions = buildUnnamed106();
      var arg_endDate_day = 42;
      var arg_endDate_month = 42;
      var arg_endDate_year = 42;
      var arg_filters = buildUnnamed107();
      var arg_languageCode = 'foo';
      var arg_limit = 42;
      var arg_metrics = buildUnnamed108();
      var arg_orderBy = buildUnnamed109();
      var arg_reportingTimeZone = 'foo';
      var arg_startDate_day = 42;
      var arg_startDate_month = 42;
      var arg_startDate_year = 42;
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
          unittest.equals("v2/"),
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
          queryMap["currencyCode"]!.first,
          unittest.equals(arg_currencyCode),
        );
        unittest.expect(
          queryMap["dateRange"]!.first,
          unittest.equals(arg_dateRange),
        );
        unittest.expect(
          queryMap["dimensions"]!,
          unittest.equals(arg_dimensions),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.day"]!.first),
          unittest.equals(arg_endDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.month"]!.first),
          unittest.equals(arg_endDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.year"]!.first),
          unittest.equals(arg_endDate_year),
        );
        unittest.expect(
          queryMap["filters"]!,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          core.int.parse(queryMap["limit"]!.first),
          unittest.equals(arg_limit),
        );
        unittest.expect(
          queryMap["metrics"]!,
          unittest.equals(arg_metrics),
        );
        unittest.expect(
          queryMap["orderBy"]!,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["reportingTimeZone"]!.first,
          unittest.equals(arg_reportingTimeZone),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.day"]!.first),
          unittest.equals(arg_startDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.month"]!.first),
          unittest.equals(arg_startDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.year"]!.first),
          unittest.equals(arg_startDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generateCsv(arg_account,
          currencyCode: arg_currencyCode,
          dateRange: arg_dateRange,
          dimensions: arg_dimensions,
          endDate_day: arg_endDate_day,
          endDate_month: arg_endDate_month,
          endDate_year: arg_endDate_year,
          filters: arg_filters,
          languageCode: arg_languageCode,
          limit: arg_limit,
          metrics: arg_metrics,
          orderBy: arg_orderBy,
          reportingTimeZone: arg_reportingTimeZone,
          startDate_day: arg_startDate_day,
          startDate_month: arg_startDate_month,
          startDate_year: arg_startDate_year,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });
  });

  unittest.group('resource-AccountsReportsSavedResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.reports.saved;
      var arg_name = 'foo';
      var arg_currencyCode = 'foo';
      var arg_dateRange = 'foo';
      var arg_endDate_day = 42;
      var arg_endDate_month = 42;
      var arg_endDate_year = 42;
      var arg_languageCode = 'foo';
      var arg_reportingTimeZone = 'foo';
      var arg_startDate_day = 42;
      var arg_startDate_month = 42;
      var arg_startDate_year = 42;
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
          unittest.equals("v2/"),
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
          queryMap["currencyCode"]!.first,
          unittest.equals(arg_currencyCode),
        );
        unittest.expect(
          queryMap["dateRange"]!.first,
          unittest.equals(arg_dateRange),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.day"]!.first),
          unittest.equals(arg_endDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.month"]!.first),
          unittest.equals(arg_endDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.year"]!.first),
          unittest.equals(arg_endDate_year),
        );
        unittest.expect(
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          queryMap["reportingTimeZone"]!.first,
          unittest.equals(arg_reportingTimeZone),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.day"]!.first),
          unittest.equals(arg_startDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.month"]!.first),
          unittest.equals(arg_startDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.year"]!.first),
          unittest.equals(arg_startDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReportResult());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generate(arg_name,
          currencyCode: arg_currencyCode,
          dateRange: arg_dateRange,
          endDate_day: arg_endDate_day,
          endDate_month: arg_endDate_month,
          endDate_year: arg_endDate_year,
          languageCode: arg_languageCode,
          reportingTimeZone: arg_reportingTimeZone,
          startDate_day: arg_startDate_day,
          startDate_month: arg_startDate_month,
          startDate_year: arg_startDate_year,
          $fields: arg_$fields);
      checkReportResult(response as api.ReportResult);
    });

    unittest.test('method--generateCsv', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.reports.saved;
      var arg_name = 'foo';
      var arg_currencyCode = 'foo';
      var arg_dateRange = 'foo';
      var arg_endDate_day = 42;
      var arg_endDate_month = 42;
      var arg_endDate_year = 42;
      var arg_languageCode = 'foo';
      var arg_reportingTimeZone = 'foo';
      var arg_startDate_day = 42;
      var arg_startDate_month = 42;
      var arg_startDate_year = 42;
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
          unittest.equals("v2/"),
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
          queryMap["currencyCode"]!.first,
          unittest.equals(arg_currencyCode),
        );
        unittest.expect(
          queryMap["dateRange"]!.first,
          unittest.equals(arg_dateRange),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.day"]!.first),
          unittest.equals(arg_endDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.month"]!.first),
          unittest.equals(arg_endDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.year"]!.first),
          unittest.equals(arg_endDate_year),
        );
        unittest.expect(
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          queryMap["reportingTimeZone"]!.first,
          unittest.equals(arg_reportingTimeZone),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.day"]!.first),
          unittest.equals(arg_startDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.month"]!.first),
          unittest.equals(arg_startDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.year"]!.first),
          unittest.equals(arg_startDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generateCsv(arg_name,
          currencyCode: arg_currencyCode,
          dateRange: arg_dateRange,
          endDate_day: arg_endDate_day,
          endDate_month: arg_endDate_month,
          endDate_year: arg_endDate_year,
          languageCode: arg_languageCode,
          reportingTimeZone: arg_reportingTimeZone,
          startDate_day: arg_startDate_day,
          startDate_month: arg_startDate_month,
          startDate_year: arg_startDate_year,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.reports.saved;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListSavedReportsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSavedReportsResponse(response as api.ListSavedReportsResponse);
    });
  });

  unittest.group('resource-AccountsSitesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.sites;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildSite());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSite(response as api.Site);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdsenseApi(mock).accounts.sites;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildListSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSitesResponse(response as api.ListSitesResponse);
    });
  });
}

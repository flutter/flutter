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

import 'package:googleapis/adsense/v1_4.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Account> buildUnnamed4511() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed4511(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterAccount = 0;
api.Account buildAccount() {
  var o = api.Account();
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    o.creationTime = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.premium = true;
    o.subAccounts = buildUnnamed4511();
    o.timezone = 'foo';
  }
  buildCounterAccount--;
  return o;
}

void checkAccount(api.Account o) {
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.premium!, unittest.isTrue);
    checkUnnamed4511(o.subAccounts!);
    unittest.expect(
      o.timezone!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccount--;
}

core.List<api.Account> buildUnnamed4512() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed4512(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterAccounts = 0;
api.Accounts buildAccounts() {
  var o = api.Accounts();
  buildCounterAccounts++;
  if (buildCounterAccounts < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed4512();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterAccounts--;
  return o;
}

void checkAccounts(api.Accounts o) {
  buildCounterAccounts++;
  if (buildCounterAccounts < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed4512(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccounts--;
}

core.int buildCounterAdClient = 0;
api.AdClient buildAdClient() {
  var o = api.AdClient();
  buildCounterAdClient++;
  if (buildCounterAdClient < 3) {
    o.arcOptIn = true;
    o.id = 'foo';
    o.kind = 'foo';
    o.productCode = 'foo';
    o.supportsReporting = true;
  }
  buildCounterAdClient--;
  return o;
}

void checkAdClient(api.AdClient o) {
  buildCounterAdClient++;
  if (buildCounterAdClient < 3) {
    unittest.expect(o.arcOptIn!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productCode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.supportsReporting!, unittest.isTrue);
  }
  buildCounterAdClient--;
}

core.List<api.AdClient> buildUnnamed4513() {
  var o = <api.AdClient>[];
  o.add(buildAdClient());
  o.add(buildAdClient());
  return o;
}

void checkUnnamed4513(core.List<api.AdClient> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdClient(o[0] as api.AdClient);
  checkAdClient(o[1] as api.AdClient);
}

core.int buildCounterAdClients = 0;
api.AdClients buildAdClients() {
  var o = api.AdClients();
  buildCounterAdClients++;
  if (buildCounterAdClients < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed4513();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterAdClients--;
  return o;
}

void checkAdClients(api.AdClients o) {
  buildCounterAdClients++;
  if (buildCounterAdClients < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed4513(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdClients--;
}

core.int buildCounterAdCode = 0;
api.AdCode buildAdCode() {
  var o = api.AdCode();
  buildCounterAdCode++;
  if (buildCounterAdCode < 3) {
    o.adCode = 'foo';
    o.ampBody = 'foo';
    o.ampHead = 'foo';
    o.kind = 'foo';
  }
  buildCounterAdCode--;
  return o;
}

void checkAdCode(api.AdCode o) {
  buildCounterAdCode++;
  if (buildCounterAdCode < 3) {
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
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdCode--;
}

core.int buildCounterAdStyleColors = 0;
api.AdStyleColors buildAdStyleColors() {
  var o = api.AdStyleColors();
  buildCounterAdStyleColors++;
  if (buildCounterAdStyleColors < 3) {
    o.background = 'foo';
    o.border = 'foo';
    o.text = 'foo';
    o.title = 'foo';
    o.url = 'foo';
  }
  buildCounterAdStyleColors--;
  return o;
}

void checkAdStyleColors(api.AdStyleColors o) {
  buildCounterAdStyleColors++;
  if (buildCounterAdStyleColors < 3) {
    unittest.expect(
      o.background!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.border!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdStyleColors--;
}

core.int buildCounterAdStyleFont = 0;
api.AdStyleFont buildAdStyleFont() {
  var o = api.AdStyleFont();
  buildCounterAdStyleFont++;
  if (buildCounterAdStyleFont < 3) {
    o.family = 'foo';
    o.size = 'foo';
  }
  buildCounterAdStyleFont--;
  return o;
}

void checkAdStyleFont(api.AdStyleFont o) {
  buildCounterAdStyleFont++;
  if (buildCounterAdStyleFont < 3) {
    unittest.expect(
      o.family!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdStyleFont--;
}

core.int buildCounterAdStyle = 0;
api.AdStyle buildAdStyle() {
  var o = api.AdStyle();
  buildCounterAdStyle++;
  if (buildCounterAdStyle < 3) {
    o.colors = buildAdStyleColors();
    o.corners = 'foo';
    o.font = buildAdStyleFont();
    o.kind = 'foo';
  }
  buildCounterAdStyle--;
  return o;
}

void checkAdStyle(api.AdStyle o) {
  buildCounterAdStyle++;
  if (buildCounterAdStyle < 3) {
    checkAdStyleColors(o.colors! as api.AdStyleColors);
    unittest.expect(
      o.corners!,
      unittest.equals('foo'),
    );
    checkAdStyleFont(o.font! as api.AdStyleFont);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdStyle--;
}

core.int buildCounterAdUnitContentAdsSettingsBackupOption = 0;
api.AdUnitContentAdsSettingsBackupOption
    buildAdUnitContentAdsSettingsBackupOption() {
  var o = api.AdUnitContentAdsSettingsBackupOption();
  buildCounterAdUnitContentAdsSettingsBackupOption++;
  if (buildCounterAdUnitContentAdsSettingsBackupOption < 3) {
    o.color = 'foo';
    o.type = 'foo';
    o.url = 'foo';
  }
  buildCounterAdUnitContentAdsSettingsBackupOption--;
  return o;
}

void checkAdUnitContentAdsSettingsBackupOption(
    api.AdUnitContentAdsSettingsBackupOption o) {
  buildCounterAdUnitContentAdsSettingsBackupOption++;
  if (buildCounterAdUnitContentAdsSettingsBackupOption < 3) {
    unittest.expect(
      o.color!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnitContentAdsSettingsBackupOption--;
}

core.int buildCounterAdUnitContentAdsSettings = 0;
api.AdUnitContentAdsSettings buildAdUnitContentAdsSettings() {
  var o = api.AdUnitContentAdsSettings();
  buildCounterAdUnitContentAdsSettings++;
  if (buildCounterAdUnitContentAdsSettings < 3) {
    o.backupOption = buildAdUnitContentAdsSettingsBackupOption();
    o.size = 'foo';
    o.type = 'foo';
  }
  buildCounterAdUnitContentAdsSettings--;
  return o;
}

void checkAdUnitContentAdsSettings(api.AdUnitContentAdsSettings o) {
  buildCounterAdUnitContentAdsSettings++;
  if (buildCounterAdUnitContentAdsSettings < 3) {
    checkAdUnitContentAdsSettingsBackupOption(
        o.backupOption! as api.AdUnitContentAdsSettingsBackupOption);
    unittest.expect(
      o.size!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnitContentAdsSettings--;
}

core.int buildCounterAdUnitFeedAdsSettings = 0;
api.AdUnitFeedAdsSettings buildAdUnitFeedAdsSettings() {
  var o = api.AdUnitFeedAdsSettings();
  buildCounterAdUnitFeedAdsSettings++;
  if (buildCounterAdUnitFeedAdsSettings < 3) {
    o.adPosition = 'foo';
    o.frequency = 42;
    o.minimumWordCount = 42;
    o.type = 'foo';
  }
  buildCounterAdUnitFeedAdsSettings--;
  return o;
}

void checkAdUnitFeedAdsSettings(api.AdUnitFeedAdsSettings o) {
  buildCounterAdUnitFeedAdsSettings++;
  if (buildCounterAdUnitFeedAdsSettings < 3) {
    unittest.expect(
      o.adPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.frequency!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minimumWordCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnitFeedAdsSettings--;
}

core.int buildCounterAdUnitMobileContentAdsSettings = 0;
api.AdUnitMobileContentAdsSettings buildAdUnitMobileContentAdsSettings() {
  var o = api.AdUnitMobileContentAdsSettings();
  buildCounterAdUnitMobileContentAdsSettings++;
  if (buildCounterAdUnitMobileContentAdsSettings < 3) {
    o.markupLanguage = 'foo';
    o.scriptingLanguage = 'foo';
    o.size = 'foo';
    o.type = 'foo';
  }
  buildCounterAdUnitMobileContentAdsSettings--;
  return o;
}

void checkAdUnitMobileContentAdsSettings(api.AdUnitMobileContentAdsSettings o) {
  buildCounterAdUnitMobileContentAdsSettings++;
  if (buildCounterAdUnitMobileContentAdsSettings < 3) {
    unittest.expect(
      o.markupLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scriptingLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnitMobileContentAdsSettings--;
}

core.int buildCounterAdUnit = 0;
api.AdUnit buildAdUnit() {
  var o = api.AdUnit();
  buildCounterAdUnit++;
  if (buildCounterAdUnit < 3) {
    o.code = 'foo';
    o.contentAdsSettings = buildAdUnitContentAdsSettings();
    o.customStyle = buildAdStyle();
    o.feedAdsSettings = buildAdUnitFeedAdsSettings();
    o.id = 'foo';
    o.kind = 'foo';
    o.mobileContentAdsSettings = buildAdUnitMobileContentAdsSettings();
    o.name = 'foo';
    o.savedStyleId = 'foo';
    o.status = 'foo';
  }
  buildCounterAdUnit--;
  return o;
}

void checkAdUnit(api.AdUnit o) {
  buildCounterAdUnit++;
  if (buildCounterAdUnit < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    checkAdUnitContentAdsSettings(
        o.contentAdsSettings! as api.AdUnitContentAdsSettings);
    checkAdStyle(o.customStyle! as api.AdStyle);
    checkAdUnitFeedAdsSettings(o.feedAdsSettings! as api.AdUnitFeedAdsSettings);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkAdUnitMobileContentAdsSettings(
        o.mobileContentAdsSettings! as api.AdUnitMobileContentAdsSettings);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.savedStyleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnit--;
}

core.List<api.AdUnit> buildUnnamed4514() {
  var o = <api.AdUnit>[];
  o.add(buildAdUnit());
  o.add(buildAdUnit());
  return o;
}

void checkUnnamed4514(core.List<api.AdUnit> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdUnit(o[0] as api.AdUnit);
  checkAdUnit(o[1] as api.AdUnit);
}

core.int buildCounterAdUnits = 0;
api.AdUnits buildAdUnits() {
  var o = api.AdUnits();
  buildCounterAdUnits++;
  if (buildCounterAdUnits < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed4514();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterAdUnits--;
  return o;
}

void checkAdUnits(api.AdUnits o) {
  buildCounterAdUnits++;
  if (buildCounterAdUnits < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed4514(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdUnits--;
}

core.List<core.String> buildUnnamed4515() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4515(core.List<core.String> o) {
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

core.int buildCounterAdsenseReportsGenerateResponseHeaders = 0;
api.AdsenseReportsGenerateResponseHeaders
    buildAdsenseReportsGenerateResponseHeaders() {
  var o = api.AdsenseReportsGenerateResponseHeaders();
  buildCounterAdsenseReportsGenerateResponseHeaders++;
  if (buildCounterAdsenseReportsGenerateResponseHeaders < 3) {
    o.currency = 'foo';
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterAdsenseReportsGenerateResponseHeaders--;
  return o;
}

void checkAdsenseReportsGenerateResponseHeaders(
    api.AdsenseReportsGenerateResponseHeaders o) {
  buildCounterAdsenseReportsGenerateResponseHeaders++;
  if (buildCounterAdsenseReportsGenerateResponseHeaders < 3) {
    unittest.expect(
      o.currency!,
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
  buildCounterAdsenseReportsGenerateResponseHeaders--;
}

core.List<api.AdsenseReportsGenerateResponseHeaders> buildUnnamed4516() {
  var o = <api.AdsenseReportsGenerateResponseHeaders>[];
  o.add(buildAdsenseReportsGenerateResponseHeaders());
  o.add(buildAdsenseReportsGenerateResponseHeaders());
  return o;
}

void checkUnnamed4516(core.List<api.AdsenseReportsGenerateResponseHeaders> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdsenseReportsGenerateResponseHeaders(
      o[0] as api.AdsenseReportsGenerateResponseHeaders);
  checkAdsenseReportsGenerateResponseHeaders(
      o[1] as api.AdsenseReportsGenerateResponseHeaders);
}

core.List<core.String> buildUnnamed4517() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4517(core.List<core.String> o) {
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

core.List<core.List<core.String>> buildUnnamed4518() {
  var o = <core.List<core.String>>[];
  o.add(buildUnnamed4517());
  o.add(buildUnnamed4517());
  return o;
}

void checkUnnamed4518(core.List<core.List<core.String>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed4517(o[0]);
  checkUnnamed4517(o[1]);
}

core.List<core.String> buildUnnamed4519() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4519(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4520() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4520(core.List<core.String> o) {
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

core.int buildCounterAdsenseReportsGenerateResponse = 0;
api.AdsenseReportsGenerateResponse buildAdsenseReportsGenerateResponse() {
  var o = api.AdsenseReportsGenerateResponse();
  buildCounterAdsenseReportsGenerateResponse++;
  if (buildCounterAdsenseReportsGenerateResponse < 3) {
    o.averages = buildUnnamed4515();
    o.endDate = 'foo';
    o.headers = buildUnnamed4516();
    o.kind = 'foo';
    o.rows = buildUnnamed4518();
    o.startDate = 'foo';
    o.totalMatchedRows = 'foo';
    o.totals = buildUnnamed4519();
    o.warnings = buildUnnamed4520();
  }
  buildCounterAdsenseReportsGenerateResponse--;
  return o;
}

void checkAdsenseReportsGenerateResponse(api.AdsenseReportsGenerateResponse o) {
  buildCounterAdsenseReportsGenerateResponse++;
  if (buildCounterAdsenseReportsGenerateResponse < 3) {
    checkUnnamed4515(o.averages!);
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    checkUnnamed4516(o.headers!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed4518(o.rows!);
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalMatchedRows!,
      unittest.equals('foo'),
    );
    checkUnnamed4519(o.totals!);
    checkUnnamed4520(o.warnings!);
  }
  buildCounterAdsenseReportsGenerateResponse--;
}

core.int buildCounterAlert = 0;
api.Alert buildAlert() {
  var o = api.Alert();
  buildCounterAlert++;
  if (buildCounterAlert < 3) {
    o.id = 'foo';
    o.isDismissible = true;
    o.kind = 'foo';
    o.message = 'foo';
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
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDismissible!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.message!,
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

core.List<api.Alert> buildUnnamed4521() {
  var o = <api.Alert>[];
  o.add(buildAlert());
  o.add(buildAlert());
  return o;
}

void checkUnnamed4521(core.List<api.Alert> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAlert(o[0] as api.Alert);
  checkAlert(o[1] as api.Alert);
}

core.int buildCounterAlerts = 0;
api.Alerts buildAlerts() {
  var o = api.Alerts();
  buildCounterAlerts++;
  if (buildCounterAlerts < 3) {
    o.items = buildUnnamed4521();
    o.kind = 'foo';
  }
  buildCounterAlerts--;
  return o;
}

void checkAlerts(api.Alerts o) {
  buildCounterAlerts++;
  if (buildCounterAlerts < 3) {
    checkUnnamed4521(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAlerts--;
}

core.int buildCounterCustomChannelTargetingInfo = 0;
api.CustomChannelTargetingInfo buildCustomChannelTargetingInfo() {
  var o = api.CustomChannelTargetingInfo();
  buildCounterCustomChannelTargetingInfo++;
  if (buildCounterCustomChannelTargetingInfo < 3) {
    o.adsAppearOn = 'foo';
    o.description = 'foo';
    o.location = 'foo';
    o.siteLanguage = 'foo';
  }
  buildCounterCustomChannelTargetingInfo--;
  return o;
}

void checkCustomChannelTargetingInfo(api.CustomChannelTargetingInfo o) {
  buildCounterCustomChannelTargetingInfo++;
  if (buildCounterCustomChannelTargetingInfo < 3) {
    unittest.expect(
      o.adsAppearOn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.siteLanguage!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomChannelTargetingInfo--;
}

core.int buildCounterCustomChannel = 0;
api.CustomChannel buildCustomChannel() {
  var o = api.CustomChannel();
  buildCounterCustomChannel++;
  if (buildCounterCustomChannel < 3) {
    o.code = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.targetingInfo = buildCustomChannelTargetingInfo();
  }
  buildCounterCustomChannel--;
  return o;
}

void checkCustomChannel(api.CustomChannel o) {
  buildCounterCustomChannel++;
  if (buildCounterCustomChannel < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkCustomChannelTargetingInfo(
        o.targetingInfo! as api.CustomChannelTargetingInfo);
  }
  buildCounterCustomChannel--;
}

core.List<api.CustomChannel> buildUnnamed4522() {
  var o = <api.CustomChannel>[];
  o.add(buildCustomChannel());
  o.add(buildCustomChannel());
  return o;
}

void checkUnnamed4522(core.List<api.CustomChannel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomChannel(o[0] as api.CustomChannel);
  checkCustomChannel(o[1] as api.CustomChannel);
}

core.int buildCounterCustomChannels = 0;
api.CustomChannels buildCustomChannels() {
  var o = api.CustomChannels();
  buildCounterCustomChannels++;
  if (buildCounterCustomChannels < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed4522();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterCustomChannels--;
  return o;
}

void checkCustomChannels(api.CustomChannels o) {
  buildCounterCustomChannels++;
  if (buildCounterCustomChannels < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed4522(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomChannels--;
}

core.List<api.ReportingMetadataEntry> buildUnnamed4523() {
  var o = <api.ReportingMetadataEntry>[];
  o.add(buildReportingMetadataEntry());
  o.add(buildReportingMetadataEntry());
  return o;
}

void checkUnnamed4523(core.List<api.ReportingMetadataEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportingMetadataEntry(o[0] as api.ReportingMetadataEntry);
  checkReportingMetadataEntry(o[1] as api.ReportingMetadataEntry);
}

core.int buildCounterMetadata = 0;
api.Metadata buildMetadata() {
  var o = api.Metadata();
  buildCounterMetadata++;
  if (buildCounterMetadata < 3) {
    o.items = buildUnnamed4523();
    o.kind = 'foo';
  }
  buildCounterMetadata--;
  return o;
}

void checkMetadata(api.Metadata o) {
  buildCounterMetadata++;
  if (buildCounterMetadata < 3) {
    checkUnnamed4523(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetadata--;
}

core.int buildCounterPayment = 0;
api.Payment buildPayment() {
  var o = api.Payment();
  buildCounterPayment++;
  if (buildCounterPayment < 3) {
    o.id = 'foo';
    o.kind = 'foo';
    o.paymentAmount = 'foo';
    o.paymentAmountCurrencyCode = 'foo';
    o.paymentDate = 'foo';
  }
  buildCounterPayment--;
  return o;
}

void checkPayment(api.Payment o) {
  buildCounterPayment++;
  if (buildCounterPayment < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.paymentAmount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.paymentAmountCurrencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.paymentDate!,
      unittest.equals('foo'),
    );
  }
  buildCounterPayment--;
}

core.List<api.Payment> buildUnnamed4524() {
  var o = <api.Payment>[];
  o.add(buildPayment());
  o.add(buildPayment());
  return o;
}

void checkUnnamed4524(core.List<api.Payment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPayment(o[0] as api.Payment);
  checkPayment(o[1] as api.Payment);
}

core.int buildCounterPayments = 0;
api.Payments buildPayments() {
  var o = api.Payments();
  buildCounterPayments++;
  if (buildCounterPayments < 3) {
    o.items = buildUnnamed4524();
    o.kind = 'foo';
  }
  buildCounterPayments--;
  return o;
}

void checkPayments(api.Payments o) {
  buildCounterPayments++;
  if (buildCounterPayments < 3) {
    checkUnnamed4524(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterPayments--;
}

core.List<core.String> buildUnnamed4525() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4525(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4526() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4526(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4527() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4527(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4528() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4528(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4529() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4529(core.List<core.String> o) {
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

core.int buildCounterReportingMetadataEntry = 0;
api.ReportingMetadataEntry buildReportingMetadataEntry() {
  var o = api.ReportingMetadataEntry();
  buildCounterReportingMetadataEntry++;
  if (buildCounterReportingMetadataEntry < 3) {
    o.compatibleDimensions = buildUnnamed4525();
    o.compatibleMetrics = buildUnnamed4526();
    o.id = 'foo';
    o.kind = 'foo';
    o.requiredDimensions = buildUnnamed4527();
    o.requiredMetrics = buildUnnamed4528();
    o.supportedProducts = buildUnnamed4529();
  }
  buildCounterReportingMetadataEntry--;
  return o;
}

void checkReportingMetadataEntry(api.ReportingMetadataEntry o) {
  buildCounterReportingMetadataEntry++;
  if (buildCounterReportingMetadataEntry < 3) {
    checkUnnamed4525(o.compatibleDimensions!);
    checkUnnamed4526(o.compatibleMetrics!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed4527(o.requiredDimensions!);
    checkUnnamed4528(o.requiredMetrics!);
    checkUnnamed4529(o.supportedProducts!);
  }
  buildCounterReportingMetadataEntry--;
}

core.int buildCounterSavedAdStyle = 0;
api.SavedAdStyle buildSavedAdStyle() {
  var o = api.SavedAdStyle();
  buildCounterSavedAdStyle++;
  if (buildCounterSavedAdStyle < 3) {
    o.adStyle = buildAdStyle();
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterSavedAdStyle--;
  return o;
}

void checkSavedAdStyle(api.SavedAdStyle o) {
  buildCounterSavedAdStyle++;
  if (buildCounterSavedAdStyle < 3) {
    checkAdStyle(o.adStyle! as api.AdStyle);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSavedAdStyle--;
}

core.List<api.SavedAdStyle> buildUnnamed4530() {
  var o = <api.SavedAdStyle>[];
  o.add(buildSavedAdStyle());
  o.add(buildSavedAdStyle());
  return o;
}

void checkUnnamed4530(core.List<api.SavedAdStyle> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSavedAdStyle(o[0] as api.SavedAdStyle);
  checkSavedAdStyle(o[1] as api.SavedAdStyle);
}

core.int buildCounterSavedAdStyles = 0;
api.SavedAdStyles buildSavedAdStyles() {
  var o = api.SavedAdStyles();
  buildCounterSavedAdStyles++;
  if (buildCounterSavedAdStyles < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed4530();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterSavedAdStyles--;
  return o;
}

void checkSavedAdStyles(api.SavedAdStyles o) {
  buildCounterSavedAdStyles++;
  if (buildCounterSavedAdStyles < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed4530(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSavedAdStyles--;
}

core.int buildCounterSavedReport = 0;
api.SavedReport buildSavedReport() {
  var o = api.SavedReport();
  buildCounterSavedReport++;
  if (buildCounterSavedReport < 3) {
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterSavedReport--;
  return o;
}

void checkSavedReport(api.SavedReport o) {
  buildCounterSavedReport++;
  if (buildCounterSavedReport < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSavedReport--;
}

core.List<api.SavedReport> buildUnnamed4531() {
  var o = <api.SavedReport>[];
  o.add(buildSavedReport());
  o.add(buildSavedReport());
  return o;
}

void checkUnnamed4531(core.List<api.SavedReport> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSavedReport(o[0] as api.SavedReport);
  checkSavedReport(o[1] as api.SavedReport);
}

core.int buildCounterSavedReports = 0;
api.SavedReports buildSavedReports() {
  var o = api.SavedReports();
  buildCounterSavedReports++;
  if (buildCounterSavedReports < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed4531();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterSavedReports--;
  return o;
}

void checkSavedReports(api.SavedReports o) {
  buildCounterSavedReports++;
  if (buildCounterSavedReports < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed4531(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSavedReports--;
}

core.int buildCounterUrlChannel = 0;
api.UrlChannel buildUrlChannel() {
  var o = api.UrlChannel();
  buildCounterUrlChannel++;
  if (buildCounterUrlChannel < 3) {
    o.id = 'foo';
    o.kind = 'foo';
    o.urlPattern = 'foo';
  }
  buildCounterUrlChannel--;
  return o;
}

void checkUrlChannel(api.UrlChannel o) {
  buildCounterUrlChannel++;
  if (buildCounterUrlChannel < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.urlPattern!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrlChannel--;
}

core.List<api.UrlChannel> buildUnnamed4532() {
  var o = <api.UrlChannel>[];
  o.add(buildUrlChannel());
  o.add(buildUrlChannel());
  return o;
}

void checkUnnamed4532(core.List<api.UrlChannel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUrlChannel(o[0] as api.UrlChannel);
  checkUrlChannel(o[1] as api.UrlChannel);
}

core.int buildCounterUrlChannels = 0;
api.UrlChannels buildUrlChannels() {
  var o = api.UrlChannels();
  buildCounterUrlChannels++;
  if (buildCounterUrlChannels < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed4532();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterUrlChannels--;
  return o;
}

void checkUrlChannels(api.UrlChannels o) {
  buildCounterUrlChannels++;
  if (buildCounterUrlChannels < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed4532(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrlChannels--;
}

core.List<core.String> buildUnnamed4533() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4533(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4534() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4534(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4535() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4535(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4536() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4536(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4537() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4537(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4538() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4538(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4539() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4539(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4540() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4540(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4541() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4541(core.List<core.String> o) {
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

  unittest.group('obj-schema-Accounts', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccounts();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Accounts.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAccounts(od as api.Accounts);
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

  unittest.group('obj-schema-AdClients', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdClients();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AdClients.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdClients(od as api.AdClients);
    });
  });

  unittest.group('obj-schema-AdCode', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdCode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AdCode.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdCode(od as api.AdCode);
    });
  });

  unittest.group('obj-schema-AdStyleColors', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdStyleColors();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdStyleColors.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdStyleColors(od as api.AdStyleColors);
    });
  });

  unittest.group('obj-schema-AdStyleFont', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdStyleFont();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdStyleFont.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdStyleFont(od as api.AdStyleFont);
    });
  });

  unittest.group('obj-schema-AdStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AdStyle.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdStyle(od as api.AdStyle);
    });
  });

  unittest.group('obj-schema-AdUnitContentAdsSettingsBackupOption', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnitContentAdsSettingsBackupOption();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdUnitContentAdsSettingsBackupOption.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdUnitContentAdsSettingsBackupOption(
          od as api.AdUnitContentAdsSettingsBackupOption);
    });
  });

  unittest.group('obj-schema-AdUnitContentAdsSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnitContentAdsSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdUnitContentAdsSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdUnitContentAdsSettings(od as api.AdUnitContentAdsSettings);
    });
  });

  unittest.group('obj-schema-AdUnitFeedAdsSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnitFeedAdsSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdUnitFeedAdsSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdUnitFeedAdsSettings(od as api.AdUnitFeedAdsSettings);
    });
  });

  unittest.group('obj-schema-AdUnitMobileContentAdsSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnitMobileContentAdsSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdUnitMobileContentAdsSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdUnitMobileContentAdsSettings(
          od as api.AdUnitMobileContentAdsSettings);
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

  unittest.group('obj-schema-AdUnits', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdUnits();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AdUnits.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdUnits(od as api.AdUnits);
    });
  });

  unittest.group('obj-schema-AdsenseReportsGenerateResponseHeaders', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdsenseReportsGenerateResponseHeaders();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdsenseReportsGenerateResponseHeaders.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdsenseReportsGenerateResponseHeaders(
          od as api.AdsenseReportsGenerateResponseHeaders);
    });
  });

  unittest.group('obj-schema-AdsenseReportsGenerateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdsenseReportsGenerateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdsenseReportsGenerateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdsenseReportsGenerateResponse(
          od as api.AdsenseReportsGenerateResponse);
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

  unittest.group('obj-schema-Alerts', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAlerts();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Alerts.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAlerts(od as api.Alerts);
    });
  });

  unittest.group('obj-schema-CustomChannelTargetingInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomChannelTargetingInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomChannelTargetingInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomChannelTargetingInfo(od as api.CustomChannelTargetingInfo);
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

  unittest.group('obj-schema-CustomChannels', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomChannels();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomChannels.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomChannels(od as api.CustomChannels);
    });
  });

  unittest.group('obj-schema-Metadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Metadata.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMetadata(od as api.Metadata);
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

  unittest.group('obj-schema-Payments', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPayments();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Payments.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPayments(od as api.Payments);
    });
  });

  unittest.group('obj-schema-ReportingMetadataEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportingMetadataEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportingMetadataEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportingMetadataEntry(od as api.ReportingMetadataEntry);
    });
  });

  unittest.group('obj-schema-SavedAdStyle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSavedAdStyle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SavedAdStyle.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSavedAdStyle(od as api.SavedAdStyle);
    });
  });

  unittest.group('obj-schema-SavedAdStyles', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSavedAdStyles();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SavedAdStyles.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSavedAdStyles(od as api.SavedAdStyles);
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

  unittest.group('obj-schema-SavedReports', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSavedReports();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SavedReports.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSavedReports(od as api.SavedReports);
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

  unittest.group('obj-schema-UrlChannels', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUrlChannels();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UrlChannels.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUrlChannels(od as api.UrlChannels);
    });
  });

  unittest.group('resource-AccountsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts;
      var arg_accountId = 'foo';
      var arg_tree = true;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
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
          queryMap["tree"]!.first,
          unittest.equals("$arg_tree"),
        );
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
      final response =
          await res.get(arg_accountId, tree: arg_tree, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("accounts"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildAccounts());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAccounts(response as api.Accounts);
    });
  });

  unittest.group('resource-AccountsAdclientsResource', () {
    unittest.test('method--getAdCode', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.adclients;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_tagPartner = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/adcode', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/adcode"),
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
          queryMap["tagPartner"]!.first,
          unittest.equals(arg_tagPartner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAdCode());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getAdCode(arg_accountId, arg_adClientId,
          tagPartner: arg_tagPartner, $fields: arg_$fields);
      checkAdCode(response as api.AdCode);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.adclients;
      var arg_accountId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/adclients"),
        );
        pathOffset += 10;

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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildAdClients());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAdClients(response as api.AdClients);
    });
  });

  unittest.group('resource-AccountsAdunitsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.adunits;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_adUnitId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/adunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/adunits/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adUnitId'),
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
        var resp = convert.json.encode(buildAdUnit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_adClientId, arg_adUnitId,
          $fields: arg_$fields);
      checkAdUnit(response as api.AdUnit);
    });

    unittest.test('method--getAdCode', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.adunits;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_adUnitId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/adunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/adunits/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adcode', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adUnitId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/adcode"),
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
        var resp = convert.json.encode(buildAdCode());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getAdCode(
          arg_accountId, arg_adClientId, arg_adUnitId,
          $fields: arg_$fields);
      checkAdCode(response as api.AdCode);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.adunits;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_includeInactive = true;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/adunits', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/adunits"),
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
          queryMap["includeInactive"]!.first,
          unittest.equals("$arg_includeInactive"),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildAdUnits());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_adClientId,
          includeInactive: arg_includeInactive,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAdUnits(response as api.AdUnits);
    });
  });

  unittest.group('resource-AccountsAdunitsCustomchannelsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.adunits.customchannels;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_adUnitId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/adunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/adunits/"),
        );
        pathOffset += 9;
        index = path.indexOf('/customchannels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adUnitId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/customchannels"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildCustomChannels());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_adClientId, arg_adUnitId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCustomChannels(response as api.CustomChannels);
    });
  });

  unittest.group('resource-AccountsAlertsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.alerts;
      var arg_accountId = 'foo';
      var arg_alertId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/alerts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/alerts/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_alertId'),
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
      await res.delete(arg_accountId, arg_alertId, $fields: arg_$fields);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.alerts;
      var arg_accountId = 'foo';
      var arg_locale = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/alerts', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/alerts"),
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
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAlerts());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId,
          locale: arg_locale, $fields: arg_$fields);
      checkAlerts(response as api.Alerts);
    });
  });

  unittest.group('resource-AccountsCustomchannelsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.customchannels;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_customChannelId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/customchannels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/customchannels/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customChannelId'),
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
        var resp = convert.json.encode(buildCustomChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_adClientId, arg_customChannelId,
          $fields: arg_$fields);
      checkCustomChannel(response as api.CustomChannel);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.customchannels;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/customchannels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/customchannels"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildCustomChannels());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_adClientId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCustomChannels(response as api.CustomChannels);
    });
  });

  unittest.group('resource-AccountsCustomchannelsAdunitsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.customchannels.adunits;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_customChannelId = 'foo';
      var arg_includeInactive = true;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/customchannels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/customchannels/"),
        );
        pathOffset += 16;
        index = path.indexOf('/adunits', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customChannelId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/adunits"),
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
          queryMap["includeInactive"]!.first,
          unittest.equals("$arg_includeInactive"),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildAdUnits());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_adClientId, arg_customChannelId,
          includeInactive: arg_includeInactive,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAdUnits(response as api.AdUnits);
    });
  });

  unittest.group('resource-AccountsPaymentsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.payments;
      var arg_accountId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/payments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/payments"),
        );
        pathOffset += 9;

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
        var resp = convert.json.encode(buildPayments());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, $fields: arg_$fields);
      checkPayments(response as api.Payments);
    });
  });

  unittest.group('resource-AccountsReportsResource', () {
    unittest.test('method--generate', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.reports;
      var arg_accountId = 'foo';
      var arg_startDate = 'foo';
      var arg_endDate = 'foo';
      var arg_currency = 'foo';
      var arg_dimension = buildUnnamed4533();
      var arg_filter = buildUnnamed4534();
      var arg_locale = 'foo';
      var arg_maxResults = 42;
      var arg_metric = buildUnnamed4535();
      var arg_sort = buildUnnamed4536();
      var arg_startIndex = 42;
      var arg_useTimezoneReporting = true;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/reports', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
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
          queryMap["startDate"]!.first,
          unittest.equals(arg_startDate),
        );
        unittest.expect(
          queryMap["endDate"]!.first,
          unittest.equals(arg_endDate),
        );
        unittest.expect(
          queryMap["currency"]!.first,
          unittest.equals(arg_currency),
        );
        unittest.expect(
          queryMap["dimension"]!,
          unittest.equals(arg_dimension),
        );
        unittest.expect(
          queryMap["filter"]!,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["metric"]!,
          unittest.equals(arg_metric),
        );
        unittest.expect(
          queryMap["sort"]!,
          unittest.equals(arg_sort),
        );
        unittest.expect(
          core.int.parse(queryMap["startIndex"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["useTimezoneReporting"]!.first,
          unittest.equals("$arg_useTimezoneReporting"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAdsenseReportsGenerateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generate(
          arg_accountId, arg_startDate, arg_endDate,
          currency: arg_currency,
          dimension: arg_dimension,
          filter: arg_filter,
          locale: arg_locale,
          maxResults: arg_maxResults,
          metric: arg_metric,
          sort: arg_sort,
          startIndex: arg_startIndex,
          useTimezoneReporting: arg_useTimezoneReporting,
          $fields: arg_$fields);
      checkAdsenseReportsGenerateResponse(
          response as api.AdsenseReportsGenerateResponse);
    });
  });

  unittest.group('resource-AccountsReportsSavedResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.reports.saved;
      var arg_accountId = 'foo';
      var arg_savedReportId = 'foo';
      var arg_locale = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/reports/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/reports/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_savedReportId'),
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
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["startIndex"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAdsenseReportsGenerateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generate(arg_accountId, arg_savedReportId,
          locale: arg_locale,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkAdsenseReportsGenerateResponse(
          response as api.AdsenseReportsGenerateResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.reports.saved;
      var arg_accountId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/reports/saved', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/reports/saved"),
        );
        pathOffset += 14;

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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildSavedReports());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSavedReports(response as api.SavedReports);
    });
  });

  unittest.group('resource-AccountsSavedadstylesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.savedadstyles;
      var arg_accountId = 'foo';
      var arg_savedAdStyleId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/savedadstyles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/savedadstyles/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_savedAdStyleId'),
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
        var resp = convert.json.encode(buildSavedAdStyle());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_accountId, arg_savedAdStyleId,
          $fields: arg_$fields);
      checkSavedAdStyle(response as api.SavedAdStyle);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.savedadstyles;
      var arg_accountId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/savedadstyles', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/savedadstyles"),
        );
        pathOffset += 14;

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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildSavedAdStyles());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSavedAdStyles(response as api.SavedAdStyles);
    });
  });

  unittest.group('resource-AccountsUrlchannelsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).accounts.urlchannels;
      var arg_accountId = 'foo';
      var arg_adClientId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adclients/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/adclients/"),
        );
        pathOffset += 11;
        index = path.indexOf('/urlchannels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/urlchannels"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildUrlChannels());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_adClientId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkUrlChannels(response as api.UrlChannels);
    });
  });

  unittest.group('resource-AdclientsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).adclients;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("adclients"),
        );
        pathOffset += 9;

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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildAdClients());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAdClients(response as api.AdClients);
    });
  });

  unittest.group('resource-AdunitsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).adunits;
      var arg_adClientId = 'foo';
      var arg_adUnitId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/adunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/adunits/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adUnitId'),
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
        var resp = convert.json.encode(buildAdUnit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_adClientId, arg_adUnitId, $fields: arg_$fields);
      checkAdUnit(response as api.AdUnit);
    });

    unittest.test('method--getAdCode', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).adunits;
      var arg_adClientId = 'foo';
      var arg_adUnitId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/adunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/adunits/"),
        );
        pathOffset += 9;
        index = path.indexOf('/adcode', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adUnitId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/adcode"),
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
        var resp = convert.json.encode(buildAdCode());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getAdCode(arg_adClientId, arg_adUnitId,
          $fields: arg_$fields);
      checkAdCode(response as api.AdCode);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).adunits;
      var arg_adClientId = 'foo';
      var arg_includeInactive = true;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/adunits', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/adunits"),
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
          queryMap["includeInactive"]!.first,
          unittest.equals("$arg_includeInactive"),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildAdUnits());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_adClientId,
          includeInactive: arg_includeInactive,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAdUnits(response as api.AdUnits);
    });
  });

  unittest.group('resource-AdunitsCustomchannelsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).adunits.customchannels;
      var arg_adClientId = 'foo';
      var arg_adUnitId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/adunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/adunits/"),
        );
        pathOffset += 9;
        index = path.indexOf('/customchannels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adUnitId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/customchannels"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildCustomChannels());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_adClientId, arg_adUnitId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCustomChannels(response as api.CustomChannels);
    });
  });

  unittest.group('resource-AlertsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).alerts;
      var arg_alertId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("alerts/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_alertId'),
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
      await res.delete(arg_alertId, $fields: arg_$fields);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).alerts;
      var arg_locale = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("alerts"),
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
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAlerts());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(locale: arg_locale, $fields: arg_$fields);
      checkAlerts(response as api.Alerts);
    });
  });

  unittest.group('resource-CustomchannelsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).customchannels;
      var arg_adClientId = 'foo';
      var arg_customChannelId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/customchannels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/customchannels/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customChannelId'),
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
        var resp = convert.json.encode(buildCustomChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_adClientId, arg_customChannelId,
          $fields: arg_$fields);
      checkCustomChannel(response as api.CustomChannel);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).customchannels;
      var arg_adClientId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/customchannels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/customchannels"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildCustomChannels());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_adClientId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCustomChannels(response as api.CustomChannels);
    });
  });

  unittest.group('resource-CustomchannelsAdunitsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).customchannels.adunits;
      var arg_adClientId = 'foo';
      var arg_customChannelId = 'foo';
      var arg_includeInactive = true;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/customchannels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/customchannels/"),
        );
        pathOffset += 16;
        index = path.indexOf('/adunits', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customChannelId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/adunits"),
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
          queryMap["includeInactive"]!.first,
          unittest.equals("$arg_includeInactive"),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildAdUnits());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_adClientId, arg_customChannelId,
          includeInactive: arg_includeInactive,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAdUnits(response as api.AdUnits);
    });
  });

  unittest.group('resource-MetadataDimensionsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).metadata.dimensions;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("metadata/dimensions"),
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
        var resp = convert.json.encode(buildMetadata());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list($fields: arg_$fields);
      checkMetadata(response as api.Metadata);
    });
  });

  unittest.group('resource-MetadataMetricsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).metadata.metrics;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("metadata/metrics"),
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
        var resp = convert.json.encode(buildMetadata());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list($fields: arg_$fields);
      checkMetadata(response as api.Metadata);
    });
  });

  unittest.group('resource-PaymentsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).payments;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("payments"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPayments());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list($fields: arg_$fields);
      checkPayments(response as api.Payments);
    });
  });

  unittest.group('resource-ReportsResource', () {
    unittest.test('method--generate', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).reports;
      var arg_startDate = 'foo';
      var arg_endDate = 'foo';
      var arg_accountId = buildUnnamed4537();
      var arg_currency = 'foo';
      var arg_dimension = buildUnnamed4538();
      var arg_filter = buildUnnamed4539();
      var arg_locale = 'foo';
      var arg_maxResults = 42;
      var arg_metric = buildUnnamed4540();
      var arg_sort = buildUnnamed4541();
      var arg_startIndex = 42;
      var arg_useTimezoneReporting = true;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("reports"),
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
          queryMap["startDate"]!.first,
          unittest.equals(arg_startDate),
        );
        unittest.expect(
          queryMap["endDate"]!.first,
          unittest.equals(arg_endDate),
        );
        unittest.expect(
          queryMap["accountId"]!,
          unittest.equals(arg_accountId),
        );
        unittest.expect(
          queryMap["currency"]!.first,
          unittest.equals(arg_currency),
        );
        unittest.expect(
          queryMap["dimension"]!,
          unittest.equals(arg_dimension),
        );
        unittest.expect(
          queryMap["filter"]!,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["metric"]!,
          unittest.equals(arg_metric),
        );
        unittest.expect(
          queryMap["sort"]!,
          unittest.equals(arg_sort),
        );
        unittest.expect(
          core.int.parse(queryMap["startIndex"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["useTimezoneReporting"]!.first,
          unittest.equals("$arg_useTimezoneReporting"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAdsenseReportsGenerateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generate(arg_startDate, arg_endDate,
          accountId: arg_accountId,
          currency: arg_currency,
          dimension: arg_dimension,
          filter: arg_filter,
          locale: arg_locale,
          maxResults: arg_maxResults,
          metric: arg_metric,
          sort: arg_sort,
          startIndex: arg_startIndex,
          useTimezoneReporting: arg_useTimezoneReporting,
          $fields: arg_$fields);
      checkAdsenseReportsGenerateResponse(
          response as api.AdsenseReportsGenerateResponse);
    });
  });

  unittest.group('resource-ReportsSavedResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).reports.saved;
      var arg_savedReportId = 'foo';
      var arg_locale = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("reports/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_savedReportId'),
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
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["startIndex"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAdsenseReportsGenerateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generate(arg_savedReportId,
          locale: arg_locale,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkAdsenseReportsGenerateResponse(
          response as api.AdsenseReportsGenerateResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).reports.saved;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("reports/saved"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildSavedReports());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSavedReports(response as api.SavedReports);
    });
  });

  unittest.group('resource-SavedadstylesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).savedadstyles;
      var arg_savedAdStyleId = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("savedadstyles/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_savedAdStyleId'),
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
        var resp = convert.json.encode(buildSavedAdStyle());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_savedAdStyleId, $fields: arg_$fields);
      checkSavedAdStyle(response as api.SavedAdStyle);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).savedadstyles;
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("savedadstyles"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildSavedAdStyles());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSavedAdStyles(response as api.SavedAdStyles);
    });
  });

  unittest.group('resource-UrlchannelsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdSenseApi(mock).urlchannels;
      var arg_adClientId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("adsense/v1.4/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("adclients/"),
        );
        pathOffset += 10;
        index = path.indexOf('/urlchannels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_adClientId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/urlchannels"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildUrlChannels());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_adClientId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkUrlChannels(response as api.UrlChannels);
    });
  });
}

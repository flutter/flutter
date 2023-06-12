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

import 'package:googleapis/firebasedynamiclinks/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAnalyticsInfo = 0;
api.AnalyticsInfo buildAnalyticsInfo() {
  var o = api.AnalyticsInfo();
  buildCounterAnalyticsInfo++;
  if (buildCounterAnalyticsInfo < 3) {
    o.googlePlayAnalytics = buildGooglePlayAnalytics();
    o.itunesConnectAnalytics = buildITunesConnectAnalytics();
  }
  buildCounterAnalyticsInfo--;
  return o;
}

void checkAnalyticsInfo(api.AnalyticsInfo o) {
  buildCounterAnalyticsInfo++;
  if (buildCounterAnalyticsInfo < 3) {
    checkGooglePlayAnalytics(o.googlePlayAnalytics! as api.GooglePlayAnalytics);
    checkITunesConnectAnalytics(
        o.itunesConnectAnalytics! as api.ITunesConnectAnalytics);
  }
  buildCounterAnalyticsInfo--;
}

core.int buildCounterAndroidInfo = 0;
api.AndroidInfo buildAndroidInfo() {
  var o = api.AndroidInfo();
  buildCounterAndroidInfo++;
  if (buildCounterAndroidInfo < 3) {
    o.androidFallbackLink = 'foo';
    o.androidLink = 'foo';
    o.androidMinPackageVersionCode = 'foo';
    o.androidPackageName = 'foo';
  }
  buildCounterAndroidInfo--;
  return o;
}

void checkAndroidInfo(api.AndroidInfo o) {
  buildCounterAndroidInfo++;
  if (buildCounterAndroidInfo < 3) {
    unittest.expect(
      o.androidFallbackLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.androidLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.androidMinPackageVersionCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.androidPackageName!,
      unittest.equals('foo'),
    );
  }
  buildCounterAndroidInfo--;
}

core.int buildCounterCreateManagedShortLinkRequest = 0;
api.CreateManagedShortLinkRequest buildCreateManagedShortLinkRequest() {
  var o = api.CreateManagedShortLinkRequest();
  buildCounterCreateManagedShortLinkRequest++;
  if (buildCounterCreateManagedShortLinkRequest < 3) {
    o.dynamicLinkInfo = buildDynamicLinkInfo();
    o.longDynamicLink = 'foo';
    o.name = 'foo';
    o.sdkVersion = 'foo';
    o.suffix = buildSuffix();
  }
  buildCounterCreateManagedShortLinkRequest--;
  return o;
}

void checkCreateManagedShortLinkRequest(api.CreateManagedShortLinkRequest o) {
  buildCounterCreateManagedShortLinkRequest++;
  if (buildCounterCreateManagedShortLinkRequest < 3) {
    checkDynamicLinkInfo(o.dynamicLinkInfo! as api.DynamicLinkInfo);
    unittest.expect(
      o.longDynamicLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sdkVersion!,
      unittest.equals('foo'),
    );
    checkSuffix(o.suffix! as api.Suffix);
  }
  buildCounterCreateManagedShortLinkRequest--;
}

core.List<api.DynamicLinkWarning> buildUnnamed3508() {
  var o = <api.DynamicLinkWarning>[];
  o.add(buildDynamicLinkWarning());
  o.add(buildDynamicLinkWarning());
  return o;
}

void checkUnnamed3508(core.List<api.DynamicLinkWarning> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicLinkWarning(o[0] as api.DynamicLinkWarning);
  checkDynamicLinkWarning(o[1] as api.DynamicLinkWarning);
}

core.int buildCounterCreateManagedShortLinkResponse = 0;
api.CreateManagedShortLinkResponse buildCreateManagedShortLinkResponse() {
  var o = api.CreateManagedShortLinkResponse();
  buildCounterCreateManagedShortLinkResponse++;
  if (buildCounterCreateManagedShortLinkResponse < 3) {
    o.managedShortLink = buildManagedShortLink();
    o.previewLink = 'foo';
    o.warning = buildUnnamed3508();
  }
  buildCounterCreateManagedShortLinkResponse--;
  return o;
}

void checkCreateManagedShortLinkResponse(api.CreateManagedShortLinkResponse o) {
  buildCounterCreateManagedShortLinkResponse++;
  if (buildCounterCreateManagedShortLinkResponse < 3) {
    checkManagedShortLink(o.managedShortLink! as api.ManagedShortLink);
    unittest.expect(
      o.previewLink!,
      unittest.equals('foo'),
    );
    checkUnnamed3508(o.warning!);
  }
  buildCounterCreateManagedShortLinkResponse--;
}

core.int buildCounterCreateShortDynamicLinkRequest = 0;
api.CreateShortDynamicLinkRequest buildCreateShortDynamicLinkRequest() {
  var o = api.CreateShortDynamicLinkRequest();
  buildCounterCreateShortDynamicLinkRequest++;
  if (buildCounterCreateShortDynamicLinkRequest < 3) {
    o.dynamicLinkInfo = buildDynamicLinkInfo();
    o.longDynamicLink = 'foo';
    o.sdkVersion = 'foo';
    o.suffix = buildSuffix();
  }
  buildCounterCreateShortDynamicLinkRequest--;
  return o;
}

void checkCreateShortDynamicLinkRequest(api.CreateShortDynamicLinkRequest o) {
  buildCounterCreateShortDynamicLinkRequest++;
  if (buildCounterCreateShortDynamicLinkRequest < 3) {
    checkDynamicLinkInfo(o.dynamicLinkInfo! as api.DynamicLinkInfo);
    unittest.expect(
      o.longDynamicLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sdkVersion!,
      unittest.equals('foo'),
    );
    checkSuffix(o.suffix! as api.Suffix);
  }
  buildCounterCreateShortDynamicLinkRequest--;
}

core.List<api.DynamicLinkWarning> buildUnnamed3509() {
  var o = <api.DynamicLinkWarning>[];
  o.add(buildDynamicLinkWarning());
  o.add(buildDynamicLinkWarning());
  return o;
}

void checkUnnamed3509(core.List<api.DynamicLinkWarning> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicLinkWarning(o[0] as api.DynamicLinkWarning);
  checkDynamicLinkWarning(o[1] as api.DynamicLinkWarning);
}

core.int buildCounterCreateShortDynamicLinkResponse = 0;
api.CreateShortDynamicLinkResponse buildCreateShortDynamicLinkResponse() {
  var o = api.CreateShortDynamicLinkResponse();
  buildCounterCreateShortDynamicLinkResponse++;
  if (buildCounterCreateShortDynamicLinkResponse < 3) {
    o.previewLink = 'foo';
    o.shortLink = 'foo';
    o.warning = buildUnnamed3509();
  }
  buildCounterCreateShortDynamicLinkResponse--;
  return o;
}

void checkCreateShortDynamicLinkResponse(api.CreateShortDynamicLinkResponse o) {
  buildCounterCreateShortDynamicLinkResponse++;
  if (buildCounterCreateShortDynamicLinkResponse < 3) {
    unittest.expect(
      o.previewLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shortLink!,
      unittest.equals('foo'),
    );
    checkUnnamed3509(o.warning!);
  }
  buildCounterCreateShortDynamicLinkResponse--;
}

core.int buildCounterDesktopInfo = 0;
api.DesktopInfo buildDesktopInfo() {
  var o = api.DesktopInfo();
  buildCounterDesktopInfo++;
  if (buildCounterDesktopInfo < 3) {
    o.desktopFallbackLink = 'foo';
  }
  buildCounterDesktopInfo--;
  return o;
}

void checkDesktopInfo(api.DesktopInfo o) {
  buildCounterDesktopInfo++;
  if (buildCounterDesktopInfo < 3) {
    unittest.expect(
      o.desktopFallbackLink!,
      unittest.equals('foo'),
    );
  }
  buildCounterDesktopInfo--;
}

core.int buildCounterDeviceInfo = 0;
api.DeviceInfo buildDeviceInfo() {
  var o = api.DeviceInfo();
  buildCounterDeviceInfo++;
  if (buildCounterDeviceInfo < 3) {
    o.deviceModelName = 'foo';
    o.languageCode = 'foo';
    o.languageCodeFromWebview = 'foo';
    o.languageCodeRaw = 'foo';
    o.screenResolutionHeight = 'foo';
    o.screenResolutionWidth = 'foo';
    o.timezone = 'foo';
  }
  buildCounterDeviceInfo--;
  return o;
}

void checkDeviceInfo(api.DeviceInfo o) {
  buildCounterDeviceInfo++;
  if (buildCounterDeviceInfo < 3) {
    unittest.expect(
      o.deviceModelName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCodeFromWebview!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCodeRaw!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenResolutionHeight!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenResolutionWidth!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timezone!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceInfo--;
}

core.int buildCounterDynamicLinkEventStat = 0;
api.DynamicLinkEventStat buildDynamicLinkEventStat() {
  var o = api.DynamicLinkEventStat();
  buildCounterDynamicLinkEventStat++;
  if (buildCounterDynamicLinkEventStat < 3) {
    o.count = 'foo';
    o.event = 'foo';
    o.platform = 'foo';
  }
  buildCounterDynamicLinkEventStat--;
  return o;
}

void checkDynamicLinkEventStat(api.DynamicLinkEventStat o) {
  buildCounterDynamicLinkEventStat++;
  if (buildCounterDynamicLinkEventStat < 3) {
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.event!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platform!,
      unittest.equals('foo'),
    );
  }
  buildCounterDynamicLinkEventStat--;
}

core.int buildCounterDynamicLinkInfo = 0;
api.DynamicLinkInfo buildDynamicLinkInfo() {
  var o = api.DynamicLinkInfo();
  buildCounterDynamicLinkInfo++;
  if (buildCounterDynamicLinkInfo < 3) {
    o.analyticsInfo = buildAnalyticsInfo();
    o.androidInfo = buildAndroidInfo();
    o.desktopInfo = buildDesktopInfo();
    o.domainUriPrefix = 'foo';
    o.dynamicLinkDomain = 'foo';
    o.iosInfo = buildIosInfo();
    o.link = 'foo';
    o.navigationInfo = buildNavigationInfo();
    o.socialMetaTagInfo = buildSocialMetaTagInfo();
  }
  buildCounterDynamicLinkInfo--;
  return o;
}

void checkDynamicLinkInfo(api.DynamicLinkInfo o) {
  buildCounterDynamicLinkInfo++;
  if (buildCounterDynamicLinkInfo < 3) {
    checkAnalyticsInfo(o.analyticsInfo! as api.AnalyticsInfo);
    checkAndroidInfo(o.androidInfo! as api.AndroidInfo);
    checkDesktopInfo(o.desktopInfo! as api.DesktopInfo);
    unittest.expect(
      o.domainUriPrefix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dynamicLinkDomain!,
      unittest.equals('foo'),
    );
    checkIosInfo(o.iosInfo! as api.IosInfo);
    unittest.expect(
      o.link!,
      unittest.equals('foo'),
    );
    checkNavigationInfo(o.navigationInfo! as api.NavigationInfo);
    checkSocialMetaTagInfo(o.socialMetaTagInfo! as api.SocialMetaTagInfo);
  }
  buildCounterDynamicLinkInfo--;
}

core.List<api.DynamicLinkEventStat> buildUnnamed3510() {
  var o = <api.DynamicLinkEventStat>[];
  o.add(buildDynamicLinkEventStat());
  o.add(buildDynamicLinkEventStat());
  return o;
}

void checkUnnamed3510(core.List<api.DynamicLinkEventStat> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicLinkEventStat(o[0] as api.DynamicLinkEventStat);
  checkDynamicLinkEventStat(o[1] as api.DynamicLinkEventStat);
}

core.int buildCounterDynamicLinkStats = 0;
api.DynamicLinkStats buildDynamicLinkStats() {
  var o = api.DynamicLinkStats();
  buildCounterDynamicLinkStats++;
  if (buildCounterDynamicLinkStats < 3) {
    o.linkEventStats = buildUnnamed3510();
  }
  buildCounterDynamicLinkStats--;
  return o;
}

void checkDynamicLinkStats(api.DynamicLinkStats o) {
  buildCounterDynamicLinkStats++;
  if (buildCounterDynamicLinkStats < 3) {
    checkUnnamed3510(o.linkEventStats!);
  }
  buildCounterDynamicLinkStats--;
}

core.int buildCounterDynamicLinkWarning = 0;
api.DynamicLinkWarning buildDynamicLinkWarning() {
  var o = api.DynamicLinkWarning();
  buildCounterDynamicLinkWarning++;
  if (buildCounterDynamicLinkWarning < 3) {
    o.warningCode = 'foo';
    o.warningDocumentLink = 'foo';
    o.warningMessage = 'foo';
  }
  buildCounterDynamicLinkWarning--;
  return o;
}

void checkDynamicLinkWarning(api.DynamicLinkWarning o) {
  buildCounterDynamicLinkWarning++;
  if (buildCounterDynamicLinkWarning < 3) {
    unittest.expect(
      o.warningCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.warningDocumentLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.warningMessage!,
      unittest.equals('foo'),
    );
  }
  buildCounterDynamicLinkWarning--;
}

core.int buildCounterGetIosPostInstallAttributionRequest = 0;
api.GetIosPostInstallAttributionRequest
    buildGetIosPostInstallAttributionRequest() {
  var o = api.GetIosPostInstallAttributionRequest();
  buildCounterGetIosPostInstallAttributionRequest++;
  if (buildCounterGetIosPostInstallAttributionRequest < 3) {
    o.appInstallationTime = 'foo';
    o.bundleId = 'foo';
    o.device = buildDeviceInfo();
    o.iosVersion = 'foo';
    o.retrievalMethod = 'foo';
    o.sdkVersion = 'foo';
    o.uniqueMatchLinkToCheck = 'foo';
    o.visualStyle = 'foo';
  }
  buildCounterGetIosPostInstallAttributionRequest--;
  return o;
}

void checkGetIosPostInstallAttributionRequest(
    api.GetIosPostInstallAttributionRequest o) {
  buildCounterGetIosPostInstallAttributionRequest++;
  if (buildCounterGetIosPostInstallAttributionRequest < 3) {
    unittest.expect(
      o.appInstallationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bundleId!,
      unittest.equals('foo'),
    );
    checkDeviceInfo(o.device! as api.DeviceInfo);
    unittest.expect(
      o.iosVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.retrievalMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sdkVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uniqueMatchLinkToCheck!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visualStyle!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetIosPostInstallAttributionRequest--;
}

core.int buildCounterGetIosPostInstallAttributionResponse = 0;
api.GetIosPostInstallAttributionResponse
    buildGetIosPostInstallAttributionResponse() {
  var o = api.GetIosPostInstallAttributionResponse();
  buildCounterGetIosPostInstallAttributionResponse++;
  if (buildCounterGetIosPostInstallAttributionResponse < 3) {
    o.appMinimumVersion = 'foo';
    o.attributionConfidence = 'foo';
    o.deepLink = 'foo';
    o.externalBrowserDestinationLink = 'foo';
    o.fallbackLink = 'foo';
    o.invitationId = 'foo';
    o.isStrongMatchExecutable = true;
    o.matchMessage = 'foo';
    o.requestIpVersion = 'foo';
    o.requestedLink = 'foo';
    o.resolvedLink = 'foo';
    o.utmCampaign = 'foo';
    o.utmContent = 'foo';
    o.utmMedium = 'foo';
    o.utmSource = 'foo';
    o.utmTerm = 'foo';
  }
  buildCounterGetIosPostInstallAttributionResponse--;
  return o;
}

void checkGetIosPostInstallAttributionResponse(
    api.GetIosPostInstallAttributionResponse o) {
  buildCounterGetIosPostInstallAttributionResponse++;
  if (buildCounterGetIosPostInstallAttributionResponse < 3) {
    unittest.expect(
      o.appMinimumVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.attributionConfidence!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deepLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalBrowserDestinationLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fallbackLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invitationId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isStrongMatchExecutable!, unittest.isTrue);
    unittest.expect(
      o.matchMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestIpVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestedLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resolvedLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmCampaign!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmContent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmMedium!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmTerm!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetIosPostInstallAttributionResponse--;
}

core.int buildCounterGetIosReopenAttributionRequest = 0;
api.GetIosReopenAttributionRequest buildGetIosReopenAttributionRequest() {
  var o = api.GetIosReopenAttributionRequest();
  buildCounterGetIosReopenAttributionRequest++;
  if (buildCounterGetIosReopenAttributionRequest < 3) {
    o.bundleId = 'foo';
    o.requestedLink = 'foo';
    o.sdkVersion = 'foo';
  }
  buildCounterGetIosReopenAttributionRequest--;
  return o;
}

void checkGetIosReopenAttributionRequest(api.GetIosReopenAttributionRequest o) {
  buildCounterGetIosReopenAttributionRequest++;
  if (buildCounterGetIosReopenAttributionRequest < 3) {
    unittest.expect(
      o.bundleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestedLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sdkVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetIosReopenAttributionRequest--;
}

core.int buildCounterGetIosReopenAttributionResponse = 0;
api.GetIosReopenAttributionResponse buildGetIosReopenAttributionResponse() {
  var o = api.GetIosReopenAttributionResponse();
  buildCounterGetIosReopenAttributionResponse++;
  if (buildCounterGetIosReopenAttributionResponse < 3) {
    o.deepLink = 'foo';
    o.invitationId = 'foo';
    o.iosMinAppVersion = 'foo';
    o.resolvedLink = 'foo';
    o.utmCampaign = 'foo';
    o.utmContent = 'foo';
    o.utmMedium = 'foo';
    o.utmSource = 'foo';
    o.utmTerm = 'foo';
  }
  buildCounterGetIosReopenAttributionResponse--;
  return o;
}

void checkGetIosReopenAttributionResponse(
    api.GetIosReopenAttributionResponse o) {
  buildCounterGetIosReopenAttributionResponse++;
  if (buildCounterGetIosReopenAttributionResponse < 3) {
    unittest.expect(
      o.deepLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invitationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosMinAppVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resolvedLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmCampaign!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmContent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmMedium!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmTerm!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetIosReopenAttributionResponse--;
}

core.int buildCounterGooglePlayAnalytics = 0;
api.GooglePlayAnalytics buildGooglePlayAnalytics() {
  var o = api.GooglePlayAnalytics();
  buildCounterGooglePlayAnalytics++;
  if (buildCounterGooglePlayAnalytics < 3) {
    o.gclid = 'foo';
    o.utmCampaign = 'foo';
    o.utmContent = 'foo';
    o.utmMedium = 'foo';
    o.utmSource = 'foo';
    o.utmTerm = 'foo';
  }
  buildCounterGooglePlayAnalytics--;
  return o;
}

void checkGooglePlayAnalytics(api.GooglePlayAnalytics o) {
  buildCounterGooglePlayAnalytics++;
  if (buildCounterGooglePlayAnalytics < 3) {
    unittest.expect(
      o.gclid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmCampaign!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmContent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmMedium!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.utmTerm!,
      unittest.equals('foo'),
    );
  }
  buildCounterGooglePlayAnalytics--;
}

core.int buildCounterITunesConnectAnalytics = 0;
api.ITunesConnectAnalytics buildITunesConnectAnalytics() {
  var o = api.ITunesConnectAnalytics();
  buildCounterITunesConnectAnalytics++;
  if (buildCounterITunesConnectAnalytics < 3) {
    o.at = 'foo';
    o.ct = 'foo';
    o.mt = 'foo';
    o.pt = 'foo';
  }
  buildCounterITunesConnectAnalytics--;
  return o;
}

void checkITunesConnectAnalytics(api.ITunesConnectAnalytics o) {
  buildCounterITunesConnectAnalytics++;
  if (buildCounterITunesConnectAnalytics < 3) {
    unittest.expect(
      o.at!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ct!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pt!,
      unittest.equals('foo'),
    );
  }
  buildCounterITunesConnectAnalytics--;
}

core.int buildCounterIosInfo = 0;
api.IosInfo buildIosInfo() {
  var o = api.IosInfo();
  buildCounterIosInfo++;
  if (buildCounterIosInfo < 3) {
    o.iosAppStoreId = 'foo';
    o.iosBundleId = 'foo';
    o.iosCustomScheme = 'foo';
    o.iosFallbackLink = 'foo';
    o.iosIpadBundleId = 'foo';
    o.iosIpadFallbackLink = 'foo';
    o.iosMinimumVersion = 'foo';
  }
  buildCounterIosInfo--;
  return o;
}

void checkIosInfo(api.IosInfo o) {
  buildCounterIosInfo++;
  if (buildCounterIosInfo < 3) {
    unittest.expect(
      o.iosAppStoreId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosBundleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosCustomScheme!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosFallbackLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosIpadBundleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosIpadFallbackLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosMinimumVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterIosInfo--;
}

core.List<core.String> buildUnnamed3511() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3511(core.List<core.String> o) {
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

core.int buildCounterManagedShortLink = 0;
api.ManagedShortLink buildManagedShortLink() {
  var o = api.ManagedShortLink();
  buildCounterManagedShortLink++;
  if (buildCounterManagedShortLink < 3) {
    o.creationTime = 'foo';
    o.flaggedAttribute = buildUnnamed3511();
    o.info = buildDynamicLinkInfo();
    o.link = 'foo';
    o.linkName = 'foo';
    o.visibility = 'foo';
  }
  buildCounterManagedShortLink--;
  return o;
}

void checkManagedShortLink(api.ManagedShortLink o) {
  buildCounterManagedShortLink++;
  if (buildCounterManagedShortLink < 3) {
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    checkUnnamed3511(o.flaggedAttribute!);
    checkDynamicLinkInfo(o.info! as api.DynamicLinkInfo);
    unittest.expect(
      o.link!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.linkName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visibility!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedShortLink--;
}

core.int buildCounterNavigationInfo = 0;
api.NavigationInfo buildNavigationInfo() {
  var o = api.NavigationInfo();
  buildCounterNavigationInfo++;
  if (buildCounterNavigationInfo < 3) {
    o.enableForcedRedirect = true;
  }
  buildCounterNavigationInfo--;
  return o;
}

void checkNavigationInfo(api.NavigationInfo o) {
  buildCounterNavigationInfo++;
  if (buildCounterNavigationInfo < 3) {
    unittest.expect(o.enableForcedRedirect!, unittest.isTrue);
  }
  buildCounterNavigationInfo--;
}

core.int buildCounterSocialMetaTagInfo = 0;
api.SocialMetaTagInfo buildSocialMetaTagInfo() {
  var o = api.SocialMetaTagInfo();
  buildCounterSocialMetaTagInfo++;
  if (buildCounterSocialMetaTagInfo < 3) {
    o.socialDescription = 'foo';
    o.socialImageLink = 'foo';
    o.socialTitle = 'foo';
  }
  buildCounterSocialMetaTagInfo--;
  return o;
}

void checkSocialMetaTagInfo(api.SocialMetaTagInfo o) {
  buildCounterSocialMetaTagInfo++;
  if (buildCounterSocialMetaTagInfo < 3) {
    unittest.expect(
      o.socialDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.socialImageLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.socialTitle!,
      unittest.equals('foo'),
    );
  }
  buildCounterSocialMetaTagInfo--;
}

core.int buildCounterSuffix = 0;
api.Suffix buildSuffix() {
  var o = api.Suffix();
  buildCounterSuffix++;
  if (buildCounterSuffix < 3) {
    o.customSuffix = 'foo';
    o.option = 'foo';
  }
  buildCounterSuffix--;
  return o;
}

void checkSuffix(api.Suffix o) {
  buildCounterSuffix++;
  if (buildCounterSuffix < 3) {
    unittest.expect(
      o.customSuffix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.option!,
      unittest.equals('foo'),
    );
  }
  buildCounterSuffix--;
}

void main() {
  unittest.group('obj-schema-AnalyticsInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyticsInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyticsInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyticsInfo(od as api.AnalyticsInfo);
    });
  });

  unittest.group('obj-schema-AndroidInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidInfo(od as api.AndroidInfo);
    });
  });

  unittest.group('obj-schema-CreateManagedShortLinkRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateManagedShortLinkRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateManagedShortLinkRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateManagedShortLinkRequest(
          od as api.CreateManagedShortLinkRequest);
    });
  });

  unittest.group('obj-schema-CreateManagedShortLinkResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateManagedShortLinkResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateManagedShortLinkResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateManagedShortLinkResponse(
          od as api.CreateManagedShortLinkResponse);
    });
  });

  unittest.group('obj-schema-CreateShortDynamicLinkRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateShortDynamicLinkRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateShortDynamicLinkRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateShortDynamicLinkRequest(
          od as api.CreateShortDynamicLinkRequest);
    });
  });

  unittest.group('obj-schema-CreateShortDynamicLinkResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateShortDynamicLinkResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateShortDynamicLinkResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateShortDynamicLinkResponse(
          od as api.CreateShortDynamicLinkResponse);
    });
  });

  unittest.group('obj-schema-DesktopInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDesktopInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DesktopInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDesktopInfo(od as api.DesktopInfo);
    });
  });

  unittest.group('obj-schema-DeviceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DeviceInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDeviceInfo(od as api.DeviceInfo);
    });
  });

  unittest.group('obj-schema-DynamicLinkEventStat', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicLinkEventStat();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicLinkEventStat.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicLinkEventStat(od as api.DynamicLinkEventStat);
    });
  });

  unittest.group('obj-schema-DynamicLinkInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicLinkInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicLinkInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicLinkInfo(od as api.DynamicLinkInfo);
    });
  });

  unittest.group('obj-schema-DynamicLinkStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicLinkStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicLinkStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicLinkStats(od as api.DynamicLinkStats);
    });
  });

  unittest.group('obj-schema-DynamicLinkWarning', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicLinkWarning();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicLinkWarning.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicLinkWarning(od as api.DynamicLinkWarning);
    });
  });

  unittest.group('obj-schema-GetIosPostInstallAttributionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetIosPostInstallAttributionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetIosPostInstallAttributionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetIosPostInstallAttributionRequest(
          od as api.GetIosPostInstallAttributionRequest);
    });
  });

  unittest.group('obj-schema-GetIosPostInstallAttributionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetIosPostInstallAttributionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetIosPostInstallAttributionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetIosPostInstallAttributionResponse(
          od as api.GetIosPostInstallAttributionResponse);
    });
  });

  unittest.group('obj-schema-GetIosReopenAttributionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetIosReopenAttributionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetIosReopenAttributionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetIosReopenAttributionRequest(
          od as api.GetIosReopenAttributionRequest);
    });
  });

  unittest.group('obj-schema-GetIosReopenAttributionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetIosReopenAttributionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetIosReopenAttributionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetIosReopenAttributionResponse(
          od as api.GetIosReopenAttributionResponse);
    });
  });

  unittest.group('obj-schema-GooglePlayAnalytics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGooglePlayAnalytics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GooglePlayAnalytics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGooglePlayAnalytics(od as api.GooglePlayAnalytics);
    });
  });

  unittest.group('obj-schema-ITunesConnectAnalytics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildITunesConnectAnalytics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ITunesConnectAnalytics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkITunesConnectAnalytics(od as api.ITunesConnectAnalytics);
    });
  });

  unittest.group('obj-schema-IosInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IosInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIosInfo(od as api.IosInfo);
    });
  });

  unittest.group('obj-schema-ManagedShortLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedShortLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedShortLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedShortLink(od as api.ManagedShortLink);
    });
  });

  unittest.group('obj-schema-NavigationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNavigationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NavigationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNavigationInfo(od as api.NavigationInfo);
    });
  });

  unittest.group('obj-schema-SocialMetaTagInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSocialMetaTagInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SocialMetaTagInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSocialMetaTagInfo(od as api.SocialMetaTagInfo);
    });
  });

  unittest.group('obj-schema-Suffix', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuffix();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Suffix.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSuffix(od as api.Suffix);
    });
  });

  unittest.group('resource-ManagedShortLinksResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.FirebaseDynamicLinksApi(mock).managedShortLinks;
      var arg_request = buildCreateManagedShortLinkRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateManagedShortLinkRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateManagedShortLinkRequest(
            obj as api.CreateManagedShortLinkRequest);

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
          unittest.equals("v1/managedShortLinks:create"),
        );
        pathOffset += 27;

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
        var resp = convert.json.encode(buildCreateManagedShortLinkResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkCreateManagedShortLinkResponse(
          response as api.CreateManagedShortLinkResponse);
    });
  });

  unittest.group('resource-ShortLinksResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.FirebaseDynamicLinksApi(mock).shortLinks;
      var arg_request = buildCreateShortDynamicLinkRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateShortDynamicLinkRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateShortDynamicLinkRequest(
            obj as api.CreateShortDynamicLinkRequest);

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
          unittest.equals("v1/shortLinks"),
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
        var resp = convert.json.encode(buildCreateShortDynamicLinkResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkCreateShortDynamicLinkResponse(
          response as api.CreateShortDynamicLinkResponse);
    });
  });

  unittest.group('resource-V1Resource', () {
    unittest.test('method--getLinkStats', () async {
      var mock = HttpServerMock();
      var res = api.FirebaseDynamicLinksApi(mock).v1;
      var arg_dynamicLink = 'foo';
      var arg_durationDays = 'foo';
      var arg_sdkVersion = 'foo';
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
        index = path.indexOf('/linkStats', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_dynamicLink'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/linkStats"),
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
          queryMap["durationDays"]!.first,
          unittest.equals(arg_durationDays),
        );
        unittest.expect(
          queryMap["sdkVersion"]!.first,
          unittest.equals(arg_sdkVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDynamicLinkStats());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getLinkStats(arg_dynamicLink,
          durationDays: arg_durationDays,
          sdkVersion: arg_sdkVersion,
          $fields: arg_$fields);
      checkDynamicLinkStats(response as api.DynamicLinkStats);
    });

    unittest.test('method--installAttribution', () async {
      var mock = HttpServerMock();
      var res = api.FirebaseDynamicLinksApi(mock).v1;
      var arg_request = buildGetIosPostInstallAttributionRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIosPostInstallAttributionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIosPostInstallAttributionRequest(
            obj as api.GetIosPostInstallAttributionRequest);

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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("v1/installAttribution"),
        );
        pathOffset += 21;

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
            convert.json.encode(buildGetIosPostInstallAttributionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.installAttribution(arg_request, $fields: arg_$fields);
      checkGetIosPostInstallAttributionResponse(
          response as api.GetIosPostInstallAttributionResponse);
    });

    unittest.test('method--reopenAttribution', () async {
      var mock = HttpServerMock();
      var res = api.FirebaseDynamicLinksApi(mock).v1;
      var arg_request = buildGetIosReopenAttributionRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIosReopenAttributionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIosReopenAttributionRequest(
            obj as api.GetIosReopenAttributionRequest);

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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("v1/reopenAttribution"),
        );
        pathOffset += 20;

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
        var resp = convert.json.encode(buildGetIosReopenAttributionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.reopenAttribution(arg_request, $fields: arg_$fields);
      checkGetIosReopenAttributionResponse(
          response as api.GetIosReopenAttributionResponse);
    });
  });
}

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

import 'package:googleapis/androidpublisher/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterApk = 0;
api.Apk buildApk() {
  var o = api.Apk();
  buildCounterApk++;
  if (buildCounterApk < 3) {
    o.binary = buildApkBinary();
    o.versionCode = 42;
  }
  buildCounterApk--;
  return o;
}

void checkApk(api.Apk o) {
  buildCounterApk++;
  if (buildCounterApk < 3) {
    checkApkBinary(o.binary! as api.ApkBinary);
    unittest.expect(
      o.versionCode!,
      unittest.equals(42),
    );
  }
  buildCounterApk--;
}

core.int buildCounterApkBinary = 0;
api.ApkBinary buildApkBinary() {
  var o = api.ApkBinary();
  buildCounterApkBinary++;
  if (buildCounterApkBinary < 3) {
    o.sha1 = 'foo';
    o.sha256 = 'foo';
  }
  buildCounterApkBinary--;
  return o;
}

void checkApkBinary(api.ApkBinary o) {
  buildCounterApkBinary++;
  if (buildCounterApkBinary < 3) {
    unittest.expect(
      o.sha1!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha256!,
      unittest.equals('foo'),
    );
  }
  buildCounterApkBinary--;
}

core.int buildCounterApksAddExternallyHostedRequest = 0;
api.ApksAddExternallyHostedRequest buildApksAddExternallyHostedRequest() {
  var o = api.ApksAddExternallyHostedRequest();
  buildCounterApksAddExternallyHostedRequest++;
  if (buildCounterApksAddExternallyHostedRequest < 3) {
    o.externallyHostedApk = buildExternallyHostedApk();
  }
  buildCounterApksAddExternallyHostedRequest--;
  return o;
}

void checkApksAddExternallyHostedRequest(api.ApksAddExternallyHostedRequest o) {
  buildCounterApksAddExternallyHostedRequest++;
  if (buildCounterApksAddExternallyHostedRequest < 3) {
    checkExternallyHostedApk(o.externallyHostedApk! as api.ExternallyHostedApk);
  }
  buildCounterApksAddExternallyHostedRequest--;
}

core.int buildCounterApksAddExternallyHostedResponse = 0;
api.ApksAddExternallyHostedResponse buildApksAddExternallyHostedResponse() {
  var o = api.ApksAddExternallyHostedResponse();
  buildCounterApksAddExternallyHostedResponse++;
  if (buildCounterApksAddExternallyHostedResponse < 3) {
    o.externallyHostedApk = buildExternallyHostedApk();
  }
  buildCounterApksAddExternallyHostedResponse--;
  return o;
}

void checkApksAddExternallyHostedResponse(
    api.ApksAddExternallyHostedResponse o) {
  buildCounterApksAddExternallyHostedResponse++;
  if (buildCounterApksAddExternallyHostedResponse < 3) {
    checkExternallyHostedApk(o.externallyHostedApk! as api.ExternallyHostedApk);
  }
  buildCounterApksAddExternallyHostedResponse--;
}

core.List<api.Apk> buildUnnamed1657() {
  var o = <api.Apk>[];
  o.add(buildApk());
  o.add(buildApk());
  return o;
}

void checkUnnamed1657(core.List<api.Apk> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApk(o[0] as api.Apk);
  checkApk(o[1] as api.Apk);
}

core.int buildCounterApksListResponse = 0;
api.ApksListResponse buildApksListResponse() {
  var o = api.ApksListResponse();
  buildCounterApksListResponse++;
  if (buildCounterApksListResponse < 3) {
    o.apks = buildUnnamed1657();
    o.kind = 'foo';
  }
  buildCounterApksListResponse--;
  return o;
}

void checkApksListResponse(api.ApksListResponse o) {
  buildCounterApksListResponse++;
  if (buildCounterApksListResponse < 3) {
    checkUnnamed1657(o.apks!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterApksListResponse--;
}

core.int buildCounterAppDetails = 0;
api.AppDetails buildAppDetails() {
  var o = api.AppDetails();
  buildCounterAppDetails++;
  if (buildCounterAppDetails < 3) {
    o.contactEmail = 'foo';
    o.contactPhone = 'foo';
    o.contactWebsite = 'foo';
    o.defaultLanguage = 'foo';
  }
  buildCounterAppDetails--;
  return o;
}

void checkAppDetails(api.AppDetails o) {
  buildCounterAppDetails++;
  if (buildCounterAppDetails < 3) {
    unittest.expect(
      o.contactEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contactPhone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contactWebsite!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppDetails--;
}

core.int buildCounterAppEdit = 0;
api.AppEdit buildAppEdit() {
  var o = api.AppEdit();
  buildCounterAppEdit++;
  if (buildCounterAppEdit < 3) {
    o.expiryTimeSeconds = 'foo';
    o.id = 'foo';
  }
  buildCounterAppEdit--;
  return o;
}

void checkAppEdit(api.AppEdit o) {
  buildCounterAppEdit++;
  if (buildCounterAppEdit < 3) {
    unittest.expect(
      o.expiryTimeSeconds!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppEdit--;
}

core.int buildCounterBundle = 0;
api.Bundle buildBundle() {
  var o = api.Bundle();
  buildCounterBundle++;
  if (buildCounterBundle < 3) {
    o.sha1 = 'foo';
    o.sha256 = 'foo';
    o.versionCode = 42;
  }
  buildCounterBundle--;
  return o;
}

void checkBundle(api.Bundle o) {
  buildCounterBundle++;
  if (buildCounterBundle < 3) {
    unittest.expect(
      o.sha1!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha256!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionCode!,
      unittest.equals(42),
    );
  }
  buildCounterBundle--;
}

core.List<api.Bundle> buildUnnamed1658() {
  var o = <api.Bundle>[];
  o.add(buildBundle());
  o.add(buildBundle());
  return o;
}

void checkUnnamed1658(core.List<api.Bundle> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBundle(o[0] as api.Bundle);
  checkBundle(o[1] as api.Bundle);
}

core.int buildCounterBundlesListResponse = 0;
api.BundlesListResponse buildBundlesListResponse() {
  var o = api.BundlesListResponse();
  buildCounterBundlesListResponse++;
  if (buildCounterBundlesListResponse < 3) {
    o.bundles = buildUnnamed1658();
    o.kind = 'foo';
  }
  buildCounterBundlesListResponse--;
  return o;
}

void checkBundlesListResponse(api.BundlesListResponse o) {
  buildCounterBundlesListResponse++;
  if (buildCounterBundlesListResponse < 3) {
    checkUnnamed1658(o.bundles!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterBundlesListResponse--;
}

core.int buildCounterComment = 0;
api.Comment buildComment() {
  var o = api.Comment();
  buildCounterComment++;
  if (buildCounterComment < 3) {
    o.developerComment = buildDeveloperComment();
    o.userComment = buildUserComment();
  }
  buildCounterComment--;
  return o;
}

void checkComment(api.Comment o) {
  buildCounterComment++;
  if (buildCounterComment < 3) {
    checkDeveloperComment(o.developerComment! as api.DeveloperComment);
    checkUserComment(o.userComment! as api.UserComment);
  }
  buildCounterComment--;
}

core.List<core.String> buildUnnamed1659() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1659(core.List<core.String> o) {
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

core.int buildCounterCountryTargeting = 0;
api.CountryTargeting buildCountryTargeting() {
  var o = api.CountryTargeting();
  buildCounterCountryTargeting++;
  if (buildCounterCountryTargeting < 3) {
    o.countries = buildUnnamed1659();
    o.includeRestOfWorld = true;
  }
  buildCounterCountryTargeting--;
  return o;
}

void checkCountryTargeting(api.CountryTargeting o) {
  buildCounterCountryTargeting++;
  if (buildCounterCountryTargeting < 3) {
    checkUnnamed1659(o.countries!);
    unittest.expect(o.includeRestOfWorld!, unittest.isTrue);
  }
  buildCounterCountryTargeting--;
}

core.int buildCounterDeobfuscationFile = 0;
api.DeobfuscationFile buildDeobfuscationFile() {
  var o = api.DeobfuscationFile();
  buildCounterDeobfuscationFile++;
  if (buildCounterDeobfuscationFile < 3) {
    o.symbolType = 'foo';
  }
  buildCounterDeobfuscationFile--;
  return o;
}

void checkDeobfuscationFile(api.DeobfuscationFile o) {
  buildCounterDeobfuscationFile++;
  if (buildCounterDeobfuscationFile < 3) {
    unittest.expect(
      o.symbolType!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeobfuscationFile--;
}

core.int buildCounterDeobfuscationFilesUploadResponse = 0;
api.DeobfuscationFilesUploadResponse buildDeobfuscationFilesUploadResponse() {
  var o = api.DeobfuscationFilesUploadResponse();
  buildCounterDeobfuscationFilesUploadResponse++;
  if (buildCounterDeobfuscationFilesUploadResponse < 3) {
    o.deobfuscationFile = buildDeobfuscationFile();
  }
  buildCounterDeobfuscationFilesUploadResponse--;
  return o;
}

void checkDeobfuscationFilesUploadResponse(
    api.DeobfuscationFilesUploadResponse o) {
  buildCounterDeobfuscationFilesUploadResponse++;
  if (buildCounterDeobfuscationFilesUploadResponse < 3) {
    checkDeobfuscationFile(o.deobfuscationFile! as api.DeobfuscationFile);
  }
  buildCounterDeobfuscationFilesUploadResponse--;
}

core.int buildCounterDeveloperComment = 0;
api.DeveloperComment buildDeveloperComment() {
  var o = api.DeveloperComment();
  buildCounterDeveloperComment++;
  if (buildCounterDeveloperComment < 3) {
    o.lastModified = buildTimestamp();
    o.text = 'foo';
  }
  buildCounterDeveloperComment--;
  return o;
}

void checkDeveloperComment(api.DeveloperComment o) {
  buildCounterDeveloperComment++;
  if (buildCounterDeveloperComment < 3) {
    checkTimestamp(o.lastModified! as api.Timestamp);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeveloperComment--;
}

core.int buildCounterDeviceMetadata = 0;
api.DeviceMetadata buildDeviceMetadata() {
  var o = api.DeviceMetadata();
  buildCounterDeviceMetadata++;
  if (buildCounterDeviceMetadata < 3) {
    o.cpuMake = 'foo';
    o.cpuModel = 'foo';
    o.deviceClass = 'foo';
    o.glEsVersion = 42;
    o.manufacturer = 'foo';
    o.nativePlatform = 'foo';
    o.productName = 'foo';
    o.ramMb = 42;
    o.screenDensityDpi = 42;
    o.screenHeightPx = 42;
    o.screenWidthPx = 42;
  }
  buildCounterDeviceMetadata--;
  return o;
}

void checkDeviceMetadata(api.DeviceMetadata o) {
  buildCounterDeviceMetadata++;
  if (buildCounterDeviceMetadata < 3) {
    unittest.expect(
      o.cpuMake!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cpuModel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deviceClass!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.glEsVersion!,
      unittest.equals(42),
    );
    unittest.expect(
      o.manufacturer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nativePlatform!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ramMb!,
      unittest.equals(42),
    );
    unittest.expect(
      o.screenDensityDpi!,
      unittest.equals(42),
    );
    unittest.expect(
      o.screenHeightPx!,
      unittest.equals(42),
    );
    unittest.expect(
      o.screenWidthPx!,
      unittest.equals(42),
    );
  }
  buildCounterDeviceMetadata--;
}

core.List<core.String> buildUnnamed1660() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1660(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1661() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1661(core.List<core.String> o) {
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

core.int buildCounterDeviceSpec = 0;
api.DeviceSpec buildDeviceSpec() {
  var o = api.DeviceSpec();
  buildCounterDeviceSpec++;
  if (buildCounterDeviceSpec < 3) {
    o.screenDensity = 42;
    o.supportedAbis = buildUnnamed1660();
    o.supportedLocales = buildUnnamed1661();
  }
  buildCounterDeviceSpec--;
  return o;
}

void checkDeviceSpec(api.DeviceSpec o) {
  buildCounterDeviceSpec++;
  if (buildCounterDeviceSpec < 3) {
    unittest.expect(
      o.screenDensity!,
      unittest.equals(42),
    );
    checkUnnamed1660(o.supportedAbis!);
    checkUnnamed1661(o.supportedLocales!);
  }
  buildCounterDeviceSpec--;
}

core.int buildCounterExpansionFile = 0;
api.ExpansionFile buildExpansionFile() {
  var o = api.ExpansionFile();
  buildCounterExpansionFile++;
  if (buildCounterExpansionFile < 3) {
    o.fileSize = 'foo';
    o.referencesVersion = 42;
  }
  buildCounterExpansionFile--;
  return o;
}

void checkExpansionFile(api.ExpansionFile o) {
  buildCounterExpansionFile++;
  if (buildCounterExpansionFile < 3) {
    unittest.expect(
      o.fileSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referencesVersion!,
      unittest.equals(42),
    );
  }
  buildCounterExpansionFile--;
}

core.int buildCounterExpansionFilesUploadResponse = 0;
api.ExpansionFilesUploadResponse buildExpansionFilesUploadResponse() {
  var o = api.ExpansionFilesUploadResponse();
  buildCounterExpansionFilesUploadResponse++;
  if (buildCounterExpansionFilesUploadResponse < 3) {
    o.expansionFile = buildExpansionFile();
  }
  buildCounterExpansionFilesUploadResponse--;
  return o;
}

void checkExpansionFilesUploadResponse(api.ExpansionFilesUploadResponse o) {
  buildCounterExpansionFilesUploadResponse++;
  if (buildCounterExpansionFilesUploadResponse < 3) {
    checkExpansionFile(o.expansionFile! as api.ExpansionFile);
  }
  buildCounterExpansionFilesUploadResponse--;
}

core.List<core.String> buildUnnamed1662() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1662(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1663() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1663(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1664() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1664(core.List<core.String> o) {
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

core.List<api.UsesPermission> buildUnnamed1665() {
  var o = <api.UsesPermission>[];
  o.add(buildUsesPermission());
  o.add(buildUsesPermission());
  return o;
}

void checkUnnamed1665(core.List<api.UsesPermission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUsesPermission(o[0] as api.UsesPermission);
  checkUsesPermission(o[1] as api.UsesPermission);
}

core.int buildCounterExternallyHostedApk = 0;
api.ExternallyHostedApk buildExternallyHostedApk() {
  var o = api.ExternallyHostedApk();
  buildCounterExternallyHostedApk++;
  if (buildCounterExternallyHostedApk < 3) {
    o.applicationLabel = 'foo';
    o.certificateBase64s = buildUnnamed1662();
    o.externallyHostedUrl = 'foo';
    o.fileSha1Base64 = 'foo';
    o.fileSha256Base64 = 'foo';
    o.fileSize = 'foo';
    o.iconBase64 = 'foo';
    o.maximumSdk = 42;
    o.minimumSdk = 42;
    o.nativeCodes = buildUnnamed1663();
    o.packageName = 'foo';
    o.usesFeatures = buildUnnamed1664();
    o.usesPermissions = buildUnnamed1665();
    o.versionCode = 42;
    o.versionName = 'foo';
  }
  buildCounterExternallyHostedApk--;
  return o;
}

void checkExternallyHostedApk(api.ExternallyHostedApk o) {
  buildCounterExternallyHostedApk++;
  if (buildCounterExternallyHostedApk < 3) {
    unittest.expect(
      o.applicationLabel!,
      unittest.equals('foo'),
    );
    checkUnnamed1662(o.certificateBase64s!);
    unittest.expect(
      o.externallyHostedUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fileSha1Base64!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fileSha256Base64!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fileSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iconBase64!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maximumSdk!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minimumSdk!,
      unittest.equals(42),
    );
    checkUnnamed1663(o.nativeCodes!);
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    checkUnnamed1664(o.usesFeatures!);
    checkUnnamed1665(o.usesPermissions!);
    unittest.expect(
      o.versionCode!,
      unittest.equals(42),
    );
    unittest.expect(
      o.versionName!,
      unittest.equals('foo'),
    );
  }
  buildCounterExternallyHostedApk--;
}

core.int buildCounterImage = 0;
api.Image buildImage() {
  var o = api.Image();
  buildCounterImage++;
  if (buildCounterImage < 3) {
    o.id = 'foo';
    o.sha1 = 'foo';
    o.sha256 = 'foo';
    o.url = 'foo';
  }
  buildCounterImage--;
  return o;
}

void checkImage(api.Image o) {
  buildCounterImage++;
  if (buildCounterImage < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha1!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha256!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterImage--;
}

core.List<api.Image> buildUnnamed1666() {
  var o = <api.Image>[];
  o.add(buildImage());
  o.add(buildImage());
  return o;
}

void checkUnnamed1666(core.List<api.Image> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImage(o[0] as api.Image);
  checkImage(o[1] as api.Image);
}

core.int buildCounterImagesDeleteAllResponse = 0;
api.ImagesDeleteAllResponse buildImagesDeleteAllResponse() {
  var o = api.ImagesDeleteAllResponse();
  buildCounterImagesDeleteAllResponse++;
  if (buildCounterImagesDeleteAllResponse < 3) {
    o.deleted = buildUnnamed1666();
  }
  buildCounterImagesDeleteAllResponse--;
  return o;
}

void checkImagesDeleteAllResponse(api.ImagesDeleteAllResponse o) {
  buildCounterImagesDeleteAllResponse++;
  if (buildCounterImagesDeleteAllResponse < 3) {
    checkUnnamed1666(o.deleted!);
  }
  buildCounterImagesDeleteAllResponse--;
}

core.List<api.Image> buildUnnamed1667() {
  var o = <api.Image>[];
  o.add(buildImage());
  o.add(buildImage());
  return o;
}

void checkUnnamed1667(core.List<api.Image> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImage(o[0] as api.Image);
  checkImage(o[1] as api.Image);
}

core.int buildCounterImagesListResponse = 0;
api.ImagesListResponse buildImagesListResponse() {
  var o = api.ImagesListResponse();
  buildCounterImagesListResponse++;
  if (buildCounterImagesListResponse < 3) {
    o.images = buildUnnamed1667();
  }
  buildCounterImagesListResponse--;
  return o;
}

void checkImagesListResponse(api.ImagesListResponse o) {
  buildCounterImagesListResponse++;
  if (buildCounterImagesListResponse < 3) {
    checkUnnamed1667(o.images!);
  }
  buildCounterImagesListResponse--;
}

core.int buildCounterImagesUploadResponse = 0;
api.ImagesUploadResponse buildImagesUploadResponse() {
  var o = api.ImagesUploadResponse();
  buildCounterImagesUploadResponse++;
  if (buildCounterImagesUploadResponse < 3) {
    o.image = buildImage();
  }
  buildCounterImagesUploadResponse--;
  return o;
}

void checkImagesUploadResponse(api.ImagesUploadResponse o) {
  buildCounterImagesUploadResponse++;
  if (buildCounterImagesUploadResponse < 3) {
    checkImage(o.image! as api.Image);
  }
  buildCounterImagesUploadResponse--;
}

core.Map<core.String, api.InAppProductListing> buildUnnamed1668() {
  var o = <core.String, api.InAppProductListing>{};
  o['x'] = buildInAppProductListing();
  o['y'] = buildInAppProductListing();
  return o;
}

void checkUnnamed1668(core.Map<core.String, api.InAppProductListing> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInAppProductListing(o['x']! as api.InAppProductListing);
  checkInAppProductListing(o['y']! as api.InAppProductListing);
}

core.Map<core.String, api.Price> buildUnnamed1669() {
  var o = <core.String, api.Price>{};
  o['x'] = buildPrice();
  o['y'] = buildPrice();
  return o;
}

void checkUnnamed1669(core.Map<core.String, api.Price> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrice(o['x']! as api.Price);
  checkPrice(o['y']! as api.Price);
}

core.int buildCounterInAppProduct = 0;
api.InAppProduct buildInAppProduct() {
  var o = api.InAppProduct();
  buildCounterInAppProduct++;
  if (buildCounterInAppProduct < 3) {
    o.defaultLanguage = 'foo';
    o.defaultPrice = buildPrice();
    o.gracePeriod = 'foo';
    o.listings = buildUnnamed1668();
    o.packageName = 'foo';
    o.prices = buildUnnamed1669();
    o.purchaseType = 'foo';
    o.sku = 'foo';
    o.status = 'foo';
    o.subscriptionPeriod = 'foo';
    o.trialPeriod = 'foo';
  }
  buildCounterInAppProduct--;
  return o;
}

void checkInAppProduct(api.InAppProduct o) {
  buildCounterInAppProduct++;
  if (buildCounterInAppProduct < 3) {
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
    checkPrice(o.defaultPrice! as api.Price);
    unittest.expect(
      o.gracePeriod!,
      unittest.equals('foo'),
    );
    checkUnnamed1668(o.listings!);
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    checkUnnamed1669(o.prices!);
    unittest.expect(
      o.purchaseType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sku!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subscriptionPeriod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.trialPeriod!,
      unittest.equals('foo'),
    );
  }
  buildCounterInAppProduct--;
}

core.List<core.String> buildUnnamed1670() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1670(core.List<core.String> o) {
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

core.int buildCounterInAppProductListing = 0;
api.InAppProductListing buildInAppProductListing() {
  var o = api.InAppProductListing();
  buildCounterInAppProductListing++;
  if (buildCounterInAppProductListing < 3) {
    o.benefits = buildUnnamed1670();
    o.description = 'foo';
    o.title = 'foo';
  }
  buildCounterInAppProductListing--;
  return o;
}

void checkInAppProductListing(api.InAppProductListing o) {
  buildCounterInAppProductListing++;
  if (buildCounterInAppProductListing < 3) {
    checkUnnamed1670(o.benefits!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterInAppProductListing--;
}

core.List<api.InAppProduct> buildUnnamed1671() {
  var o = <api.InAppProduct>[];
  o.add(buildInAppProduct());
  o.add(buildInAppProduct());
  return o;
}

void checkUnnamed1671(core.List<api.InAppProduct> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInAppProduct(o[0] as api.InAppProduct);
  checkInAppProduct(o[1] as api.InAppProduct);
}

core.int buildCounterInappproductsListResponse = 0;
api.InappproductsListResponse buildInappproductsListResponse() {
  var o = api.InappproductsListResponse();
  buildCounterInappproductsListResponse++;
  if (buildCounterInappproductsListResponse < 3) {
    o.inappproduct = buildUnnamed1671();
    o.kind = 'foo';
    o.pageInfo = buildPageInfo();
    o.tokenPagination = buildTokenPagination();
  }
  buildCounterInappproductsListResponse--;
  return o;
}

void checkInappproductsListResponse(api.InappproductsListResponse o) {
  buildCounterInappproductsListResponse++;
  if (buildCounterInappproductsListResponse < 3) {
    checkUnnamed1671(o.inappproduct!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
  }
  buildCounterInappproductsListResponse--;
}

core.int buildCounterInternalAppSharingArtifact = 0;
api.InternalAppSharingArtifact buildInternalAppSharingArtifact() {
  var o = api.InternalAppSharingArtifact();
  buildCounterInternalAppSharingArtifact++;
  if (buildCounterInternalAppSharingArtifact < 3) {
    o.certificateFingerprint = 'foo';
    o.downloadUrl = 'foo';
    o.sha256 = 'foo';
  }
  buildCounterInternalAppSharingArtifact--;
  return o;
}

void checkInternalAppSharingArtifact(api.InternalAppSharingArtifact o) {
  buildCounterInternalAppSharingArtifact++;
  if (buildCounterInternalAppSharingArtifact < 3) {
    unittest.expect(
      o.certificateFingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.downloadUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha256!,
      unittest.equals('foo'),
    );
  }
  buildCounterInternalAppSharingArtifact--;
}

core.int buildCounterIntroductoryPriceInfo = 0;
api.IntroductoryPriceInfo buildIntroductoryPriceInfo() {
  var o = api.IntroductoryPriceInfo();
  buildCounterIntroductoryPriceInfo++;
  if (buildCounterIntroductoryPriceInfo < 3) {
    o.introductoryPriceAmountMicros = 'foo';
    o.introductoryPriceCurrencyCode = 'foo';
    o.introductoryPriceCycles = 42;
    o.introductoryPricePeriod = 'foo';
  }
  buildCounterIntroductoryPriceInfo--;
  return o;
}

void checkIntroductoryPriceInfo(api.IntroductoryPriceInfo o) {
  buildCounterIntroductoryPriceInfo++;
  if (buildCounterIntroductoryPriceInfo < 3) {
    unittest.expect(
      o.introductoryPriceAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.introductoryPriceCurrencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.introductoryPriceCycles!,
      unittest.equals(42),
    );
    unittest.expect(
      o.introductoryPricePeriod!,
      unittest.equals('foo'),
    );
  }
  buildCounterIntroductoryPriceInfo--;
}

core.int buildCounterListing = 0;
api.Listing buildListing() {
  var o = api.Listing();
  buildCounterListing++;
  if (buildCounterListing < 3) {
    o.fullDescription = 'foo';
    o.language = 'foo';
    o.shortDescription = 'foo';
    o.title = 'foo';
    o.video = 'foo';
  }
  buildCounterListing--;
  return o;
}

void checkListing(api.Listing o) {
  buildCounterListing++;
  if (buildCounterListing < 3) {
    unittest.expect(
      o.fullDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shortDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.video!,
      unittest.equals('foo'),
    );
  }
  buildCounterListing--;
}

core.List<api.Listing> buildUnnamed1672() {
  var o = <api.Listing>[];
  o.add(buildListing());
  o.add(buildListing());
  return o;
}

void checkUnnamed1672(core.List<api.Listing> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkListing(o[0] as api.Listing);
  checkListing(o[1] as api.Listing);
}

core.int buildCounterListingsListResponse = 0;
api.ListingsListResponse buildListingsListResponse() {
  var o = api.ListingsListResponse();
  buildCounterListingsListResponse++;
  if (buildCounterListingsListResponse < 3) {
    o.kind = 'foo';
    o.listings = buildUnnamed1672();
  }
  buildCounterListingsListResponse--;
  return o;
}

void checkListingsListResponse(api.ListingsListResponse o) {
  buildCounterListingsListResponse++;
  if (buildCounterListingsListResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1672(o.listings!);
  }
  buildCounterListingsListResponse--;
}

core.int buildCounterLocalizedText = 0;
api.LocalizedText buildLocalizedText() {
  var o = api.LocalizedText();
  buildCounterLocalizedText++;
  if (buildCounterLocalizedText < 3) {
    o.language = 'foo';
    o.text = 'foo';
  }
  buildCounterLocalizedText--;
  return o;
}

void checkLocalizedText(api.LocalizedText o) {
  buildCounterLocalizedText++;
  if (buildCounterLocalizedText < 3) {
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocalizedText--;
}

core.int buildCounterPageInfo = 0;
api.PageInfo buildPageInfo() {
  var o = api.PageInfo();
  buildCounterPageInfo++;
  if (buildCounterPageInfo < 3) {
    o.resultPerPage = 42;
    o.startIndex = 42;
    o.totalResults = 42;
  }
  buildCounterPageInfo--;
  return o;
}

void checkPageInfo(api.PageInfo o) {
  buildCounterPageInfo++;
  if (buildCounterPageInfo < 3) {
    unittest.expect(
      o.resultPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
  }
  buildCounterPageInfo--;
}

core.int buildCounterPrice = 0;
api.Price buildPrice() {
  var o = api.Price();
  buildCounterPrice++;
  if (buildCounterPrice < 3) {
    o.currency = 'foo';
    o.priceMicros = 'foo';
  }
  buildCounterPrice--;
  return o;
}

void checkPrice(api.Price o) {
  buildCounterPrice++;
  if (buildCounterPrice < 3) {
    unittest.expect(
      o.currency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.priceMicros!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrice--;
}

core.int buildCounterProductPurchase = 0;
api.ProductPurchase buildProductPurchase() {
  var o = api.ProductPurchase();
  buildCounterProductPurchase++;
  if (buildCounterProductPurchase < 3) {
    o.acknowledgementState = 42;
    o.consumptionState = 42;
    o.developerPayload = 'foo';
    o.kind = 'foo';
    o.obfuscatedExternalAccountId = 'foo';
    o.obfuscatedExternalProfileId = 'foo';
    o.orderId = 'foo';
    o.productId = 'foo';
    o.purchaseState = 42;
    o.purchaseTimeMillis = 'foo';
    o.purchaseToken = 'foo';
    o.purchaseType = 42;
    o.quantity = 42;
    o.regionCode = 'foo';
  }
  buildCounterProductPurchase--;
  return o;
}

void checkProductPurchase(api.ProductPurchase o) {
  buildCounterProductPurchase++;
  if (buildCounterProductPurchase < 3) {
    unittest.expect(
      o.acknowledgementState!,
      unittest.equals(42),
    );
    unittest.expect(
      o.consumptionState!,
      unittest.equals(42),
    );
    unittest.expect(
      o.developerPayload!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.obfuscatedExternalAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.obfuscatedExternalProfileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.purchaseState!,
      unittest.equals(42),
    );
    unittest.expect(
      o.purchaseTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.purchaseToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.purchaseType!,
      unittest.equals(42),
    );
    unittest.expect(
      o.quantity!,
      unittest.equals(42),
    );
    unittest.expect(
      o.regionCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterProductPurchase--;
}

core.int buildCounterProductPurchasesAcknowledgeRequest = 0;
api.ProductPurchasesAcknowledgeRequest
    buildProductPurchasesAcknowledgeRequest() {
  var o = api.ProductPurchasesAcknowledgeRequest();
  buildCounterProductPurchasesAcknowledgeRequest++;
  if (buildCounterProductPurchasesAcknowledgeRequest < 3) {
    o.developerPayload = 'foo';
  }
  buildCounterProductPurchasesAcknowledgeRequest--;
  return o;
}

void checkProductPurchasesAcknowledgeRequest(
    api.ProductPurchasesAcknowledgeRequest o) {
  buildCounterProductPurchasesAcknowledgeRequest++;
  if (buildCounterProductPurchasesAcknowledgeRequest < 3) {
    unittest.expect(
      o.developerPayload!,
      unittest.equals('foo'),
    );
  }
  buildCounterProductPurchasesAcknowledgeRequest--;
}

core.List<api.Comment> buildUnnamed1673() {
  var o = <api.Comment>[];
  o.add(buildComment());
  o.add(buildComment());
  return o;
}

void checkUnnamed1673(core.List<api.Comment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkComment(o[0] as api.Comment);
  checkComment(o[1] as api.Comment);
}

core.int buildCounterReview = 0;
api.Review buildReview() {
  var o = api.Review();
  buildCounterReview++;
  if (buildCounterReview < 3) {
    o.authorName = 'foo';
    o.comments = buildUnnamed1673();
    o.reviewId = 'foo';
  }
  buildCounterReview--;
  return o;
}

void checkReview(api.Review o) {
  buildCounterReview++;
  if (buildCounterReview < 3) {
    unittest.expect(
      o.authorName!,
      unittest.equals('foo'),
    );
    checkUnnamed1673(o.comments!);
    unittest.expect(
      o.reviewId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReview--;
}

core.int buildCounterReviewReplyResult = 0;
api.ReviewReplyResult buildReviewReplyResult() {
  var o = api.ReviewReplyResult();
  buildCounterReviewReplyResult++;
  if (buildCounterReviewReplyResult < 3) {
    o.lastEdited = buildTimestamp();
    o.replyText = 'foo';
  }
  buildCounterReviewReplyResult--;
  return o;
}

void checkReviewReplyResult(api.ReviewReplyResult o) {
  buildCounterReviewReplyResult++;
  if (buildCounterReviewReplyResult < 3) {
    checkTimestamp(o.lastEdited! as api.Timestamp);
    unittest.expect(
      o.replyText!,
      unittest.equals('foo'),
    );
  }
  buildCounterReviewReplyResult--;
}

core.List<api.Review> buildUnnamed1674() {
  var o = <api.Review>[];
  o.add(buildReview());
  o.add(buildReview());
  return o;
}

void checkUnnamed1674(core.List<api.Review> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReview(o[0] as api.Review);
  checkReview(o[1] as api.Review);
}

core.int buildCounterReviewsListResponse = 0;
api.ReviewsListResponse buildReviewsListResponse() {
  var o = api.ReviewsListResponse();
  buildCounterReviewsListResponse++;
  if (buildCounterReviewsListResponse < 3) {
    o.pageInfo = buildPageInfo();
    o.reviews = buildUnnamed1674();
    o.tokenPagination = buildTokenPagination();
  }
  buildCounterReviewsListResponse--;
  return o;
}

void checkReviewsListResponse(api.ReviewsListResponse o) {
  buildCounterReviewsListResponse++;
  if (buildCounterReviewsListResponse < 3) {
    checkPageInfo(o.pageInfo! as api.PageInfo);
    checkUnnamed1674(o.reviews!);
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
  }
  buildCounterReviewsListResponse--;
}

core.int buildCounterReviewsReplyRequest = 0;
api.ReviewsReplyRequest buildReviewsReplyRequest() {
  var o = api.ReviewsReplyRequest();
  buildCounterReviewsReplyRequest++;
  if (buildCounterReviewsReplyRequest < 3) {
    o.replyText = 'foo';
  }
  buildCounterReviewsReplyRequest--;
  return o;
}

void checkReviewsReplyRequest(api.ReviewsReplyRequest o) {
  buildCounterReviewsReplyRequest++;
  if (buildCounterReviewsReplyRequest < 3) {
    unittest.expect(
      o.replyText!,
      unittest.equals('foo'),
    );
  }
  buildCounterReviewsReplyRequest--;
}

core.int buildCounterReviewsReplyResponse = 0;
api.ReviewsReplyResponse buildReviewsReplyResponse() {
  var o = api.ReviewsReplyResponse();
  buildCounterReviewsReplyResponse++;
  if (buildCounterReviewsReplyResponse < 3) {
    o.result = buildReviewReplyResult();
  }
  buildCounterReviewsReplyResponse--;
  return o;
}

void checkReviewsReplyResponse(api.ReviewsReplyResponse o) {
  buildCounterReviewsReplyResponse++;
  if (buildCounterReviewsReplyResponse < 3) {
    checkReviewReplyResult(o.result! as api.ReviewReplyResult);
  }
  buildCounterReviewsReplyResponse--;
}

core.int buildCounterSubscriptionCancelSurveyResult = 0;
api.SubscriptionCancelSurveyResult buildSubscriptionCancelSurveyResult() {
  var o = api.SubscriptionCancelSurveyResult();
  buildCounterSubscriptionCancelSurveyResult++;
  if (buildCounterSubscriptionCancelSurveyResult < 3) {
    o.cancelSurveyReason = 42;
    o.userInputCancelReason = 'foo';
  }
  buildCounterSubscriptionCancelSurveyResult--;
  return o;
}

void checkSubscriptionCancelSurveyResult(api.SubscriptionCancelSurveyResult o) {
  buildCounterSubscriptionCancelSurveyResult++;
  if (buildCounterSubscriptionCancelSurveyResult < 3) {
    unittest.expect(
      o.cancelSurveyReason!,
      unittest.equals(42),
    );
    unittest.expect(
      o.userInputCancelReason!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionCancelSurveyResult--;
}

core.int buildCounterSubscriptionDeferralInfo = 0;
api.SubscriptionDeferralInfo buildSubscriptionDeferralInfo() {
  var o = api.SubscriptionDeferralInfo();
  buildCounterSubscriptionDeferralInfo++;
  if (buildCounterSubscriptionDeferralInfo < 3) {
    o.desiredExpiryTimeMillis = 'foo';
    o.expectedExpiryTimeMillis = 'foo';
  }
  buildCounterSubscriptionDeferralInfo--;
  return o;
}

void checkSubscriptionDeferralInfo(api.SubscriptionDeferralInfo o) {
  buildCounterSubscriptionDeferralInfo++;
  if (buildCounterSubscriptionDeferralInfo < 3) {
    unittest.expect(
      o.desiredExpiryTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expectedExpiryTimeMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionDeferralInfo--;
}

core.int buildCounterSubscriptionPriceChange = 0;
api.SubscriptionPriceChange buildSubscriptionPriceChange() {
  var o = api.SubscriptionPriceChange();
  buildCounterSubscriptionPriceChange++;
  if (buildCounterSubscriptionPriceChange < 3) {
    o.newPrice = buildPrice();
    o.state = 42;
  }
  buildCounterSubscriptionPriceChange--;
  return o;
}

void checkSubscriptionPriceChange(api.SubscriptionPriceChange o) {
  buildCounterSubscriptionPriceChange++;
  if (buildCounterSubscriptionPriceChange < 3) {
    checkPrice(o.newPrice! as api.Price);
    unittest.expect(
      o.state!,
      unittest.equals(42),
    );
  }
  buildCounterSubscriptionPriceChange--;
}

core.int buildCounterSubscriptionPurchase = 0;
api.SubscriptionPurchase buildSubscriptionPurchase() {
  var o = api.SubscriptionPurchase();
  buildCounterSubscriptionPurchase++;
  if (buildCounterSubscriptionPurchase < 3) {
    o.acknowledgementState = 42;
    o.autoRenewing = true;
    o.autoResumeTimeMillis = 'foo';
    o.cancelReason = 42;
    o.cancelSurveyResult = buildSubscriptionCancelSurveyResult();
    o.countryCode = 'foo';
    o.developerPayload = 'foo';
    o.emailAddress = 'foo';
    o.expiryTimeMillis = 'foo';
    o.externalAccountId = 'foo';
    o.familyName = 'foo';
    o.givenName = 'foo';
    o.introductoryPriceInfo = buildIntroductoryPriceInfo();
    o.kind = 'foo';
    o.linkedPurchaseToken = 'foo';
    o.obfuscatedExternalAccountId = 'foo';
    o.obfuscatedExternalProfileId = 'foo';
    o.orderId = 'foo';
    o.paymentState = 42;
    o.priceAmountMicros = 'foo';
    o.priceChange = buildSubscriptionPriceChange();
    o.priceCurrencyCode = 'foo';
    o.profileId = 'foo';
    o.profileName = 'foo';
    o.promotionCode = 'foo';
    o.promotionType = 42;
    o.purchaseType = 42;
    o.startTimeMillis = 'foo';
    o.userCancellationTimeMillis = 'foo';
  }
  buildCounterSubscriptionPurchase--;
  return o;
}

void checkSubscriptionPurchase(api.SubscriptionPurchase o) {
  buildCounterSubscriptionPurchase++;
  if (buildCounterSubscriptionPurchase < 3) {
    unittest.expect(
      o.acknowledgementState!,
      unittest.equals(42),
    );
    unittest.expect(o.autoRenewing!, unittest.isTrue);
    unittest.expect(
      o.autoResumeTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cancelReason!,
      unittest.equals(42),
    );
    checkSubscriptionCancelSurveyResult(
        o.cancelSurveyResult! as api.SubscriptionCancelSurveyResult);
    unittest.expect(
      o.countryCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.developerPayload!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiryTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.familyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.givenName!,
      unittest.equals('foo'),
    );
    checkIntroductoryPriceInfo(
        o.introductoryPriceInfo! as api.IntroductoryPriceInfo);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.linkedPurchaseToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.obfuscatedExternalAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.obfuscatedExternalProfileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.paymentState!,
      unittest.equals(42),
    );
    unittest.expect(
      o.priceAmountMicros!,
      unittest.equals('foo'),
    );
    checkSubscriptionPriceChange(o.priceChange! as api.SubscriptionPriceChange);
    unittest.expect(
      o.priceCurrencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.promotionCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.promotionType!,
      unittest.equals(42),
    );
    unittest.expect(
      o.purchaseType!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userCancellationTimeMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionPurchase--;
}

core.int buildCounterSubscriptionPurchasesAcknowledgeRequest = 0;
api.SubscriptionPurchasesAcknowledgeRequest
    buildSubscriptionPurchasesAcknowledgeRequest() {
  var o = api.SubscriptionPurchasesAcknowledgeRequest();
  buildCounterSubscriptionPurchasesAcknowledgeRequest++;
  if (buildCounterSubscriptionPurchasesAcknowledgeRequest < 3) {
    o.developerPayload = 'foo';
  }
  buildCounterSubscriptionPurchasesAcknowledgeRequest--;
  return o;
}

void checkSubscriptionPurchasesAcknowledgeRequest(
    api.SubscriptionPurchasesAcknowledgeRequest o) {
  buildCounterSubscriptionPurchasesAcknowledgeRequest++;
  if (buildCounterSubscriptionPurchasesAcknowledgeRequest < 3) {
    unittest.expect(
      o.developerPayload!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionPurchasesAcknowledgeRequest--;
}

core.int buildCounterSubscriptionPurchasesDeferRequest = 0;
api.SubscriptionPurchasesDeferRequest buildSubscriptionPurchasesDeferRequest() {
  var o = api.SubscriptionPurchasesDeferRequest();
  buildCounterSubscriptionPurchasesDeferRequest++;
  if (buildCounterSubscriptionPurchasesDeferRequest < 3) {
    o.deferralInfo = buildSubscriptionDeferralInfo();
  }
  buildCounterSubscriptionPurchasesDeferRequest--;
  return o;
}

void checkSubscriptionPurchasesDeferRequest(
    api.SubscriptionPurchasesDeferRequest o) {
  buildCounterSubscriptionPurchasesDeferRequest++;
  if (buildCounterSubscriptionPurchasesDeferRequest < 3) {
    checkSubscriptionDeferralInfo(
        o.deferralInfo! as api.SubscriptionDeferralInfo);
  }
  buildCounterSubscriptionPurchasesDeferRequest--;
}

core.int buildCounterSubscriptionPurchasesDeferResponse = 0;
api.SubscriptionPurchasesDeferResponse
    buildSubscriptionPurchasesDeferResponse() {
  var o = api.SubscriptionPurchasesDeferResponse();
  buildCounterSubscriptionPurchasesDeferResponse++;
  if (buildCounterSubscriptionPurchasesDeferResponse < 3) {
    o.newExpiryTimeMillis = 'foo';
  }
  buildCounterSubscriptionPurchasesDeferResponse--;
  return o;
}

void checkSubscriptionPurchasesDeferResponse(
    api.SubscriptionPurchasesDeferResponse o) {
  buildCounterSubscriptionPurchasesDeferResponse++;
  if (buildCounterSubscriptionPurchasesDeferResponse < 3) {
    unittest.expect(
      o.newExpiryTimeMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionPurchasesDeferResponse--;
}

core.List<api.Variant> buildUnnamed1675() {
  var o = <api.Variant>[];
  o.add(buildVariant());
  o.add(buildVariant());
  return o;
}

void checkUnnamed1675(core.List<api.Variant> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariant(o[0] as api.Variant);
  checkVariant(o[1] as api.Variant);
}

core.int buildCounterSystemApksListResponse = 0;
api.SystemApksListResponse buildSystemApksListResponse() {
  var o = api.SystemApksListResponse();
  buildCounterSystemApksListResponse++;
  if (buildCounterSystemApksListResponse < 3) {
    o.variants = buildUnnamed1675();
  }
  buildCounterSystemApksListResponse--;
  return o;
}

void checkSystemApksListResponse(api.SystemApksListResponse o) {
  buildCounterSystemApksListResponse++;
  if (buildCounterSystemApksListResponse < 3) {
    checkUnnamed1675(o.variants!);
  }
  buildCounterSystemApksListResponse--;
}

core.List<core.String> buildUnnamed1676() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1676(core.List<core.String> o) {
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

core.int buildCounterTesters = 0;
api.Testers buildTesters() {
  var o = api.Testers();
  buildCounterTesters++;
  if (buildCounterTesters < 3) {
    o.googleGroups = buildUnnamed1676();
  }
  buildCounterTesters--;
  return o;
}

void checkTesters(api.Testers o) {
  buildCounterTesters++;
  if (buildCounterTesters < 3) {
    checkUnnamed1676(o.googleGroups!);
  }
  buildCounterTesters--;
}

core.int buildCounterTimestamp = 0;
api.Timestamp buildTimestamp() {
  var o = api.Timestamp();
  buildCounterTimestamp++;
  if (buildCounterTimestamp < 3) {
    o.nanos = 42;
    o.seconds = 'foo';
  }
  buildCounterTimestamp--;
  return o;
}

void checkTimestamp(api.Timestamp o) {
  buildCounterTimestamp++;
  if (buildCounterTimestamp < 3) {
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.seconds!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimestamp--;
}

core.int buildCounterTokenPagination = 0;
api.TokenPagination buildTokenPagination() {
  var o = api.TokenPagination();
  buildCounterTokenPagination++;
  if (buildCounterTokenPagination < 3) {
    o.nextPageToken = 'foo';
    o.previousPageToken = 'foo';
  }
  buildCounterTokenPagination--;
  return o;
}

void checkTokenPagination(api.TokenPagination o) {
  buildCounterTokenPagination++;
  if (buildCounterTokenPagination < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterTokenPagination--;
}

core.List<api.TrackRelease> buildUnnamed1677() {
  var o = <api.TrackRelease>[];
  o.add(buildTrackRelease());
  o.add(buildTrackRelease());
  return o;
}

void checkUnnamed1677(core.List<api.TrackRelease> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrackRelease(o[0] as api.TrackRelease);
  checkTrackRelease(o[1] as api.TrackRelease);
}

core.int buildCounterTrack = 0;
api.Track buildTrack() {
  var o = api.Track();
  buildCounterTrack++;
  if (buildCounterTrack < 3) {
    o.releases = buildUnnamed1677();
    o.track = 'foo';
  }
  buildCounterTrack--;
  return o;
}

void checkTrack(api.Track o) {
  buildCounterTrack++;
  if (buildCounterTrack < 3) {
    checkUnnamed1677(o.releases!);
    unittest.expect(
      o.track!,
      unittest.equals('foo'),
    );
  }
  buildCounterTrack--;
}

core.List<api.LocalizedText> buildUnnamed1678() {
  var o = <api.LocalizedText>[];
  o.add(buildLocalizedText());
  o.add(buildLocalizedText());
  return o;
}

void checkUnnamed1678(core.List<api.LocalizedText> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocalizedText(o[0] as api.LocalizedText);
  checkLocalizedText(o[1] as api.LocalizedText);
}

core.List<core.String> buildUnnamed1679() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1679(core.List<core.String> o) {
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

core.int buildCounterTrackRelease = 0;
api.TrackRelease buildTrackRelease() {
  var o = api.TrackRelease();
  buildCounterTrackRelease++;
  if (buildCounterTrackRelease < 3) {
    o.countryTargeting = buildCountryTargeting();
    o.inAppUpdatePriority = 42;
    o.name = 'foo';
    o.releaseNotes = buildUnnamed1678();
    o.status = 'foo';
    o.userFraction = 42.0;
    o.versionCodes = buildUnnamed1679();
  }
  buildCounterTrackRelease--;
  return o;
}

void checkTrackRelease(api.TrackRelease o) {
  buildCounterTrackRelease++;
  if (buildCounterTrackRelease < 3) {
    checkCountryTargeting(o.countryTargeting! as api.CountryTargeting);
    unittest.expect(
      o.inAppUpdatePriority!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed1678(o.releaseNotes!);
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userFraction!,
      unittest.equals(42.0),
    );
    checkUnnamed1679(o.versionCodes!);
  }
  buildCounterTrackRelease--;
}

core.List<api.Track> buildUnnamed1680() {
  var o = <api.Track>[];
  o.add(buildTrack());
  o.add(buildTrack());
  return o;
}

void checkUnnamed1680(core.List<api.Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrack(o[0] as api.Track);
  checkTrack(o[1] as api.Track);
}

core.int buildCounterTracksListResponse = 0;
api.TracksListResponse buildTracksListResponse() {
  var o = api.TracksListResponse();
  buildCounterTracksListResponse++;
  if (buildCounterTracksListResponse < 3) {
    o.kind = 'foo';
    o.tracks = buildUnnamed1680();
  }
  buildCounterTracksListResponse--;
  return o;
}

void checkTracksListResponse(api.TracksListResponse o) {
  buildCounterTracksListResponse++;
  if (buildCounterTracksListResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1680(o.tracks!);
  }
  buildCounterTracksListResponse--;
}

core.int buildCounterUserComment = 0;
api.UserComment buildUserComment() {
  var o = api.UserComment();
  buildCounterUserComment++;
  if (buildCounterUserComment < 3) {
    o.androidOsVersion = 42;
    o.appVersionCode = 42;
    o.appVersionName = 'foo';
    o.device = 'foo';
    o.deviceMetadata = buildDeviceMetadata();
    o.lastModified = buildTimestamp();
    o.originalText = 'foo';
    o.reviewerLanguage = 'foo';
    o.starRating = 42;
    o.text = 'foo';
    o.thumbsDownCount = 42;
    o.thumbsUpCount = 42;
  }
  buildCounterUserComment--;
  return o;
}

void checkUserComment(api.UserComment o) {
  buildCounterUserComment++;
  if (buildCounterUserComment < 3) {
    unittest.expect(
      o.androidOsVersion!,
      unittest.equals(42),
    );
    unittest.expect(
      o.appVersionCode!,
      unittest.equals(42),
    );
    unittest.expect(
      o.appVersionName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.device!,
      unittest.equals('foo'),
    );
    checkDeviceMetadata(o.deviceMetadata! as api.DeviceMetadata);
    checkTimestamp(o.lastModified! as api.Timestamp);
    unittest.expect(
      o.originalText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reviewerLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.starRating!,
      unittest.equals(42),
    );
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbsDownCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.thumbsUpCount!,
      unittest.equals(42),
    );
  }
  buildCounterUserComment--;
}

core.int buildCounterUsesPermission = 0;
api.UsesPermission buildUsesPermission() {
  var o = api.UsesPermission();
  buildCounterUsesPermission++;
  if (buildCounterUsesPermission < 3) {
    o.maxSdkVersion = 42;
    o.name = 'foo';
  }
  buildCounterUsesPermission--;
  return o;
}

void checkUsesPermission(api.UsesPermission o) {
  buildCounterUsesPermission++;
  if (buildCounterUsesPermission < 3) {
    unittest.expect(
      o.maxSdkVersion!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterUsesPermission--;
}

core.int buildCounterVariant = 0;
api.Variant buildVariant() {
  var o = api.Variant();
  buildCounterVariant++;
  if (buildCounterVariant < 3) {
    o.deviceSpec = buildDeviceSpec();
    o.variantId = 42;
  }
  buildCounterVariant--;
  return o;
}

void checkVariant(api.Variant o) {
  buildCounterVariant++;
  if (buildCounterVariant < 3) {
    checkDeviceSpec(o.deviceSpec! as api.DeviceSpec);
    unittest.expect(
      o.variantId!,
      unittest.equals(42),
    );
  }
  buildCounterVariant--;
}

core.int buildCounterVoidedPurchase = 0;
api.VoidedPurchase buildVoidedPurchase() {
  var o = api.VoidedPurchase();
  buildCounterVoidedPurchase++;
  if (buildCounterVoidedPurchase < 3) {
    o.kind = 'foo';
    o.orderId = 'foo';
    o.purchaseTimeMillis = 'foo';
    o.purchaseToken = 'foo';
    o.voidedReason = 42;
    o.voidedSource = 42;
    o.voidedTimeMillis = 'foo';
  }
  buildCounterVoidedPurchase--;
  return o;
}

void checkVoidedPurchase(api.VoidedPurchase o) {
  buildCounterVoidedPurchase++;
  if (buildCounterVoidedPurchase < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.purchaseTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.purchaseToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.voidedReason!,
      unittest.equals(42),
    );
    unittest.expect(
      o.voidedSource!,
      unittest.equals(42),
    );
    unittest.expect(
      o.voidedTimeMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterVoidedPurchase--;
}

core.List<api.VoidedPurchase> buildUnnamed1681() {
  var o = <api.VoidedPurchase>[];
  o.add(buildVoidedPurchase());
  o.add(buildVoidedPurchase());
  return o;
}

void checkUnnamed1681(core.List<api.VoidedPurchase> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVoidedPurchase(o[0] as api.VoidedPurchase);
  checkVoidedPurchase(o[1] as api.VoidedPurchase);
}

core.int buildCounterVoidedPurchasesListResponse = 0;
api.VoidedPurchasesListResponse buildVoidedPurchasesListResponse() {
  var o = api.VoidedPurchasesListResponse();
  buildCounterVoidedPurchasesListResponse++;
  if (buildCounterVoidedPurchasesListResponse < 3) {
    o.pageInfo = buildPageInfo();
    o.tokenPagination = buildTokenPagination();
    o.voidedPurchases = buildUnnamed1681();
  }
  buildCounterVoidedPurchasesListResponse--;
  return o;
}

void checkVoidedPurchasesListResponse(api.VoidedPurchasesListResponse o) {
  buildCounterVoidedPurchasesListResponse++;
  if (buildCounterVoidedPurchasesListResponse < 3) {
    checkPageInfo(o.pageInfo! as api.PageInfo);
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    checkUnnamed1681(o.voidedPurchases!);
  }
  buildCounterVoidedPurchasesListResponse--;
}

void main() {
  unittest.group('obj-schema-Apk', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApk();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Apk.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkApk(od as api.Apk);
    });
  });

  unittest.group('obj-schema-ApkBinary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApkBinary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ApkBinary.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkApkBinary(od as api.ApkBinary);
    });
  });

  unittest.group('obj-schema-ApksAddExternallyHostedRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApksAddExternallyHostedRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApksAddExternallyHostedRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApksAddExternallyHostedRequest(
          od as api.ApksAddExternallyHostedRequest);
    });
  });

  unittest.group('obj-schema-ApksAddExternallyHostedResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApksAddExternallyHostedResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApksAddExternallyHostedResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApksAddExternallyHostedResponse(
          od as api.ApksAddExternallyHostedResponse);
    });
  });

  unittest.group('obj-schema-ApksListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApksListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApksListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApksListResponse(od as api.ApksListResponse);
    });
  });

  unittest.group('obj-schema-AppDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AppDetails.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAppDetails(od as api.AppDetails);
    });
  });

  unittest.group('obj-schema-AppEdit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppEdit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AppEdit.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAppEdit(od as api.AppEdit);
    });
  });

  unittest.group('obj-schema-Bundle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBundle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Bundle.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBundle(od as api.Bundle);
    });
  });

  unittest.group('obj-schema-BundlesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBundlesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BundlesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBundlesListResponse(od as api.BundlesListResponse);
    });
  });

  unittest.group('obj-schema-Comment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildComment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Comment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkComment(od as api.Comment);
    });
  });

  unittest.group('obj-schema-CountryTargeting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCountryTargeting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CountryTargeting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCountryTargeting(od as api.CountryTargeting);
    });
  });

  unittest.group('obj-schema-DeobfuscationFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeobfuscationFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeobfuscationFile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeobfuscationFile(od as api.DeobfuscationFile);
    });
  });

  unittest.group('obj-schema-DeobfuscationFilesUploadResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeobfuscationFilesUploadResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeobfuscationFilesUploadResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeobfuscationFilesUploadResponse(
          od as api.DeobfuscationFilesUploadResponse);
    });
  });

  unittest.group('obj-schema-DeveloperComment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeveloperComment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeveloperComment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeveloperComment(od as api.DeveloperComment);
    });
  });

  unittest.group('obj-schema-DeviceMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceMetadata(od as api.DeviceMetadata);
    });
  });

  unittest.group('obj-schema-DeviceSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DeviceSpec.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDeviceSpec(od as api.DeviceSpec);
    });
  });

  unittest.group('obj-schema-ExpansionFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpansionFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExpansionFile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExpansionFile(od as api.ExpansionFile);
    });
  });

  unittest.group('obj-schema-ExpansionFilesUploadResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpansionFilesUploadResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExpansionFilesUploadResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExpansionFilesUploadResponse(od as api.ExpansionFilesUploadResponse);
    });
  });

  unittest.group('obj-schema-ExternallyHostedApk', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExternallyHostedApk();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExternallyHostedApk.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExternallyHostedApk(od as api.ExternallyHostedApk);
    });
  });

  unittest.group('obj-schema-Image', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Image.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImage(od as api.Image);
    });
  });

  unittest.group('obj-schema-ImagesDeleteAllResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImagesDeleteAllResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImagesDeleteAllResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImagesDeleteAllResponse(od as api.ImagesDeleteAllResponse);
    });
  });

  unittest.group('obj-schema-ImagesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImagesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImagesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImagesListResponse(od as api.ImagesListResponse);
    });
  });

  unittest.group('obj-schema-ImagesUploadResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImagesUploadResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImagesUploadResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImagesUploadResponse(od as api.ImagesUploadResponse);
    });
  });

  unittest.group('obj-schema-InAppProduct', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInAppProduct();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InAppProduct.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInAppProduct(od as api.InAppProduct);
    });
  });

  unittest.group('obj-schema-InAppProductListing', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInAppProductListing();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InAppProductListing.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInAppProductListing(od as api.InAppProductListing);
    });
  });

  unittest.group('obj-schema-InappproductsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInappproductsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InappproductsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInappproductsListResponse(od as api.InappproductsListResponse);
    });
  });

  unittest.group('obj-schema-InternalAppSharingArtifact', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInternalAppSharingArtifact();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InternalAppSharingArtifact.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInternalAppSharingArtifact(od as api.InternalAppSharingArtifact);
    });
  });

  unittest.group('obj-schema-IntroductoryPriceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIntroductoryPriceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IntroductoryPriceInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIntroductoryPriceInfo(od as api.IntroductoryPriceInfo);
    });
  });

  unittest.group('obj-schema-Listing', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListing();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Listing.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkListing(od as api.Listing);
    });
  });

  unittest.group('obj-schema-ListingsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListingsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListingsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListingsListResponse(od as api.ListingsListResponse);
    });
  });

  unittest.group('obj-schema-LocalizedText', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalizedText();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocalizedText.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocalizedText(od as api.LocalizedText);
    });
  });

  unittest.group('obj-schema-PageInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPageInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PageInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPageInfo(od as api.PageInfo);
    });
  });

  unittest.group('obj-schema-Price', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Price.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPrice(od as api.Price);
    });
  });

  unittest.group('obj-schema-ProductPurchase', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProductPurchase();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProductPurchase.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProductPurchase(od as api.ProductPurchase);
    });
  });

  unittest.group('obj-schema-ProductPurchasesAcknowledgeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProductPurchasesAcknowledgeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProductPurchasesAcknowledgeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProductPurchasesAcknowledgeRequest(
          od as api.ProductPurchasesAcknowledgeRequest);
    });
  });

  unittest.group('obj-schema-Review', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReview();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Review.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReview(od as api.Review);
    });
  });

  unittest.group('obj-schema-ReviewReplyResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReviewReplyResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReviewReplyResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReviewReplyResult(od as api.ReviewReplyResult);
    });
  });

  unittest.group('obj-schema-ReviewsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReviewsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReviewsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReviewsListResponse(od as api.ReviewsListResponse);
    });
  });

  unittest.group('obj-schema-ReviewsReplyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReviewsReplyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReviewsReplyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReviewsReplyRequest(od as api.ReviewsReplyRequest);
    });
  });

  unittest.group('obj-schema-ReviewsReplyResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReviewsReplyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReviewsReplyResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReviewsReplyResponse(od as api.ReviewsReplyResponse);
    });
  });

  unittest.group('obj-schema-SubscriptionCancelSurveyResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionCancelSurveyResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionCancelSurveyResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionCancelSurveyResult(
          od as api.SubscriptionCancelSurveyResult);
    });
  });

  unittest.group('obj-schema-SubscriptionDeferralInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionDeferralInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionDeferralInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionDeferralInfo(od as api.SubscriptionDeferralInfo);
    });
  });

  unittest.group('obj-schema-SubscriptionPriceChange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionPriceChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionPriceChange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionPriceChange(od as api.SubscriptionPriceChange);
    });
  });

  unittest.group('obj-schema-SubscriptionPurchase', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionPurchase();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionPurchase.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionPurchase(od as api.SubscriptionPurchase);
    });
  });

  unittest.group('obj-schema-SubscriptionPurchasesAcknowledgeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionPurchasesAcknowledgeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionPurchasesAcknowledgeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionPurchasesAcknowledgeRequest(
          od as api.SubscriptionPurchasesAcknowledgeRequest);
    });
  });

  unittest.group('obj-schema-SubscriptionPurchasesDeferRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionPurchasesDeferRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionPurchasesDeferRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionPurchasesDeferRequest(
          od as api.SubscriptionPurchasesDeferRequest);
    });
  });

  unittest.group('obj-schema-SubscriptionPurchasesDeferResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionPurchasesDeferResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionPurchasesDeferResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionPurchasesDeferResponse(
          od as api.SubscriptionPurchasesDeferResponse);
    });
  });

  unittest.group('obj-schema-SystemApksListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSystemApksListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SystemApksListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSystemApksListResponse(od as api.SystemApksListResponse);
    });
  });

  unittest.group('obj-schema-Testers', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTesters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Testers.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTesters(od as api.Testers);
    });
  });

  unittest.group('obj-schema-Timestamp', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimestamp();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Timestamp.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimestamp(od as api.Timestamp);
    });
  });

  unittest.group('obj-schema-TokenPagination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTokenPagination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TokenPagination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTokenPagination(od as api.TokenPagination);
    });
  });

  unittest.group('obj-schema-Track', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrack();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Track.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTrack(od as api.Track);
    });
  });

  unittest.group('obj-schema-TrackRelease', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrackRelease();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrackRelease.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrackRelease(od as api.TrackRelease);
    });
  });

  unittest.group('obj-schema-TracksListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTracksListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TracksListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTracksListResponse(od as api.TracksListResponse);
    });
  });

  unittest.group('obj-schema-UserComment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserComment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserComment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserComment(od as api.UserComment);
    });
  });

  unittest.group('obj-schema-UsesPermission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsesPermission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UsesPermission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUsesPermission(od as api.UsesPermission);
    });
  });

  unittest.group('obj-schema-Variant', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVariant();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Variant.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVariant(od as api.Variant);
    });
  });

  unittest.group('obj-schema-VoidedPurchase', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVoidedPurchase();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VoidedPurchase.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVoidedPurchase(od as api.VoidedPurchase);
    });
  });

  unittest.group('obj-schema-VoidedPurchasesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVoidedPurchasesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VoidedPurchasesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVoidedPurchasesListResponse(od as api.VoidedPurchasesListResponse);
    });
  });

  unittest.group('resource-EditsResource', () {
    unittest.test('method--commit', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_changesNotSentForReview = true;
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf(':commit', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":commit"),
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
          queryMap["changesNotSentForReview"]!.first,
          unittest.equals("$arg_changesNotSentForReview"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAppEdit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.commit(arg_packageName, arg_editId,
          changesNotSentForReview: arg_changesNotSentForReview,
          $fields: arg_$fields);
      checkAppEdit(response as api.AppEdit);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
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
      await res.delete(arg_packageName, arg_editId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
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
        var resp = convert.json.encode(buildAppEdit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_packageName, arg_editId, $fields: arg_$fields);
      checkAppEdit(response as api.AppEdit);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits;
      var arg_request = buildAppEdit();
      var arg_packageName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.AppEdit.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAppEdit(obj as api.AppEdit);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/edits"),
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
        var resp = convert.json.encode(buildAppEdit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_packageName, $fields: arg_$fields);
      checkAppEdit(response as api.AppEdit);
    });

    unittest.test('method--validate', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf(':validate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals(":validate"),
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
        var resp = convert.json.encode(buildAppEdit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.validate(arg_packageName, arg_editId, $fields: arg_$fields);
      checkAppEdit(response as api.AppEdit);
    });
  });

  unittest.group('resource-EditsApksResource', () {
    unittest.test('method--addexternallyhosted', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.apks;
      var arg_request = buildApksAddExternallyHostedRequest();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ApksAddExternallyHostedRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkApksAddExternallyHostedRequest(
            obj as api.ApksAddExternallyHostedRequest);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks/externallyHosted', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/apks/externallyHosted"),
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
        var resp = convert.json.encode(buildApksAddExternallyHostedResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.addexternallyhosted(
          arg_request, arg_packageName, arg_editId,
          $fields: arg_$fields);
      checkApksAddExternallyHostedResponse(
          response as api.ApksAddExternallyHostedResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.apks;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/apks"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildApksListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_packageName, arg_editId, $fields: arg_$fields);
      checkApksListResponse(response as api.ApksListResponse);
    });

    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.apks;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/apks"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildApk());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.upload(arg_packageName, arg_editId, $fields: arg_$fields);
      checkApk(response as api.Apk);
    });
  });

  unittest.group('resource-EditsBundlesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.bundles;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/bundles', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/bundles"),
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
        var resp = convert.json.encode(buildBundlesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_packageName, arg_editId, $fields: arg_$fields);
      checkBundlesListResponse(response as api.BundlesListResponse);
    });

    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.bundles;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_ackBundleInstallationWarning = true;
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/bundles', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/bundles"),
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
          queryMap["ackBundleInstallationWarning"]!.first,
          unittest.equals("$arg_ackBundleInstallationWarning"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBundle());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.upload(arg_packageName, arg_editId,
          ackBundleInstallationWarning: arg_ackBundleInstallationWarning,
          $fields: arg_$fields);
      checkBundle(response as api.Bundle);
    });
  });

  unittest.group('resource-EditsDeobfuscationfilesResource', () {
    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.deobfuscationfiles;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_apkVersionCode = 42;
      var arg_deobfuscationFileType = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/apks/"),
        );
        pathOffset += 6;
        index = path.indexOf('/deobfuscationFiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_apkVersionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/deobfuscationFiles/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deobfuscationFileType'),
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
        var resp = convert.json.encode(buildDeobfuscationFilesUploadResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.upload(arg_packageName, arg_editId,
          arg_apkVersionCode, arg_deobfuscationFileType,
          $fields: arg_$fields);
      checkDeobfuscationFilesUploadResponse(
          response as api.DeobfuscationFilesUploadResponse);
    });
  });

  unittest.group('resource-EditsDetailsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.details;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/details', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/details"),
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
        var resp = convert.json.encode(buildAppDetails());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_packageName, arg_editId, $fields: arg_$fields);
      checkAppDetails(response as api.AppDetails);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.details;
      var arg_request = buildAppDetails();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AppDetails.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAppDetails(obj as api.AppDetails);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/details', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/details"),
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
        var resp = convert.json.encode(buildAppDetails());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_packageName, arg_editId,
          $fields: arg_$fields);
      checkAppDetails(response as api.AppDetails);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.details;
      var arg_request = buildAppDetails();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AppDetails.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAppDetails(obj as api.AppDetails);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/details', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/details"),
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
        var resp = convert.json.encode(buildAppDetails());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_packageName, arg_editId,
          $fields: arg_$fields);
      checkAppDetails(response as api.AppDetails);
    });
  });

  unittest.group('resource-EditsExpansionfilesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.expansionfiles;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_apkVersionCode = 42;
      var arg_expansionFileType = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/apks/"),
        );
        pathOffset += 6;
        index = path.indexOf('/expansionFiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_apkVersionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/expansionFiles/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_expansionFileType'),
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
        var resp = convert.json.encode(buildExpansionFile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_packageName, arg_editId,
          arg_apkVersionCode, arg_expansionFileType,
          $fields: arg_$fields);
      checkExpansionFile(response as api.ExpansionFile);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.expansionfiles;
      var arg_request = buildExpansionFile();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_apkVersionCode = 42;
      var arg_expansionFileType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExpansionFile.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExpansionFile(obj as api.ExpansionFile);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/apks/"),
        );
        pathOffset += 6;
        index = path.indexOf('/expansionFiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_apkVersionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/expansionFiles/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_expansionFileType'),
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
        var resp = convert.json.encode(buildExpansionFile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_packageName, arg_editId,
          arg_apkVersionCode, arg_expansionFileType,
          $fields: arg_$fields);
      checkExpansionFile(response as api.ExpansionFile);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.expansionfiles;
      var arg_request = buildExpansionFile();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_apkVersionCode = 42;
      var arg_expansionFileType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExpansionFile.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExpansionFile(obj as api.ExpansionFile);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/apks/"),
        );
        pathOffset += 6;
        index = path.indexOf('/expansionFiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_apkVersionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/expansionFiles/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_expansionFileType'),
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
        var resp = convert.json.encode(buildExpansionFile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_packageName,
          arg_editId, arg_apkVersionCode, arg_expansionFileType,
          $fields: arg_$fields);
      checkExpansionFile(response as api.ExpansionFile);
    });

    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.expansionfiles;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_apkVersionCode = 42;
      var arg_expansionFileType = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/apks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/apks/"),
        );
        pathOffset += 6;
        index = path.indexOf('/expansionFiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_apkVersionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/expansionFiles/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_expansionFileType'),
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
        var resp = convert.json.encode(buildExpansionFilesUploadResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.upload(arg_packageName, arg_editId,
          arg_apkVersionCode, arg_expansionFileType,
          $fields: arg_$fields);
      checkExpansionFilesUploadResponse(
          response as api.ExpansionFilesUploadResponse);
    });
  });

  unittest.group('resource-EditsImagesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.images;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
      var arg_imageType = 'foo';
      var arg_imageId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_imageType'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_imageId'),
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
      await res.delete(
          arg_packageName, arg_editId, arg_language, arg_imageType, arg_imageId,
          $fields: arg_$fields);
    });

    unittest.test('method--deleteall', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.images;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
      var arg_imageType = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_imageType'),
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
        var resp = convert.json.encode(buildImagesDeleteAllResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.deleteall(
          arg_packageName, arg_editId, arg_language, arg_imageType,
          $fields: arg_$fields);
      checkImagesDeleteAllResponse(response as api.ImagesDeleteAllResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.images;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
      var arg_imageType = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_imageType'),
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
        var resp = convert.json.encode(buildImagesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_packageName, arg_editId, arg_language, arg_imageType,
          $fields: arg_$fields);
      checkImagesListResponse(response as api.ImagesListResponse);
    });

    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.images;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
      var arg_imageType = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_imageType'),
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
        var resp = convert.json.encode(buildImagesUploadResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.upload(
          arg_packageName, arg_editId, arg_language, arg_imageType,
          $fields: arg_$fields);
      checkImagesUploadResponse(response as api.ImagesUploadResponse);
    });
  });

  unittest.group('resource-EditsListingsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.listings;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
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
      await res.delete(arg_packageName, arg_editId, arg_language,
          $fields: arg_$fields);
    });

    unittest.test('method--deleteall', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.listings;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/listings"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.deleteall(arg_packageName, arg_editId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.listings;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
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
        var resp = convert.json.encode(buildListing());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_packageName, arg_editId, arg_language,
          $fields: arg_$fields);
      checkListing(response as api.Listing);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.listings;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/listings"),
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
        var resp = convert.json.encode(buildListingsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_packageName, arg_editId, $fields: arg_$fields);
      checkListingsListResponse(response as api.ListingsListResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.listings;
      var arg_request = buildListing();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Listing.fromJson(json as core.Map<core.String, core.dynamic>);
        checkListing(obj as api.Listing);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
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
        var resp = convert.json.encode(buildListing());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_packageName, arg_editId, arg_language,
          $fields: arg_$fields);
      checkListing(response as api.Listing);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.listings;
      var arg_request = buildListing();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_language = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Listing.fromJson(json as core.Map<core.String, core.dynamic>);
        checkListing(obj as api.Listing);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/listings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listings/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_language'),
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
        var resp = convert.json.encode(buildListing());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_packageName, arg_editId, arg_language,
          $fields: arg_$fields);
      checkListing(response as api.Listing);
    });
  });

  unittest.group('resource-EditsTestersResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.testers;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_track = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/testers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/testers/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_track'),
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
        var resp = convert.json.encode(buildTesters());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_packageName, arg_editId, arg_track,
          $fields: arg_$fields);
      checkTesters(response as api.Testers);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.testers;
      var arg_request = buildTesters();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_track = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Testers.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTesters(obj as api.Testers);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/testers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/testers/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_track'),
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
        var resp = convert.json.encode(buildTesters());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_packageName, arg_editId, arg_track,
          $fields: arg_$fields);
      checkTesters(response as api.Testers);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.testers;
      var arg_request = buildTesters();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_track = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Testers.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTesters(obj as api.Testers);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/testers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/testers/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_track'),
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
        var resp = convert.json.encode(buildTesters());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_packageName, arg_editId, arg_track,
          $fields: arg_$fields);
      checkTesters(response as api.Testers);
    });
  });

  unittest.group('resource-EditsTracksResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.tracks;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_track = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/tracks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tracks/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_track'),
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
        var resp = convert.json.encode(buildTrack());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_packageName, arg_editId, arg_track,
          $fields: arg_$fields);
      checkTrack(response as api.Track);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.tracks;
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/tracks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tracks"),
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
        var resp = convert.json.encode(buildTracksListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_packageName, arg_editId, $fields: arg_$fields);
      checkTracksListResponse(response as api.TracksListResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.tracks;
      var arg_request = buildTrack();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_track = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Track.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTrack(obj as api.Track);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/tracks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tracks/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_track'),
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
        var resp = convert.json.encode(buildTrack());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_packageName, arg_editId, arg_track,
          $fields: arg_$fields);
      checkTrack(response as api.Track);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).edits.tracks;
      var arg_request = buildTrack();
      var arg_packageName = 'foo';
      var arg_editId = 'foo';
      var arg_track = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Track.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTrack(obj as api.Track);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/edits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/edits/"),
        );
        pathOffset += 7;
        index = path.indexOf('/tracks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_editId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tracks/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_track'),
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
        var resp = convert.json.encode(buildTrack());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_packageName, arg_editId, arg_track,
          $fields: arg_$fields);
      checkTrack(response as api.Track);
    });
  });

  unittest.group('resource-InappproductsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).inappproducts;
      var arg_packageName = 'foo';
      var arg_sku = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/inappproducts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/inappproducts/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sku'),
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
      await res.delete(arg_packageName, arg_sku, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).inappproducts;
      var arg_packageName = 'foo';
      var arg_sku = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/inappproducts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/inappproducts/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sku'),
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
        var resp = convert.json.encode(buildInAppProduct());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_packageName, arg_sku, $fields: arg_$fields);
      checkInAppProduct(response as api.InAppProduct);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).inappproducts;
      var arg_request = buildInAppProduct();
      var arg_packageName = 'foo';
      var arg_autoConvertMissingPrices = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InAppProduct.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInAppProduct(obj as api.InAppProduct);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/inappproducts', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/inappproducts"),
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
          queryMap["autoConvertMissingPrices"]!.first,
          unittest.equals("$arg_autoConvertMissingPrices"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInAppProduct());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_packageName,
          autoConvertMissingPrices: arg_autoConvertMissingPrices,
          $fields: arg_$fields);
      checkInAppProduct(response as api.InAppProduct);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).inappproducts;
      var arg_packageName = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
      var arg_token = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/inappproducts', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/inappproducts"),
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
          core.int.parse(queryMap["startIndex"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["token"]!.first,
          unittest.equals(arg_token),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInappproductsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_packageName,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          token: arg_token,
          $fields: arg_$fields);
      checkInappproductsListResponse(response as api.InappproductsListResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).inappproducts;
      var arg_request = buildInAppProduct();
      var arg_packageName = 'foo';
      var arg_sku = 'foo';
      var arg_autoConvertMissingPrices = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InAppProduct.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInAppProduct(obj as api.InAppProduct);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/inappproducts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/inappproducts/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sku'),
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
          queryMap["autoConvertMissingPrices"]!.first,
          unittest.equals("$arg_autoConvertMissingPrices"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInAppProduct());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_packageName, arg_sku,
          autoConvertMissingPrices: arg_autoConvertMissingPrices,
          $fields: arg_$fields);
      checkInAppProduct(response as api.InAppProduct);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).inappproducts;
      var arg_request = buildInAppProduct();
      var arg_packageName = 'foo';
      var arg_sku = 'foo';
      var arg_autoConvertMissingPrices = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InAppProduct.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInAppProduct(obj as api.InAppProduct);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/inappproducts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/inappproducts/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sku'),
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
          queryMap["autoConvertMissingPrices"]!.first,
          unittest.equals("$arg_autoConvertMissingPrices"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInAppProduct());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_packageName, arg_sku,
          autoConvertMissingPrices: arg_autoConvertMissingPrices,
          $fields: arg_$fields);
      checkInAppProduct(response as api.InAppProduct);
    });
  });

  unittest.group('resource-InternalappsharingartifactsResource', () {
    unittest.test('method--uploadapk', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).internalappsharingartifacts;
      var arg_packageName = 'foo';
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
          path.substring(pathOffset, pathOffset + 52),
          unittest
              .equals("androidpublisher/v3/applications/internalappsharing/"),
        );
        pathOffset += 52;
        index = path.indexOf('/artifacts/apk', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/artifacts/apk"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInternalAppSharingArtifact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.uploadapk(arg_packageName, $fields: arg_$fields);
      checkInternalAppSharingArtifact(
          response as api.InternalAppSharingArtifact);
    });

    unittest.test('method--uploadbundle', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).internalappsharingartifacts;
      var arg_packageName = 'foo';
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
          path.substring(pathOffset, pathOffset + 52),
          unittest
              .equals("androidpublisher/v3/applications/internalappsharing/"),
        );
        pathOffset += 52;
        index = path.indexOf('/artifacts/bundle', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/artifacts/bundle"),
        );
        pathOffset += 17;

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
        var resp = convert.json.encode(buildInternalAppSharingArtifact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.uploadbundle(arg_packageName, $fields: arg_$fields);
      checkInternalAppSharingArtifact(
          response as api.InternalAppSharingArtifact);
    });
  });

  unittest.group('resource-OrdersResource', () {
    unittest.test('method--refund', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).orders;
      var arg_packageName = 'foo';
      var arg_orderId = 'foo';
      var arg_revoke = true;
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/orders/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/orders/"),
        );
        pathOffset += 8;
        index = path.indexOf(':refund', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_orderId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":refund"),
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
          queryMap["revoke"]!.first,
          unittest.equals("$arg_revoke"),
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
      await res.refund(arg_packageName, arg_orderId,
          revoke: arg_revoke, $fields: arg_$fields);
    });
  });

  unittest.group('resource-PurchasesProductsResource', () {
    unittest.test('method--acknowledge', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.products;
      var arg_request = buildProductPurchasesAcknowledgeRequest();
      var arg_packageName = 'foo';
      var arg_productId = 'foo';
      var arg_token = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ProductPurchasesAcknowledgeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkProductPurchasesAcknowledgeRequest(
            obj as api.ProductPurchasesAcknowledgeRequest);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/products/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/purchases/products/"),
        );
        pathOffset += 20;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_productId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        index = path.indexOf(':acknowledge', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals(":acknowledge"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.acknowledge(
          arg_request, arg_packageName, arg_productId, arg_token,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.products;
      var arg_packageName = 'foo';
      var arg_productId = 'foo';
      var arg_token = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/products/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/purchases/products/"),
        );
        pathOffset += 20;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_productId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
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
        var resp = convert.json.encode(buildProductPurchase());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_packageName, arg_productId, arg_token,
          $fields: arg_$fields);
      checkProductPurchase(response as api.ProductPurchase);
    });
  });

  unittest.group('resource-PurchasesSubscriptionsResource', () {
    unittest.test('method--acknowledge', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.subscriptions;
      var arg_request = buildSubscriptionPurchasesAcknowledgeRequest();
      var arg_packageName = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_token = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SubscriptionPurchasesAcknowledgeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSubscriptionPurchasesAcknowledgeRequest(
            obj as api.SubscriptionPurchasesAcknowledgeRequest);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/subscriptions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("/purchases/subscriptions/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        index = path.indexOf(':acknowledge', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals(":acknowledge"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.acknowledge(
          arg_request, arg_packageName, arg_subscriptionId, arg_token,
          $fields: arg_$fields);
    });

    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.subscriptions;
      var arg_packageName = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_token = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/subscriptions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("/purchases/subscriptions/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        index = path.indexOf(':cancel', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":cancel"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.cancel(arg_packageName, arg_subscriptionId, arg_token,
          $fields: arg_$fields);
    });

    unittest.test('method--defer', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.subscriptions;
      var arg_request = buildSubscriptionPurchasesDeferRequest();
      var arg_packageName = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_token = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SubscriptionPurchasesDeferRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSubscriptionPurchasesDeferRequest(
            obj as api.SubscriptionPurchasesDeferRequest);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/subscriptions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("/purchases/subscriptions/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        index = path.indexOf(':defer', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals(":defer"),
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
        var resp =
            convert.json.encode(buildSubscriptionPurchasesDeferResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.defer(
          arg_request, arg_packageName, arg_subscriptionId, arg_token,
          $fields: arg_$fields);
      checkSubscriptionPurchasesDeferResponse(
          response as api.SubscriptionPurchasesDeferResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.subscriptions;
      var arg_packageName = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_token = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/subscriptions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("/purchases/subscriptions/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
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
        var resp = convert.json.encode(buildSubscriptionPurchase());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_packageName, arg_subscriptionId, arg_token,
          $fields: arg_$fields);
      checkSubscriptionPurchase(response as api.SubscriptionPurchase);
    });

    unittest.test('method--refund', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.subscriptions;
      var arg_packageName = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_token = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/subscriptions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("/purchases/subscriptions/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        index = path.indexOf(':refund', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":refund"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.refund(arg_packageName, arg_subscriptionId, arg_token,
          $fields: arg_$fields);
    });

    unittest.test('method--revoke', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.subscriptions;
      var arg_packageName = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_token = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/subscriptions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("/purchases/subscriptions/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        index = path.indexOf(':revoke', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_token'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":revoke"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.revoke(arg_packageName, arg_subscriptionId, arg_token,
          $fields: arg_$fields);
    });
  });

  unittest.group('resource-PurchasesVoidedpurchasesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).purchases.voidedpurchases;
      var arg_packageName = 'foo';
      var arg_endTime = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
      var arg_startTime = 'foo';
      var arg_token = 'foo';
      var arg_type = 42;
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/purchases/voidedpurchases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("/purchases/voidedpurchases"),
        );
        pathOffset += 26;

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
          queryMap["endTime"]!.first,
          unittest.equals(arg_endTime),
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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
        unittest.expect(
          queryMap["token"]!.first,
          unittest.equals(arg_token),
        );
        unittest.expect(
          core.int.parse(queryMap["type"]!.first),
          unittest.equals(arg_type),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVoidedPurchasesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_packageName,
          endTime: arg_endTime,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          startTime: arg_startTime,
          token: arg_token,
          type: arg_type,
          $fields: arg_$fields);
      checkVoidedPurchasesListResponse(
          response as api.VoidedPurchasesListResponse);
    });
  });

  unittest.group('resource-ReviewsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).reviews;
      var arg_packageName = 'foo';
      var arg_reviewId = 'foo';
      var arg_translationLanguage = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/reviews/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/reviews/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_reviewId'),
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
          queryMap["translationLanguage"]!.first,
          unittest.equals(arg_translationLanguage),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReview());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_packageName, arg_reviewId,
          translationLanguage: arg_translationLanguage, $fields: arg_$fields);
      checkReview(response as api.Review);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).reviews;
      var arg_packageName = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
      var arg_token = 'foo';
      var arg_translationLanguage = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/reviews', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/reviews"),
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
          core.int.parse(queryMap["startIndex"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["token"]!.first,
          unittest.equals(arg_token),
        );
        unittest.expect(
          queryMap["translationLanguage"]!.first,
          unittest.equals(arg_translationLanguage),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReviewsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_packageName,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          token: arg_token,
          translationLanguage: arg_translationLanguage,
          $fields: arg_$fields);
      checkReviewsListResponse(response as api.ReviewsListResponse);
    });

    unittest.test('method--reply', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).reviews;
      var arg_request = buildReviewsReplyRequest();
      var arg_packageName = 'foo';
      var arg_reviewId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReviewsReplyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReviewsReplyRequest(obj as api.ReviewsReplyRequest);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/reviews/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/reviews/"),
        );
        pathOffset += 9;
        index = path.indexOf(':reply', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_reviewId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals(":reply"),
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
        var resp = convert.json.encode(buildReviewsReplyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.reply(
          arg_request, arg_packageName, arg_reviewId,
          $fields: arg_$fields);
      checkReviewsReplyResponse(response as api.ReviewsReplyResponse);
    });
  });

  unittest.group('resource-SystemapksVariantsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).systemapks.variants;
      var arg_request = buildVariant();
      var arg_packageName = 'foo';
      var arg_versionCode = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Variant.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVariant(obj as api.Variant);

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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/systemApks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/systemApks/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variants', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/variants"),
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
        var resp = convert.json.encode(buildVariant());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_packageName, arg_versionCode,
          $fields: arg_$fields);
      checkVariant(response as api.Variant);
    });

    unittest.test('method--download', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).systemapks.variants;
      var arg_packageName = 'foo';
      var arg_versionCode = 'foo';
      var arg_variantId = 42;
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/systemApks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/systemApks/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variants/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/variants/"),
        );
        pathOffset += 10;
        index = path.indexOf(':download', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_variantId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals(":download"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.download(arg_packageName, arg_versionCode, arg_variantId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).systemapks.variants;
      var arg_packageName = 'foo';
      var arg_versionCode = 'foo';
      var arg_variantId = 42;
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/systemApks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/systemApks/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variants/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/variants/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_variantId'),
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
        var resp = convert.json.encode(buildVariant());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_packageName, arg_versionCode, arg_variantId,
          $fields: arg_$fields);
      checkVariant(response as api.Variant);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidPublisherApi(mock).systemapks.variants;
      var arg_packageName = 'foo';
      var arg_versionCode = 'foo';
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
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("androidpublisher/v3/applications/"),
        );
        pathOffset += 33;
        index = path.indexOf('/systemApks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_packageName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/systemApks/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variants', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionCode'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/variants"),
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
        var resp = convert.json.encode(buildSystemApksListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_packageName, arg_versionCode,
          $fields: arg_$fields);
      checkSystemApksListResponse(response as api.SystemApksListResponse);
    });
  });
}

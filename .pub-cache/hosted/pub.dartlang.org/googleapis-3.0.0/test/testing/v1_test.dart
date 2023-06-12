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

import 'package:googleapis/testing/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAccount = 0;
api.Account buildAccount() {
  var o = api.Account();
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    o.googleAuto = buildGoogleAuto();
  }
  buildCounterAccount--;
  return o;
}

void checkAccount(api.Account o) {
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    checkGoogleAuto(o.googleAuto! as api.GoogleAuto);
  }
  buildCounterAccount--;
}

core.int buildCounterAndroidDevice = 0;
api.AndroidDevice buildAndroidDevice() {
  var o = api.AndroidDevice();
  buildCounterAndroidDevice++;
  if (buildCounterAndroidDevice < 3) {
    o.androidModelId = 'foo';
    o.androidVersionId = 'foo';
    o.locale = 'foo';
    o.orientation = 'foo';
  }
  buildCounterAndroidDevice--;
  return o;
}

void checkAndroidDevice(api.AndroidDevice o) {
  buildCounterAndroidDevice++;
  if (buildCounterAndroidDevice < 3) {
    unittest.expect(
      o.androidModelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.androidVersionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orientation!,
      unittest.equals('foo'),
    );
  }
  buildCounterAndroidDevice--;
}

core.List<api.AndroidModel> buildUnnamed161() {
  var o = <api.AndroidModel>[];
  o.add(buildAndroidModel());
  o.add(buildAndroidModel());
  return o;
}

void checkUnnamed161(core.List<api.AndroidModel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAndroidModel(o[0] as api.AndroidModel);
  checkAndroidModel(o[1] as api.AndroidModel);
}

core.List<api.AndroidVersion> buildUnnamed162() {
  var o = <api.AndroidVersion>[];
  o.add(buildAndroidVersion());
  o.add(buildAndroidVersion());
  return o;
}

void checkUnnamed162(core.List<api.AndroidVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAndroidVersion(o[0] as api.AndroidVersion);
  checkAndroidVersion(o[1] as api.AndroidVersion);
}

core.int buildCounterAndroidDeviceCatalog = 0;
api.AndroidDeviceCatalog buildAndroidDeviceCatalog() {
  var o = api.AndroidDeviceCatalog();
  buildCounterAndroidDeviceCatalog++;
  if (buildCounterAndroidDeviceCatalog < 3) {
    o.models = buildUnnamed161();
    o.runtimeConfiguration = buildAndroidRuntimeConfiguration();
    o.versions = buildUnnamed162();
  }
  buildCounterAndroidDeviceCatalog--;
  return o;
}

void checkAndroidDeviceCatalog(api.AndroidDeviceCatalog o) {
  buildCounterAndroidDeviceCatalog++;
  if (buildCounterAndroidDeviceCatalog < 3) {
    checkUnnamed161(o.models!);
    checkAndroidRuntimeConfiguration(
        o.runtimeConfiguration! as api.AndroidRuntimeConfiguration);
    checkUnnamed162(o.versions!);
  }
  buildCounterAndroidDeviceCatalog--;
}

core.List<api.AndroidDevice> buildUnnamed163() {
  var o = <api.AndroidDevice>[];
  o.add(buildAndroidDevice());
  o.add(buildAndroidDevice());
  return o;
}

void checkUnnamed163(core.List<api.AndroidDevice> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAndroidDevice(o[0] as api.AndroidDevice);
  checkAndroidDevice(o[1] as api.AndroidDevice);
}

core.int buildCounterAndroidDeviceList = 0;
api.AndroidDeviceList buildAndroidDeviceList() {
  var o = api.AndroidDeviceList();
  buildCounterAndroidDeviceList++;
  if (buildCounterAndroidDeviceList < 3) {
    o.androidDevices = buildUnnamed163();
  }
  buildCounterAndroidDeviceList--;
  return o;
}

void checkAndroidDeviceList(api.AndroidDeviceList o) {
  buildCounterAndroidDeviceList++;
  if (buildCounterAndroidDeviceList < 3) {
    checkUnnamed163(o.androidDevices!);
  }
  buildCounterAndroidDeviceList--;
}

core.List<core.String> buildUnnamed164() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed164(core.List<core.String> o) {
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

core.int buildCounterAndroidInstrumentationTest = 0;
api.AndroidInstrumentationTest buildAndroidInstrumentationTest() {
  var o = api.AndroidInstrumentationTest();
  buildCounterAndroidInstrumentationTest++;
  if (buildCounterAndroidInstrumentationTest < 3) {
    o.appApk = buildFileReference();
    o.appBundle = buildAppBundle();
    o.appPackageId = 'foo';
    o.orchestratorOption = 'foo';
    o.shardingOption = buildShardingOption();
    o.testApk = buildFileReference();
    o.testPackageId = 'foo';
    o.testRunnerClass = 'foo';
    o.testTargets = buildUnnamed164();
  }
  buildCounterAndroidInstrumentationTest--;
  return o;
}

void checkAndroidInstrumentationTest(api.AndroidInstrumentationTest o) {
  buildCounterAndroidInstrumentationTest++;
  if (buildCounterAndroidInstrumentationTest < 3) {
    checkFileReference(o.appApk! as api.FileReference);
    checkAppBundle(o.appBundle! as api.AppBundle);
    unittest.expect(
      o.appPackageId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orchestratorOption!,
      unittest.equals('foo'),
    );
    checkShardingOption(o.shardingOption! as api.ShardingOption);
    checkFileReference(o.testApk! as api.FileReference);
    unittest.expect(
      o.testPackageId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.testRunnerClass!,
      unittest.equals('foo'),
    );
    checkUnnamed164(o.testTargets!);
  }
  buildCounterAndroidInstrumentationTest--;
}

core.List<core.String> buildUnnamed165() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed165(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed166() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed166(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed167() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed167(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed168() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed168(core.List<core.String> o) {
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

core.int buildCounterAndroidMatrix = 0;
api.AndroidMatrix buildAndroidMatrix() {
  var o = api.AndroidMatrix();
  buildCounterAndroidMatrix++;
  if (buildCounterAndroidMatrix < 3) {
    o.androidModelIds = buildUnnamed165();
    o.androidVersionIds = buildUnnamed166();
    o.locales = buildUnnamed167();
    o.orientations = buildUnnamed168();
  }
  buildCounterAndroidMatrix--;
  return o;
}

void checkAndroidMatrix(api.AndroidMatrix o) {
  buildCounterAndroidMatrix++;
  if (buildCounterAndroidMatrix < 3) {
    checkUnnamed165(o.androidModelIds!);
    checkUnnamed166(o.androidVersionIds!);
    checkUnnamed167(o.locales!);
    checkUnnamed168(o.orientations!);
  }
  buildCounterAndroidMatrix--;
}

core.List<core.String> buildUnnamed169() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed169(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed170() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed170(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed171() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed171(core.List<core.String> o) {
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

core.int buildCounterAndroidModel = 0;
api.AndroidModel buildAndroidModel() {
  var o = api.AndroidModel();
  buildCounterAndroidModel++;
  if (buildCounterAndroidModel < 3) {
    o.brand = 'foo';
    o.codename = 'foo';
    o.form = 'foo';
    o.formFactor = 'foo';
    o.id = 'foo';
    o.lowFpsVideoRecording = true;
    o.manufacturer = 'foo';
    o.name = 'foo';
    o.screenDensity = 42;
    o.screenX = 42;
    o.screenY = 42;
    o.supportedAbis = buildUnnamed169();
    o.supportedVersionIds = buildUnnamed170();
    o.tags = buildUnnamed171();
    o.thumbnailUrl = 'foo';
  }
  buildCounterAndroidModel--;
  return o;
}

void checkAndroidModel(api.AndroidModel o) {
  buildCounterAndroidModel++;
  if (buildCounterAndroidModel < 3) {
    unittest.expect(
      o.brand!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.codename!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.form!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formFactor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.lowFpsVideoRecording!, unittest.isTrue);
    unittest.expect(
      o.manufacturer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenDensity!,
      unittest.equals(42),
    );
    unittest.expect(
      o.screenX!,
      unittest.equals(42),
    );
    unittest.expect(
      o.screenY!,
      unittest.equals(42),
    );
    checkUnnamed169(o.supportedAbis!);
    checkUnnamed170(o.supportedVersionIds!);
    checkUnnamed171(o.tags!);
    unittest.expect(
      o.thumbnailUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterAndroidModel--;
}

core.List<api.RoboDirective> buildUnnamed172() {
  var o = <api.RoboDirective>[];
  o.add(buildRoboDirective());
  o.add(buildRoboDirective());
  return o;
}

void checkUnnamed172(core.List<api.RoboDirective> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRoboDirective(o[0] as api.RoboDirective);
  checkRoboDirective(o[1] as api.RoboDirective);
}

core.List<api.RoboStartingIntent> buildUnnamed173() {
  var o = <api.RoboStartingIntent>[];
  o.add(buildRoboStartingIntent());
  o.add(buildRoboStartingIntent());
  return o;
}

void checkUnnamed173(core.List<api.RoboStartingIntent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRoboStartingIntent(o[0] as api.RoboStartingIntent);
  checkRoboStartingIntent(o[1] as api.RoboStartingIntent);
}

core.int buildCounterAndroidRoboTest = 0;
api.AndroidRoboTest buildAndroidRoboTest() {
  var o = api.AndroidRoboTest();
  buildCounterAndroidRoboTest++;
  if (buildCounterAndroidRoboTest < 3) {
    o.appApk = buildFileReference();
    o.appBundle = buildAppBundle();
    o.appInitialActivity = 'foo';
    o.appPackageId = 'foo';
    o.maxDepth = 42;
    o.maxSteps = 42;
    o.roboDirectives = buildUnnamed172();
    o.roboScript = buildFileReference();
    o.startingIntents = buildUnnamed173();
  }
  buildCounterAndroidRoboTest--;
  return o;
}

void checkAndroidRoboTest(api.AndroidRoboTest o) {
  buildCounterAndroidRoboTest++;
  if (buildCounterAndroidRoboTest < 3) {
    checkFileReference(o.appApk! as api.FileReference);
    checkAppBundle(o.appBundle! as api.AppBundle);
    unittest.expect(
      o.appInitialActivity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appPackageId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxDepth!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxSteps!,
      unittest.equals(42),
    );
    checkUnnamed172(o.roboDirectives!);
    checkFileReference(o.roboScript! as api.FileReference);
    checkUnnamed173(o.startingIntents!);
  }
  buildCounterAndroidRoboTest--;
}

core.List<api.Locale> buildUnnamed174() {
  var o = <api.Locale>[];
  o.add(buildLocale());
  o.add(buildLocale());
  return o;
}

void checkUnnamed174(core.List<api.Locale> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocale(o[0] as api.Locale);
  checkLocale(o[1] as api.Locale);
}

core.List<api.Orientation> buildUnnamed175() {
  var o = <api.Orientation>[];
  o.add(buildOrientation());
  o.add(buildOrientation());
  return o;
}

void checkUnnamed175(core.List<api.Orientation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrientation(o[0] as api.Orientation);
  checkOrientation(o[1] as api.Orientation);
}

core.int buildCounterAndroidRuntimeConfiguration = 0;
api.AndroidRuntimeConfiguration buildAndroidRuntimeConfiguration() {
  var o = api.AndroidRuntimeConfiguration();
  buildCounterAndroidRuntimeConfiguration++;
  if (buildCounterAndroidRuntimeConfiguration < 3) {
    o.locales = buildUnnamed174();
    o.orientations = buildUnnamed175();
  }
  buildCounterAndroidRuntimeConfiguration--;
  return o;
}

void checkAndroidRuntimeConfiguration(api.AndroidRuntimeConfiguration o) {
  buildCounterAndroidRuntimeConfiguration++;
  if (buildCounterAndroidRuntimeConfiguration < 3) {
    checkUnnamed174(o.locales!);
    checkUnnamed175(o.orientations!);
  }
  buildCounterAndroidRuntimeConfiguration--;
}

core.List<core.String> buildUnnamed176() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed176(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed177() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed177(core.List<core.int> o) {
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

core.int buildCounterAndroidTestLoop = 0;
api.AndroidTestLoop buildAndroidTestLoop() {
  var o = api.AndroidTestLoop();
  buildCounterAndroidTestLoop++;
  if (buildCounterAndroidTestLoop < 3) {
    o.appApk = buildFileReference();
    o.appBundle = buildAppBundle();
    o.appPackageId = 'foo';
    o.scenarioLabels = buildUnnamed176();
    o.scenarios = buildUnnamed177();
  }
  buildCounterAndroidTestLoop--;
  return o;
}

void checkAndroidTestLoop(api.AndroidTestLoop o) {
  buildCounterAndroidTestLoop++;
  if (buildCounterAndroidTestLoop < 3) {
    checkFileReference(o.appApk! as api.FileReference);
    checkAppBundle(o.appBundle! as api.AppBundle);
    unittest.expect(
      o.appPackageId!,
      unittest.equals('foo'),
    );
    checkUnnamed176(o.scenarioLabels!);
    checkUnnamed177(o.scenarios!);
  }
  buildCounterAndroidTestLoop--;
}

core.List<core.String> buildUnnamed178() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed178(core.List<core.String> o) {
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

core.int buildCounterAndroidVersion = 0;
api.AndroidVersion buildAndroidVersion() {
  var o = api.AndroidVersion();
  buildCounterAndroidVersion++;
  if (buildCounterAndroidVersion < 3) {
    o.apiLevel = 42;
    o.codeName = 'foo';
    o.distribution = buildDistribution();
    o.id = 'foo';
    o.releaseDate = buildDate();
    o.tags = buildUnnamed178();
    o.versionString = 'foo';
  }
  buildCounterAndroidVersion--;
  return o;
}

void checkAndroidVersion(api.AndroidVersion o) {
  buildCounterAndroidVersion++;
  if (buildCounterAndroidVersion < 3) {
    unittest.expect(
      o.apiLevel!,
      unittest.equals(42),
    );
    unittest.expect(
      o.codeName!,
      unittest.equals('foo'),
    );
    checkDistribution(o.distribution! as api.Distribution);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkDate(o.releaseDate! as api.Date);
    checkUnnamed178(o.tags!);
    unittest.expect(
      o.versionString!,
      unittest.equals('foo'),
    );
  }
  buildCounterAndroidVersion--;
}

core.int buildCounterApk = 0;
api.Apk buildApk() {
  var o = api.Apk();
  buildCounterApk++;
  if (buildCounterApk < 3) {
    o.location = buildFileReference();
    o.packageName = 'foo';
  }
  buildCounterApk--;
  return o;
}

void checkApk(api.Apk o) {
  buildCounterApk++;
  if (buildCounterApk < 3) {
    checkFileReference(o.location! as api.FileReference);
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
  }
  buildCounterApk--;
}

core.int buildCounterApkDetail = 0;
api.ApkDetail buildApkDetail() {
  var o = api.ApkDetail();
  buildCounterApkDetail++;
  if (buildCounterApkDetail < 3) {
    o.apkManifest = buildApkManifest();
  }
  buildCounterApkDetail--;
  return o;
}

void checkApkDetail(api.ApkDetail o) {
  buildCounterApkDetail++;
  if (buildCounterApkDetail < 3) {
    checkApkManifest(o.apkManifest! as api.ApkManifest);
  }
  buildCounterApkDetail--;
}

core.List<api.IntentFilter> buildUnnamed179() {
  var o = <api.IntentFilter>[];
  o.add(buildIntentFilter());
  o.add(buildIntentFilter());
  return o;
}

void checkUnnamed179(core.List<api.IntentFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIntentFilter(o[0] as api.IntentFilter);
  checkIntentFilter(o[1] as api.IntentFilter);
}

core.List<core.String> buildUnnamed180() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed180(core.List<core.String> o) {
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

core.int buildCounterApkManifest = 0;
api.ApkManifest buildApkManifest() {
  var o = api.ApkManifest();
  buildCounterApkManifest++;
  if (buildCounterApkManifest < 3) {
    o.applicationLabel = 'foo';
    o.intentFilters = buildUnnamed179();
    o.maxSdkVersion = 42;
    o.minSdkVersion = 42;
    o.packageName = 'foo';
    o.targetSdkVersion = 42;
    o.usesPermission = buildUnnamed180();
  }
  buildCounterApkManifest--;
  return o;
}

void checkApkManifest(api.ApkManifest o) {
  buildCounterApkManifest++;
  if (buildCounterApkManifest < 3) {
    unittest.expect(
      o.applicationLabel!,
      unittest.equals('foo'),
    );
    checkUnnamed179(o.intentFilters!);
    unittest.expect(
      o.maxSdkVersion!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minSdkVersion!,
      unittest.equals(42),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetSdkVersion!,
      unittest.equals(42),
    );
    checkUnnamed180(o.usesPermission!);
  }
  buildCounterApkManifest--;
}

core.int buildCounterAppBundle = 0;
api.AppBundle buildAppBundle() {
  var o = api.AppBundle();
  buildCounterAppBundle++;
  if (buildCounterAppBundle < 3) {
    o.bundleLocation = buildFileReference();
  }
  buildCounterAppBundle--;
  return o;
}

void checkAppBundle(api.AppBundle o) {
  buildCounterAppBundle++;
  if (buildCounterAppBundle < 3) {
    checkFileReference(o.bundleLocation! as api.FileReference);
  }
  buildCounterAppBundle--;
}

core.int buildCounterCancelTestMatrixResponse = 0;
api.CancelTestMatrixResponse buildCancelTestMatrixResponse() {
  var o = api.CancelTestMatrixResponse();
  buildCounterCancelTestMatrixResponse++;
  if (buildCounterCancelTestMatrixResponse < 3) {
    o.testState = 'foo';
  }
  buildCounterCancelTestMatrixResponse--;
  return o;
}

void checkCancelTestMatrixResponse(api.CancelTestMatrixResponse o) {
  buildCounterCancelTestMatrixResponse++;
  if (buildCounterCancelTestMatrixResponse < 3) {
    unittest.expect(
      o.testState!,
      unittest.equals('foo'),
    );
  }
  buildCounterCancelTestMatrixResponse--;
}

core.List<api.ClientInfoDetail> buildUnnamed181() {
  var o = <api.ClientInfoDetail>[];
  o.add(buildClientInfoDetail());
  o.add(buildClientInfoDetail());
  return o;
}

void checkUnnamed181(core.List<api.ClientInfoDetail> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkClientInfoDetail(o[0] as api.ClientInfoDetail);
  checkClientInfoDetail(o[1] as api.ClientInfoDetail);
}

core.int buildCounterClientInfo = 0;
api.ClientInfo buildClientInfo() {
  var o = api.ClientInfo();
  buildCounterClientInfo++;
  if (buildCounterClientInfo < 3) {
    o.clientInfoDetails = buildUnnamed181();
    o.name = 'foo';
  }
  buildCounterClientInfo--;
  return o;
}

void checkClientInfo(api.ClientInfo o) {
  buildCounterClientInfo++;
  if (buildCounterClientInfo < 3) {
    checkUnnamed181(o.clientInfoDetails!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterClientInfo--;
}

core.int buildCounterClientInfoDetail = 0;
api.ClientInfoDetail buildClientInfoDetail() {
  var o = api.ClientInfoDetail();
  buildCounterClientInfoDetail++;
  if (buildCounterClientInfoDetail < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterClientInfoDetail--;
  return o;
}

void checkClientInfoDetail(api.ClientInfoDetail o) {
  buildCounterClientInfoDetail++;
  if (buildCounterClientInfoDetail < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterClientInfoDetail--;
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

core.int buildCounterDeviceFile = 0;
api.DeviceFile buildDeviceFile() {
  var o = api.DeviceFile();
  buildCounterDeviceFile++;
  if (buildCounterDeviceFile < 3) {
    o.obbFile = buildObbFile();
    o.regularFile = buildRegularFile();
  }
  buildCounterDeviceFile--;
  return o;
}

void checkDeviceFile(api.DeviceFile o) {
  buildCounterDeviceFile++;
  if (buildCounterDeviceFile < 3) {
    checkObbFile(o.obbFile! as api.ObbFile);
    checkRegularFile(o.regularFile! as api.RegularFile);
  }
  buildCounterDeviceFile--;
}

core.int buildCounterDeviceIpBlock = 0;
api.DeviceIpBlock buildDeviceIpBlock() {
  var o = api.DeviceIpBlock();
  buildCounterDeviceIpBlock++;
  if (buildCounterDeviceIpBlock < 3) {
    o.addedDate = buildDate();
    o.block = 'foo';
    o.form = 'foo';
  }
  buildCounterDeviceIpBlock--;
  return o;
}

void checkDeviceIpBlock(api.DeviceIpBlock o) {
  buildCounterDeviceIpBlock++;
  if (buildCounterDeviceIpBlock < 3) {
    checkDate(o.addedDate! as api.Date);
    unittest.expect(
      o.block!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.form!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceIpBlock--;
}

core.List<api.DeviceIpBlock> buildUnnamed182() {
  var o = <api.DeviceIpBlock>[];
  o.add(buildDeviceIpBlock());
  o.add(buildDeviceIpBlock());
  return o;
}

void checkUnnamed182(core.List<api.DeviceIpBlock> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeviceIpBlock(o[0] as api.DeviceIpBlock);
  checkDeviceIpBlock(o[1] as api.DeviceIpBlock);
}

core.int buildCounterDeviceIpBlockCatalog = 0;
api.DeviceIpBlockCatalog buildDeviceIpBlockCatalog() {
  var o = api.DeviceIpBlockCatalog();
  buildCounterDeviceIpBlockCatalog++;
  if (buildCounterDeviceIpBlockCatalog < 3) {
    o.ipBlocks = buildUnnamed182();
  }
  buildCounterDeviceIpBlockCatalog--;
  return o;
}

void checkDeviceIpBlockCatalog(api.DeviceIpBlockCatalog o) {
  buildCounterDeviceIpBlockCatalog++;
  if (buildCounterDeviceIpBlockCatalog < 3) {
    checkUnnamed182(o.ipBlocks!);
  }
  buildCounterDeviceIpBlockCatalog--;
}

core.int buildCounterDistribution = 0;
api.Distribution buildDistribution() {
  var o = api.Distribution();
  buildCounterDistribution++;
  if (buildCounterDistribution < 3) {
    o.marketShare = 42.0;
    o.measurementTime = 'foo';
  }
  buildCounterDistribution--;
  return o;
}

void checkDistribution(api.Distribution o) {
  buildCounterDistribution++;
  if (buildCounterDistribution < 3) {
    unittest.expect(
      o.marketShare!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.measurementTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterDistribution--;
}

core.int buildCounterEnvironment = 0;
api.Environment buildEnvironment() {
  var o = api.Environment();
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    o.androidDevice = buildAndroidDevice();
    o.iosDevice = buildIosDevice();
  }
  buildCounterEnvironment--;
  return o;
}

void checkEnvironment(api.Environment o) {
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    checkAndroidDevice(o.androidDevice! as api.AndroidDevice);
    checkIosDevice(o.iosDevice! as api.IosDevice);
  }
  buildCounterEnvironment--;
}

core.int buildCounterEnvironmentMatrix = 0;
api.EnvironmentMatrix buildEnvironmentMatrix() {
  var o = api.EnvironmentMatrix();
  buildCounterEnvironmentMatrix++;
  if (buildCounterEnvironmentMatrix < 3) {
    o.androidDeviceList = buildAndroidDeviceList();
    o.androidMatrix = buildAndroidMatrix();
    o.iosDeviceList = buildIosDeviceList();
  }
  buildCounterEnvironmentMatrix--;
  return o;
}

void checkEnvironmentMatrix(api.EnvironmentMatrix o) {
  buildCounterEnvironmentMatrix++;
  if (buildCounterEnvironmentMatrix < 3) {
    checkAndroidDeviceList(o.androidDeviceList! as api.AndroidDeviceList);
    checkAndroidMatrix(o.androidMatrix! as api.AndroidMatrix);
    checkIosDeviceList(o.iosDeviceList! as api.IosDeviceList);
  }
  buildCounterEnvironmentMatrix--;
}

core.int buildCounterEnvironmentVariable = 0;
api.EnvironmentVariable buildEnvironmentVariable() {
  var o = api.EnvironmentVariable();
  buildCounterEnvironmentVariable++;
  if (buildCounterEnvironmentVariable < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterEnvironmentVariable--;
  return o;
}

void checkEnvironmentVariable(api.EnvironmentVariable o) {
  buildCounterEnvironmentVariable++;
  if (buildCounterEnvironmentVariable < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnvironmentVariable--;
}

core.int buildCounterFileReference = 0;
api.FileReference buildFileReference() {
  var o = api.FileReference();
  buildCounterFileReference++;
  if (buildCounterFileReference < 3) {
    o.gcsPath = 'foo';
  }
  buildCounterFileReference--;
  return o;
}

void checkFileReference(api.FileReference o) {
  buildCounterFileReference++;
  if (buildCounterFileReference < 3) {
    unittest.expect(
      o.gcsPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterFileReference--;
}

core.int buildCounterGetApkDetailsResponse = 0;
api.GetApkDetailsResponse buildGetApkDetailsResponse() {
  var o = api.GetApkDetailsResponse();
  buildCounterGetApkDetailsResponse++;
  if (buildCounterGetApkDetailsResponse < 3) {
    o.apkDetail = buildApkDetail();
  }
  buildCounterGetApkDetailsResponse--;
  return o;
}

void checkGetApkDetailsResponse(api.GetApkDetailsResponse o) {
  buildCounterGetApkDetailsResponse++;
  if (buildCounterGetApkDetailsResponse < 3) {
    checkApkDetail(o.apkDetail! as api.ApkDetail);
  }
  buildCounterGetApkDetailsResponse--;
}

core.int buildCounterGoogleAuto = 0;
api.GoogleAuto buildGoogleAuto() {
  var o = api.GoogleAuto();
  buildCounterGoogleAuto++;
  if (buildCounterGoogleAuto < 3) {}
  buildCounterGoogleAuto--;
  return o;
}

void checkGoogleAuto(api.GoogleAuto o) {
  buildCounterGoogleAuto++;
  if (buildCounterGoogleAuto < 3) {}
  buildCounterGoogleAuto--;
}

core.int buildCounterGoogleCloudStorage = 0;
api.GoogleCloudStorage buildGoogleCloudStorage() {
  var o = api.GoogleCloudStorage();
  buildCounterGoogleCloudStorage++;
  if (buildCounterGoogleCloudStorage < 3) {
    o.gcsPath = 'foo';
  }
  buildCounterGoogleCloudStorage--;
  return o;
}

void checkGoogleCloudStorage(api.GoogleCloudStorage o) {
  buildCounterGoogleCloudStorage++;
  if (buildCounterGoogleCloudStorage < 3) {
    unittest.expect(
      o.gcsPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudStorage--;
}

core.List<core.String> buildUnnamed183() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed183(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed184() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed184(core.List<core.String> o) {
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

core.int buildCounterIntentFilter = 0;
api.IntentFilter buildIntentFilter() {
  var o = api.IntentFilter();
  buildCounterIntentFilter++;
  if (buildCounterIntentFilter < 3) {
    o.actionNames = buildUnnamed183();
    o.categoryNames = buildUnnamed184();
    o.mimeType = 'foo';
  }
  buildCounterIntentFilter--;
  return o;
}

void checkIntentFilter(api.IntentFilter o) {
  buildCounterIntentFilter++;
  if (buildCounterIntentFilter < 3) {
    checkUnnamed183(o.actionNames!);
    checkUnnamed184(o.categoryNames!);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
  }
  buildCounterIntentFilter--;
}

core.int buildCounterIosDevice = 0;
api.IosDevice buildIosDevice() {
  var o = api.IosDevice();
  buildCounterIosDevice++;
  if (buildCounterIosDevice < 3) {
    o.iosModelId = 'foo';
    o.iosVersionId = 'foo';
    o.locale = 'foo';
    o.orientation = 'foo';
  }
  buildCounterIosDevice--;
  return o;
}

void checkIosDevice(api.IosDevice o) {
  buildCounterIosDevice++;
  if (buildCounterIosDevice < 3) {
    unittest.expect(
      o.iosModelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosVersionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orientation!,
      unittest.equals('foo'),
    );
  }
  buildCounterIosDevice--;
}

core.List<api.IosModel> buildUnnamed185() {
  var o = <api.IosModel>[];
  o.add(buildIosModel());
  o.add(buildIosModel());
  return o;
}

void checkUnnamed185(core.List<api.IosModel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIosModel(o[0] as api.IosModel);
  checkIosModel(o[1] as api.IosModel);
}

core.List<api.IosVersion> buildUnnamed186() {
  var o = <api.IosVersion>[];
  o.add(buildIosVersion());
  o.add(buildIosVersion());
  return o;
}

void checkUnnamed186(core.List<api.IosVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIosVersion(o[0] as api.IosVersion);
  checkIosVersion(o[1] as api.IosVersion);
}

core.List<api.XcodeVersion> buildUnnamed187() {
  var o = <api.XcodeVersion>[];
  o.add(buildXcodeVersion());
  o.add(buildXcodeVersion());
  return o;
}

void checkUnnamed187(core.List<api.XcodeVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkXcodeVersion(o[0] as api.XcodeVersion);
  checkXcodeVersion(o[1] as api.XcodeVersion);
}

core.int buildCounterIosDeviceCatalog = 0;
api.IosDeviceCatalog buildIosDeviceCatalog() {
  var o = api.IosDeviceCatalog();
  buildCounterIosDeviceCatalog++;
  if (buildCounterIosDeviceCatalog < 3) {
    o.models = buildUnnamed185();
    o.runtimeConfiguration = buildIosRuntimeConfiguration();
    o.versions = buildUnnamed186();
    o.xcodeVersions = buildUnnamed187();
  }
  buildCounterIosDeviceCatalog--;
  return o;
}

void checkIosDeviceCatalog(api.IosDeviceCatalog o) {
  buildCounterIosDeviceCatalog++;
  if (buildCounterIosDeviceCatalog < 3) {
    checkUnnamed185(o.models!);
    checkIosRuntimeConfiguration(
        o.runtimeConfiguration! as api.IosRuntimeConfiguration);
    checkUnnamed186(o.versions!);
    checkUnnamed187(o.xcodeVersions!);
  }
  buildCounterIosDeviceCatalog--;
}

core.int buildCounterIosDeviceFile = 0;
api.IosDeviceFile buildIosDeviceFile() {
  var o = api.IosDeviceFile();
  buildCounterIosDeviceFile++;
  if (buildCounterIosDeviceFile < 3) {
    o.bundleId = 'foo';
    o.content = buildFileReference();
    o.devicePath = 'foo';
  }
  buildCounterIosDeviceFile--;
  return o;
}

void checkIosDeviceFile(api.IosDeviceFile o) {
  buildCounterIosDeviceFile++;
  if (buildCounterIosDeviceFile < 3) {
    unittest.expect(
      o.bundleId!,
      unittest.equals('foo'),
    );
    checkFileReference(o.content! as api.FileReference);
    unittest.expect(
      o.devicePath!,
      unittest.equals('foo'),
    );
  }
  buildCounterIosDeviceFile--;
}

core.List<api.IosDevice> buildUnnamed188() {
  var o = <api.IosDevice>[];
  o.add(buildIosDevice());
  o.add(buildIosDevice());
  return o;
}

void checkUnnamed188(core.List<api.IosDevice> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIosDevice(o[0] as api.IosDevice);
  checkIosDevice(o[1] as api.IosDevice);
}

core.int buildCounterIosDeviceList = 0;
api.IosDeviceList buildIosDeviceList() {
  var o = api.IosDeviceList();
  buildCounterIosDeviceList++;
  if (buildCounterIosDeviceList < 3) {
    o.iosDevices = buildUnnamed188();
  }
  buildCounterIosDeviceList--;
  return o;
}

void checkIosDeviceList(api.IosDeviceList o) {
  buildCounterIosDeviceList++;
  if (buildCounterIosDeviceList < 3) {
    checkUnnamed188(o.iosDevices!);
  }
  buildCounterIosDeviceList--;
}

core.List<core.String> buildUnnamed189() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed189(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed190() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed190(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed191() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed191(core.List<core.String> o) {
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

core.int buildCounterIosModel = 0;
api.IosModel buildIosModel() {
  var o = api.IosModel();
  buildCounterIosModel++;
  if (buildCounterIosModel < 3) {
    o.deviceCapabilities = buildUnnamed189();
    o.formFactor = 'foo';
    o.id = 'foo';
    o.name = 'foo';
    o.screenDensity = 42;
    o.screenX = 42;
    o.screenY = 42;
    o.supportedVersionIds = buildUnnamed190();
    o.tags = buildUnnamed191();
  }
  buildCounterIosModel--;
  return o;
}

void checkIosModel(api.IosModel o) {
  buildCounterIosModel++;
  if (buildCounterIosModel < 3) {
    checkUnnamed189(o.deviceCapabilities!);
    unittest.expect(
      o.formFactor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenDensity!,
      unittest.equals(42),
    );
    unittest.expect(
      o.screenX!,
      unittest.equals(42),
    );
    unittest.expect(
      o.screenY!,
      unittest.equals(42),
    );
    checkUnnamed190(o.supportedVersionIds!);
    checkUnnamed191(o.tags!);
  }
  buildCounterIosModel--;
}

core.List<api.Locale> buildUnnamed192() {
  var o = <api.Locale>[];
  o.add(buildLocale());
  o.add(buildLocale());
  return o;
}

void checkUnnamed192(core.List<api.Locale> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocale(o[0] as api.Locale);
  checkLocale(o[1] as api.Locale);
}

core.List<api.Orientation> buildUnnamed193() {
  var o = <api.Orientation>[];
  o.add(buildOrientation());
  o.add(buildOrientation());
  return o;
}

void checkUnnamed193(core.List<api.Orientation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrientation(o[0] as api.Orientation);
  checkOrientation(o[1] as api.Orientation);
}

core.int buildCounterIosRuntimeConfiguration = 0;
api.IosRuntimeConfiguration buildIosRuntimeConfiguration() {
  var o = api.IosRuntimeConfiguration();
  buildCounterIosRuntimeConfiguration++;
  if (buildCounterIosRuntimeConfiguration < 3) {
    o.locales = buildUnnamed192();
    o.orientations = buildUnnamed193();
  }
  buildCounterIosRuntimeConfiguration--;
  return o;
}

void checkIosRuntimeConfiguration(api.IosRuntimeConfiguration o) {
  buildCounterIosRuntimeConfiguration++;
  if (buildCounterIosRuntimeConfiguration < 3) {
    checkUnnamed192(o.locales!);
    checkUnnamed193(o.orientations!);
  }
  buildCounterIosRuntimeConfiguration--;
}

core.List<core.int> buildUnnamed194() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed194(core.List<core.int> o) {
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

core.int buildCounterIosTestLoop = 0;
api.IosTestLoop buildIosTestLoop() {
  var o = api.IosTestLoop();
  buildCounterIosTestLoop++;
  if (buildCounterIosTestLoop < 3) {
    o.appBundleId = 'foo';
    o.appIpa = buildFileReference();
    o.scenarios = buildUnnamed194();
  }
  buildCounterIosTestLoop--;
  return o;
}

void checkIosTestLoop(api.IosTestLoop o) {
  buildCounterIosTestLoop++;
  if (buildCounterIosTestLoop < 3) {
    unittest.expect(
      o.appBundleId!,
      unittest.equals('foo'),
    );
    checkFileReference(o.appIpa! as api.FileReference);
    checkUnnamed194(o.scenarios!);
  }
  buildCounterIosTestLoop--;
}

core.List<api.FileReference> buildUnnamed195() {
  var o = <api.FileReference>[];
  o.add(buildFileReference());
  o.add(buildFileReference());
  return o;
}

void checkUnnamed195(core.List<api.FileReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFileReference(o[0] as api.FileReference);
  checkFileReference(o[1] as api.FileReference);
}

core.List<api.IosDeviceFile> buildUnnamed196() {
  var o = <api.IosDeviceFile>[];
  o.add(buildIosDeviceFile());
  o.add(buildIosDeviceFile());
  return o;
}

void checkUnnamed196(core.List<api.IosDeviceFile> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIosDeviceFile(o[0] as api.IosDeviceFile);
  checkIosDeviceFile(o[1] as api.IosDeviceFile);
}

core.List<api.IosDeviceFile> buildUnnamed197() {
  var o = <api.IosDeviceFile>[];
  o.add(buildIosDeviceFile());
  o.add(buildIosDeviceFile());
  return o;
}

void checkUnnamed197(core.List<api.IosDeviceFile> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIosDeviceFile(o[0] as api.IosDeviceFile);
  checkIosDeviceFile(o[1] as api.IosDeviceFile);
}

core.int buildCounterIosTestSetup = 0;
api.IosTestSetup buildIosTestSetup() {
  var o = api.IosTestSetup();
  buildCounterIosTestSetup++;
  if (buildCounterIosTestSetup < 3) {
    o.additionalIpas = buildUnnamed195();
    o.networkProfile = 'foo';
    o.pullDirectories = buildUnnamed196();
    o.pushFiles = buildUnnamed197();
  }
  buildCounterIosTestSetup--;
  return o;
}

void checkIosTestSetup(api.IosTestSetup o) {
  buildCounterIosTestSetup++;
  if (buildCounterIosTestSetup < 3) {
    checkUnnamed195(o.additionalIpas!);
    unittest.expect(
      o.networkProfile!,
      unittest.equals('foo'),
    );
    checkUnnamed196(o.pullDirectories!);
    checkUnnamed197(o.pushFiles!);
  }
  buildCounterIosTestSetup--;
}

core.List<core.String> buildUnnamed198() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed198(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed199() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed199(core.List<core.String> o) {
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

core.int buildCounterIosVersion = 0;
api.IosVersion buildIosVersion() {
  var o = api.IosVersion();
  buildCounterIosVersion++;
  if (buildCounterIosVersion < 3) {
    o.id = 'foo';
    o.majorVersion = 42;
    o.minorVersion = 42;
    o.supportedXcodeVersionIds = buildUnnamed198();
    o.tags = buildUnnamed199();
  }
  buildCounterIosVersion--;
  return o;
}

void checkIosVersion(api.IosVersion o) {
  buildCounterIosVersion++;
  if (buildCounterIosVersion < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.majorVersion!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minorVersion!,
      unittest.equals(42),
    );
    checkUnnamed198(o.supportedXcodeVersionIds!);
    checkUnnamed199(o.tags!);
  }
  buildCounterIosVersion--;
}

core.int buildCounterIosXcTest = 0;
api.IosXcTest buildIosXcTest() {
  var o = api.IosXcTest();
  buildCounterIosXcTest++;
  if (buildCounterIosXcTest < 3) {
    o.appBundleId = 'foo';
    o.testSpecialEntitlements = true;
    o.testsZip = buildFileReference();
    o.xcodeVersion = 'foo';
    o.xctestrun = buildFileReference();
  }
  buildCounterIosXcTest--;
  return o;
}

void checkIosXcTest(api.IosXcTest o) {
  buildCounterIosXcTest++;
  if (buildCounterIosXcTest < 3) {
    unittest.expect(
      o.appBundleId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.testSpecialEntitlements!, unittest.isTrue);
    checkFileReference(o.testsZip! as api.FileReference);
    unittest.expect(
      o.xcodeVersion!,
      unittest.equals('foo'),
    );
    checkFileReference(o.xctestrun! as api.FileReference);
  }
  buildCounterIosXcTest--;
}

core.int buildCounterLauncherActivityIntent = 0;
api.LauncherActivityIntent buildLauncherActivityIntent() {
  var o = api.LauncherActivityIntent();
  buildCounterLauncherActivityIntent++;
  if (buildCounterLauncherActivityIntent < 3) {}
  buildCounterLauncherActivityIntent--;
  return o;
}

void checkLauncherActivityIntent(api.LauncherActivityIntent o) {
  buildCounterLauncherActivityIntent++;
  if (buildCounterLauncherActivityIntent < 3) {}
  buildCounterLauncherActivityIntent--;
}

core.List<core.String> buildUnnamed200() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed200(core.List<core.String> o) {
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

core.int buildCounterLocale = 0;
api.Locale buildLocale() {
  var o = api.Locale();
  buildCounterLocale++;
  if (buildCounterLocale < 3) {
    o.id = 'foo';
    o.name = 'foo';
    o.region = 'foo';
    o.tags = buildUnnamed200();
  }
  buildCounterLocale--;
  return o;
}

void checkLocale(api.Locale o) {
  buildCounterLocale++;
  if (buildCounterLocale < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    checkUnnamed200(o.tags!);
  }
  buildCounterLocale--;
}

core.List<api.TestTargetsForShard> buildUnnamed201() {
  var o = <api.TestTargetsForShard>[];
  o.add(buildTestTargetsForShard());
  o.add(buildTestTargetsForShard());
  return o;
}

void checkUnnamed201(core.List<api.TestTargetsForShard> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTestTargetsForShard(o[0] as api.TestTargetsForShard);
  checkTestTargetsForShard(o[1] as api.TestTargetsForShard);
}

core.int buildCounterManualSharding = 0;
api.ManualSharding buildManualSharding() {
  var o = api.ManualSharding();
  buildCounterManualSharding++;
  if (buildCounterManualSharding < 3) {
    o.testTargetsForShard = buildUnnamed201();
  }
  buildCounterManualSharding--;
  return o;
}

void checkManualSharding(api.ManualSharding o) {
  buildCounterManualSharding++;
  if (buildCounterManualSharding < 3) {
    checkUnnamed201(o.testTargetsForShard!);
  }
  buildCounterManualSharding--;
}

core.int buildCounterNetworkConfiguration = 0;
api.NetworkConfiguration buildNetworkConfiguration() {
  var o = api.NetworkConfiguration();
  buildCounterNetworkConfiguration++;
  if (buildCounterNetworkConfiguration < 3) {
    o.downRule = buildTrafficRule();
    o.id = 'foo';
    o.upRule = buildTrafficRule();
  }
  buildCounterNetworkConfiguration--;
  return o;
}

void checkNetworkConfiguration(api.NetworkConfiguration o) {
  buildCounterNetworkConfiguration++;
  if (buildCounterNetworkConfiguration < 3) {
    checkTrafficRule(o.downRule! as api.TrafficRule);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkTrafficRule(o.upRule! as api.TrafficRule);
  }
  buildCounterNetworkConfiguration--;
}

core.List<api.NetworkConfiguration> buildUnnamed202() {
  var o = <api.NetworkConfiguration>[];
  o.add(buildNetworkConfiguration());
  o.add(buildNetworkConfiguration());
  return o;
}

void checkUnnamed202(core.List<api.NetworkConfiguration> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNetworkConfiguration(o[0] as api.NetworkConfiguration);
  checkNetworkConfiguration(o[1] as api.NetworkConfiguration);
}

core.int buildCounterNetworkConfigurationCatalog = 0;
api.NetworkConfigurationCatalog buildNetworkConfigurationCatalog() {
  var o = api.NetworkConfigurationCatalog();
  buildCounterNetworkConfigurationCatalog++;
  if (buildCounterNetworkConfigurationCatalog < 3) {
    o.configurations = buildUnnamed202();
  }
  buildCounterNetworkConfigurationCatalog--;
  return o;
}

void checkNetworkConfigurationCatalog(api.NetworkConfigurationCatalog o) {
  buildCounterNetworkConfigurationCatalog++;
  if (buildCounterNetworkConfigurationCatalog < 3) {
    checkUnnamed202(o.configurations!);
  }
  buildCounterNetworkConfigurationCatalog--;
}

core.int buildCounterObbFile = 0;
api.ObbFile buildObbFile() {
  var o = api.ObbFile();
  buildCounterObbFile++;
  if (buildCounterObbFile < 3) {
    o.obb = buildFileReference();
    o.obbFileName = 'foo';
  }
  buildCounterObbFile--;
  return o;
}

void checkObbFile(api.ObbFile o) {
  buildCounterObbFile++;
  if (buildCounterObbFile < 3) {
    checkFileReference(o.obb! as api.FileReference);
    unittest.expect(
      o.obbFileName!,
      unittest.equals('foo'),
    );
  }
  buildCounterObbFile--;
}

core.List<core.String> buildUnnamed203() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed203(core.List<core.String> o) {
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

core.int buildCounterOrientation = 0;
api.Orientation buildOrientation() {
  var o = api.Orientation();
  buildCounterOrientation++;
  if (buildCounterOrientation < 3) {
    o.id = 'foo';
    o.name = 'foo';
    o.tags = buildUnnamed203();
  }
  buildCounterOrientation--;
  return o;
}

void checkOrientation(api.Orientation o) {
  buildCounterOrientation++;
  if (buildCounterOrientation < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed203(o.tags!);
  }
  buildCounterOrientation--;
}

core.int buildCounterProvidedSoftwareCatalog = 0;
api.ProvidedSoftwareCatalog buildProvidedSoftwareCatalog() {
  var o = api.ProvidedSoftwareCatalog();
  buildCounterProvidedSoftwareCatalog++;
  if (buildCounterProvidedSoftwareCatalog < 3) {
    o.androidxOrchestratorVersion = 'foo';
    o.orchestratorVersion = 'foo';
  }
  buildCounterProvidedSoftwareCatalog--;
  return o;
}

void checkProvidedSoftwareCatalog(api.ProvidedSoftwareCatalog o) {
  buildCounterProvidedSoftwareCatalog++;
  if (buildCounterProvidedSoftwareCatalog < 3) {
    unittest.expect(
      o.androidxOrchestratorVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orchestratorVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterProvidedSoftwareCatalog--;
}

core.int buildCounterRegularFile = 0;
api.RegularFile buildRegularFile() {
  var o = api.RegularFile();
  buildCounterRegularFile++;
  if (buildCounterRegularFile < 3) {
    o.content = buildFileReference();
    o.devicePath = 'foo';
  }
  buildCounterRegularFile--;
  return o;
}

void checkRegularFile(api.RegularFile o) {
  buildCounterRegularFile++;
  if (buildCounterRegularFile < 3) {
    checkFileReference(o.content! as api.FileReference);
    unittest.expect(
      o.devicePath!,
      unittest.equals('foo'),
    );
  }
  buildCounterRegularFile--;
}

core.int buildCounterResultStorage = 0;
api.ResultStorage buildResultStorage() {
  var o = api.ResultStorage();
  buildCounterResultStorage++;
  if (buildCounterResultStorage < 3) {
    o.googleCloudStorage = buildGoogleCloudStorage();
    o.resultsUrl = 'foo';
    o.toolResultsExecution = buildToolResultsExecution();
    o.toolResultsHistory = buildToolResultsHistory();
  }
  buildCounterResultStorage--;
  return o;
}

void checkResultStorage(api.ResultStorage o) {
  buildCounterResultStorage++;
  if (buildCounterResultStorage < 3) {
    checkGoogleCloudStorage(o.googleCloudStorage! as api.GoogleCloudStorage);
    unittest.expect(
      o.resultsUrl!,
      unittest.equals('foo'),
    );
    checkToolResultsExecution(
        o.toolResultsExecution! as api.ToolResultsExecution);
    checkToolResultsHistory(o.toolResultsHistory! as api.ToolResultsHistory);
  }
  buildCounterResultStorage--;
}

core.int buildCounterRoboDirective = 0;
api.RoboDirective buildRoboDirective() {
  var o = api.RoboDirective();
  buildCounterRoboDirective++;
  if (buildCounterRoboDirective < 3) {
    o.actionType = 'foo';
    o.inputText = 'foo';
    o.resourceName = 'foo';
  }
  buildCounterRoboDirective--;
  return o;
}

void checkRoboDirective(api.RoboDirective o) {
  buildCounterRoboDirective++;
  if (buildCounterRoboDirective < 3) {
    unittest.expect(
      o.actionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoboDirective--;
}

core.int buildCounterRoboStartingIntent = 0;
api.RoboStartingIntent buildRoboStartingIntent() {
  var o = api.RoboStartingIntent();
  buildCounterRoboStartingIntent++;
  if (buildCounterRoboStartingIntent < 3) {
    o.launcherActivity = buildLauncherActivityIntent();
    o.startActivity = buildStartActivityIntent();
    o.timeout = 'foo';
  }
  buildCounterRoboStartingIntent--;
  return o;
}

void checkRoboStartingIntent(api.RoboStartingIntent o) {
  buildCounterRoboStartingIntent++;
  if (buildCounterRoboStartingIntent < 3) {
    checkLauncherActivityIntent(
        o.launcherActivity! as api.LauncherActivityIntent);
    checkStartActivityIntent(o.startActivity! as api.StartActivityIntent);
    unittest.expect(
      o.timeout!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoboStartingIntent--;
}

core.int buildCounterShard = 0;
api.Shard buildShard() {
  var o = api.Shard();
  buildCounterShard++;
  if (buildCounterShard < 3) {
    o.numShards = 42;
    o.shardIndex = 42;
    o.testTargetsForShard = buildTestTargetsForShard();
  }
  buildCounterShard--;
  return o;
}

void checkShard(api.Shard o) {
  buildCounterShard++;
  if (buildCounterShard < 3) {
    unittest.expect(
      o.numShards!,
      unittest.equals(42),
    );
    unittest.expect(
      o.shardIndex!,
      unittest.equals(42),
    );
    checkTestTargetsForShard(o.testTargetsForShard! as api.TestTargetsForShard);
  }
  buildCounterShard--;
}

core.int buildCounterShardingOption = 0;
api.ShardingOption buildShardingOption() {
  var o = api.ShardingOption();
  buildCounterShardingOption++;
  if (buildCounterShardingOption < 3) {
    o.manualSharding = buildManualSharding();
    o.uniformSharding = buildUniformSharding();
  }
  buildCounterShardingOption--;
  return o;
}

void checkShardingOption(api.ShardingOption o) {
  buildCounterShardingOption++;
  if (buildCounterShardingOption < 3) {
    checkManualSharding(o.manualSharding! as api.ManualSharding);
    checkUniformSharding(o.uniformSharding! as api.UniformSharding);
  }
  buildCounterShardingOption--;
}

core.List<core.String> buildUnnamed204() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed204(core.List<core.String> o) {
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

core.int buildCounterStartActivityIntent = 0;
api.StartActivityIntent buildStartActivityIntent() {
  var o = api.StartActivityIntent();
  buildCounterStartActivityIntent++;
  if (buildCounterStartActivityIntent < 3) {
    o.action = 'foo';
    o.categories = buildUnnamed204();
    o.uri = 'foo';
  }
  buildCounterStartActivityIntent--;
  return o;
}

void checkStartActivityIntent(api.StartActivityIntent o) {
  buildCounterStartActivityIntent++;
  if (buildCounterStartActivityIntent < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    checkUnnamed204(o.categories!);
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterStartActivityIntent--;
}

core.int buildCounterSystraceSetup = 0;
api.SystraceSetup buildSystraceSetup() {
  var o = api.SystraceSetup();
  buildCounterSystraceSetup++;
  if (buildCounterSystraceSetup < 3) {
    o.durationSeconds = 42;
  }
  buildCounterSystraceSetup--;
  return o;
}

void checkSystraceSetup(api.SystraceSetup o) {
  buildCounterSystraceSetup++;
  if (buildCounterSystraceSetup < 3) {
    unittest.expect(
      o.durationSeconds!,
      unittest.equals(42),
    );
  }
  buildCounterSystraceSetup--;
}

core.List<core.String> buildUnnamed205() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed205(core.List<core.String> o) {
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

core.int buildCounterTestDetails = 0;
api.TestDetails buildTestDetails() {
  var o = api.TestDetails();
  buildCounterTestDetails++;
  if (buildCounterTestDetails < 3) {
    o.errorMessage = 'foo';
    o.progressMessages = buildUnnamed205();
  }
  buildCounterTestDetails--;
  return o;
}

void checkTestDetails(api.TestDetails o) {
  buildCounterTestDetails++;
  if (buildCounterTestDetails < 3) {
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    checkUnnamed205(o.progressMessages!);
  }
  buildCounterTestDetails--;
}

core.int buildCounterTestEnvironmentCatalog = 0;
api.TestEnvironmentCatalog buildTestEnvironmentCatalog() {
  var o = api.TestEnvironmentCatalog();
  buildCounterTestEnvironmentCatalog++;
  if (buildCounterTestEnvironmentCatalog < 3) {
    o.androidDeviceCatalog = buildAndroidDeviceCatalog();
    o.deviceIpBlockCatalog = buildDeviceIpBlockCatalog();
    o.iosDeviceCatalog = buildIosDeviceCatalog();
    o.networkConfigurationCatalog = buildNetworkConfigurationCatalog();
    o.softwareCatalog = buildProvidedSoftwareCatalog();
  }
  buildCounterTestEnvironmentCatalog--;
  return o;
}

void checkTestEnvironmentCatalog(api.TestEnvironmentCatalog o) {
  buildCounterTestEnvironmentCatalog++;
  if (buildCounterTestEnvironmentCatalog < 3) {
    checkAndroidDeviceCatalog(
        o.androidDeviceCatalog! as api.AndroidDeviceCatalog);
    checkDeviceIpBlockCatalog(
        o.deviceIpBlockCatalog! as api.DeviceIpBlockCatalog);
    checkIosDeviceCatalog(o.iosDeviceCatalog! as api.IosDeviceCatalog);
    checkNetworkConfigurationCatalog(
        o.networkConfigurationCatalog! as api.NetworkConfigurationCatalog);
    checkProvidedSoftwareCatalog(
        o.softwareCatalog! as api.ProvidedSoftwareCatalog);
  }
  buildCounterTestEnvironmentCatalog--;
}

core.int buildCounterTestExecution = 0;
api.TestExecution buildTestExecution() {
  var o = api.TestExecution();
  buildCounterTestExecution++;
  if (buildCounterTestExecution < 3) {
    o.environment = buildEnvironment();
    o.id = 'foo';
    o.matrixId = 'foo';
    o.projectId = 'foo';
    o.shard = buildShard();
    o.state = 'foo';
    o.testDetails = buildTestDetails();
    o.testSpecification = buildTestSpecification();
    o.timestamp = 'foo';
    o.toolResultsStep = buildToolResultsStep();
  }
  buildCounterTestExecution--;
  return o;
}

void checkTestExecution(api.TestExecution o) {
  buildCounterTestExecution++;
  if (buildCounterTestExecution < 3) {
    checkEnvironment(o.environment! as api.Environment);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.matrixId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    checkShard(o.shard! as api.Shard);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkTestDetails(o.testDetails! as api.TestDetails);
    checkTestSpecification(o.testSpecification! as api.TestSpecification);
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
    checkToolResultsStep(o.toolResultsStep! as api.ToolResultsStep);
  }
  buildCounterTestExecution--;
}

core.List<api.TestExecution> buildUnnamed206() {
  var o = <api.TestExecution>[];
  o.add(buildTestExecution());
  o.add(buildTestExecution());
  return o;
}

void checkUnnamed206(core.List<api.TestExecution> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTestExecution(o[0] as api.TestExecution);
  checkTestExecution(o[1] as api.TestExecution);
}

core.int buildCounterTestMatrix = 0;
api.TestMatrix buildTestMatrix() {
  var o = api.TestMatrix();
  buildCounterTestMatrix++;
  if (buildCounterTestMatrix < 3) {
    o.clientInfo = buildClientInfo();
    o.environmentMatrix = buildEnvironmentMatrix();
    o.failFast = true;
    o.flakyTestAttempts = 42;
    o.invalidMatrixDetails = 'foo';
    o.outcomeSummary = 'foo';
    o.projectId = 'foo';
    o.resultStorage = buildResultStorage();
    o.state = 'foo';
    o.testExecutions = buildUnnamed206();
    o.testMatrixId = 'foo';
    o.testSpecification = buildTestSpecification();
    o.timestamp = 'foo';
  }
  buildCounterTestMatrix--;
  return o;
}

void checkTestMatrix(api.TestMatrix o) {
  buildCounterTestMatrix++;
  if (buildCounterTestMatrix < 3) {
    checkClientInfo(o.clientInfo! as api.ClientInfo);
    checkEnvironmentMatrix(o.environmentMatrix! as api.EnvironmentMatrix);
    unittest.expect(o.failFast!, unittest.isTrue);
    unittest.expect(
      o.flakyTestAttempts!,
      unittest.equals(42),
    );
    unittest.expect(
      o.invalidMatrixDetails!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outcomeSummary!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    checkResultStorage(o.resultStorage! as api.ResultStorage);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkUnnamed206(o.testExecutions!);
    unittest.expect(
      o.testMatrixId!,
      unittest.equals('foo'),
    );
    checkTestSpecification(o.testSpecification! as api.TestSpecification);
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterTestMatrix--;
}

core.List<api.Apk> buildUnnamed207() {
  var o = <api.Apk>[];
  o.add(buildApk());
  o.add(buildApk());
  return o;
}

void checkUnnamed207(core.List<api.Apk> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApk(o[0] as api.Apk);
  checkApk(o[1] as api.Apk);
}

core.List<core.String> buildUnnamed208() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed208(core.List<core.String> o) {
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

core.List<api.EnvironmentVariable> buildUnnamed209() {
  var o = <api.EnvironmentVariable>[];
  o.add(buildEnvironmentVariable());
  o.add(buildEnvironmentVariable());
  return o;
}

void checkUnnamed209(core.List<api.EnvironmentVariable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEnvironmentVariable(o[0] as api.EnvironmentVariable);
  checkEnvironmentVariable(o[1] as api.EnvironmentVariable);
}

core.List<api.DeviceFile> buildUnnamed210() {
  var o = <api.DeviceFile>[];
  o.add(buildDeviceFile());
  o.add(buildDeviceFile());
  return o;
}

void checkUnnamed210(core.List<api.DeviceFile> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeviceFile(o[0] as api.DeviceFile);
  checkDeviceFile(o[1] as api.DeviceFile);
}

core.int buildCounterTestSetup = 0;
api.TestSetup buildTestSetup() {
  var o = api.TestSetup();
  buildCounterTestSetup++;
  if (buildCounterTestSetup < 3) {
    o.account = buildAccount();
    o.additionalApks = buildUnnamed207();
    o.directoriesToPull = buildUnnamed208();
    o.dontAutograntPermissions = true;
    o.environmentVariables = buildUnnamed209();
    o.filesToPush = buildUnnamed210();
    o.networkProfile = 'foo';
    o.systrace = buildSystraceSetup();
  }
  buildCounterTestSetup--;
  return o;
}

void checkTestSetup(api.TestSetup o) {
  buildCounterTestSetup++;
  if (buildCounterTestSetup < 3) {
    checkAccount(o.account! as api.Account);
    checkUnnamed207(o.additionalApks!);
    checkUnnamed208(o.directoriesToPull!);
    unittest.expect(o.dontAutograntPermissions!, unittest.isTrue);
    checkUnnamed209(o.environmentVariables!);
    checkUnnamed210(o.filesToPush!);
    unittest.expect(
      o.networkProfile!,
      unittest.equals('foo'),
    );
    checkSystraceSetup(o.systrace! as api.SystraceSetup);
  }
  buildCounterTestSetup--;
}

core.int buildCounterTestSpecification = 0;
api.TestSpecification buildTestSpecification() {
  var o = api.TestSpecification();
  buildCounterTestSpecification++;
  if (buildCounterTestSpecification < 3) {
    o.androidInstrumentationTest = buildAndroidInstrumentationTest();
    o.androidRoboTest = buildAndroidRoboTest();
    o.androidTestLoop = buildAndroidTestLoop();
    o.disablePerformanceMetrics = true;
    o.disableVideoRecording = true;
    o.iosTestLoop = buildIosTestLoop();
    o.iosTestSetup = buildIosTestSetup();
    o.iosXcTest = buildIosXcTest();
    o.testSetup = buildTestSetup();
    o.testTimeout = 'foo';
  }
  buildCounterTestSpecification--;
  return o;
}

void checkTestSpecification(api.TestSpecification o) {
  buildCounterTestSpecification++;
  if (buildCounterTestSpecification < 3) {
    checkAndroidInstrumentationTest(
        o.androidInstrumentationTest! as api.AndroidInstrumentationTest);
    checkAndroidRoboTest(o.androidRoboTest! as api.AndroidRoboTest);
    checkAndroidTestLoop(o.androidTestLoop! as api.AndroidTestLoop);
    unittest.expect(o.disablePerformanceMetrics!, unittest.isTrue);
    unittest.expect(o.disableVideoRecording!, unittest.isTrue);
    checkIosTestLoop(o.iosTestLoop! as api.IosTestLoop);
    checkIosTestSetup(o.iosTestSetup! as api.IosTestSetup);
    checkIosXcTest(o.iosXcTest! as api.IosXcTest);
    checkTestSetup(o.testSetup! as api.TestSetup);
    unittest.expect(
      o.testTimeout!,
      unittest.equals('foo'),
    );
  }
  buildCounterTestSpecification--;
}

core.List<core.String> buildUnnamed211() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed211(core.List<core.String> o) {
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

core.int buildCounterTestTargetsForShard = 0;
api.TestTargetsForShard buildTestTargetsForShard() {
  var o = api.TestTargetsForShard();
  buildCounterTestTargetsForShard++;
  if (buildCounterTestTargetsForShard < 3) {
    o.testTargets = buildUnnamed211();
  }
  buildCounterTestTargetsForShard--;
  return o;
}

void checkTestTargetsForShard(api.TestTargetsForShard o) {
  buildCounterTestTargetsForShard++;
  if (buildCounterTestTargetsForShard < 3) {
    checkUnnamed211(o.testTargets!);
  }
  buildCounterTestTargetsForShard--;
}

core.int buildCounterToolResultsExecution = 0;
api.ToolResultsExecution buildToolResultsExecution() {
  var o = api.ToolResultsExecution();
  buildCounterToolResultsExecution++;
  if (buildCounterToolResultsExecution < 3) {
    o.executionId = 'foo';
    o.historyId = 'foo';
    o.projectId = 'foo';
  }
  buildCounterToolResultsExecution--;
  return o;
}

void checkToolResultsExecution(api.ToolResultsExecution o) {
  buildCounterToolResultsExecution++;
  if (buildCounterToolResultsExecution < 3) {
    unittest.expect(
      o.executionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterToolResultsExecution--;
}

core.int buildCounterToolResultsHistory = 0;
api.ToolResultsHistory buildToolResultsHistory() {
  var o = api.ToolResultsHistory();
  buildCounterToolResultsHistory++;
  if (buildCounterToolResultsHistory < 3) {
    o.historyId = 'foo';
    o.projectId = 'foo';
  }
  buildCounterToolResultsHistory--;
  return o;
}

void checkToolResultsHistory(api.ToolResultsHistory o) {
  buildCounterToolResultsHistory++;
  if (buildCounterToolResultsHistory < 3) {
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterToolResultsHistory--;
}

core.int buildCounterToolResultsStep = 0;
api.ToolResultsStep buildToolResultsStep() {
  var o = api.ToolResultsStep();
  buildCounterToolResultsStep++;
  if (buildCounterToolResultsStep < 3) {
    o.executionId = 'foo';
    o.historyId = 'foo';
    o.projectId = 'foo';
    o.stepId = 'foo';
  }
  buildCounterToolResultsStep--;
  return o;
}

void checkToolResultsStep(api.ToolResultsStep o) {
  buildCounterToolResultsStep++;
  if (buildCounterToolResultsStep < 3) {
    unittest.expect(
      o.executionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stepId!,
      unittest.equals('foo'),
    );
  }
  buildCounterToolResultsStep--;
}

core.int buildCounterTrafficRule = 0;
api.TrafficRule buildTrafficRule() {
  var o = api.TrafficRule();
  buildCounterTrafficRule++;
  if (buildCounterTrafficRule < 3) {
    o.bandwidth = 42.0;
    o.burst = 42.0;
    o.delay = 'foo';
    o.packetDuplicationRatio = 42.0;
    o.packetLossRatio = 42.0;
  }
  buildCounterTrafficRule--;
  return o;
}

void checkTrafficRule(api.TrafficRule o) {
  buildCounterTrafficRule++;
  if (buildCounterTrafficRule < 3) {
    unittest.expect(
      o.bandwidth!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.burst!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.delay!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packetDuplicationRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.packetLossRatio!,
      unittest.equals(42.0),
    );
  }
  buildCounterTrafficRule--;
}

core.int buildCounterUniformSharding = 0;
api.UniformSharding buildUniformSharding() {
  var o = api.UniformSharding();
  buildCounterUniformSharding++;
  if (buildCounterUniformSharding < 3) {
    o.numShards = 42;
  }
  buildCounterUniformSharding--;
  return o;
}

void checkUniformSharding(api.UniformSharding o) {
  buildCounterUniformSharding++;
  if (buildCounterUniformSharding < 3) {
    unittest.expect(
      o.numShards!,
      unittest.equals(42),
    );
  }
  buildCounterUniformSharding--;
}

core.List<core.String> buildUnnamed212() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed212(core.List<core.String> o) {
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

core.int buildCounterXcodeVersion = 0;
api.XcodeVersion buildXcodeVersion() {
  var o = api.XcodeVersion();
  buildCounterXcodeVersion++;
  if (buildCounterXcodeVersion < 3) {
    o.tags = buildUnnamed212();
    o.version = 'foo';
  }
  buildCounterXcodeVersion--;
  return o;
}

void checkXcodeVersion(api.XcodeVersion o) {
  buildCounterXcodeVersion++;
  if (buildCounterXcodeVersion < 3) {
    checkUnnamed212(o.tags!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterXcodeVersion--;
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

  unittest.group('obj-schema-AndroidDevice', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidDevice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidDevice.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidDevice(od as api.AndroidDevice);
    });
  });

  unittest.group('obj-schema-AndroidDeviceCatalog', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidDeviceCatalog();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidDeviceCatalog.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidDeviceCatalog(od as api.AndroidDeviceCatalog);
    });
  });

  unittest.group('obj-schema-AndroidDeviceList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidDeviceList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidDeviceList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidDeviceList(od as api.AndroidDeviceList);
    });
  });

  unittest.group('obj-schema-AndroidInstrumentationTest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidInstrumentationTest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidInstrumentationTest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidInstrumentationTest(od as api.AndroidInstrumentationTest);
    });
  });

  unittest.group('obj-schema-AndroidMatrix', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidMatrix();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidMatrix.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidMatrix(od as api.AndroidMatrix);
    });
  });

  unittest.group('obj-schema-AndroidModel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidModel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidModel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidModel(od as api.AndroidModel);
    });
  });

  unittest.group('obj-schema-AndroidRoboTest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidRoboTest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidRoboTest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidRoboTest(od as api.AndroidRoboTest);
    });
  });

  unittest.group('obj-schema-AndroidRuntimeConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidRuntimeConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidRuntimeConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidRuntimeConfiguration(od as api.AndroidRuntimeConfiguration);
    });
  });

  unittest.group('obj-schema-AndroidTestLoop', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidTestLoop();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidTestLoop.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidTestLoop(od as api.AndroidTestLoop);
    });
  });

  unittest.group('obj-schema-AndroidVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAndroidVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AndroidVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAndroidVersion(od as api.AndroidVersion);
    });
  });

  unittest.group('obj-schema-Apk', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApk();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Apk.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkApk(od as api.Apk);
    });
  });

  unittest.group('obj-schema-ApkDetail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApkDetail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ApkDetail.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkApkDetail(od as api.ApkDetail);
    });
  });

  unittest.group('obj-schema-ApkManifest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApkManifest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApkManifest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApkManifest(od as api.ApkManifest);
    });
  });

  unittest.group('obj-schema-AppBundle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppBundle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AppBundle.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAppBundle(od as api.AppBundle);
    });
  });

  unittest.group('obj-schema-CancelTestMatrixResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelTestMatrixResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelTestMatrixResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelTestMatrixResponse(od as api.CancelTestMatrixResponse);
    });
  });

  unittest.group('obj-schema-ClientInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClientInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ClientInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkClientInfo(od as api.ClientInfo);
    });
  });

  unittest.group('obj-schema-ClientInfoDetail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClientInfoDetail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClientInfoDetail.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClientInfoDetail(od as api.ClientInfoDetail);
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

  unittest.group('obj-schema-DeviceFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DeviceFile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDeviceFile(od as api.DeviceFile);
    });
  });

  unittest.group('obj-schema-DeviceIpBlock', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceIpBlock();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceIpBlock.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceIpBlock(od as api.DeviceIpBlock);
    });
  });

  unittest.group('obj-schema-DeviceIpBlockCatalog', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceIpBlockCatalog();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceIpBlockCatalog.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceIpBlockCatalog(od as api.DeviceIpBlockCatalog);
    });
  });

  unittest.group('obj-schema-Distribution', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDistribution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Distribution.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDistribution(od as api.Distribution);
    });
  });

  unittest.group('obj-schema-Environment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnvironment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Environment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnvironment(od as api.Environment);
    });
  });

  unittest.group('obj-schema-EnvironmentMatrix', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnvironmentMatrix();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnvironmentMatrix.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnvironmentMatrix(od as api.EnvironmentMatrix);
    });
  });

  unittest.group('obj-schema-EnvironmentVariable', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnvironmentVariable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnvironmentVariable.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnvironmentVariable(od as api.EnvironmentVariable);
    });
  });

  unittest.group('obj-schema-FileReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFileReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FileReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFileReference(od as api.FileReference);
    });
  });

  unittest.group('obj-schema-GetApkDetailsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetApkDetailsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetApkDetailsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetApkDetailsResponse(od as api.GetApkDetailsResponse);
    });
  });

  unittest.group('obj-schema-GoogleAuto', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAuto();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleAuto.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAuto(od as api.GoogleAuto);
    });
  });

  unittest.group('obj-schema-GoogleCloudStorage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudStorage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudStorage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudStorage(od as api.GoogleCloudStorage);
    });
  });

  unittest.group('obj-schema-IntentFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIntentFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IntentFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIntentFilter(od as api.IntentFilter);
    });
  });

  unittest.group('obj-schema-IosDevice', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosDevice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IosDevice.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIosDevice(od as api.IosDevice);
    });
  });

  unittest.group('obj-schema-IosDeviceCatalog', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosDeviceCatalog();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IosDeviceCatalog.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIosDeviceCatalog(od as api.IosDeviceCatalog);
    });
  });

  unittest.group('obj-schema-IosDeviceFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosDeviceFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IosDeviceFile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIosDeviceFile(od as api.IosDeviceFile);
    });
  });

  unittest.group('obj-schema-IosDeviceList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosDeviceList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IosDeviceList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIosDeviceList(od as api.IosDeviceList);
    });
  });

  unittest.group('obj-schema-IosModel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosModel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IosModel.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIosModel(od as api.IosModel);
    });
  });

  unittest.group('obj-schema-IosRuntimeConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosRuntimeConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IosRuntimeConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIosRuntimeConfiguration(od as api.IosRuntimeConfiguration);
    });
  });

  unittest.group('obj-schema-IosTestLoop', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosTestLoop();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IosTestLoop.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIosTestLoop(od as api.IosTestLoop);
    });
  });

  unittest.group('obj-schema-IosTestSetup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosTestSetup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IosTestSetup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIosTestSetup(od as api.IosTestSetup);
    });
  });

  unittest.group('obj-schema-IosVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IosVersion.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIosVersion(od as api.IosVersion);
    });
  });

  unittest.group('obj-schema-IosXcTest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIosXcTest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IosXcTest.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIosXcTest(od as api.IosXcTest);
    });
  });

  unittest.group('obj-schema-LauncherActivityIntent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLauncherActivityIntent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LauncherActivityIntent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLauncherActivityIntent(od as api.LauncherActivityIntent);
    });
  });

  unittest.group('obj-schema-Locale', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocale();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Locale.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocale(od as api.Locale);
    });
  });

  unittest.group('obj-schema-ManualSharding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManualSharding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManualSharding.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManualSharding(od as api.ManualSharding);
    });
  });

  unittest.group('obj-schema-NetworkConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkConfiguration(od as api.NetworkConfiguration);
    });
  });

  unittest.group('obj-schema-NetworkConfigurationCatalog', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkConfigurationCatalog();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkConfigurationCatalog.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkConfigurationCatalog(od as api.NetworkConfigurationCatalog);
    });
  });

  unittest.group('obj-schema-ObbFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildObbFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ObbFile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkObbFile(od as api.ObbFile);
    });
  });

  unittest.group('obj-schema-Orientation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrientation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Orientation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrientation(od as api.Orientation);
    });
  });

  unittest.group('obj-schema-ProvidedSoftwareCatalog', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProvidedSoftwareCatalog();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProvidedSoftwareCatalog.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProvidedSoftwareCatalog(od as api.ProvidedSoftwareCatalog);
    });
  });

  unittest.group('obj-schema-RegularFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegularFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RegularFile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegularFile(od as api.RegularFile);
    });
  });

  unittest.group('obj-schema-ResultStorage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultStorage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultStorage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultStorage(od as api.ResultStorage);
    });
  });

  unittest.group('obj-schema-RoboDirective', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoboDirective();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RoboDirective.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRoboDirective(od as api.RoboDirective);
    });
  });

  unittest.group('obj-schema-RoboStartingIntent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoboStartingIntent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RoboStartingIntent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRoboStartingIntent(od as api.RoboStartingIntent);
    });
  });

  unittest.group('obj-schema-Shard', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShard();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Shard.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkShard(od as api.Shard);
    });
  });

  unittest.group('obj-schema-ShardingOption', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShardingOption();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ShardingOption.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkShardingOption(od as api.ShardingOption);
    });
  });

  unittest.group('obj-schema-StartActivityIntent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStartActivityIntent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StartActivityIntent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStartActivityIntent(od as api.StartActivityIntent);
    });
  });

  unittest.group('obj-schema-SystraceSetup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSystraceSetup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SystraceSetup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSystraceSetup(od as api.SystraceSetup);
    });
  });

  unittest.group('obj-schema-TestDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestDetails(od as api.TestDetails);
    });
  });

  unittest.group('obj-schema-TestEnvironmentCatalog', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestEnvironmentCatalog();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestEnvironmentCatalog.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestEnvironmentCatalog(od as api.TestEnvironmentCatalog);
    });
  });

  unittest.group('obj-schema-TestExecution', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestExecution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestExecution.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestExecution(od as api.TestExecution);
    });
  });

  unittest.group('obj-schema-TestMatrix', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestMatrix();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TestMatrix.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTestMatrix(od as api.TestMatrix);
    });
  });

  unittest.group('obj-schema-TestSetup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestSetup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TestSetup.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTestSetup(od as api.TestSetup);
    });
  });

  unittest.group('obj-schema-TestSpecification', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestSpecification();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestSpecification.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestSpecification(od as api.TestSpecification);
    });
  });

  unittest.group('obj-schema-TestTargetsForShard', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestTargetsForShard();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestTargetsForShard.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestTargetsForShard(od as api.TestTargetsForShard);
    });
  });

  unittest.group('obj-schema-ToolResultsExecution', () {
    unittest.test('to-json--from-json', () async {
      var o = buildToolResultsExecution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ToolResultsExecution.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkToolResultsExecution(od as api.ToolResultsExecution);
    });
  });

  unittest.group('obj-schema-ToolResultsHistory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildToolResultsHistory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ToolResultsHistory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkToolResultsHistory(od as api.ToolResultsHistory);
    });
  });

  unittest.group('obj-schema-ToolResultsStep', () {
    unittest.test('to-json--from-json', () async {
      var o = buildToolResultsStep();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ToolResultsStep.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkToolResultsStep(od as api.ToolResultsStep);
    });
  });

  unittest.group('obj-schema-TrafficRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrafficRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrafficRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrafficRule(od as api.TrafficRule);
    });
  });

  unittest.group('obj-schema-UniformSharding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUniformSharding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UniformSharding.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUniformSharding(od as api.UniformSharding);
    });
  });

  unittest.group('obj-schema-XcodeVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildXcodeVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.XcodeVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkXcodeVersion(od as api.XcodeVersion);
    });
  });

  unittest.group('resource-ApplicationDetailServiceResource', () {
    unittest.test('method--getApkDetails', () async {
      var mock = HttpServerMock();
      var res = api.TestingApi(mock).applicationDetailService;
      var arg_request = buildFileReference();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FileReference.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFileReference(obj as api.FileReference);

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
          path.substring(pathOffset, pathOffset + 41),
          unittest.equals("v1/applicationDetailService/getApkDetails"),
        );
        pathOffset += 41;

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
        var resp = convert.json.encode(buildGetApkDetailsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getApkDetails(arg_request, $fields: arg_$fields);
      checkGetApkDetailsResponse(response as api.GetApkDetailsResponse);
    });
  });

  unittest.group('resource-ProjectsTestMatricesResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.TestingApi(mock).projects.testMatrices;
      var arg_projectId = 'foo';
      var arg_testMatrixId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/testMatrices/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/testMatrices/"),
        );
        pathOffset += 14;
        index = path.indexOf(':cancel', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_testMatrixId'),
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
        var resp = convert.json.encode(buildCancelTestMatrixResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.cancel(arg_projectId, arg_testMatrixId,
          $fields: arg_$fields);
      checkCancelTestMatrixResponse(response as api.CancelTestMatrixResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TestingApi(mock).projects.testMatrices;
      var arg_request = buildTestMatrix();
      var arg_projectId = 'foo';
      var arg_requestId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestMatrix.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestMatrix(obj as api.TestMatrix);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/testMatrices', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/testMatrices"),
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
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTestMatrix());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_projectId,
          requestId: arg_requestId, $fields: arg_$fields);
      checkTestMatrix(response as api.TestMatrix);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TestingApi(mock).projects.testMatrices;
      var arg_projectId = 'foo';
      var arg_testMatrixId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/testMatrices/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/testMatrices/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_testMatrixId'),
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
        var resp = convert.json.encode(buildTestMatrix());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_projectId, arg_testMatrixId, $fields: arg_$fields);
      checkTestMatrix(response as api.TestMatrix);
    });
  });

  unittest.group('resource-TestEnvironmentCatalogResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TestingApi(mock).testEnvironmentCatalog;
      var arg_environmentType = 'foo';
      var arg_projectId = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("v1/testEnvironmentCatalog/"),
        );
        pathOffset += 26;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_environmentType'),
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
          queryMap["projectId"]!.first,
          unittest.equals(arg_projectId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTestEnvironmentCatalog());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_environmentType,
          projectId: arg_projectId, $fields: arg_$fields);
      checkTestEnvironmentCatalog(response as api.TestEnvironmentCatalog);
    });
  });
}

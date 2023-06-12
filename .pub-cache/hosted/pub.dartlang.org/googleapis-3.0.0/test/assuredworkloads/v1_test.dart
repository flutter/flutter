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

import 'package:googleapis/assuredworkloads/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int
    buildCounterGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata =
    0;
api.GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata
    buildGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata() {
  var o = api.GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata();
  buildCounterGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata++;
  if (buildCounterGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata <
      3) {
    o.complianceRegime = 'foo';
    o.createTime = 'foo';
    o.displayName = 'foo';
    o.parent = 'foo';
  }
  buildCounterGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata(
    api.GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata o) {
  buildCounterGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata++;
  if (buildCounterGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata <
      3) {
    unittest.expect(
      o.complianceRegime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata--;
}

core.List<api.GoogleCloudAssuredworkloadsV1Workload> buildUnnamed626() {
  var o = <api.GoogleCloudAssuredworkloadsV1Workload>[];
  o.add(buildGoogleCloudAssuredworkloadsV1Workload());
  o.add(buildGoogleCloudAssuredworkloadsV1Workload());
  return o;
}

void checkUnnamed626(core.List<api.GoogleCloudAssuredworkloadsV1Workload> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssuredworkloadsV1Workload(
      o[0] as api.GoogleCloudAssuredworkloadsV1Workload);
  checkGoogleCloudAssuredworkloadsV1Workload(
      o[1] as api.GoogleCloudAssuredworkloadsV1Workload);
}

core.int buildCounterGoogleCloudAssuredworkloadsV1ListWorkloadsResponse = 0;
api.GoogleCloudAssuredworkloadsV1ListWorkloadsResponse
    buildGoogleCloudAssuredworkloadsV1ListWorkloadsResponse() {
  var o = api.GoogleCloudAssuredworkloadsV1ListWorkloadsResponse();
  buildCounterGoogleCloudAssuredworkloadsV1ListWorkloadsResponse++;
  if (buildCounterGoogleCloudAssuredworkloadsV1ListWorkloadsResponse < 3) {
    o.nextPageToken = 'foo';
    o.workloads = buildUnnamed626();
  }
  buildCounterGoogleCloudAssuredworkloadsV1ListWorkloadsResponse--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1ListWorkloadsResponse(
    api.GoogleCloudAssuredworkloadsV1ListWorkloadsResponse o) {
  buildCounterGoogleCloudAssuredworkloadsV1ListWorkloadsResponse++;
  if (buildCounterGoogleCloudAssuredworkloadsV1ListWorkloadsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed626(o.workloads!);
  }
  buildCounterGoogleCloudAssuredworkloadsV1ListWorkloadsResponse--;
}

core.Map<core.String, core.String> buildUnnamed627() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed627(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.List<api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings>
    buildUnnamed628() {
  var o = <api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings>[];
  o.add(buildGoogleCloudAssuredworkloadsV1WorkloadResourceSettings());
  o.add(buildGoogleCloudAssuredworkloadsV1WorkloadResourceSettings());
  return o;
}

void checkUnnamed628(
    core.List<api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssuredworkloadsV1WorkloadResourceSettings(
      o[0] as api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings);
  checkGoogleCloudAssuredworkloadsV1WorkloadResourceSettings(
      o[1] as api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings);
}

core.List<api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo>
    buildUnnamed629() {
  var o = <api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo>[];
  o.add(buildGoogleCloudAssuredworkloadsV1WorkloadResourceInfo());
  o.add(buildGoogleCloudAssuredworkloadsV1WorkloadResourceInfo());
  return o;
}

void checkUnnamed629(
    core.List<api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssuredworkloadsV1WorkloadResourceInfo(
      o[0] as api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo);
  checkGoogleCloudAssuredworkloadsV1WorkloadResourceInfo(
      o[1] as api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo);
}

core.int buildCounterGoogleCloudAssuredworkloadsV1Workload = 0;
api.GoogleCloudAssuredworkloadsV1Workload
    buildGoogleCloudAssuredworkloadsV1Workload() {
  var o = api.GoogleCloudAssuredworkloadsV1Workload();
  buildCounterGoogleCloudAssuredworkloadsV1Workload++;
  if (buildCounterGoogleCloudAssuredworkloadsV1Workload < 3) {
    o.billingAccount = 'foo';
    o.complianceRegime = 'foo';
    o.createTime = 'foo';
    o.displayName = 'foo';
    o.etag = 'foo';
    o.kmsSettings = buildGoogleCloudAssuredworkloadsV1WorkloadKMSSettings();
    o.labels = buildUnnamed627();
    o.name = 'foo';
    o.provisionedResourcesParent = 'foo';
    o.resourceSettings = buildUnnamed628();
    o.resources = buildUnnamed629();
  }
  buildCounterGoogleCloudAssuredworkloadsV1Workload--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1Workload(
    api.GoogleCloudAssuredworkloadsV1Workload o) {
  buildCounterGoogleCloudAssuredworkloadsV1Workload++;
  if (buildCounterGoogleCloudAssuredworkloadsV1Workload < 3) {
    unittest.expect(
      o.billingAccount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.complianceRegime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkGoogleCloudAssuredworkloadsV1WorkloadKMSSettings(
        o.kmsSettings! as api.GoogleCloudAssuredworkloadsV1WorkloadKMSSettings);
    checkUnnamed627(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.provisionedResourcesParent!,
      unittest.equals('foo'),
    );
    checkUnnamed628(o.resourceSettings!);
    checkUnnamed629(o.resources!);
  }
  buildCounterGoogleCloudAssuredworkloadsV1Workload--;
}

core.int buildCounterGoogleCloudAssuredworkloadsV1WorkloadKMSSettings = 0;
api.GoogleCloudAssuredworkloadsV1WorkloadKMSSettings
    buildGoogleCloudAssuredworkloadsV1WorkloadKMSSettings() {
  var o = api.GoogleCloudAssuredworkloadsV1WorkloadKMSSettings();
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadKMSSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1WorkloadKMSSettings < 3) {
    o.nextRotationTime = 'foo';
    o.rotationPeriod = 'foo';
  }
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadKMSSettings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1WorkloadKMSSettings(
    api.GoogleCloudAssuredworkloadsV1WorkloadKMSSettings o) {
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadKMSSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1WorkloadKMSSettings < 3) {
    unittest.expect(
      o.nextRotationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rotationPeriod!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadKMSSettings--;
}

core.int buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceInfo = 0;
api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo
    buildGoogleCloudAssuredworkloadsV1WorkloadResourceInfo() {
  var o = api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo();
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceInfo++;
  if (buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceInfo < 3) {
    o.resourceId = 'foo';
    o.resourceType = 'foo';
  }
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceInfo--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1WorkloadResourceInfo(
    api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo o) {
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceInfo++;
  if (buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceInfo < 3) {
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceInfo--;
}

core.int buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceSettings = 0;
api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings
    buildGoogleCloudAssuredworkloadsV1WorkloadResourceSettings() {
  var o = api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings();
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceSettings < 3) {
    o.displayName = 'foo';
    o.resourceId = 'foo';
    o.resourceType = 'foo';
  }
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceSettings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1WorkloadResourceSettings(
    api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings o) {
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceSettings < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssuredworkloadsV1WorkloadResourceSettings--;
}

core.List<api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>
    buildUnnamed630() {
  var o = <api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>[];
  o.add(buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings());
  o.add(buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings());
  return o;
}

void checkUnnamed630(
    core.List<api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings(
      o[0] as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings);
  checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings(
      o[1] as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings);
}

core.int
    buildCounterGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata =
    0;
api.GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata
    buildGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata() {
  var o =
      api.GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata();
  buildCounterGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata <
      3) {
    o.complianceRegime = 'foo';
    o.createTime = 'foo';
    o.displayName = 'foo';
    o.parent = 'foo';
    o.resourceSettings = buildUnnamed630();
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata(
    api.GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata <
      3) {
    unittest.expect(
      o.complianceRegime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    checkUnnamed630(o.resourceSettings!);
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata--;
}

core.Map<core.String, core.String> buildUnnamed631() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed631(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.List<api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>
    buildUnnamed632() {
  var o = <api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>[];
  o.add(buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings());
  o.add(buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings());
  return o;
}

void checkUnnamed632(
    core.List<api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings(
      o[0] as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings);
  checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings(
      o[1] as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings);
}

core.List<api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo>
    buildUnnamed633() {
  var o = <api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo>[];
  o.add(buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo());
  o.add(buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo());
  return o;
}

void checkUnnamed633(
    core.List<api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo(
      o[0] as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo);
  checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo(
      o[1] as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo);
}

core.int buildCounterGoogleCloudAssuredworkloadsV1beta1Workload = 0;
api.GoogleCloudAssuredworkloadsV1beta1Workload
    buildGoogleCloudAssuredworkloadsV1beta1Workload() {
  var o = api.GoogleCloudAssuredworkloadsV1beta1Workload();
  buildCounterGoogleCloudAssuredworkloadsV1beta1Workload++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1Workload < 3) {
    o.billingAccount = 'foo';
    o.cjisSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings();
    o.complianceRegime = 'foo';
    o.createTime = 'foo';
    o.displayName = 'foo';
    o.etag = 'foo';
    o.fedrampHighSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings();
    o.fedrampModerateSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings();
    o.il4Settings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings();
    o.kmsSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();
    o.labels = buildUnnamed631();
    o.name = 'foo';
    o.provisionedResourcesParent = 'foo';
    o.resourceSettings = buildUnnamed632();
    o.resources = buildUnnamed633();
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1Workload--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1Workload(
    api.GoogleCloudAssuredworkloadsV1beta1Workload o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1Workload++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1Workload < 3) {
    unittest.expect(
      o.billingAccount!,
      unittest.equals('foo'),
    );
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings(o.cjisSettings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings);
    unittest.expect(
      o.complianceRegime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings(o
            .fedrampHighSettings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings);
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings(
        o.fedrampModerateSettings! as api
            .GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings);
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings(o.il4Settings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings);
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings(o.kmsSettings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings);
    checkUnnamed631(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.provisionedResourcesParent!,
      unittest.equals('foo'),
    );
    checkUnnamed632(o.resourceSettings!);
    checkUnnamed633(o.resources!);
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1Workload--;
}

core.int buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings = 0;
api.GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings
    buildGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings() {
  var o = api.GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings();
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings < 3) {
    o.kmsSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings(
    api.GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings < 3) {
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings(o.kmsSettings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings);
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings--;
}

core.int
    buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings =
    0;
api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings
    buildGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings() {
  var o = api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings();
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings <
      3) {
    o.kmsSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings(
    api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings <
      3) {
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings(o.kmsSettings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings);
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings--;
}

core.int
    buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings =
    0;
api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings
    buildGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings() {
  var o =
      api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings();
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings <
      3) {
    o.kmsSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings(
    api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings <
      3) {
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings(o.kmsSettings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings);
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings--;
}

core.int buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings = 0;
api.GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings
    buildGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings() {
  var o = api.GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings();
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings < 3) {
    o.kmsSettings =
        buildGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings(
    api.GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings < 3) {
    checkGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings(o.kmsSettings!
        as api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings);
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings--;
}

core.int buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings = 0;
api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings
    buildGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings() {
  var o = api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings < 3) {
    o.nextRotationTime = 'foo';
    o.rotationPeriod = 'foo';
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings(
    api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings < 3) {
    unittest.expect(
      o.nextRotationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rotationPeriod!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings--;
}

core.int buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo = 0;
api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo
    buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo() {
  var o = api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo();
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo < 3) {
    o.resourceId = 'foo';
    o.resourceType = 'foo';
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo(
    api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo < 3) {
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo--;
}

core.int
    buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings = 0;
api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings
    buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings() {
  var o = api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings();
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings <
      3) {
    o.displayName = 'foo';
    o.resourceId = 'foo';
    o.resourceType = 'foo';
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings--;
  return o;
}

void checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings(
    api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings o) {
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings++;
  if (buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings <
      3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings--;
}

core.List<api.GoogleLongrunningOperation> buildUnnamed634() {
  var o = <api.GoogleLongrunningOperation>[];
  o.add(buildGoogleLongrunningOperation());
  o.add(buildGoogleLongrunningOperation());
  return o;
}

void checkUnnamed634(core.List<api.GoogleLongrunningOperation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleLongrunningOperation(o[0] as api.GoogleLongrunningOperation);
  checkGoogleLongrunningOperation(o[1] as api.GoogleLongrunningOperation);
}

core.int buildCounterGoogleLongrunningListOperationsResponse = 0;
api.GoogleLongrunningListOperationsResponse
    buildGoogleLongrunningListOperationsResponse() {
  var o = api.GoogleLongrunningListOperationsResponse();
  buildCounterGoogleLongrunningListOperationsResponse++;
  if (buildCounterGoogleLongrunningListOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed634();
  }
  buildCounterGoogleLongrunningListOperationsResponse--;
  return o;
}

void checkGoogleLongrunningListOperationsResponse(
    api.GoogleLongrunningListOperationsResponse o) {
  buildCounterGoogleLongrunningListOperationsResponse++;
  if (buildCounterGoogleLongrunningListOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed634(o.operations!);
  }
  buildCounterGoogleLongrunningListOperationsResponse--;
}

core.Map<core.String, core.Object> buildUnnamed635() {
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

void checkUnnamed635(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed636() {
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

void checkUnnamed636(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o['x']!) as core.Map;
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
  var casted4 = (o['y']!) as core.Map;
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

core.int buildCounterGoogleLongrunningOperation = 0;
api.GoogleLongrunningOperation buildGoogleLongrunningOperation() {
  var o = api.GoogleLongrunningOperation();
  buildCounterGoogleLongrunningOperation++;
  if (buildCounterGoogleLongrunningOperation < 3) {
    o.done = true;
    o.error = buildGoogleRpcStatus();
    o.metadata = buildUnnamed635();
    o.name = 'foo';
    o.response = buildUnnamed636();
  }
  buildCounterGoogleLongrunningOperation--;
  return o;
}

void checkGoogleLongrunningOperation(api.GoogleLongrunningOperation o) {
  buildCounterGoogleLongrunningOperation++;
  if (buildCounterGoogleLongrunningOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
    checkUnnamed635(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed636(o.response!);
  }
  buildCounterGoogleLongrunningOperation--;
}

core.int buildCounterGoogleProtobufEmpty = 0;
api.GoogleProtobufEmpty buildGoogleProtobufEmpty() {
  var o = api.GoogleProtobufEmpty();
  buildCounterGoogleProtobufEmpty++;
  if (buildCounterGoogleProtobufEmpty < 3) {}
  buildCounterGoogleProtobufEmpty--;
  return o;
}

void checkGoogleProtobufEmpty(api.GoogleProtobufEmpty o) {
  buildCounterGoogleProtobufEmpty++;
  if (buildCounterGoogleProtobufEmpty < 3) {}
  buildCounterGoogleProtobufEmpty--;
}

core.Map<core.String, core.Object> buildUnnamed637() {
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

void checkUnnamed637(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted5 = (o['x']!) as core.Map;
  unittest.expect(casted5, unittest.hasLength(3));
  unittest.expect(
    casted5['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted5['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted5['string'],
    unittest.equals('foo'),
  );
  var casted6 = (o['y']!) as core.Map;
  unittest.expect(casted6, unittest.hasLength(3));
  unittest.expect(
    casted6['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted6['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted6['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed638() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed637());
  o.add(buildUnnamed637());
  return o;
}

void checkUnnamed638(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed637(o[0]);
  checkUnnamed637(o[1]);
}

core.int buildCounterGoogleRpcStatus = 0;
api.GoogleRpcStatus buildGoogleRpcStatus() {
  var o = api.GoogleRpcStatus();
  buildCounterGoogleRpcStatus++;
  if (buildCounterGoogleRpcStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed638();
    o.message = 'foo';
  }
  buildCounterGoogleRpcStatus--;
  return o;
}

void checkGoogleRpcStatus(api.GoogleRpcStatus o) {
  buildCounterGoogleRpcStatus++;
  if (buildCounterGoogleRpcStatus < 3) {
    unittest.expect(
      o.code!,
      unittest.equals(42),
    );
    checkUnnamed638(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleRpcStatus--;
}

void main() {
  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata(od
          as api.GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1ListWorkloadsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1ListWorkloadsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1ListWorkloadsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1ListWorkloadsResponse(
          od as api.GoogleCloudAssuredworkloadsV1ListWorkloadsResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssuredworkloadsV1Workload', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1Workload();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1Workload.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1Workload(
          od as api.GoogleCloudAssuredworkloadsV1Workload);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssuredworkloadsV1WorkloadKMSSettings',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1WorkloadKMSSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1WorkloadKMSSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1WorkloadKMSSettings(
          od as api.GoogleCloudAssuredworkloadsV1WorkloadKMSSettings);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssuredworkloadsV1WorkloadResourceInfo',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1WorkloadResourceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1WorkloadResourceInfo(
          od as api.GoogleCloudAssuredworkloadsV1WorkloadResourceInfo);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1WorkloadResourceSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1WorkloadResourceSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1WorkloadResourceSettings(
          od as api.GoogleCloudAssuredworkloadsV1WorkloadResourceSettings);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata(od
          as api
              .GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssuredworkloadsV1beta1Workload', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1beta1Workload();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1beta1Workload.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1Workload(
          od as api.GoogleCloudAssuredworkloadsV1beta1Workload);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings(
          od as api.GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings(od
          as api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings(od
          as api
              .GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings(
          od as api.GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings(
          od as api.GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo(
          od as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings(
          od as api.GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningListOperationsResponse(
          od as api.GoogleLongrunningListOperationsResponse);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningOperation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningOperation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningOperation(od as api.GoogleLongrunningOperation);
    });
  });

  unittest.group('obj-schema-GoogleProtobufEmpty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleProtobufEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleProtobufEmpty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleProtobufEmpty(od as api.GoogleProtobufEmpty);
    });
  });

  unittest.group('obj-schema-GoogleRpcStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleRpcStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleRpcStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleRpcStatus(od as api.GoogleRpcStatus);
    });
  });

  unittest.group('resource-OrganizationsLocationsOperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.AssuredworkloadsApi(mock).organizations.locations.operations;
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
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.AssuredworkloadsApi(mock).organizations.locations.operations;
      var arg_name = 'foo';
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
        var resp =
            convert.json.encode(buildGoogleLongrunningListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleLongrunningListOperationsResponse(
          response as api.GoogleLongrunningListOperationsResponse);
    });
  });

  unittest.group('resource-OrganizationsLocationsWorkloadsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AssuredworkloadsApi(mock).organizations.locations.workloads;
      var arg_request = buildGoogleCloudAssuredworkloadsV1Workload();
      var arg_parent = 'foo';
      var arg_externalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudAssuredworkloadsV1Workload.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudAssuredworkloadsV1Workload(
            obj as api.GoogleCloudAssuredworkloadsV1Workload);

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
          queryMap["externalId"]!.first,
          unittest.equals(arg_externalId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          externalId: arg_externalId, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AssuredworkloadsApi(mock).organizations.locations.workloads;
      var arg_name = 'foo';
      var arg_etag = 'foo';
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
          queryMap["etag"]!.first,
          unittest.equals(arg_etag),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleProtobufEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_name, etag: arg_etag, $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AssuredworkloadsApi(mock).organizations.locations.workloads;
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
        var resp =
            convert.json.encode(buildGoogleCloudAssuredworkloadsV1Workload());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleCloudAssuredworkloadsV1Workload(
          response as api.GoogleCloudAssuredworkloadsV1Workload);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AssuredworkloadsApi(mock).organizations.locations.workloads;
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
        var resp = convert.json
            .encode(buildGoogleCloudAssuredworkloadsV1ListWorkloadsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudAssuredworkloadsV1ListWorkloadsResponse(
          response as api.GoogleCloudAssuredworkloadsV1ListWorkloadsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AssuredworkloadsApi(mock).organizations.locations.workloads;
      var arg_request = buildGoogleCloudAssuredworkloadsV1Workload();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudAssuredworkloadsV1Workload.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudAssuredworkloadsV1Workload(
            obj as api.GoogleCloudAssuredworkloadsV1Workload);

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
        var resp =
            convert.json.encode(buildGoogleCloudAssuredworkloadsV1Workload());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGoogleCloudAssuredworkloadsV1Workload(
          response as api.GoogleCloudAssuredworkloadsV1Workload);
    });
  });
}

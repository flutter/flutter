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

import 'package:googleapis/osconfig/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed3076() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3076(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3077() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3077(core.List<core.String> o) {
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

core.int buildCounterAptSettings = 0;
api.AptSettings buildAptSettings() {
  var o = api.AptSettings();
  buildCounterAptSettings++;
  if (buildCounterAptSettings < 3) {
    o.excludes = buildUnnamed3076();
    o.exclusivePackages = buildUnnamed3077();
    o.type = 'foo';
  }
  buildCounterAptSettings--;
  return o;
}

void checkAptSettings(api.AptSettings o) {
  buildCounterAptSettings++;
  if (buildCounterAptSettings < 3) {
    checkUnnamed3076(o.excludes!);
    checkUnnamed3077(o.exclusivePackages!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAptSettings--;
}

core.int buildCounterCancelPatchJobRequest = 0;
api.CancelPatchJobRequest buildCancelPatchJobRequest() {
  var o = api.CancelPatchJobRequest();
  buildCounterCancelPatchJobRequest++;
  if (buildCounterCancelPatchJobRequest < 3) {}
  buildCounterCancelPatchJobRequest--;
  return o;
}

void checkCancelPatchJobRequest(api.CancelPatchJobRequest o) {
  buildCounterCancelPatchJobRequest++;
  if (buildCounterCancelPatchJobRequest < 3) {}
  buildCounterCancelPatchJobRequest--;
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

core.int buildCounterExecStep = 0;
api.ExecStep buildExecStep() {
  var o = api.ExecStep();
  buildCounterExecStep++;
  if (buildCounterExecStep < 3) {
    o.linuxExecStepConfig = buildExecStepConfig();
    o.windowsExecStepConfig = buildExecStepConfig();
  }
  buildCounterExecStep--;
  return o;
}

void checkExecStep(api.ExecStep o) {
  buildCounterExecStep++;
  if (buildCounterExecStep < 3) {
    checkExecStepConfig(o.linuxExecStepConfig! as api.ExecStepConfig);
    checkExecStepConfig(o.windowsExecStepConfig! as api.ExecStepConfig);
  }
  buildCounterExecStep--;
}

core.List<core.int> buildUnnamed3078() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed3078(core.List<core.int> o) {
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

core.int buildCounterExecStepConfig = 0;
api.ExecStepConfig buildExecStepConfig() {
  var o = api.ExecStepConfig();
  buildCounterExecStepConfig++;
  if (buildCounterExecStepConfig < 3) {
    o.allowedSuccessCodes = buildUnnamed3078();
    o.gcsObject = buildGcsObject();
    o.interpreter = 'foo';
    o.localPath = 'foo';
  }
  buildCounterExecStepConfig--;
  return o;
}

void checkExecStepConfig(api.ExecStepConfig o) {
  buildCounterExecStepConfig++;
  if (buildCounterExecStepConfig < 3) {
    checkUnnamed3078(o.allowedSuccessCodes!);
    checkGcsObject(o.gcsObject! as api.GcsObject);
    unittest.expect(
      o.interpreter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterExecStepConfig--;
}

core.int buildCounterExecutePatchJobRequest = 0;
api.ExecutePatchJobRequest buildExecutePatchJobRequest() {
  var o = api.ExecutePatchJobRequest();
  buildCounterExecutePatchJobRequest++;
  if (buildCounterExecutePatchJobRequest < 3) {
    o.description = 'foo';
    o.displayName = 'foo';
    o.dryRun = true;
    o.duration = 'foo';
    o.instanceFilter = buildPatchInstanceFilter();
    o.patchConfig = buildPatchConfig();
    o.rollout = buildPatchRollout();
  }
  buildCounterExecutePatchJobRequest--;
  return o;
}

void checkExecutePatchJobRequest(api.ExecutePatchJobRequest o) {
  buildCounterExecutePatchJobRequest++;
  if (buildCounterExecutePatchJobRequest < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dryRun!, unittest.isTrue);
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    checkPatchInstanceFilter(o.instanceFilter! as api.PatchInstanceFilter);
    checkPatchConfig(o.patchConfig! as api.PatchConfig);
    checkPatchRollout(o.rollout! as api.PatchRollout);
  }
  buildCounterExecutePatchJobRequest--;
}

core.int buildCounterFixedOrPercent = 0;
api.FixedOrPercent buildFixedOrPercent() {
  var o = api.FixedOrPercent();
  buildCounterFixedOrPercent++;
  if (buildCounterFixedOrPercent < 3) {
    o.fixed = 42;
    o.percent = 42;
  }
  buildCounterFixedOrPercent--;
  return o;
}

void checkFixedOrPercent(api.FixedOrPercent o) {
  buildCounterFixedOrPercent++;
  if (buildCounterFixedOrPercent < 3) {
    unittest.expect(
      o.fixed!,
      unittest.equals(42),
    );
    unittest.expect(
      o.percent!,
      unittest.equals(42),
    );
  }
  buildCounterFixedOrPercent--;
}

core.int buildCounterGcsObject = 0;
api.GcsObject buildGcsObject() {
  var o = api.GcsObject();
  buildCounterGcsObject++;
  if (buildCounterGcsObject < 3) {
    o.bucket = 'foo';
    o.generationNumber = 'foo';
    o.object = 'foo';
  }
  buildCounterGcsObject--;
  return o;
}

void checkGcsObject(api.GcsObject o) {
  buildCounterGcsObject++;
  if (buildCounterGcsObject < 3) {
    unittest.expect(
      o.bucket!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.generationNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.object!,
      unittest.equals('foo'),
    );
  }
  buildCounterGcsObject--;
}

core.int buildCounterGooSettings = 0;
api.GooSettings buildGooSettings() {
  var o = api.GooSettings();
  buildCounterGooSettings++;
  if (buildCounterGooSettings < 3) {}
  buildCounterGooSettings--;
  return o;
}

void checkGooSettings(api.GooSettings o) {
  buildCounterGooSettings++;
  if (buildCounterGooSettings < 3) {}
  buildCounterGooSettings--;
}

core.Map<core.String, api.InventoryItem> buildUnnamed3079() {
  var o = <core.String, api.InventoryItem>{};
  o['x'] = buildInventoryItem();
  o['y'] = buildInventoryItem();
  return o;
}

void checkUnnamed3079(core.Map<core.String, api.InventoryItem> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInventoryItem(o['x']! as api.InventoryItem);
  checkInventoryItem(o['y']! as api.InventoryItem);
}

core.int buildCounterInventory = 0;
api.Inventory buildInventory() {
  var o = api.Inventory();
  buildCounterInventory++;
  if (buildCounterInventory < 3) {
    o.items = buildUnnamed3079();
    o.osInfo = buildInventoryOsInfo();
  }
  buildCounterInventory--;
  return o;
}

void checkInventory(api.Inventory o) {
  buildCounterInventory++;
  if (buildCounterInventory < 3) {
    checkUnnamed3079(o.items!);
    checkInventoryOsInfo(o.osInfo! as api.InventoryOsInfo);
  }
  buildCounterInventory--;
}

core.int buildCounterInventoryItem = 0;
api.InventoryItem buildInventoryItem() {
  var o = api.InventoryItem();
  buildCounterInventoryItem++;
  if (buildCounterInventoryItem < 3) {
    o.availablePackage = buildInventorySoftwarePackage();
    o.createTime = 'foo';
    o.id = 'foo';
    o.installedPackage = buildInventorySoftwarePackage();
    o.originType = 'foo';
    o.type = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterInventoryItem--;
  return o;
}

void checkInventoryItem(api.InventoryItem o) {
  buildCounterInventoryItem++;
  if (buildCounterInventoryItem < 3) {
    checkInventorySoftwarePackage(
        o.availablePackage! as api.InventorySoftwarePackage);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkInventorySoftwarePackage(
        o.installedPackage! as api.InventorySoftwarePackage);
    unittest.expect(
      o.originType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventoryItem--;
}

core.int buildCounterInventoryOsInfo = 0;
api.InventoryOsInfo buildInventoryOsInfo() {
  var o = api.InventoryOsInfo();
  buildCounterInventoryOsInfo++;
  if (buildCounterInventoryOsInfo < 3) {
    o.architecture = 'foo';
    o.hostname = 'foo';
    o.kernelRelease = 'foo';
    o.kernelVersion = 'foo';
    o.longName = 'foo';
    o.osconfigAgentVersion = 'foo';
    o.shortName = 'foo';
    o.version = 'foo';
  }
  buildCounterInventoryOsInfo--;
  return o;
}

void checkInventoryOsInfo(api.InventoryOsInfo o) {
  buildCounterInventoryOsInfo++;
  if (buildCounterInventoryOsInfo < 3) {
    unittest.expect(
      o.architecture!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hostname!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kernelRelease!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kernelVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.longName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.osconfigAgentVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shortName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventoryOsInfo--;
}

core.int buildCounterInventorySoftwarePackage = 0;
api.InventorySoftwarePackage buildInventorySoftwarePackage() {
  var o = api.InventorySoftwarePackage();
  buildCounterInventorySoftwarePackage++;
  if (buildCounterInventorySoftwarePackage < 3) {
    o.aptPackage = buildInventoryVersionedPackage();
    o.cosPackage = buildInventoryVersionedPackage();
    o.googetPackage = buildInventoryVersionedPackage();
    o.qfePackage = buildInventoryWindowsQuickFixEngineeringPackage();
    o.wuaPackage = buildInventoryWindowsUpdatePackage();
    o.yumPackage = buildInventoryVersionedPackage();
    o.zypperPackage = buildInventoryVersionedPackage();
    o.zypperPatch = buildInventoryZypperPatch();
  }
  buildCounterInventorySoftwarePackage--;
  return o;
}

void checkInventorySoftwarePackage(api.InventorySoftwarePackage o) {
  buildCounterInventorySoftwarePackage++;
  if (buildCounterInventorySoftwarePackage < 3) {
    checkInventoryVersionedPackage(
        o.aptPackage! as api.InventoryVersionedPackage);
    checkInventoryVersionedPackage(
        o.cosPackage! as api.InventoryVersionedPackage);
    checkInventoryVersionedPackage(
        o.googetPackage! as api.InventoryVersionedPackage);
    checkInventoryWindowsQuickFixEngineeringPackage(
        o.qfePackage! as api.InventoryWindowsQuickFixEngineeringPackage);
    checkInventoryWindowsUpdatePackage(
        o.wuaPackage! as api.InventoryWindowsUpdatePackage);
    checkInventoryVersionedPackage(
        o.yumPackage! as api.InventoryVersionedPackage);
    checkInventoryVersionedPackage(
        o.zypperPackage! as api.InventoryVersionedPackage);
    checkInventoryZypperPatch(o.zypperPatch! as api.InventoryZypperPatch);
  }
  buildCounterInventorySoftwarePackage--;
}

core.int buildCounterInventoryVersionedPackage = 0;
api.InventoryVersionedPackage buildInventoryVersionedPackage() {
  var o = api.InventoryVersionedPackage();
  buildCounterInventoryVersionedPackage++;
  if (buildCounterInventoryVersionedPackage < 3) {
    o.architecture = 'foo';
    o.packageName = 'foo';
    o.version = 'foo';
  }
  buildCounterInventoryVersionedPackage--;
  return o;
}

void checkInventoryVersionedPackage(api.InventoryVersionedPackage o) {
  buildCounterInventoryVersionedPackage++;
  if (buildCounterInventoryVersionedPackage < 3) {
    unittest.expect(
      o.architecture!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventoryVersionedPackage--;
}

core.int buildCounterInventoryWindowsQuickFixEngineeringPackage = 0;
api.InventoryWindowsQuickFixEngineeringPackage
    buildInventoryWindowsQuickFixEngineeringPackage() {
  var o = api.InventoryWindowsQuickFixEngineeringPackage();
  buildCounterInventoryWindowsQuickFixEngineeringPackage++;
  if (buildCounterInventoryWindowsQuickFixEngineeringPackage < 3) {
    o.caption = 'foo';
    o.description = 'foo';
    o.hotFixId = 'foo';
    o.installTime = 'foo';
  }
  buildCounterInventoryWindowsQuickFixEngineeringPackage--;
  return o;
}

void checkInventoryWindowsQuickFixEngineeringPackage(
    api.InventoryWindowsQuickFixEngineeringPackage o) {
  buildCounterInventoryWindowsQuickFixEngineeringPackage++;
  if (buildCounterInventoryWindowsQuickFixEngineeringPackage < 3) {
    unittest.expect(
      o.caption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hotFixId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.installTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventoryWindowsQuickFixEngineeringPackage--;
}

core.List<api.InventoryWindowsUpdatePackageWindowsUpdateCategory>
    buildUnnamed3080() {
  var o = <api.InventoryWindowsUpdatePackageWindowsUpdateCategory>[];
  o.add(buildInventoryWindowsUpdatePackageWindowsUpdateCategory());
  o.add(buildInventoryWindowsUpdatePackageWindowsUpdateCategory());
  return o;
}

void checkUnnamed3080(
    core.List<api.InventoryWindowsUpdatePackageWindowsUpdateCategory> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInventoryWindowsUpdatePackageWindowsUpdateCategory(
      o[0] as api.InventoryWindowsUpdatePackageWindowsUpdateCategory);
  checkInventoryWindowsUpdatePackageWindowsUpdateCategory(
      o[1] as api.InventoryWindowsUpdatePackageWindowsUpdateCategory);
}

core.List<core.String> buildUnnamed3081() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3081(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3082() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3082(core.List<core.String> o) {
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

core.int buildCounterInventoryWindowsUpdatePackage = 0;
api.InventoryWindowsUpdatePackage buildInventoryWindowsUpdatePackage() {
  var o = api.InventoryWindowsUpdatePackage();
  buildCounterInventoryWindowsUpdatePackage++;
  if (buildCounterInventoryWindowsUpdatePackage < 3) {
    o.categories = buildUnnamed3080();
    o.description = 'foo';
    o.kbArticleIds = buildUnnamed3081();
    o.lastDeploymentChangeTime = 'foo';
    o.moreInfoUrls = buildUnnamed3082();
    o.revisionNumber = 42;
    o.supportUrl = 'foo';
    o.title = 'foo';
    o.updateId = 'foo';
  }
  buildCounterInventoryWindowsUpdatePackage--;
  return o;
}

void checkInventoryWindowsUpdatePackage(api.InventoryWindowsUpdatePackage o) {
  buildCounterInventoryWindowsUpdatePackage++;
  if (buildCounterInventoryWindowsUpdatePackage < 3) {
    checkUnnamed3080(o.categories!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed3081(o.kbArticleIds!);
    unittest.expect(
      o.lastDeploymentChangeTime!,
      unittest.equals('foo'),
    );
    checkUnnamed3082(o.moreInfoUrls!);
    unittest.expect(
      o.revisionNumber!,
      unittest.equals(42),
    );
    unittest.expect(
      o.supportUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateId!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventoryWindowsUpdatePackage--;
}

core.int buildCounterInventoryWindowsUpdatePackageWindowsUpdateCategory = 0;
api.InventoryWindowsUpdatePackageWindowsUpdateCategory
    buildInventoryWindowsUpdatePackageWindowsUpdateCategory() {
  var o = api.InventoryWindowsUpdatePackageWindowsUpdateCategory();
  buildCounterInventoryWindowsUpdatePackageWindowsUpdateCategory++;
  if (buildCounterInventoryWindowsUpdatePackageWindowsUpdateCategory < 3) {
    o.id = 'foo';
    o.name = 'foo';
  }
  buildCounterInventoryWindowsUpdatePackageWindowsUpdateCategory--;
  return o;
}

void checkInventoryWindowsUpdatePackageWindowsUpdateCategory(
    api.InventoryWindowsUpdatePackageWindowsUpdateCategory o) {
  buildCounterInventoryWindowsUpdatePackageWindowsUpdateCategory++;
  if (buildCounterInventoryWindowsUpdatePackageWindowsUpdateCategory < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventoryWindowsUpdatePackageWindowsUpdateCategory--;
}

core.int buildCounterInventoryZypperPatch = 0;
api.InventoryZypperPatch buildInventoryZypperPatch() {
  var o = api.InventoryZypperPatch();
  buildCounterInventoryZypperPatch++;
  if (buildCounterInventoryZypperPatch < 3) {
    o.category = 'foo';
    o.patchName = 'foo';
    o.severity = 'foo';
    o.summary = 'foo';
  }
  buildCounterInventoryZypperPatch--;
  return o;
}

void checkInventoryZypperPatch(api.InventoryZypperPatch o) {
  buildCounterInventoryZypperPatch++;
  if (buildCounterInventoryZypperPatch < 3) {
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.patchName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.summary!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventoryZypperPatch--;
}

core.List<api.Operation> buildUnnamed3083() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed3083(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterListOperationsResponse = 0;
api.ListOperationsResponse buildListOperationsResponse() {
  var o = api.ListOperationsResponse();
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed3083();
  }
  buildCounterListOperationsResponse--;
  return o;
}

void checkListOperationsResponse(api.ListOperationsResponse o) {
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3083(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.PatchDeployment> buildUnnamed3084() {
  var o = <api.PatchDeployment>[];
  o.add(buildPatchDeployment());
  o.add(buildPatchDeployment());
  return o;
}

void checkUnnamed3084(core.List<api.PatchDeployment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPatchDeployment(o[0] as api.PatchDeployment);
  checkPatchDeployment(o[1] as api.PatchDeployment);
}

core.int buildCounterListPatchDeploymentsResponse = 0;
api.ListPatchDeploymentsResponse buildListPatchDeploymentsResponse() {
  var o = api.ListPatchDeploymentsResponse();
  buildCounterListPatchDeploymentsResponse++;
  if (buildCounterListPatchDeploymentsResponse < 3) {
    o.nextPageToken = 'foo';
    o.patchDeployments = buildUnnamed3084();
  }
  buildCounterListPatchDeploymentsResponse--;
  return o;
}

void checkListPatchDeploymentsResponse(api.ListPatchDeploymentsResponse o) {
  buildCounterListPatchDeploymentsResponse++;
  if (buildCounterListPatchDeploymentsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3084(o.patchDeployments!);
  }
  buildCounterListPatchDeploymentsResponse--;
}

core.List<api.PatchJobInstanceDetails> buildUnnamed3085() {
  var o = <api.PatchJobInstanceDetails>[];
  o.add(buildPatchJobInstanceDetails());
  o.add(buildPatchJobInstanceDetails());
  return o;
}

void checkUnnamed3085(core.List<api.PatchJobInstanceDetails> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPatchJobInstanceDetails(o[0] as api.PatchJobInstanceDetails);
  checkPatchJobInstanceDetails(o[1] as api.PatchJobInstanceDetails);
}

core.int buildCounterListPatchJobInstanceDetailsResponse = 0;
api.ListPatchJobInstanceDetailsResponse
    buildListPatchJobInstanceDetailsResponse() {
  var o = api.ListPatchJobInstanceDetailsResponse();
  buildCounterListPatchJobInstanceDetailsResponse++;
  if (buildCounterListPatchJobInstanceDetailsResponse < 3) {
    o.nextPageToken = 'foo';
    o.patchJobInstanceDetails = buildUnnamed3085();
  }
  buildCounterListPatchJobInstanceDetailsResponse--;
  return o;
}

void checkListPatchJobInstanceDetailsResponse(
    api.ListPatchJobInstanceDetailsResponse o) {
  buildCounterListPatchJobInstanceDetailsResponse++;
  if (buildCounterListPatchJobInstanceDetailsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3085(o.patchJobInstanceDetails!);
  }
  buildCounterListPatchJobInstanceDetailsResponse--;
}

core.List<api.PatchJob> buildUnnamed3086() {
  var o = <api.PatchJob>[];
  o.add(buildPatchJob());
  o.add(buildPatchJob());
  return o;
}

void checkUnnamed3086(core.List<api.PatchJob> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPatchJob(o[0] as api.PatchJob);
  checkPatchJob(o[1] as api.PatchJob);
}

core.int buildCounterListPatchJobsResponse = 0;
api.ListPatchJobsResponse buildListPatchJobsResponse() {
  var o = api.ListPatchJobsResponse();
  buildCounterListPatchJobsResponse++;
  if (buildCounterListPatchJobsResponse < 3) {
    o.nextPageToken = 'foo';
    o.patchJobs = buildUnnamed3086();
  }
  buildCounterListPatchJobsResponse--;
  return o;
}

void checkListPatchJobsResponse(api.ListPatchJobsResponse o) {
  buildCounterListPatchJobsResponse++;
  if (buildCounterListPatchJobsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3086(o.patchJobs!);
  }
  buildCounterListPatchJobsResponse--;
}

core.int buildCounterMonthlySchedule = 0;
api.MonthlySchedule buildMonthlySchedule() {
  var o = api.MonthlySchedule();
  buildCounterMonthlySchedule++;
  if (buildCounterMonthlySchedule < 3) {
    o.monthDay = 42;
    o.weekDayOfMonth = buildWeekDayOfMonth();
  }
  buildCounterMonthlySchedule--;
  return o;
}

void checkMonthlySchedule(api.MonthlySchedule o) {
  buildCounterMonthlySchedule++;
  if (buildCounterMonthlySchedule < 3) {
    unittest.expect(
      o.monthDay!,
      unittest.equals(42),
    );
    checkWeekDayOfMonth(o.weekDayOfMonth! as api.WeekDayOfMonth);
  }
  buildCounterMonthlySchedule--;
}

core.int buildCounterOSPolicyAssignmentOperationMetadata = 0;
api.OSPolicyAssignmentOperationMetadata
    buildOSPolicyAssignmentOperationMetadata() {
  var o = api.OSPolicyAssignmentOperationMetadata();
  buildCounterOSPolicyAssignmentOperationMetadata++;
  if (buildCounterOSPolicyAssignmentOperationMetadata < 3) {
    o.apiMethod = 'foo';
    o.osPolicyAssignment = 'foo';
    o.rolloutStartTime = 'foo';
    o.rolloutState = 'foo';
    o.rolloutUpdateTime = 'foo';
  }
  buildCounterOSPolicyAssignmentOperationMetadata--;
  return o;
}

void checkOSPolicyAssignmentOperationMetadata(
    api.OSPolicyAssignmentOperationMetadata o) {
  buildCounterOSPolicyAssignmentOperationMetadata++;
  if (buildCounterOSPolicyAssignmentOperationMetadata < 3) {
    unittest.expect(
      o.apiMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.osPolicyAssignment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rolloutStartTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rolloutState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rolloutUpdateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterOSPolicyAssignmentOperationMetadata--;
}

core.int buildCounterOneTimeSchedule = 0;
api.OneTimeSchedule buildOneTimeSchedule() {
  var o = api.OneTimeSchedule();
  buildCounterOneTimeSchedule++;
  if (buildCounterOneTimeSchedule < 3) {
    o.executeTime = 'foo';
  }
  buildCounterOneTimeSchedule--;
  return o;
}

void checkOneTimeSchedule(api.OneTimeSchedule o) {
  buildCounterOneTimeSchedule++;
  if (buildCounterOneTimeSchedule < 3) {
    unittest.expect(
      o.executeTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterOneTimeSchedule--;
}

core.Map<core.String, core.Object> buildUnnamed3087() {
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

void checkUnnamed3087(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed3088() {
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

void checkUnnamed3088(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed3087();
    o.name = 'foo';
    o.response = buildUnnamed3088();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed3087(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3088(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterPatchConfig = 0;
api.PatchConfig buildPatchConfig() {
  var o = api.PatchConfig();
  buildCounterPatchConfig++;
  if (buildCounterPatchConfig < 3) {
    o.apt = buildAptSettings();
    o.goo = buildGooSettings();
    o.postStep = buildExecStep();
    o.preStep = buildExecStep();
    o.rebootConfig = 'foo';
    o.windowsUpdate = buildWindowsUpdateSettings();
    o.yum = buildYumSettings();
    o.zypper = buildZypperSettings();
  }
  buildCounterPatchConfig--;
  return o;
}

void checkPatchConfig(api.PatchConfig o) {
  buildCounterPatchConfig++;
  if (buildCounterPatchConfig < 3) {
    checkAptSettings(o.apt! as api.AptSettings);
    checkGooSettings(o.goo! as api.GooSettings);
    checkExecStep(o.postStep! as api.ExecStep);
    checkExecStep(o.preStep! as api.ExecStep);
    unittest.expect(
      o.rebootConfig!,
      unittest.equals('foo'),
    );
    checkWindowsUpdateSettings(o.windowsUpdate! as api.WindowsUpdateSettings);
    checkYumSettings(o.yum! as api.YumSettings);
    checkZypperSettings(o.zypper! as api.ZypperSettings);
  }
  buildCounterPatchConfig--;
}

core.int buildCounterPatchDeployment = 0;
api.PatchDeployment buildPatchDeployment() {
  var o = api.PatchDeployment();
  buildCounterPatchDeployment++;
  if (buildCounterPatchDeployment < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.duration = 'foo';
    o.instanceFilter = buildPatchInstanceFilter();
    o.lastExecuteTime = 'foo';
    o.name = 'foo';
    o.oneTimeSchedule = buildOneTimeSchedule();
    o.patchConfig = buildPatchConfig();
    o.recurringSchedule = buildRecurringSchedule();
    o.rollout = buildPatchRollout();
    o.updateTime = 'foo';
  }
  buildCounterPatchDeployment--;
  return o;
}

void checkPatchDeployment(api.PatchDeployment o) {
  buildCounterPatchDeployment++;
  if (buildCounterPatchDeployment < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    checkPatchInstanceFilter(o.instanceFilter! as api.PatchInstanceFilter);
    unittest.expect(
      o.lastExecuteTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOneTimeSchedule(o.oneTimeSchedule! as api.OneTimeSchedule);
    checkPatchConfig(o.patchConfig! as api.PatchConfig);
    checkRecurringSchedule(o.recurringSchedule! as api.RecurringSchedule);
    checkPatchRollout(o.rollout! as api.PatchRollout);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPatchDeployment--;
}

core.List<api.PatchInstanceFilterGroupLabel> buildUnnamed3089() {
  var o = <api.PatchInstanceFilterGroupLabel>[];
  o.add(buildPatchInstanceFilterGroupLabel());
  o.add(buildPatchInstanceFilterGroupLabel());
  return o;
}

void checkUnnamed3089(core.List<api.PatchInstanceFilterGroupLabel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPatchInstanceFilterGroupLabel(o[0] as api.PatchInstanceFilterGroupLabel);
  checkPatchInstanceFilterGroupLabel(o[1] as api.PatchInstanceFilterGroupLabel);
}

core.List<core.String> buildUnnamed3090() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3090(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3091() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3091(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3092() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3092(core.List<core.String> o) {
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

core.int buildCounterPatchInstanceFilter = 0;
api.PatchInstanceFilter buildPatchInstanceFilter() {
  var o = api.PatchInstanceFilter();
  buildCounterPatchInstanceFilter++;
  if (buildCounterPatchInstanceFilter < 3) {
    o.all = true;
    o.groupLabels = buildUnnamed3089();
    o.instanceNamePrefixes = buildUnnamed3090();
    o.instances = buildUnnamed3091();
    o.zones = buildUnnamed3092();
  }
  buildCounterPatchInstanceFilter--;
  return o;
}

void checkPatchInstanceFilter(api.PatchInstanceFilter o) {
  buildCounterPatchInstanceFilter++;
  if (buildCounterPatchInstanceFilter < 3) {
    unittest.expect(o.all!, unittest.isTrue);
    checkUnnamed3089(o.groupLabels!);
    checkUnnamed3090(o.instanceNamePrefixes!);
    checkUnnamed3091(o.instances!);
    checkUnnamed3092(o.zones!);
  }
  buildCounterPatchInstanceFilter--;
}

core.Map<core.String, core.String> buildUnnamed3093() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3093(core.Map<core.String, core.String> o) {
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

core.int buildCounterPatchInstanceFilterGroupLabel = 0;
api.PatchInstanceFilterGroupLabel buildPatchInstanceFilterGroupLabel() {
  var o = api.PatchInstanceFilterGroupLabel();
  buildCounterPatchInstanceFilterGroupLabel++;
  if (buildCounterPatchInstanceFilterGroupLabel < 3) {
    o.labels = buildUnnamed3093();
  }
  buildCounterPatchInstanceFilterGroupLabel--;
  return o;
}

void checkPatchInstanceFilterGroupLabel(api.PatchInstanceFilterGroupLabel o) {
  buildCounterPatchInstanceFilterGroupLabel++;
  if (buildCounterPatchInstanceFilterGroupLabel < 3) {
    checkUnnamed3093(o.labels!);
  }
  buildCounterPatchInstanceFilterGroupLabel--;
}

core.int buildCounterPatchJob = 0;
api.PatchJob buildPatchJob() {
  var o = api.PatchJob();
  buildCounterPatchJob++;
  if (buildCounterPatchJob < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.dryRun = true;
    o.duration = 'foo';
    o.errorMessage = 'foo';
    o.instanceDetailsSummary = buildPatchJobInstanceDetailsSummary();
    o.instanceFilter = buildPatchInstanceFilter();
    o.name = 'foo';
    o.patchConfig = buildPatchConfig();
    o.patchDeployment = 'foo';
    o.percentComplete = 42.0;
    o.rollout = buildPatchRollout();
    o.state = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterPatchJob--;
  return o;
}

void checkPatchJob(api.PatchJob o) {
  buildCounterPatchJob++;
  if (buildCounterPatchJob < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dryRun!, unittest.isTrue);
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    checkPatchJobInstanceDetailsSummary(
        o.instanceDetailsSummary! as api.PatchJobInstanceDetailsSummary);
    checkPatchInstanceFilter(o.instanceFilter! as api.PatchInstanceFilter);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkPatchConfig(o.patchConfig! as api.PatchConfig);
    unittest.expect(
      o.patchDeployment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.percentComplete!,
      unittest.equals(42.0),
    );
    checkPatchRollout(o.rollout! as api.PatchRollout);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPatchJob--;
}

core.int buildCounterPatchJobInstanceDetails = 0;
api.PatchJobInstanceDetails buildPatchJobInstanceDetails() {
  var o = api.PatchJobInstanceDetails();
  buildCounterPatchJobInstanceDetails++;
  if (buildCounterPatchJobInstanceDetails < 3) {
    o.attemptCount = 'foo';
    o.failureReason = 'foo';
    o.instanceSystemId = 'foo';
    o.name = 'foo';
    o.state = 'foo';
  }
  buildCounterPatchJobInstanceDetails--;
  return o;
}

void checkPatchJobInstanceDetails(api.PatchJobInstanceDetails o) {
  buildCounterPatchJobInstanceDetails++;
  if (buildCounterPatchJobInstanceDetails < 3) {
    unittest.expect(
      o.attemptCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.failureReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instanceSystemId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterPatchJobInstanceDetails--;
}

core.int buildCounterPatchJobInstanceDetailsSummary = 0;
api.PatchJobInstanceDetailsSummary buildPatchJobInstanceDetailsSummary() {
  var o = api.PatchJobInstanceDetailsSummary();
  buildCounterPatchJobInstanceDetailsSummary++;
  if (buildCounterPatchJobInstanceDetailsSummary < 3) {
    o.ackedInstanceCount = 'foo';
    o.applyingPatchesInstanceCount = 'foo';
    o.downloadingPatchesInstanceCount = 'foo';
    o.failedInstanceCount = 'foo';
    o.inactiveInstanceCount = 'foo';
    o.noAgentDetectedInstanceCount = 'foo';
    o.notifiedInstanceCount = 'foo';
    o.pendingInstanceCount = 'foo';
    o.postPatchStepInstanceCount = 'foo';
    o.prePatchStepInstanceCount = 'foo';
    o.rebootingInstanceCount = 'foo';
    o.startedInstanceCount = 'foo';
    o.succeededInstanceCount = 'foo';
    o.succeededRebootRequiredInstanceCount = 'foo';
    o.timedOutInstanceCount = 'foo';
  }
  buildCounterPatchJobInstanceDetailsSummary--;
  return o;
}

void checkPatchJobInstanceDetailsSummary(api.PatchJobInstanceDetailsSummary o) {
  buildCounterPatchJobInstanceDetailsSummary++;
  if (buildCounterPatchJobInstanceDetailsSummary < 3) {
    unittest.expect(
      o.ackedInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.applyingPatchesInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.downloadingPatchesInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.failedInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inactiveInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.noAgentDetectedInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notifiedInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pendingInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postPatchStepInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.prePatchStepInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rebootingInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startedInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.succeededInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.succeededRebootRequiredInstanceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timedOutInstanceCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterPatchJobInstanceDetailsSummary--;
}

core.int buildCounterPatchRollout = 0;
api.PatchRollout buildPatchRollout() {
  var o = api.PatchRollout();
  buildCounterPatchRollout++;
  if (buildCounterPatchRollout < 3) {
    o.disruptionBudget = buildFixedOrPercent();
    o.mode = 'foo';
  }
  buildCounterPatchRollout--;
  return o;
}

void checkPatchRollout(api.PatchRollout o) {
  buildCounterPatchRollout++;
  if (buildCounterPatchRollout < 3) {
    checkFixedOrPercent(o.disruptionBudget! as api.FixedOrPercent);
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
  }
  buildCounterPatchRollout--;
}

core.int buildCounterRecurringSchedule = 0;
api.RecurringSchedule buildRecurringSchedule() {
  var o = api.RecurringSchedule();
  buildCounterRecurringSchedule++;
  if (buildCounterRecurringSchedule < 3) {
    o.endTime = 'foo';
    o.frequency = 'foo';
    o.lastExecuteTime = 'foo';
    o.monthly = buildMonthlySchedule();
    o.nextExecuteTime = 'foo';
    o.startTime = 'foo';
    o.timeOfDay = buildTimeOfDay();
    o.timeZone = buildTimeZone();
    o.weekly = buildWeeklySchedule();
  }
  buildCounterRecurringSchedule--;
  return o;
}

void checkRecurringSchedule(api.RecurringSchedule o) {
  buildCounterRecurringSchedule++;
  if (buildCounterRecurringSchedule < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.frequency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastExecuteTime!,
      unittest.equals('foo'),
    );
    checkMonthlySchedule(o.monthly! as api.MonthlySchedule);
    unittest.expect(
      o.nextExecuteTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    checkTimeOfDay(o.timeOfDay! as api.TimeOfDay);
    checkTimeZone(o.timeZone! as api.TimeZone);
    checkWeeklySchedule(o.weekly! as api.WeeklySchedule);
  }
  buildCounterRecurringSchedule--;
}

core.Map<core.String, core.Object> buildUnnamed3094() {
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

void checkUnnamed3094(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed3095() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed3094());
  o.add(buildUnnamed3094());
  return o;
}

void checkUnnamed3095(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed3094(o[0]);
  checkUnnamed3094(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed3095();
    o.message = 'foo';
  }
  buildCounterStatus--;
  return o;
}

void checkStatus(api.Status o) {
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    unittest.expect(
      o.code!,
      unittest.equals(42),
    );
    checkUnnamed3095(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTimeOfDay = 0;
api.TimeOfDay buildTimeOfDay() {
  var o = api.TimeOfDay();
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    o.hours = 42;
    o.minutes = 42;
    o.nanos = 42;
    o.seconds = 42;
  }
  buildCounterTimeOfDay--;
  return o;
}

void checkTimeOfDay(api.TimeOfDay o) {
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    unittest.expect(
      o.hours!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minutes!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.seconds!,
      unittest.equals(42),
    );
  }
  buildCounterTimeOfDay--;
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

core.int buildCounterWeekDayOfMonth = 0;
api.WeekDayOfMonth buildWeekDayOfMonth() {
  var o = api.WeekDayOfMonth();
  buildCounterWeekDayOfMonth++;
  if (buildCounterWeekDayOfMonth < 3) {
    o.dayOfWeek = 'foo';
    o.weekOrdinal = 42;
  }
  buildCounterWeekDayOfMonth--;
  return o;
}

void checkWeekDayOfMonth(api.WeekDayOfMonth o) {
  buildCounterWeekDayOfMonth++;
  if (buildCounterWeekDayOfMonth < 3) {
    unittest.expect(
      o.dayOfWeek!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.weekOrdinal!,
      unittest.equals(42),
    );
  }
  buildCounterWeekDayOfMonth--;
}

core.int buildCounterWeeklySchedule = 0;
api.WeeklySchedule buildWeeklySchedule() {
  var o = api.WeeklySchedule();
  buildCounterWeeklySchedule++;
  if (buildCounterWeeklySchedule < 3) {
    o.dayOfWeek = 'foo';
  }
  buildCounterWeeklySchedule--;
  return o;
}

void checkWeeklySchedule(api.WeeklySchedule o) {
  buildCounterWeeklySchedule++;
  if (buildCounterWeeklySchedule < 3) {
    unittest.expect(
      o.dayOfWeek!,
      unittest.equals('foo'),
    );
  }
  buildCounterWeeklySchedule--;
}

core.List<core.String> buildUnnamed3096() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3096(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3097() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3097(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3098() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3098(core.List<core.String> o) {
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

core.int buildCounterWindowsUpdateSettings = 0;
api.WindowsUpdateSettings buildWindowsUpdateSettings() {
  var o = api.WindowsUpdateSettings();
  buildCounterWindowsUpdateSettings++;
  if (buildCounterWindowsUpdateSettings < 3) {
    o.classifications = buildUnnamed3096();
    o.excludes = buildUnnamed3097();
    o.exclusivePatches = buildUnnamed3098();
  }
  buildCounterWindowsUpdateSettings--;
  return o;
}

void checkWindowsUpdateSettings(api.WindowsUpdateSettings o) {
  buildCounterWindowsUpdateSettings++;
  if (buildCounterWindowsUpdateSettings < 3) {
    checkUnnamed3096(o.classifications!);
    checkUnnamed3097(o.excludes!);
    checkUnnamed3098(o.exclusivePatches!);
  }
  buildCounterWindowsUpdateSettings--;
}

core.List<core.String> buildUnnamed3099() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3099(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3100() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3100(core.List<core.String> o) {
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

core.int buildCounterYumSettings = 0;
api.YumSettings buildYumSettings() {
  var o = api.YumSettings();
  buildCounterYumSettings++;
  if (buildCounterYumSettings < 3) {
    o.excludes = buildUnnamed3099();
    o.exclusivePackages = buildUnnamed3100();
    o.minimal = true;
    o.security = true;
  }
  buildCounterYumSettings--;
  return o;
}

void checkYumSettings(api.YumSettings o) {
  buildCounterYumSettings++;
  if (buildCounterYumSettings < 3) {
    checkUnnamed3099(o.excludes!);
    checkUnnamed3100(o.exclusivePackages!);
    unittest.expect(o.minimal!, unittest.isTrue);
    unittest.expect(o.security!, unittest.isTrue);
  }
  buildCounterYumSettings--;
}

core.List<core.String> buildUnnamed3101() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3101(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3102() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3102(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3103() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3103(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3104() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3104(core.List<core.String> o) {
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

core.int buildCounterZypperSettings = 0;
api.ZypperSettings buildZypperSettings() {
  var o = api.ZypperSettings();
  buildCounterZypperSettings++;
  if (buildCounterZypperSettings < 3) {
    o.categories = buildUnnamed3101();
    o.excludes = buildUnnamed3102();
    o.exclusivePatches = buildUnnamed3103();
    o.severities = buildUnnamed3104();
    o.withOptional = true;
    o.withUpdate = true;
  }
  buildCounterZypperSettings--;
  return o;
}

void checkZypperSettings(api.ZypperSettings o) {
  buildCounterZypperSettings++;
  if (buildCounterZypperSettings < 3) {
    checkUnnamed3101(o.categories!);
    checkUnnamed3102(o.excludes!);
    checkUnnamed3103(o.exclusivePatches!);
    checkUnnamed3104(o.severities!);
    unittest.expect(o.withOptional!, unittest.isTrue);
    unittest.expect(o.withUpdate!, unittest.isTrue);
  }
  buildCounterZypperSettings--;
}

void main() {
  unittest.group('obj-schema-AptSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAptSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AptSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAptSettings(od as api.AptSettings);
    });
  });

  unittest.group('obj-schema-CancelPatchJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelPatchJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelPatchJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelPatchJobRequest(od as api.CancelPatchJobRequest);
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

  unittest.group('obj-schema-ExecStep', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecStep();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ExecStep.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExecStep(od as api.ExecStep);
    });
  });

  unittest.group('obj-schema-ExecStepConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecStepConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecStepConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecStepConfig(od as api.ExecStepConfig);
    });
  });

  unittest.group('obj-schema-ExecutePatchJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecutePatchJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecutePatchJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecutePatchJobRequest(od as api.ExecutePatchJobRequest);
    });
  });

  unittest.group('obj-schema-FixedOrPercent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFixedOrPercent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FixedOrPercent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFixedOrPercent(od as api.FixedOrPercent);
    });
  });

  unittest.group('obj-schema-GcsObject', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGcsObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GcsObject.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGcsObject(od as api.GcsObject);
    });
  });

  unittest.group('obj-schema-GooSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGooSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GooSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGooSettings(od as api.GooSettings);
    });
  });

  unittest.group('obj-schema-Inventory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Inventory.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInventory(od as api.Inventory);
    });
  });

  unittest.group('obj-schema-InventoryItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventoryItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventoryItem.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventoryItem(od as api.InventoryItem);
    });
  });

  unittest.group('obj-schema-InventoryOsInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventoryOsInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventoryOsInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventoryOsInfo(od as api.InventoryOsInfo);
    });
  });

  unittest.group('obj-schema-InventorySoftwarePackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySoftwarePackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySoftwarePackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySoftwarePackage(od as api.InventorySoftwarePackage);
    });
  });

  unittest.group('obj-schema-InventoryVersionedPackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventoryVersionedPackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventoryVersionedPackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventoryVersionedPackage(od as api.InventoryVersionedPackage);
    });
  });

  unittest.group('obj-schema-InventoryWindowsQuickFixEngineeringPackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventoryWindowsQuickFixEngineeringPackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventoryWindowsQuickFixEngineeringPackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventoryWindowsQuickFixEngineeringPackage(
          od as api.InventoryWindowsQuickFixEngineeringPackage);
    });
  });

  unittest.group('obj-schema-InventoryWindowsUpdatePackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventoryWindowsUpdatePackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventoryWindowsUpdatePackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventoryWindowsUpdatePackage(
          od as api.InventoryWindowsUpdatePackage);
    });
  });

  unittest.group(
      'obj-schema-InventoryWindowsUpdatePackageWindowsUpdateCategory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventoryWindowsUpdatePackageWindowsUpdateCategory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventoryWindowsUpdatePackageWindowsUpdateCategory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventoryWindowsUpdatePackageWindowsUpdateCategory(
          od as api.InventoryWindowsUpdatePackageWindowsUpdateCategory);
    });
  });

  unittest.group('obj-schema-InventoryZypperPatch', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventoryZypperPatch();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventoryZypperPatch.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventoryZypperPatch(od as api.InventoryZypperPatch);
    });
  });

  unittest.group('obj-schema-ListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOperationsResponse(od as api.ListOperationsResponse);
    });
  });

  unittest.group('obj-schema-ListPatchDeploymentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPatchDeploymentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPatchDeploymentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPatchDeploymentsResponse(od as api.ListPatchDeploymentsResponse);
    });
  });

  unittest.group('obj-schema-ListPatchJobInstanceDetailsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPatchJobInstanceDetailsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPatchJobInstanceDetailsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPatchJobInstanceDetailsResponse(
          od as api.ListPatchJobInstanceDetailsResponse);
    });
  });

  unittest.group('obj-schema-ListPatchJobsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPatchJobsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPatchJobsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPatchJobsResponse(od as api.ListPatchJobsResponse);
    });
  });

  unittest.group('obj-schema-MonthlySchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMonthlySchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MonthlySchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMonthlySchedule(od as api.MonthlySchedule);
    });
  });

  unittest.group('obj-schema-OSPolicyAssignmentOperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOSPolicyAssignmentOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OSPolicyAssignmentOperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOSPolicyAssignmentOperationMetadata(
          od as api.OSPolicyAssignmentOperationMetadata);
    });
  });

  unittest.group('obj-schema-OneTimeSchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOneTimeSchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OneTimeSchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOneTimeSchedule(od as api.OneTimeSchedule);
    });
  });

  unittest.group('obj-schema-Operation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Operation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOperation(od as api.Operation);
    });
  });

  unittest.group('obj-schema-PatchConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchConfig(od as api.PatchConfig);
    });
  });

  unittest.group('obj-schema-PatchDeployment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchDeployment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchDeployment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchDeployment(od as api.PatchDeployment);
    });
  });

  unittest.group('obj-schema-PatchInstanceFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchInstanceFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchInstanceFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchInstanceFilter(od as api.PatchInstanceFilter);
    });
  });

  unittest.group('obj-schema-PatchInstanceFilterGroupLabel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchInstanceFilterGroupLabel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchInstanceFilterGroupLabel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchInstanceFilterGroupLabel(
          od as api.PatchInstanceFilterGroupLabel);
    });
  });

  unittest.group('obj-schema-PatchJob', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PatchJob.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPatchJob(od as api.PatchJob);
    });
  });

  unittest.group('obj-schema-PatchJobInstanceDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchJobInstanceDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchJobInstanceDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchJobInstanceDetails(od as api.PatchJobInstanceDetails);
    });
  });

  unittest.group('obj-schema-PatchJobInstanceDetailsSummary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchJobInstanceDetailsSummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchJobInstanceDetailsSummary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchJobInstanceDetailsSummary(
          od as api.PatchJobInstanceDetailsSummary);
    });
  });

  unittest.group('obj-schema-PatchRollout', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchRollout();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchRollout.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchRollout(od as api.PatchRollout);
    });
  });

  unittest.group('obj-schema-RecurringSchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecurringSchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RecurringSchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRecurringSchedule(od as api.RecurringSchedule);
    });
  });

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-TimeOfDay', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeOfDay();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeOfDay.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeOfDay(od as api.TimeOfDay);
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

  unittest.group('obj-schema-WeekDayOfMonth', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWeekDayOfMonth();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WeekDayOfMonth.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWeekDayOfMonth(od as api.WeekDayOfMonth);
    });
  });

  unittest.group('obj-schema-WeeklySchedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWeeklySchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WeeklySchedule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWeeklySchedule(od as api.WeeklySchedule);
    });
  });

  unittest.group('obj-schema-WindowsUpdateSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWindowsUpdateSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WindowsUpdateSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWindowsUpdateSettings(od as api.WindowsUpdateSettings);
    });
  });

  unittest.group('obj-schema-YumSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildYumSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.YumSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkYumSettings(od as api.YumSettings);
    });
  });

  unittest.group('obj-schema-ZypperSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildZypperSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ZypperSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkZypperSettings(od as api.ZypperSettings);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).operations;
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

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).operations;
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
        var resp = convert.json.encode(buildListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });
  });

  unittest.group('resource-ProjectsPatchDeploymentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchDeployments;
      var arg_request = buildPatchDeployment();
      var arg_parent = 'foo';
      var arg_patchDeploymentId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PatchDeployment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPatchDeployment(obj as api.PatchDeployment);

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
          queryMap["patchDeploymentId"]!.first,
          unittest.equals(arg_patchDeploymentId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPatchDeployment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          patchDeploymentId: arg_patchDeploymentId, $fields: arg_$fields);
      checkPatchDeployment(response as api.PatchDeployment);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchDeployments;
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
      var res = api.OSConfigApi(mock).projects.patchDeployments;
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
        var resp = convert.json.encode(buildPatchDeployment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkPatchDeployment(response as api.PatchDeployment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchDeployments;
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
        var resp = convert.json.encode(buildListPatchDeploymentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPatchDeploymentsResponse(
          response as api.ListPatchDeploymentsResponse);
    });
  });

  unittest.group('resource-ProjectsPatchJobsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchJobs;
      var arg_request = buildCancelPatchJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelPatchJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelPatchJobRequest(obj as api.CancelPatchJobRequest);

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
        var resp = convert.json.encode(buildPatchJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkPatchJob(response as api.PatchJob);
    });

    unittest.test('method--execute', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchJobs;
      var arg_request = buildExecutePatchJobRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExecutePatchJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExecutePatchJobRequest(obj as api.ExecutePatchJobRequest);

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
        var resp = convert.json.encode(buildPatchJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.execute(arg_request, arg_parent, $fields: arg_$fields);
      checkPatchJob(response as api.PatchJob);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchJobs;
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
        var resp = convert.json.encode(buildPatchJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkPatchJob(response as api.PatchJob);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchJobs;
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
        var resp = convert.json.encode(buildListPatchJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPatchJobsResponse(response as api.ListPatchJobsResponse);
    });
  });

  unittest.group('resource-ProjectsPatchJobsInstanceDetailsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.OSConfigApi(mock).projects.patchJobs.instanceDetails;
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
        var resp =
            convert.json.encode(buildListPatchJobInstanceDetailsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPatchJobInstanceDetailsResponse(
          response as api.ListPatchJobInstanceDetailsResponse);
    });
  });
}

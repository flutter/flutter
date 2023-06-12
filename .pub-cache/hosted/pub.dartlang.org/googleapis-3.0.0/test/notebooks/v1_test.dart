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

import 'package:googleapis/notebooks/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAcceleratorConfig = 0;
api.AcceleratorConfig buildAcceleratorConfig() {
  var o = api.AcceleratorConfig();
  buildCounterAcceleratorConfig++;
  if (buildCounterAcceleratorConfig < 3) {
    o.coreCount = 'foo';
    o.type = 'foo';
  }
  buildCounterAcceleratorConfig--;
  return o;
}

void checkAcceleratorConfig(api.AcceleratorConfig o) {
  buildCounterAcceleratorConfig++;
  if (buildCounterAcceleratorConfig < 3) {
    unittest.expect(
      o.coreCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAcceleratorConfig--;
}

core.List<core.String> buildUnnamed5585() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5585(core.List<core.String> o) {
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

core.int buildCounterBinding = 0;
api.Binding buildBinding() {
  var o = api.Binding();
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    o.condition = buildExpr();
    o.members = buildUnnamed5585();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed5585(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterCancelOperationRequest = 0;
api.CancelOperationRequest buildCancelOperationRequest() {
  var o = api.CancelOperationRequest();
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
  return o;
}

void checkCancelOperationRequest(api.CancelOperationRequest o) {
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
}

core.int buildCounterContainerImage = 0;
api.ContainerImage buildContainerImage() {
  var o = api.ContainerImage();
  buildCounterContainerImage++;
  if (buildCounterContainerImage < 3) {
    o.repository = 'foo';
    o.tag = 'foo';
  }
  buildCounterContainerImage--;
  return o;
}

void checkContainerImage(api.ContainerImage o) {
  buildCounterContainerImage++;
  if (buildCounterContainerImage < 3) {
    unittest.expect(
      o.repository!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tag!,
      unittest.equals('foo'),
    );
  }
  buildCounterContainerImage--;
}

core.List<api.GuestOsFeature> buildUnnamed5586() {
  var o = <api.GuestOsFeature>[];
  o.add(buildGuestOsFeature());
  o.add(buildGuestOsFeature());
  return o;
}

void checkUnnamed5586(core.List<api.GuestOsFeature> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGuestOsFeature(o[0] as api.GuestOsFeature);
  checkGuestOsFeature(o[1] as api.GuestOsFeature);
}

core.List<core.String> buildUnnamed5587() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5587(core.List<core.String> o) {
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

core.int buildCounterDisk = 0;
api.Disk buildDisk() {
  var o = api.Disk();
  buildCounterDisk++;
  if (buildCounterDisk < 3) {
    o.autoDelete = true;
    o.boot = true;
    o.deviceName = 'foo';
    o.diskSizeGb = 'foo';
    o.guestOsFeatures = buildUnnamed5586();
    o.index = 'foo';
    o.interface = 'foo';
    o.kind = 'foo';
    o.licenses = buildUnnamed5587();
    o.mode = 'foo';
    o.source = 'foo';
    o.type = 'foo';
  }
  buildCounterDisk--;
  return o;
}

void checkDisk(api.Disk o) {
  buildCounterDisk++;
  if (buildCounterDisk < 3) {
    unittest.expect(o.autoDelete!, unittest.isTrue);
    unittest.expect(o.boot!, unittest.isTrue);
    unittest.expect(
      o.deviceName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.diskSizeGb!,
      unittest.equals('foo'),
    );
    checkUnnamed5586(o.guestOsFeatures!);
    unittest.expect(
      o.index!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.interface!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed5587(o.licenses!);
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.source!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDisk--;
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

core.int buildCounterEncryptionConfig = 0;
api.EncryptionConfig buildEncryptionConfig() {
  var o = api.EncryptionConfig();
  buildCounterEncryptionConfig++;
  if (buildCounterEncryptionConfig < 3) {
    o.kmsKey = 'foo';
  }
  buildCounterEncryptionConfig--;
  return o;
}

void checkEncryptionConfig(api.EncryptionConfig o) {
  buildCounterEncryptionConfig++;
  if (buildCounterEncryptionConfig < 3) {
    unittest.expect(
      o.kmsKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterEncryptionConfig--;
}

core.int buildCounterEnvironment = 0;
api.Environment buildEnvironment() {
  var o = api.Environment();
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    o.containerImage = buildContainerImage();
    o.createTime = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
    o.postStartupScript = 'foo';
    o.vmImage = buildVmImage();
  }
  buildCounterEnvironment--;
  return o;
}

void checkEnvironment(api.Environment o) {
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    checkContainerImage(o.containerImage! as api.ContainerImage);
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
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postStartupScript!,
      unittest.equals('foo'),
    );
    checkVmImage(o.vmImage! as api.VmImage);
  }
  buildCounterEnvironment--;
}

core.int buildCounterExecution = 0;
api.Execution buildExecution() {
  var o = api.Execution();
  buildCounterExecution++;
  if (buildCounterExecution < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.executionTemplate = buildExecutionTemplate();
    o.name = 'foo';
    o.outputNotebookFile = 'foo';
    o.state = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterExecution--;
  return o;
}

void checkExecution(api.Execution o) {
  buildCounterExecution++;
  if (buildCounterExecution < 3) {
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
    checkExecutionTemplate(o.executionTemplate! as api.ExecutionTemplate);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputNotebookFile!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterExecution--;
}

core.Map<core.String, core.String> buildUnnamed5588() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5588(core.Map<core.String, core.String> o) {
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

core.int buildCounterExecutionTemplate = 0;
api.ExecutionTemplate buildExecutionTemplate() {
  var o = api.ExecutionTemplate();
  buildCounterExecutionTemplate++;
  if (buildCounterExecutionTemplate < 3) {
    o.acceleratorConfig = buildSchedulerAcceleratorConfig();
    o.containerImageUri = 'foo';
    o.inputNotebookFile = 'foo';
    o.labels = buildUnnamed5588();
    o.masterType = 'foo';
    o.outputNotebookFolder = 'foo';
    o.parameters = 'foo';
    o.paramsYamlFile = 'foo';
    o.scaleTier = 'foo';
    o.serviceAccount = 'foo';
  }
  buildCounterExecutionTemplate--;
  return o;
}

void checkExecutionTemplate(api.ExecutionTemplate o) {
  buildCounterExecutionTemplate++;
  if (buildCounterExecutionTemplate < 3) {
    checkSchedulerAcceleratorConfig(
        o.acceleratorConfig! as api.SchedulerAcceleratorConfig);
    unittest.expect(
      o.containerImageUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputNotebookFile!,
      unittest.equals('foo'),
    );
    checkUnnamed5588(o.labels!);
    unittest.expect(
      o.masterType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputNotebookFolder!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parameters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.paramsYamlFile!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scaleTier!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccount!,
      unittest.equals('foo'),
    );
  }
  buildCounterExecutionTemplate--;
}

core.int buildCounterExpr = 0;
api.Expr buildExpr() {
  var o = api.Expr();
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    o.description = 'foo';
    o.expression = 'foo';
    o.location = 'foo';
    o.title = 'foo';
  }
  buildCounterExpr--;
  return o;
}

void checkExpr(api.Expr o) {
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterExpr--;
}

core.Map<core.String, core.String> buildUnnamed5589() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5589(core.Map<core.String, core.String> o) {
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

core.int buildCounterGetInstanceHealthResponse = 0;
api.GetInstanceHealthResponse buildGetInstanceHealthResponse() {
  var o = api.GetInstanceHealthResponse();
  buildCounterGetInstanceHealthResponse++;
  if (buildCounterGetInstanceHealthResponse < 3) {
    o.healthInfo = buildUnnamed5589();
    o.healthState = 'foo';
  }
  buildCounterGetInstanceHealthResponse--;
  return o;
}

void checkGetInstanceHealthResponse(api.GetInstanceHealthResponse o) {
  buildCounterGetInstanceHealthResponse++;
  if (buildCounterGetInstanceHealthResponse < 3) {
    checkUnnamed5589(o.healthInfo!);
    unittest.expect(
      o.healthState!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetInstanceHealthResponse--;
}

core.int buildCounterGuestOsFeature = 0;
api.GuestOsFeature buildGuestOsFeature() {
  var o = api.GuestOsFeature();
  buildCounterGuestOsFeature++;
  if (buildCounterGuestOsFeature < 3) {
    o.type = 'foo';
  }
  buildCounterGuestOsFeature--;
  return o;
}

void checkGuestOsFeature(api.GuestOsFeature o) {
  buildCounterGuestOsFeature++;
  if (buildCounterGuestOsFeature < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterGuestOsFeature--;
}

core.List<api.Disk> buildUnnamed5590() {
  var o = <api.Disk>[];
  o.add(buildDisk());
  o.add(buildDisk());
  return o;
}

void checkUnnamed5590(core.List<api.Disk> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDisk(o[0] as api.Disk);
  checkDisk(o[1] as api.Disk);
}

core.List<core.String> buildUnnamed5591() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5591(core.List<core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed5592() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5592(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed5593() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5593(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed5594() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5594(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5595() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5595(core.List<core.String> o) {
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

core.List<api.UpgradeHistoryEntry> buildUnnamed5596() {
  var o = <api.UpgradeHistoryEntry>[];
  o.add(buildUpgradeHistoryEntry());
  o.add(buildUpgradeHistoryEntry());
  return o;
}

void checkUnnamed5596(core.List<api.UpgradeHistoryEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUpgradeHistoryEntry(o[0] as api.UpgradeHistoryEntry);
  checkUpgradeHistoryEntry(o[1] as api.UpgradeHistoryEntry);
}

core.int buildCounterInstance = 0;
api.Instance buildInstance() {
  var o = api.Instance();
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    o.acceleratorConfig = buildAcceleratorConfig();
    o.bootDiskSizeGb = 'foo';
    o.bootDiskType = 'foo';
    o.containerImage = buildContainerImage();
    o.createTime = 'foo';
    o.customGpuDriverPath = 'foo';
    o.dataDiskSizeGb = 'foo';
    o.dataDiskType = 'foo';
    o.diskEncryption = 'foo';
    o.disks = buildUnnamed5590();
    o.installGpuDriver = true;
    o.instanceOwners = buildUnnamed5591();
    o.kmsKey = 'foo';
    o.labels = buildUnnamed5592();
    o.machineType = 'foo';
    o.metadata = buildUnnamed5593();
    o.name = 'foo';
    o.network = 'foo';
    o.nicType = 'foo';
    o.noProxyAccess = true;
    o.noPublicIp = true;
    o.noRemoveDataDisk = true;
    o.postStartupScript = 'foo';
    o.proxyUri = 'foo';
    o.serviceAccount = 'foo';
    o.serviceAccountScopes = buildUnnamed5594();
    o.shieldedInstanceConfig = buildShieldedInstanceConfig();
    o.state = 'foo';
    o.subnet = 'foo';
    o.tags = buildUnnamed5595();
    o.updateTime = 'foo';
    o.upgradeHistory = buildUnnamed5596();
    o.vmImage = buildVmImage();
  }
  buildCounterInstance--;
  return o;
}

void checkInstance(api.Instance o) {
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    checkAcceleratorConfig(o.acceleratorConfig! as api.AcceleratorConfig);
    unittest.expect(
      o.bootDiskSizeGb!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bootDiskType!,
      unittest.equals('foo'),
    );
    checkContainerImage(o.containerImage! as api.ContainerImage);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customGpuDriverPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataDiskSizeGb!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataDiskType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.diskEncryption!,
      unittest.equals('foo'),
    );
    checkUnnamed5590(o.disks!);
    unittest.expect(o.installGpuDriver!, unittest.isTrue);
    checkUnnamed5591(o.instanceOwners!);
    unittest.expect(
      o.kmsKey!,
      unittest.equals('foo'),
    );
    checkUnnamed5592(o.labels!);
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
    checkUnnamed5593(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.network!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nicType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.noProxyAccess!, unittest.isTrue);
    unittest.expect(o.noPublicIp!, unittest.isTrue);
    unittest.expect(o.noRemoveDataDisk!, unittest.isTrue);
    unittest.expect(
      o.postStartupScript!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proxyUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccount!,
      unittest.equals('foo'),
    );
    checkUnnamed5594(o.serviceAccountScopes!);
    checkShieldedInstanceConfig(
        o.shieldedInstanceConfig! as api.ShieldedInstanceConfig);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subnet!,
      unittest.equals('foo'),
    );
    checkUnnamed5595(o.tags!);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    checkUnnamed5596(o.upgradeHistory!);
    checkVmImage(o.vmImage! as api.VmImage);
  }
  buildCounterInstance--;
}

core.int buildCounterIsInstanceUpgradeableResponse = 0;
api.IsInstanceUpgradeableResponse buildIsInstanceUpgradeableResponse() {
  var o = api.IsInstanceUpgradeableResponse();
  buildCounterIsInstanceUpgradeableResponse++;
  if (buildCounterIsInstanceUpgradeableResponse < 3) {
    o.upgradeImage = 'foo';
    o.upgradeInfo = 'foo';
    o.upgradeVersion = 'foo';
    o.upgradeable = true;
  }
  buildCounterIsInstanceUpgradeableResponse--;
  return o;
}

void checkIsInstanceUpgradeableResponse(api.IsInstanceUpgradeableResponse o) {
  buildCounterIsInstanceUpgradeableResponse++;
  if (buildCounterIsInstanceUpgradeableResponse < 3) {
    unittest.expect(
      o.upgradeImage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.upgradeInfo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.upgradeVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(o.upgradeable!, unittest.isTrue);
  }
  buildCounterIsInstanceUpgradeableResponse--;
}

core.List<api.Environment> buildUnnamed5597() {
  var o = <api.Environment>[];
  o.add(buildEnvironment());
  o.add(buildEnvironment());
  return o;
}

void checkUnnamed5597(core.List<api.Environment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEnvironment(o[0] as api.Environment);
  checkEnvironment(o[1] as api.Environment);
}

core.List<core.String> buildUnnamed5598() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5598(core.List<core.String> o) {
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

core.int buildCounterListEnvironmentsResponse = 0;
api.ListEnvironmentsResponse buildListEnvironmentsResponse() {
  var o = api.ListEnvironmentsResponse();
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    o.environments = buildUnnamed5597();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed5598();
  }
  buildCounterListEnvironmentsResponse--;
  return o;
}

void checkListEnvironmentsResponse(api.ListEnvironmentsResponse o) {
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    checkUnnamed5597(o.environments!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5598(o.unreachable!);
  }
  buildCounterListEnvironmentsResponse--;
}

core.List<api.Execution> buildUnnamed5599() {
  var o = <api.Execution>[];
  o.add(buildExecution());
  o.add(buildExecution());
  return o;
}

void checkUnnamed5599(core.List<api.Execution> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExecution(o[0] as api.Execution);
  checkExecution(o[1] as api.Execution);
}

core.List<core.String> buildUnnamed5600() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5600(core.List<core.String> o) {
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

core.int buildCounterListExecutionsResponse = 0;
api.ListExecutionsResponse buildListExecutionsResponse() {
  var o = api.ListExecutionsResponse();
  buildCounterListExecutionsResponse++;
  if (buildCounterListExecutionsResponse < 3) {
    o.executions = buildUnnamed5599();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed5600();
  }
  buildCounterListExecutionsResponse--;
  return o;
}

void checkListExecutionsResponse(api.ListExecutionsResponse o) {
  buildCounterListExecutionsResponse++;
  if (buildCounterListExecutionsResponse < 3) {
    checkUnnamed5599(o.executions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5600(o.unreachable!);
  }
  buildCounterListExecutionsResponse--;
}

core.List<api.Instance> buildUnnamed5601() {
  var o = <api.Instance>[];
  o.add(buildInstance());
  o.add(buildInstance());
  return o;
}

void checkUnnamed5601(core.List<api.Instance> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInstance(o[0] as api.Instance);
  checkInstance(o[1] as api.Instance);
}

core.List<core.String> buildUnnamed5602() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5602(core.List<core.String> o) {
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

core.int buildCounterListInstancesResponse = 0;
api.ListInstancesResponse buildListInstancesResponse() {
  var o = api.ListInstancesResponse();
  buildCounterListInstancesResponse++;
  if (buildCounterListInstancesResponse < 3) {
    o.instances = buildUnnamed5601();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed5602();
  }
  buildCounterListInstancesResponse--;
  return o;
}

void checkListInstancesResponse(api.ListInstancesResponse o) {
  buildCounterListInstancesResponse++;
  if (buildCounterListInstancesResponse < 3) {
    checkUnnamed5601(o.instances!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5602(o.unreachable!);
  }
  buildCounterListInstancesResponse--;
}

core.List<api.Location> buildUnnamed5603() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed5603(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed5603();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed5603(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.Operation> buildUnnamed5604() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed5604(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed5604();
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
    checkUnnamed5604(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.Runtime> buildUnnamed5605() {
  var o = <api.Runtime>[];
  o.add(buildRuntime());
  o.add(buildRuntime());
  return o;
}

void checkUnnamed5605(core.List<api.Runtime> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRuntime(o[0] as api.Runtime);
  checkRuntime(o[1] as api.Runtime);
}

core.List<core.String> buildUnnamed5606() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5606(core.List<core.String> o) {
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

core.int buildCounterListRuntimesResponse = 0;
api.ListRuntimesResponse buildListRuntimesResponse() {
  var o = api.ListRuntimesResponse();
  buildCounterListRuntimesResponse++;
  if (buildCounterListRuntimesResponse < 3) {
    o.nextPageToken = 'foo';
    o.runtimes = buildUnnamed5605();
    o.unreachable = buildUnnamed5606();
  }
  buildCounterListRuntimesResponse--;
  return o;
}

void checkListRuntimesResponse(api.ListRuntimesResponse o) {
  buildCounterListRuntimesResponse++;
  if (buildCounterListRuntimesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5605(o.runtimes!);
    checkUnnamed5606(o.unreachable!);
  }
  buildCounterListRuntimesResponse--;
}

core.List<api.Schedule> buildUnnamed5607() {
  var o = <api.Schedule>[];
  o.add(buildSchedule());
  o.add(buildSchedule());
  return o;
}

void checkUnnamed5607(core.List<api.Schedule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSchedule(o[0] as api.Schedule);
  checkSchedule(o[1] as api.Schedule);
}

core.List<core.String> buildUnnamed5608() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5608(core.List<core.String> o) {
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

core.int buildCounterListSchedulesResponse = 0;
api.ListSchedulesResponse buildListSchedulesResponse() {
  var o = api.ListSchedulesResponse();
  buildCounterListSchedulesResponse++;
  if (buildCounterListSchedulesResponse < 3) {
    o.nextPageToken = 'foo';
    o.schedules = buildUnnamed5607();
    o.unreachable = buildUnnamed5608();
  }
  buildCounterListSchedulesResponse--;
  return o;
}

void checkListSchedulesResponse(api.ListSchedulesResponse o) {
  buildCounterListSchedulesResponse++;
  if (buildCounterListSchedulesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5607(o.schedules!);
    checkUnnamed5608(o.unreachable!);
  }
  buildCounterListSchedulesResponse--;
}

core.List<api.RuntimeGuestOsFeature> buildUnnamed5609() {
  var o = <api.RuntimeGuestOsFeature>[];
  o.add(buildRuntimeGuestOsFeature());
  o.add(buildRuntimeGuestOsFeature());
  return o;
}

void checkUnnamed5609(core.List<api.RuntimeGuestOsFeature> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRuntimeGuestOsFeature(o[0] as api.RuntimeGuestOsFeature);
  checkRuntimeGuestOsFeature(o[1] as api.RuntimeGuestOsFeature);
}

core.List<core.String> buildUnnamed5610() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5610(core.List<core.String> o) {
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

core.int buildCounterLocalDisk = 0;
api.LocalDisk buildLocalDisk() {
  var o = api.LocalDisk();
  buildCounterLocalDisk++;
  if (buildCounterLocalDisk < 3) {
    o.autoDelete = true;
    o.boot = true;
    o.deviceName = 'foo';
    o.guestOsFeatures = buildUnnamed5609();
    o.index = 42;
    o.initializeParams = buildLocalDiskInitializeParams();
    o.interface = 'foo';
    o.kind = 'foo';
    o.licenses = buildUnnamed5610();
    o.mode = 'foo';
    o.source = 'foo';
    o.type = 'foo';
  }
  buildCounterLocalDisk--;
  return o;
}

void checkLocalDisk(api.LocalDisk o) {
  buildCounterLocalDisk++;
  if (buildCounterLocalDisk < 3) {
    unittest.expect(o.autoDelete!, unittest.isTrue);
    unittest.expect(o.boot!, unittest.isTrue);
    unittest.expect(
      o.deviceName!,
      unittest.equals('foo'),
    );
    checkUnnamed5609(o.guestOsFeatures!);
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    checkLocalDiskInitializeParams(
        o.initializeParams! as api.LocalDiskInitializeParams);
    unittest.expect(
      o.interface!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed5610(o.licenses!);
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.source!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocalDisk--;
}

core.Map<core.String, core.String> buildUnnamed5611() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5611(core.Map<core.String, core.String> o) {
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

core.int buildCounterLocalDiskInitializeParams = 0;
api.LocalDiskInitializeParams buildLocalDiskInitializeParams() {
  var o = api.LocalDiskInitializeParams();
  buildCounterLocalDiskInitializeParams++;
  if (buildCounterLocalDiskInitializeParams < 3) {
    o.description = 'foo';
    o.diskName = 'foo';
    o.diskSizeGb = 'foo';
    o.diskType = 'foo';
    o.labels = buildUnnamed5611();
  }
  buildCounterLocalDiskInitializeParams--;
  return o;
}

void checkLocalDiskInitializeParams(api.LocalDiskInitializeParams o) {
  buildCounterLocalDiskInitializeParams++;
  if (buildCounterLocalDiskInitializeParams < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.diskName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.diskSizeGb!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.diskType!,
      unittest.equals('foo'),
    );
    checkUnnamed5611(o.labels!);
  }
  buildCounterLocalDiskInitializeParams--;
}

core.Map<core.String, core.String> buildUnnamed5612() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5612(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed5613() {
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

void checkUnnamed5613(core.Map<core.String, core.Object> o) {
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

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.displayName = 'foo';
    o.labels = buildUnnamed5612();
    o.locationId = 'foo';
    o.metadata = buildUnnamed5613();
    o.name = 'foo';
  }
  buildCounterLocation--;
  return o;
}

void checkLocation(api.Location o) {
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed5612(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed5613(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.Map<core.String, core.Object> buildUnnamed5614() {
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

void checkUnnamed5614(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed5615() {
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

void checkUnnamed5615(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed5614();
    o.name = 'foo';
    o.response = buildUnnamed5615();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed5614(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5615(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOperationMetadata = 0;
api.OperationMetadata buildOperationMetadata() {
  var o = api.OperationMetadata();
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    o.apiVersion = 'foo';
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.endpoint = 'foo';
    o.requestedCancellation = true;
    o.statusMessage = 'foo';
    o.target = 'foo';
    o.verb = 'foo';
  }
  buildCounterOperationMetadata--;
  return o;
}

void checkOperationMetadata(api.OperationMetadata o) {
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    unittest.expect(
      o.apiVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endpoint!,
      unittest.equals('foo'),
    );
    unittest.expect(o.requestedCancellation!, unittest.isTrue);
    unittest.expect(
      o.statusMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verb!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationMetadata--;
}

core.List<api.Binding> buildUnnamed5616() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed5616(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.bindings = buildUnnamed5616();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed5616(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterPolicy--;
}

core.int buildCounterRegisterInstanceRequest = 0;
api.RegisterInstanceRequest buildRegisterInstanceRequest() {
  var o = api.RegisterInstanceRequest();
  buildCounterRegisterInstanceRequest++;
  if (buildCounterRegisterInstanceRequest < 3) {
    o.instanceId = 'foo';
  }
  buildCounterRegisterInstanceRequest--;
  return o;
}

void checkRegisterInstanceRequest(api.RegisterInstanceRequest o) {
  buildCounterRegisterInstanceRequest++;
  if (buildCounterRegisterInstanceRequest < 3) {
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRegisterInstanceRequest--;
}

core.Map<core.String, core.String> buildUnnamed5617() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5617(core.Map<core.String, core.String> o) {
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

core.int buildCounterReportInstanceInfoRequest = 0;
api.ReportInstanceInfoRequest buildReportInstanceInfoRequest() {
  var o = api.ReportInstanceInfoRequest();
  buildCounterReportInstanceInfoRequest++;
  if (buildCounterReportInstanceInfoRequest < 3) {
    o.metadata = buildUnnamed5617();
    o.vmId = 'foo';
  }
  buildCounterReportInstanceInfoRequest--;
  return o;
}

void checkReportInstanceInfoRequest(api.ReportInstanceInfoRequest o) {
  buildCounterReportInstanceInfoRequest++;
  if (buildCounterReportInstanceInfoRequest < 3) {
    checkUnnamed5617(o.metadata!);
    unittest.expect(
      o.vmId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportInstanceInfoRequest--;
}

core.int buildCounterResetInstanceRequest = 0;
api.ResetInstanceRequest buildResetInstanceRequest() {
  var o = api.ResetInstanceRequest();
  buildCounterResetInstanceRequest++;
  if (buildCounterResetInstanceRequest < 3) {}
  buildCounterResetInstanceRequest--;
  return o;
}

void checkResetInstanceRequest(api.ResetInstanceRequest o) {
  buildCounterResetInstanceRequest++;
  if (buildCounterResetInstanceRequest < 3) {}
  buildCounterResetInstanceRequest--;
}

core.int buildCounterResetRuntimeRequest = 0;
api.ResetRuntimeRequest buildResetRuntimeRequest() {
  var o = api.ResetRuntimeRequest();
  buildCounterResetRuntimeRequest++;
  if (buildCounterResetRuntimeRequest < 3) {}
  buildCounterResetRuntimeRequest--;
  return o;
}

void checkResetRuntimeRequest(api.ResetRuntimeRequest o) {
  buildCounterResetRuntimeRequest++;
  if (buildCounterResetRuntimeRequest < 3) {}
  buildCounterResetRuntimeRequest--;
}

core.int buildCounterRollbackInstanceRequest = 0;
api.RollbackInstanceRequest buildRollbackInstanceRequest() {
  var o = api.RollbackInstanceRequest();
  buildCounterRollbackInstanceRequest++;
  if (buildCounterRollbackInstanceRequest < 3) {
    o.targetSnapshot = 'foo';
  }
  buildCounterRollbackInstanceRequest--;
  return o;
}

void checkRollbackInstanceRequest(api.RollbackInstanceRequest o) {
  buildCounterRollbackInstanceRequest++;
  if (buildCounterRollbackInstanceRequest < 3) {
    unittest.expect(
      o.targetSnapshot!,
      unittest.equals('foo'),
    );
  }
  buildCounterRollbackInstanceRequest--;
}

core.int buildCounterRuntime = 0;
api.Runtime buildRuntime() {
  var o = api.Runtime();
  buildCounterRuntime++;
  if (buildCounterRuntime < 3) {
    o.accessConfig = buildRuntimeAccessConfig();
    o.createTime = 'foo';
    o.healthState = 'foo';
    o.metrics = buildRuntimeMetrics();
    o.name = 'foo';
    o.softwareConfig = buildRuntimeSoftwareConfig();
    o.state = 'foo';
    o.updateTime = 'foo';
    o.virtualMachine = buildVirtualMachine();
  }
  buildCounterRuntime--;
  return o;
}

void checkRuntime(api.Runtime o) {
  buildCounterRuntime++;
  if (buildCounterRuntime < 3) {
    checkRuntimeAccessConfig(o.accessConfig! as api.RuntimeAccessConfig);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.healthState!,
      unittest.equals('foo'),
    );
    checkRuntimeMetrics(o.metrics! as api.RuntimeMetrics);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkRuntimeSoftwareConfig(o.softwareConfig! as api.RuntimeSoftwareConfig);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    checkVirtualMachine(o.virtualMachine! as api.VirtualMachine);
  }
  buildCounterRuntime--;
}

core.int buildCounterRuntimeAcceleratorConfig = 0;
api.RuntimeAcceleratorConfig buildRuntimeAcceleratorConfig() {
  var o = api.RuntimeAcceleratorConfig();
  buildCounterRuntimeAcceleratorConfig++;
  if (buildCounterRuntimeAcceleratorConfig < 3) {
    o.coreCount = 'foo';
    o.type = 'foo';
  }
  buildCounterRuntimeAcceleratorConfig--;
  return o;
}

void checkRuntimeAcceleratorConfig(api.RuntimeAcceleratorConfig o) {
  buildCounterRuntimeAcceleratorConfig++;
  if (buildCounterRuntimeAcceleratorConfig < 3) {
    unittest.expect(
      o.coreCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterRuntimeAcceleratorConfig--;
}

core.int buildCounterRuntimeAccessConfig = 0;
api.RuntimeAccessConfig buildRuntimeAccessConfig() {
  var o = api.RuntimeAccessConfig();
  buildCounterRuntimeAccessConfig++;
  if (buildCounterRuntimeAccessConfig < 3) {
    o.accessType = 'foo';
    o.proxyUri = 'foo';
    o.runtimeOwner = 'foo';
  }
  buildCounterRuntimeAccessConfig--;
  return o;
}

void checkRuntimeAccessConfig(api.RuntimeAccessConfig o) {
  buildCounterRuntimeAccessConfig++;
  if (buildCounterRuntimeAccessConfig < 3) {
    unittest.expect(
      o.accessType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proxyUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.runtimeOwner!,
      unittest.equals('foo'),
    );
  }
  buildCounterRuntimeAccessConfig--;
}

core.int buildCounterRuntimeGuestOsFeature = 0;
api.RuntimeGuestOsFeature buildRuntimeGuestOsFeature() {
  var o = api.RuntimeGuestOsFeature();
  buildCounterRuntimeGuestOsFeature++;
  if (buildCounterRuntimeGuestOsFeature < 3) {
    o.type = 'foo';
  }
  buildCounterRuntimeGuestOsFeature--;
  return o;
}

void checkRuntimeGuestOsFeature(api.RuntimeGuestOsFeature o) {
  buildCounterRuntimeGuestOsFeature++;
  if (buildCounterRuntimeGuestOsFeature < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterRuntimeGuestOsFeature--;
}

core.Map<core.String, core.String> buildUnnamed5618() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5618(core.Map<core.String, core.String> o) {
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

core.int buildCounterRuntimeMetrics = 0;
api.RuntimeMetrics buildRuntimeMetrics() {
  var o = api.RuntimeMetrics();
  buildCounterRuntimeMetrics++;
  if (buildCounterRuntimeMetrics < 3) {
    o.systemMetrics = buildUnnamed5618();
  }
  buildCounterRuntimeMetrics--;
  return o;
}

void checkRuntimeMetrics(api.RuntimeMetrics o) {
  buildCounterRuntimeMetrics++;
  if (buildCounterRuntimeMetrics < 3) {
    checkUnnamed5618(o.systemMetrics!);
  }
  buildCounterRuntimeMetrics--;
}

core.int buildCounterRuntimeShieldedInstanceConfig = 0;
api.RuntimeShieldedInstanceConfig buildRuntimeShieldedInstanceConfig() {
  var o = api.RuntimeShieldedInstanceConfig();
  buildCounterRuntimeShieldedInstanceConfig++;
  if (buildCounterRuntimeShieldedInstanceConfig < 3) {
    o.enableIntegrityMonitoring = true;
    o.enableSecureBoot = true;
    o.enableVtpm = true;
  }
  buildCounterRuntimeShieldedInstanceConfig--;
  return o;
}

void checkRuntimeShieldedInstanceConfig(api.RuntimeShieldedInstanceConfig o) {
  buildCounterRuntimeShieldedInstanceConfig++;
  if (buildCounterRuntimeShieldedInstanceConfig < 3) {
    unittest.expect(o.enableIntegrityMonitoring!, unittest.isTrue);
    unittest.expect(o.enableSecureBoot!, unittest.isTrue);
    unittest.expect(o.enableVtpm!, unittest.isTrue);
  }
  buildCounterRuntimeShieldedInstanceConfig--;
}

core.int buildCounterRuntimeSoftwareConfig = 0;
api.RuntimeSoftwareConfig buildRuntimeSoftwareConfig() {
  var o = api.RuntimeSoftwareConfig();
  buildCounterRuntimeSoftwareConfig++;
  if (buildCounterRuntimeSoftwareConfig < 3) {
    o.customGpuDriverPath = 'foo';
    o.enableHealthMonitoring = true;
    o.idleShutdown = true;
    o.idleShutdownTimeout = 42;
    o.installGpuDriver = true;
    o.notebookUpgradeSchedule = 'foo';
    o.postStartupScript = 'foo';
  }
  buildCounterRuntimeSoftwareConfig--;
  return o;
}

void checkRuntimeSoftwareConfig(api.RuntimeSoftwareConfig o) {
  buildCounterRuntimeSoftwareConfig++;
  if (buildCounterRuntimeSoftwareConfig < 3) {
    unittest.expect(
      o.customGpuDriverPath!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableHealthMonitoring!, unittest.isTrue);
    unittest.expect(o.idleShutdown!, unittest.isTrue);
    unittest.expect(
      o.idleShutdownTimeout!,
      unittest.equals(42),
    );
    unittest.expect(o.installGpuDriver!, unittest.isTrue);
    unittest.expect(
      o.notebookUpgradeSchedule!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postStartupScript!,
      unittest.equals('foo'),
    );
  }
  buildCounterRuntimeSoftwareConfig--;
}

core.List<api.Execution> buildUnnamed5619() {
  var o = <api.Execution>[];
  o.add(buildExecution());
  o.add(buildExecution());
  return o;
}

void checkUnnamed5619(core.List<api.Execution> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExecution(o[0] as api.Execution);
  checkExecution(o[1] as api.Execution);
}

core.int buildCounterSchedule = 0;
api.Schedule buildSchedule() {
  var o = api.Schedule();
  buildCounterSchedule++;
  if (buildCounterSchedule < 3) {
    o.createTime = 'foo';
    o.cronSchedule = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.executionTemplate = buildExecutionTemplate();
    o.name = 'foo';
    o.recentExecutions = buildUnnamed5619();
    o.state = 'foo';
    o.timeZone = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterSchedule--;
  return o;
}

void checkSchedule(api.Schedule o) {
  buildCounterSchedule++;
  if (buildCounterSchedule < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cronSchedule!,
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
    checkExecutionTemplate(o.executionTemplate! as api.ExecutionTemplate);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5619(o.recentExecutions!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchedule--;
}

core.int buildCounterSchedulerAcceleratorConfig = 0;
api.SchedulerAcceleratorConfig buildSchedulerAcceleratorConfig() {
  var o = api.SchedulerAcceleratorConfig();
  buildCounterSchedulerAcceleratorConfig++;
  if (buildCounterSchedulerAcceleratorConfig < 3) {
    o.coreCount = 'foo';
    o.type = 'foo';
  }
  buildCounterSchedulerAcceleratorConfig--;
  return o;
}

void checkSchedulerAcceleratorConfig(api.SchedulerAcceleratorConfig o) {
  buildCounterSchedulerAcceleratorConfig++;
  if (buildCounterSchedulerAcceleratorConfig < 3) {
    unittest.expect(
      o.coreCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchedulerAcceleratorConfig--;
}

core.int buildCounterSetIamPolicyRequest = 0;
api.SetIamPolicyRequest buildSetIamPolicyRequest() {
  var o = api.SetIamPolicyRequest();
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    o.policy = buildPolicy();
  }
  buildCounterSetIamPolicyRequest--;
  return o;
}

void checkSetIamPolicyRequest(api.SetIamPolicyRequest o) {
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    checkPolicy(o.policy! as api.Policy);
  }
  buildCounterSetIamPolicyRequest--;
}

core.int buildCounterSetInstanceAcceleratorRequest = 0;
api.SetInstanceAcceleratorRequest buildSetInstanceAcceleratorRequest() {
  var o = api.SetInstanceAcceleratorRequest();
  buildCounterSetInstanceAcceleratorRequest++;
  if (buildCounterSetInstanceAcceleratorRequest < 3) {
    o.coreCount = 'foo';
    o.type = 'foo';
  }
  buildCounterSetInstanceAcceleratorRequest--;
  return o;
}

void checkSetInstanceAcceleratorRequest(api.SetInstanceAcceleratorRequest o) {
  buildCounterSetInstanceAcceleratorRequest++;
  if (buildCounterSetInstanceAcceleratorRequest < 3) {
    unittest.expect(
      o.coreCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetInstanceAcceleratorRequest--;
}

core.Map<core.String, core.String> buildUnnamed5620() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5620(core.Map<core.String, core.String> o) {
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

core.int buildCounterSetInstanceLabelsRequest = 0;
api.SetInstanceLabelsRequest buildSetInstanceLabelsRequest() {
  var o = api.SetInstanceLabelsRequest();
  buildCounterSetInstanceLabelsRequest++;
  if (buildCounterSetInstanceLabelsRequest < 3) {
    o.labels = buildUnnamed5620();
  }
  buildCounterSetInstanceLabelsRequest--;
  return o;
}

void checkSetInstanceLabelsRequest(api.SetInstanceLabelsRequest o) {
  buildCounterSetInstanceLabelsRequest++;
  if (buildCounterSetInstanceLabelsRequest < 3) {
    checkUnnamed5620(o.labels!);
  }
  buildCounterSetInstanceLabelsRequest--;
}

core.int buildCounterSetInstanceMachineTypeRequest = 0;
api.SetInstanceMachineTypeRequest buildSetInstanceMachineTypeRequest() {
  var o = api.SetInstanceMachineTypeRequest();
  buildCounterSetInstanceMachineTypeRequest++;
  if (buildCounterSetInstanceMachineTypeRequest < 3) {
    o.machineType = 'foo';
  }
  buildCounterSetInstanceMachineTypeRequest--;
  return o;
}

void checkSetInstanceMachineTypeRequest(api.SetInstanceMachineTypeRequest o) {
  buildCounterSetInstanceMachineTypeRequest++;
  if (buildCounterSetInstanceMachineTypeRequest < 3) {
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetInstanceMachineTypeRequest--;
}

core.int buildCounterShieldedInstanceConfig = 0;
api.ShieldedInstanceConfig buildShieldedInstanceConfig() {
  var o = api.ShieldedInstanceConfig();
  buildCounterShieldedInstanceConfig++;
  if (buildCounterShieldedInstanceConfig < 3) {
    o.enableIntegrityMonitoring = true;
    o.enableSecureBoot = true;
    o.enableVtpm = true;
  }
  buildCounterShieldedInstanceConfig--;
  return o;
}

void checkShieldedInstanceConfig(api.ShieldedInstanceConfig o) {
  buildCounterShieldedInstanceConfig++;
  if (buildCounterShieldedInstanceConfig < 3) {
    unittest.expect(o.enableIntegrityMonitoring!, unittest.isTrue);
    unittest.expect(o.enableSecureBoot!, unittest.isTrue);
    unittest.expect(o.enableVtpm!, unittest.isTrue);
  }
  buildCounterShieldedInstanceConfig--;
}

core.int buildCounterStartInstanceRequest = 0;
api.StartInstanceRequest buildStartInstanceRequest() {
  var o = api.StartInstanceRequest();
  buildCounterStartInstanceRequest++;
  if (buildCounterStartInstanceRequest < 3) {}
  buildCounterStartInstanceRequest--;
  return o;
}

void checkStartInstanceRequest(api.StartInstanceRequest o) {
  buildCounterStartInstanceRequest++;
  if (buildCounterStartInstanceRequest < 3) {}
  buildCounterStartInstanceRequest--;
}

core.int buildCounterStartRuntimeRequest = 0;
api.StartRuntimeRequest buildStartRuntimeRequest() {
  var o = api.StartRuntimeRequest();
  buildCounterStartRuntimeRequest++;
  if (buildCounterStartRuntimeRequest < 3) {}
  buildCounterStartRuntimeRequest--;
  return o;
}

void checkStartRuntimeRequest(api.StartRuntimeRequest o) {
  buildCounterStartRuntimeRequest++;
  if (buildCounterStartRuntimeRequest < 3) {}
  buildCounterStartRuntimeRequest--;
}

core.Map<core.String, core.Object> buildUnnamed5621() {
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

void checkUnnamed5621(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted7 = (o['x']!) as core.Map;
  unittest.expect(casted7, unittest.hasLength(3));
  unittest.expect(
    casted7['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted7['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted7['string'],
    unittest.equals('foo'),
  );
  var casted8 = (o['y']!) as core.Map;
  unittest.expect(casted8, unittest.hasLength(3));
  unittest.expect(
    casted8['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted8['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted8['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed5622() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed5621());
  o.add(buildUnnamed5621());
  return o;
}

void checkUnnamed5622(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5621(o[0]);
  checkUnnamed5621(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed5622();
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
    checkUnnamed5622(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterStopInstanceRequest = 0;
api.StopInstanceRequest buildStopInstanceRequest() {
  var o = api.StopInstanceRequest();
  buildCounterStopInstanceRequest++;
  if (buildCounterStopInstanceRequest < 3) {}
  buildCounterStopInstanceRequest--;
  return o;
}

void checkStopInstanceRequest(api.StopInstanceRequest o) {
  buildCounterStopInstanceRequest++;
  if (buildCounterStopInstanceRequest < 3) {}
  buildCounterStopInstanceRequest--;
}

core.int buildCounterStopRuntimeRequest = 0;
api.StopRuntimeRequest buildStopRuntimeRequest() {
  var o = api.StopRuntimeRequest();
  buildCounterStopRuntimeRequest++;
  if (buildCounterStopRuntimeRequest < 3) {}
  buildCounterStopRuntimeRequest--;
  return o;
}

void checkStopRuntimeRequest(api.StopRuntimeRequest o) {
  buildCounterStopRuntimeRequest++;
  if (buildCounterStopRuntimeRequest < 3) {}
  buildCounterStopRuntimeRequest--;
}

core.int buildCounterSwitchRuntimeRequest = 0;
api.SwitchRuntimeRequest buildSwitchRuntimeRequest() {
  var o = api.SwitchRuntimeRequest();
  buildCounterSwitchRuntimeRequest++;
  if (buildCounterSwitchRuntimeRequest < 3) {
    o.acceleratorConfig = buildRuntimeAcceleratorConfig();
    o.machineType = 'foo';
  }
  buildCounterSwitchRuntimeRequest--;
  return o;
}

void checkSwitchRuntimeRequest(api.SwitchRuntimeRequest o) {
  buildCounterSwitchRuntimeRequest++;
  if (buildCounterSwitchRuntimeRequest < 3) {
    checkRuntimeAcceleratorConfig(
        o.acceleratorConfig! as api.RuntimeAcceleratorConfig);
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
  }
  buildCounterSwitchRuntimeRequest--;
}

core.List<core.String> buildUnnamed5623() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5623(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsRequest = 0;
api.TestIamPermissionsRequest buildTestIamPermissionsRequest() {
  var o = api.TestIamPermissionsRequest();
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    o.permissions = buildUnnamed5623();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed5623(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed5624() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5624(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsResponse = 0;
api.TestIamPermissionsResponse buildTestIamPermissionsResponse() {
  var o = api.TestIamPermissionsResponse();
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    o.permissions = buildUnnamed5624();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed5624(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterTriggerScheduleRequest = 0;
api.TriggerScheduleRequest buildTriggerScheduleRequest() {
  var o = api.TriggerScheduleRequest();
  buildCounterTriggerScheduleRequest++;
  if (buildCounterTriggerScheduleRequest < 3) {}
  buildCounterTriggerScheduleRequest--;
  return o;
}

void checkTriggerScheduleRequest(api.TriggerScheduleRequest o) {
  buildCounterTriggerScheduleRequest++;
  if (buildCounterTriggerScheduleRequest < 3) {}
  buildCounterTriggerScheduleRequest--;
}

core.int buildCounterUpdateShieldedInstanceConfigRequest = 0;
api.UpdateShieldedInstanceConfigRequest
    buildUpdateShieldedInstanceConfigRequest() {
  var o = api.UpdateShieldedInstanceConfigRequest();
  buildCounterUpdateShieldedInstanceConfigRequest++;
  if (buildCounterUpdateShieldedInstanceConfigRequest < 3) {
    o.shieldedInstanceConfig = buildShieldedInstanceConfig();
  }
  buildCounterUpdateShieldedInstanceConfigRequest--;
  return o;
}

void checkUpdateShieldedInstanceConfigRequest(
    api.UpdateShieldedInstanceConfigRequest o) {
  buildCounterUpdateShieldedInstanceConfigRequest++;
  if (buildCounterUpdateShieldedInstanceConfigRequest < 3) {
    checkShieldedInstanceConfig(
        o.shieldedInstanceConfig! as api.ShieldedInstanceConfig);
  }
  buildCounterUpdateShieldedInstanceConfigRequest--;
}

core.int buildCounterUpgradeHistoryEntry = 0;
api.UpgradeHistoryEntry buildUpgradeHistoryEntry() {
  var o = api.UpgradeHistoryEntry();
  buildCounterUpgradeHistoryEntry++;
  if (buildCounterUpgradeHistoryEntry < 3) {
    o.action = 'foo';
    o.containerImage = 'foo';
    o.createTime = 'foo';
    o.framework = 'foo';
    o.snapshot = 'foo';
    o.state = 'foo';
    o.targetImage = 'foo';
    o.targetVersion = 'foo';
    o.version = 'foo';
    o.vmImage = 'foo';
  }
  buildCounterUpgradeHistoryEntry--;
  return o;
}

void checkUpgradeHistoryEntry(api.UpgradeHistoryEntry o) {
  buildCounterUpgradeHistoryEntry++;
  if (buildCounterUpgradeHistoryEntry < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerImage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.framework!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.snapshot!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetImage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmImage!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpgradeHistoryEntry--;
}

core.int buildCounterUpgradeInstanceInternalRequest = 0;
api.UpgradeInstanceInternalRequest buildUpgradeInstanceInternalRequest() {
  var o = api.UpgradeInstanceInternalRequest();
  buildCounterUpgradeInstanceInternalRequest++;
  if (buildCounterUpgradeInstanceInternalRequest < 3) {
    o.vmId = 'foo';
  }
  buildCounterUpgradeInstanceInternalRequest--;
  return o;
}

void checkUpgradeInstanceInternalRequest(api.UpgradeInstanceInternalRequest o) {
  buildCounterUpgradeInstanceInternalRequest++;
  if (buildCounterUpgradeInstanceInternalRequest < 3) {
    unittest.expect(
      o.vmId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpgradeInstanceInternalRequest--;
}

core.int buildCounterUpgradeInstanceRequest = 0;
api.UpgradeInstanceRequest buildUpgradeInstanceRequest() {
  var o = api.UpgradeInstanceRequest();
  buildCounterUpgradeInstanceRequest++;
  if (buildCounterUpgradeInstanceRequest < 3) {}
  buildCounterUpgradeInstanceRequest--;
  return o;
}

void checkUpgradeInstanceRequest(api.UpgradeInstanceRequest o) {
  buildCounterUpgradeInstanceRequest++;
  if (buildCounterUpgradeInstanceRequest < 3) {}
  buildCounterUpgradeInstanceRequest--;
}

core.int buildCounterVirtualMachine = 0;
api.VirtualMachine buildVirtualMachine() {
  var o = api.VirtualMachine();
  buildCounterVirtualMachine++;
  if (buildCounterVirtualMachine < 3) {
    o.instanceId = 'foo';
    o.instanceName = 'foo';
    o.virtualMachineConfig = buildVirtualMachineConfig();
  }
  buildCounterVirtualMachine--;
  return o;
}

void checkVirtualMachine(api.VirtualMachine o) {
  buildCounterVirtualMachine++;
  if (buildCounterVirtualMachine < 3) {
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instanceName!,
      unittest.equals('foo'),
    );
    checkVirtualMachineConfig(
        o.virtualMachineConfig! as api.VirtualMachineConfig);
  }
  buildCounterVirtualMachine--;
}

core.List<api.ContainerImage> buildUnnamed5625() {
  var o = <api.ContainerImage>[];
  o.add(buildContainerImage());
  o.add(buildContainerImage());
  return o;
}

void checkUnnamed5625(core.List<api.ContainerImage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainerImage(o[0] as api.ContainerImage);
  checkContainerImage(o[1] as api.ContainerImage);
}

core.Map<core.String, core.String> buildUnnamed5626() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5626(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed5627() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5627(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed5628() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5628(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed5629() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5629(core.List<core.String> o) {
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

core.int buildCounterVirtualMachineConfig = 0;
api.VirtualMachineConfig buildVirtualMachineConfig() {
  var o = api.VirtualMachineConfig();
  buildCounterVirtualMachineConfig++;
  if (buildCounterVirtualMachineConfig < 3) {
    o.acceleratorConfig = buildRuntimeAcceleratorConfig();
    o.containerImages = buildUnnamed5625();
    o.dataDisk = buildLocalDisk();
    o.encryptionConfig = buildEncryptionConfig();
    o.guestAttributes = buildUnnamed5626();
    o.internalIpOnly = true;
    o.labels = buildUnnamed5627();
    o.machineType = 'foo';
    o.metadata = buildUnnamed5628();
    o.network = 'foo';
    o.nicType = 'foo';
    o.shieldedInstanceConfig = buildRuntimeShieldedInstanceConfig();
    o.subnet = 'foo';
    o.tags = buildUnnamed5629();
    o.zone = 'foo';
  }
  buildCounterVirtualMachineConfig--;
  return o;
}

void checkVirtualMachineConfig(api.VirtualMachineConfig o) {
  buildCounterVirtualMachineConfig++;
  if (buildCounterVirtualMachineConfig < 3) {
    checkRuntimeAcceleratorConfig(
        o.acceleratorConfig! as api.RuntimeAcceleratorConfig);
    checkUnnamed5625(o.containerImages!);
    checkLocalDisk(o.dataDisk! as api.LocalDisk);
    checkEncryptionConfig(o.encryptionConfig! as api.EncryptionConfig);
    checkUnnamed5626(o.guestAttributes!);
    unittest.expect(o.internalIpOnly!, unittest.isTrue);
    checkUnnamed5627(o.labels!);
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
    checkUnnamed5628(o.metadata!);
    unittest.expect(
      o.network!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nicType!,
      unittest.equals('foo'),
    );
    checkRuntimeShieldedInstanceConfig(
        o.shieldedInstanceConfig! as api.RuntimeShieldedInstanceConfig);
    unittest.expect(
      o.subnet!,
      unittest.equals('foo'),
    );
    checkUnnamed5629(o.tags!);
    unittest.expect(
      o.zone!,
      unittest.equals('foo'),
    );
  }
  buildCounterVirtualMachineConfig--;
}

core.int buildCounterVmImage = 0;
api.VmImage buildVmImage() {
  var o = api.VmImage();
  buildCounterVmImage++;
  if (buildCounterVmImage < 3) {
    o.imageFamily = 'foo';
    o.imageName = 'foo';
    o.project = 'foo';
  }
  buildCounterVmImage--;
  return o;
}

void checkVmImage(api.VmImage o) {
  buildCounterVmImage++;
  if (buildCounterVmImage < 3) {
    unittest.expect(
      o.imageFamily!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.imageName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
  }
  buildCounterVmImage--;
}

void main() {
  unittest.group('obj-schema-AcceleratorConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAcceleratorConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AcceleratorConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAcceleratorConfig(od as api.AcceleratorConfig);
    });
  });

  unittest.group('obj-schema-Binding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Binding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBinding(od as api.Binding);
    });
  });

  unittest.group('obj-schema-CancelOperationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelOperationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelOperationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelOperationRequest(od as api.CancelOperationRequest);
    });
  });

  unittest.group('obj-schema-ContainerImage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContainerImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContainerImage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContainerImage(od as api.ContainerImage);
    });
  });

  unittest.group('obj-schema-Disk', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDisk();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Disk.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDisk(od as api.Disk);
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

  unittest.group('obj-schema-EncryptionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEncryptionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EncryptionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEncryptionConfig(od as api.EncryptionConfig);
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

  unittest.group('obj-schema-Execution', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Execution.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExecution(od as api.Execution);
    });
  });

  unittest.group('obj-schema-ExecutionTemplate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecutionTemplate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecutionTemplate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecutionTemplate(od as api.ExecutionTemplate);
    });
  });

  unittest.group('obj-schema-Expr', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpr();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Expr.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExpr(od as api.Expr);
    });
  });

  unittest.group('obj-schema-GetInstanceHealthResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetInstanceHealthResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetInstanceHealthResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetInstanceHealthResponse(od as api.GetInstanceHealthResponse);
    });
  });

  unittest.group('obj-schema-GuestOsFeature', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGuestOsFeature();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GuestOsFeature.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGuestOsFeature(od as api.GuestOsFeature);
    });
  });

  unittest.group('obj-schema-Instance', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstance();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Instance.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInstance(od as api.Instance);
    });
  });

  unittest.group('obj-schema-IsInstanceUpgradeableResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIsInstanceUpgradeableResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IsInstanceUpgradeableResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIsInstanceUpgradeableResponse(
          od as api.IsInstanceUpgradeableResponse);
    });
  });

  unittest.group('obj-schema-ListEnvironmentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListEnvironmentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListEnvironmentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListEnvironmentsResponse(od as api.ListEnvironmentsResponse);
    });
  });

  unittest.group('obj-schema-ListExecutionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListExecutionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListExecutionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListExecutionsResponse(od as api.ListExecutionsResponse);
    });
  });

  unittest.group('obj-schema-ListInstancesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInstancesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInstancesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInstancesResponse(od as api.ListInstancesResponse);
    });
  });

  unittest.group('obj-schema-ListLocationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLocationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLocationsResponse(od as api.ListLocationsResponse);
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

  unittest.group('obj-schema-ListRuntimesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListRuntimesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListRuntimesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListRuntimesResponse(od as api.ListRuntimesResponse);
    });
  });

  unittest.group('obj-schema-ListSchedulesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSchedulesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSchedulesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSchedulesResponse(od as api.ListSchedulesResponse);
    });
  });

  unittest.group('obj-schema-LocalDisk', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalDisk();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LocalDisk.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocalDisk(od as api.LocalDisk);
    });
  });

  unittest.group('obj-schema-LocalDiskInitializeParams', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalDiskInitializeParams();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocalDiskInitializeParams.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocalDiskInitializeParams(od as api.LocalDiskInitializeParams);
    });
  });

  unittest.group('obj-schema-Location', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Location.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocation(od as api.Location);
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

  unittest.group('obj-schema-OperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationMetadata(od as api.OperationMetadata);
    });
  });

  unittest.group('obj-schema-Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Policy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicy(od as api.Policy);
    });
  });

  unittest.group('obj-schema-RegisterInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegisterInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RegisterInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegisterInstanceRequest(od as api.RegisterInstanceRequest);
    });
  });

  unittest.group('obj-schema-ReportInstanceInfoRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportInstanceInfoRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportInstanceInfoRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportInstanceInfoRequest(od as api.ReportInstanceInfoRequest);
    });
  });

  unittest.group('obj-schema-ResetInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResetInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResetInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResetInstanceRequest(od as api.ResetInstanceRequest);
    });
  });

  unittest.group('obj-schema-ResetRuntimeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResetRuntimeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResetRuntimeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResetRuntimeRequest(od as api.ResetRuntimeRequest);
    });
  });

  unittest.group('obj-schema-RollbackInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRollbackInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RollbackInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRollbackInstanceRequest(od as api.RollbackInstanceRequest);
    });
  });

  unittest.group('obj-schema-Runtime', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntime();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Runtime.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRuntime(od as api.Runtime);
    });
  });

  unittest.group('obj-schema-RuntimeAcceleratorConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntimeAcceleratorConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RuntimeAcceleratorConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRuntimeAcceleratorConfig(od as api.RuntimeAcceleratorConfig);
    });
  });

  unittest.group('obj-schema-RuntimeAccessConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntimeAccessConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RuntimeAccessConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRuntimeAccessConfig(od as api.RuntimeAccessConfig);
    });
  });

  unittest.group('obj-schema-RuntimeGuestOsFeature', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntimeGuestOsFeature();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RuntimeGuestOsFeature.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRuntimeGuestOsFeature(od as api.RuntimeGuestOsFeature);
    });
  });

  unittest.group('obj-schema-RuntimeMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntimeMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RuntimeMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRuntimeMetrics(od as api.RuntimeMetrics);
    });
  });

  unittest.group('obj-schema-RuntimeShieldedInstanceConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntimeShieldedInstanceConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RuntimeShieldedInstanceConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRuntimeShieldedInstanceConfig(
          od as api.RuntimeShieldedInstanceConfig);
    });
  });

  unittest.group('obj-schema-RuntimeSoftwareConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntimeSoftwareConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RuntimeSoftwareConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRuntimeSoftwareConfig(od as api.RuntimeSoftwareConfig);
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

  unittest.group('obj-schema-SchedulerAcceleratorConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchedulerAcceleratorConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchedulerAcceleratorConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchedulerAcceleratorConfig(od as api.SchedulerAcceleratorConfig);
    });
  });

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-SetInstanceAcceleratorRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetInstanceAcceleratorRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetInstanceAcceleratorRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetInstanceAcceleratorRequest(
          od as api.SetInstanceAcceleratorRequest);
    });
  });

  unittest.group('obj-schema-SetInstanceLabelsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetInstanceLabelsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetInstanceLabelsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetInstanceLabelsRequest(od as api.SetInstanceLabelsRequest);
    });
  });

  unittest.group('obj-schema-SetInstanceMachineTypeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetInstanceMachineTypeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetInstanceMachineTypeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetInstanceMachineTypeRequest(
          od as api.SetInstanceMachineTypeRequest);
    });
  });

  unittest.group('obj-schema-ShieldedInstanceConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShieldedInstanceConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ShieldedInstanceConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkShieldedInstanceConfig(od as api.ShieldedInstanceConfig);
    });
  });

  unittest.group('obj-schema-StartInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStartInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StartInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStartInstanceRequest(od as api.StartInstanceRequest);
    });
  });

  unittest.group('obj-schema-StartRuntimeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStartRuntimeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StartRuntimeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStartRuntimeRequest(od as api.StartRuntimeRequest);
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

  unittest.group('obj-schema-StopInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStopInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StopInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStopInstanceRequest(od as api.StopInstanceRequest);
    });
  });

  unittest.group('obj-schema-StopRuntimeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStopRuntimeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StopRuntimeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStopRuntimeRequest(od as api.StopRuntimeRequest);
    });
  });

  unittest.group('obj-schema-SwitchRuntimeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSwitchRuntimeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SwitchRuntimeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSwitchRuntimeRequest(od as api.SwitchRuntimeRequest);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsRequest(od as api.TestIamPermissionsRequest);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsResponse(od as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('obj-schema-TriggerScheduleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTriggerScheduleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TriggerScheduleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTriggerScheduleRequest(od as api.TriggerScheduleRequest);
    });
  });

  unittest.group('obj-schema-UpdateShieldedInstanceConfigRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateShieldedInstanceConfigRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateShieldedInstanceConfigRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateShieldedInstanceConfigRequest(
          od as api.UpdateShieldedInstanceConfigRequest);
    });
  });

  unittest.group('obj-schema-UpgradeHistoryEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpgradeHistoryEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpgradeHistoryEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpgradeHistoryEntry(od as api.UpgradeHistoryEntry);
    });
  });

  unittest.group('obj-schema-UpgradeInstanceInternalRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpgradeInstanceInternalRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpgradeInstanceInternalRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpgradeInstanceInternalRequest(
          od as api.UpgradeInstanceInternalRequest);
    });
  });

  unittest.group('obj-schema-UpgradeInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpgradeInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpgradeInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpgradeInstanceRequest(od as api.UpgradeInstanceRequest);
    });
  });

  unittest.group('obj-schema-VirtualMachine', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVirtualMachine();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VirtualMachine.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVirtualMachine(od as api.VirtualMachine);
    });
  });

  unittest.group('obj-schema-VirtualMachineConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVirtualMachineConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VirtualMachineConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVirtualMachineConfig(od as api.VirtualMachineConfig);
    });
  });

  unittest.group('obj-schema-VmImage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVmImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.VmImage.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVmImage(od as api.VmImage);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations;
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
        var resp = convert.json.encode(buildLocation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkLocation(response as api.Location);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations;
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
        var resp = convert.json.encode(buildListLocationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLocationsResponse(response as api.ListLocationsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsEnvironmentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.AIPlatformNotebooksApi(mock).projects.locations.environments;
      var arg_request = buildEnvironment();
      var arg_parent = 'foo';
      var arg_environmentId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Environment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEnvironment(obj as api.Environment);

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
          queryMap["environmentId"]!.first,
          unittest.equals(arg_environmentId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          environmentId: arg_environmentId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.AIPlatformNotebooksApi(mock).projects.locations.environments;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.AIPlatformNotebooksApi(mock).projects.locations.environments;
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
        var resp = convert.json.encode(buildEnvironment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.AIPlatformNotebooksApi(mock).projects.locations.environments;
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
        var resp = convert.json.encode(buildListEnvironmentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListEnvironmentsResponse(response as api.ListEnvironmentsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsExecutionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.executions;
      var arg_request = buildExecution();
      var arg_parent = 'foo';
      var arg_executionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Execution.fromJson(json as core.Map<core.String, core.dynamic>);
        checkExecution(obj as api.Execution);

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
          queryMap["executionId"]!.first,
          unittest.equals(arg_executionId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          executionId: arg_executionId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.executions;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.executions;
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
        var resp = convert.json.encode(buildExecution());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkExecution(response as api.Execution);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.executions;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListExecutionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListExecutionsResponse(response as api.ListExecutionsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsInstancesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildInstance();
      var arg_parent = 'foo';
      var arg_instanceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Instance.fromJson(json as core.Map<core.String, core.dynamic>);
        checkInstance(obj as api.Instance);

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
          queryMap["instanceId"]!.first,
          unittest.equals(arg_instanceId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          instanceId: arg_instanceId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
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
        var resp = convert.json.encode(buildInstance());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkInstance(response as api.Instance);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_resource = 'foo';
      var arg_options_requestedPolicyVersion = 42;
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
          core.int.parse(queryMap["options.requestedPolicyVersion"]!.first),
          unittest.equals(arg_options_requestedPolicyVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--getInstanceHealth', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
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
        var resp = convert.json.encode(buildGetInstanceHealthResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getInstanceHealth(arg_name, $fields: arg_$fields);
      checkGetInstanceHealthResponse(response as api.GetInstanceHealthResponse);
    });

    unittest.test('method--isUpgradeable', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_notebookInstance = 'foo';
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
        var resp = convert.json.encode(buildIsInstanceUpgradeableResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.isUpgradeable(arg_notebookInstance, $fields: arg_$fields);
      checkIsInstanceUpgradeableResponse(
          response as api.IsInstanceUpgradeableResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
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
        var resp = convert.json.encode(buildListInstancesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInstancesResponse(response as api.ListInstancesResponse);
    });

    unittest.test('method--register', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildRegisterInstanceRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RegisterInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRegisterInstanceRequest(obj as api.RegisterInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.register(arg_request, arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--report', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildReportInstanceInfoRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReportInstanceInfoRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReportInstanceInfoRequest(obj as api.ReportInstanceInfoRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.report(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--reset', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildResetInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResetInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResetInstanceRequest(obj as api.ResetInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.reset(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--rollback', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildRollbackInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RollbackInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRollbackInstanceRequest(obj as api.RollbackInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.rollback(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setAccelerator', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildSetInstanceAcceleratorRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetInstanceAcceleratorRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetInstanceAcceleratorRequest(
            obj as api.SetInstanceAcceleratorRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setAccelerator(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--setLabels', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildSetInstanceLabelsRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetInstanceLabelsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetInstanceLabelsRequest(obj as api.SetInstanceLabelsRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setLabels(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setMachineType', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildSetInstanceMachineTypeRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetInstanceMachineTypeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetInstanceMachineTypeRequest(
            obj as api.SetInstanceMachineTypeRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setMachineType(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--start', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildStartInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StartInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStartInstanceRequest(obj as api.StartInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.start(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildStopInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StopInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStopInstanceRequest(obj as api.StopInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.stop(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });

    unittest.test('method--updateShieldedInstanceConfig', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildUpdateShieldedInstanceConfigRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateShieldedInstanceConfigRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateShieldedInstanceConfigRequest(
            obj as api.UpdateShieldedInstanceConfigRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateShieldedInstanceConfig(
          arg_request, arg_name,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--upgrade', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildUpgradeInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpgradeInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpgradeInstanceRequest(obj as api.UpgradeInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.upgrade(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--upgradeInternal', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.instances;
      var arg_request = buildUpgradeInstanceInternalRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpgradeInstanceInternalRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpgradeInstanceInternalRequest(
            obj as api.UpgradeInstanceInternalRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.upgradeInternal(arg_request, arg_name,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.operations;
      var arg_request = buildCancelOperationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelOperationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelOperationRequest(obj as api.CancelOperationRequest);

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
      final response =
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.operations;
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
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.operations;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.operations;
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

  unittest.group('resource-ProjectsLocationsRuntimesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
      var arg_request = buildRuntime();
      var arg_parent = 'foo';
      var arg_runtimeId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Runtime.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRuntime(obj as api.Runtime);

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
          queryMap["runtimeId"]!.first,
          unittest.equals(arg_runtimeId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          runtimeId: arg_runtimeId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
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
        var resp = convert.json.encode(buildRuntime());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkRuntime(response as api.Runtime);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
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
        var resp = convert.json.encode(buildListRuntimesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListRuntimesResponse(response as api.ListRuntimesResponse);
    });

    unittest.test('method--reset', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
      var arg_request = buildResetRuntimeRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResetRuntimeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResetRuntimeRequest(obj as api.ResetRuntimeRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.reset(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--start', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
      var arg_request = buildStartRuntimeRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StartRuntimeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStartRuntimeRequest(obj as api.StartRuntimeRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.start(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
      var arg_request = buildStopRuntimeRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StopRuntimeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStopRuntimeRequest(obj as api.StopRuntimeRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.stop(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--switch_', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.runtimes;
      var arg_request = buildSwitchRuntimeRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SwitchRuntimeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSwitchRuntimeRequest(obj as api.SwitchRuntimeRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.switch_(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsSchedulesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.schedules;
      var arg_request = buildSchedule();
      var arg_parent = 'foo';
      var arg_scheduleId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Schedule.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSchedule(obj as api.Schedule);

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
          queryMap["scheduleId"]!.first,
          unittest.equals(arg_scheduleId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          scheduleId: arg_scheduleId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.schedules;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.schedules;
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
        var resp = convert.json.encode(buildSchedule());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSchedule(response as api.Schedule);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.schedules;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListSchedulesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSchedulesResponse(response as api.ListSchedulesResponse);
    });

    unittest.test('method--trigger', () async {
      var mock = HttpServerMock();
      var res = api.AIPlatformNotebooksApi(mock).projects.locations.schedules;
      var arg_request = buildTriggerScheduleRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TriggerScheduleRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTriggerScheduleRequest(obj as api.TriggerScheduleRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.trigger(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });
}

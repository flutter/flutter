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

import 'package:googleapis/deploymentmanager/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.AuditLogConfig> buildUnnamed4841() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed4841(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed4841();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed4841(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed4842() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4842(core.List<core.String> o) {
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

core.int buildCounterAuditLogConfig = 0;
api.AuditLogConfig buildAuditLogConfig() {
  var o = api.AuditLogConfig();
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    o.exemptedMembers = buildUnnamed4842();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed4842(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed4843() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4843(core.List<core.String> o) {
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
    o.members = buildUnnamed4843();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed4843(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterConfigFile = 0;
api.ConfigFile buildConfigFile() {
  var o = api.ConfigFile();
  buildCounterConfigFile++;
  if (buildCounterConfigFile < 3) {
    o.content = 'foo';
  }
  buildCounterConfigFile--;
  return o;
}

void checkConfigFile(api.ConfigFile o) {
  buildCounterConfigFile++;
  if (buildCounterConfigFile < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
  }
  buildCounterConfigFile--;
}

core.List<api.DeploymentLabelEntry> buildUnnamed4844() {
  var o = <api.DeploymentLabelEntry>[];
  o.add(buildDeploymentLabelEntry());
  o.add(buildDeploymentLabelEntry());
  return o;
}

void checkUnnamed4844(core.List<api.DeploymentLabelEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeploymentLabelEntry(o[0] as api.DeploymentLabelEntry);
  checkDeploymentLabelEntry(o[1] as api.DeploymentLabelEntry);
}

core.int buildCounterDeployment = 0;
api.Deployment buildDeployment() {
  var o = api.Deployment();
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    o.description = 'foo';
    o.fingerprint = 'foo';
    o.id = 'foo';
    o.insertTime = 'foo';
    o.labels = buildUnnamed4844();
    o.manifest = 'foo';
    o.name = 'foo';
    o.operation = buildOperation();
    o.selfLink = 'foo';
    o.target = buildTargetConfiguration();
    o.update = buildDeploymentUpdate();
    o.updateTime = 'foo';
  }
  buildCounterDeployment--;
  return o;
}

void checkDeployment(api.Deployment o) {
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertTime!,
      unittest.equals('foo'),
    );
    checkUnnamed4844(o.labels!);
    unittest.expect(
      o.manifest!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOperation(o.operation! as api.Operation);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    checkTargetConfiguration(o.target! as api.TargetConfiguration);
    checkDeploymentUpdate(o.update! as api.DeploymentUpdate);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeployment--;
}

core.int buildCounterDeploymentLabelEntry = 0;
api.DeploymentLabelEntry buildDeploymentLabelEntry() {
  var o = api.DeploymentLabelEntry();
  buildCounterDeploymentLabelEntry++;
  if (buildCounterDeploymentLabelEntry < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterDeploymentLabelEntry--;
  return o;
}

void checkDeploymentLabelEntry(api.DeploymentLabelEntry o) {
  buildCounterDeploymentLabelEntry++;
  if (buildCounterDeploymentLabelEntry < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeploymentLabelEntry--;
}

core.List<api.DeploymentUpdateLabelEntry> buildUnnamed4845() {
  var o = <api.DeploymentUpdateLabelEntry>[];
  o.add(buildDeploymentUpdateLabelEntry());
  o.add(buildDeploymentUpdateLabelEntry());
  return o;
}

void checkUnnamed4845(core.List<api.DeploymentUpdateLabelEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeploymentUpdateLabelEntry(o[0] as api.DeploymentUpdateLabelEntry);
  checkDeploymentUpdateLabelEntry(o[1] as api.DeploymentUpdateLabelEntry);
}

core.int buildCounterDeploymentUpdate = 0;
api.DeploymentUpdate buildDeploymentUpdate() {
  var o = api.DeploymentUpdate();
  buildCounterDeploymentUpdate++;
  if (buildCounterDeploymentUpdate < 3) {
    o.description = 'foo';
    o.labels = buildUnnamed4845();
    o.manifest = 'foo';
  }
  buildCounterDeploymentUpdate--;
  return o;
}

void checkDeploymentUpdate(api.DeploymentUpdate o) {
  buildCounterDeploymentUpdate++;
  if (buildCounterDeploymentUpdate < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed4845(o.labels!);
    unittest.expect(
      o.manifest!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeploymentUpdate--;
}

core.int buildCounterDeploymentUpdateLabelEntry = 0;
api.DeploymentUpdateLabelEntry buildDeploymentUpdateLabelEntry() {
  var o = api.DeploymentUpdateLabelEntry();
  buildCounterDeploymentUpdateLabelEntry++;
  if (buildCounterDeploymentUpdateLabelEntry < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterDeploymentUpdateLabelEntry--;
  return o;
}

void checkDeploymentUpdateLabelEntry(api.DeploymentUpdateLabelEntry o) {
  buildCounterDeploymentUpdateLabelEntry++;
  if (buildCounterDeploymentUpdateLabelEntry < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeploymentUpdateLabelEntry--;
}

core.int buildCounterDeploymentsCancelPreviewRequest = 0;
api.DeploymentsCancelPreviewRequest buildDeploymentsCancelPreviewRequest() {
  var o = api.DeploymentsCancelPreviewRequest();
  buildCounterDeploymentsCancelPreviewRequest++;
  if (buildCounterDeploymentsCancelPreviewRequest < 3) {
    o.fingerprint = 'foo';
  }
  buildCounterDeploymentsCancelPreviewRequest--;
  return o;
}

void checkDeploymentsCancelPreviewRequest(
    api.DeploymentsCancelPreviewRequest o) {
  buildCounterDeploymentsCancelPreviewRequest++;
  if (buildCounterDeploymentsCancelPreviewRequest < 3) {
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeploymentsCancelPreviewRequest--;
}

core.List<api.Deployment> buildUnnamed4846() {
  var o = <api.Deployment>[];
  o.add(buildDeployment());
  o.add(buildDeployment());
  return o;
}

void checkUnnamed4846(core.List<api.Deployment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeployment(o[0] as api.Deployment);
  checkDeployment(o[1] as api.Deployment);
}

core.int buildCounterDeploymentsListResponse = 0;
api.DeploymentsListResponse buildDeploymentsListResponse() {
  var o = api.DeploymentsListResponse();
  buildCounterDeploymentsListResponse++;
  if (buildCounterDeploymentsListResponse < 3) {
    o.deployments = buildUnnamed4846();
    o.nextPageToken = 'foo';
  }
  buildCounterDeploymentsListResponse--;
  return o;
}

void checkDeploymentsListResponse(api.DeploymentsListResponse o) {
  buildCounterDeploymentsListResponse++;
  if (buildCounterDeploymentsListResponse < 3) {
    checkUnnamed4846(o.deployments!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeploymentsListResponse--;
}

core.int buildCounterDeploymentsStopRequest = 0;
api.DeploymentsStopRequest buildDeploymentsStopRequest() {
  var o = api.DeploymentsStopRequest();
  buildCounterDeploymentsStopRequest++;
  if (buildCounterDeploymentsStopRequest < 3) {
    o.fingerprint = 'foo';
  }
  buildCounterDeploymentsStopRequest--;
  return o;
}

void checkDeploymentsStopRequest(api.DeploymentsStopRequest o) {
  buildCounterDeploymentsStopRequest++;
  if (buildCounterDeploymentsStopRequest < 3) {
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeploymentsStopRequest--;
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

core.List<api.Binding> buildUnnamed4847() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed4847(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterGlobalSetPolicyRequest = 0;
api.GlobalSetPolicyRequest buildGlobalSetPolicyRequest() {
  var o = api.GlobalSetPolicyRequest();
  buildCounterGlobalSetPolicyRequest++;
  if (buildCounterGlobalSetPolicyRequest < 3) {
    o.bindings = buildUnnamed4847();
    o.etag = 'foo';
    o.policy = buildPolicy();
  }
  buildCounterGlobalSetPolicyRequest--;
  return o;
}

void checkGlobalSetPolicyRequest(api.GlobalSetPolicyRequest o) {
  buildCounterGlobalSetPolicyRequest++;
  if (buildCounterGlobalSetPolicyRequest < 3) {
    checkUnnamed4847(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkPolicy(o.policy! as api.Policy);
  }
  buildCounterGlobalSetPolicyRequest--;
}

core.int buildCounterImportFile = 0;
api.ImportFile buildImportFile() {
  var o = api.ImportFile();
  buildCounterImportFile++;
  if (buildCounterImportFile < 3) {
    o.content = 'foo';
    o.name = 'foo';
  }
  buildCounterImportFile--;
  return o;
}

void checkImportFile(api.ImportFile o) {
  buildCounterImportFile++;
  if (buildCounterImportFile < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterImportFile--;
}

core.List<api.ImportFile> buildUnnamed4848() {
  var o = <api.ImportFile>[];
  o.add(buildImportFile());
  o.add(buildImportFile());
  return o;
}

void checkUnnamed4848(core.List<api.ImportFile> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImportFile(o[0] as api.ImportFile);
  checkImportFile(o[1] as api.ImportFile);
}

core.int buildCounterManifest = 0;
api.Manifest buildManifest() {
  var o = api.Manifest();
  buildCounterManifest++;
  if (buildCounterManifest < 3) {
    o.config = buildConfigFile();
    o.expandedConfig = 'foo';
    o.id = 'foo';
    o.imports = buildUnnamed4848();
    o.insertTime = 'foo';
    o.layout = 'foo';
    o.manifestSizeBytes = 'foo';
    o.manifestSizeLimitBytes = 'foo';
    o.name = 'foo';
    o.selfLink = 'foo';
  }
  buildCounterManifest--;
  return o;
}

void checkManifest(api.Manifest o) {
  buildCounterManifest++;
  if (buildCounterManifest < 3) {
    checkConfigFile(o.config! as api.ConfigFile);
    unittest.expect(
      o.expandedConfig!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed4848(o.imports!);
    unittest.expect(
      o.insertTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.layout!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manifestSizeBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manifestSizeLimitBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
  }
  buildCounterManifest--;
}

core.List<api.Manifest> buildUnnamed4849() {
  var o = <api.Manifest>[];
  o.add(buildManifest());
  o.add(buildManifest());
  return o;
}

void checkUnnamed4849(core.List<api.Manifest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkManifest(o[0] as api.Manifest);
  checkManifest(o[1] as api.Manifest);
}

core.int buildCounterManifestsListResponse = 0;
api.ManifestsListResponse buildManifestsListResponse() {
  var o = api.ManifestsListResponse();
  buildCounterManifestsListResponse++;
  if (buildCounterManifestsListResponse < 3) {
    o.manifests = buildUnnamed4849();
    o.nextPageToken = 'foo';
  }
  buildCounterManifestsListResponse--;
  return o;
}

void checkManifestsListResponse(api.ManifestsListResponse o) {
  buildCounterManifestsListResponse++;
  if (buildCounterManifestsListResponse < 3) {
    checkUnnamed4849(o.manifests!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterManifestsListResponse--;
}

core.int buildCounterOperationErrorErrors = 0;
api.OperationErrorErrors buildOperationErrorErrors() {
  var o = api.OperationErrorErrors();
  buildCounterOperationErrorErrors++;
  if (buildCounterOperationErrorErrors < 3) {
    o.code = 'foo';
    o.location = 'foo';
    o.message = 'foo';
  }
  buildCounterOperationErrorErrors--;
  return o;
}

void checkOperationErrorErrors(api.OperationErrorErrors o) {
  buildCounterOperationErrorErrors++;
  if (buildCounterOperationErrorErrors < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationErrorErrors--;
}

core.List<api.OperationErrorErrors> buildUnnamed4850() {
  var o = <api.OperationErrorErrors>[];
  o.add(buildOperationErrorErrors());
  o.add(buildOperationErrorErrors());
  return o;
}

void checkUnnamed4850(core.List<api.OperationErrorErrors> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperationErrorErrors(o[0] as api.OperationErrorErrors);
  checkOperationErrorErrors(o[1] as api.OperationErrorErrors);
}

core.int buildCounterOperationError = 0;
api.OperationError buildOperationError() {
  var o = api.OperationError();
  buildCounterOperationError++;
  if (buildCounterOperationError < 3) {
    o.errors = buildUnnamed4850();
  }
  buildCounterOperationError--;
  return o;
}

void checkOperationError(api.OperationError o) {
  buildCounterOperationError++;
  if (buildCounterOperationError < 3) {
    checkUnnamed4850(o.errors!);
  }
  buildCounterOperationError--;
}

core.int buildCounterOperationWarningsData = 0;
api.OperationWarningsData buildOperationWarningsData() {
  var o = api.OperationWarningsData();
  buildCounterOperationWarningsData++;
  if (buildCounterOperationWarningsData < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterOperationWarningsData--;
  return o;
}

void checkOperationWarningsData(api.OperationWarningsData o) {
  buildCounterOperationWarningsData++;
  if (buildCounterOperationWarningsData < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationWarningsData--;
}

core.List<api.OperationWarningsData> buildUnnamed4851() {
  var o = <api.OperationWarningsData>[];
  o.add(buildOperationWarningsData());
  o.add(buildOperationWarningsData());
  return o;
}

void checkUnnamed4851(core.List<api.OperationWarningsData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperationWarningsData(o[0] as api.OperationWarningsData);
  checkOperationWarningsData(o[1] as api.OperationWarningsData);
}

core.int buildCounterOperationWarnings = 0;
api.OperationWarnings buildOperationWarnings() {
  var o = api.OperationWarnings();
  buildCounterOperationWarnings++;
  if (buildCounterOperationWarnings < 3) {
    o.code = 'foo';
    o.data = buildUnnamed4851();
    o.message = 'foo';
  }
  buildCounterOperationWarnings--;
  return o;
}

void checkOperationWarnings(api.OperationWarnings o) {
  buildCounterOperationWarnings++;
  if (buildCounterOperationWarnings < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    checkUnnamed4851(o.data!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationWarnings--;
}

core.List<api.OperationWarnings> buildUnnamed4852() {
  var o = <api.OperationWarnings>[];
  o.add(buildOperationWarnings());
  o.add(buildOperationWarnings());
  return o;
}

void checkUnnamed4852(core.List<api.OperationWarnings> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperationWarnings(o[0] as api.OperationWarnings);
  checkOperationWarnings(o[1] as api.OperationWarnings);
}

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.clientOperationId = 'foo';
    o.creationTimestamp = 'foo';
    o.description = 'foo';
    o.endTime = 'foo';
    o.error = buildOperationError();
    o.httpErrorMessage = 'foo';
    o.httpErrorStatusCode = 42;
    o.id = 'foo';
    o.insertTime = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.operationGroupId = 'foo';
    o.operationType = 'foo';
    o.progress = 42;
    o.region = 'foo';
    o.selfLink = 'foo';
    o.startTime = 'foo';
    o.status = 'foo';
    o.statusMessage = 'foo';
    o.targetId = 'foo';
    o.targetLink = 'foo';
    o.user = 'foo';
    o.warnings = buildUnnamed4852();
    o.zone = 'foo';
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(
      o.clientOperationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkOperationError(o.error! as api.OperationError);
    unittest.expect(
      o.httpErrorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.httpErrorStatusCode!,
      unittest.equals(42),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertTime!,
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
    unittest.expect(
      o.operationGroupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progress!,
      unittest.equals(42),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.statusMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.user!,
      unittest.equals('foo'),
    );
    checkUnnamed4852(o.warnings!);
    unittest.expect(
      o.zone!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperation--;
}

core.List<api.Operation> buildUnnamed4853() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed4853(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterOperationsListResponse = 0;
api.OperationsListResponse buildOperationsListResponse() {
  var o = api.OperationsListResponse();
  buildCounterOperationsListResponse++;
  if (buildCounterOperationsListResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed4853();
  }
  buildCounterOperationsListResponse--;
  return o;
}

void checkOperationsListResponse(api.OperationsListResponse o) {
  buildCounterOperationsListResponse++;
  if (buildCounterOperationsListResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4853(o.operations!);
  }
  buildCounterOperationsListResponse--;
}

core.List<api.AuditConfig> buildUnnamed4854() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed4854(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed4855() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed4855(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed4854();
    o.bindings = buildUnnamed4855();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed4854(o.auditConfigs!);
    checkUnnamed4855(o.bindings!);
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

core.int buildCounterResourceWarningsData = 0;
api.ResourceWarningsData buildResourceWarningsData() {
  var o = api.ResourceWarningsData();
  buildCounterResourceWarningsData++;
  if (buildCounterResourceWarningsData < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterResourceWarningsData--;
  return o;
}

void checkResourceWarningsData(api.ResourceWarningsData o) {
  buildCounterResourceWarningsData++;
  if (buildCounterResourceWarningsData < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceWarningsData--;
}

core.List<api.ResourceWarningsData> buildUnnamed4856() {
  var o = <api.ResourceWarningsData>[];
  o.add(buildResourceWarningsData());
  o.add(buildResourceWarningsData());
  return o;
}

void checkUnnamed4856(core.List<api.ResourceWarningsData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceWarningsData(o[0] as api.ResourceWarningsData);
  checkResourceWarningsData(o[1] as api.ResourceWarningsData);
}

core.int buildCounterResourceWarnings = 0;
api.ResourceWarnings buildResourceWarnings() {
  var o = api.ResourceWarnings();
  buildCounterResourceWarnings++;
  if (buildCounterResourceWarnings < 3) {
    o.code = 'foo';
    o.data = buildUnnamed4856();
    o.message = 'foo';
  }
  buildCounterResourceWarnings--;
  return o;
}

void checkResourceWarnings(api.ResourceWarnings o) {
  buildCounterResourceWarnings++;
  if (buildCounterResourceWarnings < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    checkUnnamed4856(o.data!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceWarnings--;
}

core.List<api.ResourceWarnings> buildUnnamed4857() {
  var o = <api.ResourceWarnings>[];
  o.add(buildResourceWarnings());
  o.add(buildResourceWarnings());
  return o;
}

void checkUnnamed4857(core.List<api.ResourceWarnings> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceWarnings(o[0] as api.ResourceWarnings);
  checkResourceWarnings(o[1] as api.ResourceWarnings);
}

core.int buildCounterResource = 0;
api.Resource buildResource() {
  var o = api.Resource();
  buildCounterResource++;
  if (buildCounterResource < 3) {
    o.accessControl = buildResourceAccessControl();
    o.finalProperties = 'foo';
    o.id = 'foo';
    o.insertTime = 'foo';
    o.manifest = 'foo';
    o.name = 'foo';
    o.properties = 'foo';
    o.type = 'foo';
    o.update = buildResourceUpdate();
    o.updateTime = 'foo';
    o.url = 'foo';
    o.warnings = buildUnnamed4857();
  }
  buildCounterResource--;
  return o;
}

void checkResource(api.Resource o) {
  buildCounterResource++;
  if (buildCounterResource < 3) {
    checkResourceAccessControl(o.accessControl! as api.ResourceAccessControl);
    unittest.expect(
      o.finalProperties!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manifest!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.properties!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkResourceUpdate(o.update! as api.ResourceUpdate);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
    checkUnnamed4857(o.warnings!);
  }
  buildCounterResource--;
}

core.int buildCounterResourceAccessControl = 0;
api.ResourceAccessControl buildResourceAccessControl() {
  var o = api.ResourceAccessControl();
  buildCounterResourceAccessControl++;
  if (buildCounterResourceAccessControl < 3) {
    o.gcpIamPolicy = 'foo';
  }
  buildCounterResourceAccessControl--;
  return o;
}

void checkResourceAccessControl(api.ResourceAccessControl o) {
  buildCounterResourceAccessControl++;
  if (buildCounterResourceAccessControl < 3) {
    unittest.expect(
      o.gcpIamPolicy!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceAccessControl--;
}

core.int buildCounterResourceUpdateErrorErrors = 0;
api.ResourceUpdateErrorErrors buildResourceUpdateErrorErrors() {
  var o = api.ResourceUpdateErrorErrors();
  buildCounterResourceUpdateErrorErrors++;
  if (buildCounterResourceUpdateErrorErrors < 3) {
    o.code = 'foo';
    o.location = 'foo';
    o.message = 'foo';
  }
  buildCounterResourceUpdateErrorErrors--;
  return o;
}

void checkResourceUpdateErrorErrors(api.ResourceUpdateErrorErrors o) {
  buildCounterResourceUpdateErrorErrors++;
  if (buildCounterResourceUpdateErrorErrors < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceUpdateErrorErrors--;
}

core.List<api.ResourceUpdateErrorErrors> buildUnnamed4858() {
  var o = <api.ResourceUpdateErrorErrors>[];
  o.add(buildResourceUpdateErrorErrors());
  o.add(buildResourceUpdateErrorErrors());
  return o;
}

void checkUnnamed4858(core.List<api.ResourceUpdateErrorErrors> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceUpdateErrorErrors(o[0] as api.ResourceUpdateErrorErrors);
  checkResourceUpdateErrorErrors(o[1] as api.ResourceUpdateErrorErrors);
}

core.int buildCounterResourceUpdateError = 0;
api.ResourceUpdateError buildResourceUpdateError() {
  var o = api.ResourceUpdateError();
  buildCounterResourceUpdateError++;
  if (buildCounterResourceUpdateError < 3) {
    o.errors = buildUnnamed4858();
  }
  buildCounterResourceUpdateError--;
  return o;
}

void checkResourceUpdateError(api.ResourceUpdateError o) {
  buildCounterResourceUpdateError++;
  if (buildCounterResourceUpdateError < 3) {
    checkUnnamed4858(o.errors!);
  }
  buildCounterResourceUpdateError--;
}

core.int buildCounterResourceUpdateWarningsData = 0;
api.ResourceUpdateWarningsData buildResourceUpdateWarningsData() {
  var o = api.ResourceUpdateWarningsData();
  buildCounterResourceUpdateWarningsData++;
  if (buildCounterResourceUpdateWarningsData < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterResourceUpdateWarningsData--;
  return o;
}

void checkResourceUpdateWarningsData(api.ResourceUpdateWarningsData o) {
  buildCounterResourceUpdateWarningsData++;
  if (buildCounterResourceUpdateWarningsData < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceUpdateWarningsData--;
}

core.List<api.ResourceUpdateWarningsData> buildUnnamed4859() {
  var o = <api.ResourceUpdateWarningsData>[];
  o.add(buildResourceUpdateWarningsData());
  o.add(buildResourceUpdateWarningsData());
  return o;
}

void checkUnnamed4859(core.List<api.ResourceUpdateWarningsData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceUpdateWarningsData(o[0] as api.ResourceUpdateWarningsData);
  checkResourceUpdateWarningsData(o[1] as api.ResourceUpdateWarningsData);
}

core.int buildCounterResourceUpdateWarnings = 0;
api.ResourceUpdateWarnings buildResourceUpdateWarnings() {
  var o = api.ResourceUpdateWarnings();
  buildCounterResourceUpdateWarnings++;
  if (buildCounterResourceUpdateWarnings < 3) {
    o.code = 'foo';
    o.data = buildUnnamed4859();
    o.message = 'foo';
  }
  buildCounterResourceUpdateWarnings--;
  return o;
}

void checkResourceUpdateWarnings(api.ResourceUpdateWarnings o) {
  buildCounterResourceUpdateWarnings++;
  if (buildCounterResourceUpdateWarnings < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    checkUnnamed4859(o.data!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceUpdateWarnings--;
}

core.List<api.ResourceUpdateWarnings> buildUnnamed4860() {
  var o = <api.ResourceUpdateWarnings>[];
  o.add(buildResourceUpdateWarnings());
  o.add(buildResourceUpdateWarnings());
  return o;
}

void checkUnnamed4860(core.List<api.ResourceUpdateWarnings> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceUpdateWarnings(o[0] as api.ResourceUpdateWarnings);
  checkResourceUpdateWarnings(o[1] as api.ResourceUpdateWarnings);
}

core.int buildCounterResourceUpdate = 0;
api.ResourceUpdate buildResourceUpdate() {
  var o = api.ResourceUpdate();
  buildCounterResourceUpdate++;
  if (buildCounterResourceUpdate < 3) {
    o.accessControl = buildResourceAccessControl();
    o.error = buildResourceUpdateError();
    o.finalProperties = 'foo';
    o.intent = 'foo';
    o.manifest = 'foo';
    o.properties = 'foo';
    o.state = 'foo';
    o.warnings = buildUnnamed4860();
  }
  buildCounterResourceUpdate--;
  return o;
}

void checkResourceUpdate(api.ResourceUpdate o) {
  buildCounterResourceUpdate++;
  if (buildCounterResourceUpdate < 3) {
    checkResourceAccessControl(o.accessControl! as api.ResourceAccessControl);
    checkResourceUpdateError(o.error! as api.ResourceUpdateError);
    unittest.expect(
      o.finalProperties!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.intent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manifest!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.properties!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkUnnamed4860(o.warnings!);
  }
  buildCounterResourceUpdate--;
}

core.List<api.Resource> buildUnnamed4861() {
  var o = <api.Resource>[];
  o.add(buildResource());
  o.add(buildResource());
  return o;
}

void checkUnnamed4861(core.List<api.Resource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResource(o[0] as api.Resource);
  checkResource(o[1] as api.Resource);
}

core.int buildCounterResourcesListResponse = 0;
api.ResourcesListResponse buildResourcesListResponse() {
  var o = api.ResourcesListResponse();
  buildCounterResourcesListResponse++;
  if (buildCounterResourcesListResponse < 3) {
    o.nextPageToken = 'foo';
    o.resources = buildUnnamed4861();
  }
  buildCounterResourcesListResponse--;
  return o;
}

void checkResourcesListResponse(api.ResourcesListResponse o) {
  buildCounterResourcesListResponse++;
  if (buildCounterResourcesListResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4861(o.resources!);
  }
  buildCounterResourcesListResponse--;
}

core.List<api.ImportFile> buildUnnamed4862() {
  var o = <api.ImportFile>[];
  o.add(buildImportFile());
  o.add(buildImportFile());
  return o;
}

void checkUnnamed4862(core.List<api.ImportFile> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImportFile(o[0] as api.ImportFile);
  checkImportFile(o[1] as api.ImportFile);
}

core.int buildCounterTargetConfiguration = 0;
api.TargetConfiguration buildTargetConfiguration() {
  var o = api.TargetConfiguration();
  buildCounterTargetConfiguration++;
  if (buildCounterTargetConfiguration < 3) {
    o.config = buildConfigFile();
    o.imports = buildUnnamed4862();
  }
  buildCounterTargetConfiguration--;
  return o;
}

void checkTargetConfiguration(api.TargetConfiguration o) {
  buildCounterTargetConfiguration++;
  if (buildCounterTargetConfiguration < 3) {
    checkConfigFile(o.config! as api.ConfigFile);
    checkUnnamed4862(o.imports!);
  }
  buildCounterTargetConfiguration--;
}

core.List<core.String> buildUnnamed4863() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4863(core.List<core.String> o) {
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

core.int buildCounterTestPermissionsRequest = 0;
api.TestPermissionsRequest buildTestPermissionsRequest() {
  var o = api.TestPermissionsRequest();
  buildCounterTestPermissionsRequest++;
  if (buildCounterTestPermissionsRequest < 3) {
    o.permissions = buildUnnamed4863();
  }
  buildCounterTestPermissionsRequest--;
  return o;
}

void checkTestPermissionsRequest(api.TestPermissionsRequest o) {
  buildCounterTestPermissionsRequest++;
  if (buildCounterTestPermissionsRequest < 3) {
    checkUnnamed4863(o.permissions!);
  }
  buildCounterTestPermissionsRequest--;
}

core.List<core.String> buildUnnamed4864() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4864(core.List<core.String> o) {
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

core.int buildCounterTestPermissionsResponse = 0;
api.TestPermissionsResponse buildTestPermissionsResponse() {
  var o = api.TestPermissionsResponse();
  buildCounterTestPermissionsResponse++;
  if (buildCounterTestPermissionsResponse < 3) {
    o.permissions = buildUnnamed4864();
  }
  buildCounterTestPermissionsResponse--;
  return o;
}

void checkTestPermissionsResponse(api.TestPermissionsResponse o) {
  buildCounterTestPermissionsResponse++;
  if (buildCounterTestPermissionsResponse < 3) {
    checkUnnamed4864(o.permissions!);
  }
  buildCounterTestPermissionsResponse--;
}

core.int buildCounterType = 0;
api.Type buildType() {
  var o = api.Type();
  buildCounterType++;
  if (buildCounterType < 3) {
    o.id = 'foo';
    o.insertTime = 'foo';
    o.name = 'foo';
    o.operation = buildOperation();
    o.selfLink = 'foo';
  }
  buildCounterType--;
  return o;
}

void checkType(api.Type o) {
  buildCounterType++;
  if (buildCounterType < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOperation(o.operation! as api.Operation);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
  }
  buildCounterType--;
}

core.List<api.Type> buildUnnamed4865() {
  var o = <api.Type>[];
  o.add(buildType());
  o.add(buildType());
  return o;
}

void checkUnnamed4865(core.List<api.Type> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkType(o[0] as api.Type);
  checkType(o[1] as api.Type);
}

core.int buildCounterTypesListResponse = 0;
api.TypesListResponse buildTypesListResponse() {
  var o = api.TypesListResponse();
  buildCounterTypesListResponse++;
  if (buildCounterTypesListResponse < 3) {
    o.nextPageToken = 'foo';
    o.types = buildUnnamed4865();
  }
  buildCounterTypesListResponse--;
  return o;
}

void checkTypesListResponse(api.TypesListResponse o) {
  buildCounterTypesListResponse++;
  if (buildCounterTypesListResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4865(o.types!);
  }
  buildCounterTypesListResponse--;
}

void main() {
  unittest.group('obj-schema-AuditConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditConfig(od as api.AuditConfig);
    });
  });

  unittest.group('obj-schema-AuditLogConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditLogConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditLogConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditLogConfig(od as api.AuditLogConfig);
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

  unittest.group('obj-schema-ConfigFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConfigFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ConfigFile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkConfigFile(od as api.ConfigFile);
    });
  });

  unittest.group('obj-schema-Deployment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Deployment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDeployment(od as api.Deployment);
    });
  });

  unittest.group('obj-schema-DeploymentLabelEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentLabelEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentLabelEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentLabelEntry(od as api.DeploymentLabelEntry);
    });
  });

  unittest.group('obj-schema-DeploymentUpdate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentUpdate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentUpdate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentUpdate(od as api.DeploymentUpdate);
    });
  });

  unittest.group('obj-schema-DeploymentUpdateLabelEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentUpdateLabelEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentUpdateLabelEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentUpdateLabelEntry(od as api.DeploymentUpdateLabelEntry);
    });
  });

  unittest.group('obj-schema-DeploymentsCancelPreviewRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentsCancelPreviewRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentsCancelPreviewRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentsCancelPreviewRequest(
          od as api.DeploymentsCancelPreviewRequest);
    });
  });

  unittest.group('obj-schema-DeploymentsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentsListResponse(od as api.DeploymentsListResponse);
    });
  });

  unittest.group('obj-schema-DeploymentsStopRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentsStopRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentsStopRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentsStopRequest(od as api.DeploymentsStopRequest);
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

  unittest.group('obj-schema-GlobalSetPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGlobalSetPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GlobalSetPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGlobalSetPolicyRequest(od as api.GlobalSetPolicyRequest);
    });
  });

  unittest.group('obj-schema-ImportFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ImportFile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImportFile(od as api.ImportFile);
    });
  });

  unittest.group('obj-schema-Manifest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManifest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Manifest.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkManifest(od as api.Manifest);
    });
  });

  unittest.group('obj-schema-ManifestsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManifestsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManifestsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManifestsListResponse(od as api.ManifestsListResponse);
    });
  });

  unittest.group('obj-schema-OperationErrorErrors', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationErrorErrors();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationErrorErrors.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationErrorErrors(od as api.OperationErrorErrors);
    });
  });

  unittest.group('obj-schema-OperationError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationError(od as api.OperationError);
    });
  });

  unittest.group('obj-schema-OperationWarningsData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationWarningsData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationWarningsData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationWarningsData(od as api.OperationWarningsData);
    });
  });

  unittest.group('obj-schema-OperationWarnings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationWarnings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationWarnings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationWarnings(od as api.OperationWarnings);
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

  unittest.group('obj-schema-OperationsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationsListResponse(od as api.OperationsListResponse);
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

  unittest.group('obj-schema-ResourceWarningsData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceWarningsData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceWarningsData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceWarningsData(od as api.ResourceWarningsData);
    });
  });

  unittest.group('obj-schema-ResourceWarnings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceWarnings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceWarnings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceWarnings(od as api.ResourceWarnings);
    });
  });

  unittest.group('obj-schema-Resource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Resource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResource(od as api.Resource);
    });
  });

  unittest.group('obj-schema-ResourceAccessControl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceAccessControl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceAccessControl.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceAccessControl(od as api.ResourceAccessControl);
    });
  });

  unittest.group('obj-schema-ResourceUpdateErrorErrors', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceUpdateErrorErrors();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceUpdateErrorErrors.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceUpdateErrorErrors(od as api.ResourceUpdateErrorErrors);
    });
  });

  unittest.group('obj-schema-ResourceUpdateError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceUpdateError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceUpdateError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceUpdateError(od as api.ResourceUpdateError);
    });
  });

  unittest.group('obj-schema-ResourceUpdateWarningsData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceUpdateWarningsData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceUpdateWarningsData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceUpdateWarningsData(od as api.ResourceUpdateWarningsData);
    });
  });

  unittest.group('obj-schema-ResourceUpdateWarnings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceUpdateWarnings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceUpdateWarnings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceUpdateWarnings(od as api.ResourceUpdateWarnings);
    });
  });

  unittest.group('obj-schema-ResourceUpdate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceUpdate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceUpdate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceUpdate(od as api.ResourceUpdate);
    });
  });

  unittest.group('obj-schema-ResourcesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourcesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourcesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourcesListResponse(od as api.ResourcesListResponse);
    });
  });

  unittest.group('obj-schema-TargetConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetConfiguration(od as api.TargetConfiguration);
    });
  });

  unittest.group('obj-schema-TestPermissionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestPermissionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestPermissionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestPermissionsRequest(od as api.TestPermissionsRequest);
    });
  });

  unittest.group('obj-schema-TestPermissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestPermissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestPermissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestPermissionsResponse(od as api.TestPermissionsResponse);
    });
  });

  unittest.group('obj-schema-Type', () {
    unittest.test('to-json--from-json', () async {
      var o = buildType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Type.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkType(od as api.Type);
    });
  });

  unittest.group('obj-schema-TypesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTypesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TypesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTypesListResponse(od as api.TypesListResponse);
    });
  });

  unittest.group('resource-DeploymentsResource', () {
    unittest.test('method--cancelPreview', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_request = buildDeploymentsCancelPreviewRequest();
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeploymentsCancelPreviewRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeploymentsCancelPreviewRequest(
            obj as api.DeploymentsCancelPreviewRequest);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/cancelPreview', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/cancelPreview"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.cancelPreview(
          arg_request, arg_project, arg_deployment,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_deletePolicy = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
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
          queryMap["deletePolicy"]!.first,
          unittest.equals(arg_deletePolicy),
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
      final response = await res.delete(arg_project, arg_deployment,
          deletePolicy: arg_deletePolicy, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_project = 'foo';
      var arg_deployment = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
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
        var resp = convert.json.encode(buildDeployment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_project, arg_deployment, $fields: arg_$fields);
      checkDeployment(response as api.Deployment);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_project = 'foo';
      var arg_resource = 'foo';
      var arg_optionsRequestedPolicyVersion = 42;
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/getIamPolicy', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resource'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/getIamPolicy"),
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
          core.int.parse(queryMap["optionsRequestedPolicyVersion"]!.first),
          unittest.equals(arg_optionsRequestedPolicyVersion),
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
      final response = await res.getIamPolicy(arg_project, arg_resource,
          optionsRequestedPolicyVersion: arg_optionsRequestedPolicyVersion,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_request = buildDeployment();
      var arg_project = 'foo';
      var arg_createPolicy = 'foo';
      var arg_preview = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Deployment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeployment(obj as api.Deployment);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/global/deployments"),
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
          queryMap["createPolicy"]!.first,
          unittest.equals(arg_createPolicy),
        );
        unittest.expect(
          queryMap["preview"]!.first,
          unittest.equals("$arg_preview"),
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
      final response = await res.insert(arg_request, arg_project,
          createPolicy: arg_createPolicy,
          preview: arg_preview,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_project = 'foo';
      var arg_filter = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/global/deployments"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildDeploymentsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          filter: arg_filter,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkDeploymentsListResponse(response as api.DeploymentsListResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_request = buildDeployment();
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_createPolicy = 'foo';
      var arg_deletePolicy = 'foo';
      var arg_preview = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Deployment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeployment(obj as api.Deployment);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
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
          queryMap["createPolicy"]!.first,
          unittest.equals(arg_createPolicy),
        );
        unittest.expect(
          queryMap["deletePolicy"]!.first,
          unittest.equals(arg_deletePolicy),
        );
        unittest.expect(
          queryMap["preview"]!.first,
          unittest.equals("$arg_preview"),
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
      final response = await res.patch(arg_request, arg_project, arg_deployment,
          createPolicy: arg_createPolicy,
          deletePolicy: arg_deletePolicy,
          preview: arg_preview,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_request = buildGlobalSetPolicyRequest();
      var arg_project = 'foo';
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GlobalSetPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGlobalSetPolicyRequest(obj as api.GlobalSetPolicyRequest);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/setIamPolicy', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resource'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/setIamPolicy"),
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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(
          arg_request, arg_project, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_request = buildDeploymentsStopRequest();
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeploymentsStopRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeploymentsStopRequest(obj as api.DeploymentsStopRequest);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/stop', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/stop"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.stop(arg_request, arg_project, arg_deployment,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_request = buildTestPermissionsRequest();
      var arg_project = 'foo';
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestPermissionsRequest(obj as api.TestPermissionsRequest);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/testIamPermissions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resource'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/testIamPermissions"),
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
        var resp = convert.json.encode(buildTestPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(
          arg_request, arg_project, arg_resource,
          $fields: arg_$fields);
      checkTestPermissionsResponse(response as api.TestPermissionsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).deployments;
      var arg_request = buildDeployment();
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_createPolicy = 'foo';
      var arg_deletePolicy = 'foo';
      var arg_preview = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Deployment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeployment(obj as api.Deployment);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
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
          queryMap["createPolicy"]!.first,
          unittest.equals(arg_createPolicy),
        );
        unittest.expect(
          queryMap["deletePolicy"]!.first,
          unittest.equals(arg_deletePolicy),
        );
        unittest.expect(
          queryMap["preview"]!.first,
          unittest.equals("$arg_preview"),
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
      final response = await res.update(
          arg_request, arg_project, arg_deployment,
          createPolicy: arg_createPolicy,
          deletePolicy: arg_deletePolicy,
          preview: arg_preview,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ManifestsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).manifests;
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_manifest = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/manifests/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/manifests/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_manifest'),
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
        var resp = convert.json.encode(buildManifest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_project, arg_deployment, arg_manifest,
          $fields: arg_$fields);
      checkManifest(response as api.Manifest);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).manifests;
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_filter = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/manifests', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/manifests"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildManifestsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project, arg_deployment,
          filter: arg_filter,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkManifestsListResponse(response as api.ManifestsListResponse);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).operations;
      var arg_project = 'foo';
      var arg_operation = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/operations/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/global/operations/"),
        );
        pathOffset += 19;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_operation'),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_project, arg_operation, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).operations;
      var arg_project = 'foo';
      var arg_filter = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/operations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/global/operations"),
        );
        pathOffset += 18;

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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildOperationsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          filter: arg_filter,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkOperationsListResponse(response as api.OperationsListResponse);
    });
  });

  unittest.group('resource-ResourcesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).resources;
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_resource = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/resources/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/resources/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resource'),
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
        var resp = convert.json.encode(buildResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_project, arg_deployment, arg_resource,
          $fields: arg_$fields);
      checkResource(response as api.Resource);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).resources;
      var arg_project = 'foo';
      var arg_deployment = 'foo';
      var arg_filter = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/global/deployments/"),
        );
        pathOffset += 20;
        index = path.indexOf('/resources', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deployment'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/resources"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildResourcesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project, arg_deployment,
          filter: arg_filter,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkResourcesListResponse(response as api.ResourcesListResponse);
    });
  });

  unittest.group('resource-TypesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DeploymentManagerApi(mock).types;
      var arg_project = 'foo';
      var arg_filter = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("deploymentmanager/v2/projects/"),
        );
        pathOffset += 30;
        index = path.indexOf('/global/types', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/global/types"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildTypesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          filter: arg_filter,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkTypesListResponse(response as api.TypesListResponse);
    });
  });
}

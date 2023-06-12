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

import 'package:googleapis/script/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.File> buildUnnamed1790() {
  var o = <api.File>[];
  o.add(buildFile());
  o.add(buildFile());
  return o;
}

void checkUnnamed1790(core.List<api.File> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFile(o[0] as api.File);
  checkFile(o[1] as api.File);
}

core.int buildCounterContent = 0;
api.Content buildContent() {
  var o = api.Content();
  buildCounterContent++;
  if (buildCounterContent < 3) {
    o.files = buildUnnamed1790();
    o.scriptId = 'foo';
  }
  buildCounterContent--;
  return o;
}

void checkContent(api.Content o) {
  buildCounterContent++;
  if (buildCounterContent < 3) {
    checkUnnamed1790(o.files!);
    unittest.expect(
      o.scriptId!,
      unittest.equals('foo'),
    );
  }
  buildCounterContent--;
}

core.int buildCounterCreateProjectRequest = 0;
api.CreateProjectRequest buildCreateProjectRequest() {
  var o = api.CreateProjectRequest();
  buildCounterCreateProjectRequest++;
  if (buildCounterCreateProjectRequest < 3) {
    o.parentId = 'foo';
    o.title = 'foo';
  }
  buildCounterCreateProjectRequest--;
  return o;
}

void checkCreateProjectRequest(api.CreateProjectRequest o) {
  buildCounterCreateProjectRequest++;
  if (buildCounterCreateProjectRequest < 3) {
    unittest.expect(
      o.parentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateProjectRequest--;
}

core.List<api.EntryPoint> buildUnnamed1791() {
  var o = <api.EntryPoint>[];
  o.add(buildEntryPoint());
  o.add(buildEntryPoint());
  return o;
}

void checkUnnamed1791(core.List<api.EntryPoint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntryPoint(o[0] as api.EntryPoint);
  checkEntryPoint(o[1] as api.EntryPoint);
}

core.int buildCounterDeployment = 0;
api.Deployment buildDeployment() {
  var o = api.Deployment();
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    o.deploymentConfig = buildDeploymentConfig();
    o.deploymentId = 'foo';
    o.entryPoints = buildUnnamed1791();
    o.updateTime = 'foo';
  }
  buildCounterDeployment--;
  return o;
}

void checkDeployment(api.Deployment o) {
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    checkDeploymentConfig(o.deploymentConfig! as api.DeploymentConfig);
    unittest.expect(
      o.deploymentId!,
      unittest.equals('foo'),
    );
    checkUnnamed1791(o.entryPoints!);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeployment--;
}

core.int buildCounterDeploymentConfig = 0;
api.DeploymentConfig buildDeploymentConfig() {
  var o = api.DeploymentConfig();
  buildCounterDeploymentConfig++;
  if (buildCounterDeploymentConfig < 3) {
    o.description = 'foo';
    o.manifestFileName = 'foo';
    o.scriptId = 'foo';
    o.versionNumber = 42;
  }
  buildCounterDeploymentConfig--;
  return o;
}

void checkDeploymentConfig(api.DeploymentConfig o) {
  buildCounterDeploymentConfig++;
  if (buildCounterDeploymentConfig < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manifestFileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scriptId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionNumber!,
      unittest.equals(42),
    );
  }
  buildCounterDeploymentConfig--;
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

core.int buildCounterEntryPoint = 0;
api.EntryPoint buildEntryPoint() {
  var o = api.EntryPoint();
  buildCounterEntryPoint++;
  if (buildCounterEntryPoint < 3) {
    o.addOn = buildGoogleAppsScriptTypeAddOnEntryPoint();
    o.entryPointType = 'foo';
    o.executionApi = buildGoogleAppsScriptTypeExecutionApiEntryPoint();
    o.webApp = buildGoogleAppsScriptTypeWebAppEntryPoint();
  }
  buildCounterEntryPoint--;
  return o;
}

void checkEntryPoint(api.EntryPoint o) {
  buildCounterEntryPoint++;
  if (buildCounterEntryPoint < 3) {
    checkGoogleAppsScriptTypeAddOnEntryPoint(
        o.addOn! as api.GoogleAppsScriptTypeAddOnEntryPoint);
    unittest.expect(
      o.entryPointType!,
      unittest.equals('foo'),
    );
    checkGoogleAppsScriptTypeExecutionApiEntryPoint(
        o.executionApi! as api.GoogleAppsScriptTypeExecutionApiEntryPoint);
    checkGoogleAppsScriptTypeWebAppEntryPoint(
        o.webApp! as api.GoogleAppsScriptTypeWebAppEntryPoint);
  }
  buildCounterEntryPoint--;
}

core.int buildCounterExecuteStreamResponse = 0;
api.ExecuteStreamResponse buildExecuteStreamResponse() {
  var o = api.ExecuteStreamResponse();
  buildCounterExecuteStreamResponse++;
  if (buildCounterExecuteStreamResponse < 3) {
    o.result = buildScriptExecutionResult();
  }
  buildCounterExecuteStreamResponse--;
  return o;
}

void checkExecuteStreamResponse(api.ExecuteStreamResponse o) {
  buildCounterExecuteStreamResponse++;
  if (buildCounterExecuteStreamResponse < 3) {
    checkScriptExecutionResult(o.result! as api.ScriptExecutionResult);
  }
  buildCounterExecuteStreamResponse--;
}

core.List<api.ScriptStackTraceElement> buildUnnamed1792() {
  var o = <api.ScriptStackTraceElement>[];
  o.add(buildScriptStackTraceElement());
  o.add(buildScriptStackTraceElement());
  return o;
}

void checkUnnamed1792(core.List<api.ScriptStackTraceElement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkScriptStackTraceElement(o[0] as api.ScriptStackTraceElement);
  checkScriptStackTraceElement(o[1] as api.ScriptStackTraceElement);
}

core.int buildCounterExecutionError = 0;
api.ExecutionError buildExecutionError() {
  var o = api.ExecutionError();
  buildCounterExecutionError++;
  if (buildCounterExecutionError < 3) {
    o.errorMessage = 'foo';
    o.errorType = 'foo';
    o.scriptStackTraceElements = buildUnnamed1792();
  }
  buildCounterExecutionError--;
  return o;
}

void checkExecutionError(api.ExecutionError o) {
  buildCounterExecutionError++;
  if (buildCounterExecutionError < 3) {
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorType!,
      unittest.equals('foo'),
    );
    checkUnnamed1792(o.scriptStackTraceElements!);
  }
  buildCounterExecutionError--;
}

core.List<core.Object> buildUnnamed1793() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1793(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o[0]) as core.Map;
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
  var casted2 = (o[1]) as core.Map;
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

core.int buildCounterExecutionRequest = 0;
api.ExecutionRequest buildExecutionRequest() {
  var o = api.ExecutionRequest();
  buildCounterExecutionRequest++;
  if (buildCounterExecutionRequest < 3) {
    o.devMode = true;
    o.function = 'foo';
    o.parameters = buildUnnamed1793();
    o.sessionState = 'foo';
  }
  buildCounterExecutionRequest--;
  return o;
}

void checkExecutionRequest(api.ExecutionRequest o) {
  buildCounterExecutionRequest++;
  if (buildCounterExecutionRequest < 3) {
    unittest.expect(o.devMode!, unittest.isTrue);
    unittest.expect(
      o.function!,
      unittest.equals('foo'),
    );
    checkUnnamed1793(o.parameters!);
    unittest.expect(
      o.sessionState!,
      unittest.equals('foo'),
    );
  }
  buildCounterExecutionRequest--;
}

core.int buildCounterExecutionResponse = 0;
api.ExecutionResponse buildExecutionResponse() {
  var o = api.ExecutionResponse();
  buildCounterExecutionResponse++;
  if (buildCounterExecutionResponse < 3) {
    o.result = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
  }
  buildCounterExecutionResponse--;
  return o;
}

void checkExecutionResponse(api.ExecutionResponse o) {
  buildCounterExecutionResponse++;
  if (buildCounterExecutionResponse < 3) {
    var casted3 = (o.result!) as core.Map;
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
  }
  buildCounterExecutionResponse--;
}

core.int buildCounterFile = 0;
api.File buildFile() {
  var o = api.File();
  buildCounterFile++;
  if (buildCounterFile < 3) {
    o.createTime = 'foo';
    o.functionSet = buildGoogleAppsScriptTypeFunctionSet();
    o.lastModifyUser = buildGoogleAppsScriptTypeUser();
    o.name = 'foo';
    o.source = 'foo';
    o.type = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterFile--;
  return o;
}

void checkFile(api.File o) {
  buildCounterFile++;
  if (buildCounterFile < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkGoogleAppsScriptTypeFunctionSet(
        o.functionSet! as api.GoogleAppsScriptTypeFunctionSet);
    checkGoogleAppsScriptTypeUser(
        o.lastModifyUser! as api.GoogleAppsScriptTypeUser);
    unittest.expect(
      o.name!,
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
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterFile--;
}

core.int buildCounterGoogleAppsScriptTypeAddOnEntryPoint = 0;
api.GoogleAppsScriptTypeAddOnEntryPoint
    buildGoogleAppsScriptTypeAddOnEntryPoint() {
  var o = api.GoogleAppsScriptTypeAddOnEntryPoint();
  buildCounterGoogleAppsScriptTypeAddOnEntryPoint++;
  if (buildCounterGoogleAppsScriptTypeAddOnEntryPoint < 3) {
    o.addOnType = 'foo';
    o.description = 'foo';
    o.helpUrl = 'foo';
    o.postInstallTipUrl = 'foo';
    o.reportIssueUrl = 'foo';
    o.title = 'foo';
  }
  buildCounterGoogleAppsScriptTypeAddOnEntryPoint--;
  return o;
}

void checkGoogleAppsScriptTypeAddOnEntryPoint(
    api.GoogleAppsScriptTypeAddOnEntryPoint o) {
  buildCounterGoogleAppsScriptTypeAddOnEntryPoint++;
  if (buildCounterGoogleAppsScriptTypeAddOnEntryPoint < 3) {
    unittest.expect(
      o.addOnType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.helpUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postInstallTipUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportIssueUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAppsScriptTypeAddOnEntryPoint--;
}

core.int buildCounterGoogleAppsScriptTypeExecutionApiConfig = 0;
api.GoogleAppsScriptTypeExecutionApiConfig
    buildGoogleAppsScriptTypeExecutionApiConfig() {
  var o = api.GoogleAppsScriptTypeExecutionApiConfig();
  buildCounterGoogleAppsScriptTypeExecutionApiConfig++;
  if (buildCounterGoogleAppsScriptTypeExecutionApiConfig < 3) {
    o.access = 'foo';
  }
  buildCounterGoogleAppsScriptTypeExecutionApiConfig--;
  return o;
}

void checkGoogleAppsScriptTypeExecutionApiConfig(
    api.GoogleAppsScriptTypeExecutionApiConfig o) {
  buildCounterGoogleAppsScriptTypeExecutionApiConfig++;
  if (buildCounterGoogleAppsScriptTypeExecutionApiConfig < 3) {
    unittest.expect(
      o.access!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAppsScriptTypeExecutionApiConfig--;
}

core.int buildCounterGoogleAppsScriptTypeExecutionApiEntryPoint = 0;
api.GoogleAppsScriptTypeExecutionApiEntryPoint
    buildGoogleAppsScriptTypeExecutionApiEntryPoint() {
  var o = api.GoogleAppsScriptTypeExecutionApiEntryPoint();
  buildCounterGoogleAppsScriptTypeExecutionApiEntryPoint++;
  if (buildCounterGoogleAppsScriptTypeExecutionApiEntryPoint < 3) {
    o.entryPointConfig = buildGoogleAppsScriptTypeExecutionApiConfig();
  }
  buildCounterGoogleAppsScriptTypeExecutionApiEntryPoint--;
  return o;
}

void checkGoogleAppsScriptTypeExecutionApiEntryPoint(
    api.GoogleAppsScriptTypeExecutionApiEntryPoint o) {
  buildCounterGoogleAppsScriptTypeExecutionApiEntryPoint++;
  if (buildCounterGoogleAppsScriptTypeExecutionApiEntryPoint < 3) {
    checkGoogleAppsScriptTypeExecutionApiConfig(
        o.entryPointConfig! as api.GoogleAppsScriptTypeExecutionApiConfig);
  }
  buildCounterGoogleAppsScriptTypeExecutionApiEntryPoint--;
}

core.int buildCounterGoogleAppsScriptTypeFunction = 0;
api.GoogleAppsScriptTypeFunction buildGoogleAppsScriptTypeFunction() {
  var o = api.GoogleAppsScriptTypeFunction();
  buildCounterGoogleAppsScriptTypeFunction++;
  if (buildCounterGoogleAppsScriptTypeFunction < 3) {
    o.name = 'foo';
  }
  buildCounterGoogleAppsScriptTypeFunction--;
  return o;
}

void checkGoogleAppsScriptTypeFunction(api.GoogleAppsScriptTypeFunction o) {
  buildCounterGoogleAppsScriptTypeFunction++;
  if (buildCounterGoogleAppsScriptTypeFunction < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAppsScriptTypeFunction--;
}

core.List<api.GoogleAppsScriptTypeFunction> buildUnnamed1794() {
  var o = <api.GoogleAppsScriptTypeFunction>[];
  o.add(buildGoogleAppsScriptTypeFunction());
  o.add(buildGoogleAppsScriptTypeFunction());
  return o;
}

void checkUnnamed1794(core.List<api.GoogleAppsScriptTypeFunction> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleAppsScriptTypeFunction(o[0] as api.GoogleAppsScriptTypeFunction);
  checkGoogleAppsScriptTypeFunction(o[1] as api.GoogleAppsScriptTypeFunction);
}

core.int buildCounterGoogleAppsScriptTypeFunctionSet = 0;
api.GoogleAppsScriptTypeFunctionSet buildGoogleAppsScriptTypeFunctionSet() {
  var o = api.GoogleAppsScriptTypeFunctionSet();
  buildCounterGoogleAppsScriptTypeFunctionSet++;
  if (buildCounterGoogleAppsScriptTypeFunctionSet < 3) {
    o.values = buildUnnamed1794();
  }
  buildCounterGoogleAppsScriptTypeFunctionSet--;
  return o;
}

void checkGoogleAppsScriptTypeFunctionSet(
    api.GoogleAppsScriptTypeFunctionSet o) {
  buildCounterGoogleAppsScriptTypeFunctionSet++;
  if (buildCounterGoogleAppsScriptTypeFunctionSet < 3) {
    checkUnnamed1794(o.values!);
  }
  buildCounterGoogleAppsScriptTypeFunctionSet--;
}

core.int buildCounterGoogleAppsScriptTypeProcess = 0;
api.GoogleAppsScriptTypeProcess buildGoogleAppsScriptTypeProcess() {
  var o = api.GoogleAppsScriptTypeProcess();
  buildCounterGoogleAppsScriptTypeProcess++;
  if (buildCounterGoogleAppsScriptTypeProcess < 3) {
    o.duration = 'foo';
    o.functionName = 'foo';
    o.processStatus = 'foo';
    o.processType = 'foo';
    o.projectName = 'foo';
    o.startTime = 'foo';
    o.userAccessLevel = 'foo';
  }
  buildCounterGoogleAppsScriptTypeProcess--;
  return o;
}

void checkGoogleAppsScriptTypeProcess(api.GoogleAppsScriptTypeProcess o) {
  buildCounterGoogleAppsScriptTypeProcess++;
  if (buildCounterGoogleAppsScriptTypeProcess < 3) {
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.functionName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.processStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.processType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userAccessLevel!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAppsScriptTypeProcess--;
}

core.int buildCounterGoogleAppsScriptTypeUser = 0;
api.GoogleAppsScriptTypeUser buildGoogleAppsScriptTypeUser() {
  var o = api.GoogleAppsScriptTypeUser();
  buildCounterGoogleAppsScriptTypeUser++;
  if (buildCounterGoogleAppsScriptTypeUser < 3) {
    o.domain = 'foo';
    o.email = 'foo';
    o.name = 'foo';
    o.photoUrl = 'foo';
  }
  buildCounterGoogleAppsScriptTypeUser--;
  return o;
}

void checkGoogleAppsScriptTypeUser(api.GoogleAppsScriptTypeUser o) {
  buildCounterGoogleAppsScriptTypeUser++;
  if (buildCounterGoogleAppsScriptTypeUser < 3) {
    unittest.expect(
      o.domain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAppsScriptTypeUser--;
}

core.int buildCounterGoogleAppsScriptTypeWebAppConfig = 0;
api.GoogleAppsScriptTypeWebAppConfig buildGoogleAppsScriptTypeWebAppConfig() {
  var o = api.GoogleAppsScriptTypeWebAppConfig();
  buildCounterGoogleAppsScriptTypeWebAppConfig++;
  if (buildCounterGoogleAppsScriptTypeWebAppConfig < 3) {
    o.access = 'foo';
    o.executeAs = 'foo';
  }
  buildCounterGoogleAppsScriptTypeWebAppConfig--;
  return o;
}

void checkGoogleAppsScriptTypeWebAppConfig(
    api.GoogleAppsScriptTypeWebAppConfig o) {
  buildCounterGoogleAppsScriptTypeWebAppConfig++;
  if (buildCounterGoogleAppsScriptTypeWebAppConfig < 3) {
    unittest.expect(
      o.access!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.executeAs!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAppsScriptTypeWebAppConfig--;
}

core.int buildCounterGoogleAppsScriptTypeWebAppEntryPoint = 0;
api.GoogleAppsScriptTypeWebAppEntryPoint
    buildGoogleAppsScriptTypeWebAppEntryPoint() {
  var o = api.GoogleAppsScriptTypeWebAppEntryPoint();
  buildCounterGoogleAppsScriptTypeWebAppEntryPoint++;
  if (buildCounterGoogleAppsScriptTypeWebAppEntryPoint < 3) {
    o.entryPointConfig = buildGoogleAppsScriptTypeWebAppConfig();
    o.url = 'foo';
  }
  buildCounterGoogleAppsScriptTypeWebAppEntryPoint--;
  return o;
}

void checkGoogleAppsScriptTypeWebAppEntryPoint(
    api.GoogleAppsScriptTypeWebAppEntryPoint o) {
  buildCounterGoogleAppsScriptTypeWebAppEntryPoint++;
  if (buildCounterGoogleAppsScriptTypeWebAppEntryPoint < 3) {
    checkGoogleAppsScriptTypeWebAppConfig(
        o.entryPointConfig! as api.GoogleAppsScriptTypeWebAppConfig);
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAppsScriptTypeWebAppEntryPoint--;
}

core.List<api.Deployment> buildUnnamed1795() {
  var o = <api.Deployment>[];
  o.add(buildDeployment());
  o.add(buildDeployment());
  return o;
}

void checkUnnamed1795(core.List<api.Deployment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeployment(o[0] as api.Deployment);
  checkDeployment(o[1] as api.Deployment);
}

core.int buildCounterListDeploymentsResponse = 0;
api.ListDeploymentsResponse buildListDeploymentsResponse() {
  var o = api.ListDeploymentsResponse();
  buildCounterListDeploymentsResponse++;
  if (buildCounterListDeploymentsResponse < 3) {
    o.deployments = buildUnnamed1795();
    o.nextPageToken = 'foo';
  }
  buildCounterListDeploymentsResponse--;
  return o;
}

void checkListDeploymentsResponse(api.ListDeploymentsResponse o) {
  buildCounterListDeploymentsResponse++;
  if (buildCounterListDeploymentsResponse < 3) {
    checkUnnamed1795(o.deployments!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDeploymentsResponse--;
}

core.List<api.GoogleAppsScriptTypeProcess> buildUnnamed1796() {
  var o = <api.GoogleAppsScriptTypeProcess>[];
  o.add(buildGoogleAppsScriptTypeProcess());
  o.add(buildGoogleAppsScriptTypeProcess());
  return o;
}

void checkUnnamed1796(core.List<api.GoogleAppsScriptTypeProcess> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleAppsScriptTypeProcess(o[0] as api.GoogleAppsScriptTypeProcess);
  checkGoogleAppsScriptTypeProcess(o[1] as api.GoogleAppsScriptTypeProcess);
}

core.int buildCounterListScriptProcessesResponse = 0;
api.ListScriptProcessesResponse buildListScriptProcessesResponse() {
  var o = api.ListScriptProcessesResponse();
  buildCounterListScriptProcessesResponse++;
  if (buildCounterListScriptProcessesResponse < 3) {
    o.nextPageToken = 'foo';
    o.processes = buildUnnamed1796();
  }
  buildCounterListScriptProcessesResponse--;
  return o;
}

void checkListScriptProcessesResponse(api.ListScriptProcessesResponse o) {
  buildCounterListScriptProcessesResponse++;
  if (buildCounterListScriptProcessesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1796(o.processes!);
  }
  buildCounterListScriptProcessesResponse--;
}

core.List<api.GoogleAppsScriptTypeProcess> buildUnnamed1797() {
  var o = <api.GoogleAppsScriptTypeProcess>[];
  o.add(buildGoogleAppsScriptTypeProcess());
  o.add(buildGoogleAppsScriptTypeProcess());
  return o;
}

void checkUnnamed1797(core.List<api.GoogleAppsScriptTypeProcess> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleAppsScriptTypeProcess(o[0] as api.GoogleAppsScriptTypeProcess);
  checkGoogleAppsScriptTypeProcess(o[1] as api.GoogleAppsScriptTypeProcess);
}

core.int buildCounterListUserProcessesResponse = 0;
api.ListUserProcessesResponse buildListUserProcessesResponse() {
  var o = api.ListUserProcessesResponse();
  buildCounterListUserProcessesResponse++;
  if (buildCounterListUserProcessesResponse < 3) {
    o.nextPageToken = 'foo';
    o.processes = buildUnnamed1797();
  }
  buildCounterListUserProcessesResponse--;
  return o;
}

void checkListUserProcessesResponse(api.ListUserProcessesResponse o) {
  buildCounterListUserProcessesResponse++;
  if (buildCounterListUserProcessesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1797(o.processes!);
  }
  buildCounterListUserProcessesResponse--;
}

core.List<api.Value> buildUnnamed1798() {
  var o = <api.Value>[];
  o.add(buildValue());
  o.add(buildValue());
  return o;
}

void checkUnnamed1798(core.List<api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o[0] as api.Value);
  checkValue(o[1] as api.Value);
}

core.int buildCounterListValue = 0;
api.ListValue buildListValue() {
  var o = api.ListValue();
  buildCounterListValue++;
  if (buildCounterListValue < 3) {
    o.values = buildUnnamed1798();
  }
  buildCounterListValue--;
  return o;
}

void checkListValue(api.ListValue o) {
  buildCounterListValue++;
  if (buildCounterListValue < 3) {
    checkUnnamed1798(o.values!);
  }
  buildCounterListValue--;
}

core.List<api.Version> buildUnnamed1799() {
  var o = <api.Version>[];
  o.add(buildVersion());
  o.add(buildVersion());
  return o;
}

void checkUnnamed1799(core.List<api.Version> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVersion(o[0] as api.Version);
  checkVersion(o[1] as api.Version);
}

core.int buildCounterListVersionsResponse = 0;
api.ListVersionsResponse buildListVersionsResponse() {
  var o = api.ListVersionsResponse();
  buildCounterListVersionsResponse++;
  if (buildCounterListVersionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.versions = buildUnnamed1799();
  }
  buildCounterListVersionsResponse--;
  return o;
}

void checkListVersionsResponse(api.ListVersionsResponse o) {
  buildCounterListVersionsResponse++;
  if (buildCounterListVersionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1799(o.versions!);
  }
  buildCounterListVersionsResponse--;
}

core.List<api.MetricsValue> buildUnnamed1800() {
  var o = <api.MetricsValue>[];
  o.add(buildMetricsValue());
  o.add(buildMetricsValue());
  return o;
}

void checkUnnamed1800(core.List<api.MetricsValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricsValue(o[0] as api.MetricsValue);
  checkMetricsValue(o[1] as api.MetricsValue);
}

core.List<api.MetricsValue> buildUnnamed1801() {
  var o = <api.MetricsValue>[];
  o.add(buildMetricsValue());
  o.add(buildMetricsValue());
  return o;
}

void checkUnnamed1801(core.List<api.MetricsValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricsValue(o[0] as api.MetricsValue);
  checkMetricsValue(o[1] as api.MetricsValue);
}

core.List<api.MetricsValue> buildUnnamed1802() {
  var o = <api.MetricsValue>[];
  o.add(buildMetricsValue());
  o.add(buildMetricsValue());
  return o;
}

void checkUnnamed1802(core.List<api.MetricsValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricsValue(o[0] as api.MetricsValue);
  checkMetricsValue(o[1] as api.MetricsValue);
}

core.int buildCounterMetrics = 0;
api.Metrics buildMetrics() {
  var o = api.Metrics();
  buildCounterMetrics++;
  if (buildCounterMetrics < 3) {
    o.activeUsers = buildUnnamed1800();
    o.failedExecutions = buildUnnamed1801();
    o.totalExecutions = buildUnnamed1802();
  }
  buildCounterMetrics--;
  return o;
}

void checkMetrics(api.Metrics o) {
  buildCounterMetrics++;
  if (buildCounterMetrics < 3) {
    checkUnnamed1800(o.activeUsers!);
    checkUnnamed1801(o.failedExecutions!);
    checkUnnamed1802(o.totalExecutions!);
  }
  buildCounterMetrics--;
}

core.int buildCounterMetricsValue = 0;
api.MetricsValue buildMetricsValue() {
  var o = api.MetricsValue();
  buildCounterMetricsValue++;
  if (buildCounterMetricsValue < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
    o.value = 'foo';
  }
  buildCounterMetricsValue--;
  return o;
}

void checkMetricsValue(api.MetricsValue o) {
  buildCounterMetricsValue++;
  if (buildCounterMetricsValue < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetricsValue--;
}

core.Map<core.String, core.Object> buildUnnamed1803() {
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

void checkUnnamed1803(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted4 = (o['x']!) as core.Map;
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
  var casted5 = (o['y']!) as core.Map;
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
}

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.response = buildUnnamed1803();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed1803(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterProject = 0;
api.Project buildProject() {
  var o = api.Project();
  buildCounterProject++;
  if (buildCounterProject < 3) {
    o.createTime = 'foo';
    o.creator = buildGoogleAppsScriptTypeUser();
    o.lastModifyUser = buildGoogleAppsScriptTypeUser();
    o.parentId = 'foo';
    o.scriptId = 'foo';
    o.title = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterProject--;
  return o;
}

void checkProject(api.Project o) {
  buildCounterProject++;
  if (buildCounterProject < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkGoogleAppsScriptTypeUser(o.creator! as api.GoogleAppsScriptTypeUser);
    checkGoogleAppsScriptTypeUser(
        o.lastModifyUser! as api.GoogleAppsScriptTypeUser);
    unittest.expect(
      o.parentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scriptId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterProject--;
}

core.int buildCounterScriptExecutionResult = 0;
api.ScriptExecutionResult buildScriptExecutionResult() {
  var o = api.ScriptExecutionResult();
  buildCounterScriptExecutionResult++;
  if (buildCounterScriptExecutionResult < 3) {
    o.returnValue = buildValue();
  }
  buildCounterScriptExecutionResult--;
  return o;
}

void checkScriptExecutionResult(api.ScriptExecutionResult o) {
  buildCounterScriptExecutionResult++;
  if (buildCounterScriptExecutionResult < 3) {
    checkValue(o.returnValue! as api.Value);
  }
  buildCounterScriptExecutionResult--;
}

core.int buildCounterScriptStackTraceElement = 0;
api.ScriptStackTraceElement buildScriptStackTraceElement() {
  var o = api.ScriptStackTraceElement();
  buildCounterScriptStackTraceElement++;
  if (buildCounterScriptStackTraceElement < 3) {
    o.function = 'foo';
    o.lineNumber = 42;
  }
  buildCounterScriptStackTraceElement--;
  return o;
}

void checkScriptStackTraceElement(api.ScriptStackTraceElement o) {
  buildCounterScriptStackTraceElement++;
  if (buildCounterScriptStackTraceElement < 3) {
    unittest.expect(
      o.function!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lineNumber!,
      unittest.equals(42),
    );
  }
  buildCounterScriptStackTraceElement--;
}

core.Map<core.String, core.Object> buildUnnamed1804() {
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

void checkUnnamed1804(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted6 = (o['x']!) as core.Map;
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
  var casted7 = (o['y']!) as core.Map;
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
}

core.List<core.Map<core.String, core.Object>> buildUnnamed1805() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed1804());
  o.add(buildUnnamed1804());
  return o;
}

void checkUnnamed1805(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1804(o[0]);
  checkUnnamed1804(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed1805();
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
    checkUnnamed1805(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.Map<core.String, api.Value> buildUnnamed1806() {
  var o = <core.String, api.Value>{};
  o['x'] = buildValue();
  o['y'] = buildValue();
  return o;
}

void checkUnnamed1806(core.Map<core.String, api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o['x']! as api.Value);
  checkValue(o['y']! as api.Value);
}

core.int buildCounterStruct = 0;
api.Struct buildStruct() {
  var o = api.Struct();
  buildCounterStruct++;
  if (buildCounterStruct < 3) {
    o.fields = buildUnnamed1806();
  }
  buildCounterStruct--;
  return o;
}

void checkStruct(api.Struct o) {
  buildCounterStruct++;
  if (buildCounterStruct < 3) {
    checkUnnamed1806(o.fields!);
  }
  buildCounterStruct--;
}

core.int buildCounterUpdateDeploymentRequest = 0;
api.UpdateDeploymentRequest buildUpdateDeploymentRequest() {
  var o = api.UpdateDeploymentRequest();
  buildCounterUpdateDeploymentRequest++;
  if (buildCounterUpdateDeploymentRequest < 3) {
    o.deploymentConfig = buildDeploymentConfig();
  }
  buildCounterUpdateDeploymentRequest--;
  return o;
}

void checkUpdateDeploymentRequest(api.UpdateDeploymentRequest o) {
  buildCounterUpdateDeploymentRequest++;
  if (buildCounterUpdateDeploymentRequest < 3) {
    checkDeploymentConfig(o.deploymentConfig! as api.DeploymentConfig);
  }
  buildCounterUpdateDeploymentRequest--;
}

core.Map<core.String, core.Object> buildUnnamed1807() {
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

void checkUnnamed1807(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted8 = (o['x']!) as core.Map;
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
  var casted9 = (o['y']!) as core.Map;
  unittest.expect(casted9, unittest.hasLength(3));
  unittest.expect(
    casted9['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted9['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted9['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterValue = 0;
api.Value buildValue() {
  var o = api.Value();
  buildCounterValue++;
  if (buildCounterValue < 3) {
    o.boolValue = true;
    o.bytesValue = 'foo';
    o.dateValue = 'foo';
    o.listValue = buildListValue();
    o.nullValue = 'foo';
    o.numberValue = 42.0;
    o.protoValue = buildUnnamed1807();
    o.stringValue = 'foo';
    o.structValue = buildStruct();
  }
  buildCounterValue--;
  return o;
}

void checkValue(api.Value o) {
  buildCounterValue++;
  if (buildCounterValue < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    unittest.expect(
      o.bytesValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dateValue!,
      unittest.equals('foo'),
    );
    checkListValue(o.listValue! as api.ListValue);
    unittest.expect(
      o.nullValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numberValue!,
      unittest.equals(42.0),
    );
    checkUnnamed1807(o.protoValue!);
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
    checkStruct(o.structValue! as api.Struct);
  }
  buildCounterValue--;
}

core.int buildCounterVersion = 0;
api.Version buildVersion() {
  var o = api.Version();
  buildCounterVersion++;
  if (buildCounterVersion < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.scriptId = 'foo';
    o.versionNumber = 42;
  }
  buildCounterVersion--;
  return o;
}

void checkVersion(api.Version o) {
  buildCounterVersion++;
  if (buildCounterVersion < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scriptId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionNumber!,
      unittest.equals(42),
    );
  }
  buildCounterVersion--;
}

core.List<core.String> buildUnnamed1808() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1808(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1809() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1809(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1810() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1810(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1811() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1811(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1812() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1812(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1813() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1813(core.List<core.String> o) {
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
  unittest.group('obj-schema-Content', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Content.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkContent(od as api.Content);
    });
  });

  unittest.group('obj-schema-CreateProjectRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateProjectRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateProjectRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateProjectRequest(od as api.CreateProjectRequest);
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

  unittest.group('obj-schema-DeploymentConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentConfig(od as api.DeploymentConfig);
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

  unittest.group('obj-schema-EntryPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntryPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.EntryPoint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEntryPoint(od as api.EntryPoint);
    });
  });

  unittest.group('obj-schema-ExecuteStreamResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecuteStreamResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecuteStreamResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecuteStreamResponse(od as api.ExecuteStreamResponse);
    });
  });

  unittest.group('obj-schema-ExecutionError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecutionError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecutionError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecutionError(od as api.ExecutionError);
    });
  });

  unittest.group('obj-schema-ExecutionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecutionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecutionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecutionRequest(od as api.ExecutionRequest);
    });
  });

  unittest.group('obj-schema-ExecutionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecutionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecutionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecutionResponse(od as api.ExecutionResponse);
    });
  });

  unittest.group('obj-schema-File', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.File.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFile(od as api.File);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeAddOnEntryPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeAddOnEntryPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeAddOnEntryPoint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeAddOnEntryPoint(
          od as api.GoogleAppsScriptTypeAddOnEntryPoint);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeExecutionApiConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeExecutionApiConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeExecutionApiConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeExecutionApiConfig(
          od as api.GoogleAppsScriptTypeExecutionApiConfig);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeExecutionApiEntryPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeExecutionApiEntryPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeExecutionApiEntryPoint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeExecutionApiEntryPoint(
          od as api.GoogleAppsScriptTypeExecutionApiEntryPoint);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeFunction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeFunction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeFunction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeFunction(od as api.GoogleAppsScriptTypeFunction);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeFunctionSet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeFunctionSet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeFunctionSet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeFunctionSet(
          od as api.GoogleAppsScriptTypeFunctionSet);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeProcess', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeProcess();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeProcess.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeProcess(od as api.GoogleAppsScriptTypeProcess);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeUser', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeUser.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeUser(od as api.GoogleAppsScriptTypeUser);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeWebAppConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeWebAppConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeWebAppConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeWebAppConfig(
          od as api.GoogleAppsScriptTypeWebAppConfig);
    });
  });

  unittest.group('obj-schema-GoogleAppsScriptTypeWebAppEntryPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppsScriptTypeWebAppEntryPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppsScriptTypeWebAppEntryPoint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppsScriptTypeWebAppEntryPoint(
          od as api.GoogleAppsScriptTypeWebAppEntryPoint);
    });
  });

  unittest.group('obj-schema-ListDeploymentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDeploymentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDeploymentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDeploymentsResponse(od as api.ListDeploymentsResponse);
    });
  });

  unittest.group('obj-schema-ListScriptProcessesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListScriptProcessesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListScriptProcessesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListScriptProcessesResponse(od as api.ListScriptProcessesResponse);
    });
  });

  unittest.group('obj-schema-ListUserProcessesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListUserProcessesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListUserProcessesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListUserProcessesResponse(od as api.ListUserProcessesResponse);
    });
  });

  unittest.group('obj-schema-ListValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ListValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkListValue(od as api.ListValue);
    });
  });

  unittest.group('obj-schema-ListVersionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListVersionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListVersionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListVersionsResponse(od as api.ListVersionsResponse);
    });
  });

  unittest.group('obj-schema-Metrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Metrics.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMetrics(od as api.Metrics);
    });
  });

  unittest.group('obj-schema-MetricsValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetricsValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetricsValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetricsValue(od as api.MetricsValue);
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

  unittest.group('obj-schema-Project', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Project.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProject(od as api.Project);
    });
  });

  unittest.group('obj-schema-ScriptExecutionResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScriptExecutionResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScriptExecutionResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScriptExecutionResult(od as api.ScriptExecutionResult);
    });
  });

  unittest.group('obj-schema-ScriptStackTraceElement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScriptStackTraceElement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScriptStackTraceElement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScriptStackTraceElement(od as api.ScriptStackTraceElement);
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

  unittest.group('obj-schema-Struct', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStruct();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Struct.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStruct(od as api.Struct);
    });
  });

  unittest.group('obj-schema-UpdateDeploymentRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDeploymentRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDeploymentRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDeploymentRequest(od as api.UpdateDeploymentRequest);
    });
  });

  unittest.group('obj-schema-Value', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Value.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkValue(od as api.Value);
    });
  });

  unittest.group('obj-schema-Version', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Version.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVersion(od as api.Version);
    });
  });

  unittest.group('resource-ProcessesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).processes;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_userProcessFilter_deploymentId = 'foo';
      var arg_userProcessFilter_endTime = 'foo';
      var arg_userProcessFilter_functionName = 'foo';
      var arg_userProcessFilter_projectName = 'foo';
      var arg_userProcessFilter_scriptId = 'foo';
      var arg_userProcessFilter_startTime = 'foo';
      var arg_userProcessFilter_statuses = buildUnnamed1808();
      var arg_userProcessFilter_types = buildUnnamed1809();
      var arg_userProcessFilter_userAccessLevels = buildUnnamed1810();
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
          unittest.equals("v1/processes"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["userProcessFilter.deploymentId"]!.first,
          unittest.equals(arg_userProcessFilter_deploymentId),
        );
        unittest.expect(
          queryMap["userProcessFilter.endTime"]!.first,
          unittest.equals(arg_userProcessFilter_endTime),
        );
        unittest.expect(
          queryMap["userProcessFilter.functionName"]!.first,
          unittest.equals(arg_userProcessFilter_functionName),
        );
        unittest.expect(
          queryMap["userProcessFilter.projectName"]!.first,
          unittest.equals(arg_userProcessFilter_projectName),
        );
        unittest.expect(
          queryMap["userProcessFilter.scriptId"]!.first,
          unittest.equals(arg_userProcessFilter_scriptId),
        );
        unittest.expect(
          queryMap["userProcessFilter.startTime"]!.first,
          unittest.equals(arg_userProcessFilter_startTime),
        );
        unittest.expect(
          queryMap["userProcessFilter.statuses"]!,
          unittest.equals(arg_userProcessFilter_statuses),
        );
        unittest.expect(
          queryMap["userProcessFilter.types"]!,
          unittest.equals(arg_userProcessFilter_types),
        );
        unittest.expect(
          queryMap["userProcessFilter.userAccessLevels"]!,
          unittest.equals(arg_userProcessFilter_userAccessLevels),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListUserProcessesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          userProcessFilter_deploymentId: arg_userProcessFilter_deploymentId,
          userProcessFilter_endTime: arg_userProcessFilter_endTime,
          userProcessFilter_functionName: arg_userProcessFilter_functionName,
          userProcessFilter_projectName: arg_userProcessFilter_projectName,
          userProcessFilter_scriptId: arg_userProcessFilter_scriptId,
          userProcessFilter_startTime: arg_userProcessFilter_startTime,
          userProcessFilter_statuses: arg_userProcessFilter_statuses,
          userProcessFilter_types: arg_userProcessFilter_types,
          userProcessFilter_userAccessLevels:
              arg_userProcessFilter_userAccessLevels,
          $fields: arg_$fields);
      checkListUserProcessesResponse(response as api.ListUserProcessesResponse);
    });

    unittest.test('method--listScriptProcesses', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).processes;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_scriptId = 'foo';
      var arg_scriptProcessFilter_deploymentId = 'foo';
      var arg_scriptProcessFilter_endTime = 'foo';
      var arg_scriptProcessFilter_functionName = 'foo';
      var arg_scriptProcessFilter_startTime = 'foo';
      var arg_scriptProcessFilter_statuses = buildUnnamed1811();
      var arg_scriptProcessFilter_types = buildUnnamed1812();
      var arg_scriptProcessFilter_userAccessLevels = buildUnnamed1813();
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
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("v1/processes:listScriptProcesses"),
        );
        pathOffset += 32;

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
          queryMap["scriptId"]!.first,
          unittest.equals(arg_scriptId),
        );
        unittest.expect(
          queryMap["scriptProcessFilter.deploymentId"]!.first,
          unittest.equals(arg_scriptProcessFilter_deploymentId),
        );
        unittest.expect(
          queryMap["scriptProcessFilter.endTime"]!.first,
          unittest.equals(arg_scriptProcessFilter_endTime),
        );
        unittest.expect(
          queryMap["scriptProcessFilter.functionName"]!.first,
          unittest.equals(arg_scriptProcessFilter_functionName),
        );
        unittest.expect(
          queryMap["scriptProcessFilter.startTime"]!.first,
          unittest.equals(arg_scriptProcessFilter_startTime),
        );
        unittest.expect(
          queryMap["scriptProcessFilter.statuses"]!,
          unittest.equals(arg_scriptProcessFilter_statuses),
        );
        unittest.expect(
          queryMap["scriptProcessFilter.types"]!,
          unittest.equals(arg_scriptProcessFilter_types),
        );
        unittest.expect(
          queryMap["scriptProcessFilter.userAccessLevels"]!,
          unittest.equals(arg_scriptProcessFilter_userAccessLevels),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListScriptProcessesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listScriptProcesses(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          scriptId: arg_scriptId,
          scriptProcessFilter_deploymentId:
              arg_scriptProcessFilter_deploymentId,
          scriptProcessFilter_endTime: arg_scriptProcessFilter_endTime,
          scriptProcessFilter_functionName:
              arg_scriptProcessFilter_functionName,
          scriptProcessFilter_startTime: arg_scriptProcessFilter_startTime,
          scriptProcessFilter_statuses: arg_scriptProcessFilter_statuses,
          scriptProcessFilter_types: arg_scriptProcessFilter_types,
          scriptProcessFilter_userAccessLevels:
              arg_scriptProcessFilter_userAccessLevels,
          $fields: arg_$fields);
      checkListScriptProcessesResponse(
          response as api.ListScriptProcessesResponse);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects;
      var arg_request = buildCreateProjectRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateProjectRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateProjectRequest(obj as api.CreateProjectRequest);

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
          unittest.equals("v1/projects"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildProject());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkProject(response as api.Project);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects;
      var arg_scriptId = 'foo';
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
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
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
        var resp = convert.json.encode(buildProject());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_scriptId, $fields: arg_$fields);
      checkProject(response as api.Project);
    });

    unittest.test('method--getContent', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects;
      var arg_scriptId = 'foo';
      var arg_versionNumber = 42;
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
        index = path.indexOf('/content', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/content"),
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
          core.int.parse(queryMap["versionNumber"]!.first),
          unittest.equals(arg_versionNumber),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildContent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getContent(arg_scriptId,
          versionNumber: arg_versionNumber, $fields: arg_$fields);
      checkContent(response as api.Content);
    });

    unittest.test('method--getMetrics', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects;
      var arg_scriptId = 'foo';
      var arg_metricsFilter_deploymentId = 'foo';
      var arg_metricsGranularity = 'foo';
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
        index = path.indexOf('/metrics', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/metrics"),
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
          queryMap["metricsFilter.deploymentId"]!.first,
          unittest.equals(arg_metricsFilter_deploymentId),
        );
        unittest.expect(
          queryMap["metricsGranularity"]!.first,
          unittest.equals(arg_metricsGranularity),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMetrics());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getMetrics(arg_scriptId,
          metricsFilter_deploymentId: arg_metricsFilter_deploymentId,
          metricsGranularity: arg_metricsGranularity,
          $fields: arg_$fields);
      checkMetrics(response as api.Metrics);
    });

    unittest.test('method--updateContent', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects;
      var arg_request = buildContent();
      var arg_scriptId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Content.fromJson(json as core.Map<core.String, core.dynamic>);
        checkContent(obj as api.Content);

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
        index = path.indexOf('/content', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/content"),
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
        var resp = convert.json.encode(buildContent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateContent(arg_request, arg_scriptId,
          $fields: arg_$fields);
      checkContent(response as api.Content);
    });
  });

  unittest.group('resource-ProjectsDeploymentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.deployments;
      var arg_request = buildDeploymentConfig();
      var arg_scriptId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeploymentConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeploymentConfig(obj as api.DeploymentConfig);

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
        index = path.indexOf('/deployments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/deployments"),
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
        var resp = convert.json.encode(buildDeployment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_scriptId, $fields: arg_$fields);
      checkDeployment(response as api.Deployment);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.deployments;
      var arg_scriptId = 'foo';
      var arg_deploymentId = 'foo';
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
        index = path.indexOf('/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/deployments/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deploymentId'),
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_scriptId, arg_deploymentId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.deployments;
      var arg_scriptId = 'foo';
      var arg_deploymentId = 'foo';
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
        index = path.indexOf('/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/deployments/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deploymentId'),
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
          await res.get(arg_scriptId, arg_deploymentId, $fields: arg_$fields);
      checkDeployment(response as api.Deployment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.deployments;
      var arg_scriptId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/deployments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/deployments"),
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
        var resp = convert.json.encode(buildListDeploymentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_scriptId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDeploymentsResponse(response as api.ListDeploymentsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.deployments;
      var arg_request = buildUpdateDeploymentRequest();
      var arg_scriptId = 'foo';
      var arg_deploymentId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateDeploymentRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateDeploymentRequest(obj as api.UpdateDeploymentRequest);

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
        index = path.indexOf('/deployments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/deployments/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deploymentId'),
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
      final response = await res.update(
          arg_request, arg_scriptId, arg_deploymentId,
          $fields: arg_$fields);
      checkDeployment(response as api.Deployment);
    });
  });

  unittest.group('resource-ProjectsVersionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.versions;
      var arg_request = buildVersion();
      var arg_scriptId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Version.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVersion(obj as api.Version);

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
        index = path.indexOf('/versions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/versions"),
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
        var resp = convert.json.encode(buildVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_scriptId, $fields: arg_$fields);
      checkVersion(response as api.Version);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.versions;
      var arg_scriptId = 'foo';
      var arg_versionNumber = 42;
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
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionNumber'),
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
        var resp = convert.json.encode(buildVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_scriptId, arg_versionNumber, $fields: arg_$fields);
      checkVersion(response as api.Version);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).projects.versions;
      var arg_scriptId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/versions"),
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
        var resp = convert.json.encode(buildListVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_scriptId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListVersionsResponse(response as api.ListVersionsResponse);
    });
  });

  unittest.group('resource-ScriptsResource', () {
    unittest.test('method--run', () async {
      var mock = HttpServerMock();
      var res = api.ScriptApi(mock).scripts;
      var arg_request = buildExecutionRequest();
      var arg_scriptId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExecutionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExecutionRequest(obj as api.ExecutionRequest);

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
          unittest.equals("v1/scripts/"),
        );
        pathOffset += 11;
        index = path.indexOf(':run', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_scriptId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 4),
          unittest.equals(":run"),
        );
        pathOffset += 4;

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
          await res.run(arg_request, arg_scriptId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });
}

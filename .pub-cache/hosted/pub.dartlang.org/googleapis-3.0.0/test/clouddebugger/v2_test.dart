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

import 'package:googleapis/clouddebugger/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAliasContext = 0;
api.AliasContext buildAliasContext() {
  var o = api.AliasContext();
  buildCounterAliasContext++;
  if (buildCounterAliasContext < 3) {
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterAliasContext--;
  return o;
}

void checkAliasContext(api.AliasContext o) {
  buildCounterAliasContext++;
  if (buildCounterAliasContext < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterAliasContext--;
}

core.List<api.Variable> buildUnnamed4772() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed4772(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.List<core.String> buildUnnamed4773() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4773(core.List<core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed4774() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4774(core.Map<core.String, core.String> o) {
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

core.List<api.StackFrame> buildUnnamed4775() {
  var o = <api.StackFrame>[];
  o.add(buildStackFrame());
  o.add(buildStackFrame());
  return o;
}

void checkUnnamed4775(core.List<api.StackFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStackFrame(o[0] as api.StackFrame);
  checkStackFrame(o[1] as api.StackFrame);
}

core.List<api.Variable> buildUnnamed4776() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed4776(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterBreakpoint = 0;
api.Breakpoint buildBreakpoint() {
  var o = api.Breakpoint();
  buildCounterBreakpoint++;
  if (buildCounterBreakpoint < 3) {
    o.action = 'foo';
    o.canaryExpireTime = 'foo';
    o.condition = 'foo';
    o.createTime = 'foo';
    o.evaluatedExpressions = buildUnnamed4772();
    o.expressions = buildUnnamed4773();
    o.finalTime = 'foo';
    o.id = 'foo';
    o.isFinalState = true;
    o.labels = buildUnnamed4774();
    o.location = buildSourceLocation();
    o.logLevel = 'foo';
    o.logMessageFormat = 'foo';
    o.stackFrames = buildUnnamed4775();
    o.state = 'foo';
    o.status = buildStatusMessage();
    o.userEmail = 'foo';
    o.variableTable = buildUnnamed4776();
  }
  buildCounterBreakpoint--;
  return o;
}

void checkBreakpoint(api.Breakpoint o) {
  buildCounterBreakpoint++;
  if (buildCounterBreakpoint < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.canaryExpireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.condition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkUnnamed4772(o.evaluatedExpressions!);
    checkUnnamed4773(o.expressions!);
    unittest.expect(
      o.finalTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isFinalState!, unittest.isTrue);
    checkUnnamed4774(o.labels!);
    checkSourceLocation(o.location! as api.SourceLocation);
    unittest.expect(
      o.logLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.logMessageFormat!,
      unittest.equals('foo'),
    );
    checkUnnamed4775(o.stackFrames!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkStatusMessage(o.status! as api.StatusMessage);
    unittest.expect(
      o.userEmail!,
      unittest.equals('foo'),
    );
    checkUnnamed4776(o.variableTable!);
  }
  buildCounterBreakpoint--;
}

core.int buildCounterCloudRepoSourceContext = 0;
api.CloudRepoSourceContext buildCloudRepoSourceContext() {
  var o = api.CloudRepoSourceContext();
  buildCounterCloudRepoSourceContext++;
  if (buildCounterCloudRepoSourceContext < 3) {
    o.aliasContext = buildAliasContext();
    o.aliasName = 'foo';
    o.repoId = buildRepoId();
    o.revisionId = 'foo';
  }
  buildCounterCloudRepoSourceContext--;
  return o;
}

void checkCloudRepoSourceContext(api.CloudRepoSourceContext o) {
  buildCounterCloudRepoSourceContext++;
  if (buildCounterCloudRepoSourceContext < 3) {
    checkAliasContext(o.aliasContext! as api.AliasContext);
    unittest.expect(
      o.aliasName!,
      unittest.equals('foo'),
    );
    checkRepoId(o.repoId! as api.RepoId);
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudRepoSourceContext--;
}

core.int buildCounterCloudWorkspaceId = 0;
api.CloudWorkspaceId buildCloudWorkspaceId() {
  var o = api.CloudWorkspaceId();
  buildCounterCloudWorkspaceId++;
  if (buildCounterCloudWorkspaceId < 3) {
    o.name = 'foo';
    o.repoId = buildRepoId();
  }
  buildCounterCloudWorkspaceId--;
  return o;
}

void checkCloudWorkspaceId(api.CloudWorkspaceId o) {
  buildCounterCloudWorkspaceId++;
  if (buildCounterCloudWorkspaceId < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkRepoId(o.repoId! as api.RepoId);
  }
  buildCounterCloudWorkspaceId--;
}

core.int buildCounterCloudWorkspaceSourceContext = 0;
api.CloudWorkspaceSourceContext buildCloudWorkspaceSourceContext() {
  var o = api.CloudWorkspaceSourceContext();
  buildCounterCloudWorkspaceSourceContext++;
  if (buildCounterCloudWorkspaceSourceContext < 3) {
    o.snapshotId = 'foo';
    o.workspaceId = buildCloudWorkspaceId();
  }
  buildCounterCloudWorkspaceSourceContext--;
  return o;
}

void checkCloudWorkspaceSourceContext(api.CloudWorkspaceSourceContext o) {
  buildCounterCloudWorkspaceSourceContext++;
  if (buildCounterCloudWorkspaceSourceContext < 3) {
    unittest.expect(
      o.snapshotId!,
      unittest.equals('foo'),
    );
    checkCloudWorkspaceId(o.workspaceId! as api.CloudWorkspaceId);
  }
  buildCounterCloudWorkspaceSourceContext--;
}

core.List<api.ExtendedSourceContext> buildUnnamed4777() {
  var o = <api.ExtendedSourceContext>[];
  o.add(buildExtendedSourceContext());
  o.add(buildExtendedSourceContext());
  return o;
}

void checkUnnamed4777(core.List<api.ExtendedSourceContext> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExtendedSourceContext(o[0] as api.ExtendedSourceContext);
  checkExtendedSourceContext(o[1] as api.ExtendedSourceContext);
}

core.Map<core.String, core.String> buildUnnamed4778() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4778(core.Map<core.String, core.String> o) {
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

core.List<api.SourceContext> buildUnnamed4779() {
  var o = <api.SourceContext>[];
  o.add(buildSourceContext());
  o.add(buildSourceContext());
  return o;
}

void checkUnnamed4779(core.List<api.SourceContext> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSourceContext(o[0] as api.SourceContext);
  checkSourceContext(o[1] as api.SourceContext);
}

core.int buildCounterDebuggee = 0;
api.Debuggee buildDebuggee() {
  var o = api.Debuggee();
  buildCounterDebuggee++;
  if (buildCounterDebuggee < 3) {
    o.agentVersion = 'foo';
    o.canaryMode = 'foo';
    o.description = 'foo';
    o.extSourceContexts = buildUnnamed4777();
    o.id = 'foo';
    o.isDisabled = true;
    o.isInactive = true;
    o.labels = buildUnnamed4778();
    o.project = 'foo';
    o.sourceContexts = buildUnnamed4779();
    o.status = buildStatusMessage();
    o.uniquifier = 'foo';
  }
  buildCounterDebuggee--;
  return o;
}

void checkDebuggee(api.Debuggee o) {
  buildCounterDebuggee++;
  if (buildCounterDebuggee < 3) {
    unittest.expect(
      o.agentVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.canaryMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed4777(o.extSourceContexts!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDisabled!, unittest.isTrue);
    unittest.expect(o.isInactive!, unittest.isTrue);
    checkUnnamed4778(o.labels!);
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
    checkUnnamed4779(o.sourceContexts!);
    checkStatusMessage(o.status! as api.StatusMessage);
    unittest.expect(
      o.uniquifier!,
      unittest.equals('foo'),
    );
  }
  buildCounterDebuggee--;
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

core.Map<core.String, core.String> buildUnnamed4780() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4780(core.Map<core.String, core.String> o) {
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

core.int buildCounterExtendedSourceContext = 0;
api.ExtendedSourceContext buildExtendedSourceContext() {
  var o = api.ExtendedSourceContext();
  buildCounterExtendedSourceContext++;
  if (buildCounterExtendedSourceContext < 3) {
    o.context = buildSourceContext();
    o.labels = buildUnnamed4780();
  }
  buildCounterExtendedSourceContext--;
  return o;
}

void checkExtendedSourceContext(api.ExtendedSourceContext o) {
  buildCounterExtendedSourceContext++;
  if (buildCounterExtendedSourceContext < 3) {
    checkSourceContext(o.context! as api.SourceContext);
    checkUnnamed4780(o.labels!);
  }
  buildCounterExtendedSourceContext--;
}

core.List<core.String> buildUnnamed4781() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4781(core.List<core.String> o) {
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

core.int buildCounterFormatMessage = 0;
api.FormatMessage buildFormatMessage() {
  var o = api.FormatMessage();
  buildCounterFormatMessage++;
  if (buildCounterFormatMessage < 3) {
    o.format = 'foo';
    o.parameters = buildUnnamed4781();
  }
  buildCounterFormatMessage--;
  return o;
}

void checkFormatMessage(api.FormatMessage o) {
  buildCounterFormatMessage++;
  if (buildCounterFormatMessage < 3) {
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
    checkUnnamed4781(o.parameters!);
  }
  buildCounterFormatMessage--;
}

core.int buildCounterGerritSourceContext = 0;
api.GerritSourceContext buildGerritSourceContext() {
  var o = api.GerritSourceContext();
  buildCounterGerritSourceContext++;
  if (buildCounterGerritSourceContext < 3) {
    o.aliasContext = buildAliasContext();
    o.aliasName = 'foo';
    o.gerritProject = 'foo';
    o.hostUri = 'foo';
    o.revisionId = 'foo';
  }
  buildCounterGerritSourceContext--;
  return o;
}

void checkGerritSourceContext(api.GerritSourceContext o) {
  buildCounterGerritSourceContext++;
  if (buildCounterGerritSourceContext < 3) {
    checkAliasContext(o.aliasContext! as api.AliasContext);
    unittest.expect(
      o.aliasName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gerritProject!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hostUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGerritSourceContext--;
}

core.int buildCounterGetBreakpointResponse = 0;
api.GetBreakpointResponse buildGetBreakpointResponse() {
  var o = api.GetBreakpointResponse();
  buildCounterGetBreakpointResponse++;
  if (buildCounterGetBreakpointResponse < 3) {
    o.breakpoint = buildBreakpoint();
  }
  buildCounterGetBreakpointResponse--;
  return o;
}

void checkGetBreakpointResponse(api.GetBreakpointResponse o) {
  buildCounterGetBreakpointResponse++;
  if (buildCounterGetBreakpointResponse < 3) {
    checkBreakpoint(o.breakpoint! as api.Breakpoint);
  }
  buildCounterGetBreakpointResponse--;
}

core.int buildCounterGitSourceContext = 0;
api.GitSourceContext buildGitSourceContext() {
  var o = api.GitSourceContext();
  buildCounterGitSourceContext++;
  if (buildCounterGitSourceContext < 3) {
    o.revisionId = 'foo';
    o.url = 'foo';
  }
  buildCounterGitSourceContext--;
  return o;
}

void checkGitSourceContext(api.GitSourceContext o) {
  buildCounterGitSourceContext++;
  if (buildCounterGitSourceContext < 3) {
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterGitSourceContext--;
}

core.List<api.Breakpoint> buildUnnamed4782() {
  var o = <api.Breakpoint>[];
  o.add(buildBreakpoint());
  o.add(buildBreakpoint());
  return o;
}

void checkUnnamed4782(core.List<api.Breakpoint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBreakpoint(o[0] as api.Breakpoint);
  checkBreakpoint(o[1] as api.Breakpoint);
}

core.int buildCounterListActiveBreakpointsResponse = 0;
api.ListActiveBreakpointsResponse buildListActiveBreakpointsResponse() {
  var o = api.ListActiveBreakpointsResponse();
  buildCounterListActiveBreakpointsResponse++;
  if (buildCounterListActiveBreakpointsResponse < 3) {
    o.breakpoints = buildUnnamed4782();
    o.nextWaitToken = 'foo';
    o.waitExpired = true;
  }
  buildCounterListActiveBreakpointsResponse--;
  return o;
}

void checkListActiveBreakpointsResponse(api.ListActiveBreakpointsResponse o) {
  buildCounterListActiveBreakpointsResponse++;
  if (buildCounterListActiveBreakpointsResponse < 3) {
    checkUnnamed4782(o.breakpoints!);
    unittest.expect(
      o.nextWaitToken!,
      unittest.equals('foo'),
    );
    unittest.expect(o.waitExpired!, unittest.isTrue);
  }
  buildCounterListActiveBreakpointsResponse--;
}

core.List<api.Breakpoint> buildUnnamed4783() {
  var o = <api.Breakpoint>[];
  o.add(buildBreakpoint());
  o.add(buildBreakpoint());
  return o;
}

void checkUnnamed4783(core.List<api.Breakpoint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBreakpoint(o[0] as api.Breakpoint);
  checkBreakpoint(o[1] as api.Breakpoint);
}

core.int buildCounterListBreakpointsResponse = 0;
api.ListBreakpointsResponse buildListBreakpointsResponse() {
  var o = api.ListBreakpointsResponse();
  buildCounterListBreakpointsResponse++;
  if (buildCounterListBreakpointsResponse < 3) {
    o.breakpoints = buildUnnamed4783();
    o.nextWaitToken = 'foo';
  }
  buildCounterListBreakpointsResponse--;
  return o;
}

void checkListBreakpointsResponse(api.ListBreakpointsResponse o) {
  buildCounterListBreakpointsResponse++;
  if (buildCounterListBreakpointsResponse < 3) {
    checkUnnamed4783(o.breakpoints!);
    unittest.expect(
      o.nextWaitToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListBreakpointsResponse--;
}

core.List<api.Debuggee> buildUnnamed4784() {
  var o = <api.Debuggee>[];
  o.add(buildDebuggee());
  o.add(buildDebuggee());
  return o;
}

void checkUnnamed4784(core.List<api.Debuggee> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDebuggee(o[0] as api.Debuggee);
  checkDebuggee(o[1] as api.Debuggee);
}

core.int buildCounterListDebuggeesResponse = 0;
api.ListDebuggeesResponse buildListDebuggeesResponse() {
  var o = api.ListDebuggeesResponse();
  buildCounterListDebuggeesResponse++;
  if (buildCounterListDebuggeesResponse < 3) {
    o.debuggees = buildUnnamed4784();
  }
  buildCounterListDebuggeesResponse--;
  return o;
}

void checkListDebuggeesResponse(api.ListDebuggeesResponse o) {
  buildCounterListDebuggeesResponse++;
  if (buildCounterListDebuggeesResponse < 3) {
    checkUnnamed4784(o.debuggees!);
  }
  buildCounterListDebuggeesResponse--;
}

core.int buildCounterProjectRepoId = 0;
api.ProjectRepoId buildProjectRepoId() {
  var o = api.ProjectRepoId();
  buildCounterProjectRepoId++;
  if (buildCounterProjectRepoId < 3) {
    o.projectId = 'foo';
    o.repoName = 'foo';
  }
  buildCounterProjectRepoId--;
  return o;
}

void checkProjectRepoId(api.ProjectRepoId o) {
  buildCounterProjectRepoId++;
  if (buildCounterProjectRepoId < 3) {
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.repoName!,
      unittest.equals('foo'),
    );
  }
  buildCounterProjectRepoId--;
}

core.int buildCounterRegisterDebuggeeRequest = 0;
api.RegisterDebuggeeRequest buildRegisterDebuggeeRequest() {
  var o = api.RegisterDebuggeeRequest();
  buildCounterRegisterDebuggeeRequest++;
  if (buildCounterRegisterDebuggeeRequest < 3) {
    o.debuggee = buildDebuggee();
  }
  buildCounterRegisterDebuggeeRequest--;
  return o;
}

void checkRegisterDebuggeeRequest(api.RegisterDebuggeeRequest o) {
  buildCounterRegisterDebuggeeRequest++;
  if (buildCounterRegisterDebuggeeRequest < 3) {
    checkDebuggee(o.debuggee! as api.Debuggee);
  }
  buildCounterRegisterDebuggeeRequest--;
}

core.int buildCounterRegisterDebuggeeResponse = 0;
api.RegisterDebuggeeResponse buildRegisterDebuggeeResponse() {
  var o = api.RegisterDebuggeeResponse();
  buildCounterRegisterDebuggeeResponse++;
  if (buildCounterRegisterDebuggeeResponse < 3) {
    o.agentId = 'foo';
    o.debuggee = buildDebuggee();
  }
  buildCounterRegisterDebuggeeResponse--;
  return o;
}

void checkRegisterDebuggeeResponse(api.RegisterDebuggeeResponse o) {
  buildCounterRegisterDebuggeeResponse++;
  if (buildCounterRegisterDebuggeeResponse < 3) {
    unittest.expect(
      o.agentId!,
      unittest.equals('foo'),
    );
    checkDebuggee(o.debuggee! as api.Debuggee);
  }
  buildCounterRegisterDebuggeeResponse--;
}

core.int buildCounterRepoId = 0;
api.RepoId buildRepoId() {
  var o = api.RepoId();
  buildCounterRepoId++;
  if (buildCounterRepoId < 3) {
    o.projectRepoId = buildProjectRepoId();
    o.uid = 'foo';
  }
  buildCounterRepoId--;
  return o;
}

void checkRepoId(api.RepoId o) {
  buildCounterRepoId++;
  if (buildCounterRepoId < 3) {
    checkProjectRepoId(o.projectRepoId! as api.ProjectRepoId);
    unittest.expect(
      o.uid!,
      unittest.equals('foo'),
    );
  }
  buildCounterRepoId--;
}

core.int buildCounterSetBreakpointResponse = 0;
api.SetBreakpointResponse buildSetBreakpointResponse() {
  var o = api.SetBreakpointResponse();
  buildCounterSetBreakpointResponse++;
  if (buildCounterSetBreakpointResponse < 3) {
    o.breakpoint = buildBreakpoint();
  }
  buildCounterSetBreakpointResponse--;
  return o;
}

void checkSetBreakpointResponse(api.SetBreakpointResponse o) {
  buildCounterSetBreakpointResponse++;
  if (buildCounterSetBreakpointResponse < 3) {
    checkBreakpoint(o.breakpoint! as api.Breakpoint);
  }
  buildCounterSetBreakpointResponse--;
}

core.int buildCounterSourceContext = 0;
api.SourceContext buildSourceContext() {
  var o = api.SourceContext();
  buildCounterSourceContext++;
  if (buildCounterSourceContext < 3) {
    o.cloudRepo = buildCloudRepoSourceContext();
    o.cloudWorkspace = buildCloudWorkspaceSourceContext();
    o.gerrit = buildGerritSourceContext();
    o.git = buildGitSourceContext();
  }
  buildCounterSourceContext--;
  return o;
}

void checkSourceContext(api.SourceContext o) {
  buildCounterSourceContext++;
  if (buildCounterSourceContext < 3) {
    checkCloudRepoSourceContext(o.cloudRepo! as api.CloudRepoSourceContext);
    checkCloudWorkspaceSourceContext(
        o.cloudWorkspace! as api.CloudWorkspaceSourceContext);
    checkGerritSourceContext(o.gerrit! as api.GerritSourceContext);
    checkGitSourceContext(o.git! as api.GitSourceContext);
  }
  buildCounterSourceContext--;
}

core.int buildCounterSourceLocation = 0;
api.SourceLocation buildSourceLocation() {
  var o = api.SourceLocation();
  buildCounterSourceLocation++;
  if (buildCounterSourceLocation < 3) {
    o.column = 42;
    o.line = 42;
    o.path = 'foo';
  }
  buildCounterSourceLocation--;
  return o;
}

void checkSourceLocation(api.SourceLocation o) {
  buildCounterSourceLocation++;
  if (buildCounterSourceLocation < 3) {
    unittest.expect(
      o.column!,
      unittest.equals(42),
    );
    unittest.expect(
      o.line!,
      unittest.equals(42),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
  }
  buildCounterSourceLocation--;
}

core.List<api.Variable> buildUnnamed4785() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed4785(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.List<api.Variable> buildUnnamed4786() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed4786(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterStackFrame = 0;
api.StackFrame buildStackFrame() {
  var o = api.StackFrame();
  buildCounterStackFrame++;
  if (buildCounterStackFrame < 3) {
    o.arguments = buildUnnamed4785();
    o.function = 'foo';
    o.locals = buildUnnamed4786();
    o.location = buildSourceLocation();
  }
  buildCounterStackFrame--;
  return o;
}

void checkStackFrame(api.StackFrame o) {
  buildCounterStackFrame++;
  if (buildCounterStackFrame < 3) {
    checkUnnamed4785(o.arguments!);
    unittest.expect(
      o.function!,
      unittest.equals('foo'),
    );
    checkUnnamed4786(o.locals!);
    checkSourceLocation(o.location! as api.SourceLocation);
  }
  buildCounterStackFrame--;
}

core.int buildCounterStatusMessage = 0;
api.StatusMessage buildStatusMessage() {
  var o = api.StatusMessage();
  buildCounterStatusMessage++;
  if (buildCounterStatusMessage < 3) {
    o.description = buildFormatMessage();
    o.isError = true;
    o.refersTo = 'foo';
  }
  buildCounterStatusMessage--;
  return o;
}

void checkStatusMessage(api.StatusMessage o) {
  buildCounterStatusMessage++;
  if (buildCounterStatusMessage < 3) {
    checkFormatMessage(o.description! as api.FormatMessage);
    unittest.expect(o.isError!, unittest.isTrue);
    unittest.expect(
      o.refersTo!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatusMessage--;
}

core.int buildCounterUpdateActiveBreakpointRequest = 0;
api.UpdateActiveBreakpointRequest buildUpdateActiveBreakpointRequest() {
  var o = api.UpdateActiveBreakpointRequest();
  buildCounterUpdateActiveBreakpointRequest++;
  if (buildCounterUpdateActiveBreakpointRequest < 3) {
    o.breakpoint = buildBreakpoint();
  }
  buildCounterUpdateActiveBreakpointRequest--;
  return o;
}

void checkUpdateActiveBreakpointRequest(api.UpdateActiveBreakpointRequest o) {
  buildCounterUpdateActiveBreakpointRequest++;
  if (buildCounterUpdateActiveBreakpointRequest < 3) {
    checkBreakpoint(o.breakpoint! as api.Breakpoint);
  }
  buildCounterUpdateActiveBreakpointRequest--;
}

core.int buildCounterUpdateActiveBreakpointResponse = 0;
api.UpdateActiveBreakpointResponse buildUpdateActiveBreakpointResponse() {
  var o = api.UpdateActiveBreakpointResponse();
  buildCounterUpdateActiveBreakpointResponse++;
  if (buildCounterUpdateActiveBreakpointResponse < 3) {}
  buildCounterUpdateActiveBreakpointResponse--;
  return o;
}

void checkUpdateActiveBreakpointResponse(api.UpdateActiveBreakpointResponse o) {
  buildCounterUpdateActiveBreakpointResponse++;
  if (buildCounterUpdateActiveBreakpointResponse < 3) {}
  buildCounterUpdateActiveBreakpointResponse--;
}

core.List<api.Variable> buildUnnamed4787() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed4787(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterVariable = 0;
api.Variable buildVariable() {
  var o = api.Variable();
  buildCounterVariable++;
  if (buildCounterVariable < 3) {
    o.members = buildUnnamed4787();
    o.name = 'foo';
    o.status = buildStatusMessage();
    o.type = 'foo';
    o.value = 'foo';
    o.varTableIndex = 42;
  }
  buildCounterVariable--;
  return o;
}

void checkVariable(api.Variable o) {
  buildCounterVariable++;
  if (buildCounterVariable < 3) {
    checkUnnamed4787(o.members!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkStatusMessage(o.status! as api.StatusMessage);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.varTableIndex!,
      unittest.equals(42),
    );
  }
  buildCounterVariable--;
}

void main() {
  unittest.group('obj-schema-AliasContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAliasContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AliasContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAliasContext(od as api.AliasContext);
    });
  });

  unittest.group('obj-schema-Breakpoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBreakpoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Breakpoint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBreakpoint(od as api.Breakpoint);
    });
  });

  unittest.group('obj-schema-CloudRepoSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudRepoSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudRepoSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudRepoSourceContext(od as api.CloudRepoSourceContext);
    });
  });

  unittest.group('obj-schema-CloudWorkspaceId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudWorkspaceId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudWorkspaceId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudWorkspaceId(od as api.CloudWorkspaceId);
    });
  });

  unittest.group('obj-schema-CloudWorkspaceSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudWorkspaceSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudWorkspaceSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudWorkspaceSourceContext(od as api.CloudWorkspaceSourceContext);
    });
  });

  unittest.group('obj-schema-Debuggee', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDebuggee();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Debuggee.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDebuggee(od as api.Debuggee);
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

  unittest.group('obj-schema-ExtendedSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExtendedSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExtendedSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExtendedSourceContext(od as api.ExtendedSourceContext);
    });
  });

  unittest.group('obj-schema-FormatMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFormatMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FormatMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFormatMessage(od as api.FormatMessage);
    });
  });

  unittest.group('obj-schema-GerritSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGerritSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GerritSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGerritSourceContext(od as api.GerritSourceContext);
    });
  });

  unittest.group('obj-schema-GetBreakpointResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetBreakpointResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetBreakpointResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetBreakpointResponse(od as api.GetBreakpointResponse);
    });
  });

  unittest.group('obj-schema-GitSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGitSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GitSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGitSourceContext(od as api.GitSourceContext);
    });
  });

  unittest.group('obj-schema-ListActiveBreakpointsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListActiveBreakpointsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListActiveBreakpointsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListActiveBreakpointsResponse(
          od as api.ListActiveBreakpointsResponse);
    });
  });

  unittest.group('obj-schema-ListBreakpointsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListBreakpointsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListBreakpointsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListBreakpointsResponse(od as api.ListBreakpointsResponse);
    });
  });

  unittest.group('obj-schema-ListDebuggeesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDebuggeesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDebuggeesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDebuggeesResponse(od as api.ListDebuggeesResponse);
    });
  });

  unittest.group('obj-schema-ProjectRepoId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectRepoId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectRepoId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectRepoId(od as api.ProjectRepoId);
    });
  });

  unittest.group('obj-schema-RegisterDebuggeeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegisterDebuggeeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RegisterDebuggeeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegisterDebuggeeRequest(od as api.RegisterDebuggeeRequest);
    });
  });

  unittest.group('obj-schema-RegisterDebuggeeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegisterDebuggeeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RegisterDebuggeeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegisterDebuggeeResponse(od as api.RegisterDebuggeeResponse);
    });
  });

  unittest.group('obj-schema-RepoId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepoId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RepoId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRepoId(od as api.RepoId);
    });
  });

  unittest.group('obj-schema-SetBreakpointResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetBreakpointResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetBreakpointResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetBreakpointResponse(od as api.SetBreakpointResponse);
    });
  });

  unittest.group('obj-schema-SourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceContext(od as api.SourceContext);
    });
  });

  unittest.group('obj-schema-SourceLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceLocation(od as api.SourceLocation);
    });
  });

  unittest.group('obj-schema-StackFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStackFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.StackFrame.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStackFrame(od as api.StackFrame);
    });
  });

  unittest.group('obj-schema-StatusMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatusMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StatusMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStatusMessage(od as api.StatusMessage);
    });
  });

  unittest.group('obj-schema-UpdateActiveBreakpointRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateActiveBreakpointRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateActiveBreakpointRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateActiveBreakpointRequest(
          od as api.UpdateActiveBreakpointRequest);
    });
  });

  unittest.group('obj-schema-UpdateActiveBreakpointResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateActiveBreakpointResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateActiveBreakpointResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateActiveBreakpointResponse(
          od as api.UpdateActiveBreakpointResponse);
    });
  });

  unittest.group('obj-schema-Variable', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVariable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Variable.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVariable(od as api.Variable);
    });
  });

  unittest.group('resource-ControllerDebuggeesResource', () {
    unittest.test('method--register', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).controller.debuggees;
      var arg_request = buildRegisterDebuggeeRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RegisterDebuggeeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRegisterDebuggeeRequest(obj as api.RegisterDebuggeeRequest);

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
          unittest.equals("v2/controller/debuggees/register"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRegisterDebuggeeResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.register(arg_request, $fields: arg_$fields);
      checkRegisterDebuggeeResponse(response as api.RegisterDebuggeeResponse);
    });
  });

  unittest.group('resource-ControllerDebuggeesBreakpointsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).controller.debuggees.breakpoints;
      var arg_debuggeeId = 'foo';
      var arg_agentId = 'foo';
      var arg_successOnTimeout = true;
      var arg_waitToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("v2/controller/debuggees/"),
        );
        pathOffset += 24;
        index = path.indexOf('/breakpoints', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_debuggeeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/breakpoints"),
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
          queryMap["agentId"]!.first,
          unittest.equals(arg_agentId),
        );
        unittest.expect(
          queryMap["successOnTimeout"]!.first,
          unittest.equals("$arg_successOnTimeout"),
        );
        unittest.expect(
          queryMap["waitToken"]!.first,
          unittest.equals(arg_waitToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListActiveBreakpointsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_debuggeeId,
          agentId: arg_agentId,
          successOnTimeout: arg_successOnTimeout,
          waitToken: arg_waitToken,
          $fields: arg_$fields);
      checkListActiveBreakpointsResponse(
          response as api.ListActiveBreakpointsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).controller.debuggees.breakpoints;
      var arg_request = buildUpdateActiveBreakpointRequest();
      var arg_debuggeeId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateActiveBreakpointRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateActiveBreakpointRequest(
            obj as api.UpdateActiveBreakpointRequest);

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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("v2/controller/debuggees/"),
        );
        pathOffset += 24;
        index = path.indexOf('/breakpoints/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_debuggeeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/breakpoints/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
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
        var resp = convert.json.encode(buildUpdateActiveBreakpointResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_debuggeeId, arg_id,
          $fields: arg_$fields);
      checkUpdateActiveBreakpointResponse(
          response as api.UpdateActiveBreakpointResponse);
    });
  });

  unittest.group('resource-DebuggerDebuggeesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).debugger.debuggees;
      var arg_clientVersion = 'foo';
      var arg_includeInactive = true;
      var arg_project = 'foo';
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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("v2/debugger/debuggees"),
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
          queryMap["clientVersion"]!.first,
          unittest.equals(arg_clientVersion),
        );
        unittest.expect(
          queryMap["includeInactive"]!.first,
          unittest.equals("$arg_includeInactive"),
        );
        unittest.expect(
          queryMap["project"]!.first,
          unittest.equals(arg_project),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListDebuggeesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          clientVersion: arg_clientVersion,
          includeInactive: arg_includeInactive,
          project: arg_project,
          $fields: arg_$fields);
      checkListDebuggeesResponse(response as api.ListDebuggeesResponse);
    });
  });

  unittest.group('resource-DebuggerDebuggeesBreakpointsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).debugger.debuggees.breakpoints;
      var arg_debuggeeId = 'foo';
      var arg_breakpointId = 'foo';
      var arg_clientVersion = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("v2/debugger/debuggees/"),
        );
        pathOffset += 22;
        index = path.indexOf('/breakpoints/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_debuggeeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/breakpoints/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_breakpointId'),
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
          queryMap["clientVersion"]!.first,
          unittest.equals(arg_clientVersion),
        );
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
      final response = await res.delete(arg_debuggeeId, arg_breakpointId,
          clientVersion: arg_clientVersion, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).debugger.debuggees.breakpoints;
      var arg_debuggeeId = 'foo';
      var arg_breakpointId = 'foo';
      var arg_clientVersion = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("v2/debugger/debuggees/"),
        );
        pathOffset += 22;
        index = path.indexOf('/breakpoints/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_debuggeeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/breakpoints/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_breakpointId'),
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
          queryMap["clientVersion"]!.first,
          unittest.equals(arg_clientVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetBreakpointResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_debuggeeId, arg_breakpointId,
          clientVersion: arg_clientVersion, $fields: arg_$fields);
      checkGetBreakpointResponse(response as api.GetBreakpointResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).debugger.debuggees.breakpoints;
      var arg_debuggeeId = 'foo';
      var arg_action_value = 'foo';
      var arg_clientVersion = 'foo';
      var arg_includeAllUsers = true;
      var arg_includeInactive = true;
      var arg_stripResults = true;
      var arg_waitToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("v2/debugger/debuggees/"),
        );
        pathOffset += 22;
        index = path.indexOf('/breakpoints', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_debuggeeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/breakpoints"),
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
          queryMap["action.value"]!.first,
          unittest.equals(arg_action_value),
        );
        unittest.expect(
          queryMap["clientVersion"]!.first,
          unittest.equals(arg_clientVersion),
        );
        unittest.expect(
          queryMap["includeAllUsers"]!.first,
          unittest.equals("$arg_includeAllUsers"),
        );
        unittest.expect(
          queryMap["includeInactive"]!.first,
          unittest.equals("$arg_includeInactive"),
        );
        unittest.expect(
          queryMap["stripResults"]!.first,
          unittest.equals("$arg_stripResults"),
        );
        unittest.expect(
          queryMap["waitToken"]!.first,
          unittest.equals(arg_waitToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListBreakpointsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_debuggeeId,
          action_value: arg_action_value,
          clientVersion: arg_clientVersion,
          includeAllUsers: arg_includeAllUsers,
          includeInactive: arg_includeInactive,
          stripResults: arg_stripResults,
          waitToken: arg_waitToken,
          $fields: arg_$fields);
      checkListBreakpointsResponse(response as api.ListBreakpointsResponse);
    });

    unittest.test('method--set', () async {
      var mock = HttpServerMock();
      var res = api.CloudDebuggerApi(mock).debugger.debuggees.breakpoints;
      var arg_request = buildBreakpoint();
      var arg_debuggeeId = 'foo';
      var arg_canaryOption = 'foo';
      var arg_clientVersion = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Breakpoint.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBreakpoint(obj as api.Breakpoint);

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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("v2/debugger/debuggees/"),
        );
        pathOffset += 22;
        index = path.indexOf('/breakpoints/set', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_debuggeeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/breakpoints/set"),
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
          queryMap["canaryOption"]!.first,
          unittest.equals(arg_canaryOption),
        );
        unittest.expect(
          queryMap["clientVersion"]!.first,
          unittest.equals(arg_clientVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSetBreakpointResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.set(arg_request, arg_debuggeeId,
          canaryOption: arg_canaryOption,
          clientVersion: arg_clientVersion,
          $fields: arg_$fields);
      checkSetBreakpointResponse(response as api.SetBreakpointResponse);
    });
  });
}

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

import 'package:googleapis/tagmanager/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAccount = 0;
api.Account buildAccount() {
  var o = api.Account();
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    o.accountId = 'foo';
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.shareData = true;
  }
  buildCounterAccount--;
  return o;
}

void checkAccount(api.Account o) {
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.shareData!, unittest.isTrue);
  }
  buildCounterAccount--;
}

core.List<core.String> buildUnnamed2407() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2407(core.List<core.String> o) {
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

core.int buildCounterAccountAccess = 0;
api.AccountAccess buildAccountAccess() {
  var o = api.AccountAccess();
  buildCounterAccountAccess++;
  if (buildCounterAccountAccess < 3) {
    o.permission = buildUnnamed2407();
  }
  buildCounterAccountAccess--;
  return o;
}

void checkAccountAccess(api.AccountAccess o) {
  buildCounterAccountAccess++;
  if (buildCounterAccountAccess < 3) {
    checkUnnamed2407(o.permission!);
  }
  buildCounterAccountAccess--;
}

core.List<api.Parameter> buildUnnamed2408() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed2408(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.int buildCounterCondition = 0;
api.Condition buildCondition() {
  var o = api.Condition();
  buildCounterCondition++;
  if (buildCounterCondition < 3) {
    o.parameter = buildUnnamed2408();
    o.type = 'foo';
  }
  buildCounterCondition--;
  return o;
}

void checkCondition(api.Condition o) {
  buildCounterCondition++;
  if (buildCounterCondition < 3) {
    checkUnnamed2408(o.parameter!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCondition--;
}

core.List<core.String> buildUnnamed2409() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2409(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2410() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2410(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2411() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2411(core.List<core.String> o) {
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

core.int buildCounterContainer = 0;
api.Container buildContainer() {
  var o = api.Container();
  buildCounterContainer++;
  if (buildCounterContainer < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.domainName = buildUnnamed2409();
    o.enabledBuiltInVariable = buildUnnamed2410();
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.publicId = 'foo';
    o.timeZoneCountryId = 'foo';
    o.timeZoneId = 'foo';
    o.usageContext = buildUnnamed2411();
  }
  buildCounterContainer--;
  return o;
}

void checkContainer(api.Container o) {
  buildCounterContainer++;
  if (buildCounterContainer < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    checkUnnamed2409(o.domainName!);
    checkUnnamed2410(o.enabledBuiltInVariable!);
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publicId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZoneCountryId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZoneId!,
      unittest.equals('foo'),
    );
    checkUnnamed2411(o.usageContext!);
  }
  buildCounterContainer--;
}

core.List<core.String> buildUnnamed2412() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2412(core.List<core.String> o) {
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

core.int buildCounterContainerAccess = 0;
api.ContainerAccess buildContainerAccess() {
  var o = api.ContainerAccess();
  buildCounterContainerAccess++;
  if (buildCounterContainerAccess < 3) {
    o.containerId = 'foo';
    o.permission = buildUnnamed2412();
  }
  buildCounterContainerAccess--;
  return o;
}

void checkContainerAccess(api.ContainerAccess o) {
  buildCounterContainerAccess++;
  if (buildCounterContainerAccess < 3) {
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    checkUnnamed2412(o.permission!);
  }
  buildCounterContainerAccess--;
}

core.List<api.Folder> buildUnnamed2413() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed2413(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.List<api.Macro> buildUnnamed2414() {
  var o = <api.Macro>[];
  o.add(buildMacro());
  o.add(buildMacro());
  return o;
}

void checkUnnamed2414(core.List<api.Macro> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMacro(o[0] as api.Macro);
  checkMacro(o[1] as api.Macro);
}

core.List<api.Rule> buildUnnamed2415() {
  var o = <api.Rule>[];
  o.add(buildRule());
  o.add(buildRule());
  return o;
}

void checkUnnamed2415(core.List<api.Rule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRule(o[0] as api.Rule);
  checkRule(o[1] as api.Rule);
}

core.List<api.Tag> buildUnnamed2416() {
  var o = <api.Tag>[];
  o.add(buildTag());
  o.add(buildTag());
  return o;
}

void checkUnnamed2416(core.List<api.Tag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTag(o[0] as api.Tag);
  checkTag(o[1] as api.Tag);
}

core.List<api.Trigger> buildUnnamed2417() {
  var o = <api.Trigger>[];
  o.add(buildTrigger());
  o.add(buildTrigger());
  return o;
}

void checkUnnamed2417(core.List<api.Trigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrigger(o[0] as api.Trigger);
  checkTrigger(o[1] as api.Trigger);
}

core.List<api.Variable> buildUnnamed2418() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed2418(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterContainerVersion = 0;
api.ContainerVersion buildContainerVersion() {
  var o = api.ContainerVersion();
  buildCounterContainerVersion++;
  if (buildCounterContainerVersion < 3) {
    o.accountId = 'foo';
    o.container = buildContainer();
    o.containerId = 'foo';
    o.containerVersionId = 'foo';
    o.deleted = true;
    o.fingerprint = 'foo';
    o.folder = buildUnnamed2413();
    o.macro = buildUnnamed2414();
    o.name = 'foo';
    o.notes = 'foo';
    o.rule = buildUnnamed2415();
    o.tag = buildUnnamed2416();
    o.trigger = buildUnnamed2417();
    o.variable = buildUnnamed2418();
  }
  buildCounterContainerVersion--;
  return o;
}

void checkContainerVersion(api.ContainerVersion o) {
  buildCounterContainerVersion++;
  if (buildCounterContainerVersion < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkContainer(o.container! as api.Container);
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerVersionId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.deleted!, unittest.isTrue);
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    checkUnnamed2413(o.folder!);
    checkUnnamed2414(o.macro!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkUnnamed2415(o.rule!);
    checkUnnamed2416(o.tag!);
    checkUnnamed2417(o.trigger!);
    checkUnnamed2418(o.variable!);
  }
  buildCounterContainerVersion--;
}

core.int buildCounterContainerVersionHeader = 0;
api.ContainerVersionHeader buildContainerVersionHeader() {
  var o = api.ContainerVersionHeader();
  buildCounterContainerVersionHeader++;
  if (buildCounterContainerVersionHeader < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.containerVersionId = 'foo';
    o.deleted = true;
    o.name = 'foo';
    o.numMacros = 'foo';
    o.numRules = 'foo';
    o.numTags = 'foo';
    o.numTriggers = 'foo';
    o.numVariables = 'foo';
  }
  buildCounterContainerVersionHeader--;
  return o;
}

void checkContainerVersionHeader(api.ContainerVersionHeader o) {
  buildCounterContainerVersionHeader++;
  if (buildCounterContainerVersionHeader < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerVersionId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.deleted!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numMacros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numRules!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numTags!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numTriggers!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numVariables!,
      unittest.equals('foo'),
    );
  }
  buildCounterContainerVersionHeader--;
}

core.int buildCounterCreateContainerVersionRequestVersionOptions = 0;
api.CreateContainerVersionRequestVersionOptions
    buildCreateContainerVersionRequestVersionOptions() {
  var o = api.CreateContainerVersionRequestVersionOptions();
  buildCounterCreateContainerVersionRequestVersionOptions++;
  if (buildCounterCreateContainerVersionRequestVersionOptions < 3) {
    o.name = 'foo';
    o.notes = 'foo';
    o.quickPreview = true;
  }
  buildCounterCreateContainerVersionRequestVersionOptions--;
  return o;
}

void checkCreateContainerVersionRequestVersionOptions(
    api.CreateContainerVersionRequestVersionOptions o) {
  buildCounterCreateContainerVersionRequestVersionOptions++;
  if (buildCounterCreateContainerVersionRequestVersionOptions < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    unittest.expect(o.quickPreview!, unittest.isTrue);
  }
  buildCounterCreateContainerVersionRequestVersionOptions--;
}

core.int buildCounterCreateContainerVersionResponse = 0;
api.CreateContainerVersionResponse buildCreateContainerVersionResponse() {
  var o = api.CreateContainerVersionResponse();
  buildCounterCreateContainerVersionResponse++;
  if (buildCounterCreateContainerVersionResponse < 3) {
    o.compilerError = true;
    o.containerVersion = buildContainerVersion();
  }
  buildCounterCreateContainerVersionResponse--;
  return o;
}

void checkCreateContainerVersionResponse(api.CreateContainerVersionResponse o) {
  buildCounterCreateContainerVersionResponse++;
  if (buildCounterCreateContainerVersionResponse < 3) {
    unittest.expect(o.compilerError!, unittest.isTrue);
    checkContainerVersion(o.containerVersion! as api.ContainerVersion);
  }
  buildCounterCreateContainerVersionResponse--;
}

core.int buildCounterEnvironment = 0;
api.Environment buildEnvironment() {
  var o = api.Environment();
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    o.accountId = 'foo';
    o.authorizationCode = 'foo';
    o.authorizationTimestampMs = 'foo';
    o.containerId = 'foo';
    o.containerVersionId = 'foo';
    o.description = 'foo';
    o.enableDebug = true;
    o.environmentId = 'foo';
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.type = 'foo';
    o.url = 'foo';
  }
  buildCounterEnvironment--;
  return o;
}

void checkEnvironment(api.Environment o) {
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.authorizationCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.authorizationTimestampMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerVersionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableDebug!, unittest.isTrue);
    unittest.expect(
      o.environmentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
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
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnvironment--;
}

core.int buildCounterFolder = 0;
api.Folder buildFolder() {
  var o = api.Folder();
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.fingerprint = 'foo';
    o.folderId = 'foo';
    o.name = 'foo';
  }
  buildCounterFolder--;
  return o;
}

void checkFolder(api.Folder o) {
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.folderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterFolder--;
}

core.List<api.Tag> buildUnnamed2419() {
  var o = <api.Tag>[];
  o.add(buildTag());
  o.add(buildTag());
  return o;
}

void checkUnnamed2419(core.List<api.Tag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTag(o[0] as api.Tag);
  checkTag(o[1] as api.Tag);
}

core.List<api.Trigger> buildUnnamed2420() {
  var o = <api.Trigger>[];
  o.add(buildTrigger());
  o.add(buildTrigger());
  return o;
}

void checkUnnamed2420(core.List<api.Trigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrigger(o[0] as api.Trigger);
  checkTrigger(o[1] as api.Trigger);
}

core.List<api.Variable> buildUnnamed2421() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed2421(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterFolderEntities = 0;
api.FolderEntities buildFolderEntities() {
  var o = api.FolderEntities();
  buildCounterFolderEntities++;
  if (buildCounterFolderEntities < 3) {
    o.tag = buildUnnamed2419();
    o.trigger = buildUnnamed2420();
    o.variable = buildUnnamed2421();
  }
  buildCounterFolderEntities--;
  return o;
}

void checkFolderEntities(api.FolderEntities o) {
  buildCounterFolderEntities++;
  if (buildCounterFolderEntities < 3) {
    checkUnnamed2419(o.tag!);
    checkUnnamed2420(o.trigger!);
    checkUnnamed2421(o.variable!);
  }
  buildCounterFolderEntities--;
}

core.List<api.UserAccess> buildUnnamed2422() {
  var o = <api.UserAccess>[];
  o.add(buildUserAccess());
  o.add(buildUserAccess());
  return o;
}

void checkUnnamed2422(core.List<api.UserAccess> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserAccess(o[0] as api.UserAccess);
  checkUserAccess(o[1] as api.UserAccess);
}

core.int buildCounterListAccountUsersResponse = 0;
api.ListAccountUsersResponse buildListAccountUsersResponse() {
  var o = api.ListAccountUsersResponse();
  buildCounterListAccountUsersResponse++;
  if (buildCounterListAccountUsersResponse < 3) {
    o.userAccess = buildUnnamed2422();
  }
  buildCounterListAccountUsersResponse--;
  return o;
}

void checkListAccountUsersResponse(api.ListAccountUsersResponse o) {
  buildCounterListAccountUsersResponse++;
  if (buildCounterListAccountUsersResponse < 3) {
    checkUnnamed2422(o.userAccess!);
  }
  buildCounterListAccountUsersResponse--;
}

core.List<api.Account> buildUnnamed2423() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed2423(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterListAccountsResponse = 0;
api.ListAccountsResponse buildListAccountsResponse() {
  var o = api.ListAccountsResponse();
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    o.accounts = buildUnnamed2423();
  }
  buildCounterListAccountsResponse--;
  return o;
}

void checkListAccountsResponse(api.ListAccountsResponse o) {
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    checkUnnamed2423(o.accounts!);
  }
  buildCounterListAccountsResponse--;
}

core.List<api.ContainerVersion> buildUnnamed2424() {
  var o = <api.ContainerVersion>[];
  o.add(buildContainerVersion());
  o.add(buildContainerVersion());
  return o;
}

void checkUnnamed2424(core.List<api.ContainerVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainerVersion(o[0] as api.ContainerVersion);
  checkContainerVersion(o[1] as api.ContainerVersion);
}

core.List<api.ContainerVersionHeader> buildUnnamed2425() {
  var o = <api.ContainerVersionHeader>[];
  o.add(buildContainerVersionHeader());
  o.add(buildContainerVersionHeader());
  return o;
}

void checkUnnamed2425(core.List<api.ContainerVersionHeader> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainerVersionHeader(o[0] as api.ContainerVersionHeader);
  checkContainerVersionHeader(o[1] as api.ContainerVersionHeader);
}

core.int buildCounterListContainerVersionsResponse = 0;
api.ListContainerVersionsResponse buildListContainerVersionsResponse() {
  var o = api.ListContainerVersionsResponse();
  buildCounterListContainerVersionsResponse++;
  if (buildCounterListContainerVersionsResponse < 3) {
    o.containerVersion = buildUnnamed2424();
    o.containerVersionHeader = buildUnnamed2425();
  }
  buildCounterListContainerVersionsResponse--;
  return o;
}

void checkListContainerVersionsResponse(api.ListContainerVersionsResponse o) {
  buildCounterListContainerVersionsResponse++;
  if (buildCounterListContainerVersionsResponse < 3) {
    checkUnnamed2424(o.containerVersion!);
    checkUnnamed2425(o.containerVersionHeader!);
  }
  buildCounterListContainerVersionsResponse--;
}

core.List<api.Container> buildUnnamed2426() {
  var o = <api.Container>[];
  o.add(buildContainer());
  o.add(buildContainer());
  return o;
}

void checkUnnamed2426(core.List<api.Container> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainer(o[0] as api.Container);
  checkContainer(o[1] as api.Container);
}

core.int buildCounterListContainersResponse = 0;
api.ListContainersResponse buildListContainersResponse() {
  var o = api.ListContainersResponse();
  buildCounterListContainersResponse++;
  if (buildCounterListContainersResponse < 3) {
    o.containers = buildUnnamed2426();
  }
  buildCounterListContainersResponse--;
  return o;
}

void checkListContainersResponse(api.ListContainersResponse o) {
  buildCounterListContainersResponse++;
  if (buildCounterListContainersResponse < 3) {
    checkUnnamed2426(o.containers!);
  }
  buildCounterListContainersResponse--;
}

core.List<api.Environment> buildUnnamed2427() {
  var o = <api.Environment>[];
  o.add(buildEnvironment());
  o.add(buildEnvironment());
  return o;
}

void checkUnnamed2427(core.List<api.Environment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEnvironment(o[0] as api.Environment);
  checkEnvironment(o[1] as api.Environment);
}

core.int buildCounterListEnvironmentsResponse = 0;
api.ListEnvironmentsResponse buildListEnvironmentsResponse() {
  var o = api.ListEnvironmentsResponse();
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    o.environments = buildUnnamed2427();
  }
  buildCounterListEnvironmentsResponse--;
  return o;
}

void checkListEnvironmentsResponse(api.ListEnvironmentsResponse o) {
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    checkUnnamed2427(o.environments!);
  }
  buildCounterListEnvironmentsResponse--;
}

core.List<api.Folder> buildUnnamed2428() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed2428(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterListFoldersResponse = 0;
api.ListFoldersResponse buildListFoldersResponse() {
  var o = api.ListFoldersResponse();
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    o.folders = buildUnnamed2428();
  }
  buildCounterListFoldersResponse--;
  return o;
}

void checkListFoldersResponse(api.ListFoldersResponse o) {
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    checkUnnamed2428(o.folders!);
  }
  buildCounterListFoldersResponse--;
}

core.List<api.Tag> buildUnnamed2429() {
  var o = <api.Tag>[];
  o.add(buildTag());
  o.add(buildTag());
  return o;
}

void checkUnnamed2429(core.List<api.Tag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTag(o[0] as api.Tag);
  checkTag(o[1] as api.Tag);
}

core.int buildCounterListTagsResponse = 0;
api.ListTagsResponse buildListTagsResponse() {
  var o = api.ListTagsResponse();
  buildCounterListTagsResponse++;
  if (buildCounterListTagsResponse < 3) {
    o.tags = buildUnnamed2429();
  }
  buildCounterListTagsResponse--;
  return o;
}

void checkListTagsResponse(api.ListTagsResponse o) {
  buildCounterListTagsResponse++;
  if (buildCounterListTagsResponse < 3) {
    checkUnnamed2429(o.tags!);
  }
  buildCounterListTagsResponse--;
}

core.List<api.Trigger> buildUnnamed2430() {
  var o = <api.Trigger>[];
  o.add(buildTrigger());
  o.add(buildTrigger());
  return o;
}

void checkUnnamed2430(core.List<api.Trigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrigger(o[0] as api.Trigger);
  checkTrigger(o[1] as api.Trigger);
}

core.int buildCounterListTriggersResponse = 0;
api.ListTriggersResponse buildListTriggersResponse() {
  var o = api.ListTriggersResponse();
  buildCounterListTriggersResponse++;
  if (buildCounterListTriggersResponse < 3) {
    o.triggers = buildUnnamed2430();
  }
  buildCounterListTriggersResponse--;
  return o;
}

void checkListTriggersResponse(api.ListTriggersResponse o) {
  buildCounterListTriggersResponse++;
  if (buildCounterListTriggersResponse < 3) {
    checkUnnamed2430(o.triggers!);
  }
  buildCounterListTriggersResponse--;
}

core.List<api.Variable> buildUnnamed2431() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed2431(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterListVariablesResponse = 0;
api.ListVariablesResponse buildListVariablesResponse() {
  var o = api.ListVariablesResponse();
  buildCounterListVariablesResponse++;
  if (buildCounterListVariablesResponse < 3) {
    o.variables = buildUnnamed2431();
  }
  buildCounterListVariablesResponse--;
  return o;
}

void checkListVariablesResponse(api.ListVariablesResponse o) {
  buildCounterListVariablesResponse++;
  if (buildCounterListVariablesResponse < 3) {
    checkUnnamed2431(o.variables!);
  }
  buildCounterListVariablesResponse--;
}

core.List<core.String> buildUnnamed2432() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2432(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2433() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2433(core.List<core.String> o) {
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

core.List<api.Parameter> buildUnnamed2434() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed2434(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.int buildCounterMacro = 0;
api.Macro buildMacro() {
  var o = api.Macro();
  buildCounterMacro++;
  if (buildCounterMacro < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.disablingRuleId = buildUnnamed2432();
    o.enablingRuleId = buildUnnamed2433();
    o.fingerprint = 'foo';
    o.macroId = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.parameter = buildUnnamed2434();
    o.parentFolderId = 'foo';
    o.scheduleEndMs = 'foo';
    o.scheduleStartMs = 'foo';
    o.type = 'foo';
  }
  buildCounterMacro--;
  return o;
}

void checkMacro(api.Macro o) {
  buildCounterMacro++;
  if (buildCounterMacro < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    checkUnnamed2432(o.disablingRuleId!);
    checkUnnamed2433(o.enablingRuleId!);
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.macroId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkUnnamed2434(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheduleEndMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheduleStartMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterMacro--;
}

core.List<api.Parameter> buildUnnamed2435() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed2435(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.List<api.Parameter> buildUnnamed2436() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed2436(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.int buildCounterParameter = 0;
api.Parameter buildParameter() {
  var o = api.Parameter();
  buildCounterParameter++;
  if (buildCounterParameter < 3) {
    o.key = 'foo';
    o.list = buildUnnamed2435();
    o.map = buildUnnamed2436();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterParameter--;
  return o;
}

void checkParameter(api.Parameter o) {
  buildCounterParameter++;
  if (buildCounterParameter < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    checkUnnamed2435(o.list!);
    checkUnnamed2436(o.map!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterParameter--;
}

core.int buildCounterPublishContainerVersionResponse = 0;
api.PublishContainerVersionResponse buildPublishContainerVersionResponse() {
  var o = api.PublishContainerVersionResponse();
  buildCounterPublishContainerVersionResponse++;
  if (buildCounterPublishContainerVersionResponse < 3) {
    o.compilerError = true;
    o.containerVersion = buildContainerVersion();
  }
  buildCounterPublishContainerVersionResponse--;
  return o;
}

void checkPublishContainerVersionResponse(
    api.PublishContainerVersionResponse o) {
  buildCounterPublishContainerVersionResponse++;
  if (buildCounterPublishContainerVersionResponse < 3) {
    unittest.expect(o.compilerError!, unittest.isTrue);
    checkContainerVersion(o.containerVersion! as api.ContainerVersion);
  }
  buildCounterPublishContainerVersionResponse--;
}

core.List<api.Condition> buildUnnamed2437() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed2437(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.int buildCounterRule = 0;
api.Rule buildRule() {
  var o = api.Rule();
  buildCounterRule++;
  if (buildCounterRule < 3) {
    o.accountId = 'foo';
    o.condition = buildUnnamed2437();
    o.containerId = 'foo';
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.ruleId = 'foo';
  }
  buildCounterRule--;
  return o;
}

void checkRule(api.Rule o) {
  buildCounterRule++;
  if (buildCounterRule < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkUnnamed2437(o.condition!);
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ruleId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRule--;
}

core.int buildCounterSetupTag = 0;
api.SetupTag buildSetupTag() {
  var o = api.SetupTag();
  buildCounterSetupTag++;
  if (buildCounterSetupTag < 3) {
    o.stopOnSetupFailure = true;
    o.tagName = 'foo';
  }
  buildCounterSetupTag--;
  return o;
}

void checkSetupTag(api.SetupTag o) {
  buildCounterSetupTag++;
  if (buildCounterSetupTag < 3) {
    unittest.expect(o.stopOnSetupFailure!, unittest.isTrue);
    unittest.expect(
      o.tagName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetupTag--;
}

core.List<core.String> buildUnnamed2438() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2438(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2439() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2439(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2440() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2440(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2441() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2441(core.List<core.String> o) {
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

core.List<api.Parameter> buildUnnamed2442() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed2442(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.List<api.SetupTag> buildUnnamed2443() {
  var o = <api.SetupTag>[];
  o.add(buildSetupTag());
  o.add(buildSetupTag());
  return o;
}

void checkUnnamed2443(core.List<api.SetupTag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSetupTag(o[0] as api.SetupTag);
  checkSetupTag(o[1] as api.SetupTag);
}

core.List<api.TeardownTag> buildUnnamed2444() {
  var o = <api.TeardownTag>[];
  o.add(buildTeardownTag());
  o.add(buildTeardownTag());
  return o;
}

void checkUnnamed2444(core.List<api.TeardownTag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTeardownTag(o[0] as api.TeardownTag);
  checkTeardownTag(o[1] as api.TeardownTag);
}

core.int buildCounterTag = 0;
api.Tag buildTag() {
  var o = api.Tag();
  buildCounterTag++;
  if (buildCounterTag < 3) {
    o.accountId = 'foo';
    o.blockingRuleId = buildUnnamed2438();
    o.blockingTriggerId = buildUnnamed2439();
    o.containerId = 'foo';
    o.fingerprint = 'foo';
    o.firingRuleId = buildUnnamed2440();
    o.firingTriggerId = buildUnnamed2441();
    o.liveOnly = true;
    o.name = 'foo';
    o.notes = 'foo';
    o.parameter = buildUnnamed2442();
    o.parentFolderId = 'foo';
    o.paused = true;
    o.priority = buildParameter();
    o.scheduleEndMs = 'foo';
    o.scheduleStartMs = 'foo';
    o.setupTag = buildUnnamed2443();
    o.tagFiringOption = 'foo';
    o.tagId = 'foo';
    o.teardownTag = buildUnnamed2444();
    o.type = 'foo';
  }
  buildCounterTag--;
  return o;
}

void checkTag(api.Tag o) {
  buildCounterTag++;
  if (buildCounterTag < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkUnnamed2438(o.blockingRuleId!);
    checkUnnamed2439(o.blockingTriggerId!);
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    checkUnnamed2440(o.firingRuleId!);
    checkUnnamed2441(o.firingTriggerId!);
    unittest.expect(o.liveOnly!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkUnnamed2442(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.paused!, unittest.isTrue);
    checkParameter(o.priority! as api.Parameter);
    unittest.expect(
      o.scheduleEndMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheduleStartMs!,
      unittest.equals('foo'),
    );
    checkUnnamed2443(o.setupTag!);
    unittest.expect(
      o.tagFiringOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagId!,
      unittest.equals('foo'),
    );
    checkUnnamed2444(o.teardownTag!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterTag--;
}

core.int buildCounterTeardownTag = 0;
api.TeardownTag buildTeardownTag() {
  var o = api.TeardownTag();
  buildCounterTeardownTag++;
  if (buildCounterTeardownTag < 3) {
    o.stopTeardownOnFailure = true;
    o.tagName = 'foo';
  }
  buildCounterTeardownTag--;
  return o;
}

void checkTeardownTag(api.TeardownTag o) {
  buildCounterTeardownTag++;
  if (buildCounterTeardownTag < 3) {
    unittest.expect(o.stopTeardownOnFailure!, unittest.isTrue);
    unittest.expect(
      o.tagName!,
      unittest.equals('foo'),
    );
  }
  buildCounterTeardownTag--;
}

core.List<api.Condition> buildUnnamed2445() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed2445(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<api.Condition> buildUnnamed2446() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed2446(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<api.Condition> buildUnnamed2447() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed2447(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<api.Parameter> buildUnnamed2448() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed2448(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.int buildCounterTrigger = 0;
api.Trigger buildTrigger() {
  var o = api.Trigger();
  buildCounterTrigger++;
  if (buildCounterTrigger < 3) {
    o.accountId = 'foo';
    o.autoEventFilter = buildUnnamed2445();
    o.checkValidation = buildParameter();
    o.containerId = 'foo';
    o.continuousTimeMinMilliseconds = buildParameter();
    o.customEventFilter = buildUnnamed2446();
    o.eventName = buildParameter();
    o.filter = buildUnnamed2447();
    o.fingerprint = 'foo';
    o.horizontalScrollPercentageList = buildParameter();
    o.interval = buildParameter();
    o.intervalSeconds = buildParameter();
    o.limit = buildParameter();
    o.maxTimerLengthSeconds = buildParameter();
    o.name = 'foo';
    o.parameter = buildUnnamed2448();
    o.parentFolderId = 'foo';
    o.selector = buildParameter();
    o.totalTimeMinMilliseconds = buildParameter();
    o.triggerId = 'foo';
    o.type = 'foo';
    o.uniqueTriggerId = buildParameter();
    o.verticalScrollPercentageList = buildParameter();
    o.visibilitySelector = buildParameter();
    o.visiblePercentageMax = buildParameter();
    o.visiblePercentageMin = buildParameter();
    o.waitForTags = buildParameter();
    o.waitForTagsTimeout = buildParameter();
  }
  buildCounterTrigger--;
  return o;
}

void checkTrigger(api.Trigger o) {
  buildCounterTrigger++;
  if (buildCounterTrigger < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkUnnamed2445(o.autoEventFilter!);
    checkParameter(o.checkValidation! as api.Parameter);
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    checkParameter(o.continuousTimeMinMilliseconds! as api.Parameter);
    checkUnnamed2446(o.customEventFilter!);
    checkParameter(o.eventName! as api.Parameter);
    checkUnnamed2447(o.filter!);
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    checkParameter(o.horizontalScrollPercentageList! as api.Parameter);
    checkParameter(o.interval! as api.Parameter);
    checkParameter(o.intervalSeconds! as api.Parameter);
    checkParameter(o.limit! as api.Parameter);
    checkParameter(o.maxTimerLengthSeconds! as api.Parameter);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2448(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    checkParameter(o.selector! as api.Parameter);
    checkParameter(o.totalTimeMinMilliseconds! as api.Parameter);
    unittest.expect(
      o.triggerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkParameter(o.uniqueTriggerId! as api.Parameter);
    checkParameter(o.verticalScrollPercentageList! as api.Parameter);
    checkParameter(o.visibilitySelector! as api.Parameter);
    checkParameter(o.visiblePercentageMax! as api.Parameter);
    checkParameter(o.visiblePercentageMin! as api.Parameter);
    checkParameter(o.waitForTags! as api.Parameter);
    checkParameter(o.waitForTagsTimeout! as api.Parameter);
  }
  buildCounterTrigger--;
}

core.List<api.ContainerAccess> buildUnnamed2449() {
  var o = <api.ContainerAccess>[];
  o.add(buildContainerAccess());
  o.add(buildContainerAccess());
  return o;
}

void checkUnnamed2449(core.List<api.ContainerAccess> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainerAccess(o[0] as api.ContainerAccess);
  checkContainerAccess(o[1] as api.ContainerAccess);
}

core.int buildCounterUserAccess = 0;
api.UserAccess buildUserAccess() {
  var o = api.UserAccess();
  buildCounterUserAccess++;
  if (buildCounterUserAccess < 3) {
    o.accountAccess = buildAccountAccess();
    o.accountId = 'foo';
    o.containerAccess = buildUnnamed2449();
    o.emailAddress = 'foo';
    o.permissionId = 'foo';
  }
  buildCounterUserAccess--;
  return o;
}

void checkUserAccess(api.UserAccess o) {
  buildCounterUserAccess++;
  if (buildCounterUserAccess < 3) {
    checkAccountAccess(o.accountAccess! as api.AccountAccess);
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkUnnamed2449(o.containerAccess!);
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.permissionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserAccess--;
}

core.List<core.String> buildUnnamed2450() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2450(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2451() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2451(core.List<core.String> o) {
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

core.List<api.Parameter> buildUnnamed2452() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed2452(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.int buildCounterVariable = 0;
api.Variable buildVariable() {
  var o = api.Variable();
  buildCounterVariable++;
  if (buildCounterVariable < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.disablingTriggerId = buildUnnamed2450();
    o.enablingTriggerId = buildUnnamed2451();
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.parameter = buildUnnamed2452();
    o.parentFolderId = 'foo';
    o.scheduleEndMs = 'foo';
    o.scheduleStartMs = 'foo';
    o.type = 'foo';
    o.variableId = 'foo';
  }
  buildCounterVariable--;
  return o;
}

void checkVariable(api.Variable o) {
  buildCounterVariable++;
  if (buildCounterVariable < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    checkUnnamed2450(o.disablingTriggerId!);
    checkUnnamed2451(o.enablingTriggerId!);
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkUnnamed2452(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheduleEndMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheduleStartMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.variableId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVariable--;
}

core.List<core.String> buildUnnamed2453() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2453(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2454() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2454(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2455() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2455(core.List<core.String> o) {
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

  unittest.group('obj-schema-AccountAccess', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountAccess();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountAccess.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountAccess(od as api.AccountAccess);
    });
  });

  unittest.group('obj-schema-Condition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCondition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Condition.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCondition(od as api.Condition);
    });
  });

  unittest.group('obj-schema-Container', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContainer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Container.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkContainer(od as api.Container);
    });
  });

  unittest.group('obj-schema-ContainerAccess', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContainerAccess();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContainerAccess.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContainerAccess(od as api.ContainerAccess);
    });
  });

  unittest.group('obj-schema-ContainerVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContainerVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContainerVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContainerVersion(od as api.ContainerVersion);
    });
  });

  unittest.group('obj-schema-ContainerVersionHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContainerVersionHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContainerVersionHeader.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContainerVersionHeader(od as api.ContainerVersionHeader);
    });
  });

  unittest.group('obj-schema-CreateContainerVersionRequestVersionOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateContainerVersionRequestVersionOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateContainerVersionRequestVersionOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateContainerVersionRequestVersionOptions(
          od as api.CreateContainerVersionRequestVersionOptions);
    });
  });

  unittest.group('obj-schema-CreateContainerVersionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateContainerVersionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateContainerVersionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateContainerVersionResponse(
          od as api.CreateContainerVersionResponse);
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

  unittest.group('obj-schema-Folder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFolder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Folder.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFolder(od as api.Folder);
    });
  });

  unittest.group('obj-schema-FolderEntities', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFolderEntities();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FolderEntities.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFolderEntities(od as api.FolderEntities);
    });
  });

  unittest.group('obj-schema-ListAccountUsersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAccountUsersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAccountUsersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAccountUsersResponse(od as api.ListAccountUsersResponse);
    });
  });

  unittest.group('obj-schema-ListAccountsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAccountsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAccountsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAccountsResponse(od as api.ListAccountsResponse);
    });
  });

  unittest.group('obj-schema-ListContainerVersionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListContainerVersionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListContainerVersionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListContainerVersionsResponse(
          od as api.ListContainerVersionsResponse);
    });
  });

  unittest.group('obj-schema-ListContainersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListContainersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListContainersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListContainersResponse(od as api.ListContainersResponse);
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

  unittest.group('obj-schema-ListFoldersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFoldersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFoldersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFoldersResponse(od as api.ListFoldersResponse);
    });
  });

  unittest.group('obj-schema-ListTagsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTagsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTagsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTagsResponse(od as api.ListTagsResponse);
    });
  });

  unittest.group('obj-schema-ListTriggersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTriggersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTriggersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTriggersResponse(od as api.ListTriggersResponse);
    });
  });

  unittest.group('obj-schema-ListVariablesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListVariablesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListVariablesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListVariablesResponse(od as api.ListVariablesResponse);
    });
  });

  unittest.group('obj-schema-Macro', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMacro();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Macro.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMacro(od as api.Macro);
    });
  });

  unittest.group('obj-schema-Parameter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParameter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Parameter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkParameter(od as api.Parameter);
    });
  });

  unittest.group('obj-schema-PublishContainerVersionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublishContainerVersionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PublishContainerVersionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPublishContainerVersionResponse(
          od as api.PublishContainerVersionResponse);
    });
  });

  unittest.group('obj-schema-Rule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Rule.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRule(od as api.Rule);
    });
  });

  unittest.group('obj-schema-SetupTag', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetupTag();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SetupTag.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSetupTag(od as api.SetupTag);
    });
  });

  unittest.group('obj-schema-Tag', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTag();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Tag.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTag(od as api.Tag);
    });
  });

  unittest.group('obj-schema-TeardownTag', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTeardownTag();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TeardownTag.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTeardownTag(od as api.TeardownTag);
    });
  });

  unittest.group('obj-schema-Trigger', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrigger();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Trigger.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTrigger(od as api.Trigger);
    });
  });

  unittest.group('obj-schema-UserAccess', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserAccess();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserAccess.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserAccess(od as api.UserAccess);
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

  unittest.group('resource-AccountsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts;
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_accountId, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts;
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
          unittest.equals("tagmanager/v1/accounts"),
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
        var resp = convert.json.encode(buildListAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list($fields: arg_$fields);
      checkListAccountsResponse(response as api.ListAccountsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts;
      var arg_request = buildAccount();
      var arg_accountId = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Account.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAccount(obj as api.Account);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
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
      final response = await res.update(arg_request, arg_accountId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });
  });

  unittest.group('resource-AccountsContainersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_request = buildContainer();
      var arg_accountId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Container.fromJson(json as core.Map<core.String, core.dynamic>);
        checkContainer(obj as api.Container);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers', pathOffset);
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
          unittest.equals("/containers"),
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
        var resp = convert.json.encode(buildContainer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_accountId, $fields: arg_$fields);
      checkContainer(response as api.Container);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
      await res.delete(arg_accountId, arg_containerId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
        var resp = convert.json.encode(buildContainer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_accountId, arg_containerId, $fields: arg_$fields);
      checkContainer(response as api.Container);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers', pathOffset);
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
          unittest.equals("/containers"),
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
        var resp = convert.json.encode(buildListContainersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, $fields: arg_$fields);
      checkListContainersResponse(response as api.ListContainersResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_request = buildContainer();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Container.fromJson(json as core.Map<core.String, core.dynamic>);
        checkContainer(obj as api.Container);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildContainer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkContainer(response as api.Container);
    });
  });

  unittest.group('resource-AccountsContainersEnvironmentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_request = buildEnvironment();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/environments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/environments"),
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
        var resp = convert.json.encode(buildEnvironment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_accountId, arg_containerId,
          $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_environmentId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/environments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/environments/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_environmentId'),
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
      await res.delete(arg_accountId, arg_containerId, arg_environmentId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_environmentId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/environments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/environments/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_environmentId'),
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
        var resp = convert.json.encode(buildEnvironment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_containerId, arg_environmentId,
          $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/environments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/environments"),
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
        var resp = convert.json.encode(buildListEnvironmentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_accountId, arg_containerId, $fields: arg_$fields);
      checkListEnvironmentsResponse(response as api.ListEnvironmentsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_request = buildEnvironment();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_environmentId = 'foo';
      var arg_fingerprint = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/environments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/environments/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_environmentId'),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
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
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId, arg_environmentId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });
  });

  unittest.group('resource-AccountsContainersFoldersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.folders;
      var arg_request = buildFolder();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Folder.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFolder(obj as api.Folder);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/folders', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/folders"),
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
        var resp = convert.json.encode(buildFolder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_accountId, arg_containerId,
          $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.folders;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_folderId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/folders/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/folders/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_folderId'),
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
      await res.delete(arg_accountId, arg_containerId, arg_folderId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.folders;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_folderId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/folders/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/folders/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_folderId'),
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
        var resp = convert.json.encode(buildFolder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_containerId, arg_folderId,
          $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.folders;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/folders', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/folders"),
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
        var resp = convert.json.encode(buildListFoldersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_accountId, arg_containerId, $fields: arg_$fields);
      checkListFoldersResponse(response as api.ListFoldersResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.folders;
      var arg_request = buildFolder();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_folderId = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Folder.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFolder(obj as api.Folder);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/folders/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/folders/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_folderId'),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFolder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId, arg_folderId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });
  });

  unittest.group('resource-AccountsContainersFoldersEntitiesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.folders.entities;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_folderId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/folders/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/folders/"),
        );
        pathOffset += 9;
        index = path.indexOf('/entities', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_folderId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/entities"),
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
        var resp = convert.json.encode(buildFolderEntities());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_containerId, arg_folderId,
          $fields: arg_$fields);
      checkFolderEntities(response as api.FolderEntities);
    });
  });

  unittest.group('resource-AccountsContainersMoveFoldersResource', () {
    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.moveFolders;
      var arg_request = buildFolder();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_folderId = 'foo';
      var arg_tagId = buildUnnamed2453();
      var arg_triggerId = buildUnnamed2454();
      var arg_variableId = buildUnnamed2455();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Folder.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFolder(obj as api.Folder);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/move_folders/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/move_folders/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_folderId'),
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
          queryMap["tagId"]!,
          unittest.equals(arg_tagId),
        );
        unittest.expect(
          queryMap["triggerId"]!,
          unittest.equals(arg_triggerId),
        );
        unittest.expect(
          queryMap["variableId"]!,
          unittest.equals(arg_variableId),
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
      await res.update(
          arg_request, arg_accountId, arg_containerId, arg_folderId,
          tagId: arg_tagId,
          triggerId: arg_triggerId,
          variableId: arg_variableId,
          $fields: arg_$fields);
    });
  });

  unittest.group('resource-AccountsContainersReauthorizeEnvironmentsResource',
      () {
    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.reauthorizeEnvironments;
      var arg_request = buildEnvironment();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/reauthorize_environments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("/reauthorize_environments/"),
        );
        pathOffset += 26;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_environmentId'),
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
        var resp = convert.json.encode(buildEnvironment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId, arg_environmentId,
          $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });
  });

  unittest.group('resource-AccountsContainersTagsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.tags;
      var arg_request = buildTag();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Tag.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTag(obj as api.Tag);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/tags', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/tags"),
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
        var resp = convert.json.encode(buildTag());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_accountId, arg_containerId,
          $fields: arg_$fields);
      checkTag(response as api.Tag);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.tags;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_tagId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/tags/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/tags/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tagId'),
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
      await res.delete(arg_accountId, arg_containerId, arg_tagId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.tags;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_tagId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/tags/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/tags/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tagId'),
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
        var resp = convert.json.encode(buildTag());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_accountId, arg_containerId, arg_tagId,
          $fields: arg_$fields);
      checkTag(response as api.Tag);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.tags;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/tags', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/tags"),
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
        var resp = convert.json.encode(buildListTagsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_accountId, arg_containerId, $fields: arg_$fields);
      checkListTagsResponse(response as api.ListTagsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.tags;
      var arg_request = buildTag();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_tagId = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Tag.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTag(obj as api.Tag);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/tags/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/tags/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tagId'),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTag());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId, arg_tagId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkTag(response as api.Tag);
    });
  });

  unittest.group('resource-AccountsContainersTriggersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.triggers;
      var arg_request = buildTrigger();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Trigger.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTrigger(obj as api.Trigger);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/triggers', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/triggers"),
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
        var resp = convert.json.encode(buildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_accountId, arg_containerId,
          $fields: arg_$fields);
      checkTrigger(response as api.Trigger);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.triggers;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_triggerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_triggerId'),
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
      await res.delete(arg_accountId, arg_containerId, arg_triggerId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.triggers;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_triggerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_triggerId'),
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
        var resp = convert.json.encode(buildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_containerId, arg_triggerId,
          $fields: arg_$fields);
      checkTrigger(response as api.Trigger);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.triggers;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/triggers', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/triggers"),
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
        var resp = convert.json.encode(buildListTriggersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_accountId, arg_containerId, $fields: arg_$fields);
      checkListTriggersResponse(response as api.ListTriggersResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.triggers;
      var arg_request = buildTrigger();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_triggerId = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Trigger.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTrigger(obj as api.Trigger);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_triggerId'),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId, arg_triggerId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkTrigger(response as api.Trigger);
    });
  });

  unittest.group('resource-AccountsContainersVariablesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.variables;
      var arg_request = buildVariable();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Variable.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVariable(obj as api.Variable);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variables', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/variables"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVariable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_accountId, arg_containerId,
          $fields: arg_$fields);
      checkVariable(response as api.Variable);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.variables;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_variableId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/variables/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_variableId'),
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
      await res.delete(arg_accountId, arg_containerId, arg_variableId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.variables;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_variableId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/variables/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_variableId'),
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
        var resp = convert.json.encode(buildVariable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_containerId, arg_variableId,
          $fields: arg_$fields);
      checkVariable(response as api.Variable);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.variables;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variables', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/variables"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListVariablesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_accountId, arg_containerId, $fields: arg_$fields);
      checkListVariablesResponse(response as api.ListVariablesResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.variables;
      var arg_request = buildVariable();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_variableId = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Variable.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVariable(obj as api.Variable);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/variables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/variables/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_variableId'),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVariable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId, arg_variableId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkVariable(response as api.Variable);
    });
  });

  unittest.group('resource-AccountsContainersVersionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_request = buildCreateContainerVersionRequestVersionOptions();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateContainerVersionRequestVersionOptions.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateContainerVersionRequestVersionOptions(
            obj as api.CreateContainerVersionRequestVersionOptions);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
        var resp = convert.json.encode(buildCreateContainerVersionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_accountId, arg_containerId,
          $fields: arg_$fields);
      checkCreateContainerVersionResponse(
          response as api.CreateContainerVersionResponse);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_containerVersionId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
          unittest.equals('$arg_containerVersionId'),
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
      await res.delete(arg_accountId, arg_containerId, arg_containerVersionId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_containerVersionId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
          unittest.equals('$arg_containerVersionId'),
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
        var resp = convert.json.encode(buildContainerVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_containerId, arg_containerVersionId,
          $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_headers = true;
      var arg_includeDeleted = true;
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
          queryMap["headers"]!.first,
          unittest.equals("$arg_headers"),
        );
        unittest.expect(
          queryMap["includeDeleted"]!.first,
          unittest.equals("$arg_includeDeleted"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListContainerVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_containerId,
          headers: arg_headers,
          includeDeleted: arg_includeDeleted,
          $fields: arg_$fields);
      checkListContainerVersionsResponse(
          response as api.ListContainerVersionsResponse);
    });

    unittest.test('method--publish', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_containerVersionId = 'foo';
      var arg_fingerprint = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        index = path.indexOf('/publish', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerVersionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/publish"),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPublishContainerVersionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.publish(
          arg_accountId, arg_containerId, arg_containerVersionId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkPublishContainerVersionResponse(
          response as api.PublishContainerVersionResponse);
    });

    unittest.test('method--restore', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_containerVersionId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        index = path.indexOf('/restore', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerVersionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/restore"),
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
        var resp = convert.json.encode(buildContainerVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.restore(
          arg_accountId, arg_containerId, arg_containerVersionId,
          $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_containerVersionId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        index = path.indexOf('/undelete', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerVersionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/undelete"),
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
        var resp = convert.json.encode(buildContainerVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.undelete(
          arg_accountId, arg_containerId, arg_containerVersionId,
          $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_request = buildContainerVersion();
      var arg_accountId = 'foo';
      var arg_containerId = 'foo';
      var arg_containerVersionId = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ContainerVersion.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkContainerVersion(obj as api.ContainerVersion);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/containers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/containers/"),
        );
        pathOffset += 12;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_containerId'),
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
          unittest.equals('$arg_containerVersionId'),
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
          queryMap["fingerprint"]!.first,
          unittest.equals(arg_fingerprint),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildContainerVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_containerId, arg_containerVersionId,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });
  });

  unittest.group('resource-AccountsPermissionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.permissions;
      var arg_request = buildUserAccess();
      var arg_accountId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserAccess.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserAccess(obj as api.UserAccess);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/permissions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/permissions"),
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
        var resp = convert.json.encode(buildUserAccess());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_accountId, $fields: arg_$fields);
      checkUserAccess(response as api.UserAccess);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.permissions;
      var arg_accountId = 'foo';
      var arg_permissionId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/permissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/permissions/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_permissionId'),
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
      await res.delete(arg_accountId, arg_permissionId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.permissions;
      var arg_accountId = 'foo';
      var arg_permissionId = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/permissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/permissions/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_permissionId'),
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
        var resp = convert.json.encode(buildUserAccess());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_accountId, arg_permissionId, $fields: arg_$fields);
      checkUserAccess(response as api.UserAccess);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.permissions;
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/permissions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/permissions"),
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
        var resp = convert.json.encode(buildListAccountUsersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, $fields: arg_$fields);
      checkListAccountUsersResponse(response as api.ListAccountUsersResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.permissions;
      var arg_request = buildUserAccess();
      var arg_accountId = 'foo';
      var arg_permissionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserAccess.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserAccess(obj as api.UserAccess);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("tagmanager/v1/accounts/"),
        );
        pathOffset += 23;
        index = path.indexOf('/permissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/permissions/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_permissionId'),
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
        var resp = convert.json.encode(buildUserAccess());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_permissionId,
          $fields: arg_$fields);
      checkUserAccess(response as api.UserAccess);
    });
  });
}

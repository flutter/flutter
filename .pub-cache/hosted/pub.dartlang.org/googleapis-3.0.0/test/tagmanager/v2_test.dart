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

import 'package:googleapis/tagmanager/v2.dart' as api;
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
    o.path = 'foo';
    o.shareData = true;
    o.tagManagerUrl = 'foo';
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
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(o.shareData!, unittest.isTrue);
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccount--;
}

core.int buildCounterAccountAccess = 0;
api.AccountAccess buildAccountAccess() {
  var o = api.AccountAccess();
  buildCounterAccountAccess++;
  if (buildCounterAccountAccess < 3) {
    o.permission = 'foo';
  }
  buildCounterAccountAccess--;
  return o;
}

void checkAccountAccess(api.AccountAccess o) {
  buildCounterAccountAccess++;
  if (buildCounterAccountAccess < 3) {
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccountAccess--;
}

core.int buildCounterBuiltInVariable = 0;
api.BuiltInVariable buildBuiltInVariable() {
  var o = api.BuiltInVariable();
  buildCounterBuiltInVariable++;
  if (buildCounterBuiltInVariable < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.name = 'foo';
    o.path = 'foo';
    o.type = 'foo';
    o.workspaceId = 'foo';
  }
  buildCounterBuiltInVariable--;
  return o;
}

void checkBuiltInVariable(api.BuiltInVariable o) {
  buildCounterBuiltInVariable++;
  if (buildCounterBuiltInVariable < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuiltInVariable--;
}

core.List<api.Parameter> buildUnnamed5251() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed5251(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.int buildCounterClient = 0;
api.Client buildClient() {
  var o = api.Client();
  buildCounterClient++;
  if (buildCounterClient < 3) {
    o.accountId = 'foo';
    o.clientId = 'foo';
    o.containerId = 'foo';
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.parameter = buildUnnamed5251();
    o.parentFolderId = 'foo';
    o.path = 'foo';
    o.priority = 42;
    o.tagManagerUrl = 'foo';
    o.type = 'foo';
    o.workspaceId = 'foo';
  }
  buildCounterClient--;
  return o;
}

void checkClient(api.Client o) {
  buildCounterClient++;
  if (buildCounterClient < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clientId!,
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
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkUnnamed5251(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.priority!,
      unittest.equals(42),
    );
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterClient--;
}

core.List<api.Parameter> buildUnnamed5252() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed5252(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.int buildCounterCondition = 0;
api.Condition buildCondition() {
  var o = api.Condition();
  buildCounterCondition++;
  if (buildCounterCondition < 3) {
    o.parameter = buildUnnamed5252();
    o.type = 'foo';
  }
  buildCounterCondition--;
  return o;
}

void checkCondition(api.Condition o) {
  buildCounterCondition++;
  if (buildCounterCondition < 3) {
    checkUnnamed5252(o.parameter!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCondition--;
}

core.List<core.String> buildUnnamed5253() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5253(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5254() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5254(core.List<core.String> o) {
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
    o.domainName = buildUnnamed5253();
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.path = 'foo';
    o.publicId = 'foo';
    o.tagManagerUrl = 'foo';
    o.usageContext = buildUnnamed5254();
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
    checkUnnamed5253(o.domainName!);
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
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publicId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed5254(o.usageContext!);
  }
  buildCounterContainer--;
}

core.int buildCounterContainerAccess = 0;
api.ContainerAccess buildContainerAccess() {
  var o = api.ContainerAccess();
  buildCounterContainerAccess++;
  if (buildCounterContainerAccess < 3) {
    o.containerId = 'foo';
    o.permission = 'foo';
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
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
  }
  buildCounterContainerAccess--;
}

core.List<api.BuiltInVariable> buildUnnamed5255() {
  var o = <api.BuiltInVariable>[];
  o.add(buildBuiltInVariable());
  o.add(buildBuiltInVariable());
  return o;
}

void checkUnnamed5255(core.List<api.BuiltInVariable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuiltInVariable(o[0] as api.BuiltInVariable);
  checkBuiltInVariable(o[1] as api.BuiltInVariable);
}

core.List<api.Client> buildUnnamed5256() {
  var o = <api.Client>[];
  o.add(buildClient());
  o.add(buildClient());
  return o;
}

void checkUnnamed5256(core.List<api.Client> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkClient(o[0] as api.Client);
  checkClient(o[1] as api.Client);
}

core.List<api.CustomTemplate> buildUnnamed5257() {
  var o = <api.CustomTemplate>[];
  o.add(buildCustomTemplate());
  o.add(buildCustomTemplate());
  return o;
}

void checkUnnamed5257(core.List<api.CustomTemplate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomTemplate(o[0] as api.CustomTemplate);
  checkCustomTemplate(o[1] as api.CustomTemplate);
}

core.List<api.Folder> buildUnnamed5258() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed5258(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.List<api.Tag> buildUnnamed5259() {
  var o = <api.Tag>[];
  o.add(buildTag());
  o.add(buildTag());
  return o;
}

void checkUnnamed5259(core.List<api.Tag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTag(o[0] as api.Tag);
  checkTag(o[1] as api.Tag);
}

core.List<api.Trigger> buildUnnamed5260() {
  var o = <api.Trigger>[];
  o.add(buildTrigger());
  o.add(buildTrigger());
  return o;
}

void checkUnnamed5260(core.List<api.Trigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrigger(o[0] as api.Trigger);
  checkTrigger(o[1] as api.Trigger);
}

core.List<api.Variable> buildUnnamed5261() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed5261(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.List<api.Zone> buildUnnamed5262() {
  var o = <api.Zone>[];
  o.add(buildZone());
  o.add(buildZone());
  return o;
}

void checkUnnamed5262(core.List<api.Zone> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkZone(o[0] as api.Zone);
  checkZone(o[1] as api.Zone);
}

core.int buildCounterContainerVersion = 0;
api.ContainerVersion buildContainerVersion() {
  var o = api.ContainerVersion();
  buildCounterContainerVersion++;
  if (buildCounterContainerVersion < 3) {
    o.accountId = 'foo';
    o.builtInVariable = buildUnnamed5255();
    o.client = buildUnnamed5256();
    o.container = buildContainer();
    o.containerId = 'foo';
    o.containerVersionId = 'foo';
    o.customTemplate = buildUnnamed5257();
    o.deleted = true;
    o.description = 'foo';
    o.fingerprint = 'foo';
    o.folder = buildUnnamed5258();
    o.name = 'foo';
    o.path = 'foo';
    o.tag = buildUnnamed5259();
    o.tagManagerUrl = 'foo';
    o.trigger = buildUnnamed5260();
    o.variable = buildUnnamed5261();
    o.zone = buildUnnamed5262();
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
    checkUnnamed5255(o.builtInVariable!);
    checkUnnamed5256(o.client!);
    checkContainer(o.container! as api.Container);
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerVersionId!,
      unittest.equals('foo'),
    );
    checkUnnamed5257(o.customTemplate!);
    unittest.expect(o.deleted!, unittest.isTrue);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    checkUnnamed5258(o.folder!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    checkUnnamed5259(o.tag!);
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed5260(o.trigger!);
    checkUnnamed5261(o.variable!);
    checkUnnamed5262(o.zone!);
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
    o.numClients = 'foo';
    o.numCustomTemplates = 'foo';
    o.numMacros = 'foo';
    o.numRules = 'foo';
    o.numTags = 'foo';
    o.numTriggers = 'foo';
    o.numVariables = 'foo';
    o.numZones = 'foo';
    o.path = 'foo';
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
      o.numClients!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numCustomTemplates!,
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
    unittest.expect(
      o.numZones!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
  }
  buildCounterContainerVersionHeader--;
}

core.List<api.BuiltInVariable> buildUnnamed5263() {
  var o = <api.BuiltInVariable>[];
  o.add(buildBuiltInVariable());
  o.add(buildBuiltInVariable());
  return o;
}

void checkUnnamed5263(core.List<api.BuiltInVariable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuiltInVariable(o[0] as api.BuiltInVariable);
  checkBuiltInVariable(o[1] as api.BuiltInVariable);
}

core.int buildCounterCreateBuiltInVariableResponse = 0;
api.CreateBuiltInVariableResponse buildCreateBuiltInVariableResponse() {
  var o = api.CreateBuiltInVariableResponse();
  buildCounterCreateBuiltInVariableResponse++;
  if (buildCounterCreateBuiltInVariableResponse < 3) {
    o.builtInVariable = buildUnnamed5263();
  }
  buildCounterCreateBuiltInVariableResponse--;
  return o;
}

void checkCreateBuiltInVariableResponse(api.CreateBuiltInVariableResponse o) {
  buildCounterCreateBuiltInVariableResponse++;
  if (buildCounterCreateBuiltInVariableResponse < 3) {
    checkUnnamed5263(o.builtInVariable!);
  }
  buildCounterCreateBuiltInVariableResponse--;
}

core.int buildCounterCreateContainerVersionRequestVersionOptions = 0;
api.CreateContainerVersionRequestVersionOptions
    buildCreateContainerVersionRequestVersionOptions() {
  var o = api.CreateContainerVersionRequestVersionOptions();
  buildCounterCreateContainerVersionRequestVersionOptions++;
  if (buildCounterCreateContainerVersionRequestVersionOptions < 3) {
    o.name = 'foo';
    o.notes = 'foo';
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
    o.newWorkspacePath = 'foo';
    o.syncStatus = buildSyncStatus();
  }
  buildCounterCreateContainerVersionResponse--;
  return o;
}

void checkCreateContainerVersionResponse(api.CreateContainerVersionResponse o) {
  buildCounterCreateContainerVersionResponse++;
  if (buildCounterCreateContainerVersionResponse < 3) {
    unittest.expect(o.compilerError!, unittest.isTrue);
    checkContainerVersion(o.containerVersion! as api.ContainerVersion);
    unittest.expect(
      o.newWorkspacePath!,
      unittest.equals('foo'),
    );
    checkSyncStatus(o.syncStatus! as api.SyncStatus);
  }
  buildCounterCreateContainerVersionResponse--;
}

core.int buildCounterCustomTemplate = 0;
api.CustomTemplate buildCustomTemplate() {
  var o = api.CustomTemplate();
  buildCounterCustomTemplate++;
  if (buildCounterCustomTemplate < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.fingerprint = 'foo';
    o.galleryReference = buildGalleryReference();
    o.name = 'foo';
    o.path = 'foo';
    o.tagManagerUrl = 'foo';
    o.templateData = 'foo';
    o.templateId = 'foo';
    o.workspaceId = 'foo';
  }
  buildCounterCustomTemplate--;
  return o;
}

void checkCustomTemplate(api.CustomTemplate o) {
  buildCounterCustomTemplate++;
  if (buildCounterCustomTemplate < 3) {
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
    checkGalleryReference(o.galleryReference! as api.GalleryReference);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.templateData!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.templateId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomTemplate--;
}

core.int buildCounterEntity = 0;
api.Entity buildEntity() {
  var o = api.Entity();
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    o.changeStatus = 'foo';
    o.client = buildClient();
    o.folder = buildFolder();
    o.tag = buildTag();
    o.trigger = buildTrigger();
    o.variable = buildVariable();
  }
  buildCounterEntity--;
  return o;
}

void checkEntity(api.Entity o) {
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    unittest.expect(
      o.changeStatus!,
      unittest.equals('foo'),
    );
    checkClient(o.client! as api.Client);
    checkFolder(o.folder! as api.Folder);
    checkTag(o.tag! as api.Tag);
    checkTrigger(o.trigger! as api.Trigger);
    checkVariable(o.variable! as api.Variable);
  }
  buildCounterEntity--;
}

core.int buildCounterEnvironment = 0;
api.Environment buildEnvironment() {
  var o = api.Environment();
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    o.accountId = 'foo';
    o.authorizationCode = 'foo';
    o.authorizationTimestamp = 'foo';
    o.containerId = 'foo';
    o.containerVersionId = 'foo';
    o.description = 'foo';
    o.enableDebug = true;
    o.environmentId = 'foo';
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.path = 'foo';
    o.tagManagerUrl = 'foo';
    o.type = 'foo';
    o.url = 'foo';
    o.workspaceId = 'foo';
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
      o.authorizationTimestamp!,
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
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagManagerUrl!,
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
    unittest.expect(
      o.workspaceId!,
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
    o.notes = 'foo';
    o.path = 'foo';
    o.tagManagerUrl = 'foo';
    o.workspaceId = 'foo';
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
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterFolder--;
}

core.List<api.Tag> buildUnnamed5264() {
  var o = <api.Tag>[];
  o.add(buildTag());
  o.add(buildTag());
  return o;
}

void checkUnnamed5264(core.List<api.Tag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTag(o[0] as api.Tag);
  checkTag(o[1] as api.Tag);
}

core.List<api.Trigger> buildUnnamed5265() {
  var o = <api.Trigger>[];
  o.add(buildTrigger());
  o.add(buildTrigger());
  return o;
}

void checkUnnamed5265(core.List<api.Trigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrigger(o[0] as api.Trigger);
  checkTrigger(o[1] as api.Trigger);
}

core.List<api.Variable> buildUnnamed5266() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed5266(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterFolderEntities = 0;
api.FolderEntities buildFolderEntities() {
  var o = api.FolderEntities();
  buildCounterFolderEntities++;
  if (buildCounterFolderEntities < 3) {
    o.nextPageToken = 'foo';
    o.tag = buildUnnamed5264();
    o.trigger = buildUnnamed5265();
    o.variable = buildUnnamed5266();
  }
  buildCounterFolderEntities--;
  return o;
}

void checkFolderEntities(api.FolderEntities o) {
  buildCounterFolderEntities++;
  if (buildCounterFolderEntities < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5264(o.tag!);
    checkUnnamed5265(o.trigger!);
    checkUnnamed5266(o.variable!);
  }
  buildCounterFolderEntities--;
}

core.int buildCounterGalleryReference = 0;
api.GalleryReference buildGalleryReference() {
  var o = api.GalleryReference();
  buildCounterGalleryReference++;
  if (buildCounterGalleryReference < 3) {
    o.host = 'foo';
    o.isModified = true;
    o.owner = 'foo';
    o.repository = 'foo';
    o.signature = 'foo';
    o.version = 'foo';
  }
  buildCounterGalleryReference--;
  return o;
}

void checkGalleryReference(api.GalleryReference o) {
  buildCounterGalleryReference++;
  if (buildCounterGalleryReference < 3) {
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isModified!, unittest.isTrue);
    unittest.expect(
      o.owner!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.repository!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGalleryReference--;
}

core.List<api.MergeConflict> buildUnnamed5267() {
  var o = <api.MergeConflict>[];
  o.add(buildMergeConflict());
  o.add(buildMergeConflict());
  return o;
}

void checkUnnamed5267(core.List<api.MergeConflict> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMergeConflict(o[0] as api.MergeConflict);
  checkMergeConflict(o[1] as api.MergeConflict);
}

core.List<api.Entity> buildUnnamed5268() {
  var o = <api.Entity>[];
  o.add(buildEntity());
  o.add(buildEntity());
  return o;
}

void checkUnnamed5268(core.List<api.Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntity(o[0] as api.Entity);
  checkEntity(o[1] as api.Entity);
}

core.int buildCounterGetWorkspaceStatusResponse = 0;
api.GetWorkspaceStatusResponse buildGetWorkspaceStatusResponse() {
  var o = api.GetWorkspaceStatusResponse();
  buildCounterGetWorkspaceStatusResponse++;
  if (buildCounterGetWorkspaceStatusResponse < 3) {
    o.mergeConflict = buildUnnamed5267();
    o.workspaceChange = buildUnnamed5268();
  }
  buildCounterGetWorkspaceStatusResponse--;
  return o;
}

void checkGetWorkspaceStatusResponse(api.GetWorkspaceStatusResponse o) {
  buildCounterGetWorkspaceStatusResponse++;
  if (buildCounterGetWorkspaceStatusResponse < 3) {
    checkUnnamed5267(o.mergeConflict!);
    checkUnnamed5268(o.workspaceChange!);
  }
  buildCounterGetWorkspaceStatusResponse--;
}

core.List<api.Account> buildUnnamed5269() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed5269(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterListAccountsResponse = 0;
api.ListAccountsResponse buildListAccountsResponse() {
  var o = api.ListAccountsResponse();
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    o.account = buildUnnamed5269();
    o.nextPageToken = 'foo';
  }
  buildCounterListAccountsResponse--;
  return o;
}

void checkListAccountsResponse(api.ListAccountsResponse o) {
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    checkUnnamed5269(o.account!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAccountsResponse--;
}

core.List<api.ContainerVersionHeader> buildUnnamed5270() {
  var o = <api.ContainerVersionHeader>[];
  o.add(buildContainerVersionHeader());
  o.add(buildContainerVersionHeader());
  return o;
}

void checkUnnamed5270(core.List<api.ContainerVersionHeader> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainerVersionHeader(o[0] as api.ContainerVersionHeader);
  checkContainerVersionHeader(o[1] as api.ContainerVersionHeader);
}

core.int buildCounterListContainerVersionsResponse = 0;
api.ListContainerVersionsResponse buildListContainerVersionsResponse() {
  var o = api.ListContainerVersionsResponse();
  buildCounterListContainerVersionsResponse++;
  if (buildCounterListContainerVersionsResponse < 3) {
    o.containerVersionHeader = buildUnnamed5270();
    o.nextPageToken = 'foo';
  }
  buildCounterListContainerVersionsResponse--;
  return o;
}

void checkListContainerVersionsResponse(api.ListContainerVersionsResponse o) {
  buildCounterListContainerVersionsResponse++;
  if (buildCounterListContainerVersionsResponse < 3) {
    checkUnnamed5270(o.containerVersionHeader!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListContainerVersionsResponse--;
}

core.List<api.Container> buildUnnamed5271() {
  var o = <api.Container>[];
  o.add(buildContainer());
  o.add(buildContainer());
  return o;
}

void checkUnnamed5271(core.List<api.Container> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainer(o[0] as api.Container);
  checkContainer(o[1] as api.Container);
}

core.int buildCounterListContainersResponse = 0;
api.ListContainersResponse buildListContainersResponse() {
  var o = api.ListContainersResponse();
  buildCounterListContainersResponse++;
  if (buildCounterListContainersResponse < 3) {
    o.container = buildUnnamed5271();
    o.nextPageToken = 'foo';
  }
  buildCounterListContainersResponse--;
  return o;
}

void checkListContainersResponse(api.ListContainersResponse o) {
  buildCounterListContainersResponse++;
  if (buildCounterListContainersResponse < 3) {
    checkUnnamed5271(o.container!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListContainersResponse--;
}

core.List<api.BuiltInVariable> buildUnnamed5272() {
  var o = <api.BuiltInVariable>[];
  o.add(buildBuiltInVariable());
  o.add(buildBuiltInVariable());
  return o;
}

void checkUnnamed5272(core.List<api.BuiltInVariable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuiltInVariable(o[0] as api.BuiltInVariable);
  checkBuiltInVariable(o[1] as api.BuiltInVariable);
}

core.int buildCounterListEnabledBuiltInVariablesResponse = 0;
api.ListEnabledBuiltInVariablesResponse
    buildListEnabledBuiltInVariablesResponse() {
  var o = api.ListEnabledBuiltInVariablesResponse();
  buildCounterListEnabledBuiltInVariablesResponse++;
  if (buildCounterListEnabledBuiltInVariablesResponse < 3) {
    o.builtInVariable = buildUnnamed5272();
    o.nextPageToken = 'foo';
  }
  buildCounterListEnabledBuiltInVariablesResponse--;
  return o;
}

void checkListEnabledBuiltInVariablesResponse(
    api.ListEnabledBuiltInVariablesResponse o) {
  buildCounterListEnabledBuiltInVariablesResponse++;
  if (buildCounterListEnabledBuiltInVariablesResponse < 3) {
    checkUnnamed5272(o.builtInVariable!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListEnabledBuiltInVariablesResponse--;
}

core.List<api.Environment> buildUnnamed5273() {
  var o = <api.Environment>[];
  o.add(buildEnvironment());
  o.add(buildEnvironment());
  return o;
}

void checkUnnamed5273(core.List<api.Environment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEnvironment(o[0] as api.Environment);
  checkEnvironment(o[1] as api.Environment);
}

core.int buildCounterListEnvironmentsResponse = 0;
api.ListEnvironmentsResponse buildListEnvironmentsResponse() {
  var o = api.ListEnvironmentsResponse();
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    o.environment = buildUnnamed5273();
    o.nextPageToken = 'foo';
  }
  buildCounterListEnvironmentsResponse--;
  return o;
}

void checkListEnvironmentsResponse(api.ListEnvironmentsResponse o) {
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    checkUnnamed5273(o.environment!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListEnvironmentsResponse--;
}

core.List<api.Folder> buildUnnamed5274() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed5274(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterListFoldersResponse = 0;
api.ListFoldersResponse buildListFoldersResponse() {
  var o = api.ListFoldersResponse();
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    o.folder = buildUnnamed5274();
    o.nextPageToken = 'foo';
  }
  buildCounterListFoldersResponse--;
  return o;
}

void checkListFoldersResponse(api.ListFoldersResponse o) {
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    checkUnnamed5274(o.folder!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListFoldersResponse--;
}

core.List<api.Tag> buildUnnamed5275() {
  var o = <api.Tag>[];
  o.add(buildTag());
  o.add(buildTag());
  return o;
}

void checkUnnamed5275(core.List<api.Tag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTag(o[0] as api.Tag);
  checkTag(o[1] as api.Tag);
}

core.int buildCounterListTagsResponse = 0;
api.ListTagsResponse buildListTagsResponse() {
  var o = api.ListTagsResponse();
  buildCounterListTagsResponse++;
  if (buildCounterListTagsResponse < 3) {
    o.nextPageToken = 'foo';
    o.tag = buildUnnamed5275();
  }
  buildCounterListTagsResponse--;
  return o;
}

void checkListTagsResponse(api.ListTagsResponse o) {
  buildCounterListTagsResponse++;
  if (buildCounterListTagsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5275(o.tag!);
  }
  buildCounterListTagsResponse--;
}

core.List<api.CustomTemplate> buildUnnamed5276() {
  var o = <api.CustomTemplate>[];
  o.add(buildCustomTemplate());
  o.add(buildCustomTemplate());
  return o;
}

void checkUnnamed5276(core.List<api.CustomTemplate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomTemplate(o[0] as api.CustomTemplate);
  checkCustomTemplate(o[1] as api.CustomTemplate);
}

core.int buildCounterListTemplatesResponse = 0;
api.ListTemplatesResponse buildListTemplatesResponse() {
  var o = api.ListTemplatesResponse();
  buildCounterListTemplatesResponse++;
  if (buildCounterListTemplatesResponse < 3) {
    o.nextPageToken = 'foo';
    o.template = buildUnnamed5276();
  }
  buildCounterListTemplatesResponse--;
  return o;
}

void checkListTemplatesResponse(api.ListTemplatesResponse o) {
  buildCounterListTemplatesResponse++;
  if (buildCounterListTemplatesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5276(o.template!);
  }
  buildCounterListTemplatesResponse--;
}

core.List<api.Trigger> buildUnnamed5277() {
  var o = <api.Trigger>[];
  o.add(buildTrigger());
  o.add(buildTrigger());
  return o;
}

void checkUnnamed5277(core.List<api.Trigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrigger(o[0] as api.Trigger);
  checkTrigger(o[1] as api.Trigger);
}

core.int buildCounterListTriggersResponse = 0;
api.ListTriggersResponse buildListTriggersResponse() {
  var o = api.ListTriggersResponse();
  buildCounterListTriggersResponse++;
  if (buildCounterListTriggersResponse < 3) {
    o.nextPageToken = 'foo';
    o.trigger = buildUnnamed5277();
  }
  buildCounterListTriggersResponse--;
  return o;
}

void checkListTriggersResponse(api.ListTriggersResponse o) {
  buildCounterListTriggersResponse++;
  if (buildCounterListTriggersResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5277(o.trigger!);
  }
  buildCounterListTriggersResponse--;
}

core.List<api.UserPermission> buildUnnamed5278() {
  var o = <api.UserPermission>[];
  o.add(buildUserPermission());
  o.add(buildUserPermission());
  return o;
}

void checkUnnamed5278(core.List<api.UserPermission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserPermission(o[0] as api.UserPermission);
  checkUserPermission(o[1] as api.UserPermission);
}

core.int buildCounterListUserPermissionsResponse = 0;
api.ListUserPermissionsResponse buildListUserPermissionsResponse() {
  var o = api.ListUserPermissionsResponse();
  buildCounterListUserPermissionsResponse++;
  if (buildCounterListUserPermissionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.userPermission = buildUnnamed5278();
  }
  buildCounterListUserPermissionsResponse--;
  return o;
}

void checkListUserPermissionsResponse(api.ListUserPermissionsResponse o) {
  buildCounterListUserPermissionsResponse++;
  if (buildCounterListUserPermissionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5278(o.userPermission!);
  }
  buildCounterListUserPermissionsResponse--;
}

core.List<api.Variable> buildUnnamed5279() {
  var o = <api.Variable>[];
  o.add(buildVariable());
  o.add(buildVariable());
  return o;
}

void checkUnnamed5279(core.List<api.Variable> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVariable(o[0] as api.Variable);
  checkVariable(o[1] as api.Variable);
}

core.int buildCounterListVariablesResponse = 0;
api.ListVariablesResponse buildListVariablesResponse() {
  var o = api.ListVariablesResponse();
  buildCounterListVariablesResponse++;
  if (buildCounterListVariablesResponse < 3) {
    o.nextPageToken = 'foo';
    o.variable = buildUnnamed5279();
  }
  buildCounterListVariablesResponse--;
  return o;
}

void checkListVariablesResponse(api.ListVariablesResponse o) {
  buildCounterListVariablesResponse++;
  if (buildCounterListVariablesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5279(o.variable!);
  }
  buildCounterListVariablesResponse--;
}

core.List<api.Workspace> buildUnnamed5280() {
  var o = <api.Workspace>[];
  o.add(buildWorkspace());
  o.add(buildWorkspace());
  return o;
}

void checkUnnamed5280(core.List<api.Workspace> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWorkspace(o[0] as api.Workspace);
  checkWorkspace(o[1] as api.Workspace);
}

core.int buildCounterListWorkspacesResponse = 0;
api.ListWorkspacesResponse buildListWorkspacesResponse() {
  var o = api.ListWorkspacesResponse();
  buildCounterListWorkspacesResponse++;
  if (buildCounterListWorkspacesResponse < 3) {
    o.nextPageToken = 'foo';
    o.workspace = buildUnnamed5280();
  }
  buildCounterListWorkspacesResponse--;
  return o;
}

void checkListWorkspacesResponse(api.ListWorkspacesResponse o) {
  buildCounterListWorkspacesResponse++;
  if (buildCounterListWorkspacesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5280(o.workspace!);
  }
  buildCounterListWorkspacesResponse--;
}

core.List<api.Zone> buildUnnamed5281() {
  var o = <api.Zone>[];
  o.add(buildZone());
  o.add(buildZone());
  return o;
}

void checkUnnamed5281(core.List<api.Zone> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkZone(o[0] as api.Zone);
  checkZone(o[1] as api.Zone);
}

core.int buildCounterListZonesResponse = 0;
api.ListZonesResponse buildListZonesResponse() {
  var o = api.ListZonesResponse();
  buildCounterListZonesResponse++;
  if (buildCounterListZonesResponse < 3) {
    o.nextPageToken = 'foo';
    o.zone = buildUnnamed5281();
  }
  buildCounterListZonesResponse--;
  return o;
}

void checkListZonesResponse(api.ListZonesResponse o) {
  buildCounterListZonesResponse++;
  if (buildCounterListZonesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5281(o.zone!);
  }
  buildCounterListZonesResponse--;
}

core.int buildCounterMergeConflict = 0;
api.MergeConflict buildMergeConflict() {
  var o = api.MergeConflict();
  buildCounterMergeConflict++;
  if (buildCounterMergeConflict < 3) {
    o.entityInBaseVersion = buildEntity();
    o.entityInWorkspace = buildEntity();
  }
  buildCounterMergeConflict--;
  return o;
}

void checkMergeConflict(api.MergeConflict o) {
  buildCounterMergeConflict++;
  if (buildCounterMergeConflict < 3) {
    checkEntity(o.entityInBaseVersion! as api.Entity);
    checkEntity(o.entityInWorkspace! as api.Entity);
  }
  buildCounterMergeConflict--;
}

core.List<api.Parameter> buildUnnamed5282() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed5282(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.List<api.Parameter> buildUnnamed5283() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed5283(core.List<api.Parameter> o) {
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
    o.list = buildUnnamed5282();
    o.map = buildUnnamed5283();
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
    checkUnnamed5282(o.list!);
    checkUnnamed5283(o.map!);
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

core.int buildCounterQuickPreviewResponse = 0;
api.QuickPreviewResponse buildQuickPreviewResponse() {
  var o = api.QuickPreviewResponse();
  buildCounterQuickPreviewResponse++;
  if (buildCounterQuickPreviewResponse < 3) {
    o.compilerError = true;
    o.containerVersion = buildContainerVersion();
    o.syncStatus = buildSyncStatus();
  }
  buildCounterQuickPreviewResponse--;
  return o;
}

void checkQuickPreviewResponse(api.QuickPreviewResponse o) {
  buildCounterQuickPreviewResponse++;
  if (buildCounterQuickPreviewResponse < 3) {
    unittest.expect(o.compilerError!, unittest.isTrue);
    checkContainerVersion(o.containerVersion! as api.ContainerVersion);
    checkSyncStatus(o.syncStatus! as api.SyncStatus);
  }
  buildCounterQuickPreviewResponse--;
}

core.int buildCounterRevertBuiltInVariableResponse = 0;
api.RevertBuiltInVariableResponse buildRevertBuiltInVariableResponse() {
  var o = api.RevertBuiltInVariableResponse();
  buildCounterRevertBuiltInVariableResponse++;
  if (buildCounterRevertBuiltInVariableResponse < 3) {
    o.enabled = true;
  }
  buildCounterRevertBuiltInVariableResponse--;
  return o;
}

void checkRevertBuiltInVariableResponse(api.RevertBuiltInVariableResponse o) {
  buildCounterRevertBuiltInVariableResponse++;
  if (buildCounterRevertBuiltInVariableResponse < 3) {
    unittest.expect(o.enabled!, unittest.isTrue);
  }
  buildCounterRevertBuiltInVariableResponse--;
}

core.int buildCounterRevertFolderResponse = 0;
api.RevertFolderResponse buildRevertFolderResponse() {
  var o = api.RevertFolderResponse();
  buildCounterRevertFolderResponse++;
  if (buildCounterRevertFolderResponse < 3) {
    o.folder = buildFolder();
  }
  buildCounterRevertFolderResponse--;
  return o;
}

void checkRevertFolderResponse(api.RevertFolderResponse o) {
  buildCounterRevertFolderResponse++;
  if (buildCounterRevertFolderResponse < 3) {
    checkFolder(o.folder! as api.Folder);
  }
  buildCounterRevertFolderResponse--;
}

core.int buildCounterRevertTagResponse = 0;
api.RevertTagResponse buildRevertTagResponse() {
  var o = api.RevertTagResponse();
  buildCounterRevertTagResponse++;
  if (buildCounterRevertTagResponse < 3) {
    o.tag = buildTag();
  }
  buildCounterRevertTagResponse--;
  return o;
}

void checkRevertTagResponse(api.RevertTagResponse o) {
  buildCounterRevertTagResponse++;
  if (buildCounterRevertTagResponse < 3) {
    checkTag(o.tag! as api.Tag);
  }
  buildCounterRevertTagResponse--;
}

core.int buildCounterRevertTemplateResponse = 0;
api.RevertTemplateResponse buildRevertTemplateResponse() {
  var o = api.RevertTemplateResponse();
  buildCounterRevertTemplateResponse++;
  if (buildCounterRevertTemplateResponse < 3) {
    o.template = buildCustomTemplate();
  }
  buildCounterRevertTemplateResponse--;
  return o;
}

void checkRevertTemplateResponse(api.RevertTemplateResponse o) {
  buildCounterRevertTemplateResponse++;
  if (buildCounterRevertTemplateResponse < 3) {
    checkCustomTemplate(o.template! as api.CustomTemplate);
  }
  buildCounterRevertTemplateResponse--;
}

core.int buildCounterRevertTriggerResponse = 0;
api.RevertTriggerResponse buildRevertTriggerResponse() {
  var o = api.RevertTriggerResponse();
  buildCounterRevertTriggerResponse++;
  if (buildCounterRevertTriggerResponse < 3) {
    o.trigger = buildTrigger();
  }
  buildCounterRevertTriggerResponse--;
  return o;
}

void checkRevertTriggerResponse(api.RevertTriggerResponse o) {
  buildCounterRevertTriggerResponse++;
  if (buildCounterRevertTriggerResponse < 3) {
    checkTrigger(o.trigger! as api.Trigger);
  }
  buildCounterRevertTriggerResponse--;
}

core.int buildCounterRevertVariableResponse = 0;
api.RevertVariableResponse buildRevertVariableResponse() {
  var o = api.RevertVariableResponse();
  buildCounterRevertVariableResponse++;
  if (buildCounterRevertVariableResponse < 3) {
    o.variable = buildVariable();
  }
  buildCounterRevertVariableResponse--;
  return o;
}

void checkRevertVariableResponse(api.RevertVariableResponse o) {
  buildCounterRevertVariableResponse++;
  if (buildCounterRevertVariableResponse < 3) {
    checkVariable(o.variable! as api.Variable);
  }
  buildCounterRevertVariableResponse--;
}

core.int buildCounterRevertZoneResponse = 0;
api.RevertZoneResponse buildRevertZoneResponse() {
  var o = api.RevertZoneResponse();
  buildCounterRevertZoneResponse++;
  if (buildCounterRevertZoneResponse < 3) {
    o.zone = buildZone();
  }
  buildCounterRevertZoneResponse--;
  return o;
}

void checkRevertZoneResponse(api.RevertZoneResponse o) {
  buildCounterRevertZoneResponse++;
  if (buildCounterRevertZoneResponse < 3) {
    checkZone(o.zone! as api.Zone);
  }
  buildCounterRevertZoneResponse--;
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

core.int buildCounterSyncStatus = 0;
api.SyncStatus buildSyncStatus() {
  var o = api.SyncStatus();
  buildCounterSyncStatus++;
  if (buildCounterSyncStatus < 3) {
    o.mergeConflict = true;
    o.syncError = true;
  }
  buildCounterSyncStatus--;
  return o;
}

void checkSyncStatus(api.SyncStatus o) {
  buildCounterSyncStatus++;
  if (buildCounterSyncStatus < 3) {
    unittest.expect(o.mergeConflict!, unittest.isTrue);
    unittest.expect(o.syncError!, unittest.isTrue);
  }
  buildCounterSyncStatus--;
}

core.List<api.MergeConflict> buildUnnamed5284() {
  var o = <api.MergeConflict>[];
  o.add(buildMergeConflict());
  o.add(buildMergeConflict());
  return o;
}

void checkUnnamed5284(core.List<api.MergeConflict> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMergeConflict(o[0] as api.MergeConflict);
  checkMergeConflict(o[1] as api.MergeConflict);
}

core.int buildCounterSyncWorkspaceResponse = 0;
api.SyncWorkspaceResponse buildSyncWorkspaceResponse() {
  var o = api.SyncWorkspaceResponse();
  buildCounterSyncWorkspaceResponse++;
  if (buildCounterSyncWorkspaceResponse < 3) {
    o.mergeConflict = buildUnnamed5284();
    o.syncStatus = buildSyncStatus();
  }
  buildCounterSyncWorkspaceResponse--;
  return o;
}

void checkSyncWorkspaceResponse(api.SyncWorkspaceResponse o) {
  buildCounterSyncWorkspaceResponse++;
  if (buildCounterSyncWorkspaceResponse < 3) {
    checkUnnamed5284(o.mergeConflict!);
    checkSyncStatus(o.syncStatus! as api.SyncStatus);
  }
  buildCounterSyncWorkspaceResponse--;
}

core.List<core.String> buildUnnamed5285() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5285(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5286() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5286(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5287() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5287(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5288() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5288(core.List<core.String> o) {
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

core.List<api.Parameter> buildUnnamed5289() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed5289(core.List<api.Parameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkParameter(o[0] as api.Parameter);
  checkParameter(o[1] as api.Parameter);
}

core.List<api.SetupTag> buildUnnamed5290() {
  var o = <api.SetupTag>[];
  o.add(buildSetupTag());
  o.add(buildSetupTag());
  return o;
}

void checkUnnamed5290(core.List<api.SetupTag> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSetupTag(o[0] as api.SetupTag);
  checkSetupTag(o[1] as api.SetupTag);
}

core.List<api.TeardownTag> buildUnnamed5291() {
  var o = <api.TeardownTag>[];
  o.add(buildTeardownTag());
  o.add(buildTeardownTag());
  return o;
}

void checkUnnamed5291(core.List<api.TeardownTag> o) {
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
    o.blockingRuleId = buildUnnamed5285();
    o.blockingTriggerId = buildUnnamed5286();
    o.containerId = 'foo';
    o.fingerprint = 'foo';
    o.firingRuleId = buildUnnamed5287();
    o.firingTriggerId = buildUnnamed5288();
    o.liveOnly = true;
    o.monitoringMetadata = buildParameter();
    o.monitoringMetadataTagNameKey = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.parameter = buildUnnamed5289();
    o.parentFolderId = 'foo';
    o.path = 'foo';
    o.paused = true;
    o.priority = buildParameter();
    o.scheduleEndMs = 'foo';
    o.scheduleStartMs = 'foo';
    o.setupTag = buildUnnamed5290();
    o.tagFiringOption = 'foo';
    o.tagId = 'foo';
    o.tagManagerUrl = 'foo';
    o.teardownTag = buildUnnamed5291();
    o.type = 'foo';
    o.workspaceId = 'foo';
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
    checkUnnamed5285(o.blockingRuleId!);
    checkUnnamed5286(o.blockingTriggerId!);
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    checkUnnamed5287(o.firingRuleId!);
    checkUnnamed5288(o.firingTriggerId!);
    unittest.expect(o.liveOnly!, unittest.isTrue);
    checkParameter(o.monitoringMetadata! as api.Parameter);
    unittest.expect(
      o.monitoringMetadataTagNameKey!,
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
    checkUnnamed5289(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
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
    checkUnnamed5290(o.setupTag!);
    unittest.expect(
      o.tagFiringOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed5291(o.teardownTag!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workspaceId!,
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

core.List<api.Condition> buildUnnamed5292() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed5292(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<api.Condition> buildUnnamed5293() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed5293(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<api.Condition> buildUnnamed5294() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed5294(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<api.Parameter> buildUnnamed5295() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed5295(core.List<api.Parameter> o) {
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
    o.autoEventFilter = buildUnnamed5292();
    o.checkValidation = buildParameter();
    o.containerId = 'foo';
    o.continuousTimeMinMilliseconds = buildParameter();
    o.customEventFilter = buildUnnamed5293();
    o.eventName = buildParameter();
    o.filter = buildUnnamed5294();
    o.fingerprint = 'foo';
    o.horizontalScrollPercentageList = buildParameter();
    o.interval = buildParameter();
    o.intervalSeconds = buildParameter();
    o.limit = buildParameter();
    o.maxTimerLengthSeconds = buildParameter();
    o.name = 'foo';
    o.notes = 'foo';
    o.parameter = buildUnnamed5295();
    o.parentFolderId = 'foo';
    o.path = 'foo';
    o.selector = buildParameter();
    o.tagManagerUrl = 'foo';
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
    o.workspaceId = 'foo';
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
    checkUnnamed5292(o.autoEventFilter!);
    checkParameter(o.checkValidation! as api.Parameter);
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    checkParameter(o.continuousTimeMinMilliseconds! as api.Parameter);
    checkUnnamed5293(o.customEventFilter!);
    checkParameter(o.eventName! as api.Parameter);
    checkUnnamed5294(o.filter!);
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
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkUnnamed5295(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    checkParameter(o.selector! as api.Parameter);
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
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
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterTrigger--;
}

core.List<api.ContainerAccess> buildUnnamed5296() {
  var o = <api.ContainerAccess>[];
  o.add(buildContainerAccess());
  o.add(buildContainerAccess());
  return o;
}

void checkUnnamed5296(core.List<api.ContainerAccess> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContainerAccess(o[0] as api.ContainerAccess);
  checkContainerAccess(o[1] as api.ContainerAccess);
}

core.int buildCounterUserPermission = 0;
api.UserPermission buildUserPermission() {
  var o = api.UserPermission();
  buildCounterUserPermission++;
  if (buildCounterUserPermission < 3) {
    o.accountAccess = buildAccountAccess();
    o.accountId = 'foo';
    o.containerAccess = buildUnnamed5296();
    o.emailAddress = 'foo';
    o.path = 'foo';
  }
  buildCounterUserPermission--;
  return o;
}

void checkUserPermission(api.UserPermission o) {
  buildCounterUserPermission++;
  if (buildCounterUserPermission < 3) {
    checkAccountAccess(o.accountAccess! as api.AccountAccess);
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkUnnamed5296(o.containerAccess!);
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserPermission--;
}

core.List<core.String> buildUnnamed5297() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5297(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5298() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5298(core.List<core.String> o) {
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

core.List<api.Parameter> buildUnnamed5299() {
  var o = <api.Parameter>[];
  o.add(buildParameter());
  o.add(buildParameter());
  return o;
}

void checkUnnamed5299(core.List<api.Parameter> o) {
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
    o.disablingTriggerId = buildUnnamed5297();
    o.enablingTriggerId = buildUnnamed5298();
    o.fingerprint = 'foo';
    o.formatValue = buildVariableFormatValue();
    o.name = 'foo';
    o.notes = 'foo';
    o.parameter = buildUnnamed5299();
    o.parentFolderId = 'foo';
    o.path = 'foo';
    o.scheduleEndMs = 'foo';
    o.scheduleStartMs = 'foo';
    o.tagManagerUrl = 'foo';
    o.type = 'foo';
    o.variableId = 'foo';
    o.workspaceId = 'foo';
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
    checkUnnamed5297(o.disablingTriggerId!);
    checkUnnamed5298(o.enablingTriggerId!);
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    checkVariableFormatValue(o.formatValue! as api.VariableFormatValue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkUnnamed5299(o.parameter!);
    unittest.expect(
      o.parentFolderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
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
      o.tagManagerUrl!,
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
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVariable--;
}

core.int buildCounterVariableFormatValue = 0;
api.VariableFormatValue buildVariableFormatValue() {
  var o = api.VariableFormatValue();
  buildCounterVariableFormatValue++;
  if (buildCounterVariableFormatValue < 3) {
    o.caseConversionType = 'foo';
    o.convertFalseToValue = buildParameter();
    o.convertNullToValue = buildParameter();
    o.convertTrueToValue = buildParameter();
    o.convertUndefinedToValue = buildParameter();
  }
  buildCounterVariableFormatValue--;
  return o;
}

void checkVariableFormatValue(api.VariableFormatValue o) {
  buildCounterVariableFormatValue++;
  if (buildCounterVariableFormatValue < 3) {
    unittest.expect(
      o.caseConversionType!,
      unittest.equals('foo'),
    );
    checkParameter(o.convertFalseToValue! as api.Parameter);
    checkParameter(o.convertNullToValue! as api.Parameter);
    checkParameter(o.convertTrueToValue! as api.Parameter);
    checkParameter(o.convertUndefinedToValue! as api.Parameter);
  }
  buildCounterVariableFormatValue--;
}

core.int buildCounterWorkspace = 0;
api.Workspace buildWorkspace() {
  var o = api.Workspace();
  buildCounterWorkspace++;
  if (buildCounterWorkspace < 3) {
    o.accountId = 'foo';
    o.containerId = 'foo';
    o.description = 'foo';
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.path = 'foo';
    o.tagManagerUrl = 'foo';
    o.workspaceId = 'foo';
  }
  buildCounterWorkspace--;
  return o;
}

void checkWorkspace(api.Workspace o) {
  buildCounterWorkspace++;
  if (buildCounterWorkspace < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.containerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
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
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterWorkspace--;
}

core.List<api.ZoneChildContainer> buildUnnamed5300() {
  var o = <api.ZoneChildContainer>[];
  o.add(buildZoneChildContainer());
  o.add(buildZoneChildContainer());
  return o;
}

void checkUnnamed5300(core.List<api.ZoneChildContainer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkZoneChildContainer(o[0] as api.ZoneChildContainer);
  checkZoneChildContainer(o[1] as api.ZoneChildContainer);
}

core.int buildCounterZone = 0;
api.Zone buildZone() {
  var o = api.Zone();
  buildCounterZone++;
  if (buildCounterZone < 3) {
    o.accountId = 'foo';
    o.boundary = buildZoneBoundary();
    o.childContainer = buildUnnamed5300();
    o.containerId = 'foo';
    o.fingerprint = 'foo';
    o.name = 'foo';
    o.notes = 'foo';
    o.path = 'foo';
    o.tagManagerUrl = 'foo';
    o.typeRestriction = buildZoneTypeRestriction();
    o.workspaceId = 'foo';
    o.zoneId = 'foo';
  }
  buildCounterZone--;
  return o;
}

void checkZone(api.Zone o) {
  buildCounterZone++;
  if (buildCounterZone < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkZoneBoundary(o.boundary! as api.ZoneBoundary);
    checkUnnamed5300(o.childContainer!);
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
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagManagerUrl!,
      unittest.equals('foo'),
    );
    checkZoneTypeRestriction(o.typeRestriction! as api.ZoneTypeRestriction);
    unittest.expect(
      o.workspaceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.zoneId!,
      unittest.equals('foo'),
    );
  }
  buildCounterZone--;
}

core.List<api.Condition> buildUnnamed5301() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed5301(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<core.String> buildUnnamed5302() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5302(core.List<core.String> o) {
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

core.int buildCounterZoneBoundary = 0;
api.ZoneBoundary buildZoneBoundary() {
  var o = api.ZoneBoundary();
  buildCounterZoneBoundary++;
  if (buildCounterZoneBoundary < 3) {
    o.condition = buildUnnamed5301();
    o.customEvaluationTriggerId = buildUnnamed5302();
  }
  buildCounterZoneBoundary--;
  return o;
}

void checkZoneBoundary(api.ZoneBoundary o) {
  buildCounterZoneBoundary++;
  if (buildCounterZoneBoundary < 3) {
    checkUnnamed5301(o.condition!);
    checkUnnamed5302(o.customEvaluationTriggerId!);
  }
  buildCounterZoneBoundary--;
}

core.int buildCounterZoneChildContainer = 0;
api.ZoneChildContainer buildZoneChildContainer() {
  var o = api.ZoneChildContainer();
  buildCounterZoneChildContainer++;
  if (buildCounterZoneChildContainer < 3) {
    o.nickname = 'foo';
    o.publicId = 'foo';
  }
  buildCounterZoneChildContainer--;
  return o;
}

void checkZoneChildContainer(api.ZoneChildContainer o) {
  buildCounterZoneChildContainer++;
  if (buildCounterZoneChildContainer < 3) {
    unittest.expect(
      o.nickname!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publicId!,
      unittest.equals('foo'),
    );
  }
  buildCounterZoneChildContainer--;
}

core.List<core.String> buildUnnamed5303() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5303(core.List<core.String> o) {
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

core.int buildCounterZoneTypeRestriction = 0;
api.ZoneTypeRestriction buildZoneTypeRestriction() {
  var o = api.ZoneTypeRestriction();
  buildCounterZoneTypeRestriction++;
  if (buildCounterZoneTypeRestriction < 3) {
    o.enable = true;
    o.whitelistedTypeId = buildUnnamed5303();
  }
  buildCounterZoneTypeRestriction--;
  return o;
}

void checkZoneTypeRestriction(api.ZoneTypeRestriction o) {
  buildCounterZoneTypeRestriction++;
  if (buildCounterZoneTypeRestriction < 3) {
    unittest.expect(o.enable!, unittest.isTrue);
    checkUnnamed5303(o.whitelistedTypeId!);
  }
  buildCounterZoneTypeRestriction--;
}

core.List<core.String> buildUnnamed5304() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5304(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5305() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5305(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5306() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5306(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5307() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5307(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5308() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5308(core.List<core.String> o) {
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

  unittest.group('obj-schema-BuiltInVariable', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuiltInVariable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuiltInVariable.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuiltInVariable(od as api.BuiltInVariable);
    });
  });

  unittest.group('obj-schema-Client', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClient();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Client.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkClient(od as api.Client);
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

  unittest.group('obj-schema-CreateBuiltInVariableResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateBuiltInVariableResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateBuiltInVariableResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateBuiltInVariableResponse(
          od as api.CreateBuiltInVariableResponse);
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

  unittest.group('obj-schema-CustomTemplate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomTemplate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomTemplate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomTemplate(od as api.CustomTemplate);
    });
  });

  unittest.group('obj-schema-Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Entity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEntity(od as api.Entity);
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

  unittest.group('obj-schema-GalleryReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGalleryReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GalleryReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGalleryReference(od as api.GalleryReference);
    });
  });

  unittest.group('obj-schema-GetWorkspaceStatusResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetWorkspaceStatusResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetWorkspaceStatusResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetWorkspaceStatusResponse(od as api.GetWorkspaceStatusResponse);
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

  unittest.group('obj-schema-ListEnabledBuiltInVariablesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListEnabledBuiltInVariablesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListEnabledBuiltInVariablesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListEnabledBuiltInVariablesResponse(
          od as api.ListEnabledBuiltInVariablesResponse);
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

  unittest.group('obj-schema-ListTemplatesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTemplatesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTemplatesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTemplatesResponse(od as api.ListTemplatesResponse);
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

  unittest.group('obj-schema-ListUserPermissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListUserPermissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListUserPermissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListUserPermissionsResponse(od as api.ListUserPermissionsResponse);
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

  unittest.group('obj-schema-ListWorkspacesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListWorkspacesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListWorkspacesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListWorkspacesResponse(od as api.ListWorkspacesResponse);
    });
  });

  unittest.group('obj-schema-ListZonesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListZonesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListZonesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListZonesResponse(od as api.ListZonesResponse);
    });
  });

  unittest.group('obj-schema-MergeConflict', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMergeConflict();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MergeConflict.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMergeConflict(od as api.MergeConflict);
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

  unittest.group('obj-schema-QuickPreviewResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuickPreviewResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QuickPreviewResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQuickPreviewResponse(od as api.QuickPreviewResponse);
    });
  });

  unittest.group('obj-schema-RevertBuiltInVariableResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevertBuiltInVariableResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevertBuiltInVariableResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevertBuiltInVariableResponse(
          od as api.RevertBuiltInVariableResponse);
    });
  });

  unittest.group('obj-schema-RevertFolderResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevertFolderResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevertFolderResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevertFolderResponse(od as api.RevertFolderResponse);
    });
  });

  unittest.group('obj-schema-RevertTagResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevertTagResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevertTagResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevertTagResponse(od as api.RevertTagResponse);
    });
  });

  unittest.group('obj-schema-RevertTemplateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevertTemplateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevertTemplateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevertTemplateResponse(od as api.RevertTemplateResponse);
    });
  });

  unittest.group('obj-schema-RevertTriggerResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevertTriggerResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevertTriggerResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevertTriggerResponse(od as api.RevertTriggerResponse);
    });
  });

  unittest.group('obj-schema-RevertVariableResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevertVariableResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevertVariableResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevertVariableResponse(od as api.RevertVariableResponse);
    });
  });

  unittest.group('obj-schema-RevertZoneResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevertZoneResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevertZoneResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevertZoneResponse(od as api.RevertZoneResponse);
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

  unittest.group('obj-schema-SyncStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSyncStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SyncStatus.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSyncStatus(od as api.SyncStatus);
    });
  });

  unittest.group('obj-schema-SyncWorkspaceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSyncWorkspaceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SyncWorkspaceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSyncWorkspaceResponse(od as api.SyncWorkspaceResponse);
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

  unittest.group('obj-schema-UserPermission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserPermission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserPermission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserPermission(od as api.UserPermission);
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

  unittest.group('obj-schema-VariableFormatValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVariableFormatValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VariableFormatValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVariableFormatValue(od as api.VariableFormatValue);
    });
  });

  unittest.group('obj-schema-Workspace', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWorkspace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Workspace.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkWorkspace(od as api.Workspace);
    });
  });

  unittest.group('obj-schema-Zone', () {
    unittest.test('to-json--from-json', () async {
      var o = buildZone();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Zone.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkZone(od as api.Zone);
    });
  });

  unittest.group('obj-schema-ZoneBoundary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildZoneBoundary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ZoneBoundary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkZoneBoundary(od as api.ZoneBoundary);
    });
  });

  unittest.group('obj-schema-ZoneChildContainer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildZoneChildContainer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ZoneChildContainer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkZoneChildContainer(od as api.ZoneChildContainer);
    });
  });

  unittest.group('obj-schema-ZoneTypeRestriction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildZoneTypeRestriction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ZoneTypeRestriction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkZoneTypeRestriction(od as api.ZoneTypeRestriction);
    });
  });

  unittest.group('resource-AccountsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts;
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("tagmanager/v2/accounts"),
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
        var resp = convert.json.encode(buildListAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(pageToken: arg_pageToken, $fields: arg_$fields);
      checkListAccountsResponse(response as api.ListAccountsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts;
      var arg_request = buildAccount();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });
  });

  unittest.group('resource-AccountsContainersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_request = buildContainer();
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildContainer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkContainer(response as api.Container);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildContainer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkContainer(response as api.Container);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListContainersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListContainersResponse(response as api.ListContainersResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers;
      var arg_request = buildContainer();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkContainer(response as api.Container);
    });
  });

  unittest.group('resource-AccountsContainersEnvironmentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_request = buildEnvironment();
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListEnvironmentsResponse(response as api.ListEnvironmentsResponse);
    });

    unittest.test('method--reauthorize', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_request = buildEnvironment();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response =
          await res.reauthorize(arg_request, arg_path, $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.environments;
      var arg_request = buildEnvironment();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });
  });

  unittest.group('resource-AccountsContainersVersionHeadersResource', () {
    unittest.test('method--latest', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versionHeaders;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildContainerVersionHeader());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.latest(arg_parent, $fields: arg_$fields);
      checkContainerVersionHeader(response as api.ContainerVersionHeader);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versionHeaders;
      var arg_parent = 'foo';
      var arg_includeDeleted = true;
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
          queryMap["includeDeleted"]!.first,
          unittest.equals("$arg_includeDeleted"),
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
        var resp = convert.json.encode(buildListContainerVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          includeDeleted: arg_includeDeleted,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListContainerVersionsResponse(
          response as api.ListContainerVersionsResponse);
    });
  });

  unittest.group('resource-AccountsContainersVersionsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
          queryMap["containerVersionId"]!.first,
          unittest.equals(arg_containerVersionId),
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
      final response = await res.get(arg_path,
          containerVersionId: arg_containerVersionId, $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });

    unittest.test('method--live', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildContainerVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.live(arg_parent, $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });

    unittest.test('method--publish', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.publish(arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkPublishContainerVersionResponse(
          response as api.PublishContainerVersionResponse);
    });

    unittest.test('method--setLatest', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildContainerVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setLatest(arg_path, $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildContainerVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.undelete(arg_path, $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.versions;
      var arg_request = buildContainerVersion();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkContainerVersion(response as api.ContainerVersion);
    });
  });

  unittest.group('resource-AccountsContainersWorkspacesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_request = buildWorkspace();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Workspace.fromJson(json as core.Map<core.String, core.dynamic>);
        checkWorkspace(obj as api.Workspace);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildWorkspace());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkWorkspace(response as api.Workspace);
    });

    unittest.test('method--createVersion', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_request = buildCreateContainerVersionRequestVersionOptions();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildCreateContainerVersionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.createVersion(arg_request, arg_path, $fields: arg_$fields);
      checkCreateContainerVersionResponse(
          response as api.CreateContainerVersionResponse);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildWorkspace());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkWorkspace(response as api.Workspace);
    });

    unittest.test('method--getStatus', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildGetWorkspaceStatusResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getStatus(arg_path, $fields: arg_$fields);
      checkGetWorkspaceStatusResponse(
          response as api.GetWorkspaceStatusResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListWorkspacesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListWorkspacesResponse(response as api.ListWorkspacesResponse);
    });

    unittest.test('method--quickPreview', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildQuickPreviewResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.quickPreview(arg_path, $fields: arg_$fields);
      checkQuickPreviewResponse(response as api.QuickPreviewResponse);
    });

    unittest.test('method--resolveConflict', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_request = buildEntity();
      var arg_path = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Entity.fromJson(json as core.Map<core.String, core.dynamic>);
        checkEntity(obj as api.Entity);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.resolveConflict(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
    });

    unittest.test('method--sync', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildSyncWorkspaceResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.sync(arg_path, $fields: arg_$fields);
      checkSyncWorkspaceResponse(response as api.SyncWorkspaceResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces;
      var arg_request = buildWorkspace();
      var arg_path = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Workspace.fromJson(json as core.Map<core.String, core.dynamic>);
        checkWorkspace(obj as api.Workspace);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildWorkspace());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkWorkspace(response as api.Workspace);
    });
  });

  unittest.group(
      'resource-AccountsContainersWorkspacesBuiltInVariablesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock)
          .accounts
          .containers
          .workspaces
          .builtInVariables;
      var arg_parent = 'foo';
      var arg_type = buildUnnamed5304();
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
          queryMap["type"]!,
          unittest.equals(arg_type),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCreateBuiltInVariableResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_parent, type: arg_type, $fields: arg_$fields);
      checkCreateBuiltInVariableResponse(
          response as api.CreateBuiltInVariableResponse);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock)
          .accounts
          .containers
          .workspaces
          .builtInVariables;
      var arg_path = 'foo';
      var arg_type = buildUnnamed5305();
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
          queryMap["type"]!,
          unittest.equals(arg_type),
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
      await res.delete(arg_path, type: arg_type, $fields: arg_$fields);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock)
          .accounts
          .containers
          .workspaces
          .builtInVariables;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
            convert.json.encode(buildListEnabledBuiltInVariablesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListEnabledBuiltInVariablesResponse(
          response as api.ListEnabledBuiltInVariablesResponse);
    });

    unittest.test('method--revert', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock)
          .accounts
          .containers
          .workspaces
          .builtInVariables;
      var arg_path = 'foo';
      var arg_type = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
          queryMap["type"]!.first,
          unittest.equals(arg_type),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRevertBuiltInVariableResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.revert(arg_path, type: arg_type, $fields: arg_$fields);
      checkRevertBuiltInVariableResponse(
          response as api.RevertBuiltInVariableResponse);
    });
  });

  unittest.group('resource-AccountsContainersWorkspacesFoldersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_request = buildFolder();
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildFolder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--entities', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildFolderEntities());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.entities(arg_path,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkFolderEntities(response as api.FolderEntities);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildFolder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListFoldersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListFoldersResponse(response as api.ListFoldersResponse);
    });

    unittest.test('method--moveEntitiesToFolder', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_request = buildFolder();
      var arg_path = 'foo';
      var arg_tagId = buildUnnamed5306();
      var arg_triggerId = buildUnnamed5307();
      var arg_variableId = buildUnnamed5308();
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      await res.moveEntitiesToFolder(arg_request, arg_path,
          tagId: arg_tagId,
          triggerId: arg_triggerId,
          variableId: arg_variableId,
          $fields: arg_$fields);
    });

    unittest.test('method--revert', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildRevertFolderResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.revert(arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkRevertFolderResponse(response as api.RevertFolderResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.folders;
      var arg_request = buildFolder();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });
  });

  unittest.group('resource-AccountsContainersWorkspacesTagsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.tags;
      var arg_request = buildTag();
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildTag());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkTag(response as api.Tag);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.tags;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.tags;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildTag());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkTag(response as api.Tag);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.tags;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListTagsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListTagsResponse(response as api.ListTagsResponse);
    });

    unittest.test('method--revert', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.tags;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildRevertTagResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.revert(arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkRevertTagResponse(response as api.RevertTagResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.tags;
      var arg_request = buildTag();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkTag(response as api.Tag);
    });
  });

  unittest.group('resource-AccountsContainersWorkspacesTemplatesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.templates;
      var arg_request = buildCustomTemplate();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomTemplate.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomTemplate(obj as api.CustomTemplate);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildCustomTemplate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkCustomTemplate(response as api.CustomTemplate);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.templates;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.templates;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildCustomTemplate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkCustomTemplate(response as api.CustomTemplate);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.templates;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListTemplatesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListTemplatesResponse(response as api.ListTemplatesResponse);
    });

    unittest.test('method--revert', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.templates;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildRevertTemplateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.revert(arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkRevertTemplateResponse(response as api.RevertTemplateResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.templates;
      var arg_request = buildCustomTemplate();
      var arg_path = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomTemplate.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomTemplate(obj as api.CustomTemplate);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildCustomTemplate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkCustomTemplate(response as api.CustomTemplate);
    });
  });

  unittest.group('resource-AccountsContainersWorkspacesTriggersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.triggers;
      var arg_request = buildTrigger();
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkTrigger(response as api.Trigger);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.triggers;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.triggers;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkTrigger(response as api.Trigger);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.triggers;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListTriggersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListTriggersResponse(response as api.ListTriggersResponse);
    });

    unittest.test('method--revert', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.triggers;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildRevertTriggerResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.revert(arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkRevertTriggerResponse(response as api.RevertTriggerResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.triggers;
      var arg_request = buildTrigger();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkTrigger(response as api.Trigger);
    });
  });

  unittest.group('resource-AccountsContainersWorkspacesVariablesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.variables;
      var arg_request = buildVariable();
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildVariable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkVariable(response as api.Variable);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.variables;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.variables;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildVariable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkVariable(response as api.Variable);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.variables;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListVariablesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListVariablesResponse(response as api.ListVariablesResponse);
    });

    unittest.test('method--revert', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.variables;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildRevertVariableResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.revert(arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkRevertVariableResponse(response as api.RevertVariableResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res =
          api.TagManagerApi(mock).accounts.containers.workspaces.variables;
      var arg_request = buildVariable();
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkVariable(response as api.Variable);
    });
  });

  unittest.group('resource-AccountsContainersWorkspacesZonesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.zones;
      var arg_request = buildZone();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Zone.fromJson(json as core.Map<core.String, core.dynamic>);
        checkZone(obj as api.Zone);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildZone());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkZone(response as api.Zone);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.zones;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.zones;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildZone());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkZone(response as api.Zone);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.zones;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListZonesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListZonesResponse(response as api.ListZonesResponse);
    });

    unittest.test('method--revert', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.zones;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildRevertZoneResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.revert(arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkRevertZoneResponse(response as api.RevertZoneResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.containers.workspaces.zones;
      var arg_request = buildZone();
      var arg_path = 'foo';
      var arg_fingerprint = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Zone.fromJson(json as core.Map<core.String, core.dynamic>);
        checkZone(obj as api.Zone);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildZone());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_path,
          fingerprint: arg_fingerprint, $fields: arg_$fields);
      checkZone(response as api.Zone);
    });
  });

  unittest.group('resource-AccountsUserPermissionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.userPermissions;
      var arg_request = buildUserPermission();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserPermission.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserPermission(obj as api.UserPermission);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildUserPermission());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkUserPermission(response as api.UserPermission);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.userPermissions;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_path, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.userPermissions;
      var arg_path = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildUserPermission());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_path, $fields: arg_$fields);
      checkUserPermission(response as api.UserPermission);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.userPermissions;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildListUserPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageToken: arg_pageToken, $fields: arg_$fields);
      checkListUserPermissionsResponse(
          response as api.ListUserPermissionsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TagManagerApi(mock).accounts.userPermissions;
      var arg_request = buildUserPermission();
      var arg_path = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserPermission.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserPermission(obj as api.UserPermission);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("tagmanager/v2/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildUserPermission());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_path, $fields: arg_$fields);
      checkUserPermission(response as api.UserPermission);
    });
  });
}

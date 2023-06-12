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

import 'package:googleapis/cloudresourcemanager/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.AuditLogConfig> buildUnnamed2385() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed2385(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed2385();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed2385(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed2386() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2386(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed2386();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed2386(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed2387() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2387(core.List<core.String> o) {
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
    o.members = buildUnnamed2387();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed2387(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int
    buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation =
    0;
api.CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation
    buildCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation() {
  var o = api
      .CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation();
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation++;
  if (buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation <
      3) {
    o.destinationParent = 'foo';
    o.displayName = 'foo';
    o.operationType = 'foo';
    o.sourceParent = 'foo';
  }
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation--;
  return o;
}

void checkCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation(
    api.CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation
        o) {
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation++;
  if (buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation <
      3) {
    unittest.expect(
      o.destinationParent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceParent!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation--;
}

core.int
    buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation =
    0;
api.CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation
    buildCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation() {
  var o = api
      .CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation();
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation++;
  if (buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation <
      3) {
    o.destinationParent = 'foo';
    o.displayName = 'foo';
    o.operationType = 'foo';
    o.sourceParent = 'foo';
  }
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation--;
  return o;
}

void checkCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation(
    api.CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation
        o) {
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation++;
  if (buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation <
      3) {
    unittest.expect(
      o.destinationParent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceParent!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation--;
}

core.int buildCounterCreateFolderMetadata = 0;
api.CreateFolderMetadata buildCreateFolderMetadata() {
  var o = api.CreateFolderMetadata();
  buildCounterCreateFolderMetadata++;
  if (buildCounterCreateFolderMetadata < 3) {
    o.displayName = 'foo';
    o.parent = 'foo';
  }
  buildCounterCreateFolderMetadata--;
  return o;
}

void checkCreateFolderMetadata(api.CreateFolderMetadata o) {
  buildCounterCreateFolderMetadata++;
  if (buildCounterCreateFolderMetadata < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateFolderMetadata--;
}

core.int buildCounterCreateProjectMetadata = 0;
api.CreateProjectMetadata buildCreateProjectMetadata() {
  var o = api.CreateProjectMetadata();
  buildCounterCreateProjectMetadata++;
  if (buildCounterCreateProjectMetadata < 3) {
    o.createTime = 'foo';
    o.gettable = true;
    o.ready = true;
  }
  buildCounterCreateProjectMetadata--;
  return o;
}

void checkCreateProjectMetadata(api.CreateProjectMetadata o) {
  buildCounterCreateProjectMetadata++;
  if (buildCounterCreateProjectMetadata < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(o.gettable!, unittest.isTrue);
    unittest.expect(o.ready!, unittest.isTrue);
  }
  buildCounterCreateProjectMetadata--;
}

core.int buildCounterCreateTagBindingMetadata = 0;
api.CreateTagBindingMetadata buildCreateTagBindingMetadata() {
  var o = api.CreateTagBindingMetadata();
  buildCounterCreateTagBindingMetadata++;
  if (buildCounterCreateTagBindingMetadata < 3) {}
  buildCounterCreateTagBindingMetadata--;
  return o;
}

void checkCreateTagBindingMetadata(api.CreateTagBindingMetadata o) {
  buildCounterCreateTagBindingMetadata++;
  if (buildCounterCreateTagBindingMetadata < 3) {}
  buildCounterCreateTagBindingMetadata--;
}

core.int buildCounterCreateTagKeyMetadata = 0;
api.CreateTagKeyMetadata buildCreateTagKeyMetadata() {
  var o = api.CreateTagKeyMetadata();
  buildCounterCreateTagKeyMetadata++;
  if (buildCounterCreateTagKeyMetadata < 3) {}
  buildCounterCreateTagKeyMetadata--;
  return o;
}

void checkCreateTagKeyMetadata(api.CreateTagKeyMetadata o) {
  buildCounterCreateTagKeyMetadata++;
  if (buildCounterCreateTagKeyMetadata < 3) {}
  buildCounterCreateTagKeyMetadata--;
}

core.int buildCounterCreateTagValueMetadata = 0;
api.CreateTagValueMetadata buildCreateTagValueMetadata() {
  var o = api.CreateTagValueMetadata();
  buildCounterCreateTagValueMetadata++;
  if (buildCounterCreateTagValueMetadata < 3) {}
  buildCounterCreateTagValueMetadata--;
  return o;
}

void checkCreateTagValueMetadata(api.CreateTagValueMetadata o) {
  buildCounterCreateTagValueMetadata++;
  if (buildCounterCreateTagValueMetadata < 3) {}
  buildCounterCreateTagValueMetadata--;
}

core.int buildCounterDeleteFolderMetadata = 0;
api.DeleteFolderMetadata buildDeleteFolderMetadata() {
  var o = api.DeleteFolderMetadata();
  buildCounterDeleteFolderMetadata++;
  if (buildCounterDeleteFolderMetadata < 3) {}
  buildCounterDeleteFolderMetadata--;
  return o;
}

void checkDeleteFolderMetadata(api.DeleteFolderMetadata o) {
  buildCounterDeleteFolderMetadata++;
  if (buildCounterDeleteFolderMetadata < 3) {}
  buildCounterDeleteFolderMetadata--;
}

core.int buildCounterDeleteOrganizationMetadata = 0;
api.DeleteOrganizationMetadata buildDeleteOrganizationMetadata() {
  var o = api.DeleteOrganizationMetadata();
  buildCounterDeleteOrganizationMetadata++;
  if (buildCounterDeleteOrganizationMetadata < 3) {}
  buildCounterDeleteOrganizationMetadata--;
  return o;
}

void checkDeleteOrganizationMetadata(api.DeleteOrganizationMetadata o) {
  buildCounterDeleteOrganizationMetadata++;
  if (buildCounterDeleteOrganizationMetadata < 3) {}
  buildCounterDeleteOrganizationMetadata--;
}

core.int buildCounterDeleteProjectMetadata = 0;
api.DeleteProjectMetadata buildDeleteProjectMetadata() {
  var o = api.DeleteProjectMetadata();
  buildCounterDeleteProjectMetadata++;
  if (buildCounterDeleteProjectMetadata < 3) {}
  buildCounterDeleteProjectMetadata--;
  return o;
}

void checkDeleteProjectMetadata(api.DeleteProjectMetadata o) {
  buildCounterDeleteProjectMetadata++;
  if (buildCounterDeleteProjectMetadata < 3) {}
  buildCounterDeleteProjectMetadata--;
}

core.int buildCounterDeleteTagBindingMetadata = 0;
api.DeleteTagBindingMetadata buildDeleteTagBindingMetadata() {
  var o = api.DeleteTagBindingMetadata();
  buildCounterDeleteTagBindingMetadata++;
  if (buildCounterDeleteTagBindingMetadata < 3) {}
  buildCounterDeleteTagBindingMetadata--;
  return o;
}

void checkDeleteTagBindingMetadata(api.DeleteTagBindingMetadata o) {
  buildCounterDeleteTagBindingMetadata++;
  if (buildCounterDeleteTagBindingMetadata < 3) {}
  buildCounterDeleteTagBindingMetadata--;
}

core.int buildCounterDeleteTagKeyMetadata = 0;
api.DeleteTagKeyMetadata buildDeleteTagKeyMetadata() {
  var o = api.DeleteTagKeyMetadata();
  buildCounterDeleteTagKeyMetadata++;
  if (buildCounterDeleteTagKeyMetadata < 3) {}
  buildCounterDeleteTagKeyMetadata--;
  return o;
}

void checkDeleteTagKeyMetadata(api.DeleteTagKeyMetadata o) {
  buildCounterDeleteTagKeyMetadata++;
  if (buildCounterDeleteTagKeyMetadata < 3) {}
  buildCounterDeleteTagKeyMetadata--;
}

core.int buildCounterDeleteTagValueMetadata = 0;
api.DeleteTagValueMetadata buildDeleteTagValueMetadata() {
  var o = api.DeleteTagValueMetadata();
  buildCounterDeleteTagValueMetadata++;
  if (buildCounterDeleteTagValueMetadata < 3) {}
  buildCounterDeleteTagValueMetadata--;
  return o;
}

void checkDeleteTagValueMetadata(api.DeleteTagValueMetadata o) {
  buildCounterDeleteTagValueMetadata++;
  if (buildCounterDeleteTagValueMetadata < 3) {}
  buildCounterDeleteTagValueMetadata--;
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

core.int buildCounterFolder = 0;
api.Folder buildFolder() {
  var o = api.Folder();
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    o.createTime = 'foo';
    o.deleteTime = 'foo';
    o.displayName = 'foo';
    o.etag = 'foo';
    o.name = 'foo';
    o.parent = 'foo';
    o.state = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterFolder--;
  return o;
}

void checkFolder(api.Folder o) {
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deleteTime!,
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
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
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
  buildCounterFolder--;
}

core.int buildCounterFolderOperation = 0;
api.FolderOperation buildFolderOperation() {
  var o = api.FolderOperation();
  buildCounterFolderOperation++;
  if (buildCounterFolderOperation < 3) {
    o.destinationParent = 'foo';
    o.displayName = 'foo';
    o.operationType = 'foo';
    o.sourceParent = 'foo';
  }
  buildCounterFolderOperation--;
  return o;
}

void checkFolderOperation(api.FolderOperation o) {
  buildCounterFolderOperation++;
  if (buildCounterFolderOperation < 3) {
    unittest.expect(
      o.destinationParent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceParent!,
      unittest.equals('foo'),
    );
  }
  buildCounterFolderOperation--;
}

core.int buildCounterFolderOperationError = 0;
api.FolderOperationError buildFolderOperationError() {
  var o = api.FolderOperationError();
  buildCounterFolderOperationError++;
  if (buildCounterFolderOperationError < 3) {
    o.errorMessageId = 'foo';
  }
  buildCounterFolderOperationError--;
  return o;
}

void checkFolderOperationError(api.FolderOperationError o) {
  buildCounterFolderOperationError++;
  if (buildCounterFolderOperationError < 3) {
    unittest.expect(
      o.errorMessageId!,
      unittest.equals('foo'),
    );
  }
  buildCounterFolderOperationError--;
}

core.int buildCounterGetIamPolicyRequest = 0;
api.GetIamPolicyRequest buildGetIamPolicyRequest() {
  var o = api.GetIamPolicyRequest();
  buildCounterGetIamPolicyRequest++;
  if (buildCounterGetIamPolicyRequest < 3) {
    o.options = buildGetPolicyOptions();
  }
  buildCounterGetIamPolicyRequest--;
  return o;
}

void checkGetIamPolicyRequest(api.GetIamPolicyRequest o) {
  buildCounterGetIamPolicyRequest++;
  if (buildCounterGetIamPolicyRequest < 3) {
    checkGetPolicyOptions(o.options! as api.GetPolicyOptions);
  }
  buildCounterGetIamPolicyRequest--;
}

core.int buildCounterGetPolicyOptions = 0;
api.GetPolicyOptions buildGetPolicyOptions() {
  var o = api.GetPolicyOptions();
  buildCounterGetPolicyOptions++;
  if (buildCounterGetPolicyOptions < 3) {
    o.requestedPolicyVersion = 42;
  }
  buildCounterGetPolicyOptions--;
  return o;
}

void checkGetPolicyOptions(api.GetPolicyOptions o) {
  buildCounterGetPolicyOptions++;
  if (buildCounterGetPolicyOptions < 3) {
    unittest.expect(
      o.requestedPolicyVersion!,
      unittest.equals(42),
    );
  }
  buildCounterGetPolicyOptions--;
}

core.List<core.String> buildUnnamed2388() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2388(core.List<core.String> o) {
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

core.int buildCounterLien = 0;
api.Lien buildLien() {
  var o = api.Lien();
  buildCounterLien++;
  if (buildCounterLien < 3) {
    o.createTime = 'foo';
    o.name = 'foo';
    o.origin = 'foo';
    o.parent = 'foo';
    o.reason = 'foo';
    o.restrictions = buildUnnamed2388();
  }
  buildCounterLien--;
  return o;
}

void checkLien(api.Lien o) {
  buildCounterLien++;
  if (buildCounterLien < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.origin!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
    checkUnnamed2388(o.restrictions!);
  }
  buildCounterLien--;
}

core.List<api.Folder> buildUnnamed2389() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed2389(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterListFoldersResponse = 0;
api.ListFoldersResponse buildListFoldersResponse() {
  var o = api.ListFoldersResponse();
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    o.folders = buildUnnamed2389();
    o.nextPageToken = 'foo';
  }
  buildCounterListFoldersResponse--;
  return o;
}

void checkListFoldersResponse(api.ListFoldersResponse o) {
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    checkUnnamed2389(o.folders!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListFoldersResponse--;
}

core.List<api.Lien> buildUnnamed2390() {
  var o = <api.Lien>[];
  o.add(buildLien());
  o.add(buildLien());
  return o;
}

void checkUnnamed2390(core.List<api.Lien> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLien(o[0] as api.Lien);
  checkLien(o[1] as api.Lien);
}

core.int buildCounterListLiensResponse = 0;
api.ListLiensResponse buildListLiensResponse() {
  var o = api.ListLiensResponse();
  buildCounterListLiensResponse++;
  if (buildCounterListLiensResponse < 3) {
    o.liens = buildUnnamed2390();
    o.nextPageToken = 'foo';
  }
  buildCounterListLiensResponse--;
  return o;
}

void checkListLiensResponse(api.ListLiensResponse o) {
  buildCounterListLiensResponse++;
  if (buildCounterListLiensResponse < 3) {
    checkUnnamed2390(o.liens!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLiensResponse--;
}

core.List<api.Project> buildUnnamed2391() {
  var o = <api.Project>[];
  o.add(buildProject());
  o.add(buildProject());
  return o;
}

void checkUnnamed2391(core.List<api.Project> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProject(o[0] as api.Project);
  checkProject(o[1] as api.Project);
}

core.int buildCounterListProjectsResponse = 0;
api.ListProjectsResponse buildListProjectsResponse() {
  var o = api.ListProjectsResponse();
  buildCounterListProjectsResponse++;
  if (buildCounterListProjectsResponse < 3) {
    o.nextPageToken = 'foo';
    o.projects = buildUnnamed2391();
  }
  buildCounterListProjectsResponse--;
  return o;
}

void checkListProjectsResponse(api.ListProjectsResponse o) {
  buildCounterListProjectsResponse++;
  if (buildCounterListProjectsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2391(o.projects!);
  }
  buildCounterListProjectsResponse--;
}

core.List<api.TagBinding> buildUnnamed2392() {
  var o = <api.TagBinding>[];
  o.add(buildTagBinding());
  o.add(buildTagBinding());
  return o;
}

void checkUnnamed2392(core.List<api.TagBinding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTagBinding(o[0] as api.TagBinding);
  checkTagBinding(o[1] as api.TagBinding);
}

core.int buildCounterListTagBindingsResponse = 0;
api.ListTagBindingsResponse buildListTagBindingsResponse() {
  var o = api.ListTagBindingsResponse();
  buildCounterListTagBindingsResponse++;
  if (buildCounterListTagBindingsResponse < 3) {
    o.nextPageToken = 'foo';
    o.tagBindings = buildUnnamed2392();
  }
  buildCounterListTagBindingsResponse--;
  return o;
}

void checkListTagBindingsResponse(api.ListTagBindingsResponse o) {
  buildCounterListTagBindingsResponse++;
  if (buildCounterListTagBindingsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2392(o.tagBindings!);
  }
  buildCounterListTagBindingsResponse--;
}

core.List<api.TagKey> buildUnnamed2393() {
  var o = <api.TagKey>[];
  o.add(buildTagKey());
  o.add(buildTagKey());
  return o;
}

void checkUnnamed2393(core.List<api.TagKey> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTagKey(o[0] as api.TagKey);
  checkTagKey(o[1] as api.TagKey);
}

core.int buildCounterListTagKeysResponse = 0;
api.ListTagKeysResponse buildListTagKeysResponse() {
  var o = api.ListTagKeysResponse();
  buildCounterListTagKeysResponse++;
  if (buildCounterListTagKeysResponse < 3) {
    o.nextPageToken = 'foo';
    o.tagKeys = buildUnnamed2393();
  }
  buildCounterListTagKeysResponse--;
  return o;
}

void checkListTagKeysResponse(api.ListTagKeysResponse o) {
  buildCounterListTagKeysResponse++;
  if (buildCounterListTagKeysResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2393(o.tagKeys!);
  }
  buildCounterListTagKeysResponse--;
}

core.List<api.TagValue> buildUnnamed2394() {
  var o = <api.TagValue>[];
  o.add(buildTagValue());
  o.add(buildTagValue());
  return o;
}

void checkUnnamed2394(core.List<api.TagValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTagValue(o[0] as api.TagValue);
  checkTagValue(o[1] as api.TagValue);
}

core.int buildCounterListTagValuesResponse = 0;
api.ListTagValuesResponse buildListTagValuesResponse() {
  var o = api.ListTagValuesResponse();
  buildCounterListTagValuesResponse++;
  if (buildCounterListTagValuesResponse < 3) {
    o.nextPageToken = 'foo';
    o.tagValues = buildUnnamed2394();
  }
  buildCounterListTagValuesResponse--;
  return o;
}

void checkListTagValuesResponse(api.ListTagValuesResponse o) {
  buildCounterListTagValuesResponse++;
  if (buildCounterListTagValuesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2394(o.tagValues!);
  }
  buildCounterListTagValuesResponse--;
}

core.int buildCounterMoveFolderMetadata = 0;
api.MoveFolderMetadata buildMoveFolderMetadata() {
  var o = api.MoveFolderMetadata();
  buildCounterMoveFolderMetadata++;
  if (buildCounterMoveFolderMetadata < 3) {
    o.destinationParent = 'foo';
    o.displayName = 'foo';
    o.sourceParent = 'foo';
  }
  buildCounterMoveFolderMetadata--;
  return o;
}

void checkMoveFolderMetadata(api.MoveFolderMetadata o) {
  buildCounterMoveFolderMetadata++;
  if (buildCounterMoveFolderMetadata < 3) {
    unittest.expect(
      o.destinationParent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceParent!,
      unittest.equals('foo'),
    );
  }
  buildCounterMoveFolderMetadata--;
}

core.int buildCounterMoveFolderRequest = 0;
api.MoveFolderRequest buildMoveFolderRequest() {
  var o = api.MoveFolderRequest();
  buildCounterMoveFolderRequest++;
  if (buildCounterMoveFolderRequest < 3) {
    o.destinationParent = 'foo';
  }
  buildCounterMoveFolderRequest--;
  return o;
}

void checkMoveFolderRequest(api.MoveFolderRequest o) {
  buildCounterMoveFolderRequest++;
  if (buildCounterMoveFolderRequest < 3) {
    unittest.expect(
      o.destinationParent!,
      unittest.equals('foo'),
    );
  }
  buildCounterMoveFolderRequest--;
}

core.int buildCounterMoveProjectMetadata = 0;
api.MoveProjectMetadata buildMoveProjectMetadata() {
  var o = api.MoveProjectMetadata();
  buildCounterMoveProjectMetadata++;
  if (buildCounterMoveProjectMetadata < 3) {}
  buildCounterMoveProjectMetadata--;
  return o;
}

void checkMoveProjectMetadata(api.MoveProjectMetadata o) {
  buildCounterMoveProjectMetadata++;
  if (buildCounterMoveProjectMetadata < 3) {}
  buildCounterMoveProjectMetadata--;
}

core.int buildCounterMoveProjectRequest = 0;
api.MoveProjectRequest buildMoveProjectRequest() {
  var o = api.MoveProjectRequest();
  buildCounterMoveProjectRequest++;
  if (buildCounterMoveProjectRequest < 3) {
    o.destinationParent = 'foo';
  }
  buildCounterMoveProjectRequest--;
  return o;
}

void checkMoveProjectRequest(api.MoveProjectRequest o) {
  buildCounterMoveProjectRequest++;
  if (buildCounterMoveProjectRequest < 3) {
    unittest.expect(
      o.destinationParent!,
      unittest.equals('foo'),
    );
  }
  buildCounterMoveProjectRequest--;
}

core.Map<core.String, core.Object> buildUnnamed2395() {
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

void checkUnnamed2395(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2396() {
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

void checkUnnamed2396(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed2395();
    o.name = 'foo';
    o.response = buildUnnamed2396();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed2395(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2396(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOrganization = 0;
api.Organization buildOrganization() {
  var o = api.Organization();
  buildCounterOrganization++;
  if (buildCounterOrganization < 3) {
    o.createTime = 'foo';
    o.deleteTime = 'foo';
    o.directoryCustomerId = 'foo';
    o.displayName = 'foo';
    o.etag = 'foo';
    o.name = 'foo';
    o.state = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterOrganization--;
  return o;
}

void checkOrganization(api.Organization o) {
  buildCounterOrganization++;
  if (buildCounterOrganization < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deleteTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.directoryCustomerId!,
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
    unittest.expect(
      o.name!,
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
  buildCounterOrganization--;
}

core.List<api.AuditConfig> buildUnnamed2397() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed2397(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed2398() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed2398(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed2397();
    o.bindings = buildUnnamed2398();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed2397(o.auditConfigs!);
    checkUnnamed2398(o.bindings!);
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

core.Map<core.String, core.String> buildUnnamed2399() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2399(core.Map<core.String, core.String> o) {
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

core.int buildCounterProject = 0;
api.Project buildProject() {
  var o = api.Project();
  buildCounterProject++;
  if (buildCounterProject < 3) {
    o.createTime = 'foo';
    o.deleteTime = 'foo';
    o.displayName = 'foo';
    o.etag = 'foo';
    o.labels = buildUnnamed2399();
    o.name = 'foo';
    o.parent = 'foo';
    o.projectId = 'foo';
    o.state = 'foo';
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
    unittest.expect(
      o.deleteTime!,
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
    checkUnnamed2399(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
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
  buildCounterProject--;
}

core.int buildCounterProjectCreationStatus = 0;
api.ProjectCreationStatus buildProjectCreationStatus() {
  var o = api.ProjectCreationStatus();
  buildCounterProjectCreationStatus++;
  if (buildCounterProjectCreationStatus < 3) {
    o.createTime = 'foo';
    o.gettable = true;
    o.ready = true;
  }
  buildCounterProjectCreationStatus--;
  return o;
}

void checkProjectCreationStatus(api.ProjectCreationStatus o) {
  buildCounterProjectCreationStatus++;
  if (buildCounterProjectCreationStatus < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(o.gettable!, unittest.isTrue);
    unittest.expect(o.ready!, unittest.isTrue);
  }
  buildCounterProjectCreationStatus--;
}

core.List<api.Folder> buildUnnamed2400() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed2400(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterSearchFoldersResponse = 0;
api.SearchFoldersResponse buildSearchFoldersResponse() {
  var o = api.SearchFoldersResponse();
  buildCounterSearchFoldersResponse++;
  if (buildCounterSearchFoldersResponse < 3) {
    o.folders = buildUnnamed2400();
    o.nextPageToken = 'foo';
  }
  buildCounterSearchFoldersResponse--;
  return o;
}

void checkSearchFoldersResponse(api.SearchFoldersResponse o) {
  buildCounterSearchFoldersResponse++;
  if (buildCounterSearchFoldersResponse < 3) {
    checkUnnamed2400(o.folders!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchFoldersResponse--;
}

core.List<api.Organization> buildUnnamed2401() {
  var o = <api.Organization>[];
  o.add(buildOrganization());
  o.add(buildOrganization());
  return o;
}

void checkUnnamed2401(core.List<api.Organization> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrganization(o[0] as api.Organization);
  checkOrganization(o[1] as api.Organization);
}

core.int buildCounterSearchOrganizationsResponse = 0;
api.SearchOrganizationsResponse buildSearchOrganizationsResponse() {
  var o = api.SearchOrganizationsResponse();
  buildCounterSearchOrganizationsResponse++;
  if (buildCounterSearchOrganizationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.organizations = buildUnnamed2401();
  }
  buildCounterSearchOrganizationsResponse--;
  return o;
}

void checkSearchOrganizationsResponse(api.SearchOrganizationsResponse o) {
  buildCounterSearchOrganizationsResponse++;
  if (buildCounterSearchOrganizationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2401(o.organizations!);
  }
  buildCounterSearchOrganizationsResponse--;
}

core.List<api.Project> buildUnnamed2402() {
  var o = <api.Project>[];
  o.add(buildProject());
  o.add(buildProject());
  return o;
}

void checkUnnamed2402(core.List<api.Project> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProject(o[0] as api.Project);
  checkProject(o[1] as api.Project);
}

core.int buildCounterSearchProjectsResponse = 0;
api.SearchProjectsResponse buildSearchProjectsResponse() {
  var o = api.SearchProjectsResponse();
  buildCounterSearchProjectsResponse++;
  if (buildCounterSearchProjectsResponse < 3) {
    o.nextPageToken = 'foo';
    o.projects = buildUnnamed2402();
  }
  buildCounterSearchProjectsResponse--;
  return o;
}

void checkSearchProjectsResponse(api.SearchProjectsResponse o) {
  buildCounterSearchProjectsResponse++;
  if (buildCounterSearchProjectsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2402(o.projects!);
  }
  buildCounterSearchProjectsResponse--;
}

core.int buildCounterSetIamPolicyRequest = 0;
api.SetIamPolicyRequest buildSetIamPolicyRequest() {
  var o = api.SetIamPolicyRequest();
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    o.policy = buildPolicy();
    o.updateMask = 'foo';
  }
  buildCounterSetIamPolicyRequest--;
  return o;
}

void checkSetIamPolicyRequest(api.SetIamPolicyRequest o) {
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    checkPolicy(o.policy! as api.Policy);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetIamPolicyRequest--;
}

core.Map<core.String, core.Object> buildUnnamed2403() {
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

void checkUnnamed2403(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed2404() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2403());
  o.add(buildUnnamed2403());
  return o;
}

void checkUnnamed2404(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2403(o[0]);
  checkUnnamed2403(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed2404();
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
    checkUnnamed2404(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTagBinding = 0;
api.TagBinding buildTagBinding() {
  var o = api.TagBinding();
  buildCounterTagBinding++;
  if (buildCounterTagBinding < 3) {
    o.name = 'foo';
    o.parent = 'foo';
    o.tagValue = 'foo';
  }
  buildCounterTagBinding--;
  return o;
}

void checkTagBinding(api.TagBinding o) {
  buildCounterTagBinding++;
  if (buildCounterTagBinding < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterTagBinding--;
}

core.int buildCounterTagKey = 0;
api.TagKey buildTagKey() {
  var o = api.TagKey();
  buildCounterTagKey++;
  if (buildCounterTagKey < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.etag = 'foo';
    o.name = 'foo';
    o.namespacedName = 'foo';
    o.parent = 'foo';
    o.shortName = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterTagKey--;
  return o;
}

void checkTagKey(api.TagKey o) {
  buildCounterTagKey++;
  if (buildCounterTagKey < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.namespacedName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shortName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTagKey--;
}

core.int buildCounterTagValue = 0;
api.TagValue buildTagValue() {
  var o = api.TagValue();
  buildCounterTagValue++;
  if (buildCounterTagValue < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.etag = 'foo';
    o.name = 'foo';
    o.namespacedName = 'foo';
    o.parent = 'foo';
    o.shortName = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterTagValue--;
  return o;
}

void checkTagValue(api.TagValue o) {
  buildCounterTagValue++;
  if (buildCounterTagValue < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.namespacedName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shortName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTagValue--;
}

core.List<core.String> buildUnnamed2405() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2405(core.List<core.String> o) {
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
    o.permissions = buildUnnamed2405();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed2405(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed2406() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2406(core.List<core.String> o) {
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
    o.permissions = buildUnnamed2406();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed2406(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterUndeleteFolderMetadata = 0;
api.UndeleteFolderMetadata buildUndeleteFolderMetadata() {
  var o = api.UndeleteFolderMetadata();
  buildCounterUndeleteFolderMetadata++;
  if (buildCounterUndeleteFolderMetadata < 3) {}
  buildCounterUndeleteFolderMetadata--;
  return o;
}

void checkUndeleteFolderMetadata(api.UndeleteFolderMetadata o) {
  buildCounterUndeleteFolderMetadata++;
  if (buildCounterUndeleteFolderMetadata < 3) {}
  buildCounterUndeleteFolderMetadata--;
}

core.int buildCounterUndeleteFolderRequest = 0;
api.UndeleteFolderRequest buildUndeleteFolderRequest() {
  var o = api.UndeleteFolderRequest();
  buildCounterUndeleteFolderRequest++;
  if (buildCounterUndeleteFolderRequest < 3) {}
  buildCounterUndeleteFolderRequest--;
  return o;
}

void checkUndeleteFolderRequest(api.UndeleteFolderRequest o) {
  buildCounterUndeleteFolderRequest++;
  if (buildCounterUndeleteFolderRequest < 3) {}
  buildCounterUndeleteFolderRequest--;
}

core.int buildCounterUndeleteOrganizationMetadata = 0;
api.UndeleteOrganizationMetadata buildUndeleteOrganizationMetadata() {
  var o = api.UndeleteOrganizationMetadata();
  buildCounterUndeleteOrganizationMetadata++;
  if (buildCounterUndeleteOrganizationMetadata < 3) {}
  buildCounterUndeleteOrganizationMetadata--;
  return o;
}

void checkUndeleteOrganizationMetadata(api.UndeleteOrganizationMetadata o) {
  buildCounterUndeleteOrganizationMetadata++;
  if (buildCounterUndeleteOrganizationMetadata < 3) {}
  buildCounterUndeleteOrganizationMetadata--;
}

core.int buildCounterUndeleteProjectMetadata = 0;
api.UndeleteProjectMetadata buildUndeleteProjectMetadata() {
  var o = api.UndeleteProjectMetadata();
  buildCounterUndeleteProjectMetadata++;
  if (buildCounterUndeleteProjectMetadata < 3) {}
  buildCounterUndeleteProjectMetadata--;
  return o;
}

void checkUndeleteProjectMetadata(api.UndeleteProjectMetadata o) {
  buildCounterUndeleteProjectMetadata++;
  if (buildCounterUndeleteProjectMetadata < 3) {}
  buildCounterUndeleteProjectMetadata--;
}

core.int buildCounterUndeleteProjectRequest = 0;
api.UndeleteProjectRequest buildUndeleteProjectRequest() {
  var o = api.UndeleteProjectRequest();
  buildCounterUndeleteProjectRequest++;
  if (buildCounterUndeleteProjectRequest < 3) {}
  buildCounterUndeleteProjectRequest--;
  return o;
}

void checkUndeleteProjectRequest(api.UndeleteProjectRequest o) {
  buildCounterUndeleteProjectRequest++;
  if (buildCounterUndeleteProjectRequest < 3) {}
  buildCounterUndeleteProjectRequest--;
}

core.int buildCounterUpdateFolderMetadata = 0;
api.UpdateFolderMetadata buildUpdateFolderMetadata() {
  var o = api.UpdateFolderMetadata();
  buildCounterUpdateFolderMetadata++;
  if (buildCounterUpdateFolderMetadata < 3) {}
  buildCounterUpdateFolderMetadata--;
  return o;
}

void checkUpdateFolderMetadata(api.UpdateFolderMetadata o) {
  buildCounterUpdateFolderMetadata++;
  if (buildCounterUpdateFolderMetadata < 3) {}
  buildCounterUpdateFolderMetadata--;
}

core.int buildCounterUpdateProjectMetadata = 0;
api.UpdateProjectMetadata buildUpdateProjectMetadata() {
  var o = api.UpdateProjectMetadata();
  buildCounterUpdateProjectMetadata++;
  if (buildCounterUpdateProjectMetadata < 3) {}
  buildCounterUpdateProjectMetadata--;
  return o;
}

void checkUpdateProjectMetadata(api.UpdateProjectMetadata o) {
  buildCounterUpdateProjectMetadata++;
  if (buildCounterUpdateProjectMetadata < 3) {}
  buildCounterUpdateProjectMetadata--;
}

core.int buildCounterUpdateTagKeyMetadata = 0;
api.UpdateTagKeyMetadata buildUpdateTagKeyMetadata() {
  var o = api.UpdateTagKeyMetadata();
  buildCounterUpdateTagKeyMetadata++;
  if (buildCounterUpdateTagKeyMetadata < 3) {}
  buildCounterUpdateTagKeyMetadata--;
  return o;
}

void checkUpdateTagKeyMetadata(api.UpdateTagKeyMetadata o) {
  buildCounterUpdateTagKeyMetadata++;
  if (buildCounterUpdateTagKeyMetadata < 3) {}
  buildCounterUpdateTagKeyMetadata--;
}

core.int buildCounterUpdateTagValueMetadata = 0;
api.UpdateTagValueMetadata buildUpdateTagValueMetadata() {
  var o = api.UpdateTagValueMetadata();
  buildCounterUpdateTagValueMetadata++;
  if (buildCounterUpdateTagValueMetadata < 3) {}
  buildCounterUpdateTagValueMetadata--;
  return o;
}

void checkUpdateTagValueMetadata(api.UpdateTagValueMetadata o) {
  buildCounterUpdateTagValueMetadata++;
  if (buildCounterUpdateTagValueMetadata < 3) {}
  buildCounterUpdateTagValueMetadata--;
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

  unittest.group(
      'obj-schema-CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation(
          od as api
              .CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation);
    });
  });

  unittest.group(
      'obj-schema-CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation(
          od as api
              .CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation);
    });
  });

  unittest.group('obj-schema-CreateFolderMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateFolderMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateFolderMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateFolderMetadata(od as api.CreateFolderMetadata);
    });
  });

  unittest.group('obj-schema-CreateProjectMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateProjectMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateProjectMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateProjectMetadata(od as api.CreateProjectMetadata);
    });
  });

  unittest.group('obj-schema-CreateTagBindingMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateTagBindingMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateTagBindingMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateTagBindingMetadata(od as api.CreateTagBindingMetadata);
    });
  });

  unittest.group('obj-schema-CreateTagKeyMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateTagKeyMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateTagKeyMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateTagKeyMetadata(od as api.CreateTagKeyMetadata);
    });
  });

  unittest.group('obj-schema-CreateTagValueMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateTagValueMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateTagValueMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateTagValueMetadata(od as api.CreateTagValueMetadata);
    });
  });

  unittest.group('obj-schema-DeleteFolderMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteFolderMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteFolderMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteFolderMetadata(od as api.DeleteFolderMetadata);
    });
  });

  unittest.group('obj-schema-DeleteOrganizationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteOrganizationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteOrganizationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteOrganizationMetadata(od as api.DeleteOrganizationMetadata);
    });
  });

  unittest.group('obj-schema-DeleteProjectMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteProjectMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteProjectMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteProjectMetadata(od as api.DeleteProjectMetadata);
    });
  });

  unittest.group('obj-schema-DeleteTagBindingMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteTagBindingMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteTagBindingMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteTagBindingMetadata(od as api.DeleteTagBindingMetadata);
    });
  });

  unittest.group('obj-schema-DeleteTagKeyMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteTagKeyMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteTagKeyMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteTagKeyMetadata(od as api.DeleteTagKeyMetadata);
    });
  });

  unittest.group('obj-schema-DeleteTagValueMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteTagValueMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteTagValueMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteTagValueMetadata(od as api.DeleteTagValueMetadata);
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

  unittest.group('obj-schema-Expr', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpr();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Expr.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExpr(od as api.Expr);
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

  unittest.group('obj-schema-FolderOperation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFolderOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FolderOperation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFolderOperation(od as api.FolderOperation);
    });
  });

  unittest.group('obj-schema-FolderOperationError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFolderOperationError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FolderOperationError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFolderOperationError(od as api.FolderOperationError);
    });
  });

  unittest.group('obj-schema-GetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetIamPolicyRequest(od as api.GetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-GetPolicyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetPolicyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetPolicyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetPolicyOptions(od as api.GetPolicyOptions);
    });
  });

  unittest.group('obj-schema-Lien', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLien();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Lien.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLien(od as api.Lien);
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

  unittest.group('obj-schema-ListLiensResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLiensResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLiensResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLiensResponse(od as api.ListLiensResponse);
    });
  });

  unittest.group('obj-schema-ListProjectsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListProjectsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListProjectsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListProjectsResponse(od as api.ListProjectsResponse);
    });
  });

  unittest.group('obj-schema-ListTagBindingsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTagBindingsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTagBindingsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTagBindingsResponse(od as api.ListTagBindingsResponse);
    });
  });

  unittest.group('obj-schema-ListTagKeysResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTagKeysResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTagKeysResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTagKeysResponse(od as api.ListTagKeysResponse);
    });
  });

  unittest.group('obj-schema-ListTagValuesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTagValuesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTagValuesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTagValuesResponse(od as api.ListTagValuesResponse);
    });
  });

  unittest.group('obj-schema-MoveFolderMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveFolderMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveFolderMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveFolderMetadata(od as api.MoveFolderMetadata);
    });
  });

  unittest.group('obj-schema-MoveFolderRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveFolderRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveFolderRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveFolderRequest(od as api.MoveFolderRequest);
    });
  });

  unittest.group('obj-schema-MoveProjectMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveProjectMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveProjectMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveProjectMetadata(od as api.MoveProjectMetadata);
    });
  });

  unittest.group('obj-schema-MoveProjectRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveProjectRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveProjectRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveProjectRequest(od as api.MoveProjectRequest);
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

  unittest.group('obj-schema-Organization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrganization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Organization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrganization(od as api.Organization);
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

  unittest.group('obj-schema-Project', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Project.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProject(od as api.Project);
    });
  });

  unittest.group('obj-schema-ProjectCreationStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectCreationStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectCreationStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectCreationStatus(od as api.ProjectCreationStatus);
    });
  });

  unittest.group('obj-schema-SearchFoldersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchFoldersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchFoldersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchFoldersResponse(od as api.SearchFoldersResponse);
    });
  });

  unittest.group('obj-schema-SearchOrganizationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchOrganizationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchOrganizationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchOrganizationsResponse(od as api.SearchOrganizationsResponse);
    });
  });

  unittest.group('obj-schema-SearchProjectsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchProjectsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchProjectsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchProjectsResponse(od as api.SearchProjectsResponse);
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

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-TagBinding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTagBinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TagBinding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTagBinding(od as api.TagBinding);
    });
  });

  unittest.group('obj-schema-TagKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTagKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TagKey.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTagKey(od as api.TagKey);
    });
  });

  unittest.group('obj-schema-TagValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTagValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TagValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTagValue(od as api.TagValue);
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

  unittest.group('obj-schema-UndeleteFolderMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteFolderMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteFolderMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteFolderMetadata(od as api.UndeleteFolderMetadata);
    });
  });

  unittest.group('obj-schema-UndeleteFolderRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteFolderRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteFolderRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteFolderRequest(od as api.UndeleteFolderRequest);
    });
  });

  unittest.group('obj-schema-UndeleteOrganizationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteOrganizationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteOrganizationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteOrganizationMetadata(od as api.UndeleteOrganizationMetadata);
    });
  });

  unittest.group('obj-schema-UndeleteProjectMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteProjectMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteProjectMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteProjectMetadata(od as api.UndeleteProjectMetadata);
    });
  });

  unittest.group('obj-schema-UndeleteProjectRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteProjectRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteProjectRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteProjectRequest(od as api.UndeleteProjectRequest);
    });
  });

  unittest.group('obj-schema-UpdateFolderMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateFolderMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateFolderMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateFolderMetadata(od as api.UpdateFolderMetadata);
    });
  });

  unittest.group('obj-schema-UpdateProjectMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateProjectMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateProjectMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateProjectMetadata(od as api.UpdateProjectMetadata);
    });
  });

  unittest.group('obj-schema-UpdateTagKeyMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTagKeyMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTagKeyMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTagKeyMetadata(od as api.UpdateTagKeyMetadata);
    });
  });

  unittest.group('obj-schema-UpdateTagValueMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTagValueMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTagValueMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTagValueMetadata(od as api.UpdateTagValueMetadata);
    });
  });

  unittest.group('resource-FoldersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildFolder();
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
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v3/folders"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
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
          unittest.equals("v3/"),
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
      var res = api.CloudResourceManagerApi(mock).folders;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildFolder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_parent = 'foo';
      var arg_showDeleted = true;
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
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v3/folders"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["showDeleted"]!.first,
          unittest.equals("$arg_showDeleted"),
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
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          showDeleted: arg_showDeleted,
          $fields: arg_$fields);
      checkListFoldersResponse(response as api.ListFoldersResponse);
    });

    unittest.test('method--move', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildMoveFolderRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.MoveFolderRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkMoveFolderRequest(obj as api.MoveFolderRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
          await res.move(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildFolder();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v3/folders:search"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchFoldersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          query: arg_query,
          $fields: arg_$fields);
      checkSearchFoldersResponse(response as api.SearchFoldersResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
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
          unittest.equals("v3/"),
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

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
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
          unittest.equals("v3/"),
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

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildUndeleteFolderRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UndeleteFolderRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUndeleteFolderRequest(obj as api.UndeleteFolderRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-LiensResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).liens;
      var arg_request = buildLien();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Lien.fromJson(json as core.Map<core.String, core.dynamic>);
        checkLien(obj as api.Lien);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v3/liens"),
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
        var resp = convert.json.encode(buildLien());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkLien(response as api.Lien);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).liens;
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
          unittest.equals("v3/"),
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
      var res = api.CloudResourceManagerApi(mock).liens;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildLien());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkLien(response as api.Lien);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).liens;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v3/liens"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListLiensResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          $fields: arg_$fields);
      checkListLiensResponse(response as api.ListLiensResponse);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).operations;
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
          unittest.equals("v3/"),
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
  });

  unittest.group('resource-OrganizationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildOrganization());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkOrganization(response as api.Organization);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
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
          unittest.equals("v3/organizations:search"),
        );
        pathOffset += 23;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchOrganizationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          query: arg_query,
          $fields: arg_$fields);
      checkSearchOrganizationsResponse(
          response as api.SearchOrganizationsResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
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
          unittest.equals("v3/"),
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

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
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
          unittest.equals("v3/"),
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
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildProject();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Project.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProject(obj as api.Project);

        var path = (req.url).path;
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
          unittest.equals("v3/projects"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
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
          unittest.equals("v3/"),
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
      var res = api.CloudResourceManagerApi(mock).projects;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildProject());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkProject(response as api.Project);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_parent = 'foo';
      var arg_showDeleted = true;
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v3/projects"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["showDeleted"]!.first,
          unittest.equals("$arg_showDeleted"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListProjectsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          showDeleted: arg_showDeleted,
          $fields: arg_$fields);
      checkListProjectsResponse(response as api.ListProjectsResponse);
    });

    unittest.test('method--move', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildMoveProjectRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.MoveProjectRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkMoveProjectRequest(obj as api.MoveProjectRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
          await res.move(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildProject();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Project.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProject(obj as api.Project);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
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
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("v3/projects:search"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchProjectsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          query: arg_query,
          $fields: arg_$fields);
      checkSearchProjectsResponse(response as api.SearchProjectsResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
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
          unittest.equals("v3/"),
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

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
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
          unittest.equals("v3/"),
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

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildUndeleteProjectRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UndeleteProjectRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUndeleteProjectRequest(obj as api.UndeleteProjectRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-TagBindingsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagBindings;
      var arg_request = buildTagBinding();
      var arg_validateOnly = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TagBinding.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTagBinding(obj as api.TagBinding);

        var path = (req.url).path;
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
          unittest.equals("v3/tagBindings"),
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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
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
      final response = await res.create(arg_request,
          validateOnly: arg_validateOnly, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagBindings;
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
          unittest.equals("v3/"),
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

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagBindings;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          unittest.equals("v3/tagBindings"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListTagBindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          $fields: arg_$fields);
      checkListTagBindingsResponse(response as api.ListTagBindingsResponse);
    });
  });

  unittest.group('resource-TagKeysResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
      var arg_request = buildTagKey();
      var arg_validateOnly = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TagKey.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTagKey(obj as api.TagKey);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v3/tagKeys"),
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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
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
      final response = await res.create(arg_request,
          validateOnly: arg_validateOnly, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
      var arg_name = 'foo';
      var arg_etag = 'foo';
      var arg_validateOnly = true;
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
          unittest.equals("v3/"),
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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
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
      final response = await res.delete(arg_name,
          etag: arg_etag, validateOnly: arg_validateOnly, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildTagKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkTagKey(response as api.TagKey);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v3/tagKeys"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListTagKeysResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          $fields: arg_$fields);
      checkListTagKeysResponse(response as api.ListTagKeysResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
      var arg_request = buildTagKey();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_validateOnly = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TagKey.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTagKey(obj as api.TagKey);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
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
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask,
          validateOnly: arg_validateOnly,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
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
          unittest.equals("v3/"),
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

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagKeys;
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
          unittest.equals("v3/"),
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
  });

  unittest.group('resource-TagValuesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
      var arg_request = buildTagValue();
      var arg_validateOnly = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TagValue.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTagValue(obj as api.TagValue);

        var path = (req.url).path;
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
          unittest.equals("v3/tagValues"),
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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
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
      final response = await res.create(arg_request,
          validateOnly: arg_validateOnly, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
      var arg_name = 'foo';
      var arg_etag = 'foo';
      var arg_validateOnly = true;
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
          unittest.equals("v3/"),
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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
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
      final response = await res.delete(arg_name,
          etag: arg_etag, validateOnly: arg_validateOnly, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildTagValue());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkTagValue(response as api.TagValue);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v3/tagValues"),
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
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListTagValuesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          $fields: arg_$fields);
      checkListTagValuesResponse(response as api.ListTagValuesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
      var arg_request = buildTagValue();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_validateOnly = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TagValue.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTagValue(obj as api.TagValue);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
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
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask,
          validateOnly: arg_validateOnly,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
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
          unittest.equals("v3/"),
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

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).tagValues;
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
          unittest.equals("v3/"),
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
  });
}

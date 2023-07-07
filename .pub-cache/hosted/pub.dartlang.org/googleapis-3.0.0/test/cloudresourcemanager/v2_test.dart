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

import 'package:googleapis/cloudresourcemanager/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.AuditLogConfig> buildUnnamed3530() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed3530(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed3530();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed3530(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed3531() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3531(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed3531();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed3531(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed3532() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3532(core.List<core.String> o) {
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
    o.members = buildUnnamed3532();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed3532(o.members!);
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
    o.displayName = 'foo';
    o.lifecycleState = 'foo';
    o.name = 'foo';
    o.parent = 'foo';
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
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lifecycleState!,
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

core.List<api.Folder> buildUnnamed3533() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed3533(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterListFoldersResponse = 0;
api.ListFoldersResponse buildListFoldersResponse() {
  var o = api.ListFoldersResponse();
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    o.folders = buildUnnamed3533();
    o.nextPageToken = 'foo';
  }
  buildCounterListFoldersResponse--;
  return o;
}

void checkListFoldersResponse(api.ListFoldersResponse o) {
  buildCounterListFoldersResponse++;
  if (buildCounterListFoldersResponse < 3) {
    checkUnnamed3533(o.folders!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListFoldersResponse--;
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

core.Map<core.String, core.Object> buildUnnamed3534() {
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

void checkUnnamed3534(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed3535() {
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

void checkUnnamed3535(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed3534();
    o.name = 'foo';
    o.response = buildUnnamed3535();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed3534(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3535(o.response!);
  }
  buildCounterOperation--;
}

core.List<api.AuditConfig> buildUnnamed3536() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed3536(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed3537() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed3537(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed3536();
    o.bindings = buildUnnamed3537();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed3536(o.auditConfigs!);
    checkUnnamed3537(o.bindings!);
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

core.int buildCounterSearchFoldersRequest = 0;
api.SearchFoldersRequest buildSearchFoldersRequest() {
  var o = api.SearchFoldersRequest();
  buildCounterSearchFoldersRequest++;
  if (buildCounterSearchFoldersRequest < 3) {
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.query = 'foo';
  }
  buildCounterSearchFoldersRequest--;
  return o;
}

void checkSearchFoldersRequest(api.SearchFoldersRequest o) {
  buildCounterSearchFoldersRequest++;
  if (buildCounterSearchFoldersRequest < 3) {
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchFoldersRequest--;
}

core.List<api.Folder> buildUnnamed3538() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed3538(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterSearchFoldersResponse = 0;
api.SearchFoldersResponse buildSearchFoldersResponse() {
  var o = api.SearchFoldersResponse();
  buildCounterSearchFoldersResponse++;
  if (buildCounterSearchFoldersResponse < 3) {
    o.folders = buildUnnamed3538();
    o.nextPageToken = 'foo';
  }
  buildCounterSearchFoldersResponse--;
  return o;
}

void checkSearchFoldersResponse(api.SearchFoldersResponse o) {
  buildCounterSearchFoldersResponse++;
  if (buildCounterSearchFoldersResponse < 3) {
    checkUnnamed3538(o.folders!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchFoldersResponse--;
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

core.Map<core.String, core.Object> buildUnnamed3539() {
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

void checkUnnamed3539(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed3540() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed3539());
  o.add(buildUnnamed3539());
  return o;
}

void checkUnnamed3540(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed3539(o[0]);
  checkUnnamed3539(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed3540();
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
    checkUnnamed3540(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<core.String> buildUnnamed3541() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3541(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3541();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed3541(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed3542() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3542(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3542();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed3542(o.permissions!);
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

  unittest.group('obj-schema-ListFoldersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFoldersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFoldersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFoldersResponse(od as api.ListFoldersResponse);
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

  unittest.group('obj-schema-Operation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Operation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOperation(od as api.Operation);
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

  unittest.group('obj-schema-ProjectCreationStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectCreationStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectCreationStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectCreationStatus(od as api.ProjectCreationStatus);
    });
  });

  unittest.group('obj-schema-SearchFoldersRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchFoldersRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchFoldersRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchFoldersRequest(od as api.SearchFoldersRequest);
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
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v2/folders"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request,
          parent: arg_parent, $fields: arg_$fields);
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
          unittest.equals("v2/"),
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
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkFolder(response as api.Folder);
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
          unittest.equals("v2/"),
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
          unittest.equals("v2/"),
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
          unittest.equals("v2/folders"),
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
          unittest.equals("v2/"),
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildFolder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkFolder(response as api.Folder);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildSearchFoldersRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchFoldersRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchFoldersRequest(obj as api.SearchFoldersRequest);

        var path = (req.url).path;
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
          unittest.equals("v2/folders:search"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchFoldersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(arg_request, $fields: arg_$fields);
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
          unittest.equals("v2/"),
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
          unittest.equals("v2/"),
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
          unittest.equals("v2/"),
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
      final response =
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkFolder(response as api.Folder);
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
  });
}

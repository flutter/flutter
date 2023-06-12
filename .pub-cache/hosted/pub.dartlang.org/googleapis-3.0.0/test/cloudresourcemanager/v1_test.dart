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

import 'package:googleapis/cloudresourcemanager/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAncestor = 0;
api.Ancestor buildAncestor() {
  var o = api.Ancestor();
  buildCounterAncestor++;
  if (buildCounterAncestor < 3) {
    o.resourceId = buildResourceId();
  }
  buildCounterAncestor--;
  return o;
}

void checkAncestor(api.Ancestor o) {
  buildCounterAncestor++;
  if (buildCounterAncestor < 3) {
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterAncestor--;
}

core.List<api.AuditLogConfig> buildUnnamed3620() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed3620(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed3620();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed3620(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed3621() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3621(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed3621();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed3621(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed3622() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3622(core.List<core.String> o) {
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
    o.members = buildUnnamed3622();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed3622(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterBooleanConstraint = 0;
api.BooleanConstraint buildBooleanConstraint() {
  var o = api.BooleanConstraint();
  buildCounterBooleanConstraint++;
  if (buildCounterBooleanConstraint < 3) {}
  buildCounterBooleanConstraint--;
  return o;
}

void checkBooleanConstraint(api.BooleanConstraint o) {
  buildCounterBooleanConstraint++;
  if (buildCounterBooleanConstraint < 3) {}
  buildCounterBooleanConstraint--;
}

core.int buildCounterBooleanPolicy = 0;
api.BooleanPolicy buildBooleanPolicy() {
  var o = api.BooleanPolicy();
  buildCounterBooleanPolicy++;
  if (buildCounterBooleanPolicy < 3) {
    o.enforced = true;
  }
  buildCounterBooleanPolicy--;
  return o;
}

void checkBooleanPolicy(api.BooleanPolicy o) {
  buildCounterBooleanPolicy++;
  if (buildCounterBooleanPolicy < 3) {
    unittest.expect(o.enforced!, unittest.isTrue);
  }
  buildCounterBooleanPolicy--;
}

core.int buildCounterClearOrgPolicyRequest = 0;
api.ClearOrgPolicyRequest buildClearOrgPolicyRequest() {
  var o = api.ClearOrgPolicyRequest();
  buildCounterClearOrgPolicyRequest++;
  if (buildCounterClearOrgPolicyRequest < 3) {
    o.constraint = 'foo';
    o.etag = 'foo';
  }
  buildCounterClearOrgPolicyRequest--;
  return o;
}

void checkClearOrgPolicyRequest(api.ClearOrgPolicyRequest o) {
  buildCounterClearOrgPolicyRequest++;
  if (buildCounterClearOrgPolicyRequest < 3) {
    unittest.expect(
      o.constraint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
  }
  buildCounterClearOrgPolicyRequest--;
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

core.int buildCounterConstraint = 0;
api.Constraint buildConstraint() {
  var o = api.Constraint();
  buildCounterConstraint++;
  if (buildCounterConstraint < 3) {
    o.booleanConstraint = buildBooleanConstraint();
    o.constraintDefault = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.listConstraint = buildListConstraint();
    o.name = 'foo';
    o.version = 42;
  }
  buildCounterConstraint--;
  return o;
}

void checkConstraint(api.Constraint o) {
  buildCounterConstraint++;
  if (buildCounterConstraint < 3) {
    checkBooleanConstraint(o.booleanConstraint! as api.BooleanConstraint);
    unittest.expect(
      o.constraintDefault!,
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
    checkListConstraint(o.listConstraint! as api.ListConstraint);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterConstraint--;
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

core.int buildCounterGetAncestryRequest = 0;
api.GetAncestryRequest buildGetAncestryRequest() {
  var o = api.GetAncestryRequest();
  buildCounterGetAncestryRequest++;
  if (buildCounterGetAncestryRequest < 3) {}
  buildCounterGetAncestryRequest--;
  return o;
}

void checkGetAncestryRequest(api.GetAncestryRequest o) {
  buildCounterGetAncestryRequest++;
  if (buildCounterGetAncestryRequest < 3) {}
  buildCounterGetAncestryRequest--;
}

core.List<api.Ancestor> buildUnnamed3623() {
  var o = <api.Ancestor>[];
  o.add(buildAncestor());
  o.add(buildAncestor());
  return o;
}

void checkUnnamed3623(core.List<api.Ancestor> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAncestor(o[0] as api.Ancestor);
  checkAncestor(o[1] as api.Ancestor);
}

core.int buildCounterGetAncestryResponse = 0;
api.GetAncestryResponse buildGetAncestryResponse() {
  var o = api.GetAncestryResponse();
  buildCounterGetAncestryResponse++;
  if (buildCounterGetAncestryResponse < 3) {
    o.ancestor = buildUnnamed3623();
  }
  buildCounterGetAncestryResponse--;
  return o;
}

void checkGetAncestryResponse(api.GetAncestryResponse o) {
  buildCounterGetAncestryResponse++;
  if (buildCounterGetAncestryResponse < 3) {
    checkUnnamed3623(o.ancestor!);
  }
  buildCounterGetAncestryResponse--;
}

core.int buildCounterGetEffectiveOrgPolicyRequest = 0;
api.GetEffectiveOrgPolicyRequest buildGetEffectiveOrgPolicyRequest() {
  var o = api.GetEffectiveOrgPolicyRequest();
  buildCounterGetEffectiveOrgPolicyRequest++;
  if (buildCounterGetEffectiveOrgPolicyRequest < 3) {
    o.constraint = 'foo';
  }
  buildCounterGetEffectiveOrgPolicyRequest--;
  return o;
}

void checkGetEffectiveOrgPolicyRequest(api.GetEffectiveOrgPolicyRequest o) {
  buildCounterGetEffectiveOrgPolicyRequest++;
  if (buildCounterGetEffectiveOrgPolicyRequest < 3) {
    unittest.expect(
      o.constraint!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetEffectiveOrgPolicyRequest--;
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

core.int buildCounterGetOrgPolicyRequest = 0;
api.GetOrgPolicyRequest buildGetOrgPolicyRequest() {
  var o = api.GetOrgPolicyRequest();
  buildCounterGetOrgPolicyRequest++;
  if (buildCounterGetOrgPolicyRequest < 3) {
    o.constraint = 'foo';
  }
  buildCounterGetOrgPolicyRequest--;
  return o;
}

void checkGetOrgPolicyRequest(api.GetOrgPolicyRequest o) {
  buildCounterGetOrgPolicyRequest++;
  if (buildCounterGetOrgPolicyRequest < 3) {
    unittest.expect(
      o.constraint!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetOrgPolicyRequest--;
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

core.List<core.String> buildUnnamed3624() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3624(core.List<core.String> o) {
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
    o.restrictions = buildUnnamed3624();
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
    checkUnnamed3624(o.restrictions!);
  }
  buildCounterLien--;
}

core.int buildCounterListAvailableOrgPolicyConstraintsRequest = 0;
api.ListAvailableOrgPolicyConstraintsRequest
    buildListAvailableOrgPolicyConstraintsRequest() {
  var o = api.ListAvailableOrgPolicyConstraintsRequest();
  buildCounterListAvailableOrgPolicyConstraintsRequest++;
  if (buildCounterListAvailableOrgPolicyConstraintsRequest < 3) {
    o.pageSize = 42;
    o.pageToken = 'foo';
  }
  buildCounterListAvailableOrgPolicyConstraintsRequest--;
  return o;
}

void checkListAvailableOrgPolicyConstraintsRequest(
    api.ListAvailableOrgPolicyConstraintsRequest o) {
  buildCounterListAvailableOrgPolicyConstraintsRequest++;
  if (buildCounterListAvailableOrgPolicyConstraintsRequest < 3) {
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAvailableOrgPolicyConstraintsRequest--;
}

core.List<api.Constraint> buildUnnamed3625() {
  var o = <api.Constraint>[];
  o.add(buildConstraint());
  o.add(buildConstraint());
  return o;
}

void checkUnnamed3625(core.List<api.Constraint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConstraint(o[0] as api.Constraint);
  checkConstraint(o[1] as api.Constraint);
}

core.int buildCounterListAvailableOrgPolicyConstraintsResponse = 0;
api.ListAvailableOrgPolicyConstraintsResponse
    buildListAvailableOrgPolicyConstraintsResponse() {
  var o = api.ListAvailableOrgPolicyConstraintsResponse();
  buildCounterListAvailableOrgPolicyConstraintsResponse++;
  if (buildCounterListAvailableOrgPolicyConstraintsResponse < 3) {
    o.constraints = buildUnnamed3625();
    o.nextPageToken = 'foo';
  }
  buildCounterListAvailableOrgPolicyConstraintsResponse--;
  return o;
}

void checkListAvailableOrgPolicyConstraintsResponse(
    api.ListAvailableOrgPolicyConstraintsResponse o) {
  buildCounterListAvailableOrgPolicyConstraintsResponse++;
  if (buildCounterListAvailableOrgPolicyConstraintsResponse < 3) {
    checkUnnamed3625(o.constraints!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAvailableOrgPolicyConstraintsResponse--;
}

core.int buildCounterListConstraint = 0;
api.ListConstraint buildListConstraint() {
  var o = api.ListConstraint();
  buildCounterListConstraint++;
  if (buildCounterListConstraint < 3) {
    o.suggestedValue = 'foo';
    o.supportsUnder = true;
  }
  buildCounterListConstraint--;
  return o;
}

void checkListConstraint(api.ListConstraint o) {
  buildCounterListConstraint++;
  if (buildCounterListConstraint < 3) {
    unittest.expect(
      o.suggestedValue!,
      unittest.equals('foo'),
    );
    unittest.expect(o.supportsUnder!, unittest.isTrue);
  }
  buildCounterListConstraint--;
}

core.List<api.Lien> buildUnnamed3626() {
  var o = <api.Lien>[];
  o.add(buildLien());
  o.add(buildLien());
  return o;
}

void checkUnnamed3626(core.List<api.Lien> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLien(o[0] as api.Lien);
  checkLien(o[1] as api.Lien);
}

core.int buildCounterListLiensResponse = 0;
api.ListLiensResponse buildListLiensResponse() {
  var o = api.ListLiensResponse();
  buildCounterListLiensResponse++;
  if (buildCounterListLiensResponse < 3) {
    o.liens = buildUnnamed3626();
    o.nextPageToken = 'foo';
  }
  buildCounterListLiensResponse--;
  return o;
}

void checkListLiensResponse(api.ListLiensResponse o) {
  buildCounterListLiensResponse++;
  if (buildCounterListLiensResponse < 3) {
    checkUnnamed3626(o.liens!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLiensResponse--;
}

core.int buildCounterListOrgPoliciesRequest = 0;
api.ListOrgPoliciesRequest buildListOrgPoliciesRequest() {
  var o = api.ListOrgPoliciesRequest();
  buildCounterListOrgPoliciesRequest++;
  if (buildCounterListOrgPoliciesRequest < 3) {
    o.pageSize = 42;
    o.pageToken = 'foo';
  }
  buildCounterListOrgPoliciesRequest--;
  return o;
}

void checkListOrgPoliciesRequest(api.ListOrgPoliciesRequest o) {
  buildCounterListOrgPoliciesRequest++;
  if (buildCounterListOrgPoliciesRequest < 3) {
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListOrgPoliciesRequest--;
}

core.List<api.OrgPolicy> buildUnnamed3627() {
  var o = <api.OrgPolicy>[];
  o.add(buildOrgPolicy());
  o.add(buildOrgPolicy());
  return o;
}

void checkUnnamed3627(core.List<api.OrgPolicy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrgPolicy(o[0] as api.OrgPolicy);
  checkOrgPolicy(o[1] as api.OrgPolicy);
}

core.int buildCounterListOrgPoliciesResponse = 0;
api.ListOrgPoliciesResponse buildListOrgPoliciesResponse() {
  var o = api.ListOrgPoliciesResponse();
  buildCounterListOrgPoliciesResponse++;
  if (buildCounterListOrgPoliciesResponse < 3) {
    o.nextPageToken = 'foo';
    o.policies = buildUnnamed3627();
  }
  buildCounterListOrgPoliciesResponse--;
  return o;
}

void checkListOrgPoliciesResponse(api.ListOrgPoliciesResponse o) {
  buildCounterListOrgPoliciesResponse++;
  if (buildCounterListOrgPoliciesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3627(o.policies!);
  }
  buildCounterListOrgPoliciesResponse--;
}

core.List<core.String> buildUnnamed3628() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3628(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3629() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3629(core.List<core.String> o) {
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

core.int buildCounterListPolicy = 0;
api.ListPolicy buildListPolicy() {
  var o = api.ListPolicy();
  buildCounterListPolicy++;
  if (buildCounterListPolicy < 3) {
    o.allValues = 'foo';
    o.allowedValues = buildUnnamed3628();
    o.deniedValues = buildUnnamed3629();
    o.inheritFromParent = true;
    o.suggestedValue = 'foo';
  }
  buildCounterListPolicy--;
  return o;
}

void checkListPolicy(api.ListPolicy o) {
  buildCounterListPolicy++;
  if (buildCounterListPolicy < 3) {
    unittest.expect(
      o.allValues!,
      unittest.equals('foo'),
    );
    checkUnnamed3628(o.allowedValues!);
    checkUnnamed3629(o.deniedValues!);
    unittest.expect(o.inheritFromParent!, unittest.isTrue);
    unittest.expect(
      o.suggestedValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterListPolicy--;
}

core.List<api.Project> buildUnnamed3630() {
  var o = <api.Project>[];
  o.add(buildProject());
  o.add(buildProject());
  return o;
}

void checkUnnamed3630(core.List<api.Project> o) {
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
    o.projects = buildUnnamed3630();
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
    checkUnnamed3630(o.projects!);
  }
  buildCounterListProjectsResponse--;
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

core.Map<core.String, core.Object> buildUnnamed3631() {
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

void checkUnnamed3631(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed3632() {
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

void checkUnnamed3632(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed3631();
    o.name = 'foo';
    o.response = buildUnnamed3632();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed3631(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3632(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOrgPolicy = 0;
api.OrgPolicy buildOrgPolicy() {
  var o = api.OrgPolicy();
  buildCounterOrgPolicy++;
  if (buildCounterOrgPolicy < 3) {
    o.booleanPolicy = buildBooleanPolicy();
    o.constraint = 'foo';
    o.etag = 'foo';
    o.listPolicy = buildListPolicy();
    o.restoreDefault = buildRestoreDefault();
    o.updateTime = 'foo';
    o.version = 42;
  }
  buildCounterOrgPolicy--;
  return o;
}

void checkOrgPolicy(api.OrgPolicy o) {
  buildCounterOrgPolicy++;
  if (buildCounterOrgPolicy < 3) {
    checkBooleanPolicy(o.booleanPolicy! as api.BooleanPolicy);
    unittest.expect(
      o.constraint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkListPolicy(o.listPolicy! as api.ListPolicy);
    checkRestoreDefault(o.restoreDefault! as api.RestoreDefault);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterOrgPolicy--;
}

core.int buildCounterOrganization = 0;
api.Organization buildOrganization() {
  var o = api.Organization();
  buildCounterOrganization++;
  if (buildCounterOrganization < 3) {
    o.creationTime = 'foo';
    o.displayName = 'foo';
    o.lifecycleState = 'foo';
    o.name = 'foo';
    o.owner = buildOrganizationOwner();
  }
  buildCounterOrganization--;
  return o;
}

void checkOrganization(api.Organization o) {
  buildCounterOrganization++;
  if (buildCounterOrganization < 3) {
    unittest.expect(
      o.creationTime!,
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
    checkOrganizationOwner(o.owner! as api.OrganizationOwner);
  }
  buildCounterOrganization--;
}

core.int buildCounterOrganizationOwner = 0;
api.OrganizationOwner buildOrganizationOwner() {
  var o = api.OrganizationOwner();
  buildCounterOrganizationOwner++;
  if (buildCounterOrganizationOwner < 3) {
    o.directoryCustomerId = 'foo';
  }
  buildCounterOrganizationOwner--;
  return o;
}

void checkOrganizationOwner(api.OrganizationOwner o) {
  buildCounterOrganizationOwner++;
  if (buildCounterOrganizationOwner < 3) {
    unittest.expect(
      o.directoryCustomerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterOrganizationOwner--;
}

core.List<api.AuditConfig> buildUnnamed3633() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed3633(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed3634() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed3634(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed3633();
    o.bindings = buildUnnamed3634();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed3633(o.auditConfigs!);
    checkUnnamed3634(o.bindings!);
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

core.Map<core.String, core.String> buildUnnamed3635() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3635(core.Map<core.String, core.String> o) {
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
    o.labels = buildUnnamed3635();
    o.lifecycleState = 'foo';
    o.name = 'foo';
    o.parent = buildResourceId();
    o.projectId = 'foo';
    o.projectNumber = 'foo';
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
    checkUnnamed3635(o.labels!);
    unittest.expect(
      o.lifecycleState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkResourceId(o.parent! as api.ResourceId);
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectNumber!,
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

core.int buildCounterResourceId = 0;
api.ResourceId buildResourceId() {
  var o = api.ResourceId();
  buildCounterResourceId++;
  if (buildCounterResourceId < 3) {
    o.id = 'foo';
    o.type = 'foo';
  }
  buildCounterResourceId--;
  return o;
}

void checkResourceId(api.ResourceId o) {
  buildCounterResourceId++;
  if (buildCounterResourceId < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceId--;
}

core.int buildCounterRestoreDefault = 0;
api.RestoreDefault buildRestoreDefault() {
  var o = api.RestoreDefault();
  buildCounterRestoreDefault++;
  if (buildCounterRestoreDefault < 3) {}
  buildCounterRestoreDefault--;
  return o;
}

void checkRestoreDefault(api.RestoreDefault o) {
  buildCounterRestoreDefault++;
  if (buildCounterRestoreDefault < 3) {}
  buildCounterRestoreDefault--;
}

core.int buildCounterSearchOrganizationsRequest = 0;
api.SearchOrganizationsRequest buildSearchOrganizationsRequest() {
  var o = api.SearchOrganizationsRequest();
  buildCounterSearchOrganizationsRequest++;
  if (buildCounterSearchOrganizationsRequest < 3) {
    o.filter = 'foo';
    o.pageSize = 42;
    o.pageToken = 'foo';
  }
  buildCounterSearchOrganizationsRequest--;
  return o;
}

void checkSearchOrganizationsRequest(api.SearchOrganizationsRequest o) {
  buildCounterSearchOrganizationsRequest++;
  if (buildCounterSearchOrganizationsRequest < 3) {
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchOrganizationsRequest--;
}

core.List<api.Organization> buildUnnamed3636() {
  var o = <api.Organization>[];
  o.add(buildOrganization());
  o.add(buildOrganization());
  return o;
}

void checkUnnamed3636(core.List<api.Organization> o) {
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
    o.organizations = buildUnnamed3636();
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
    checkUnnamed3636(o.organizations!);
  }
  buildCounterSearchOrganizationsResponse--;
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

core.int buildCounterSetOrgPolicyRequest = 0;
api.SetOrgPolicyRequest buildSetOrgPolicyRequest() {
  var o = api.SetOrgPolicyRequest();
  buildCounterSetOrgPolicyRequest++;
  if (buildCounterSetOrgPolicyRequest < 3) {
    o.policy = buildOrgPolicy();
  }
  buildCounterSetOrgPolicyRequest--;
  return o;
}

void checkSetOrgPolicyRequest(api.SetOrgPolicyRequest o) {
  buildCounterSetOrgPolicyRequest++;
  if (buildCounterSetOrgPolicyRequest < 3) {
    checkOrgPolicy(o.policy! as api.OrgPolicy);
  }
  buildCounterSetOrgPolicyRequest--;
}

core.Map<core.String, core.Object> buildUnnamed3637() {
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

void checkUnnamed3637(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed3638() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed3637());
  o.add(buildUnnamed3637());
  return o;
}

void checkUnnamed3638(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed3637(o[0]);
  checkUnnamed3637(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed3638();
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
    checkUnnamed3638(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<core.String> buildUnnamed3639() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3639(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3639();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed3639(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed3640() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3640(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3640();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed3640(o.permissions!);
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
  unittest.group('obj-schema-Ancestor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAncestor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Ancestor.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAncestor(od as api.Ancestor);
    });
  });

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

  unittest.group('obj-schema-BooleanConstraint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBooleanConstraint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BooleanConstraint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBooleanConstraint(od as api.BooleanConstraint);
    });
  });

  unittest.group('obj-schema-BooleanPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBooleanPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BooleanPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBooleanPolicy(od as api.BooleanPolicy);
    });
  });

  unittest.group('obj-schema-ClearOrgPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClearOrgPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClearOrgPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClearOrgPolicyRequest(od as api.ClearOrgPolicyRequest);
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

  unittest.group('obj-schema-Constraint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConstraint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Constraint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkConstraint(od as api.Constraint);
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

  unittest.group('obj-schema-GetAncestryRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetAncestryRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetAncestryRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetAncestryRequest(od as api.GetAncestryRequest);
    });
  });

  unittest.group('obj-schema-GetAncestryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetAncestryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetAncestryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetAncestryResponse(od as api.GetAncestryResponse);
    });
  });

  unittest.group('obj-schema-GetEffectiveOrgPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetEffectiveOrgPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetEffectiveOrgPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetEffectiveOrgPolicyRequest(od as api.GetEffectiveOrgPolicyRequest);
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

  unittest.group('obj-schema-GetOrgPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetOrgPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetOrgPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetOrgPolicyRequest(od as api.GetOrgPolicyRequest);
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

  unittest.group('obj-schema-ListAvailableOrgPolicyConstraintsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAvailableOrgPolicyConstraintsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAvailableOrgPolicyConstraintsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAvailableOrgPolicyConstraintsRequest(
          od as api.ListAvailableOrgPolicyConstraintsRequest);
    });
  });

  unittest.group('obj-schema-ListAvailableOrgPolicyConstraintsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAvailableOrgPolicyConstraintsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAvailableOrgPolicyConstraintsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAvailableOrgPolicyConstraintsResponse(
          od as api.ListAvailableOrgPolicyConstraintsResponse);
    });
  });

  unittest.group('obj-schema-ListConstraint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConstraint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConstraint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConstraint(od as api.ListConstraint);
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

  unittest.group('obj-schema-ListOrgPoliciesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOrgPoliciesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOrgPoliciesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOrgPoliciesRequest(od as api.ListOrgPoliciesRequest);
    });
  });

  unittest.group('obj-schema-ListOrgPoliciesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOrgPoliciesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOrgPoliciesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOrgPoliciesResponse(od as api.ListOrgPoliciesResponse);
    });
  });

  unittest.group('obj-schema-ListPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ListPolicy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkListPolicy(od as api.ListPolicy);
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

  unittest.group('obj-schema-MoveFolderMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveFolderMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveFolderMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveFolderMetadata(od as api.MoveFolderMetadata);
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

  unittest.group('obj-schema-OrgPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrgPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OrgPolicy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOrgPolicy(od as api.OrgPolicy);
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

  unittest.group('obj-schema-OrganizationOwner', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrganizationOwner();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OrganizationOwner.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrganizationOwner(od as api.OrganizationOwner);
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

  unittest.group('obj-schema-ResourceId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ResourceId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResourceId(od as api.ResourceId);
    });
  });

  unittest.group('obj-schema-RestoreDefault', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestoreDefault();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestoreDefault.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestoreDefault(od as api.RestoreDefault);
    });
  });

  unittest.group('obj-schema-SearchOrganizationsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchOrganizationsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchOrganizationsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchOrganizationsRequest(od as api.SearchOrganizationsRequest);
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

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-SetOrgPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetOrgPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetOrgPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetOrgPolicyRequest(od as api.SetOrgPolicyRequest);
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
    unittest.test('method--clearOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildClearOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClearOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClearOrgPolicyRequest(obj as api.ClearOrgPolicyRequest);

        var path = (req.url).path;
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
      final response = await res.clearOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--getEffectiveOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildGetEffectiveOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetEffectiveOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetEffectiveOrgPolicyRequest(
            obj as api.GetEffectiveOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getEffectiveOrgPolicy(
          arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
    });

    unittest.test('method--getOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildGetOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetOrgPolicyRequest(obj as api.GetOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
    });

    unittest.test('method--listAvailableOrgPolicyConstraints', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildListAvailableOrgPolicyConstraintsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListAvailableOrgPolicyConstraintsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListAvailableOrgPolicyConstraintsRequest(
            obj as api.ListAvailableOrgPolicyConstraintsRequest);

        var path = (req.url).path;
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
        var resp = convert.json
            .encode(buildListAvailableOrgPolicyConstraintsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listAvailableOrgPolicyConstraints(
          arg_request, arg_resource,
          $fields: arg_$fields);
      checkListAvailableOrgPolicyConstraintsResponse(
          response as api.ListAvailableOrgPolicyConstraintsResponse);
    });

    unittest.test('method--listOrgPolicies', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildListOrgPoliciesRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListOrgPoliciesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListOrgPoliciesRequest(obj as api.ListOrgPoliciesRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildListOrgPoliciesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listOrgPolicies(arg_request, arg_resource,
          $fields: arg_$fields);
      checkListOrgPoliciesResponse(response as api.ListOrgPoliciesResponse);
    });

    unittest.test('method--setOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).folders;
      var arg_request = buildSetOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetOrgPolicyRequest(obj as api.SetOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
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
          unittest.equals("v1/liens"),
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
          unittest.equals("v1/liens"),
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

  unittest.group('resource-OrganizationsResource', () {
    unittest.test('method--clearOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildClearOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClearOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClearOrgPolicyRequest(obj as api.ClearOrgPolicyRequest);

        var path = (req.url).path;
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
      final response = await res.clearOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

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
        var resp = convert.json.encode(buildOrganization());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkOrganization(response as api.Organization);
    });

    unittest.test('method--getEffectiveOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildGetEffectiveOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetEffectiveOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetEffectiveOrgPolicyRequest(
            obj as api.GetEffectiveOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getEffectiveOrgPolicy(
          arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
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
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--getOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildGetOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetOrgPolicyRequest(obj as api.GetOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
    });

    unittest.test('method--listAvailableOrgPolicyConstraints', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildListAvailableOrgPolicyConstraintsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListAvailableOrgPolicyConstraintsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListAvailableOrgPolicyConstraintsRequest(
            obj as api.ListAvailableOrgPolicyConstraintsRequest);

        var path = (req.url).path;
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
        var resp = convert.json
            .encode(buildListAvailableOrgPolicyConstraintsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listAvailableOrgPolicyConstraints(
          arg_request, arg_resource,
          $fields: arg_$fields);
      checkListAvailableOrgPolicyConstraintsResponse(
          response as api.ListAvailableOrgPolicyConstraintsResponse);
    });

    unittest.test('method--listOrgPolicies', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildListOrgPoliciesRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListOrgPoliciesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListOrgPoliciesRequest(obj as api.ListOrgPoliciesRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildListOrgPoliciesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listOrgPolicies(arg_request, arg_resource,
          $fields: arg_$fields);
      checkListOrgPoliciesResponse(response as api.ListOrgPoliciesResponse);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildSearchOrganizationsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchOrganizationsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchOrganizationsRequest(obj as api.SearchOrganizationsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/organizations:search"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchOrganizationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(arg_request, $fields: arg_$fields);
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

    unittest.test('method--setOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).organizations;
      var arg_request = buildSetOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetOrgPolicyRequest(obj as api.SetOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
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
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--clearOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildClearOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClearOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClearOrgPolicyRequest(obj as api.ClearOrgPolicyRequest);

        var path = (req.url).path;
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
      final response = await res.clearOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_projectId = 'foo';
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
          unittest.equals('$arg_projectId'),
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
      final response = await res.delete(arg_projectId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_projectId = 'foo';
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
          unittest.equals('$arg_projectId'),
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
      final response = await res.get(arg_projectId, $fields: arg_$fields);
      checkProject(response as api.Project);
    });

    unittest.test('method--getAncestry', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildGetAncestryRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetAncestryRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetAncestryRequest(obj as api.GetAncestryRequest);

        var path = (req.url).path;
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
        index = path.indexOf(':getAncestry', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals(":getAncestry"),
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
        var resp = convert.json.encode(buildGetAncestryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getAncestry(arg_request, arg_projectId,
          $fields: arg_$fields);
      checkGetAncestryResponse(response as api.GetAncestryResponse);
    });

    unittest.test('method--getEffectiveOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildGetEffectiveOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetEffectiveOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetEffectiveOrgPolicyRequest(
            obj as api.GetEffectiveOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getEffectiveOrgPolicy(
          arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':getIamPolicy', pathOffset);
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
          unittest.equals(":getIamPolicy"),
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
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--getOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildGetOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetOrgPolicyRequest(obj as api.GetOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
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
        var resp = convert.json.encode(buildListProjectsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListProjectsResponse(response as api.ListProjectsResponse);
    });

    unittest.test('method--listAvailableOrgPolicyConstraints', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildListAvailableOrgPolicyConstraintsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListAvailableOrgPolicyConstraintsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListAvailableOrgPolicyConstraintsRequest(
            obj as api.ListAvailableOrgPolicyConstraintsRequest);

        var path = (req.url).path;
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
        var resp = convert.json
            .encode(buildListAvailableOrgPolicyConstraintsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listAvailableOrgPolicyConstraints(
          arg_request, arg_resource,
          $fields: arg_$fields);
      checkListAvailableOrgPolicyConstraintsResponse(
          response as api.ListAvailableOrgPolicyConstraintsResponse);
    });

    unittest.test('method--listOrgPolicies', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildListOrgPoliciesRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListOrgPoliciesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListOrgPoliciesRequest(obj as api.ListOrgPoliciesRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildListOrgPoliciesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listOrgPolicies(arg_request, arg_resource,
          $fields: arg_$fields);
      checkListOrgPoliciesResponse(response as api.ListOrgPoliciesResponse);
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':setIamPolicy', pathOffset);
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
          unittest.equals(":setIamPolicy"),
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
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--setOrgPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildSetOrgPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetOrgPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetOrgPolicyRequest(obj as api.SetOrgPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildOrgPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setOrgPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkOrgPolicy(response as api.OrgPolicy);
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':testIamPermissions', pathOffset);
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
          unittest.equals(":testIamPermissions"),
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
      var arg_projectId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':undelete', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals(":undelete"),
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.undelete(arg_request, arg_projectId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.CloudResourceManagerApi(mock).projects;
      var arg_request = buildProject();
      var arg_projectId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
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
      final response =
          await res.update(arg_request, arg_projectId, $fields: arg_$fields);
      checkProject(response as api.Project);
    });
  });
}

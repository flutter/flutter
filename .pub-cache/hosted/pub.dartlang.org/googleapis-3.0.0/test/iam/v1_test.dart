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

import 'package:googleapis/iam/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAdminAuditData = 0;
api.AdminAuditData buildAdminAuditData() {
  var o = api.AdminAuditData();
  buildCounterAdminAuditData++;
  if (buildCounterAdminAuditData < 3) {
    o.permissionDelta = buildPermissionDelta();
  }
  buildCounterAdminAuditData--;
  return o;
}

void checkAdminAuditData(api.AdminAuditData o) {
  buildCounterAdminAuditData++;
  if (buildCounterAdminAuditData < 3) {
    checkPermissionDelta(o.permissionDelta! as api.PermissionDelta);
  }
  buildCounterAdminAuditData--;
}

core.List<api.AuditLogConfig> buildUnnamed7138() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed7138(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed7138();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed7138(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.int buildCounterAuditData = 0;
api.AuditData buildAuditData() {
  var o = api.AuditData();
  buildCounterAuditData++;
  if (buildCounterAuditData < 3) {
    o.policyDelta = buildPolicyDelta();
  }
  buildCounterAuditData--;
  return o;
}

void checkAuditData(api.AuditData o) {
  buildCounterAuditData++;
  if (buildCounterAuditData < 3) {
    checkPolicyDelta(o.policyDelta! as api.PolicyDelta);
  }
  buildCounterAuditData--;
}

core.List<core.String> buildUnnamed7139() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7139(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed7139();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed7139(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.int buildCounterAuditableService = 0;
api.AuditableService buildAuditableService() {
  var o = api.AuditableService();
  buildCounterAuditableService++;
  if (buildCounterAuditableService < 3) {
    o.name = 'foo';
  }
  buildCounterAuditableService--;
  return o;
}

void checkAuditableService(api.AuditableService o) {
  buildCounterAuditableService++;
  if (buildCounterAuditableService < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditableService--;
}

core.int buildCounterAws = 0;
api.Aws buildAws() {
  var o = api.Aws();
  buildCounterAws++;
  if (buildCounterAws < 3) {
    o.accountId = 'foo';
  }
  buildCounterAws--;
  return o;
}

void checkAws(api.Aws o) {
  buildCounterAws++;
  if (buildCounterAws < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAws--;
}

core.List<core.String> buildUnnamed7140() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7140(core.List<core.String> o) {
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
    o.members = buildUnnamed7140();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed7140(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterBindingDelta = 0;
api.BindingDelta buildBindingDelta() {
  var o = api.BindingDelta();
  buildCounterBindingDelta++;
  if (buildCounterBindingDelta < 3) {
    o.action = 'foo';
    o.condition = buildExpr();
    o.member = 'foo';
    o.role = 'foo';
  }
  buildCounterBindingDelta--;
  return o;
}

void checkBindingDelta(api.BindingDelta o) {
  buildCounterBindingDelta++;
  if (buildCounterBindingDelta < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    checkExpr(o.condition! as api.Expr);
    unittest.expect(
      o.member!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBindingDelta--;
}

core.int buildCounterCreateRoleRequest = 0;
api.CreateRoleRequest buildCreateRoleRequest() {
  var o = api.CreateRoleRequest();
  buildCounterCreateRoleRequest++;
  if (buildCounterCreateRoleRequest < 3) {
    o.role = buildRole();
    o.roleId = 'foo';
  }
  buildCounterCreateRoleRequest--;
  return o;
}

void checkCreateRoleRequest(api.CreateRoleRequest o) {
  buildCounterCreateRoleRequest++;
  if (buildCounterCreateRoleRequest < 3) {
    checkRole(o.role! as api.Role);
    unittest.expect(
      o.roleId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateRoleRequest--;
}

core.int buildCounterCreateServiceAccountKeyRequest = 0;
api.CreateServiceAccountKeyRequest buildCreateServiceAccountKeyRequest() {
  var o = api.CreateServiceAccountKeyRequest();
  buildCounterCreateServiceAccountKeyRequest++;
  if (buildCounterCreateServiceAccountKeyRequest < 3) {
    o.keyAlgorithm = 'foo';
    o.privateKeyType = 'foo';
  }
  buildCounterCreateServiceAccountKeyRequest--;
  return o;
}

void checkCreateServiceAccountKeyRequest(api.CreateServiceAccountKeyRequest o) {
  buildCounterCreateServiceAccountKeyRequest++;
  if (buildCounterCreateServiceAccountKeyRequest < 3) {
    unittest.expect(
      o.keyAlgorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.privateKeyType!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateServiceAccountKeyRequest--;
}

core.int buildCounterCreateServiceAccountRequest = 0;
api.CreateServiceAccountRequest buildCreateServiceAccountRequest() {
  var o = api.CreateServiceAccountRequest();
  buildCounterCreateServiceAccountRequest++;
  if (buildCounterCreateServiceAccountRequest < 3) {
    o.accountId = 'foo';
    o.serviceAccount = buildServiceAccount();
  }
  buildCounterCreateServiceAccountRequest--;
  return o;
}

void checkCreateServiceAccountRequest(api.CreateServiceAccountRequest o) {
  buildCounterCreateServiceAccountRequest++;
  if (buildCounterCreateServiceAccountRequest < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkServiceAccount(o.serviceAccount! as api.ServiceAccount);
  }
  buildCounterCreateServiceAccountRequest--;
}

core.int buildCounterDisableServiceAccountRequest = 0;
api.DisableServiceAccountRequest buildDisableServiceAccountRequest() {
  var o = api.DisableServiceAccountRequest();
  buildCounterDisableServiceAccountRequest++;
  if (buildCounterDisableServiceAccountRequest < 3) {}
  buildCounterDisableServiceAccountRequest--;
  return o;
}

void checkDisableServiceAccountRequest(api.DisableServiceAccountRequest o) {
  buildCounterDisableServiceAccountRequest++;
  if (buildCounterDisableServiceAccountRequest < 3) {}
  buildCounterDisableServiceAccountRequest--;
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

core.int buildCounterEnableServiceAccountRequest = 0;
api.EnableServiceAccountRequest buildEnableServiceAccountRequest() {
  var o = api.EnableServiceAccountRequest();
  buildCounterEnableServiceAccountRequest++;
  if (buildCounterEnableServiceAccountRequest < 3) {}
  buildCounterEnableServiceAccountRequest--;
  return o;
}

void checkEnableServiceAccountRequest(api.EnableServiceAccountRequest o) {
  buildCounterEnableServiceAccountRequest++;
  if (buildCounterEnableServiceAccountRequest < 3) {}
  buildCounterEnableServiceAccountRequest--;
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

core.int buildCounterLintPolicyRequest = 0;
api.LintPolicyRequest buildLintPolicyRequest() {
  var o = api.LintPolicyRequest();
  buildCounterLintPolicyRequest++;
  if (buildCounterLintPolicyRequest < 3) {
    o.condition = buildExpr();
    o.fullResourceName = 'foo';
  }
  buildCounterLintPolicyRequest--;
  return o;
}

void checkLintPolicyRequest(api.LintPolicyRequest o) {
  buildCounterLintPolicyRequest++;
  if (buildCounterLintPolicyRequest < 3) {
    checkExpr(o.condition! as api.Expr);
    unittest.expect(
      o.fullResourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterLintPolicyRequest--;
}

core.List<api.LintResult> buildUnnamed7141() {
  var o = <api.LintResult>[];
  o.add(buildLintResult());
  o.add(buildLintResult());
  return o;
}

void checkUnnamed7141(core.List<api.LintResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLintResult(o[0] as api.LintResult);
  checkLintResult(o[1] as api.LintResult);
}

core.int buildCounterLintPolicyResponse = 0;
api.LintPolicyResponse buildLintPolicyResponse() {
  var o = api.LintPolicyResponse();
  buildCounterLintPolicyResponse++;
  if (buildCounterLintPolicyResponse < 3) {
    o.lintResults = buildUnnamed7141();
  }
  buildCounterLintPolicyResponse--;
  return o;
}

void checkLintPolicyResponse(api.LintPolicyResponse o) {
  buildCounterLintPolicyResponse++;
  if (buildCounterLintPolicyResponse < 3) {
    checkUnnamed7141(o.lintResults!);
  }
  buildCounterLintPolicyResponse--;
}

core.int buildCounterLintResult = 0;
api.LintResult buildLintResult() {
  var o = api.LintResult();
  buildCounterLintResult++;
  if (buildCounterLintResult < 3) {
    o.debugMessage = 'foo';
    o.fieldName = 'foo';
    o.level = 'foo';
    o.locationOffset = 42;
    o.severity = 'foo';
    o.validationUnitName = 'foo';
  }
  buildCounterLintResult--;
  return o;
}

void checkLintResult(api.LintResult o) {
  buildCounterLintResult++;
  if (buildCounterLintResult < 3) {
    unittest.expect(
      o.debugMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.level!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationOffset!,
      unittest.equals(42),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.validationUnitName!,
      unittest.equals('foo'),
    );
  }
  buildCounterLintResult--;
}

core.List<api.Role> buildUnnamed7142() {
  var o = <api.Role>[];
  o.add(buildRole());
  o.add(buildRole());
  return o;
}

void checkUnnamed7142(core.List<api.Role> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRole(o[0] as api.Role);
  checkRole(o[1] as api.Role);
}

core.int buildCounterListRolesResponse = 0;
api.ListRolesResponse buildListRolesResponse() {
  var o = api.ListRolesResponse();
  buildCounterListRolesResponse++;
  if (buildCounterListRolesResponse < 3) {
    o.nextPageToken = 'foo';
    o.roles = buildUnnamed7142();
  }
  buildCounterListRolesResponse--;
  return o;
}

void checkListRolesResponse(api.ListRolesResponse o) {
  buildCounterListRolesResponse++;
  if (buildCounterListRolesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed7142(o.roles!);
  }
  buildCounterListRolesResponse--;
}

core.List<api.ServiceAccountKey> buildUnnamed7143() {
  var o = <api.ServiceAccountKey>[];
  o.add(buildServiceAccountKey());
  o.add(buildServiceAccountKey());
  return o;
}

void checkUnnamed7143(core.List<api.ServiceAccountKey> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkServiceAccountKey(o[0] as api.ServiceAccountKey);
  checkServiceAccountKey(o[1] as api.ServiceAccountKey);
}

core.int buildCounterListServiceAccountKeysResponse = 0;
api.ListServiceAccountKeysResponse buildListServiceAccountKeysResponse() {
  var o = api.ListServiceAccountKeysResponse();
  buildCounterListServiceAccountKeysResponse++;
  if (buildCounterListServiceAccountKeysResponse < 3) {
    o.keys = buildUnnamed7143();
  }
  buildCounterListServiceAccountKeysResponse--;
  return o;
}

void checkListServiceAccountKeysResponse(api.ListServiceAccountKeysResponse o) {
  buildCounterListServiceAccountKeysResponse++;
  if (buildCounterListServiceAccountKeysResponse < 3) {
    checkUnnamed7143(o.keys!);
  }
  buildCounterListServiceAccountKeysResponse--;
}

core.List<api.ServiceAccount> buildUnnamed7144() {
  var o = <api.ServiceAccount>[];
  o.add(buildServiceAccount());
  o.add(buildServiceAccount());
  return o;
}

void checkUnnamed7144(core.List<api.ServiceAccount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkServiceAccount(o[0] as api.ServiceAccount);
  checkServiceAccount(o[1] as api.ServiceAccount);
}

core.int buildCounterListServiceAccountsResponse = 0;
api.ListServiceAccountsResponse buildListServiceAccountsResponse() {
  var o = api.ListServiceAccountsResponse();
  buildCounterListServiceAccountsResponse++;
  if (buildCounterListServiceAccountsResponse < 3) {
    o.accounts = buildUnnamed7144();
    o.nextPageToken = 'foo';
  }
  buildCounterListServiceAccountsResponse--;
  return o;
}

void checkListServiceAccountsResponse(api.ListServiceAccountsResponse o) {
  buildCounterListServiceAccountsResponse++;
  if (buildCounterListServiceAccountsResponse < 3) {
    checkUnnamed7144(o.accounts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListServiceAccountsResponse--;
}

core.List<api.WorkloadIdentityPoolProvider> buildUnnamed7145() {
  var o = <api.WorkloadIdentityPoolProvider>[];
  o.add(buildWorkloadIdentityPoolProvider());
  o.add(buildWorkloadIdentityPoolProvider());
  return o;
}

void checkUnnamed7145(core.List<api.WorkloadIdentityPoolProvider> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWorkloadIdentityPoolProvider(o[0] as api.WorkloadIdentityPoolProvider);
  checkWorkloadIdentityPoolProvider(o[1] as api.WorkloadIdentityPoolProvider);
}

core.int buildCounterListWorkloadIdentityPoolProvidersResponse = 0;
api.ListWorkloadIdentityPoolProvidersResponse
    buildListWorkloadIdentityPoolProvidersResponse() {
  var o = api.ListWorkloadIdentityPoolProvidersResponse();
  buildCounterListWorkloadIdentityPoolProvidersResponse++;
  if (buildCounterListWorkloadIdentityPoolProvidersResponse < 3) {
    o.nextPageToken = 'foo';
    o.workloadIdentityPoolProviders = buildUnnamed7145();
  }
  buildCounterListWorkloadIdentityPoolProvidersResponse--;
  return o;
}

void checkListWorkloadIdentityPoolProvidersResponse(
    api.ListWorkloadIdentityPoolProvidersResponse o) {
  buildCounterListWorkloadIdentityPoolProvidersResponse++;
  if (buildCounterListWorkloadIdentityPoolProvidersResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed7145(o.workloadIdentityPoolProviders!);
  }
  buildCounterListWorkloadIdentityPoolProvidersResponse--;
}

core.List<api.WorkloadIdentityPool> buildUnnamed7146() {
  var o = <api.WorkloadIdentityPool>[];
  o.add(buildWorkloadIdentityPool());
  o.add(buildWorkloadIdentityPool());
  return o;
}

void checkUnnamed7146(core.List<api.WorkloadIdentityPool> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWorkloadIdentityPool(o[0] as api.WorkloadIdentityPool);
  checkWorkloadIdentityPool(o[1] as api.WorkloadIdentityPool);
}

core.int buildCounterListWorkloadIdentityPoolsResponse = 0;
api.ListWorkloadIdentityPoolsResponse buildListWorkloadIdentityPoolsResponse() {
  var o = api.ListWorkloadIdentityPoolsResponse();
  buildCounterListWorkloadIdentityPoolsResponse++;
  if (buildCounterListWorkloadIdentityPoolsResponse < 3) {
    o.nextPageToken = 'foo';
    o.workloadIdentityPools = buildUnnamed7146();
  }
  buildCounterListWorkloadIdentityPoolsResponse--;
  return o;
}

void checkListWorkloadIdentityPoolsResponse(
    api.ListWorkloadIdentityPoolsResponse o) {
  buildCounterListWorkloadIdentityPoolsResponse++;
  if (buildCounterListWorkloadIdentityPoolsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed7146(o.workloadIdentityPools!);
  }
  buildCounterListWorkloadIdentityPoolsResponse--;
}

core.List<core.String> buildUnnamed7147() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7147(core.List<core.String> o) {
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

core.int buildCounterOidc = 0;
api.Oidc buildOidc() {
  var o = api.Oidc();
  buildCounterOidc++;
  if (buildCounterOidc < 3) {
    o.allowedAudiences = buildUnnamed7147();
    o.issuerUri = 'foo';
  }
  buildCounterOidc--;
  return o;
}

void checkOidc(api.Oidc o) {
  buildCounterOidc++;
  if (buildCounterOidc < 3) {
    checkUnnamed7147(o.allowedAudiences!);
    unittest.expect(
      o.issuerUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterOidc--;
}

core.Map<core.String, core.Object> buildUnnamed7148() {
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

void checkUnnamed7148(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed7149() {
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

void checkUnnamed7149(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed7148();
    o.name = 'foo';
    o.response = buildUnnamed7149();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed7148(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed7149(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterPatchServiceAccountRequest = 0;
api.PatchServiceAccountRequest buildPatchServiceAccountRequest() {
  var o = api.PatchServiceAccountRequest();
  buildCounterPatchServiceAccountRequest++;
  if (buildCounterPatchServiceAccountRequest < 3) {
    o.serviceAccount = buildServiceAccount();
    o.updateMask = 'foo';
  }
  buildCounterPatchServiceAccountRequest--;
  return o;
}

void checkPatchServiceAccountRequest(api.PatchServiceAccountRequest o) {
  buildCounterPatchServiceAccountRequest++;
  if (buildCounterPatchServiceAccountRequest < 3) {
    checkServiceAccount(o.serviceAccount! as api.ServiceAccount);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterPatchServiceAccountRequest--;
}

core.int buildCounterPermission = 0;
api.Permission buildPermission() {
  var o = api.Permission();
  buildCounterPermission++;
  if (buildCounterPermission < 3) {
    o.apiDisabled = true;
    o.customRolesSupportLevel = 'foo';
    o.description = 'foo';
    o.name = 'foo';
    o.onlyInPredefinedRoles = true;
    o.primaryPermission = 'foo';
    o.stage = 'foo';
    o.title = 'foo';
  }
  buildCounterPermission--;
  return o;
}

void checkPermission(api.Permission o) {
  buildCounterPermission++;
  if (buildCounterPermission < 3) {
    unittest.expect(o.apiDisabled!, unittest.isTrue);
    unittest.expect(
      o.customRolesSupportLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.onlyInPredefinedRoles!, unittest.isTrue);
    unittest.expect(
      o.primaryPermission!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterPermission--;
}

core.List<core.String> buildUnnamed7150() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7150(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed7151() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7151(core.List<core.String> o) {
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

core.int buildCounterPermissionDelta = 0;
api.PermissionDelta buildPermissionDelta() {
  var o = api.PermissionDelta();
  buildCounterPermissionDelta++;
  if (buildCounterPermissionDelta < 3) {
    o.addedPermissions = buildUnnamed7150();
    o.removedPermissions = buildUnnamed7151();
  }
  buildCounterPermissionDelta--;
  return o;
}

void checkPermissionDelta(api.PermissionDelta o) {
  buildCounterPermissionDelta++;
  if (buildCounterPermissionDelta < 3) {
    checkUnnamed7150(o.addedPermissions!);
    checkUnnamed7151(o.removedPermissions!);
  }
  buildCounterPermissionDelta--;
}

core.List<api.AuditConfig> buildUnnamed7152() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed7152(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed7153() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed7153(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed7152();
    o.bindings = buildUnnamed7153();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed7152(o.auditConfigs!);
    checkUnnamed7153(o.bindings!);
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

core.List<api.BindingDelta> buildUnnamed7154() {
  var o = <api.BindingDelta>[];
  o.add(buildBindingDelta());
  o.add(buildBindingDelta());
  return o;
}

void checkUnnamed7154(core.List<api.BindingDelta> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBindingDelta(o[0] as api.BindingDelta);
  checkBindingDelta(o[1] as api.BindingDelta);
}

core.int buildCounterPolicyDelta = 0;
api.PolicyDelta buildPolicyDelta() {
  var o = api.PolicyDelta();
  buildCounterPolicyDelta++;
  if (buildCounterPolicyDelta < 3) {
    o.bindingDeltas = buildUnnamed7154();
  }
  buildCounterPolicyDelta--;
  return o;
}

void checkPolicyDelta(api.PolicyDelta o) {
  buildCounterPolicyDelta++;
  if (buildCounterPolicyDelta < 3) {
    checkUnnamed7154(o.bindingDeltas!);
  }
  buildCounterPolicyDelta--;
}

core.int buildCounterQueryAuditableServicesRequest = 0;
api.QueryAuditableServicesRequest buildQueryAuditableServicesRequest() {
  var o = api.QueryAuditableServicesRequest();
  buildCounterQueryAuditableServicesRequest++;
  if (buildCounterQueryAuditableServicesRequest < 3) {
    o.fullResourceName = 'foo';
  }
  buildCounterQueryAuditableServicesRequest--;
  return o;
}

void checkQueryAuditableServicesRequest(api.QueryAuditableServicesRequest o) {
  buildCounterQueryAuditableServicesRequest++;
  if (buildCounterQueryAuditableServicesRequest < 3) {
    unittest.expect(
      o.fullResourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryAuditableServicesRequest--;
}

core.List<api.AuditableService> buildUnnamed7155() {
  var o = <api.AuditableService>[];
  o.add(buildAuditableService());
  o.add(buildAuditableService());
  return o;
}

void checkUnnamed7155(core.List<api.AuditableService> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditableService(o[0] as api.AuditableService);
  checkAuditableService(o[1] as api.AuditableService);
}

core.int buildCounterQueryAuditableServicesResponse = 0;
api.QueryAuditableServicesResponse buildQueryAuditableServicesResponse() {
  var o = api.QueryAuditableServicesResponse();
  buildCounterQueryAuditableServicesResponse++;
  if (buildCounterQueryAuditableServicesResponse < 3) {
    o.services = buildUnnamed7155();
  }
  buildCounterQueryAuditableServicesResponse--;
  return o;
}

void checkQueryAuditableServicesResponse(api.QueryAuditableServicesResponse o) {
  buildCounterQueryAuditableServicesResponse++;
  if (buildCounterQueryAuditableServicesResponse < 3) {
    checkUnnamed7155(o.services!);
  }
  buildCounterQueryAuditableServicesResponse--;
}

core.int buildCounterQueryGrantableRolesRequest = 0;
api.QueryGrantableRolesRequest buildQueryGrantableRolesRequest() {
  var o = api.QueryGrantableRolesRequest();
  buildCounterQueryGrantableRolesRequest++;
  if (buildCounterQueryGrantableRolesRequest < 3) {
    o.fullResourceName = 'foo';
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.view = 'foo';
  }
  buildCounterQueryGrantableRolesRequest--;
  return o;
}

void checkQueryGrantableRolesRequest(api.QueryGrantableRolesRequest o) {
  buildCounterQueryGrantableRolesRequest++;
  if (buildCounterQueryGrantableRolesRequest < 3) {
    unittest.expect(
      o.fullResourceName!,
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
    unittest.expect(
      o.view!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryGrantableRolesRequest--;
}

core.List<api.Role> buildUnnamed7156() {
  var o = <api.Role>[];
  o.add(buildRole());
  o.add(buildRole());
  return o;
}

void checkUnnamed7156(core.List<api.Role> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRole(o[0] as api.Role);
  checkRole(o[1] as api.Role);
}

core.int buildCounterQueryGrantableRolesResponse = 0;
api.QueryGrantableRolesResponse buildQueryGrantableRolesResponse() {
  var o = api.QueryGrantableRolesResponse();
  buildCounterQueryGrantableRolesResponse++;
  if (buildCounterQueryGrantableRolesResponse < 3) {
    o.nextPageToken = 'foo';
    o.roles = buildUnnamed7156();
  }
  buildCounterQueryGrantableRolesResponse--;
  return o;
}

void checkQueryGrantableRolesResponse(api.QueryGrantableRolesResponse o) {
  buildCounterQueryGrantableRolesResponse++;
  if (buildCounterQueryGrantableRolesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed7156(o.roles!);
  }
  buildCounterQueryGrantableRolesResponse--;
}

core.int buildCounterQueryTestablePermissionsRequest = 0;
api.QueryTestablePermissionsRequest buildQueryTestablePermissionsRequest() {
  var o = api.QueryTestablePermissionsRequest();
  buildCounterQueryTestablePermissionsRequest++;
  if (buildCounterQueryTestablePermissionsRequest < 3) {
    o.fullResourceName = 'foo';
    o.pageSize = 42;
    o.pageToken = 'foo';
  }
  buildCounterQueryTestablePermissionsRequest--;
  return o;
}

void checkQueryTestablePermissionsRequest(
    api.QueryTestablePermissionsRequest o) {
  buildCounterQueryTestablePermissionsRequest++;
  if (buildCounterQueryTestablePermissionsRequest < 3) {
    unittest.expect(
      o.fullResourceName!,
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
  buildCounterQueryTestablePermissionsRequest--;
}

core.List<api.Permission> buildUnnamed7157() {
  var o = <api.Permission>[];
  o.add(buildPermission());
  o.add(buildPermission());
  return o;
}

void checkUnnamed7157(core.List<api.Permission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPermission(o[0] as api.Permission);
  checkPermission(o[1] as api.Permission);
}

core.int buildCounterQueryTestablePermissionsResponse = 0;
api.QueryTestablePermissionsResponse buildQueryTestablePermissionsResponse() {
  var o = api.QueryTestablePermissionsResponse();
  buildCounterQueryTestablePermissionsResponse++;
  if (buildCounterQueryTestablePermissionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.permissions = buildUnnamed7157();
  }
  buildCounterQueryTestablePermissionsResponse--;
  return o;
}

void checkQueryTestablePermissionsResponse(
    api.QueryTestablePermissionsResponse o) {
  buildCounterQueryTestablePermissionsResponse++;
  if (buildCounterQueryTestablePermissionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed7157(o.permissions!);
  }
  buildCounterQueryTestablePermissionsResponse--;
}

core.List<core.String> buildUnnamed7158() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7158(core.List<core.String> o) {
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

core.int buildCounterRole = 0;
api.Role buildRole() {
  var o = api.Role();
  buildCounterRole++;
  if (buildCounterRole < 3) {
    o.deleted = true;
    o.description = 'foo';
    o.etag = 'foo';
    o.includedPermissions = buildUnnamed7158();
    o.name = 'foo';
    o.stage = 'foo';
    o.title = 'foo';
  }
  buildCounterRole--;
  return o;
}

void checkRole(api.Role o) {
  buildCounterRole++;
  if (buildCounterRole < 3) {
    unittest.expect(o.deleted!, unittest.isTrue);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed7158(o.includedPermissions!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterRole--;
}

core.int buildCounterServiceAccount = 0;
api.ServiceAccount buildServiceAccount() {
  var o = api.ServiceAccount();
  buildCounterServiceAccount++;
  if (buildCounterServiceAccount < 3) {
    o.description = 'foo';
    o.disabled = true;
    o.displayName = 'foo';
    o.email = 'foo';
    o.etag = 'foo';
    o.name = 'foo';
    o.oauth2ClientId = 'foo';
    o.projectId = 'foo';
    o.uniqueId = 'foo';
  }
  buildCounterServiceAccount--;
  return o;
}

void checkServiceAccount(api.ServiceAccount o) {
  buildCounterServiceAccount++;
  if (buildCounterServiceAccount < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
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
      o.oauth2ClientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uniqueId!,
      unittest.equals('foo'),
    );
  }
  buildCounterServiceAccount--;
}

core.int buildCounterServiceAccountKey = 0;
api.ServiceAccountKey buildServiceAccountKey() {
  var o = api.ServiceAccountKey();
  buildCounterServiceAccountKey++;
  if (buildCounterServiceAccountKey < 3) {
    o.keyAlgorithm = 'foo';
    o.keyOrigin = 'foo';
    o.keyType = 'foo';
    o.name = 'foo';
    o.privateKeyData = 'foo';
    o.privateKeyType = 'foo';
    o.publicKeyData = 'foo';
    o.validAfterTime = 'foo';
    o.validBeforeTime = 'foo';
  }
  buildCounterServiceAccountKey--;
  return o;
}

void checkServiceAccountKey(api.ServiceAccountKey o) {
  buildCounterServiceAccountKey++;
  if (buildCounterServiceAccountKey < 3) {
    unittest.expect(
      o.keyAlgorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.keyOrigin!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.keyType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.privateKeyData!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.privateKeyType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publicKeyData!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.validAfterTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.validBeforeTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterServiceAccountKey--;
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

core.int buildCounterSignBlobRequest = 0;
api.SignBlobRequest buildSignBlobRequest() {
  var o = api.SignBlobRequest();
  buildCounterSignBlobRequest++;
  if (buildCounterSignBlobRequest < 3) {
    o.bytesToSign = 'foo';
  }
  buildCounterSignBlobRequest--;
  return o;
}

void checkSignBlobRequest(api.SignBlobRequest o) {
  buildCounterSignBlobRequest++;
  if (buildCounterSignBlobRequest < 3) {
    unittest.expect(
      o.bytesToSign!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignBlobRequest--;
}

core.int buildCounterSignBlobResponse = 0;
api.SignBlobResponse buildSignBlobResponse() {
  var o = api.SignBlobResponse();
  buildCounterSignBlobResponse++;
  if (buildCounterSignBlobResponse < 3) {
    o.keyId = 'foo';
    o.signature = 'foo';
  }
  buildCounterSignBlobResponse--;
  return o;
}

void checkSignBlobResponse(api.SignBlobResponse o) {
  buildCounterSignBlobResponse++;
  if (buildCounterSignBlobResponse < 3) {
    unittest.expect(
      o.keyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signature!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignBlobResponse--;
}

core.int buildCounterSignJwtRequest = 0;
api.SignJwtRequest buildSignJwtRequest() {
  var o = api.SignJwtRequest();
  buildCounterSignJwtRequest++;
  if (buildCounterSignJwtRequest < 3) {
    o.payload = 'foo';
  }
  buildCounterSignJwtRequest--;
  return o;
}

void checkSignJwtRequest(api.SignJwtRequest o) {
  buildCounterSignJwtRequest++;
  if (buildCounterSignJwtRequest < 3) {
    unittest.expect(
      o.payload!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignJwtRequest--;
}

core.int buildCounterSignJwtResponse = 0;
api.SignJwtResponse buildSignJwtResponse() {
  var o = api.SignJwtResponse();
  buildCounterSignJwtResponse++;
  if (buildCounterSignJwtResponse < 3) {
    o.keyId = 'foo';
    o.signedJwt = 'foo';
  }
  buildCounterSignJwtResponse--;
  return o;
}

void checkSignJwtResponse(api.SignJwtResponse o) {
  buildCounterSignJwtResponse++;
  if (buildCounterSignJwtResponse < 3) {
    unittest.expect(
      o.keyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signedJwt!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignJwtResponse--;
}

core.Map<core.String, core.Object> buildUnnamed7159() {
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

void checkUnnamed7159(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed7160() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed7159());
  o.add(buildUnnamed7159());
  return o;
}

void checkUnnamed7160(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed7159(o[0]);
  checkUnnamed7159(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed7160();
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
    checkUnnamed7160(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<core.String> buildUnnamed7161() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7161(core.List<core.String> o) {
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
    o.permissions = buildUnnamed7161();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed7161(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed7162() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7162(core.List<core.String> o) {
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
    o.permissions = buildUnnamed7162();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed7162(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterUndeleteRoleRequest = 0;
api.UndeleteRoleRequest buildUndeleteRoleRequest() {
  var o = api.UndeleteRoleRequest();
  buildCounterUndeleteRoleRequest++;
  if (buildCounterUndeleteRoleRequest < 3) {
    o.etag = 'foo';
  }
  buildCounterUndeleteRoleRequest--;
  return o;
}

void checkUndeleteRoleRequest(api.UndeleteRoleRequest o) {
  buildCounterUndeleteRoleRequest++;
  if (buildCounterUndeleteRoleRequest < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
  }
  buildCounterUndeleteRoleRequest--;
}

core.int buildCounterUndeleteServiceAccountRequest = 0;
api.UndeleteServiceAccountRequest buildUndeleteServiceAccountRequest() {
  var o = api.UndeleteServiceAccountRequest();
  buildCounterUndeleteServiceAccountRequest++;
  if (buildCounterUndeleteServiceAccountRequest < 3) {}
  buildCounterUndeleteServiceAccountRequest--;
  return o;
}

void checkUndeleteServiceAccountRequest(api.UndeleteServiceAccountRequest o) {
  buildCounterUndeleteServiceAccountRequest++;
  if (buildCounterUndeleteServiceAccountRequest < 3) {}
  buildCounterUndeleteServiceAccountRequest--;
}

core.int buildCounterUndeleteServiceAccountResponse = 0;
api.UndeleteServiceAccountResponse buildUndeleteServiceAccountResponse() {
  var o = api.UndeleteServiceAccountResponse();
  buildCounterUndeleteServiceAccountResponse++;
  if (buildCounterUndeleteServiceAccountResponse < 3) {
    o.restoredAccount = buildServiceAccount();
  }
  buildCounterUndeleteServiceAccountResponse--;
  return o;
}

void checkUndeleteServiceAccountResponse(api.UndeleteServiceAccountResponse o) {
  buildCounterUndeleteServiceAccountResponse++;
  if (buildCounterUndeleteServiceAccountResponse < 3) {
    checkServiceAccount(o.restoredAccount! as api.ServiceAccount);
  }
  buildCounterUndeleteServiceAccountResponse--;
}

core.int buildCounterUndeleteWorkloadIdentityPoolProviderRequest = 0;
api.UndeleteWorkloadIdentityPoolProviderRequest
    buildUndeleteWorkloadIdentityPoolProviderRequest() {
  var o = api.UndeleteWorkloadIdentityPoolProviderRequest();
  buildCounterUndeleteWorkloadIdentityPoolProviderRequest++;
  if (buildCounterUndeleteWorkloadIdentityPoolProviderRequest < 3) {}
  buildCounterUndeleteWorkloadIdentityPoolProviderRequest--;
  return o;
}

void checkUndeleteWorkloadIdentityPoolProviderRequest(
    api.UndeleteWorkloadIdentityPoolProviderRequest o) {
  buildCounterUndeleteWorkloadIdentityPoolProviderRequest++;
  if (buildCounterUndeleteWorkloadIdentityPoolProviderRequest < 3) {}
  buildCounterUndeleteWorkloadIdentityPoolProviderRequest--;
}

core.int buildCounterUndeleteWorkloadIdentityPoolRequest = 0;
api.UndeleteWorkloadIdentityPoolRequest
    buildUndeleteWorkloadIdentityPoolRequest() {
  var o = api.UndeleteWorkloadIdentityPoolRequest();
  buildCounterUndeleteWorkloadIdentityPoolRequest++;
  if (buildCounterUndeleteWorkloadIdentityPoolRequest < 3) {}
  buildCounterUndeleteWorkloadIdentityPoolRequest--;
  return o;
}

void checkUndeleteWorkloadIdentityPoolRequest(
    api.UndeleteWorkloadIdentityPoolRequest o) {
  buildCounterUndeleteWorkloadIdentityPoolRequest++;
  if (buildCounterUndeleteWorkloadIdentityPoolRequest < 3) {}
  buildCounterUndeleteWorkloadIdentityPoolRequest--;
}

core.int buildCounterUploadServiceAccountKeyRequest = 0;
api.UploadServiceAccountKeyRequest buildUploadServiceAccountKeyRequest() {
  var o = api.UploadServiceAccountKeyRequest();
  buildCounterUploadServiceAccountKeyRequest++;
  if (buildCounterUploadServiceAccountKeyRequest < 3) {
    o.publicKeyData = 'foo';
  }
  buildCounterUploadServiceAccountKeyRequest--;
  return o;
}

void checkUploadServiceAccountKeyRequest(api.UploadServiceAccountKeyRequest o) {
  buildCounterUploadServiceAccountKeyRequest++;
  if (buildCounterUploadServiceAccountKeyRequest < 3) {
    unittest.expect(
      o.publicKeyData!,
      unittest.equals('foo'),
    );
  }
  buildCounterUploadServiceAccountKeyRequest--;
}

core.int buildCounterWorkloadIdentityPool = 0;
api.WorkloadIdentityPool buildWorkloadIdentityPool() {
  var o = api.WorkloadIdentityPool();
  buildCounterWorkloadIdentityPool++;
  if (buildCounterWorkloadIdentityPool < 3) {
    o.description = 'foo';
    o.disabled = true;
    o.displayName = 'foo';
    o.name = 'foo';
    o.state = 'foo';
  }
  buildCounterWorkloadIdentityPool--;
  return o;
}

void checkWorkloadIdentityPool(api.WorkloadIdentityPool o) {
  buildCounterWorkloadIdentityPool++;
  if (buildCounterWorkloadIdentityPool < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
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
  buildCounterWorkloadIdentityPool--;
}

core.Map<core.String, core.String> buildUnnamed7163() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed7163(core.Map<core.String, core.String> o) {
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

core.int buildCounterWorkloadIdentityPoolProvider = 0;
api.WorkloadIdentityPoolProvider buildWorkloadIdentityPoolProvider() {
  var o = api.WorkloadIdentityPoolProvider();
  buildCounterWorkloadIdentityPoolProvider++;
  if (buildCounterWorkloadIdentityPoolProvider < 3) {
    o.attributeCondition = 'foo';
    o.attributeMapping = buildUnnamed7163();
    o.aws = buildAws();
    o.description = 'foo';
    o.disabled = true;
    o.displayName = 'foo';
    o.name = 'foo';
    o.oidc = buildOidc();
    o.state = 'foo';
  }
  buildCounterWorkloadIdentityPoolProvider--;
  return o;
}

void checkWorkloadIdentityPoolProvider(api.WorkloadIdentityPoolProvider o) {
  buildCounterWorkloadIdentityPoolProvider++;
  if (buildCounterWorkloadIdentityPoolProvider < 3) {
    unittest.expect(
      o.attributeCondition!,
      unittest.equals('foo'),
    );
    checkUnnamed7163(o.attributeMapping!);
    checkAws(o.aws! as api.Aws);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOidc(o.oidc! as api.Oidc);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterWorkloadIdentityPoolProvider--;
}

core.List<core.String> buildUnnamed7164() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7164(core.List<core.String> o) {
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
  unittest.group('obj-schema-AdminAuditData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdminAuditData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdminAuditData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdminAuditData(od as api.AdminAuditData);
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

  unittest.group('obj-schema-AuditData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AuditData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAuditData(od as api.AuditData);
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

  unittest.group('obj-schema-AuditableService', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditableService();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditableService.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditableService(od as api.AuditableService);
    });
  });

  unittest.group('obj-schema-Aws', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAws();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Aws.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAws(od as api.Aws);
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

  unittest.group('obj-schema-BindingDelta', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBindingDelta();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BindingDelta.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBindingDelta(od as api.BindingDelta);
    });
  });

  unittest.group('obj-schema-CreateRoleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateRoleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateRoleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateRoleRequest(od as api.CreateRoleRequest);
    });
  });

  unittest.group('obj-schema-CreateServiceAccountKeyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateServiceAccountKeyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateServiceAccountKeyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateServiceAccountKeyRequest(
          od as api.CreateServiceAccountKeyRequest);
    });
  });

  unittest.group('obj-schema-CreateServiceAccountRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateServiceAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateServiceAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateServiceAccountRequest(od as api.CreateServiceAccountRequest);
    });
  });

  unittest.group('obj-schema-DisableServiceAccountRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDisableServiceAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DisableServiceAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDisableServiceAccountRequest(od as api.DisableServiceAccountRequest);
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

  unittest.group('obj-schema-EnableServiceAccountRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnableServiceAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnableServiceAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnableServiceAccountRequest(od as api.EnableServiceAccountRequest);
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

  unittest.group('obj-schema-LintPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLintPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LintPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLintPolicyRequest(od as api.LintPolicyRequest);
    });
  });

  unittest.group('obj-schema-LintPolicyResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLintPolicyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LintPolicyResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLintPolicyResponse(od as api.LintPolicyResponse);
    });
  });

  unittest.group('obj-schema-LintResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLintResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LintResult.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLintResult(od as api.LintResult);
    });
  });

  unittest.group('obj-schema-ListRolesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListRolesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListRolesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListRolesResponse(od as api.ListRolesResponse);
    });
  });

  unittest.group('obj-schema-ListServiceAccountKeysResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListServiceAccountKeysResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListServiceAccountKeysResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListServiceAccountKeysResponse(
          od as api.ListServiceAccountKeysResponse);
    });
  });

  unittest.group('obj-schema-ListServiceAccountsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListServiceAccountsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListServiceAccountsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListServiceAccountsResponse(od as api.ListServiceAccountsResponse);
    });
  });

  unittest.group('obj-schema-ListWorkloadIdentityPoolProvidersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListWorkloadIdentityPoolProvidersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListWorkloadIdentityPoolProvidersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListWorkloadIdentityPoolProvidersResponse(
          od as api.ListWorkloadIdentityPoolProvidersResponse);
    });
  });

  unittest.group('obj-schema-ListWorkloadIdentityPoolsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListWorkloadIdentityPoolsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListWorkloadIdentityPoolsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListWorkloadIdentityPoolsResponse(
          od as api.ListWorkloadIdentityPoolsResponse);
    });
  });

  unittest.group('obj-schema-Oidc', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOidc();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Oidc.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOidc(od as api.Oidc);
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

  unittest.group('obj-schema-PatchServiceAccountRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatchServiceAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PatchServiceAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPatchServiceAccountRequest(od as api.PatchServiceAccountRequest);
    });
  });

  unittest.group('obj-schema-Permission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPermission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Permission.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPermission(od as api.Permission);
    });
  });

  unittest.group('obj-schema-PermissionDelta', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPermissionDelta();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PermissionDelta.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPermissionDelta(od as api.PermissionDelta);
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

  unittest.group('obj-schema-PolicyDelta', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicyDelta();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PolicyDelta.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPolicyDelta(od as api.PolicyDelta);
    });
  });

  unittest.group('obj-schema-QueryAuditableServicesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryAuditableServicesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryAuditableServicesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryAuditableServicesRequest(
          od as api.QueryAuditableServicesRequest);
    });
  });

  unittest.group('obj-schema-QueryAuditableServicesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryAuditableServicesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryAuditableServicesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryAuditableServicesResponse(
          od as api.QueryAuditableServicesResponse);
    });
  });

  unittest.group('obj-schema-QueryGrantableRolesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryGrantableRolesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryGrantableRolesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryGrantableRolesRequest(od as api.QueryGrantableRolesRequest);
    });
  });

  unittest.group('obj-schema-QueryGrantableRolesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryGrantableRolesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryGrantableRolesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryGrantableRolesResponse(od as api.QueryGrantableRolesResponse);
    });
  });

  unittest.group('obj-schema-QueryTestablePermissionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryTestablePermissionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryTestablePermissionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryTestablePermissionsRequest(
          od as api.QueryTestablePermissionsRequest);
    });
  });

  unittest.group('obj-schema-QueryTestablePermissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryTestablePermissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryTestablePermissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryTestablePermissionsResponse(
          od as api.QueryTestablePermissionsResponse);
    });
  });

  unittest.group('obj-schema-Role', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRole();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Role.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRole(od as api.Role);
    });
  });

  unittest.group('obj-schema-ServiceAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildServiceAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ServiceAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkServiceAccount(od as api.ServiceAccount);
    });
  });

  unittest.group('obj-schema-ServiceAccountKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildServiceAccountKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ServiceAccountKey.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkServiceAccountKey(od as api.ServiceAccountKey);
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

  unittest.group('obj-schema-SignBlobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSignBlobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SignBlobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSignBlobRequest(od as api.SignBlobRequest);
    });
  });

  unittest.group('obj-schema-SignBlobResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSignBlobResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SignBlobResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSignBlobResponse(od as api.SignBlobResponse);
    });
  });

  unittest.group('obj-schema-SignJwtRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSignJwtRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SignJwtRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSignJwtRequest(od as api.SignJwtRequest);
    });
  });

  unittest.group('obj-schema-SignJwtResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSignJwtResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SignJwtResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSignJwtResponse(od as api.SignJwtResponse);
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

  unittest.group('obj-schema-UndeleteRoleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteRoleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteRoleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteRoleRequest(od as api.UndeleteRoleRequest);
    });
  });

  unittest.group('obj-schema-UndeleteServiceAccountRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteServiceAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteServiceAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteServiceAccountRequest(
          od as api.UndeleteServiceAccountRequest);
    });
  });

  unittest.group('obj-schema-UndeleteServiceAccountResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteServiceAccountResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteServiceAccountResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteServiceAccountResponse(
          od as api.UndeleteServiceAccountResponse);
    });
  });

  unittest.group('obj-schema-UndeleteWorkloadIdentityPoolProviderRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteWorkloadIdentityPoolProviderRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteWorkloadIdentityPoolProviderRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteWorkloadIdentityPoolProviderRequest(
          od as api.UndeleteWorkloadIdentityPoolProviderRequest);
    });
  });

  unittest.group('obj-schema-UndeleteWorkloadIdentityPoolRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUndeleteWorkloadIdentityPoolRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UndeleteWorkloadIdentityPoolRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUndeleteWorkloadIdentityPoolRequest(
          od as api.UndeleteWorkloadIdentityPoolRequest);
    });
  });

  unittest.group('obj-schema-UploadServiceAccountKeyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUploadServiceAccountKeyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UploadServiceAccountKeyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUploadServiceAccountKeyRequest(
          od as api.UploadServiceAccountKeyRequest);
    });
  });

  unittest.group('obj-schema-WorkloadIdentityPool', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWorkloadIdentityPool();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WorkloadIdentityPool.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWorkloadIdentityPool(od as api.WorkloadIdentityPool);
    });
  });

  unittest.group('obj-schema-WorkloadIdentityPoolProvider', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWorkloadIdentityPoolProvider();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WorkloadIdentityPoolProvider.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWorkloadIdentityPoolProvider(od as api.WorkloadIdentityPoolProvider);
    });
  });

  unittest.group('resource-IamPoliciesResource', () {
    unittest.test('method--lintPolicy', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).iamPolicies;
      var arg_request = buildLintPolicyRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LintPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLintPolicyRequest(obj as api.LintPolicyRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("v1/iamPolicies:lintPolicy"),
        );
        pathOffset += 25;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildLintPolicyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.lintPolicy(arg_request, $fields: arg_$fields);
      checkLintPolicyResponse(response as api.LintPolicyResponse);
    });

    unittest.test('method--queryAuditableServices', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).iamPolicies;
      var arg_request = buildQueryAuditableServicesRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.QueryAuditableServicesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkQueryAuditableServicesRequest(
            obj as api.QueryAuditableServicesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 37),
          unittest.equals("v1/iamPolicies:queryAuditableServices"),
        );
        pathOffset += 37;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildQueryAuditableServicesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.queryAuditableServices(arg_request, $fields: arg_$fields);
      checkQueryAuditableServicesResponse(
          response as api.QueryAuditableServicesResponse);
    });
  });

  unittest.group('resource-OrganizationsRolesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).organizations.roles;
      var arg_request = buildCreateRoleRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateRoleRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateRoleRequest(obj as api.CreateRoleRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).organizations.roles;
      var arg_name = 'foo';
      var arg_etag = 'foo';
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
          queryMap["etag"]!.first,
          unittest.equals(arg_etag),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_name, etag: arg_etag, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).organizations.roles;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).organizations.roles;
      var arg_parent = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_showDeleted = true;
      var arg_view = 'foo';
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
          queryMap["showDeleted"]!.first,
          unittest.equals("$arg_showDeleted"),
        );
        unittest.expect(
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListRolesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          showDeleted: arg_showDeleted,
          view: arg_view,
          $fields: arg_$fields);
      checkListRolesResponse(response as api.ListRolesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).organizations.roles;
      var arg_request = buildRole();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Role.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRole(obj as api.Role);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).organizations.roles;
      var arg_request = buildUndeleteRoleRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UndeleteRoleRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUndeleteRoleRequest(obj as api.UndeleteRoleRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkRole(response as api.Role);
    });
  });

  unittest.group('resource-PermissionsResource', () {
    unittest.test('method--queryTestablePermissions', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).permissions;
      var arg_request = buildQueryTestablePermissionsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.QueryTestablePermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkQueryTestablePermissionsRequest(
            obj as api.QueryTestablePermissionsRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 39),
          unittest.equals("v1/permissions:queryTestablePermissions"),
        );
        pathOffset += 39;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildQueryTestablePermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.queryTestablePermissions(arg_request, $fields: arg_$fields);
      checkQueryTestablePermissionsResponse(
          response as api.QueryTestablePermissionsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsWorkloadIdentityPoolsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.locations.workloadIdentityPools;
      var arg_request = buildWorkloadIdentityPool();
      var arg_parent = 'foo';
      var arg_workloadIdentityPoolId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.WorkloadIdentityPool.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWorkloadIdentityPool(obj as api.WorkloadIdentityPool);

        var path = (req.url).path;
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
          queryMap["workloadIdentityPoolId"]!.first,
          unittest.equals(arg_workloadIdentityPoolId),
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
          workloadIdentityPoolId: arg_workloadIdentityPoolId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.locations.workloadIdentityPools;
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
      var res = api.IamApi(mock).projects.locations.workloadIdentityPools;
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
        var resp = convert.json.encode(buildWorkloadIdentityPool());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkWorkloadIdentityPool(response as api.WorkloadIdentityPool);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.locations.workloadIdentityPools;
      var arg_parent = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
        var resp =
            convert.json.encode(buildListWorkloadIdentityPoolsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          showDeleted: arg_showDeleted,
          $fields: arg_$fields);
      checkListWorkloadIdentityPoolsResponse(
          response as api.ListWorkloadIdentityPoolsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.locations.workloadIdentityPools;
      var arg_request = buildWorkloadIdentityPool();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.WorkloadIdentityPool.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWorkloadIdentityPool(obj as api.WorkloadIdentityPool);

        var path = (req.url).path;
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

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.locations.workloadIdentityPools;
      var arg_request = buildUndeleteWorkloadIdentityPoolRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UndeleteWorkloadIdentityPoolRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUndeleteWorkloadIdentityPoolRequest(
            obj as api.UndeleteWorkloadIdentityPoolRequest);

        var path = (req.url).path;
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
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsWorkloadIdentityPoolsOperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.IamApi(mock).projects.locations.workloadIdentityPools.operations;
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

  unittest.group(
      'resource-ProjectsLocationsWorkloadIdentityPoolsProvidersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.IamApi(mock).projects.locations.workloadIdentityPools.providers;
      var arg_request = buildWorkloadIdentityPoolProvider();
      var arg_parent = 'foo';
      var arg_workloadIdentityPoolProviderId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.WorkloadIdentityPoolProvider.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWorkloadIdentityPoolProvider(
            obj as api.WorkloadIdentityPoolProvider);

        var path = (req.url).path;
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
          queryMap["workloadIdentityPoolProviderId"]!.first,
          unittest.equals(arg_workloadIdentityPoolProviderId),
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
          workloadIdentityPoolProviderId: arg_workloadIdentityPoolProviderId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.IamApi(mock).projects.locations.workloadIdentityPools.providers;
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
          api.IamApi(mock).projects.locations.workloadIdentityPools.providers;
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
        var resp = convert.json.encode(buildWorkloadIdentityPoolProvider());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkWorkloadIdentityPoolProvider(
          response as api.WorkloadIdentityPoolProvider);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.IamApi(mock).projects.locations.workloadIdentityPools.providers;
      var arg_parent = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
        var resp = convert.json
            .encode(buildListWorkloadIdentityPoolProvidersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          showDeleted: arg_showDeleted,
          $fields: arg_$fields);
      checkListWorkloadIdentityPoolProvidersResponse(
          response as api.ListWorkloadIdentityPoolProvidersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.IamApi(mock).projects.locations.workloadIdentityPools.providers;
      var arg_request = buildWorkloadIdentityPoolProvider();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.WorkloadIdentityPoolProvider.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWorkloadIdentityPoolProvider(
            obj as api.WorkloadIdentityPoolProvider);

        var path = (req.url).path;
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

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res =
          api.IamApi(mock).projects.locations.workloadIdentityPools.providers;
      var arg_request = buildUndeleteWorkloadIdentityPoolProviderRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UndeleteWorkloadIdentityPoolProviderRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUndeleteWorkloadIdentityPoolProviderRequest(
            obj as api.UndeleteWorkloadIdentityPoolProviderRequest);

        var path = (req.url).path;
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
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsWorkloadIdentityPoolsProvidersOperationsResource',
      () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock)
          .projects
          .locations
          .workloadIdentityPools
          .providers
          .operations;
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

  unittest.group('resource-ProjectsRolesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.roles;
      var arg_request = buildCreateRoleRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateRoleRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateRoleRequest(obj as api.CreateRoleRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.roles;
      var arg_name = 'foo';
      var arg_etag = 'foo';
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
          queryMap["etag"]!.first,
          unittest.equals(arg_etag),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_name, etag: arg_etag, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.roles;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.roles;
      var arg_parent = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_showDeleted = true;
      var arg_view = 'foo';
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
          queryMap["showDeleted"]!.first,
          unittest.equals("$arg_showDeleted"),
        );
        unittest.expect(
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListRolesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          showDeleted: arg_showDeleted,
          view: arg_view,
          $fields: arg_$fields);
      checkListRolesResponse(response as api.ListRolesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.roles;
      var arg_request = buildRole();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Role.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRole(obj as api.Role);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.roles;
      var arg_request = buildUndeleteRoleRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UndeleteRoleRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUndeleteRoleRequest(obj as api.UndeleteRoleRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkRole(response as api.Role);
    });
  });

  unittest.group('resource-ProjectsServiceAccountsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildCreateServiceAccountRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateServiceAccountRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateServiceAccountRequest(
            obj as api.CreateServiceAccountRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildServiceAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_name, $fields: arg_$fields);
      checkServiceAccount(response as api.ServiceAccount);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
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

    unittest.test('method--disable', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildDisableServiceAccountRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DisableServiceAccountRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDisableServiceAccountRequest(
            obj as api.DisableServiceAccountRequest);

        var path = (req.url).path;
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
          await res.disable(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--enable', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildEnableServiceAccountRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EnableServiceAccountRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEnableServiceAccountRequest(
            obj as api.EnableServiceAccountRequest);

        var path = (req.url).path;
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
          await res.enable(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
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
        var resp = convert.json.encode(buildServiceAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkServiceAccount(response as api.ServiceAccount);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
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

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildListServiceAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListServiceAccountsResponse(
          response as api.ListServiceAccountsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildPatchServiceAccountRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PatchServiceAccountRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPatchServiceAccountRequest(obj as api.PatchServiceAccountRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildServiceAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkServiceAccount(response as api.ServiceAccount);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
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

    unittest.test('method--signBlob', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildSignBlobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SignBlobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSignBlobRequest(obj as api.SignBlobRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSignBlobResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.signBlob(arg_request, arg_name, $fields: arg_$fields);
      checkSignBlobResponse(response as api.SignBlobResponse);
    });

    unittest.test('method--signJwt', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildSignJwtRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SignJwtRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSignJwtRequest(obj as api.SignJwtRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSignJwtResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.signJwt(arg_request, arg_name, $fields: arg_$fields);
      checkSignJwtResponse(response as api.SignJwtResponse);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
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

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildUndeleteServiceAccountRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UndeleteServiceAccountRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUndeleteServiceAccountRequest(
            obj as api.UndeleteServiceAccountRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildUndeleteServiceAccountResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkUndeleteServiceAccountResponse(
          response as api.UndeleteServiceAccountResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts;
      var arg_request = buildServiceAccount();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ServiceAccount.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkServiceAccount(obj as api.ServiceAccount);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildServiceAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_name, $fields: arg_$fields);
      checkServiceAccount(response as api.ServiceAccount);
    });
  });

  unittest.group('resource-ProjectsServiceAccountsKeysResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts.keys;
      var arg_request = buildCreateServiceAccountKeyRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateServiceAccountKeyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateServiceAccountKeyRequest(
            obj as api.CreateServiceAccountKeyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildServiceAccountKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_name, $fields: arg_$fields);
      checkServiceAccountKey(response as api.ServiceAccountKey);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts.keys;
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
      var res = api.IamApi(mock).projects.serviceAccounts.keys;
      var arg_name = 'foo';
      var arg_publicKeyType = 'foo';
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
          queryMap["publicKeyType"]!.first,
          unittest.equals(arg_publicKeyType),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildServiceAccountKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          publicKeyType: arg_publicKeyType, $fields: arg_$fields);
      checkServiceAccountKey(response as api.ServiceAccountKey);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts.keys;
      var arg_name = 'foo';
      var arg_keyTypes = buildUnnamed7164();
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
          queryMap["keyTypes"]!,
          unittest.equals(arg_keyTypes),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListServiceAccountKeysResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          keyTypes: arg_keyTypes, $fields: arg_$fields);
      checkListServiceAccountKeysResponse(
          response as api.ListServiceAccountKeysResponse);
    });

    unittest.test('method--upload', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).projects.serviceAccounts.keys;
      var arg_request = buildUploadServiceAccountKeyRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UploadServiceAccountKeyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUploadServiceAccountKeyRequest(
            obj as api.UploadServiceAccountKeyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildServiceAccountKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.upload(arg_request, arg_name, $fields: arg_$fields);
      checkServiceAccountKey(response as api.ServiceAccountKey);
    });
  });

  unittest.group('resource-RolesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).roles;
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).roles;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_parent = 'foo';
      var arg_showDeleted = true;
      var arg_view = 'foo';
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
          unittest.equals("v1/roles"),
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
          queryMap["showDeleted"]!.first,
          unittest.equals("$arg_showDeleted"),
        );
        unittest.expect(
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListRolesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          showDeleted: arg_showDeleted,
          view: arg_view,
          $fields: arg_$fields);
      checkListRolesResponse(response as api.ListRolesResponse);
    });

    unittest.test('method--queryGrantableRoles', () async {
      var mock = HttpServerMock();
      var res = api.IamApi(mock).roles;
      var arg_request = buildQueryGrantableRolesRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.QueryGrantableRolesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkQueryGrantableRolesRequest(obj as api.QueryGrantableRolesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("v1/roles:queryGrantableRoles"),
        );
        pathOffset += 28;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildQueryGrantableRolesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.queryGrantableRoles(arg_request, $fields: arg_$fields);
      checkQueryGrantableRolesResponse(
          response as api.QueryGrantableRolesResponse);
    });
  });
}

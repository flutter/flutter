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

import 'package:googleapis/iap/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAccessDeniedPageSettings = 0;
api.AccessDeniedPageSettings buildAccessDeniedPageSettings() {
  var o = api.AccessDeniedPageSettings();
  buildCounterAccessDeniedPageSettings++;
  if (buildCounterAccessDeniedPageSettings < 3) {
    o.accessDeniedPageUri = 'foo';
  }
  buildCounterAccessDeniedPageSettings--;
  return o;
}

void checkAccessDeniedPageSettings(api.AccessDeniedPageSettings o) {
  buildCounterAccessDeniedPageSettings++;
  if (buildCounterAccessDeniedPageSettings < 3) {
    unittest.expect(
      o.accessDeniedPageUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccessDeniedPageSettings--;
}

core.int buildCounterAccessSettings = 0;
api.AccessSettings buildAccessSettings() {
  var o = api.AccessSettings();
  buildCounterAccessSettings++;
  if (buildCounterAccessSettings < 3) {
    o.corsSettings = buildCorsSettings();
    o.gcipSettings = buildGcipSettings();
    o.oauthSettings = buildOAuthSettings();
    o.policyDelegationSettings = buildPolicyDelegationSettings();
  }
  buildCounterAccessSettings--;
  return o;
}

void checkAccessSettings(api.AccessSettings o) {
  buildCounterAccessSettings++;
  if (buildCounterAccessSettings < 3) {
    checkCorsSettings(o.corsSettings! as api.CorsSettings);
    checkGcipSettings(o.gcipSettings! as api.GcipSettings);
    checkOAuthSettings(o.oauthSettings! as api.OAuthSettings);
    checkPolicyDelegationSettings(
        o.policyDelegationSettings! as api.PolicyDelegationSettings);
  }
  buildCounterAccessSettings--;
}

core.int buildCounterApplicationSettings = 0;
api.ApplicationSettings buildApplicationSettings() {
  var o = api.ApplicationSettings();
  buildCounterApplicationSettings++;
  if (buildCounterApplicationSettings < 3) {
    o.accessDeniedPageSettings = buildAccessDeniedPageSettings();
    o.cookieDomain = 'foo';
    o.csmSettings = buildCsmSettings();
  }
  buildCounterApplicationSettings--;
  return o;
}

void checkApplicationSettings(api.ApplicationSettings o) {
  buildCounterApplicationSettings++;
  if (buildCounterApplicationSettings < 3) {
    checkAccessDeniedPageSettings(
        o.accessDeniedPageSettings! as api.AccessDeniedPageSettings);
    unittest.expect(
      o.cookieDomain!,
      unittest.equals('foo'),
    );
    checkCsmSettings(o.csmSettings! as api.CsmSettings);
  }
  buildCounterApplicationSettings--;
}

core.List<core.String> buildUnnamed3549() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3549(core.List<core.String> o) {
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
    o.members = buildUnnamed3549();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed3549(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterBrand = 0;
api.Brand buildBrand() {
  var o = api.Brand();
  buildCounterBrand++;
  if (buildCounterBrand < 3) {
    o.applicationTitle = 'foo';
    o.name = 'foo';
    o.orgInternalOnly = true;
    o.supportEmail = 'foo';
  }
  buildCounterBrand--;
  return o;
}

void checkBrand(api.Brand o) {
  buildCounterBrand++;
  if (buildCounterBrand < 3) {
    unittest.expect(
      o.applicationTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.orgInternalOnly!, unittest.isTrue);
    unittest.expect(
      o.supportEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterBrand--;
}

core.int buildCounterCorsSettings = 0;
api.CorsSettings buildCorsSettings() {
  var o = api.CorsSettings();
  buildCounterCorsSettings++;
  if (buildCounterCorsSettings < 3) {
    o.allowHttpOptions = true;
  }
  buildCounterCorsSettings--;
  return o;
}

void checkCorsSettings(api.CorsSettings o) {
  buildCounterCorsSettings++;
  if (buildCounterCorsSettings < 3) {
    unittest.expect(o.allowHttpOptions!, unittest.isTrue);
  }
  buildCounterCorsSettings--;
}

core.int buildCounterCsmSettings = 0;
api.CsmSettings buildCsmSettings() {
  var o = api.CsmSettings();
  buildCounterCsmSettings++;
  if (buildCounterCsmSettings < 3) {
    o.rctokenAud = 'foo';
  }
  buildCounterCsmSettings--;
  return o;
}

void checkCsmSettings(api.CsmSettings o) {
  buildCounterCsmSettings++;
  if (buildCounterCsmSettings < 3) {
    unittest.expect(
      o.rctokenAud!,
      unittest.equals('foo'),
    );
  }
  buildCounterCsmSettings--;
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

core.List<core.String> buildUnnamed3550() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3550(core.List<core.String> o) {
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

core.int buildCounterGcipSettings = 0;
api.GcipSettings buildGcipSettings() {
  var o = api.GcipSettings();
  buildCounterGcipSettings++;
  if (buildCounterGcipSettings < 3) {
    o.loginPageUri = 'foo';
    o.tenantIds = buildUnnamed3550();
  }
  buildCounterGcipSettings--;
  return o;
}

void checkGcipSettings(api.GcipSettings o) {
  buildCounterGcipSettings++;
  if (buildCounterGcipSettings < 3) {
    unittest.expect(
      o.loginPageUri!,
      unittest.equals('foo'),
    );
    checkUnnamed3550(o.tenantIds!);
  }
  buildCounterGcipSettings--;
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

core.int buildCounterIapSettings = 0;
api.IapSettings buildIapSettings() {
  var o = api.IapSettings();
  buildCounterIapSettings++;
  if (buildCounterIapSettings < 3) {
    o.accessSettings = buildAccessSettings();
    o.applicationSettings = buildApplicationSettings();
    o.name = 'foo';
  }
  buildCounterIapSettings--;
  return o;
}

void checkIapSettings(api.IapSettings o) {
  buildCounterIapSettings++;
  if (buildCounterIapSettings < 3) {
    checkAccessSettings(o.accessSettings! as api.AccessSettings);
    checkApplicationSettings(o.applicationSettings! as api.ApplicationSettings);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterIapSettings--;
}

core.int buildCounterIdentityAwareProxyClient = 0;
api.IdentityAwareProxyClient buildIdentityAwareProxyClient() {
  var o = api.IdentityAwareProxyClient();
  buildCounterIdentityAwareProxyClient++;
  if (buildCounterIdentityAwareProxyClient < 3) {
    o.displayName = 'foo';
    o.name = 'foo';
    o.secret = 'foo';
  }
  buildCounterIdentityAwareProxyClient--;
  return o;
}

void checkIdentityAwareProxyClient(api.IdentityAwareProxyClient o) {
  buildCounterIdentityAwareProxyClient++;
  if (buildCounterIdentityAwareProxyClient < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.secret!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentityAwareProxyClient--;
}

core.List<api.Brand> buildUnnamed3551() {
  var o = <api.Brand>[];
  o.add(buildBrand());
  o.add(buildBrand());
  return o;
}

void checkUnnamed3551(core.List<api.Brand> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBrand(o[0] as api.Brand);
  checkBrand(o[1] as api.Brand);
}

core.int buildCounterListBrandsResponse = 0;
api.ListBrandsResponse buildListBrandsResponse() {
  var o = api.ListBrandsResponse();
  buildCounterListBrandsResponse++;
  if (buildCounterListBrandsResponse < 3) {
    o.brands = buildUnnamed3551();
  }
  buildCounterListBrandsResponse--;
  return o;
}

void checkListBrandsResponse(api.ListBrandsResponse o) {
  buildCounterListBrandsResponse++;
  if (buildCounterListBrandsResponse < 3) {
    checkUnnamed3551(o.brands!);
  }
  buildCounterListBrandsResponse--;
}

core.List<api.IdentityAwareProxyClient> buildUnnamed3552() {
  var o = <api.IdentityAwareProxyClient>[];
  o.add(buildIdentityAwareProxyClient());
  o.add(buildIdentityAwareProxyClient());
  return o;
}

void checkUnnamed3552(core.List<api.IdentityAwareProxyClient> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIdentityAwareProxyClient(o[0] as api.IdentityAwareProxyClient);
  checkIdentityAwareProxyClient(o[1] as api.IdentityAwareProxyClient);
}

core.int buildCounterListIdentityAwareProxyClientsResponse = 0;
api.ListIdentityAwareProxyClientsResponse
    buildListIdentityAwareProxyClientsResponse() {
  var o = api.ListIdentityAwareProxyClientsResponse();
  buildCounterListIdentityAwareProxyClientsResponse++;
  if (buildCounterListIdentityAwareProxyClientsResponse < 3) {
    o.identityAwareProxyClients = buildUnnamed3552();
    o.nextPageToken = 'foo';
  }
  buildCounterListIdentityAwareProxyClientsResponse--;
  return o;
}

void checkListIdentityAwareProxyClientsResponse(
    api.ListIdentityAwareProxyClientsResponse o) {
  buildCounterListIdentityAwareProxyClientsResponse++;
  if (buildCounterListIdentityAwareProxyClientsResponse < 3) {
    checkUnnamed3552(o.identityAwareProxyClients!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListIdentityAwareProxyClientsResponse--;
}

core.int buildCounterOAuthSettings = 0;
api.OAuthSettings buildOAuthSettings() {
  var o = api.OAuthSettings();
  buildCounterOAuthSettings++;
  if (buildCounterOAuthSettings < 3) {
    o.loginHint = 'foo';
  }
  buildCounterOAuthSettings--;
  return o;
}

void checkOAuthSettings(api.OAuthSettings o) {
  buildCounterOAuthSettings++;
  if (buildCounterOAuthSettings < 3) {
    unittest.expect(
      o.loginHint!,
      unittest.equals('foo'),
    );
  }
  buildCounterOAuthSettings--;
}

core.List<api.Binding> buildUnnamed3553() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed3553(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.bindings = buildUnnamed3553();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed3553(o.bindings!);
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

core.int buildCounterPolicyDelegationSettings = 0;
api.PolicyDelegationSettings buildPolicyDelegationSettings() {
  var o = api.PolicyDelegationSettings();
  buildCounterPolicyDelegationSettings++;
  if (buildCounterPolicyDelegationSettings < 3) {
    o.iamPermission = 'foo';
    o.iamServiceName = 'foo';
    o.policyName = buildPolicyName();
    o.resource = buildResource();
  }
  buildCounterPolicyDelegationSettings--;
  return o;
}

void checkPolicyDelegationSettings(api.PolicyDelegationSettings o) {
  buildCounterPolicyDelegationSettings++;
  if (buildCounterPolicyDelegationSettings < 3) {
    unittest.expect(
      o.iamPermission!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iamServiceName!,
      unittest.equals('foo'),
    );
    checkPolicyName(o.policyName! as api.PolicyName);
    checkResource(o.resource! as api.Resource);
  }
  buildCounterPolicyDelegationSettings--;
}

core.int buildCounterPolicyName = 0;
api.PolicyName buildPolicyName() {
  var o = api.PolicyName();
  buildCounterPolicyName++;
  if (buildCounterPolicyName < 3) {
    o.id = 'foo';
    o.region = 'foo';
    o.type = 'foo';
  }
  buildCounterPolicyName--;
  return o;
}

void checkPolicyName(api.PolicyName o) {
  buildCounterPolicyName++;
  if (buildCounterPolicyName < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterPolicyName--;
}

core.int buildCounterResetIdentityAwareProxyClientSecretRequest = 0;
api.ResetIdentityAwareProxyClientSecretRequest
    buildResetIdentityAwareProxyClientSecretRequest() {
  var o = api.ResetIdentityAwareProxyClientSecretRequest();
  buildCounterResetIdentityAwareProxyClientSecretRequest++;
  if (buildCounterResetIdentityAwareProxyClientSecretRequest < 3) {}
  buildCounterResetIdentityAwareProxyClientSecretRequest--;
  return o;
}

void checkResetIdentityAwareProxyClientSecretRequest(
    api.ResetIdentityAwareProxyClientSecretRequest o) {
  buildCounterResetIdentityAwareProxyClientSecretRequest++;
  if (buildCounterResetIdentityAwareProxyClientSecretRequest < 3) {}
  buildCounterResetIdentityAwareProxyClientSecretRequest--;
}

core.Map<core.String, core.String> buildUnnamed3554() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3554(core.Map<core.String, core.String> o) {
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

core.int buildCounterResource = 0;
api.Resource buildResource() {
  var o = api.Resource();
  buildCounterResource++;
  if (buildCounterResource < 3) {
    o.labels = buildUnnamed3554();
    o.name = 'foo';
    o.service = 'foo';
    o.type = 'foo';
  }
  buildCounterResource--;
  return o;
}

void checkResource(api.Resource o) {
  buildCounterResource++;
  if (buildCounterResource < 3) {
    checkUnnamed3554(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterResource--;
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

core.List<core.String> buildUnnamed3555() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3555(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3555();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed3555(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed3556() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3556(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3556();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed3556(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

void main() {
  unittest.group('obj-schema-AccessDeniedPageSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessDeniedPageSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessDeniedPageSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessDeniedPageSettings(od as api.AccessDeniedPageSettings);
    });
  });

  unittest.group('obj-schema-AccessSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessSettings(od as api.AccessSettings);
    });
  });

  unittest.group('obj-schema-ApplicationSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationSettings(od as api.ApplicationSettings);
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

  unittest.group('obj-schema-Brand', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBrand();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Brand.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBrand(od as api.Brand);
    });
  });

  unittest.group('obj-schema-CorsSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCorsSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CorsSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCorsSettings(od as api.CorsSettings);
    });
  });

  unittest.group('obj-schema-CsmSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCsmSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CsmSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCsmSettings(od as api.CsmSettings);
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

  unittest.group('obj-schema-GcipSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGcipSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GcipSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGcipSettings(od as api.GcipSettings);
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

  unittest.group('obj-schema-IapSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIapSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IapSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIapSettings(od as api.IapSettings);
    });
  });

  unittest.group('obj-schema-IdentityAwareProxyClient', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentityAwareProxyClient();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentityAwareProxyClient.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentityAwareProxyClient(od as api.IdentityAwareProxyClient);
    });
  });

  unittest.group('obj-schema-ListBrandsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListBrandsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListBrandsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListBrandsResponse(od as api.ListBrandsResponse);
    });
  });

  unittest.group('obj-schema-ListIdentityAwareProxyClientsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListIdentityAwareProxyClientsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListIdentityAwareProxyClientsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListIdentityAwareProxyClientsResponse(
          od as api.ListIdentityAwareProxyClientsResponse);
    });
  });

  unittest.group('obj-schema-OAuthSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOAuthSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OAuthSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOAuthSettings(od as api.OAuthSettings);
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

  unittest.group('obj-schema-PolicyDelegationSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicyDelegationSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PolicyDelegationSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPolicyDelegationSettings(od as api.PolicyDelegationSettings);
    });
  });

  unittest.group('obj-schema-PolicyName', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicyName();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PolicyName.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicyName(od as api.PolicyName);
    });
  });

  unittest.group('obj-schema-ResetIdentityAwareProxyClientSecretRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResetIdentityAwareProxyClientSecretRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResetIdentityAwareProxyClientSecretRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResetIdentityAwareProxyClientSecretRequest(
          od as api.ResetIdentityAwareProxyClientSecretRequest);
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

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
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

  unittest.group('resource-ProjectsBrandsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).projects.brands;
      var arg_request = buildBrand();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Brand.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBrand(obj as api.Brand);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildBrand());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkBrand(response as api.Brand);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).projects.brands;
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
        var resp = convert.json.encode(buildBrand());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkBrand(response as api.Brand);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).projects.brands;
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
        var resp = convert.json.encode(buildListBrandsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkListBrandsResponse(response as api.ListBrandsResponse);
    });
  });

  unittest.group('resource-ProjectsBrandsIdentityAwareProxyClientsResource',
      () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).projects.brands.identityAwareProxyClients;
      var arg_request = buildIdentityAwareProxyClient();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentityAwareProxyClient.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentityAwareProxyClient(obj as api.IdentityAwareProxyClient);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildIdentityAwareProxyClient());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkIdentityAwareProxyClient(response as api.IdentityAwareProxyClient);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).projects.brands.identityAwareProxyClients;
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
      var res = api.CloudIAPApi(mock).projects.brands.identityAwareProxyClients;
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
        var resp = convert.json.encode(buildIdentityAwareProxyClient());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkIdentityAwareProxyClient(response as api.IdentityAwareProxyClient);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).projects.brands.identityAwareProxyClients;
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
        var resp =
            convert.json.encode(buildListIdentityAwareProxyClientsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListIdentityAwareProxyClientsResponse(
          response as api.ListIdentityAwareProxyClientsResponse);
    });

    unittest.test('method--resetSecret', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).projects.brands.identityAwareProxyClients;
      var arg_request = buildResetIdentityAwareProxyClientSecretRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResetIdentityAwareProxyClientSecretRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResetIdentityAwareProxyClientSecretRequest(
            obj as api.ResetIdentityAwareProxyClientSecretRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildIdentityAwareProxyClient());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.resetSecret(arg_request, arg_name, $fields: arg_$fields);
      checkIdentityAwareProxyClient(response as api.IdentityAwareProxyClient);
    });
  });

  unittest.group('resource-V1Resource', () {
    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).v1;
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

    unittest.test('method--getIapSettings', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).v1;
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
        var resp = convert.json.encode(buildIapSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIapSettings(arg_name, $fields: arg_$fields);
      checkIapSettings(response as api.IapSettings);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).v1;
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

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).v1;
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

    unittest.test('method--updateIapSettings', () async {
      var mock = HttpServerMock();
      var res = api.CloudIAPApi(mock).v1;
      var arg_request = buildIapSettings();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IapSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIapSettings(obj as api.IapSettings);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildIapSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateIapSettings(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkIapSettings(response as api.IapSettings);
    });
  });
}

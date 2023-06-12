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

import 'package:googleapis/policytroubleshooter/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterGoogleCloudPolicytroubleshooterV1AccessTuple = 0;
api.GoogleCloudPolicytroubleshooterV1AccessTuple
    buildGoogleCloudPolicytroubleshooterV1AccessTuple() {
  var o = api.GoogleCloudPolicytroubleshooterV1AccessTuple();
  buildCounterGoogleCloudPolicytroubleshooterV1AccessTuple++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1AccessTuple < 3) {
    o.fullResourceName = 'foo';
    o.permission = 'foo';
    o.principal = 'foo';
  }
  buildCounterGoogleCloudPolicytroubleshooterV1AccessTuple--;
  return o;
}

void checkGoogleCloudPolicytroubleshooterV1AccessTuple(
    api.GoogleCloudPolicytroubleshooterV1AccessTuple o) {
  buildCounterGoogleCloudPolicytroubleshooterV1AccessTuple++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1AccessTuple < 3) {
    unittest.expect(
      o.fullResourceName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.principal!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudPolicytroubleshooterV1AccessTuple--;
}

core.Map<core.String,
        api.GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership>
    buildUnnamed767() {
  var o = <core.String,
      api.GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership>{};
  o['x'] =
      buildGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership();
  o['y'] =
      buildGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership();
  return o;
}

void checkUnnamed767(
    core.Map<core.String,
            api.GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership(
      o['x']! as api
          .GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership);
  checkGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership(
      o['y']! as api
          .GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership);
}

core.int buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanation = 0;
api.GoogleCloudPolicytroubleshooterV1BindingExplanation
    buildGoogleCloudPolicytroubleshooterV1BindingExplanation() {
  var o = api.GoogleCloudPolicytroubleshooterV1BindingExplanation();
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanation++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanation < 3) {
    o.access = 'foo';
    o.condition = buildGoogleTypeExpr();
    o.memberships = buildUnnamed767();
    o.relevance = 'foo';
    o.role = 'foo';
    o.rolePermission = 'foo';
    o.rolePermissionRelevance = 'foo';
  }
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanation--;
  return o;
}

void checkGoogleCloudPolicytroubleshooterV1BindingExplanation(
    api.GoogleCloudPolicytroubleshooterV1BindingExplanation o) {
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanation++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanation < 3) {
    unittest.expect(
      o.access!,
      unittest.equals('foo'),
    );
    checkGoogleTypeExpr(o.condition! as api.GoogleTypeExpr);
    checkUnnamed767(o.memberships!);
    unittest.expect(
      o.relevance!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rolePermission!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rolePermissionRelevance!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanation--;
}

core.int
    buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership =
    0;
api.GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership
    buildGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership() {
  var o = api
      .GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership();
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership <
      3) {
    o.membership = 'foo';
    o.relevance = 'foo';
  }
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership--;
  return o;
}

void checkGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership(
    api.GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership
        o) {
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership <
      3) {
    unittest.expect(
      o.membership!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.relevance!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership--;
}

core.List<api.GoogleCloudPolicytroubleshooterV1BindingExplanation>
    buildUnnamed768() {
  var o = <api.GoogleCloudPolicytroubleshooterV1BindingExplanation>[];
  o.add(buildGoogleCloudPolicytroubleshooterV1BindingExplanation());
  o.add(buildGoogleCloudPolicytroubleshooterV1BindingExplanation());
  return o;
}

void checkUnnamed768(
    core.List<api.GoogleCloudPolicytroubleshooterV1BindingExplanation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudPolicytroubleshooterV1BindingExplanation(
      o[0] as api.GoogleCloudPolicytroubleshooterV1BindingExplanation);
  checkGoogleCloudPolicytroubleshooterV1BindingExplanation(
      o[1] as api.GoogleCloudPolicytroubleshooterV1BindingExplanation);
}

core.int buildCounterGoogleCloudPolicytroubleshooterV1ExplainedPolicy = 0;
api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy
    buildGoogleCloudPolicytroubleshooterV1ExplainedPolicy() {
  var o = api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy();
  buildCounterGoogleCloudPolicytroubleshooterV1ExplainedPolicy++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1ExplainedPolicy < 3) {
    o.access = 'foo';
    o.bindingExplanations = buildUnnamed768();
    o.fullResourceName = 'foo';
    o.policy = buildGoogleIamV1Policy();
    o.relevance = 'foo';
  }
  buildCounterGoogleCloudPolicytroubleshooterV1ExplainedPolicy--;
  return o;
}

void checkGoogleCloudPolicytroubleshooterV1ExplainedPolicy(
    api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy o) {
  buildCounterGoogleCloudPolicytroubleshooterV1ExplainedPolicy++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1ExplainedPolicy < 3) {
    unittest.expect(
      o.access!,
      unittest.equals('foo'),
    );
    checkUnnamed768(o.bindingExplanations!);
    unittest.expect(
      o.fullResourceName!,
      unittest.equals('foo'),
    );
    checkGoogleIamV1Policy(o.policy! as api.GoogleIamV1Policy);
    unittest.expect(
      o.relevance!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudPolicytroubleshooterV1ExplainedPolicy--;
}

core.int
    buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest =
    0;
api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest
    buildGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest() {
  var o = api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest();
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest <
      3) {
    o.accessTuple = buildGoogleCloudPolicytroubleshooterV1AccessTuple();
  }
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest--;
  return o;
}

void checkGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest(
    api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest o) {
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest <
      3) {
    checkGoogleCloudPolicytroubleshooterV1AccessTuple(
        o.accessTuple! as api.GoogleCloudPolicytroubleshooterV1AccessTuple);
  }
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest--;
}

core.List<api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy>
    buildUnnamed769() {
  var o = <api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy>[];
  o.add(buildGoogleCloudPolicytroubleshooterV1ExplainedPolicy());
  o.add(buildGoogleCloudPolicytroubleshooterV1ExplainedPolicy());
  return o;
}

void checkUnnamed769(
    core.List<api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudPolicytroubleshooterV1ExplainedPolicy(
      o[0] as api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy);
  checkGoogleCloudPolicytroubleshooterV1ExplainedPolicy(
      o[1] as api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy);
}

core.int
    buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse =
    0;
api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse
    buildGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse() {
  var o = api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse();
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse <
      3) {
    o.access = 'foo';
    o.explainedPolicies = buildUnnamed769();
  }
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse--;
  return o;
}

void checkGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse(
    api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse o) {
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse++;
  if (buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse <
      3) {
    unittest.expect(
      o.access!,
      unittest.equals('foo'),
    );
    checkUnnamed769(o.explainedPolicies!);
  }
  buildCounterGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse--;
}

core.List<api.GoogleIamV1AuditLogConfig> buildUnnamed770() {
  var o = <api.GoogleIamV1AuditLogConfig>[];
  o.add(buildGoogleIamV1AuditLogConfig());
  o.add(buildGoogleIamV1AuditLogConfig());
  return o;
}

void checkUnnamed770(core.List<api.GoogleIamV1AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIamV1AuditLogConfig(o[0] as api.GoogleIamV1AuditLogConfig);
  checkGoogleIamV1AuditLogConfig(o[1] as api.GoogleIamV1AuditLogConfig);
}

core.int buildCounterGoogleIamV1AuditConfig = 0;
api.GoogleIamV1AuditConfig buildGoogleIamV1AuditConfig() {
  var o = api.GoogleIamV1AuditConfig();
  buildCounterGoogleIamV1AuditConfig++;
  if (buildCounterGoogleIamV1AuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed770();
    o.service = 'foo';
  }
  buildCounterGoogleIamV1AuditConfig--;
  return o;
}

void checkGoogleIamV1AuditConfig(api.GoogleIamV1AuditConfig o) {
  buildCounterGoogleIamV1AuditConfig++;
  if (buildCounterGoogleIamV1AuditConfig < 3) {
    checkUnnamed770(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIamV1AuditConfig--;
}

core.List<core.String> buildUnnamed771() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed771(core.List<core.String> o) {
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

core.int buildCounterGoogleIamV1AuditLogConfig = 0;
api.GoogleIamV1AuditLogConfig buildGoogleIamV1AuditLogConfig() {
  var o = api.GoogleIamV1AuditLogConfig();
  buildCounterGoogleIamV1AuditLogConfig++;
  if (buildCounterGoogleIamV1AuditLogConfig < 3) {
    o.exemptedMembers = buildUnnamed771();
    o.logType = 'foo';
  }
  buildCounterGoogleIamV1AuditLogConfig--;
  return o;
}

void checkGoogleIamV1AuditLogConfig(api.GoogleIamV1AuditLogConfig o) {
  buildCounterGoogleIamV1AuditLogConfig++;
  if (buildCounterGoogleIamV1AuditLogConfig < 3) {
    checkUnnamed771(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIamV1AuditLogConfig--;
}

core.List<core.String> buildUnnamed772() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed772(core.List<core.String> o) {
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

core.int buildCounterGoogleIamV1Binding = 0;
api.GoogleIamV1Binding buildGoogleIamV1Binding() {
  var o = api.GoogleIamV1Binding();
  buildCounterGoogleIamV1Binding++;
  if (buildCounterGoogleIamV1Binding < 3) {
    o.condition = buildGoogleTypeExpr();
    o.members = buildUnnamed772();
    o.role = 'foo';
  }
  buildCounterGoogleIamV1Binding--;
  return o;
}

void checkGoogleIamV1Binding(api.GoogleIamV1Binding o) {
  buildCounterGoogleIamV1Binding++;
  if (buildCounterGoogleIamV1Binding < 3) {
    checkGoogleTypeExpr(o.condition! as api.GoogleTypeExpr);
    checkUnnamed772(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIamV1Binding--;
}

core.List<api.GoogleIamV1AuditConfig> buildUnnamed773() {
  var o = <api.GoogleIamV1AuditConfig>[];
  o.add(buildGoogleIamV1AuditConfig());
  o.add(buildGoogleIamV1AuditConfig());
  return o;
}

void checkUnnamed773(core.List<api.GoogleIamV1AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIamV1AuditConfig(o[0] as api.GoogleIamV1AuditConfig);
  checkGoogleIamV1AuditConfig(o[1] as api.GoogleIamV1AuditConfig);
}

core.List<api.GoogleIamV1Binding> buildUnnamed774() {
  var o = <api.GoogleIamV1Binding>[];
  o.add(buildGoogleIamV1Binding());
  o.add(buildGoogleIamV1Binding());
  return o;
}

void checkUnnamed774(core.List<api.GoogleIamV1Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIamV1Binding(o[0] as api.GoogleIamV1Binding);
  checkGoogleIamV1Binding(o[1] as api.GoogleIamV1Binding);
}

core.int buildCounterGoogleIamV1Policy = 0;
api.GoogleIamV1Policy buildGoogleIamV1Policy() {
  var o = api.GoogleIamV1Policy();
  buildCounterGoogleIamV1Policy++;
  if (buildCounterGoogleIamV1Policy < 3) {
    o.auditConfigs = buildUnnamed773();
    o.bindings = buildUnnamed774();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterGoogleIamV1Policy--;
  return o;
}

void checkGoogleIamV1Policy(api.GoogleIamV1Policy o) {
  buildCounterGoogleIamV1Policy++;
  if (buildCounterGoogleIamV1Policy < 3) {
    checkUnnamed773(o.auditConfigs!);
    checkUnnamed774(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleIamV1Policy--;
}

core.int buildCounterGoogleTypeExpr = 0;
api.GoogleTypeExpr buildGoogleTypeExpr() {
  var o = api.GoogleTypeExpr();
  buildCounterGoogleTypeExpr++;
  if (buildCounterGoogleTypeExpr < 3) {
    o.description = 'foo';
    o.expression = 'foo';
    o.location = 'foo';
    o.title = 'foo';
  }
  buildCounterGoogleTypeExpr--;
  return o;
}

void checkGoogleTypeExpr(api.GoogleTypeExpr o) {
  buildCounterGoogleTypeExpr++;
  if (buildCounterGoogleTypeExpr < 3) {
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
  buildCounterGoogleTypeExpr--;
}

void main() {
  unittest.group('obj-schema-GoogleCloudPolicytroubleshooterV1AccessTuple', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudPolicytroubleshooterV1AccessTuple();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudPolicytroubleshooterV1AccessTuple.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudPolicytroubleshooterV1AccessTuple(
          od as api.GoogleCloudPolicytroubleshooterV1AccessTuple);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudPolicytroubleshooterV1BindingExplanation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudPolicytroubleshooterV1BindingExplanation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudPolicytroubleshooterV1BindingExplanation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudPolicytroubleshooterV1BindingExplanation(
          od as api.GoogleCloudPolicytroubleshooterV1BindingExplanation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership(
          od as api
              .GoogleCloudPolicytroubleshooterV1BindingExplanationAnnotatedMembership);
    });
  });

  unittest.group('obj-schema-GoogleCloudPolicytroubleshooterV1ExplainedPolicy',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudPolicytroubleshooterV1ExplainedPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudPolicytroubleshooterV1ExplainedPolicy(
          od as api.GoogleCloudPolicytroubleshooterV1ExplainedPolicy);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest(od
          as api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse(od
          as api
              .GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse);
    });
  });

  unittest.group('obj-schema-GoogleIamV1AuditConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIamV1AuditConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIamV1AuditConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIamV1AuditConfig(od as api.GoogleIamV1AuditConfig);
    });
  });

  unittest.group('obj-schema-GoogleIamV1AuditLogConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIamV1AuditLogConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIamV1AuditLogConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIamV1AuditLogConfig(od as api.GoogleIamV1AuditLogConfig);
    });
  });

  unittest.group('obj-schema-GoogleIamV1Binding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIamV1Binding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIamV1Binding.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIamV1Binding(od as api.GoogleIamV1Binding);
    });
  });

  unittest.group('obj-schema-GoogleIamV1Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIamV1Policy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIamV1Policy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIamV1Policy(od as api.GoogleIamV1Policy);
    });
  });

  unittest.group('obj-schema-GoogleTypeExpr', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleTypeExpr();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleTypeExpr.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleTypeExpr(od as api.GoogleTypeExpr);
    });
  });

  unittest.group('resource-IamResource', () {
    unittest.test('method--troubleshoot', () async {
      var mock = HttpServerMock();
      var res = api.PolicyTroubleshooterApi(mock).iam;
      var arg_request =
          buildGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest
                .fromJson(json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest(obj
            as api
                .GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("v1/iam:troubleshoot"),
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
        var resp = convert.json.encode(
            buildGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.troubleshoot(arg_request, $fields: arg_$fields);
      checkGoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse(
          response as api
              .GoogleCloudPolicytroubleshooterV1TroubleshootIamPolicyResponse);
    });
  });
}

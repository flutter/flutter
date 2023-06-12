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

import 'package:googleapis/binaryauthorization/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed4497() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4497(core.List<core.String> o) {
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

core.int buildCounterAdmissionRule = 0;
api.AdmissionRule buildAdmissionRule() {
  var o = api.AdmissionRule();
  buildCounterAdmissionRule++;
  if (buildCounterAdmissionRule < 3) {
    o.enforcementMode = 'foo';
    o.evaluationMode = 'foo';
    o.requireAttestationsBy = buildUnnamed4497();
  }
  buildCounterAdmissionRule--;
  return o;
}

void checkAdmissionRule(api.AdmissionRule o) {
  buildCounterAdmissionRule++;
  if (buildCounterAdmissionRule < 3) {
    unittest.expect(
      o.enforcementMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.evaluationMode!,
      unittest.equals('foo'),
    );
    checkUnnamed4497(o.requireAttestationsBy!);
  }
  buildCounterAdmissionRule--;
}

core.int buildCounterAdmissionWhitelistPattern = 0;
api.AdmissionWhitelistPattern buildAdmissionWhitelistPattern() {
  var o = api.AdmissionWhitelistPattern();
  buildCounterAdmissionWhitelistPattern++;
  if (buildCounterAdmissionWhitelistPattern < 3) {
    o.namePattern = 'foo';
  }
  buildCounterAdmissionWhitelistPattern--;
  return o;
}

void checkAdmissionWhitelistPattern(api.AdmissionWhitelistPattern o) {
  buildCounterAdmissionWhitelistPattern++;
  if (buildCounterAdmissionWhitelistPattern < 3) {
    unittest.expect(
      o.namePattern!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdmissionWhitelistPattern--;
}

core.List<api.Jwt> buildUnnamed4498() {
  var o = <api.Jwt>[];
  o.add(buildJwt());
  o.add(buildJwt());
  return o;
}

void checkUnnamed4498(core.List<api.Jwt> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJwt(o[0] as api.Jwt);
  checkJwt(o[1] as api.Jwt);
}

core.List<api.Signature> buildUnnamed4499() {
  var o = <api.Signature>[];
  o.add(buildSignature());
  o.add(buildSignature());
  return o;
}

void checkUnnamed4499(core.List<api.Signature> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSignature(o[0] as api.Signature);
  checkSignature(o[1] as api.Signature);
}

core.int buildCounterAttestationOccurrence = 0;
api.AttestationOccurrence buildAttestationOccurrence() {
  var o = api.AttestationOccurrence();
  buildCounterAttestationOccurrence++;
  if (buildCounterAttestationOccurrence < 3) {
    o.jwts = buildUnnamed4498();
    o.serializedPayload = 'foo';
    o.signatures = buildUnnamed4499();
  }
  buildCounterAttestationOccurrence--;
  return o;
}

void checkAttestationOccurrence(api.AttestationOccurrence o) {
  buildCounterAttestationOccurrence++;
  if (buildCounterAttestationOccurrence < 3) {
    checkUnnamed4498(o.jwts!);
    unittest.expect(
      o.serializedPayload!,
      unittest.equals('foo'),
    );
    checkUnnamed4499(o.signatures!);
  }
  buildCounterAttestationOccurrence--;
}

core.int buildCounterAttestor = 0;
api.Attestor buildAttestor() {
  var o = api.Attestor();
  buildCounterAttestor++;
  if (buildCounterAttestor < 3) {
    o.description = 'foo';
    o.name = 'foo';
    o.updateTime = 'foo';
    o.userOwnedGrafeasNote = buildUserOwnedGrafeasNote();
  }
  buildCounterAttestor--;
  return o;
}

void checkAttestor(api.Attestor o) {
  buildCounterAttestor++;
  if (buildCounterAttestor < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    checkUserOwnedGrafeasNote(
        o.userOwnedGrafeasNote! as api.UserOwnedGrafeasNote);
  }
  buildCounterAttestor--;
}

core.int buildCounterAttestorPublicKey = 0;
api.AttestorPublicKey buildAttestorPublicKey() {
  var o = api.AttestorPublicKey();
  buildCounterAttestorPublicKey++;
  if (buildCounterAttestorPublicKey < 3) {
    o.asciiArmoredPgpPublicKey = 'foo';
    o.comment = 'foo';
    o.id = 'foo';
    o.pkixPublicKey = buildPkixPublicKey();
  }
  buildCounterAttestorPublicKey--;
  return o;
}

void checkAttestorPublicKey(api.AttestorPublicKey o) {
  buildCounterAttestorPublicKey++;
  if (buildCounterAttestorPublicKey < 3) {
    unittest.expect(
      o.asciiArmoredPgpPublicKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.comment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkPkixPublicKey(o.pkixPublicKey! as api.PkixPublicKey);
  }
  buildCounterAttestorPublicKey--;
}

core.List<core.String> buildUnnamed4500() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4500(core.List<core.String> o) {
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
    o.members = buildUnnamed4500();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed4500(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
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

core.List<api.Binding> buildUnnamed4501() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed4501(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterIamPolicy = 0;
api.IamPolicy buildIamPolicy() {
  var o = api.IamPolicy();
  buildCounterIamPolicy++;
  if (buildCounterIamPolicy < 3) {
    o.bindings = buildUnnamed4501();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterIamPolicy--;
  return o;
}

void checkIamPolicy(api.IamPolicy o) {
  buildCounterIamPolicy++;
  if (buildCounterIamPolicy < 3) {
    checkUnnamed4501(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterIamPolicy--;
}

core.int buildCounterJwt = 0;
api.Jwt buildJwt() {
  var o = api.Jwt();
  buildCounterJwt++;
  if (buildCounterJwt < 3) {
    o.compactJwt = 'foo';
  }
  buildCounterJwt--;
  return o;
}

void checkJwt(api.Jwt o) {
  buildCounterJwt++;
  if (buildCounterJwt < 3) {
    unittest.expect(
      o.compactJwt!,
      unittest.equals('foo'),
    );
  }
  buildCounterJwt--;
}

core.List<api.Attestor> buildUnnamed4502() {
  var o = <api.Attestor>[];
  o.add(buildAttestor());
  o.add(buildAttestor());
  return o;
}

void checkUnnamed4502(core.List<api.Attestor> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttestor(o[0] as api.Attestor);
  checkAttestor(o[1] as api.Attestor);
}

core.int buildCounterListAttestorsResponse = 0;
api.ListAttestorsResponse buildListAttestorsResponse() {
  var o = api.ListAttestorsResponse();
  buildCounterListAttestorsResponse++;
  if (buildCounterListAttestorsResponse < 3) {
    o.attestors = buildUnnamed4502();
    o.nextPageToken = 'foo';
  }
  buildCounterListAttestorsResponse--;
  return o;
}

void checkListAttestorsResponse(api.ListAttestorsResponse o) {
  buildCounterListAttestorsResponse++;
  if (buildCounterListAttestorsResponse < 3) {
    checkUnnamed4502(o.attestors!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAttestorsResponse--;
}

core.int buildCounterPkixPublicKey = 0;
api.PkixPublicKey buildPkixPublicKey() {
  var o = api.PkixPublicKey();
  buildCounterPkixPublicKey++;
  if (buildCounterPkixPublicKey < 3) {
    o.publicKeyPem = 'foo';
    o.signatureAlgorithm = 'foo';
  }
  buildCounterPkixPublicKey--;
  return o;
}

void checkPkixPublicKey(api.PkixPublicKey o) {
  buildCounterPkixPublicKey++;
  if (buildCounterPkixPublicKey < 3) {
    unittest.expect(
      o.publicKeyPem!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signatureAlgorithm!,
      unittest.equals('foo'),
    );
  }
  buildCounterPkixPublicKey--;
}

core.List<api.AdmissionWhitelistPattern> buildUnnamed4503() {
  var o = <api.AdmissionWhitelistPattern>[];
  o.add(buildAdmissionWhitelistPattern());
  o.add(buildAdmissionWhitelistPattern());
  return o;
}

void checkUnnamed4503(core.List<api.AdmissionWhitelistPattern> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdmissionWhitelistPattern(o[0] as api.AdmissionWhitelistPattern);
  checkAdmissionWhitelistPattern(o[1] as api.AdmissionWhitelistPattern);
}

core.Map<core.String, api.AdmissionRule> buildUnnamed4504() {
  var o = <core.String, api.AdmissionRule>{};
  o['x'] = buildAdmissionRule();
  o['y'] = buildAdmissionRule();
  return o;
}

void checkUnnamed4504(core.Map<core.String, api.AdmissionRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdmissionRule(o['x']! as api.AdmissionRule);
  checkAdmissionRule(o['y']! as api.AdmissionRule);
}

core.Map<core.String, api.AdmissionRule> buildUnnamed4505() {
  var o = <core.String, api.AdmissionRule>{};
  o['x'] = buildAdmissionRule();
  o['y'] = buildAdmissionRule();
  return o;
}

void checkUnnamed4505(core.Map<core.String, api.AdmissionRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdmissionRule(o['x']! as api.AdmissionRule);
  checkAdmissionRule(o['y']! as api.AdmissionRule);
}

core.Map<core.String, api.AdmissionRule> buildUnnamed4506() {
  var o = <core.String, api.AdmissionRule>{};
  o['x'] = buildAdmissionRule();
  o['y'] = buildAdmissionRule();
  return o;
}

void checkUnnamed4506(core.Map<core.String, api.AdmissionRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdmissionRule(o['x']! as api.AdmissionRule);
  checkAdmissionRule(o['y']! as api.AdmissionRule);
}

core.Map<core.String, api.AdmissionRule> buildUnnamed4507() {
  var o = <core.String, api.AdmissionRule>{};
  o['x'] = buildAdmissionRule();
  o['y'] = buildAdmissionRule();
  return o;
}

void checkUnnamed4507(core.Map<core.String, api.AdmissionRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdmissionRule(o['x']! as api.AdmissionRule);
  checkAdmissionRule(o['y']! as api.AdmissionRule);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.admissionWhitelistPatterns = buildUnnamed4503();
    o.clusterAdmissionRules = buildUnnamed4504();
    o.defaultAdmissionRule = buildAdmissionRule();
    o.description = 'foo';
    o.globalPolicyEvaluationMode = 'foo';
    o.istioServiceIdentityAdmissionRules = buildUnnamed4505();
    o.kubernetesNamespaceAdmissionRules = buildUnnamed4506();
    o.kubernetesServiceAccountAdmissionRules = buildUnnamed4507();
    o.name = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed4503(o.admissionWhitelistPatterns!);
    checkUnnamed4504(o.clusterAdmissionRules!);
    checkAdmissionRule(o.defaultAdmissionRule! as api.AdmissionRule);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.globalPolicyEvaluationMode!,
      unittest.equals('foo'),
    );
    checkUnnamed4505(o.istioServiceIdentityAdmissionRules!);
    checkUnnamed4506(o.kubernetesNamespaceAdmissionRules!);
    checkUnnamed4507(o.kubernetesServiceAccountAdmissionRules!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPolicy--;
}

core.int buildCounterSetIamPolicyRequest = 0;
api.SetIamPolicyRequest buildSetIamPolicyRequest() {
  var o = api.SetIamPolicyRequest();
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    o.policy = buildIamPolicy();
  }
  buildCounterSetIamPolicyRequest--;
  return o;
}

void checkSetIamPolicyRequest(api.SetIamPolicyRequest o) {
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    checkIamPolicy(o.policy! as api.IamPolicy);
  }
  buildCounterSetIamPolicyRequest--;
}

core.int buildCounterSignature = 0;
api.Signature buildSignature() {
  var o = api.Signature();
  buildCounterSignature++;
  if (buildCounterSignature < 3) {
    o.publicKeyId = 'foo';
    o.signature = 'foo';
  }
  buildCounterSignature--;
  return o;
}

void checkSignature(api.Signature o) {
  buildCounterSignature++;
  if (buildCounterSignature < 3) {
    unittest.expect(
      o.publicKeyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signature!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignature--;
}

core.List<core.String> buildUnnamed4508() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4508(core.List<core.String> o) {
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
    o.permissions = buildUnnamed4508();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed4508(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed4509() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4509(core.List<core.String> o) {
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
    o.permissions = buildUnnamed4509();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed4509(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.List<api.AttestorPublicKey> buildUnnamed4510() {
  var o = <api.AttestorPublicKey>[];
  o.add(buildAttestorPublicKey());
  o.add(buildAttestorPublicKey());
  return o;
}

void checkUnnamed4510(core.List<api.AttestorPublicKey> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttestorPublicKey(o[0] as api.AttestorPublicKey);
  checkAttestorPublicKey(o[1] as api.AttestorPublicKey);
}

core.int buildCounterUserOwnedGrafeasNote = 0;
api.UserOwnedGrafeasNote buildUserOwnedGrafeasNote() {
  var o = api.UserOwnedGrafeasNote();
  buildCounterUserOwnedGrafeasNote++;
  if (buildCounterUserOwnedGrafeasNote < 3) {
    o.delegationServiceAccountEmail = 'foo';
    o.noteReference = 'foo';
    o.publicKeys = buildUnnamed4510();
  }
  buildCounterUserOwnedGrafeasNote--;
  return o;
}

void checkUserOwnedGrafeasNote(api.UserOwnedGrafeasNote o) {
  buildCounterUserOwnedGrafeasNote++;
  if (buildCounterUserOwnedGrafeasNote < 3) {
    unittest.expect(
      o.delegationServiceAccountEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.noteReference!,
      unittest.equals('foo'),
    );
    checkUnnamed4510(o.publicKeys!);
  }
  buildCounterUserOwnedGrafeasNote--;
}

core.int buildCounterValidateAttestationOccurrenceRequest = 0;
api.ValidateAttestationOccurrenceRequest
    buildValidateAttestationOccurrenceRequest() {
  var o = api.ValidateAttestationOccurrenceRequest();
  buildCounterValidateAttestationOccurrenceRequest++;
  if (buildCounterValidateAttestationOccurrenceRequest < 3) {
    o.attestation = buildAttestationOccurrence();
    o.occurrenceNote = 'foo';
    o.occurrenceResourceUri = 'foo';
  }
  buildCounterValidateAttestationOccurrenceRequest--;
  return o;
}

void checkValidateAttestationOccurrenceRequest(
    api.ValidateAttestationOccurrenceRequest o) {
  buildCounterValidateAttestationOccurrenceRequest++;
  if (buildCounterValidateAttestationOccurrenceRequest < 3) {
    checkAttestationOccurrence(o.attestation! as api.AttestationOccurrence);
    unittest.expect(
      o.occurrenceNote!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.occurrenceResourceUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterValidateAttestationOccurrenceRequest--;
}

core.int buildCounterValidateAttestationOccurrenceResponse = 0;
api.ValidateAttestationOccurrenceResponse
    buildValidateAttestationOccurrenceResponse() {
  var o = api.ValidateAttestationOccurrenceResponse();
  buildCounterValidateAttestationOccurrenceResponse++;
  if (buildCounterValidateAttestationOccurrenceResponse < 3) {
    o.denialReason = 'foo';
    o.result = 'foo';
  }
  buildCounterValidateAttestationOccurrenceResponse--;
  return o;
}

void checkValidateAttestationOccurrenceResponse(
    api.ValidateAttestationOccurrenceResponse o) {
  buildCounterValidateAttestationOccurrenceResponse++;
  if (buildCounterValidateAttestationOccurrenceResponse < 3) {
    unittest.expect(
      o.denialReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.result!,
      unittest.equals('foo'),
    );
  }
  buildCounterValidateAttestationOccurrenceResponse--;
}

void main() {
  unittest.group('obj-schema-AdmissionRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdmissionRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdmissionRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdmissionRule(od as api.AdmissionRule);
    });
  });

  unittest.group('obj-schema-AdmissionWhitelistPattern', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdmissionWhitelistPattern();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdmissionWhitelistPattern.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdmissionWhitelistPattern(od as api.AdmissionWhitelistPattern);
    });
  });

  unittest.group('obj-schema-AttestationOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttestationOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AttestationOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAttestationOccurrence(od as api.AttestationOccurrence);
    });
  });

  unittest.group('obj-schema-Attestor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttestor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Attestor.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAttestor(od as api.Attestor);
    });
  });

  unittest.group('obj-schema-AttestorPublicKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttestorPublicKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AttestorPublicKey.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAttestorPublicKey(od as api.AttestorPublicKey);
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

  unittest.group('obj-schema-IamPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IamPolicy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicy(od as api.IamPolicy);
    });
  });

  unittest.group('obj-schema-Jwt', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJwt();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Jwt.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJwt(od as api.Jwt);
    });
  });

  unittest.group('obj-schema-ListAttestorsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAttestorsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAttestorsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAttestorsResponse(od as api.ListAttestorsResponse);
    });
  });

  unittest.group('obj-schema-PkixPublicKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPkixPublicKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PkixPublicKey.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPkixPublicKey(od as api.PkixPublicKey);
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

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-Signature', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSignature();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Signature.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSignature(od as api.Signature);
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

  unittest.group('obj-schema-UserOwnedGrafeasNote', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserOwnedGrafeasNote();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserOwnedGrafeasNote.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserOwnedGrafeasNote(od as api.UserOwnedGrafeasNote);
    });
  });

  unittest.group('obj-schema-ValidateAttestationOccurrenceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValidateAttestationOccurrenceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValidateAttestationOccurrenceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValidateAttestationOccurrenceRequest(
          od as api.ValidateAttestationOccurrenceRequest);
    });
  });

  unittest.group('obj-schema-ValidateAttestationOccurrenceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValidateAttestationOccurrenceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValidateAttestationOccurrenceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValidateAttestationOccurrenceResponse(
          od as api.ValidateAttestationOccurrenceResponse);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--getPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects;
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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getPolicy(arg_name, $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--updatePolicy', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects;
      var arg_request = buildPolicy();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Policy.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPolicy(obj as api.Policy);

        var path = (req.url).path;
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
      final response =
          await res.updatePolicy(arg_request, arg_name, $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });
  });

  unittest.group('resource-ProjectsAttestorsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
      var arg_request = buildAttestor();
      var arg_parent = 'foo';
      var arg_attestorId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Attestor.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAttestor(obj as api.Attestor);

        var path = (req.url).path;
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
          queryMap["attestorId"]!.first,
          unittest.equals(arg_attestorId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAttestor());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          attestorId: arg_attestorId, $fields: arg_$fields);
      checkAttestor(response as api.Attestor);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
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
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
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
        var resp = convert.json.encode(buildAttestor());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkAttestor(response as api.Attestor);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
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
        var resp = convert.json.encode(buildIamPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkIamPolicy(response as api.IamPolicy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
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
        var resp = convert.json.encode(buildListAttestorsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAttestorsResponse(response as api.ListAttestorsResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
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
        var resp = convert.json.encode(buildIamPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkIamPolicy(response as api.IamPolicy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
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

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
      var arg_request = buildAttestor();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Attestor.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAttestor(obj as api.Attestor);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildAttestor());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_name, $fields: arg_$fields);
      checkAttestor(response as api.Attestor);
    });

    unittest.test('method--validateAttestationOccurrence', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.attestors;
      var arg_request = buildValidateAttestationOccurrenceRequest();
      var arg_attestor = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ValidateAttestationOccurrenceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkValidateAttestationOccurrenceRequest(
            obj as api.ValidateAttestationOccurrenceRequest);

        var path = (req.url).path;
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
        var resp =
            convert.json.encode(buildValidateAttestationOccurrenceResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.validateAttestationOccurrence(
          arg_request, arg_attestor,
          $fields: arg_$fields);
      checkValidateAttestationOccurrenceResponse(
          response as api.ValidateAttestationOccurrenceResponse);
    });
  });

  unittest.group('resource-ProjectsPolicyResource', () {
    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.policy;
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
        var resp = convert.json.encode(buildIamPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkIamPolicy(response as api.IamPolicy);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.policy;
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
        var resp = convert.json.encode(buildIamPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkIamPolicy(response as api.IamPolicy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).projects.policy;
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

  unittest.group('resource-SystempolicyResource', () {
    unittest.test('method--getPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BinaryAuthorizationApi(mock).systempolicy;
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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getPolicy(arg_name, $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });
  });
}

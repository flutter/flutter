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

import 'package:googleapis/servicecontrol/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed2710() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2710(core.List<core.String> o) {
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

core.int buildCounterAllocateInfo = 0;
api.AllocateInfo buildAllocateInfo() {
  var o = api.AllocateInfo();
  buildCounterAllocateInfo++;
  if (buildCounterAllocateInfo < 3) {
    o.unusedArguments = buildUnnamed2710();
  }
  buildCounterAllocateInfo--;
  return o;
}

void checkAllocateInfo(api.AllocateInfo o) {
  buildCounterAllocateInfo++;
  if (buildCounterAllocateInfo < 3) {
    checkUnnamed2710(o.unusedArguments!);
  }
  buildCounterAllocateInfo--;
}

core.int buildCounterAllocateQuotaRequest = 0;
api.AllocateQuotaRequest buildAllocateQuotaRequest() {
  var o = api.AllocateQuotaRequest();
  buildCounterAllocateQuotaRequest++;
  if (buildCounterAllocateQuotaRequest < 3) {
    o.allocateOperation = buildQuotaOperation();
    o.serviceConfigId = 'foo';
  }
  buildCounterAllocateQuotaRequest--;
  return o;
}

void checkAllocateQuotaRequest(api.AllocateQuotaRequest o) {
  buildCounterAllocateQuotaRequest++;
  if (buildCounterAllocateQuotaRequest < 3) {
    checkQuotaOperation(o.allocateOperation! as api.QuotaOperation);
    unittest.expect(
      o.serviceConfigId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAllocateQuotaRequest--;
}

core.List<api.QuotaError> buildUnnamed2711() {
  var o = <api.QuotaError>[];
  o.add(buildQuotaError());
  o.add(buildQuotaError());
  return o;
}

void checkUnnamed2711(core.List<api.QuotaError> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQuotaError(o[0] as api.QuotaError);
  checkQuotaError(o[1] as api.QuotaError);
}

core.List<api.MetricValueSet> buildUnnamed2712() {
  var o = <api.MetricValueSet>[];
  o.add(buildMetricValueSet());
  o.add(buildMetricValueSet());
  return o;
}

void checkUnnamed2712(core.List<api.MetricValueSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricValueSet(o[0] as api.MetricValueSet);
  checkMetricValueSet(o[1] as api.MetricValueSet);
}

core.int buildCounterAllocateQuotaResponse = 0;
api.AllocateQuotaResponse buildAllocateQuotaResponse() {
  var o = api.AllocateQuotaResponse();
  buildCounterAllocateQuotaResponse++;
  if (buildCounterAllocateQuotaResponse < 3) {
    o.allocateErrors = buildUnnamed2711();
    o.allocateInfo = buildAllocateInfo();
    o.operationId = 'foo';
    o.quotaMetrics = buildUnnamed2712();
    o.serviceConfigId = 'foo';
  }
  buildCounterAllocateQuotaResponse--;
  return o;
}

void checkAllocateQuotaResponse(api.AllocateQuotaResponse o) {
  buildCounterAllocateQuotaResponse++;
  if (buildCounterAllocateQuotaResponse < 3) {
    checkUnnamed2711(o.allocateErrors!);
    checkAllocateInfo(o.allocateInfo! as api.AllocateInfo);
    unittest.expect(
      o.operationId!,
      unittest.equals('foo'),
    );
    checkUnnamed2712(o.quotaMetrics!);
    unittest.expect(
      o.serviceConfigId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAllocateQuotaResponse--;
}

core.int buildCounterAttributeValue = 0;
api.AttributeValue buildAttributeValue() {
  var o = api.AttributeValue();
  buildCounterAttributeValue++;
  if (buildCounterAttributeValue < 3) {
    o.boolValue = true;
    o.intValue = 'foo';
    o.stringValue = buildTruncatableString();
  }
  buildCounterAttributeValue--;
  return o;
}

void checkAttributeValue(api.AttributeValue o) {
  buildCounterAttributeValue++;
  if (buildCounterAttributeValue < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    unittest.expect(
      o.intValue!,
      unittest.equals('foo'),
    );
    checkTruncatableString(o.stringValue! as api.TruncatableString);
  }
  buildCounterAttributeValue--;
}

core.Map<core.String, api.AttributeValue> buildUnnamed2713() {
  var o = <core.String, api.AttributeValue>{};
  o['x'] = buildAttributeValue();
  o['y'] = buildAttributeValue();
  return o;
}

void checkUnnamed2713(core.Map<core.String, api.AttributeValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttributeValue(o['x']! as api.AttributeValue);
  checkAttributeValue(o['y']! as api.AttributeValue);
}

core.int buildCounterAttributes = 0;
api.Attributes buildAttributes() {
  var o = api.Attributes();
  buildCounterAttributes++;
  if (buildCounterAttributes < 3) {
    o.attributeMap = buildUnnamed2713();
    o.droppedAttributesCount = 42;
  }
  buildCounterAttributes--;
  return o;
}

void checkAttributes(api.Attributes o) {
  buildCounterAttributes++;
  if (buildCounterAttributes < 3) {
    checkUnnamed2713(o.attributeMap!);
    unittest.expect(
      o.droppedAttributesCount!,
      unittest.equals(42),
    );
  }
  buildCounterAttributes--;
}

core.List<api.AuthorizationInfo> buildUnnamed2714() {
  var o = <api.AuthorizationInfo>[];
  o.add(buildAuthorizationInfo());
  o.add(buildAuthorizationInfo());
  return o;
}

void checkUnnamed2714(core.List<api.AuthorizationInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuthorizationInfo(o[0] as api.AuthorizationInfo);
  checkAuthorizationInfo(o[1] as api.AuthorizationInfo);
}

core.Map<core.String, core.Object> buildUnnamed2715() {
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

void checkUnnamed2715(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2716() {
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

void checkUnnamed2716(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2717() {
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

void checkUnnamed2717(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2718() {
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

void checkUnnamed2718(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted7 = (o['x']!) as core.Map;
  unittest.expect(casted7, unittest.hasLength(3));
  unittest.expect(
    casted7['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted7['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted7['string'],
    unittest.equals('foo'),
  );
  var casted8 = (o['y']!) as core.Map;
  unittest.expect(casted8, unittest.hasLength(3));
  unittest.expect(
    casted8['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted8['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted8['string'],
    unittest.equals('foo'),
  );
}

core.Map<core.String, core.Object> buildUnnamed2719() {
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

void checkUnnamed2719(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted9 = (o['x']!) as core.Map;
  unittest.expect(casted9, unittest.hasLength(3));
  unittest.expect(
    casted9['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted9['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted9['string'],
    unittest.equals('foo'),
  );
  var casted10 = (o['y']!) as core.Map;
  unittest.expect(casted10, unittest.hasLength(3));
  unittest.expect(
    casted10['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted10['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted10['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterAuditLog = 0;
api.AuditLog buildAuditLog() {
  var o = api.AuditLog();
  buildCounterAuditLog++;
  if (buildCounterAuditLog < 3) {
    o.authenticationInfo = buildAuthenticationInfo();
    o.authorizationInfo = buildUnnamed2714();
    o.metadata = buildUnnamed2715();
    o.methodName = 'foo';
    o.numResponseItems = 'foo';
    o.request = buildUnnamed2716();
    o.requestMetadata = buildRequestMetadata();
    o.resourceLocation = buildResourceLocation();
    o.resourceName = 'foo';
    o.resourceOriginalState = buildUnnamed2717();
    o.response = buildUnnamed2718();
    o.serviceData = buildUnnamed2719();
    o.serviceName = 'foo';
    o.status = buildStatus();
  }
  buildCounterAuditLog--;
  return o;
}

void checkAuditLog(api.AuditLog o) {
  buildCounterAuditLog++;
  if (buildCounterAuditLog < 3) {
    checkAuthenticationInfo(o.authenticationInfo! as api.AuthenticationInfo);
    checkUnnamed2714(o.authorizationInfo!);
    checkUnnamed2715(o.metadata!);
    unittest.expect(
      o.methodName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numResponseItems!,
      unittest.equals('foo'),
    );
    checkUnnamed2716(o.request!);
    checkRequestMetadata(o.requestMetadata! as api.RequestMetadata);
    checkResourceLocation(o.resourceLocation! as api.ResourceLocation);
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
    checkUnnamed2717(o.resourceOriginalState!);
    checkUnnamed2718(o.response!);
    checkUnnamed2719(o.serviceData!);
    unittest.expect(
      o.serviceName!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
  }
  buildCounterAuditLog--;
}

core.List<core.String> buildUnnamed2720() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2720(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2721() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2721(core.List<core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed2722() {
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

void checkUnnamed2722(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted11 = (o['x']!) as core.Map;
  unittest.expect(casted11, unittest.hasLength(3));
  unittest.expect(
    casted11['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted11['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted11['string'],
    unittest.equals('foo'),
  );
  var casted12 = (o['y']!) as core.Map;
  unittest.expect(casted12, unittest.hasLength(3));
  unittest.expect(
    casted12['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted12['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted12['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterAuth = 0;
api.Auth buildAuth() {
  var o = api.Auth();
  buildCounterAuth++;
  if (buildCounterAuth < 3) {
    o.accessLevels = buildUnnamed2720();
    o.audiences = buildUnnamed2721();
    o.claims = buildUnnamed2722();
    o.presenter = 'foo';
    o.principal = 'foo';
  }
  buildCounterAuth--;
  return o;
}

void checkAuth(api.Auth o) {
  buildCounterAuth++;
  if (buildCounterAuth < 3) {
    checkUnnamed2720(o.accessLevels!);
    checkUnnamed2721(o.audiences!);
    checkUnnamed2722(o.claims!);
    unittest.expect(
      o.presenter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.principal!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuth--;
}

core.List<api.ServiceAccountDelegationInfo> buildUnnamed2723() {
  var o = <api.ServiceAccountDelegationInfo>[];
  o.add(buildServiceAccountDelegationInfo());
  o.add(buildServiceAccountDelegationInfo());
  return o;
}

void checkUnnamed2723(core.List<api.ServiceAccountDelegationInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkServiceAccountDelegationInfo(o[0] as api.ServiceAccountDelegationInfo);
  checkServiceAccountDelegationInfo(o[1] as api.ServiceAccountDelegationInfo);
}

core.Map<core.String, core.Object> buildUnnamed2724() {
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

void checkUnnamed2724(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted13 = (o['x']!) as core.Map;
  unittest.expect(casted13, unittest.hasLength(3));
  unittest.expect(
    casted13['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted13['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted13['string'],
    unittest.equals('foo'),
  );
  var casted14 = (o['y']!) as core.Map;
  unittest.expect(casted14, unittest.hasLength(3));
  unittest.expect(
    casted14['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted14['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted14['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterAuthenticationInfo = 0;
api.AuthenticationInfo buildAuthenticationInfo() {
  var o = api.AuthenticationInfo();
  buildCounterAuthenticationInfo++;
  if (buildCounterAuthenticationInfo < 3) {
    o.authoritySelector = 'foo';
    o.principalEmail = 'foo';
    o.principalSubject = 'foo';
    o.serviceAccountDelegationInfo = buildUnnamed2723();
    o.serviceAccountKeyName = 'foo';
    o.thirdPartyPrincipal = buildUnnamed2724();
  }
  buildCounterAuthenticationInfo--;
  return o;
}

void checkAuthenticationInfo(api.AuthenticationInfo o) {
  buildCounterAuthenticationInfo++;
  if (buildCounterAuthenticationInfo < 3) {
    unittest.expect(
      o.authoritySelector!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.principalEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.principalSubject!,
      unittest.equals('foo'),
    );
    checkUnnamed2723(o.serviceAccountDelegationInfo!);
    unittest.expect(
      o.serviceAccountKeyName!,
      unittest.equals('foo'),
    );
    checkUnnamed2724(o.thirdPartyPrincipal!);
  }
  buildCounterAuthenticationInfo--;
}

core.int buildCounterAuthorizationInfo = 0;
api.AuthorizationInfo buildAuthorizationInfo() {
  var o = api.AuthorizationInfo();
  buildCounterAuthorizationInfo++;
  if (buildCounterAuthorizationInfo < 3) {
    o.granted = true;
    o.permission = 'foo';
    o.resource = 'foo';
    o.resourceAttributes = buildResource();
  }
  buildCounterAuthorizationInfo--;
  return o;
}

void checkAuthorizationInfo(api.AuthorizationInfo o) {
  buildCounterAuthorizationInfo++;
  if (buildCounterAuthorizationInfo < 3) {
    unittest.expect(o.granted!, unittest.isTrue);
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resource!,
      unittest.equals('foo'),
    );
    checkResource(o.resourceAttributes! as api.Resource);
  }
  buildCounterAuthorizationInfo--;
}

core.int buildCounterCheckError = 0;
api.CheckError buildCheckError() {
  var o = api.CheckError();
  buildCounterCheckError++;
  if (buildCounterCheckError < 3) {
    o.code = 'foo';
    o.detail = 'foo';
    o.status = buildStatus();
    o.subject = 'foo';
  }
  buildCounterCheckError--;
  return o;
}

void checkCheckError(api.CheckError o) {
  buildCounterCheckError++;
  if (buildCounterCheckError < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.detail!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
    unittest.expect(
      o.subject!,
      unittest.equals('foo'),
    );
  }
  buildCounterCheckError--;
}

core.List<core.String> buildUnnamed2725() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2725(core.List<core.String> o) {
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

core.int buildCounterCheckInfo = 0;
api.CheckInfo buildCheckInfo() {
  var o = api.CheckInfo();
  buildCounterCheckInfo++;
  if (buildCounterCheckInfo < 3) {
    o.consumerInfo = buildConsumerInfo();
    o.unusedArguments = buildUnnamed2725();
  }
  buildCounterCheckInfo--;
  return o;
}

void checkCheckInfo(api.CheckInfo o) {
  buildCounterCheckInfo++;
  if (buildCounterCheckInfo < 3) {
    checkConsumerInfo(o.consumerInfo! as api.ConsumerInfo);
    checkUnnamed2725(o.unusedArguments!);
  }
  buildCounterCheckInfo--;
}

core.int buildCounterCheckRequest = 0;
api.CheckRequest buildCheckRequest() {
  var o = api.CheckRequest();
  buildCounterCheckRequest++;
  if (buildCounterCheckRequest < 3) {
    o.operation = buildOperation();
    o.requestProjectSettings = true;
    o.serviceConfigId = 'foo';
    o.skipActivationCheck = true;
  }
  buildCounterCheckRequest--;
  return o;
}

void checkCheckRequest(api.CheckRequest o) {
  buildCounterCheckRequest++;
  if (buildCounterCheckRequest < 3) {
    checkOperation(o.operation! as api.Operation);
    unittest.expect(o.requestProjectSettings!, unittest.isTrue);
    unittest.expect(
      o.serviceConfigId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.skipActivationCheck!, unittest.isTrue);
  }
  buildCounterCheckRequest--;
}

core.List<api.CheckError> buildUnnamed2726() {
  var o = <api.CheckError>[];
  o.add(buildCheckError());
  o.add(buildCheckError());
  return o;
}

void checkUnnamed2726(core.List<api.CheckError> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCheckError(o[0] as api.CheckError);
  checkCheckError(o[1] as api.CheckError);
}

core.int buildCounterCheckResponse = 0;
api.CheckResponse buildCheckResponse() {
  var o = api.CheckResponse();
  buildCounterCheckResponse++;
  if (buildCounterCheckResponse < 3) {
    o.checkErrors = buildUnnamed2726();
    o.checkInfo = buildCheckInfo();
    o.operationId = 'foo';
    o.quotaInfo = buildQuotaInfo();
    o.serviceConfigId = 'foo';
    o.serviceRolloutId = 'foo';
  }
  buildCounterCheckResponse--;
  return o;
}

void checkCheckResponse(api.CheckResponse o) {
  buildCounterCheckResponse++;
  if (buildCounterCheckResponse < 3) {
    checkUnnamed2726(o.checkErrors!);
    checkCheckInfo(o.checkInfo! as api.CheckInfo);
    unittest.expect(
      o.operationId!,
      unittest.equals('foo'),
    );
    checkQuotaInfo(o.quotaInfo! as api.QuotaInfo);
    unittest.expect(
      o.serviceConfigId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceRolloutId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCheckResponse--;
}

core.int buildCounterConsumerInfo = 0;
api.ConsumerInfo buildConsumerInfo() {
  var o = api.ConsumerInfo();
  buildCounterConsumerInfo++;
  if (buildCounterConsumerInfo < 3) {
    o.consumerNumber = 'foo';
    o.projectNumber = 'foo';
    o.type = 'foo';
  }
  buildCounterConsumerInfo--;
  return o;
}

void checkConsumerInfo(api.ConsumerInfo o) {
  buildCounterConsumerInfo++;
  if (buildCounterConsumerInfo < 3) {
    unittest.expect(
      o.consumerNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterConsumerInfo--;
}

core.List<core.String> buildUnnamed2727() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2727(core.List<core.String> o) {
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

core.List<api.Exemplar> buildUnnamed2728() {
  var o = <api.Exemplar>[];
  o.add(buildExemplar());
  o.add(buildExemplar());
  return o;
}

void checkUnnamed2728(core.List<api.Exemplar> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExemplar(o[0] as api.Exemplar);
  checkExemplar(o[1] as api.Exemplar);
}

core.int buildCounterDistribution = 0;
api.Distribution buildDistribution() {
  var o = api.Distribution();
  buildCounterDistribution++;
  if (buildCounterDistribution < 3) {
    o.bucketCounts = buildUnnamed2727();
    o.count = 'foo';
    o.exemplars = buildUnnamed2728();
    o.explicitBuckets = buildExplicitBuckets();
    o.exponentialBuckets = buildExponentialBuckets();
    o.linearBuckets = buildLinearBuckets();
    o.maximum = 42.0;
    o.mean = 42.0;
    o.minimum = 42.0;
    o.sumOfSquaredDeviation = 42.0;
  }
  buildCounterDistribution--;
  return o;
}

void checkDistribution(api.Distribution o) {
  buildCounterDistribution++;
  if (buildCounterDistribution < 3) {
    checkUnnamed2727(o.bucketCounts!);
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
    checkUnnamed2728(o.exemplars!);
    checkExplicitBuckets(o.explicitBuckets! as api.ExplicitBuckets);
    checkExponentialBuckets(o.exponentialBuckets! as api.ExponentialBuckets);
    checkLinearBuckets(o.linearBuckets! as api.LinearBuckets);
    unittest.expect(
      o.maximum!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.mean!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.minimum!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.sumOfSquaredDeviation!,
      unittest.equals(42.0),
    );
  }
  buildCounterDistribution--;
}

core.Map<core.String, core.Object> buildUnnamed2729() {
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

void checkUnnamed2729(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted15 = (o['x']!) as core.Map;
  unittest.expect(casted15, unittest.hasLength(3));
  unittest.expect(
    casted15['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted15['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted15['string'],
    unittest.equals('foo'),
  );
  var casted16 = (o['y']!) as core.Map;
  unittest.expect(casted16, unittest.hasLength(3));
  unittest.expect(
    casted16['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted16['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted16['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed2730() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2729());
  o.add(buildUnnamed2729());
  return o;
}

void checkUnnamed2730(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2729(o[0]);
  checkUnnamed2729(o[1]);
}

core.int buildCounterExemplar = 0;
api.Exemplar buildExemplar() {
  var o = api.Exemplar();
  buildCounterExemplar++;
  if (buildCounterExemplar < 3) {
    o.attachments = buildUnnamed2730();
    o.timestamp = 'foo';
    o.value = 42.0;
  }
  buildCounterExemplar--;
  return o;
}

void checkExemplar(api.Exemplar o) {
  buildCounterExemplar++;
  if (buildCounterExemplar < 3) {
    checkUnnamed2730(o.attachments!);
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals(42.0),
    );
  }
  buildCounterExemplar--;
}

core.List<core.double> buildUnnamed2731() {
  var o = <core.double>[];
  o.add(42.0);
  o.add(42.0);
  return o;
}

void checkUnnamed2731(core.List<core.double> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42.0),
  );
  unittest.expect(
    o[1],
    unittest.equals(42.0),
  );
}

core.int buildCounterExplicitBuckets = 0;
api.ExplicitBuckets buildExplicitBuckets() {
  var o = api.ExplicitBuckets();
  buildCounterExplicitBuckets++;
  if (buildCounterExplicitBuckets < 3) {
    o.bounds = buildUnnamed2731();
  }
  buildCounterExplicitBuckets--;
  return o;
}

void checkExplicitBuckets(api.ExplicitBuckets o) {
  buildCounterExplicitBuckets++;
  if (buildCounterExplicitBuckets < 3) {
    checkUnnamed2731(o.bounds!);
  }
  buildCounterExplicitBuckets--;
}

core.int buildCounterExponentialBuckets = 0;
api.ExponentialBuckets buildExponentialBuckets() {
  var o = api.ExponentialBuckets();
  buildCounterExponentialBuckets++;
  if (buildCounterExponentialBuckets < 3) {
    o.growthFactor = 42.0;
    o.numFiniteBuckets = 42;
    o.scale = 42.0;
  }
  buildCounterExponentialBuckets--;
  return o;
}

void checkExponentialBuckets(api.ExponentialBuckets o) {
  buildCounterExponentialBuckets++;
  if (buildCounterExponentialBuckets < 3) {
    unittest.expect(
      o.growthFactor!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.numFiniteBuckets!,
      unittest.equals(42),
    );
    unittest.expect(
      o.scale!,
      unittest.equals(42.0),
    );
  }
  buildCounterExponentialBuckets--;
}

core.Map<core.String, core.Object> buildUnnamed2732() {
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

void checkUnnamed2732(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted17 = (o['x']!) as core.Map;
  unittest.expect(casted17, unittest.hasLength(3));
  unittest.expect(
    casted17['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted17['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted17['string'],
    unittest.equals('foo'),
  );
  var casted18 = (o['y']!) as core.Map;
  unittest.expect(casted18, unittest.hasLength(3));
  unittest.expect(
    casted18['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted18['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted18['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterFirstPartyPrincipal = 0;
api.FirstPartyPrincipal buildFirstPartyPrincipal() {
  var o = api.FirstPartyPrincipal();
  buildCounterFirstPartyPrincipal++;
  if (buildCounterFirstPartyPrincipal < 3) {
    o.principalEmail = 'foo';
    o.serviceMetadata = buildUnnamed2732();
  }
  buildCounterFirstPartyPrincipal--;
  return o;
}

void checkFirstPartyPrincipal(api.FirstPartyPrincipal o) {
  buildCounterFirstPartyPrincipal++;
  if (buildCounterFirstPartyPrincipal < 3) {
    unittest.expect(
      o.principalEmail!,
      unittest.equals('foo'),
    );
    checkUnnamed2732(o.serviceMetadata!);
  }
  buildCounterFirstPartyPrincipal--;
}

core.int buildCounterHttpRequest = 0;
api.HttpRequest buildHttpRequest() {
  var o = api.HttpRequest();
  buildCounterHttpRequest++;
  if (buildCounterHttpRequest < 3) {
    o.cacheFillBytes = 'foo';
    o.cacheHit = true;
    o.cacheLookup = true;
    o.cacheValidatedWithOriginServer = true;
    o.latency = 'foo';
    o.protocol = 'foo';
    o.referer = 'foo';
    o.remoteIp = 'foo';
    o.requestMethod = 'foo';
    o.requestSize = 'foo';
    o.requestUrl = 'foo';
    o.responseSize = 'foo';
    o.serverIp = 'foo';
    o.status = 42;
    o.userAgent = 'foo';
  }
  buildCounterHttpRequest--;
  return o;
}

void checkHttpRequest(api.HttpRequest o) {
  buildCounterHttpRequest++;
  if (buildCounterHttpRequest < 3) {
    unittest.expect(
      o.cacheFillBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cacheHit!, unittest.isTrue);
    unittest.expect(o.cacheLookup!, unittest.isTrue);
    unittest.expect(o.cacheValidatedWithOriginServer!, unittest.isTrue);
    unittest.expect(
      o.latency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.remoteIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responseSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serverIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals(42),
    );
    unittest.expect(
      o.userAgent!,
      unittest.equals('foo'),
    );
  }
  buildCounterHttpRequest--;
}

core.int buildCounterLinearBuckets = 0;
api.LinearBuckets buildLinearBuckets() {
  var o = api.LinearBuckets();
  buildCounterLinearBuckets++;
  if (buildCounterLinearBuckets < 3) {
    o.numFiniteBuckets = 42;
    o.offset = 42.0;
    o.width = 42.0;
  }
  buildCounterLinearBuckets--;
  return o;
}

void checkLinearBuckets(api.LinearBuckets o) {
  buildCounterLinearBuckets++;
  if (buildCounterLinearBuckets < 3) {
    unittest.expect(
      o.numFiniteBuckets!,
      unittest.equals(42),
    );
    unittest.expect(
      o.offset!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42.0),
    );
  }
  buildCounterLinearBuckets--;
}

core.Map<core.String, core.String> buildUnnamed2733() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2733(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed2734() {
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

void checkUnnamed2734(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted19 = (o['x']!) as core.Map;
  unittest.expect(casted19, unittest.hasLength(3));
  unittest.expect(
    casted19['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted19['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted19['string'],
    unittest.equals('foo'),
  );
  var casted20 = (o['y']!) as core.Map;
  unittest.expect(casted20, unittest.hasLength(3));
  unittest.expect(
    casted20['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted20['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted20['string'],
    unittest.equals('foo'),
  );
}

core.Map<core.String, core.Object> buildUnnamed2735() {
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

void checkUnnamed2735(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted21 = (o['x']!) as core.Map;
  unittest.expect(casted21, unittest.hasLength(3));
  unittest.expect(
    casted21['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted21['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted21['string'],
    unittest.equals('foo'),
  );
  var casted22 = (o['y']!) as core.Map;
  unittest.expect(casted22, unittest.hasLength(3));
  unittest.expect(
    casted22['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted22['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted22['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterLogEntry = 0;
api.LogEntry buildLogEntry() {
  var o = api.LogEntry();
  buildCounterLogEntry++;
  if (buildCounterLogEntry < 3) {
    o.httpRequest = buildHttpRequest();
    o.insertId = 'foo';
    o.labels = buildUnnamed2733();
    o.name = 'foo';
    o.operation = buildLogEntryOperation();
    o.protoPayload = buildUnnamed2734();
    o.severity = 'foo';
    o.sourceLocation = buildLogEntrySourceLocation();
    o.structPayload = buildUnnamed2735();
    o.textPayload = 'foo';
    o.timestamp = 'foo';
    o.trace = 'foo';
  }
  buildCounterLogEntry--;
  return o;
}

void checkLogEntry(api.LogEntry o) {
  buildCounterLogEntry++;
  if (buildCounterLogEntry < 3) {
    checkHttpRequest(o.httpRequest! as api.HttpRequest);
    unittest.expect(
      o.insertId!,
      unittest.equals('foo'),
    );
    checkUnnamed2733(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkLogEntryOperation(o.operation! as api.LogEntryOperation);
    checkUnnamed2734(o.protoPayload!);
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    checkLogEntrySourceLocation(
        o.sourceLocation! as api.LogEntrySourceLocation);
    checkUnnamed2735(o.structPayload!);
    unittest.expect(
      o.textPayload!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.trace!,
      unittest.equals('foo'),
    );
  }
  buildCounterLogEntry--;
}

core.int buildCounterLogEntryOperation = 0;
api.LogEntryOperation buildLogEntryOperation() {
  var o = api.LogEntryOperation();
  buildCounterLogEntryOperation++;
  if (buildCounterLogEntryOperation < 3) {
    o.first = true;
    o.id = 'foo';
    o.last = true;
    o.producer = 'foo';
  }
  buildCounterLogEntryOperation--;
  return o;
}

void checkLogEntryOperation(api.LogEntryOperation o) {
  buildCounterLogEntryOperation++;
  if (buildCounterLogEntryOperation < 3) {
    unittest.expect(o.first!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.last!, unittest.isTrue);
    unittest.expect(
      o.producer!,
      unittest.equals('foo'),
    );
  }
  buildCounterLogEntryOperation--;
}

core.int buildCounterLogEntrySourceLocation = 0;
api.LogEntrySourceLocation buildLogEntrySourceLocation() {
  var o = api.LogEntrySourceLocation();
  buildCounterLogEntrySourceLocation++;
  if (buildCounterLogEntrySourceLocation < 3) {
    o.file = 'foo';
    o.function = 'foo';
    o.line = 'foo';
  }
  buildCounterLogEntrySourceLocation--;
  return o;
}

void checkLogEntrySourceLocation(api.LogEntrySourceLocation o) {
  buildCounterLogEntrySourceLocation++;
  if (buildCounterLogEntrySourceLocation < 3) {
    unittest.expect(
      o.file!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.function!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.line!,
      unittest.equals('foo'),
    );
  }
  buildCounterLogEntrySourceLocation--;
}

core.Map<core.String, core.String> buildUnnamed2736() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2736(core.Map<core.String, core.String> o) {
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

core.int buildCounterMetricValue = 0;
api.MetricValue buildMetricValue() {
  var o = api.MetricValue();
  buildCounterMetricValue++;
  if (buildCounterMetricValue < 3) {
    o.boolValue = true;
    o.distributionValue = buildDistribution();
    o.doubleValue = 42.0;
    o.endTime = 'foo';
    o.int64Value = 'foo';
    o.labels = buildUnnamed2736();
    o.moneyValue = buildMoney();
    o.startTime = 'foo';
    o.stringValue = 'foo';
  }
  buildCounterMetricValue--;
  return o;
}

void checkMetricValue(api.MetricValue o) {
  buildCounterMetricValue++;
  if (buildCounterMetricValue < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    checkDistribution(o.distributionValue! as api.Distribution);
    unittest.expect(
      o.doubleValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.int64Value!,
      unittest.equals('foo'),
    );
    checkUnnamed2736(o.labels!);
    checkMoney(o.moneyValue! as api.Money);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetricValue--;
}

core.List<api.MetricValue> buildUnnamed2737() {
  var o = <api.MetricValue>[];
  o.add(buildMetricValue());
  o.add(buildMetricValue());
  return o;
}

void checkUnnamed2737(core.List<api.MetricValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricValue(o[0] as api.MetricValue);
  checkMetricValue(o[1] as api.MetricValue);
}

core.int buildCounterMetricValueSet = 0;
api.MetricValueSet buildMetricValueSet() {
  var o = api.MetricValueSet();
  buildCounterMetricValueSet++;
  if (buildCounterMetricValueSet < 3) {
    o.metricName = 'foo';
    o.metricValues = buildUnnamed2737();
  }
  buildCounterMetricValueSet--;
  return o;
}

void checkMetricValueSet(api.MetricValueSet o) {
  buildCounterMetricValueSet++;
  if (buildCounterMetricValueSet < 3) {
    unittest.expect(
      o.metricName!,
      unittest.equals('foo'),
    );
    checkUnnamed2737(o.metricValues!);
  }
  buildCounterMetricValueSet--;
}

core.int buildCounterMoney = 0;
api.Money buildMoney() {
  var o = api.Money();
  buildCounterMoney++;
  if (buildCounterMoney < 3) {
    o.currencyCode = 'foo';
    o.nanos = 42;
    o.units = 'foo';
  }
  buildCounterMoney--;
  return o;
}

void checkMoney(api.Money o) {
  buildCounterMoney++;
  if (buildCounterMoney < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.units!,
      unittest.equals('foo'),
    );
  }
  buildCounterMoney--;
}

core.Map<core.String, core.Object> buildUnnamed2738() {
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

void checkUnnamed2738(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted23 = (o['x']!) as core.Map;
  unittest.expect(casted23, unittest.hasLength(3));
  unittest.expect(
    casted23['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted23['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted23['string'],
    unittest.equals('foo'),
  );
  var casted24 = (o['y']!) as core.Map;
  unittest.expect(casted24, unittest.hasLength(3));
  unittest.expect(
    casted24['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted24['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted24['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed2739() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2738());
  o.add(buildUnnamed2738());
  return o;
}

void checkUnnamed2739(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2738(o[0]);
  checkUnnamed2738(o[1]);
}

core.Map<core.String, core.String> buildUnnamed2740() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2740(core.Map<core.String, core.String> o) {
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

core.List<api.LogEntry> buildUnnamed2741() {
  var o = <api.LogEntry>[];
  o.add(buildLogEntry());
  o.add(buildLogEntry());
  return o;
}

void checkUnnamed2741(core.List<api.LogEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLogEntry(o[0] as api.LogEntry);
  checkLogEntry(o[1] as api.LogEntry);
}

core.List<api.MetricValueSet> buildUnnamed2742() {
  var o = <api.MetricValueSet>[];
  o.add(buildMetricValueSet());
  o.add(buildMetricValueSet());
  return o;
}

void checkUnnamed2742(core.List<api.MetricValueSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricValueSet(o[0] as api.MetricValueSet);
  checkMetricValueSet(o[1] as api.MetricValueSet);
}

core.List<api.ResourceInfo> buildUnnamed2743() {
  var o = <api.ResourceInfo>[];
  o.add(buildResourceInfo());
  o.add(buildResourceInfo());
  return o;
}

void checkUnnamed2743(core.List<api.ResourceInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceInfo(o[0] as api.ResourceInfo);
  checkResourceInfo(o[1] as api.ResourceInfo);
}

core.List<api.TraceSpan> buildUnnamed2744() {
  var o = <api.TraceSpan>[];
  o.add(buildTraceSpan());
  o.add(buildTraceSpan());
  return o;
}

void checkUnnamed2744(core.List<api.TraceSpan> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTraceSpan(o[0] as api.TraceSpan);
  checkTraceSpan(o[1] as api.TraceSpan);
}

core.Map<core.String, core.String> buildUnnamed2745() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2745(core.Map<core.String, core.String> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.consumerId = 'foo';
    o.endTime = 'foo';
    o.extensions = buildUnnamed2739();
    o.importance = 'foo';
    o.labels = buildUnnamed2740();
    o.logEntries = buildUnnamed2741();
    o.metricValueSets = buildUnnamed2742();
    o.operationId = 'foo';
    o.operationName = 'foo';
    o.quotaProperties = buildQuotaProperties();
    o.resources = buildUnnamed2743();
    o.startTime = 'foo';
    o.traceSpans = buildUnnamed2744();
    o.userLabels = buildUnnamed2745();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(
      o.consumerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkUnnamed2739(o.extensions!);
    unittest.expect(
      o.importance!,
      unittest.equals('foo'),
    );
    checkUnnamed2740(o.labels!);
    checkUnnamed2741(o.logEntries!);
    checkUnnamed2742(o.metricValueSets!);
    unittest.expect(
      o.operationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationName!,
      unittest.equals('foo'),
    );
    checkQuotaProperties(o.quotaProperties! as api.QuotaProperties);
    checkUnnamed2743(o.resources!);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    checkUnnamed2744(o.traceSpans!);
    checkUnnamed2745(o.userLabels!);
  }
  buildCounterOperation--;
}

core.Map<core.String, core.String> buildUnnamed2746() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2746(core.Map<core.String, core.String> o) {
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

core.int buildCounterPeer = 0;
api.Peer buildPeer() {
  var o = api.Peer();
  buildCounterPeer++;
  if (buildCounterPeer < 3) {
    o.ip = 'foo';
    o.labels = buildUnnamed2746();
    o.port = 'foo';
    o.principal = 'foo';
    o.regionCode = 'foo';
  }
  buildCounterPeer--;
  return o;
}

void checkPeer(api.Peer o) {
  buildCounterPeer++;
  if (buildCounterPeer < 3) {
    unittest.expect(
      o.ip!,
      unittest.equals('foo'),
    );
    checkUnnamed2746(o.labels!);
    unittest.expect(
      o.port!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.principal!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.regionCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterPeer--;
}

core.int buildCounterQuotaError = 0;
api.QuotaError buildQuotaError() {
  var o = api.QuotaError();
  buildCounterQuotaError++;
  if (buildCounterQuotaError < 3) {
    o.code = 'foo';
    o.description = 'foo';
    o.status = buildStatus();
    o.subject = 'foo';
  }
  buildCounterQuotaError--;
  return o;
}

void checkQuotaError(api.QuotaError o) {
  buildCounterQuotaError++;
  if (buildCounterQuotaError < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
    unittest.expect(
      o.subject!,
      unittest.equals('foo'),
    );
  }
  buildCounterQuotaError--;
}

core.List<core.String> buildUnnamed2747() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2747(core.List<core.String> o) {
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

core.Map<core.String, core.int> buildUnnamed2748() {
  var o = <core.String, core.int>{};
  o['x'] = 42;
  o['y'] = 42;
  return o;
}

void checkUnnamed2748(core.Map<core.String, core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals(42),
  );
  unittest.expect(
    o['y']!,
    unittest.equals(42),
  );
}

core.List<api.MetricValueSet> buildUnnamed2749() {
  var o = <api.MetricValueSet>[];
  o.add(buildMetricValueSet());
  o.add(buildMetricValueSet());
  return o;
}

void checkUnnamed2749(core.List<api.MetricValueSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricValueSet(o[0] as api.MetricValueSet);
  checkMetricValueSet(o[1] as api.MetricValueSet);
}

core.int buildCounterQuotaInfo = 0;
api.QuotaInfo buildQuotaInfo() {
  var o = api.QuotaInfo();
  buildCounterQuotaInfo++;
  if (buildCounterQuotaInfo < 3) {
    o.limitExceeded = buildUnnamed2747();
    o.quotaConsumed = buildUnnamed2748();
    o.quotaMetrics = buildUnnamed2749();
  }
  buildCounterQuotaInfo--;
  return o;
}

void checkQuotaInfo(api.QuotaInfo o) {
  buildCounterQuotaInfo++;
  if (buildCounterQuotaInfo < 3) {
    checkUnnamed2747(o.limitExceeded!);
    checkUnnamed2748(o.quotaConsumed!);
    checkUnnamed2749(o.quotaMetrics!);
  }
  buildCounterQuotaInfo--;
}

core.Map<core.String, core.String> buildUnnamed2750() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2750(core.Map<core.String, core.String> o) {
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

core.List<api.MetricValueSet> buildUnnamed2751() {
  var o = <api.MetricValueSet>[];
  o.add(buildMetricValueSet());
  o.add(buildMetricValueSet());
  return o;
}

void checkUnnamed2751(core.List<api.MetricValueSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetricValueSet(o[0] as api.MetricValueSet);
  checkMetricValueSet(o[1] as api.MetricValueSet);
}

core.int buildCounterQuotaOperation = 0;
api.QuotaOperation buildQuotaOperation() {
  var o = api.QuotaOperation();
  buildCounterQuotaOperation++;
  if (buildCounterQuotaOperation < 3) {
    o.consumerId = 'foo';
    o.labels = buildUnnamed2750();
    o.methodName = 'foo';
    o.operationId = 'foo';
    o.quotaMetrics = buildUnnamed2751();
    o.quotaMode = 'foo';
  }
  buildCounterQuotaOperation--;
  return o;
}

void checkQuotaOperation(api.QuotaOperation o) {
  buildCounterQuotaOperation++;
  if (buildCounterQuotaOperation < 3) {
    unittest.expect(
      o.consumerId!,
      unittest.equals('foo'),
    );
    checkUnnamed2750(o.labels!);
    unittest.expect(
      o.methodName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationId!,
      unittest.equals('foo'),
    );
    checkUnnamed2751(o.quotaMetrics!);
    unittest.expect(
      o.quotaMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterQuotaOperation--;
}

core.int buildCounterQuotaProperties = 0;
api.QuotaProperties buildQuotaProperties() {
  var o = api.QuotaProperties();
  buildCounterQuotaProperties++;
  if (buildCounterQuotaProperties < 3) {
    o.quotaMode = 'foo';
  }
  buildCounterQuotaProperties--;
  return o;
}

void checkQuotaProperties(api.QuotaProperties o) {
  buildCounterQuotaProperties++;
  if (buildCounterQuotaProperties < 3) {
    unittest.expect(
      o.quotaMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterQuotaProperties--;
}

core.int buildCounterReportError = 0;
api.ReportError buildReportError() {
  var o = api.ReportError();
  buildCounterReportError++;
  if (buildCounterReportError < 3) {
    o.operationId = 'foo';
    o.status = buildStatus();
  }
  buildCounterReportError--;
  return o;
}

void checkReportError(api.ReportError o) {
  buildCounterReportError++;
  if (buildCounterReportError < 3) {
    unittest.expect(
      o.operationId!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
  }
  buildCounterReportError--;
}

core.List<api.Operation> buildUnnamed2752() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed2752(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterReportRequest = 0;
api.ReportRequest buildReportRequest() {
  var o = api.ReportRequest();
  buildCounterReportRequest++;
  if (buildCounterReportRequest < 3) {
    o.operations = buildUnnamed2752();
    o.serviceConfigId = 'foo';
  }
  buildCounterReportRequest--;
  return o;
}

void checkReportRequest(api.ReportRequest o) {
  buildCounterReportRequest++;
  if (buildCounterReportRequest < 3) {
    checkUnnamed2752(o.operations!);
    unittest.expect(
      o.serviceConfigId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportRequest--;
}

core.List<api.ReportError> buildUnnamed2753() {
  var o = <api.ReportError>[];
  o.add(buildReportError());
  o.add(buildReportError());
  return o;
}

void checkUnnamed2753(core.List<api.ReportError> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportError(o[0] as api.ReportError);
  checkReportError(o[1] as api.ReportError);
}

core.int buildCounterReportResponse = 0;
api.ReportResponse buildReportResponse() {
  var o = api.ReportResponse();
  buildCounterReportResponse++;
  if (buildCounterReportResponse < 3) {
    o.reportErrors = buildUnnamed2753();
    o.serviceConfigId = 'foo';
    o.serviceRolloutId = 'foo';
  }
  buildCounterReportResponse--;
  return o;
}

void checkReportResponse(api.ReportResponse o) {
  buildCounterReportResponse++;
  if (buildCounterReportResponse < 3) {
    checkUnnamed2753(o.reportErrors!);
    unittest.expect(
      o.serviceConfigId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceRolloutId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReportResponse--;
}

core.Map<core.String, core.String> buildUnnamed2754() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2754(core.Map<core.String, core.String> o) {
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

core.int buildCounterRequest = 0;
api.Request buildRequest() {
  var o = api.Request();
  buildCounterRequest++;
  if (buildCounterRequest < 3) {
    o.auth = buildAuth();
    o.headers = buildUnnamed2754();
    o.host = 'foo';
    o.id = 'foo';
    o.method = 'foo';
    o.path = 'foo';
    o.protocol = 'foo';
    o.query = 'foo';
    o.reason = 'foo';
    o.scheme = 'foo';
    o.size = 'foo';
    o.time = 'foo';
  }
  buildCounterRequest--;
  return o;
}

void checkRequest(api.Request o) {
  buildCounterRequest++;
  if (buildCounterRequest < 3) {
    checkAuth(o.auth! as api.Auth);
    checkUnnamed2754(o.headers!);
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.method!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheme!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.time!,
      unittest.equals('foo'),
    );
  }
  buildCounterRequest--;
}

core.int buildCounterRequestMetadata = 0;
api.RequestMetadata buildRequestMetadata() {
  var o = api.RequestMetadata();
  buildCounterRequestMetadata++;
  if (buildCounterRequestMetadata < 3) {
    o.callerIp = 'foo';
    o.callerNetwork = 'foo';
    o.callerSuppliedUserAgent = 'foo';
    o.destinationAttributes = buildPeer();
    o.requestAttributes = buildRequest();
  }
  buildCounterRequestMetadata--;
  return o;
}

void checkRequestMetadata(api.RequestMetadata o) {
  buildCounterRequestMetadata++;
  if (buildCounterRequestMetadata < 3) {
    unittest.expect(
      o.callerIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.callerNetwork!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.callerSuppliedUserAgent!,
      unittest.equals('foo'),
    );
    checkPeer(o.destinationAttributes! as api.Peer);
    checkRequest(o.requestAttributes! as api.Request);
  }
  buildCounterRequestMetadata--;
}

core.Map<core.String, core.String> buildUnnamed2755() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2755(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed2756() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2756(core.Map<core.String, core.String> o) {
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
    o.annotations = buildUnnamed2755();
    o.createTime = 'foo';
    o.deleteTime = 'foo';
    o.displayName = 'foo';
    o.etag = 'foo';
    o.labels = buildUnnamed2756();
    o.location = 'foo';
    o.name = 'foo';
    o.service = 'foo';
    o.type = 'foo';
    o.uid = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterResource--;
  return o;
}

void checkResource(api.Resource o) {
  buildCounterResource++;
  if (buildCounterResource < 3) {
    checkUnnamed2755(o.annotations!);
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
    checkUnnamed2756(o.labels!);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
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
    unittest.expect(
      o.uid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterResource--;
}

core.int buildCounterResourceInfo = 0;
api.ResourceInfo buildResourceInfo() {
  var o = api.ResourceInfo();
  buildCounterResourceInfo++;
  if (buildCounterResourceInfo < 3) {
    o.resourceContainer = 'foo';
    o.resourceLocation = 'foo';
    o.resourceName = 'foo';
  }
  buildCounterResourceInfo--;
  return o;
}

void checkResourceInfo(api.ResourceInfo o) {
  buildCounterResourceInfo++;
  if (buildCounterResourceInfo < 3) {
    unittest.expect(
      o.resourceContainer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceLocation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceInfo--;
}

core.List<core.String> buildUnnamed2757() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2757(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2758() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2758(core.List<core.String> o) {
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

core.int buildCounterResourceLocation = 0;
api.ResourceLocation buildResourceLocation() {
  var o = api.ResourceLocation();
  buildCounterResourceLocation++;
  if (buildCounterResourceLocation < 3) {
    o.currentLocations = buildUnnamed2757();
    o.originalLocations = buildUnnamed2758();
  }
  buildCounterResourceLocation--;
  return o;
}

void checkResourceLocation(api.ResourceLocation o) {
  buildCounterResourceLocation++;
  if (buildCounterResourceLocation < 3) {
    checkUnnamed2757(o.currentLocations!);
    checkUnnamed2758(o.originalLocations!);
  }
  buildCounterResourceLocation--;
}

core.int buildCounterServiceAccountDelegationInfo = 0;
api.ServiceAccountDelegationInfo buildServiceAccountDelegationInfo() {
  var o = api.ServiceAccountDelegationInfo();
  buildCounterServiceAccountDelegationInfo++;
  if (buildCounterServiceAccountDelegationInfo < 3) {
    o.firstPartyPrincipal = buildFirstPartyPrincipal();
    o.principalSubject = 'foo';
    o.thirdPartyPrincipal = buildThirdPartyPrincipal();
  }
  buildCounterServiceAccountDelegationInfo--;
  return o;
}

void checkServiceAccountDelegationInfo(api.ServiceAccountDelegationInfo o) {
  buildCounterServiceAccountDelegationInfo++;
  if (buildCounterServiceAccountDelegationInfo < 3) {
    checkFirstPartyPrincipal(o.firstPartyPrincipal! as api.FirstPartyPrincipal);
    unittest.expect(
      o.principalSubject!,
      unittest.equals('foo'),
    );
    checkThirdPartyPrincipal(o.thirdPartyPrincipal! as api.ThirdPartyPrincipal);
  }
  buildCounterServiceAccountDelegationInfo--;
}

core.int buildCounterSpanContext = 0;
api.SpanContext buildSpanContext() {
  var o = api.SpanContext();
  buildCounterSpanContext++;
  if (buildCounterSpanContext < 3) {
    o.spanName = 'foo';
  }
  buildCounterSpanContext--;
  return o;
}

void checkSpanContext(api.SpanContext o) {
  buildCounterSpanContext++;
  if (buildCounterSpanContext < 3) {
    unittest.expect(
      o.spanName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSpanContext--;
}

core.Map<core.String, core.Object> buildUnnamed2759() {
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

void checkUnnamed2759(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted25 = (o['x']!) as core.Map;
  unittest.expect(casted25, unittest.hasLength(3));
  unittest.expect(
    casted25['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted25['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted25['string'],
    unittest.equals('foo'),
  );
  var casted26 = (o['y']!) as core.Map;
  unittest.expect(casted26, unittest.hasLength(3));
  unittest.expect(
    casted26['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted26['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted26['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed2760() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2759());
  o.add(buildUnnamed2759());
  return o;
}

void checkUnnamed2760(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2759(o[0]);
  checkUnnamed2759(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed2760();
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
    checkUnnamed2760(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.Map<core.String, core.Object> buildUnnamed2761() {
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

void checkUnnamed2761(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted27 = (o['x']!) as core.Map;
  unittest.expect(casted27, unittest.hasLength(3));
  unittest.expect(
    casted27['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted27['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted27['string'],
    unittest.equals('foo'),
  );
  var casted28 = (o['y']!) as core.Map;
  unittest.expect(casted28, unittest.hasLength(3));
  unittest.expect(
    casted28['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted28['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted28['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterThirdPartyPrincipal = 0;
api.ThirdPartyPrincipal buildThirdPartyPrincipal() {
  var o = api.ThirdPartyPrincipal();
  buildCounterThirdPartyPrincipal++;
  if (buildCounterThirdPartyPrincipal < 3) {
    o.thirdPartyClaims = buildUnnamed2761();
  }
  buildCounterThirdPartyPrincipal--;
  return o;
}

void checkThirdPartyPrincipal(api.ThirdPartyPrincipal o) {
  buildCounterThirdPartyPrincipal++;
  if (buildCounterThirdPartyPrincipal < 3) {
    checkUnnamed2761(o.thirdPartyClaims!);
  }
  buildCounterThirdPartyPrincipal--;
}

core.int buildCounterTraceSpan = 0;
api.TraceSpan buildTraceSpan() {
  var o = api.TraceSpan();
  buildCounterTraceSpan++;
  if (buildCounterTraceSpan < 3) {
    o.attributes = buildAttributes();
    o.childSpanCount = 42;
    o.displayName = buildTruncatableString();
    o.endTime = 'foo';
    o.name = 'foo';
    o.parentSpanId = 'foo';
    o.sameProcessAsParentSpan = true;
    o.spanId = 'foo';
    o.spanKind = 'foo';
    o.startTime = 'foo';
    o.status = buildStatus();
  }
  buildCounterTraceSpan--;
  return o;
}

void checkTraceSpan(api.TraceSpan o) {
  buildCounterTraceSpan++;
  if (buildCounterTraceSpan < 3) {
    checkAttributes(o.attributes! as api.Attributes);
    unittest.expect(
      o.childSpanCount!,
      unittest.equals(42),
    );
    checkTruncatableString(o.displayName! as api.TruncatableString);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentSpanId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sameProcessAsParentSpan!, unittest.isTrue);
    unittest.expect(
      o.spanId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.spanKind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
  }
  buildCounterTraceSpan--;
}

core.int buildCounterTruncatableString = 0;
api.TruncatableString buildTruncatableString() {
  var o = api.TruncatableString();
  buildCounterTruncatableString++;
  if (buildCounterTruncatableString < 3) {
    o.truncatedByteCount = 42;
    o.value = 'foo';
  }
  buildCounterTruncatableString--;
  return o;
}

void checkTruncatableString(api.TruncatableString o) {
  buildCounterTruncatableString++;
  if (buildCounterTruncatableString < 3) {
    unittest.expect(
      o.truncatedByteCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterTruncatableString--;
}

void main() {
  unittest.group('obj-schema-AllocateInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAllocateInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AllocateInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAllocateInfo(od as api.AllocateInfo);
    });
  });

  unittest.group('obj-schema-AllocateQuotaRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAllocateQuotaRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AllocateQuotaRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAllocateQuotaRequest(od as api.AllocateQuotaRequest);
    });
  });

  unittest.group('obj-schema-AllocateQuotaResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAllocateQuotaResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AllocateQuotaResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAllocateQuotaResponse(od as api.AllocateQuotaResponse);
    });
  });

  unittest.group('obj-schema-AttributeValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttributeValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AttributeValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAttributeValue(od as api.AttributeValue);
    });
  });

  unittest.group('obj-schema-Attributes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttributes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Attributes.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAttributes(od as api.Attributes);
    });
  });

  unittest.group('obj-schema-AuditLog', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditLog();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AuditLog.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAuditLog(od as api.AuditLog);
    });
  });

  unittest.group('obj-schema-Auth', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuth();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Auth.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAuth(od as api.Auth);
    });
  });

  unittest.group('obj-schema-AuthenticationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthenticationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuthenticationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuthenticationInfo(od as api.AuthenticationInfo);
    });
  });

  unittest.group('obj-schema-AuthorizationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthorizationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuthorizationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuthorizationInfo(od as api.AuthorizationInfo);
    });
  });

  unittest.group('obj-schema-CheckError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCheckError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CheckError.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCheckError(od as api.CheckError);
    });
  });

  unittest.group('obj-schema-CheckInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCheckInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CheckInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCheckInfo(od as api.CheckInfo);
    });
  });

  unittest.group('obj-schema-CheckRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCheckRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CheckRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCheckRequest(od as api.CheckRequest);
    });
  });

  unittest.group('obj-schema-CheckResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCheckResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CheckResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCheckResponse(od as api.CheckResponse);
    });
  });

  unittest.group('obj-schema-ConsumerInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConsumerInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConsumerInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConsumerInfo(od as api.ConsumerInfo);
    });
  });

  unittest.group('obj-schema-Distribution', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDistribution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Distribution.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDistribution(od as api.Distribution);
    });
  });

  unittest.group('obj-schema-Exemplar', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExemplar();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Exemplar.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExemplar(od as api.Exemplar);
    });
  });

  unittest.group('obj-schema-ExplicitBuckets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExplicitBuckets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExplicitBuckets.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExplicitBuckets(od as api.ExplicitBuckets);
    });
  });

  unittest.group('obj-schema-ExponentialBuckets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExponentialBuckets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExponentialBuckets.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExponentialBuckets(od as api.ExponentialBuckets);
    });
  });

  unittest.group('obj-schema-FirstPartyPrincipal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFirstPartyPrincipal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FirstPartyPrincipal.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFirstPartyPrincipal(od as api.FirstPartyPrincipal);
    });
  });

  unittest.group('obj-schema-HttpRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHttpRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HttpRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHttpRequest(od as api.HttpRequest);
    });
  });

  unittest.group('obj-schema-LinearBuckets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLinearBuckets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LinearBuckets.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLinearBuckets(od as api.LinearBuckets);
    });
  });

  unittest.group('obj-schema-LogEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLogEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LogEntry.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLogEntry(od as api.LogEntry);
    });
  });

  unittest.group('obj-schema-LogEntryOperation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLogEntryOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LogEntryOperation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLogEntryOperation(od as api.LogEntryOperation);
    });
  });

  unittest.group('obj-schema-LogEntrySourceLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLogEntrySourceLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LogEntrySourceLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLogEntrySourceLocation(od as api.LogEntrySourceLocation);
    });
  });

  unittest.group('obj-schema-MetricValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetricValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetricValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetricValue(od as api.MetricValue);
    });
  });

  unittest.group('obj-schema-MetricValueSet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetricValueSet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetricValueSet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetricValueSet(od as api.MetricValueSet);
    });
  });

  unittest.group('obj-schema-Money', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoney();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Money.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMoney(od as api.Money);
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

  unittest.group('obj-schema-Peer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPeer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Peer.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPeer(od as api.Peer);
    });
  });

  unittest.group('obj-schema-QuotaError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuotaError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.QuotaError.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkQuotaError(od as api.QuotaError);
    });
  });

  unittest.group('obj-schema-QuotaInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuotaInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.QuotaInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkQuotaInfo(od as api.QuotaInfo);
    });
  });

  unittest.group('obj-schema-QuotaOperation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuotaOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QuotaOperation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQuotaOperation(od as api.QuotaOperation);
    });
  });

  unittest.group('obj-schema-QuotaProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuotaProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QuotaProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQuotaProperties(od as api.QuotaProperties);
    });
  });

  unittest.group('obj-schema-ReportError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportError(od as api.ReportError);
    });
  });

  unittest.group('obj-schema-ReportRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportRequest(od as api.ReportRequest);
    });
  });

  unittest.group('obj-schema-ReportResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReportResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReportResponse(od as api.ReportResponse);
    });
  });

  unittest.group('obj-schema-Request', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Request.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRequest(od as api.Request);
    });
  });

  unittest.group('obj-schema-RequestMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequestMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RequestMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRequestMetadata(od as api.RequestMetadata);
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

  unittest.group('obj-schema-ResourceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceInfo(od as api.ResourceInfo);
    });
  });

  unittest.group('obj-schema-ResourceLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceLocation(od as api.ResourceLocation);
    });
  });

  unittest.group('obj-schema-ServiceAccountDelegationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildServiceAccountDelegationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ServiceAccountDelegationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkServiceAccountDelegationInfo(od as api.ServiceAccountDelegationInfo);
    });
  });

  unittest.group('obj-schema-SpanContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpanContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpanContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpanContext(od as api.SpanContext);
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

  unittest.group('obj-schema-ThirdPartyPrincipal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThirdPartyPrincipal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThirdPartyPrincipal.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThirdPartyPrincipal(od as api.ThirdPartyPrincipal);
    });
  });

  unittest.group('obj-schema-TraceSpan', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTraceSpan();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TraceSpan.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTraceSpan(od as api.TraceSpan);
    });
  });

  unittest.group('obj-schema-TruncatableString', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTruncatableString();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TruncatableString.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTruncatableString(od as api.TruncatableString);
    });
  });

  unittest.group('resource-ServicesResource', () {
    unittest.test('method--allocateQuota', () async {
      var mock = HttpServerMock();
      var res = api.ServiceControlApi(mock).services;
      var arg_request = buildAllocateQuotaRequest();
      var arg_serviceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AllocateQuotaRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAllocateQuotaRequest(obj as api.AllocateQuotaRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/services/"),
        );
        pathOffset += 12;
        index = path.indexOf(':allocateQuota', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_serviceName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals(":allocateQuota"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAllocateQuotaResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.allocateQuota(arg_request, arg_serviceName,
          $fields: arg_$fields);
      checkAllocateQuotaResponse(response as api.AllocateQuotaResponse);
    });

    unittest.test('method--check', () async {
      var mock = HttpServerMock();
      var res = api.ServiceControlApi(mock).services;
      var arg_request = buildCheckRequest();
      var arg_serviceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CheckRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCheckRequest(obj as api.CheckRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/services/"),
        );
        pathOffset += 12;
        index = path.indexOf(':check', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_serviceName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals(":check"),
        );
        pathOffset += 6;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildCheckResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.check(arg_request, arg_serviceName, $fields: arg_$fields);
      checkCheckResponse(response as api.CheckResponse);
    });

    unittest.test('method--report', () async {
      var mock = HttpServerMock();
      var res = api.ServiceControlApi(mock).services;
      var arg_request = buildReportRequest();
      var arg_serviceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReportRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReportRequest(obj as api.ReportRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/services/"),
        );
        pathOffset += 12;
        index = path.indexOf(':report', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_serviceName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":report"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildReportResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.report(arg_request, arg_serviceName, $fields: arg_$fields);
      checkReportResponse(response as api.ReportResponse);
    });
  });
}

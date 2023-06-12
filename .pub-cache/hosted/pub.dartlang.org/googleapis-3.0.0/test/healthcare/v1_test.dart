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

import 'package:googleapis/healthcare/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterActivateConsentRequest = 0;
api.ActivateConsentRequest buildActivateConsentRequest() {
  var o = api.ActivateConsentRequest();
  buildCounterActivateConsentRequest++;
  if (buildCounterActivateConsentRequest < 3) {
    o.consentArtifact = 'foo';
    o.expireTime = 'foo';
    o.ttl = 'foo';
  }
  buildCounterActivateConsentRequest--;
  return o;
}

void checkActivateConsentRequest(api.ActivateConsentRequest o) {
  buildCounterActivateConsentRequest++;
  if (buildCounterActivateConsentRequest < 3) {
    unittest.expect(
      o.consentArtifact!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ttl!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivateConsentRequest--;
}

core.int buildCounterArchiveUserDataMappingRequest = 0;
api.ArchiveUserDataMappingRequest buildArchiveUserDataMappingRequest() {
  var o = api.ArchiveUserDataMappingRequest();
  buildCounterArchiveUserDataMappingRequest++;
  if (buildCounterArchiveUserDataMappingRequest < 3) {}
  buildCounterArchiveUserDataMappingRequest--;
  return o;
}

void checkArchiveUserDataMappingRequest(api.ArchiveUserDataMappingRequest o) {
  buildCounterArchiveUserDataMappingRequest++;
  if (buildCounterArchiveUserDataMappingRequest < 3) {}
  buildCounterArchiveUserDataMappingRequest--;
}

core.int buildCounterArchiveUserDataMappingResponse = 0;
api.ArchiveUserDataMappingResponse buildArchiveUserDataMappingResponse() {
  var o = api.ArchiveUserDataMappingResponse();
  buildCounterArchiveUserDataMappingResponse++;
  if (buildCounterArchiveUserDataMappingResponse < 3) {}
  buildCounterArchiveUserDataMappingResponse--;
  return o;
}

void checkArchiveUserDataMappingResponse(api.ArchiveUserDataMappingResponse o) {
  buildCounterArchiveUserDataMappingResponse++;
  if (buildCounterArchiveUserDataMappingResponse < 3) {}
  buildCounterArchiveUserDataMappingResponse--;
}

core.List<core.String> buildUnnamed3259() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3259(core.List<core.String> o) {
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

core.int buildCounterAttribute = 0;
api.Attribute buildAttribute() {
  var o = api.Attribute();
  buildCounterAttribute++;
  if (buildCounterAttribute < 3) {
    o.attributeDefinitionId = 'foo';
    o.values = buildUnnamed3259();
  }
  buildCounterAttribute--;
  return o;
}

void checkAttribute(api.Attribute o) {
  buildCounterAttribute++;
  if (buildCounterAttribute < 3) {
    unittest.expect(
      o.attributeDefinitionId!,
      unittest.equals('foo'),
    );
    checkUnnamed3259(o.values!);
  }
  buildCounterAttribute--;
}

core.List<core.String> buildUnnamed3260() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3260(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3261() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3261(core.List<core.String> o) {
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

core.int buildCounterAttributeDefinition = 0;
api.AttributeDefinition buildAttributeDefinition() {
  var o = api.AttributeDefinition();
  buildCounterAttributeDefinition++;
  if (buildCounterAttributeDefinition < 3) {
    o.allowedValues = buildUnnamed3260();
    o.category = 'foo';
    o.consentDefaultValues = buildUnnamed3261();
    o.dataMappingDefaultValue = 'foo';
    o.description = 'foo';
    o.name = 'foo';
  }
  buildCounterAttributeDefinition--;
  return o;
}

void checkAttributeDefinition(api.AttributeDefinition o) {
  buildCounterAttributeDefinition++;
  if (buildCounterAttributeDefinition < 3) {
    checkUnnamed3260(o.allowedValues!);
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    checkUnnamed3261(o.consentDefaultValues!);
    unittest.expect(
      o.dataMappingDefaultValue!,
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
  }
  buildCounterAttributeDefinition--;
}

core.List<api.AuditLogConfig> buildUnnamed3262() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed3262(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed3262();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed3262(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed3263() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3263(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed3263();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed3263(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed3264() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3264(core.List<core.String> o) {
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
    o.members = buildUnnamed3264();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed3264(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterCancelOperationRequest = 0;
api.CancelOperationRequest buildCancelOperationRequest() {
  var o = api.CancelOperationRequest();
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
  return o;
}

void checkCancelOperationRequest(api.CancelOperationRequest o) {
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
}

core.int buildCounterCharacterMaskConfig = 0;
api.CharacterMaskConfig buildCharacterMaskConfig() {
  var o = api.CharacterMaskConfig();
  buildCounterCharacterMaskConfig++;
  if (buildCounterCharacterMaskConfig < 3) {
    o.maskingCharacter = 'foo';
  }
  buildCounterCharacterMaskConfig--;
  return o;
}

void checkCharacterMaskConfig(api.CharacterMaskConfig o) {
  buildCounterCharacterMaskConfig++;
  if (buildCounterCharacterMaskConfig < 3) {
    unittest.expect(
      o.maskingCharacter!,
      unittest.equals('foo'),
    );
  }
  buildCounterCharacterMaskConfig--;
}

core.Map<core.String, core.String> buildUnnamed3265() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3265(core.Map<core.String, core.String> o) {
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

core.int buildCounterCheckDataAccessRequest = 0;
api.CheckDataAccessRequest buildCheckDataAccessRequest() {
  var o = api.CheckDataAccessRequest();
  buildCounterCheckDataAccessRequest++;
  if (buildCounterCheckDataAccessRequest < 3) {
    o.consentList = buildConsentList();
    o.dataId = 'foo';
    o.requestAttributes = buildUnnamed3265();
    o.responseView = 'foo';
  }
  buildCounterCheckDataAccessRequest--;
  return o;
}

void checkCheckDataAccessRequest(api.CheckDataAccessRequest o) {
  buildCounterCheckDataAccessRequest++;
  if (buildCounterCheckDataAccessRequest < 3) {
    checkConsentList(o.consentList! as api.ConsentList);
    unittest.expect(
      o.dataId!,
      unittest.equals('foo'),
    );
    checkUnnamed3265(o.requestAttributes!);
    unittest.expect(
      o.responseView!,
      unittest.equals('foo'),
    );
  }
  buildCounterCheckDataAccessRequest--;
}

core.Map<core.String, api.ConsentEvaluation> buildUnnamed3266() {
  var o = <core.String, api.ConsentEvaluation>{};
  o['x'] = buildConsentEvaluation();
  o['y'] = buildConsentEvaluation();
  return o;
}

void checkUnnamed3266(core.Map<core.String, api.ConsentEvaluation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConsentEvaluation(o['x']! as api.ConsentEvaluation);
  checkConsentEvaluation(o['y']! as api.ConsentEvaluation);
}

core.int buildCounterCheckDataAccessResponse = 0;
api.CheckDataAccessResponse buildCheckDataAccessResponse() {
  var o = api.CheckDataAccessResponse();
  buildCounterCheckDataAccessResponse++;
  if (buildCounterCheckDataAccessResponse < 3) {
    o.consentDetails = buildUnnamed3266();
    o.consented = true;
  }
  buildCounterCheckDataAccessResponse--;
  return o;
}

void checkCheckDataAccessResponse(api.CheckDataAccessResponse o) {
  buildCounterCheckDataAccessResponse++;
  if (buildCounterCheckDataAccessResponse < 3) {
    checkUnnamed3266(o.consentDetails!);
    unittest.expect(o.consented!, unittest.isTrue);
  }
  buildCounterCheckDataAccessResponse--;
}

core.Map<core.String, core.String> buildUnnamed3267() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3267(core.Map<core.String, core.String> o) {
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

core.List<api.GoogleCloudHealthcareV1ConsentPolicy> buildUnnamed3268() {
  var o = <api.GoogleCloudHealthcareV1ConsentPolicy>[];
  o.add(buildGoogleCloudHealthcareV1ConsentPolicy());
  o.add(buildGoogleCloudHealthcareV1ConsentPolicy());
  return o;
}

void checkUnnamed3268(core.List<api.GoogleCloudHealthcareV1ConsentPolicy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudHealthcareV1ConsentPolicy(
      o[0] as api.GoogleCloudHealthcareV1ConsentPolicy);
  checkGoogleCloudHealthcareV1ConsentPolicy(
      o[1] as api.GoogleCloudHealthcareV1ConsentPolicy);
}

core.int buildCounterConsent = 0;
api.Consent buildConsent() {
  var o = api.Consent();
  buildCounterConsent++;
  if (buildCounterConsent < 3) {
    o.consentArtifact = 'foo';
    o.expireTime = 'foo';
    o.metadata = buildUnnamed3267();
    o.name = 'foo';
    o.policies = buildUnnamed3268();
    o.revisionCreateTime = 'foo';
    o.revisionId = 'foo';
    o.state = 'foo';
    o.ttl = 'foo';
    o.userId = 'foo';
  }
  buildCounterConsent--;
  return o;
}

void checkConsent(api.Consent o) {
  buildCounterConsent++;
  if (buildCounterConsent < 3) {
    unittest.expect(
      o.consentArtifact!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    checkUnnamed3267(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3268(o.policies!);
    unittest.expect(
      o.revisionCreateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ttl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterConsent--;
}

core.List<api.Image> buildUnnamed3269() {
  var o = <api.Image>[];
  o.add(buildImage());
  o.add(buildImage());
  return o;
}

void checkUnnamed3269(core.List<api.Image> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImage(o[0] as api.Image);
  checkImage(o[1] as api.Image);
}

core.Map<core.String, core.String> buildUnnamed3270() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3270(core.Map<core.String, core.String> o) {
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

core.int buildCounterConsentArtifact = 0;
api.ConsentArtifact buildConsentArtifact() {
  var o = api.ConsentArtifact();
  buildCounterConsentArtifact++;
  if (buildCounterConsentArtifact < 3) {
    o.consentContentScreenshots = buildUnnamed3269();
    o.consentContentVersion = 'foo';
    o.guardianSignature = buildSignature();
    o.metadata = buildUnnamed3270();
    o.name = 'foo';
    o.userId = 'foo';
    o.userSignature = buildSignature();
    o.witnessSignature = buildSignature();
  }
  buildCounterConsentArtifact--;
  return o;
}

void checkConsentArtifact(api.ConsentArtifact o) {
  buildCounterConsentArtifact++;
  if (buildCounterConsentArtifact < 3) {
    checkUnnamed3269(o.consentContentScreenshots!);
    unittest.expect(
      o.consentContentVersion!,
      unittest.equals('foo'),
    );
    checkSignature(o.guardianSignature! as api.Signature);
    checkUnnamed3270(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
    checkSignature(o.userSignature! as api.Signature);
    checkSignature(o.witnessSignature! as api.Signature);
  }
  buildCounterConsentArtifact--;
}

core.int buildCounterConsentEvaluation = 0;
api.ConsentEvaluation buildConsentEvaluation() {
  var o = api.ConsentEvaluation();
  buildCounterConsentEvaluation++;
  if (buildCounterConsentEvaluation < 3) {
    o.evaluationResult = 'foo';
  }
  buildCounterConsentEvaluation--;
  return o;
}

void checkConsentEvaluation(api.ConsentEvaluation o) {
  buildCounterConsentEvaluation++;
  if (buildCounterConsentEvaluation < 3) {
    unittest.expect(
      o.evaluationResult!,
      unittest.equals('foo'),
    );
  }
  buildCounterConsentEvaluation--;
}

core.List<core.String> buildUnnamed3271() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3271(core.List<core.String> o) {
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

core.int buildCounterConsentList = 0;
api.ConsentList buildConsentList() {
  var o = api.ConsentList();
  buildCounterConsentList++;
  if (buildCounterConsentList < 3) {
    o.consents = buildUnnamed3271();
  }
  buildCounterConsentList--;
  return o;
}

void checkConsentList(api.ConsentList o) {
  buildCounterConsentList++;
  if (buildCounterConsentList < 3) {
    checkUnnamed3271(o.consents!);
  }
  buildCounterConsentList--;
}

core.Map<core.String, core.String> buildUnnamed3272() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3272(core.Map<core.String, core.String> o) {
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

core.int buildCounterConsentStore = 0;
api.ConsentStore buildConsentStore() {
  var o = api.ConsentStore();
  buildCounterConsentStore++;
  if (buildCounterConsentStore < 3) {
    o.defaultConsentTtl = 'foo';
    o.enableConsentCreateOnUpdate = true;
    o.labels = buildUnnamed3272();
    o.name = 'foo';
  }
  buildCounterConsentStore--;
  return o;
}

void checkConsentStore(api.ConsentStore o) {
  buildCounterConsentStore++;
  if (buildCounterConsentStore < 3) {
    unittest.expect(
      o.defaultConsentTtl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableConsentCreateOnUpdate!, unittest.isTrue);
    checkUnnamed3272(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterConsentStore--;
}

core.int buildCounterCreateMessageRequest = 0;
api.CreateMessageRequest buildCreateMessageRequest() {
  var o = api.CreateMessageRequest();
  buildCounterCreateMessageRequest++;
  if (buildCounterCreateMessageRequest < 3) {
    o.message = buildMessage();
  }
  buildCounterCreateMessageRequest--;
  return o;
}

void checkCreateMessageRequest(api.CreateMessageRequest o) {
  buildCounterCreateMessageRequest++;
  if (buildCounterCreateMessageRequest < 3) {
    checkMessage(o.message! as api.Message);
  }
  buildCounterCreateMessageRequest--;
}

core.int buildCounterCryptoHashConfig = 0;
api.CryptoHashConfig buildCryptoHashConfig() {
  var o = api.CryptoHashConfig();
  buildCounterCryptoHashConfig++;
  if (buildCounterCryptoHashConfig < 3) {
    o.cryptoKey = 'foo';
  }
  buildCounterCryptoHashConfig--;
  return o;
}

void checkCryptoHashConfig(api.CryptoHashConfig o) {
  buildCounterCryptoHashConfig++;
  if (buildCounterCryptoHashConfig < 3) {
    unittest.expect(
      o.cryptoKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterCryptoHashConfig--;
}

core.int buildCounterDataset = 0;
api.Dataset buildDataset() {
  var o = api.Dataset();
  buildCounterDataset++;
  if (buildCounterDataset < 3) {
    o.name = 'foo';
    o.timeZone = 'foo';
  }
  buildCounterDataset--;
  return o;
}

void checkDataset(api.Dataset o) {
  buildCounterDataset++;
  if (buildCounterDataset < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataset--;
}

core.int buildCounterDateShiftConfig = 0;
api.DateShiftConfig buildDateShiftConfig() {
  var o = api.DateShiftConfig();
  buildCounterDateShiftConfig++;
  if (buildCounterDateShiftConfig < 3) {
    o.cryptoKey = 'foo';
  }
  buildCounterDateShiftConfig--;
  return o;
}

void checkDateShiftConfig(api.DateShiftConfig o) {
  buildCounterDateShiftConfig++;
  if (buildCounterDateShiftConfig < 3) {
    unittest.expect(
      o.cryptoKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterDateShiftConfig--;
}

core.int buildCounterDeidentifyConfig = 0;
api.DeidentifyConfig buildDeidentifyConfig() {
  var o = api.DeidentifyConfig();
  buildCounterDeidentifyConfig++;
  if (buildCounterDeidentifyConfig < 3) {
    o.dicom = buildDicomConfig();
    o.fhir = buildFhirConfig();
    o.image = buildImageConfig();
    o.text = buildTextConfig();
  }
  buildCounterDeidentifyConfig--;
  return o;
}

void checkDeidentifyConfig(api.DeidentifyConfig o) {
  buildCounterDeidentifyConfig++;
  if (buildCounterDeidentifyConfig < 3) {
    checkDicomConfig(o.dicom! as api.DicomConfig);
    checkFhirConfig(o.fhir! as api.FhirConfig);
    checkImageConfig(o.image! as api.ImageConfig);
    checkTextConfig(o.text! as api.TextConfig);
  }
  buildCounterDeidentifyConfig--;
}

core.int buildCounterDeidentifyDatasetRequest = 0;
api.DeidentifyDatasetRequest buildDeidentifyDatasetRequest() {
  var o = api.DeidentifyDatasetRequest();
  buildCounterDeidentifyDatasetRequest++;
  if (buildCounterDeidentifyDatasetRequest < 3) {
    o.config = buildDeidentifyConfig();
    o.destinationDataset = 'foo';
  }
  buildCounterDeidentifyDatasetRequest--;
  return o;
}

void checkDeidentifyDatasetRequest(api.DeidentifyDatasetRequest o) {
  buildCounterDeidentifyDatasetRequest++;
  if (buildCounterDeidentifyDatasetRequest < 3) {
    checkDeidentifyConfig(o.config! as api.DeidentifyConfig);
    unittest.expect(
      o.destinationDataset!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeidentifyDatasetRequest--;
}

core.int buildCounterDeidentifyDicomStoreRequest = 0;
api.DeidentifyDicomStoreRequest buildDeidentifyDicomStoreRequest() {
  var o = api.DeidentifyDicomStoreRequest();
  buildCounterDeidentifyDicomStoreRequest++;
  if (buildCounterDeidentifyDicomStoreRequest < 3) {
    o.config = buildDeidentifyConfig();
    o.destinationStore = 'foo';
    o.filterConfig = buildDicomFilterConfig();
  }
  buildCounterDeidentifyDicomStoreRequest--;
  return o;
}

void checkDeidentifyDicomStoreRequest(api.DeidentifyDicomStoreRequest o) {
  buildCounterDeidentifyDicomStoreRequest++;
  if (buildCounterDeidentifyDicomStoreRequest < 3) {
    checkDeidentifyConfig(o.config! as api.DeidentifyConfig);
    unittest.expect(
      o.destinationStore!,
      unittest.equals('foo'),
    );
    checkDicomFilterConfig(o.filterConfig! as api.DicomFilterConfig);
  }
  buildCounterDeidentifyDicomStoreRequest--;
}

core.int buildCounterDeidentifyFhirStoreRequest = 0;
api.DeidentifyFhirStoreRequest buildDeidentifyFhirStoreRequest() {
  var o = api.DeidentifyFhirStoreRequest();
  buildCounterDeidentifyFhirStoreRequest++;
  if (buildCounterDeidentifyFhirStoreRequest < 3) {
    o.config = buildDeidentifyConfig();
    o.destinationStore = 'foo';
    o.resourceFilter = buildFhirFilter();
  }
  buildCounterDeidentifyFhirStoreRequest--;
  return o;
}

void checkDeidentifyFhirStoreRequest(api.DeidentifyFhirStoreRequest o) {
  buildCounterDeidentifyFhirStoreRequest++;
  if (buildCounterDeidentifyFhirStoreRequest < 3) {
    checkDeidentifyConfig(o.config! as api.DeidentifyConfig);
    unittest.expect(
      o.destinationStore!,
      unittest.equals('foo'),
    );
    checkFhirFilter(o.resourceFilter! as api.FhirFilter);
  }
  buildCounterDeidentifyFhirStoreRequest--;
}

core.int buildCounterDeidentifySummary = 0;
api.DeidentifySummary buildDeidentifySummary() {
  var o = api.DeidentifySummary();
  buildCounterDeidentifySummary++;
  if (buildCounterDeidentifySummary < 3) {}
  buildCounterDeidentifySummary--;
  return o;
}

void checkDeidentifySummary(api.DeidentifySummary o) {
  buildCounterDeidentifySummary++;
  if (buildCounterDeidentifySummary < 3) {}
  buildCounterDeidentifySummary--;
}

core.int buildCounterDicomConfig = 0;
api.DicomConfig buildDicomConfig() {
  var o = api.DicomConfig();
  buildCounterDicomConfig++;
  if (buildCounterDicomConfig < 3) {
    o.filterProfile = 'foo';
    o.keepList = buildTagFilterList();
    o.removeList = buildTagFilterList();
    o.skipIdRedaction = true;
  }
  buildCounterDicomConfig--;
  return o;
}

void checkDicomConfig(api.DicomConfig o) {
  buildCounterDicomConfig++;
  if (buildCounterDicomConfig < 3) {
    unittest.expect(
      o.filterProfile!,
      unittest.equals('foo'),
    );
    checkTagFilterList(o.keepList! as api.TagFilterList);
    checkTagFilterList(o.removeList! as api.TagFilterList);
    unittest.expect(o.skipIdRedaction!, unittest.isTrue);
  }
  buildCounterDicomConfig--;
}

core.int buildCounterDicomFilterConfig = 0;
api.DicomFilterConfig buildDicomFilterConfig() {
  var o = api.DicomFilterConfig();
  buildCounterDicomFilterConfig++;
  if (buildCounterDicomFilterConfig < 3) {
    o.resourcePathsGcsUri = 'foo';
  }
  buildCounterDicomFilterConfig--;
  return o;
}

void checkDicomFilterConfig(api.DicomFilterConfig o) {
  buildCounterDicomFilterConfig++;
  if (buildCounterDicomFilterConfig < 3) {
    unittest.expect(
      o.resourcePathsGcsUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterDicomFilterConfig--;
}

core.Map<core.String, core.String> buildUnnamed3273() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3273(core.Map<core.String, core.String> o) {
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

core.int buildCounterDicomStore = 0;
api.DicomStore buildDicomStore() {
  var o = api.DicomStore();
  buildCounterDicomStore++;
  if (buildCounterDicomStore < 3) {
    o.labels = buildUnnamed3273();
    o.name = 'foo';
    o.notificationConfig = buildNotificationConfig();
  }
  buildCounterDicomStore--;
  return o;
}

void checkDicomStore(api.DicomStore o) {
  buildCounterDicomStore++;
  if (buildCounterDicomStore < 3) {
    checkUnnamed3273(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkNotificationConfig(o.notificationConfig! as api.NotificationConfig);
  }
  buildCounterDicomStore--;
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

core.Map<core.String, core.String> buildUnnamed3274() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3274(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed3275() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3275(core.Map<core.String, core.String> o) {
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

core.int buildCounterEvaluateUserConsentsRequest = 0;
api.EvaluateUserConsentsRequest buildEvaluateUserConsentsRequest() {
  var o = api.EvaluateUserConsentsRequest();
  buildCounterEvaluateUserConsentsRequest++;
  if (buildCounterEvaluateUserConsentsRequest < 3) {
    o.consentList = buildConsentList();
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.requestAttributes = buildUnnamed3274();
    o.resourceAttributes = buildUnnamed3275();
    o.responseView = 'foo';
    o.userId = 'foo';
  }
  buildCounterEvaluateUserConsentsRequest--;
  return o;
}

void checkEvaluateUserConsentsRequest(api.EvaluateUserConsentsRequest o) {
  buildCounterEvaluateUserConsentsRequest++;
  if (buildCounterEvaluateUserConsentsRequest < 3) {
    checkConsentList(o.consentList! as api.ConsentList);
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3274(o.requestAttributes!);
    checkUnnamed3275(o.resourceAttributes!);
    unittest.expect(
      o.responseView!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterEvaluateUserConsentsRequest--;
}

core.List<api.Result> buildUnnamed3276() {
  var o = <api.Result>[];
  o.add(buildResult());
  o.add(buildResult());
  return o;
}

void checkUnnamed3276(core.List<api.Result> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResult(o[0] as api.Result);
  checkResult(o[1] as api.Result);
}

core.int buildCounterEvaluateUserConsentsResponse = 0;
api.EvaluateUserConsentsResponse buildEvaluateUserConsentsResponse() {
  var o = api.EvaluateUserConsentsResponse();
  buildCounterEvaluateUserConsentsResponse++;
  if (buildCounterEvaluateUserConsentsResponse < 3) {
    o.nextPageToken = 'foo';
    o.results = buildUnnamed3276();
  }
  buildCounterEvaluateUserConsentsResponse--;
  return o;
}

void checkEvaluateUserConsentsResponse(api.EvaluateUserConsentsResponse o) {
  buildCounterEvaluateUserConsentsResponse++;
  if (buildCounterEvaluateUserConsentsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3276(o.results!);
  }
  buildCounterEvaluateUserConsentsResponse--;
}

core.int buildCounterExportDicomDataRequest = 0;
api.ExportDicomDataRequest buildExportDicomDataRequest() {
  var o = api.ExportDicomDataRequest();
  buildCounterExportDicomDataRequest++;
  if (buildCounterExportDicomDataRequest < 3) {
    o.bigqueryDestination =
        buildGoogleCloudHealthcareV1DicomBigQueryDestination();
    o.gcsDestination = buildGoogleCloudHealthcareV1DicomGcsDestination();
  }
  buildCounterExportDicomDataRequest--;
  return o;
}

void checkExportDicomDataRequest(api.ExportDicomDataRequest o) {
  buildCounterExportDicomDataRequest++;
  if (buildCounterExportDicomDataRequest < 3) {
    checkGoogleCloudHealthcareV1DicomBigQueryDestination(o.bigqueryDestination!
        as api.GoogleCloudHealthcareV1DicomBigQueryDestination);
    checkGoogleCloudHealthcareV1DicomGcsDestination(
        o.gcsDestination! as api.GoogleCloudHealthcareV1DicomGcsDestination);
  }
  buildCounterExportDicomDataRequest--;
}

core.int buildCounterExportDicomDataResponse = 0;
api.ExportDicomDataResponse buildExportDicomDataResponse() {
  var o = api.ExportDicomDataResponse();
  buildCounterExportDicomDataResponse++;
  if (buildCounterExportDicomDataResponse < 3) {}
  buildCounterExportDicomDataResponse--;
  return o;
}

void checkExportDicomDataResponse(api.ExportDicomDataResponse o) {
  buildCounterExportDicomDataResponse++;
  if (buildCounterExportDicomDataResponse < 3) {}
  buildCounterExportDicomDataResponse--;
}

core.int buildCounterExportResourcesRequest = 0;
api.ExportResourcesRequest buildExportResourcesRequest() {
  var o = api.ExportResourcesRequest();
  buildCounterExportResourcesRequest++;
  if (buildCounterExportResourcesRequest < 3) {
    o.bigqueryDestination =
        buildGoogleCloudHealthcareV1FhirBigQueryDestination();
    o.gcsDestination = buildGoogleCloudHealthcareV1FhirGcsDestination();
  }
  buildCounterExportResourcesRequest--;
  return o;
}

void checkExportResourcesRequest(api.ExportResourcesRequest o) {
  buildCounterExportResourcesRequest++;
  if (buildCounterExportResourcesRequest < 3) {
    checkGoogleCloudHealthcareV1FhirBigQueryDestination(o.bigqueryDestination!
        as api.GoogleCloudHealthcareV1FhirBigQueryDestination);
    checkGoogleCloudHealthcareV1FhirGcsDestination(
        o.gcsDestination! as api.GoogleCloudHealthcareV1FhirGcsDestination);
  }
  buildCounterExportResourcesRequest--;
}

core.int buildCounterExportResourcesResponse = 0;
api.ExportResourcesResponse buildExportResourcesResponse() {
  var o = api.ExportResourcesResponse();
  buildCounterExportResourcesResponse++;
  if (buildCounterExportResourcesResponse < 3) {}
  buildCounterExportResourcesResponse--;
  return o;
}

void checkExportResourcesResponse(api.ExportResourcesResponse o) {
  buildCounterExportResourcesResponse++;
  if (buildCounterExportResourcesResponse < 3) {}
  buildCounterExportResourcesResponse--;
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

core.List<api.FieldMetadata> buildUnnamed3277() {
  var o = <api.FieldMetadata>[];
  o.add(buildFieldMetadata());
  o.add(buildFieldMetadata());
  return o;
}

void checkUnnamed3277(core.List<api.FieldMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFieldMetadata(o[0] as api.FieldMetadata);
  checkFieldMetadata(o[1] as api.FieldMetadata);
}

core.int buildCounterFhirConfig = 0;
api.FhirConfig buildFhirConfig() {
  var o = api.FhirConfig();
  buildCounterFhirConfig++;
  if (buildCounterFhirConfig < 3) {
    o.fieldMetadataList = buildUnnamed3277();
  }
  buildCounterFhirConfig--;
  return o;
}

void checkFhirConfig(api.FhirConfig o) {
  buildCounterFhirConfig++;
  if (buildCounterFhirConfig < 3) {
    checkUnnamed3277(o.fieldMetadataList!);
  }
  buildCounterFhirConfig--;
}

core.int buildCounterFhirFilter = 0;
api.FhirFilter buildFhirFilter() {
  var o = api.FhirFilter();
  buildCounterFhirFilter++;
  if (buildCounterFhirFilter < 3) {
    o.resources = buildResources();
  }
  buildCounterFhirFilter--;
  return o;
}

void checkFhirFilter(api.FhirFilter o) {
  buildCounterFhirFilter++;
  if (buildCounterFhirFilter < 3) {
    checkResources(o.resources! as api.Resources);
  }
  buildCounterFhirFilter--;
}

core.Map<core.String, core.String> buildUnnamed3278() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3278(core.Map<core.String, core.String> o) {
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

core.List<api.StreamConfig> buildUnnamed3279() {
  var o = <api.StreamConfig>[];
  o.add(buildStreamConfig());
  o.add(buildStreamConfig());
  return o;
}

void checkUnnamed3279(core.List<api.StreamConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStreamConfig(o[0] as api.StreamConfig);
  checkStreamConfig(o[1] as api.StreamConfig);
}

core.int buildCounterFhirStore = 0;
api.FhirStore buildFhirStore() {
  var o = api.FhirStore();
  buildCounterFhirStore++;
  if (buildCounterFhirStore < 3) {
    o.defaultSearchHandlingStrict = true;
    o.disableReferentialIntegrity = true;
    o.disableResourceVersioning = true;
    o.enableUpdateCreate = true;
    o.labels = buildUnnamed3278();
    o.name = 'foo';
    o.notificationConfig = buildNotificationConfig();
    o.streamConfigs = buildUnnamed3279();
    o.version = 'foo';
  }
  buildCounterFhirStore--;
  return o;
}

void checkFhirStore(api.FhirStore o) {
  buildCounterFhirStore++;
  if (buildCounterFhirStore < 3) {
    unittest.expect(o.defaultSearchHandlingStrict!, unittest.isTrue);
    unittest.expect(o.disableReferentialIntegrity!, unittest.isTrue);
    unittest.expect(o.disableResourceVersioning!, unittest.isTrue);
    unittest.expect(o.enableUpdateCreate!, unittest.isTrue);
    checkUnnamed3278(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkNotificationConfig(o.notificationConfig! as api.NotificationConfig);
    checkUnnamed3279(o.streamConfigs!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterFhirStore--;
}

core.int buildCounterField = 0;
api.Field buildField() {
  var o = api.Field();
  buildCounterField++;
  if (buildCounterField < 3) {
    o.maxOccurs = 42;
    o.minOccurs = 42;
    o.name = 'foo';
    o.table = 'foo';
    o.type = 'foo';
  }
  buildCounterField--;
  return o;
}

void checkField(api.Field o) {
  buildCounterField++;
  if (buildCounterField < 3) {
    unittest.expect(
      o.maxOccurs!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minOccurs!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.table!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterField--;
}

core.List<core.String> buildUnnamed3280() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3280(core.List<core.String> o) {
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

core.int buildCounterFieldMetadata = 0;
api.FieldMetadata buildFieldMetadata() {
  var o = api.FieldMetadata();
  buildCounterFieldMetadata++;
  if (buildCounterFieldMetadata < 3) {
    o.action = 'foo';
    o.paths = buildUnnamed3280();
  }
  buildCounterFieldMetadata--;
  return o;
}

void checkFieldMetadata(api.FieldMetadata o) {
  buildCounterFieldMetadata++;
  if (buildCounterFieldMetadata < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    checkUnnamed3280(o.paths!);
  }
  buildCounterFieldMetadata--;
}

core.int buildCounterGoogleCloudHealthcareV1ConsentGcsDestination = 0;
api.GoogleCloudHealthcareV1ConsentGcsDestination
    buildGoogleCloudHealthcareV1ConsentGcsDestination() {
  var o = api.GoogleCloudHealthcareV1ConsentGcsDestination();
  buildCounterGoogleCloudHealthcareV1ConsentGcsDestination++;
  if (buildCounterGoogleCloudHealthcareV1ConsentGcsDestination < 3) {
    o.uriPrefix = 'foo';
  }
  buildCounterGoogleCloudHealthcareV1ConsentGcsDestination--;
  return o;
}

void checkGoogleCloudHealthcareV1ConsentGcsDestination(
    api.GoogleCloudHealthcareV1ConsentGcsDestination o) {
  buildCounterGoogleCloudHealthcareV1ConsentGcsDestination++;
  if (buildCounterGoogleCloudHealthcareV1ConsentGcsDestination < 3) {
    unittest.expect(
      o.uriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudHealthcareV1ConsentGcsDestination--;
}

core.List<api.Attribute> buildUnnamed3281() {
  var o = <api.Attribute>[];
  o.add(buildAttribute());
  o.add(buildAttribute());
  return o;
}

void checkUnnamed3281(core.List<api.Attribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttribute(o[0] as api.Attribute);
  checkAttribute(o[1] as api.Attribute);
}

core.int buildCounterGoogleCloudHealthcareV1ConsentPolicy = 0;
api.GoogleCloudHealthcareV1ConsentPolicy
    buildGoogleCloudHealthcareV1ConsentPolicy() {
  var o = api.GoogleCloudHealthcareV1ConsentPolicy();
  buildCounterGoogleCloudHealthcareV1ConsentPolicy++;
  if (buildCounterGoogleCloudHealthcareV1ConsentPolicy < 3) {
    o.authorizationRule = buildExpr();
    o.resourceAttributes = buildUnnamed3281();
  }
  buildCounterGoogleCloudHealthcareV1ConsentPolicy--;
  return o;
}

void checkGoogleCloudHealthcareV1ConsentPolicy(
    api.GoogleCloudHealthcareV1ConsentPolicy o) {
  buildCounterGoogleCloudHealthcareV1ConsentPolicy++;
  if (buildCounterGoogleCloudHealthcareV1ConsentPolicy < 3) {
    checkExpr(o.authorizationRule! as api.Expr);
    checkUnnamed3281(o.resourceAttributes!);
  }
  buildCounterGoogleCloudHealthcareV1ConsentPolicy--;
}

core.int
    buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary =
    0;
api.GoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary
    buildGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary() {
  var o = api.GoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary();
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary++;
  if (buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary <
      3) {}
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary--;
  return o;
}

void checkGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary(
    api.GoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary o) {
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary++;
  if (buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary <
      3) {}
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary--;
}

core.int
    buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary = 0;
api.GoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary
    buildGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary() {
  var o = api.GoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary();
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary++;
  if (buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary <
      3) {}
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary--;
  return o;
}

void checkGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary(
    api.GoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary o) {
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary++;
  if (buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary <
      3) {}
  buildCounterGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary--;
}

core.int buildCounterGoogleCloudHealthcareV1DicomBigQueryDestination = 0;
api.GoogleCloudHealthcareV1DicomBigQueryDestination
    buildGoogleCloudHealthcareV1DicomBigQueryDestination() {
  var o = api.GoogleCloudHealthcareV1DicomBigQueryDestination();
  buildCounterGoogleCloudHealthcareV1DicomBigQueryDestination++;
  if (buildCounterGoogleCloudHealthcareV1DicomBigQueryDestination < 3) {
    o.force = true;
    o.tableUri = 'foo';
  }
  buildCounterGoogleCloudHealthcareV1DicomBigQueryDestination--;
  return o;
}

void checkGoogleCloudHealthcareV1DicomBigQueryDestination(
    api.GoogleCloudHealthcareV1DicomBigQueryDestination o) {
  buildCounterGoogleCloudHealthcareV1DicomBigQueryDestination++;
  if (buildCounterGoogleCloudHealthcareV1DicomBigQueryDestination < 3) {
    unittest.expect(o.force!, unittest.isTrue);
    unittest.expect(
      o.tableUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudHealthcareV1DicomBigQueryDestination--;
}

core.int buildCounterGoogleCloudHealthcareV1DicomGcsDestination = 0;
api.GoogleCloudHealthcareV1DicomGcsDestination
    buildGoogleCloudHealthcareV1DicomGcsDestination() {
  var o = api.GoogleCloudHealthcareV1DicomGcsDestination();
  buildCounterGoogleCloudHealthcareV1DicomGcsDestination++;
  if (buildCounterGoogleCloudHealthcareV1DicomGcsDestination < 3) {
    o.mimeType = 'foo';
    o.uriPrefix = 'foo';
  }
  buildCounterGoogleCloudHealthcareV1DicomGcsDestination--;
  return o;
}

void checkGoogleCloudHealthcareV1DicomGcsDestination(
    api.GoogleCloudHealthcareV1DicomGcsDestination o) {
  buildCounterGoogleCloudHealthcareV1DicomGcsDestination++;
  if (buildCounterGoogleCloudHealthcareV1DicomGcsDestination < 3) {
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudHealthcareV1DicomGcsDestination--;
}

core.int buildCounterGoogleCloudHealthcareV1DicomGcsSource = 0;
api.GoogleCloudHealthcareV1DicomGcsSource
    buildGoogleCloudHealthcareV1DicomGcsSource() {
  var o = api.GoogleCloudHealthcareV1DicomGcsSource();
  buildCounterGoogleCloudHealthcareV1DicomGcsSource++;
  if (buildCounterGoogleCloudHealthcareV1DicomGcsSource < 3) {
    o.uri = 'foo';
  }
  buildCounterGoogleCloudHealthcareV1DicomGcsSource--;
  return o;
}

void checkGoogleCloudHealthcareV1DicomGcsSource(
    api.GoogleCloudHealthcareV1DicomGcsSource o) {
  buildCounterGoogleCloudHealthcareV1DicomGcsSource++;
  if (buildCounterGoogleCloudHealthcareV1DicomGcsSource < 3) {
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudHealthcareV1DicomGcsSource--;
}

core.int buildCounterGoogleCloudHealthcareV1FhirBigQueryDestination = 0;
api.GoogleCloudHealthcareV1FhirBigQueryDestination
    buildGoogleCloudHealthcareV1FhirBigQueryDestination() {
  var o = api.GoogleCloudHealthcareV1FhirBigQueryDestination();
  buildCounterGoogleCloudHealthcareV1FhirBigQueryDestination++;
  if (buildCounterGoogleCloudHealthcareV1FhirBigQueryDestination < 3) {
    o.datasetUri = 'foo';
    o.force = true;
    o.schemaConfig = buildSchemaConfig();
    o.writeDisposition = 'foo';
  }
  buildCounterGoogleCloudHealthcareV1FhirBigQueryDestination--;
  return o;
}

void checkGoogleCloudHealthcareV1FhirBigQueryDestination(
    api.GoogleCloudHealthcareV1FhirBigQueryDestination o) {
  buildCounterGoogleCloudHealthcareV1FhirBigQueryDestination++;
  if (buildCounterGoogleCloudHealthcareV1FhirBigQueryDestination < 3) {
    unittest.expect(
      o.datasetUri!,
      unittest.equals('foo'),
    );
    unittest.expect(o.force!, unittest.isTrue);
    checkSchemaConfig(o.schemaConfig! as api.SchemaConfig);
    unittest.expect(
      o.writeDisposition!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudHealthcareV1FhirBigQueryDestination--;
}

core.int buildCounterGoogleCloudHealthcareV1FhirGcsDestination = 0;
api.GoogleCloudHealthcareV1FhirGcsDestination
    buildGoogleCloudHealthcareV1FhirGcsDestination() {
  var o = api.GoogleCloudHealthcareV1FhirGcsDestination();
  buildCounterGoogleCloudHealthcareV1FhirGcsDestination++;
  if (buildCounterGoogleCloudHealthcareV1FhirGcsDestination < 3) {
    o.uriPrefix = 'foo';
  }
  buildCounterGoogleCloudHealthcareV1FhirGcsDestination--;
  return o;
}

void checkGoogleCloudHealthcareV1FhirGcsDestination(
    api.GoogleCloudHealthcareV1FhirGcsDestination o) {
  buildCounterGoogleCloudHealthcareV1FhirGcsDestination++;
  if (buildCounterGoogleCloudHealthcareV1FhirGcsDestination < 3) {
    unittest.expect(
      o.uriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudHealthcareV1FhirGcsDestination--;
}

core.int buildCounterGoogleCloudHealthcareV1FhirGcsSource = 0;
api.GoogleCloudHealthcareV1FhirGcsSource
    buildGoogleCloudHealthcareV1FhirGcsSource() {
  var o = api.GoogleCloudHealthcareV1FhirGcsSource();
  buildCounterGoogleCloudHealthcareV1FhirGcsSource++;
  if (buildCounterGoogleCloudHealthcareV1FhirGcsSource < 3) {
    o.uri = 'foo';
  }
  buildCounterGoogleCloudHealthcareV1FhirGcsSource--;
  return o;
}

void checkGoogleCloudHealthcareV1FhirGcsSource(
    api.GoogleCloudHealthcareV1FhirGcsSource o) {
  buildCounterGoogleCloudHealthcareV1FhirGcsSource++;
  if (buildCounterGoogleCloudHealthcareV1FhirGcsSource < 3) {
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudHealthcareV1FhirGcsSource--;
}

core.int buildCounterGroupOrSegment = 0;
api.GroupOrSegment buildGroupOrSegment() {
  var o = api.GroupOrSegment();
  buildCounterGroupOrSegment++;
  if (buildCounterGroupOrSegment < 3) {
    o.group = buildSchemaGroup();
    o.segment = buildSchemaSegment();
  }
  buildCounterGroupOrSegment--;
  return o;
}

void checkGroupOrSegment(api.GroupOrSegment o) {
  buildCounterGroupOrSegment++;
  if (buildCounterGroupOrSegment < 3) {
    checkSchemaGroup(o.group! as api.SchemaGroup);
    checkSchemaSegment(o.segment! as api.SchemaSegment);
  }
  buildCounterGroupOrSegment--;
}

core.Map<core.String, api.SchemaGroup> buildUnnamed3282() {
  var o = <core.String, api.SchemaGroup>{};
  o['x'] = buildSchemaGroup();
  o['y'] = buildSchemaGroup();
  return o;
}

void checkUnnamed3282(core.Map<core.String, api.SchemaGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSchemaGroup(o['x']! as api.SchemaGroup);
  checkSchemaGroup(o['y']! as api.SchemaGroup);
}

core.List<api.VersionSource> buildUnnamed3283() {
  var o = <api.VersionSource>[];
  o.add(buildVersionSource());
  o.add(buildVersionSource());
  return o;
}

void checkUnnamed3283(core.List<api.VersionSource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVersionSource(o[0] as api.VersionSource);
  checkVersionSource(o[1] as api.VersionSource);
}

core.int buildCounterHl7SchemaConfig = 0;
api.Hl7SchemaConfig buildHl7SchemaConfig() {
  var o = api.Hl7SchemaConfig();
  buildCounterHl7SchemaConfig++;
  if (buildCounterHl7SchemaConfig < 3) {
    o.messageSchemaConfigs = buildUnnamed3282();
    o.version = buildUnnamed3283();
  }
  buildCounterHl7SchemaConfig--;
  return o;
}

void checkHl7SchemaConfig(api.Hl7SchemaConfig o) {
  buildCounterHl7SchemaConfig++;
  if (buildCounterHl7SchemaConfig < 3) {
    checkUnnamed3282(o.messageSchemaConfigs!);
    checkUnnamed3283(o.version!);
  }
  buildCounterHl7SchemaConfig--;
}

core.List<api.Type> buildUnnamed3284() {
  var o = <api.Type>[];
  o.add(buildType());
  o.add(buildType());
  return o;
}

void checkUnnamed3284(core.List<api.Type> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkType(o[0] as api.Type);
  checkType(o[1] as api.Type);
}

core.List<api.VersionSource> buildUnnamed3285() {
  var o = <api.VersionSource>[];
  o.add(buildVersionSource());
  o.add(buildVersionSource());
  return o;
}

void checkUnnamed3285(core.List<api.VersionSource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVersionSource(o[0] as api.VersionSource);
  checkVersionSource(o[1] as api.VersionSource);
}

core.int buildCounterHl7TypesConfig = 0;
api.Hl7TypesConfig buildHl7TypesConfig() {
  var o = api.Hl7TypesConfig();
  buildCounterHl7TypesConfig++;
  if (buildCounterHl7TypesConfig < 3) {
    o.type = buildUnnamed3284();
    o.version = buildUnnamed3285();
  }
  buildCounterHl7TypesConfig--;
  return o;
}

void checkHl7TypesConfig(api.Hl7TypesConfig o) {
  buildCounterHl7TypesConfig++;
  if (buildCounterHl7TypesConfig < 3) {
    checkUnnamed3284(o.type!);
    checkUnnamed3285(o.version!);
  }
  buildCounterHl7TypesConfig--;
}

core.int buildCounterHl7V2NotificationConfig = 0;
api.Hl7V2NotificationConfig buildHl7V2NotificationConfig() {
  var o = api.Hl7V2NotificationConfig();
  buildCounterHl7V2NotificationConfig++;
  if (buildCounterHl7V2NotificationConfig < 3) {
    o.filter = 'foo';
    o.pubsubTopic = 'foo';
  }
  buildCounterHl7V2NotificationConfig--;
  return o;
}

void checkHl7V2NotificationConfig(api.Hl7V2NotificationConfig o) {
  buildCounterHl7V2NotificationConfig++;
  if (buildCounterHl7V2NotificationConfig < 3) {
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pubsubTopic!,
      unittest.equals('foo'),
    );
  }
  buildCounterHl7V2NotificationConfig--;
}

core.Map<core.String, core.String> buildUnnamed3286() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3286(core.Map<core.String, core.String> o) {
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

core.List<api.Hl7V2NotificationConfig> buildUnnamed3287() {
  var o = <api.Hl7V2NotificationConfig>[];
  o.add(buildHl7V2NotificationConfig());
  o.add(buildHl7V2NotificationConfig());
  return o;
}

void checkUnnamed3287(core.List<api.Hl7V2NotificationConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHl7V2NotificationConfig(o[0] as api.Hl7V2NotificationConfig);
  checkHl7V2NotificationConfig(o[1] as api.Hl7V2NotificationConfig);
}

core.int buildCounterHl7V2Store = 0;
api.Hl7V2Store buildHl7V2Store() {
  var o = api.Hl7V2Store();
  buildCounterHl7V2Store++;
  if (buildCounterHl7V2Store < 3) {
    o.labels = buildUnnamed3286();
    o.name = 'foo';
    o.notificationConfigs = buildUnnamed3287();
    o.parserConfig = buildParserConfig();
    o.rejectDuplicateMessage = true;
  }
  buildCounterHl7V2Store--;
  return o;
}

void checkHl7V2Store(api.Hl7V2Store o) {
  buildCounterHl7V2Store++;
  if (buildCounterHl7V2Store < 3) {
    checkUnnamed3286(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3287(o.notificationConfigs!);
    checkParserConfig(o.parserConfig! as api.ParserConfig);
    unittest.expect(o.rejectDuplicateMessage!, unittest.isTrue);
  }
  buildCounterHl7V2Store--;
}

core.Map<core.String, core.Object> buildUnnamed3288() {
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

void checkUnnamed3288(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed3289() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed3288());
  o.add(buildUnnamed3288());
  return o;
}

void checkUnnamed3289(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed3288(o[0]);
  checkUnnamed3288(o[1]);
}

core.int buildCounterHttpBody = 0;
api.HttpBody buildHttpBody() {
  var o = api.HttpBody();
  buildCounterHttpBody++;
  if (buildCounterHttpBody < 3) {
    o.contentType = 'foo';
    o.data = 'foo';
    o.extensions = buildUnnamed3289();
  }
  buildCounterHttpBody--;
  return o;
}

void checkHttpBody(api.HttpBody o) {
  buildCounterHttpBody++;
  if (buildCounterHttpBody < 3) {
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    checkUnnamed3289(o.extensions!);
  }
  buildCounterHttpBody--;
}

core.int buildCounterImage = 0;
api.Image buildImage() {
  var o = api.Image();
  buildCounterImage++;
  if (buildCounterImage < 3) {
    o.gcsUri = 'foo';
    o.rawBytes = 'foo';
  }
  buildCounterImage--;
  return o;
}

void checkImage(api.Image o) {
  buildCounterImage++;
  if (buildCounterImage < 3) {
    unittest.expect(
      o.gcsUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rawBytes!,
      unittest.equals('foo'),
    );
  }
  buildCounterImage--;
}

core.int buildCounterImageConfig = 0;
api.ImageConfig buildImageConfig() {
  var o = api.ImageConfig();
  buildCounterImageConfig++;
  if (buildCounterImageConfig < 3) {
    o.textRedactionMode = 'foo';
  }
  buildCounterImageConfig--;
  return o;
}

void checkImageConfig(api.ImageConfig o) {
  buildCounterImageConfig++;
  if (buildCounterImageConfig < 3) {
    unittest.expect(
      o.textRedactionMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterImageConfig--;
}

core.int buildCounterImportDicomDataRequest = 0;
api.ImportDicomDataRequest buildImportDicomDataRequest() {
  var o = api.ImportDicomDataRequest();
  buildCounterImportDicomDataRequest++;
  if (buildCounterImportDicomDataRequest < 3) {
    o.gcsSource = buildGoogleCloudHealthcareV1DicomGcsSource();
  }
  buildCounterImportDicomDataRequest--;
  return o;
}

void checkImportDicomDataRequest(api.ImportDicomDataRequest o) {
  buildCounterImportDicomDataRequest++;
  if (buildCounterImportDicomDataRequest < 3) {
    checkGoogleCloudHealthcareV1DicomGcsSource(
        o.gcsSource! as api.GoogleCloudHealthcareV1DicomGcsSource);
  }
  buildCounterImportDicomDataRequest--;
}

core.int buildCounterImportDicomDataResponse = 0;
api.ImportDicomDataResponse buildImportDicomDataResponse() {
  var o = api.ImportDicomDataResponse();
  buildCounterImportDicomDataResponse++;
  if (buildCounterImportDicomDataResponse < 3) {}
  buildCounterImportDicomDataResponse--;
  return o;
}

void checkImportDicomDataResponse(api.ImportDicomDataResponse o) {
  buildCounterImportDicomDataResponse++;
  if (buildCounterImportDicomDataResponse < 3) {}
  buildCounterImportDicomDataResponse--;
}

core.int buildCounterImportResourcesRequest = 0;
api.ImportResourcesRequest buildImportResourcesRequest() {
  var o = api.ImportResourcesRequest();
  buildCounterImportResourcesRequest++;
  if (buildCounterImportResourcesRequest < 3) {
    o.contentStructure = 'foo';
    o.gcsSource = buildGoogleCloudHealthcareV1FhirGcsSource();
  }
  buildCounterImportResourcesRequest--;
  return o;
}

void checkImportResourcesRequest(api.ImportResourcesRequest o) {
  buildCounterImportResourcesRequest++;
  if (buildCounterImportResourcesRequest < 3) {
    unittest.expect(
      o.contentStructure!,
      unittest.equals('foo'),
    );
    checkGoogleCloudHealthcareV1FhirGcsSource(
        o.gcsSource! as api.GoogleCloudHealthcareV1FhirGcsSource);
  }
  buildCounterImportResourcesRequest--;
}

core.int buildCounterImportResourcesResponse = 0;
api.ImportResourcesResponse buildImportResourcesResponse() {
  var o = api.ImportResourcesResponse();
  buildCounterImportResourcesResponse++;
  if (buildCounterImportResourcesResponse < 3) {}
  buildCounterImportResourcesResponse--;
  return o;
}

void checkImportResourcesResponse(api.ImportResourcesResponse o) {
  buildCounterImportResourcesResponse++;
  if (buildCounterImportResourcesResponse < 3) {}
  buildCounterImportResourcesResponse--;
}

core.List<core.String> buildUnnamed3290() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3290(core.List<core.String> o) {
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

core.int buildCounterInfoTypeTransformation = 0;
api.InfoTypeTransformation buildInfoTypeTransformation() {
  var o = api.InfoTypeTransformation();
  buildCounterInfoTypeTransformation++;
  if (buildCounterInfoTypeTransformation < 3) {
    o.characterMaskConfig = buildCharacterMaskConfig();
    o.cryptoHashConfig = buildCryptoHashConfig();
    o.dateShiftConfig = buildDateShiftConfig();
    o.infoTypes = buildUnnamed3290();
    o.redactConfig = buildRedactConfig();
    o.replaceWithInfoTypeConfig = buildReplaceWithInfoTypeConfig();
  }
  buildCounterInfoTypeTransformation--;
  return o;
}

void checkInfoTypeTransformation(api.InfoTypeTransformation o) {
  buildCounterInfoTypeTransformation++;
  if (buildCounterInfoTypeTransformation < 3) {
    checkCharacterMaskConfig(o.characterMaskConfig! as api.CharacterMaskConfig);
    checkCryptoHashConfig(o.cryptoHashConfig! as api.CryptoHashConfig);
    checkDateShiftConfig(o.dateShiftConfig! as api.DateShiftConfig);
    checkUnnamed3290(o.infoTypes!);
    checkRedactConfig(o.redactConfig! as api.RedactConfig);
    checkReplaceWithInfoTypeConfig(
        o.replaceWithInfoTypeConfig! as api.ReplaceWithInfoTypeConfig);
  }
  buildCounterInfoTypeTransformation--;
}

core.int buildCounterIngestMessageRequest = 0;
api.IngestMessageRequest buildIngestMessageRequest() {
  var o = api.IngestMessageRequest();
  buildCounterIngestMessageRequest++;
  if (buildCounterIngestMessageRequest < 3) {
    o.message = buildMessage();
  }
  buildCounterIngestMessageRequest--;
  return o;
}

void checkIngestMessageRequest(api.IngestMessageRequest o) {
  buildCounterIngestMessageRequest++;
  if (buildCounterIngestMessageRequest < 3) {
    checkMessage(o.message! as api.Message);
  }
  buildCounterIngestMessageRequest--;
}

core.int buildCounterIngestMessageResponse = 0;
api.IngestMessageResponse buildIngestMessageResponse() {
  var o = api.IngestMessageResponse();
  buildCounterIngestMessageResponse++;
  if (buildCounterIngestMessageResponse < 3) {
    o.hl7Ack = 'foo';
    o.message = buildMessage();
  }
  buildCounterIngestMessageResponse--;
  return o;
}

void checkIngestMessageResponse(api.IngestMessageResponse o) {
  buildCounterIngestMessageResponse++;
  if (buildCounterIngestMessageResponse < 3) {
    unittest.expect(
      o.hl7Ack!,
      unittest.equals('foo'),
    );
    checkMessage(o.message! as api.Message);
  }
  buildCounterIngestMessageResponse--;
}

core.List<api.AttributeDefinition> buildUnnamed3291() {
  var o = <api.AttributeDefinition>[];
  o.add(buildAttributeDefinition());
  o.add(buildAttributeDefinition());
  return o;
}

void checkUnnamed3291(core.List<api.AttributeDefinition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttributeDefinition(o[0] as api.AttributeDefinition);
  checkAttributeDefinition(o[1] as api.AttributeDefinition);
}

core.int buildCounterListAttributeDefinitionsResponse = 0;
api.ListAttributeDefinitionsResponse buildListAttributeDefinitionsResponse() {
  var o = api.ListAttributeDefinitionsResponse();
  buildCounterListAttributeDefinitionsResponse++;
  if (buildCounterListAttributeDefinitionsResponse < 3) {
    o.attributeDefinitions = buildUnnamed3291();
    o.nextPageToken = 'foo';
  }
  buildCounterListAttributeDefinitionsResponse--;
  return o;
}

void checkListAttributeDefinitionsResponse(
    api.ListAttributeDefinitionsResponse o) {
  buildCounterListAttributeDefinitionsResponse++;
  if (buildCounterListAttributeDefinitionsResponse < 3) {
    checkUnnamed3291(o.attributeDefinitions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAttributeDefinitionsResponse--;
}

core.List<api.ConsentArtifact> buildUnnamed3292() {
  var o = <api.ConsentArtifact>[];
  o.add(buildConsentArtifact());
  o.add(buildConsentArtifact());
  return o;
}

void checkUnnamed3292(core.List<api.ConsentArtifact> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConsentArtifact(o[0] as api.ConsentArtifact);
  checkConsentArtifact(o[1] as api.ConsentArtifact);
}

core.int buildCounterListConsentArtifactsResponse = 0;
api.ListConsentArtifactsResponse buildListConsentArtifactsResponse() {
  var o = api.ListConsentArtifactsResponse();
  buildCounterListConsentArtifactsResponse++;
  if (buildCounterListConsentArtifactsResponse < 3) {
    o.consentArtifacts = buildUnnamed3292();
    o.nextPageToken = 'foo';
  }
  buildCounterListConsentArtifactsResponse--;
  return o;
}

void checkListConsentArtifactsResponse(api.ListConsentArtifactsResponse o) {
  buildCounterListConsentArtifactsResponse++;
  if (buildCounterListConsentArtifactsResponse < 3) {
    checkUnnamed3292(o.consentArtifacts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListConsentArtifactsResponse--;
}

core.List<api.Consent> buildUnnamed3293() {
  var o = <api.Consent>[];
  o.add(buildConsent());
  o.add(buildConsent());
  return o;
}

void checkUnnamed3293(core.List<api.Consent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConsent(o[0] as api.Consent);
  checkConsent(o[1] as api.Consent);
}

core.int buildCounterListConsentRevisionsResponse = 0;
api.ListConsentRevisionsResponse buildListConsentRevisionsResponse() {
  var o = api.ListConsentRevisionsResponse();
  buildCounterListConsentRevisionsResponse++;
  if (buildCounterListConsentRevisionsResponse < 3) {
    o.consents = buildUnnamed3293();
    o.nextPageToken = 'foo';
  }
  buildCounterListConsentRevisionsResponse--;
  return o;
}

void checkListConsentRevisionsResponse(api.ListConsentRevisionsResponse o) {
  buildCounterListConsentRevisionsResponse++;
  if (buildCounterListConsentRevisionsResponse < 3) {
    checkUnnamed3293(o.consents!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListConsentRevisionsResponse--;
}

core.List<api.ConsentStore> buildUnnamed3294() {
  var o = <api.ConsentStore>[];
  o.add(buildConsentStore());
  o.add(buildConsentStore());
  return o;
}

void checkUnnamed3294(core.List<api.ConsentStore> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConsentStore(o[0] as api.ConsentStore);
  checkConsentStore(o[1] as api.ConsentStore);
}

core.int buildCounterListConsentStoresResponse = 0;
api.ListConsentStoresResponse buildListConsentStoresResponse() {
  var o = api.ListConsentStoresResponse();
  buildCounterListConsentStoresResponse++;
  if (buildCounterListConsentStoresResponse < 3) {
    o.consentStores = buildUnnamed3294();
    o.nextPageToken = 'foo';
  }
  buildCounterListConsentStoresResponse--;
  return o;
}

void checkListConsentStoresResponse(api.ListConsentStoresResponse o) {
  buildCounterListConsentStoresResponse++;
  if (buildCounterListConsentStoresResponse < 3) {
    checkUnnamed3294(o.consentStores!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListConsentStoresResponse--;
}

core.List<api.Consent> buildUnnamed3295() {
  var o = <api.Consent>[];
  o.add(buildConsent());
  o.add(buildConsent());
  return o;
}

void checkUnnamed3295(core.List<api.Consent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConsent(o[0] as api.Consent);
  checkConsent(o[1] as api.Consent);
}

core.int buildCounterListConsentsResponse = 0;
api.ListConsentsResponse buildListConsentsResponse() {
  var o = api.ListConsentsResponse();
  buildCounterListConsentsResponse++;
  if (buildCounterListConsentsResponse < 3) {
    o.consents = buildUnnamed3295();
    o.nextPageToken = 'foo';
  }
  buildCounterListConsentsResponse--;
  return o;
}

void checkListConsentsResponse(api.ListConsentsResponse o) {
  buildCounterListConsentsResponse++;
  if (buildCounterListConsentsResponse < 3) {
    checkUnnamed3295(o.consents!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListConsentsResponse--;
}

core.List<api.Dataset> buildUnnamed3296() {
  var o = <api.Dataset>[];
  o.add(buildDataset());
  o.add(buildDataset());
  return o;
}

void checkUnnamed3296(core.List<api.Dataset> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataset(o[0] as api.Dataset);
  checkDataset(o[1] as api.Dataset);
}

core.int buildCounterListDatasetsResponse = 0;
api.ListDatasetsResponse buildListDatasetsResponse() {
  var o = api.ListDatasetsResponse();
  buildCounterListDatasetsResponse++;
  if (buildCounterListDatasetsResponse < 3) {
    o.datasets = buildUnnamed3296();
    o.nextPageToken = 'foo';
  }
  buildCounterListDatasetsResponse--;
  return o;
}

void checkListDatasetsResponse(api.ListDatasetsResponse o) {
  buildCounterListDatasetsResponse++;
  if (buildCounterListDatasetsResponse < 3) {
    checkUnnamed3296(o.datasets!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDatasetsResponse--;
}

core.List<api.DicomStore> buildUnnamed3297() {
  var o = <api.DicomStore>[];
  o.add(buildDicomStore());
  o.add(buildDicomStore());
  return o;
}

void checkUnnamed3297(core.List<api.DicomStore> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDicomStore(o[0] as api.DicomStore);
  checkDicomStore(o[1] as api.DicomStore);
}

core.int buildCounterListDicomStoresResponse = 0;
api.ListDicomStoresResponse buildListDicomStoresResponse() {
  var o = api.ListDicomStoresResponse();
  buildCounterListDicomStoresResponse++;
  if (buildCounterListDicomStoresResponse < 3) {
    o.dicomStores = buildUnnamed3297();
    o.nextPageToken = 'foo';
  }
  buildCounterListDicomStoresResponse--;
  return o;
}

void checkListDicomStoresResponse(api.ListDicomStoresResponse o) {
  buildCounterListDicomStoresResponse++;
  if (buildCounterListDicomStoresResponse < 3) {
    checkUnnamed3297(o.dicomStores!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDicomStoresResponse--;
}

core.List<api.FhirStore> buildUnnamed3298() {
  var o = <api.FhirStore>[];
  o.add(buildFhirStore());
  o.add(buildFhirStore());
  return o;
}

void checkUnnamed3298(core.List<api.FhirStore> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFhirStore(o[0] as api.FhirStore);
  checkFhirStore(o[1] as api.FhirStore);
}

core.int buildCounterListFhirStoresResponse = 0;
api.ListFhirStoresResponse buildListFhirStoresResponse() {
  var o = api.ListFhirStoresResponse();
  buildCounterListFhirStoresResponse++;
  if (buildCounterListFhirStoresResponse < 3) {
    o.fhirStores = buildUnnamed3298();
    o.nextPageToken = 'foo';
  }
  buildCounterListFhirStoresResponse--;
  return o;
}

void checkListFhirStoresResponse(api.ListFhirStoresResponse o) {
  buildCounterListFhirStoresResponse++;
  if (buildCounterListFhirStoresResponse < 3) {
    checkUnnamed3298(o.fhirStores!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListFhirStoresResponse--;
}

core.List<api.Hl7V2Store> buildUnnamed3299() {
  var o = <api.Hl7V2Store>[];
  o.add(buildHl7V2Store());
  o.add(buildHl7V2Store());
  return o;
}

void checkUnnamed3299(core.List<api.Hl7V2Store> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHl7V2Store(o[0] as api.Hl7V2Store);
  checkHl7V2Store(o[1] as api.Hl7V2Store);
}

core.int buildCounterListHl7V2StoresResponse = 0;
api.ListHl7V2StoresResponse buildListHl7V2StoresResponse() {
  var o = api.ListHl7V2StoresResponse();
  buildCounterListHl7V2StoresResponse++;
  if (buildCounterListHl7V2StoresResponse < 3) {
    o.hl7V2Stores = buildUnnamed3299();
    o.nextPageToken = 'foo';
  }
  buildCounterListHl7V2StoresResponse--;
  return o;
}

void checkListHl7V2StoresResponse(api.ListHl7V2StoresResponse o) {
  buildCounterListHl7V2StoresResponse++;
  if (buildCounterListHl7V2StoresResponse < 3) {
    checkUnnamed3299(o.hl7V2Stores!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListHl7V2StoresResponse--;
}

core.List<api.Location> buildUnnamed3300() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed3300(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed3300();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed3300(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.Message> buildUnnamed3301() {
  var o = <api.Message>[];
  o.add(buildMessage());
  o.add(buildMessage());
  return o;
}

void checkUnnamed3301(core.List<api.Message> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMessage(o[0] as api.Message);
  checkMessage(o[1] as api.Message);
}

core.int buildCounterListMessagesResponse = 0;
api.ListMessagesResponse buildListMessagesResponse() {
  var o = api.ListMessagesResponse();
  buildCounterListMessagesResponse++;
  if (buildCounterListMessagesResponse < 3) {
    o.hl7V2Messages = buildUnnamed3301();
    o.nextPageToken = 'foo';
  }
  buildCounterListMessagesResponse--;
  return o;
}

void checkListMessagesResponse(api.ListMessagesResponse o) {
  buildCounterListMessagesResponse++;
  if (buildCounterListMessagesResponse < 3) {
    checkUnnamed3301(o.hl7V2Messages!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListMessagesResponse--;
}

core.List<api.Operation> buildUnnamed3302() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed3302(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterListOperationsResponse = 0;
api.ListOperationsResponse buildListOperationsResponse() {
  var o = api.ListOperationsResponse();
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed3302();
  }
  buildCounterListOperationsResponse--;
  return o;
}

void checkListOperationsResponse(api.ListOperationsResponse o) {
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3302(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.UserDataMapping> buildUnnamed3303() {
  var o = <api.UserDataMapping>[];
  o.add(buildUserDataMapping());
  o.add(buildUserDataMapping());
  return o;
}

void checkUnnamed3303(core.List<api.UserDataMapping> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserDataMapping(o[0] as api.UserDataMapping);
  checkUserDataMapping(o[1] as api.UserDataMapping);
}

core.int buildCounterListUserDataMappingsResponse = 0;
api.ListUserDataMappingsResponse buildListUserDataMappingsResponse() {
  var o = api.ListUserDataMappingsResponse();
  buildCounterListUserDataMappingsResponse++;
  if (buildCounterListUserDataMappingsResponse < 3) {
    o.nextPageToken = 'foo';
    o.userDataMappings = buildUnnamed3303();
  }
  buildCounterListUserDataMappingsResponse--;
  return o;
}

void checkListUserDataMappingsResponse(api.ListUserDataMappingsResponse o) {
  buildCounterListUserDataMappingsResponse++;
  if (buildCounterListUserDataMappingsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3303(o.userDataMappings!);
  }
  buildCounterListUserDataMappingsResponse--;
}

core.Map<core.String, core.String> buildUnnamed3304() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3304(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed3305() {
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

void checkUnnamed3305(core.Map<core.String, core.Object> o) {
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

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.displayName = 'foo';
    o.labels = buildUnnamed3304();
    o.locationId = 'foo';
    o.metadata = buildUnnamed3305();
    o.name = 'foo';
  }
  buildCounterLocation--;
  return o;
}

void checkLocation(api.Location o) {
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed3304(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed3305(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.Map<core.String, core.String> buildUnnamed3306() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3306(core.Map<core.String, core.String> o) {
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

core.List<api.PatientId> buildUnnamed3307() {
  var o = <api.PatientId>[];
  o.add(buildPatientId());
  o.add(buildPatientId());
  return o;
}

void checkUnnamed3307(core.List<api.PatientId> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPatientId(o[0] as api.PatientId);
  checkPatientId(o[1] as api.PatientId);
}

core.int buildCounterMessage = 0;
api.Message buildMessage() {
  var o = api.Message();
  buildCounterMessage++;
  if (buildCounterMessage < 3) {
    o.createTime = 'foo';
    o.data = 'foo';
    o.labels = buildUnnamed3306();
    o.messageType = 'foo';
    o.name = 'foo';
    o.parsedData = buildParsedData();
    o.patientIds = buildUnnamed3307();
    o.schematizedData = buildSchematizedData();
    o.sendFacility = 'foo';
    o.sendTime = 'foo';
  }
  buildCounterMessage--;
  return o;
}

void checkMessage(api.Message o) {
  buildCounterMessage++;
  if (buildCounterMessage < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    checkUnnamed3306(o.labels!);
    unittest.expect(
      o.messageType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkParsedData(o.parsedData! as api.ParsedData);
    checkUnnamed3307(o.patientIds!);
    checkSchematizedData(o.schematizedData! as api.SchematizedData);
    unittest.expect(
      o.sendFacility!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sendTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterMessage--;
}

core.int buildCounterNotificationConfig = 0;
api.NotificationConfig buildNotificationConfig() {
  var o = api.NotificationConfig();
  buildCounterNotificationConfig++;
  if (buildCounterNotificationConfig < 3) {
    o.pubsubTopic = 'foo';
  }
  buildCounterNotificationConfig--;
  return o;
}

void checkNotificationConfig(api.NotificationConfig o) {
  buildCounterNotificationConfig++;
  if (buildCounterNotificationConfig < 3) {
    unittest.expect(
      o.pubsubTopic!,
      unittest.equals('foo'),
    );
  }
  buildCounterNotificationConfig--;
}

core.Map<core.String, core.Object> buildUnnamed3308() {
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

void checkUnnamed3308(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed3309() {
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

void checkUnnamed3309(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed3308();
    o.name = 'foo';
    o.response = buildUnnamed3309();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed3308(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3309(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOperationMetadata = 0;
api.OperationMetadata buildOperationMetadata() {
  var o = api.OperationMetadata();
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    o.apiMethodName = 'foo';
    o.cancelRequested = true;
    o.counter = buildProgressCounter();
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.logsUrl = 'foo';
  }
  buildCounterOperationMetadata--;
  return o;
}

void checkOperationMetadata(api.OperationMetadata o) {
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    unittest.expect(
      o.apiMethodName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cancelRequested!, unittest.isTrue);
    checkProgressCounter(o.counter! as api.ProgressCounter);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.logsUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationMetadata--;
}

core.List<api.Segment> buildUnnamed3310() {
  var o = <api.Segment>[];
  o.add(buildSegment());
  o.add(buildSegment());
  return o;
}

void checkUnnamed3310(core.List<api.Segment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSegment(o[0] as api.Segment);
  checkSegment(o[1] as api.Segment);
}

core.int buildCounterParsedData = 0;
api.ParsedData buildParsedData() {
  var o = api.ParsedData();
  buildCounterParsedData++;
  if (buildCounterParsedData < 3) {
    o.segments = buildUnnamed3310();
  }
  buildCounterParsedData--;
  return o;
}

void checkParsedData(api.ParsedData o) {
  buildCounterParsedData++;
  if (buildCounterParsedData < 3) {
    checkUnnamed3310(o.segments!);
  }
  buildCounterParsedData--;
}

core.int buildCounterParserConfig = 0;
api.ParserConfig buildParserConfig() {
  var o = api.ParserConfig();
  buildCounterParserConfig++;
  if (buildCounterParserConfig < 3) {
    o.allowNullHeader = true;
    o.schema = buildSchemaPackage();
    o.segmentTerminator = 'foo';
  }
  buildCounterParserConfig--;
  return o;
}

void checkParserConfig(api.ParserConfig o) {
  buildCounterParserConfig++;
  if (buildCounterParserConfig < 3) {
    unittest.expect(o.allowNullHeader!, unittest.isTrue);
    checkSchemaPackage(o.schema! as api.SchemaPackage);
    unittest.expect(
      o.segmentTerminator!,
      unittest.equals('foo'),
    );
  }
  buildCounterParserConfig--;
}

core.int buildCounterPatientId = 0;
api.PatientId buildPatientId() {
  var o = api.PatientId();
  buildCounterPatientId++;
  if (buildCounterPatientId < 3) {
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterPatientId--;
  return o;
}

void checkPatientId(api.PatientId o) {
  buildCounterPatientId++;
  if (buildCounterPatientId < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterPatientId--;
}

core.List<api.AuditConfig> buildUnnamed3311() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed3311(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed3312() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed3312(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed3311();
    o.bindings = buildUnnamed3312();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed3311(o.auditConfigs!);
    checkUnnamed3312(o.bindings!);
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

core.int buildCounterProgressCounter = 0;
api.ProgressCounter buildProgressCounter() {
  var o = api.ProgressCounter();
  buildCounterProgressCounter++;
  if (buildCounterProgressCounter < 3) {
    o.failure = 'foo';
    o.pending = 'foo';
    o.success = 'foo';
  }
  buildCounterProgressCounter--;
  return o;
}

void checkProgressCounter(api.ProgressCounter o) {
  buildCounterProgressCounter++;
  if (buildCounterProgressCounter < 3) {
    unittest.expect(
      o.failure!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pending!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.success!,
      unittest.equals('foo'),
    );
  }
  buildCounterProgressCounter--;
}

core.Map<core.String, core.String> buildUnnamed3313() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3313(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed3314() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3314(core.Map<core.String, core.String> o) {
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

core.int buildCounterQueryAccessibleDataRequest = 0;
api.QueryAccessibleDataRequest buildQueryAccessibleDataRequest() {
  var o = api.QueryAccessibleDataRequest();
  buildCounterQueryAccessibleDataRequest++;
  if (buildCounterQueryAccessibleDataRequest < 3) {
    o.gcsDestination = buildGoogleCloudHealthcareV1ConsentGcsDestination();
    o.requestAttributes = buildUnnamed3313();
    o.resourceAttributes = buildUnnamed3314();
  }
  buildCounterQueryAccessibleDataRequest--;
  return o;
}

void checkQueryAccessibleDataRequest(api.QueryAccessibleDataRequest o) {
  buildCounterQueryAccessibleDataRequest++;
  if (buildCounterQueryAccessibleDataRequest < 3) {
    checkGoogleCloudHealthcareV1ConsentGcsDestination(
        o.gcsDestination! as api.GoogleCloudHealthcareV1ConsentGcsDestination);
    checkUnnamed3313(o.requestAttributes!);
    checkUnnamed3314(o.resourceAttributes!);
  }
  buildCounterQueryAccessibleDataRequest--;
}

core.int buildCounterQueryAccessibleDataResponse = 0;
api.QueryAccessibleDataResponse buildQueryAccessibleDataResponse() {
  var o = api.QueryAccessibleDataResponse();
  buildCounterQueryAccessibleDataResponse++;
  if (buildCounterQueryAccessibleDataResponse < 3) {}
  buildCounterQueryAccessibleDataResponse--;
  return o;
}

void checkQueryAccessibleDataResponse(api.QueryAccessibleDataResponse o) {
  buildCounterQueryAccessibleDataResponse++;
  if (buildCounterQueryAccessibleDataResponse < 3) {}
  buildCounterQueryAccessibleDataResponse--;
}

core.int buildCounterRedactConfig = 0;
api.RedactConfig buildRedactConfig() {
  var o = api.RedactConfig();
  buildCounterRedactConfig++;
  if (buildCounterRedactConfig < 3) {}
  buildCounterRedactConfig--;
  return o;
}

void checkRedactConfig(api.RedactConfig o) {
  buildCounterRedactConfig++;
  if (buildCounterRedactConfig < 3) {}
  buildCounterRedactConfig--;
}

core.int buildCounterRejectConsentRequest = 0;
api.RejectConsentRequest buildRejectConsentRequest() {
  var o = api.RejectConsentRequest();
  buildCounterRejectConsentRequest++;
  if (buildCounterRejectConsentRequest < 3) {
    o.consentArtifact = 'foo';
  }
  buildCounterRejectConsentRequest--;
  return o;
}

void checkRejectConsentRequest(api.RejectConsentRequest o) {
  buildCounterRejectConsentRequest++;
  if (buildCounterRejectConsentRequest < 3) {
    unittest.expect(
      o.consentArtifact!,
      unittest.equals('foo'),
    );
  }
  buildCounterRejectConsentRequest--;
}

core.int buildCounterReplaceWithInfoTypeConfig = 0;
api.ReplaceWithInfoTypeConfig buildReplaceWithInfoTypeConfig() {
  var o = api.ReplaceWithInfoTypeConfig();
  buildCounterReplaceWithInfoTypeConfig++;
  if (buildCounterReplaceWithInfoTypeConfig < 3) {}
  buildCounterReplaceWithInfoTypeConfig--;
  return o;
}

void checkReplaceWithInfoTypeConfig(api.ReplaceWithInfoTypeConfig o) {
  buildCounterReplaceWithInfoTypeConfig++;
  if (buildCounterReplaceWithInfoTypeConfig < 3) {}
  buildCounterReplaceWithInfoTypeConfig--;
}

core.List<core.String> buildUnnamed3315() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3315(core.List<core.String> o) {
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

core.int buildCounterResources = 0;
api.Resources buildResources() {
  var o = api.Resources();
  buildCounterResources++;
  if (buildCounterResources < 3) {
    o.resources = buildUnnamed3315();
  }
  buildCounterResources--;
  return o;
}

void checkResources(api.Resources o) {
  buildCounterResources++;
  if (buildCounterResources < 3) {
    checkUnnamed3315(o.resources!);
  }
  buildCounterResources--;
}

core.Map<core.String, api.ConsentEvaluation> buildUnnamed3316() {
  var o = <core.String, api.ConsentEvaluation>{};
  o['x'] = buildConsentEvaluation();
  o['y'] = buildConsentEvaluation();
  return o;
}

void checkUnnamed3316(core.Map<core.String, api.ConsentEvaluation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConsentEvaluation(o['x']! as api.ConsentEvaluation);
  checkConsentEvaluation(o['y']! as api.ConsentEvaluation);
}

core.int buildCounterResult = 0;
api.Result buildResult() {
  var o = api.Result();
  buildCounterResult++;
  if (buildCounterResult < 3) {
    o.consentDetails = buildUnnamed3316();
    o.consented = true;
    o.dataId = 'foo';
  }
  buildCounterResult--;
  return o;
}

void checkResult(api.Result o) {
  buildCounterResult++;
  if (buildCounterResult < 3) {
    checkUnnamed3316(o.consentDetails!);
    unittest.expect(o.consented!, unittest.isTrue);
    unittest.expect(
      o.dataId!,
      unittest.equals('foo'),
    );
  }
  buildCounterResult--;
}

core.int buildCounterRevokeConsentRequest = 0;
api.RevokeConsentRequest buildRevokeConsentRequest() {
  var o = api.RevokeConsentRequest();
  buildCounterRevokeConsentRequest++;
  if (buildCounterRevokeConsentRequest < 3) {
    o.consentArtifact = 'foo';
  }
  buildCounterRevokeConsentRequest--;
  return o;
}

void checkRevokeConsentRequest(api.RevokeConsentRequest o) {
  buildCounterRevokeConsentRequest++;
  if (buildCounterRevokeConsentRequest < 3) {
    unittest.expect(
      o.consentArtifact!,
      unittest.equals('foo'),
    );
  }
  buildCounterRevokeConsentRequest--;
}

core.int buildCounterSchemaConfig = 0;
api.SchemaConfig buildSchemaConfig() {
  var o = api.SchemaConfig();
  buildCounterSchemaConfig++;
  if (buildCounterSchemaConfig < 3) {
    o.recursiveStructureDepth = 'foo';
    o.schemaType = 'foo';
  }
  buildCounterSchemaConfig--;
  return o;
}

void checkSchemaConfig(api.SchemaConfig o) {
  buildCounterSchemaConfig++;
  if (buildCounterSchemaConfig < 3) {
    unittest.expect(
      o.recursiveStructureDepth!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.schemaType!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchemaConfig--;
}

core.List<api.GroupOrSegment> buildUnnamed3317() {
  var o = <api.GroupOrSegment>[];
  o.add(buildGroupOrSegment());
  o.add(buildGroupOrSegment());
  return o;
}

void checkUnnamed3317(core.List<api.GroupOrSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGroupOrSegment(o[0] as api.GroupOrSegment);
  checkGroupOrSegment(o[1] as api.GroupOrSegment);
}

core.int buildCounterSchemaGroup = 0;
api.SchemaGroup buildSchemaGroup() {
  var o = api.SchemaGroup();
  buildCounterSchemaGroup++;
  if (buildCounterSchemaGroup < 3) {
    o.choice = true;
    o.maxOccurs = 42;
    o.members = buildUnnamed3317();
    o.minOccurs = 42;
    o.name = 'foo';
  }
  buildCounterSchemaGroup--;
  return o;
}

void checkSchemaGroup(api.SchemaGroup o) {
  buildCounterSchemaGroup++;
  if (buildCounterSchemaGroup < 3) {
    unittest.expect(o.choice!, unittest.isTrue);
    unittest.expect(
      o.maxOccurs!,
      unittest.equals(42),
    );
    checkUnnamed3317(o.members!);
    unittest.expect(
      o.minOccurs!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchemaGroup--;
}

core.List<api.Hl7SchemaConfig> buildUnnamed3318() {
  var o = <api.Hl7SchemaConfig>[];
  o.add(buildHl7SchemaConfig());
  o.add(buildHl7SchemaConfig());
  return o;
}

void checkUnnamed3318(core.List<api.Hl7SchemaConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHl7SchemaConfig(o[0] as api.Hl7SchemaConfig);
  checkHl7SchemaConfig(o[1] as api.Hl7SchemaConfig);
}

core.List<api.Hl7TypesConfig> buildUnnamed3319() {
  var o = <api.Hl7TypesConfig>[];
  o.add(buildHl7TypesConfig());
  o.add(buildHl7TypesConfig());
  return o;
}

void checkUnnamed3319(core.List<api.Hl7TypesConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHl7TypesConfig(o[0] as api.Hl7TypesConfig);
  checkHl7TypesConfig(o[1] as api.Hl7TypesConfig);
}

core.int buildCounterSchemaPackage = 0;
api.SchemaPackage buildSchemaPackage() {
  var o = api.SchemaPackage();
  buildCounterSchemaPackage++;
  if (buildCounterSchemaPackage < 3) {
    o.ignoreMinOccurs = true;
    o.schemas = buildUnnamed3318();
    o.schematizedParsingType = 'foo';
    o.types = buildUnnamed3319();
  }
  buildCounterSchemaPackage--;
  return o;
}

void checkSchemaPackage(api.SchemaPackage o) {
  buildCounterSchemaPackage++;
  if (buildCounterSchemaPackage < 3) {
    unittest.expect(o.ignoreMinOccurs!, unittest.isTrue);
    checkUnnamed3318(o.schemas!);
    unittest.expect(
      o.schematizedParsingType!,
      unittest.equals('foo'),
    );
    checkUnnamed3319(o.types!);
  }
  buildCounterSchemaPackage--;
}

core.int buildCounterSchemaSegment = 0;
api.SchemaSegment buildSchemaSegment() {
  var o = api.SchemaSegment();
  buildCounterSchemaSegment++;
  if (buildCounterSchemaSegment < 3) {
    o.maxOccurs = 42;
    o.minOccurs = 42;
    o.type = 'foo';
  }
  buildCounterSchemaSegment--;
  return o;
}

void checkSchemaSegment(api.SchemaSegment o) {
  buildCounterSchemaSegment++;
  if (buildCounterSchemaSegment < 3) {
    unittest.expect(
      o.maxOccurs!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minOccurs!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchemaSegment--;
}

core.int buildCounterSchematizedData = 0;
api.SchematizedData buildSchematizedData() {
  var o = api.SchematizedData();
  buildCounterSchematizedData++;
  if (buildCounterSchematizedData < 3) {
    o.data = 'foo';
    o.error = 'foo';
  }
  buildCounterSchematizedData--;
  return o;
}

void checkSchematizedData(api.SchematizedData o) {
  buildCounterSchematizedData++;
  if (buildCounterSchematizedData < 3) {
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.error!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchematizedData--;
}

core.int buildCounterSearchResourcesRequest = 0;
api.SearchResourcesRequest buildSearchResourcesRequest() {
  var o = api.SearchResourcesRequest();
  buildCounterSearchResourcesRequest++;
  if (buildCounterSearchResourcesRequest < 3) {
    o.resourceType = 'foo';
  }
  buildCounterSearchResourcesRequest--;
  return o;
}

void checkSearchResourcesRequest(api.SearchResourcesRequest o) {
  buildCounterSearchResourcesRequest++;
  if (buildCounterSearchResourcesRequest < 3) {
    unittest.expect(
      o.resourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchResourcesRequest--;
}

core.Map<core.String, core.String> buildUnnamed3320() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3320(core.Map<core.String, core.String> o) {
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

core.int buildCounterSegment = 0;
api.Segment buildSegment() {
  var o = api.Segment();
  buildCounterSegment++;
  if (buildCounterSegment < 3) {
    o.fields = buildUnnamed3320();
    o.segmentId = 'foo';
    o.setId = 'foo';
  }
  buildCounterSegment--;
  return o;
}

void checkSegment(api.Segment o) {
  buildCounterSegment++;
  if (buildCounterSegment < 3) {
    checkUnnamed3320(o.fields!);
    unittest.expect(
      o.segmentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.setId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSegment--;
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

core.Map<core.String, core.String> buildUnnamed3321() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3321(core.Map<core.String, core.String> o) {
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

core.int buildCounterSignature = 0;
api.Signature buildSignature() {
  var o = api.Signature();
  buildCounterSignature++;
  if (buildCounterSignature < 3) {
    o.image = buildImage();
    o.metadata = buildUnnamed3321();
    o.signatureTime = 'foo';
    o.userId = 'foo';
  }
  buildCounterSignature--;
  return o;
}

void checkSignature(api.Signature o) {
  buildCounterSignature++;
  if (buildCounterSignature < 3) {
    checkImage(o.image! as api.Image);
    checkUnnamed3321(o.metadata!);
    unittest.expect(
      o.signatureTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignature--;
}

core.Map<core.String, core.Object> buildUnnamed3322() {
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

void checkUnnamed3322(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed3323() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed3322());
  o.add(buildUnnamed3322());
  return o;
}

void checkUnnamed3323(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed3322(o[0]);
  checkUnnamed3322(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed3323();
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
    checkUnnamed3323(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<core.String> buildUnnamed3324() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3324(core.List<core.String> o) {
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

core.int buildCounterStreamConfig = 0;
api.StreamConfig buildStreamConfig() {
  var o = api.StreamConfig();
  buildCounterStreamConfig++;
  if (buildCounterStreamConfig < 3) {
    o.bigqueryDestination =
        buildGoogleCloudHealthcareV1FhirBigQueryDestination();
    o.resourceTypes = buildUnnamed3324();
  }
  buildCounterStreamConfig--;
  return o;
}

void checkStreamConfig(api.StreamConfig o) {
  buildCounterStreamConfig++;
  if (buildCounterStreamConfig < 3) {
    checkGoogleCloudHealthcareV1FhirBigQueryDestination(o.bigqueryDestination!
        as api.GoogleCloudHealthcareV1FhirBigQueryDestination);
    checkUnnamed3324(o.resourceTypes!);
  }
  buildCounterStreamConfig--;
}

core.List<core.String> buildUnnamed3325() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3325(core.List<core.String> o) {
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

core.int buildCounterTagFilterList = 0;
api.TagFilterList buildTagFilterList() {
  var o = api.TagFilterList();
  buildCounterTagFilterList++;
  if (buildCounterTagFilterList < 3) {
    o.tags = buildUnnamed3325();
  }
  buildCounterTagFilterList--;
  return o;
}

void checkTagFilterList(api.TagFilterList o) {
  buildCounterTagFilterList++;
  if (buildCounterTagFilterList < 3) {
    checkUnnamed3325(o.tags!);
  }
  buildCounterTagFilterList--;
}

core.List<core.String> buildUnnamed3326() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3326(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3326();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed3326(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed3327() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3327(core.List<core.String> o) {
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
    o.permissions = buildUnnamed3327();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed3327(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.List<api.InfoTypeTransformation> buildUnnamed3328() {
  var o = <api.InfoTypeTransformation>[];
  o.add(buildInfoTypeTransformation());
  o.add(buildInfoTypeTransformation());
  return o;
}

void checkUnnamed3328(core.List<api.InfoTypeTransformation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInfoTypeTransformation(o[0] as api.InfoTypeTransformation);
  checkInfoTypeTransformation(o[1] as api.InfoTypeTransformation);
}

core.int buildCounterTextConfig = 0;
api.TextConfig buildTextConfig() {
  var o = api.TextConfig();
  buildCounterTextConfig++;
  if (buildCounterTextConfig < 3) {
    o.transformations = buildUnnamed3328();
  }
  buildCounterTextConfig--;
  return o;
}

void checkTextConfig(api.TextConfig o) {
  buildCounterTextConfig++;
  if (buildCounterTextConfig < 3) {
    checkUnnamed3328(o.transformations!);
  }
  buildCounterTextConfig--;
}

core.List<api.Field> buildUnnamed3329() {
  var o = <api.Field>[];
  o.add(buildField());
  o.add(buildField());
  return o;
}

void checkUnnamed3329(core.List<api.Field> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkField(o[0] as api.Field);
  checkField(o[1] as api.Field);
}

core.int buildCounterType = 0;
api.Type buildType() {
  var o = api.Type();
  buildCounterType++;
  if (buildCounterType < 3) {
    o.fields = buildUnnamed3329();
    o.name = 'foo';
    o.primitive = 'foo';
  }
  buildCounterType--;
  return o;
}

void checkType(api.Type o) {
  buildCounterType++;
  if (buildCounterType < 3) {
    checkUnnamed3329(o.fields!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.primitive!,
      unittest.equals('foo'),
    );
  }
  buildCounterType--;
}

core.List<api.Attribute> buildUnnamed3330() {
  var o = <api.Attribute>[];
  o.add(buildAttribute());
  o.add(buildAttribute());
  return o;
}

void checkUnnamed3330(core.List<api.Attribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttribute(o[0] as api.Attribute);
  checkAttribute(o[1] as api.Attribute);
}

core.int buildCounterUserDataMapping = 0;
api.UserDataMapping buildUserDataMapping() {
  var o = api.UserDataMapping();
  buildCounterUserDataMapping++;
  if (buildCounterUserDataMapping < 3) {
    o.archiveTime = 'foo';
    o.archived = true;
    o.dataId = 'foo';
    o.name = 'foo';
    o.resourceAttributes = buildUnnamed3330();
    o.userId = 'foo';
  }
  buildCounterUserDataMapping--;
  return o;
}

void checkUserDataMapping(api.UserDataMapping o) {
  buildCounterUserDataMapping++;
  if (buildCounterUserDataMapping < 3) {
    unittest.expect(
      o.archiveTime!,
      unittest.equals('foo'),
    );
    unittest.expect(o.archived!, unittest.isTrue);
    unittest.expect(
      o.dataId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3330(o.resourceAttributes!);
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserDataMapping--;
}

core.int buildCounterVersionSource = 0;
api.VersionSource buildVersionSource() {
  var o = api.VersionSource();
  buildCounterVersionSource++;
  if (buildCounterVersionSource < 3) {
    o.mshField = 'foo';
    o.value = 'foo';
  }
  buildCounterVersionSource--;
  return o;
}

void checkVersionSource(api.VersionSource o) {
  buildCounterVersionSource++;
  if (buildCounterVersionSource < 3) {
    unittest.expect(
      o.mshField!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterVersionSource--;
}

void main() {
  unittest.group('obj-schema-ActivateConsentRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivateConsentRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivateConsentRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivateConsentRequest(od as api.ActivateConsentRequest);
    });
  });

  unittest.group('obj-schema-ArchiveUserDataMappingRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArchiveUserDataMappingRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArchiveUserDataMappingRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArchiveUserDataMappingRequest(
          od as api.ArchiveUserDataMappingRequest);
    });
  });

  unittest.group('obj-schema-ArchiveUserDataMappingResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArchiveUserDataMappingResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArchiveUserDataMappingResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArchiveUserDataMappingResponse(
          od as api.ArchiveUserDataMappingResponse);
    });
  });

  unittest.group('obj-schema-Attribute', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Attribute.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAttribute(od as api.Attribute);
    });
  });

  unittest.group('obj-schema-AttributeDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttributeDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AttributeDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAttributeDefinition(od as api.AttributeDefinition);
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

  unittest.group('obj-schema-CancelOperationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelOperationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelOperationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelOperationRequest(od as api.CancelOperationRequest);
    });
  });

  unittest.group('obj-schema-CharacterMaskConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCharacterMaskConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CharacterMaskConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCharacterMaskConfig(od as api.CharacterMaskConfig);
    });
  });

  unittest.group('obj-schema-CheckDataAccessRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCheckDataAccessRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CheckDataAccessRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCheckDataAccessRequest(od as api.CheckDataAccessRequest);
    });
  });

  unittest.group('obj-schema-CheckDataAccessResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCheckDataAccessResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CheckDataAccessResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCheckDataAccessResponse(od as api.CheckDataAccessResponse);
    });
  });

  unittest.group('obj-schema-Consent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConsent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Consent.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkConsent(od as api.Consent);
    });
  });

  unittest.group('obj-schema-ConsentArtifact', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConsentArtifact();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConsentArtifact.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConsentArtifact(od as api.ConsentArtifact);
    });
  });

  unittest.group('obj-schema-ConsentEvaluation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConsentEvaluation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConsentEvaluation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConsentEvaluation(od as api.ConsentEvaluation);
    });
  });

  unittest.group('obj-schema-ConsentList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConsentList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConsentList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConsentList(od as api.ConsentList);
    });
  });

  unittest.group('obj-schema-ConsentStore', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConsentStore();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConsentStore.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConsentStore(od as api.ConsentStore);
    });
  });

  unittest.group('obj-schema-CreateMessageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateMessageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateMessageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateMessageRequest(od as api.CreateMessageRequest);
    });
  });

  unittest.group('obj-schema-CryptoHashConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCryptoHashConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CryptoHashConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCryptoHashConfig(od as api.CryptoHashConfig);
    });
  });

  unittest.group('obj-schema-Dataset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Dataset.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataset(od as api.Dataset);
    });
  });

  unittest.group('obj-schema-DateShiftConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDateShiftConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DateShiftConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDateShiftConfig(od as api.DateShiftConfig);
    });
  });

  unittest.group('obj-schema-DeidentifyConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeidentifyConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeidentifyConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeidentifyConfig(od as api.DeidentifyConfig);
    });
  });

  unittest.group('obj-schema-DeidentifyDatasetRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeidentifyDatasetRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeidentifyDatasetRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeidentifyDatasetRequest(od as api.DeidentifyDatasetRequest);
    });
  });

  unittest.group('obj-schema-DeidentifyDicomStoreRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeidentifyDicomStoreRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeidentifyDicomStoreRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeidentifyDicomStoreRequest(od as api.DeidentifyDicomStoreRequest);
    });
  });

  unittest.group('obj-schema-DeidentifyFhirStoreRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeidentifyFhirStoreRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeidentifyFhirStoreRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeidentifyFhirStoreRequest(od as api.DeidentifyFhirStoreRequest);
    });
  });

  unittest.group('obj-schema-DeidentifySummary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeidentifySummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeidentifySummary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeidentifySummary(od as api.DeidentifySummary);
    });
  });

  unittest.group('obj-schema-DicomConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDicomConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DicomConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDicomConfig(od as api.DicomConfig);
    });
  });

  unittest.group('obj-schema-DicomFilterConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDicomFilterConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DicomFilterConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDicomFilterConfig(od as api.DicomFilterConfig);
    });
  });

  unittest.group('obj-schema-DicomStore', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDicomStore();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DicomStore.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDicomStore(od as api.DicomStore);
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

  unittest.group('obj-schema-EvaluateUserConsentsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEvaluateUserConsentsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EvaluateUserConsentsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEvaluateUserConsentsRequest(od as api.EvaluateUserConsentsRequest);
    });
  });

  unittest.group('obj-schema-EvaluateUserConsentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEvaluateUserConsentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EvaluateUserConsentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEvaluateUserConsentsResponse(od as api.EvaluateUserConsentsResponse);
    });
  });

  unittest.group('obj-schema-ExportDicomDataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExportDicomDataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExportDicomDataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExportDicomDataRequest(od as api.ExportDicomDataRequest);
    });
  });

  unittest.group('obj-schema-ExportDicomDataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExportDicomDataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExportDicomDataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExportDicomDataResponse(od as api.ExportDicomDataResponse);
    });
  });

  unittest.group('obj-schema-ExportResourcesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExportResourcesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExportResourcesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExportResourcesRequest(od as api.ExportResourcesRequest);
    });
  });

  unittest.group('obj-schema-ExportResourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExportResourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExportResourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExportResourcesResponse(od as api.ExportResourcesResponse);
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

  unittest.group('obj-schema-FhirConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFhirConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FhirConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFhirConfig(od as api.FhirConfig);
    });
  });

  unittest.group('obj-schema-FhirFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFhirFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FhirFilter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFhirFilter(od as api.FhirFilter);
    });
  });

  unittest.group('obj-schema-FhirStore', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFhirStore();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FhirStore.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFhirStore(od as api.FhirStore);
    });
  });

  unittest.group('obj-schema-Field', () {
    unittest.test('to-json--from-json', () async {
      var o = buildField();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Field.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkField(od as api.Field);
    });
  });

  unittest.group('obj-schema-FieldMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFieldMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FieldMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFieldMetadata(od as api.FieldMetadata);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1ConsentGcsDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1ConsentGcsDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1ConsentGcsDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1ConsentGcsDestination(
          od as api.GoogleCloudHealthcareV1ConsentGcsDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1ConsentPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1ConsentPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1ConsentPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1ConsentPolicy(
          od as api.GoogleCloudHealthcareV1ConsentPolicy);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary(od
          as api.GoogleCloudHealthcareV1DeidentifyDeidentifyDicomStoreSummary);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary(od
          as api.GoogleCloudHealthcareV1DeidentifyDeidentifyFhirStoreSummary);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1DicomBigQueryDestination',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1DicomBigQueryDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1DicomBigQueryDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1DicomBigQueryDestination(
          od as api.GoogleCloudHealthcareV1DicomBigQueryDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1DicomGcsDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1DicomGcsDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1DicomGcsDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1DicomGcsDestination(
          od as api.GoogleCloudHealthcareV1DicomGcsDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1DicomGcsSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1DicomGcsSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1DicomGcsSource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1DicomGcsSource(
          od as api.GoogleCloudHealthcareV1DicomGcsSource);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1FhirBigQueryDestination',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1FhirBigQueryDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1FhirBigQueryDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1FhirBigQueryDestination(
          od as api.GoogleCloudHealthcareV1FhirBigQueryDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1FhirGcsDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1FhirGcsDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1FhirGcsDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1FhirGcsDestination(
          od as api.GoogleCloudHealthcareV1FhirGcsDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudHealthcareV1FhirGcsSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudHealthcareV1FhirGcsSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudHealthcareV1FhirGcsSource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudHealthcareV1FhirGcsSource(
          od as api.GoogleCloudHealthcareV1FhirGcsSource);
    });
  });

  unittest.group('obj-schema-GroupOrSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupOrSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupOrSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupOrSegment(od as api.GroupOrSegment);
    });
  });

  unittest.group('obj-schema-Hl7SchemaConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHl7SchemaConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Hl7SchemaConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHl7SchemaConfig(od as api.Hl7SchemaConfig);
    });
  });

  unittest.group('obj-schema-Hl7TypesConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHl7TypesConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Hl7TypesConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHl7TypesConfig(od as api.Hl7TypesConfig);
    });
  });

  unittest.group('obj-schema-Hl7V2NotificationConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHl7V2NotificationConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Hl7V2NotificationConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHl7V2NotificationConfig(od as api.Hl7V2NotificationConfig);
    });
  });

  unittest.group('obj-schema-Hl7V2Store', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHl7V2Store();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Hl7V2Store.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHl7V2Store(od as api.Hl7V2Store);
    });
  });

  unittest.group('obj-schema-HttpBody', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHttpBody();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.HttpBody.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHttpBody(od as api.HttpBody);
    });
  });

  unittest.group('obj-schema-Image', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Image.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImage(od as api.Image);
    });
  });

  unittest.group('obj-schema-ImageConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImageConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImageConfig(od as api.ImageConfig);
    });
  });

  unittest.group('obj-schema-ImportDicomDataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportDicomDataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImportDicomDataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImportDicomDataRequest(od as api.ImportDicomDataRequest);
    });
  });

  unittest.group('obj-schema-ImportDicomDataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportDicomDataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImportDicomDataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImportDicomDataResponse(od as api.ImportDicomDataResponse);
    });
  });

  unittest.group('obj-schema-ImportResourcesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportResourcesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImportResourcesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImportResourcesRequest(od as api.ImportResourcesRequest);
    });
  });

  unittest.group('obj-schema-ImportResourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportResourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImportResourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImportResourcesResponse(od as api.ImportResourcesResponse);
    });
  });

  unittest.group('obj-schema-InfoTypeTransformation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInfoTypeTransformation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InfoTypeTransformation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInfoTypeTransformation(od as api.InfoTypeTransformation);
    });
  });

  unittest.group('obj-schema-IngestMessageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIngestMessageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IngestMessageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIngestMessageRequest(od as api.IngestMessageRequest);
    });
  });

  unittest.group('obj-schema-IngestMessageResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIngestMessageResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IngestMessageResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIngestMessageResponse(od as api.IngestMessageResponse);
    });
  });

  unittest.group('obj-schema-ListAttributeDefinitionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAttributeDefinitionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAttributeDefinitionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAttributeDefinitionsResponse(
          od as api.ListAttributeDefinitionsResponse);
    });
  });

  unittest.group('obj-schema-ListConsentArtifactsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConsentArtifactsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConsentArtifactsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConsentArtifactsResponse(od as api.ListConsentArtifactsResponse);
    });
  });

  unittest.group('obj-schema-ListConsentRevisionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConsentRevisionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConsentRevisionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConsentRevisionsResponse(od as api.ListConsentRevisionsResponse);
    });
  });

  unittest.group('obj-schema-ListConsentStoresResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConsentStoresResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConsentStoresResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConsentStoresResponse(od as api.ListConsentStoresResponse);
    });
  });

  unittest.group('obj-schema-ListConsentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConsentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConsentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConsentsResponse(od as api.ListConsentsResponse);
    });
  });

  unittest.group('obj-schema-ListDatasetsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDatasetsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDatasetsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDatasetsResponse(od as api.ListDatasetsResponse);
    });
  });

  unittest.group('obj-schema-ListDicomStoresResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDicomStoresResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDicomStoresResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDicomStoresResponse(od as api.ListDicomStoresResponse);
    });
  });

  unittest.group('obj-schema-ListFhirStoresResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFhirStoresResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFhirStoresResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFhirStoresResponse(od as api.ListFhirStoresResponse);
    });
  });

  unittest.group('obj-schema-ListHl7V2StoresResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListHl7V2StoresResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListHl7V2StoresResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListHl7V2StoresResponse(od as api.ListHl7V2StoresResponse);
    });
  });

  unittest.group('obj-schema-ListLocationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLocationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLocationsResponse(od as api.ListLocationsResponse);
    });
  });

  unittest.group('obj-schema-ListMessagesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListMessagesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListMessagesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListMessagesResponse(od as api.ListMessagesResponse);
    });
  });

  unittest.group('obj-schema-ListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOperationsResponse(od as api.ListOperationsResponse);
    });
  });

  unittest.group('obj-schema-ListUserDataMappingsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListUserDataMappingsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListUserDataMappingsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListUserDataMappingsResponse(od as api.ListUserDataMappingsResponse);
    });
  });

  unittest.group('obj-schema-Location', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Location.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocation(od as api.Location);
    });
  });

  unittest.group('obj-schema-Message', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Message.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMessage(od as api.Message);
    });
  });

  unittest.group('obj-schema-NotificationConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotificationConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotificationConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotificationConfig(od as api.NotificationConfig);
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

  unittest.group('obj-schema-OperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationMetadata(od as api.OperationMetadata);
    });
  });

  unittest.group('obj-schema-ParsedData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParsedData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ParsedData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkParsedData(od as api.ParsedData);
    });
  });

  unittest.group('obj-schema-ParserConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParserConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ParserConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkParserConfig(od as api.ParserConfig);
    });
  });

  unittest.group('obj-schema-PatientId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPatientId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PatientId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPatientId(od as api.PatientId);
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

  unittest.group('obj-schema-ProgressCounter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProgressCounter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProgressCounter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProgressCounter(od as api.ProgressCounter);
    });
  });

  unittest.group('obj-schema-QueryAccessibleDataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryAccessibleDataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryAccessibleDataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryAccessibleDataRequest(od as api.QueryAccessibleDataRequest);
    });
  });

  unittest.group('obj-schema-QueryAccessibleDataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryAccessibleDataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryAccessibleDataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryAccessibleDataResponse(od as api.QueryAccessibleDataResponse);
    });
  });

  unittest.group('obj-schema-RedactConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRedactConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RedactConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRedactConfig(od as api.RedactConfig);
    });
  });

  unittest.group('obj-schema-RejectConsentRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRejectConsentRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RejectConsentRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRejectConsentRequest(od as api.RejectConsentRequest);
    });
  });

  unittest.group('obj-schema-ReplaceWithInfoTypeConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceWithInfoTypeConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceWithInfoTypeConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceWithInfoTypeConfig(od as api.ReplaceWithInfoTypeConfig);
    });
  });

  unittest.group('obj-schema-Resources', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResources();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Resources.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResources(od as api.Resources);
    });
  });

  unittest.group('obj-schema-Result', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Result.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResult(od as api.Result);
    });
  });

  unittest.group('obj-schema-RevokeConsentRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevokeConsentRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevokeConsentRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevokeConsentRequest(od as api.RevokeConsentRequest);
    });
  });

  unittest.group('obj-schema-SchemaConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemaConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchemaConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchemaConfig(od as api.SchemaConfig);
    });
  });

  unittest.group('obj-schema-SchemaGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemaGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchemaGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchemaGroup(od as api.SchemaGroup);
    });
  });

  unittest.group('obj-schema-SchemaPackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemaPackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchemaPackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchemaPackage(od as api.SchemaPackage);
    });
  });

  unittest.group('obj-schema-SchemaSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemaSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchemaSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchemaSegment(od as api.SchemaSegment);
    });
  });

  unittest.group('obj-schema-SchematizedData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchematizedData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchematizedData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchematizedData(od as api.SchematizedData);
    });
  });

  unittest.group('obj-schema-SearchResourcesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchResourcesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchResourcesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchResourcesRequest(od as api.SearchResourcesRequest);
    });
  });

  unittest.group('obj-schema-Segment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Segment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSegment(od as api.Segment);
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

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-StreamConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStreamConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StreamConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStreamConfig(od as api.StreamConfig);
    });
  });

  unittest.group('obj-schema-TagFilterList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTagFilterList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TagFilterList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTagFilterList(od as api.TagFilterList);
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

  unittest.group('obj-schema-TextConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TextConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTextConfig(od as api.TextConfig);
    });
  });

  unittest.group('obj-schema-Type', () {
    unittest.test('to-json--from-json', () async {
      var o = buildType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Type.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkType(od as api.Type);
    });
  });

  unittest.group('obj-schema-UserDataMapping', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserDataMapping();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserDataMapping.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserDataMapping(od as api.UserDataMapping);
    });
  });

  unittest.group('obj-schema-VersionSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVersionSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VersionSource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVersionSource(od as api.VersionSource);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations;
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
        var resp = convert.json.encode(buildLocation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkLocation(response as api.Location);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildListLocationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLocationsResponse(response as api.ListLocationsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsDatasetsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
      var arg_request = buildDataset();
      var arg_parent = 'foo';
      var arg_datasetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Dataset.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDataset(obj as api.Dataset);

        var path = (req.url).path;
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
          queryMap["datasetId"]!.first,
          unittest.equals(arg_datasetId),
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
          datasetId: arg_datasetId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--deidentify', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
      var arg_request = buildDeidentifyDatasetRequest();
      var arg_sourceDataset = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeidentifyDatasetRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeidentifyDatasetRequest(obj as api.DeidentifyDatasetRequest);

        var path = (req.url).path;
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
      final response = await res.deidentify(arg_request, arg_sourceDataset,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
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
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
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
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
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
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
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
        var resp = convert.json.encode(buildListDatasetsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDatasetsResponse(response as api.ListDatasetsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
      var arg_request = buildDataset();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Dataset.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDataset(obj as api.Dataset);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
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
      var res = api.CloudHealthcareApi(mock).projects.locations.datasets;
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

  unittest.group('resource-ProjectsLocationsDatasetsConsentStoresResource', () {
    unittest.test('method--checkDataAccess', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
      var arg_request = buildCheckDataAccessRequest();
      var arg_consentStore = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CheckDataAccessRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCheckDataAccessRequest(obj as api.CheckDataAccessRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildCheckDataAccessResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.checkDataAccess(arg_request, arg_consentStore,
          $fields: arg_$fields);
      checkCheckDataAccessResponse(response as api.CheckDataAccessResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
      var arg_request = buildConsentStore();
      var arg_parent = 'foo';
      var arg_consentStoreId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConsentStore.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConsentStore(obj as api.ConsentStore);

        var path = (req.url).path;
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
          queryMap["consentStoreId"]!.first,
          unittest.equals(arg_consentStoreId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildConsentStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          consentStoreId: arg_consentStoreId, $fields: arg_$fields);
      checkConsentStore(response as api.ConsentStore);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
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

    unittest.test('method--evaluateUserConsents', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
      var arg_request = buildEvaluateUserConsentsRequest();
      var arg_consentStore = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EvaluateUserConsentsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEvaluateUserConsentsRequest(
            obj as api.EvaluateUserConsentsRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildEvaluateUserConsentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.evaluateUserConsents(
          arg_request, arg_consentStore,
          $fields: arg_$fields);
      checkEvaluateUserConsentsResponse(
          response as api.EvaluateUserConsentsResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
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
        var resp = convert.json.encode(buildConsentStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkConsentStore(response as api.ConsentStore);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
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
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListConsentStoresResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListConsentStoresResponse(response as api.ListConsentStoresResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
      var arg_request = buildConsentStore();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConsentStore.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConsentStore(obj as api.ConsentStore);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConsentStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkConsentStore(response as api.ConsentStore);
    });

    unittest.test('method--queryAccessibleData', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
      var arg_request = buildQueryAccessibleDataRequest();
      var arg_consentStore = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.QueryAccessibleDataRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkQueryAccessibleDataRequest(obj as api.QueryAccessibleDataRequest);

        var path = (req.url).path;
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
      final response = await res.queryAccessibleData(
          arg_request, arg_consentStore,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
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
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores;
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

  unittest.group(
      'resource-ProjectsLocationsDatasetsConsentStoresAttributeDefinitionsResource',
      () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .attributeDefinitions;
      var arg_request = buildAttributeDefinition();
      var arg_parent = 'foo';
      var arg_attributeDefinitionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AttributeDefinition.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAttributeDefinition(obj as api.AttributeDefinition);

        var path = (req.url).path;
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
          queryMap["attributeDefinitionId"]!.first,
          unittest.equals(arg_attributeDefinitionId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAttributeDefinition());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          attributeDefinitionId: arg_attributeDefinitionId,
          $fields: arg_$fields);
      checkAttributeDefinition(response as api.AttributeDefinition);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .attributeDefinitions;
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
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .attributeDefinitions;
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
        var resp = convert.json.encode(buildAttributeDefinition());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkAttributeDefinition(response as api.AttributeDefinition);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .attributeDefinitions;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListAttributeDefinitionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAttributeDefinitionsResponse(
          response as api.ListAttributeDefinitionsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .attributeDefinitions;
      var arg_request = buildAttributeDefinition();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AttributeDefinition.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAttributeDefinition(obj as api.AttributeDefinition);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildAttributeDefinition());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAttributeDefinition(response as api.AttributeDefinition);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsDatasetsConsentStoresConsentArtifactsResource',
      () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consentArtifacts;
      var arg_request = buildConsentArtifact();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConsentArtifact.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConsentArtifact(obj as api.ConsentArtifact);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConsentArtifact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkConsentArtifact(response as api.ConsentArtifact);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consentArtifacts;
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
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consentArtifacts;
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
        var resp = convert.json.encode(buildConsentArtifact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkConsentArtifact(response as api.ConsentArtifact);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consentArtifacts;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListConsentArtifactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListConsentArtifactsResponse(
          response as api.ListConsentArtifactsResponse);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsDatasetsConsentStoresConsentsResource', () {
    unittest.test('method--activate', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
      var arg_request = buildActivateConsentRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ActivateConsentRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkActivateConsentRequest(obj as api.ActivateConsentRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConsent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.activate(arg_request, arg_name, $fields: arg_$fields);
      checkConsent(response as api.Consent);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
      var arg_request = buildConsent();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Consent.fromJson(json as core.Map<core.String, core.dynamic>);
        checkConsent(obj as api.Consent);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConsent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkConsent(response as api.Consent);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
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

    unittest.test('method--deleteRevision', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
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
      final response = await res.deleteRevision(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
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
        var resp = convert.json.encode(buildConsent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkConsent(response as api.Consent);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListConsentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListConsentsResponse(response as api.ListConsentsResponse);
    });

    unittest.test('method--listRevisions', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildListConsentRevisionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listRevisions(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListConsentRevisionsResponse(
          response as api.ListConsentRevisionsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
      var arg_request = buildConsent();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Consent.fromJson(json as core.Map<core.String, core.dynamic>);
        checkConsent(obj as api.Consent);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConsent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkConsent(response as api.Consent);
    });

    unittest.test('method--reject', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
      var arg_request = buildRejectConsentRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RejectConsentRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRejectConsentRequest(obj as api.RejectConsentRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConsent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.reject(arg_request, arg_name, $fields: arg_$fields);
      checkConsent(response as api.Consent);
    });

    unittest.test('method--revoke', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .consents;
      var arg_request = buildRevokeConsentRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RevokeConsentRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRevokeConsentRequest(obj as api.RevokeConsentRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConsent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.revoke(arg_request, arg_name, $fields: arg_$fields);
      checkConsent(response as api.Consent);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsDatasetsConsentStoresUserDataMappingsResource',
      () {
    unittest.test('method--archive', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .userDataMappings;
      var arg_request = buildArchiveUserDataMappingRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ArchiveUserDataMappingRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkArchiveUserDataMappingRequest(
            obj as api.ArchiveUserDataMappingRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildArchiveUserDataMappingResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.archive(arg_request, arg_name, $fields: arg_$fields);
      checkArchiveUserDataMappingResponse(
          response as api.ArchiveUserDataMappingResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .userDataMappings;
      var arg_request = buildUserDataMapping();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserDataMapping.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserDataMapping(obj as api.UserDataMapping);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildUserDataMapping());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkUserDataMapping(response as api.UserDataMapping);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .userDataMappings;
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
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .userDataMappings;
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
        var resp = convert.json.encode(buildUserDataMapping());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkUserDataMapping(response as api.UserDataMapping);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .userDataMappings;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListUserDataMappingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListUserDataMappingsResponse(
          response as api.ListUserDataMappingsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .consentStores
          .userDataMappings;
      var arg_request = buildUserDataMapping();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserDataMapping.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserDataMapping(obj as api.UserDataMapping);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildUserDataMapping());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkUserDataMapping(response as api.UserDataMapping);
    });
  });

  unittest.group('resource-ProjectsLocationsDatasetsDicomStoresResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_request = buildDicomStore();
      var arg_parent = 'foo';
      var arg_dicomStoreId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DicomStore.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDicomStore(obj as api.DicomStore);

        var path = (req.url).path;
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
          queryMap["dicomStoreId"]!.first,
          unittest.equals(arg_dicomStoreId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDicomStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          dicomStoreId: arg_dicomStoreId, $fields: arg_$fields);
      checkDicomStore(response as api.DicomStore);
    });

    unittest.test('method--deidentify', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_request = buildDeidentifyDicomStoreRequest();
      var arg_sourceStore = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeidentifyDicomStoreRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeidentifyDicomStoreRequest(
            obj as api.DeidentifyDicomStoreRequest);

        var path = (req.url).path;
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
      final response = await res.deidentify(arg_request, arg_sourceStore,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
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

    unittest.test('method--export', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_request = buildExportDicomDataRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExportDicomDataRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExportDicomDataRequest(obj as api.ExportDicomDataRequest);

        var path = (req.url).path;
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
          await res.export(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
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
        var resp = convert.json.encode(buildDicomStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkDicomStore(response as api.DicomStore);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
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

    unittest.test('method--import', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_request = buildImportDicomDataRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ImportDicomDataRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkImportDicomDataRequest(obj as api.ImportDicomDataRequest);

        var path = (req.url).path;
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
          await res.import(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListDicomStoresResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDicomStoresResponse(response as api.ListDicomStoresResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_request = buildDicomStore();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DicomStore.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDicomStore(obj as api.DicomStore);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildDicomStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkDicomStore(response as api.DicomStore);
    });

    unittest.test('method--searchForInstances', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchForInstances(
          arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--searchForSeries', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchForSeries(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--searchForStudies', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchForStudies(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
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

    unittest.test('method--storeInstances', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
      var arg_request = buildHttpBody();
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.HttpBody.fromJson(json as core.Map<core.String, core.dynamic>);
        checkHttpBody(obj as api.HttpBody);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.storeInstances(
          arg_request, arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.dicomStores;
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

  unittest.group('resource-ProjectsLocationsDatasetsDicomStoresStudiesResource',
      () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
      final response =
          await res.delete(arg_parent, arg_dicomWebPath, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--retrieveMetadata', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveMetadata(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--retrieveStudy', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveStudy(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--searchForInstances', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchForInstances(
          arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--searchForSeries', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchForSeries(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--storeInstances', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies;
      var arg_request = buildHttpBody();
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.HttpBody.fromJson(json as core.Map<core.String, core.dynamic>);
        checkHttpBody(obj as api.HttpBody);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.storeInstances(
          arg_request, arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsDatasetsDicomStoresStudiesSeriesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
      final response =
          await res.delete(arg_parent, arg_dicomWebPath, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--retrieveMetadata', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveMetadata(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--retrieveSeries', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveSeries(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--searchForInstances', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchForInstances(
          arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsDatasetsDicomStoresStudiesSeriesInstancesResource',
      () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series
          .instances;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
      final response =
          await res.delete(arg_parent, arg_dicomWebPath, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--retrieveInstance', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series
          .instances;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveInstance(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--retrieveMetadata', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series
          .instances;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveMetadata(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--retrieveRendered', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series
          .instances;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveRendered(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsDatasetsDicomStoresStudiesSeriesInstancesFramesResource',
      () {
    unittest.test('method--retrieveFrames', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series
          .instances
          .frames;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveFrames(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--retrieveRendered', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .dicomStores
          .studies
          .series
          .instances
          .frames;
      var arg_parent = 'foo';
      var arg_dicomWebPath = 'foo';
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retrieveRendered(arg_parent, arg_dicomWebPath,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });
  });

  unittest.group('resource-ProjectsLocationsDatasetsFhirStoresResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
      var arg_request = buildFhirStore();
      var arg_parent = 'foo';
      var arg_fhirStoreId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.FhirStore.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFhirStore(obj as api.FhirStore);

        var path = (req.url).path;
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
          queryMap["fhirStoreId"]!.first,
          unittest.equals(arg_fhirStoreId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFhirStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          fhirStoreId: arg_fhirStoreId, $fields: arg_$fields);
      checkFhirStore(response as api.FhirStore);
    });

    unittest.test('method--deidentify', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
      var arg_request = buildDeidentifyFhirStoreRequest();
      var arg_sourceStore = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeidentifyFhirStoreRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeidentifyFhirStoreRequest(obj as api.DeidentifyFhirStoreRequest);

        var path = (req.url).path;
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
      final response = await res.deidentify(arg_request, arg_sourceStore,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
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

    unittest.test('method--export', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
      var arg_request = buildExportResourcesRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExportResourcesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExportResourcesRequest(obj as api.ExportResourcesRequest);

        var path = (req.url).path;
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
          await res.export(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
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
        var resp = convert.json.encode(buildFhirStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkFhirStore(response as api.FhirStore);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
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

    unittest.test('method--import', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
      var arg_request = buildImportResourcesRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ImportResourcesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkImportResourcesRequest(obj as api.ImportResourcesRequest);

        var path = (req.url).path;
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
          await res.import(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListFhirStoresResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListFhirStoresResponse(response as api.ListFhirStoresResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
      var arg_request = buildFhirStore();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.FhirStore.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFhirStore(obj as api.FhirStore);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildFhirStore());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkFhirStore(response as api.FhirStore);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
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
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.fhirStores;
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

  unittest.group('resource-ProjectsLocationsDatasetsFhirStoresFhirResource',
      () {
    unittest.test('method--PatientEverything', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_name = 'foo';
      var arg_P_count = 42;
      var arg_P_pageToken = 'foo';
      var arg_P_since = 'foo';
      var arg_P_type = 'foo';
      var arg_end = 'foo';
      var arg_start = 'foo';
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
          core.int.parse(queryMap["_count"]!.first),
          unittest.equals(arg_P_count),
        );
        unittest.expect(
          queryMap["_page_token"]!.first,
          unittest.equals(arg_P_pageToken),
        );
        unittest.expect(
          queryMap["_since"]!.first,
          unittest.equals(arg_P_since),
        );
        unittest.expect(
          queryMap["_type"]!.first,
          unittest.equals(arg_P_type),
        );
        unittest.expect(
          queryMap["end"]!.first,
          unittest.equals(arg_end),
        );
        unittest.expect(
          queryMap["start"]!.first,
          unittest.equals(arg_start),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.PatientEverything(arg_name,
          P_count: arg_P_count,
          P_pageToken: arg_P_pageToken,
          P_since: arg_P_since,
          P_type: arg_P_type,
          end: arg_end,
          start: arg_start,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--ResourcePurge', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
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
      final response = await res.ResourcePurge(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--capabilities', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.capabilities(arg_name, $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_request = buildHttpBody();
      var arg_parent = 'foo';
      var arg_type = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.HttpBody.fromJson(json as core.Map<core.String, core.dynamic>);
        checkHttpBody(obj as api.HttpBody);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent, arg_type,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--executeBundle', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_request = buildHttpBody();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.HttpBody.fromJson(json as core.Map<core.String, core.dynamic>);
        checkHttpBody(obj as api.HttpBody);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.executeBundle(arg_request, arg_parent,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--history', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_name = 'foo';
      var arg_P_at = 'foo';
      var arg_P_count = 42;
      var arg_P_pageToken = 'foo';
      var arg_P_since = 'foo';
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
          queryMap["_at"]!.first,
          unittest.equals(arg_P_at),
        );
        unittest.expect(
          core.int.parse(queryMap["_count"]!.first),
          unittest.equals(arg_P_count),
        );
        unittest.expect(
          queryMap["_page_token"]!.first,
          unittest.equals(arg_P_pageToken),
        );
        unittest.expect(
          queryMap["_since"]!.first,
          unittest.equals(arg_P_since),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.history(arg_name,
          P_at: arg_P_at,
          P_count: arg_P_count,
          P_pageToken: arg_P_pageToken,
          P_since: arg_P_since,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_request = buildHttpBody();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.HttpBody.fromJson(json as core.Map<core.String, core.dynamic>);
        checkHttpBody(obj as api.HttpBody);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--read', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.read(arg_name, $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_request = buildSearchResourcesRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchResourcesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchResourcesRequest(obj as api.SearchResourcesRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.search(arg_request, arg_parent, $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--searchType', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_request = buildSearchResourcesRequest();
      var arg_parent = 'foo';
      var arg_resourceType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchResourcesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchResourcesRequest(obj as api.SearchResourcesRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchType(
          arg_request, arg_parent, arg_resourceType,
          $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
      var arg_request = buildHttpBody();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.HttpBody.fromJson(json as core.Map<core.String, core.dynamic>);
        checkHttpBody(obj as api.HttpBody);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_name, $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });

    unittest.test('method--vread', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .fhirStores
          .fhir;
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
        var resp = convert.json.encode(buildHttpBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.vread(arg_name, $fields: arg_$fields);
      checkHttpBody(response as api.HttpBody);
    });
  });

  unittest.group('resource-ProjectsLocationsDatasetsHl7V2StoresResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
      var arg_request = buildHl7V2Store();
      var arg_parent = 'foo';
      var arg_hl7V2StoreId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Hl7V2Store.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkHl7V2Store(obj as api.Hl7V2Store);

        var path = (req.url).path;
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
          queryMap["hl7V2StoreId"]!.first,
          unittest.equals(arg_hl7V2StoreId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildHl7V2Store());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          hl7V2StoreId: arg_hl7V2StoreId, $fields: arg_$fields);
      checkHl7V2Store(response as api.Hl7V2Store);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
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
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
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
        var resp = convert.json.encode(buildHl7V2Store());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkHl7V2Store(response as api.Hl7V2Store);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
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
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListHl7V2StoresResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListHl7V2StoresResponse(response as api.ListHl7V2StoresResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
      var arg_request = buildHl7V2Store();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Hl7V2Store.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkHl7V2Store(obj as api.Hl7V2Store);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildHl7V2Store());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkHl7V2Store(response as api.Hl7V2Store);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
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
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.hl7V2Stores;
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

  unittest.group(
      'resource-ProjectsLocationsDatasetsHl7V2StoresMessagesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .hl7V2Stores
          .messages;
      var arg_request = buildCreateMessageRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateMessageRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateMessageRequest(obj as api.CreateMessageRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .hl7V2Stores
          .messages;
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
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .hl7V2Stores
          .messages;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_name, view: arg_view, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--ingest', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .hl7V2Stores
          .messages;
      var arg_request = buildIngestMessageRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IngestMessageRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIngestMessageRequest(obj as api.IngestMessageRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildIngestMessageResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.ingest(arg_request, arg_parent, $fields: arg_$fields);
      checkIngestMessageResponse(response as api.IngestMessageResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .hl7V2Stores
          .messages;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListMessagesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          view: arg_view,
          $fields: arg_$fields);
      checkListMessagesResponse(response as api.ListMessagesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudHealthcareApi(mock)
          .projects
          .locations
          .datasets
          .hl7V2Stores
          .messages;
      var arg_request = buildMessage();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-ProjectsLocationsDatasetsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.operations;
      var arg_request = buildCancelOperationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelOperationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelOperationRequest(obj as api.CancelOperationRequest);

        var path = (req.url).path;
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
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.operations;
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

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudHealthcareApi(mock).projects.locations.datasets.operations;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });
  });
}

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

import 'package:googleapis/cloudkms/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAsymmetricDecryptRequest = 0;
api.AsymmetricDecryptRequest buildAsymmetricDecryptRequest() {
  var o = api.AsymmetricDecryptRequest();
  buildCounterAsymmetricDecryptRequest++;
  if (buildCounterAsymmetricDecryptRequest < 3) {
    o.ciphertext = 'foo';
    o.ciphertextCrc32c = 'foo';
  }
  buildCounterAsymmetricDecryptRequest--;
  return o;
}

void checkAsymmetricDecryptRequest(api.AsymmetricDecryptRequest o) {
  buildCounterAsymmetricDecryptRequest++;
  if (buildCounterAsymmetricDecryptRequest < 3) {
    unittest.expect(
      o.ciphertext!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ciphertextCrc32c!,
      unittest.equals('foo'),
    );
  }
  buildCounterAsymmetricDecryptRequest--;
}

core.int buildCounterAsymmetricDecryptResponse = 0;
api.AsymmetricDecryptResponse buildAsymmetricDecryptResponse() {
  var o = api.AsymmetricDecryptResponse();
  buildCounterAsymmetricDecryptResponse++;
  if (buildCounterAsymmetricDecryptResponse < 3) {
    o.plaintext = 'foo';
    o.plaintextCrc32c = 'foo';
    o.protectionLevel = 'foo';
    o.verifiedCiphertextCrc32c = true;
  }
  buildCounterAsymmetricDecryptResponse--;
  return o;
}

void checkAsymmetricDecryptResponse(api.AsymmetricDecryptResponse o) {
  buildCounterAsymmetricDecryptResponse++;
  if (buildCounterAsymmetricDecryptResponse < 3) {
    unittest.expect(
      o.plaintext!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.plaintextCrc32c!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(o.verifiedCiphertextCrc32c!, unittest.isTrue);
  }
  buildCounterAsymmetricDecryptResponse--;
}

core.int buildCounterAsymmetricSignRequest = 0;
api.AsymmetricSignRequest buildAsymmetricSignRequest() {
  var o = api.AsymmetricSignRequest();
  buildCounterAsymmetricSignRequest++;
  if (buildCounterAsymmetricSignRequest < 3) {
    o.digest = buildDigest();
    o.digestCrc32c = 'foo';
  }
  buildCounterAsymmetricSignRequest--;
  return o;
}

void checkAsymmetricSignRequest(api.AsymmetricSignRequest o) {
  buildCounterAsymmetricSignRequest++;
  if (buildCounterAsymmetricSignRequest < 3) {
    checkDigest(o.digest! as api.Digest);
    unittest.expect(
      o.digestCrc32c!,
      unittest.equals('foo'),
    );
  }
  buildCounterAsymmetricSignRequest--;
}

core.int buildCounterAsymmetricSignResponse = 0;
api.AsymmetricSignResponse buildAsymmetricSignResponse() {
  var o = api.AsymmetricSignResponse();
  buildCounterAsymmetricSignResponse++;
  if (buildCounterAsymmetricSignResponse < 3) {
    o.name = 'foo';
    o.protectionLevel = 'foo';
    o.signature = 'foo';
    o.signatureCrc32c = 'foo';
    o.verifiedDigestCrc32c = true;
  }
  buildCounterAsymmetricSignResponse--;
  return o;
}

void checkAsymmetricSignResponse(api.AsymmetricSignResponse o) {
  buildCounterAsymmetricSignResponse++;
  if (buildCounterAsymmetricSignResponse < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signatureCrc32c!,
      unittest.equals('foo'),
    );
    unittest.expect(o.verifiedDigestCrc32c!, unittest.isTrue);
  }
  buildCounterAsymmetricSignResponse--;
}

core.List<api.AuditLogConfig> buildUnnamed5630() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed5630(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed5630();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed5630(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed5631() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5631(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed5631();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed5631(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed5632() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5632(core.List<core.String> o) {
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
    o.members = buildUnnamed5632();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed5632(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.List<core.String> buildUnnamed5633() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5633(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5634() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5634(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5635() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5635(core.List<core.String> o) {
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

core.int buildCounterCertificateChains = 0;
api.CertificateChains buildCertificateChains() {
  var o = api.CertificateChains();
  buildCounterCertificateChains++;
  if (buildCounterCertificateChains < 3) {
    o.caviumCerts = buildUnnamed5633();
    o.googleCardCerts = buildUnnamed5634();
    o.googlePartitionCerts = buildUnnamed5635();
  }
  buildCounterCertificateChains--;
  return o;
}

void checkCertificateChains(api.CertificateChains o) {
  buildCounterCertificateChains++;
  if (buildCounterCertificateChains < 3) {
    checkUnnamed5633(o.caviumCerts!);
    checkUnnamed5634(o.googleCardCerts!);
    checkUnnamed5635(o.googlePartitionCerts!);
  }
  buildCounterCertificateChains--;
}

core.Map<core.String, core.String> buildUnnamed5636() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5636(core.Map<core.String, core.String> o) {
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

core.int buildCounterCryptoKey = 0;
api.CryptoKey buildCryptoKey() {
  var o = api.CryptoKey();
  buildCounterCryptoKey++;
  if (buildCounterCryptoKey < 3) {
    o.createTime = 'foo';
    o.labels = buildUnnamed5636();
    o.name = 'foo';
    o.nextRotationTime = 'foo';
    o.primary = buildCryptoKeyVersion();
    o.purpose = 'foo';
    o.rotationPeriod = 'foo';
    o.versionTemplate = buildCryptoKeyVersionTemplate();
  }
  buildCounterCryptoKey--;
  return o;
}

void checkCryptoKey(api.CryptoKey o) {
  buildCounterCryptoKey++;
  if (buildCounterCryptoKey < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkUnnamed5636(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextRotationTime!,
      unittest.equals('foo'),
    );
    checkCryptoKeyVersion(o.primary! as api.CryptoKeyVersion);
    unittest.expect(
      o.purpose!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rotationPeriod!,
      unittest.equals('foo'),
    );
    checkCryptoKeyVersionTemplate(
        o.versionTemplate! as api.CryptoKeyVersionTemplate);
  }
  buildCounterCryptoKey--;
}

core.int buildCounterCryptoKeyVersion = 0;
api.CryptoKeyVersion buildCryptoKeyVersion() {
  var o = api.CryptoKeyVersion();
  buildCounterCryptoKeyVersion++;
  if (buildCounterCryptoKeyVersion < 3) {
    o.algorithm = 'foo';
    o.attestation = buildKeyOperationAttestation();
    o.createTime = 'foo';
    o.destroyEventTime = 'foo';
    o.destroyTime = 'foo';
    o.externalProtectionLevelOptions = buildExternalProtectionLevelOptions();
    o.generateTime = 'foo';
    o.importFailureReason = 'foo';
    o.importJob = 'foo';
    o.importTime = 'foo';
    o.name = 'foo';
    o.protectionLevel = 'foo';
    o.state = 'foo';
  }
  buildCounterCryptoKeyVersion--;
  return o;
}

void checkCryptoKeyVersion(api.CryptoKeyVersion o) {
  buildCounterCryptoKeyVersion++;
  if (buildCounterCryptoKeyVersion < 3) {
    unittest.expect(
      o.algorithm!,
      unittest.equals('foo'),
    );
    checkKeyOperationAttestation(o.attestation! as api.KeyOperationAttestation);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destroyEventTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destroyTime!,
      unittest.equals('foo'),
    );
    checkExternalProtectionLevelOptions(o.externalProtectionLevelOptions!
        as api.ExternalProtectionLevelOptions);
    unittest.expect(
      o.generateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.importFailureReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.importJob!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.importTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterCryptoKeyVersion--;
}

core.int buildCounterCryptoKeyVersionTemplate = 0;
api.CryptoKeyVersionTemplate buildCryptoKeyVersionTemplate() {
  var o = api.CryptoKeyVersionTemplate();
  buildCounterCryptoKeyVersionTemplate++;
  if (buildCounterCryptoKeyVersionTemplate < 3) {
    o.algorithm = 'foo';
    o.protectionLevel = 'foo';
  }
  buildCounterCryptoKeyVersionTemplate--;
  return o;
}

void checkCryptoKeyVersionTemplate(api.CryptoKeyVersionTemplate o) {
  buildCounterCryptoKeyVersionTemplate++;
  if (buildCounterCryptoKeyVersionTemplate < 3) {
    unittest.expect(
      o.algorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
  }
  buildCounterCryptoKeyVersionTemplate--;
}

core.int buildCounterDecryptRequest = 0;
api.DecryptRequest buildDecryptRequest() {
  var o = api.DecryptRequest();
  buildCounterDecryptRequest++;
  if (buildCounterDecryptRequest < 3) {
    o.additionalAuthenticatedData = 'foo';
    o.additionalAuthenticatedDataCrc32c = 'foo';
    o.ciphertext = 'foo';
    o.ciphertextCrc32c = 'foo';
  }
  buildCounterDecryptRequest--;
  return o;
}

void checkDecryptRequest(api.DecryptRequest o) {
  buildCounterDecryptRequest++;
  if (buildCounterDecryptRequest < 3) {
    unittest.expect(
      o.additionalAuthenticatedData!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.additionalAuthenticatedDataCrc32c!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ciphertext!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ciphertextCrc32c!,
      unittest.equals('foo'),
    );
  }
  buildCounterDecryptRequest--;
}

core.int buildCounterDecryptResponse = 0;
api.DecryptResponse buildDecryptResponse() {
  var o = api.DecryptResponse();
  buildCounterDecryptResponse++;
  if (buildCounterDecryptResponse < 3) {
    o.plaintext = 'foo';
    o.plaintextCrc32c = 'foo';
    o.protectionLevel = 'foo';
    o.usedPrimary = true;
  }
  buildCounterDecryptResponse--;
  return o;
}

void checkDecryptResponse(api.DecryptResponse o) {
  buildCounterDecryptResponse++;
  if (buildCounterDecryptResponse < 3) {
    unittest.expect(
      o.plaintext!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.plaintextCrc32c!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(o.usedPrimary!, unittest.isTrue);
  }
  buildCounterDecryptResponse--;
}

core.int buildCounterDestroyCryptoKeyVersionRequest = 0;
api.DestroyCryptoKeyVersionRequest buildDestroyCryptoKeyVersionRequest() {
  var o = api.DestroyCryptoKeyVersionRequest();
  buildCounterDestroyCryptoKeyVersionRequest++;
  if (buildCounterDestroyCryptoKeyVersionRequest < 3) {}
  buildCounterDestroyCryptoKeyVersionRequest--;
  return o;
}

void checkDestroyCryptoKeyVersionRequest(api.DestroyCryptoKeyVersionRequest o) {
  buildCounterDestroyCryptoKeyVersionRequest++;
  if (buildCounterDestroyCryptoKeyVersionRequest < 3) {}
  buildCounterDestroyCryptoKeyVersionRequest--;
}

core.int buildCounterDigest = 0;
api.Digest buildDigest() {
  var o = api.Digest();
  buildCounterDigest++;
  if (buildCounterDigest < 3) {
    o.sha256 = 'foo';
    o.sha384 = 'foo';
    o.sha512 = 'foo';
  }
  buildCounterDigest--;
  return o;
}

void checkDigest(api.Digest o) {
  buildCounterDigest++;
  if (buildCounterDigest < 3) {
    unittest.expect(
      o.sha256!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha384!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha512!,
      unittest.equals('foo'),
    );
  }
  buildCounterDigest--;
}

core.int buildCounterEncryptRequest = 0;
api.EncryptRequest buildEncryptRequest() {
  var o = api.EncryptRequest();
  buildCounterEncryptRequest++;
  if (buildCounterEncryptRequest < 3) {
    o.additionalAuthenticatedData = 'foo';
    o.additionalAuthenticatedDataCrc32c = 'foo';
    o.plaintext = 'foo';
    o.plaintextCrc32c = 'foo';
  }
  buildCounterEncryptRequest--;
  return o;
}

void checkEncryptRequest(api.EncryptRequest o) {
  buildCounterEncryptRequest++;
  if (buildCounterEncryptRequest < 3) {
    unittest.expect(
      o.additionalAuthenticatedData!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.additionalAuthenticatedDataCrc32c!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.plaintext!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.plaintextCrc32c!,
      unittest.equals('foo'),
    );
  }
  buildCounterEncryptRequest--;
}

core.int buildCounterEncryptResponse = 0;
api.EncryptResponse buildEncryptResponse() {
  var o = api.EncryptResponse();
  buildCounterEncryptResponse++;
  if (buildCounterEncryptResponse < 3) {
    o.ciphertext = 'foo';
    o.ciphertextCrc32c = 'foo';
    o.name = 'foo';
    o.protectionLevel = 'foo';
    o.verifiedAdditionalAuthenticatedDataCrc32c = true;
    o.verifiedPlaintextCrc32c = true;
  }
  buildCounterEncryptResponse--;
  return o;
}

void checkEncryptResponse(api.EncryptResponse o) {
  buildCounterEncryptResponse++;
  if (buildCounterEncryptResponse < 3) {
    unittest.expect(
      o.ciphertext!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ciphertextCrc32c!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
        o.verifiedAdditionalAuthenticatedDataCrc32c!, unittest.isTrue);
    unittest.expect(o.verifiedPlaintextCrc32c!, unittest.isTrue);
  }
  buildCounterEncryptResponse--;
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

core.int buildCounterExternalProtectionLevelOptions = 0;
api.ExternalProtectionLevelOptions buildExternalProtectionLevelOptions() {
  var o = api.ExternalProtectionLevelOptions();
  buildCounterExternalProtectionLevelOptions++;
  if (buildCounterExternalProtectionLevelOptions < 3) {
    o.externalKeyUri = 'foo';
  }
  buildCounterExternalProtectionLevelOptions--;
  return o;
}

void checkExternalProtectionLevelOptions(api.ExternalProtectionLevelOptions o) {
  buildCounterExternalProtectionLevelOptions++;
  if (buildCounterExternalProtectionLevelOptions < 3) {
    unittest.expect(
      o.externalKeyUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterExternalProtectionLevelOptions--;
}

core.int buildCounterImportCryptoKeyVersionRequest = 0;
api.ImportCryptoKeyVersionRequest buildImportCryptoKeyVersionRequest() {
  var o = api.ImportCryptoKeyVersionRequest();
  buildCounterImportCryptoKeyVersionRequest++;
  if (buildCounterImportCryptoKeyVersionRequest < 3) {
    o.algorithm = 'foo';
    o.importJob = 'foo';
    o.rsaAesWrappedKey = 'foo';
  }
  buildCounterImportCryptoKeyVersionRequest--;
  return o;
}

void checkImportCryptoKeyVersionRequest(api.ImportCryptoKeyVersionRequest o) {
  buildCounterImportCryptoKeyVersionRequest++;
  if (buildCounterImportCryptoKeyVersionRequest < 3) {
    unittest.expect(
      o.algorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.importJob!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rsaAesWrappedKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterImportCryptoKeyVersionRequest--;
}

core.int buildCounterImportJob = 0;
api.ImportJob buildImportJob() {
  var o = api.ImportJob();
  buildCounterImportJob++;
  if (buildCounterImportJob < 3) {
    o.attestation = buildKeyOperationAttestation();
    o.createTime = 'foo';
    o.expireEventTime = 'foo';
    o.expireTime = 'foo';
    o.generateTime = 'foo';
    o.importMethod = 'foo';
    o.name = 'foo';
    o.protectionLevel = 'foo';
    o.publicKey = buildWrappingPublicKey();
    o.state = 'foo';
  }
  buildCounterImportJob--;
  return o;
}

void checkImportJob(api.ImportJob o) {
  buildCounterImportJob++;
  if (buildCounterImportJob < 3) {
    checkKeyOperationAttestation(o.attestation! as api.KeyOperationAttestation);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireEventTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.generateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.importMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
    checkWrappingPublicKey(o.publicKey! as api.WrappingPublicKey);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterImportJob--;
}

core.int buildCounterKeyOperationAttestation = 0;
api.KeyOperationAttestation buildKeyOperationAttestation() {
  var o = api.KeyOperationAttestation();
  buildCounterKeyOperationAttestation++;
  if (buildCounterKeyOperationAttestation < 3) {
    o.certChains = buildCertificateChains();
    o.content = 'foo';
    o.format = 'foo';
  }
  buildCounterKeyOperationAttestation--;
  return o;
}

void checkKeyOperationAttestation(api.KeyOperationAttestation o) {
  buildCounterKeyOperationAttestation++;
  if (buildCounterKeyOperationAttestation < 3) {
    checkCertificateChains(o.certChains! as api.CertificateChains);
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
  }
  buildCounterKeyOperationAttestation--;
}

core.int buildCounterKeyRing = 0;
api.KeyRing buildKeyRing() {
  var o = api.KeyRing();
  buildCounterKeyRing++;
  if (buildCounterKeyRing < 3) {
    o.createTime = 'foo';
    o.name = 'foo';
  }
  buildCounterKeyRing--;
  return o;
}

void checkKeyRing(api.KeyRing o) {
  buildCounterKeyRing++;
  if (buildCounterKeyRing < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterKeyRing--;
}

core.List<api.CryptoKeyVersion> buildUnnamed5637() {
  var o = <api.CryptoKeyVersion>[];
  o.add(buildCryptoKeyVersion());
  o.add(buildCryptoKeyVersion());
  return o;
}

void checkUnnamed5637(core.List<api.CryptoKeyVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCryptoKeyVersion(o[0] as api.CryptoKeyVersion);
  checkCryptoKeyVersion(o[1] as api.CryptoKeyVersion);
}

core.int buildCounterListCryptoKeyVersionsResponse = 0;
api.ListCryptoKeyVersionsResponse buildListCryptoKeyVersionsResponse() {
  var o = api.ListCryptoKeyVersionsResponse();
  buildCounterListCryptoKeyVersionsResponse++;
  if (buildCounterListCryptoKeyVersionsResponse < 3) {
    o.cryptoKeyVersions = buildUnnamed5637();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterListCryptoKeyVersionsResponse--;
  return o;
}

void checkListCryptoKeyVersionsResponse(api.ListCryptoKeyVersionsResponse o) {
  buildCounterListCryptoKeyVersionsResponse++;
  if (buildCounterListCryptoKeyVersionsResponse < 3) {
    checkUnnamed5637(o.cryptoKeyVersions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListCryptoKeyVersionsResponse--;
}

core.List<api.CryptoKey> buildUnnamed5638() {
  var o = <api.CryptoKey>[];
  o.add(buildCryptoKey());
  o.add(buildCryptoKey());
  return o;
}

void checkUnnamed5638(core.List<api.CryptoKey> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCryptoKey(o[0] as api.CryptoKey);
  checkCryptoKey(o[1] as api.CryptoKey);
}

core.int buildCounterListCryptoKeysResponse = 0;
api.ListCryptoKeysResponse buildListCryptoKeysResponse() {
  var o = api.ListCryptoKeysResponse();
  buildCounterListCryptoKeysResponse++;
  if (buildCounterListCryptoKeysResponse < 3) {
    o.cryptoKeys = buildUnnamed5638();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterListCryptoKeysResponse--;
  return o;
}

void checkListCryptoKeysResponse(api.ListCryptoKeysResponse o) {
  buildCounterListCryptoKeysResponse++;
  if (buildCounterListCryptoKeysResponse < 3) {
    checkUnnamed5638(o.cryptoKeys!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListCryptoKeysResponse--;
}

core.List<api.ImportJob> buildUnnamed5639() {
  var o = <api.ImportJob>[];
  o.add(buildImportJob());
  o.add(buildImportJob());
  return o;
}

void checkUnnamed5639(core.List<api.ImportJob> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImportJob(o[0] as api.ImportJob);
  checkImportJob(o[1] as api.ImportJob);
}

core.int buildCounterListImportJobsResponse = 0;
api.ListImportJobsResponse buildListImportJobsResponse() {
  var o = api.ListImportJobsResponse();
  buildCounterListImportJobsResponse++;
  if (buildCounterListImportJobsResponse < 3) {
    o.importJobs = buildUnnamed5639();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterListImportJobsResponse--;
  return o;
}

void checkListImportJobsResponse(api.ListImportJobsResponse o) {
  buildCounterListImportJobsResponse++;
  if (buildCounterListImportJobsResponse < 3) {
    checkUnnamed5639(o.importJobs!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListImportJobsResponse--;
}

core.List<api.KeyRing> buildUnnamed5640() {
  var o = <api.KeyRing>[];
  o.add(buildKeyRing());
  o.add(buildKeyRing());
  return o;
}

void checkUnnamed5640(core.List<api.KeyRing> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKeyRing(o[0] as api.KeyRing);
  checkKeyRing(o[1] as api.KeyRing);
}

core.int buildCounterListKeyRingsResponse = 0;
api.ListKeyRingsResponse buildListKeyRingsResponse() {
  var o = api.ListKeyRingsResponse();
  buildCounterListKeyRingsResponse++;
  if (buildCounterListKeyRingsResponse < 3) {
    o.keyRings = buildUnnamed5640();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterListKeyRingsResponse--;
  return o;
}

void checkListKeyRingsResponse(api.ListKeyRingsResponse o) {
  buildCounterListKeyRingsResponse++;
  if (buildCounterListKeyRingsResponse < 3) {
    checkUnnamed5640(o.keyRings!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListKeyRingsResponse--;
}

core.List<api.Location> buildUnnamed5641() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed5641(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed5641();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed5641(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.Map<core.String, core.String> buildUnnamed5642() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5642(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed5643() {
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

void checkUnnamed5643(core.Map<core.String, core.Object> o) {
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

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.displayName = 'foo';
    o.labels = buildUnnamed5642();
    o.locationId = 'foo';
    o.metadata = buildUnnamed5643();
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
    checkUnnamed5642(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed5643(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.int buildCounterLocationMetadata = 0;
api.LocationMetadata buildLocationMetadata() {
  var o = api.LocationMetadata();
  buildCounterLocationMetadata++;
  if (buildCounterLocationMetadata < 3) {
    o.ekmAvailable = true;
    o.hsmAvailable = true;
  }
  buildCounterLocationMetadata--;
  return o;
}

void checkLocationMetadata(api.LocationMetadata o) {
  buildCounterLocationMetadata++;
  if (buildCounterLocationMetadata < 3) {
    unittest.expect(o.ekmAvailable!, unittest.isTrue);
    unittest.expect(o.hsmAvailable!, unittest.isTrue);
  }
  buildCounterLocationMetadata--;
}

core.List<api.AuditConfig> buildUnnamed5644() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed5644(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed5645() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed5645(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed5644();
    o.bindings = buildUnnamed5645();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed5644(o.auditConfigs!);
    checkUnnamed5645(o.bindings!);
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

core.int buildCounterPublicKey = 0;
api.PublicKey buildPublicKey() {
  var o = api.PublicKey();
  buildCounterPublicKey++;
  if (buildCounterPublicKey < 3) {
    o.algorithm = 'foo';
    o.name = 'foo';
    o.pem = 'foo';
    o.pemCrc32c = 'foo';
    o.protectionLevel = 'foo';
  }
  buildCounterPublicKey--;
  return o;
}

void checkPublicKey(api.PublicKey o) {
  buildCounterPublicKey++;
  if (buildCounterPublicKey < 3) {
    unittest.expect(
      o.algorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pem!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pemCrc32c!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protectionLevel!,
      unittest.equals('foo'),
    );
  }
  buildCounterPublicKey--;
}

core.int buildCounterRestoreCryptoKeyVersionRequest = 0;
api.RestoreCryptoKeyVersionRequest buildRestoreCryptoKeyVersionRequest() {
  var o = api.RestoreCryptoKeyVersionRequest();
  buildCounterRestoreCryptoKeyVersionRequest++;
  if (buildCounterRestoreCryptoKeyVersionRequest < 3) {}
  buildCounterRestoreCryptoKeyVersionRequest--;
  return o;
}

void checkRestoreCryptoKeyVersionRequest(api.RestoreCryptoKeyVersionRequest o) {
  buildCounterRestoreCryptoKeyVersionRequest++;
  if (buildCounterRestoreCryptoKeyVersionRequest < 3) {}
  buildCounterRestoreCryptoKeyVersionRequest--;
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

core.List<core.String> buildUnnamed5646() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5646(core.List<core.String> o) {
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
    o.permissions = buildUnnamed5646();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed5646(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed5647() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5647(core.List<core.String> o) {
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
    o.permissions = buildUnnamed5647();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed5647(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterUpdateCryptoKeyPrimaryVersionRequest = 0;
api.UpdateCryptoKeyPrimaryVersionRequest
    buildUpdateCryptoKeyPrimaryVersionRequest() {
  var o = api.UpdateCryptoKeyPrimaryVersionRequest();
  buildCounterUpdateCryptoKeyPrimaryVersionRequest++;
  if (buildCounterUpdateCryptoKeyPrimaryVersionRequest < 3) {
    o.cryptoKeyVersionId = 'foo';
  }
  buildCounterUpdateCryptoKeyPrimaryVersionRequest--;
  return o;
}

void checkUpdateCryptoKeyPrimaryVersionRequest(
    api.UpdateCryptoKeyPrimaryVersionRequest o) {
  buildCounterUpdateCryptoKeyPrimaryVersionRequest++;
  if (buildCounterUpdateCryptoKeyPrimaryVersionRequest < 3) {
    unittest.expect(
      o.cryptoKeyVersionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateCryptoKeyPrimaryVersionRequest--;
}

core.int buildCounterWrappingPublicKey = 0;
api.WrappingPublicKey buildWrappingPublicKey() {
  var o = api.WrappingPublicKey();
  buildCounterWrappingPublicKey++;
  if (buildCounterWrappingPublicKey < 3) {
    o.pem = 'foo';
  }
  buildCounterWrappingPublicKey--;
  return o;
}

void checkWrappingPublicKey(api.WrappingPublicKey o) {
  buildCounterWrappingPublicKey++;
  if (buildCounterWrappingPublicKey < 3) {
    unittest.expect(
      o.pem!,
      unittest.equals('foo'),
    );
  }
  buildCounterWrappingPublicKey--;
}

void main() {
  unittest.group('obj-schema-AsymmetricDecryptRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsymmetricDecryptRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AsymmetricDecryptRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAsymmetricDecryptRequest(od as api.AsymmetricDecryptRequest);
    });
  });

  unittest.group('obj-schema-AsymmetricDecryptResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsymmetricDecryptResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AsymmetricDecryptResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAsymmetricDecryptResponse(od as api.AsymmetricDecryptResponse);
    });
  });

  unittest.group('obj-schema-AsymmetricSignRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsymmetricSignRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AsymmetricSignRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAsymmetricSignRequest(od as api.AsymmetricSignRequest);
    });
  });

  unittest.group('obj-schema-AsymmetricSignResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsymmetricSignResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AsymmetricSignResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAsymmetricSignResponse(od as api.AsymmetricSignResponse);
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

  unittest.group('obj-schema-CertificateChains', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCertificateChains();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CertificateChains.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCertificateChains(od as api.CertificateChains);
    });
  });

  unittest.group('obj-schema-CryptoKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCryptoKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CryptoKey.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCryptoKey(od as api.CryptoKey);
    });
  });

  unittest.group('obj-schema-CryptoKeyVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCryptoKeyVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CryptoKeyVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCryptoKeyVersion(od as api.CryptoKeyVersion);
    });
  });

  unittest.group('obj-schema-CryptoKeyVersionTemplate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCryptoKeyVersionTemplate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CryptoKeyVersionTemplate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCryptoKeyVersionTemplate(od as api.CryptoKeyVersionTemplate);
    });
  });

  unittest.group('obj-schema-DecryptRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDecryptRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DecryptRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDecryptRequest(od as api.DecryptRequest);
    });
  });

  unittest.group('obj-schema-DecryptResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDecryptResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DecryptResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDecryptResponse(od as api.DecryptResponse);
    });
  });

  unittest.group('obj-schema-DestroyCryptoKeyVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDestroyCryptoKeyVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DestroyCryptoKeyVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDestroyCryptoKeyVersionRequest(
          od as api.DestroyCryptoKeyVersionRequest);
    });
  });

  unittest.group('obj-schema-Digest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDigest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Digest.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDigest(od as api.Digest);
    });
  });

  unittest.group('obj-schema-EncryptRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEncryptRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EncryptRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEncryptRequest(od as api.EncryptRequest);
    });
  });

  unittest.group('obj-schema-EncryptResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEncryptResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EncryptResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEncryptResponse(od as api.EncryptResponse);
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

  unittest.group('obj-schema-ExternalProtectionLevelOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExternalProtectionLevelOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExternalProtectionLevelOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExternalProtectionLevelOptions(
          od as api.ExternalProtectionLevelOptions);
    });
  });

  unittest.group('obj-schema-ImportCryptoKeyVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportCryptoKeyVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImportCryptoKeyVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImportCryptoKeyVersionRequest(
          od as api.ImportCryptoKeyVersionRequest);
    });
  });

  unittest.group('obj-schema-ImportJob', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ImportJob.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImportJob(od as api.ImportJob);
    });
  });

  unittest.group('obj-schema-KeyOperationAttestation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKeyOperationAttestation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.KeyOperationAttestation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkKeyOperationAttestation(od as api.KeyOperationAttestation);
    });
  });

  unittest.group('obj-schema-KeyRing', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKeyRing();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.KeyRing.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkKeyRing(od as api.KeyRing);
    });
  });

  unittest.group('obj-schema-ListCryptoKeyVersionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCryptoKeyVersionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCryptoKeyVersionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCryptoKeyVersionsResponse(
          od as api.ListCryptoKeyVersionsResponse);
    });
  });

  unittest.group('obj-schema-ListCryptoKeysResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCryptoKeysResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCryptoKeysResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCryptoKeysResponse(od as api.ListCryptoKeysResponse);
    });
  });

  unittest.group('obj-schema-ListImportJobsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListImportJobsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListImportJobsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListImportJobsResponse(od as api.ListImportJobsResponse);
    });
  });

  unittest.group('obj-schema-ListKeyRingsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListKeyRingsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListKeyRingsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListKeyRingsResponse(od as api.ListKeyRingsResponse);
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

  unittest.group('obj-schema-Location', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Location.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocation(od as api.Location);
    });
  });

  unittest.group('obj-schema-LocationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocationMetadata(od as api.LocationMetadata);
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

  unittest.group('obj-schema-PublicKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublicKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PublicKey.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPublicKey(od as api.PublicKey);
    });
  });

  unittest.group('obj-schema-RestoreCryptoKeyVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestoreCryptoKeyVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestoreCryptoKeyVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestoreCryptoKeyVersionRequest(
          od as api.RestoreCryptoKeyVersionRequest);
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

  unittest.group('obj-schema-UpdateCryptoKeyPrimaryVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateCryptoKeyPrimaryVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateCryptoKeyPrimaryVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateCryptoKeyPrimaryVersionRequest(
          od as api.UpdateCryptoKeyPrimaryVersionRequest);
    });
  });

  unittest.group('obj-schema-WrappingPublicKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWrappingPublicKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WrappingPublicKey.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWrappingPublicKey(od as api.WrappingPublicKey);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations;
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
      var res = api.CloudKMSApi(mock).projects.locations;
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

  unittest.group('resource-ProjectsLocationsKeyRingsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings;
      var arg_request = buildKeyRing();
      var arg_parent = 'foo';
      var arg_keyRingId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.KeyRing.fromJson(json as core.Map<core.String, core.dynamic>);
        checkKeyRing(obj as api.KeyRing);

        var path = (req.url).path;
        var pathOffset = 0;
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
          queryMap["keyRingId"]!.first,
          unittest.equals(arg_keyRingId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildKeyRing());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          keyRingId: arg_keyRingId, $fields: arg_$fields);
      checkKeyRing(response as api.KeyRing);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings;
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
        var resp = convert.json.encode(buildKeyRing());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkKeyRing(response as api.KeyRing);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings;
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
      var res = api.CloudKMSApi(mock).projects.locations.keyRings;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListKeyRingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListKeyRingsResponse(response as api.ListKeyRingsResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings;
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
      var res = api.CloudKMSApi(mock).projects.locations.keyRings;
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

  unittest.group('resource-ProjectsLocationsKeyRingsCryptoKeysResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
      var arg_request = buildCryptoKey();
      var arg_parent = 'foo';
      var arg_cryptoKeyId = 'foo';
      var arg_skipInitialVersionCreation = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.CryptoKey.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCryptoKey(obj as api.CryptoKey);

        var path = (req.url).path;
        var pathOffset = 0;
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
          queryMap["cryptoKeyId"]!.first,
          unittest.equals(arg_cryptoKeyId),
        );
        unittest.expect(
          queryMap["skipInitialVersionCreation"]!.first,
          unittest.equals("$arg_skipInitialVersionCreation"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCryptoKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          cryptoKeyId: arg_cryptoKeyId,
          skipInitialVersionCreation: arg_skipInitialVersionCreation,
          $fields: arg_$fields);
      checkCryptoKey(response as api.CryptoKey);
    });

    unittest.test('method--decrypt', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
      var arg_request = buildDecryptRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DecryptRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDecryptRequest(obj as api.DecryptRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildDecryptResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.decrypt(arg_request, arg_name, $fields: arg_$fields);
      checkDecryptResponse(response as api.DecryptResponse);
    });

    unittest.test('method--encrypt', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
      var arg_request = buildEncryptRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EncryptRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEncryptRequest(obj as api.EncryptRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildEncryptResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.encrypt(arg_request, arg_name, $fields: arg_$fields);
      checkEncryptResponse(response as api.EncryptResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
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
        var resp = convert.json.encode(buildCryptoKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkCryptoKey(response as api.CryptoKey);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
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
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_versionView = 'foo';
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
          queryMap["versionView"]!.first,
          unittest.equals(arg_versionView),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListCryptoKeysResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          versionView: arg_versionView,
          $fields: arg_$fields);
      checkListCryptoKeysResponse(response as api.ListCryptoKeysResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
      var arg_request = buildCryptoKey();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.CryptoKey.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCryptoKey(obj as api.CryptoKey);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildCryptoKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkCryptoKey(response as api.CryptoKey);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
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
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
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

    unittest.test('method--updatePrimaryVersion', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.cryptoKeys;
      var arg_request = buildUpdateCryptoKeyPrimaryVersionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateCryptoKeyPrimaryVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateCryptoKeyPrimaryVersionRequest(
            obj as api.UpdateCryptoKeyPrimaryVersionRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildCryptoKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updatePrimaryVersion(arg_request, arg_name,
          $fields: arg_$fields);
      checkCryptoKey(response as api.CryptoKey);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsKeyRingsCryptoKeysCryptoKeyVersionsResource',
      () {
    unittest.test('method--asymmetricDecrypt', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
      var arg_request = buildAsymmetricDecryptRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AsymmetricDecryptRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAsymmetricDecryptRequest(obj as api.AsymmetricDecryptRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildAsymmetricDecryptResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.asymmetricDecrypt(arg_request, arg_name,
          $fields: arg_$fields);
      checkAsymmetricDecryptResponse(response as api.AsymmetricDecryptResponse);
    });

    unittest.test('method--asymmetricSign', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
      var arg_request = buildAsymmetricSignRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AsymmetricSignRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAsymmetricSignRequest(obj as api.AsymmetricSignRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildAsymmetricSignResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.asymmetricSign(arg_request, arg_name, $fields: arg_$fields);
      checkAsymmetricSignResponse(response as api.AsymmetricSignResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
      var arg_request = buildCryptoKeyVersion();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CryptoKeyVersion.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCryptoKeyVersion(obj as api.CryptoKeyVersion);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildCryptoKeyVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkCryptoKeyVersion(response as api.CryptoKeyVersion);
    });

    unittest.test('method--destroy', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
      var arg_request = buildDestroyCryptoKeyVersionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DestroyCryptoKeyVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDestroyCryptoKeyVersionRequest(
            obj as api.DestroyCryptoKeyVersionRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildCryptoKeyVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.destroy(arg_request, arg_name, $fields: arg_$fields);
      checkCryptoKeyVersion(response as api.CryptoKeyVersion);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
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
        var resp = convert.json.encode(buildCryptoKeyVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkCryptoKeyVersion(response as api.CryptoKeyVersion);
    });

    unittest.test('method--getPublicKey', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
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
        var resp = convert.json.encode(buildPublicKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getPublicKey(arg_name, $fields: arg_$fields);
      checkPublicKey(response as api.PublicKey);
    });

    unittest.test('method--import', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
      var arg_request = buildImportCryptoKeyVersionRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ImportCryptoKeyVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkImportCryptoKeyVersionRequest(
            obj as api.ImportCryptoKeyVersionRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildCryptoKeyVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.import(arg_request, arg_parent, $fields: arg_$fields);
      checkCryptoKeyVersion(response as api.CryptoKeyVersion);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
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
        var resp = convert.json.encode(buildListCryptoKeyVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          view: arg_view,
          $fields: arg_$fields);
      checkListCryptoKeyVersionsResponse(
          response as api.ListCryptoKeyVersionsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
      var arg_request = buildCryptoKeyVersion();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CryptoKeyVersion.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCryptoKeyVersion(obj as api.CryptoKeyVersion);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildCryptoKeyVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkCryptoKeyVersion(response as api.CryptoKeyVersion);
    });

    unittest.test('method--restore', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock)
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions;
      var arg_request = buildRestoreCryptoKeyVersionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RestoreCryptoKeyVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRestoreCryptoKeyVersionRequest(
            obj as api.RestoreCryptoKeyVersionRequest);

        var path = (req.url).path;
        var pathOffset = 0;
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
        var resp = convert.json.encode(buildCryptoKeyVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.restore(arg_request, arg_name, $fields: arg_$fields);
      checkCryptoKeyVersion(response as api.CryptoKeyVersion);
    });
  });

  unittest.group('resource-ProjectsLocationsKeyRingsImportJobsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.importJobs;
      var arg_request = buildImportJob();
      var arg_parent = 'foo';
      var arg_importJobId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.ImportJob.fromJson(json as core.Map<core.String, core.dynamic>);
        checkImportJob(obj as api.ImportJob);

        var path = (req.url).path;
        var pathOffset = 0;
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
          queryMap["importJobId"]!.first,
          unittest.equals(arg_importJobId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildImportJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          importJobId: arg_importJobId, $fields: arg_$fields);
      checkImportJob(response as api.ImportJob);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.importJobs;
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
        var resp = convert.json.encode(buildImportJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkImportJob(response as api.ImportJob);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.importJobs;
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
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.importJobs;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListImportJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListImportJobsResponse(response as api.ListImportJobsResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.importJobs;
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
      var res = api.CloudKMSApi(mock).projects.locations.keyRings.importJobs;
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
}

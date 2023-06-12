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

import 'package:googleapis/ondemandscanning/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAliasContext = 0;
api.AliasContext buildAliasContext() {
  var o = api.AliasContext();
  buildCounterAliasContext++;
  if (buildCounterAliasContext < 3) {
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterAliasContext--;
  return o;
}

void checkAliasContext(api.AliasContext o) {
  buildCounterAliasContext++;
  if (buildCounterAliasContext < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterAliasContext--;
}

core.int buildCounterAnalyzePackagesMetadata = 0;
api.AnalyzePackagesMetadata buildAnalyzePackagesMetadata() {
  var o = api.AnalyzePackagesMetadata();
  buildCounterAnalyzePackagesMetadata++;
  if (buildCounterAnalyzePackagesMetadata < 3) {
    o.createTime = 'foo';
    o.resourceUri = 'foo';
  }
  buildCounterAnalyzePackagesMetadata--;
  return o;
}

void checkAnalyzePackagesMetadata(api.AnalyzePackagesMetadata o) {
  buildCounterAnalyzePackagesMetadata++;
  if (buildCounterAnalyzePackagesMetadata < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzePackagesMetadata--;
}

core.int buildCounterAnalyzePackagesMetadataV1 = 0;
api.AnalyzePackagesMetadataV1 buildAnalyzePackagesMetadataV1() {
  var o = api.AnalyzePackagesMetadataV1();
  buildCounterAnalyzePackagesMetadataV1++;
  if (buildCounterAnalyzePackagesMetadataV1 < 3) {
    o.createTime = 'foo';
    o.resourceUri = 'foo';
  }
  buildCounterAnalyzePackagesMetadataV1--;
  return o;
}

void checkAnalyzePackagesMetadataV1(api.AnalyzePackagesMetadataV1 o) {
  buildCounterAnalyzePackagesMetadataV1++;
  if (buildCounterAnalyzePackagesMetadataV1 < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzePackagesMetadataV1--;
}

core.List<api.PackageData> buildUnnamed597() {
  var o = <api.PackageData>[];
  o.add(buildPackageData());
  o.add(buildPackageData());
  return o;
}

void checkUnnamed597(core.List<api.PackageData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPackageData(o[0] as api.PackageData);
  checkPackageData(o[1] as api.PackageData);
}

core.int buildCounterAnalyzePackagesRequestV1 = 0;
api.AnalyzePackagesRequestV1 buildAnalyzePackagesRequestV1() {
  var o = api.AnalyzePackagesRequestV1();
  buildCounterAnalyzePackagesRequestV1++;
  if (buildCounterAnalyzePackagesRequestV1 < 3) {
    o.packages = buildUnnamed597();
    o.resourceUri = 'foo';
  }
  buildCounterAnalyzePackagesRequestV1--;
  return o;
}

void checkAnalyzePackagesRequestV1(api.AnalyzePackagesRequestV1 o) {
  buildCounterAnalyzePackagesRequestV1++;
  if (buildCounterAnalyzePackagesRequestV1 < 3) {
    checkUnnamed597(o.packages!);
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzePackagesRequestV1--;
}

core.int buildCounterAnalyzePackagesResponse = 0;
api.AnalyzePackagesResponse buildAnalyzePackagesResponse() {
  var o = api.AnalyzePackagesResponse();
  buildCounterAnalyzePackagesResponse++;
  if (buildCounterAnalyzePackagesResponse < 3) {
    o.scan = 'foo';
  }
  buildCounterAnalyzePackagesResponse--;
  return o;
}

void checkAnalyzePackagesResponse(api.AnalyzePackagesResponse o) {
  buildCounterAnalyzePackagesResponse++;
  if (buildCounterAnalyzePackagesResponse < 3) {
    unittest.expect(
      o.scan!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzePackagesResponse--;
}

core.int buildCounterAnalyzePackagesResponseV1 = 0;
api.AnalyzePackagesResponseV1 buildAnalyzePackagesResponseV1() {
  var o = api.AnalyzePackagesResponseV1();
  buildCounterAnalyzePackagesResponseV1++;
  if (buildCounterAnalyzePackagesResponseV1 < 3) {
    o.scan = 'foo';
  }
  buildCounterAnalyzePackagesResponseV1--;
  return o;
}

void checkAnalyzePackagesResponseV1(api.AnalyzePackagesResponseV1 o) {
  buildCounterAnalyzePackagesResponseV1++;
  if (buildCounterAnalyzePackagesResponseV1 < 3) {
    unittest.expect(
      o.scan!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzePackagesResponseV1--;
}

core.List<core.String> buildUnnamed598() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed598(core.List<core.String> o) {
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

core.int buildCounterArtifact = 0;
api.Artifact buildArtifact() {
  var o = api.Artifact();
  buildCounterArtifact++;
  if (buildCounterArtifact < 3) {
    o.checksum = 'foo';
    o.id = 'foo';
    o.names = buildUnnamed598();
  }
  buildCounterArtifact--;
  return o;
}

void checkArtifact(api.Artifact o) {
  buildCounterArtifact++;
  if (buildCounterArtifact < 3) {
    unittest.expect(
      o.checksum!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed598(o.names!);
  }
  buildCounterArtifact--;
}

core.List<api.Jwt> buildUnnamed599() {
  var o = <api.Jwt>[];
  o.add(buildJwt());
  o.add(buildJwt());
  return o;
}

void checkUnnamed599(core.List<api.Jwt> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJwt(o[0] as api.Jwt);
  checkJwt(o[1] as api.Jwt);
}

core.List<api.Signature> buildUnnamed600() {
  var o = <api.Signature>[];
  o.add(buildSignature());
  o.add(buildSignature());
  return o;
}

void checkUnnamed600(core.List<api.Signature> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSignature(o[0] as api.Signature);
  checkSignature(o[1] as api.Signature);
}

core.int buildCounterAttestationOccurrence = 0;
api.AttestationOccurrence buildAttestationOccurrence() {
  var o = api.AttestationOccurrence();
  buildCounterAttestationOccurrence++;
  if (buildCounterAttestationOccurrence < 3) {
    o.jwts = buildUnnamed599();
    o.serializedPayload = 'foo';
    o.signatures = buildUnnamed600();
  }
  buildCounterAttestationOccurrence--;
  return o;
}

void checkAttestationOccurrence(api.AttestationOccurrence o) {
  buildCounterAttestationOccurrence++;
  if (buildCounterAttestationOccurrence < 3) {
    checkUnnamed599(o.jwts!);
    unittest.expect(
      o.serializedPayload!,
      unittest.equals('foo'),
    );
    checkUnnamed600(o.signatures!);
  }
  buildCounterAttestationOccurrence--;
}

core.int buildCounterBuildOccurrence = 0;
api.BuildOccurrence buildBuildOccurrence() {
  var o = api.BuildOccurrence();
  buildCounterBuildOccurrence++;
  if (buildCounterBuildOccurrence < 3) {
    o.provenance = buildBuildProvenance();
    o.provenanceBytes = 'foo';
  }
  buildCounterBuildOccurrence--;
  return o;
}

void checkBuildOccurrence(api.BuildOccurrence o) {
  buildCounterBuildOccurrence++;
  if (buildCounterBuildOccurrence < 3) {
    checkBuildProvenance(o.provenance! as api.BuildProvenance);
    unittest.expect(
      o.provenanceBytes!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuildOccurrence--;
}

core.Map<core.String, core.String> buildUnnamed601() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed601(core.Map<core.String, core.String> o) {
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

core.List<api.Artifact> buildUnnamed602() {
  var o = <api.Artifact>[];
  o.add(buildArtifact());
  o.add(buildArtifact());
  return o;
}

void checkUnnamed602(core.List<api.Artifact> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkArtifact(o[0] as api.Artifact);
  checkArtifact(o[1] as api.Artifact);
}

core.List<api.Command> buildUnnamed603() {
  var o = <api.Command>[];
  o.add(buildCommand());
  o.add(buildCommand());
  return o;
}

void checkUnnamed603(core.List<api.Command> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCommand(o[0] as api.Command);
  checkCommand(o[1] as api.Command);
}

core.int buildCounterBuildProvenance = 0;
api.BuildProvenance buildBuildProvenance() {
  var o = api.BuildProvenance();
  buildCounterBuildProvenance++;
  if (buildCounterBuildProvenance < 3) {
    o.buildOptions = buildUnnamed601();
    o.builderVersion = 'foo';
    o.builtArtifacts = buildUnnamed602();
    o.commands = buildUnnamed603();
    o.createTime = 'foo';
    o.creator = 'foo';
    o.endTime = 'foo';
    o.id = 'foo';
    o.logsUri = 'foo';
    o.projectId = 'foo';
    o.sourceProvenance = buildSource();
    o.startTime = 'foo';
    o.triggerId = 'foo';
  }
  buildCounterBuildProvenance--;
  return o;
}

void checkBuildProvenance(api.BuildProvenance o) {
  buildCounterBuildProvenance++;
  if (buildCounterBuildProvenance < 3) {
    checkUnnamed601(o.buildOptions!);
    unittest.expect(
      o.builderVersion!,
      unittest.equals('foo'),
    );
    checkUnnamed602(o.builtArtifacts!);
    checkUnnamed603(o.commands!);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creator!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.logsUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    checkSource(o.sourceProvenance! as api.Source);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.triggerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuildProvenance--;
}

core.int buildCounterCategory = 0;
api.Category buildCategory() {
  var o = api.Category();
  buildCounterCategory++;
  if (buildCounterCategory < 3) {
    o.categoryId = 'foo';
    o.name = 'foo';
  }
  buildCounterCategory--;
  return o;
}

void checkCategory(api.Category o) {
  buildCounterCategory++;
  if (buildCounterCategory < 3) {
    unittest.expect(
      o.categoryId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategory--;
}

core.int buildCounterCloudRepoSourceContext = 0;
api.CloudRepoSourceContext buildCloudRepoSourceContext() {
  var o = api.CloudRepoSourceContext();
  buildCounterCloudRepoSourceContext++;
  if (buildCounterCloudRepoSourceContext < 3) {
    o.aliasContext = buildAliasContext();
    o.repoId = buildRepoId();
    o.revisionId = 'foo';
  }
  buildCounterCloudRepoSourceContext--;
  return o;
}

void checkCloudRepoSourceContext(api.CloudRepoSourceContext o) {
  buildCounterCloudRepoSourceContext++;
  if (buildCounterCloudRepoSourceContext < 3) {
    checkAliasContext(o.aliasContext! as api.AliasContext);
    checkRepoId(o.repoId! as api.RepoId);
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudRepoSourceContext--;
}

core.List<core.String> buildUnnamed604() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed604(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed605() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed605(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed606() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed606(core.List<core.String> o) {
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

core.int buildCounterCommand = 0;
api.Command buildCommand() {
  var o = api.Command();
  buildCounterCommand++;
  if (buildCounterCommand < 3) {
    o.args = buildUnnamed604();
    o.dir = 'foo';
    o.env = buildUnnamed605();
    o.id = 'foo';
    o.name = 'foo';
    o.waitFor = buildUnnamed606();
  }
  buildCounterCommand--;
  return o;
}

void checkCommand(api.Command o) {
  buildCounterCommand++;
  if (buildCounterCommand < 3) {
    checkUnnamed604(o.args!);
    unittest.expect(
      o.dir!,
      unittest.equals('foo'),
    );
    checkUnnamed605(o.env!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed606(o.waitFor!);
  }
  buildCounterCommand--;
}

core.List<core.String> buildUnnamed607() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed607(core.List<core.String> o) {
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

core.int buildCounterDeploymentOccurrence = 0;
api.DeploymentOccurrence buildDeploymentOccurrence() {
  var o = api.DeploymentOccurrence();
  buildCounterDeploymentOccurrence++;
  if (buildCounterDeploymentOccurrence < 3) {
    o.address = 'foo';
    o.config = 'foo';
    o.deployTime = 'foo';
    o.platform = 'foo';
    o.resourceUri = buildUnnamed607();
    o.undeployTime = 'foo';
    o.userEmail = 'foo';
  }
  buildCounterDeploymentOccurrence--;
  return o;
}

void checkDeploymentOccurrence(api.DeploymentOccurrence o) {
  buildCounterDeploymentOccurrence++;
  if (buildCounterDeploymentOccurrence < 3) {
    unittest.expect(
      o.address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.config!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deployTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platform!,
      unittest.equals('foo'),
    );
    checkUnnamed607(o.resourceUri!);
    unittest.expect(
      o.undeployTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeploymentOccurrence--;
}

core.int buildCounterDiscoveryOccurrence = 0;
api.DiscoveryOccurrence buildDiscoveryOccurrence() {
  var o = api.DiscoveryOccurrence();
  buildCounterDiscoveryOccurrence++;
  if (buildCounterDiscoveryOccurrence < 3) {
    o.analysisStatus = 'foo';
    o.analysisStatusError = buildStatus();
    o.continuousAnalysis = 'foo';
    o.cpe = 'foo';
    o.lastScanTime = 'foo';
  }
  buildCounterDiscoveryOccurrence--;
  return o;
}

void checkDiscoveryOccurrence(api.DiscoveryOccurrence o) {
  buildCounterDiscoveryOccurrence++;
  if (buildCounterDiscoveryOccurrence < 3) {
    unittest.expect(
      o.analysisStatus!,
      unittest.equals('foo'),
    );
    checkStatus(o.analysisStatusError! as api.Status);
    unittest.expect(
      o.continuousAnalysis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cpe!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastScanTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterDiscoveryOccurrence--;
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

core.List<api.Hash> buildUnnamed608() {
  var o = <api.Hash>[];
  o.add(buildHash());
  o.add(buildHash());
  return o;
}

void checkUnnamed608(core.List<api.Hash> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHash(o[0] as api.Hash);
  checkHash(o[1] as api.Hash);
}

core.int buildCounterFileHashes = 0;
api.FileHashes buildFileHashes() {
  var o = api.FileHashes();
  buildCounterFileHashes++;
  if (buildCounterFileHashes < 3) {
    o.fileHash = buildUnnamed608();
  }
  buildCounterFileHashes--;
  return o;
}

void checkFileHashes(api.FileHashes o) {
  buildCounterFileHashes++;
  if (buildCounterFileHashes < 3) {
    checkUnnamed608(o.fileHash!);
  }
  buildCounterFileHashes--;
}

core.List<core.String> buildUnnamed609() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed609(core.List<core.String> o) {
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

core.int buildCounterFingerprint = 0;
api.Fingerprint buildFingerprint() {
  var o = api.Fingerprint();
  buildCounterFingerprint++;
  if (buildCounterFingerprint < 3) {
    o.v1Name = 'foo';
    o.v2Blob = buildUnnamed609();
    o.v2Name = 'foo';
  }
  buildCounterFingerprint--;
  return o;
}

void checkFingerprint(api.Fingerprint o) {
  buildCounterFingerprint++;
  if (buildCounterFingerprint < 3) {
    unittest.expect(
      o.v1Name!,
      unittest.equals('foo'),
    );
    checkUnnamed609(o.v2Blob!);
    unittest.expect(
      o.v2Name!,
      unittest.equals('foo'),
    );
  }
  buildCounterFingerprint--;
}

core.int buildCounterGerritSourceContext = 0;
api.GerritSourceContext buildGerritSourceContext() {
  var o = api.GerritSourceContext();
  buildCounterGerritSourceContext++;
  if (buildCounterGerritSourceContext < 3) {
    o.aliasContext = buildAliasContext();
    o.gerritProject = 'foo';
    o.hostUri = 'foo';
    o.revisionId = 'foo';
  }
  buildCounterGerritSourceContext--;
  return o;
}

void checkGerritSourceContext(api.GerritSourceContext o) {
  buildCounterGerritSourceContext++;
  if (buildCounterGerritSourceContext < 3) {
    checkAliasContext(o.aliasContext! as api.AliasContext);
    unittest.expect(
      o.gerritProject!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hostUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGerritSourceContext--;
}

core.int buildCounterGitSourceContext = 0;
api.GitSourceContext buildGitSourceContext() {
  var o = api.GitSourceContext();
  buildCounterGitSourceContext++;
  if (buildCounterGitSourceContext < 3) {
    o.revisionId = 'foo';
    o.url = 'foo';
  }
  buildCounterGitSourceContext--;
  return o;
}

void checkGitSourceContext(api.GitSourceContext o) {
  buildCounterGitSourceContext++;
  if (buildCounterGitSourceContext < 3) {
    unittest.expect(
      o.revisionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterGitSourceContext--;
}

core.int buildCounterHash = 0;
api.Hash buildHash() {
  var o = api.Hash();
  buildCounterHash++;
  if (buildCounterHash < 3) {
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterHash--;
  return o;
}

void checkHash(api.Hash o) {
  buildCounterHash++;
  if (buildCounterHash < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterHash--;
}

core.int buildCounterIdentity = 0;
api.Identity buildIdentity() {
  var o = api.Identity();
  buildCounterIdentity++;
  if (buildCounterIdentity < 3) {
    o.revision = 42;
    o.updateId = 'foo';
  }
  buildCounterIdentity--;
  return o;
}

void checkIdentity(api.Identity o) {
  buildCounterIdentity++;
  if (buildCounterIdentity < 3) {
    unittest.expect(
      o.revision!,
      unittest.equals(42),
    );
    unittest.expect(
      o.updateId!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentity--;
}

core.List<api.Layer> buildUnnamed610() {
  var o = <api.Layer>[];
  o.add(buildLayer());
  o.add(buildLayer());
  return o;
}

void checkUnnamed610(core.List<api.Layer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLayer(o[0] as api.Layer);
  checkLayer(o[1] as api.Layer);
}

core.int buildCounterImageOccurrence = 0;
api.ImageOccurrence buildImageOccurrence() {
  var o = api.ImageOccurrence();
  buildCounterImageOccurrence++;
  if (buildCounterImageOccurrence < 3) {
    o.baseResourceUrl = 'foo';
    o.distance = 42;
    o.fingerprint = buildFingerprint();
    o.layerInfo = buildUnnamed610();
  }
  buildCounterImageOccurrence--;
  return o;
}

void checkImageOccurrence(api.ImageOccurrence o) {
  buildCounterImageOccurrence++;
  if (buildCounterImageOccurrence < 3) {
    unittest.expect(
      o.baseResourceUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.distance!,
      unittest.equals(42),
    );
    checkFingerprint(o.fingerprint! as api.Fingerprint);
    checkUnnamed610(o.layerInfo!);
  }
  buildCounterImageOccurrence--;
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

core.int buildCounterLayer = 0;
api.Layer buildLayer() {
  var o = api.Layer();
  buildCounterLayer++;
  if (buildCounterLayer < 3) {
    o.arguments = 'foo';
    o.directive = 'foo';
  }
  buildCounterLayer--;
  return o;
}

void checkLayer(api.Layer o) {
  buildCounterLayer++;
  if (buildCounterLayer < 3) {
    unittest.expect(
      o.arguments!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.directive!,
      unittest.equals('foo'),
    );
  }
  buildCounterLayer--;
}

core.List<api.Operation> buildUnnamed611() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed611(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed611();
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
    checkUnnamed611(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.Occurrence> buildUnnamed612() {
  var o = <api.Occurrence>[];
  o.add(buildOccurrence());
  o.add(buildOccurrence());
  return o;
}

void checkUnnamed612(core.List<api.Occurrence> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOccurrence(o[0] as api.Occurrence);
  checkOccurrence(o[1] as api.Occurrence);
}

core.int buildCounterListVulnerabilitiesResponseV1 = 0;
api.ListVulnerabilitiesResponseV1 buildListVulnerabilitiesResponseV1() {
  var o = api.ListVulnerabilitiesResponseV1();
  buildCounterListVulnerabilitiesResponseV1++;
  if (buildCounterListVulnerabilitiesResponseV1 < 3) {
    o.nextPageToken = 'foo';
    o.occurrences = buildUnnamed612();
  }
  buildCounterListVulnerabilitiesResponseV1--;
  return o;
}

void checkListVulnerabilitiesResponseV1(api.ListVulnerabilitiesResponseV1 o) {
  buildCounterListVulnerabilitiesResponseV1++;
  if (buildCounterListVulnerabilitiesResponseV1 < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed612(o.occurrences!);
  }
  buildCounterListVulnerabilitiesResponseV1--;
}

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.cpeUri = 'foo';
    o.path = 'foo';
    o.version = buildVersion();
  }
  buildCounterLocation--;
  return o;
}

void checkLocation(api.Location o) {
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    unittest.expect(
      o.cpeUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    checkVersion(o.version! as api.Version);
  }
  buildCounterLocation--;
}

core.int buildCounterOccurrence = 0;
api.Occurrence buildOccurrence() {
  var o = api.Occurrence();
  buildCounterOccurrence++;
  if (buildCounterOccurrence < 3) {
    o.attestation = buildAttestationOccurrence();
    o.build = buildBuildOccurrence();
    o.createTime = 'foo';
    o.deployment = buildDeploymentOccurrence();
    o.discovery = buildDiscoveryOccurrence();
    o.image = buildImageOccurrence();
    o.kind = 'foo';
    o.name = 'foo';
    o.noteName = 'foo';
    o.package = buildPackageOccurrence();
    o.remediation = 'foo';
    o.resourceUri = 'foo';
    o.updateTime = 'foo';
    o.upgrade = buildUpgradeOccurrence();
    o.vulnerability = buildVulnerabilityOccurrence();
  }
  buildCounterOccurrence--;
  return o;
}

void checkOccurrence(api.Occurrence o) {
  buildCounterOccurrence++;
  if (buildCounterOccurrence < 3) {
    checkAttestationOccurrence(o.attestation! as api.AttestationOccurrence);
    checkBuildOccurrence(o.build! as api.BuildOccurrence);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkDeploymentOccurrence(o.deployment! as api.DeploymentOccurrence);
    checkDiscoveryOccurrence(o.discovery! as api.DiscoveryOccurrence);
    checkImageOccurrence(o.image! as api.ImageOccurrence);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.noteName!,
      unittest.equals('foo'),
    );
    checkPackageOccurrence(o.package! as api.PackageOccurrence);
    unittest.expect(
      o.remediation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    checkUpgradeOccurrence(o.upgrade! as api.UpgradeOccurrence);
    checkVulnerabilityOccurrence(
        o.vulnerability! as api.VulnerabilityOccurrence);
  }
  buildCounterOccurrence--;
}

core.Map<core.String, core.Object> buildUnnamed613() {
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

void checkUnnamed613(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed614() {
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

void checkUnnamed614(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed613();
    o.name = 'foo';
    o.response = buildUnnamed614();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed613(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed614(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterPackageData = 0;
api.PackageData buildPackageData() {
  var o = api.PackageData();
  buildCounterPackageData++;
  if (buildCounterPackageData < 3) {
    o.cpeUri = 'foo';
    o.os = 'foo';
    o.osVersion = 'foo';
    o.package = 'foo';
    o.unused = 'foo';
    o.version = 'foo';
  }
  buildCounterPackageData--;
  return o;
}

void checkPackageData(api.PackageData o) {
  buildCounterPackageData++;
  if (buildCounterPackageData < 3) {
    unittest.expect(
      o.cpeUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.os!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.osVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.package!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.unused!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterPackageData--;
}

core.int buildCounterPackageIssue = 0;
api.PackageIssue buildPackageIssue() {
  var o = api.PackageIssue();
  buildCounterPackageIssue++;
  if (buildCounterPackageIssue < 3) {
    o.affectedCpeUri = 'foo';
    o.affectedPackage = 'foo';
    o.affectedVersion = buildVersion();
    o.fixAvailable = true;
    o.fixedCpeUri = 'foo';
    o.fixedPackage = 'foo';
    o.fixedVersion = buildVersion();
  }
  buildCounterPackageIssue--;
  return o;
}

void checkPackageIssue(api.PackageIssue o) {
  buildCounterPackageIssue++;
  if (buildCounterPackageIssue < 3) {
    unittest.expect(
      o.affectedCpeUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.affectedPackage!,
      unittest.equals('foo'),
    );
    checkVersion(o.affectedVersion! as api.Version);
    unittest.expect(o.fixAvailable!, unittest.isTrue);
    unittest.expect(
      o.fixedCpeUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fixedPackage!,
      unittest.equals('foo'),
    );
    checkVersion(o.fixedVersion! as api.Version);
  }
  buildCounterPackageIssue--;
}

core.List<api.Location> buildUnnamed615() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed615(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterPackageOccurrence = 0;
api.PackageOccurrence buildPackageOccurrence() {
  var o = api.PackageOccurrence();
  buildCounterPackageOccurrence++;
  if (buildCounterPackageOccurrence < 3) {
    o.location = buildUnnamed615();
    o.name = 'foo';
  }
  buildCounterPackageOccurrence--;
  return o;
}

void checkPackageOccurrence(api.PackageOccurrence o) {
  buildCounterPackageOccurrence++;
  if (buildCounterPackageOccurrence < 3) {
    checkUnnamed615(o.location!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterPackageOccurrence--;
}

core.int buildCounterProjectRepoId = 0;
api.ProjectRepoId buildProjectRepoId() {
  var o = api.ProjectRepoId();
  buildCounterProjectRepoId++;
  if (buildCounterProjectRepoId < 3) {
    o.projectId = 'foo';
    o.repoName = 'foo';
  }
  buildCounterProjectRepoId--;
  return o;
}

void checkProjectRepoId(api.ProjectRepoId o) {
  buildCounterProjectRepoId++;
  if (buildCounterProjectRepoId < 3) {
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.repoName!,
      unittest.equals('foo'),
    );
  }
  buildCounterProjectRepoId--;
}

core.int buildCounterRelatedUrl = 0;
api.RelatedUrl buildRelatedUrl() {
  var o = api.RelatedUrl();
  buildCounterRelatedUrl++;
  if (buildCounterRelatedUrl < 3) {
    o.label = 'foo';
    o.url = 'foo';
  }
  buildCounterRelatedUrl--;
  return o;
}

void checkRelatedUrl(api.RelatedUrl o) {
  buildCounterRelatedUrl++;
  if (buildCounterRelatedUrl < 3) {
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterRelatedUrl--;
}

core.int buildCounterRepoId = 0;
api.RepoId buildRepoId() {
  var o = api.RepoId();
  buildCounterRepoId++;
  if (buildCounterRepoId < 3) {
    o.projectRepoId = buildProjectRepoId();
    o.uid = 'foo';
  }
  buildCounterRepoId--;
  return o;
}

void checkRepoId(api.RepoId o) {
  buildCounterRepoId++;
  if (buildCounterRepoId < 3) {
    checkProjectRepoId(o.projectRepoId! as api.ProjectRepoId);
    unittest.expect(
      o.uid!,
      unittest.equals('foo'),
    );
  }
  buildCounterRepoId--;
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

core.List<api.SourceContext> buildUnnamed616() {
  var o = <api.SourceContext>[];
  o.add(buildSourceContext());
  o.add(buildSourceContext());
  return o;
}

void checkUnnamed616(core.List<api.SourceContext> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSourceContext(o[0] as api.SourceContext);
  checkSourceContext(o[1] as api.SourceContext);
}

core.Map<core.String, api.FileHashes> buildUnnamed617() {
  var o = <core.String, api.FileHashes>{};
  o['x'] = buildFileHashes();
  o['y'] = buildFileHashes();
  return o;
}

void checkUnnamed617(core.Map<core.String, api.FileHashes> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFileHashes(o['x']! as api.FileHashes);
  checkFileHashes(o['y']! as api.FileHashes);
}

core.int buildCounterSource = 0;
api.Source buildSource() {
  var o = api.Source();
  buildCounterSource++;
  if (buildCounterSource < 3) {
    o.additionalContexts = buildUnnamed616();
    o.artifactStorageSourceUri = 'foo';
    o.context = buildSourceContext();
    o.fileHashes = buildUnnamed617();
  }
  buildCounterSource--;
  return o;
}

void checkSource(api.Source o) {
  buildCounterSource++;
  if (buildCounterSource < 3) {
    checkUnnamed616(o.additionalContexts!);
    unittest.expect(
      o.artifactStorageSourceUri!,
      unittest.equals('foo'),
    );
    checkSourceContext(o.context! as api.SourceContext);
    checkUnnamed617(o.fileHashes!);
  }
  buildCounterSource--;
}

core.Map<core.String, core.String> buildUnnamed618() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed618(core.Map<core.String, core.String> o) {
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

core.int buildCounterSourceContext = 0;
api.SourceContext buildSourceContext() {
  var o = api.SourceContext();
  buildCounterSourceContext++;
  if (buildCounterSourceContext < 3) {
    o.cloudRepo = buildCloudRepoSourceContext();
    o.gerrit = buildGerritSourceContext();
    o.git = buildGitSourceContext();
    o.labels = buildUnnamed618();
  }
  buildCounterSourceContext--;
  return o;
}

void checkSourceContext(api.SourceContext o) {
  buildCounterSourceContext++;
  if (buildCounterSourceContext < 3) {
    checkCloudRepoSourceContext(o.cloudRepo! as api.CloudRepoSourceContext);
    checkGerritSourceContext(o.gerrit! as api.GerritSourceContext);
    checkGitSourceContext(o.git! as api.GitSourceContext);
    checkUnnamed618(o.labels!);
  }
  buildCounterSourceContext--;
}

core.Map<core.String, core.Object> buildUnnamed619() {
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

void checkUnnamed619(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed620() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed619());
  o.add(buildUnnamed619());
  return o;
}

void checkUnnamed620(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed619(o[0]);
  checkUnnamed619(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed620();
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
    checkUnnamed620(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<core.String> buildUnnamed621() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed621(core.List<core.String> o) {
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

core.int buildCounterUpgradeDistribution = 0;
api.UpgradeDistribution buildUpgradeDistribution() {
  var o = api.UpgradeDistribution();
  buildCounterUpgradeDistribution++;
  if (buildCounterUpgradeDistribution < 3) {
    o.classification = 'foo';
    o.cpeUri = 'foo';
    o.cve = buildUnnamed621();
    o.severity = 'foo';
  }
  buildCounterUpgradeDistribution--;
  return o;
}

void checkUpgradeDistribution(api.UpgradeDistribution o) {
  buildCounterUpgradeDistribution++;
  if (buildCounterUpgradeDistribution < 3) {
    unittest.expect(
      o.classification!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cpeUri!,
      unittest.equals('foo'),
    );
    checkUnnamed621(o.cve!);
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpgradeDistribution--;
}

core.int buildCounterUpgradeOccurrence = 0;
api.UpgradeOccurrence buildUpgradeOccurrence() {
  var o = api.UpgradeOccurrence();
  buildCounterUpgradeOccurrence++;
  if (buildCounterUpgradeOccurrence < 3) {
    o.distribution = buildUpgradeDistribution();
    o.package = 'foo';
    o.parsedVersion = buildVersion();
    o.windowsUpdate = buildWindowsUpdate();
  }
  buildCounterUpgradeOccurrence--;
  return o;
}

void checkUpgradeOccurrence(api.UpgradeOccurrence o) {
  buildCounterUpgradeOccurrence++;
  if (buildCounterUpgradeOccurrence < 3) {
    checkUpgradeDistribution(o.distribution! as api.UpgradeDistribution);
    unittest.expect(
      o.package!,
      unittest.equals('foo'),
    );
    checkVersion(o.parsedVersion! as api.Version);
    checkWindowsUpdate(o.windowsUpdate! as api.WindowsUpdate);
  }
  buildCounterUpgradeOccurrence--;
}

core.int buildCounterVersion = 0;
api.Version buildVersion() {
  var o = api.Version();
  buildCounterVersion++;
  if (buildCounterVersion < 3) {
    o.epoch = 42;
    o.fullName = 'foo';
    o.inclusive = true;
    o.kind = 'foo';
    o.name = 'foo';
    o.revision = 'foo';
  }
  buildCounterVersion--;
  return o;
}

void checkVersion(api.Version o) {
  buildCounterVersion++;
  if (buildCounterVersion < 3) {
    unittest.expect(
      o.epoch!,
      unittest.equals(42),
    );
    unittest.expect(
      o.fullName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.inclusive!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revision!,
      unittest.equals('foo'),
    );
  }
  buildCounterVersion--;
}

core.List<api.PackageIssue> buildUnnamed622() {
  var o = <api.PackageIssue>[];
  o.add(buildPackageIssue());
  o.add(buildPackageIssue());
  return o;
}

void checkUnnamed622(core.List<api.PackageIssue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPackageIssue(o[0] as api.PackageIssue);
  checkPackageIssue(o[1] as api.PackageIssue);
}

core.List<api.RelatedUrl> buildUnnamed623() {
  var o = <api.RelatedUrl>[];
  o.add(buildRelatedUrl());
  o.add(buildRelatedUrl());
  return o;
}

void checkUnnamed623(core.List<api.RelatedUrl> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRelatedUrl(o[0] as api.RelatedUrl);
  checkRelatedUrl(o[1] as api.RelatedUrl);
}

core.int buildCounterVulnerabilityOccurrence = 0;
api.VulnerabilityOccurrence buildVulnerabilityOccurrence() {
  var o = api.VulnerabilityOccurrence();
  buildCounterVulnerabilityOccurrence++;
  if (buildCounterVulnerabilityOccurrence < 3) {
    o.cvssScore = 42.0;
    o.effectiveSeverity = 'foo';
    o.fixAvailable = true;
    o.longDescription = 'foo';
    o.packageIssue = buildUnnamed622();
    o.relatedUrls = buildUnnamed623();
    o.severity = 'foo';
    o.shortDescription = 'foo';
    o.type = 'foo';
  }
  buildCounterVulnerabilityOccurrence--;
  return o;
}

void checkVulnerabilityOccurrence(api.VulnerabilityOccurrence o) {
  buildCounterVulnerabilityOccurrence++;
  if (buildCounterVulnerabilityOccurrence < 3) {
    unittest.expect(
      o.cvssScore!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.effectiveSeverity!,
      unittest.equals('foo'),
    );
    unittest.expect(o.fixAvailable!, unittest.isTrue);
    unittest.expect(
      o.longDescription!,
      unittest.equals('foo'),
    );
    checkUnnamed622(o.packageIssue!);
    checkUnnamed623(o.relatedUrls!);
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shortDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterVulnerabilityOccurrence--;
}

core.List<api.Category> buildUnnamed624() {
  var o = <api.Category>[];
  o.add(buildCategory());
  o.add(buildCategory());
  return o;
}

void checkUnnamed624(core.List<api.Category> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCategory(o[0] as api.Category);
  checkCategory(o[1] as api.Category);
}

core.List<core.String> buildUnnamed625() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed625(core.List<core.String> o) {
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

core.int buildCounterWindowsUpdate = 0;
api.WindowsUpdate buildWindowsUpdate() {
  var o = api.WindowsUpdate();
  buildCounterWindowsUpdate++;
  if (buildCounterWindowsUpdate < 3) {
    o.categories = buildUnnamed624();
    o.description = 'foo';
    o.identity = buildIdentity();
    o.kbArticleIds = buildUnnamed625();
    o.lastPublishedTimestamp = 'foo';
    o.supportUrl = 'foo';
    o.title = 'foo';
  }
  buildCounterWindowsUpdate--;
  return o;
}

void checkWindowsUpdate(api.WindowsUpdate o) {
  buildCounterWindowsUpdate++;
  if (buildCounterWindowsUpdate < 3) {
    checkUnnamed624(o.categories!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkIdentity(o.identity! as api.Identity);
    checkUnnamed625(o.kbArticleIds!);
    unittest.expect(
      o.lastPublishedTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.supportUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterWindowsUpdate--;
}

void main() {
  unittest.group('obj-schema-AliasContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAliasContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AliasContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAliasContext(od as api.AliasContext);
    });
  });

  unittest.group('obj-schema-AnalyzePackagesMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzePackagesMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzePackagesMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzePackagesMetadata(od as api.AnalyzePackagesMetadata);
    });
  });

  unittest.group('obj-schema-AnalyzePackagesMetadataV1', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzePackagesMetadataV1();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzePackagesMetadataV1.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzePackagesMetadataV1(od as api.AnalyzePackagesMetadataV1);
    });
  });

  unittest.group('obj-schema-AnalyzePackagesRequestV1', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzePackagesRequestV1();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzePackagesRequestV1.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzePackagesRequestV1(od as api.AnalyzePackagesRequestV1);
    });
  });

  unittest.group('obj-schema-AnalyzePackagesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzePackagesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzePackagesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzePackagesResponse(od as api.AnalyzePackagesResponse);
    });
  });

  unittest.group('obj-schema-AnalyzePackagesResponseV1', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzePackagesResponseV1();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzePackagesResponseV1.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzePackagesResponseV1(od as api.AnalyzePackagesResponseV1);
    });
  });

  unittest.group('obj-schema-Artifact', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArtifact();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Artifact.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkArtifact(od as api.Artifact);
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

  unittest.group('obj-schema-BuildOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildOccurrence(od as api.BuildOccurrence);
    });
  });

  unittest.group('obj-schema-BuildProvenance', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildProvenance();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildProvenance.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildProvenance(od as api.BuildProvenance);
    });
  });

  unittest.group('obj-schema-Category', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Category.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCategory(od as api.Category);
    });
  });

  unittest.group('obj-schema-CloudRepoSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudRepoSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudRepoSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudRepoSourceContext(od as api.CloudRepoSourceContext);
    });
  });

  unittest.group('obj-schema-Command', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommand();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Command.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCommand(od as api.Command);
    });
  });

  unittest.group('obj-schema-DeploymentOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeploymentOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeploymentOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeploymentOccurrence(od as api.DeploymentOccurrence);
    });
  });

  unittest.group('obj-schema-DiscoveryOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDiscoveryOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DiscoveryOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDiscoveryOccurrence(od as api.DiscoveryOccurrence);
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

  unittest.group('obj-schema-FileHashes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFileHashes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FileHashes.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFileHashes(od as api.FileHashes);
    });
  });

  unittest.group('obj-schema-Fingerprint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFingerprint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Fingerprint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFingerprint(od as api.Fingerprint);
    });
  });

  unittest.group('obj-schema-GerritSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGerritSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GerritSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGerritSourceContext(od as api.GerritSourceContext);
    });
  });

  unittest.group('obj-schema-GitSourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGitSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GitSourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGitSourceContext(od as api.GitSourceContext);
    });
  });

  unittest.group('obj-schema-Hash', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHash();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Hash.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHash(od as api.Hash);
    });
  });

  unittest.group('obj-schema-Identity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Identity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIdentity(od as api.Identity);
    });
  });

  unittest.group('obj-schema-ImageOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImageOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImageOccurrence(od as api.ImageOccurrence);
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

  unittest.group('obj-schema-Layer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLayer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Layer.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLayer(od as api.Layer);
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

  unittest.group('obj-schema-ListVulnerabilitiesResponseV1', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListVulnerabilitiesResponseV1();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListVulnerabilitiesResponseV1.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListVulnerabilitiesResponseV1(
          od as api.ListVulnerabilitiesResponseV1);
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

  unittest.group('obj-schema-Occurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Occurrence.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOccurrence(od as api.Occurrence);
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

  unittest.group('obj-schema-PackageData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPackageData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PackageData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPackageData(od as api.PackageData);
    });
  });

  unittest.group('obj-schema-PackageIssue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPackageIssue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PackageIssue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPackageIssue(od as api.PackageIssue);
    });
  });

  unittest.group('obj-schema-PackageOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPackageOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PackageOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPackageOccurrence(od as api.PackageOccurrence);
    });
  });

  unittest.group('obj-schema-ProjectRepoId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectRepoId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectRepoId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectRepoId(od as api.ProjectRepoId);
    });
  });

  unittest.group('obj-schema-RelatedUrl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRelatedUrl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RelatedUrl.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRelatedUrl(od as api.RelatedUrl);
    });
  });

  unittest.group('obj-schema-RepoId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepoId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RepoId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRepoId(od as api.RepoId);
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

  unittest.group('obj-schema-Source', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Source.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSource(od as api.Source);
    });
  });

  unittest.group('obj-schema-SourceContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceContext(od as api.SourceContext);
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

  unittest.group('obj-schema-UpgradeDistribution', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpgradeDistribution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpgradeDistribution.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpgradeDistribution(od as api.UpgradeDistribution);
    });
  });

  unittest.group('obj-schema-UpgradeOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpgradeOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpgradeOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpgradeOccurrence(od as api.UpgradeOccurrence);
    });
  });

  unittest.group('obj-schema-Version', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Version.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVersion(od as api.Version);
    });
  });

  unittest.group('obj-schema-VulnerabilityOccurrence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVulnerabilityOccurrence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VulnerabilityOccurrence.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVulnerabilityOccurrence(od as api.VulnerabilityOccurrence);
    });
  });

  unittest.group('obj-schema-WindowsUpdate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWindowsUpdate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WindowsUpdate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWindowsUpdate(od as api.WindowsUpdate);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.OnDemandScanningApi(mock).projects.locations.operations;
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
      final response = await res.cancel(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.OnDemandScanningApi(mock).projects.locations.operations;
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
      var res = api.OnDemandScanningApi(mock).projects.locations.operations;
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
      var res = api.OnDemandScanningApi(mock).projects.locations.operations;
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

    unittest.test('method--wait', () async {
      var mock = HttpServerMock();
      var res = api.OnDemandScanningApi(mock).projects.locations.operations;
      var arg_name = 'foo';
      var arg_timeout = 'foo';
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
          queryMap["timeout"]!.first,
          unittest.equals(arg_timeout),
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
      final response =
          await res.wait(arg_name, timeout: arg_timeout, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsScansResource', () {
    unittest.test('method--analyzePackages', () async {
      var mock = HttpServerMock();
      var res = api.OnDemandScanningApi(mock).projects.locations.scans;
      var arg_request = buildAnalyzePackagesRequestV1();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnalyzePackagesRequestV1.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnalyzePackagesRequestV1(obj as api.AnalyzePackagesRequestV1);

        var path = (req.url).path;
        var pathOffset = 0;
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
      final response = await res.analyzePackages(arg_request, arg_parent,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsScansVulnerabilitiesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.OnDemandScanningApi(mock)
          .projects
          .locations
          .scans
          .vulnerabilities;
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
        var resp = convert.json.encode(buildListVulnerabilitiesResponseV1());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListVulnerabilitiesResponseV1(
          response as api.ListVulnerabilitiesResponseV1);
    });
  });
}

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

import 'package:googleapis/cloudbuild/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed2003() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2003(core.List<core.String> o) {
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

core.int buildCounterArtifactObjects = 0;
api.ArtifactObjects buildArtifactObjects() {
  var o = api.ArtifactObjects();
  buildCounterArtifactObjects++;
  if (buildCounterArtifactObjects < 3) {
    o.location = 'foo';
    o.paths = buildUnnamed2003();
    o.timing = buildTimeSpan();
  }
  buildCounterArtifactObjects--;
  return o;
}

void checkArtifactObjects(api.ArtifactObjects o) {
  buildCounterArtifactObjects++;
  if (buildCounterArtifactObjects < 3) {
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    checkUnnamed2003(o.paths!);
    checkTimeSpan(o.timing! as api.TimeSpan);
  }
  buildCounterArtifactObjects--;
}

core.List<api.FileHashes> buildUnnamed2004() {
  var o = <api.FileHashes>[];
  o.add(buildFileHashes());
  o.add(buildFileHashes());
  return o;
}

void checkUnnamed2004(core.List<api.FileHashes> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFileHashes(o[0] as api.FileHashes);
  checkFileHashes(o[1] as api.FileHashes);
}

core.int buildCounterArtifactResult = 0;
api.ArtifactResult buildArtifactResult() {
  var o = api.ArtifactResult();
  buildCounterArtifactResult++;
  if (buildCounterArtifactResult < 3) {
    o.fileHash = buildUnnamed2004();
    o.location = 'foo';
  }
  buildCounterArtifactResult--;
  return o;
}

void checkArtifactResult(api.ArtifactResult o) {
  buildCounterArtifactResult++;
  if (buildCounterArtifactResult < 3) {
    checkUnnamed2004(o.fileHash!);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
  }
  buildCounterArtifactResult--;
}

core.List<core.String> buildUnnamed2005() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2005(core.List<core.String> o) {
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

core.int buildCounterArtifacts = 0;
api.Artifacts buildArtifacts() {
  var o = api.Artifacts();
  buildCounterArtifacts++;
  if (buildCounterArtifacts < 3) {
    o.images = buildUnnamed2005();
    o.objects = buildArtifactObjects();
  }
  buildCounterArtifacts--;
  return o;
}

void checkArtifacts(api.Artifacts o) {
  buildCounterArtifacts++;
  if (buildCounterArtifacts < 3) {
    checkUnnamed2005(o.images!);
    checkArtifactObjects(o.objects! as api.ArtifactObjects);
  }
  buildCounterArtifacts--;
}

core.List<core.String> buildUnnamed2006() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2006(core.List<core.String> o) {
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

core.List<api.Secret> buildUnnamed2007() {
  var o = <api.Secret>[];
  o.add(buildSecret());
  o.add(buildSecret());
  return o;
}

void checkUnnamed2007(core.List<api.Secret> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSecret(o[0] as api.Secret);
  checkSecret(o[1] as api.Secret);
}

core.List<api.BuildStep> buildUnnamed2008() {
  var o = <api.BuildStep>[];
  o.add(buildBuildStep());
  o.add(buildBuildStep());
  return o;
}

void checkUnnamed2008(core.List<api.BuildStep> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuildStep(o[0] as api.BuildStep);
  checkBuildStep(o[1] as api.BuildStep);
}

core.Map<core.String, core.String> buildUnnamed2009() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2009(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed2010() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2010(core.List<core.String> o) {
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

core.Map<core.String, api.TimeSpan> buildUnnamed2011() {
  var o = <core.String, api.TimeSpan>{};
  o['x'] = buildTimeSpan();
  o['y'] = buildTimeSpan();
  return o;
}

void checkUnnamed2011(core.Map<core.String, api.TimeSpan> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTimeSpan(o['x']! as api.TimeSpan);
  checkTimeSpan(o['y']! as api.TimeSpan);
}

core.List<api.Warning> buildUnnamed2012() {
  var o = <api.Warning>[];
  o.add(buildWarning());
  o.add(buildWarning());
  return o;
}

void checkUnnamed2012(core.List<api.Warning> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWarning(o[0] as api.Warning);
  checkWarning(o[1] as api.Warning);
}

core.int buildCounterBuild = 0;
api.Build buildBuild() {
  var o = api.Build();
  buildCounterBuild++;
  if (buildCounterBuild < 3) {
    o.artifacts = buildArtifacts();
    o.availableSecrets = buildSecrets();
    o.buildTriggerId = 'foo';
    o.createTime = 'foo';
    o.finishTime = 'foo';
    o.id = 'foo';
    o.images = buildUnnamed2006();
    o.logUrl = 'foo';
    o.logsBucket = 'foo';
    o.name = 'foo';
    o.options = buildBuildOptions();
    o.projectId = 'foo';
    o.queueTtl = 'foo';
    o.results = buildResults();
    o.secrets = buildUnnamed2007();
    o.serviceAccount = 'foo';
    o.source = buildSource();
    o.sourceProvenance = buildSourceProvenance();
    o.startTime = 'foo';
    o.status = 'foo';
    o.statusDetail = 'foo';
    o.steps = buildUnnamed2008();
    o.substitutions = buildUnnamed2009();
    o.tags = buildUnnamed2010();
    o.timeout = 'foo';
    o.timing = buildUnnamed2011();
    o.warnings = buildUnnamed2012();
  }
  buildCounterBuild--;
  return o;
}

void checkBuild(api.Build o) {
  buildCounterBuild++;
  if (buildCounterBuild < 3) {
    checkArtifacts(o.artifacts! as api.Artifacts);
    checkSecrets(o.availableSecrets! as api.Secrets);
    unittest.expect(
      o.buildTriggerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.finishTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed2006(o.images!);
    unittest.expect(
      o.logUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.logsBucket!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkBuildOptions(o.options! as api.BuildOptions);
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.queueTtl!,
      unittest.equals('foo'),
    );
    checkResults(o.results! as api.Results);
    checkUnnamed2007(o.secrets!);
    unittest.expect(
      o.serviceAccount!,
      unittest.equals('foo'),
    );
    checkSource(o.source! as api.Source);
    checkSourceProvenance(o.sourceProvenance! as api.SourceProvenance);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.statusDetail!,
      unittest.equals('foo'),
    );
    checkUnnamed2008(o.steps!);
    checkUnnamed2009(o.substitutions!);
    checkUnnamed2010(o.tags!);
    unittest.expect(
      o.timeout!,
      unittest.equals('foo'),
    );
    checkUnnamed2011(o.timing!);
    checkUnnamed2012(o.warnings!);
  }
  buildCounterBuild--;
}

core.int buildCounterBuildOperationMetadata = 0;
api.BuildOperationMetadata buildBuildOperationMetadata() {
  var o = api.BuildOperationMetadata();
  buildCounterBuildOperationMetadata++;
  if (buildCounterBuildOperationMetadata < 3) {
    o.build = buildBuild();
  }
  buildCounterBuildOperationMetadata--;
  return o;
}

void checkBuildOperationMetadata(api.BuildOperationMetadata o) {
  buildCounterBuildOperationMetadata++;
  if (buildCounterBuildOperationMetadata < 3) {
    checkBuild(o.build! as api.Build);
  }
  buildCounterBuildOperationMetadata--;
}

core.List<core.String> buildUnnamed2013() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2013(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2014() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2014(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2015() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2015(core.List<core.String> o) {
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

core.List<api.Volume> buildUnnamed2016() {
  var o = <api.Volume>[];
  o.add(buildVolume());
  o.add(buildVolume());
  return o;
}

void checkUnnamed2016(core.List<api.Volume> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVolume(o[0] as api.Volume);
  checkVolume(o[1] as api.Volume);
}

core.int buildCounterBuildOptions = 0;
api.BuildOptions buildBuildOptions() {
  var o = api.BuildOptions();
  buildCounterBuildOptions++;
  if (buildCounterBuildOptions < 3) {
    o.diskSizeGb = 'foo';
    o.dynamicSubstitutions = true;
    o.env = buildUnnamed2013();
    o.logStreamingOption = 'foo';
    o.logging = 'foo';
    o.machineType = 'foo';
    o.requestedVerifyOption = 'foo';
    o.secretEnv = buildUnnamed2014();
    o.sourceProvenanceHash = buildUnnamed2015();
    o.substitutionOption = 'foo';
    o.volumes = buildUnnamed2016();
    o.workerPool = 'foo';
  }
  buildCounterBuildOptions--;
  return o;
}

void checkBuildOptions(api.BuildOptions o) {
  buildCounterBuildOptions++;
  if (buildCounterBuildOptions < 3) {
    unittest.expect(
      o.diskSizeGb!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dynamicSubstitutions!, unittest.isTrue);
    checkUnnamed2013(o.env!);
    unittest.expect(
      o.logStreamingOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.logging!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestedVerifyOption!,
      unittest.equals('foo'),
    );
    checkUnnamed2014(o.secretEnv!);
    checkUnnamed2015(o.sourceProvenanceHash!);
    unittest.expect(
      o.substitutionOption!,
      unittest.equals('foo'),
    );
    checkUnnamed2016(o.volumes!);
    unittest.expect(
      o.workerPool!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuildOptions--;
}

core.List<core.String> buildUnnamed2017() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2017(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2018() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2018(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2019() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2019(core.List<core.String> o) {
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

core.List<api.Volume> buildUnnamed2020() {
  var o = <api.Volume>[];
  o.add(buildVolume());
  o.add(buildVolume());
  return o;
}

void checkUnnamed2020(core.List<api.Volume> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVolume(o[0] as api.Volume);
  checkVolume(o[1] as api.Volume);
}

core.List<core.String> buildUnnamed2021() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2021(core.List<core.String> o) {
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

core.int buildCounterBuildStep = 0;
api.BuildStep buildBuildStep() {
  var o = api.BuildStep();
  buildCounterBuildStep++;
  if (buildCounterBuildStep < 3) {
    o.args = buildUnnamed2017();
    o.dir = 'foo';
    o.entrypoint = 'foo';
    o.env = buildUnnamed2018();
    o.id = 'foo';
    o.name = 'foo';
    o.pullTiming = buildTimeSpan();
    o.secretEnv = buildUnnamed2019();
    o.status = 'foo';
    o.timeout = 'foo';
    o.timing = buildTimeSpan();
    o.volumes = buildUnnamed2020();
    o.waitFor = buildUnnamed2021();
  }
  buildCounterBuildStep--;
  return o;
}

void checkBuildStep(api.BuildStep o) {
  buildCounterBuildStep++;
  if (buildCounterBuildStep < 3) {
    checkUnnamed2017(o.args!);
    unittest.expect(
      o.dir!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entrypoint!,
      unittest.equals('foo'),
    );
    checkUnnamed2018(o.env!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkTimeSpan(o.pullTiming! as api.TimeSpan);
    checkUnnamed2019(o.secretEnv!);
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeout!,
      unittest.equals('foo'),
    );
    checkTimeSpan(o.timing! as api.TimeSpan);
    checkUnnamed2020(o.volumes!);
    checkUnnamed2021(o.waitFor!);
  }
  buildCounterBuildStep--;
}

core.List<core.String> buildUnnamed2022() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2022(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2023() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2023(core.List<core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed2024() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2024(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed2025() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2025(core.List<core.String> o) {
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

core.int buildCounterBuildTrigger = 0;
api.BuildTrigger buildBuildTrigger() {
  var o = api.BuildTrigger();
  buildCounterBuildTrigger++;
  if (buildCounterBuildTrigger < 3) {
    o.build = buildBuild();
    o.createTime = 'foo';
    o.description = 'foo';
    o.disabled = true;
    o.filename = 'foo';
    o.filter = 'foo';
    o.github = buildGitHubEventsConfig();
    o.id = 'foo';
    o.ignoredFiles = buildUnnamed2022();
    o.includedFiles = buildUnnamed2023();
    o.name = 'foo';
    o.pubsubConfig = buildPubsubConfig();
    o.substitutions = buildUnnamed2024();
    o.tags = buildUnnamed2025();
    o.triggerTemplate = buildRepoSource();
  }
  buildCounterBuildTrigger--;
  return o;
}

void checkBuildTrigger(api.BuildTrigger o) {
  buildCounterBuildTrigger++;
  if (buildCounterBuildTrigger < 3) {
    checkBuild(o.build! as api.Build);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.filename!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    checkGitHubEventsConfig(o.github! as api.GitHubEventsConfig);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed2022(o.ignoredFiles!);
    checkUnnamed2023(o.includedFiles!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkPubsubConfig(o.pubsubConfig! as api.PubsubConfig);
    checkUnnamed2024(o.substitutions!);
    checkUnnamed2025(o.tags!);
    checkRepoSource(o.triggerTemplate! as api.RepoSource);
  }
  buildCounterBuildTrigger--;
}

core.int buildCounterBuiltImage = 0;
api.BuiltImage buildBuiltImage() {
  var o = api.BuiltImage();
  buildCounterBuiltImage++;
  if (buildCounterBuiltImage < 3) {
    o.digest = 'foo';
    o.name = 'foo';
    o.pushTiming = buildTimeSpan();
  }
  buildCounterBuiltImage--;
  return o;
}

void checkBuiltImage(api.BuiltImage o) {
  buildCounterBuiltImage++;
  if (buildCounterBuiltImage < 3) {
    unittest.expect(
      o.digest!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkTimeSpan(o.pushTiming! as api.TimeSpan);
  }
  buildCounterBuiltImage--;
}

core.int buildCounterCancelBuildRequest = 0;
api.CancelBuildRequest buildCancelBuildRequest() {
  var o = api.CancelBuildRequest();
  buildCounterCancelBuildRequest++;
  if (buildCounterCancelBuildRequest < 3) {
    o.id = 'foo';
    o.name = 'foo';
    o.projectId = 'foo';
  }
  buildCounterCancelBuildRequest--;
  return o;
}

void checkCancelBuildRequest(api.CancelBuildRequest o) {
  buildCounterCancelBuildRequest++;
  if (buildCounterCancelBuildRequest < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCancelBuildRequest--;
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

core.List<api.Hash> buildUnnamed2026() {
  var o = <api.Hash>[];
  o.add(buildHash());
  o.add(buildHash());
  return o;
}

void checkUnnamed2026(core.List<api.Hash> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHash(o[0] as api.Hash);
  checkHash(o[1] as api.Hash);
}

core.int buildCounterFileHashes = 0;
api.FileHashes buildFileHashes() {
  var o = api.FileHashes();
  buildCounterFileHashes++;
  if (buildCounterFileHashes < 3) {
    o.fileHash = buildUnnamed2026();
  }
  buildCounterFileHashes--;
  return o;
}

void checkFileHashes(api.FileHashes o) {
  buildCounterFileHashes++;
  if (buildCounterFileHashes < 3) {
    checkUnnamed2026(o.fileHash!);
  }
  buildCounterFileHashes--;
}

core.int buildCounterGitHubEventsConfig = 0;
api.GitHubEventsConfig buildGitHubEventsConfig() {
  var o = api.GitHubEventsConfig();
  buildCounterGitHubEventsConfig++;
  if (buildCounterGitHubEventsConfig < 3) {
    o.installationId = 'foo';
    o.name = 'foo';
    o.owner = 'foo';
    o.pullRequest = buildPullRequestFilter();
    o.push = buildPushFilter();
  }
  buildCounterGitHubEventsConfig--;
  return o;
}

void checkGitHubEventsConfig(api.GitHubEventsConfig o) {
  buildCounterGitHubEventsConfig++;
  if (buildCounterGitHubEventsConfig < 3) {
    unittest.expect(
      o.installationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.owner!,
      unittest.equals('foo'),
    );
    checkPullRequestFilter(o.pullRequest! as api.PullRequestFilter);
    checkPushFilter(o.push! as api.PushFilter);
  }
  buildCounterGitHubEventsConfig--;
}

core.int buildCounterHTTPDelivery = 0;
api.HTTPDelivery buildHTTPDelivery() {
  var o = api.HTTPDelivery();
  buildCounterHTTPDelivery++;
  if (buildCounterHTTPDelivery < 3) {
    o.uri = 'foo';
  }
  buildCounterHTTPDelivery--;
  return o;
}

void checkHTTPDelivery(api.HTTPDelivery o) {
  buildCounterHTTPDelivery++;
  if (buildCounterHTTPDelivery < 3) {
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterHTTPDelivery--;
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

core.Map<core.String, core.Object> buildUnnamed2027() {
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

void checkUnnamed2027(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed2028() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2027());
  o.add(buildUnnamed2027());
  return o;
}

void checkUnnamed2028(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2027(o[0]);
  checkUnnamed2027(o[1]);
}

core.int buildCounterHttpBody = 0;
api.HttpBody buildHttpBody() {
  var o = api.HttpBody();
  buildCounterHttpBody++;
  if (buildCounterHttpBody < 3) {
    o.contentType = 'foo';
    o.data = 'foo';
    o.extensions = buildUnnamed2028();
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
    checkUnnamed2028(o.extensions!);
  }
  buildCounterHttpBody--;
}

core.Map<core.String, core.String> buildUnnamed2029() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2029(core.Map<core.String, core.String> o) {
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

core.int buildCounterInlineSecret = 0;
api.InlineSecret buildInlineSecret() {
  var o = api.InlineSecret();
  buildCounterInlineSecret++;
  if (buildCounterInlineSecret < 3) {
    o.envMap = buildUnnamed2029();
    o.kmsKeyName = 'foo';
  }
  buildCounterInlineSecret--;
  return o;
}

void checkInlineSecret(api.InlineSecret o) {
  buildCounterInlineSecret++;
  if (buildCounterInlineSecret < 3) {
    checkUnnamed2029(o.envMap!);
    unittest.expect(
      o.kmsKeyName!,
      unittest.equals('foo'),
    );
  }
  buildCounterInlineSecret--;
}

core.List<api.BuildTrigger> buildUnnamed2030() {
  var o = <api.BuildTrigger>[];
  o.add(buildBuildTrigger());
  o.add(buildBuildTrigger());
  return o;
}

void checkUnnamed2030(core.List<api.BuildTrigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuildTrigger(o[0] as api.BuildTrigger);
  checkBuildTrigger(o[1] as api.BuildTrigger);
}

core.int buildCounterListBuildTriggersResponse = 0;
api.ListBuildTriggersResponse buildListBuildTriggersResponse() {
  var o = api.ListBuildTriggersResponse();
  buildCounterListBuildTriggersResponse++;
  if (buildCounterListBuildTriggersResponse < 3) {
    o.nextPageToken = 'foo';
    o.triggers = buildUnnamed2030();
  }
  buildCounterListBuildTriggersResponse--;
  return o;
}

void checkListBuildTriggersResponse(api.ListBuildTriggersResponse o) {
  buildCounterListBuildTriggersResponse++;
  if (buildCounterListBuildTriggersResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2030(o.triggers!);
  }
  buildCounterListBuildTriggersResponse--;
}

core.List<api.Build> buildUnnamed2031() {
  var o = <api.Build>[];
  o.add(buildBuild());
  o.add(buildBuild());
  return o;
}

void checkUnnamed2031(core.List<api.Build> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuild(o[0] as api.Build);
  checkBuild(o[1] as api.Build);
}

core.int buildCounterListBuildsResponse = 0;
api.ListBuildsResponse buildListBuildsResponse() {
  var o = api.ListBuildsResponse();
  buildCounterListBuildsResponse++;
  if (buildCounterListBuildsResponse < 3) {
    o.builds = buildUnnamed2031();
    o.nextPageToken = 'foo';
  }
  buildCounterListBuildsResponse--;
  return o;
}

void checkListBuildsResponse(api.ListBuildsResponse o) {
  buildCounterListBuildsResponse++;
  if (buildCounterListBuildsResponse < 3) {
    checkUnnamed2031(o.builds!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListBuildsResponse--;
}

core.Map<core.String, core.Object> buildUnnamed2032() {
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

void checkUnnamed2032(core.Map<core.String, core.Object> o) {
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

core.int buildCounterNotification = 0;
api.Notification buildNotification() {
  var o = api.Notification();
  buildCounterNotification++;
  if (buildCounterNotification < 3) {
    o.filter = 'foo';
    o.httpDelivery = buildHTTPDelivery();
    o.slackDelivery = buildSlackDelivery();
    o.smtpDelivery = buildSMTPDelivery();
    o.structDelivery = buildUnnamed2032();
  }
  buildCounterNotification--;
  return o;
}

void checkNotification(api.Notification o) {
  buildCounterNotification++;
  if (buildCounterNotification < 3) {
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    checkHTTPDelivery(o.httpDelivery! as api.HTTPDelivery);
    checkSlackDelivery(o.slackDelivery! as api.SlackDelivery);
    checkSMTPDelivery(o.smtpDelivery! as api.SMTPDelivery);
    checkUnnamed2032(o.structDelivery!);
  }
  buildCounterNotification--;
}

core.int buildCounterNotifierConfig = 0;
api.NotifierConfig buildNotifierConfig() {
  var o = api.NotifierConfig();
  buildCounterNotifierConfig++;
  if (buildCounterNotifierConfig < 3) {
    o.apiVersion = 'foo';
    o.kind = 'foo';
    o.metadata = buildNotifierMetadata();
    o.spec = buildNotifierSpec();
  }
  buildCounterNotifierConfig--;
  return o;
}

void checkNotifierConfig(api.NotifierConfig o) {
  buildCounterNotifierConfig++;
  if (buildCounterNotifierConfig < 3) {
    unittest.expect(
      o.apiVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkNotifierMetadata(o.metadata! as api.NotifierMetadata);
    checkNotifierSpec(o.spec! as api.NotifierSpec);
  }
  buildCounterNotifierConfig--;
}

core.int buildCounterNotifierMetadata = 0;
api.NotifierMetadata buildNotifierMetadata() {
  var o = api.NotifierMetadata();
  buildCounterNotifierMetadata++;
  if (buildCounterNotifierMetadata < 3) {
    o.name = 'foo';
    o.notifier = 'foo';
  }
  buildCounterNotifierMetadata--;
  return o;
}

void checkNotifierMetadata(api.NotifierMetadata o) {
  buildCounterNotifierMetadata++;
  if (buildCounterNotifierMetadata < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notifier!,
      unittest.equals('foo'),
    );
  }
  buildCounterNotifierMetadata--;
}

core.int buildCounterNotifierSecret = 0;
api.NotifierSecret buildNotifierSecret() {
  var o = api.NotifierSecret();
  buildCounterNotifierSecret++;
  if (buildCounterNotifierSecret < 3) {
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterNotifierSecret--;
  return o;
}

void checkNotifierSecret(api.NotifierSecret o) {
  buildCounterNotifierSecret++;
  if (buildCounterNotifierSecret < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterNotifierSecret--;
}

core.int buildCounterNotifierSecretRef = 0;
api.NotifierSecretRef buildNotifierSecretRef() {
  var o = api.NotifierSecretRef();
  buildCounterNotifierSecretRef++;
  if (buildCounterNotifierSecretRef < 3) {
    o.secretRef = 'foo';
  }
  buildCounterNotifierSecretRef--;
  return o;
}

void checkNotifierSecretRef(api.NotifierSecretRef o) {
  buildCounterNotifierSecretRef++;
  if (buildCounterNotifierSecretRef < 3) {
    unittest.expect(
      o.secretRef!,
      unittest.equals('foo'),
    );
  }
  buildCounterNotifierSecretRef--;
}

core.List<api.NotifierSecret> buildUnnamed2033() {
  var o = <api.NotifierSecret>[];
  o.add(buildNotifierSecret());
  o.add(buildNotifierSecret());
  return o;
}

void checkUnnamed2033(core.List<api.NotifierSecret> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNotifierSecret(o[0] as api.NotifierSecret);
  checkNotifierSecret(o[1] as api.NotifierSecret);
}

core.int buildCounterNotifierSpec = 0;
api.NotifierSpec buildNotifierSpec() {
  var o = api.NotifierSpec();
  buildCounterNotifierSpec++;
  if (buildCounterNotifierSpec < 3) {
    o.notification = buildNotification();
    o.secrets = buildUnnamed2033();
  }
  buildCounterNotifierSpec--;
  return o;
}

void checkNotifierSpec(api.NotifierSpec o) {
  buildCounterNotifierSpec++;
  if (buildCounterNotifierSpec < 3) {
    checkNotification(o.notification! as api.Notification);
    checkUnnamed2033(o.secrets!);
  }
  buildCounterNotifierSpec--;
}

core.Map<core.String, core.Object> buildUnnamed2034() {
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

void checkUnnamed2034(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2035() {
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

void checkUnnamed2035(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed2034();
    o.name = 'foo';
    o.response = buildUnnamed2035();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed2034(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2035(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterPubsubConfig = 0;
api.PubsubConfig buildPubsubConfig() {
  var o = api.PubsubConfig();
  buildCounterPubsubConfig++;
  if (buildCounterPubsubConfig < 3) {
    o.serviceAccountEmail = 'foo';
    o.state = 'foo';
    o.subscription = 'foo';
    o.topic = 'foo';
  }
  buildCounterPubsubConfig--;
  return o;
}

void checkPubsubConfig(api.PubsubConfig o) {
  buildCounterPubsubConfig++;
  if (buildCounterPubsubConfig < 3) {
    unittest.expect(
      o.serviceAccountEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subscription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.topic!,
      unittest.equals('foo'),
    );
  }
  buildCounterPubsubConfig--;
}

core.int buildCounterPullRequestFilter = 0;
api.PullRequestFilter buildPullRequestFilter() {
  var o = api.PullRequestFilter();
  buildCounterPullRequestFilter++;
  if (buildCounterPullRequestFilter < 3) {
    o.branch = 'foo';
    o.commentControl = 'foo';
    o.invertRegex = true;
  }
  buildCounterPullRequestFilter--;
  return o;
}

void checkPullRequestFilter(api.PullRequestFilter o) {
  buildCounterPullRequestFilter++;
  if (buildCounterPullRequestFilter < 3) {
    unittest.expect(
      o.branch!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.commentControl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.invertRegex!, unittest.isTrue);
  }
  buildCounterPullRequestFilter--;
}

core.int buildCounterPushFilter = 0;
api.PushFilter buildPushFilter() {
  var o = api.PushFilter();
  buildCounterPushFilter++;
  if (buildCounterPushFilter < 3) {
    o.branch = 'foo';
    o.invertRegex = true;
    o.tag = 'foo';
  }
  buildCounterPushFilter--;
  return o;
}

void checkPushFilter(api.PushFilter o) {
  buildCounterPushFilter++;
  if (buildCounterPushFilter < 3) {
    unittest.expect(
      o.branch!,
      unittest.equals('foo'),
    );
    unittest.expect(o.invertRegex!, unittest.isTrue);
    unittest.expect(
      o.tag!,
      unittest.equals('foo'),
    );
  }
  buildCounterPushFilter--;
}

core.int buildCounterReceiveTriggerWebhookResponse = 0;
api.ReceiveTriggerWebhookResponse buildReceiveTriggerWebhookResponse() {
  var o = api.ReceiveTriggerWebhookResponse();
  buildCounterReceiveTriggerWebhookResponse++;
  if (buildCounterReceiveTriggerWebhookResponse < 3) {}
  buildCounterReceiveTriggerWebhookResponse--;
  return o;
}

void checkReceiveTriggerWebhookResponse(api.ReceiveTriggerWebhookResponse o) {
  buildCounterReceiveTriggerWebhookResponse++;
  if (buildCounterReceiveTriggerWebhookResponse < 3) {}
  buildCounterReceiveTriggerWebhookResponse--;
}

core.Map<core.String, core.String> buildUnnamed2036() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2036(core.Map<core.String, core.String> o) {
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

core.int buildCounterRepoSource = 0;
api.RepoSource buildRepoSource() {
  var o = api.RepoSource();
  buildCounterRepoSource++;
  if (buildCounterRepoSource < 3) {
    o.branchName = 'foo';
    o.commitSha = 'foo';
    o.dir = 'foo';
    o.invertRegex = true;
    o.projectId = 'foo';
    o.repoName = 'foo';
    o.substitutions = buildUnnamed2036();
    o.tagName = 'foo';
  }
  buildCounterRepoSource--;
  return o;
}

void checkRepoSource(api.RepoSource o) {
  buildCounterRepoSource++;
  if (buildCounterRepoSource < 3) {
    unittest.expect(
      o.branchName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.commitSha!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dir!,
      unittest.equals('foo'),
    );
    unittest.expect(o.invertRegex!, unittest.isTrue);
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.repoName!,
      unittest.equals('foo'),
    );
    checkUnnamed2036(o.substitutions!);
    unittest.expect(
      o.tagName!,
      unittest.equals('foo'),
    );
  }
  buildCounterRepoSource--;
}

core.List<core.String> buildUnnamed2037() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2037(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2038() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2038(core.List<core.String> o) {
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

core.List<api.BuiltImage> buildUnnamed2039() {
  var o = <api.BuiltImage>[];
  o.add(buildBuiltImage());
  o.add(buildBuiltImage());
  return o;
}

void checkUnnamed2039(core.List<api.BuiltImage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuiltImage(o[0] as api.BuiltImage);
  checkBuiltImage(o[1] as api.BuiltImage);
}

core.int buildCounterResults = 0;
api.Results buildResults() {
  var o = api.Results();
  buildCounterResults++;
  if (buildCounterResults < 3) {
    o.artifactManifest = 'foo';
    o.artifactTiming = buildTimeSpan();
    o.buildStepImages = buildUnnamed2037();
    o.buildStepOutputs = buildUnnamed2038();
    o.images = buildUnnamed2039();
    o.numArtifacts = 'foo';
  }
  buildCounterResults--;
  return o;
}

void checkResults(api.Results o) {
  buildCounterResults++;
  if (buildCounterResults < 3) {
    unittest.expect(
      o.artifactManifest!,
      unittest.equals('foo'),
    );
    checkTimeSpan(o.artifactTiming! as api.TimeSpan);
    checkUnnamed2037(o.buildStepImages!);
    checkUnnamed2038(o.buildStepOutputs!);
    checkUnnamed2039(o.images!);
    unittest.expect(
      o.numArtifacts!,
      unittest.equals('foo'),
    );
  }
  buildCounterResults--;
}

core.int buildCounterRetryBuildRequest = 0;
api.RetryBuildRequest buildRetryBuildRequest() {
  var o = api.RetryBuildRequest();
  buildCounterRetryBuildRequest++;
  if (buildCounterRetryBuildRequest < 3) {
    o.id = 'foo';
    o.name = 'foo';
    o.projectId = 'foo';
  }
  buildCounterRetryBuildRequest--;
  return o;
}

void checkRetryBuildRequest(api.RetryBuildRequest o) {
  buildCounterRetryBuildRequest++;
  if (buildCounterRetryBuildRequest < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRetryBuildRequest--;
}

core.List<core.String> buildUnnamed2040() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2040(core.List<core.String> o) {
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

core.int buildCounterSMTPDelivery = 0;
api.SMTPDelivery buildSMTPDelivery() {
  var o = api.SMTPDelivery();
  buildCounterSMTPDelivery++;
  if (buildCounterSMTPDelivery < 3) {
    o.fromAddress = 'foo';
    o.password = buildNotifierSecretRef();
    o.port = 'foo';
    o.recipientAddresses = buildUnnamed2040();
    o.senderAddress = 'foo';
    o.server = 'foo';
  }
  buildCounterSMTPDelivery--;
  return o;
}

void checkSMTPDelivery(api.SMTPDelivery o) {
  buildCounterSMTPDelivery++;
  if (buildCounterSMTPDelivery < 3) {
    unittest.expect(
      o.fromAddress!,
      unittest.equals('foo'),
    );
    checkNotifierSecretRef(o.password! as api.NotifierSecretRef);
    unittest.expect(
      o.port!,
      unittest.equals('foo'),
    );
    checkUnnamed2040(o.recipientAddresses!);
    unittest.expect(
      o.senderAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.server!,
      unittest.equals('foo'),
    );
  }
  buildCounterSMTPDelivery--;
}

core.Map<core.String, core.String> buildUnnamed2041() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2041(core.Map<core.String, core.String> o) {
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

core.int buildCounterSecret = 0;
api.Secret buildSecret() {
  var o = api.Secret();
  buildCounterSecret++;
  if (buildCounterSecret < 3) {
    o.kmsKeyName = 'foo';
    o.secretEnv = buildUnnamed2041();
  }
  buildCounterSecret--;
  return o;
}

void checkSecret(api.Secret o) {
  buildCounterSecret++;
  if (buildCounterSecret < 3) {
    unittest.expect(
      o.kmsKeyName!,
      unittest.equals('foo'),
    );
    checkUnnamed2041(o.secretEnv!);
  }
  buildCounterSecret--;
}

core.int buildCounterSecretManagerSecret = 0;
api.SecretManagerSecret buildSecretManagerSecret() {
  var o = api.SecretManagerSecret();
  buildCounterSecretManagerSecret++;
  if (buildCounterSecretManagerSecret < 3) {
    o.env = 'foo';
    o.versionName = 'foo';
  }
  buildCounterSecretManagerSecret--;
  return o;
}

void checkSecretManagerSecret(api.SecretManagerSecret o) {
  buildCounterSecretManagerSecret++;
  if (buildCounterSecretManagerSecret < 3) {
    unittest.expect(
      o.env!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSecretManagerSecret--;
}

core.List<api.InlineSecret> buildUnnamed2042() {
  var o = <api.InlineSecret>[];
  o.add(buildInlineSecret());
  o.add(buildInlineSecret());
  return o;
}

void checkUnnamed2042(core.List<api.InlineSecret> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInlineSecret(o[0] as api.InlineSecret);
  checkInlineSecret(o[1] as api.InlineSecret);
}

core.List<api.SecretManagerSecret> buildUnnamed2043() {
  var o = <api.SecretManagerSecret>[];
  o.add(buildSecretManagerSecret());
  o.add(buildSecretManagerSecret());
  return o;
}

void checkUnnamed2043(core.List<api.SecretManagerSecret> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSecretManagerSecret(o[0] as api.SecretManagerSecret);
  checkSecretManagerSecret(o[1] as api.SecretManagerSecret);
}

core.int buildCounterSecrets = 0;
api.Secrets buildSecrets() {
  var o = api.Secrets();
  buildCounterSecrets++;
  if (buildCounterSecrets < 3) {
    o.inline = buildUnnamed2042();
    o.secretManager = buildUnnamed2043();
  }
  buildCounterSecrets--;
  return o;
}

void checkSecrets(api.Secrets o) {
  buildCounterSecrets++;
  if (buildCounterSecrets < 3) {
    checkUnnamed2042(o.inline!);
    checkUnnamed2043(o.secretManager!);
  }
  buildCounterSecrets--;
}

core.int buildCounterSlackDelivery = 0;
api.SlackDelivery buildSlackDelivery() {
  var o = api.SlackDelivery();
  buildCounterSlackDelivery++;
  if (buildCounterSlackDelivery < 3) {
    o.webhookUri = buildNotifierSecretRef();
  }
  buildCounterSlackDelivery--;
  return o;
}

void checkSlackDelivery(api.SlackDelivery o) {
  buildCounterSlackDelivery++;
  if (buildCounterSlackDelivery < 3) {
    checkNotifierSecretRef(o.webhookUri! as api.NotifierSecretRef);
  }
  buildCounterSlackDelivery--;
}

core.int buildCounterSource = 0;
api.Source buildSource() {
  var o = api.Source();
  buildCounterSource++;
  if (buildCounterSource < 3) {
    o.repoSource = buildRepoSource();
    o.storageSource = buildStorageSource();
    o.storageSourceManifest = buildStorageSourceManifest();
  }
  buildCounterSource--;
  return o;
}

void checkSource(api.Source o) {
  buildCounterSource++;
  if (buildCounterSource < 3) {
    checkRepoSource(o.repoSource! as api.RepoSource);
    checkStorageSource(o.storageSource! as api.StorageSource);
    checkStorageSourceManifest(
        o.storageSourceManifest! as api.StorageSourceManifest);
  }
  buildCounterSource--;
}

core.Map<core.String, api.FileHashes> buildUnnamed2044() {
  var o = <core.String, api.FileHashes>{};
  o['x'] = buildFileHashes();
  o['y'] = buildFileHashes();
  return o;
}

void checkUnnamed2044(core.Map<core.String, api.FileHashes> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFileHashes(o['x']! as api.FileHashes);
  checkFileHashes(o['y']! as api.FileHashes);
}

core.int buildCounterSourceProvenance = 0;
api.SourceProvenance buildSourceProvenance() {
  var o = api.SourceProvenance();
  buildCounterSourceProvenance++;
  if (buildCounterSourceProvenance < 3) {
    o.fileHashes = buildUnnamed2044();
    o.resolvedRepoSource = buildRepoSource();
    o.resolvedStorageSource = buildStorageSource();
    o.resolvedStorageSourceManifest = buildStorageSourceManifest();
  }
  buildCounterSourceProvenance--;
  return o;
}

void checkSourceProvenance(api.SourceProvenance o) {
  buildCounterSourceProvenance++;
  if (buildCounterSourceProvenance < 3) {
    checkUnnamed2044(o.fileHashes!);
    checkRepoSource(o.resolvedRepoSource! as api.RepoSource);
    checkStorageSource(o.resolvedStorageSource! as api.StorageSource);
    checkStorageSourceManifest(
        o.resolvedStorageSourceManifest! as api.StorageSourceManifest);
  }
  buildCounterSourceProvenance--;
}

core.Map<core.String, core.Object> buildUnnamed2045() {
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

void checkUnnamed2045(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed2046() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2045());
  o.add(buildUnnamed2045());
  return o;
}

void checkUnnamed2046(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2045(o[0]);
  checkUnnamed2045(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed2046();
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
    checkUnnamed2046(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterStorageSource = 0;
api.StorageSource buildStorageSource() {
  var o = api.StorageSource();
  buildCounterStorageSource++;
  if (buildCounterStorageSource < 3) {
    o.bucket = 'foo';
    o.generation = 'foo';
    o.object = 'foo';
  }
  buildCounterStorageSource--;
  return o;
}

void checkStorageSource(api.StorageSource o) {
  buildCounterStorageSource++;
  if (buildCounterStorageSource < 3) {
    unittest.expect(
      o.bucket!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.generation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.object!,
      unittest.equals('foo'),
    );
  }
  buildCounterStorageSource--;
}

core.int buildCounterStorageSourceManifest = 0;
api.StorageSourceManifest buildStorageSourceManifest() {
  var o = api.StorageSourceManifest();
  buildCounterStorageSourceManifest++;
  if (buildCounterStorageSourceManifest < 3) {
    o.bucket = 'foo';
    o.generation = 'foo';
    o.object = 'foo';
  }
  buildCounterStorageSourceManifest--;
  return o;
}

void checkStorageSourceManifest(api.StorageSourceManifest o) {
  buildCounterStorageSourceManifest++;
  if (buildCounterStorageSourceManifest < 3) {
    unittest.expect(
      o.bucket!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.generation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.object!,
      unittest.equals('foo'),
    );
  }
  buildCounterStorageSourceManifest--;
}

core.int buildCounterTimeSpan = 0;
api.TimeSpan buildTimeSpan() {
  var o = api.TimeSpan();
  buildCounterTimeSpan++;
  if (buildCounterTimeSpan < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterTimeSpan--;
  return o;
}

void checkTimeSpan(api.TimeSpan o) {
  buildCounterTimeSpan++;
  if (buildCounterTimeSpan < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimeSpan--;
}

core.int buildCounterVolume = 0;
api.Volume buildVolume() {
  var o = api.Volume();
  buildCounterVolume++;
  if (buildCounterVolume < 3) {
    o.name = 'foo';
    o.path = 'foo';
  }
  buildCounterVolume--;
  return o;
}

void checkVolume(api.Volume o) {
  buildCounterVolume++;
  if (buildCounterVolume < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
  }
  buildCounterVolume--;
}

core.int buildCounterWarning = 0;
api.Warning buildWarning() {
  var o = api.Warning();
  buildCounterWarning++;
  if (buildCounterWarning < 3) {
    o.priority = 'foo';
    o.text = 'foo';
  }
  buildCounterWarning--;
  return o;
}

void checkWarning(api.Warning o) {
  buildCounterWarning++;
  if (buildCounterWarning < 3) {
    unittest.expect(
      o.priority!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterWarning--;
}

void main() {
  unittest.group('obj-schema-ArtifactObjects', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArtifactObjects();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArtifactObjects.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArtifactObjects(od as api.ArtifactObjects);
    });
  });

  unittest.group('obj-schema-ArtifactResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArtifactResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArtifactResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArtifactResult(od as api.ArtifactResult);
    });
  });

  unittest.group('obj-schema-Artifacts', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArtifacts();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Artifacts.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkArtifacts(od as api.Artifacts);
    });
  });

  unittest.group('obj-schema-Build', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuild();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Build.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBuild(od as api.Build);
    });
  });

  unittest.group('obj-schema-BuildOperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildOperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildOperationMetadata(od as api.BuildOperationMetadata);
    });
  });

  unittest.group('obj-schema-BuildOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildOptions(od as api.BuildOptions);
    });
  });

  unittest.group('obj-schema-BuildStep', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildStep();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.BuildStep.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBuildStep(od as api.BuildStep);
    });
  });

  unittest.group('obj-schema-BuildTrigger', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildTrigger();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildTrigger.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildTrigger(od as api.BuildTrigger);
    });
  });

  unittest.group('obj-schema-BuiltImage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuiltImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.BuiltImage.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBuiltImage(od as api.BuiltImage);
    });
  });

  unittest.group('obj-schema-CancelBuildRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelBuildRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelBuildRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelBuildRequest(od as api.CancelBuildRequest);
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

  unittest.group('obj-schema-GitHubEventsConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGitHubEventsConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GitHubEventsConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGitHubEventsConfig(od as api.GitHubEventsConfig);
    });
  });

  unittest.group('obj-schema-HTTPDelivery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHTTPDelivery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HTTPDelivery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHTTPDelivery(od as api.HTTPDelivery);
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

  unittest.group('obj-schema-HttpBody', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHttpBody();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.HttpBody.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHttpBody(od as api.HttpBody);
    });
  });

  unittest.group('obj-schema-InlineSecret', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInlineSecret();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InlineSecret.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInlineSecret(od as api.InlineSecret);
    });
  });

  unittest.group('obj-schema-ListBuildTriggersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListBuildTriggersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListBuildTriggersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListBuildTriggersResponse(od as api.ListBuildTriggersResponse);
    });
  });

  unittest.group('obj-schema-ListBuildsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListBuildsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListBuildsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListBuildsResponse(od as api.ListBuildsResponse);
    });
  });

  unittest.group('obj-schema-Notification', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotification();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Notification.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotification(od as api.Notification);
    });
  });

  unittest.group('obj-schema-NotifierConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotifierConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotifierConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotifierConfig(od as api.NotifierConfig);
    });
  });

  unittest.group('obj-schema-NotifierMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotifierMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotifierMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotifierMetadata(od as api.NotifierMetadata);
    });
  });

  unittest.group('obj-schema-NotifierSecret', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotifierSecret();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotifierSecret.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotifierSecret(od as api.NotifierSecret);
    });
  });

  unittest.group('obj-schema-NotifierSecretRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotifierSecretRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotifierSecretRef.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotifierSecretRef(od as api.NotifierSecretRef);
    });
  });

  unittest.group('obj-schema-NotifierSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotifierSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotifierSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotifierSpec(od as api.NotifierSpec);
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

  unittest.group('obj-schema-PubsubConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPubsubConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PubsubConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPubsubConfig(od as api.PubsubConfig);
    });
  });

  unittest.group('obj-schema-PullRequestFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPullRequestFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PullRequestFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPullRequestFilter(od as api.PullRequestFilter);
    });
  });

  unittest.group('obj-schema-PushFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPushFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PushFilter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPushFilter(od as api.PushFilter);
    });
  });

  unittest.group('obj-schema-ReceiveTriggerWebhookResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReceiveTriggerWebhookResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReceiveTriggerWebhookResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReceiveTriggerWebhookResponse(
          od as api.ReceiveTriggerWebhookResponse);
    });
  });

  unittest.group('obj-schema-RepoSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepoSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RepoSource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRepoSource(od as api.RepoSource);
    });
  });

  unittest.group('obj-schema-Results', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Results.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResults(od as api.Results);
    });
  });

  unittest.group('obj-schema-RetryBuildRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRetryBuildRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RetryBuildRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRetryBuildRequest(od as api.RetryBuildRequest);
    });
  });

  unittest.group('obj-schema-SMTPDelivery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSMTPDelivery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SMTPDelivery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSMTPDelivery(od as api.SMTPDelivery);
    });
  });

  unittest.group('obj-schema-Secret', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecret();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Secret.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSecret(od as api.Secret);
    });
  });

  unittest.group('obj-schema-SecretManagerSecret', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecretManagerSecret();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SecretManagerSecret.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSecretManagerSecret(od as api.SecretManagerSecret);
    });
  });

  unittest.group('obj-schema-Secrets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecrets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Secrets.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSecrets(od as api.Secrets);
    });
  });

  unittest.group('obj-schema-SlackDelivery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSlackDelivery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SlackDelivery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSlackDelivery(od as api.SlackDelivery);
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

  unittest.group('obj-schema-SourceProvenance', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceProvenance();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceProvenance.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceProvenance(od as api.SourceProvenance);
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

  unittest.group('obj-schema-StorageSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStorageSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StorageSource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStorageSource(od as api.StorageSource);
    });
  });

  unittest.group('obj-schema-StorageSourceManifest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStorageSourceManifest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StorageSourceManifest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStorageSourceManifest(od as api.StorageSourceManifest);
    });
  });

  unittest.group('obj-schema-TimeSpan', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeSpan();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeSpan.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeSpan(od as api.TimeSpan);
    });
  });

  unittest.group('obj-schema-Volume', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVolume();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Volume.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVolume(od as api.Volume);
    });
  });

  unittest.group('obj-schema-Warning', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWarning();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Warning.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkWarning(od as api.Warning);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).operations;
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
      var res = api.CloudBuildApi(mock).operations;
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

  unittest.group('resource-ProjectsBuildsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.builds;
      var arg_request = buildCancelBuildRequest();
      var arg_projectId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelBuildRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelBuildRequest(obj as api.CancelBuildRequest);

        var path = (req.url).path;
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
        index = path.indexOf('/builds/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/builds/"),
        );
        pathOffset += 8;
        index = path.indexOf(':cancel', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":cancel"),
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
        var resp = convert.json.encode(buildBuild());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.cancel(arg_request, arg_projectId, arg_id,
          $fields: arg_$fields);
      checkBuild(response as api.Build);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.builds;
      var arg_request = buildBuild();
      var arg_projectId = 'foo';
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Build.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBuild(obj as api.Build);

        var path = (req.url).path;
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
        index = path.indexOf('/builds', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/builds"),
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
      final response = await res.create(arg_request, arg_projectId,
          parent: arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.builds;
      var arg_projectId = 'foo';
      var arg_id = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/builds/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/builds/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
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
          queryMap["name"]!.first,
          unittest.equals(arg_name),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBuild());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_projectId, arg_id,
          name: arg_name, $fields: arg_$fields);
      checkBuild(response as api.Build);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.builds;
      var arg_projectId = 'foo';
      var arg_filter = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/builds', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/builds"),
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
        var resp = convert.json.encode(buildListBuildsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parent: arg_parent,
          $fields: arg_$fields);
      checkListBuildsResponse(response as api.ListBuildsResponse);
    });

    unittest.test('method--retry', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.builds;
      var arg_request = buildRetryBuildRequest();
      var arg_projectId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RetryBuildRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRetryBuildRequest(obj as api.RetryBuildRequest);

        var path = (req.url).path;
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
        index = path.indexOf('/builds/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/builds/"),
        );
        pathOffset += 8;
        index = path.indexOf(':retry', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals(":retry"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.retry(arg_request, arg_projectId, arg_id,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsBuildsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.locations.builds;
      var arg_request = buildCancelBuildRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelBuildRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelBuildRequest(obj as api.CancelBuildRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildBuild());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkBuild(response as api.Build);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.locations.builds;
      var arg_request = buildBuild();
      var arg_parent = 'foo';
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Build.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBuild(obj as api.Build);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["projectId"]!.first,
          unittest.equals(arg_projectId),
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
          projectId: arg_projectId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.locations.builds;
      var arg_name = 'foo';
      var arg_id = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["projectId"]!.first,
          unittest.equals(arg_projectId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBuild());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          id: arg_id, projectId: arg_projectId, $fields: arg_$fields);
      checkBuild(response as api.Build);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.locations.builds;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
          queryMap["projectId"]!.first,
          unittest.equals(arg_projectId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListBuildsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          projectId: arg_projectId,
          $fields: arg_$fields);
      checkListBuildsResponse(response as api.ListBuildsResponse);
    });

    unittest.test('method--retry', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.locations.builds;
      var arg_request = buildRetryBuildRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RetryBuildRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRetryBuildRequest(obj as api.RetryBuildRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
          await res.retry(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.locations.operations;
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
      var res = api.CloudBuildApi(mock).projects.locations.operations;
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

  unittest.group('resource-ProjectsTriggersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.triggers;
      var arg_request = buildBuildTrigger();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BuildTrigger.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBuildTrigger(obj as api.BuildTrigger);

        var path = (req.url).path;
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
        index = path.indexOf('/triggers', pathOffset);
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
          unittest.equals("/triggers"),
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
        var resp = convert.json.encode(buildBuildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_projectId, $fields: arg_$fields);
      checkBuildTrigger(response as api.BuildTrigger);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.triggers;
      var arg_projectId = 'foo';
      var arg_triggerId = 'foo';
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
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_triggerId'),
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
      final response =
          await res.delete(arg_projectId, arg_triggerId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.triggers;
      var arg_projectId = 'foo';
      var arg_triggerId = 'foo';
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
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_triggerId'),
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
        var resp = convert.json.encode(buildBuildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_projectId, arg_triggerId, $fields: arg_$fields);
      checkBuildTrigger(response as api.BuildTrigger);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.triggers;
      var arg_projectId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/triggers', pathOffset);
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
          unittest.equals("/triggers"),
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
        var resp = convert.json.encode(buildListBuildTriggersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListBuildTriggersResponse(response as api.ListBuildTriggersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.triggers;
      var arg_request = buildBuildTrigger();
      var arg_projectId = 'foo';
      var arg_triggerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BuildTrigger.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBuildTrigger(obj as api.BuildTrigger);

        var path = (req.url).path;
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
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_triggerId'),
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
        var resp = convert.json.encode(buildBuildTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_projectId, arg_triggerId,
          $fields: arg_$fields);
      checkBuildTrigger(response as api.BuildTrigger);
    });

    unittest.test('method--run', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.triggers;
      var arg_request = buildRepoSource();
      var arg_projectId = 'foo';
      var arg_triggerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RepoSource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRepoSource(obj as api.RepoSource);

        var path = (req.url).path;
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
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        index = path.indexOf(':run', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_triggerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 4),
          unittest.equals(":run"),
        );
        pathOffset += 4;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
      final response = await res.run(arg_request, arg_projectId, arg_triggerId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--webhook', () async {
      var mock = HttpServerMock();
      var res = api.CloudBuildApi(mock).projects.triggers;
      var arg_request = buildHttpBody();
      var arg_projectId = 'foo';
      var arg_trigger = 'foo';
      var arg_secret = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/triggers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/triggers/"),
        );
        pathOffset += 10;
        index = path.indexOf(':webhook', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_trigger'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals(":webhook"),
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
          queryMap["secret"]!.first,
          unittest.equals(arg_secret),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReceiveTriggerWebhookResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.webhook(
          arg_request, arg_projectId, arg_trigger,
          secret: arg_secret, $fields: arg_$fields);
      checkReceiveTriggerWebhookResponse(
          response as api.ReceiveTriggerWebhookResponse);
    });
  });
}

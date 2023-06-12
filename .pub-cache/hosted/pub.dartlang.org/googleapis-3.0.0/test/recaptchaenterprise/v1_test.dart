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

import 'package:googleapis/recaptchaenterprise/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed3609() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3609(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudRecaptchaenterpriseV1AndroidKeySettings = 0;
api.GoogleCloudRecaptchaenterpriseV1AndroidKeySettings
    buildGoogleCloudRecaptchaenterpriseV1AndroidKeySettings() {
  var o = api.GoogleCloudRecaptchaenterpriseV1AndroidKeySettings();
  buildCounterGoogleCloudRecaptchaenterpriseV1AndroidKeySettings++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1AndroidKeySettings < 3) {
    o.allowedPackageNames = buildUnnamed3609();
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1AndroidKeySettings--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1AndroidKeySettings(
    api.GoogleCloudRecaptchaenterpriseV1AndroidKeySettings o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1AndroidKeySettings++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1AndroidKeySettings < 3) {
    checkUnnamed3609(o.allowedPackageNames!);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1AndroidKeySettings--;
}

core.List<core.String> buildUnnamed3610() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3610(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest =
    0;
api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest
    buildGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest() {
  var o = api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest();
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest <
      3) {
    o.annotation = 'foo';
    o.reasons = buildUnnamed3610();
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest(
    api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest <
      3) {
    unittest.expect(
      o.annotation!,
      unittest.equals('foo'),
    );
    checkUnnamed3610(o.reasons!);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest--;
}

core.int
    buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse = 0;
api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse
    buildGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse() {
  var o = api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse();
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse <
      3) {}
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse(
    api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse <
      3) {}
  buildCounterGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse--;
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1Assessment = 0;
api.GoogleCloudRecaptchaenterpriseV1Assessment
    buildGoogleCloudRecaptchaenterpriseV1Assessment() {
  var o = api.GoogleCloudRecaptchaenterpriseV1Assessment();
  buildCounterGoogleCloudRecaptchaenterpriseV1Assessment++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Assessment < 3) {
    o.event = buildGoogleCloudRecaptchaenterpriseV1Event();
    o.name = 'foo';
    o.riskAnalysis = buildGoogleCloudRecaptchaenterpriseV1RiskAnalysis();
    o.tokenProperties = buildGoogleCloudRecaptchaenterpriseV1TokenProperties();
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Assessment--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1Assessment(
    api.GoogleCloudRecaptchaenterpriseV1Assessment o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1Assessment++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Assessment < 3) {
    checkGoogleCloudRecaptchaenterpriseV1Event(
        o.event! as api.GoogleCloudRecaptchaenterpriseV1Event);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudRecaptchaenterpriseV1RiskAnalysis(
        o.riskAnalysis! as api.GoogleCloudRecaptchaenterpriseV1RiskAnalysis);
    checkGoogleCloudRecaptchaenterpriseV1TokenProperties(o.tokenProperties!
        as api.GoogleCloudRecaptchaenterpriseV1TokenProperties);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Assessment--;
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1ChallengeMetrics = 0;
api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics
    buildGoogleCloudRecaptchaenterpriseV1ChallengeMetrics() {
  var o = api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics();
  buildCounterGoogleCloudRecaptchaenterpriseV1ChallengeMetrics++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ChallengeMetrics < 3) {
    o.failedCount = 'foo';
    o.nocaptchaCount = 'foo';
    o.pageloadCount = 'foo';
    o.passedCount = 'foo';
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ChallengeMetrics--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1ChallengeMetrics(
    api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1ChallengeMetrics++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ChallengeMetrics < 3) {
    unittest.expect(
      o.failedCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nocaptchaCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageloadCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.passedCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ChallengeMetrics--;
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1Event = 0;
api.GoogleCloudRecaptchaenterpriseV1Event
    buildGoogleCloudRecaptchaenterpriseV1Event() {
  var o = api.GoogleCloudRecaptchaenterpriseV1Event();
  buildCounterGoogleCloudRecaptchaenterpriseV1Event++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Event < 3) {
    o.expectedAction = 'foo';
    o.siteKey = 'foo';
    o.token = 'foo';
    o.userAgent = 'foo';
    o.userIpAddress = 'foo';
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Event--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1Event(
    api.GoogleCloudRecaptchaenterpriseV1Event o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1Event++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Event < 3) {
    unittest.expect(
      o.expectedAction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.siteKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userAgent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userIpAddress!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Event--;
}

core.List<core.String> buildUnnamed3611() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3611(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudRecaptchaenterpriseV1IOSKeySettings = 0;
api.GoogleCloudRecaptchaenterpriseV1IOSKeySettings
    buildGoogleCloudRecaptchaenterpriseV1IOSKeySettings() {
  var o = api.GoogleCloudRecaptchaenterpriseV1IOSKeySettings();
  buildCounterGoogleCloudRecaptchaenterpriseV1IOSKeySettings++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1IOSKeySettings < 3) {
    o.allowedBundleIds = buildUnnamed3611();
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1IOSKeySettings--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1IOSKeySettings(
    api.GoogleCloudRecaptchaenterpriseV1IOSKeySettings o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1IOSKeySettings++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1IOSKeySettings < 3) {
    checkUnnamed3611(o.allowedBundleIds!);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1IOSKeySettings--;
}

core.Map<core.String, core.String> buildUnnamed3612() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3612(core.Map<core.String, core.String> o) {
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

core.int buildCounterGoogleCloudRecaptchaenterpriseV1Key = 0;
api.GoogleCloudRecaptchaenterpriseV1Key
    buildGoogleCloudRecaptchaenterpriseV1Key() {
  var o = api.GoogleCloudRecaptchaenterpriseV1Key();
  buildCounterGoogleCloudRecaptchaenterpriseV1Key++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Key < 3) {
    o.androidSettings =
        buildGoogleCloudRecaptchaenterpriseV1AndroidKeySettings();
    o.createTime = 'foo';
    o.displayName = 'foo';
    o.iosSettings = buildGoogleCloudRecaptchaenterpriseV1IOSKeySettings();
    o.labels = buildUnnamed3612();
    o.name = 'foo';
    o.testingOptions = buildGoogleCloudRecaptchaenterpriseV1TestingOptions();
    o.webSettings = buildGoogleCloudRecaptchaenterpriseV1WebKeySettings();
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Key--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1Key(
    api.GoogleCloudRecaptchaenterpriseV1Key o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1Key++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Key < 3) {
    checkGoogleCloudRecaptchaenterpriseV1AndroidKeySettings(o.androidSettings!
        as api.GoogleCloudRecaptchaenterpriseV1AndroidKeySettings);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkGoogleCloudRecaptchaenterpriseV1IOSKeySettings(
        o.iosSettings! as api.GoogleCloudRecaptchaenterpriseV1IOSKeySettings);
    checkUnnamed3612(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudRecaptchaenterpriseV1TestingOptions(o.testingOptions!
        as api.GoogleCloudRecaptchaenterpriseV1TestingOptions);
    checkGoogleCloudRecaptchaenterpriseV1WebKeySettings(
        o.webSettings! as api.GoogleCloudRecaptchaenterpriseV1WebKeySettings);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Key--;
}

core.List<api.GoogleCloudRecaptchaenterpriseV1Key> buildUnnamed3613() {
  var o = <api.GoogleCloudRecaptchaenterpriseV1Key>[];
  o.add(buildGoogleCloudRecaptchaenterpriseV1Key());
  o.add(buildGoogleCloudRecaptchaenterpriseV1Key());
  return o;
}

void checkUnnamed3613(core.List<api.GoogleCloudRecaptchaenterpriseV1Key> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudRecaptchaenterpriseV1Key(
      o[0] as api.GoogleCloudRecaptchaenterpriseV1Key);
  checkGoogleCloudRecaptchaenterpriseV1Key(
      o[1] as api.GoogleCloudRecaptchaenterpriseV1Key);
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1ListKeysResponse = 0;
api.GoogleCloudRecaptchaenterpriseV1ListKeysResponse
    buildGoogleCloudRecaptchaenterpriseV1ListKeysResponse() {
  var o = api.GoogleCloudRecaptchaenterpriseV1ListKeysResponse();
  buildCounterGoogleCloudRecaptchaenterpriseV1ListKeysResponse++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ListKeysResponse < 3) {
    o.keys = buildUnnamed3613();
    o.nextPageToken = 'foo';
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ListKeysResponse--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1ListKeysResponse(
    api.GoogleCloudRecaptchaenterpriseV1ListKeysResponse o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1ListKeysResponse++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ListKeysResponse < 3) {
    checkUnnamed3613(o.keys!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ListKeysResponse--;
}

core.List<api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics>
    buildUnnamed3614() {
  var o = <api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics>[];
  o.add(buildGoogleCloudRecaptchaenterpriseV1ChallengeMetrics());
  o.add(buildGoogleCloudRecaptchaenterpriseV1ChallengeMetrics());
  return o;
}

void checkUnnamed3614(
    core.List<api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudRecaptchaenterpriseV1ChallengeMetrics(
      o[0] as api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics);
  checkGoogleCloudRecaptchaenterpriseV1ChallengeMetrics(
      o[1] as api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics);
}

core.List<api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics> buildUnnamed3615() {
  var o = <api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics>[];
  o.add(buildGoogleCloudRecaptchaenterpriseV1ScoreMetrics());
  o.add(buildGoogleCloudRecaptchaenterpriseV1ScoreMetrics());
  return o;
}

void checkUnnamed3615(
    core.List<api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudRecaptchaenterpriseV1ScoreMetrics(
      o[0] as api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics);
  checkGoogleCloudRecaptchaenterpriseV1ScoreMetrics(
      o[1] as api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics);
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1Metrics = 0;
api.GoogleCloudRecaptchaenterpriseV1Metrics
    buildGoogleCloudRecaptchaenterpriseV1Metrics() {
  var o = api.GoogleCloudRecaptchaenterpriseV1Metrics();
  buildCounterGoogleCloudRecaptchaenterpriseV1Metrics++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Metrics < 3) {
    o.challengeMetrics = buildUnnamed3614();
    o.scoreMetrics = buildUnnamed3615();
    o.startTime = 'foo';
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Metrics--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1Metrics(
    api.GoogleCloudRecaptchaenterpriseV1Metrics o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1Metrics++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1Metrics < 3) {
    checkUnnamed3614(o.challengeMetrics!);
    checkUnnamed3615(o.scoreMetrics!);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1Metrics--;
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest = 0;
api.GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest
    buildGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest() {
  var o = api.GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest();
  buildCounterGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest < 3) {}
  buildCounterGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest(
    api.GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest < 3) {}
  buildCounterGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest--;
}

core.List<core.String> buildUnnamed3616() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3616(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudRecaptchaenterpriseV1RiskAnalysis = 0;
api.GoogleCloudRecaptchaenterpriseV1RiskAnalysis
    buildGoogleCloudRecaptchaenterpriseV1RiskAnalysis() {
  var o = api.GoogleCloudRecaptchaenterpriseV1RiskAnalysis();
  buildCounterGoogleCloudRecaptchaenterpriseV1RiskAnalysis++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1RiskAnalysis < 3) {
    o.reasons = buildUnnamed3616();
    o.score = 42.0;
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1RiskAnalysis--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1RiskAnalysis(
    api.GoogleCloudRecaptchaenterpriseV1RiskAnalysis o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1RiskAnalysis++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1RiskAnalysis < 3) {
    checkUnnamed3616(o.reasons!);
    unittest.expect(
      o.score!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1RiskAnalysis--;
}

core.Map<core.String, core.String> buildUnnamed3617() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3617(core.Map<core.String, core.String> o) {
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

core.int buildCounterGoogleCloudRecaptchaenterpriseV1ScoreDistribution = 0;
api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution
    buildGoogleCloudRecaptchaenterpriseV1ScoreDistribution() {
  var o = api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution();
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreDistribution++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ScoreDistribution < 3) {
    o.scoreBuckets = buildUnnamed3617();
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreDistribution--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1ScoreDistribution(
    api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreDistribution++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ScoreDistribution < 3) {
    checkUnnamed3617(o.scoreBuckets!);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreDistribution--;
}

core.Map<core.String, api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution>
    buildUnnamed3618() {
  var o =
      <core.String, api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution>{};
  o['x'] = buildGoogleCloudRecaptchaenterpriseV1ScoreDistribution();
  o['y'] = buildGoogleCloudRecaptchaenterpriseV1ScoreDistribution();
  return o;
}

void checkUnnamed3618(
    core.Map<core.String, api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudRecaptchaenterpriseV1ScoreDistribution(
      o['x']! as api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution);
  checkGoogleCloudRecaptchaenterpriseV1ScoreDistribution(
      o['y']! as api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution);
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1ScoreMetrics = 0;
api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics
    buildGoogleCloudRecaptchaenterpriseV1ScoreMetrics() {
  var o = api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics();
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreMetrics++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ScoreMetrics < 3) {
    o.actionMetrics = buildUnnamed3618();
    o.overallMetrics = buildGoogleCloudRecaptchaenterpriseV1ScoreDistribution();
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreMetrics--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1ScoreMetrics(
    api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreMetrics++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1ScoreMetrics < 3) {
    checkUnnamed3618(o.actionMetrics!);
    checkGoogleCloudRecaptchaenterpriseV1ScoreDistribution(o.overallMetrics!
        as api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1ScoreMetrics--;
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1TestingOptions = 0;
api.GoogleCloudRecaptchaenterpriseV1TestingOptions
    buildGoogleCloudRecaptchaenterpriseV1TestingOptions() {
  var o = api.GoogleCloudRecaptchaenterpriseV1TestingOptions();
  buildCounterGoogleCloudRecaptchaenterpriseV1TestingOptions++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1TestingOptions < 3) {
    o.testingChallenge = 'foo';
    o.testingScore = 42.0;
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1TestingOptions--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1TestingOptions(
    api.GoogleCloudRecaptchaenterpriseV1TestingOptions o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1TestingOptions++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1TestingOptions < 3) {
    unittest.expect(
      o.testingChallenge!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.testingScore!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1TestingOptions--;
}

core.int buildCounterGoogleCloudRecaptchaenterpriseV1TokenProperties = 0;
api.GoogleCloudRecaptchaenterpriseV1TokenProperties
    buildGoogleCloudRecaptchaenterpriseV1TokenProperties() {
  var o = api.GoogleCloudRecaptchaenterpriseV1TokenProperties();
  buildCounterGoogleCloudRecaptchaenterpriseV1TokenProperties++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1TokenProperties < 3) {
    o.action = 'foo';
    o.createTime = 'foo';
    o.hostname = 'foo';
    o.invalidReason = 'foo';
    o.valid = true;
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1TokenProperties--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1TokenProperties(
    api.GoogleCloudRecaptchaenterpriseV1TokenProperties o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1TokenProperties++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1TokenProperties < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hostname!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invalidReason!,
      unittest.equals('foo'),
    );
    unittest.expect(o.valid!, unittest.isTrue);
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1TokenProperties--;
}

core.List<core.String> buildUnnamed3619() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3619(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudRecaptchaenterpriseV1WebKeySettings = 0;
api.GoogleCloudRecaptchaenterpriseV1WebKeySettings
    buildGoogleCloudRecaptchaenterpriseV1WebKeySettings() {
  var o = api.GoogleCloudRecaptchaenterpriseV1WebKeySettings();
  buildCounterGoogleCloudRecaptchaenterpriseV1WebKeySettings++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1WebKeySettings < 3) {
    o.allowAllDomains = true;
    o.allowAmpTraffic = true;
    o.allowedDomains = buildUnnamed3619();
    o.challengeSecurityPreference = 'foo';
    o.integrationType = 'foo';
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1WebKeySettings--;
  return o;
}

void checkGoogleCloudRecaptchaenterpriseV1WebKeySettings(
    api.GoogleCloudRecaptchaenterpriseV1WebKeySettings o) {
  buildCounterGoogleCloudRecaptchaenterpriseV1WebKeySettings++;
  if (buildCounterGoogleCloudRecaptchaenterpriseV1WebKeySettings < 3) {
    unittest.expect(o.allowAllDomains!, unittest.isTrue);
    unittest.expect(o.allowAmpTraffic!, unittest.isTrue);
    checkUnnamed3619(o.allowedDomains!);
    unittest.expect(
      o.challengeSecurityPreference!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.integrationType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudRecaptchaenterpriseV1WebKeySettings--;
}

core.int buildCounterGoogleProtobufEmpty = 0;
api.GoogleProtobufEmpty buildGoogleProtobufEmpty() {
  var o = api.GoogleProtobufEmpty();
  buildCounterGoogleProtobufEmpty++;
  if (buildCounterGoogleProtobufEmpty < 3) {}
  buildCounterGoogleProtobufEmpty--;
  return o;
}

void checkGoogleProtobufEmpty(api.GoogleProtobufEmpty o) {
  buildCounterGoogleProtobufEmpty++;
  if (buildCounterGoogleProtobufEmpty < 3) {}
  buildCounterGoogleProtobufEmpty--;
}

void main() {
  unittest.group(
      'obj-schema-GoogleCloudRecaptchaenterpriseV1AndroidKeySettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1AndroidKeySettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1AndroidKeySettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1AndroidKeySettings(
          od as api.GoogleCloudRecaptchaenterpriseV1AndroidKeySettings);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest(
          od as api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse(
          od as api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1Assessment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1Assessment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1Assessment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1Assessment(
          od as api.GoogleCloudRecaptchaenterpriseV1Assessment);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1ChallengeMetrics',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1ChallengeMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1ChallengeMetrics(
          od as api.GoogleCloudRecaptchaenterpriseV1ChallengeMetrics);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1Event', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1Event();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1Event.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1Event(
          od as api.GoogleCloudRecaptchaenterpriseV1Event);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1IOSKeySettings',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1IOSKeySettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1IOSKeySettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1IOSKeySettings(
          od as api.GoogleCloudRecaptchaenterpriseV1IOSKeySettings);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1Key', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1Key();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1Key.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1Key(
          od as api.GoogleCloudRecaptchaenterpriseV1Key);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1ListKeysResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1ListKeysResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1ListKeysResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1ListKeysResponse(
          od as api.GoogleCloudRecaptchaenterpriseV1ListKeysResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1Metrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1Metrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1Metrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1Metrics(
          od as api.GoogleCloudRecaptchaenterpriseV1Metrics);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest(
          od as api.GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1RiskAnalysis', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1RiskAnalysis();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1RiskAnalysis.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1RiskAnalysis(
          od as api.GoogleCloudRecaptchaenterpriseV1RiskAnalysis);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1ScoreDistribution',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1ScoreDistribution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1ScoreDistribution(
          od as api.GoogleCloudRecaptchaenterpriseV1ScoreDistribution);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1ScoreMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1ScoreMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1ScoreMetrics(
          od as api.GoogleCloudRecaptchaenterpriseV1ScoreMetrics);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1TestingOptions',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1TestingOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1TestingOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1TestingOptions(
          od as api.GoogleCloudRecaptchaenterpriseV1TestingOptions);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1TokenProperties',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1TokenProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1TokenProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1TokenProperties(
          od as api.GoogleCloudRecaptchaenterpriseV1TokenProperties);
    });
  });

  unittest.group('obj-schema-GoogleCloudRecaptchaenterpriseV1WebKeySettings',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRecaptchaenterpriseV1WebKeySettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRecaptchaenterpriseV1WebKeySettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRecaptchaenterpriseV1WebKeySettings(
          od as api.GoogleCloudRecaptchaenterpriseV1WebKeySettings);
    });
  });

  unittest.group('obj-schema-GoogleProtobufEmpty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleProtobufEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleProtobufEmpty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleProtobufEmpty(od as api.GoogleProtobufEmpty);
    });
  });

  unittest.group('resource-ProjectsAssessmentsResource', () {
    unittest.test('method--annotate', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.assessments;
      var arg_request =
          buildGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest
            .fromJson(json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest(obj
            as api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
            buildGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.annotate(arg_request, arg_name, $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse(response
          as api.GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.assessments;
      var arg_request = buildGoogleCloudRecaptchaenterpriseV1Assessment();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudRecaptchaenterpriseV1Assessment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudRecaptchaenterpriseV1Assessment(
            obj as api.GoogleCloudRecaptchaenterpriseV1Assessment);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
            .encode(buildGoogleCloudRecaptchaenterpriseV1Assessment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1Assessment(
          response as api.GoogleCloudRecaptchaenterpriseV1Assessment);
    });
  });

  unittest.group('resource-ProjectsKeysResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.keys;
      var arg_request = buildGoogleCloudRecaptchaenterpriseV1Key();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudRecaptchaenterpriseV1Key.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudRecaptchaenterpriseV1Key(
            obj as api.GoogleCloudRecaptchaenterpriseV1Key);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
            convert.json.encode(buildGoogleCloudRecaptchaenterpriseV1Key());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1Key(
          response as api.GoogleCloudRecaptchaenterpriseV1Key);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.keys;
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
        var resp = convert.json.encode(buildGoogleProtobufEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.keys;
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
        var resp =
            convert.json.encode(buildGoogleCloudRecaptchaenterpriseV1Key());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1Key(
          response as api.GoogleCloudRecaptchaenterpriseV1Key);
    });

    unittest.test('method--getMetrics', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.keys;
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
        var resp =
            convert.json.encode(buildGoogleCloudRecaptchaenterpriseV1Metrics());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getMetrics(arg_name, $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1Metrics(
          response as api.GoogleCloudRecaptchaenterpriseV1Metrics);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.keys;
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
        var resp = convert.json
            .encode(buildGoogleCloudRecaptchaenterpriseV1ListKeysResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1ListKeysResponse(
          response as api.GoogleCloudRecaptchaenterpriseV1ListKeysResponse);
    });

    unittest.test('method--migrate', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.keys;
      var arg_request =
          buildGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudRecaptchaenterpriseV1MigrateKeyRequest(
            obj as api.GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
            convert.json.encode(buildGoogleCloudRecaptchaenterpriseV1Key());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.migrate(arg_request, arg_name, $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1Key(
          response as api.GoogleCloudRecaptchaenterpriseV1Key);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.RecaptchaEnterpriseApi(mock).projects.keys;
      var arg_request = buildGoogleCloudRecaptchaenterpriseV1Key();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudRecaptchaenterpriseV1Key.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudRecaptchaenterpriseV1Key(
            obj as api.GoogleCloudRecaptchaenterpriseV1Key);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp =
            convert.json.encode(buildGoogleCloudRecaptchaenterpriseV1Key());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGoogleCloudRecaptchaenterpriseV1Key(
          response as api.GoogleCloudRecaptchaenterpriseV1Key);
    });
  });
}

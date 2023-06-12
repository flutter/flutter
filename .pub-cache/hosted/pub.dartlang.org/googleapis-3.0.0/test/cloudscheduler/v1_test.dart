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

import 'package:googleapis/cloudscheduler/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.Map<core.String, core.String> buildUnnamed3520() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3520(core.Map<core.String, core.String> o) {
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

core.int buildCounterAppEngineHttpTarget = 0;
api.AppEngineHttpTarget buildAppEngineHttpTarget() {
  var o = api.AppEngineHttpTarget();
  buildCounterAppEngineHttpTarget++;
  if (buildCounterAppEngineHttpTarget < 3) {
    o.appEngineRouting = buildAppEngineRouting();
    o.body = 'foo';
    o.headers = buildUnnamed3520();
    o.httpMethod = 'foo';
    o.relativeUri = 'foo';
  }
  buildCounterAppEngineHttpTarget--;
  return o;
}

void checkAppEngineHttpTarget(api.AppEngineHttpTarget o) {
  buildCounterAppEngineHttpTarget++;
  if (buildCounterAppEngineHttpTarget < 3) {
    checkAppEngineRouting(o.appEngineRouting! as api.AppEngineRouting);
    unittest.expect(
      o.body!,
      unittest.equals('foo'),
    );
    checkUnnamed3520(o.headers!);
    unittest.expect(
      o.httpMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.relativeUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppEngineHttpTarget--;
}

core.int buildCounterAppEngineRouting = 0;
api.AppEngineRouting buildAppEngineRouting() {
  var o = api.AppEngineRouting();
  buildCounterAppEngineRouting++;
  if (buildCounterAppEngineRouting < 3) {
    o.host = 'foo';
    o.instance = 'foo';
    o.service = 'foo';
    o.version = 'foo';
  }
  buildCounterAppEngineRouting--;
  return o;
}

void checkAppEngineRouting(api.AppEngineRouting o) {
  buildCounterAppEngineRouting++;
  if (buildCounterAppEngineRouting < 3) {
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instance!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppEngineRouting--;
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

core.Map<core.String, core.String> buildUnnamed3521() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3521(core.Map<core.String, core.String> o) {
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

core.int buildCounterHttpTarget = 0;
api.HttpTarget buildHttpTarget() {
  var o = api.HttpTarget();
  buildCounterHttpTarget++;
  if (buildCounterHttpTarget < 3) {
    o.body = 'foo';
    o.headers = buildUnnamed3521();
    o.httpMethod = 'foo';
    o.oauthToken = buildOAuthToken();
    o.oidcToken = buildOidcToken();
    o.uri = 'foo';
  }
  buildCounterHttpTarget--;
  return o;
}

void checkHttpTarget(api.HttpTarget o) {
  buildCounterHttpTarget++;
  if (buildCounterHttpTarget < 3) {
    unittest.expect(
      o.body!,
      unittest.equals('foo'),
    );
    checkUnnamed3521(o.headers!);
    unittest.expect(
      o.httpMethod!,
      unittest.equals('foo'),
    );
    checkOAuthToken(o.oauthToken! as api.OAuthToken);
    checkOidcToken(o.oidcToken! as api.OidcToken);
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterHttpTarget--;
}

core.int buildCounterJob = 0;
api.Job buildJob() {
  var o = api.Job();
  buildCounterJob++;
  if (buildCounterJob < 3) {
    o.appEngineHttpTarget = buildAppEngineHttpTarget();
    o.attemptDeadline = 'foo';
    o.description = 'foo';
    o.httpTarget = buildHttpTarget();
    o.lastAttemptTime = 'foo';
    o.name = 'foo';
    o.pubsubTarget = buildPubsubTarget();
    o.retryConfig = buildRetryConfig();
    o.schedule = 'foo';
    o.scheduleTime = 'foo';
    o.state = 'foo';
    o.status = buildStatus();
    o.timeZone = 'foo';
    o.userUpdateTime = 'foo';
  }
  buildCounterJob--;
  return o;
}

void checkJob(api.Job o) {
  buildCounterJob++;
  if (buildCounterJob < 3) {
    checkAppEngineHttpTarget(o.appEngineHttpTarget! as api.AppEngineHttpTarget);
    unittest.expect(
      o.attemptDeadline!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkHttpTarget(o.httpTarget! as api.HttpTarget);
    unittest.expect(
      o.lastAttemptTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkPubsubTarget(o.pubsubTarget! as api.PubsubTarget);
    checkRetryConfig(o.retryConfig! as api.RetryConfig);
    unittest.expect(
      o.schedule!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheduleTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userUpdateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterJob--;
}

core.List<api.Job> buildUnnamed3522() {
  var o = <api.Job>[];
  o.add(buildJob());
  o.add(buildJob());
  return o;
}

void checkUnnamed3522(core.List<api.Job> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJob(o[0] as api.Job);
  checkJob(o[1] as api.Job);
}

core.int buildCounterListJobsResponse = 0;
api.ListJobsResponse buildListJobsResponse() {
  var o = api.ListJobsResponse();
  buildCounterListJobsResponse++;
  if (buildCounterListJobsResponse < 3) {
    o.jobs = buildUnnamed3522();
    o.nextPageToken = 'foo';
  }
  buildCounterListJobsResponse--;
  return o;
}

void checkListJobsResponse(api.ListJobsResponse o) {
  buildCounterListJobsResponse++;
  if (buildCounterListJobsResponse < 3) {
    checkUnnamed3522(o.jobs!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListJobsResponse--;
}

core.List<api.Location> buildUnnamed3523() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed3523(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed3523();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed3523(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.Map<core.String, core.String> buildUnnamed3524() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3524(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed3525() {
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

void checkUnnamed3525(core.Map<core.String, core.Object> o) {
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
    o.labels = buildUnnamed3524();
    o.locationId = 'foo';
    o.metadata = buildUnnamed3525();
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
    checkUnnamed3524(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed3525(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.int buildCounterOAuthToken = 0;
api.OAuthToken buildOAuthToken() {
  var o = api.OAuthToken();
  buildCounterOAuthToken++;
  if (buildCounterOAuthToken < 3) {
    o.scope = 'foo';
    o.serviceAccountEmail = 'foo';
  }
  buildCounterOAuthToken--;
  return o;
}

void checkOAuthToken(api.OAuthToken o) {
  buildCounterOAuthToken++;
  if (buildCounterOAuthToken < 3) {
    unittest.expect(
      o.scope!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccountEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterOAuthToken--;
}

core.int buildCounterOidcToken = 0;
api.OidcToken buildOidcToken() {
  var o = api.OidcToken();
  buildCounterOidcToken++;
  if (buildCounterOidcToken < 3) {
    o.audience = 'foo';
    o.serviceAccountEmail = 'foo';
  }
  buildCounterOidcToken--;
  return o;
}

void checkOidcToken(api.OidcToken o) {
  buildCounterOidcToken++;
  if (buildCounterOidcToken < 3) {
    unittest.expect(
      o.audience!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccountEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterOidcToken--;
}

core.int buildCounterPauseJobRequest = 0;
api.PauseJobRequest buildPauseJobRequest() {
  var o = api.PauseJobRequest();
  buildCounterPauseJobRequest++;
  if (buildCounterPauseJobRequest < 3) {}
  buildCounterPauseJobRequest--;
  return o;
}

void checkPauseJobRequest(api.PauseJobRequest o) {
  buildCounterPauseJobRequest++;
  if (buildCounterPauseJobRequest < 3) {}
  buildCounterPauseJobRequest--;
}

core.Map<core.String, core.String> buildUnnamed3526() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3526(core.Map<core.String, core.String> o) {
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

core.int buildCounterPubsubMessage = 0;
api.PubsubMessage buildPubsubMessage() {
  var o = api.PubsubMessage();
  buildCounterPubsubMessage++;
  if (buildCounterPubsubMessage < 3) {
    o.attributes = buildUnnamed3526();
    o.data = 'foo';
    o.messageId = 'foo';
    o.orderingKey = 'foo';
    o.publishTime = 'foo';
  }
  buildCounterPubsubMessage--;
  return o;
}

void checkPubsubMessage(api.PubsubMessage o) {
  buildCounterPubsubMessage++;
  if (buildCounterPubsubMessage < 3) {
    checkUnnamed3526(o.attributes!);
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.messageId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderingKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publishTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPubsubMessage--;
}

core.Map<core.String, core.String> buildUnnamed3527() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3527(core.Map<core.String, core.String> o) {
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

core.int buildCounterPubsubTarget = 0;
api.PubsubTarget buildPubsubTarget() {
  var o = api.PubsubTarget();
  buildCounterPubsubTarget++;
  if (buildCounterPubsubTarget < 3) {
    o.attributes = buildUnnamed3527();
    o.data = 'foo';
    o.topicName = 'foo';
  }
  buildCounterPubsubTarget--;
  return o;
}

void checkPubsubTarget(api.PubsubTarget o) {
  buildCounterPubsubTarget++;
  if (buildCounterPubsubTarget < 3) {
    checkUnnamed3527(o.attributes!);
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.topicName!,
      unittest.equals('foo'),
    );
  }
  buildCounterPubsubTarget--;
}

core.int buildCounterResumeJobRequest = 0;
api.ResumeJobRequest buildResumeJobRequest() {
  var o = api.ResumeJobRequest();
  buildCounterResumeJobRequest++;
  if (buildCounterResumeJobRequest < 3) {}
  buildCounterResumeJobRequest--;
  return o;
}

void checkResumeJobRequest(api.ResumeJobRequest o) {
  buildCounterResumeJobRequest++;
  if (buildCounterResumeJobRequest < 3) {}
  buildCounterResumeJobRequest--;
}

core.int buildCounterRetryConfig = 0;
api.RetryConfig buildRetryConfig() {
  var o = api.RetryConfig();
  buildCounterRetryConfig++;
  if (buildCounterRetryConfig < 3) {
    o.maxBackoffDuration = 'foo';
    o.maxDoublings = 42;
    o.maxRetryDuration = 'foo';
    o.minBackoffDuration = 'foo';
    o.retryCount = 42;
  }
  buildCounterRetryConfig--;
  return o;
}

void checkRetryConfig(api.RetryConfig o) {
  buildCounterRetryConfig++;
  if (buildCounterRetryConfig < 3) {
    unittest.expect(
      o.maxBackoffDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxDoublings!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxRetryDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minBackoffDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.retryCount!,
      unittest.equals(42),
    );
  }
  buildCounterRetryConfig--;
}

core.int buildCounterRunJobRequest = 0;
api.RunJobRequest buildRunJobRequest() {
  var o = api.RunJobRequest();
  buildCounterRunJobRequest++;
  if (buildCounterRunJobRequest < 3) {}
  buildCounterRunJobRequest--;
  return o;
}

void checkRunJobRequest(api.RunJobRequest o) {
  buildCounterRunJobRequest++;
  if (buildCounterRunJobRequest < 3) {}
  buildCounterRunJobRequest--;
}

core.Map<core.String, core.Object> buildUnnamed3528() {
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

void checkUnnamed3528(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed3529() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed3528());
  o.add(buildUnnamed3528());
  return o;
}

void checkUnnamed3529(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed3528(o[0]);
  checkUnnamed3528(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed3529();
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
    checkUnnamed3529(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

void main() {
  unittest.group('obj-schema-AppEngineHttpTarget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppEngineHttpTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppEngineHttpTarget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppEngineHttpTarget(od as api.AppEngineHttpTarget);
    });
  });

  unittest.group('obj-schema-AppEngineRouting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppEngineRouting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppEngineRouting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppEngineRouting(od as api.AppEngineRouting);
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

  unittest.group('obj-schema-HttpTarget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHttpTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.HttpTarget.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHttpTarget(od as api.HttpTarget);
    });
  });

  unittest.group('obj-schema-Job', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Job.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJob(od as api.Job);
    });
  });

  unittest.group('obj-schema-ListJobsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListJobsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListJobsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListJobsResponse(od as api.ListJobsResponse);
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

  unittest.group('obj-schema-OAuthToken', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOAuthToken();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OAuthToken.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOAuthToken(od as api.OAuthToken);
    });
  });

  unittest.group('obj-schema-OidcToken', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOidcToken();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OidcToken.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOidcToken(od as api.OidcToken);
    });
  });

  unittest.group('obj-schema-PauseJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPauseJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PauseJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPauseJobRequest(od as api.PauseJobRequest);
    });
  });

  unittest.group('obj-schema-PubsubMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPubsubMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PubsubMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPubsubMessage(od as api.PubsubMessage);
    });
  });

  unittest.group('obj-schema-PubsubTarget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPubsubTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PubsubTarget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPubsubTarget(od as api.PubsubTarget);
    });
  });

  unittest.group('obj-schema-ResumeJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResumeJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResumeJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResumeJobRequest(od as api.ResumeJobRequest);
    });
  });

  unittest.group('obj-schema-RetryConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRetryConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RetryConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRetryConfig(od as api.RetryConfig);
    });
  });

  unittest.group('obj-schema-RunJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRunJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RunJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRunJobRequest(od as api.RunJobRequest);
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

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations;
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
      var res = api.CloudSchedulerApi(mock).projects.locations;
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

  unittest.group('resource-ProjectsLocationsJobsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
      var arg_request = buildJob();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Job.fromJson(json as core.Map<core.String, core.dynamic>);
        checkJob(obj as api.Job);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
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
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
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
        var resp = convert.json.encode(buildListJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListJobsResponse(response as api.ListJobsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
      var arg_request = buildJob();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Job.fromJson(json as core.Map<core.String, core.dynamic>);
        checkJob(obj as api.Job);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--pause', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
      var arg_request = buildPauseJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PauseJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPauseJobRequest(obj as api.PauseJobRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.pause(arg_request, arg_name, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--resume', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
      var arg_request = buildResumeJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResumeJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResumeJobRequest(obj as api.ResumeJobRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.resume(arg_request, arg_name, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--run', () async {
      var mock = HttpServerMock();
      var res = api.CloudSchedulerApi(mock).projects.locations.jobs;
      var arg_request = buildRunJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RunJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRunJobRequest(obj as api.RunJobRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.run(arg_request, arg_name, $fields: arg_$fields);
      checkJob(response as api.Job);
    });
  });
}

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

import 'package:googleapis/verifiedaccess/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterChallenge = 0;
api.Challenge buildChallenge() {
  var o = api.Challenge();
  buildCounterChallenge++;
  if (buildCounterChallenge < 3) {
    o.alternativeChallenge = buildSignedData();
    o.challenge = buildSignedData();
  }
  buildCounterChallenge--;
  return o;
}

void checkChallenge(api.Challenge o) {
  buildCounterChallenge++;
  if (buildCounterChallenge < 3) {
    checkSignedData(o.alternativeChallenge! as api.SignedData);
    checkSignedData(o.challenge! as api.SignedData);
  }
  buildCounterChallenge--;
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

core.int buildCounterSignedData = 0;
api.SignedData buildSignedData() {
  var o = api.SignedData();
  buildCounterSignedData++;
  if (buildCounterSignedData < 3) {
    o.data = 'foo';
    o.signature = 'foo';
  }
  buildCounterSignedData--;
  return o;
}

void checkSignedData(api.SignedData o) {
  buildCounterSignedData++;
  if (buildCounterSignedData < 3) {
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signature!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignedData--;
}

core.int buildCounterVerifyChallengeResponseRequest = 0;
api.VerifyChallengeResponseRequest buildVerifyChallengeResponseRequest() {
  var o = api.VerifyChallengeResponseRequest();
  buildCounterVerifyChallengeResponseRequest++;
  if (buildCounterVerifyChallengeResponseRequest < 3) {
    o.challengeResponse = buildSignedData();
    o.expectedIdentity = 'foo';
  }
  buildCounterVerifyChallengeResponseRequest--;
  return o;
}

void checkVerifyChallengeResponseRequest(api.VerifyChallengeResponseRequest o) {
  buildCounterVerifyChallengeResponseRequest++;
  if (buildCounterVerifyChallengeResponseRequest < 3) {
    checkSignedData(o.challengeResponse! as api.SignedData);
    unittest.expect(
      o.expectedIdentity!,
      unittest.equals('foo'),
    );
  }
  buildCounterVerifyChallengeResponseRequest--;
}

core.int buildCounterVerifyChallengeResponseResult = 0;
api.VerifyChallengeResponseResult buildVerifyChallengeResponseResult() {
  var o = api.VerifyChallengeResponseResult();
  buildCounterVerifyChallengeResponseResult++;
  if (buildCounterVerifyChallengeResponseResult < 3) {
    o.deviceEnrollmentId = 'foo';
    o.devicePermanentId = 'foo';
    o.signedPublicKeyAndChallenge = 'foo';
    o.verificationOutput = 'foo';
  }
  buildCounterVerifyChallengeResponseResult--;
  return o;
}

void checkVerifyChallengeResponseResult(api.VerifyChallengeResponseResult o) {
  buildCounterVerifyChallengeResponseResult++;
  if (buildCounterVerifyChallengeResponseResult < 3) {
    unittest.expect(
      o.deviceEnrollmentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.devicePermanentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signedPublicKeyAndChallenge!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationOutput!,
      unittest.equals('foo'),
    );
  }
  buildCounterVerifyChallengeResponseResult--;
}

void main() {
  unittest.group('obj-schema-Challenge', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChallenge();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Challenge.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChallenge(od as api.Challenge);
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

  unittest.group('obj-schema-SignedData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSignedData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SignedData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSignedData(od as api.SignedData);
    });
  });

  unittest.group('obj-schema-VerifyChallengeResponseRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerifyChallengeResponseRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerifyChallengeResponseRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerifyChallengeResponseRequest(
          od as api.VerifyChallengeResponseRequest);
    });
  });

  unittest.group('obj-schema-VerifyChallengeResponseResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerifyChallengeResponseResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerifyChallengeResponseResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerifyChallengeResponseResult(
          od as api.VerifyChallengeResponseResult);
    });
  });

  unittest.group('resource-ChallengeResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.VerifiedaccessApi(mock).challenge;
      var arg_request = buildEmpty();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Empty.fromJson(json as core.Map<core.String, core.dynamic>);
        checkEmpty(obj as api.Empty);

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
          unittest.equals("v1/challenge"),
        );
        pathOffset += 12;

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
        var resp = convert.json.encode(buildChallenge());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkChallenge(response as api.Challenge);
    });

    unittest.test('method--verify', () async {
      var mock = HttpServerMock();
      var res = api.VerifiedaccessApi(mock).challenge;
      var arg_request = buildVerifyChallengeResponseRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.VerifyChallengeResponseRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkVerifyChallengeResponseRequest(
            obj as api.VerifyChallengeResponseRequest);

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
          unittest.equals("v1/challenge:verify"),
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
        var resp = convert.json.encode(buildVerifyChallengeResponseResult());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.verify(arg_request, $fields: arg_$fields);
      checkVerifyChallengeResponseResult(
          response as api.VerifyChallengeResponseResult);
    });
  });
}

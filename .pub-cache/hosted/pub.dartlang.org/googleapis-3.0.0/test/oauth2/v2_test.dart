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

import 'package:googleapis/oauth2/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterTokeninfo = 0;
api.Tokeninfo buildTokeninfo() {
  var o = api.Tokeninfo();
  buildCounterTokeninfo++;
  if (buildCounterTokeninfo < 3) {
    o.audience = 'foo';
    o.email = 'foo';
    o.expiresIn = 42;
    o.issuedTo = 'foo';
    o.scope = 'foo';
    o.userId = 'foo';
    o.verifiedEmail = true;
  }
  buildCounterTokeninfo--;
  return o;
}

void checkTokeninfo(api.Tokeninfo o) {
  buildCounterTokeninfo++;
  if (buildCounterTokeninfo < 3) {
    unittest.expect(
      o.audience!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiresIn!,
      unittest.equals(42),
    );
    unittest.expect(
      o.issuedTo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scope!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.verifiedEmail!, unittest.isTrue);
  }
  buildCounterTokeninfo--;
}

core.int buildCounterUserinfo = 0;
api.Userinfo buildUserinfo() {
  var o = api.Userinfo();
  buildCounterUserinfo++;
  if (buildCounterUserinfo < 3) {
    o.email = 'foo';
    o.familyName = 'foo';
    o.gender = 'foo';
    o.givenName = 'foo';
    o.hd = 'foo';
    o.id = 'foo';
    o.link = 'foo';
    o.locale = 'foo';
    o.name = 'foo';
    o.picture = 'foo';
    o.verifiedEmail = true;
  }
  buildCounterUserinfo--;
  return o;
}

void checkUserinfo(api.Userinfo o) {
  buildCounterUserinfo++;
  if (buildCounterUserinfo < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.familyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gender!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.givenName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hd!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.link!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.picture!,
      unittest.equals('foo'),
    );
    unittest.expect(o.verifiedEmail!, unittest.isTrue);
  }
  buildCounterUserinfo--;
}

void main() {
  unittest.group('obj-schema-Tokeninfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTokeninfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Tokeninfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTokeninfo(od as api.Tokeninfo);
    });
  });

  unittest.group('obj-schema-Userinfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserinfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Userinfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserinfo(od as api.Userinfo);
    });
  });

  unittest.group('resource-Oauth2Api', () {
    unittest.test('method--tokeninfo', () async {
      var mock = HttpServerMock();
      var res = api.Oauth2Api(mock);
      var arg_accessToken = 'foo';
      var arg_idToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("oauth2/v2/tokeninfo"),
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
          queryMap["access_token"]!.first,
          unittest.equals(arg_accessToken),
        );
        unittest.expect(
          queryMap["id_token"]!.first,
          unittest.equals(arg_idToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTokeninfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.tokeninfo(
          accessToken: arg_accessToken,
          idToken: arg_idToken,
          $fields: arg_$fields);
      checkTokeninfo(response as api.Tokeninfo);
    });
  });

  unittest.group('resource-UserinfoResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.Oauth2Api(mock).userinfo;
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
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("oauth2/v2/userinfo"),
        );
        pathOffset += 18;

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
        var resp = convert.json.encode(buildUserinfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get($fields: arg_$fields);
      checkUserinfo(response as api.Userinfo);
    });
  });

  unittest.group('resource-UserinfoV2MeResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.Oauth2Api(mock).userinfo.v2.me;
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("userinfo/v2/me"),
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
        var resp = convert.json.encode(buildUserinfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get($fields: arg_$fields);
      checkUserinfo(response as api.Userinfo);
    });
  });
}

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

import 'package:googleapis/playcustomapp/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterCustomApp = 0;
api.CustomApp buildCustomApp() {
  var o = api.CustomApp();
  buildCounterCustomApp++;
  if (buildCounterCustomApp < 3) {
    o.languageCode = 'foo';
    o.packageName = 'foo';
    o.title = 'foo';
  }
  buildCounterCustomApp--;
  return o;
}

void checkCustomApp(api.CustomApp o) {
  buildCounterCustomApp++;
  if (buildCounterCustomApp < 3) {
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomApp--;
}

void main() {
  unittest.group('obj-schema-CustomApp', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomApp();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CustomApp.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCustomApp(od as api.CustomApp);
    });
  });

  unittest.group('resource-AccountsCustomAppsResource', () {
    unittest.test('method--create', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.PlaycustomappApi(mock).accounts.customApps;
      var arg_request = buildCustomApp();
      var arg_account = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.CustomApp.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCustomApp(obj as api.CustomApp);

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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("playcustomapp/v1/accounts/"),
        );
        pathOffset += 26;
        index = path.indexOf('/customApps', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_account'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/customApps"),
        );
        pathOffset += 11;

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
        var resp = convert.json.encode(buildCustomApp());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_account, $fields: arg_$fields);
      checkCustomApp(response as api.CustomApp);
    });
  });
}

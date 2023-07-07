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

import 'package:googleapis/baremetalsolution/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterResetInstanceRequest = 0;
api.ResetInstanceRequest buildResetInstanceRequest() {
  var o = api.ResetInstanceRequest();
  buildCounterResetInstanceRequest++;
  if (buildCounterResetInstanceRequest < 3) {}
  buildCounterResetInstanceRequest--;
  return o;
}

void checkResetInstanceRequest(api.ResetInstanceRequest o) {
  buildCounterResetInstanceRequest++;
  if (buildCounterResetInstanceRequest < 3) {}
  buildCounterResetInstanceRequest--;
}

core.int buildCounterResetInstanceResponse = 0;
api.ResetInstanceResponse buildResetInstanceResponse() {
  var o = api.ResetInstanceResponse();
  buildCounterResetInstanceResponse++;
  if (buildCounterResetInstanceResponse < 3) {}
  buildCounterResetInstanceResponse--;
  return o;
}

void checkResetInstanceResponse(api.ResetInstanceResponse o) {
  buildCounterResetInstanceResponse++;
  if (buildCounterResetInstanceResponse < 3) {}
  buildCounterResetInstanceResponse--;
}

void main() {
  unittest.group('obj-schema-ResetInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResetInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResetInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResetInstanceRequest(od as api.ResetInstanceRequest);
    });
  });

  unittest.group('obj-schema-ResetInstanceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResetInstanceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResetInstanceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResetInstanceResponse(od as api.ResetInstanceResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsInstancesResource', () {
    unittest.test('method--resetInstance', () async {
      var mock = HttpServerMock();
      var res = api.BaremetalsolutionApi(mock).projects.locations.instances;
      var arg_request = buildResetInstanceRequest();
      var arg_instance = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResetInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResetInstanceRequest(obj as api.ResetInstanceRequest);

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
        var resp = convert.json.encode(buildResetInstanceResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.resetInstance(arg_request, arg_instance,
          $fields: arg_$fields);
      checkResetInstanceResponse(response as api.ResetInstanceResponse);
    });
  });
}

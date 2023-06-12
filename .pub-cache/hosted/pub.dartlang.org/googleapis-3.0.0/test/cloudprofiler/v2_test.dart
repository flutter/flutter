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

import 'package:googleapis/cloudprofiler/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed2853() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2853(core.List<core.String> o) {
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

core.int buildCounterCreateProfileRequest = 0;
api.CreateProfileRequest buildCreateProfileRequest() {
  var o = api.CreateProfileRequest();
  buildCounterCreateProfileRequest++;
  if (buildCounterCreateProfileRequest < 3) {
    o.deployment = buildDeployment();
    o.profileType = buildUnnamed2853();
  }
  buildCounterCreateProfileRequest--;
  return o;
}

void checkCreateProfileRequest(api.CreateProfileRequest o) {
  buildCounterCreateProfileRequest++;
  if (buildCounterCreateProfileRequest < 3) {
    checkDeployment(o.deployment! as api.Deployment);
    checkUnnamed2853(o.profileType!);
  }
  buildCounterCreateProfileRequest--;
}

core.Map<core.String, core.String> buildUnnamed2854() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2854(core.Map<core.String, core.String> o) {
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

core.int buildCounterDeployment = 0;
api.Deployment buildDeployment() {
  var o = api.Deployment();
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    o.labels = buildUnnamed2854();
    o.projectId = 'foo';
    o.target = 'foo';
  }
  buildCounterDeployment--;
  return o;
}

void checkDeployment(api.Deployment o) {
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    checkUnnamed2854(o.labels!);
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeployment--;
}

core.Map<core.String, core.String> buildUnnamed2855() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2855(core.Map<core.String, core.String> o) {
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

core.int buildCounterProfile = 0;
api.Profile buildProfile() {
  var o = api.Profile();
  buildCounterProfile++;
  if (buildCounterProfile < 3) {
    o.deployment = buildDeployment();
    o.duration = 'foo';
    o.labels = buildUnnamed2855();
    o.name = 'foo';
    o.profileBytes = 'foo';
    o.profileType = 'foo';
  }
  buildCounterProfile--;
  return o;
}

void checkProfile(api.Profile o) {
  buildCounterProfile++;
  if (buildCounterProfile < 3) {
    checkDeployment(o.deployment! as api.Deployment);
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    checkUnnamed2855(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileType!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfile--;
}

void main() {
  unittest.group('obj-schema-CreateProfileRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateProfileRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateProfileRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateProfileRequest(od as api.CreateProfileRequest);
    });
  });

  unittest.group('obj-schema-Deployment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Deployment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDeployment(od as api.Deployment);
    });
  });

  unittest.group('obj-schema-Profile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Profile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProfile(od as api.Profile);
    });
  });

  unittest.group('resource-ProjectsProfilesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudProfilerApi(mock).projects.profiles;
      var arg_request = buildCreateProfileRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateProfileRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateProfileRequest(obj as api.CreateProfileRequest);

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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });

    unittest.test('method--createOffline', () async {
      var mock = HttpServerMock();
      var res = api.CloudProfilerApi(mock).projects.profiles;
      var arg_request = buildProfile();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Profile.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProfile(obj as api.Profile);

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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.createOffline(arg_request, arg_parent,
          $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudProfilerApi(mock).projects.profiles;
      var arg_request = buildProfile();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Profile.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProfile(obj as api.Profile);

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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });
  });
}

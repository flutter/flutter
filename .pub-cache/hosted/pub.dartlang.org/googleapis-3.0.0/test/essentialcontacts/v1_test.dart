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

import 'package:googleapis/essentialcontacts/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.GoogleCloudEssentialcontactsV1Contact> buildUnnamed639() {
  var o = <api.GoogleCloudEssentialcontactsV1Contact>[];
  o.add(buildGoogleCloudEssentialcontactsV1Contact());
  o.add(buildGoogleCloudEssentialcontactsV1Contact());
  return o;
}

void checkUnnamed639(core.List<api.GoogleCloudEssentialcontactsV1Contact> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudEssentialcontactsV1Contact(
      o[0] as api.GoogleCloudEssentialcontactsV1Contact);
  checkGoogleCloudEssentialcontactsV1Contact(
      o[1] as api.GoogleCloudEssentialcontactsV1Contact);
}

core.int buildCounterGoogleCloudEssentialcontactsV1ComputeContactsResponse = 0;
api.GoogleCloudEssentialcontactsV1ComputeContactsResponse
    buildGoogleCloudEssentialcontactsV1ComputeContactsResponse() {
  var o = api.GoogleCloudEssentialcontactsV1ComputeContactsResponse();
  buildCounterGoogleCloudEssentialcontactsV1ComputeContactsResponse++;
  if (buildCounterGoogleCloudEssentialcontactsV1ComputeContactsResponse < 3) {
    o.contacts = buildUnnamed639();
    o.nextPageToken = 'foo';
  }
  buildCounterGoogleCloudEssentialcontactsV1ComputeContactsResponse--;
  return o;
}

void checkGoogleCloudEssentialcontactsV1ComputeContactsResponse(
    api.GoogleCloudEssentialcontactsV1ComputeContactsResponse o) {
  buildCounterGoogleCloudEssentialcontactsV1ComputeContactsResponse++;
  if (buildCounterGoogleCloudEssentialcontactsV1ComputeContactsResponse < 3) {
    checkUnnamed639(o.contacts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudEssentialcontactsV1ComputeContactsResponse--;
}

core.List<core.String> buildUnnamed640() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed640(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudEssentialcontactsV1Contact = 0;
api.GoogleCloudEssentialcontactsV1Contact
    buildGoogleCloudEssentialcontactsV1Contact() {
  var o = api.GoogleCloudEssentialcontactsV1Contact();
  buildCounterGoogleCloudEssentialcontactsV1Contact++;
  if (buildCounterGoogleCloudEssentialcontactsV1Contact < 3) {
    o.email = 'foo';
    o.languageTag = 'foo';
    o.name = 'foo';
    o.notificationCategorySubscriptions = buildUnnamed640();
    o.validateTime = 'foo';
    o.validationState = 'foo';
  }
  buildCounterGoogleCloudEssentialcontactsV1Contact--;
  return o;
}

void checkGoogleCloudEssentialcontactsV1Contact(
    api.GoogleCloudEssentialcontactsV1Contact o) {
  buildCounterGoogleCloudEssentialcontactsV1Contact++;
  if (buildCounterGoogleCloudEssentialcontactsV1Contact < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed640(o.notificationCategorySubscriptions!);
    unittest.expect(
      o.validateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.validationState!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudEssentialcontactsV1Contact--;
}

core.List<api.GoogleCloudEssentialcontactsV1Contact> buildUnnamed641() {
  var o = <api.GoogleCloudEssentialcontactsV1Contact>[];
  o.add(buildGoogleCloudEssentialcontactsV1Contact());
  o.add(buildGoogleCloudEssentialcontactsV1Contact());
  return o;
}

void checkUnnamed641(core.List<api.GoogleCloudEssentialcontactsV1Contact> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudEssentialcontactsV1Contact(
      o[0] as api.GoogleCloudEssentialcontactsV1Contact);
  checkGoogleCloudEssentialcontactsV1Contact(
      o[1] as api.GoogleCloudEssentialcontactsV1Contact);
}

core.int buildCounterGoogleCloudEssentialcontactsV1ListContactsResponse = 0;
api.GoogleCloudEssentialcontactsV1ListContactsResponse
    buildGoogleCloudEssentialcontactsV1ListContactsResponse() {
  var o = api.GoogleCloudEssentialcontactsV1ListContactsResponse();
  buildCounterGoogleCloudEssentialcontactsV1ListContactsResponse++;
  if (buildCounterGoogleCloudEssentialcontactsV1ListContactsResponse < 3) {
    o.contacts = buildUnnamed641();
    o.nextPageToken = 'foo';
  }
  buildCounterGoogleCloudEssentialcontactsV1ListContactsResponse--;
  return o;
}

void checkGoogleCloudEssentialcontactsV1ListContactsResponse(
    api.GoogleCloudEssentialcontactsV1ListContactsResponse o) {
  buildCounterGoogleCloudEssentialcontactsV1ListContactsResponse++;
  if (buildCounterGoogleCloudEssentialcontactsV1ListContactsResponse < 3) {
    checkUnnamed641(o.contacts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudEssentialcontactsV1ListContactsResponse--;
}

core.List<core.String> buildUnnamed642() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed642(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudEssentialcontactsV1SendTestMessageRequest = 0;
api.GoogleCloudEssentialcontactsV1SendTestMessageRequest
    buildGoogleCloudEssentialcontactsV1SendTestMessageRequest() {
  var o = api.GoogleCloudEssentialcontactsV1SendTestMessageRequest();
  buildCounterGoogleCloudEssentialcontactsV1SendTestMessageRequest++;
  if (buildCounterGoogleCloudEssentialcontactsV1SendTestMessageRequest < 3) {
    o.contacts = buildUnnamed642();
    o.notificationCategory = 'foo';
  }
  buildCounterGoogleCloudEssentialcontactsV1SendTestMessageRequest--;
  return o;
}

void checkGoogleCloudEssentialcontactsV1SendTestMessageRequest(
    api.GoogleCloudEssentialcontactsV1SendTestMessageRequest o) {
  buildCounterGoogleCloudEssentialcontactsV1SendTestMessageRequest++;
  if (buildCounterGoogleCloudEssentialcontactsV1SendTestMessageRequest < 3) {
    checkUnnamed642(o.contacts!);
    unittest.expect(
      o.notificationCategory!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudEssentialcontactsV1SendTestMessageRequest--;
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

core.List<core.String> buildUnnamed643() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed643(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed644() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed644(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed645() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed645(core.List<core.String> o) {
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

void main() {
  unittest.group(
      'obj-schema-GoogleCloudEssentialcontactsV1ComputeContactsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudEssentialcontactsV1ComputeContactsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudEssentialcontactsV1ComputeContactsResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudEssentialcontactsV1ComputeContactsResponse(
          od as api.GoogleCloudEssentialcontactsV1ComputeContactsResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudEssentialcontactsV1Contact', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudEssentialcontactsV1Contact();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudEssentialcontactsV1Contact.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudEssentialcontactsV1Contact(
          od as api.GoogleCloudEssentialcontactsV1Contact);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudEssentialcontactsV1ListContactsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudEssentialcontactsV1ListContactsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudEssentialcontactsV1ListContactsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudEssentialcontactsV1ListContactsResponse(
          od as api.GoogleCloudEssentialcontactsV1ListContactsResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudEssentialcontactsV1SendTestMessageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudEssentialcontactsV1SendTestMessageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudEssentialcontactsV1SendTestMessageRequest.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudEssentialcontactsV1SendTestMessageRequest(
          od as api.GoogleCloudEssentialcontactsV1SendTestMessageRequest);
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

  unittest.group('resource-FoldersContactsResource', () {
    unittest.test('method--compute', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).folders.contacts;
      var arg_parent = 'foo';
      var arg_notificationCategories = buildUnnamed643();
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
          queryMap["notificationCategories"]!,
          unittest.equals(arg_notificationCategories),
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
        var resp = convert.json.encode(
            buildGoogleCloudEssentialcontactsV1ComputeContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.compute(arg_parent,
          notificationCategories: arg_notificationCategories,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1ComputeContactsResponse(response
          as api.GoogleCloudEssentialcontactsV1ComputeContactsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).folders.contacts;
      var arg_request = buildGoogleCloudEssentialcontactsV1Contact();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudEssentialcontactsV1Contact.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1Contact(
            obj as api.GoogleCloudEssentialcontactsV1Contact);

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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).folders.contacts;
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
      var res = api.EssentialcontactsApi(mock).folders.contacts;
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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).folders.contacts;
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
            .encode(buildGoogleCloudEssentialcontactsV1ListContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1ListContactsResponse(
          response as api.GoogleCloudEssentialcontactsV1ListContactsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).folders.contacts;
      var arg_request = buildGoogleCloudEssentialcontactsV1Contact();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudEssentialcontactsV1Contact.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1Contact(
            obj as api.GoogleCloudEssentialcontactsV1Contact);

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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--sendTestMessage', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).folders.contacts;
      var arg_request =
          buildGoogleCloudEssentialcontactsV1SendTestMessageRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleCloudEssentialcontactsV1SendTestMessageRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1SendTestMessageRequest(
            obj as api.GoogleCloudEssentialcontactsV1SendTestMessageRequest);

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
      final response = await res.sendTestMessage(arg_request, arg_resource,
          $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });
  });

  unittest.group('resource-OrganizationsContactsResource', () {
    unittest.test('method--compute', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).organizations.contacts;
      var arg_parent = 'foo';
      var arg_notificationCategories = buildUnnamed644();
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
          queryMap["notificationCategories"]!,
          unittest.equals(arg_notificationCategories),
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
        var resp = convert.json.encode(
            buildGoogleCloudEssentialcontactsV1ComputeContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.compute(arg_parent,
          notificationCategories: arg_notificationCategories,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1ComputeContactsResponse(response
          as api.GoogleCloudEssentialcontactsV1ComputeContactsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).organizations.contacts;
      var arg_request = buildGoogleCloudEssentialcontactsV1Contact();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudEssentialcontactsV1Contact.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1Contact(
            obj as api.GoogleCloudEssentialcontactsV1Contact);

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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).organizations.contacts;
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
      var res = api.EssentialcontactsApi(mock).organizations.contacts;
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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).organizations.contacts;
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
            .encode(buildGoogleCloudEssentialcontactsV1ListContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1ListContactsResponse(
          response as api.GoogleCloudEssentialcontactsV1ListContactsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).organizations.contacts;
      var arg_request = buildGoogleCloudEssentialcontactsV1Contact();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudEssentialcontactsV1Contact.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1Contact(
            obj as api.GoogleCloudEssentialcontactsV1Contact);

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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--sendTestMessage', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).organizations.contacts;
      var arg_request =
          buildGoogleCloudEssentialcontactsV1SendTestMessageRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleCloudEssentialcontactsV1SendTestMessageRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1SendTestMessageRequest(
            obj as api.GoogleCloudEssentialcontactsV1SendTestMessageRequest);

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
      final response = await res.sendTestMessage(arg_request, arg_resource,
          $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });
  });

  unittest.group('resource-ProjectsContactsResource', () {
    unittest.test('method--compute', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).projects.contacts;
      var arg_parent = 'foo';
      var arg_notificationCategories = buildUnnamed645();
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
          queryMap["notificationCategories"]!,
          unittest.equals(arg_notificationCategories),
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
        var resp = convert.json.encode(
            buildGoogleCloudEssentialcontactsV1ComputeContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.compute(arg_parent,
          notificationCategories: arg_notificationCategories,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1ComputeContactsResponse(response
          as api.GoogleCloudEssentialcontactsV1ComputeContactsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).projects.contacts;
      var arg_request = buildGoogleCloudEssentialcontactsV1Contact();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudEssentialcontactsV1Contact.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1Contact(
            obj as api.GoogleCloudEssentialcontactsV1Contact);

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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).projects.contacts;
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
      var res = api.EssentialcontactsApi(mock).projects.contacts;
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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).projects.contacts;
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
            .encode(buildGoogleCloudEssentialcontactsV1ListContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1ListContactsResponse(
          response as api.GoogleCloudEssentialcontactsV1ListContactsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).projects.contacts;
      var arg_request = buildGoogleCloudEssentialcontactsV1Contact();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudEssentialcontactsV1Contact.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1Contact(
            obj as api.GoogleCloudEssentialcontactsV1Contact);

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
            convert.json.encode(buildGoogleCloudEssentialcontactsV1Contact());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGoogleCloudEssentialcontactsV1Contact(
          response as api.GoogleCloudEssentialcontactsV1Contact);
    });

    unittest.test('method--sendTestMessage', () async {
      var mock = HttpServerMock();
      var res = api.EssentialcontactsApi(mock).projects.contacts;
      var arg_request =
          buildGoogleCloudEssentialcontactsV1SendTestMessageRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleCloudEssentialcontactsV1SendTestMessageRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudEssentialcontactsV1SendTestMessageRequest(
            obj as api.GoogleCloudEssentialcontactsV1SendTestMessageRequest);

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
      final response = await res.sendTestMessage(arg_request, arg_resource,
          $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });
  });
}

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

import 'package:googleapis/mybusinessplaceactions/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

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

core.List<api.PlaceActionLink> buildUnnamed6160() {
  var o = <api.PlaceActionLink>[];
  o.add(buildPlaceActionLink());
  o.add(buildPlaceActionLink());
  return o;
}

void checkUnnamed6160(core.List<api.PlaceActionLink> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlaceActionLink(o[0] as api.PlaceActionLink);
  checkPlaceActionLink(o[1] as api.PlaceActionLink);
}

core.int buildCounterListPlaceActionLinksResponse = 0;
api.ListPlaceActionLinksResponse buildListPlaceActionLinksResponse() {
  var o = api.ListPlaceActionLinksResponse();
  buildCounterListPlaceActionLinksResponse++;
  if (buildCounterListPlaceActionLinksResponse < 3) {
    o.nextPageToken = 'foo';
    o.placeActionLinks = buildUnnamed6160();
  }
  buildCounterListPlaceActionLinksResponse--;
  return o;
}

void checkListPlaceActionLinksResponse(api.ListPlaceActionLinksResponse o) {
  buildCounterListPlaceActionLinksResponse++;
  if (buildCounterListPlaceActionLinksResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed6160(o.placeActionLinks!);
  }
  buildCounterListPlaceActionLinksResponse--;
}

core.List<api.PlaceActionTypeMetadata> buildUnnamed6161() {
  var o = <api.PlaceActionTypeMetadata>[];
  o.add(buildPlaceActionTypeMetadata());
  o.add(buildPlaceActionTypeMetadata());
  return o;
}

void checkUnnamed6161(core.List<api.PlaceActionTypeMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlaceActionTypeMetadata(o[0] as api.PlaceActionTypeMetadata);
  checkPlaceActionTypeMetadata(o[1] as api.PlaceActionTypeMetadata);
}

core.int buildCounterListPlaceActionTypeMetadataResponse = 0;
api.ListPlaceActionTypeMetadataResponse
    buildListPlaceActionTypeMetadataResponse() {
  var o = api.ListPlaceActionTypeMetadataResponse();
  buildCounterListPlaceActionTypeMetadataResponse++;
  if (buildCounterListPlaceActionTypeMetadataResponse < 3) {
    o.nextPageToken = 'foo';
    o.placeActionTypeMetadata = buildUnnamed6161();
  }
  buildCounterListPlaceActionTypeMetadataResponse--;
  return o;
}

void checkListPlaceActionTypeMetadataResponse(
    api.ListPlaceActionTypeMetadataResponse o) {
  buildCounterListPlaceActionTypeMetadataResponse++;
  if (buildCounterListPlaceActionTypeMetadataResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed6161(o.placeActionTypeMetadata!);
  }
  buildCounterListPlaceActionTypeMetadataResponse--;
}

core.int buildCounterPlaceActionLink = 0;
api.PlaceActionLink buildPlaceActionLink() {
  var o = api.PlaceActionLink();
  buildCounterPlaceActionLink++;
  if (buildCounterPlaceActionLink < 3) {
    o.createTime = 'foo';
    o.isEditable = true;
    o.isPreferred = true;
    o.name = 'foo';
    o.placeActionType = 'foo';
    o.providerType = 'foo';
    o.updateTime = 'foo';
    o.uri = 'foo';
  }
  buildCounterPlaceActionLink--;
  return o;
}

void checkPlaceActionLink(api.PlaceActionLink o) {
  buildCounterPlaceActionLink++;
  if (buildCounterPlaceActionLink < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isEditable!, unittest.isTrue);
    unittest.expect(o.isPreferred!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.placeActionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.providerType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaceActionLink--;
}

core.int buildCounterPlaceActionTypeMetadata = 0;
api.PlaceActionTypeMetadata buildPlaceActionTypeMetadata() {
  var o = api.PlaceActionTypeMetadata();
  buildCounterPlaceActionTypeMetadata++;
  if (buildCounterPlaceActionTypeMetadata < 3) {
    o.displayName = 'foo';
    o.placeActionType = 'foo';
  }
  buildCounterPlaceActionTypeMetadata--;
  return o;
}

void checkPlaceActionTypeMetadata(api.PlaceActionTypeMetadata o) {
  buildCounterPlaceActionTypeMetadata++;
  if (buildCounterPlaceActionTypeMetadata < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.placeActionType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaceActionTypeMetadata--;
}

void main() {
  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-ListPlaceActionLinksResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPlaceActionLinksResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPlaceActionLinksResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPlaceActionLinksResponse(od as api.ListPlaceActionLinksResponse);
    });
  });

  unittest.group('obj-schema-ListPlaceActionTypeMetadataResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPlaceActionTypeMetadataResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPlaceActionTypeMetadataResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPlaceActionTypeMetadataResponse(
          od as api.ListPlaceActionTypeMetadataResponse);
    });
  });

  unittest.group('obj-schema-PlaceActionLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaceActionLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaceActionLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaceActionLink(od as api.PlaceActionLink);
    });
  });

  unittest.group('obj-schema-PlaceActionTypeMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaceActionTypeMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaceActionTypeMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaceActionTypeMetadata(od as api.PlaceActionTypeMetadata);
    });
  });

  unittest.group('resource-LocationsPlaceActionLinksResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessPlaceActionsApi(mock).locations.placeActionLinks;
      var arg_request = buildPlaceActionLink();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PlaceActionLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPlaceActionLink(obj as api.PlaceActionLink);

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
        var resp = convert.json.encode(buildPlaceActionLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkPlaceActionLink(response as api.PlaceActionLink);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessPlaceActionsApi(mock).locations.placeActionLinks;
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
      var res = api.MyBusinessPlaceActionsApi(mock).locations.placeActionLinks;
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
        var resp = convert.json.encode(buildPlaceActionLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkPlaceActionLink(response as api.PlaceActionLink);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessPlaceActionsApi(mock).locations.placeActionLinks;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListPlaceActionLinksResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPlaceActionLinksResponse(
          response as api.ListPlaceActionLinksResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessPlaceActionsApi(mock).locations.placeActionLinks;
      var arg_request = buildPlaceActionLink();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PlaceActionLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPlaceActionLink(obj as api.PlaceActionLink);

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
        var resp = convert.json.encode(buildPlaceActionLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkPlaceActionLink(response as api.PlaceActionLink);
    });
  });

  unittest.group('resource-PlaceActionTypeMetadataResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessPlaceActionsApi(mock).placeActionTypeMetadata;
      var arg_filter = 'foo';
      var arg_languageCode = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("v1/placeActionTypeMetadata"),
        );
        pathOffset += 26;

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
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
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
        var resp =
            convert.json.encode(buildListPlaceActionTypeMetadataResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          languageCode: arg_languageCode,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPlaceActionTypeMetadataResponse(
          response as api.ListPlaceActionTypeMetadataResponse);
    });
  });
}

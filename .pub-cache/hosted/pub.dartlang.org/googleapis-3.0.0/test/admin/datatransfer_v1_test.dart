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

import 'package:googleapis/admin/datatransfer_v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.ApplicationTransferParam> buildUnnamed5740() {
  var o = <api.ApplicationTransferParam>[];
  o.add(buildApplicationTransferParam());
  o.add(buildApplicationTransferParam());
  return o;
}

void checkUnnamed5740(core.List<api.ApplicationTransferParam> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApplicationTransferParam(o[0] as api.ApplicationTransferParam);
  checkApplicationTransferParam(o[1] as api.ApplicationTransferParam);
}

core.int buildCounterApplication = 0;
api.Application buildApplication() {
  var o = api.Application();
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.transferParams = buildUnnamed5740();
  }
  buildCounterApplication--;
  return o;
}

void checkApplication(api.Application o) {
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5740(o.transferParams!);
  }
  buildCounterApplication--;
}

core.List<api.ApplicationTransferParam> buildUnnamed5741() {
  var o = <api.ApplicationTransferParam>[];
  o.add(buildApplicationTransferParam());
  o.add(buildApplicationTransferParam());
  return o;
}

void checkUnnamed5741(core.List<api.ApplicationTransferParam> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApplicationTransferParam(o[0] as api.ApplicationTransferParam);
  checkApplicationTransferParam(o[1] as api.ApplicationTransferParam);
}

core.int buildCounterApplicationDataTransfer = 0;
api.ApplicationDataTransfer buildApplicationDataTransfer() {
  var o = api.ApplicationDataTransfer();
  buildCounterApplicationDataTransfer++;
  if (buildCounterApplicationDataTransfer < 3) {
    o.applicationId = 'foo';
    o.applicationTransferParams = buildUnnamed5741();
    o.applicationTransferStatus = 'foo';
  }
  buildCounterApplicationDataTransfer--;
  return o;
}

void checkApplicationDataTransfer(api.ApplicationDataTransfer o) {
  buildCounterApplicationDataTransfer++;
  if (buildCounterApplicationDataTransfer < 3) {
    unittest.expect(
      o.applicationId!,
      unittest.equals('foo'),
    );
    checkUnnamed5741(o.applicationTransferParams!);
    unittest.expect(
      o.applicationTransferStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplicationDataTransfer--;
}

core.List<core.String> buildUnnamed5742() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5742(core.List<core.String> o) {
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

core.int buildCounterApplicationTransferParam = 0;
api.ApplicationTransferParam buildApplicationTransferParam() {
  var o = api.ApplicationTransferParam();
  buildCounterApplicationTransferParam++;
  if (buildCounterApplicationTransferParam < 3) {
    o.key = 'foo';
    o.value = buildUnnamed5742();
  }
  buildCounterApplicationTransferParam--;
  return o;
}

void checkApplicationTransferParam(api.ApplicationTransferParam o) {
  buildCounterApplicationTransferParam++;
  if (buildCounterApplicationTransferParam < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    checkUnnamed5742(o.value!);
  }
  buildCounterApplicationTransferParam--;
}

core.List<api.Application> buildUnnamed5743() {
  var o = <api.Application>[];
  o.add(buildApplication());
  o.add(buildApplication());
  return o;
}

void checkUnnamed5743(core.List<api.Application> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApplication(o[0] as api.Application);
  checkApplication(o[1] as api.Application);
}

core.int buildCounterApplicationsListResponse = 0;
api.ApplicationsListResponse buildApplicationsListResponse() {
  var o = api.ApplicationsListResponse();
  buildCounterApplicationsListResponse++;
  if (buildCounterApplicationsListResponse < 3) {
    o.applications = buildUnnamed5743();
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterApplicationsListResponse--;
  return o;
}

void checkApplicationsListResponse(api.ApplicationsListResponse o) {
  buildCounterApplicationsListResponse++;
  if (buildCounterApplicationsListResponse < 3) {
    checkUnnamed5743(o.applications!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplicationsListResponse--;
}

core.List<api.ApplicationDataTransfer> buildUnnamed5744() {
  var o = <api.ApplicationDataTransfer>[];
  o.add(buildApplicationDataTransfer());
  o.add(buildApplicationDataTransfer());
  return o;
}

void checkUnnamed5744(core.List<api.ApplicationDataTransfer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApplicationDataTransfer(o[0] as api.ApplicationDataTransfer);
  checkApplicationDataTransfer(o[1] as api.ApplicationDataTransfer);
}

core.int buildCounterDataTransfer = 0;
api.DataTransfer buildDataTransfer() {
  var o = api.DataTransfer();
  buildCounterDataTransfer++;
  if (buildCounterDataTransfer < 3) {
    o.applicationDataTransfers = buildUnnamed5744();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.newOwnerUserId = 'foo';
    o.oldOwnerUserId = 'foo';
    o.overallTransferStatusCode = 'foo';
    o.requestTime = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterDataTransfer--;
  return o;
}

void checkDataTransfer(api.DataTransfer o) {
  buildCounterDataTransfer++;
  if (buildCounterDataTransfer < 3) {
    checkUnnamed5744(o.applicationDataTransfers!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.newOwnerUserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oldOwnerUserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.overallTransferStatusCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterDataTransfer--;
}

core.List<api.DataTransfer> buildUnnamed5745() {
  var o = <api.DataTransfer>[];
  o.add(buildDataTransfer());
  o.add(buildDataTransfer());
  return o;
}

void checkUnnamed5745(core.List<api.DataTransfer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataTransfer(o[0] as api.DataTransfer);
  checkDataTransfer(o[1] as api.DataTransfer);
}

core.int buildCounterDataTransfersListResponse = 0;
api.DataTransfersListResponse buildDataTransfersListResponse() {
  var o = api.DataTransfersListResponse();
  buildCounterDataTransfersListResponse++;
  if (buildCounterDataTransfersListResponse < 3) {
    o.dataTransfers = buildUnnamed5745();
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterDataTransfersListResponse--;
  return o;
}

void checkDataTransfersListResponse(api.DataTransfersListResponse o) {
  buildCounterDataTransfersListResponse++;
  if (buildCounterDataTransfersListResponse < 3) {
    checkUnnamed5745(o.dataTransfers!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataTransfersListResponse--;
}

void main() {
  unittest.group('obj-schema-Application', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Application.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplication(od as api.Application);
    });
  });

  unittest.group('obj-schema-ApplicationDataTransfer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationDataTransfer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationDataTransfer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationDataTransfer(od as api.ApplicationDataTransfer);
    });
  });

  unittest.group('obj-schema-ApplicationTransferParam', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationTransferParam();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationTransferParam.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationTransferParam(od as api.ApplicationTransferParam);
    });
  });

  unittest.group('obj-schema-ApplicationsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationsListResponse(od as api.ApplicationsListResponse);
    });
  });

  unittest.group('obj-schema-DataTransfer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataTransfer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataTransfer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataTransfer(od as api.DataTransfer);
    });
  });

  unittest.group('obj-schema-DataTransfersListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataTransfersListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataTransfersListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataTransfersListResponse(od as api.DataTransfersListResponse);
    });
  });

  unittest.group('resource-ApplicationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DataTransferApi(mock).applications;
      var arg_applicationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("admin/datatransfer/v1/applications/"),
        );
        pathOffset += 35;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationId'),
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
        var resp = convert.json.encode(buildApplication());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_applicationId, $fields: arg_$fields);
      checkApplication(response as api.Application);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DataTransferApi(mock).applications;
      var arg_customerId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 34),
          unittest.equals("admin/datatransfer/v1/applications"),
        );
        pathOffset += 34;

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
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildApplicationsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          customerId: arg_customerId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkApplicationsListResponse(response as api.ApplicationsListResponse);
    });
  });

  unittest.group('resource-TransfersResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DataTransferApi(mock).transfers;
      var arg_dataTransferId = 'foo';
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
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("admin/datatransfer/v1/transfers/"),
        );
        pathOffset += 32;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_dataTransferId'),
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
        var resp = convert.json.encode(buildDataTransfer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_dataTransferId, $fields: arg_$fields);
      checkDataTransfer(response as api.DataTransfer);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DataTransferApi(mock).transfers;
      var arg_request = buildDataTransfer();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DataTransfer.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDataTransfer(obj as api.DataTransfer);

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
          path.substring(pathOffset, pathOffset + 31),
          unittest.equals("admin/datatransfer/v1/transfers"),
        );
        pathOffset += 31;

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
        var resp = convert.json.encode(buildDataTransfer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, $fields: arg_$fields);
      checkDataTransfer(response as api.DataTransfer);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DataTransferApi(mock).transfers;
      var arg_customerId = 'foo';
      var arg_maxResults = 42;
      var arg_newOwnerUserId = 'foo';
      var arg_oldOwnerUserId = 'foo';
      var arg_pageToken = 'foo';
      var arg_status = 'foo';
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
          path.substring(pathOffset, pathOffset + 31),
          unittest.equals("admin/datatransfer/v1/transfers"),
        );
        pathOffset += 31;

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
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["newOwnerUserId"]!.first,
          unittest.equals(arg_newOwnerUserId),
        );
        unittest.expect(
          queryMap["oldOwnerUserId"]!.first,
          unittest.equals(arg_oldOwnerUserId),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["status"]!.first,
          unittest.equals(arg_status),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDataTransfersListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          customerId: arg_customerId,
          maxResults: arg_maxResults,
          newOwnerUserId: arg_newOwnerUserId,
          oldOwnerUserId: arg_oldOwnerUserId,
          pageToken: arg_pageToken,
          status: arg_status,
          $fields: arg_$fields);
      checkDataTransfersListResponse(response as api.DataTransfersListResponse);
    });
  });
}

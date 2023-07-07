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

import 'package:googleapis/workflowexecutions/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterCancelExecutionRequest = 0;
api.CancelExecutionRequest buildCancelExecutionRequest() {
  var o = api.CancelExecutionRequest();
  buildCounterCancelExecutionRequest++;
  if (buildCounterCancelExecutionRequest < 3) {}
  buildCounterCancelExecutionRequest--;
  return o;
}

void checkCancelExecutionRequest(api.CancelExecutionRequest o) {
  buildCounterCancelExecutionRequest++;
  if (buildCounterCancelExecutionRequest < 3) {}
  buildCounterCancelExecutionRequest--;
}

core.int buildCounterError = 0;
api.Error buildError() {
  var o = api.Error();
  buildCounterError++;
  if (buildCounterError < 3) {
    o.context = 'foo';
    o.payload = 'foo';
    o.stackTrace = buildStackTrace();
  }
  buildCounterError--;
  return o;
}

void checkError(api.Error o) {
  buildCounterError++;
  if (buildCounterError < 3) {
    unittest.expect(
      o.context!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.payload!,
      unittest.equals('foo'),
    );
    checkStackTrace(o.stackTrace! as api.StackTrace);
  }
  buildCounterError--;
}

core.int buildCounterExecution = 0;
api.Execution buildExecution() {
  var o = api.Execution();
  buildCounterExecution++;
  if (buildCounterExecution < 3) {
    o.argument = 'foo';
    o.endTime = 'foo';
    o.error = buildError();
    o.name = 'foo';
    o.result = 'foo';
    o.startTime = 'foo';
    o.state = 'foo';
    o.workflowRevisionId = 'foo';
  }
  buildCounterExecution--;
  return o;
}

void checkExecution(api.Execution o) {
  buildCounterExecution++;
  if (buildCounterExecution < 3) {
    unittest.expect(
      o.argument!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkError(o.error! as api.Error);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.result!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workflowRevisionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterExecution--;
}

core.List<api.Execution> buildUnnamed5654() {
  var o = <api.Execution>[];
  o.add(buildExecution());
  o.add(buildExecution());
  return o;
}

void checkUnnamed5654(core.List<api.Execution> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExecution(o[0] as api.Execution);
  checkExecution(o[1] as api.Execution);
}

core.int buildCounterListExecutionsResponse = 0;
api.ListExecutionsResponse buildListExecutionsResponse() {
  var o = api.ListExecutionsResponse();
  buildCounterListExecutionsResponse++;
  if (buildCounterListExecutionsResponse < 3) {
    o.executions = buildUnnamed5654();
    o.nextPageToken = 'foo';
  }
  buildCounterListExecutionsResponse--;
  return o;
}

void checkListExecutionsResponse(api.ListExecutionsResponse o) {
  buildCounterListExecutionsResponse++;
  if (buildCounterListExecutionsResponse < 3) {
    checkUnnamed5654(o.executions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListExecutionsResponse--;
}

core.int buildCounterPosition = 0;
api.Position buildPosition() {
  var o = api.Position();
  buildCounterPosition++;
  if (buildCounterPosition < 3) {
    o.column = 'foo';
    o.length = 'foo';
    o.line = 'foo';
  }
  buildCounterPosition--;
  return o;
}

void checkPosition(api.Position o) {
  buildCounterPosition++;
  if (buildCounterPosition < 3) {
    unittest.expect(
      o.column!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.length!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.line!,
      unittest.equals('foo'),
    );
  }
  buildCounterPosition--;
}

core.List<api.StackTraceElement> buildUnnamed5655() {
  var o = <api.StackTraceElement>[];
  o.add(buildStackTraceElement());
  o.add(buildStackTraceElement());
  return o;
}

void checkUnnamed5655(core.List<api.StackTraceElement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStackTraceElement(o[0] as api.StackTraceElement);
  checkStackTraceElement(o[1] as api.StackTraceElement);
}

core.int buildCounterStackTrace = 0;
api.StackTrace buildStackTrace() {
  var o = api.StackTrace();
  buildCounterStackTrace++;
  if (buildCounterStackTrace < 3) {
    o.elements = buildUnnamed5655();
  }
  buildCounterStackTrace--;
  return o;
}

void checkStackTrace(api.StackTrace o) {
  buildCounterStackTrace++;
  if (buildCounterStackTrace < 3) {
    checkUnnamed5655(o.elements!);
  }
  buildCounterStackTrace--;
}

core.int buildCounterStackTraceElement = 0;
api.StackTraceElement buildStackTraceElement() {
  var o = api.StackTraceElement();
  buildCounterStackTraceElement++;
  if (buildCounterStackTraceElement < 3) {
    o.position = buildPosition();
    o.routine = 'foo';
    o.step = 'foo';
  }
  buildCounterStackTraceElement--;
  return o;
}

void checkStackTraceElement(api.StackTraceElement o) {
  buildCounterStackTraceElement++;
  if (buildCounterStackTraceElement < 3) {
    checkPosition(o.position! as api.Position);
    unittest.expect(
      o.routine!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.step!,
      unittest.equals('foo'),
    );
  }
  buildCounterStackTraceElement--;
}

void main() {
  unittest.group('obj-schema-CancelExecutionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelExecutionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelExecutionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelExecutionRequest(od as api.CancelExecutionRequest);
    });
  });

  unittest.group('obj-schema-Error', () {
    unittest.test('to-json--from-json', () async {
      var o = buildError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Error.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkError(od as api.Error);
    });
  });

  unittest.group('obj-schema-Execution', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecution();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Execution.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExecution(od as api.Execution);
    });
  });

  unittest.group('obj-schema-ListExecutionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListExecutionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListExecutionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListExecutionsResponse(od as api.ListExecutionsResponse);
    });
  });

  unittest.group('obj-schema-Position', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPosition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Position.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPosition(od as api.Position);
    });
  });

  unittest.group('obj-schema-StackTrace', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStackTrace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.StackTrace.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStackTrace(od as api.StackTrace);
    });
  });

  unittest.group('obj-schema-StackTraceElement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStackTraceElement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StackTraceElement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStackTraceElement(od as api.StackTraceElement);
    });
  });

  unittest.group('resource-ProjectsLocationsWorkflowsExecutionsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.WorkflowExecutionsApi(mock)
          .projects
          .locations
          .workflows
          .executions;
      var arg_request = buildCancelExecutionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelExecutionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelExecutionRequest(obj as api.CancelExecutionRequest);

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
        var resp = convert.json.encode(buildExecution());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkExecution(response as api.Execution);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.WorkflowExecutionsApi(mock)
          .projects
          .locations
          .workflows
          .executions;
      var arg_request = buildExecution();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Execution.fromJson(json as core.Map<core.String, core.dynamic>);
        checkExecution(obj as api.Execution);

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
        var resp = convert.json.encode(buildExecution());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkExecution(response as api.Execution);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.WorkflowExecutionsApi(mock)
          .projects
          .locations
          .workflows
          .executions;
      var arg_name = 'foo';
      var arg_view = 'foo';
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
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildExecution());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_name, view: arg_view, $fields: arg_$fields);
      checkExecution(response as api.Execution);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.WorkflowExecutionsApi(mock)
          .projects
          .locations
          .workflows
          .executions;
      var arg_parent = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_view = 'foo';
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
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListExecutionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          view: arg_view,
          $fields: arg_$fields);
      checkListExecutionsResponse(response as api.ListExecutionsResponse);
    });
  });
}

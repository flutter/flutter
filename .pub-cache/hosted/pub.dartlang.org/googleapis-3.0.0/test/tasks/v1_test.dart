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

import 'package:googleapis/tasks/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterTaskLinks = 0;
api.TaskLinks buildTaskLinks() {
  var o = api.TaskLinks();
  buildCounterTaskLinks++;
  if (buildCounterTaskLinks < 3) {
    o.description = 'foo';
    o.link = 'foo';
    o.type = 'foo';
  }
  buildCounterTaskLinks--;
  return o;
}

void checkTaskLinks(api.TaskLinks o) {
  buildCounterTaskLinks++;
  if (buildCounterTaskLinks < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.link!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterTaskLinks--;
}

core.List<api.TaskLinks> buildUnnamed7295() {
  var o = <api.TaskLinks>[];
  o.add(buildTaskLinks());
  o.add(buildTaskLinks());
  return o;
}

void checkUnnamed7295(core.List<api.TaskLinks> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTaskLinks(o[0] as api.TaskLinks);
  checkTaskLinks(o[1] as api.TaskLinks);
}

core.int buildCounterTask = 0;
api.Task buildTask() {
  var o = api.Task();
  buildCounterTask++;
  if (buildCounterTask < 3) {
    o.completed = 'foo';
    o.deleted = true;
    o.due = 'foo';
    o.etag = 'foo';
    o.hidden = true;
    o.id = 'foo';
    o.kind = 'foo';
    o.links = buildUnnamed7295();
    o.notes = 'foo';
    o.parent = 'foo';
    o.position = 'foo';
    o.selfLink = 'foo';
    o.status = 'foo';
    o.title = 'foo';
    o.updated = 'foo';
  }
  buildCounterTask--;
  return o;
}

void checkTask(api.Task o) {
  buildCounterTask++;
  if (buildCounterTask < 3) {
    unittest.expect(
      o.completed!,
      unittest.equals('foo'),
    );
    unittest.expect(o.deleted!, unittest.isTrue);
    unittest.expect(
      o.due!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hidden!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed7295(o.links!);
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.position!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals('foo'),
    );
  }
  buildCounterTask--;
}

core.int buildCounterTaskList = 0;
api.TaskList buildTaskList() {
  var o = api.TaskList();
  buildCounterTaskList++;
  if (buildCounterTaskList < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.selfLink = 'foo';
    o.title = 'foo';
    o.updated = 'foo';
  }
  buildCounterTaskList--;
  return o;
}

void checkTaskList(api.TaskList o) {
  buildCounterTaskList++;
  if (buildCounterTaskList < 3) {
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
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals('foo'),
    );
  }
  buildCounterTaskList--;
}

core.List<api.TaskList> buildUnnamed7296() {
  var o = <api.TaskList>[];
  o.add(buildTaskList());
  o.add(buildTaskList());
  return o;
}

void checkUnnamed7296(core.List<api.TaskList> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTaskList(o[0] as api.TaskList);
  checkTaskList(o[1] as api.TaskList);
}

core.int buildCounterTaskLists = 0;
api.TaskLists buildTaskLists() {
  var o = api.TaskLists();
  buildCounterTaskLists++;
  if (buildCounterTaskLists < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed7296();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterTaskLists--;
  return o;
}

void checkTaskLists(api.TaskLists o) {
  buildCounterTaskLists++;
  if (buildCounterTaskLists < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed7296(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterTaskLists--;
}

core.List<api.Task> buildUnnamed7297() {
  var o = <api.Task>[];
  o.add(buildTask());
  o.add(buildTask());
  return o;
}

void checkUnnamed7297(core.List<api.Task> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTask(o[0] as api.Task);
  checkTask(o[1] as api.Task);
}

core.int buildCounterTasks = 0;
api.Tasks buildTasks() {
  var o = api.Tasks();
  buildCounterTasks++;
  if (buildCounterTasks < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed7297();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterTasks--;
  return o;
}

void checkTasks(api.Tasks o) {
  buildCounterTasks++;
  if (buildCounterTasks < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed7297(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterTasks--;
}

void main() {
  unittest.group('obj-schema-TaskLinks', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTaskLinks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TaskLinks.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTaskLinks(od as api.TaskLinks);
    });
  });

  unittest.group('obj-schema-Task', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTask();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Task.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTask(od as api.Task);
    });
  });

  unittest.group('obj-schema-TaskList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTaskList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TaskList.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTaskList(od as api.TaskList);
    });
  });

  unittest.group('obj-schema-TaskLists', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTaskLists();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TaskLists.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTaskLists(od as api.TaskLists);
    });
  });

  unittest.group('obj-schema-Tasks', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTasks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Tasks.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTasks(od as api.Tasks);
    });
  });

  unittest.group('resource-TasklistsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasklists;
      var arg_tasklist = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("tasks/v1/users/@me/lists/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_tasklist, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasklists;
      var arg_tasklist = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("tasks/v1/users/@me/lists/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
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
        var resp = convert.json.encode(buildTaskList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_tasklist, $fields: arg_$fields);
      checkTaskList(response as api.TaskList);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasklists;
      var arg_request = buildTaskList();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TaskList.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTaskList(obj as api.TaskList);

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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("tasks/v1/users/@me/lists"),
        );
        pathOffset += 24;

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
        var resp = convert.json.encode(buildTaskList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, $fields: arg_$fields);
      checkTaskList(response as api.TaskList);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasklists;
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("tasks/v1/users/@me/lists"),
        );
        pathOffset += 24;

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
        var resp = convert.json.encode(buildTaskLists());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkTaskLists(response as api.TaskLists);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasklists;
      var arg_request = buildTaskList();
      var arg_tasklist = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TaskList.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTaskList(obj as api.TaskList);

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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("tasks/v1/users/@me/lists/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
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
        var resp = convert.json.encode(buildTaskList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_tasklist, $fields: arg_$fields);
      checkTaskList(response as api.TaskList);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasklists;
      var arg_request = buildTaskList();
      var arg_tasklist = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TaskList.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTaskList(obj as api.TaskList);

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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("tasks/v1/users/@me/lists/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
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
        var resp = convert.json.encode(buildTaskList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_tasklist, $fields: arg_$fields);
      checkTaskList(response as api.TaskList);
    });
  });

  unittest.group('resource-TasksResource', () {
    unittest.test('method--clear', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_tasklist = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/clear', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/clear"),
        );
        pathOffset += 6;

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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.clear(arg_tasklist, $fields: arg_$fields);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_tasklist = 'foo';
      var arg_task = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/tasks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tasks/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_task'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_tasklist, arg_task, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_tasklist = 'foo';
      var arg_task = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/tasks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tasks/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_task'),
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
        var resp = convert.json.encode(buildTask());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_tasklist, arg_task, $fields: arg_$fields);
      checkTask(response as api.Task);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_request = buildTask();
      var arg_tasklist = 'foo';
      var arg_parent = 'foo';
      var arg_previous = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Task.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTask(obj as api.Task);

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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/tasks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/tasks"),
        );
        pathOffset += 6;

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
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["previous"]!.first,
          unittest.equals(arg_previous),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTask());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_tasklist,
          parent: arg_parent, previous: arg_previous, $fields: arg_$fields);
      checkTask(response as api.Task);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_tasklist = 'foo';
      var arg_completedMax = 'foo';
      var arg_completedMin = 'foo';
      var arg_dueMax = 'foo';
      var arg_dueMin = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_showCompleted = true;
      var arg_showDeleted = true;
      var arg_showHidden = true;
      var arg_updatedMin = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/tasks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/tasks"),
        );
        pathOffset += 6;

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
          queryMap["completedMax"]!.first,
          unittest.equals(arg_completedMax),
        );
        unittest.expect(
          queryMap["completedMin"]!.first,
          unittest.equals(arg_completedMin),
        );
        unittest.expect(
          queryMap["dueMax"]!.first,
          unittest.equals(arg_dueMax),
        );
        unittest.expect(
          queryMap["dueMin"]!.first,
          unittest.equals(arg_dueMin),
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
          queryMap["showCompleted"]!.first,
          unittest.equals("$arg_showCompleted"),
        );
        unittest.expect(
          queryMap["showDeleted"]!.first,
          unittest.equals("$arg_showDeleted"),
        );
        unittest.expect(
          queryMap["showHidden"]!.first,
          unittest.equals("$arg_showHidden"),
        );
        unittest.expect(
          queryMap["updatedMin"]!.first,
          unittest.equals(arg_updatedMin),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTasks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_tasklist,
          completedMax: arg_completedMax,
          completedMin: arg_completedMin,
          dueMax: arg_dueMax,
          dueMin: arg_dueMin,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          showCompleted: arg_showCompleted,
          showDeleted: arg_showDeleted,
          showHidden: arg_showHidden,
          updatedMin: arg_updatedMin,
          $fields: arg_$fields);
      checkTasks(response as api.Tasks);
    });

    unittest.test('method--move', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_tasklist = 'foo';
      var arg_task = 'foo';
      var arg_parent = 'foo';
      var arg_previous = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/tasks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tasks/"),
        );
        pathOffset += 7;
        index = path.indexOf('/move', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_task'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/move"),
        );
        pathOffset += 5;

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
          queryMap["parent"]!.first,
          unittest.equals(arg_parent),
        );
        unittest.expect(
          queryMap["previous"]!.first,
          unittest.equals(arg_previous),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTask());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.move(arg_tasklist, arg_task,
          parent: arg_parent, previous: arg_previous, $fields: arg_$fields);
      checkTask(response as api.Task);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_request = buildTask();
      var arg_tasklist = 'foo';
      var arg_task = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Task.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTask(obj as api.Task);

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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/tasks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tasks/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_task'),
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
        var resp = convert.json.encode(buildTask());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_tasklist, arg_task,
          $fields: arg_$fields);
      checkTask(response as api.Task);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.TasksApi(mock).tasks;
      var arg_request = buildTask();
      var arg_tasklist = 'foo';
      var arg_task = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Task.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTask(obj as api.Task);

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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("tasks/v1/lists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/tasks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tasklist'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tasks/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_task'),
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
        var resp = convert.json.encode(buildTask());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_tasklist, arg_task,
          $fields: arg_$fields);
      checkTask(response as api.Task);
    });
  });
}

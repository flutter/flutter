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

import 'package:googleapis/oslogin/v1.dart' as api;
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

core.int buildCounterImportSshPublicKeyResponse = 0;
api.ImportSshPublicKeyResponse buildImportSshPublicKeyResponse() {
  var o = api.ImportSshPublicKeyResponse();
  buildCounterImportSshPublicKeyResponse++;
  if (buildCounterImportSshPublicKeyResponse < 3) {
    o.details = 'foo';
    o.loginProfile = buildLoginProfile();
  }
  buildCounterImportSshPublicKeyResponse--;
  return o;
}

void checkImportSshPublicKeyResponse(api.ImportSshPublicKeyResponse o) {
  buildCounterImportSshPublicKeyResponse++;
  if (buildCounterImportSshPublicKeyResponse < 3) {
    unittest.expect(
      o.details!,
      unittest.equals('foo'),
    );
    checkLoginProfile(o.loginProfile! as api.LoginProfile);
  }
  buildCounterImportSshPublicKeyResponse--;
}

core.List<api.PosixAccount> buildUnnamed3468() {
  var o = <api.PosixAccount>[];
  o.add(buildPosixAccount());
  o.add(buildPosixAccount());
  return o;
}

void checkUnnamed3468(core.List<api.PosixAccount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPosixAccount(o[0] as api.PosixAccount);
  checkPosixAccount(o[1] as api.PosixAccount);
}

core.Map<core.String, api.SshPublicKey> buildUnnamed3469() {
  var o = <core.String, api.SshPublicKey>{};
  o['x'] = buildSshPublicKey();
  o['y'] = buildSshPublicKey();
  return o;
}

void checkUnnamed3469(core.Map<core.String, api.SshPublicKey> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSshPublicKey(o['x']! as api.SshPublicKey);
  checkSshPublicKey(o['y']! as api.SshPublicKey);
}

core.int buildCounterLoginProfile = 0;
api.LoginProfile buildLoginProfile() {
  var o = api.LoginProfile();
  buildCounterLoginProfile++;
  if (buildCounterLoginProfile < 3) {
    o.name = 'foo';
    o.posixAccounts = buildUnnamed3468();
    o.sshPublicKeys = buildUnnamed3469();
  }
  buildCounterLoginProfile--;
  return o;
}

void checkLoginProfile(api.LoginProfile o) {
  buildCounterLoginProfile++;
  if (buildCounterLoginProfile < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3468(o.posixAccounts!);
    checkUnnamed3469(o.sshPublicKeys!);
  }
  buildCounterLoginProfile--;
}

core.int buildCounterPosixAccount = 0;
api.PosixAccount buildPosixAccount() {
  var o = api.PosixAccount();
  buildCounterPosixAccount++;
  if (buildCounterPosixAccount < 3) {
    o.accountId = 'foo';
    o.gecos = 'foo';
    o.gid = 'foo';
    o.homeDirectory = 'foo';
    o.name = 'foo';
    o.operatingSystemType = 'foo';
    o.primary = true;
    o.shell = 'foo';
    o.systemId = 'foo';
    o.uid = 'foo';
    o.username = 'foo';
  }
  buildCounterPosixAccount--;
  return o;
}

void checkPosixAccount(api.PosixAccount o) {
  buildCounterPosixAccount++;
  if (buildCounterPosixAccount < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gecos!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.homeDirectory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatingSystemType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.shell!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.systemId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterPosixAccount--;
}

core.int buildCounterSshPublicKey = 0;
api.SshPublicKey buildSshPublicKey() {
  var o = api.SshPublicKey();
  buildCounterSshPublicKey++;
  if (buildCounterSshPublicKey < 3) {
    o.expirationTimeUsec = 'foo';
    o.fingerprint = 'foo';
    o.key = 'foo';
    o.name = 'foo';
  }
  buildCounterSshPublicKey--;
  return o;
}

void checkSshPublicKey(api.SshPublicKey o) {
  buildCounterSshPublicKey++;
  if (buildCounterSshPublicKey < 3) {
    unittest.expect(
      o.expirationTimeUsec!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSshPublicKey--;
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

  unittest.group('obj-schema-ImportSshPublicKeyResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportSshPublicKeyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImportSshPublicKeyResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImportSshPublicKeyResponse(od as api.ImportSshPublicKeyResponse);
    });
  });

  unittest.group('obj-schema-LoginProfile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLoginProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LoginProfile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLoginProfile(od as api.LoginProfile);
    });
  });

  unittest.group('obj-schema-PosixAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPosixAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PosixAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPosixAccount(od as api.PosixAccount);
    });
  });

  unittest.group('obj-schema-SshPublicKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSshPublicKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SshPublicKey.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSshPublicKey(od as api.SshPublicKey);
    });
  });

  unittest.group('resource-UsersResource', () {
    unittest.test('method--getLoginProfile', () async {
      var mock = HttpServerMock();
      var res = api.CloudOSLoginApi(mock).users;
      var arg_name = 'foo';
      var arg_projectId = 'foo';
      var arg_systemId = 'foo';
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
          queryMap["projectId"]!.first,
          unittest.equals(arg_projectId),
        );
        unittest.expect(
          queryMap["systemId"]!.first,
          unittest.equals(arg_systemId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLoginProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getLoginProfile(arg_name,
          projectId: arg_projectId,
          systemId: arg_systemId,
          $fields: arg_$fields);
      checkLoginProfile(response as api.LoginProfile);
    });

    unittest.test('method--importSshPublicKey', () async {
      var mock = HttpServerMock();
      var res = api.CloudOSLoginApi(mock).users;
      var arg_request = buildSshPublicKey();
      var arg_parent = 'foo';
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SshPublicKey.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSshPublicKey(obj as api.SshPublicKey);

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
          queryMap["projectId"]!.first,
          unittest.equals(arg_projectId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildImportSshPublicKeyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.importSshPublicKey(arg_request, arg_parent,
          projectId: arg_projectId, $fields: arg_$fields);
      checkImportSshPublicKeyResponse(
          response as api.ImportSshPublicKeyResponse);
    });
  });

  unittest.group('resource-UsersProjectsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudOSLoginApi(mock).users.projects;
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
  });

  unittest.group('resource-UsersSshPublicKeysResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudOSLoginApi(mock).users.sshPublicKeys;
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
      var res = api.CloudOSLoginApi(mock).users.sshPublicKeys;
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
        var resp = convert.json.encode(buildSshPublicKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSshPublicKey(response as api.SshPublicKey);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudOSLoginApi(mock).users.sshPublicKeys;
      var arg_request = buildSshPublicKey();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SshPublicKey.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSshPublicKey(obj as api.SshPublicKey);

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
        var resp = convert.json.encode(buildSshPublicKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkSshPublicKey(response as api.SshPublicKey);
    });
  });
}

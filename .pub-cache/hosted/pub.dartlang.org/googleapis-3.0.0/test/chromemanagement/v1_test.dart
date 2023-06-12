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

import 'package:googleapis/chromemanagement/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterGoogleChromeManagementV1BrowserVersion = 0;
api.GoogleChromeManagementV1BrowserVersion
    buildGoogleChromeManagementV1BrowserVersion() {
  var o = api.GoogleChromeManagementV1BrowserVersion();
  buildCounterGoogleChromeManagementV1BrowserVersion++;
  if (buildCounterGoogleChromeManagementV1BrowserVersion < 3) {
    o.channel = 'foo';
    o.count = 'foo';
    o.deviceOsVersion = 'foo';
    o.system = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleChromeManagementV1BrowserVersion--;
  return o;
}

void checkGoogleChromeManagementV1BrowserVersion(
    api.GoogleChromeManagementV1BrowserVersion o) {
  buildCounterGoogleChromeManagementV1BrowserVersion++;
  if (buildCounterGoogleChromeManagementV1BrowserVersion < 3) {
    unittest.expect(
      o.channel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deviceOsVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.system!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleChromeManagementV1BrowserVersion--;
}

core.List<api.GoogleChromeManagementV1BrowserVersion> buildUnnamed1455() {
  var o = <api.GoogleChromeManagementV1BrowserVersion>[];
  o.add(buildGoogleChromeManagementV1BrowserVersion());
  o.add(buildGoogleChromeManagementV1BrowserVersion());
  return o;
}

void checkUnnamed1455(core.List<api.GoogleChromeManagementV1BrowserVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleChromeManagementV1BrowserVersion(
      o[0] as api.GoogleChromeManagementV1BrowserVersion);
  checkGoogleChromeManagementV1BrowserVersion(
      o[1] as api.GoogleChromeManagementV1BrowserVersion);
}

core.int buildCounterGoogleChromeManagementV1CountChromeVersionsResponse = 0;
api.GoogleChromeManagementV1CountChromeVersionsResponse
    buildGoogleChromeManagementV1CountChromeVersionsResponse() {
  var o = api.GoogleChromeManagementV1CountChromeVersionsResponse();
  buildCounterGoogleChromeManagementV1CountChromeVersionsResponse++;
  if (buildCounterGoogleChromeManagementV1CountChromeVersionsResponse < 3) {
    o.browserVersions = buildUnnamed1455();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterGoogleChromeManagementV1CountChromeVersionsResponse--;
  return o;
}

void checkGoogleChromeManagementV1CountChromeVersionsResponse(
    api.GoogleChromeManagementV1CountChromeVersionsResponse o) {
  buildCounterGoogleChromeManagementV1CountChromeVersionsResponse++;
  if (buildCounterGoogleChromeManagementV1CountChromeVersionsResponse < 3) {
    checkUnnamed1455(o.browserVersions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleChromeManagementV1CountChromeVersionsResponse--;
}

core.List<api.GoogleChromeManagementV1InstalledApp> buildUnnamed1456() {
  var o = <api.GoogleChromeManagementV1InstalledApp>[];
  o.add(buildGoogleChromeManagementV1InstalledApp());
  o.add(buildGoogleChromeManagementV1InstalledApp());
  return o;
}

void checkUnnamed1456(core.List<api.GoogleChromeManagementV1InstalledApp> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleChromeManagementV1InstalledApp(
      o[0] as api.GoogleChromeManagementV1InstalledApp);
  checkGoogleChromeManagementV1InstalledApp(
      o[1] as api.GoogleChromeManagementV1InstalledApp);
}

core.int buildCounterGoogleChromeManagementV1CountInstalledAppsResponse = 0;
api.GoogleChromeManagementV1CountInstalledAppsResponse
    buildGoogleChromeManagementV1CountInstalledAppsResponse() {
  var o = api.GoogleChromeManagementV1CountInstalledAppsResponse();
  buildCounterGoogleChromeManagementV1CountInstalledAppsResponse++;
  if (buildCounterGoogleChromeManagementV1CountInstalledAppsResponse < 3) {
    o.installedApps = buildUnnamed1456();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterGoogleChromeManagementV1CountInstalledAppsResponse--;
  return o;
}

void checkGoogleChromeManagementV1CountInstalledAppsResponse(
    api.GoogleChromeManagementV1CountInstalledAppsResponse o) {
  buildCounterGoogleChromeManagementV1CountInstalledAppsResponse++;
  if (buildCounterGoogleChromeManagementV1CountInstalledAppsResponse < 3) {
    checkUnnamed1456(o.installedApps!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleChromeManagementV1CountInstalledAppsResponse--;
}

core.int buildCounterGoogleChromeManagementV1Device = 0;
api.GoogleChromeManagementV1Device buildGoogleChromeManagementV1Device() {
  var o = api.GoogleChromeManagementV1Device();
  buildCounterGoogleChromeManagementV1Device++;
  if (buildCounterGoogleChromeManagementV1Device < 3) {
    o.deviceId = 'foo';
    o.machine = 'foo';
  }
  buildCounterGoogleChromeManagementV1Device--;
  return o;
}

void checkGoogleChromeManagementV1Device(api.GoogleChromeManagementV1Device o) {
  buildCounterGoogleChromeManagementV1Device++;
  if (buildCounterGoogleChromeManagementV1Device < 3) {
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.machine!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleChromeManagementV1Device--;
}

core.List<api.GoogleChromeManagementV1Device> buildUnnamed1457() {
  var o = <api.GoogleChromeManagementV1Device>[];
  o.add(buildGoogleChromeManagementV1Device());
  o.add(buildGoogleChromeManagementV1Device());
  return o;
}

void checkUnnamed1457(core.List<api.GoogleChromeManagementV1Device> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleChromeManagementV1Device(
      o[0] as api.GoogleChromeManagementV1Device);
  checkGoogleChromeManagementV1Device(
      o[1] as api.GoogleChromeManagementV1Device);
}

core.int buildCounterGoogleChromeManagementV1FindInstalledAppDevicesResponse =
    0;
api.GoogleChromeManagementV1FindInstalledAppDevicesResponse
    buildGoogleChromeManagementV1FindInstalledAppDevicesResponse() {
  var o = api.GoogleChromeManagementV1FindInstalledAppDevicesResponse();
  buildCounterGoogleChromeManagementV1FindInstalledAppDevicesResponse++;
  if (buildCounterGoogleChromeManagementV1FindInstalledAppDevicesResponse < 3) {
    o.devices = buildUnnamed1457();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterGoogleChromeManagementV1FindInstalledAppDevicesResponse--;
  return o;
}

void checkGoogleChromeManagementV1FindInstalledAppDevicesResponse(
    api.GoogleChromeManagementV1FindInstalledAppDevicesResponse o) {
  buildCounterGoogleChromeManagementV1FindInstalledAppDevicesResponse++;
  if (buildCounterGoogleChromeManagementV1FindInstalledAppDevicesResponse < 3) {
    checkUnnamed1457(o.devices!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleChromeManagementV1FindInstalledAppDevicesResponse--;
}

core.List<core.String> buildUnnamed1458() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1458(core.List<core.String> o) {
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

core.int buildCounterGoogleChromeManagementV1InstalledApp = 0;
api.GoogleChromeManagementV1InstalledApp
    buildGoogleChromeManagementV1InstalledApp() {
  var o = api.GoogleChromeManagementV1InstalledApp();
  buildCounterGoogleChromeManagementV1InstalledApp++;
  if (buildCounterGoogleChromeManagementV1InstalledApp < 3) {
    o.appId = 'foo';
    o.appInstallType = 'foo';
    o.appSource = 'foo';
    o.appType = 'foo';
    o.browserDeviceCount = 'foo';
    o.description = 'foo';
    o.disabled = true;
    o.displayName = 'foo';
    o.homepageUri = 'foo';
    o.osUserCount = 'foo';
    o.permissions = buildUnnamed1458();
  }
  buildCounterGoogleChromeManagementV1InstalledApp--;
  return o;
}

void checkGoogleChromeManagementV1InstalledApp(
    api.GoogleChromeManagementV1InstalledApp o) {
  buildCounterGoogleChromeManagementV1InstalledApp++;
  if (buildCounterGoogleChromeManagementV1InstalledApp < 3) {
    unittest.expect(
      o.appId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appInstallType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.browserDeviceCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.homepageUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.osUserCount!,
      unittest.equals('foo'),
    );
    checkUnnamed1458(o.permissions!);
  }
  buildCounterGoogleChromeManagementV1InstalledApp--;
}

void main() {
  unittest.group('obj-schema-GoogleChromeManagementV1BrowserVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleChromeManagementV1BrowserVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleChromeManagementV1BrowserVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleChromeManagementV1BrowserVersion(
          od as api.GoogleChromeManagementV1BrowserVersion);
    });
  });

  unittest.group(
      'obj-schema-GoogleChromeManagementV1CountChromeVersionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleChromeManagementV1CountChromeVersionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleChromeManagementV1CountChromeVersionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleChromeManagementV1CountChromeVersionsResponse(
          od as api.GoogleChromeManagementV1CountChromeVersionsResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleChromeManagementV1CountInstalledAppsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleChromeManagementV1CountInstalledAppsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleChromeManagementV1CountInstalledAppsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleChromeManagementV1CountInstalledAppsResponse(
          od as api.GoogleChromeManagementV1CountInstalledAppsResponse);
    });
  });

  unittest.group('obj-schema-GoogleChromeManagementV1Device', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleChromeManagementV1Device();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleChromeManagementV1Device.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleChromeManagementV1Device(
          od as api.GoogleChromeManagementV1Device);
    });
  });

  unittest.group(
      'obj-schema-GoogleChromeManagementV1FindInstalledAppDevicesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleChromeManagementV1FindInstalledAppDevicesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleChromeManagementV1FindInstalledAppDevicesResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleChromeManagementV1FindInstalledAppDevicesResponse(
          od as api.GoogleChromeManagementV1FindInstalledAppDevicesResponse);
    });
  });

  unittest.group('obj-schema-GoogleChromeManagementV1InstalledApp', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleChromeManagementV1InstalledApp();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleChromeManagementV1InstalledApp.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleChromeManagementV1InstalledApp(
          od as api.GoogleChromeManagementV1InstalledApp);
    });
  });

  unittest.group('resource-CustomersReportsResource', () {
    unittest.test('method--countChromeVersions', () async {
      var mock = HttpServerMock();
      var res = api.ChromeManagementApi(mock).customers.reports;
      var arg_customer = 'foo';
      var arg_filter = 'foo';
      var arg_orgUnitId = 'foo';
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
          queryMap["orgUnitId"]!.first,
          unittest.equals(arg_orgUnitId),
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
        var resp = convert.json
            .encode(buildGoogleChromeManagementV1CountChromeVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.countChromeVersions(arg_customer,
          filter: arg_filter,
          orgUnitId: arg_orgUnitId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleChromeManagementV1CountChromeVersionsResponse(
          response as api.GoogleChromeManagementV1CountChromeVersionsResponse);
    });

    unittest.test('method--countInstalledApps', () async {
      var mock = HttpServerMock();
      var res = api.ChromeManagementApi(mock).customers.reports;
      var arg_customer = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_orgUnitId = 'foo';
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
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["orgUnitId"]!.first,
          unittest.equals(arg_orgUnitId),
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
        var resp = convert.json
            .encode(buildGoogleChromeManagementV1CountInstalledAppsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.countInstalledApps(arg_customer,
          filter: arg_filter,
          orderBy: arg_orderBy,
          orgUnitId: arg_orgUnitId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleChromeManagementV1CountInstalledAppsResponse(
          response as api.GoogleChromeManagementV1CountInstalledAppsResponse);
    });

    unittest.test('method--findInstalledAppDevices', () async {
      var mock = HttpServerMock();
      var res = api.ChromeManagementApi(mock).customers.reports;
      var arg_customer = 'foo';
      var arg_appId = 'foo';
      var arg_appType = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_orgUnitId = 'foo';
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
          queryMap["appId"]!.first,
          unittest.equals(arg_appId),
        );
        unittest.expect(
          queryMap["appType"]!.first,
          unittest.equals(arg_appType),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["orgUnitId"]!.first,
          unittest.equals(arg_orgUnitId),
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
            buildGoogleChromeManagementV1FindInstalledAppDevicesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.findInstalledAppDevices(arg_customer,
          appId: arg_appId,
          appType: arg_appType,
          filter: arg_filter,
          orderBy: arg_orderBy,
          orgUnitId: arg_orgUnitId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleChromeManagementV1FindInstalledAppDevicesResponse(response
          as api.GoogleChromeManagementV1FindInstalledAppDevicesResponse);
    });
  });
}

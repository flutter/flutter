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

import 'package:googleapis/accessapproval/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.EnrolledService> buildUnnamed5248() {
  var o = <api.EnrolledService>[];
  o.add(buildEnrolledService());
  o.add(buildEnrolledService());
  return o;
}

void checkUnnamed5248(core.List<api.EnrolledService> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEnrolledService(o[0] as api.EnrolledService);
  checkEnrolledService(o[1] as api.EnrolledService);
}

core.List<core.String> buildUnnamed5249() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5249(core.List<core.String> o) {
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

core.int buildCounterAccessApprovalSettings = 0;
api.AccessApprovalSettings buildAccessApprovalSettings() {
  var o = api.AccessApprovalSettings();
  buildCounterAccessApprovalSettings++;
  if (buildCounterAccessApprovalSettings < 3) {
    o.enrolledAncestor = true;
    o.enrolledServices = buildUnnamed5248();
    o.name = 'foo';
    o.notificationEmails = buildUnnamed5249();
  }
  buildCounterAccessApprovalSettings--;
  return o;
}

void checkAccessApprovalSettings(api.AccessApprovalSettings o) {
  buildCounterAccessApprovalSettings++;
  if (buildCounterAccessApprovalSettings < 3) {
    unittest.expect(o.enrolledAncestor!, unittest.isTrue);
    checkUnnamed5248(o.enrolledServices!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5249(o.notificationEmails!);
  }
  buildCounterAccessApprovalSettings--;
}

core.int buildCounterAccessLocations = 0;
api.AccessLocations buildAccessLocations() {
  var o = api.AccessLocations();
  buildCounterAccessLocations++;
  if (buildCounterAccessLocations < 3) {
    o.principalOfficeCountry = 'foo';
    o.principalPhysicalLocationCountry = 'foo';
  }
  buildCounterAccessLocations--;
  return o;
}

void checkAccessLocations(api.AccessLocations o) {
  buildCounterAccessLocations++;
  if (buildCounterAccessLocations < 3) {
    unittest.expect(
      o.principalOfficeCountry!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.principalPhysicalLocationCountry!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccessLocations--;
}

core.int buildCounterAccessReason = 0;
api.AccessReason buildAccessReason() {
  var o = api.AccessReason();
  buildCounterAccessReason++;
  if (buildCounterAccessReason < 3) {
    o.detail = 'foo';
    o.type = 'foo';
  }
  buildCounterAccessReason--;
  return o;
}

void checkAccessReason(api.AccessReason o) {
  buildCounterAccessReason++;
  if (buildCounterAccessReason < 3) {
    unittest.expect(
      o.detail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccessReason--;
}

core.int buildCounterApprovalRequest = 0;
api.ApprovalRequest buildApprovalRequest() {
  var o = api.ApprovalRequest();
  buildCounterApprovalRequest++;
  if (buildCounterApprovalRequest < 3) {
    o.approve = buildApproveDecision();
    o.dismiss = buildDismissDecision();
    o.name = 'foo';
    o.requestTime = 'foo';
    o.requestedExpiration = 'foo';
    o.requestedLocations = buildAccessLocations();
    o.requestedReason = buildAccessReason();
    o.requestedResourceName = 'foo';
    o.requestedResourceProperties = buildResourceProperties();
  }
  buildCounterApprovalRequest--;
  return o;
}

void checkApprovalRequest(api.ApprovalRequest o) {
  buildCounterApprovalRequest++;
  if (buildCounterApprovalRequest < 3) {
    checkApproveDecision(o.approve! as api.ApproveDecision);
    checkDismissDecision(o.dismiss! as api.DismissDecision);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestedExpiration!,
      unittest.equals('foo'),
    );
    checkAccessLocations(o.requestedLocations! as api.AccessLocations);
    checkAccessReason(o.requestedReason! as api.AccessReason);
    unittest.expect(
      o.requestedResourceName!,
      unittest.equals('foo'),
    );
    checkResourceProperties(
        o.requestedResourceProperties! as api.ResourceProperties);
  }
  buildCounterApprovalRequest--;
}

core.int buildCounterApproveApprovalRequestMessage = 0;
api.ApproveApprovalRequestMessage buildApproveApprovalRequestMessage() {
  var o = api.ApproveApprovalRequestMessage();
  buildCounterApproveApprovalRequestMessage++;
  if (buildCounterApproveApprovalRequestMessage < 3) {
    o.expireTime = 'foo';
  }
  buildCounterApproveApprovalRequestMessage--;
  return o;
}

void checkApproveApprovalRequestMessage(api.ApproveApprovalRequestMessage o) {
  buildCounterApproveApprovalRequestMessage++;
  if (buildCounterApproveApprovalRequestMessage < 3) {
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterApproveApprovalRequestMessage--;
}

core.int buildCounterApproveDecision = 0;
api.ApproveDecision buildApproveDecision() {
  var o = api.ApproveDecision();
  buildCounterApproveDecision++;
  if (buildCounterApproveDecision < 3) {
    o.approveTime = 'foo';
    o.expireTime = 'foo';
  }
  buildCounterApproveDecision--;
  return o;
}

void checkApproveDecision(api.ApproveDecision o) {
  buildCounterApproveDecision++;
  if (buildCounterApproveDecision < 3) {
    unittest.expect(
      o.approveTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterApproveDecision--;
}

core.int buildCounterDismissApprovalRequestMessage = 0;
api.DismissApprovalRequestMessage buildDismissApprovalRequestMessage() {
  var o = api.DismissApprovalRequestMessage();
  buildCounterDismissApprovalRequestMessage++;
  if (buildCounterDismissApprovalRequestMessage < 3) {}
  buildCounterDismissApprovalRequestMessage--;
  return o;
}

void checkDismissApprovalRequestMessage(api.DismissApprovalRequestMessage o) {
  buildCounterDismissApprovalRequestMessage++;
  if (buildCounterDismissApprovalRequestMessage < 3) {}
  buildCounterDismissApprovalRequestMessage--;
}

core.int buildCounterDismissDecision = 0;
api.DismissDecision buildDismissDecision() {
  var o = api.DismissDecision();
  buildCounterDismissDecision++;
  if (buildCounterDismissDecision < 3) {
    o.dismissTime = 'foo';
    o.implicit = true;
  }
  buildCounterDismissDecision--;
  return o;
}

void checkDismissDecision(api.DismissDecision o) {
  buildCounterDismissDecision++;
  if (buildCounterDismissDecision < 3) {
    unittest.expect(
      o.dismissTime!,
      unittest.equals('foo'),
    );
    unittest.expect(o.implicit!, unittest.isTrue);
  }
  buildCounterDismissDecision--;
}

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

core.int buildCounterEnrolledService = 0;
api.EnrolledService buildEnrolledService() {
  var o = api.EnrolledService();
  buildCounterEnrolledService++;
  if (buildCounterEnrolledService < 3) {
    o.cloudProduct = 'foo';
    o.enrollmentLevel = 'foo';
  }
  buildCounterEnrolledService--;
  return o;
}

void checkEnrolledService(api.EnrolledService o) {
  buildCounterEnrolledService++;
  if (buildCounterEnrolledService < 3) {
    unittest.expect(
      o.cloudProduct!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.enrollmentLevel!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnrolledService--;
}

core.List<api.ApprovalRequest> buildUnnamed5250() {
  var o = <api.ApprovalRequest>[];
  o.add(buildApprovalRequest());
  o.add(buildApprovalRequest());
  return o;
}

void checkUnnamed5250(core.List<api.ApprovalRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkApprovalRequest(o[0] as api.ApprovalRequest);
  checkApprovalRequest(o[1] as api.ApprovalRequest);
}

core.int buildCounterListApprovalRequestsResponse = 0;
api.ListApprovalRequestsResponse buildListApprovalRequestsResponse() {
  var o = api.ListApprovalRequestsResponse();
  buildCounterListApprovalRequestsResponse++;
  if (buildCounterListApprovalRequestsResponse < 3) {
    o.approvalRequests = buildUnnamed5250();
    o.nextPageToken = 'foo';
  }
  buildCounterListApprovalRequestsResponse--;
  return o;
}

void checkListApprovalRequestsResponse(api.ListApprovalRequestsResponse o) {
  buildCounterListApprovalRequestsResponse++;
  if (buildCounterListApprovalRequestsResponse < 3) {
    checkUnnamed5250(o.approvalRequests!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListApprovalRequestsResponse--;
}

core.int buildCounterResourceProperties = 0;
api.ResourceProperties buildResourceProperties() {
  var o = api.ResourceProperties();
  buildCounterResourceProperties++;
  if (buildCounterResourceProperties < 3) {
    o.excludesDescendants = true;
  }
  buildCounterResourceProperties--;
  return o;
}

void checkResourceProperties(api.ResourceProperties o) {
  buildCounterResourceProperties++;
  if (buildCounterResourceProperties < 3) {
    unittest.expect(o.excludesDescendants!, unittest.isTrue);
  }
  buildCounterResourceProperties--;
}

void main() {
  unittest.group('obj-schema-AccessApprovalSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessApprovalSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessApprovalSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessApprovalSettings(od as api.AccessApprovalSettings);
    });
  });

  unittest.group('obj-schema-AccessLocations', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessLocations();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessLocations.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessLocations(od as api.AccessLocations);
    });
  });

  unittest.group('obj-schema-AccessReason', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessReason();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessReason.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessReason(od as api.AccessReason);
    });
  });

  unittest.group('obj-schema-ApprovalRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApprovalRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApprovalRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApprovalRequest(od as api.ApprovalRequest);
    });
  });

  unittest.group('obj-schema-ApproveApprovalRequestMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApproveApprovalRequestMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApproveApprovalRequestMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApproveApprovalRequestMessage(
          od as api.ApproveApprovalRequestMessage);
    });
  });

  unittest.group('obj-schema-ApproveDecision', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApproveDecision();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApproveDecision.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApproveDecision(od as api.ApproveDecision);
    });
  });

  unittest.group('obj-schema-DismissApprovalRequestMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDismissApprovalRequestMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DismissApprovalRequestMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDismissApprovalRequestMessage(
          od as api.DismissApprovalRequestMessage);
    });
  });

  unittest.group('obj-schema-DismissDecision', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDismissDecision();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DismissDecision.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDismissDecision(od as api.DismissDecision);
    });
  });

  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-EnrolledService', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnrolledService();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnrolledService.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnrolledService(od as api.EnrolledService);
    });
  });

  unittest.group('obj-schema-ListApprovalRequestsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListApprovalRequestsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListApprovalRequestsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListApprovalRequestsResponse(od as api.ListApprovalRequestsResponse);
    });
  });

  unittest.group('obj-schema-ResourceProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceProperties(od as api.ResourceProperties);
    });
  });

  unittest.group('resource-FoldersResource', () {
    unittest.test('method--deleteAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).folders;
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
      final response = await res.deleteAccessApprovalSettings(arg_name,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--getAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).folders;
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
        var resp = convert.json.encode(buildAccessApprovalSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getAccessApprovalSettings(arg_name, $fields: arg_$fields);
      checkAccessApprovalSettings(response as api.AccessApprovalSettings);
    });

    unittest.test('method--updateAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).folders;
      var arg_request = buildAccessApprovalSettings();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AccessApprovalSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAccessApprovalSettings(obj as api.AccessApprovalSettings);

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
        var resp = convert.json.encode(buildAccessApprovalSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateAccessApprovalSettings(
          arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAccessApprovalSettings(response as api.AccessApprovalSettings);
    });
  });

  unittest.group('resource-FoldersApprovalRequestsResource', () {
    unittest.test('method--approve', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).folders.approvalRequests;
      var arg_request = buildApproveApprovalRequestMessage();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ApproveApprovalRequestMessage.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkApproveApprovalRequestMessage(
            obj as api.ApproveApprovalRequestMessage);

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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.approve(arg_request, arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--dismiss', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).folders.approvalRequests;
      var arg_request = buildDismissApprovalRequestMessage();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DismissApprovalRequestMessage.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDismissApprovalRequestMessage(
            obj as api.DismissApprovalRequestMessage);

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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.dismiss(arg_request, arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).folders.approvalRequests;
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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).folders.approvalRequests;
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
        var resp = convert.json.encode(buildListApprovalRequestsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListApprovalRequestsResponse(
          response as api.ListApprovalRequestsResponse);
    });
  });

  unittest.group('resource-OrganizationsResource', () {
    unittest.test('method--deleteAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).organizations;
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
      final response = await res.deleteAccessApprovalSettings(arg_name,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--getAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).organizations;
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
        var resp = convert.json.encode(buildAccessApprovalSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getAccessApprovalSettings(arg_name, $fields: arg_$fields);
      checkAccessApprovalSettings(response as api.AccessApprovalSettings);
    });

    unittest.test('method--updateAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).organizations;
      var arg_request = buildAccessApprovalSettings();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AccessApprovalSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAccessApprovalSettings(obj as api.AccessApprovalSettings);

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
        var resp = convert.json.encode(buildAccessApprovalSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateAccessApprovalSettings(
          arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAccessApprovalSettings(response as api.AccessApprovalSettings);
    });
  });

  unittest.group('resource-OrganizationsApprovalRequestsResource', () {
    unittest.test('method--approve', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).organizations.approvalRequests;
      var arg_request = buildApproveApprovalRequestMessage();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ApproveApprovalRequestMessage.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkApproveApprovalRequestMessage(
            obj as api.ApproveApprovalRequestMessage);

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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.approve(arg_request, arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--dismiss', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).organizations.approvalRequests;
      var arg_request = buildDismissApprovalRequestMessage();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DismissApprovalRequestMessage.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDismissApprovalRequestMessage(
            obj as api.DismissApprovalRequestMessage);

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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.dismiss(arg_request, arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).organizations.approvalRequests;
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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).organizations.approvalRequests;
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
        var resp = convert.json.encode(buildListApprovalRequestsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListApprovalRequestsResponse(
          response as api.ListApprovalRequestsResponse);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--deleteAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).projects;
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
      final response = await res.deleteAccessApprovalSettings(arg_name,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--getAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).projects;
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
        var resp = convert.json.encode(buildAccessApprovalSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getAccessApprovalSettings(arg_name, $fields: arg_$fields);
      checkAccessApprovalSettings(response as api.AccessApprovalSettings);
    });

    unittest.test('method--updateAccessApprovalSettings', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).projects;
      var arg_request = buildAccessApprovalSettings();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AccessApprovalSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAccessApprovalSettings(obj as api.AccessApprovalSettings);

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
        var resp = convert.json.encode(buildAccessApprovalSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateAccessApprovalSettings(
          arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAccessApprovalSettings(response as api.AccessApprovalSettings);
    });
  });

  unittest.group('resource-ProjectsApprovalRequestsResource', () {
    unittest.test('method--approve', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).projects.approvalRequests;
      var arg_request = buildApproveApprovalRequestMessage();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ApproveApprovalRequestMessage.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkApproveApprovalRequestMessage(
            obj as api.ApproveApprovalRequestMessage);

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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.approve(arg_request, arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--dismiss', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).projects.approvalRequests;
      var arg_request = buildDismissApprovalRequestMessage();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DismissApprovalRequestMessage.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDismissApprovalRequestMessage(
            obj as api.DismissApprovalRequestMessage);

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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.dismiss(arg_request, arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).projects.approvalRequests;
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
        var resp = convert.json.encode(buildApprovalRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkApprovalRequest(response as api.ApprovalRequest);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AccessApprovalApi(mock).projects.approvalRequests;
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
        var resp = convert.json.encode(buildListApprovalRequestsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListApprovalRequestsResponse(
          response as api.ListApprovalRequestsResponse);
    });
  });
}

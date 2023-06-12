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

import 'package:googleapis/mybusinessaccountmanagement/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAcceptInvitationRequest = 0;
api.AcceptInvitationRequest buildAcceptInvitationRequest() {
  var o = api.AcceptInvitationRequest();
  buildCounterAcceptInvitationRequest++;
  if (buildCounterAcceptInvitationRequest < 3) {}
  buildCounterAcceptInvitationRequest--;
  return o;
}

void checkAcceptInvitationRequest(api.AcceptInvitationRequest o) {
  buildCounterAcceptInvitationRequest++;
  if (buildCounterAcceptInvitationRequest < 3) {}
  buildCounterAcceptInvitationRequest--;
}

core.int buildCounterAccount = 0;
api.Account buildAccount() {
  var o = api.Account();
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    o.accountName = 'foo';
    o.accountNumber = 'foo';
    o.name = 'foo';
    o.organizationInfo = buildOrganizationInfo();
    o.permissionLevel = 'foo';
    o.primaryOwner = 'foo';
    o.role = 'foo';
    o.type = 'foo';
    o.verificationState = 'foo';
    o.vettedState = 'foo';
  }
  buildCounterAccount--;
  return o;
}

void checkAccount(api.Account o) {
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    unittest.expect(
      o.accountName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.accountNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOrganizationInfo(o.organizationInfo! as api.OrganizationInfo);
    unittest.expect(
      o.permissionLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.primaryOwner!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vettedState!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccount--;
}

core.int buildCounterAdmin = 0;
api.Admin buildAdmin() {
  var o = api.Admin();
  buildCounterAdmin++;
  if (buildCounterAdmin < 3) {
    o.admin = 'foo';
    o.name = 'foo';
    o.pendingInvitation = true;
    o.role = 'foo';
  }
  buildCounterAdmin--;
  return o;
}

void checkAdmin(api.Admin o) {
  buildCounterAdmin++;
  if (buildCounterAdmin < 3) {
    unittest.expect(
      o.admin!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.pendingInvitation!, unittest.isTrue);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdmin--;
}

core.int buildCounterDeclineInvitationRequest = 0;
api.DeclineInvitationRequest buildDeclineInvitationRequest() {
  var o = api.DeclineInvitationRequest();
  buildCounterDeclineInvitationRequest++;
  if (buildCounterDeclineInvitationRequest < 3) {}
  buildCounterDeclineInvitationRequest--;
  return o;
}

void checkDeclineInvitationRequest(api.DeclineInvitationRequest o) {
  buildCounterDeclineInvitationRequest++;
  if (buildCounterDeclineInvitationRequest < 3) {}
  buildCounterDeclineInvitationRequest--;
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

core.int buildCounterInvitation = 0;
api.Invitation buildInvitation() {
  var o = api.Invitation();
  buildCounterInvitation++;
  if (buildCounterInvitation < 3) {
    o.name = 'foo';
    o.role = 'foo';
    o.targetAccount = buildAccount();
    o.targetLocation = buildTargetLocation();
    o.targetType = 'foo';
  }
  buildCounterInvitation--;
  return o;
}

void checkInvitation(api.Invitation o) {
  buildCounterInvitation++;
  if (buildCounterInvitation < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
    checkAccount(o.targetAccount! as api.Account);
    checkTargetLocation(o.targetLocation! as api.TargetLocation);
    unittest.expect(
      o.targetType!,
      unittest.equals('foo'),
    );
  }
  buildCounterInvitation--;
}

core.List<api.Admin> buildUnnamed5422() {
  var o = <api.Admin>[];
  o.add(buildAdmin());
  o.add(buildAdmin());
  return o;
}

void checkUnnamed5422(core.List<api.Admin> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdmin(o[0] as api.Admin);
  checkAdmin(o[1] as api.Admin);
}

core.int buildCounterListAccountAdminsResponse = 0;
api.ListAccountAdminsResponse buildListAccountAdminsResponse() {
  var o = api.ListAccountAdminsResponse();
  buildCounterListAccountAdminsResponse++;
  if (buildCounterListAccountAdminsResponse < 3) {
    o.accountAdmins = buildUnnamed5422();
  }
  buildCounterListAccountAdminsResponse--;
  return o;
}

void checkListAccountAdminsResponse(api.ListAccountAdminsResponse o) {
  buildCounterListAccountAdminsResponse++;
  if (buildCounterListAccountAdminsResponse < 3) {
    checkUnnamed5422(o.accountAdmins!);
  }
  buildCounterListAccountAdminsResponse--;
}

core.List<api.Account> buildUnnamed5423() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed5423(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterListAccountsResponse = 0;
api.ListAccountsResponse buildListAccountsResponse() {
  var o = api.ListAccountsResponse();
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    o.accounts = buildUnnamed5423();
    o.nextPageToken = 'foo';
  }
  buildCounterListAccountsResponse--;
  return o;
}

void checkListAccountsResponse(api.ListAccountsResponse o) {
  buildCounterListAccountsResponse++;
  if (buildCounterListAccountsResponse < 3) {
    checkUnnamed5423(o.accounts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAccountsResponse--;
}

core.List<api.Invitation> buildUnnamed5424() {
  var o = <api.Invitation>[];
  o.add(buildInvitation());
  o.add(buildInvitation());
  return o;
}

void checkUnnamed5424(core.List<api.Invitation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInvitation(o[0] as api.Invitation);
  checkInvitation(o[1] as api.Invitation);
}

core.int buildCounterListInvitationsResponse = 0;
api.ListInvitationsResponse buildListInvitationsResponse() {
  var o = api.ListInvitationsResponse();
  buildCounterListInvitationsResponse++;
  if (buildCounterListInvitationsResponse < 3) {
    o.invitations = buildUnnamed5424();
  }
  buildCounterListInvitationsResponse--;
  return o;
}

void checkListInvitationsResponse(api.ListInvitationsResponse o) {
  buildCounterListInvitationsResponse++;
  if (buildCounterListInvitationsResponse < 3) {
    checkUnnamed5424(o.invitations!);
  }
  buildCounterListInvitationsResponse--;
}

core.List<api.Admin> buildUnnamed5425() {
  var o = <api.Admin>[];
  o.add(buildAdmin());
  o.add(buildAdmin());
  return o;
}

void checkUnnamed5425(core.List<api.Admin> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdmin(o[0] as api.Admin);
  checkAdmin(o[1] as api.Admin);
}

core.int buildCounterListLocationAdminsResponse = 0;
api.ListLocationAdminsResponse buildListLocationAdminsResponse() {
  var o = api.ListLocationAdminsResponse();
  buildCounterListLocationAdminsResponse++;
  if (buildCounterListLocationAdminsResponse < 3) {
    o.admins = buildUnnamed5425();
  }
  buildCounterListLocationAdminsResponse--;
  return o;
}

void checkListLocationAdminsResponse(api.ListLocationAdminsResponse o) {
  buildCounterListLocationAdminsResponse++;
  if (buildCounterListLocationAdminsResponse < 3) {
    checkUnnamed5425(o.admins!);
  }
  buildCounterListLocationAdminsResponse--;
}

core.int buildCounterOrganizationInfo = 0;
api.OrganizationInfo buildOrganizationInfo() {
  var o = api.OrganizationInfo();
  buildCounterOrganizationInfo++;
  if (buildCounterOrganizationInfo < 3) {
    o.address = buildPostalAddress();
    o.phoneNumber = 'foo';
    o.registeredDomain = 'foo';
  }
  buildCounterOrganizationInfo--;
  return o;
}

void checkOrganizationInfo(api.OrganizationInfo o) {
  buildCounterOrganizationInfo++;
  if (buildCounterOrganizationInfo < 3) {
    checkPostalAddress(o.address! as api.PostalAddress);
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.registeredDomain!,
      unittest.equals('foo'),
    );
  }
  buildCounterOrganizationInfo--;
}

core.List<core.String> buildUnnamed5426() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5426(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5427() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5427(core.List<core.String> o) {
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

core.int buildCounterPostalAddress = 0;
api.PostalAddress buildPostalAddress() {
  var o = api.PostalAddress();
  buildCounterPostalAddress++;
  if (buildCounterPostalAddress < 3) {
    o.addressLines = buildUnnamed5426();
    o.administrativeArea = 'foo';
    o.languageCode = 'foo';
    o.locality = 'foo';
    o.organization = 'foo';
    o.postalCode = 'foo';
    o.recipients = buildUnnamed5427();
    o.regionCode = 'foo';
    o.revision = 42;
    o.sortingCode = 'foo';
    o.sublocality = 'foo';
  }
  buildCounterPostalAddress--;
  return o;
}

void checkPostalAddress(api.PostalAddress o) {
  buildCounterPostalAddress++;
  if (buildCounterPostalAddress < 3) {
    checkUnnamed5426(o.addressLines!);
    unittest.expect(
      o.administrativeArea!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locality!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.organization!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postalCode!,
      unittest.equals('foo'),
    );
    checkUnnamed5427(o.recipients!);
    unittest.expect(
      o.regionCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revision!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sortingCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sublocality!,
      unittest.equals('foo'),
    );
  }
  buildCounterPostalAddress--;
}

core.int buildCounterTargetLocation = 0;
api.TargetLocation buildTargetLocation() {
  var o = api.TargetLocation();
  buildCounterTargetLocation++;
  if (buildCounterTargetLocation < 3) {
    o.address = 'foo';
    o.locationName = 'foo';
  }
  buildCounterTargetLocation--;
  return o;
}

void checkTargetLocation(api.TargetLocation o) {
  buildCounterTargetLocation++;
  if (buildCounterTargetLocation < 3) {
    unittest.expect(
      o.address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationName!,
      unittest.equals('foo'),
    );
  }
  buildCounterTargetLocation--;
}

core.int buildCounterTransferLocationRequest = 0;
api.TransferLocationRequest buildTransferLocationRequest() {
  var o = api.TransferLocationRequest();
  buildCounterTransferLocationRequest++;
  if (buildCounterTransferLocationRequest < 3) {
    o.destinationAccount = 'foo';
  }
  buildCounterTransferLocationRequest--;
  return o;
}

void checkTransferLocationRequest(api.TransferLocationRequest o) {
  buildCounterTransferLocationRequest++;
  if (buildCounterTransferLocationRequest < 3) {
    unittest.expect(
      o.destinationAccount!,
      unittest.equals('foo'),
    );
  }
  buildCounterTransferLocationRequest--;
}

void main() {
  unittest.group('obj-schema-AcceptInvitationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAcceptInvitationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AcceptInvitationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAcceptInvitationRequest(od as api.AcceptInvitationRequest);
    });
  });

  unittest.group('obj-schema-Account', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Account.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAccount(od as api.Account);
    });
  });

  unittest.group('obj-schema-Admin', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdmin();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Admin.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdmin(od as api.Admin);
    });
  });

  unittest.group('obj-schema-DeclineInvitationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeclineInvitationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeclineInvitationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeclineInvitationRequest(od as api.DeclineInvitationRequest);
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

  unittest.group('obj-schema-Invitation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInvitation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Invitation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInvitation(od as api.Invitation);
    });
  });

  unittest.group('obj-schema-ListAccountAdminsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAccountAdminsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAccountAdminsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAccountAdminsResponse(od as api.ListAccountAdminsResponse);
    });
  });

  unittest.group('obj-schema-ListAccountsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAccountsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAccountsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAccountsResponse(od as api.ListAccountsResponse);
    });
  });

  unittest.group('obj-schema-ListInvitationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInvitationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInvitationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInvitationsResponse(od as api.ListInvitationsResponse);
    });
  });

  unittest.group('obj-schema-ListLocationAdminsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLocationAdminsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLocationAdminsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLocationAdminsResponse(od as api.ListLocationAdminsResponse);
    });
  });

  unittest.group('obj-schema-OrganizationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrganizationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OrganizationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrganizationInfo(od as api.OrganizationInfo);
    });
  });

  unittest.group('obj-schema-PostalAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPostalAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PostalAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPostalAddress(od as api.PostalAddress);
    });
  });

  unittest.group('obj-schema-TargetLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetLocation(od as api.TargetLocation);
    });
  });

  unittest.group('obj-schema-TransferLocationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTransferLocationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TransferLocationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTransferLocationRequest(od as api.TransferLocationRequest);
    });
  });

  unittest.group('resource-AccountsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts;
      var arg_request = buildAccount();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Account.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAccount(obj as api.Account);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/accounts"),
        );
        pathOffset += 11;

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
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts;
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
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts;
      var arg_filter = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_parentAccount = 'foo';
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/accounts"),
        );
        pathOffset += 11;

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
          queryMap["parentAccount"]!.first,
          unittest.equals(arg_parentAccount),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          parentAccount: arg_parentAccount,
          $fields: arg_$fields);
      checkListAccountsResponse(response as api.ListAccountsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts;
      var arg_request = buildAccount();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_validateOnly = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Account.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAccount(obj as api.Account);

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
          queryMap["validateOnly"]!.first,
          unittest.equals("$arg_validateOnly"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask,
          validateOnly: arg_validateOnly,
          $fields: arg_$fields);
      checkAccount(response as api.Account);
    });
  });

  unittest.group('resource-AccountsAdminsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts.admins;
      var arg_request = buildAdmin();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Admin.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAdmin(obj as api.Admin);

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
        var resp = convert.json.encode(buildAdmin());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkAdmin(response as api.Admin);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts.admins;
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

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts.admins;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListAccountAdminsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkListAccountAdminsResponse(response as api.ListAccountAdminsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts.admins;
      var arg_request = buildAdmin();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Admin.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAdmin(obj as api.Admin);

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
        var resp = convert.json.encode(buildAdmin());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAdmin(response as api.Admin);
    });
  });

  unittest.group('resource-AccountsInvitationsResource', () {
    unittest.test('method--accept', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts.invitations;
      var arg_request = buildAcceptInvitationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AcceptInvitationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAcceptInvitationRequest(obj as api.AcceptInvitationRequest);

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
      final response =
          await res.accept(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--decline', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts.invitations;
      var arg_request = buildDeclineInvitationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeclineInvitationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeclineInvitationRequest(obj as api.DeclineInvitationRequest);

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
      final response =
          await res.decline(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).accounts.invitations;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListInvitationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_parent, filter: arg_filter, $fields: arg_$fields);
      checkListInvitationsResponse(response as api.ListInvitationsResponse);
    });
  });

  unittest.group('resource-LocationsResource', () {
    unittest.test('method--transfer', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).locations;
      var arg_request = buildTransferLocationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TransferLocationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTransferLocationRequest(obj as api.TransferLocationRequest);

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
      final response =
          await res.transfer(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });
  });

  unittest.group('resource-LocationsAdminsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).locations.admins;
      var arg_request = buildAdmin();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Admin.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAdmin(obj as api.Admin);

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
        var resp = convert.json.encode(buildAdmin());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkAdmin(response as api.Admin);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).locations.admins;
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

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).locations.admins;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListLocationAdminsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkListLocationAdminsResponse(
          response as api.ListLocationAdminsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessAccountManagementApi(mock).locations.admins;
      var arg_request = buildAdmin();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Admin.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAdmin(obj as api.Admin);

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
        var resp = convert.json.encode(buildAdmin());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAdmin(response as api.Admin);
    });
  });
}

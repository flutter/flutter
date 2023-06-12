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

import 'package:googleapis/groupssettings/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterGroups = 0;
api.Groups buildGroups() {
  var o = api.Groups();
  buildCounterGroups++;
  if (buildCounterGroups < 3) {
    o.allowExternalMembers = 'foo';
    o.allowGoogleCommunication = 'foo';
    o.allowWebPosting = 'foo';
    o.archiveOnly = 'foo';
    o.customFooterText = 'foo';
    o.customReplyTo = 'foo';
    o.customRolesEnabledForSettingsToBeMerged = 'foo';
    o.defaultMessageDenyNotificationText = 'foo';
    o.description = 'foo';
    o.email = 'foo';
    o.enableCollaborativeInbox = 'foo';
    o.favoriteRepliesOnTop = 'foo';
    o.includeCustomFooter = 'foo';
    o.includeInGlobalAddressList = 'foo';
    o.isArchived = 'foo';
    o.kind = 'foo';
    o.maxMessageBytes = 42;
    o.membersCanPostAsTheGroup = 'foo';
    o.messageDisplayFont = 'foo';
    o.messageModerationLevel = 'foo';
    o.name = 'foo';
    o.primaryLanguage = 'foo';
    o.replyTo = 'foo';
    o.sendMessageDenyNotification = 'foo';
    o.showInGroupDirectory = 'foo';
    o.spamModerationLevel = 'foo';
    o.whoCanAdd = 'foo';
    o.whoCanAddReferences = 'foo';
    o.whoCanApproveMembers = 'foo';
    o.whoCanApproveMessages = 'foo';
    o.whoCanAssignTopics = 'foo';
    o.whoCanAssistContent = 'foo';
    o.whoCanBanUsers = 'foo';
    o.whoCanContactOwner = 'foo';
    o.whoCanDeleteAnyPost = 'foo';
    o.whoCanDeleteTopics = 'foo';
    o.whoCanDiscoverGroup = 'foo';
    o.whoCanEnterFreeFormTags = 'foo';
    o.whoCanHideAbuse = 'foo';
    o.whoCanInvite = 'foo';
    o.whoCanJoin = 'foo';
    o.whoCanLeaveGroup = 'foo';
    o.whoCanLockTopics = 'foo';
    o.whoCanMakeTopicsSticky = 'foo';
    o.whoCanMarkDuplicate = 'foo';
    o.whoCanMarkFavoriteReplyOnAnyTopic = 'foo';
    o.whoCanMarkFavoriteReplyOnOwnTopic = 'foo';
    o.whoCanMarkNoResponseNeeded = 'foo';
    o.whoCanModerateContent = 'foo';
    o.whoCanModerateMembers = 'foo';
    o.whoCanModifyMembers = 'foo';
    o.whoCanModifyTagsAndCategories = 'foo';
    o.whoCanMoveTopicsIn = 'foo';
    o.whoCanMoveTopicsOut = 'foo';
    o.whoCanPostAnnouncements = 'foo';
    o.whoCanPostMessage = 'foo';
    o.whoCanTakeTopics = 'foo';
    o.whoCanUnassignTopic = 'foo';
    o.whoCanUnmarkFavoriteReplyOnAnyTopic = 'foo';
    o.whoCanViewGroup = 'foo';
    o.whoCanViewMembership = 'foo';
  }
  buildCounterGroups--;
  return o;
}

void checkGroups(api.Groups o) {
  buildCounterGroups++;
  if (buildCounterGroups < 3) {
    unittest.expect(
      o.allowExternalMembers!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.allowGoogleCommunication!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.allowWebPosting!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.archiveOnly!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customFooterText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customReplyTo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customRolesEnabledForSettingsToBeMerged!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultMessageDenyNotificationText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.enableCollaborativeInbox!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.favoriteRepliesOnTop!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.includeCustomFooter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.includeInGlobalAddressList!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.isArchived!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxMessageBytes!,
      unittest.equals(42),
    );
    unittest.expect(
      o.membersCanPostAsTheGroup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.messageDisplayFont!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.messageModerationLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.primaryLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.replyTo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sendMessageDenyNotification!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.showInGroupDirectory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.spamModerationLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanAdd!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanAddReferences!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanApproveMembers!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanApproveMessages!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanAssignTopics!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanAssistContent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanBanUsers!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanContactOwner!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanDeleteAnyPost!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanDeleteTopics!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanDiscoverGroup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanEnterFreeFormTags!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanHideAbuse!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanInvite!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanJoin!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanLeaveGroup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanLockTopics!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanMakeTopicsSticky!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanMarkDuplicate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanMarkFavoriteReplyOnAnyTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanMarkFavoriteReplyOnOwnTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanMarkNoResponseNeeded!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanModerateContent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanModerateMembers!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanModifyMembers!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanModifyTagsAndCategories!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanMoveTopicsIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanMoveTopicsOut!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanPostAnnouncements!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanPostMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanTakeTopics!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanUnassignTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanUnmarkFavoriteReplyOnAnyTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanViewGroup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.whoCanViewMembership!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroups--;
}

void main() {
  unittest.group('obj-schema-Groups', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroups();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Groups.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGroups(od as api.Groups);
    });
  });

  unittest.group('resource-GroupsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GroupssettingsApi(mock).groups;
      var arg_groupUniqueId = 'foo';
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
        var resp = convert.json.encode(buildGroups());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_groupUniqueId, $fields: arg_$fields);
      checkGroups(response as api.Groups);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.GroupssettingsApi(mock).groups;
      var arg_request = buildGroups();
      var arg_groupUniqueId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Groups.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGroups(obj as api.Groups);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;

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
        var resp = convert.json.encode(buildGroups());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_groupUniqueId, $fields: arg_$fields);
      checkGroups(response as api.Groups);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.GroupssettingsApi(mock).groups;
      var arg_request = buildGroups();
      var arg_groupUniqueId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Groups.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGroups(obj as api.Groups);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;

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
        var resp = convert.json.encode(buildGroups());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_groupUniqueId,
          $fields: arg_$fields);
      checkGroups(response as api.Groups);
    });
  });
}

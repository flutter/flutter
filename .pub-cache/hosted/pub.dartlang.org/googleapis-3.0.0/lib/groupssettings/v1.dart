// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Groups Settings API - v1
///
/// Manages permission levels and related settings of a group.
///
/// For more information, see
/// <https://developers.google.com/google-apps/groups-settings/get_started>
///
/// Create an instance of [GroupssettingsApi] to access these resources:
///
/// - [GroupsResource]
library groupssettings.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Manages permission levels and related settings of a group.
class GroupssettingsApi {
  /// View and manage the settings of a G Suite group
  static const appsGroupsSettingsScope =
      'https://www.googleapis.com/auth/apps.groups.settings';

  final commons.ApiRequester _requester;

  GroupsResource get groups => GroupsResource(_requester);

  GroupssettingsApi(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = 'groups/v1/groups/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class GroupsResource {
  final commons.ApiRequester _requester;

  GroupsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one resource by id.
  ///
  /// Request parameters:
  ///
  /// [groupUniqueId] - The group's email address.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Groups].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Groups> get(
    core.String groupUniqueId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$groupUniqueId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Groups.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing resource.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupUniqueId] - The group's email address.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Groups].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Groups> patch(
    Groups request,
    core.String groupUniqueId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$groupUniqueId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Groups.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupUniqueId] - The group's email address.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Groups].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Groups> update(
    Groups request,
    core.String groupUniqueId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$groupUniqueId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Groups.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// JSON template for Group resource
class Groups {
  /// Identifies whether members external to your organization can join the
  /// group.
  ///
  /// Possible values are:
  /// - true: G Suite users external to your organization can become members of
  /// this group.
  /// - false: Users not belonging to the organization are not allowed to become
  /// members of this group.
  core.String? allowExternalMembers;

  /// Allows Google to contact administrator of the group.
  ///
  ///
  /// - true: Allow Google to contact managers of this group. Occasionally
  /// Google may send updates on the latest features, ask for input on new
  /// features, or ask for permission to highlight your group.
  /// - false: Google can not contact managers of this group.
  ///
  /// Deprecated.
  core.String? allowGoogleCommunication;

  /// Allows posting from web.
  ///
  /// Possible values are:
  /// - true: Allows any member to post to the group forum.
  /// - false: Members only use Gmail to communicate with the group.
  core.String? allowWebPosting;

  /// Allows the group to be archived only.
  ///
  /// Possible values are:
  /// - true: Group is archived and the group is inactive. New messages to this
  /// group are rejected. The older archived messages are browseable and
  /// searchable.
  /// - If true, the whoCanPostMessage property is set to NONE_CAN_POST.
  /// - If reverted from true to false, whoCanPostMessages is set to
  /// ALL_MANAGERS_CAN_POST.
  /// - false: The group is active and can receive messages.
  /// - When false, updating whoCanPostMessage to NONE_CAN_POST, results in an
  /// error.
  core.String? archiveOnly;

  /// Set the content of custom footer text.
  ///
  /// The maximum number of characters is 1,000.
  core.String? customFooterText;

  /// An email address used when replying to a message if the replyTo property
  /// is set to REPLY_TO_CUSTOM.
  ///
  /// This address is defined by an account administrator.
  /// - When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the
  /// customReplyTo property holds a custom email address used when replying to
  /// a message.
  /// - If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the
  /// customReplyTo property must have a text value or an error is returned.
  core.String? customReplyTo;

  /// Specifies whether the group has a custom role that's included in one of
  /// the settings being merged.
  ///
  /// This field is read-only and update/patch requests to it are ignored.
  /// Possible values are:
  /// - true
  /// - false
  core.String? customRolesEnabledForSettingsToBeMerged;

  /// When a message is rejected, this is text for the rejection notification
  /// sent to the message's author.
  ///
  /// By default, this property is empty and has no value in the API's response
  /// body. The maximum notification text size is 10,000 characters. Note:
  /// Requires sendMessageDenyNotification property to be true.
  core.String? defaultMessageDenyNotificationText;

  /// Description of the group.
  ///
  /// This property value may be an empty string if no group description has
  /// been entered. If entered, the maximum group description is no more than
  /// 300 characters.
  core.String? description;

  /// The group's email address.
  ///
  /// This property can be updated using the Directory API. Note: Only a group
  /// owner can change a group's email address. A group manager can't do this.
  /// When you change your group's address using the Directory API or the
  /// control panel, you are changing the address your subscribers use to send
  /// email and the web address people use to access your group. People can't
  /// reach your group by visiting the old address.
  core.String? email;

  /// Specifies whether a collaborative inbox will remain turned on for the
  /// group.
  ///
  /// Possible values are:
  /// - true
  /// - false
  core.String? enableCollaborativeInbox;

  /// Indicates if favorite replies should be displayed above other replies.
  ///
  ///
  /// - true: Favorite replies will be displayed above other replies.
  /// - false: Favorite replies will not be displayed above other replies.
  core.String? favoriteRepliesOnTop;

  /// Whether to include custom footer.
  ///
  /// Possible values are:
  /// - true
  /// - false
  core.String? includeCustomFooter;

  /// Enables the group to be included in the Global Address List.
  ///
  /// For more information, see the help center. Possible values are:
  /// - true: Group is included in the Global Address List.
  /// - false: Group is not included in the Global Address List.
  core.String? includeInGlobalAddressList;

  /// Allows the Group contents to be archived.
  ///
  /// Possible values are:
  /// - true: Archive messages sent to the group.
  /// - false: Do not keep an archive of messages sent to this group. If false,
  /// previously archived messages remain in the archive.
  core.String? isArchived;

  /// The type of the resource.
  ///
  /// It is always groupsSettings#groups.
  core.String? kind;

  /// The maximum size of a message is 25Mb.
  ///
  /// Deprecated.
  core.int? maxMessageBytes;

  /// Enables members to post messages as the group.
  ///
  /// Possible values are:
  /// - true: Group member can post messages using the group's email address
  /// instead of their own email address. Message appear to originate from the
  /// group itself. Note: When true, any message moderation settings on
  /// individual users or new members do not apply to posts made on behalf of
  /// the group.
  /// - false: Members can not post in behalf of the group's email address.
  core.String? membersCanPostAsTheGroup;

  /// The default message display font always has a value of "DEFAULT_FONT".
  ///
  /// Deprecated.
  core.String? messageDisplayFont;

  /// Moderation level of incoming messages.
  ///
  /// Possible values are:
  /// - MODERATE_ALL_MESSAGES: All messages are sent to the group owner's email
  /// address for approval. If approved, the message is sent to the group.
  /// - MODERATE_NON_MEMBERS: All messages from non group members are sent to
  /// the group owner's email address for approval. If approved, the message is
  /// sent to the group.
  /// - MODERATE_NEW_MEMBERS: All messages from new members are sent to the
  /// group owner's email address for approval. If approved, the message is sent
  /// to the group.
  /// - MODERATE_NONE: No moderator approval is required. Messages are delivered
  /// directly to the group. Note: When the whoCanPostMessage is set to
  /// ANYONE_CAN_POST, we recommend the messageModerationLevel be set to
  /// MODERATE_NON_MEMBERS to protect the group from possible spam.
  /// When memberCanPostAsTheGroup is true, any message moderation settings on
  /// individual users or new members will not apply to posts made on behalf of
  /// the group.
  core.String? messageModerationLevel;

  /// Name of the group, which has a maximum size of 75 characters.
  core.String? name;

  /// The primary language for group.
  ///
  /// For a group's primary language use the language tags from the G Suite
  /// languages found at G Suite Email Settings API Email Language Tags.
  core.String? primaryLanguage;

  /// Specifies who receives the default reply.
  ///
  /// Possible values are:
  /// - REPLY_TO_CUSTOM: For replies to messages, use the group's custom email
  /// address.
  /// When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the
  /// customReplyTo property holds the custom email address used when replying
  /// to a message. If the group's ReplyTo property is set to REPLY_TO_CUSTOM,
  /// the customReplyTo property must have a value. Otherwise an error is
  /// returned.
  ///
  /// - REPLY_TO_SENDER: The reply sent to author of message.
  /// - REPLY_TO_LIST: This reply message is sent to the group.
  /// - REPLY_TO_OWNER: The reply is sent to the owner(s) of the group. This
  /// does not include the group's managers.
  /// - REPLY_TO_IGNORE: Group users individually decide where the message reply
  /// is sent.
  /// - REPLY_TO_MANAGERS: This reply message is sent to the group's managers,
  /// which includes all managers and the group owner.
  core.String? replyTo;

  /// Allows a member to be notified if the member's message to the group is
  /// denied by the group owner.
  ///
  /// Possible values are:
  /// - true: When a message is rejected, send the deny message notification to
  /// the message author.
  /// The defaultMessageDenyNotificationText property is dependent on the
  /// sendMessageDenyNotification property being true.
  ///
  /// - false: When a message is rejected, no notification is sent.
  core.String? sendMessageDenyNotification;

  /// This is merged into the new whoCanDiscoverGroup setting.
  ///
  /// Allows the group to be visible in the Groups Directory. Possible values
  /// are:
  /// - true: All groups in the account are listed in the Groups directory.
  /// - false: All groups in the account are not listed in the directory.
  ///
  /// Deprecated.
  core.String? showInGroupDirectory;

  /// Specifies moderation levels for messages detected as spam.
  ///
  /// Possible values are:
  /// - ALLOW: Post the message to the group.
  /// - MODERATE: Send the message to the moderation queue. This is the default.
  /// - SILENTLY_MODERATE: Send the message to the moderation queue, but do not
  /// send notification to moderators.
  /// - REJECT: Immediately reject the message.
  core.String? spamModerationLevel;

  /// This is merged into the new whoCanModerateMembers setting.
  ///
  /// Permissions to add members. Possible values are:
  /// - ALL_MEMBERS_CAN_ADD: Managers and members can directly add new members.
  /// - ALL_MANAGERS_CAN_ADD: Only managers can directly add new members. this
  /// includes the group's owner.
  /// - ALL_OWNERS_CAN_ADD: Only owners can directly add new members.
  /// - NONE_CAN_ADD: No one can directly add new members.
  ///
  /// Deprecated.
  core.String? whoCanAdd;

  /// This functionality is no longer supported in the Google Groups UI.
  ///
  /// The value is always "NONE".
  ///
  /// Deprecated.
  core.String? whoCanAddReferences;

  /// Specifies who can approve members who ask to join groups.
  ///
  /// This permission will be deprecated once it is merged into the new
  /// whoCanModerateMembers setting. Possible values are:
  /// - ALL_MEMBERS_CAN_APPROVE
  /// - ALL_MANAGERS_CAN_APPROVE
  /// - ALL_OWNERS_CAN_APPROVE
  /// - NONE_CAN_APPROVE
  core.String? whoCanApproveMembers;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can approve pending messages in the moderation queue.
  /// Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanApproveMessages;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to assign topics in a forum to another user. Possible values
  /// are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanAssignTopics;

  /// Specifies who can moderate metadata.
  ///
  /// Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  core.String? whoCanAssistContent;

  /// Specifies who can deny membership to users.
  ///
  /// This permission will be deprecated once it is merged into the new
  /// whoCanModerateMembers setting. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  core.String? whoCanBanUsers;

  /// Permission to contact owner of the group via web UI.
  ///
  /// Possible values are:
  /// - ALL_IN_DOMAIN_CAN_CONTACT
  /// - ALL_MANAGERS_CAN_CONTACT
  /// - ALL_MEMBERS_CAN_CONTACT
  /// - ANYONE_CAN_CONTACT
  /// - ALL_OWNERS_CAN_CONTACT
  core.String? whoCanContactOwner;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can delete replies to topics. (Authors can always delete
  /// their own posts). Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanDeleteAnyPost;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can delete topics. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanDeleteTopics;

  /// Specifies the set of users for whom this group is discoverable.
  ///
  /// Possible values are:
  /// - ANYONE_CAN_DISCOVER
  /// - ALL_IN_DOMAIN_CAN_DISCOVER
  /// - ALL_MEMBERS_CAN_DISCOVER
  core.String? whoCanDiscoverGroup;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to enter free form tags for topics in a forum. Possible values
  /// are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanEnterFreeFormTags;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can hide posts by reporting them as abuse. Possible values
  /// are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanHideAbuse;

  /// This is merged into the new whoCanModerateMembers setting.
  ///
  /// Permissions to invite new members. Possible values are:
  /// - ALL_MEMBERS_CAN_INVITE: Managers and members can invite a new member
  /// candidate.
  /// - ALL_MANAGERS_CAN_INVITE: Only managers can invite a new member. This
  /// includes the group's owner.
  /// - ALL_OWNERS_CAN_INVITE: Only owners can invite a new member.
  /// - NONE_CAN_INVITE: No one can invite a new member candidate.
  ///
  /// Deprecated.
  core.String? whoCanInvite;

  /// Permission to join group.
  ///
  /// Possible values are:
  /// - ANYONE_CAN_JOIN: Anyone in the account domain can join. This includes
  /// accounts with multiple domains.
  /// - ALL_IN_DOMAIN_CAN_JOIN: Any Internet user who is outside your domain can
  /// access your Google Groups service and view the list of groups in your
  /// Groups directory. Warning: Group owners can add external addresses,
  /// outside of the domain to their groups. They can also allow people outside
  /// your domain to join their groups. If you later disable this option, any
  /// external addresses already added to users' groups remain in those groups.
  /// - INVITED_CAN_JOIN: Candidates for membership can be invited to join.
  /// - CAN_REQUEST_TO_JOIN: Non members can request an invitation to join.
  core.String? whoCanJoin;

  /// Permission to leave the group.
  ///
  /// Possible values are:
  /// - ALL_MANAGERS_CAN_LEAVE
  /// - ALL_MEMBERS_CAN_LEAVE
  /// - NONE_CAN_LEAVE
  core.String? whoCanLeaveGroup;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can prevent users from posting replies to topics. Possible
  /// values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanLockTopics;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can make topics appear at the top of the topic list.
  /// Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanMakeTopicsSticky;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to mark a topic as a duplicate of another topic. Possible
  /// values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanMarkDuplicate;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to mark any other user's post as a favorite reply. Possible
  /// values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanMarkFavoriteReplyOnAnyTopic;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to mark a post for a topic they started as a favorite reply.
  /// Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanMarkFavoriteReplyOnOwnTopic;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to mark a topic as not needing a response. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanMarkNoResponseNeeded;

  /// Specifies who can moderate content.
  ///
  /// Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  core.String? whoCanModerateContent;

  /// Specifies who can manage members.
  ///
  /// Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  core.String? whoCanModerateMembers;

  /// This is merged into the new whoCanModerateMembers setting.
  ///
  /// Specifies who can change group members' roles. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanModifyMembers;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to change tags and categories. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanModifyTagsAndCategories;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can move topics into the group or forum. Possible values
  /// are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanMoveTopicsIn;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can move topics out of the group or forum. Possible values
  /// are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanMoveTopicsOut;

  /// This is merged into the new whoCanModerateContent setting.
  ///
  /// Specifies who can post announcements, a special topic type. Possible
  /// values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanPostAnnouncements;

  /// Permissions to post messages.
  ///
  /// Possible values are:
  /// - NONE_CAN_POST: The group is disabled and archived. No one can post a
  /// message to this group.
  /// - When archiveOnly is false, updating whoCanPostMessage to NONE_CAN_POST,
  /// results in an error.
  /// - If archiveOnly is reverted from true to false, whoCanPostMessages is set
  /// to ALL_MANAGERS_CAN_POST.
  /// - ALL_MANAGERS_CAN_POST: Managers, including group owners, can post
  /// messages.
  /// - ALL_MEMBERS_CAN_POST: Any group member can post a message.
  /// - ALL_OWNERS_CAN_POST: Only group owners can post a message.
  /// - ALL_IN_DOMAIN_CAN_POST: Anyone in the account can post a message.
  /// - ANYONE_CAN_POST: Any Internet user who outside your account can access
  /// your Google Groups service and post a message. Note: When
  /// whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the
  /// messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group
  /// from possible spam.
  core.String? whoCanPostMessage;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to take topics in a forum. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanTakeTopics;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to unassign any topic in a forum. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanUnassignTopic;

  /// This is merged into the new whoCanAssistContent setting.
  ///
  /// Permission to unmark any post from a favorite reply. Possible values are:
  /// - ALL_MEMBERS
  /// - OWNERS_AND_MANAGERS
  /// - MANAGERS_ONLY
  /// - OWNERS_ONLY
  /// - NONE
  ///
  /// Deprecated.
  core.String? whoCanUnmarkFavoriteReplyOnAnyTopic;

  /// Permissions to view group messages.
  ///
  /// Possible values are:
  /// - ANYONE_CAN_VIEW: Any Internet user can view the group's messages.
  /// - ALL_IN_DOMAIN_CAN_VIEW: Anyone in your account can view this group's
  /// messages.
  /// - ALL_MEMBERS_CAN_VIEW: All group members can view the group's messages.
  /// - ALL_MANAGERS_CAN_VIEW: Any group manager can view this group's messages.
  core.String? whoCanViewGroup;

  /// Permissions to view membership.
  ///
  /// Possible values are:
  /// - ALL_IN_DOMAIN_CAN_VIEW: Anyone in the account can view the group members
  /// list.
  /// If a group already has external members, those members can still send
  /// email to this group.
  ///
  /// - ALL_MEMBERS_CAN_VIEW: The group members can view the group members list.
  /// - ALL_MANAGERS_CAN_VIEW: The group managers can view group members list.
  core.String? whoCanViewMembership;

  Groups();

  Groups.fromJson(core.Map _json) {
    if (_json.containsKey('allowExternalMembers')) {
      allowExternalMembers = _json['allowExternalMembers'] as core.String;
    }
    if (_json.containsKey('allowGoogleCommunication')) {
      allowGoogleCommunication =
          _json['allowGoogleCommunication'] as core.String;
    }
    if (_json.containsKey('allowWebPosting')) {
      allowWebPosting = _json['allowWebPosting'] as core.String;
    }
    if (_json.containsKey('archiveOnly')) {
      archiveOnly = _json['archiveOnly'] as core.String;
    }
    if (_json.containsKey('customFooterText')) {
      customFooterText = _json['customFooterText'] as core.String;
    }
    if (_json.containsKey('customReplyTo')) {
      customReplyTo = _json['customReplyTo'] as core.String;
    }
    if (_json.containsKey('customRolesEnabledForSettingsToBeMerged')) {
      customRolesEnabledForSettingsToBeMerged =
          _json['customRolesEnabledForSettingsToBeMerged'] as core.String;
    }
    if (_json.containsKey('defaultMessageDenyNotificationText')) {
      defaultMessageDenyNotificationText =
          _json['defaultMessageDenyNotificationText'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('enableCollaborativeInbox')) {
      enableCollaborativeInbox =
          _json['enableCollaborativeInbox'] as core.String;
    }
    if (_json.containsKey('favoriteRepliesOnTop')) {
      favoriteRepliesOnTop = _json['favoriteRepliesOnTop'] as core.String;
    }
    if (_json.containsKey('includeCustomFooter')) {
      includeCustomFooter = _json['includeCustomFooter'] as core.String;
    }
    if (_json.containsKey('includeInGlobalAddressList')) {
      includeInGlobalAddressList =
          _json['includeInGlobalAddressList'] as core.String;
    }
    if (_json.containsKey('isArchived')) {
      isArchived = _json['isArchived'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('maxMessageBytes')) {
      maxMessageBytes = _json['maxMessageBytes'] as core.int;
    }
    if (_json.containsKey('membersCanPostAsTheGroup')) {
      membersCanPostAsTheGroup =
          _json['membersCanPostAsTheGroup'] as core.String;
    }
    if (_json.containsKey('messageDisplayFont')) {
      messageDisplayFont = _json['messageDisplayFont'] as core.String;
    }
    if (_json.containsKey('messageModerationLevel')) {
      messageModerationLevel = _json['messageModerationLevel'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('primaryLanguage')) {
      primaryLanguage = _json['primaryLanguage'] as core.String;
    }
    if (_json.containsKey('replyTo')) {
      replyTo = _json['replyTo'] as core.String;
    }
    if (_json.containsKey('sendMessageDenyNotification')) {
      sendMessageDenyNotification =
          _json['sendMessageDenyNotification'] as core.String;
    }
    if (_json.containsKey('showInGroupDirectory')) {
      showInGroupDirectory = _json['showInGroupDirectory'] as core.String;
    }
    if (_json.containsKey('spamModerationLevel')) {
      spamModerationLevel = _json['spamModerationLevel'] as core.String;
    }
    if (_json.containsKey('whoCanAdd')) {
      whoCanAdd = _json['whoCanAdd'] as core.String;
    }
    if (_json.containsKey('whoCanAddReferences')) {
      whoCanAddReferences = _json['whoCanAddReferences'] as core.String;
    }
    if (_json.containsKey('whoCanApproveMembers')) {
      whoCanApproveMembers = _json['whoCanApproveMembers'] as core.String;
    }
    if (_json.containsKey('whoCanApproveMessages')) {
      whoCanApproveMessages = _json['whoCanApproveMessages'] as core.String;
    }
    if (_json.containsKey('whoCanAssignTopics')) {
      whoCanAssignTopics = _json['whoCanAssignTopics'] as core.String;
    }
    if (_json.containsKey('whoCanAssistContent')) {
      whoCanAssistContent = _json['whoCanAssistContent'] as core.String;
    }
    if (_json.containsKey('whoCanBanUsers')) {
      whoCanBanUsers = _json['whoCanBanUsers'] as core.String;
    }
    if (_json.containsKey('whoCanContactOwner')) {
      whoCanContactOwner = _json['whoCanContactOwner'] as core.String;
    }
    if (_json.containsKey('whoCanDeleteAnyPost')) {
      whoCanDeleteAnyPost = _json['whoCanDeleteAnyPost'] as core.String;
    }
    if (_json.containsKey('whoCanDeleteTopics')) {
      whoCanDeleteTopics = _json['whoCanDeleteTopics'] as core.String;
    }
    if (_json.containsKey('whoCanDiscoverGroup')) {
      whoCanDiscoverGroup = _json['whoCanDiscoverGroup'] as core.String;
    }
    if (_json.containsKey('whoCanEnterFreeFormTags')) {
      whoCanEnterFreeFormTags = _json['whoCanEnterFreeFormTags'] as core.String;
    }
    if (_json.containsKey('whoCanHideAbuse')) {
      whoCanHideAbuse = _json['whoCanHideAbuse'] as core.String;
    }
    if (_json.containsKey('whoCanInvite')) {
      whoCanInvite = _json['whoCanInvite'] as core.String;
    }
    if (_json.containsKey('whoCanJoin')) {
      whoCanJoin = _json['whoCanJoin'] as core.String;
    }
    if (_json.containsKey('whoCanLeaveGroup')) {
      whoCanLeaveGroup = _json['whoCanLeaveGroup'] as core.String;
    }
    if (_json.containsKey('whoCanLockTopics')) {
      whoCanLockTopics = _json['whoCanLockTopics'] as core.String;
    }
    if (_json.containsKey('whoCanMakeTopicsSticky')) {
      whoCanMakeTopicsSticky = _json['whoCanMakeTopicsSticky'] as core.String;
    }
    if (_json.containsKey('whoCanMarkDuplicate')) {
      whoCanMarkDuplicate = _json['whoCanMarkDuplicate'] as core.String;
    }
    if (_json.containsKey('whoCanMarkFavoriteReplyOnAnyTopic')) {
      whoCanMarkFavoriteReplyOnAnyTopic =
          _json['whoCanMarkFavoriteReplyOnAnyTopic'] as core.String;
    }
    if (_json.containsKey('whoCanMarkFavoriteReplyOnOwnTopic')) {
      whoCanMarkFavoriteReplyOnOwnTopic =
          _json['whoCanMarkFavoriteReplyOnOwnTopic'] as core.String;
    }
    if (_json.containsKey('whoCanMarkNoResponseNeeded')) {
      whoCanMarkNoResponseNeeded =
          _json['whoCanMarkNoResponseNeeded'] as core.String;
    }
    if (_json.containsKey('whoCanModerateContent')) {
      whoCanModerateContent = _json['whoCanModerateContent'] as core.String;
    }
    if (_json.containsKey('whoCanModerateMembers')) {
      whoCanModerateMembers = _json['whoCanModerateMembers'] as core.String;
    }
    if (_json.containsKey('whoCanModifyMembers')) {
      whoCanModifyMembers = _json['whoCanModifyMembers'] as core.String;
    }
    if (_json.containsKey('whoCanModifyTagsAndCategories')) {
      whoCanModifyTagsAndCategories =
          _json['whoCanModifyTagsAndCategories'] as core.String;
    }
    if (_json.containsKey('whoCanMoveTopicsIn')) {
      whoCanMoveTopicsIn = _json['whoCanMoveTopicsIn'] as core.String;
    }
    if (_json.containsKey('whoCanMoveTopicsOut')) {
      whoCanMoveTopicsOut = _json['whoCanMoveTopicsOut'] as core.String;
    }
    if (_json.containsKey('whoCanPostAnnouncements')) {
      whoCanPostAnnouncements = _json['whoCanPostAnnouncements'] as core.String;
    }
    if (_json.containsKey('whoCanPostMessage')) {
      whoCanPostMessage = _json['whoCanPostMessage'] as core.String;
    }
    if (_json.containsKey('whoCanTakeTopics')) {
      whoCanTakeTopics = _json['whoCanTakeTopics'] as core.String;
    }
    if (_json.containsKey('whoCanUnassignTopic')) {
      whoCanUnassignTopic = _json['whoCanUnassignTopic'] as core.String;
    }
    if (_json.containsKey('whoCanUnmarkFavoriteReplyOnAnyTopic')) {
      whoCanUnmarkFavoriteReplyOnAnyTopic =
          _json['whoCanUnmarkFavoriteReplyOnAnyTopic'] as core.String;
    }
    if (_json.containsKey('whoCanViewGroup')) {
      whoCanViewGroup = _json['whoCanViewGroup'] as core.String;
    }
    if (_json.containsKey('whoCanViewMembership')) {
      whoCanViewMembership = _json['whoCanViewMembership'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowExternalMembers != null)
          'allowExternalMembers': allowExternalMembers!,
        if (allowGoogleCommunication != null)
          'allowGoogleCommunication': allowGoogleCommunication!,
        if (allowWebPosting != null) 'allowWebPosting': allowWebPosting!,
        if (archiveOnly != null) 'archiveOnly': archiveOnly!,
        if (customFooterText != null) 'customFooterText': customFooterText!,
        if (customReplyTo != null) 'customReplyTo': customReplyTo!,
        if (customRolesEnabledForSettingsToBeMerged != null)
          'customRolesEnabledForSettingsToBeMerged':
              customRolesEnabledForSettingsToBeMerged!,
        if (defaultMessageDenyNotificationText != null)
          'defaultMessageDenyNotificationText':
              defaultMessageDenyNotificationText!,
        if (description != null) 'description': description!,
        if (email != null) 'email': email!,
        if (enableCollaborativeInbox != null)
          'enableCollaborativeInbox': enableCollaborativeInbox!,
        if (favoriteRepliesOnTop != null)
          'favoriteRepliesOnTop': favoriteRepliesOnTop!,
        if (includeCustomFooter != null)
          'includeCustomFooter': includeCustomFooter!,
        if (includeInGlobalAddressList != null)
          'includeInGlobalAddressList': includeInGlobalAddressList!,
        if (isArchived != null) 'isArchived': isArchived!,
        if (kind != null) 'kind': kind!,
        if (maxMessageBytes != null) 'maxMessageBytes': maxMessageBytes!,
        if (membersCanPostAsTheGroup != null)
          'membersCanPostAsTheGroup': membersCanPostAsTheGroup!,
        if (messageDisplayFont != null)
          'messageDisplayFont': messageDisplayFont!,
        if (messageModerationLevel != null)
          'messageModerationLevel': messageModerationLevel!,
        if (name != null) 'name': name!,
        if (primaryLanguage != null) 'primaryLanguage': primaryLanguage!,
        if (replyTo != null) 'replyTo': replyTo!,
        if (sendMessageDenyNotification != null)
          'sendMessageDenyNotification': sendMessageDenyNotification!,
        if (showInGroupDirectory != null)
          'showInGroupDirectory': showInGroupDirectory!,
        if (spamModerationLevel != null)
          'spamModerationLevel': spamModerationLevel!,
        if (whoCanAdd != null) 'whoCanAdd': whoCanAdd!,
        if (whoCanAddReferences != null)
          'whoCanAddReferences': whoCanAddReferences!,
        if (whoCanApproveMembers != null)
          'whoCanApproveMembers': whoCanApproveMembers!,
        if (whoCanApproveMessages != null)
          'whoCanApproveMessages': whoCanApproveMessages!,
        if (whoCanAssignTopics != null)
          'whoCanAssignTopics': whoCanAssignTopics!,
        if (whoCanAssistContent != null)
          'whoCanAssistContent': whoCanAssistContent!,
        if (whoCanBanUsers != null) 'whoCanBanUsers': whoCanBanUsers!,
        if (whoCanContactOwner != null)
          'whoCanContactOwner': whoCanContactOwner!,
        if (whoCanDeleteAnyPost != null)
          'whoCanDeleteAnyPost': whoCanDeleteAnyPost!,
        if (whoCanDeleteTopics != null)
          'whoCanDeleteTopics': whoCanDeleteTopics!,
        if (whoCanDiscoverGroup != null)
          'whoCanDiscoverGroup': whoCanDiscoverGroup!,
        if (whoCanEnterFreeFormTags != null)
          'whoCanEnterFreeFormTags': whoCanEnterFreeFormTags!,
        if (whoCanHideAbuse != null) 'whoCanHideAbuse': whoCanHideAbuse!,
        if (whoCanInvite != null) 'whoCanInvite': whoCanInvite!,
        if (whoCanJoin != null) 'whoCanJoin': whoCanJoin!,
        if (whoCanLeaveGroup != null) 'whoCanLeaveGroup': whoCanLeaveGroup!,
        if (whoCanLockTopics != null) 'whoCanLockTopics': whoCanLockTopics!,
        if (whoCanMakeTopicsSticky != null)
          'whoCanMakeTopicsSticky': whoCanMakeTopicsSticky!,
        if (whoCanMarkDuplicate != null)
          'whoCanMarkDuplicate': whoCanMarkDuplicate!,
        if (whoCanMarkFavoriteReplyOnAnyTopic != null)
          'whoCanMarkFavoriteReplyOnAnyTopic':
              whoCanMarkFavoriteReplyOnAnyTopic!,
        if (whoCanMarkFavoriteReplyOnOwnTopic != null)
          'whoCanMarkFavoriteReplyOnOwnTopic':
              whoCanMarkFavoriteReplyOnOwnTopic!,
        if (whoCanMarkNoResponseNeeded != null)
          'whoCanMarkNoResponseNeeded': whoCanMarkNoResponseNeeded!,
        if (whoCanModerateContent != null)
          'whoCanModerateContent': whoCanModerateContent!,
        if (whoCanModerateMembers != null)
          'whoCanModerateMembers': whoCanModerateMembers!,
        if (whoCanModifyMembers != null)
          'whoCanModifyMembers': whoCanModifyMembers!,
        if (whoCanModifyTagsAndCategories != null)
          'whoCanModifyTagsAndCategories': whoCanModifyTagsAndCategories!,
        if (whoCanMoveTopicsIn != null)
          'whoCanMoveTopicsIn': whoCanMoveTopicsIn!,
        if (whoCanMoveTopicsOut != null)
          'whoCanMoveTopicsOut': whoCanMoveTopicsOut!,
        if (whoCanPostAnnouncements != null)
          'whoCanPostAnnouncements': whoCanPostAnnouncements!,
        if (whoCanPostMessage != null) 'whoCanPostMessage': whoCanPostMessage!,
        if (whoCanTakeTopics != null) 'whoCanTakeTopics': whoCanTakeTopics!,
        if (whoCanUnassignTopic != null)
          'whoCanUnassignTopic': whoCanUnassignTopic!,
        if (whoCanUnmarkFavoriteReplyOnAnyTopic != null)
          'whoCanUnmarkFavoriteReplyOnAnyTopic':
              whoCanUnmarkFavoriteReplyOnAnyTopic!,
        if (whoCanViewGroup != null) 'whoCanViewGroup': whoCanViewGroup!,
        if (whoCanViewMembership != null)
          'whoCanViewMembership': whoCanViewMembership!,
      };
}

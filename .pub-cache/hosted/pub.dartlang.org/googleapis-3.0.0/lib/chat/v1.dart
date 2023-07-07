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

/// Google Chat API - v1
///
/// Enables bots to fetch information and perform actions in Google Chat.
/// Authentication using a service account is a prerequisite for using the
/// Google Chat REST API.
///
/// For more information, see <https://developers.google.com/hangouts/chat>
///
/// Create an instance of [HangoutsChatApi] to access these resources:
///
/// - [DmsResource]
///   - [DmsConversationsResource]
/// - [MediaResource]
/// - [RoomsResource]
///   - [RoomsConversationsResource]
/// - [SpacesResource]
///   - [SpacesMembersResource]
///   - [SpacesMessagesResource]
///     - [SpacesMessagesAttachmentsResource]
library chat.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show
        ApiRequestError,
        DetailedApiRequestError,
        Media,
        UploadOptions,
        ResumableUploadOptions,
        DownloadOptions,
        PartialDownloadOptions,
        ByteRange;

/// Enables bots to fetch information and perform actions in Google Chat.
///
/// Authentication using a service account is a prerequisite for using the
/// Google Chat REST API.
class HangoutsChatApi {
  final commons.ApiRequester _requester;

  DmsResource get dms => DmsResource(_requester);
  MediaResource get media => MediaResource(_requester);
  RoomsResource get rooms => RoomsResource(_requester);
  SpacesResource get spaces => SpacesResource(_requester);

  HangoutsChatApi(http.Client client,
      {core.String rootUrl = 'https://chat.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DmsResource {
  final commons.ApiRequester _requester;

  DmsConversationsResource get conversations =>
      DmsConversationsResource(_requester);

  DmsResource(commons.ApiRequester client) : _requester = client;

  /// Legacy path for creating message.
  ///
  /// Calling these will result in a BadRequest response.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^dms/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> messages(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/messages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Legacy path for creating message.
  ///
  /// Calling these will result in a BadRequest response.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^dms/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> webhooks(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/webhooks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DmsConversationsResource {
  final commons.ApiRequester _requester;

  DmsConversationsResource(commons.ApiRequester client) : _requester = client;

  /// Legacy path for creating message.
  ///
  /// Calling these will result in a BadRequest response.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^dms/\[^/\]+/conversations/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> messages(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/messages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class MediaResource {
  final commons.ApiRequester _requester;

  MediaResource(commons.ApiRequester client) : _requester = client;

  /// Downloads media.
  ///
  /// Download is supported on the URI `/v1/media/{+name}?alt=media`.
  ///
  /// Request parameters:
  ///
  /// [resourceName] - Name of the media that is being downloaded. See
  /// ReadRequest.resource_name.
  /// Value must have pattern `^.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [downloadOptions] - Options for downloading. A download can be either a
  /// Metadata (default) or Media download. Partial Media downloads are possible
  /// as well.
  ///
  /// Completes with a
  ///
  /// - [Media] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> download(
    core.String resourceName, {
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/media/' + core.Uri.encodeFull('$resourceName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return Media.fromJson(_response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }
}

class RoomsResource {
  final commons.ApiRequester _requester;

  RoomsConversationsResource get conversations =>
      RoomsConversationsResource(_requester);

  RoomsResource(commons.ApiRequester client) : _requester = client;

  /// Legacy path for creating message.
  ///
  /// Calling these will result in a BadRequest response.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^rooms/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> messages(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/messages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Legacy path for creating message.
  ///
  /// Calling these will result in a BadRequest response.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^rooms/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> webhooks(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/webhooks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class RoomsConversationsResource {
  final commons.ApiRequester _requester;

  RoomsConversationsResource(commons.ApiRequester client) : _requester = client;

  /// Legacy path for creating message.
  ///
  /// Calling these will result in a BadRequest response.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^rooms/\[^/\]+/conversations/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> messages(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/messages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SpacesResource {
  final commons.ApiRequester _requester;

  SpacesMembersResource get members => SpacesMembersResource(_requester);
  SpacesMessagesResource get messages => SpacesMessagesResource(_requester);

  SpacesResource(commons.ApiRequester client) : _requester = client;

  /// Returns a space.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the space, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^spaces/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Space].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Space> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Space.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists spaces the caller is a member of.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Requested page size. The value is capped at 1000. Server may
  /// return fewer results than requested. If unspecified, server will default
  /// to 100.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSpacesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSpacesResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/spaces';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSpacesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Legacy path for creating message.
  ///
  /// Calling these will result in a BadRequest response.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^spaces/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> webhooks(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/webhooks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SpacesMembersResource {
  final commons.ApiRequester _requester;

  SpacesMembersResource(commons.ApiRequester client) : _requester = client;

  /// Returns a membership.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the membership to be retrieved, in the
  /// form "spaces / * /members / * ". Example:
  /// spaces/AAAAMpdlehY/members/105115627578887013105
  /// Value must have pattern `^spaces/\[^/\]+/members/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Membership].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Membership> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Membership.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists human memberships in a space.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the space for which membership
  /// list is to be fetched, in the form "spaces / * ". Example:
  /// spaces/AAAAMpdlehY
  /// Value must have pattern `^spaces/\[^/\]+$`.
  ///
  /// [pageSize] - Requested page size. The value is capped at 1000. Server may
  /// return fewer results than requested. If unspecified, server will default
  /// to 100.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListMembershipsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListMembershipsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/members';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListMembershipsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SpacesMessagesResource {
  final commons.ApiRequester _requester;

  SpacesMessagesAttachmentsResource get attachments =>
      SpacesMessagesAttachmentsResource(_requester);

  SpacesMessagesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a message.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Space resource name, in the form "spaces / * ".
  /// Example: spaces/AAAAMpdlehY
  /// Value must have pattern `^spaces/\[^/\]+$`.
  ///
  /// [threadKey] - Opaque thread identifier string that can be specified to
  /// group messages into a single thread. If this is the first message with a
  /// given thread identifier, a new thread is created. Subsequent messages with
  /// the same thread identifier will be posted into the same thread. This
  /// relieves bots and webhooks from having to store the Hangouts Chat thread
  /// ID of a thread (created earlier by them) to post further updates to it.
  /// Has no effect if thread field, corresponding to an existing thread, is set
  /// in message.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> create(
    Message request,
    core.String parent, {
    core.String? threadKey,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (threadKey != null) 'threadKey': [threadKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/messages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a message.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the message to be deleted, in the form
  /// "spaces / * /messages / * " Example:
  /// spaces/AAAAMpdlehY/messages/UMxbHmzDlr4.UMxbHmzDlr4
  /// Value must have pattern `^spaces/\[^/\]+/messages/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a message.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the message to be retrieved, in the
  /// form "spaces / * /messages / * ". Example:
  /// spaces/AAAAMpdlehY/messages/UMxbHmzDlr4.UMxbHmzDlr4
  /// Value must have pattern `^spaces/\[^/\]+/messages/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a message.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - null
  /// Value must have pattern `^spaces/\[^/\]+/messages/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The field paths to be updated, comma separated if
  /// there are multiple. Currently supported field paths: * text * cards
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> update(
    Message request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SpacesMessagesAttachmentsResource {
  final commons.ApiRequester _requester;

  SpacesMessagesAttachmentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the metadata of a message attachment.
  ///
  /// The attachment data is fetched using the media API.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name of the attachment, in the form "spaces / *
  /// /messages / * /attachments / * ".
  /// Value must have pattern
  /// `^spaces/\[^/\]+/messages/\[^/\]+/attachments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Attachment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Attachment> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Attachment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// List of string parameters to supply when the action method is invoked.
///
/// For example, consider three snooze buttons: snooze now, snooze 1 day, snooze
/// next week. You might use action method = snooze(), passing the snooze type
/// and snooze time in the list of string parameters.
class ActionParameter {
  /// The name of the parameter for the action script.
  core.String? key;

  /// The value of the parameter.
  core.String? value;

  ActionParameter();

  ActionParameter.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

/// Parameters that a bot can use to configure how it's response is posted.
class ActionResponse {
  /// The type of bot response.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default type; will be handled as NEW_MESSAGE.
  /// - "NEW_MESSAGE" : Post as a new message in the topic.
  /// - "UPDATE_MESSAGE" : Update the bot's message. This is only permitted on a
  /// CARD_CLICKED event where the message sender type is BOT.
  /// - "REQUEST_CONFIG" : Update a message, with cards only. (Only after a
  /// MESSAGE event with a matched url, or a CARD_CLICKED event on a human
  /// created message).
  core.String? type;

  /// URL for users to auth or config.
  ///
  /// (Only for REQUEST_CONFIG response types.)
  core.String? url;

  ActionResponse();

  ActionResponse.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (url != null) 'url': url!,
      };
}

/// Annotations associated with the plain-text body of the message.
///
/// Example plain-text message body: ``` Hello @FooBot how are you!" ``` The
/// corresponding annotations metadata: ``` "annotations":[{
/// "type":"USER_MENTION", "startIndex":6, "length":7, "userMention": { "user":
/// { "name":"users/107946847022116401880", "displayName":"FooBot",
/// "avatarUrl":"https://goo.gl/aeDtrS", "type":"BOT" }, "type":"MENTION" } }]
/// ```
class Annotation {
  /// Length of the substring in the plain-text message body this annotation
  /// corresponds to.
  core.int? length;

  /// The metadata for a slash command.
  SlashCommandMetadata? slashCommand;

  /// Start index (0-based, inclusive) in the plain-text message body this
  /// annotation corresponds to.
  core.int? startIndex;

  /// The type of this annotation.
  /// Possible string values are:
  /// - "ANNOTATION_TYPE_UNSPECIFIED" : Default value for the enum. DO NOT USE.
  /// - "USER_MENTION" : A user is mentioned.
  /// - "SLASH_COMMAND" : A slash command is invoked.
  core.String? type;

  /// The metadata of user mention.
  UserMentionMetadata? userMention;

  Annotation();

  Annotation.fromJson(core.Map _json) {
    if (_json.containsKey('length')) {
      length = _json['length'] as core.int;
    }
    if (_json.containsKey('slashCommand')) {
      slashCommand = SlashCommandMetadata.fromJson(
          _json['slashCommand'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('userMention')) {
      userMention = UserMentionMetadata.fromJson(
          _json['userMention'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (length != null) 'length': length!,
        if (slashCommand != null) 'slashCommand': slashCommand!.toJson(),
        if (startIndex != null) 'startIndex': startIndex!,
        if (type != null) 'type': type!,
        if (userMention != null) 'userMention': userMention!.toJson(),
      };
}

/// An attachment in Hangouts Chat.
class Attachment {
  /// A reference to the attachment data.
  ///
  /// This is used with the media API to download the attachment data.
  AttachmentDataRef? attachmentDataRef;

  /// The original file name for the content, not the full path.
  core.String? contentName;

  /// The content type (MIME type) of the file.
  core.String? contentType;

  /// The download URL which should be used to allow a human user to download
  /// the attachment.
  ///
  /// Bots should not use this URL to download attachment content.
  ///
  /// Output only.
  core.String? downloadUri;

  /// A reference to the drive attachment.
  ///
  /// This is used with the Drive API.
  DriveDataRef? driveDataRef;

  /// Resource name of the attachment, in the form "spaces / * /messages / *
  /// /attachments / * ".
  core.String? name;

  /// The source of the attachment.
  /// Possible string values are:
  /// - "SOURCE_UNSPECIFIED"
  /// - "DRIVE_FILE"
  /// - "UPLOADED_CONTENT"
  core.String? source;

  /// The thumbnail URL which should be used to preview the attachment to a
  /// human user.
  ///
  /// Bots should not use this URL to download attachment content.
  ///
  /// Output only.
  core.String? thumbnailUri;

  Attachment();

  Attachment.fromJson(core.Map _json) {
    if (_json.containsKey('attachmentDataRef')) {
      attachmentDataRef = AttachmentDataRef.fromJson(
          _json['attachmentDataRef'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentName')) {
      contentName = _json['contentName'] as core.String;
    }
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('downloadUri')) {
      downloadUri = _json['downloadUri'] as core.String;
    }
    if (_json.containsKey('driveDataRef')) {
      driveDataRef = DriveDataRef.fromJson(
          _json['driveDataRef'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('thumbnailUri')) {
      thumbnailUri = _json['thumbnailUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attachmentDataRef != null)
          'attachmentDataRef': attachmentDataRef!.toJson(),
        if (contentName != null) 'contentName': contentName!,
        if (contentType != null) 'contentType': contentType!,
        if (downloadUri != null) 'downloadUri': downloadUri!,
        if (driveDataRef != null) 'driveDataRef': driveDataRef!.toJson(),
        if (name != null) 'name': name!,
        if (source != null) 'source': source!,
        if (thumbnailUri != null) 'thumbnailUri': thumbnailUri!,
      };
}

/// A reference to the data of an attachment.
class AttachmentDataRef {
  /// The resource name of the attachment data.
  ///
  /// This is used with the media API to download the attachment data.
  core.String? resourceName;

  AttachmentDataRef();

  AttachmentDataRef.fromJson(core.Map _json) {
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceName != null) 'resourceName': resourceName!,
      };
}

/// A button.
///
/// Can be a text button or an image button.
class Button {
  /// A button with image and onclick action.
  ImageButton? imageButton;

  /// A button with text and onclick action.
  TextButton? textButton;

  Button();

  Button.fromJson(core.Map _json) {
    if (_json.containsKey('imageButton')) {
      imageButton = ImageButton.fromJson(
          _json['imageButton'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textButton')) {
      textButton = TextButton.fromJson(
          _json['textButton'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageButton != null) 'imageButton': imageButton!.toJson(),
        if (textButton != null) 'textButton': textButton!.toJson(),
      };
}

/// A card is a UI element that can contain UI widgets such as texts, images.
class Card {
  /// The actions of this card.
  core.List<CardAction>? cardActions;

  /// The header of the card.
  ///
  /// A header usually contains a title and an image.
  CardHeader? header;

  /// Name of the card.
  core.String? name;

  /// Sections are separated by a line divider.
  core.List<Section>? sections;

  Card();

  Card.fromJson(core.Map _json) {
    if (_json.containsKey('cardActions')) {
      cardActions = (_json['cardActions'] as core.List)
          .map<CardAction>((value) =>
              CardAction.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('header')) {
      header = CardHeader.fromJson(
          _json['header'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('sections')) {
      sections = (_json['sections'] as core.List)
          .map<Section>((value) =>
              Section.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cardActions != null)
          'cardActions': cardActions!.map((value) => value.toJson()).toList(),
        if (header != null) 'header': header!.toJson(),
        if (name != null) 'name': name!,
        if (sections != null)
          'sections': sections!.map((value) => value.toJson()).toList(),
      };
}

/// A card action is the action associated with the card.
///
/// For an invoice card, a typical action would be: delete invoice, email
/// invoice or open the invoice in browser.
class CardAction {
  /// The label used to be displayed in the action menu item.
  core.String? actionLabel;

  /// The onclick action for this action item.
  OnClick? onClick;

  CardAction();

  CardAction.fromJson(core.Map _json) {
    if (_json.containsKey('actionLabel')) {
      actionLabel = _json['actionLabel'] as core.String;
    }
    if (_json.containsKey('onClick')) {
      onClick = OnClick.fromJson(
          _json['onClick'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actionLabel != null) 'actionLabel': actionLabel!,
        if (onClick != null) 'onClick': onClick!.toJson(),
      };
}

class CardHeader {
  /// The image's type (e.g. square border or circular border).
  /// Possible string values are:
  /// - "IMAGE_STYLE_UNSPECIFIED"
  /// - "IMAGE" : Square border.
  /// - "AVATAR" : Circular border.
  core.String? imageStyle;

  /// The URL of the image in the card header.
  core.String? imageUrl;

  /// The subtitle of the card header.
  core.String? subtitle;

  /// The title must be specified.
  ///
  /// The header has a fixed height: if both a title and subtitle is specified,
  /// each will take up 1 line. If only the title is specified, it will take up
  /// both lines.
  core.String? title;

  CardHeader();

  CardHeader.fromJson(core.Map _json) {
    if (_json.containsKey('imageStyle')) {
      imageStyle = _json['imageStyle'] as core.String;
    }
    if (_json.containsKey('imageUrl')) {
      imageUrl = _json['imageUrl'] as core.String;
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageStyle != null) 'imageStyle': imageStyle!,
        if (imageUrl != null) 'imageUrl': imageUrl!,
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// Google Chat events.
class DeprecatedEvent {
  /// The form action data associated with an interactive card that was clicked.
  ///
  /// Only populated for CARD_CLICKED events. See the \[Interactive Cards
  /// guide\](/hangouts/chat/how-tos/cards-onclick) for more information.
  FormAction? action;

  /// The URL the bot should redirect the user to after they have completed an
  /// authorization or configuration flow outside of Google Chat.
  ///
  /// See the \[Authorizing access to 3p services
  /// guide\](/hangouts/chat/how-tos/auth-3p) for more information.
  core.String? configCompleteRedirectUrl;

  /// The timestamp indicating when the event was dispatched.
  core.String? eventTime;

  /// The message that triggered the event, if applicable.
  Message? message;

  /// The room or DM in which the event occurred.
  Space? space;

  /// The bot-defined key for the thread related to the event.
  ///
  /// See the thread_key field of the `spaces.message.create` request for more
  /// information.
  core.String? threadKey;

  /// A secret value that bots can use to verify if a request is from Google.
  ///
  /// The token is randomly generated by Google, remains static, and can be
  /// obtained from the Google Chat API configuration page in the Cloud Console.
  /// Developers can revoke/regenerate it if needed from the same page.
  core.String? token;

  /// The type of the event.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Default value for the enum. DO NOT USE.
  /// - "MESSAGE" : A message was sent in a room or direct message.
  /// - "ADDED_TO_SPACE" : The bot was added to a room or DM.
  /// - "REMOVED_FROM_SPACE" : The bot was removed from a room or DM.
  /// - "CARD_CLICKED" : The bot's interactive card was clicked.
  core.String? type;

  /// The user that triggered the event.
  User? user;

  DeprecatedEvent();

  DeprecatedEvent.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = FormAction.fromJson(
          _json['action'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('configCompleteRedirectUrl')) {
      configCompleteRedirectUrl =
          _json['configCompleteRedirectUrl'] as core.String;
    }
    if (_json.containsKey('eventTime')) {
      eventTime = _json['eventTime'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = Message.fromJson(
          _json['message'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('space')) {
      space =
          Space.fromJson(_json['space'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('threadKey')) {
      threadKey = _json['threadKey'] as core.String;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('user')) {
      user =
          User.fromJson(_json['user'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!.toJson(),
        if (configCompleteRedirectUrl != null)
          'configCompleteRedirectUrl': configCompleteRedirectUrl!,
        if (eventTime != null) 'eventTime': eventTime!,
        if (message != null) 'message': message!.toJson(),
        if (space != null) 'space': space!.toJson(),
        if (threadKey != null) 'threadKey': threadKey!,
        if (token != null) 'token': token!,
        if (type != null) 'type': type!,
        if (user != null) 'user': user!.toJson(),
      };
}

/// A reference to the data of a drive attachment.
class DriveDataRef {
  /// The id for the drive file, for use with the Drive API.
  core.String? driveFileId;

  DriveDataRef();

  DriveDataRef.fromJson(core.Map _json) {
    if (_json.containsKey('driveFileId')) {
      driveFileId = _json['driveFileId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (driveFileId != null) 'driveFileId': driveFileId!,
      };
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class Empty {
  Empty();

  Empty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A form action describes the behavior when the form is submitted.
///
/// For example, an Apps Script can be invoked to handle the form.
class FormAction {
  /// The method name is used to identify which part of the form triggered the
  /// form submission.
  ///
  /// This information is echoed back to the bot as part of the card click
  /// event. The same method name can be used for several elements that trigger
  /// a common behavior if desired.
  core.String? actionMethodName;

  /// List of action parameters.
  core.List<ActionParameter>? parameters;

  FormAction();

  FormAction.fromJson(core.Map _json) {
    if (_json.containsKey('actionMethodName')) {
      actionMethodName = _json['actionMethodName'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<ActionParameter>((value) => ActionParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actionMethodName != null) 'actionMethodName': actionMethodName!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
      };
}

/// An image that is specified by a URL and can have an onclick action.
class Image {
  /// The aspect ratio of this image (width/height).
  ///
  /// This field allows clients to reserve the right height for the image while
  /// waiting for it to load. It's not meant to override the native aspect ratio
  /// of the image. If unset, the server fills it by prefetching the image.
  core.double? aspectRatio;

  /// The URL of the image.
  core.String? imageUrl;

  /// The onclick action.
  OnClick? onClick;

  Image();

  Image.fromJson(core.Map _json) {
    if (_json.containsKey('aspectRatio')) {
      aspectRatio = (_json['aspectRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('imageUrl')) {
      imageUrl = _json['imageUrl'] as core.String;
    }
    if (_json.containsKey('onClick')) {
      onClick = OnClick.fromJson(
          _json['onClick'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aspectRatio != null) 'aspectRatio': aspectRatio!,
        if (imageUrl != null) 'imageUrl': imageUrl!,
        if (onClick != null) 'onClick': onClick!.toJson(),
      };
}

/// An image button with an onclick action.
class ImageButton {
  /// The icon specified by an enum that indices to an icon provided by Chat
  /// API.
  /// Possible string values are:
  /// - "ICON_UNSPECIFIED"
  /// - "AIRPLANE"
  /// - "BOOKMARK"
  /// - "BUS"
  /// - "CAR"
  /// - "CLOCK"
  /// - "CONFIRMATION_NUMBER_ICON"
  /// - "DOLLAR"
  /// - "DESCRIPTION"
  /// - "EMAIL"
  /// - "EVENT_PERFORMER"
  /// - "EVENT_SEAT"
  /// - "FLIGHT_ARRIVAL"
  /// - "FLIGHT_DEPARTURE"
  /// - "HOTEL"
  /// - "HOTEL_ROOM_TYPE"
  /// - "INVITE"
  /// - "MAP_PIN"
  /// - "MEMBERSHIP"
  /// - "MULTIPLE_PEOPLE"
  /// - "OFFER"
  /// - "PERSON"
  /// - "PHONE"
  /// - "RESTAURANT_ICON"
  /// - "SHOPPING_CART"
  /// - "STAR"
  /// - "STORE"
  /// - "TICKET"
  /// - "TRAIN"
  /// - "VIDEO_CAMERA"
  /// - "VIDEO_PLAY"
  core.String? icon;

  /// The icon specified by a URL.
  core.String? iconUrl;

  /// The name of this image_button which will be used for accessibility.
  ///
  /// Default value will be provided if developers don't specify.
  core.String? name;

  /// The onclick action.
  OnClick? onClick;

  ImageButton();

  ImageButton.fromJson(core.Map _json) {
    if (_json.containsKey('icon')) {
      icon = _json['icon'] as core.String;
    }
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('onClick')) {
      onClick = OnClick.fromJson(
          _json['onClick'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (icon != null) 'icon': icon!,
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (name != null) 'name': name!,
        if (onClick != null) 'onClick': onClick!.toJson(),
      };
}

/// A UI element contains a key (label) and a value (content).
///
/// And this element may also contain some actions such as onclick button.
class KeyValue {
  /// The text of the bottom label.
  ///
  /// Formatted text supported.
  core.String? bottomLabel;

  /// A button that can be clicked to trigger an action.
  Button? button;

  /// The text of the content.
  ///
  /// Formatted text supported and always required.
  core.String? content;

  /// If the content should be multiline.
  core.bool? contentMultiline;

  /// An enum value that will be replaced by the Chat API with the corresponding
  /// icon image.
  /// Possible string values are:
  /// - "ICON_UNSPECIFIED"
  /// - "AIRPLANE"
  /// - "BOOKMARK"
  /// - "BUS"
  /// - "CAR"
  /// - "CLOCK"
  /// - "CONFIRMATION_NUMBER_ICON"
  /// - "DOLLAR"
  /// - "DESCRIPTION"
  /// - "EMAIL"
  /// - "EVENT_PERFORMER"
  /// - "EVENT_SEAT"
  /// - "FLIGHT_ARRIVAL"
  /// - "FLIGHT_DEPARTURE"
  /// - "HOTEL"
  /// - "HOTEL_ROOM_TYPE"
  /// - "INVITE"
  /// - "MAP_PIN"
  /// - "MEMBERSHIP"
  /// - "MULTIPLE_PEOPLE"
  /// - "OFFER"
  /// - "PERSON"
  /// - "PHONE"
  /// - "RESTAURANT_ICON"
  /// - "SHOPPING_CART"
  /// - "STAR"
  /// - "STORE"
  /// - "TICKET"
  /// - "TRAIN"
  /// - "VIDEO_CAMERA"
  /// - "VIDEO_PLAY"
  core.String? icon;

  /// The icon specified by a URL.
  core.String? iconUrl;

  /// The onclick action.
  ///
  /// Only the top label, bottom label and content region are clickable.
  OnClick? onClick;

  /// The text of the top label.
  ///
  /// Formatted text supported.
  core.String? topLabel;

  KeyValue();

  KeyValue.fromJson(core.Map _json) {
    if (_json.containsKey('bottomLabel')) {
      bottomLabel = _json['bottomLabel'] as core.String;
    }
    if (_json.containsKey('button')) {
      button = Button.fromJson(
          _json['button'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('contentMultiline')) {
      contentMultiline = _json['contentMultiline'] as core.bool;
    }
    if (_json.containsKey('icon')) {
      icon = _json['icon'] as core.String;
    }
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('onClick')) {
      onClick = OnClick.fromJson(
          _json['onClick'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('topLabel')) {
      topLabel = _json['topLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottomLabel != null) 'bottomLabel': bottomLabel!,
        if (button != null) 'button': button!.toJson(),
        if (content != null) 'content': content!,
        if (contentMultiline != null) 'contentMultiline': contentMultiline!,
        if (icon != null) 'icon': icon!,
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (onClick != null) 'onClick': onClick!.toJson(),
        if (topLabel != null) 'topLabel': topLabel!,
      };
}

class ListMembershipsResponse {
  /// List of memberships in the requested (or first) page.
  core.List<Membership>? memberships;

  /// Continuation token to retrieve the next page of results.
  ///
  /// It will be empty for the last page of results.
  core.String? nextPageToken;

  ListMembershipsResponse();

  ListMembershipsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('memberships')) {
      memberships = (_json['memberships'] as core.List)
          .map<Membership>((value) =>
              Membership.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (memberships != null)
          'memberships': memberships!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListSpacesResponse {
  /// Continuation token to retrieve the next page of results.
  ///
  /// It will be empty for the last page of results. Tokens expire in an hour.
  /// An error is thrown if an expired token is passed.
  core.String? nextPageToken;

  /// List of spaces in the requested (or first) page.
  core.List<Space>? spaces;

  ListSpacesResponse();

  ListSpacesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('spaces')) {
      spaces = (_json['spaces'] as core.List)
          .map<Space>((value) =>
              Space.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (spaces != null)
          'spaces': spaces!.map((value) => value.toJson()).toList(),
      };
}

/// Media resource.
class Media {
  /// Name of the media resource.
  core.String? resourceName;

  Media();

  Media.fromJson(core.Map _json) {
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceName != null) 'resourceName': resourceName!,
      };
}

/// Represents a membership relation in Hangouts Chat.
class Membership {
  /// The creation time of the membership a.k.a the time at which the member
  /// joined the space, if applicable.
  core.String? createTime;

  /// A User in Hangout Chat
  User? member;
  core.String? name;

  /// State of the membership.
  /// Possible string values are:
  /// - "MEMBERSHIP_STATE_UNSPECIFIED" : Default, do not use.
  /// - "JOINED" : The user has joined the space.
  /// - "INVITED" : The user has been invited, is able to join the space, but
  /// currently has not joined.
  /// - "NOT_A_MEMBER" : The user is not a member of the space, has not been
  /// invited and is not able to join the space.
  core.String? state;

  Membership();

  Membership.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('member')) {
      member =
          User.fromJson(_json['member'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (member != null) 'member': member!.toJson(),
        if (name != null) 'name': name!,
        if (state != null) 'state': state!,
      };
}

/// A message in Hangouts Chat.
class Message {
  /// Input only.
  ///
  /// Parameters that a bot can use to configure how its response is posted.
  ActionResponse? actionResponse;

  /// Annotations associated with the text in this message.
  ///
  /// Output only.
  core.List<Annotation>? annotations;

  /// Plain-text body of the message with all bot mentions stripped out.
  core.String? argumentText;

  /// User uploaded attachment.
  core.List<Attachment>? attachment;

  /// Rich, formatted and interactive cards that can be used to display UI
  /// elements such as: formatted texts, buttons, clickable images.
  ///
  /// Cards are normally displayed below the plain-text body of the message.
  core.List<Card>? cards;

  /// The time at which the message was created in Hangouts Chat server.
  ///
  /// Output only.
  core.String? createTime;

  /// A plain-text description of the message's cards, used when the actual
  /// cards cannot be displayed (e.g. mobile notifications).
  core.String? fallbackText;
  core.String? name;

  /// Text for generating preview chips.
  ///
  /// This text will not be displayed to the user, but any links to images, web
  /// pages, videos, etc. included here will generate preview chips.
  core.String? previewText;

  /// The user who created the message.
  User? sender;

  /// Slash command information, if applicable.
  SlashCommand? slashCommand;

  /// The space the message belongs to.
  Space? space;

  /// Plain-text body of the message.
  core.String? text;

  /// The thread the message belongs to.
  Thread? thread;

  Message();

  Message.fromJson(core.Map _json) {
    if (_json.containsKey('actionResponse')) {
      actionResponse = ActionResponse.fromJson(
          _json['actionResponse'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('annotations')) {
      annotations = (_json['annotations'] as core.List)
          .map<Annotation>((value) =>
              Annotation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('argumentText')) {
      argumentText = _json['argumentText'] as core.String;
    }
    if (_json.containsKey('attachment')) {
      attachment = (_json['attachment'] as core.List)
          .map<Attachment>((value) =>
              Attachment.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('cards')) {
      cards = (_json['cards'] as core.List)
          .map<Card>((value) =>
              Card.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('fallbackText')) {
      fallbackText = _json['fallbackText'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('previewText')) {
      previewText = _json['previewText'] as core.String;
    }
    if (_json.containsKey('sender')) {
      sender =
          User.fromJson(_json['sender'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('slashCommand')) {
      slashCommand = SlashCommand.fromJson(
          _json['slashCommand'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('space')) {
      space =
          Space.fromJson(_json['space'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('thread')) {
      thread = Thread.fromJson(
          _json['thread'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actionResponse != null) 'actionResponse': actionResponse!.toJson(),
        if (annotations != null)
          'annotations': annotations!.map((value) => value.toJson()).toList(),
        if (argumentText != null) 'argumentText': argumentText!,
        if (attachment != null)
          'attachment': attachment!.map((value) => value.toJson()).toList(),
        if (cards != null)
          'cards': cards!.map((value) => value.toJson()).toList(),
        if (createTime != null) 'createTime': createTime!,
        if (fallbackText != null) 'fallbackText': fallbackText!,
        if (name != null) 'name': name!,
        if (previewText != null) 'previewText': previewText!,
        if (sender != null) 'sender': sender!.toJson(),
        if (slashCommand != null) 'slashCommand': slashCommand!.toJson(),
        if (space != null) 'space': space!.toJson(),
        if (text != null) 'text': text!,
        if (thread != null) 'thread': thread!.toJson(),
      };
}

/// An onclick action (e.g. open a link).
class OnClick {
  /// A form action will be triggered by this onclick if specified.
  FormAction? action;

  /// This onclick triggers an open link action if specified.
  OpenLink? openLink;

  OnClick();

  OnClick.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = FormAction.fromJson(
          _json['action'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('openLink')) {
      openLink = OpenLink.fromJson(
          _json['openLink'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!.toJson(),
        if (openLink != null) 'openLink': openLink!.toJson(),
      };
}

/// A link that opens a new window.
class OpenLink {
  /// The URL to open.
  core.String? url;

  OpenLink();

  OpenLink.fromJson(core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
      };
}

/// A section contains a collection of widgets that are rendered (vertically) in
/// the order that they are specified.
///
/// Across all platforms, cards have a narrow fixed width, so there is currently
/// no need for layout properties (e.g. float).
class Section {
  /// The header of the section, text formatted supported.
  core.String? header;

  /// A section must contain at least 1 widget.
  core.List<WidgetMarkup>? widgets;

  Section();

  Section.fromJson(core.Map _json) {
    if (_json.containsKey('header')) {
      header = _json['header'] as core.String;
    }
    if (_json.containsKey('widgets')) {
      widgets = (_json['widgets'] as core.List)
          .map<WidgetMarkup>((value) => WidgetMarkup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (header != null) 'header': header!,
        if (widgets != null)
          'widgets': widgets!.map((value) => value.toJson()).toList(),
      };
}

/// A Slash Command in Chat.
class SlashCommand {
  /// The id of the slash command invoked.
  core.String? commandId;

  SlashCommand();

  SlashCommand.fromJson(core.Map _json) {
    if (_json.containsKey('commandId')) {
      commandId = _json['commandId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commandId != null) 'commandId': commandId!,
      };
}

/// Annotation metadata for slash commands (/).
class SlashCommandMetadata {
  /// The bot whose command was invoked.
  User? bot;

  /// The command id of the invoked slash command.
  core.String? commandId;

  /// The name of the invoked slash command.
  core.String? commandName;

  /// Indicating whether the slash command is for a dialog.
  core.bool? triggersDialog;

  /// The type of slash command.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value for the enum. DO NOT USE.
  /// - "ADD" : Add bot to space.
  /// - "INVOKE" : Invoke slash command in space.
  core.String? type;

  SlashCommandMetadata();

  SlashCommandMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('bot')) {
      bot = User.fromJson(_json['bot'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('commandId')) {
      commandId = _json['commandId'] as core.String;
    }
    if (_json.containsKey('commandName')) {
      commandName = _json['commandName'] as core.String;
    }
    if (_json.containsKey('triggersDialog')) {
      triggersDialog = _json['triggersDialog'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bot != null) 'bot': bot!.toJson(),
        if (commandId != null) 'commandId': commandId!,
        if (commandName != null) 'commandName': commandName!,
        if (triggersDialog != null) 'triggersDialog': triggersDialog!,
        if (type != null) 'type': type!,
      };
}

/// A room or DM in Hangouts Chat.
class Space {
  /// The display name (only if the space is a room).
  ///
  /// Please note that this field might not be populated in direct messages
  /// between humans.
  ///
  /// Output only.
  core.String? displayName;

  /// Resource name of the space, in the form "spaces / * ".
  ///
  /// Example: spaces/AAAAMpdlehYs
  core.String? name;

  /// Whether the space is a DM between a bot and a single human.
  core.bool? singleUserBotDm;

  /// Whether the messages are threaded in this space.
  core.bool? threaded;

  /// The type of a space.
  ///
  /// This is deprecated. Use `single_user_bot_dm` instead.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED"
  /// - "ROOM" : Multi-user spaces such as rooms and DMs between humans.
  /// - "DM" : 1:1 Direct Message between a human and a bot, where all messages
  /// are flat.
  core.String? type;

  Space();

  Space.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('singleUserBotDm')) {
      singleUserBotDm = _json['singleUserBotDm'] as core.bool;
    }
    if (_json.containsKey('threaded')) {
      threaded = _json['threaded'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (singleUserBotDm != null) 'singleUserBotDm': singleUserBotDm!,
        if (threaded != null) 'threaded': threaded!,
        if (type != null) 'type': type!,
      };
}

/// A button with text and onclick action.
class TextButton {
  /// The onclick action of the button.
  OnClick? onClick;

  /// The text of the button.
  core.String? text;

  TextButton();

  TextButton.fromJson(core.Map _json) {
    if (_json.containsKey('onClick')) {
      onClick = OnClick.fromJson(
          _json['onClick'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (onClick != null) 'onClick': onClick!.toJson(),
        if (text != null) 'text': text!,
      };
}

/// A paragraph of text.
///
/// Formatted text supported.
class TextParagraph {
  core.String? text;

  TextParagraph();

  TextParagraph.fromJson(core.Map _json) {
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// A thread in Hangouts Chat.
class Thread {
  /// Resource name, in the form "spaces / * /threads / * ".
  ///
  /// Example: spaces/AAAAMpdlehY/threads/UMxbHmzDlr4
  core.String? name;

  Thread();

  Thread.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
      };
}

/// A user in Google Chat.
class User {
  /// The user's display name.
  core.String? displayName;

  /// Obfuscated domain information.
  core.String? domainId;

  /// True when the user is deleted or the user's profile is not visible.
  core.bool? isAnonymous;

  /// Resource name, in the format "users / * ".
  core.String? name;

  /// User type.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value for the enum. DO NOT USE.
  /// - "HUMAN" : Human user.
  /// - "BOT" : Bot user.
  core.String? type;

  User();

  User.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('domainId')) {
      domainId = _json['domainId'] as core.String;
    }
    if (_json.containsKey('isAnonymous')) {
      isAnonymous = _json['isAnonymous'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (domainId != null) 'domainId': domainId!,
        if (isAnonymous != null) 'isAnonymous': isAnonymous!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

/// Annotation metadata for user mentions (@).
class UserMentionMetadata {
  /// The type of user mention.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value for the enum. DO NOT USE.
  /// - "ADD" : Add user to space.
  /// - "MENTION" : Mention user in space.
  core.String? type;

  /// The user mentioned.
  User? user;

  UserMentionMetadata();

  UserMentionMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('user')) {
      user =
          User.fromJson(_json['user'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (user != null) 'user': user!.toJson(),
      };
}

/// A widget is a UI element that presents texts, images, etc.
class WidgetMarkup {
  /// A list of buttons.
  ///
  /// Buttons is also oneof data and only one of these fields should be set.
  core.List<Button>? buttons;

  /// Display an image in this widget.
  Image? image;

  /// Display a key value item in this widget.
  KeyValue? keyValue;

  /// Display a text paragraph in this widget.
  TextParagraph? textParagraph;

  WidgetMarkup();

  WidgetMarkup.fromJson(core.Map _json) {
    if (_json.containsKey('buttons')) {
      buttons = (_json['buttons'] as core.List)
          .map<Button>((value) =>
              Button.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('image')) {
      image =
          Image.fromJson(_json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keyValue')) {
      keyValue = KeyValue.fromJson(
          _json['keyValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textParagraph')) {
      textParagraph = TextParagraph.fromJson(
          _json['textParagraph'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buttons != null)
          'buttons': buttons!.map((value) => value.toJson()).toList(),
        if (image != null) 'image': image!.toJson(),
        if (keyValue != null) 'keyValue': keyValue!.toJson(),
        if (textParagraph != null) 'textParagraph': textParagraph!.toJson(),
      };
}

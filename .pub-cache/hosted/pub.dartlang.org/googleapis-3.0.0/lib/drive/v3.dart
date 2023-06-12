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

/// Drive API - v3
///
/// Manages files in Drive including uploading, downloading, searching,
/// detecting changes, and updating sharing permissions.
///
/// For more information, see <https://developers.google.com/drive/>
///
/// Create an instance of [DriveApi] to access these resources:
///
/// - [AboutResource]
/// - [ChangesResource]
/// - [ChannelsResource]
/// - [CommentsResource]
/// - [DrivesResource]
/// - [FilesResource]
/// - [PermissionsResource]
/// - [RepliesResource]
/// - [RevisionsResource]
/// - [TeamdrivesResource]
library drive.v3;

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

/// Manages files in Drive including uploading, downloading, searching,
/// detecting changes, and updating sharing permissions.
class DriveApi {
  /// See, edit, create, and delete all of your Google Drive files
  static const driveScope = 'https://www.googleapis.com/auth/drive';

  /// See, create, and delete its own configuration data in your Google Drive
  static const driveAppdataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  /// See, edit, create, and delete only the specific Google Drive files you use
  /// with this app
  static const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

  /// View and manage metadata of files in your Google Drive
  static const driveMetadataScope =
      'https://www.googleapis.com/auth/drive.metadata';

  /// See information about your Google Drive files
  static const driveMetadataReadonlyScope =
      'https://www.googleapis.com/auth/drive.metadata.readonly';

  /// View the photos, videos and albums in your Google Photos
  static const drivePhotosReadonlyScope =
      'https://www.googleapis.com/auth/drive.photos.readonly';

  /// See and download all your Google Drive files
  static const driveReadonlyScope =
      'https://www.googleapis.com/auth/drive.readonly';

  /// Modify your Google Apps Script scripts' behavior
  static const driveScriptsScope =
      'https://www.googleapis.com/auth/drive.scripts';

  final commons.ApiRequester _requester;

  AboutResource get about => AboutResource(_requester);
  ChangesResource get changes => ChangesResource(_requester);
  ChannelsResource get channels => ChannelsResource(_requester);
  CommentsResource get comments => CommentsResource(_requester);
  DrivesResource get drives => DrivesResource(_requester);
  FilesResource get files => FilesResource(_requester);
  PermissionsResource get permissions => PermissionsResource(_requester);
  RepliesResource get replies => RepliesResource(_requester);
  RevisionsResource get revisions => RevisionsResource(_requester);
  TeamdrivesResource get teamdrives => TeamdrivesResource(_requester);

  DriveApi(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = 'drive/v3/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AboutResource {
  final commons.ApiRequester _requester;

  AboutResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about the user, the user's Drive, and system
  /// capabilities.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [About].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<About> get({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'about';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return About.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ChangesResource {
  final commons.ApiRequester _requester;

  ChangesResource(commons.ApiRequester client) : _requester = client;

  /// Gets the starting pageToken for listing future changes.
  ///
  /// Request parameters:
  ///
  /// [driveId] - The ID of the shared drive for which the starting pageToken
  /// for listing future changes from that shared drive is returned.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [teamDriveId] - Deprecated use driveId instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StartPageToken].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StartPageToken> getStartPageToken({
    core.String? driveId,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? teamDriveId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (driveId != null) 'driveId': [driveId],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (teamDriveId != null) 'teamDriveId': [teamDriveId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'changes/startPageToken';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return StartPageToken.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the changes for a user or shared drive.
  ///
  /// Request parameters:
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response or to the response from the getStartPageToken method.
  ///
  /// [driveId] - The shared drive from which changes are returned. If specified
  /// the change IDs will be reflective of the shared drive; use the combined
  /// drive ID and change ID as an identifier.
  ///
  /// [includeCorpusRemovals] - Whether changes should include the file resource
  /// if the file is still accessible by the user at the time of the request,
  /// even when a file was removed from the list of changes and there will be no
  /// further change entries for this file.
  ///
  /// [includeItemsFromAllDrives] - Whether both My Drive and shared drive items
  /// should be included in results.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [includeRemoved] - Whether to include changes indicating that items have
  /// been removed from the list of changes, for example by deletion or loss of
  /// access.
  ///
  /// [includeTeamDriveItems] - Deprecated use includeItemsFromAllDrives
  /// instead.
  ///
  /// [pageSize] - The maximum number of changes to return per page.
  /// Value must be between "1" and "1000".
  ///
  /// [restrictToMyDrive] - Whether to restrict the results to changes inside
  /// the My Drive hierarchy. This omits changes to files such as those in the
  /// Application Data folder or shared files which have not been added to My
  /// Drive.
  ///
  /// [spaces] - A comma-separated list of spaces to query within the user
  /// corpus. Supported values are 'drive', 'appDataFolder' and 'photos'.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [teamDriveId] - Deprecated use driveId instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChangeList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChangeList> list(
    core.String pageToken, {
    core.String? driveId,
    core.bool? includeCorpusRemovals,
    core.bool? includeItemsFromAllDrives,
    core.String? includePermissionsForView,
    core.bool? includeRemoved,
    core.bool? includeTeamDriveItems,
    core.int? pageSize,
    core.bool? restrictToMyDrive,
    core.String? spaces,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? teamDriveId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'pageToken': [pageToken],
      if (driveId != null) 'driveId': [driveId],
      if (includeCorpusRemovals != null)
        'includeCorpusRemovals': ['${includeCorpusRemovals}'],
      if (includeItemsFromAllDrives != null)
        'includeItemsFromAllDrives': ['${includeItemsFromAllDrives}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (includeRemoved != null) 'includeRemoved': ['${includeRemoved}'],
      if (includeTeamDriveItems != null)
        'includeTeamDriveItems': ['${includeTeamDriveItems}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (restrictToMyDrive != null)
        'restrictToMyDrive': ['${restrictToMyDrive}'],
      if (spaces != null) 'spaces': [spaces],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (teamDriveId != null) 'teamDriveId': [teamDriveId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'changes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ChangeList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Subscribes to changes for a user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response or to the response from the getStartPageToken method.
  ///
  /// [driveId] - The shared drive from which changes are returned. If specified
  /// the change IDs will be reflective of the shared drive; use the combined
  /// drive ID and change ID as an identifier.
  ///
  /// [includeCorpusRemovals] - Whether changes should include the file resource
  /// if the file is still accessible by the user at the time of the request,
  /// even when a file was removed from the list of changes and there will be no
  /// further change entries for this file.
  ///
  /// [includeItemsFromAllDrives] - Whether both My Drive and shared drive items
  /// should be included in results.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [includeRemoved] - Whether to include changes indicating that items have
  /// been removed from the list of changes, for example by deletion or loss of
  /// access.
  ///
  /// [includeTeamDriveItems] - Deprecated use includeItemsFromAllDrives
  /// instead.
  ///
  /// [pageSize] - The maximum number of changes to return per page.
  /// Value must be between "1" and "1000".
  ///
  /// [restrictToMyDrive] - Whether to restrict the results to changes inside
  /// the My Drive hierarchy. This omits changes to files such as those in the
  /// Application Data folder or shared files which have not been added to My
  /// Drive.
  ///
  /// [spaces] - A comma-separated list of spaces to query within the user
  /// corpus. Supported values are 'drive', 'appDataFolder' and 'photos'.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [teamDriveId] - Deprecated use driveId instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Channel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Channel> watch(
    Channel request,
    core.String pageToken, {
    core.String? driveId,
    core.bool? includeCorpusRemovals,
    core.bool? includeItemsFromAllDrives,
    core.String? includePermissionsForView,
    core.bool? includeRemoved,
    core.bool? includeTeamDriveItems,
    core.int? pageSize,
    core.bool? restrictToMyDrive,
    core.String? spaces,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? teamDriveId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'pageToken': [pageToken],
      if (driveId != null) 'driveId': [driveId],
      if (includeCorpusRemovals != null)
        'includeCorpusRemovals': ['${includeCorpusRemovals}'],
      if (includeItemsFromAllDrives != null)
        'includeItemsFromAllDrives': ['${includeItemsFromAllDrives}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (includeRemoved != null) 'includeRemoved': ['${includeRemoved}'],
      if (includeTeamDriveItems != null)
        'includeTeamDriveItems': ['${includeTeamDriveItems}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (restrictToMyDrive != null)
        'restrictToMyDrive': ['${restrictToMyDrive}'],
      if (spaces != null) 'spaces': [spaces],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (teamDriveId != null) 'teamDriveId': [teamDriveId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'changes/watch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ChannelsResource {
  final commons.ApiRequester _requester;

  ChannelsResource(commons.ApiRequester client) : _requester = client;

  /// Stop watching resources through this channel
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> stop(
    Channel request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'channels/stop';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class CommentsResource {
  final commons.ApiRequester _requester;

  CommentsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new comment on a file.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Comment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Comment> create(
    Comment request,
    core.String fileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/comments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Comment.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a comment.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String fileId,
    core.String commentId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a comment by ID.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [includeDeleted] - Whether to return deleted comments. Deleted comments
  /// will not include their original content.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Comment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Comment> get(
    core.String fileId,
    core.String commentId, {
    core.bool? includeDeleted,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Comment.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a file's comments.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [includeDeleted] - Whether to include deleted comments. Deleted comments
  /// will not include their original content.
  ///
  /// [pageSize] - The maximum number of comments to return per page.
  /// Value must be between "1" and "100".
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response.
  ///
  /// [startModifiedTime] - The minimum value of 'modifiedTime' for the result
  /// comments (RFC 3339 date-time).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CommentList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommentList> list(
    core.String fileId, {
    core.bool? includeDeleted,
    core.int? pageSize,
    core.String? pageToken,
    core.String? startModifiedTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startModifiedTime != null) 'startModifiedTime': [startModifiedTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/comments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CommentList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a comment with patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Comment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Comment> update(
    Comment request,
    core.String fileId,
    core.String commentId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Comment.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DrivesResource {
  final commons.ApiRequester _requester;

  DrivesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new shared drive.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [requestId] - An ID, such as a random UUID, which uniquely identifies this
  /// user's request for idempotent creation of a shared drive. A repeated
  /// request by the same user and with the same request ID will avoid creating
  /// duplicates by attempting to create the same shared drive. If the shared
  /// drive already exists a 409 error will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Drive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Drive> create(
    Drive request,
    core.String requestId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'requestId': [requestId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'drives';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Drive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Permanently deletes a shared drive for which the user is an organizer.
  ///
  /// The shared drive cannot contain any untrashed items.
  ///
  /// Request parameters:
  ///
  /// [driveId] - The ID of the shared drive.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String driveId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'drives/' + commons.escapeVariable('$driveId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a shared drive's metadata by ID.
  ///
  /// Request parameters:
  ///
  /// [driveId] - The ID of the shared drive.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if they are an
  /// administrator of the domain to which the shared drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Drive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Drive> get(
    core.String driveId, {
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'drives/' + commons.escapeVariable('$driveId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Drive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Hides a shared drive from the default view.
  ///
  /// Request parameters:
  ///
  /// [driveId] - The ID of the shared drive.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Drive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Drive> hide(
    core.String driveId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'drives/' + commons.escapeVariable('$driveId') + '/hide';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Drive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the user's shared drives.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Maximum number of shared drives to return.
  /// Value must be between "1" and "100".
  ///
  /// [pageToken] - Page token for shared drives.
  ///
  /// [q] - Query string for searching shared drives.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then all shared drives of the domain in which the requester
  /// is an administrator are returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DriveList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DriveList> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? q,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (q != null) 'q': [q],
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'drives';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DriveList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Restores a shared drive to the default view.
  ///
  /// Request parameters:
  ///
  /// [driveId] - The ID of the shared drive.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Drive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Drive> unhide(
    core.String driveId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'drives/' + commons.escapeVariable('$driveId') + '/unhide';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Drive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the metadate for a shared drive.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [driveId] - The ID of the shared drive.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if they are an
  /// administrator of the domain to which the shared drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Drive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Drive> update(
    Drive request,
    core.String driveId, {
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'drives/' + commons.escapeVariable('$driveId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Drive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class FilesResource {
  final commons.ApiRequester _requester;

  FilesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a copy of a file and applies any requested updates with patch
  /// semantics.
  ///
  /// Folders cannot be copied.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [enforceSingleParent] - Deprecated. Copying files into multiple folders is
  /// no longer supported. Use shortcuts instead.
  ///
  /// [ignoreDefaultVisibility] - Whether to ignore the domain's default
  /// visibility settings for the created file. Domain administrators can choose
  /// to make all uploaded files visible to the domain by default; this
  /// parameter bypasses that behavior for the request. Permissions are still
  /// inherited from parent folders.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [keepRevisionForever] - Whether to set the 'keepForever' field in the new
  /// head revision. This is only applicable to files with binary content in
  /// Google Drive. Only 200 revisions for the file can be kept forever. If the
  /// limit is reached, try deleting pinned revisions.
  ///
  /// [ocrLanguage] - A language hint for OCR processing during image import
  /// (ISO 639-1 code).
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [File].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<File> copy(
    File request,
    core.String fileId, {
    core.bool? enforceSingleParent,
    core.bool? ignoreDefaultVisibility,
    core.String? includePermissionsForView,
    core.bool? keepRevisionForever,
    core.String? ocrLanguage,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (ignoreDefaultVisibility != null)
        'ignoreDefaultVisibility': ['${ignoreDefaultVisibility}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (keepRevisionForever != null)
        'keepRevisionForever': ['${keepRevisionForever}'],
      if (ocrLanguage != null) 'ocrLanguage': [ocrLanguage],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/copy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new file.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enforceSingleParent] - Deprecated. Creating files in multiple folders is
  /// no longer supported.
  ///
  /// [ignoreDefaultVisibility] - Whether to ignore the domain's default
  /// visibility settings for the created file. Domain administrators can choose
  /// to make all uploaded files visible to the domain by default; this
  /// parameter bypasses that behavior for the request. Permissions are still
  /// inherited from parent folders.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [keepRevisionForever] - Whether to set the 'keepForever' field in the new
  /// head revision. This is only applicable to files with binary content in
  /// Google Drive. Only 200 revisions for the file can be kept forever. If the
  /// limit is reached, try deleting pinned revisions.
  ///
  /// [ocrLanguage] - A language hint for OCR processing during image import
  /// (ISO 639-1 code).
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [useContentAsIndexableText] - Whether to use the uploaded content as
  /// indexable text.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// [uploadOptions] - Options for the media upload. Streaming Media without
  /// the length being known ahead of time is only supported via resumable
  /// uploads.
  ///
  /// Completes with a [File].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<File> create(
    File request, {
    core.bool? enforceSingleParent,
    core.bool? ignoreDefaultVisibility,
    core.String? includePermissionsForView,
    core.bool? keepRevisionForever,
    core.String? ocrLanguage,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? useContentAsIndexableText,
    core.String? $fields,
    commons.UploadOptions uploadOptions = commons.UploadOptions.defaultOptions,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (ignoreDefaultVisibility != null)
        'ignoreDefaultVisibility': ['${ignoreDefaultVisibility}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (keepRevisionForever != null)
        'keepRevisionForever': ['${keepRevisionForever}'],
      if (ocrLanguage != null) 'ocrLanguage': [ocrLanguage],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (useContentAsIndexableText != null)
        'useContentAsIndexableText': ['${useContentAsIndexableText}'],
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'files';
    } else if (uploadOptions is commons.ResumableUploadOptions) {
      _url = '/resumable/upload/drive/v3/files';
    } else {
      _url = '/upload/drive/v3/files';
    }

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: uploadOptions,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Permanently deletes a file owned by the user without moving it to the
  /// trash.
  ///
  /// If the file belongs to a shared drive the user must be an organizer on the
  /// parent. If the target is a folder, all descendants owned by the user are
  /// also deleted.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [enforceSingleParent] - Deprecated. If an item is not in a shared drive
  /// and its last parent is deleted but the item itself is not, the item will
  /// be placed under its owner's root.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String fileId, {
    core.bool? enforceSingleParent,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Permanently deletes all of the user's trashed files.
  ///
  /// Request parameters:
  ///
  /// [enforceSingleParent] - Deprecated. If an item is not in a shared drive
  /// and its last parent is deleted but the item itself is not, the item will
  /// be placed under its owner's root.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> emptyTrash({
    core.bool? enforceSingleParent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'files/trash';

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Exports a Google Doc to the requested MIME type and returns the exported
  /// content.
  ///
  /// Please note that the exported content is limited to 10MB.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [mimeType] - The MIME type of the format requested for this export.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [downloadOptions] - Options for downloading. A download can be either a
  /// Metadata (default) or Media download. Partial Media downloads are possible
  /// as well.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<commons.Media?> export(
    core.String fileId,
    core.String mimeType, {
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'mimeType': [mimeType],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/export';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return null;
    } else {
      return _response as commons.Media;
    }
  }

  /// Generates a set of file IDs which can be provided in create or copy
  /// requests.
  ///
  /// Request parameters:
  ///
  /// [count] - The number of IDs to return.
  /// Value must be between "1" and "1000".
  ///
  /// [space] - The space in which the IDs can be used to create new files.
  /// Supported values are 'drive' and 'appDataFolder'. (Default: 'drive')
  ///
  /// [type] - The type of items which the IDs can be used for. Supported values
  /// are 'files' and 'shortcuts'. Note that 'shortcuts' are only supported in
  /// the drive 'space'. (Default: 'files')
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GeneratedIds].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GeneratedIds> generateIds({
    core.int? count,
    core.String? space,
    core.String? type,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (count != null) 'count': ['${count}'],
      if (space != null) 'space': [space],
      if (type != null) 'type': [type],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'files/generateIds';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GeneratedIds.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a file's metadata or content by ID.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [acknowledgeAbuse] - Whether the user is acknowledging the risk of
  /// downloading known malware or other abusive files. This is only applicable
  /// when alt=media.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
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
  /// - [File] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> get(
    core.String fileId, {
    core.bool? acknowledgeAbuse,
    core.String? includePermissionsForView,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acknowledgeAbuse != null) 'acknowledgeAbuse': ['${acknowledgeAbuse}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return File.fromJson(_response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }

  /// Lists or searches files.
  ///
  /// Request parameters:
  ///
  /// [corpora] - Groupings of files to which the query applies. Supported
  /// groupings are: 'user' (files created by, opened by, or shared directly
  /// with the user), 'drive' (files in the specified shared drive as indicated
  /// by the 'driveId'), 'domain' (files shared to the user's domain), and
  /// 'allDrives' (A combination of 'user' and 'drive' for all drives where the
  /// user is a member). When able, use 'user' or 'drive', instead of
  /// 'allDrives', for efficiency.
  ///
  /// [corpus] - The source of files to list. Deprecated: use 'corpora' instead.
  /// Possible string values are:
  /// - "domain" : Files shared to the user's domain.
  /// - "user" : Files owned by or shared to the user. If a user has permissions
  /// on a Shared Drive, the files inside it won't be retrieved unless the user
  /// has created, opened, or shared the file.
  ///
  /// [driveId] - ID of the shared drive to search.
  ///
  /// [includeItemsFromAllDrives] - Whether both My Drive and shared drive items
  /// should be included in results.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [includeTeamDriveItems] - Deprecated use includeItemsFromAllDrives
  /// instead.
  ///
  /// [orderBy] - A comma-separated list of sort keys. Valid keys are
  /// 'createdTime', 'folder', 'modifiedByMeTime', 'modifiedTime', 'name',
  /// 'name_natural', 'quotaBytesUsed', 'recency', 'sharedWithMeTime',
  /// 'starred', and 'viewedByMeTime'. Each key sorts ascending by default, but
  /// may be reversed with the 'desc' modifier. Example usage:
  /// ?orderBy=folder,modifiedTime desc,name. Please note that there is a
  /// current limitation for users with approximately one million files in which
  /// the requested sort order is ignored.
  ///
  /// [pageSize] - The maximum number of files to return per page. Partial or
  /// empty result pages are possible even before the end of the files list has
  /// been reached.
  /// Value must be between "1" and "1000".
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response.
  ///
  /// [q] - A query for filtering the file results. See the "Search for Files"
  /// guide for supported syntax.
  ///
  /// [spaces] - A comma-separated list of spaces to query within the corpus.
  /// Supported values are 'drive', 'appDataFolder' and 'photos'.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [teamDriveId] - Deprecated use driveId instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FileList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FileList> list({
    core.String? corpora,
    core.String? corpus,
    core.String? driveId,
    core.bool? includeItemsFromAllDrives,
    core.String? includePermissionsForView,
    core.bool? includeTeamDriveItems,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? q,
    core.String? spaces,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? teamDriveId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (corpora != null) 'corpora': [corpora],
      if (corpus != null) 'corpus': [corpus],
      if (driveId != null) 'driveId': [driveId],
      if (includeItemsFromAllDrives != null)
        'includeItemsFromAllDrives': ['${includeItemsFromAllDrives}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (includeTeamDriveItems != null)
        'includeTeamDriveItems': ['${includeTeamDriveItems}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (q != null) 'q': [q],
      if (spaces != null) 'spaces': [spaces],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (teamDriveId != null) 'teamDriveId': [teamDriveId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'files';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FileList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a file's metadata and/or content.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [addParents] - A comma-separated list of parent IDs to add.
  ///
  /// [enforceSingleParent] - Deprecated. Adding files to multiple folders is no
  /// longer supported. Use shortcuts instead.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [keepRevisionForever] - Whether to set the 'keepForever' field in the new
  /// head revision. This is only applicable to files with binary content in
  /// Google Drive. Only 200 revisions for the file can be kept forever. If the
  /// limit is reached, try deleting pinned revisions.
  ///
  /// [ocrLanguage] - A language hint for OCR processing during image import
  /// (ISO 639-1 code).
  ///
  /// [removeParents] - A comma-separated list of parent IDs to remove.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [useContentAsIndexableText] - Whether to use the uploaded content as
  /// indexable text.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// [uploadOptions] - Options for the media upload. Streaming Media without
  /// the length being known ahead of time is only supported via resumable
  /// uploads.
  ///
  /// Completes with a [File].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<File> update(
    File request,
    core.String fileId, {
    core.String? addParents,
    core.bool? enforceSingleParent,
    core.String? includePermissionsForView,
    core.bool? keepRevisionForever,
    core.String? ocrLanguage,
    core.String? removeParents,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? useContentAsIndexableText,
    core.String? $fields,
    commons.UploadOptions uploadOptions = commons.UploadOptions.defaultOptions,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (addParents != null) 'addParents': [addParents],
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (keepRevisionForever != null)
        'keepRevisionForever': ['${keepRevisionForever}'],
      if (ocrLanguage != null) 'ocrLanguage': [ocrLanguage],
      if (removeParents != null) 'removeParents': [removeParents],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (useContentAsIndexableText != null)
        'useContentAsIndexableText': ['${useContentAsIndexableText}'],
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'files/' + commons.escapeVariable('$fileId');
    } else if (uploadOptions is commons.ResumableUploadOptions) {
      _url = '/resumable/upload/drive/v3/files/' +
          commons.escapeVariable('$fileId');
    } else {
      _url = '/upload/drive/v3/files/' + commons.escapeVariable('$fileId');
    }

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: uploadOptions,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Subscribes to changes to a file
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [acknowledgeAbuse] - Whether the user is acknowledging the risk of
  /// downloading known malware or other abusive files. This is only applicable
  /// when alt=media.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
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
  /// - [Channel] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> watch(
    Channel request,
    core.String fileId, {
    core.bool? acknowledgeAbuse,
    core.String? includePermissionsForView,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (acknowledgeAbuse != null) 'acknowledgeAbuse': ['${acknowledgeAbuse}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/watch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }
}

class PermissionsResource {
  final commons.ApiRequester _requester;

  PermissionsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a permission for a file or shared drive.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file or shared drive.
  ///
  /// [emailMessage] - A plain text custom message to include in the
  /// notification email.
  ///
  /// [enforceSingleParent] - Deprecated. See moveToNewOwnersRoot for details.
  ///
  /// [moveToNewOwnersRoot] - This parameter will only take effect if the item
  /// is not in a shared drive and the request is attempting to transfer the
  /// ownership of the item. If set to true, the item will be moved to the new
  /// owner's My Drive root folder and all prior parents removed. If set to
  /// false, parents are not changed.
  ///
  /// [sendNotificationEmail] - Whether to send a notification email when
  /// sharing to users or groups. This defaults to true for users and groups,
  /// and is not allowed for other requests. It must not be disabled for
  /// ownership transfers.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [transferOwnership] - Whether to transfer ownership to the specified user
  /// and downgrade the current owner to a writer. This parameter is required as
  /// an acknowledgement of the side effect.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if the file ID
  /// parameter refers to a shared drive and the requester is an administrator
  /// of the domain to which the shared drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Permission].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Permission> create(
    Permission request,
    core.String fileId, {
    core.String? emailMessage,
    core.bool? enforceSingleParent,
    core.bool? moveToNewOwnersRoot,
    core.bool? sendNotificationEmail,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? transferOwnership,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (emailMessage != null) 'emailMessage': [emailMessage],
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (moveToNewOwnersRoot != null)
        'moveToNewOwnersRoot': ['${moveToNewOwnersRoot}'],
      if (sendNotificationEmail != null)
        'sendNotificationEmail': ['${sendNotificationEmail}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (transferOwnership != null)
        'transferOwnership': ['${transferOwnership}'],
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/permissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Permission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a permission.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file or shared drive.
  ///
  /// [permissionId] - The ID of the permission.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if the file ID
  /// parameter refers to a shared drive and the requester is an administrator
  /// of the domain to which the shared drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String fileId,
    core.String permissionId, {
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/permissions/' +
        commons.escapeVariable('$permissionId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a permission by ID.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [permissionId] - The ID of the permission.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if the file ID
  /// parameter refers to a shared drive and the requester is an administrator
  /// of the domain to which the shared drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Permission].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Permission> get(
    core.String fileId,
    core.String permissionId, {
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/permissions/' +
        commons.escapeVariable('$permissionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Permission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a file's or shared drive's permissions.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file or shared drive.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [pageSize] - The maximum number of permissions to return per page. When
  /// not set for files in a shared drive, at most 100 results will be returned.
  /// When not set for files that are not in a shared drive, the entire list
  /// will be returned.
  /// Value must be between "1" and "100".
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if the file ID
  /// parameter refers to a shared drive and the requester is an administrator
  /// of the domain to which the shared drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PermissionList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PermissionList> list(
    core.String fileId, {
    core.String? includePermissionsForView,
    core.int? pageSize,
    core.String? pageToken,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/permissions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PermissionList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a permission with patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file or shared drive.
  ///
  /// [permissionId] - The ID of the permission.
  ///
  /// [removeExpiration] - Whether to remove the expiration date.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [transferOwnership] - Whether to transfer ownership to the specified user
  /// and downgrade the current owner to a writer. This parameter is required as
  /// an acknowledgement of the side effect.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if the file ID
  /// parameter refers to a shared drive and the requester is an administrator
  /// of the domain to which the shared drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Permission].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Permission> update(
    Permission request,
    core.String fileId,
    core.String permissionId, {
    core.bool? removeExpiration,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? transferOwnership,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (removeExpiration != null) 'removeExpiration': ['${removeExpiration}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (transferOwnership != null)
        'transferOwnership': ['${transferOwnership}'],
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/permissions/' +
        commons.escapeVariable('$permissionId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Permission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RepliesResource {
  final commons.ApiRequester _requester;

  RepliesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new reply to a comment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Reply].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Reply> create(
    Reply request,
    core.String fileId,
    core.String commentId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId') +
        '/replies';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Reply.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a reply.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [replyId] - The ID of the reply.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String fileId,
    core.String commentId,
    core.String replyId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId') +
        '/replies/' +
        commons.escapeVariable('$replyId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a reply by ID.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [replyId] - The ID of the reply.
  ///
  /// [includeDeleted] - Whether to return deleted replies. Deleted replies will
  /// not include their original content.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Reply].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Reply> get(
    core.String fileId,
    core.String commentId,
    core.String replyId, {
    core.bool? includeDeleted,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId') +
        '/replies/' +
        commons.escapeVariable('$replyId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Reply.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a comment's replies.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [includeDeleted] - Whether to include deleted replies. Deleted replies
  /// will not include their original content.
  ///
  /// [pageSize] - The maximum number of replies to return per page.
  /// Value must be between "1" and "100".
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReplyList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReplyList> list(
    core.String fileId,
    core.String commentId, {
    core.bool? includeDeleted,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId') +
        '/replies';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReplyList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a reply with patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [replyId] - The ID of the reply.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Reply].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Reply> update(
    Reply request,
    core.String fileId,
    core.String commentId,
    core.String replyId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId') +
        '/replies/' +
        commons.escapeVariable('$replyId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Reply.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class RevisionsResource {
  final commons.ApiRequester _requester;

  RevisionsResource(commons.ApiRequester client) : _requester = client;

  /// Permanently deletes a file version.
  ///
  /// You can only delete revisions for files with binary content in Google
  /// Drive, like images or videos. Revisions for other files, like Google Docs
  /// or Sheets, and the last remaining file version can't be deleted.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [revisionId] - The ID of the revision.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String fileId,
    core.String revisionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/revisions/' +
        commons.escapeVariable('$revisionId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a revision's metadata or content by ID.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [revisionId] - The ID of the revision.
  ///
  /// [acknowledgeAbuse] - Whether the user is acknowledging the risk of
  /// downloading known malware or other abusive files. This is only applicable
  /// when alt=media.
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
  /// - [Revision] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> get(
    core.String fileId,
    core.String revisionId, {
    core.bool? acknowledgeAbuse,
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acknowledgeAbuse != null) 'acknowledgeAbuse': ['${acknowledgeAbuse}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/revisions/' +
        commons.escapeVariable('$revisionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return Revision.fromJson(
          _response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }

  /// Lists a file's revisions.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [pageSize] - The maximum number of revisions to return per page.
  /// Value must be between "1" and "1000".
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RevisionList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RevisionList> list(
    core.String fileId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/revisions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RevisionList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a revision with patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [revisionId] - The ID of the revision.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Revision].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Revision> update(
    Revision request,
    core.String fileId,
    core.String revisionId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/revisions/' +
        commons.escapeVariable('$revisionId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Revision.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class TeamdrivesResource {
  final commons.ApiRequester _requester;

  TeamdrivesResource(commons.ApiRequester client) : _requester = client;

  /// Deprecated use drives.create instead.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [requestId] - An ID, such as a random UUID, which uniquely identifies this
  /// user's request for idempotent creation of a Team Drive. A repeated request
  /// by the same user and with the same request ID will avoid creating
  /// duplicates by attempting to create the same Team Drive. If the Team Drive
  /// already exists a 409 error will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TeamDrive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TeamDrive> create(
    TeamDrive request,
    core.String requestId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'requestId': [requestId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'teamdrives';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TeamDrive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deprecated use drives.delete instead.
  ///
  /// Request parameters:
  ///
  /// [teamDriveId] - The ID of the Team Drive
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String teamDriveId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'teamdrives/' + commons.escapeVariable('$teamDriveId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Deprecated use drives.get instead.
  ///
  /// Request parameters:
  ///
  /// [teamDriveId] - The ID of the Team Drive
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if they are an
  /// administrator of the domain to which the Team Drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TeamDrive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TeamDrive> get(
    core.String teamDriveId, {
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'teamdrives/' + commons.escapeVariable('$teamDriveId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TeamDrive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deprecated use drives.list instead.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Maximum number of Team Drives to return.
  /// Value must be between "1" and "100".
  ///
  /// [pageToken] - Page token for Team Drives.
  ///
  /// [q] - Query string for searching Team Drives.
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then all Team Drives of the domain in which the requester is
  /// an administrator are returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TeamDriveList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TeamDriveList> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? q,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (q != null) 'q': [q],
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'teamdrives';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TeamDriveList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deprecated use drives.update instead
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [teamDriveId] - The ID of the Team Drive
  ///
  /// [useDomainAdminAccess] - Issue the request as a domain administrator; if
  /// set to true, then the requester will be granted access if they are an
  /// administrator of the domain to which the Team Drive belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TeamDrive].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TeamDrive> update(
    TeamDrive request,
    core.String teamDriveId, {
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'teamdrives/' + commons.escapeVariable('$teamDriveId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return TeamDrive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AboutDriveThemes {
  /// A link to this theme's background image.
  core.String? backgroundImageLink;

  /// The color of this theme as an RGB hex string.
  core.String? colorRgb;

  /// The ID of the theme.
  core.String? id;

  AboutDriveThemes();

  AboutDriveThemes.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundImageLink')) {
      backgroundImageLink = _json['backgroundImageLink'] as core.String;
    }
    if (_json.containsKey('colorRgb')) {
      colorRgb = _json['colorRgb'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundImageLink != null)
          'backgroundImageLink': backgroundImageLink!,
        if (colorRgb != null) 'colorRgb': colorRgb!,
        if (id != null) 'id': id!,
      };
}

/// The user's storage quota limits and usage.
///
/// All fields are measured in bytes.
class AboutStorageQuota {
  /// The usage limit, if applicable.
  ///
  /// This will not be present if the user has unlimited storage.
  core.String? limit;

  /// The total usage across all services.
  core.String? usage;

  /// The usage by all files in Google Drive.
  core.String? usageInDrive;

  /// The usage by trashed files in Google Drive.
  core.String? usageInDriveTrash;

  AboutStorageQuota();

  AboutStorageQuota.fromJson(core.Map _json) {
    if (_json.containsKey('limit')) {
      limit = _json['limit'] as core.String;
    }
    if (_json.containsKey('usage')) {
      usage = _json['usage'] as core.String;
    }
    if (_json.containsKey('usageInDrive')) {
      usageInDrive = _json['usageInDrive'] as core.String;
    }
    if (_json.containsKey('usageInDriveTrash')) {
      usageInDriveTrash = _json['usageInDriveTrash'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (limit != null) 'limit': limit!,
        if (usage != null) 'usage': usage!,
        if (usageInDrive != null) 'usageInDrive': usageInDrive!,
        if (usageInDriveTrash != null) 'usageInDriveTrash': usageInDriveTrash!,
      };
}

class AboutTeamDriveThemes {
  /// Deprecated - use driveThemes/backgroundImageLink instead.
  core.String? backgroundImageLink;

  /// Deprecated - use driveThemes/colorRgb instead.
  core.String? colorRgb;

  /// Deprecated - use driveThemes/id instead.
  core.String? id;

  AboutTeamDriveThemes();

  AboutTeamDriveThemes.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundImageLink')) {
      backgroundImageLink = _json['backgroundImageLink'] as core.String;
    }
    if (_json.containsKey('colorRgb')) {
      colorRgb = _json['colorRgb'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundImageLink != null)
          'backgroundImageLink': backgroundImageLink!,
        if (colorRgb != null) 'colorRgb': colorRgb!,
        if (id != null) 'id': id!,
      };
}

/// Information about the user, the user's Drive, and system capabilities.
class About {
  /// Whether the user has installed the requesting app.
  core.bool? appInstalled;

  /// Whether the user can create shared drives.
  core.bool? canCreateDrives;

  /// Deprecated - use canCreateDrives instead.
  core.bool? canCreateTeamDrives;

  /// A list of themes that are supported for shared drives.
  core.List<AboutDriveThemes>? driveThemes;

  /// A map of source MIME type to possible targets for all supported exports.
  core.Map<core.String, core.List<core.String>>? exportFormats;

  /// The currently supported folder colors as RGB hex strings.
  core.List<core.String>? folderColorPalette;

  /// A map of source MIME type to possible targets for all supported imports.
  core.Map<core.String, core.List<core.String>>? importFormats;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#about".
  core.String? kind;

  /// A map of maximum import sizes by MIME type, in bytes.
  core.Map<core.String, core.String>? maxImportSizes;

  /// The maximum upload size in bytes.
  core.String? maxUploadSize;

  /// The user's storage quota limits and usage.
  ///
  /// All fields are measured in bytes.
  AboutStorageQuota? storageQuota;

  /// Deprecated - use driveThemes instead.
  core.List<AboutTeamDriveThemes>? teamDriveThemes;

  /// The authenticated user.
  User? user;

  About();

  About.fromJson(core.Map _json) {
    if (_json.containsKey('appInstalled')) {
      appInstalled = _json['appInstalled'] as core.bool;
    }
    if (_json.containsKey('canCreateDrives')) {
      canCreateDrives = _json['canCreateDrives'] as core.bool;
    }
    if (_json.containsKey('canCreateTeamDrives')) {
      canCreateTeamDrives = _json['canCreateTeamDrives'] as core.bool;
    }
    if (_json.containsKey('driveThemes')) {
      driveThemes = (_json['driveThemes'] as core.List)
          .map<AboutDriveThemes>((value) => AboutDriveThemes.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('exportFormats')) {
      exportFormats =
          (_json['exportFormats'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          (item as core.List)
              .map<core.String>((value) => value as core.String)
              .toList(),
        ),
      );
    }
    if (_json.containsKey('folderColorPalette')) {
      folderColorPalette = (_json['folderColorPalette'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('importFormats')) {
      importFormats =
          (_json['importFormats'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          (item as core.List)
              .map<core.String>((value) => value as core.String)
              .toList(),
        ),
      );
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('maxImportSizes')) {
      maxImportSizes =
          (_json['maxImportSizes'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('maxUploadSize')) {
      maxUploadSize = _json['maxUploadSize'] as core.String;
    }
    if (_json.containsKey('storageQuota')) {
      storageQuota = AboutStorageQuota.fromJson(
          _json['storageQuota'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('teamDriveThemes')) {
      teamDriveThemes = (_json['teamDriveThemes'] as core.List)
          .map<AboutTeamDriveThemes>((value) => AboutTeamDriveThemes.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('user')) {
      user =
          User.fromJson(_json['user'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appInstalled != null) 'appInstalled': appInstalled!,
        if (canCreateDrives != null) 'canCreateDrives': canCreateDrives!,
        if (canCreateTeamDrives != null)
          'canCreateTeamDrives': canCreateTeamDrives!,
        if (driveThemes != null)
          'driveThemes': driveThemes!.map((value) => value.toJson()).toList(),
        if (exportFormats != null) 'exportFormats': exportFormats!,
        if (folderColorPalette != null)
          'folderColorPalette': folderColorPalette!,
        if (importFormats != null) 'importFormats': importFormats!,
        if (kind != null) 'kind': kind!,
        if (maxImportSizes != null) 'maxImportSizes': maxImportSizes!,
        if (maxUploadSize != null) 'maxUploadSize': maxUploadSize!,
        if (storageQuota != null) 'storageQuota': storageQuota!.toJson(),
        if (teamDriveThemes != null)
          'teamDriveThemes':
              teamDriveThemes!.map((value) => value.toJson()).toList(),
        if (user != null) 'user': user!.toJson(),
      };
}

/// A change to a file or shared drive.
class Change {
  /// The type of the change.
  ///
  /// Possible values are file and drive.
  core.String? changeType;

  /// The updated state of the shared drive.
  ///
  /// Present if the changeType is drive, the user is still a member of the
  /// shared drive, and the shared drive has not been deleted.
  Drive? drive;

  /// The ID of the shared drive associated with this change.
  core.String? driveId;

  /// The updated state of the file.
  ///
  /// Present if the type is file and the file has not been removed from this
  /// list of changes.
  File? file;

  /// The ID of the file which has changed.
  core.String? fileId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#change".
  core.String? kind;

  /// Whether the file or shared drive has been removed from this list of
  /// changes, for example by deletion or loss of access.
  core.bool? removed;

  /// Deprecated - use drive instead.
  TeamDrive? teamDrive;

  /// Deprecated - use driveId instead.
  core.String? teamDriveId;

  /// The time of this change (RFC 3339 date-time).
  core.DateTime? time;

  /// Deprecated - use changeType instead.
  core.String? type;

  Change();

  Change.fromJson(core.Map _json) {
    if (_json.containsKey('changeType')) {
      changeType = _json['changeType'] as core.String;
    }
    if (_json.containsKey('drive')) {
      drive =
          Drive.fromJson(_json['drive'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('driveId')) {
      driveId = _json['driveId'] as core.String;
    }
    if (_json.containsKey('file')) {
      file =
          File.fromJson(_json['file'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fileId')) {
      fileId = _json['fileId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('removed')) {
      removed = _json['removed'] as core.bool;
    }
    if (_json.containsKey('teamDrive')) {
      teamDrive = TeamDrive.fromJson(
          _json['teamDrive'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('teamDriveId')) {
      teamDriveId = _json['teamDriveId'] as core.String;
    }
    if (_json.containsKey('time')) {
      time = core.DateTime.parse(_json['time'] as core.String);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (changeType != null) 'changeType': changeType!,
        if (drive != null) 'drive': drive!.toJson(),
        if (driveId != null) 'driveId': driveId!,
        if (file != null) 'file': file!.toJson(),
        if (fileId != null) 'fileId': fileId!,
        if (kind != null) 'kind': kind!,
        if (removed != null) 'removed': removed!,
        if (teamDrive != null) 'teamDrive': teamDrive!.toJson(),
        if (teamDriveId != null) 'teamDriveId': teamDriveId!,
        if (time != null) 'time': time!.toIso8601String(),
        if (type != null) 'type': type!,
      };
}

/// A list of changes for a user.
class ChangeList {
  /// The list of changes.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Change>? changes;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#changeList".
  core.String? kind;

  /// The starting page token for future changes.
  ///
  /// This will be present only if the end of the current changes list has been
  /// reached.
  core.String? newStartPageToken;

  /// The page token for the next page of changes.
  ///
  /// This will be absent if the end of the changes list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  ChangeList();

  ChangeList.fromJson(core.Map _json) {
    if (_json.containsKey('changes')) {
      changes = (_json['changes'] as core.List)
          .map<Change>((value) =>
              Change.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newStartPageToken')) {
      newStartPageToken = _json['newStartPageToken'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (changes != null)
          'changes': changes!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (newStartPageToken != null) 'newStartPageToken': newStartPageToken!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// An notification channel used to watch for resource changes.
class Channel {
  /// The address where notifications are delivered for this channel.
  core.String? address;

  /// Date and time of notification channel expiration, expressed as a Unix
  /// timestamp, in milliseconds.
  ///
  /// Optional.
  core.String? expiration;

  /// A UUID or similar unique string that identifies this channel.
  core.String? id;

  /// Identifies this as a notification channel used to watch for changes to a
  /// resource, which is "api#channel".
  core.String? kind;

  /// Additional parameters controlling delivery channel behavior.
  ///
  /// Optional.
  core.Map<core.String, core.String>? params;

  /// A Boolean value to indicate whether payload is wanted.
  ///
  /// Optional.
  core.bool? payload;

  /// An opaque ID that identifies the resource being watched on this channel.
  ///
  /// Stable across different API versions.
  core.String? resourceId;

  /// A version-specific identifier for the watched resource.
  core.String? resourceUri;

  /// An arbitrary string delivered to the target address with each notification
  /// delivered over this channel.
  ///
  /// Optional.
  core.String? token;

  /// The type of delivery mechanism used for this channel.
  ///
  /// Valid values are "web_hook" (or "webhook"). Both values refer to a channel
  /// where Http requests are used to deliver messages.
  core.String? type;

  Channel();

  Channel.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('expiration')) {
      expiration = _json['expiration'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('params')) {
      params = (_json['params'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('payload')) {
      payload = _json['payload'] as core.bool;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (expiration != null) 'expiration': expiration!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (params != null) 'params': params!,
        if (payload != null) 'payload': payload!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
        if (token != null) 'token': token!,
        if (type != null) 'type': type!,
      };
}

/// The file content to which the comment refers, typically within the anchor
/// region.
///
/// For a text file, for example, this would be the text at the location of the
/// comment.
class CommentQuotedFileContent {
  /// The MIME type of the quoted content.
  core.String? mimeType;

  /// The quoted content itself.
  ///
  /// This is interpreted as plain text if set through the API.
  core.String? value;

  CommentQuotedFileContent();

  CommentQuotedFileContent.fromJson(core.Map _json) {
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mimeType != null) 'mimeType': mimeType!,
        if (value != null) 'value': value!,
      };
}

/// A comment on a file.
class Comment {
  /// A region of the document represented as a JSON string.
  ///
  /// For details on defining anchor properties, refer to Add comments and
  /// replies.
  core.String? anchor;

  /// The author of the comment.
  ///
  /// The author's email address and permission ID will not be populated.
  User? author;

  /// The plain text content of the comment.
  ///
  /// This field is used for setting the content, while htmlContent should be
  /// displayed.
  core.String? content;

  /// The time at which the comment was created (RFC 3339 date-time).
  core.DateTime? createdTime;

  /// Whether the comment has been deleted.
  ///
  /// A deleted comment has no content.
  core.bool? deleted;

  /// The content of the comment with HTML formatting.
  core.String? htmlContent;

  /// The ID of the comment.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#comment".
  core.String? kind;

  /// The last time the comment or any of its replies was modified (RFC 3339
  /// date-time).
  core.DateTime? modifiedTime;

  /// The file content to which the comment refers, typically within the anchor
  /// region.
  ///
  /// For a text file, for example, this would be the text at the location of
  /// the comment.
  CommentQuotedFileContent? quotedFileContent;

  /// The full list of replies to the comment in chronological order.
  core.List<Reply>? replies;

  /// Whether the comment has been resolved by one of its replies.
  core.bool? resolved;

  Comment();

  Comment.fromJson(core.Map _json) {
    if (_json.containsKey('anchor')) {
      anchor = _json['anchor'] as core.String;
    }
    if (_json.containsKey('author')) {
      author =
          User.fromJson(_json['author'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('createdTime')) {
      createdTime = core.DateTime.parse(_json['createdTime'] as core.String);
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('htmlContent')) {
      htmlContent = _json['htmlContent'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('modifiedTime')) {
      modifiedTime = core.DateTime.parse(_json['modifiedTime'] as core.String);
    }
    if (_json.containsKey('quotedFileContent')) {
      quotedFileContent = CommentQuotedFileContent.fromJson(
          _json['quotedFileContent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replies')) {
      replies = (_json['replies'] as core.List)
          .map<Reply>((value) =>
              Reply.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resolved')) {
      resolved = _json['resolved'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (anchor != null) 'anchor': anchor!,
        if (author != null) 'author': author!.toJson(),
        if (content != null) 'content': content!,
        if (createdTime != null) 'createdTime': createdTime!.toIso8601String(),
        if (deleted != null) 'deleted': deleted!,
        if (htmlContent != null) 'htmlContent': htmlContent!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (modifiedTime != null)
          'modifiedTime': modifiedTime!.toIso8601String(),
        if (quotedFileContent != null)
          'quotedFileContent': quotedFileContent!.toJson(),
        if (replies != null)
          'replies': replies!.map((value) => value.toJson()).toList(),
        if (resolved != null) 'resolved': resolved!,
      };
}

/// A list of comments on a file.
class CommentList {
  /// The list of comments.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Comment>? comments;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#commentList".
  core.String? kind;

  /// The page token for the next page of comments.
  ///
  /// This will be absent if the end of the comments list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  CommentList();

  CommentList.fromJson(core.Map _json) {
    if (_json.containsKey('comments')) {
      comments = (_json['comments'] as core.List)
          .map<Comment>((value) =>
              Comment.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (comments != null)
          'comments': comments!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A restriction for accessing the content of the file.
class ContentRestriction {
  /// Whether the content of the file is read-only.
  ///
  /// If a file is read-only, a new revision of the file may not be added,
  /// comments may not be added or modified, and the title of the file may not
  /// be modified.
  core.bool? readOnly;

  /// Reason for why the content of the file is restricted.
  ///
  /// This is only mutable on requests that also set readOnly=true.
  core.String? reason;

  /// The user who set the content restriction.
  ///
  /// Only populated if readOnly is true.
  User? restrictingUser;

  /// The time at which the content restriction was set (formatted RFC 3339
  /// timestamp).
  ///
  /// Only populated if readOnly is true.
  core.DateTime? restrictionTime;

  /// The type of the content restriction.
  ///
  /// Currently the only possible value is globalContentRestriction.
  core.String? type;

  ContentRestriction();

  ContentRestriction.fromJson(core.Map _json) {
    if (_json.containsKey('readOnly')) {
      readOnly = _json['readOnly'] as core.bool;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('restrictingUser')) {
      restrictingUser = User.fromJson(
          _json['restrictingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('restrictionTime')) {
      restrictionTime =
          core.DateTime.parse(_json['restrictionTime'] as core.String);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (readOnly != null) 'readOnly': readOnly!,
        if (reason != null) 'reason': reason!,
        if (restrictingUser != null)
          'restrictingUser': restrictingUser!.toJson(),
        if (restrictionTime != null)
          'restrictionTime': restrictionTime!.toIso8601String(),
        if (type != null) 'type': type!,
      };
}

/// An image file and cropping parameters from which a background image for this
/// shared drive is set.
///
/// This is a write only field; it can only be set on drive.drives.update
/// requests that don't set themeId. When specified, all fields of the
/// backgroundImageFile must be set.
class DriveBackgroundImageFile {
  /// The ID of an image file in Google Drive to use for the background image.
  core.String? id;

  /// The width of the cropped image in the closed range of 0 to 1.
  ///
  /// This value represents the width of the cropped image divided by the width
  /// of the entire image. The height is computed by applying a width to height
  /// aspect ratio of 80 to 9. The resulting image must be at least 1280 pixels
  /// wide and 144 pixels high.
  core.double? width;

  /// The X coordinate of the upper left corner of the cropping area in the
  /// background image.
  ///
  /// This is a value in the closed range of 0 to 1. This value represents the
  /// horizontal distance from the left side of the entire image to the left
  /// side of the cropping area divided by the width of the entire image.
  core.double? xCoordinate;

  /// The Y coordinate of the upper left corner of the cropping area in the
  /// background image.
  ///
  /// This is a value in the closed range of 0 to 1. This value represents the
  /// vertical distance from the top side of the entire image to the top side of
  /// the cropping area divided by the height of the entire image.
  core.double? yCoordinate;

  DriveBackgroundImageFile();

  DriveBackgroundImageFile.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = (_json['width'] as core.num).toDouble();
    }
    if (_json.containsKey('xCoordinate')) {
      xCoordinate = (_json['xCoordinate'] as core.num).toDouble();
    }
    if (_json.containsKey('yCoordinate')) {
      yCoordinate = (_json['yCoordinate'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (width != null) 'width': width!,
        if (xCoordinate != null) 'xCoordinate': xCoordinate!,
        if (yCoordinate != null) 'yCoordinate': yCoordinate!,
      };
}

/// Capabilities the current user has on this shared drive.
class DriveCapabilities {
  /// Whether the current user can add children to folders in this shared drive.
  core.bool? canAddChildren;

  /// Whether the current user can change the copyRequiresWriterPermission
  /// restriction of this shared drive.
  core.bool? canChangeCopyRequiresWriterPermissionRestriction;

  /// Whether the current user can change the domainUsersOnly restriction of
  /// this shared drive.
  core.bool? canChangeDomainUsersOnlyRestriction;

  /// Whether the current user can change the background of this shared drive.
  core.bool? canChangeDriveBackground;

  /// Whether the current user can change the driveMembersOnly restriction of
  /// this shared drive.
  core.bool? canChangeDriveMembersOnlyRestriction;

  /// Whether the current user can comment on files in this shared drive.
  core.bool? canComment;

  /// Whether the current user can copy files in this shared drive.
  core.bool? canCopy;

  /// Whether the current user can delete children from folders in this shared
  /// drive.
  core.bool? canDeleteChildren;

  /// Whether the current user can delete this shared drive.
  ///
  /// Attempting to delete the shared drive may still fail if there are
  /// untrashed items inside the shared drive.
  core.bool? canDeleteDrive;

  /// Whether the current user can download files in this shared drive.
  core.bool? canDownload;

  /// Whether the current user can edit files in this shared drive
  core.bool? canEdit;

  /// Whether the current user can list the children of folders in this shared
  /// drive.
  core.bool? canListChildren;

  /// Whether the current user can add members to this shared drive or remove
  /// them or change their role.
  core.bool? canManageMembers;

  /// Whether the current user can read the revisions resource of files in this
  /// shared drive.
  core.bool? canReadRevisions;

  /// Whether the current user can rename files or folders in this shared drive.
  core.bool? canRename;

  /// Whether the current user can rename this shared drive.
  core.bool? canRenameDrive;

  /// Whether the current user can share files or folders in this shared drive.
  core.bool? canShare;

  /// Whether the current user can trash children from folders in this shared
  /// drive.
  core.bool? canTrashChildren;

  DriveCapabilities();

  DriveCapabilities.fromJson(core.Map _json) {
    if (_json.containsKey('canAddChildren')) {
      canAddChildren = _json['canAddChildren'] as core.bool;
    }
    if (_json.containsKey('canChangeCopyRequiresWriterPermissionRestriction')) {
      canChangeCopyRequiresWriterPermissionRestriction =
          _json['canChangeCopyRequiresWriterPermissionRestriction']
              as core.bool;
    }
    if (_json.containsKey('canChangeDomainUsersOnlyRestriction')) {
      canChangeDomainUsersOnlyRestriction =
          _json['canChangeDomainUsersOnlyRestriction'] as core.bool;
    }
    if (_json.containsKey('canChangeDriveBackground')) {
      canChangeDriveBackground = _json['canChangeDriveBackground'] as core.bool;
    }
    if (_json.containsKey('canChangeDriveMembersOnlyRestriction')) {
      canChangeDriveMembersOnlyRestriction =
          _json['canChangeDriveMembersOnlyRestriction'] as core.bool;
    }
    if (_json.containsKey('canComment')) {
      canComment = _json['canComment'] as core.bool;
    }
    if (_json.containsKey('canCopy')) {
      canCopy = _json['canCopy'] as core.bool;
    }
    if (_json.containsKey('canDeleteChildren')) {
      canDeleteChildren = _json['canDeleteChildren'] as core.bool;
    }
    if (_json.containsKey('canDeleteDrive')) {
      canDeleteDrive = _json['canDeleteDrive'] as core.bool;
    }
    if (_json.containsKey('canDownload')) {
      canDownload = _json['canDownload'] as core.bool;
    }
    if (_json.containsKey('canEdit')) {
      canEdit = _json['canEdit'] as core.bool;
    }
    if (_json.containsKey('canListChildren')) {
      canListChildren = _json['canListChildren'] as core.bool;
    }
    if (_json.containsKey('canManageMembers')) {
      canManageMembers = _json['canManageMembers'] as core.bool;
    }
    if (_json.containsKey('canReadRevisions')) {
      canReadRevisions = _json['canReadRevisions'] as core.bool;
    }
    if (_json.containsKey('canRename')) {
      canRename = _json['canRename'] as core.bool;
    }
    if (_json.containsKey('canRenameDrive')) {
      canRenameDrive = _json['canRenameDrive'] as core.bool;
    }
    if (_json.containsKey('canShare')) {
      canShare = _json['canShare'] as core.bool;
    }
    if (_json.containsKey('canTrashChildren')) {
      canTrashChildren = _json['canTrashChildren'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canAddChildren != null) 'canAddChildren': canAddChildren!,
        if (canChangeCopyRequiresWriterPermissionRestriction != null)
          'canChangeCopyRequiresWriterPermissionRestriction':
              canChangeCopyRequiresWriterPermissionRestriction!,
        if (canChangeDomainUsersOnlyRestriction != null)
          'canChangeDomainUsersOnlyRestriction':
              canChangeDomainUsersOnlyRestriction!,
        if (canChangeDriveBackground != null)
          'canChangeDriveBackground': canChangeDriveBackground!,
        if (canChangeDriveMembersOnlyRestriction != null)
          'canChangeDriveMembersOnlyRestriction':
              canChangeDriveMembersOnlyRestriction!,
        if (canComment != null) 'canComment': canComment!,
        if (canCopy != null) 'canCopy': canCopy!,
        if (canDeleteChildren != null) 'canDeleteChildren': canDeleteChildren!,
        if (canDeleteDrive != null) 'canDeleteDrive': canDeleteDrive!,
        if (canDownload != null) 'canDownload': canDownload!,
        if (canEdit != null) 'canEdit': canEdit!,
        if (canListChildren != null) 'canListChildren': canListChildren!,
        if (canManageMembers != null) 'canManageMembers': canManageMembers!,
        if (canReadRevisions != null) 'canReadRevisions': canReadRevisions!,
        if (canRename != null) 'canRename': canRename!,
        if (canRenameDrive != null) 'canRenameDrive': canRenameDrive!,
        if (canShare != null) 'canShare': canShare!,
        if (canTrashChildren != null) 'canTrashChildren': canTrashChildren!,
      };
}

/// A set of restrictions that apply to this shared drive or items inside this
/// shared drive.
class DriveRestrictions {
  /// Whether administrative privileges on this shared drive are required to
  /// modify restrictions.
  core.bool? adminManagedRestrictions;

  /// Whether the options to copy, print, or download files inside this shared
  /// drive, should be disabled for readers and commenters.
  ///
  /// When this restriction is set to true, it will override the similarly named
  /// field to true for any file inside this shared drive.
  core.bool? copyRequiresWriterPermission;

  /// Whether access to this shared drive and items inside this shared drive is
  /// restricted to users of the domain to which this shared drive belongs.
  ///
  /// This restriction may be overridden by other sharing policies controlled
  /// outside of this shared drive.
  core.bool? domainUsersOnly;

  /// Whether access to items inside this shared drive is restricted to its
  /// members.
  core.bool? driveMembersOnly;

  DriveRestrictions();

  DriveRestrictions.fromJson(core.Map _json) {
    if (_json.containsKey('adminManagedRestrictions')) {
      adminManagedRestrictions = _json['adminManagedRestrictions'] as core.bool;
    }
    if (_json.containsKey('copyRequiresWriterPermission')) {
      copyRequiresWriterPermission =
          _json['copyRequiresWriterPermission'] as core.bool;
    }
    if (_json.containsKey('domainUsersOnly')) {
      domainUsersOnly = _json['domainUsersOnly'] as core.bool;
    }
    if (_json.containsKey('driveMembersOnly')) {
      driveMembersOnly = _json['driveMembersOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adminManagedRestrictions != null)
          'adminManagedRestrictions': adminManagedRestrictions!,
        if (copyRequiresWriterPermission != null)
          'copyRequiresWriterPermission': copyRequiresWriterPermission!,
        if (domainUsersOnly != null) 'domainUsersOnly': domainUsersOnly!,
        if (driveMembersOnly != null) 'driveMembersOnly': driveMembersOnly!,
      };
}

/// Representation of a shared drive.
class Drive {
  /// An image file and cropping parameters from which a background image for
  /// this shared drive is set.
  ///
  /// This is a write only field; it can only be set on drive.drives.update
  /// requests that don't set themeId. When specified, all fields of the
  /// backgroundImageFile must be set.
  DriveBackgroundImageFile? backgroundImageFile;

  /// A short-lived link to this shared drive's background image.
  core.String? backgroundImageLink;

  /// Capabilities the current user has on this shared drive.
  DriveCapabilities? capabilities;

  /// The color of this shared drive as an RGB hex string.
  ///
  /// It can only be set on a drive.drives.update request that does not set
  /// themeId.
  core.String? colorRgb;

  /// The time at which the shared drive was created (RFC 3339 date-time).
  core.DateTime? createdTime;

  /// Whether the shared drive is hidden from default view.
  core.bool? hidden;

  /// The ID of this shared drive which is also the ID of the top level folder
  /// of this shared drive.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#drive".
  core.String? kind;

  /// The name of this shared drive.
  core.String? name;

  /// A set of restrictions that apply to this shared drive or items inside this
  /// shared drive.
  DriveRestrictions? restrictions;

  /// The ID of the theme from which the background image and color will be set.
  ///
  /// The set of possible driveThemes can be retrieved from a drive.about.get
  /// response. When not specified on a drive.drives.create request, a random
  /// theme is chosen from which the background image and color are set. This is
  /// a write-only field; it can only be set on requests that don't set colorRgb
  /// or backgroundImageFile.
  core.String? themeId;

  Drive();

  Drive.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundImageFile')) {
      backgroundImageFile = DriveBackgroundImageFile.fromJson(
          _json['backgroundImageFile'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('backgroundImageLink')) {
      backgroundImageLink = _json['backgroundImageLink'] as core.String;
    }
    if (_json.containsKey('capabilities')) {
      capabilities = DriveCapabilities.fromJson(
          _json['capabilities'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorRgb')) {
      colorRgb = _json['colorRgb'] as core.String;
    }
    if (_json.containsKey('createdTime')) {
      createdTime = core.DateTime.parse(_json['createdTime'] as core.String);
    }
    if (_json.containsKey('hidden')) {
      hidden = _json['hidden'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('restrictions')) {
      restrictions = DriveRestrictions.fromJson(
          _json['restrictions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('themeId')) {
      themeId = _json['themeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundImageFile != null)
          'backgroundImageFile': backgroundImageFile!.toJson(),
        if (backgroundImageLink != null)
          'backgroundImageLink': backgroundImageLink!,
        if (capabilities != null) 'capabilities': capabilities!.toJson(),
        if (colorRgb != null) 'colorRgb': colorRgb!,
        if (createdTime != null) 'createdTime': createdTime!.toIso8601String(),
        if (hidden != null) 'hidden': hidden!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (restrictions != null) 'restrictions': restrictions!.toJson(),
        if (themeId != null) 'themeId': themeId!,
      };
}

/// A list of shared drives.
class DriveList {
  /// The list of shared drives.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Drive>? drives;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#driveList".
  core.String? kind;

  /// The page token for the next page of shared drives.
  ///
  /// This will be absent if the end of the list has been reached. If the token
  /// is rejected for any reason, it should be discarded, and pagination should
  /// be restarted from the first page of results.
  core.String? nextPageToken;

  DriveList();

  DriveList.fromJson(core.Map _json) {
    if (_json.containsKey('drives')) {
      drives = (_json['drives'] as core.List)
          .map<Drive>((value) =>
              Drive.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (drives != null)
          'drives': drives!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Capabilities the current user has on this file.
///
/// Each capability corresponds to a fine-grained action that a user may take.
class FileCapabilities {
  /// Whether the current user can add children to this folder.
  ///
  /// This is always false when the item is not a folder.
  core.bool? canAddChildren;

  /// Whether the current user can add a folder from another drive (different
  /// shared drive or My Drive) to this folder.
  ///
  /// This is false when the item is not a folder. Only populated for items in
  /// shared drives.
  core.bool? canAddFolderFromAnotherDrive;

  /// Whether the current user can add a parent for the item without removing an
  /// existing parent in the same request.
  ///
  /// Not populated for shared drive files.
  core.bool? canAddMyDriveParent;

  /// Whether the current user can change the copyRequiresWriterPermission
  /// restriction of this file.
  core.bool? canChangeCopyRequiresWriterPermission;

  /// Deprecated
  core.bool? canChangeViewersCanCopyContent;

  /// Whether the current user can comment on this file.
  core.bool? canComment;

  /// Whether the current user can copy this file.
  ///
  /// For an item in a shared drive, whether the current user can copy
  /// non-folder descendants of this item, or this item itself if it is not a
  /// folder.
  core.bool? canCopy;

  /// Whether the current user can delete this file.
  core.bool? canDelete;

  /// Whether the current user can delete children of this folder.
  ///
  /// This is false when the item is not a folder. Only populated for items in
  /// shared drives.
  core.bool? canDeleteChildren;

  /// Whether the current user can download this file.
  core.bool? canDownload;

  /// Whether the current user can edit this file.
  ///
  /// Other factors may limit the type of changes a user can make to a file. For
  /// example, see canChangeCopyRequiresWriterPermission or canModifyContent.
  core.bool? canEdit;

  /// Whether the current user can list the children of this folder.
  ///
  /// This is always false when the item is not a folder.
  core.bool? canListChildren;

  /// Whether the current user can modify the content of this file.
  core.bool? canModifyContent;

  /// Whether the current user can modify restrictions on content of this file.
  core.bool? canModifyContentRestriction;

  /// Whether the current user can move children of this folder outside of the
  /// shared drive.
  ///
  /// This is false when the item is not a folder. Only populated for items in
  /// shared drives.
  core.bool? canMoveChildrenOutOfDrive;

  /// Deprecated - use canMoveChildrenOutOfDrive instead.
  core.bool? canMoveChildrenOutOfTeamDrive;

  /// Whether the current user can move children of this folder within this
  /// drive.
  ///
  /// This is false when the item is not a folder. Note that a request to move
  /// the child may still fail depending on the current user's access to the
  /// child and to the destination folder.
  core.bool? canMoveChildrenWithinDrive;

  /// Deprecated - use canMoveChildrenWithinDrive instead.
  core.bool? canMoveChildrenWithinTeamDrive;

  /// Deprecated - use canMoveItemOutOfDrive instead.
  core.bool? canMoveItemIntoTeamDrive;

  /// Whether the current user can move this item outside of this drive by
  /// changing its parent.
  ///
  /// Note that a request to change the parent of the item may still fail
  /// depending on the new parent that is being added.
  core.bool? canMoveItemOutOfDrive;

  /// Deprecated - use canMoveItemOutOfDrive instead.
  core.bool? canMoveItemOutOfTeamDrive;

  /// Whether the current user can move this item within this drive.
  ///
  /// Note that a request to change the parent of the item may still fail
  /// depending on the new parent that is being added and the parent that is
  /// being removed.
  core.bool? canMoveItemWithinDrive;

  /// Deprecated - use canMoveItemWithinDrive instead.
  core.bool? canMoveItemWithinTeamDrive;

  /// Deprecated - use canMoveItemWithinDrive or canMoveItemOutOfDrive instead.
  core.bool? canMoveTeamDriveItem;

  /// Whether the current user can read the shared drive to which this file
  /// belongs.
  ///
  /// Only populated for items in shared drives.
  core.bool? canReadDrive;

  /// Whether the current user can read the revisions resource of this file.
  ///
  /// For a shared drive item, whether revisions of non-folder descendants of
  /// this item, or this item itself if it is not a folder, can be read.
  core.bool? canReadRevisions;

  /// Deprecated - use canReadDrive instead.
  core.bool? canReadTeamDrive;

  /// Whether the current user can remove children from this folder.
  ///
  /// This is always false when the item is not a folder. For a folder in a
  /// shared drive, use canDeleteChildren or canTrashChildren instead.
  core.bool? canRemoveChildren;

  /// Whether the current user can remove a parent from the item without adding
  /// another parent in the same request.
  ///
  /// Not populated for shared drive files.
  core.bool? canRemoveMyDriveParent;

  /// Whether the current user can rename this file.
  core.bool? canRename;

  /// Whether the current user can modify the sharing settings for this file.
  core.bool? canShare;

  /// Whether the current user can move this file to trash.
  core.bool? canTrash;

  /// Whether the current user can trash children of this folder.
  ///
  /// This is false when the item is not a folder. Only populated for items in
  /// shared drives.
  core.bool? canTrashChildren;

  /// Whether the current user can restore this file from trash.
  core.bool? canUntrash;

  FileCapabilities();

  FileCapabilities.fromJson(core.Map _json) {
    if (_json.containsKey('canAddChildren')) {
      canAddChildren = _json['canAddChildren'] as core.bool;
    }
    if (_json.containsKey('canAddFolderFromAnotherDrive')) {
      canAddFolderFromAnotherDrive =
          _json['canAddFolderFromAnotherDrive'] as core.bool;
    }
    if (_json.containsKey('canAddMyDriveParent')) {
      canAddMyDriveParent = _json['canAddMyDriveParent'] as core.bool;
    }
    if (_json.containsKey('canChangeCopyRequiresWriterPermission')) {
      canChangeCopyRequiresWriterPermission =
          _json['canChangeCopyRequiresWriterPermission'] as core.bool;
    }
    if (_json.containsKey('canChangeViewersCanCopyContent')) {
      canChangeViewersCanCopyContent =
          _json['canChangeViewersCanCopyContent'] as core.bool;
    }
    if (_json.containsKey('canComment')) {
      canComment = _json['canComment'] as core.bool;
    }
    if (_json.containsKey('canCopy')) {
      canCopy = _json['canCopy'] as core.bool;
    }
    if (_json.containsKey('canDelete')) {
      canDelete = _json['canDelete'] as core.bool;
    }
    if (_json.containsKey('canDeleteChildren')) {
      canDeleteChildren = _json['canDeleteChildren'] as core.bool;
    }
    if (_json.containsKey('canDownload')) {
      canDownload = _json['canDownload'] as core.bool;
    }
    if (_json.containsKey('canEdit')) {
      canEdit = _json['canEdit'] as core.bool;
    }
    if (_json.containsKey('canListChildren')) {
      canListChildren = _json['canListChildren'] as core.bool;
    }
    if (_json.containsKey('canModifyContent')) {
      canModifyContent = _json['canModifyContent'] as core.bool;
    }
    if (_json.containsKey('canModifyContentRestriction')) {
      canModifyContentRestriction =
          _json['canModifyContentRestriction'] as core.bool;
    }
    if (_json.containsKey('canMoveChildrenOutOfDrive')) {
      canMoveChildrenOutOfDrive =
          _json['canMoveChildrenOutOfDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveChildrenOutOfTeamDrive')) {
      canMoveChildrenOutOfTeamDrive =
          _json['canMoveChildrenOutOfTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveChildrenWithinDrive')) {
      canMoveChildrenWithinDrive =
          _json['canMoveChildrenWithinDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveChildrenWithinTeamDrive')) {
      canMoveChildrenWithinTeamDrive =
          _json['canMoveChildrenWithinTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveItemIntoTeamDrive')) {
      canMoveItemIntoTeamDrive = _json['canMoveItemIntoTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveItemOutOfDrive')) {
      canMoveItemOutOfDrive = _json['canMoveItemOutOfDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveItemOutOfTeamDrive')) {
      canMoveItemOutOfTeamDrive =
          _json['canMoveItemOutOfTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveItemWithinDrive')) {
      canMoveItemWithinDrive = _json['canMoveItemWithinDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveItemWithinTeamDrive')) {
      canMoveItemWithinTeamDrive =
          _json['canMoveItemWithinTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canMoveTeamDriveItem')) {
      canMoveTeamDriveItem = _json['canMoveTeamDriveItem'] as core.bool;
    }
    if (_json.containsKey('canReadDrive')) {
      canReadDrive = _json['canReadDrive'] as core.bool;
    }
    if (_json.containsKey('canReadRevisions')) {
      canReadRevisions = _json['canReadRevisions'] as core.bool;
    }
    if (_json.containsKey('canReadTeamDrive')) {
      canReadTeamDrive = _json['canReadTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canRemoveChildren')) {
      canRemoveChildren = _json['canRemoveChildren'] as core.bool;
    }
    if (_json.containsKey('canRemoveMyDriveParent')) {
      canRemoveMyDriveParent = _json['canRemoveMyDriveParent'] as core.bool;
    }
    if (_json.containsKey('canRename')) {
      canRename = _json['canRename'] as core.bool;
    }
    if (_json.containsKey('canShare')) {
      canShare = _json['canShare'] as core.bool;
    }
    if (_json.containsKey('canTrash')) {
      canTrash = _json['canTrash'] as core.bool;
    }
    if (_json.containsKey('canTrashChildren')) {
      canTrashChildren = _json['canTrashChildren'] as core.bool;
    }
    if (_json.containsKey('canUntrash')) {
      canUntrash = _json['canUntrash'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canAddChildren != null) 'canAddChildren': canAddChildren!,
        if (canAddFolderFromAnotherDrive != null)
          'canAddFolderFromAnotherDrive': canAddFolderFromAnotherDrive!,
        if (canAddMyDriveParent != null)
          'canAddMyDriveParent': canAddMyDriveParent!,
        if (canChangeCopyRequiresWriterPermission != null)
          'canChangeCopyRequiresWriterPermission':
              canChangeCopyRequiresWriterPermission!,
        if (canChangeViewersCanCopyContent != null)
          'canChangeViewersCanCopyContent': canChangeViewersCanCopyContent!,
        if (canComment != null) 'canComment': canComment!,
        if (canCopy != null) 'canCopy': canCopy!,
        if (canDelete != null) 'canDelete': canDelete!,
        if (canDeleteChildren != null) 'canDeleteChildren': canDeleteChildren!,
        if (canDownload != null) 'canDownload': canDownload!,
        if (canEdit != null) 'canEdit': canEdit!,
        if (canListChildren != null) 'canListChildren': canListChildren!,
        if (canModifyContent != null) 'canModifyContent': canModifyContent!,
        if (canModifyContentRestriction != null)
          'canModifyContentRestriction': canModifyContentRestriction!,
        if (canMoveChildrenOutOfDrive != null)
          'canMoveChildrenOutOfDrive': canMoveChildrenOutOfDrive!,
        if (canMoveChildrenOutOfTeamDrive != null)
          'canMoveChildrenOutOfTeamDrive': canMoveChildrenOutOfTeamDrive!,
        if (canMoveChildrenWithinDrive != null)
          'canMoveChildrenWithinDrive': canMoveChildrenWithinDrive!,
        if (canMoveChildrenWithinTeamDrive != null)
          'canMoveChildrenWithinTeamDrive': canMoveChildrenWithinTeamDrive!,
        if (canMoveItemIntoTeamDrive != null)
          'canMoveItemIntoTeamDrive': canMoveItemIntoTeamDrive!,
        if (canMoveItemOutOfDrive != null)
          'canMoveItemOutOfDrive': canMoveItemOutOfDrive!,
        if (canMoveItemOutOfTeamDrive != null)
          'canMoveItemOutOfTeamDrive': canMoveItemOutOfTeamDrive!,
        if (canMoveItemWithinDrive != null)
          'canMoveItemWithinDrive': canMoveItemWithinDrive!,
        if (canMoveItemWithinTeamDrive != null)
          'canMoveItemWithinTeamDrive': canMoveItemWithinTeamDrive!,
        if (canMoveTeamDriveItem != null)
          'canMoveTeamDriveItem': canMoveTeamDriveItem!,
        if (canReadDrive != null) 'canReadDrive': canReadDrive!,
        if (canReadRevisions != null) 'canReadRevisions': canReadRevisions!,
        if (canReadTeamDrive != null) 'canReadTeamDrive': canReadTeamDrive!,
        if (canRemoveChildren != null) 'canRemoveChildren': canRemoveChildren!,
        if (canRemoveMyDriveParent != null)
          'canRemoveMyDriveParent': canRemoveMyDriveParent!,
        if (canRename != null) 'canRename': canRename!,
        if (canShare != null) 'canShare': canShare!,
        if (canTrash != null) 'canTrash': canTrash!,
        if (canTrashChildren != null) 'canTrashChildren': canTrashChildren!,
        if (canUntrash != null) 'canUntrash': canUntrash!,
      };
}

/// A thumbnail for the file.
///
/// This will only be used if Google Drive cannot generate a standard thumbnail.
class FileContentHintsThumbnail {
  /// The thumbnail data encoded with URL-safe Base64 (RFC 4648 section 5).
  core.String? image;
  core.List<core.int> get imageAsBytes => convert.base64.decode(image!);

  set imageAsBytes(core.List<core.int> _bytes) {
    image =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The MIME type of the thumbnail.
  core.String? mimeType;

  FileContentHintsThumbnail();

  FileContentHintsThumbnail.fromJson(core.Map _json) {
    if (_json.containsKey('image')) {
      image = _json['image'] as core.String;
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (image != null) 'image': image!,
        if (mimeType != null) 'mimeType': mimeType!,
      };
}

/// Additional information about the content of the file.
///
/// These fields are never populated in responses.
class FileContentHints {
  /// Text to be indexed for the file to improve fullText queries.
  ///
  /// This is limited to 128KB in length and may contain HTML elements.
  core.String? indexableText;

  /// A thumbnail for the file.
  ///
  /// This will only be used if Google Drive cannot generate a standard
  /// thumbnail.
  FileContentHintsThumbnail? thumbnail;

  FileContentHints();

  FileContentHints.fromJson(core.Map _json) {
    if (_json.containsKey('indexableText')) {
      indexableText = _json['indexableText'] as core.String;
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = FileContentHintsThumbnail.fromJson(
          _json['thumbnail'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (indexableText != null) 'indexableText': indexableText!,
        if (thumbnail != null) 'thumbnail': thumbnail!.toJson(),
      };
}

/// Geographic location information stored in the image.
class FileImageMediaMetadataLocation {
  /// The altitude stored in the image.
  core.double? altitude;

  /// The latitude stored in the image.
  core.double? latitude;

  /// The longitude stored in the image.
  core.double? longitude;

  FileImageMediaMetadataLocation();

  FileImageMediaMetadataLocation.fromJson(core.Map _json) {
    if (_json.containsKey('altitude')) {
      altitude = (_json['altitude'] as core.num).toDouble();
    }
    if (_json.containsKey('latitude')) {
      latitude = (_json['latitude'] as core.num).toDouble();
    }
    if (_json.containsKey('longitude')) {
      longitude = (_json['longitude'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (altitude != null) 'altitude': altitude!,
        if (latitude != null) 'latitude': latitude!,
        if (longitude != null) 'longitude': longitude!,
      };
}

/// Additional metadata about image media, if available.
class FileImageMediaMetadata {
  /// The aperture used to create the photo (f-number).
  core.double? aperture;

  /// The make of the camera used to create the photo.
  core.String? cameraMake;

  /// The model of the camera used to create the photo.
  core.String? cameraModel;

  /// The color space of the photo.
  core.String? colorSpace;

  /// The exposure bias of the photo (APEX value).
  core.double? exposureBias;

  /// The exposure mode used to create the photo.
  core.String? exposureMode;

  /// The length of the exposure, in seconds.
  core.double? exposureTime;

  /// Whether a flash was used to create the photo.
  core.bool? flashUsed;

  /// The focal length used to create the photo, in millimeters.
  core.double? focalLength;

  /// The height of the image in pixels.
  core.int? height;

  /// The ISO speed used to create the photo.
  core.int? isoSpeed;

  /// The lens used to create the photo.
  core.String? lens;

  /// Geographic location information stored in the image.
  FileImageMediaMetadataLocation? location;

  /// The smallest f-number of the lens at the focal length used to create the
  /// photo (APEX value).
  core.double? maxApertureValue;

  /// The metering mode used to create the photo.
  core.String? meteringMode;

  /// The number of clockwise 90 degree rotations applied from the image's
  /// original orientation.
  core.int? rotation;

  /// The type of sensor used to create the photo.
  core.String? sensor;

  /// The distance to the subject of the photo, in meters.
  core.int? subjectDistance;

  /// The date and time the photo was taken (EXIF DateTime).
  core.String? time;

  /// The white balance mode used to create the photo.
  core.String? whiteBalance;

  /// The width of the image in pixels.
  core.int? width;

  FileImageMediaMetadata();

  FileImageMediaMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('aperture')) {
      aperture = (_json['aperture'] as core.num).toDouble();
    }
    if (_json.containsKey('cameraMake')) {
      cameraMake = _json['cameraMake'] as core.String;
    }
    if (_json.containsKey('cameraModel')) {
      cameraModel = _json['cameraModel'] as core.String;
    }
    if (_json.containsKey('colorSpace')) {
      colorSpace = _json['colorSpace'] as core.String;
    }
    if (_json.containsKey('exposureBias')) {
      exposureBias = (_json['exposureBias'] as core.num).toDouble();
    }
    if (_json.containsKey('exposureMode')) {
      exposureMode = _json['exposureMode'] as core.String;
    }
    if (_json.containsKey('exposureTime')) {
      exposureTime = (_json['exposureTime'] as core.num).toDouble();
    }
    if (_json.containsKey('flashUsed')) {
      flashUsed = _json['flashUsed'] as core.bool;
    }
    if (_json.containsKey('focalLength')) {
      focalLength = (_json['focalLength'] as core.num).toDouble();
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('isoSpeed')) {
      isoSpeed = _json['isoSpeed'] as core.int;
    }
    if (_json.containsKey('lens')) {
      lens = _json['lens'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = FileImageMediaMetadataLocation.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maxApertureValue')) {
      maxApertureValue = (_json['maxApertureValue'] as core.num).toDouble();
    }
    if (_json.containsKey('meteringMode')) {
      meteringMode = _json['meteringMode'] as core.String;
    }
    if (_json.containsKey('rotation')) {
      rotation = _json['rotation'] as core.int;
    }
    if (_json.containsKey('sensor')) {
      sensor = _json['sensor'] as core.String;
    }
    if (_json.containsKey('subjectDistance')) {
      subjectDistance = _json['subjectDistance'] as core.int;
    }
    if (_json.containsKey('time')) {
      time = _json['time'] as core.String;
    }
    if (_json.containsKey('whiteBalance')) {
      whiteBalance = _json['whiteBalance'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aperture != null) 'aperture': aperture!,
        if (cameraMake != null) 'cameraMake': cameraMake!,
        if (cameraModel != null) 'cameraModel': cameraModel!,
        if (colorSpace != null) 'colorSpace': colorSpace!,
        if (exposureBias != null) 'exposureBias': exposureBias!,
        if (exposureMode != null) 'exposureMode': exposureMode!,
        if (exposureTime != null) 'exposureTime': exposureTime!,
        if (flashUsed != null) 'flashUsed': flashUsed!,
        if (focalLength != null) 'focalLength': focalLength!,
        if (height != null) 'height': height!,
        if (isoSpeed != null) 'isoSpeed': isoSpeed!,
        if (lens != null) 'lens': lens!,
        if (location != null) 'location': location!.toJson(),
        if (maxApertureValue != null) 'maxApertureValue': maxApertureValue!,
        if (meteringMode != null) 'meteringMode': meteringMode!,
        if (rotation != null) 'rotation': rotation!,
        if (sensor != null) 'sensor': sensor!,
        if (subjectDistance != null) 'subjectDistance': subjectDistance!,
        if (time != null) 'time': time!,
        if (whiteBalance != null) 'whiteBalance': whiteBalance!,
        if (width != null) 'width': width!,
      };
}

/// Shortcut file details.
///
/// Only populated for shortcut files, which have the mimeType field set to
/// application/vnd.google-apps.shortcut.
class FileShortcutDetails {
  /// The ID of the file that this shortcut points to.
  core.String? targetId;

  /// The MIME type of the file that this shortcut points to.
  ///
  /// The value of this field is a snapshot of the target's MIME type, captured
  /// when the shortcut is created.
  core.String? targetMimeType;

  FileShortcutDetails();

  FileShortcutDetails.fromJson(core.Map _json) {
    if (_json.containsKey('targetId')) {
      targetId = _json['targetId'] as core.String;
    }
    if (_json.containsKey('targetMimeType')) {
      targetMimeType = _json['targetMimeType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetId != null) 'targetId': targetId!,
        if (targetMimeType != null) 'targetMimeType': targetMimeType!,
      };
}

/// Additional metadata about video media.
///
/// This may not be available immediately upon upload.
class FileVideoMediaMetadata {
  /// The duration of the video in milliseconds.
  core.String? durationMillis;

  /// The height of the video in pixels.
  core.int? height;

  /// The width of the video in pixels.
  core.int? width;

  FileVideoMediaMetadata();

  FileVideoMediaMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('durationMillis')) {
      durationMillis = _json['durationMillis'] as core.String;
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (durationMillis != null) 'durationMillis': durationMillis!,
        if (height != null) 'height': height!,
        if (width != null) 'width': width!,
      };
}

/// The metadata for a file.
class File {
  /// A collection of arbitrary key-value pairs which are private to the
  /// requesting app.
  /// Entries with null values are cleared in update and copy requests.
  ///
  /// These properties can only be retrieved using an authenticated request. An
  /// authenticated request uses an access token obtained with a OAuth 2 client
  /// ID. You cannot use an API key to retrieve private properties.
  core.Map<core.String, core.String>? appProperties;

  /// Capabilities the current user has on this file.
  ///
  /// Each capability corresponds to a fine-grained action that a user may take.
  FileCapabilities? capabilities;

  /// Additional information about the content of the file.
  ///
  /// These fields are never populated in responses.
  FileContentHints? contentHints;

  /// Restrictions for accessing the content of the file.
  ///
  /// Only populated if such a restriction exists.
  core.List<ContentRestriction>? contentRestrictions;

  /// Whether the options to copy, print, or download this file, should be
  /// disabled for readers and commenters.
  core.bool? copyRequiresWriterPermission;

  /// The time at which the file was created (RFC 3339 date-time).
  core.DateTime? createdTime;

  /// A short description of the file.
  core.String? description;

  /// ID of the shared drive the file resides in.
  ///
  /// Only populated for items in shared drives.
  core.String? driveId;

  /// Whether the file has been explicitly trashed, as opposed to recursively
  /// trashed from a parent folder.
  core.bool? explicitlyTrashed;

  /// Links for exporting Docs Editors files to specific formats.
  core.Map<core.String, core.String>? exportLinks;

  /// The final component of fullFileExtension.
  ///
  /// This is only available for files with binary content in Google Drive.
  core.String? fileExtension;

  /// The color for a folder as an RGB hex string.
  ///
  /// The supported colors are published in the folderColorPalette field of the
  /// About resource.
  /// If an unsupported color is specified, the closest color in the palette
  /// will be used instead.
  core.String? folderColorRgb;

  /// The full file extension extracted from the name field.
  ///
  /// May contain multiple concatenated extensions, such as "tar.gz". This is
  /// only available for files with binary content in Google Drive.
  /// This is automatically updated when the name field changes, however it is
  /// not cleared if the new name does not contain a valid extension.
  core.String? fullFileExtension;

  /// Whether there are permissions directly on this file.
  ///
  /// This field is only populated for items in shared drives.
  core.bool? hasAugmentedPermissions;

  /// Whether this file has a thumbnail.
  ///
  /// This does not indicate whether the requesting app has access to the
  /// thumbnail. To check access, look for the presence of the thumbnailLink
  /// field.
  core.bool? hasThumbnail;

  /// The ID of the file's head revision.
  ///
  /// This is currently only available for files with binary content in Google
  /// Drive.
  core.String? headRevisionId;

  /// A static, unauthenticated link to the file's icon.
  core.String? iconLink;

  /// The ID of the file.
  core.String? id;

  /// Additional metadata about image media, if available.
  FileImageMediaMetadata? imageMediaMetadata;

  /// Whether the file was created or opened by the requesting app.
  core.bool? isAppAuthorized;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#file".
  core.String? kind;

  /// The last user to modify the file.
  User? lastModifyingUser;

  /// The MD5 checksum for the content of the file.
  ///
  /// This is only applicable to files with binary content in Google Drive.
  core.String? md5Checksum;

  /// The MIME type of the file.
  /// Google Drive will attempt to automatically detect an appropriate value
  /// from uploaded content if no value is provided.
  ///
  /// The value cannot be changed unless a new revision is uploaded.
  /// If a file is created with a Google Doc MIME type, the uploaded content
  /// will be imported if possible. The supported import formats are published
  /// in the About resource.
  core.String? mimeType;

  /// Whether the file has been modified by this user.
  core.bool? modifiedByMe;

  /// The last time the file was modified by the user (RFC 3339 date-time).
  core.DateTime? modifiedByMeTime;

  /// The last time the file was modified by anyone (RFC 3339 date-time).
  /// Note that setting modifiedTime will also update modifiedByMeTime for the
  /// user.
  core.DateTime? modifiedTime;

  /// The name of the file.
  ///
  /// This is not necessarily unique within a folder. Note that for immutable
  /// items such as the top level folders of shared drives, My Drive root
  /// folder, and Application Data folder the name is constant.
  core.String? name;

  /// The original filename of the uploaded content if available, or else the
  /// original value of the name field.
  ///
  /// This is only available for files with binary content in Google Drive.
  core.String? originalFilename;

  /// Whether the user owns the file.
  ///
  /// Not populated for items in shared drives.
  core.bool? ownedByMe;

  /// The owners of the file.
  ///
  /// Currently, only certain legacy files may have more than one owner. Not
  /// populated for items in shared drives.
  core.List<User>? owners;

  /// The IDs of the parent folders which contain the file.
  /// If not specified as part of a create request, the file will be placed
  /// directly in the user's My Drive folder.
  ///
  /// If not specified as part of a copy request, the file will inherit any
  /// discoverable parents of the source file. Update requests must use the
  /// addParents and removeParents parameters to modify the parents list.
  core.List<core.String>? parents;

  /// List of permission IDs for users with access to this file.
  core.List<core.String>? permissionIds;

  /// The full list of permissions for the file.
  ///
  /// This is only available if the requesting user can share the file. Not
  /// populated for items in shared drives.
  core.List<Permission>? permissions;

  /// A collection of arbitrary key-value pairs which are visible to all apps.
  /// Entries with null values are cleared in update and copy requests.
  core.Map<core.String, core.String>? properties;

  /// The number of storage quota bytes used by the file.
  ///
  /// This includes the head revision as well as previous revisions with
  /// keepForever enabled.
  core.String? quotaBytesUsed;

  /// Whether the file has been shared.
  ///
  /// Not populated for items in shared drives.
  core.bool? shared;

  /// The time at which the file was shared with the user, if applicable (RFC
  /// 3339 date-time).
  core.DateTime? sharedWithMeTime;

  /// The user who shared the file with the requesting user, if applicable.
  User? sharingUser;

  /// Shortcut file details.
  ///
  /// Only populated for shortcut files, which have the mimeType field set to
  /// application/vnd.google-apps.shortcut.
  FileShortcutDetails? shortcutDetails;

  /// The size of the file's content in bytes.
  ///
  /// This is applicable to binary files in Google Drive and Google Docs files.
  core.String? size;

  /// The list of spaces which contain the file.
  ///
  /// The currently supported values are 'drive', 'appDataFolder' and 'photos'.
  core.List<core.String>? spaces;

  /// Whether the user has starred the file.
  core.bool? starred;

  /// Deprecated - use driveId instead.
  core.String? teamDriveId;

  /// A short-lived link to the file's thumbnail, if available.
  ///
  /// Typically lasts on the order of hours. Only populated when the requesting
  /// app can access the file's content. If the file isn't shared publicly, the
  /// URL returned in Files.thumbnailLink must be fetched using a credentialed
  /// request.
  core.String? thumbnailLink;

  /// The thumbnail version for use in thumbnail cache invalidation.
  core.String? thumbnailVersion;

  /// Whether the file has been trashed, either explicitly or from a trashed
  /// parent folder.
  ///
  /// Only the owner may trash a file. The trashed item is excluded from all
  /// files.list responses returned for any user who does not own the file.
  /// However, all users with access to the file can see the trashed item
  /// metadata in an API response. All users with access can copy, download,
  /// export, and share the file.
  core.bool? trashed;

  /// The time that the item was trashed (RFC 3339 date-time).
  ///
  /// Only populated for items in shared drives.
  core.DateTime? trashedTime;

  /// If the file has been explicitly trashed, the user who trashed it.
  ///
  /// Only populated for items in shared drives.
  User? trashingUser;

  /// A monotonically increasing version number for the file.
  ///
  /// This reflects every change made to the file on the server, even those not
  /// visible to the user.
  core.String? version;

  /// Additional metadata about video media.
  ///
  /// This may not be available immediately upon upload.
  FileVideoMediaMetadata? videoMediaMetadata;

  /// Whether the file has been viewed by this user.
  core.bool? viewedByMe;

  /// The last time the file was viewed by the user (RFC 3339 date-time).
  core.DateTime? viewedByMeTime;

  /// Deprecated - use copyRequiresWriterPermission instead.
  core.bool? viewersCanCopyContent;

  /// A link for downloading the content of the file in a browser.
  ///
  /// This is only available for files with binary content in Google Drive.
  core.String? webContentLink;

  /// A link for opening the file in a relevant Google editor or viewer in a
  /// browser.
  core.String? webViewLink;

  /// Whether users with only writer permission can modify the file's
  /// permissions.
  ///
  /// Not populated for items in shared drives.
  core.bool? writersCanShare;

  File();

  File.fromJson(core.Map _json) {
    if (_json.containsKey('appProperties')) {
      appProperties =
          (_json['appProperties'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('capabilities')) {
      capabilities = FileCapabilities.fromJson(
          _json['capabilities'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentHints')) {
      contentHints = FileContentHints.fromJson(
          _json['contentHints'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentRestrictions')) {
      contentRestrictions = (_json['contentRestrictions'] as core.List)
          .map<ContentRestriction>((value) => ContentRestriction.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('copyRequiresWriterPermission')) {
      copyRequiresWriterPermission =
          _json['copyRequiresWriterPermission'] as core.bool;
    }
    if (_json.containsKey('createdTime')) {
      createdTime = core.DateTime.parse(_json['createdTime'] as core.String);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('driveId')) {
      driveId = _json['driveId'] as core.String;
    }
    if (_json.containsKey('explicitlyTrashed')) {
      explicitlyTrashed = _json['explicitlyTrashed'] as core.bool;
    }
    if (_json.containsKey('exportLinks')) {
      exportLinks =
          (_json['exportLinks'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('fileExtension')) {
      fileExtension = _json['fileExtension'] as core.String;
    }
    if (_json.containsKey('folderColorRgb')) {
      folderColorRgb = _json['folderColorRgb'] as core.String;
    }
    if (_json.containsKey('fullFileExtension')) {
      fullFileExtension = _json['fullFileExtension'] as core.String;
    }
    if (_json.containsKey('hasAugmentedPermissions')) {
      hasAugmentedPermissions = _json['hasAugmentedPermissions'] as core.bool;
    }
    if (_json.containsKey('hasThumbnail')) {
      hasThumbnail = _json['hasThumbnail'] as core.bool;
    }
    if (_json.containsKey('headRevisionId')) {
      headRevisionId = _json['headRevisionId'] as core.String;
    }
    if (_json.containsKey('iconLink')) {
      iconLink = _json['iconLink'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('imageMediaMetadata')) {
      imageMediaMetadata = FileImageMediaMetadata.fromJson(
          _json['imageMediaMetadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isAppAuthorized')) {
      isAppAuthorized = _json['isAppAuthorized'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifyingUser')) {
      lastModifyingUser = User.fromJson(
          _json['lastModifyingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('md5Checksum')) {
      md5Checksum = _json['md5Checksum'] as core.String;
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('modifiedByMe')) {
      modifiedByMe = _json['modifiedByMe'] as core.bool;
    }
    if (_json.containsKey('modifiedByMeTime')) {
      modifiedByMeTime =
          core.DateTime.parse(_json['modifiedByMeTime'] as core.String);
    }
    if (_json.containsKey('modifiedTime')) {
      modifiedTime = core.DateTime.parse(_json['modifiedTime'] as core.String);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('originalFilename')) {
      originalFilename = _json['originalFilename'] as core.String;
    }
    if (_json.containsKey('ownedByMe')) {
      ownedByMe = _json['ownedByMe'] as core.bool;
    }
    if (_json.containsKey('owners')) {
      owners = (_json['owners'] as core.List)
          .map<User>((value) =>
              User.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parents')) {
      parents = (_json['parents'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('permissionIds')) {
      permissionIds = (_json['permissionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<Permission>((value) =>
              Permission.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('properties')) {
      properties =
          (_json['properties'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('quotaBytesUsed')) {
      quotaBytesUsed = _json['quotaBytesUsed'] as core.String;
    }
    if (_json.containsKey('shared')) {
      shared = _json['shared'] as core.bool;
    }
    if (_json.containsKey('sharedWithMeTime')) {
      sharedWithMeTime =
          core.DateTime.parse(_json['sharedWithMeTime'] as core.String);
    }
    if (_json.containsKey('sharingUser')) {
      sharingUser = User.fromJson(
          _json['sharingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shortcutDetails')) {
      shortcutDetails = FileShortcutDetails.fromJson(
          _json['shortcutDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('spaces')) {
      spaces = (_json['spaces'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('starred')) {
      starred = _json['starred'] as core.bool;
    }
    if (_json.containsKey('teamDriveId')) {
      teamDriveId = _json['teamDriveId'] as core.String;
    }
    if (_json.containsKey('thumbnailLink')) {
      thumbnailLink = _json['thumbnailLink'] as core.String;
    }
    if (_json.containsKey('thumbnailVersion')) {
      thumbnailVersion = _json['thumbnailVersion'] as core.String;
    }
    if (_json.containsKey('trashed')) {
      trashed = _json['trashed'] as core.bool;
    }
    if (_json.containsKey('trashedTime')) {
      trashedTime = core.DateTime.parse(_json['trashedTime'] as core.String);
    }
    if (_json.containsKey('trashingUser')) {
      trashingUser = User.fromJson(
          _json['trashingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
    if (_json.containsKey('videoMediaMetadata')) {
      videoMediaMetadata = FileVideoMediaMetadata.fromJson(
          _json['videoMediaMetadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('viewedByMe')) {
      viewedByMe = _json['viewedByMe'] as core.bool;
    }
    if (_json.containsKey('viewedByMeTime')) {
      viewedByMeTime =
          core.DateTime.parse(_json['viewedByMeTime'] as core.String);
    }
    if (_json.containsKey('viewersCanCopyContent')) {
      viewersCanCopyContent = _json['viewersCanCopyContent'] as core.bool;
    }
    if (_json.containsKey('webContentLink')) {
      webContentLink = _json['webContentLink'] as core.String;
    }
    if (_json.containsKey('webViewLink')) {
      webViewLink = _json['webViewLink'] as core.String;
    }
    if (_json.containsKey('writersCanShare')) {
      writersCanShare = _json['writersCanShare'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appProperties != null) 'appProperties': appProperties!,
        if (capabilities != null) 'capabilities': capabilities!.toJson(),
        if (contentHints != null) 'contentHints': contentHints!.toJson(),
        if (contentRestrictions != null)
          'contentRestrictions':
              contentRestrictions!.map((value) => value.toJson()).toList(),
        if (copyRequiresWriterPermission != null)
          'copyRequiresWriterPermission': copyRequiresWriterPermission!,
        if (createdTime != null) 'createdTime': createdTime!.toIso8601String(),
        if (description != null) 'description': description!,
        if (driveId != null) 'driveId': driveId!,
        if (explicitlyTrashed != null) 'explicitlyTrashed': explicitlyTrashed!,
        if (exportLinks != null) 'exportLinks': exportLinks!,
        if (fileExtension != null) 'fileExtension': fileExtension!,
        if (folderColorRgb != null) 'folderColorRgb': folderColorRgb!,
        if (fullFileExtension != null) 'fullFileExtension': fullFileExtension!,
        if (hasAugmentedPermissions != null)
          'hasAugmentedPermissions': hasAugmentedPermissions!,
        if (hasThumbnail != null) 'hasThumbnail': hasThumbnail!,
        if (headRevisionId != null) 'headRevisionId': headRevisionId!,
        if (iconLink != null) 'iconLink': iconLink!,
        if (id != null) 'id': id!,
        if (imageMediaMetadata != null)
          'imageMediaMetadata': imageMediaMetadata!.toJson(),
        if (isAppAuthorized != null) 'isAppAuthorized': isAppAuthorized!,
        if (kind != null) 'kind': kind!,
        if (lastModifyingUser != null)
          'lastModifyingUser': lastModifyingUser!.toJson(),
        if (md5Checksum != null) 'md5Checksum': md5Checksum!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (modifiedByMe != null) 'modifiedByMe': modifiedByMe!,
        if (modifiedByMeTime != null)
          'modifiedByMeTime': modifiedByMeTime!.toIso8601String(),
        if (modifiedTime != null)
          'modifiedTime': modifiedTime!.toIso8601String(),
        if (name != null) 'name': name!,
        if (originalFilename != null) 'originalFilename': originalFilename!,
        if (ownedByMe != null) 'ownedByMe': ownedByMe!,
        if (owners != null)
          'owners': owners!.map((value) => value.toJson()).toList(),
        if (parents != null) 'parents': parents!,
        if (permissionIds != null) 'permissionIds': permissionIds!,
        if (permissions != null)
          'permissions': permissions!.map((value) => value.toJson()).toList(),
        if (properties != null) 'properties': properties!,
        if (quotaBytesUsed != null) 'quotaBytesUsed': quotaBytesUsed!,
        if (shared != null) 'shared': shared!,
        if (sharedWithMeTime != null)
          'sharedWithMeTime': sharedWithMeTime!.toIso8601String(),
        if (sharingUser != null) 'sharingUser': sharingUser!.toJson(),
        if (shortcutDetails != null)
          'shortcutDetails': shortcutDetails!.toJson(),
        if (size != null) 'size': size!,
        if (spaces != null) 'spaces': spaces!,
        if (starred != null) 'starred': starred!,
        if (teamDriveId != null) 'teamDriveId': teamDriveId!,
        if (thumbnailLink != null) 'thumbnailLink': thumbnailLink!,
        if (thumbnailVersion != null) 'thumbnailVersion': thumbnailVersion!,
        if (trashed != null) 'trashed': trashed!,
        if (trashedTime != null) 'trashedTime': trashedTime!.toIso8601String(),
        if (trashingUser != null) 'trashingUser': trashingUser!.toJson(),
        if (version != null) 'version': version!,
        if (videoMediaMetadata != null)
          'videoMediaMetadata': videoMediaMetadata!.toJson(),
        if (viewedByMe != null) 'viewedByMe': viewedByMe!,
        if (viewedByMeTime != null)
          'viewedByMeTime': viewedByMeTime!.toIso8601String(),
        if (viewersCanCopyContent != null)
          'viewersCanCopyContent': viewersCanCopyContent!,
        if (webContentLink != null) 'webContentLink': webContentLink!,
        if (webViewLink != null) 'webViewLink': webViewLink!,
        if (writersCanShare != null) 'writersCanShare': writersCanShare!,
      };
}

/// A list of files.
class FileList {
  /// The list of files.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<File>? files;

  /// Whether the search process was incomplete.
  ///
  /// If true, then some search results may be missing, since all documents were
  /// not searched. This may occur when searching multiple drives with the
  /// "allDrives" corpora, but all corpora could not be searched. When this
  /// happens, it is suggested that clients narrow their query by choosing a
  /// different corpus such as "user" or "drive".
  core.bool? incompleteSearch;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#fileList".
  core.String? kind;

  /// The page token for the next page of files.
  ///
  /// This will be absent if the end of the files list has been reached. If the
  /// token is rejected for any reason, it should be discarded, and pagination
  /// should be restarted from the first page of results.
  core.String? nextPageToken;

  FileList();

  FileList.fromJson(core.Map _json) {
    if (_json.containsKey('files')) {
      files = (_json['files'] as core.List)
          .map<File>((value) =>
              File.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('incompleteSearch')) {
      incompleteSearch = _json['incompleteSearch'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (files != null)
          'files': files!.map((value) => value.toJson()).toList(),
        if (incompleteSearch != null) 'incompleteSearch': incompleteSearch!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A list of generated file IDs which can be provided in create requests.
class GeneratedIds {
  /// The IDs generated for the requesting user in the specified space.
  core.List<core.String>? ids;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#generatedIds".
  core.String? kind;

  /// The type of file that can be created with these IDs.
  core.String? space;

  GeneratedIds();

  GeneratedIds.fromJson(core.Map _json) {
    if (_json.containsKey('ids')) {
      ids = (_json['ids'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('space')) {
      space = _json['space'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ids != null) 'ids': ids!,
        if (kind != null) 'kind': kind!,
        if (space != null) 'space': space!,
      };
}

class PermissionPermissionDetails {
  /// Whether this permission is inherited.
  ///
  /// This field is always populated. This is an output-only field.
  core.bool? inherited;

  /// The ID of the item from which this permission is inherited.
  ///
  /// This is an output-only field.
  core.String? inheritedFrom;

  /// The permission type for this user.
  ///
  /// While new values may be added in future, the following are currently
  /// possible:
  /// - file
  /// - member
  core.String? permissionType;

  /// The primary role for this user.
  ///
  /// While new values may be added in the future, the following are currently
  /// possible:
  /// - organizer
  /// - fileOrganizer
  /// - writer
  /// - commenter
  /// - reader
  core.String? role;

  PermissionPermissionDetails();

  PermissionPermissionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('inherited')) {
      inherited = _json['inherited'] as core.bool;
    }
    if (_json.containsKey('inheritedFrom')) {
      inheritedFrom = _json['inheritedFrom'] as core.String;
    }
    if (_json.containsKey('permissionType')) {
      permissionType = _json['permissionType'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inherited != null) 'inherited': inherited!,
        if (inheritedFrom != null) 'inheritedFrom': inheritedFrom!,
        if (permissionType != null) 'permissionType': permissionType!,
        if (role != null) 'role': role!,
      };
}

class PermissionTeamDrivePermissionDetails {
  /// Deprecated - use permissionDetails/inherited instead.
  core.bool? inherited;

  /// Deprecated - use permissionDetails/inheritedFrom instead.
  core.String? inheritedFrom;

  /// Deprecated - use permissionDetails/role instead.
  core.String? role;

  /// Deprecated - use permissionDetails/permissionType instead.
  core.String? teamDrivePermissionType;

  PermissionTeamDrivePermissionDetails();

  PermissionTeamDrivePermissionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('inherited')) {
      inherited = _json['inherited'] as core.bool;
    }
    if (_json.containsKey('inheritedFrom')) {
      inheritedFrom = _json['inheritedFrom'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('teamDrivePermissionType')) {
      teamDrivePermissionType = _json['teamDrivePermissionType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inherited != null) 'inherited': inherited!,
        if (inheritedFrom != null) 'inheritedFrom': inheritedFrom!,
        if (role != null) 'role': role!,
        if (teamDrivePermissionType != null)
          'teamDrivePermissionType': teamDrivePermissionType!,
      };
}

/// A permission for a file.
///
/// A permission grants a user, group, domain or the world access to a file or a
/// folder hierarchy.
class Permission {
  /// Whether the permission allows the file to be discovered through search.
  ///
  /// This is only applicable for permissions of type domain or anyone.
  core.bool? allowFileDiscovery;

  /// Whether the account associated with this permission has been deleted.
  ///
  /// This field only pertains to user and group permissions.
  core.bool? deleted;

  /// The "pretty" name of the value of the permission.
  ///
  /// The following is a list of examples for each type of permission:
  /// - user - User's full name, as defined for their Google account, such as
  /// "Joe Smith."
  /// - group - Name of the Google Group, such as "The Company Administrators."
  /// - domain - String domain name, such as "thecompany.com."
  /// - anyone - No displayName is present.
  core.String? displayName;

  /// The domain to which this permission refers.
  core.String? domain;

  /// The email address of the user or group to which this permission refers.
  core.String? emailAddress;

  /// The time at which this permission will expire (RFC 3339 date-time).
  ///
  /// Expiration times have the following restrictions:
  /// - They can only be set on user and group permissions
  /// - The time must be in the future
  /// - The time cannot be more than a year in the future
  core.DateTime? expirationTime;

  /// The ID of this permission.
  ///
  /// This is a unique identifier for the grantee, and is published in User
  /// resources as permissionId. IDs should be treated as opaque values.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#permission".
  core.String? kind;

  /// Details of whether the permissions on this shared drive item are inherited
  /// or directly on this item.
  ///
  /// This is an output-only field which is present only for shared drive items.
  core.List<PermissionPermissionDetails>? permissionDetails;

  /// A link to the user's profile photo, if available.
  core.String? photoLink;

  /// The role granted by this permission.
  ///
  /// While new values may be supported in the future, the following are
  /// currently allowed:
  /// - owner
  /// - organizer
  /// - fileOrganizer
  /// - writer
  /// - commenter
  /// - reader
  core.String? role;

  /// Deprecated - use permissionDetails instead.
  core.List<PermissionTeamDrivePermissionDetails>? teamDrivePermissionDetails;

  /// The type of the grantee.
  ///
  /// Valid values are:
  /// - user
  /// - group
  /// - domain
  /// - anyone When creating a permission, if type is user or group, you must
  /// provide an emailAddress for the user or group. When type is domain, you
  /// must provide a domain. There isn't extra information required for a anyone
  /// type.
  core.String? type;

  /// Indicates the view for this permission.
  ///
  /// Only populated for permissions that belong to a view. published is the
  /// only supported value.
  core.String? view;

  Permission();

  Permission.fromJson(core.Map _json) {
    if (_json.containsKey('allowFileDiscovery')) {
      allowFileDiscovery = _json['allowFileDiscovery'] as core.bool;
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('emailAddress')) {
      emailAddress = _json['emailAddress'] as core.String;
    }
    if (_json.containsKey('expirationTime')) {
      expirationTime =
          core.DateTime.parse(_json['expirationTime'] as core.String);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('permissionDetails')) {
      permissionDetails = (_json['permissionDetails'] as core.List)
          .map<PermissionPermissionDetails>((value) =>
              PermissionPermissionDetails.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('photoLink')) {
      photoLink = _json['photoLink'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('teamDrivePermissionDetails')) {
      teamDrivePermissionDetails =
          (_json['teamDrivePermissionDetails'] as core.List)
              .map<PermissionTeamDrivePermissionDetails>((value) =>
                  PermissionTeamDrivePermissionDetails.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('view')) {
      view = _json['view'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowFileDiscovery != null)
          'allowFileDiscovery': allowFileDiscovery!,
        if (deleted != null) 'deleted': deleted!,
        if (displayName != null) 'displayName': displayName!,
        if (domain != null) 'domain': domain!,
        if (emailAddress != null) 'emailAddress': emailAddress!,
        if (expirationTime != null)
          'expirationTime': expirationTime!.toIso8601String(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (permissionDetails != null)
          'permissionDetails':
              permissionDetails!.map((value) => value.toJson()).toList(),
        if (photoLink != null) 'photoLink': photoLink!,
        if (role != null) 'role': role!,
        if (teamDrivePermissionDetails != null)
          'teamDrivePermissionDetails': teamDrivePermissionDetails!
              .map((value) => value.toJson())
              .toList(),
        if (type != null) 'type': type!,
        if (view != null) 'view': view!,
      };
}

/// A list of permissions for a file.
class PermissionList {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#permissionList".
  core.String? kind;

  /// The page token for the next page of permissions.
  ///
  /// This field will be absent if the end of the permissions list has been
  /// reached. If the token is rejected for any reason, it should be discarded,
  /// and pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// The list of permissions.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Permission>? permissions;

  PermissionList();

  PermissionList.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<Permission>((value) =>
              Permission.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (permissions != null)
          'permissions': permissions!.map((value) => value.toJson()).toList(),
      };
}

/// A reply to a comment on a file.
class Reply {
  /// The action the reply performed to the parent comment.
  ///
  /// Valid values are:
  /// - resolve
  /// - reopen
  core.String? action;

  /// The author of the reply.
  ///
  /// The author's email address and permission ID will not be populated.
  User? author;

  /// The plain text content of the reply.
  ///
  /// This field is used for setting the content, while htmlContent should be
  /// displayed. This is required on creates if no action is specified.
  core.String? content;

  /// The time at which the reply was created (RFC 3339 date-time).
  core.DateTime? createdTime;

  /// Whether the reply has been deleted.
  ///
  /// A deleted reply has no content.
  core.bool? deleted;

  /// The content of the reply with HTML formatting.
  core.String? htmlContent;

  /// The ID of the reply.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#reply".
  core.String? kind;

  /// The last time the reply was modified (RFC 3339 date-time).
  core.DateTime? modifiedTime;

  Reply();

  Reply.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('author')) {
      author =
          User.fromJson(_json['author'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('createdTime')) {
      createdTime = core.DateTime.parse(_json['createdTime'] as core.String);
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('htmlContent')) {
      htmlContent = _json['htmlContent'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('modifiedTime')) {
      modifiedTime = core.DateTime.parse(_json['modifiedTime'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (author != null) 'author': author!.toJson(),
        if (content != null) 'content': content!,
        if (createdTime != null) 'createdTime': createdTime!.toIso8601String(),
        if (deleted != null) 'deleted': deleted!,
        if (htmlContent != null) 'htmlContent': htmlContent!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (modifiedTime != null)
          'modifiedTime': modifiedTime!.toIso8601String(),
      };
}

/// A list of replies to a comment on a file.
class ReplyList {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#replyList".
  core.String? kind;

  /// The page token for the next page of replies.
  ///
  /// This will be absent if the end of the replies list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// The list of replies.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Reply>? replies;

  ReplyList();

  ReplyList.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('replies')) {
      replies = (_json['replies'] as core.List)
          .map<Reply>((value) =>
              Reply.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (replies != null)
          'replies': replies!.map((value) => value.toJson()).toList(),
      };
}

/// The metadata for a revision to a file.
class Revision {
  /// Links for exporting Docs Editors files to specific formats.
  core.Map<core.String, core.String>? exportLinks;

  /// The ID of the revision.
  core.String? id;

  /// Whether to keep this revision forever, even if it is no longer the head
  /// revision.
  ///
  /// If not set, the revision will be automatically purged 30 days after newer
  /// content is uploaded. This can be set on a maximum of 200 revisions for a
  /// file.
  /// This field is only applicable to files with binary content in Drive.
  core.bool? keepForever;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#revision".
  core.String? kind;

  /// The last user to modify this revision.
  User? lastModifyingUser;

  /// The MD5 checksum of the revision's content.
  ///
  /// This is only applicable to files with binary content in Drive.
  core.String? md5Checksum;

  /// The MIME type of the revision.
  core.String? mimeType;

  /// The last time the revision was modified (RFC 3339 date-time).
  core.DateTime? modifiedTime;

  /// The original filename used to create this revision.
  ///
  /// This is only applicable to files with binary content in Drive.
  core.String? originalFilename;

  /// Whether subsequent revisions will be automatically republished.
  ///
  /// This is only applicable to Docs Editors files.
  core.bool? publishAuto;

  /// Whether this revision is published.
  ///
  /// This is only applicable to Docs Editors files.
  core.bool? published;

  /// A link to the published revision.
  ///
  /// This is only populated for Google Sites files.
  core.String? publishedLink;

  /// Whether this revision is published outside the domain.
  ///
  /// This is only applicable to Docs Editors files.
  core.bool? publishedOutsideDomain;

  /// The size of the revision's content in bytes.
  ///
  /// This is only applicable to files with binary content in Drive.
  core.String? size;

  Revision();

  Revision.fromJson(core.Map _json) {
    if (_json.containsKey('exportLinks')) {
      exportLinks =
          (_json['exportLinks'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('keepForever')) {
      keepForever = _json['keepForever'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifyingUser')) {
      lastModifyingUser = User.fromJson(
          _json['lastModifyingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('md5Checksum')) {
      md5Checksum = _json['md5Checksum'] as core.String;
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('modifiedTime')) {
      modifiedTime = core.DateTime.parse(_json['modifiedTime'] as core.String);
    }
    if (_json.containsKey('originalFilename')) {
      originalFilename = _json['originalFilename'] as core.String;
    }
    if (_json.containsKey('publishAuto')) {
      publishAuto = _json['publishAuto'] as core.bool;
    }
    if (_json.containsKey('published')) {
      published = _json['published'] as core.bool;
    }
    if (_json.containsKey('publishedLink')) {
      publishedLink = _json['publishedLink'] as core.String;
    }
    if (_json.containsKey('publishedOutsideDomain')) {
      publishedOutsideDomain = _json['publishedOutsideDomain'] as core.bool;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exportLinks != null) 'exportLinks': exportLinks!,
        if (id != null) 'id': id!,
        if (keepForever != null) 'keepForever': keepForever!,
        if (kind != null) 'kind': kind!,
        if (lastModifyingUser != null)
          'lastModifyingUser': lastModifyingUser!.toJson(),
        if (md5Checksum != null) 'md5Checksum': md5Checksum!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (modifiedTime != null)
          'modifiedTime': modifiedTime!.toIso8601String(),
        if (originalFilename != null) 'originalFilename': originalFilename!,
        if (publishAuto != null) 'publishAuto': publishAuto!,
        if (published != null) 'published': published!,
        if (publishedLink != null) 'publishedLink': publishedLink!,
        if (publishedOutsideDomain != null)
          'publishedOutsideDomain': publishedOutsideDomain!,
        if (size != null) 'size': size!,
      };
}

/// A list of revisions of a file.
class RevisionList {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#revisionList".
  core.String? kind;

  /// The page token for the next page of revisions.
  ///
  /// This will be absent if the end of the revisions list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// The list of revisions.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Revision>? revisions;

  RevisionList();

  RevisionList.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('revisions')) {
      revisions = (_json['revisions'] as core.List)
          .map<Revision>((value) =>
              Revision.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (revisions != null)
          'revisions': revisions!.map((value) => value.toJson()).toList(),
      };
}

class StartPageToken {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#startPageToken".
  core.String? kind;

  /// The starting page token for listing changes.
  core.String? startPageToken;

  StartPageToken();

  StartPageToken.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('startPageToken')) {
      startPageToken = _json['startPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (startPageToken != null) 'startPageToken': startPageToken!,
      };
}

/// An image file and cropping parameters from which a background image for this
/// Team Drive is set.
///
/// This is a write only field; it can only be set on drive.teamdrives.update
/// requests that don't set themeId. When specified, all fields of the
/// backgroundImageFile must be set.
class TeamDriveBackgroundImageFile {
  /// The ID of an image file in Drive to use for the background image.
  core.String? id;

  /// The width of the cropped image in the closed range of 0 to 1.
  ///
  /// This value represents the width of the cropped image divided by the width
  /// of the entire image. The height is computed by applying a width to height
  /// aspect ratio of 80 to 9. The resulting image must be at least 1280 pixels
  /// wide and 144 pixels high.
  core.double? width;

  /// The X coordinate of the upper left corner of the cropping area in the
  /// background image.
  ///
  /// This is a value in the closed range of 0 to 1. This value represents the
  /// horizontal distance from the left side of the entire image to the left
  /// side of the cropping area divided by the width of the entire image.
  core.double? xCoordinate;

  /// The Y coordinate of the upper left corner of the cropping area in the
  /// background image.
  ///
  /// This is a value in the closed range of 0 to 1. This value represents the
  /// vertical distance from the top side of the entire image to the top side of
  /// the cropping area divided by the height of the entire image.
  core.double? yCoordinate;

  TeamDriveBackgroundImageFile();

  TeamDriveBackgroundImageFile.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = (_json['width'] as core.num).toDouble();
    }
    if (_json.containsKey('xCoordinate')) {
      xCoordinate = (_json['xCoordinate'] as core.num).toDouble();
    }
    if (_json.containsKey('yCoordinate')) {
      yCoordinate = (_json['yCoordinate'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (width != null) 'width': width!,
        if (xCoordinate != null) 'xCoordinate': xCoordinate!,
        if (yCoordinate != null) 'yCoordinate': yCoordinate!,
      };
}

/// Capabilities the current user has on this Team Drive.
class TeamDriveCapabilities {
  /// Whether the current user can add children to folders in this Team Drive.
  core.bool? canAddChildren;

  /// Whether the current user can change the copyRequiresWriterPermission
  /// restriction of this Team Drive.
  core.bool? canChangeCopyRequiresWriterPermissionRestriction;

  /// Whether the current user can change the domainUsersOnly restriction of
  /// this Team Drive.
  core.bool? canChangeDomainUsersOnlyRestriction;

  /// Whether the current user can change the background of this Team Drive.
  core.bool? canChangeTeamDriveBackground;

  /// Whether the current user can change the teamMembersOnly restriction of
  /// this Team Drive.
  core.bool? canChangeTeamMembersOnlyRestriction;

  /// Whether the current user can comment on files in this Team Drive.
  core.bool? canComment;

  /// Whether the current user can copy files in this Team Drive.
  core.bool? canCopy;

  /// Whether the current user can delete children from folders in this Team
  /// Drive.
  core.bool? canDeleteChildren;

  /// Whether the current user can delete this Team Drive.
  ///
  /// Attempting to delete the Team Drive may still fail if there are untrashed
  /// items inside the Team Drive.
  core.bool? canDeleteTeamDrive;

  /// Whether the current user can download files in this Team Drive.
  core.bool? canDownload;

  /// Whether the current user can edit files in this Team Drive
  core.bool? canEdit;

  /// Whether the current user can list the children of folders in this Team
  /// Drive.
  core.bool? canListChildren;

  /// Whether the current user can add members to this Team Drive or remove them
  /// or change their role.
  core.bool? canManageMembers;

  /// Whether the current user can read the revisions resource of files in this
  /// Team Drive.
  core.bool? canReadRevisions;

  /// Deprecated - use canDeleteChildren or canTrashChildren instead.
  core.bool? canRemoveChildren;

  /// Whether the current user can rename files or folders in this Team Drive.
  core.bool? canRename;

  /// Whether the current user can rename this Team Drive.
  core.bool? canRenameTeamDrive;

  /// Whether the current user can share files or folders in this Team Drive.
  core.bool? canShare;

  /// Whether the current user can trash children from folders in this Team
  /// Drive.
  core.bool? canTrashChildren;

  TeamDriveCapabilities();

  TeamDriveCapabilities.fromJson(core.Map _json) {
    if (_json.containsKey('canAddChildren')) {
      canAddChildren = _json['canAddChildren'] as core.bool;
    }
    if (_json.containsKey('canChangeCopyRequiresWriterPermissionRestriction')) {
      canChangeCopyRequiresWriterPermissionRestriction =
          _json['canChangeCopyRequiresWriterPermissionRestriction']
              as core.bool;
    }
    if (_json.containsKey('canChangeDomainUsersOnlyRestriction')) {
      canChangeDomainUsersOnlyRestriction =
          _json['canChangeDomainUsersOnlyRestriction'] as core.bool;
    }
    if (_json.containsKey('canChangeTeamDriveBackground')) {
      canChangeTeamDriveBackground =
          _json['canChangeTeamDriveBackground'] as core.bool;
    }
    if (_json.containsKey('canChangeTeamMembersOnlyRestriction')) {
      canChangeTeamMembersOnlyRestriction =
          _json['canChangeTeamMembersOnlyRestriction'] as core.bool;
    }
    if (_json.containsKey('canComment')) {
      canComment = _json['canComment'] as core.bool;
    }
    if (_json.containsKey('canCopy')) {
      canCopy = _json['canCopy'] as core.bool;
    }
    if (_json.containsKey('canDeleteChildren')) {
      canDeleteChildren = _json['canDeleteChildren'] as core.bool;
    }
    if (_json.containsKey('canDeleteTeamDrive')) {
      canDeleteTeamDrive = _json['canDeleteTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canDownload')) {
      canDownload = _json['canDownload'] as core.bool;
    }
    if (_json.containsKey('canEdit')) {
      canEdit = _json['canEdit'] as core.bool;
    }
    if (_json.containsKey('canListChildren')) {
      canListChildren = _json['canListChildren'] as core.bool;
    }
    if (_json.containsKey('canManageMembers')) {
      canManageMembers = _json['canManageMembers'] as core.bool;
    }
    if (_json.containsKey('canReadRevisions')) {
      canReadRevisions = _json['canReadRevisions'] as core.bool;
    }
    if (_json.containsKey('canRemoveChildren')) {
      canRemoveChildren = _json['canRemoveChildren'] as core.bool;
    }
    if (_json.containsKey('canRename')) {
      canRename = _json['canRename'] as core.bool;
    }
    if (_json.containsKey('canRenameTeamDrive')) {
      canRenameTeamDrive = _json['canRenameTeamDrive'] as core.bool;
    }
    if (_json.containsKey('canShare')) {
      canShare = _json['canShare'] as core.bool;
    }
    if (_json.containsKey('canTrashChildren')) {
      canTrashChildren = _json['canTrashChildren'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canAddChildren != null) 'canAddChildren': canAddChildren!,
        if (canChangeCopyRequiresWriterPermissionRestriction != null)
          'canChangeCopyRequiresWriterPermissionRestriction':
              canChangeCopyRequiresWriterPermissionRestriction!,
        if (canChangeDomainUsersOnlyRestriction != null)
          'canChangeDomainUsersOnlyRestriction':
              canChangeDomainUsersOnlyRestriction!,
        if (canChangeTeamDriveBackground != null)
          'canChangeTeamDriveBackground': canChangeTeamDriveBackground!,
        if (canChangeTeamMembersOnlyRestriction != null)
          'canChangeTeamMembersOnlyRestriction':
              canChangeTeamMembersOnlyRestriction!,
        if (canComment != null) 'canComment': canComment!,
        if (canCopy != null) 'canCopy': canCopy!,
        if (canDeleteChildren != null) 'canDeleteChildren': canDeleteChildren!,
        if (canDeleteTeamDrive != null)
          'canDeleteTeamDrive': canDeleteTeamDrive!,
        if (canDownload != null) 'canDownload': canDownload!,
        if (canEdit != null) 'canEdit': canEdit!,
        if (canListChildren != null) 'canListChildren': canListChildren!,
        if (canManageMembers != null) 'canManageMembers': canManageMembers!,
        if (canReadRevisions != null) 'canReadRevisions': canReadRevisions!,
        if (canRemoveChildren != null) 'canRemoveChildren': canRemoveChildren!,
        if (canRename != null) 'canRename': canRename!,
        if (canRenameTeamDrive != null)
          'canRenameTeamDrive': canRenameTeamDrive!,
        if (canShare != null) 'canShare': canShare!,
        if (canTrashChildren != null) 'canTrashChildren': canTrashChildren!,
      };
}

/// A set of restrictions that apply to this Team Drive or items inside this
/// Team Drive.
class TeamDriveRestrictions {
  /// Whether administrative privileges on this Team Drive are required to
  /// modify restrictions.
  core.bool? adminManagedRestrictions;

  /// Whether the options to copy, print, or download files inside this Team
  /// Drive, should be disabled for readers and commenters.
  ///
  /// When this restriction is set to true, it will override the similarly named
  /// field to true for any file inside this Team Drive.
  core.bool? copyRequiresWriterPermission;

  /// Whether access to this Team Drive and items inside this Team Drive is
  /// restricted to users of the domain to which this Team Drive belongs.
  ///
  /// This restriction may be overridden by other sharing policies controlled
  /// outside of this Team Drive.
  core.bool? domainUsersOnly;

  /// Whether access to items inside this Team Drive is restricted to members of
  /// this Team Drive.
  core.bool? teamMembersOnly;

  TeamDriveRestrictions();

  TeamDriveRestrictions.fromJson(core.Map _json) {
    if (_json.containsKey('adminManagedRestrictions')) {
      adminManagedRestrictions = _json['adminManagedRestrictions'] as core.bool;
    }
    if (_json.containsKey('copyRequiresWriterPermission')) {
      copyRequiresWriterPermission =
          _json['copyRequiresWriterPermission'] as core.bool;
    }
    if (_json.containsKey('domainUsersOnly')) {
      domainUsersOnly = _json['domainUsersOnly'] as core.bool;
    }
    if (_json.containsKey('teamMembersOnly')) {
      teamMembersOnly = _json['teamMembersOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adminManagedRestrictions != null)
          'adminManagedRestrictions': adminManagedRestrictions!,
        if (copyRequiresWriterPermission != null)
          'copyRequiresWriterPermission': copyRequiresWriterPermission!,
        if (domainUsersOnly != null) 'domainUsersOnly': domainUsersOnly!,
        if (teamMembersOnly != null) 'teamMembersOnly': teamMembersOnly!,
      };
}

/// Deprecated: use the drive collection instead.
class TeamDrive {
  /// An image file and cropping parameters from which a background image for
  /// this Team Drive is set.
  ///
  /// This is a write only field; it can only be set on drive.teamdrives.update
  /// requests that don't set themeId. When specified, all fields of the
  /// backgroundImageFile must be set.
  TeamDriveBackgroundImageFile? backgroundImageFile;

  /// A short-lived link to this Team Drive's background image.
  core.String? backgroundImageLink;

  /// Capabilities the current user has on this Team Drive.
  TeamDriveCapabilities? capabilities;

  /// The color of this Team Drive as an RGB hex string.
  ///
  /// It can only be set on a drive.teamdrives.update request that does not set
  /// themeId.
  core.String? colorRgb;

  /// The time at which the Team Drive was created (RFC 3339 date-time).
  core.DateTime? createdTime;

  /// The ID of this Team Drive which is also the ID of the top level folder of
  /// this Team Drive.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#teamDrive".
  core.String? kind;

  /// The name of this Team Drive.
  core.String? name;

  /// A set of restrictions that apply to this Team Drive or items inside this
  /// Team Drive.
  TeamDriveRestrictions? restrictions;

  /// The ID of the theme from which the background image and color will be set.
  ///
  /// The set of possible teamDriveThemes can be retrieved from a
  /// drive.about.get response. When not specified on a drive.teamdrives.create
  /// request, a random theme is chosen from which the background image and
  /// color are set. This is a write-only field; it can only be set on requests
  /// that don't set colorRgb or backgroundImageFile.
  core.String? themeId;

  TeamDrive();

  TeamDrive.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundImageFile')) {
      backgroundImageFile = TeamDriveBackgroundImageFile.fromJson(
          _json['backgroundImageFile'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('backgroundImageLink')) {
      backgroundImageLink = _json['backgroundImageLink'] as core.String;
    }
    if (_json.containsKey('capabilities')) {
      capabilities = TeamDriveCapabilities.fromJson(
          _json['capabilities'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorRgb')) {
      colorRgb = _json['colorRgb'] as core.String;
    }
    if (_json.containsKey('createdTime')) {
      createdTime = core.DateTime.parse(_json['createdTime'] as core.String);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('restrictions')) {
      restrictions = TeamDriveRestrictions.fromJson(
          _json['restrictions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('themeId')) {
      themeId = _json['themeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundImageFile != null)
          'backgroundImageFile': backgroundImageFile!.toJson(),
        if (backgroundImageLink != null)
          'backgroundImageLink': backgroundImageLink!,
        if (capabilities != null) 'capabilities': capabilities!.toJson(),
        if (colorRgb != null) 'colorRgb': colorRgb!,
        if (createdTime != null) 'createdTime': createdTime!.toIso8601String(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (restrictions != null) 'restrictions': restrictions!.toJson(),
        if (themeId != null) 'themeId': themeId!,
      };
}

/// A list of Team Drives.
class TeamDriveList {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#teamDriveList".
  core.String? kind;

  /// The page token for the next page of Team Drives.
  ///
  /// This will be absent if the end of the Team Drives list has been reached.
  /// If the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// The list of Team Drives.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<TeamDrive>? teamDrives;

  TeamDriveList();

  TeamDriveList.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('teamDrives')) {
      teamDrives = (_json['teamDrives'] as core.List)
          .map<TeamDrive>((value) =>
              TeamDrive.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (teamDrives != null)
          'teamDrives': teamDrives!.map((value) => value.toJson()).toList(),
      };
}

/// Information about a Drive user.
class User {
  /// A plain text displayable name for this user.
  core.String? displayName;

  /// The email address of the user.
  ///
  /// This may not be present in certain contexts if the user has not made their
  /// email address visible to the requester.
  core.String? emailAddress;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "drive#user".
  core.String? kind;

  /// Whether this user is the requesting user.
  core.bool? me;

  /// The user's ID as visible in Permission resources.
  core.String? permissionId;

  /// A link to the user's profile photo, if available.
  core.String? photoLink;

  User();

  User.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('emailAddress')) {
      emailAddress = _json['emailAddress'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('me')) {
      me = _json['me'] as core.bool;
    }
    if (_json.containsKey('permissionId')) {
      permissionId = _json['permissionId'] as core.String;
    }
    if (_json.containsKey('photoLink')) {
      photoLink = _json['photoLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (emailAddress != null) 'emailAddress': emailAddress!,
        if (kind != null) 'kind': kind!,
        if (me != null) 'me': me!,
        if (permissionId != null) 'permissionId': permissionId!,
        if (photoLink != null) 'photoLink': photoLink!,
      };
}

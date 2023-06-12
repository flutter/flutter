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

/// Drive API - v2
///
/// Manages files in Drive including uploading, downloading, searching,
/// detecting changes, and updating sharing permissions.
///
/// For more information, see <https://developers.google.com/drive/>
///
/// Create an instance of [DriveApi] to access these resources:
///
/// - [AboutResource]
/// - [AppsResource]
/// - [ChangesResource]
/// - [ChannelsResource]
/// - [ChildrenResource]
/// - [CommentsResource]
/// - [DrivesResource]
/// - [FilesResource]
/// - [ParentsResource]
/// - [PermissionsResource]
/// - [PropertiesResource]
/// - [RepliesResource]
/// - [RevisionsResource]
/// - [TeamdrivesResource]
library drive.v2;

import 'dart:async' as async;
import 'dart:convert' as convert_1;
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

  /// View your Google Drive apps
  static const driveAppsReadonlyScope =
      'https://www.googleapis.com/auth/drive.apps.readonly';

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
  AppsResource get apps => AppsResource(_requester);
  ChangesResource get changes => ChangesResource(_requester);
  ChannelsResource get channels => ChannelsResource(_requester);
  ChildrenResource get children => ChildrenResource(_requester);
  CommentsResource get comments => CommentsResource(_requester);
  DrivesResource get drives => DrivesResource(_requester);
  FilesResource get files => FilesResource(_requester);
  ParentsResource get parents => ParentsResource(_requester);
  PermissionsResource get permissions => PermissionsResource(_requester);
  PropertiesResource get properties => PropertiesResource(_requester);
  RepliesResource get replies => RepliesResource(_requester);
  RevisionsResource get revisions => RevisionsResource(_requester);
  TeamdrivesResource get teamdrives => TeamdrivesResource(_requester);

  DriveApi(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = 'drive/v2/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AboutResource {
  final commons.ApiRequester _requester;

  AboutResource(commons.ApiRequester client) : _requester = client;

  /// Gets the information about the current user along with Drive API settings
  ///
  /// Request parameters:
  ///
  /// [includeSubscribed] - Whether to count changes outside the My Drive
  /// hierarchy. When set to false, changes to files such as those in the
  /// Application Data folder or shared files which have not been added to My
  /// Drive will be omitted from the maxChangeIdCount.
  ///
  /// [maxChangeIdCount] - Maximum number of remaining change IDs to count
  ///
  /// [startChangeId] - Change ID to start counting from when calculating number
  /// of remaining change IDs
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
    core.bool? includeSubscribed,
    core.String? maxChangeIdCount,
    core.String? startChangeId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeSubscribed != null)
        'includeSubscribed': ['${includeSubscribed}'],
      if (maxChangeIdCount != null) 'maxChangeIdCount': [maxChangeIdCount],
      if (startChangeId != null) 'startChangeId': [startChangeId],
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

class AppsResource {
  final commons.ApiRequester _requester;

  AppsResource(commons.ApiRequester client) : _requester = client;

  /// Gets a specific app.
  ///
  /// Request parameters:
  ///
  /// [appId] - The ID of the app.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [App].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<App> get(
    core.String appId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/' + commons.escapeVariable('$appId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return App.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a user's installed apps.
  ///
  /// Request parameters:
  ///
  /// [appFilterExtensions] - A comma-separated list of file extensions for open
  /// with filtering. All apps within the given app query scope which can open
  /// any of the given file extensions will be included in the response. If
  /// appFilterMimeTypes are provided as well, the result is a union of the two
  /// resulting app lists.
  ///
  /// [appFilterMimeTypes] - A comma-separated list of MIME types for open with
  /// filtering. All apps within the given app query scope which can open any of
  /// the given MIME types will be included in the response. If
  /// appFilterExtensions are provided as well, the result is a union of the two
  /// resulting app lists.
  ///
  /// [languageCode] - A language or locale code, as defined by BCP 47, with
  /// some extensions from Unicode's LDML format
  /// (http://www.unicode.org/reports/tr35/).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AppList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AppList> list({
    core.String? appFilterExtensions,
    core.String? appFilterMimeTypes,
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (appFilterExtensions != null)
        'appFilterExtensions': [appFilterExtensions],
      if (appFilterMimeTypes != null)
        'appFilterMimeTypes': [appFilterMimeTypes],
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'apps';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AppList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ChangesResource {
  final commons.ApiRequester _requester;

  ChangesResource(commons.ApiRequester client) : _requester = client;

  /// Deprecated - Use changes.getStartPageToken and changes.list to retrieve
  /// recent changes.
  ///
  /// Request parameters:
  ///
  /// [changeId] - The ID of the change.
  ///
  /// [driveId] - The shared drive from which the change is returned.
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
  /// Completes with a [Change].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Change> get(
    core.String changeId, {
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

    final _url = 'changes/' + commons.escapeVariable('$changeId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Change.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

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
  /// [driveId] - The shared drive from which changes are returned. If specified
  /// the change IDs will be reflective of the shared drive; use the combined
  /// drive ID and change ID as an identifier.
  ///
  /// [includeCorpusRemovals] - Whether changes should include the file resource
  /// if the file is still accessible by the user at the time of the request,
  /// even when a file was removed from the list of changes and there will be no
  /// further change entries for this file.
  ///
  /// [includeDeleted] - Whether to include changes indicating that items have
  /// been removed from the list of changes, for example by deletion or loss of
  /// access.
  ///
  /// [includeItemsFromAllDrives] - Whether both My Drive and shared drive items
  /// should be included in results.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [includeSubscribed] - Whether to include changes outside the My Drive
  /// hierarchy in the result. When set to false, changes to files such as those
  /// in the Application Data folder or shared files which have not been added
  /// to My Drive are omitted from the result.
  ///
  /// [includeTeamDriveItems] - Deprecated use includeItemsFromAllDrives
  /// instead.
  ///
  /// [maxResults] - Maximum number of changes to return.
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response or to the response from the getStartPageToken method.
  ///
  /// [spaces] - A comma-separated list of spaces to query. Supported values are
  /// 'drive', 'appDataFolder' and 'photos'.
  ///
  /// [startChangeId] - Deprecated - use pageToken instead.
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
  async.Future<ChangeList> list({
    core.String? driveId,
    core.bool? includeCorpusRemovals,
    core.bool? includeDeleted,
    core.bool? includeItemsFromAllDrives,
    core.String? includePermissionsForView,
    core.bool? includeSubscribed,
    core.bool? includeTeamDriveItems,
    core.int? maxResults,
    core.String? pageToken,
    core.String? spaces,
    core.String? startChangeId,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? teamDriveId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (driveId != null) 'driveId': [driveId],
      if (includeCorpusRemovals != null)
        'includeCorpusRemovals': ['${includeCorpusRemovals}'],
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if (includeItemsFromAllDrives != null)
        'includeItemsFromAllDrives': ['${includeItemsFromAllDrives}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (includeSubscribed != null)
        'includeSubscribed': ['${includeSubscribed}'],
      if (includeTeamDriveItems != null)
        'includeTeamDriveItems': ['${includeTeamDriveItems}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (spaces != null) 'spaces': [spaces],
      if (startChangeId != null) 'startChangeId': [startChangeId],
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

  /// Subscribe to changes for a user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
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
  /// [includeDeleted] - Whether to include changes indicating that items have
  /// been removed from the list of changes, for example by deletion or loss of
  /// access.
  ///
  /// [includeItemsFromAllDrives] - Whether both My Drive and shared drive items
  /// should be included in results.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [includeSubscribed] - Whether to include changes outside the My Drive
  /// hierarchy in the result. When set to false, changes to files such as those
  /// in the Application Data folder or shared files which have not been added
  /// to My Drive are omitted from the result.
  ///
  /// [includeTeamDriveItems] - Deprecated use includeItemsFromAllDrives
  /// instead.
  ///
  /// [maxResults] - Maximum number of changes to return.
  ///
  /// [pageToken] - The token for continuing a previous list request on the next
  /// page. This should be set to the value of 'nextPageToken' from the previous
  /// response or to the response from the getStartPageToken method.
  ///
  /// [spaces] - A comma-separated list of spaces to query. Supported values are
  /// 'drive', 'appDataFolder' and 'photos'.
  ///
  /// [startChangeId] - Deprecated - use pageToken instead.
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
    Channel request, {
    core.String? driveId,
    core.bool? includeCorpusRemovals,
    core.bool? includeDeleted,
    core.bool? includeItemsFromAllDrives,
    core.String? includePermissionsForView,
    core.bool? includeSubscribed,
    core.bool? includeTeamDriveItems,
    core.int? maxResults,
    core.String? pageToken,
    core.String? spaces,
    core.String? startChangeId,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? teamDriveId,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (driveId != null) 'driveId': [driveId],
      if (includeCorpusRemovals != null)
        'includeCorpusRemovals': ['${includeCorpusRemovals}'],
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if (includeItemsFromAllDrives != null)
        'includeItemsFromAllDrives': ['${includeItemsFromAllDrives}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (includeSubscribed != null)
        'includeSubscribed': ['${includeSubscribed}'],
      if (includeTeamDriveItems != null)
        'includeTeamDriveItems': ['${includeTeamDriveItems}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (spaces != null) 'spaces': [spaces],
      if (startChangeId != null) 'startChangeId': [startChangeId],
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
    final _body = convert_1.json.encode(request.toJson());
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

class ChildrenResource {
  final commons.ApiRequester _requester;

  ChildrenResource(commons.ApiRequester client) : _requester = client;

  /// Removes a child from a folder.
  ///
  /// Request parameters:
  ///
  /// [folderId] - The ID of the folder.
  ///
  /// [childId] - The ID of the child.
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
  async.Future<void> delete(
    core.String folderId,
    core.String childId, {
    core.bool? enforceSingleParent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$folderId') +
        '/children/' +
        commons.escapeVariable('$childId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a specific child reference.
  ///
  /// Request parameters:
  ///
  /// [folderId] - The ID of the folder.
  ///
  /// [childId] - The ID of the child.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChildReference].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChildReference> get(
    core.String folderId,
    core.String childId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$folderId') +
        '/children/' +
        commons.escapeVariable('$childId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ChildReference.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a file into a folder.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [folderId] - The ID of the folder.
  ///
  /// [enforceSingleParent] - Deprecated. Adding files to multiple folders is no
  /// longer supported. Use shortcuts instead.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChildReference].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChildReference> insert(
    ChildReference request,
    core.String folderId, {
    core.bool? enforceSingleParent,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$folderId') + '/children';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ChildReference.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a folder's children.
  ///
  /// Request parameters:
  ///
  /// [folderId] - The ID of the folder.
  ///
  /// [maxResults] - Maximum number of children to return.
  ///
  /// [orderBy] - A comma-separated list of sort keys. Valid keys are
  /// 'createdDate', 'folder', 'lastViewedByMeDate', 'modifiedByMeDate',
  /// 'modifiedDate', 'quotaBytesUsed', 'recency', 'sharedWithMeDate',
  /// 'starred', and 'title'. Each key sorts ascending by default, but may be
  /// reversed with the 'desc' modifier. Example usage:
  /// ?orderBy=folder,modifiedDate desc,title. Please note that there is a
  /// current limitation for users with approximately one million files in which
  /// the requested sort order is ignored.
  ///
  /// [pageToken] - Page token for children.
  ///
  /// [q] - Query string for searching children.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChildList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChildList> list(
    core.String folderId, {
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? q,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (q != null) 'q': [q],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$folderId') + '/children';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ChildList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class CommentsResource {
  final commons.ApiRequester _requester;

  CommentsResource(commons.ApiRequester client) : _requester = client;

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
  /// [includeDeleted] - If set, this will succeed when retrieving a deleted
  /// comment, and will include any deleted replies.
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

  /// Creates a new comment on the given file.
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
  async.Future<Comment> insert(
    Comment request,
    core.String fileId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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

  /// Lists a file's comments.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [includeDeleted] - If set, all comments and replies, including deleted
  /// comments and replies (with content stripped) will be returned.
  ///
  /// [maxResults] - The maximum number of discussions to include in the
  /// response, used for paging.
  /// Value must be between "0" and "100".
  ///
  /// [pageToken] - The continuation token, used to page through large result
  /// sets. To get the next page of results, set this parameter to the value of
  /// "nextPageToken" from the previous response.
  ///
  /// [updatedMin] - Only discussions that were updated after this timestamp
  /// will be returned. Formatted as an RFC 3339 timestamp.
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
    core.int? maxResults,
    core.String? pageToken,
    core.String? updatedMin,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (updatedMin != null) 'updatedMin': [updatedMin],
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

  /// Updates an existing comment.
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
  async.Future<Comment> patch(
    Comment request,
    core.String fileId,
    core.String commentId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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

  /// Updates an existing comment.
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
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/comments/' +
        commons.escapeVariable('$commentId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Comment.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DrivesResource {
  final commons.ApiRequester _requester;

  DrivesResource(commons.ApiRequester client) : _requester = client;

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
  async.Future<Drive> insert(
    Drive request,
    core.String requestId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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

  /// Lists the user's shared drives.
  ///
  /// Request parameters:
  ///
  /// [maxResults] - Maximum number of shared drives to return.
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
    core.int? maxResults,
    core.String? pageToken,
    core.String? q,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
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

  /// Updates the metadata for a shared drive.
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
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'drives/' + commons.escapeVariable('$driveId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Drive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class FilesResource {
  final commons.ApiRequester _requester;

  FilesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a copy of the specified file.
  ///
  /// Folders cannot be copied.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file to copy.
  ///
  /// [convert] - Whether to convert this file to the corresponding Docs Editors
  /// format.
  ///
  /// [enforceSingleParent] - Deprecated. Copying files into multiple folders is
  /// no longer supported. Use shortcuts instead.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [ocr] - Whether to attempt OCR on .jpg, .png, .gif, or .pdf uploads.
  ///
  /// [ocrLanguage] - If ocr is true, hints at the language to use. Valid values
  /// are BCP 47 codes.
  ///
  /// [pinned] - Whether to pin the head revision of the new copy. A file can
  /// have a maximum of 200 pinned revisions.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [timedTextLanguage] - The language of the timed text.
  ///
  /// [timedTextTrackName] - The timed text track name.
  ///
  /// [visibility] - The visibility of the new file. This parameter is only
  /// relevant when the source is not a native Google Doc and convert=false.
  /// Possible string values are:
  /// - "DEFAULT" : The visibility of the new file is determined by the user's
  /// default visibility/sharing policies.
  /// - "PRIVATE" : The new file will be visible to only the owner.
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
    core.bool? convert,
    core.bool? enforceSingleParent,
    core.String? includePermissionsForView,
    core.bool? ocr,
    core.String? ocrLanguage,
    core.bool? pinned,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? timedTextLanguage,
    core.String? timedTextTrackName,
    core.String? visibility,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (convert != null) 'convert': ['${convert}'],
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (ocr != null) 'ocr': ['${ocr}'],
      if (ocrLanguage != null) 'ocrLanguage': [ocrLanguage],
      if (pinned != null) 'pinned': ['${pinned}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (timedTextLanguage != null) 'timedTextLanguage': [timedTextLanguage],
      if (timedTextTrackName != null)
        'timedTextTrackName': [timedTextTrackName],
      if (visibility != null) 'visibility': [visibility],
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

  /// Permanently deletes a file by ID.
  ///
  /// Skips the trash. The currently authenticated user must own the file or be
  /// an organizer on the parent for shared drive files.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file to delete.
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

  /// Generates a set of file IDs which can be provided in insert or copy
  /// requests.
  ///
  /// Request parameters:
  ///
  /// [maxResults] - Maximum number of IDs to return.
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
    core.int? maxResults,
    core.String? space,
    core.String? type,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
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
  /// [fileId] - The ID for the file in question.
  ///
  /// [acknowledgeAbuse] - Whether the user is acknowledging the risk of
  /// downloading known malware or other abusive files.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [projection] - This parameter is deprecated and has no function.
  /// Possible string values are:
  /// - "BASIC" : Deprecated
  /// - "FULL" : Deprecated
  ///
  /// [revisionId] - Specifies the Revision ID that should be downloaded.
  /// Ignored unless alt=media is specified.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [updateViewedDate] - Deprecated: Use files.update with
  /// modifiedDateBehavior=noChange, updateViewedDate=true and an empty request
  /// body.
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
    core.String? projection,
    core.String? revisionId,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? updateViewedDate,
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acknowledgeAbuse != null) 'acknowledgeAbuse': ['${acknowledgeAbuse}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (projection != null) 'projection': [projection],
      if (revisionId != null) 'revisionId': [revisionId],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (updateViewedDate != null) 'updateViewedDate': ['${updateViewedDate}'],
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

  /// Insert a new file.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [convert] - Whether to convert this file to the corresponding Docs Editors
  /// format.
  ///
  /// [enforceSingleParent] - Deprecated. Creating files in multiple folders is
  /// no longer supported.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [ocr] - Whether to attempt OCR on .jpg, .png, .gif, or .pdf uploads.
  ///
  /// [ocrLanguage] - If ocr is true, hints at the language to use. Valid values
  /// are BCP 47 codes.
  ///
  /// [pinned] - Whether to pin the head revision of the uploaded file. A file
  /// can have a maximum of 200 pinned revisions.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [timedTextLanguage] - The language of the timed text.
  ///
  /// [timedTextTrackName] - The timed text track name.
  ///
  /// [useContentAsIndexableText] - Whether to use the content as indexable
  /// text.
  ///
  /// [visibility] - The visibility of the new file. This parameter is only
  /// relevant when convert=false.
  /// Possible string values are:
  /// - "DEFAULT" : The visibility of the new file is determined by the user's
  /// default visibility/sharing policies.
  /// - "PRIVATE" : The new file will be visible to only the owner.
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
  async.Future<File> insert(
    File request, {
    core.bool? convert,
    core.bool? enforceSingleParent,
    core.String? includePermissionsForView,
    core.bool? ocr,
    core.String? ocrLanguage,
    core.bool? pinned,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? timedTextLanguage,
    core.String? timedTextTrackName,
    core.bool? useContentAsIndexableText,
    core.String? visibility,
    core.String? $fields,
    commons.UploadOptions uploadOptions = commons.UploadOptions.defaultOptions,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (convert != null) 'convert': ['${convert}'],
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (ocr != null) 'ocr': ['${ocr}'],
      if (ocrLanguage != null) 'ocrLanguage': [ocrLanguage],
      if (pinned != null) 'pinned': ['${pinned}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (timedTextLanguage != null) 'timedTextLanguage': [timedTextLanguage],
      if (timedTextTrackName != null)
        'timedTextTrackName': [timedTextTrackName],
      if (useContentAsIndexableText != null)
        'useContentAsIndexableText': ['${useContentAsIndexableText}'],
      if (visibility != null) 'visibility': [visibility],
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'files';
    } else if (uploadOptions is commons.ResumableUploadOptions) {
      _url = '/resumable/upload/drive/v2/files';
    } else {
      _url = '/upload/drive/v2/files';
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

  /// Lists the user's files.
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
  /// [corpus] - The body of items (files/documents) to which the query applies.
  /// Deprecated: use 'corpora' instead.
  /// Possible string values are:
  /// - "DEFAULT" : The items that the user has accessed.
  /// - "DOMAIN" : Items shared to the user's domain.
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
  /// [maxResults] - The maximum number of files to return per page. Partial or
  /// empty result pages are possible even before the end of the files list has
  /// been reached.
  ///
  /// [orderBy] - A comma-separated list of sort keys. Valid keys are
  /// 'createdDate', 'folder', 'lastViewedByMeDate', 'modifiedByMeDate',
  /// 'modifiedDate', 'quotaBytesUsed', 'recency', 'sharedWithMeDate',
  /// 'starred', 'title', and 'title_natural'. Each key sorts ascending by
  /// default, but may be reversed with the 'desc' modifier. Example usage:
  /// ?orderBy=folder,modifiedDate desc,title. Please note that there is a
  /// current limitation for users with approximately one million files in which
  /// the requested sort order is ignored.
  ///
  /// [pageToken] - Page token for files.
  ///
  /// [projection] - This parameter is deprecated and has no function.
  /// Possible string values are:
  /// - "BASIC" : Deprecated
  /// - "FULL" : Deprecated
  ///
  /// [q] - Query string for searching files.
  ///
  /// [spaces] - A comma-separated list of spaces to query. Supported values are
  /// 'drive', 'appDataFolder' and 'photos'.
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
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? projection,
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
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (projection != null) 'projection': [projection],
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

  /// Updates file metadata and/or content.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file to update.
  ///
  /// [addParents] - Comma-separated list of parent IDs to add.
  ///
  /// [convert] - This parameter is deprecated and has no function.
  ///
  /// [enforceSingleParent] - Deprecated. Adding files to multiple folders is no
  /// longer supported. Use shortcuts instead.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [modifiedDateBehavior] - Determines the behavior in which modifiedDate is
  /// updated. This overrides setModifiedDate.
  /// Possible string values are:
  /// - "fromBody" : Set modifiedDate to the value provided in the body of the
  /// request. No change if no value was provided.
  /// - "fromBodyIfNeeded" : Set modifiedDate to the value provided in the body
  /// of the request depending on other contents of the update.
  /// - "fromBodyOrNow" : Set modifiedDate to the value provided in the body of
  /// the request, or to the current time if no value was provided.
  /// - "noChange" : Maintain the previous value of modifiedDate.
  /// - "now" : Set modifiedDate to the current time.
  /// - "nowIfNeeded" : Set modifiedDate to the current time depending on
  /// contents of the update.
  ///
  /// [newRevision] - Whether a blob upload should create a new revision. If
  /// false, the blob data in the current head revision is replaced. If true or
  /// not set, a new blob is created as head revision, and previous unpinned
  /// revisions are preserved for a short period of time. Pinned revisions are
  /// stored indefinitely, using additional storage quota, up to a maximum of
  /// 200 revisions. For details on how revisions are retained, see the Drive
  /// Help Center. Note that this field is ignored if there is no payload in the
  /// request.
  ///
  /// [ocr] - Whether to attempt OCR on .jpg, .png, .gif, or .pdf uploads.
  ///
  /// [ocrLanguage] - If ocr is true, hints at the language to use. Valid values
  /// are BCP 47 codes.
  ///
  /// [pinned] - Whether to pin the new revision. A file can have a maximum of
  /// 200 pinned revisions. Note that this field is ignored if there is no
  /// payload in the request.
  ///
  /// [removeParents] - Comma-separated list of parent IDs to remove.
  ///
  /// [setModifiedDate] - Whether to set the modified date using the value
  /// supplied in the request body. Setting this field to true is equivalent to
  /// modifiedDateBehavior=fromBodyOrNow, and false is equivalent to
  /// modifiedDateBehavior=now. To prevent any changes to the modified date set
  /// modifiedDateBehavior=noChange.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [timedTextLanguage] - The language of the timed text.
  ///
  /// [timedTextTrackName] - The timed text track name.
  ///
  /// [updateViewedDate] - Whether to update the view date after successfully
  /// updating the file.
  ///
  /// [useContentAsIndexableText] - Whether to use the content as indexable
  /// text.
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
  async.Future<File> patch(
    File request,
    core.String fileId, {
    core.String? addParents,
    core.bool? convert,
    core.bool? enforceSingleParent,
    core.String? includePermissionsForView,
    core.String? modifiedDateBehavior,
    core.bool? newRevision,
    core.bool? ocr,
    core.String? ocrLanguage,
    core.bool? pinned,
    core.String? removeParents,
    core.bool? setModifiedDate,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? timedTextLanguage,
    core.String? timedTextTrackName,
    core.bool? updateViewedDate,
    core.bool? useContentAsIndexableText,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (addParents != null) 'addParents': [addParents],
      if (convert != null) 'convert': ['${convert}'],
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (modifiedDateBehavior != null)
        'modifiedDateBehavior': [modifiedDateBehavior],
      if (newRevision != null) 'newRevision': ['${newRevision}'],
      if (ocr != null) 'ocr': ['${ocr}'],
      if (ocrLanguage != null) 'ocrLanguage': [ocrLanguage],
      if (pinned != null) 'pinned': ['${pinned}'],
      if (removeParents != null) 'removeParents': [removeParents],
      if (setModifiedDate != null) 'setModifiedDate': ['${setModifiedDate}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (timedTextLanguage != null) 'timedTextLanguage': [timedTextLanguage],
      if (timedTextTrackName != null)
        'timedTextTrackName': [timedTextTrackName],
      if (updateViewedDate != null) 'updateViewedDate': ['${updateViewedDate}'],
      if (useContentAsIndexableText != null)
        'useContentAsIndexableText': ['${useContentAsIndexableText}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Set the file's updated time to the current server time.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file to update.
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
  /// Completes with a [File].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<File> touch(
    core.String fileId, {
    core.String? includePermissionsForView,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/touch';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Moves a file to the trash.
  ///
  /// The currently authenticated user must own the file or be at least a
  /// fileOrganizer on the parent for shared drive files. Only the owner may
  /// trash a file. The trashed item is excluded from all files.list responses
  /// returned for any user who does not own the file. However, all users with
  /// access to the file can see the trashed item metadata in an API response.
  /// All users with access can copy, download, export, and share the file.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file to trash.
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
  /// Completes with a [File].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<File> trash(
    core.String fileId, {
    core.String? includePermissionsForView,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/trash';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Restores a file from the trash.
  ///
  /// The currently authenticated user must own the file or be at least a
  /// fileOrganizer on the parent for shared drive files. Only the owner may
  /// untrash a file.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file to untrash.
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
  /// Completes with a [File].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<File> untrash(
    core.String fileId, {
    core.String? includePermissionsForView,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/untrash';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates file metadata and/or content.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file to update.
  ///
  /// [addParents] - Comma-separated list of parent IDs to add.
  ///
  /// [convert] - This parameter is deprecated and has no function.
  ///
  /// [enforceSingleParent] - Deprecated. Adding files to multiple folders is no
  /// longer supported. Use shortcuts instead.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [modifiedDateBehavior] - Determines the behavior in which modifiedDate is
  /// updated. This overrides setModifiedDate.
  /// Possible string values are:
  /// - "fromBody" : Set modifiedDate to the value provided in the body of the
  /// request. No change if no value was provided.
  /// - "fromBodyIfNeeded" : Set modifiedDate to the value provided in the body
  /// of the request depending on other contents of the update.
  /// - "fromBodyOrNow" : Set modifiedDate to the value provided in the body of
  /// the request, or to the current time if no value was provided.
  /// - "noChange" : Maintain the previous value of modifiedDate.
  /// - "now" : Set modifiedDate to the current time.
  /// - "nowIfNeeded" : Set modifiedDate to the current time depending on
  /// contents of the update.
  ///
  /// [newRevision] - Whether a blob upload should create a new revision. If
  /// false, the blob data in the current head revision is replaced. If true or
  /// not set, a new blob is created as head revision, and previous unpinned
  /// revisions are preserved for a short period of time. Pinned revisions are
  /// stored indefinitely, using additional storage quota, up to a maximum of
  /// 200 revisions. For details on how revisions are retained, see the Drive
  /// Help Center. Note that this field is ignored if there is no payload in the
  /// request.
  ///
  /// [ocr] - Whether to attempt OCR on .jpg, .png, .gif, or .pdf uploads.
  ///
  /// [ocrLanguage] - If ocr is true, hints at the language to use. Valid values
  /// are BCP 47 codes.
  ///
  /// [pinned] - Whether to pin the new revision. A file can have a maximum of
  /// 200 pinned revisions. Note that this field is ignored if there is no
  /// payload in the request.
  ///
  /// [removeParents] - Comma-separated list of parent IDs to remove.
  ///
  /// [setModifiedDate] - Whether to set the modified date using the value
  /// supplied in the request body. Setting this field to true is equivalent to
  /// modifiedDateBehavior=fromBodyOrNow, and false is equivalent to
  /// modifiedDateBehavior=now. To prevent any changes to the modified date set
  /// modifiedDateBehavior=noChange.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [timedTextLanguage] - The language of the timed text.
  ///
  /// [timedTextTrackName] - The timed text track name.
  ///
  /// [updateViewedDate] - Whether to update the view date after successfully
  /// updating the file.
  ///
  /// [useContentAsIndexableText] - Whether to use the content as indexable
  /// text.
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
    core.bool? convert,
    core.bool? enforceSingleParent,
    core.String? includePermissionsForView,
    core.String? modifiedDateBehavior,
    core.bool? newRevision,
    core.bool? ocr,
    core.String? ocrLanguage,
    core.bool? pinned,
    core.String? removeParents,
    core.bool? setModifiedDate,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? timedTextLanguage,
    core.String? timedTextTrackName,
    core.bool? updateViewedDate,
    core.bool? useContentAsIndexableText,
    core.String? $fields,
    commons.UploadOptions uploadOptions = commons.UploadOptions.defaultOptions,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (addParents != null) 'addParents': [addParents],
      if (convert != null) 'convert': ['${convert}'],
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (modifiedDateBehavior != null)
        'modifiedDateBehavior': [modifiedDateBehavior],
      if (newRevision != null) 'newRevision': ['${newRevision}'],
      if (ocr != null) 'ocr': ['${ocr}'],
      if (ocrLanguage != null) 'ocrLanguage': [ocrLanguage],
      if (pinned != null) 'pinned': ['${pinned}'],
      if (removeParents != null) 'removeParents': [removeParents],
      if (setModifiedDate != null) 'setModifiedDate': ['${setModifiedDate}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (timedTextLanguage != null) 'timedTextLanguage': [timedTextLanguage],
      if (timedTextTrackName != null)
        'timedTextTrackName': [timedTextTrackName],
      if (updateViewedDate != null) 'updateViewedDate': ['${updateViewedDate}'],
      if (useContentAsIndexableText != null)
        'useContentAsIndexableText': ['${useContentAsIndexableText}'],
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'files/' + commons.escapeVariable('$fileId');
    } else if (uploadOptions is commons.ResumableUploadOptions) {
      _url = '/resumable/upload/drive/v2/files/' +
          commons.escapeVariable('$fileId');
    } else {
      _url = '/upload/drive/v2/files/' + commons.escapeVariable('$fileId');
    }

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: uploadOptions,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Subscribe to changes on a file
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file in question.
  ///
  /// [acknowledgeAbuse] - Whether the user is acknowledging the risk of
  /// downloading known malware or other abusive files.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [projection] - This parameter is deprecated and has no function.
  /// Possible string values are:
  /// - "BASIC" : Deprecated
  /// - "FULL" : Deprecated
  ///
  /// [revisionId] - Specifies the Revision ID that should be downloaded.
  /// Ignored unless alt=media is specified.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [updateViewedDate] - Deprecated: Use files.update with
  /// modifiedDateBehavior=noChange, updateViewedDate=true and an empty request
  /// body.
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
    core.String? projection,
    core.String? revisionId,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? updateViewedDate,
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (acknowledgeAbuse != null) 'acknowledgeAbuse': ['${acknowledgeAbuse}'],
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (projection != null) 'projection': [projection],
      if (revisionId != null) 'revisionId': [revisionId],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if (updateViewedDate != null) 'updateViewedDate': ['${updateViewedDate}'],
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

class ParentsResource {
  final commons.ApiRequester _requester;

  ParentsResource(commons.ApiRequester client) : _requester = client;

  /// Removes a parent from a file.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [parentId] - The ID of the parent.
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
  async.Future<void> delete(
    core.String fileId,
    core.String parentId, {
    core.bool? enforceSingleParent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/parents/' +
        commons.escapeVariable('$parentId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a specific parent reference.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [parentId] - The ID of the parent.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ParentReference].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ParentReference> get(
    core.String fileId,
    core.String parentId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/parents/' +
        commons.escapeVariable('$parentId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ParentReference.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a parent folder for a file.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [enforceSingleParent] - Deprecated. Adding files to multiple folders is no
  /// longer supported. Use shortcuts instead.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ParentReference].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ParentReference> insert(
    ParentReference request,
    core.String fileId, {
    core.bool? enforceSingleParent,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (supportsAllDrives != null)
        'supportsAllDrives': ['${supportsAllDrives}'],
      if (supportsTeamDrives != null)
        'supportsTeamDrives': ['${supportsTeamDrives}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/parents';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ParentReference.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a file's parents.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ParentList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ParentList> list(
    core.String fileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/parents';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ParentList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PermissionsResource {
  final commons.ApiRequester _requester;

  PermissionsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a permission from a file or shared drive.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file or shared drive.
  ///
  /// [permissionId] - The ID for the permission.
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
  /// [fileId] - The ID for the file or shared drive.
  ///
  /// [permissionId] - The ID for the permission.
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

  /// Returns the permission ID for an email address.
  ///
  /// Request parameters:
  ///
  /// [email] - The email address for which to return a permission ID
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PermissionId].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PermissionId> getIdForEmail(
    core.String email, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'permissionIds/' + commons.escapeVariable('$email');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PermissionId.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a permission for a file or shared drive.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file or shared drive.
  ///
  /// [emailMessage] - A plain text custom message to include in notification
  /// emails.
  ///
  /// [enforceSingleParent] - Deprecated. See moveToNewOwnersRoot for details.
  ///
  /// [moveToNewOwnersRoot] - This parameter will only take effect if the item
  /// is not in a shared drive and the request is attempting to transfer the
  /// ownership of the item. If set to true, the item will be moved to the new
  /// owner's My Drive root folder and all prior parents removed. If set to
  /// false, parents are not changed.
  ///
  /// [sendNotificationEmails] - Whether to send notification emails when
  /// sharing to users or groups. This parameter is ignored and an email is sent
  /// if the role is owner.
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
  async.Future<Permission> insert(
    Permission request,
    core.String fileId, {
    core.String? emailMessage,
    core.bool? enforceSingleParent,
    core.bool? moveToNewOwnersRoot,
    core.bool? sendNotificationEmails,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (emailMessage != null) 'emailMessage': [emailMessage],
      if (enforceSingleParent != null)
        'enforceSingleParent': ['${enforceSingleParent}'],
      if (moveToNewOwnersRoot != null)
        'moveToNewOwnersRoot': ['${moveToNewOwnersRoot}'],
      if (sendNotificationEmails != null)
        'sendNotificationEmails': ['${sendNotificationEmails}'],
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
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Permission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a file's or shared drive's permissions.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file or shared drive.
  ///
  /// [includePermissionsForView] - Specifies which additional view's
  /// permissions to include in the response. Only 'published' is supported.
  ///
  /// [maxResults] - The maximum number of permissions to return per page. When
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
    core.int? maxResults,
    core.String? pageToken,
    core.bool? supportsAllDrives,
    core.bool? supportsTeamDrives,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includePermissionsForView != null)
        'includePermissionsForView': [includePermissionsForView],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
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

  /// Updates a permission using patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file or shared drive.
  ///
  /// [permissionId] - The ID for the permission.
  ///
  /// [removeExpiration] - Whether to remove the expiration date.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [transferOwnership] - Whether changing a role to 'owner' downgrades the
  /// current owners to writers. Does nothing if the specified role is not
  /// 'owner'.
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
  async.Future<Permission> patch(
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
    final _body = convert_1.json.encode(request.toJson());
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

  /// Updates a permission.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file or shared drive.
  ///
  /// [permissionId] - The ID for the permission.
  ///
  /// [removeExpiration] - Whether to remove the expiration date.
  ///
  /// [supportsAllDrives] - Whether the requesting application supports both My
  /// Drives and shared drives.
  ///
  /// [supportsTeamDrives] - Deprecated use supportsAllDrives instead.
  ///
  /// [transferOwnership] - Whether changing a role to 'owner' downgrades the
  /// current owners to writers. Does nothing if the specified role is not
  /// 'owner'.
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
    final _body = convert_1.json.encode(request.toJson());
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
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Permission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PropertiesResource {
  final commons.ApiRequester _requester;

  PropertiesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a property.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [propertyKey] - The key of the property.
  ///
  /// [visibility] - The visibility of the property.
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
    core.String propertyKey, {
    core.String? visibility,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (visibility != null) 'visibility': [visibility],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/properties/' +
        commons.escapeVariable('$propertyKey');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a property by its key.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [propertyKey] - The key of the property.
  ///
  /// [visibility] - The visibility of the property.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Property].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Property> get(
    core.String fileId,
    core.String propertyKey, {
    core.String? visibility,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (visibility != null) 'visibility': [visibility],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/properties/' +
        commons.escapeVariable('$propertyKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Property.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a property to a file, or updates it if it already exists.
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
  /// Completes with a [Property].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Property> insert(
    Property request,
    core.String fileId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/properties';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Property.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a file's properties.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PropertyList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PropertyList> list(
    core.String fileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' + commons.escapeVariable('$fileId') + '/properties';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PropertyList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a property.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [propertyKey] - The key of the property.
  ///
  /// [visibility] - The visibility of the property. Allowed values are PRIVATE
  /// and PUBLIC. (Default: PRIVATE)
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Property].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Property> patch(
    Property request,
    core.String fileId,
    core.String propertyKey, {
    core.String? visibility,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (visibility != null) 'visibility': [visibility],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/properties/' +
        commons.escapeVariable('$propertyKey');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Property.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a property.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [propertyKey] - The key of the property.
  ///
  /// [visibility] - The visibility of the property. Allowed values are PRIVATE
  /// and PUBLIC. (Default: PRIVATE)
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Property].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Property> update(
    Property request,
    core.String fileId,
    core.String propertyKey, {
    core.String? visibility,
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (visibility != null) 'visibility': [visibility],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/properties/' +
        commons.escapeVariable('$propertyKey');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Property.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class RepliesResource {
  final commons.ApiRequester _requester;

  RepliesResource(commons.ApiRequester client) : _requester = client;

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

  /// Gets a reply.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [replyId] - The ID of the reply.
  ///
  /// [includeDeleted] - If set, this will succeed when retrieving a deleted
  /// reply.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CommentReply].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommentReply> get(
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
    return CommentReply.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new reply to the given comment.
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
  /// Completes with a [CommentReply].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommentReply> insert(
    CommentReply request,
    core.String fileId,
    core.String commentId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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
    return CommentReply.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all of the replies to a comment.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [commentId] - The ID of the comment.
  ///
  /// [includeDeleted] - If set, all replies, including deleted replies (with
  /// content stripped) will be returned.
  ///
  /// [maxResults] - The maximum number of replies to include in the response,
  /// used for paging.
  /// Value must be between "0" and "100".
  ///
  /// [pageToken] - The continuation token, used to page through large result
  /// sets. To get the next page of results, set this parameter to the value of
  /// "nextPageToken" from the previous response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CommentReplyList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommentReplyList> list(
    core.String fileId,
    core.String commentId, {
    core.bool? includeDeleted,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
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
    return CommentReplyList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing reply.
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
  /// Completes with a [CommentReply].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommentReply> patch(
    CommentReply request,
    core.String fileId,
    core.String commentId,
    core.String replyId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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
    return CommentReply.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing reply.
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
  /// Completes with a [CommentReply].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommentReply> update(
    CommentReply request,
    core.String fileId,
    core.String commentId,
    core.String replyId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return CommentReply.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RevisionsResource {
  final commons.ApiRequester _requester;

  RevisionsResource(commons.ApiRequester client) : _requester = client;

  /// Permanently deletes a file version.
  ///
  /// You can only delete revisions for files with binary content, like images
  /// or videos. Revisions for other files, like Google Docs or Sheets, and the
  /// last remaining file version can't be deleted.
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

  /// Gets a specific revision.
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
  async.Future<Revision> get(
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

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Revision.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists a file's revisions.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID of the file.
  ///
  /// [maxResults] - Maximum number of revisions to return.
  /// Value must be between "1" and "1000".
  ///
  /// [pageToken] - Page token for revisions. To get the next page of results,
  /// set this parameter to the value of "nextPageToken" from the previous
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
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
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

  /// Updates a revision.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file.
  ///
  /// [revisionId] - The ID for the revision.
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
  async.Future<Revision> patch(
    Revision request,
    core.String fileId,
    core.String revisionId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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

  /// Updates a revision.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [fileId] - The ID for the file.
  ///
  /// [revisionId] - The ID for the revision.
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
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'files/' +
        commons.escapeVariable('$fileId') +
        '/revisions/' +
        commons.escapeVariable('$revisionId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Revision.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class TeamdrivesResource {
  final commons.ApiRequester _requester;

  TeamdrivesResource(commons.ApiRequester client) : _requester = client;

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

  /// Deprecated use drives.insert instead.
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
  async.Future<TeamDrive> insert(
    TeamDrive request,
    core.String requestId, {
    core.String? $fields,
  }) async {
    final _body = convert_1.json.encode(request.toJson());
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

  /// Deprecated use drives.list instead.
  ///
  /// Request parameters:
  ///
  /// [maxResults] - Maximum number of Team Drives to return.
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
    core.int? maxResults,
    core.String? pageToken,
    core.String? q,
    core.bool? useDomainAdminAccess,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
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

  /// Deprecated use drives.update instead.
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
    final _body = convert_1.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (useDomainAdminAccess != null)
        'useDomainAdminAccess': ['${useDomainAdminAccess}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'teamdrives/' + commons.escapeVariable('$teamDriveId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return TeamDrive.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AboutAdditionalRoleInfoRoleSets {
  /// The supported additional roles with the primary role.
  core.List<core.String>? additionalRoles;

  /// A primary permission role.
  core.String? primaryRole;

  AboutAdditionalRoleInfoRoleSets();

  AboutAdditionalRoleInfoRoleSets.fromJson(core.Map _json) {
    if (_json.containsKey('additionalRoles')) {
      additionalRoles = (_json['additionalRoles'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('primaryRole')) {
      primaryRole = _json['primaryRole'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalRoles != null) 'additionalRoles': additionalRoles!,
        if (primaryRole != null) 'primaryRole': primaryRole!,
      };
}

class AboutAdditionalRoleInfo {
  /// The supported additional roles per primary role.
  core.List<AboutAdditionalRoleInfoRoleSets>? roleSets;

  /// The content type that this additional role info applies to.
  core.String? type;

  AboutAdditionalRoleInfo();

  AboutAdditionalRoleInfo.fromJson(core.Map _json) {
    if (_json.containsKey('roleSets')) {
      roleSets = (_json['roleSets'] as core.List)
          .map<AboutAdditionalRoleInfoRoleSets>((value) =>
              AboutAdditionalRoleInfoRoleSets.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (roleSets != null)
          'roleSets': roleSets!.map((value) => value.toJson()).toList(),
        if (type != null) 'type': type!,
      };
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

class AboutExportFormats {
  /// The content type to convert from.
  core.String? source;

  /// The possible content types to convert to.
  core.List<core.String>? targets;

  AboutExportFormats();

  AboutExportFormats.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('targets')) {
      targets = (_json['targets'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!,
        if (targets != null) 'targets': targets!,
      };
}

class AboutFeatures {
  /// The name of the feature.
  core.String? featureName;

  /// The request limit rate for this feature, in queries per second.
  core.double? featureRate;

  AboutFeatures();

  AboutFeatures.fromJson(core.Map _json) {
    if (_json.containsKey('featureName')) {
      featureName = _json['featureName'] as core.String;
    }
    if (_json.containsKey('featureRate')) {
      featureRate = (_json['featureRate'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (featureName != null) 'featureName': featureName!,
        if (featureRate != null) 'featureRate': featureRate!,
      };
}

class AboutImportFormats {
  /// The imported file's content type to convert from.
  core.String? source;

  /// The possible content types to convert to.
  core.List<core.String>? targets;

  AboutImportFormats();

  AboutImportFormats.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('targets')) {
      targets = (_json['targets'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!,
        if (targets != null) 'targets': targets!,
      };
}

class AboutMaxUploadSizes {
  /// The max upload size for this type.
  core.String? size;

  /// The file type.
  core.String? type;

  AboutMaxUploadSizes();

  AboutMaxUploadSizes.fromJson(core.Map _json) {
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (size != null) 'size': size!,
        if (type != null) 'type': type!,
      };
}

class AboutQuotaBytesByService {
  /// The storage quota bytes used by the service.
  core.String? bytesUsed;

  /// The service's name, e.g. DRIVE, GMAIL, or PHOTOS.
  core.String? serviceName;

  AboutQuotaBytesByService();

  AboutQuotaBytesByService.fromJson(core.Map _json) {
    if (_json.containsKey('bytesUsed')) {
      bytesUsed = _json['bytesUsed'] as core.String;
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bytesUsed != null) 'bytesUsed': bytesUsed!,
        if (serviceName != null) 'serviceName': serviceName!,
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

/// An item with user information and settings.
class About {
  /// Information about supported additional roles per file type.
  ///
  /// The most specific type takes precedence.
  core.List<AboutAdditionalRoleInfo>? additionalRoleInfo;

  /// Whether the user can create shared drives.
  core.bool? canCreateDrives;

  /// Deprecated - use canCreateDrives instead.
  core.bool? canCreateTeamDrives;

  /// The domain sharing policy for the current user.
  ///
  /// Possible values are:
  /// - allowed
  /// - allowedWithWarning
  /// - incomingOnly
  /// - disallowed
  core.String? domainSharingPolicy;

  /// A list of themes that are supported for shared drives.
  core.List<AboutDriveThemes>? driveThemes;

  /// The ETag of the item.
  core.String? etag;

  /// The allowable export formats.
  core.List<AboutExportFormats>? exportFormats;

  /// List of additional features enabled on this account.
  core.List<AboutFeatures>? features;

  /// The palette of allowable folder colors as RGB hex strings.
  core.List<core.String>? folderColorPalette;

  /// The allowable import formats.
  core.List<AboutImportFormats>? importFormats;

  /// A boolean indicating whether the authenticated app is installed by the
  /// authenticated user.
  core.bool? isCurrentAppInstalled;

  /// This is always drive#about.
  core.String? kind;

  /// The user's language or locale code, as defined by BCP 47, with some
  /// extensions from Unicode's LDML format
  /// (http://www.unicode.org/reports/tr35/).
  core.String? languageCode;

  /// The largest change id.
  core.String? largestChangeId;

  /// List of max upload sizes for each file type.
  ///
  /// The most specific type takes precedence.
  core.List<AboutMaxUploadSizes>? maxUploadSizes;

  /// The name of the current user.
  core.String? name;

  /// The current user's ID as visible in the permissions collection.
  core.String? permissionId;

  /// The amount of storage quota used by different Google services.
  core.List<AboutQuotaBytesByService>? quotaBytesByService;

  /// The total number of quota bytes.
  ///
  /// This is only relevant when quotaType is LIMITED.
  core.String? quotaBytesTotal;

  /// The number of quota bytes used by Google Drive.
  core.String? quotaBytesUsed;

  /// The number of quota bytes used by all Google apps (Drive, Picasa, etc.).
  core.String? quotaBytesUsedAggregate;

  /// The number of quota bytes used by trashed items.
  core.String? quotaBytesUsedInTrash;

  /// The type of the user's storage quota.
  ///
  /// Possible values are:
  /// - LIMITED
  /// - UNLIMITED
  core.String? quotaType;

  /// The number of remaining change ids, limited to no more than 2500.
  core.String? remainingChangeIds;

  /// The id of the root folder.
  core.String? rootFolderId;

  /// A link back to this item.
  core.String? selfLink;

  /// Deprecated - use driveThemes instead.
  core.List<AboutTeamDriveThemes>? teamDriveThemes;

  /// The authenticated user.
  User? user;

  About();

  About.fromJson(core.Map _json) {
    if (_json.containsKey('additionalRoleInfo')) {
      additionalRoleInfo = (_json['additionalRoleInfo'] as core.List)
          .map<AboutAdditionalRoleInfo>((value) =>
              AboutAdditionalRoleInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('canCreateDrives')) {
      canCreateDrives = _json['canCreateDrives'] as core.bool;
    }
    if (_json.containsKey('canCreateTeamDrives')) {
      canCreateTeamDrives = _json['canCreateTeamDrives'] as core.bool;
    }
    if (_json.containsKey('domainSharingPolicy')) {
      domainSharingPolicy = _json['domainSharingPolicy'] as core.String;
    }
    if (_json.containsKey('driveThemes')) {
      driveThemes = (_json['driveThemes'] as core.List)
          .map<AboutDriveThemes>((value) => AboutDriveThemes.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('exportFormats')) {
      exportFormats = (_json['exportFormats'] as core.List)
          .map<AboutExportFormats>((value) => AboutExportFormats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('features')) {
      features = (_json['features'] as core.List)
          .map<AboutFeatures>((value) => AboutFeatures.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('folderColorPalette')) {
      folderColorPalette = (_json['folderColorPalette'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('importFormats')) {
      importFormats = (_json['importFormats'] as core.List)
          .map<AboutImportFormats>((value) => AboutImportFormats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('isCurrentAppInstalled')) {
      isCurrentAppInstalled = _json['isCurrentAppInstalled'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('largestChangeId')) {
      largestChangeId = _json['largestChangeId'] as core.String;
    }
    if (_json.containsKey('maxUploadSizes')) {
      maxUploadSizes = (_json['maxUploadSizes'] as core.List)
          .map<AboutMaxUploadSizes>((value) => AboutMaxUploadSizes.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permissionId')) {
      permissionId = _json['permissionId'] as core.String;
    }
    if (_json.containsKey('quotaBytesByService')) {
      quotaBytesByService = (_json['quotaBytesByService'] as core.List)
          .map<AboutQuotaBytesByService>((value) =>
              AboutQuotaBytesByService.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('quotaBytesTotal')) {
      quotaBytesTotal = _json['quotaBytesTotal'] as core.String;
    }
    if (_json.containsKey('quotaBytesUsed')) {
      quotaBytesUsed = _json['quotaBytesUsed'] as core.String;
    }
    if (_json.containsKey('quotaBytesUsedAggregate')) {
      quotaBytesUsedAggregate = _json['quotaBytesUsedAggregate'] as core.String;
    }
    if (_json.containsKey('quotaBytesUsedInTrash')) {
      quotaBytesUsedInTrash = _json['quotaBytesUsedInTrash'] as core.String;
    }
    if (_json.containsKey('quotaType')) {
      quotaType = _json['quotaType'] as core.String;
    }
    if (_json.containsKey('remainingChangeIds')) {
      remainingChangeIds = _json['remainingChangeIds'] as core.String;
    }
    if (_json.containsKey('rootFolderId')) {
      rootFolderId = _json['rootFolderId'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
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
        if (additionalRoleInfo != null)
          'additionalRoleInfo':
              additionalRoleInfo!.map((value) => value.toJson()).toList(),
        if (canCreateDrives != null) 'canCreateDrives': canCreateDrives!,
        if (canCreateTeamDrives != null)
          'canCreateTeamDrives': canCreateTeamDrives!,
        if (domainSharingPolicy != null)
          'domainSharingPolicy': domainSharingPolicy!,
        if (driveThemes != null)
          'driveThemes': driveThemes!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (exportFormats != null)
          'exportFormats':
              exportFormats!.map((value) => value.toJson()).toList(),
        if (features != null)
          'features': features!.map((value) => value.toJson()).toList(),
        if (folderColorPalette != null)
          'folderColorPalette': folderColorPalette!,
        if (importFormats != null)
          'importFormats':
              importFormats!.map((value) => value.toJson()).toList(),
        if (isCurrentAppInstalled != null)
          'isCurrentAppInstalled': isCurrentAppInstalled!,
        if (kind != null) 'kind': kind!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (largestChangeId != null) 'largestChangeId': largestChangeId!,
        if (maxUploadSizes != null)
          'maxUploadSizes':
              maxUploadSizes!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (permissionId != null) 'permissionId': permissionId!,
        if (quotaBytesByService != null)
          'quotaBytesByService':
              quotaBytesByService!.map((value) => value.toJson()).toList(),
        if (quotaBytesTotal != null) 'quotaBytesTotal': quotaBytesTotal!,
        if (quotaBytesUsed != null) 'quotaBytesUsed': quotaBytesUsed!,
        if (quotaBytesUsedAggregate != null)
          'quotaBytesUsedAggregate': quotaBytesUsedAggregate!,
        if (quotaBytesUsedInTrash != null)
          'quotaBytesUsedInTrash': quotaBytesUsedInTrash!,
        if (quotaType != null) 'quotaType': quotaType!,
        if (remainingChangeIds != null)
          'remainingChangeIds': remainingChangeIds!,
        if (rootFolderId != null) 'rootFolderId': rootFolderId!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (teamDriveThemes != null)
          'teamDriveThemes':
              teamDriveThemes!.map((value) => value.toJson()).toList(),
        if (user != null) 'user': user!.toJson(),
      };
}

class AppIcons {
  /// Category of the icon.
  ///
  /// Allowed values are:
  /// - application - icon for the application
  /// - document - icon for a file associated with the app
  /// - documentShared - icon for a shared file associated with the app
  core.String? category;

  /// URL for the icon.
  core.String? iconUrl;

  /// Size of the icon.
  ///
  /// Represented as the maximum of the width and height.
  core.int? size;

  AppIcons();

  AppIcons.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (size != null) 'size': size!,
      };
}

/// The apps resource provides a list of the apps that a user has installed,
/// with information about each app's supported MIME types, file extensions, and
/// other details.
class App {
  /// Whether the app is authorized to access data on the user's Drive.
  core.bool? authorized;

  /// The template url to create a new file with this app in a given folder.
  ///
  /// The template will contain {folderId} to be replaced by the folder to
  /// create the new file in.
  core.String? createInFolderTemplate;

  /// The url to create a new file with this app.
  core.String? createUrl;

  /// Whether the app has drive-wide scope.
  ///
  /// An app with drive-wide scope can access all files in the user's drive.
  core.bool? hasDriveWideScope;

  /// The various icons for the app.
  core.List<AppIcons>? icons;

  /// The ID of the app.
  core.String? id;

  /// Whether the app is installed.
  core.bool? installed;

  /// This is always drive#app.
  core.String? kind;

  /// A long description of the app.
  core.String? longDescription;

  /// The name of the app.
  core.String? name;

  /// The type of object this app creates (e.g. Chart).
  ///
  /// If empty, the app name should be used instead.
  core.String? objectType;

  /// The template url for opening files with this app.
  ///
  /// The template will contain {ids} and/or {exportIds} to be replaced by the
  /// actual file ids. See Open Files for the full documentation.
  core.String? openUrlTemplate;

  /// The list of primary file extensions.
  core.List<core.String>? primaryFileExtensions;

  /// The list of primary mime types.
  core.List<core.String>? primaryMimeTypes;

  /// The ID of the product listing for this app.
  core.String? productId;

  /// A link to the product listing for this app.
  core.String? productUrl;

  /// The list of secondary file extensions.
  core.List<core.String>? secondaryFileExtensions;

  /// The list of secondary mime types.
  core.List<core.String>? secondaryMimeTypes;

  /// A short description of the app.
  core.String? shortDescription;

  /// Whether this app supports creating new objects.
  core.bool? supportsCreate;

  /// Whether this app supports importing from Docs Editors.
  core.bool? supportsImport;

  /// Whether this app supports opening more than one file.
  core.bool? supportsMultiOpen;

  /// Whether this app supports creating new files when offline.
  core.bool? supportsOfflineCreate;

  /// Whether the app is selected as the default handler for the types it
  /// supports.
  core.bool? useByDefault;

  App();

  App.fromJson(core.Map _json) {
    if (_json.containsKey('authorized')) {
      authorized = _json['authorized'] as core.bool;
    }
    if (_json.containsKey('createInFolderTemplate')) {
      createInFolderTemplate = _json['createInFolderTemplate'] as core.String;
    }
    if (_json.containsKey('createUrl')) {
      createUrl = _json['createUrl'] as core.String;
    }
    if (_json.containsKey('hasDriveWideScope')) {
      hasDriveWideScope = _json['hasDriveWideScope'] as core.bool;
    }
    if (_json.containsKey('icons')) {
      icons = (_json['icons'] as core.List)
          .map<AppIcons>((value) =>
              AppIcons.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('installed')) {
      installed = _json['installed'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('longDescription')) {
      longDescription = _json['longDescription'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
    if (_json.containsKey('openUrlTemplate')) {
      openUrlTemplate = _json['openUrlTemplate'] as core.String;
    }
    if (_json.containsKey('primaryFileExtensions')) {
      primaryFileExtensions = (_json['primaryFileExtensions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('primaryMimeTypes')) {
      primaryMimeTypes = (_json['primaryMimeTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('productUrl')) {
      productUrl = _json['productUrl'] as core.String;
    }
    if (_json.containsKey('secondaryFileExtensions')) {
      secondaryFileExtensions = (_json['secondaryFileExtensions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('secondaryMimeTypes')) {
      secondaryMimeTypes = (_json['secondaryMimeTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('shortDescription')) {
      shortDescription = _json['shortDescription'] as core.String;
    }
    if (_json.containsKey('supportsCreate')) {
      supportsCreate = _json['supportsCreate'] as core.bool;
    }
    if (_json.containsKey('supportsImport')) {
      supportsImport = _json['supportsImport'] as core.bool;
    }
    if (_json.containsKey('supportsMultiOpen')) {
      supportsMultiOpen = _json['supportsMultiOpen'] as core.bool;
    }
    if (_json.containsKey('supportsOfflineCreate')) {
      supportsOfflineCreate = _json['supportsOfflineCreate'] as core.bool;
    }
    if (_json.containsKey('useByDefault')) {
      useByDefault = _json['useByDefault'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authorized != null) 'authorized': authorized!,
        if (createInFolderTemplate != null)
          'createInFolderTemplate': createInFolderTemplate!,
        if (createUrl != null) 'createUrl': createUrl!,
        if (hasDriveWideScope != null) 'hasDriveWideScope': hasDriveWideScope!,
        if (icons != null)
          'icons': icons!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (installed != null) 'installed': installed!,
        if (kind != null) 'kind': kind!,
        if (longDescription != null) 'longDescription': longDescription!,
        if (name != null) 'name': name!,
        if (objectType != null) 'objectType': objectType!,
        if (openUrlTemplate != null) 'openUrlTemplate': openUrlTemplate!,
        if (primaryFileExtensions != null)
          'primaryFileExtensions': primaryFileExtensions!,
        if (primaryMimeTypes != null) 'primaryMimeTypes': primaryMimeTypes!,
        if (productId != null) 'productId': productId!,
        if (productUrl != null) 'productUrl': productUrl!,
        if (secondaryFileExtensions != null)
          'secondaryFileExtensions': secondaryFileExtensions!,
        if (secondaryMimeTypes != null)
          'secondaryMimeTypes': secondaryMimeTypes!,
        if (shortDescription != null) 'shortDescription': shortDescription!,
        if (supportsCreate != null) 'supportsCreate': supportsCreate!,
        if (supportsImport != null) 'supportsImport': supportsImport!,
        if (supportsMultiOpen != null) 'supportsMultiOpen': supportsMultiOpen!,
        if (supportsOfflineCreate != null)
          'supportsOfflineCreate': supportsOfflineCreate!,
        if (useByDefault != null) 'useByDefault': useByDefault!,
      };
}

/// A list of third-party applications which the user has installed or given
/// access to Google Drive.
class AppList {
  /// List of app IDs that the user has specified to use by default.
  ///
  /// The list is in reverse-priority order (lowest to highest).
  core.List<core.String>? defaultAppIds;

  /// The ETag of the list.
  core.String? etag;

  /// The list of apps.
  core.List<App>? items;

  /// This is always drive#appList.
  core.String? kind;

  /// A link back to this list.
  core.String? selfLink;

  AppList();

  AppList.fromJson(core.Map _json) {
    if (_json.containsKey('defaultAppIds')) {
      defaultAppIds = (_json['defaultAppIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<App>((value) =>
              App.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultAppIds != null) 'defaultAppIds': defaultAppIds!,
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// Representation of a change to a file or shared drive.
class Change {
  /// The type of the change.
  ///
  /// Possible values are file and drive.
  core.String? changeType;

  /// Whether the file or shared drive has been removed from this list of
  /// changes, for example by deletion or loss of access.
  core.bool? deleted;

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

  /// The ID of the file associated with this change.
  core.String? fileId;

  /// The ID of the change.
  core.String? id;

  /// This is always drive#change.
  core.String? kind;

  /// The time of this modification.
  core.DateTime? modificationDate;

  /// A link back to this change.
  core.String? selfLink;

  /// Deprecated - use drive instead.
  TeamDrive? teamDrive;

  /// Deprecated - use driveId instead.
  core.String? teamDriveId;

  /// Deprecated - use changeType instead.
  core.String? type;

  Change();

  Change.fromJson(core.Map _json) {
    if (_json.containsKey('changeType')) {
      changeType = _json['changeType'] as core.String;
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
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
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('modificationDate')) {
      modificationDate =
          core.DateTime.parse(_json['modificationDate'] as core.String);
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('teamDrive')) {
      teamDrive = TeamDrive.fromJson(
          _json['teamDrive'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('teamDriveId')) {
      teamDriveId = _json['teamDriveId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (changeType != null) 'changeType': changeType!,
        if (deleted != null) 'deleted': deleted!,
        if (drive != null) 'drive': drive!.toJson(),
        if (driveId != null) 'driveId': driveId!,
        if (file != null) 'file': file!.toJson(),
        if (fileId != null) 'fileId': fileId!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (modificationDate != null)
          'modificationDate': modificationDate!.toIso8601String(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (teamDrive != null) 'teamDrive': teamDrive!.toJson(),
        if (teamDriveId != null) 'teamDriveId': teamDriveId!,
        if (type != null) 'type': type!,
      };
}

/// A list of changes for a user.
class ChangeList {
  /// The ETag of the list.
  core.String? etag;

  /// The list of changes.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Change>? items;

  /// This is always drive#changeList.
  core.String? kind;

  /// The current largest change ID.
  core.String? largestChangeId;

  /// The starting page token for future changes.
  ///
  /// This will be present only if the end of the current changes list has been
  /// reached.
  core.String? newStartPageToken;

  /// A link to the next page of changes.
  core.String? nextLink;

  /// The page token for the next page of changes.
  ///
  /// This will be absent if the end of the changes list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// A link back to this list.
  core.String? selfLink;

  ChangeList();

  ChangeList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Change>((value) =>
              Change.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('largestChangeId')) {
      largestChangeId = _json['largestChangeId'] as core.String;
    }
    if (_json.containsKey('newStartPageToken')) {
      newStartPageToken = _json['newStartPageToken'] as core.String;
    }
    if (_json.containsKey('nextLink')) {
      nextLink = _json['nextLink'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (largestChangeId != null) 'largestChangeId': largestChangeId!,
        if (newStartPageToken != null) 'newStartPageToken': newStartPageToken!,
        if (nextLink != null) 'nextLink': nextLink!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (selfLink != null) 'selfLink': selfLink!,
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

/// A list of children of a file.
class ChildList {
  /// The ETag of the list.
  core.String? etag;

  /// The list of children.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<ChildReference>? items;

  /// This is always drive#childList.
  core.String? kind;

  /// A link to the next page of children.
  core.String? nextLink;

  /// The page token for the next page of children.
  ///
  /// This will be absent if the end of the children list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// A link back to this list.
  core.String? selfLink;

  ChildList();

  ChildList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<ChildReference>((value) => ChildReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextLink')) {
      nextLink = _json['nextLink'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextLink != null) 'nextLink': nextLink!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A reference to a folder's child.
class ChildReference {
  /// A link to the child.
  core.String? childLink;

  /// The ID of the child.
  core.String? id;

  /// This is always drive#childReference.
  core.String? kind;

  /// A link back to this reference.
  core.String? selfLink;

  ChildReference();

  ChildReference.fromJson(core.Map _json) {
    if (_json.containsKey('childLink')) {
      childLink = _json['childLink'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (childLink != null) 'childLink': childLink!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// The context of the file which is being commented on.
class CommentContext {
  /// The MIME type of the context snippet.
  core.String? type;

  /// Data representation of the segment of the file being commented on.
  ///
  /// In the case of a text file for example, this would be the actual text that
  /// the comment is about.
  core.String? value;

  CommentContext();

  CommentContext.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// A comment on a file in Google Drive.
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

  /// The ID of the comment.
  core.String? commentId;

  /// The plain text content used to create this comment.
  ///
  /// This is not HTML safe and should only be used as a starting point to make
  /// edits to a comment's content.
  core.String? content;

  /// The context of the file which is being commented on.
  CommentContext? context;

  /// The date when this comment was first created.
  core.DateTime? createdDate;

  /// Whether this comment has been deleted.
  ///
  /// If a comment has been deleted the content will be cleared and this will
  /// only represent a comment that once existed.
  core.bool? deleted;

  /// The file which this comment is addressing.
  core.String? fileId;

  /// The title of the file which this comment is addressing.
  core.String? fileTitle;

  /// HTML formatted content for this comment.
  core.String? htmlContent;

  /// This is always drive#comment.
  core.String? kind;

  /// The date when this comment or any of its replies were last modified.
  core.DateTime? modifiedDate;

  /// Replies to this post.
  core.List<CommentReply>? replies;

  /// A link back to this comment.
  core.String? selfLink;

  /// The status of this comment.
  ///
  /// Status can be changed by posting a reply to a comment with the desired
  /// status.
  /// - "open" - The comment is still open.
  /// - "resolved" - The comment has been resolved by one of its replies.
  core.String? status;

  Comment();

  Comment.fromJson(core.Map _json) {
    if (_json.containsKey('anchor')) {
      anchor = _json['anchor'] as core.String;
    }
    if (_json.containsKey('author')) {
      author =
          User.fromJson(_json['author'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('commentId')) {
      commentId = _json['commentId'] as core.String;
    }
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('context')) {
      context = CommentContext.fromJson(
          _json['context'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createdDate')) {
      createdDate = core.DateTime.parse(_json['createdDate'] as core.String);
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('fileId')) {
      fileId = _json['fileId'] as core.String;
    }
    if (_json.containsKey('fileTitle')) {
      fileTitle = _json['fileTitle'] as core.String;
    }
    if (_json.containsKey('htmlContent')) {
      htmlContent = _json['htmlContent'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('modifiedDate')) {
      modifiedDate = core.DateTime.parse(_json['modifiedDate'] as core.String);
    }
    if (_json.containsKey('replies')) {
      replies = (_json['replies'] as core.List)
          .map<CommentReply>((value) => CommentReply.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (anchor != null) 'anchor': anchor!,
        if (author != null) 'author': author!.toJson(),
        if (commentId != null) 'commentId': commentId!,
        if (content != null) 'content': content!,
        if (context != null) 'context': context!.toJson(),
        if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
        if (deleted != null) 'deleted': deleted!,
        if (fileId != null) 'fileId': fileId!,
        if (fileTitle != null) 'fileTitle': fileTitle!,
        if (htmlContent != null) 'htmlContent': htmlContent!,
        if (kind != null) 'kind': kind!,
        if (modifiedDate != null)
          'modifiedDate': modifiedDate!.toIso8601String(),
        if (replies != null)
          'replies': replies!.map((value) => value.toJson()).toList(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (status != null) 'status': status!,
      };
}

/// A list of comments on a file in Google Drive.
class CommentList {
  /// The list of comments.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Comment>? items;

  /// This is always drive#commentList.
  core.String? kind;

  /// A link to the next page of comments.
  core.String? nextLink;

  /// The page token for the next page of comments.
  ///
  /// This will be absent if the end of the comments list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// A link back to this list.
  core.String? selfLink;

  CommentList();

  CommentList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Comment>((value) =>
              Comment.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextLink')) {
      nextLink = _json['nextLink'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextLink != null) 'nextLink': nextLink!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A comment on a file in Google Drive.
class CommentReply {
  /// The author of the reply.
  ///
  /// The author's email address and permission ID will not be populated.
  User? author;

  /// The plain text content used to create this reply.
  ///
  /// This is not HTML safe and should only be used as a starting point to make
  /// edits to a reply's content. This field is required on inserts if no verb
  /// is specified (resolve/reopen).
  core.String? content;

  /// The date when this reply was first created.
  core.DateTime? createdDate;

  /// Whether this reply has been deleted.
  ///
  /// If a reply has been deleted the content will be cleared and this will only
  /// represent a reply that once existed.
  core.bool? deleted;

  /// HTML formatted content for this reply.
  core.String? htmlContent;

  /// This is always drive#commentReply.
  core.String? kind;

  /// The date when this reply was last modified.
  core.DateTime? modifiedDate;

  /// The ID of the reply.
  core.String? replyId;

  /// The action this reply performed to the parent comment.
  ///
  /// When creating a new reply this is the action to be perform to the parent
  /// comment. Possible values are:
  /// - "resolve" - To resolve a comment.
  /// - "reopen" - To reopen (un-resolve) a comment.
  core.String? verb;

  CommentReply();

  CommentReply.fromJson(core.Map _json) {
    if (_json.containsKey('author')) {
      author =
          User.fromJson(_json['author'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('createdDate')) {
      createdDate = core.DateTime.parse(_json['createdDate'] as core.String);
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('htmlContent')) {
      htmlContent = _json['htmlContent'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('modifiedDate')) {
      modifiedDate = core.DateTime.parse(_json['modifiedDate'] as core.String);
    }
    if (_json.containsKey('replyId')) {
      replyId = _json['replyId'] as core.String;
    }
    if (_json.containsKey('verb')) {
      verb = _json['verb'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (author != null) 'author': author!.toJson(),
        if (content != null) 'content': content!,
        if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
        if (deleted != null) 'deleted': deleted!,
        if (htmlContent != null) 'htmlContent': htmlContent!,
        if (kind != null) 'kind': kind!,
        if (modifiedDate != null)
          'modifiedDate': modifiedDate!.toIso8601String(),
        if (replyId != null) 'replyId': replyId!,
        if (verb != null) 'verb': verb!,
      };
}

/// A list of replies to a comment on a file in Google Drive.
class CommentReplyList {
  /// The list of replies.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<CommentReply>? items;

  /// This is always drive#commentReplyList.
  core.String? kind;

  /// A link to the next page of replies.
  core.String? nextLink;

  /// The page token for the next page of replies.
  ///
  /// This will be absent if the end of the replies list has been reached. If
  /// the token is rejected for any reason, it should be discarded, and
  /// pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// A link back to this list.
  core.String? selfLink;

  CommentReplyList();

  CommentReplyList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<CommentReply>((value) => CommentReply.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextLink')) {
      nextLink = _json['nextLink'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextLink != null) 'nextLink': nextLink!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (selfLink != null) 'selfLink': selfLink!,
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
  core.DateTime? restrictionDate;

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
    if (_json.containsKey('restrictionDate')) {
      restrictionDate =
          core.DateTime.parse(_json['restrictionDate'] as core.String);
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
        if (restrictionDate != null)
          'restrictionDate': restrictionDate!.toIso8601String(),
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
  core.DateTime? createdDate;

  /// Whether the shared drive is hidden from default view.
  core.bool? hidden;

  /// The ID of this shared drive which is also the ID of the top level folder
  /// of this shared drive.
  core.String? id;

  /// This is always drive#drive
  core.String? kind;

  /// The name of this shared drive.
  core.String? name;

  /// A set of restrictions that apply to this shared drive or items inside this
  /// shared drive.
  DriveRestrictions? restrictions;

  /// The ID of the theme from which the background image and color will be set.
  ///
  /// The set of possible driveThemes can be retrieved from a drive.about.get
  /// response. When not specified on a drive.drives.insert request, a random
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
    if (_json.containsKey('createdDate')) {
      createdDate = core.DateTime.parse(_json['createdDate'] as core.String);
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
        if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
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
  core.List<Drive>? items;

  /// This is always drive#driveList
  core.String? kind;

  /// The page token for the next page of shared drives.
  ///
  /// This will be absent if the end of the list has been reached. If the token
  /// is rejected for any reason, it should be discarded, and pagination should
  /// be restarted from the first page of results.
  core.String? nextPageToken;

  DriveList();

  DriveList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
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
  core.bool? canChangeRestrictedDownload;

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
    if (_json.containsKey('canChangeRestrictedDownload')) {
      canChangeRestrictedDownload =
          _json['canChangeRestrictedDownload'] as core.bool;
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
        if (canChangeRestrictedDownload != null)
          'canChangeRestrictedDownload': canChangeRestrictedDownload!,
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

/// Metadata about image media.
///
/// This will only be present for image types, and its contents will depend on
/// what can be parsed from the image content.
class FileImageMediaMetadata {
  /// The aperture used to create the photo (f-number).
  core.double? aperture;

  /// The make of the camera used to create the photo.
  core.String? cameraMake;

  /// The model of the camera used to create the photo.
  core.String? cameraModel;

  /// The color space of the photo.
  core.String? colorSpace;

  /// The date and time the photo was taken (EXIF format timestamp).
  core.String? date;

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
    if (_json.containsKey('date')) {
      date = _json['date'] as core.String;
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
        if (date != null) 'date': date!,
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
        if (whiteBalance != null) 'whiteBalance': whiteBalance!,
        if (width != null) 'width': width!,
      };
}

/// Indexable text attributes for the file (can only be written)
class FileIndexableText {
  /// The text to be indexed for this file.
  core.String? text;

  FileIndexableText();

  FileIndexableText.fromJson(core.Map _json) {
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// A group of labels for the file.
class FileLabels {
  /// Deprecated.
  core.bool? hidden;

  /// Whether the file has been modified by this user.
  core.bool? modified;

  /// Deprecated - use copyRequiresWriterPermission instead.
  core.bool? restricted;

  /// Whether this file is starred by the user.
  core.bool? starred;

  /// Whether the file has been trashed, either explicitly or from a trashed
  /// parent folder.
  ///
  /// Only the owner may trash a file. The trashed item is excluded from all
  /// files.list responses returned for any user who does not own the file.
  /// However, all users with access to the file can see the trashed item
  /// metadata in an API response. All users with access can copy, download,
  /// export, and share the file.
  core.bool? trashed;

  /// Whether this file has been viewed by this user.
  core.bool? viewed;

  FileLabels();

  FileLabels.fromJson(core.Map _json) {
    if (_json.containsKey('hidden')) {
      hidden = _json['hidden'] as core.bool;
    }
    if (_json.containsKey('modified')) {
      modified = _json['modified'] as core.bool;
    }
    if (_json.containsKey('restricted')) {
      restricted = _json['restricted'] as core.bool;
    }
    if (_json.containsKey('starred')) {
      starred = _json['starred'] as core.bool;
    }
    if (_json.containsKey('trashed')) {
      trashed = _json['trashed'] as core.bool;
    }
    if (_json.containsKey('viewed')) {
      viewed = _json['viewed'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hidden != null) 'hidden': hidden!,
        if (modified != null) 'modified': modified!,
        if (restricted != null) 'restricted': restricted!,
        if (starred != null) 'starred': starred!,
        if (trashed != null) 'trashed': trashed!,
        if (viewed != null) 'viewed': viewed!,
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

/// A thumbnail for the file.
///
/// This will only be used if a standard thumbnail cannot be generated.
class FileThumbnail {
  /// The URL-safe Base64 encoded bytes of the thumbnail image.
  ///
  /// It should conform to RFC 4648 section 5.
  core.String? image;
  core.List<core.int> get imageAsBytes => convert_1.base64.decode(image!);

  set imageAsBytes(core.List<core.int> _bytes) {
    image = convert_1.base64
        .encode(_bytes)
        .replaceAll('/', '_')
        .replaceAll('+', '-');
  }

  /// The MIME type of the thumbnail.
  core.String? mimeType;

  FileThumbnail();

  FileThumbnail.fromJson(core.Map _json) {
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

/// Metadata about video media.
///
/// This will only be present for video types.
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
  /// A link for opening the file in a relevant Google editor or viewer.
  core.String? alternateLink;

  /// Whether this file is in the Application Data folder.
  core.bool? appDataContents;

  /// Deprecated: use capabilities/canComment.
  core.bool? canComment;

  /// Deprecated: use capabilities/canReadRevisions.
  core.bool? canReadRevisions;

  /// Capabilities the current user has on this file.
  ///
  /// Each capability corresponds to a fine-grained action that a user may take.
  FileCapabilities? capabilities;

  /// Restrictions for accessing the content of the file.
  ///
  /// Only populated if such a restriction exists.
  core.List<ContentRestriction>? contentRestrictions;

  /// Whether the options to copy, print, or download this file, should be
  /// disabled for readers and commenters.
  core.bool? copyRequiresWriterPermission;

  /// Deprecated: use capabilities/canCopy.
  core.bool? copyable;

  /// Create time for this file (formatted RFC 3339 timestamp).
  core.DateTime? createdDate;

  /// A link to open this file with the user's default app for this file.
  ///
  /// Only populated when the drive.apps.readonly scope is used.
  core.String? defaultOpenWithLink;

  /// A short description of the file.
  core.String? description;

  /// Short lived download URL for the file.
  ///
  /// This field is only populated for files with content stored in Google
  /// Drive; it is not populated for Docs Editors or shortcut files.
  core.String? downloadUrl;

  /// ID of the shared drive the file resides in.
  ///
  /// Only populated for items in shared drives.
  core.String? driveId;

  /// Deprecated: use capabilities/canEdit.
  core.bool? editable;

  /// A link for embedding the file.
  core.String? embedLink;

  /// ETag of the file.
  core.String? etag;

  /// Whether this file has been explicitly trashed, as opposed to recursively
  /// trashed.
  core.bool? explicitlyTrashed;

  /// Links for exporting Docs Editors files to specific formats.
  core.Map<core.String, core.String>? exportLinks;

  /// The final component of fullFileExtension with trailing text that does not
  /// appear to be part of the extension removed.
  ///
  /// This field is only populated for files with content stored in Google
  /// Drive; it is not populated for Docs Editors or shortcut files.
  core.String? fileExtension;

  /// The size of the file in bytes.
  ///
  /// This field is populated for files with content stored in Google Drive and
  /// for files in Docs Editors; it is not populated for shortcut files.
  core.String? fileSize;

  /// Folder color as an RGB hex string if the file is a folder.
  ///
  /// The list of supported colors is available in the folderColorPalette field
  /// of the About resource. If an unsupported color is specified, it will be
  /// changed to the closest color in the palette. Not populated for items in
  /// shared drives.
  core.String? folderColorRgb;

  /// The full file extension; extracted from the title.
  ///
  /// May contain multiple concatenated extensions, such as "tar.gz". Removing
  /// an extension from the title does not clear this field; however, changing
  /// the extension on the title does update this field. This field is only
  /// populated for files with content stored in Google Drive; it is not
  /// populated for Docs Editors or shortcut files.
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
  /// This field is only populated for files with content stored in Google
  /// Drive; it is not populated for Docs Editors or shortcut files.
  core.String? headRevisionId;

  /// A link to the file's icon.
  core.String? iconLink;

  /// The ID of the file.
  core.String? id;

  /// Metadata about image media.
  ///
  /// This will only be present for image types, and its contents will depend on
  /// what can be parsed from the image content.
  FileImageMediaMetadata? imageMediaMetadata;

  /// Indexable text attributes for the file (can only be written)
  FileIndexableText? indexableText;

  /// Whether the file was created or opened by the requesting app.
  core.bool? isAppAuthorized;

  /// The type of file.
  ///
  /// This is always drive#file.
  core.String? kind;

  /// A group of labels for the file.
  FileLabels? labels;

  /// The last user to modify this file.
  User? lastModifyingUser;

  /// Name of the last user to modify this file.
  core.String? lastModifyingUserName;

  /// Last time this file was viewed by the user (formatted RFC 3339 timestamp).
  core.DateTime? lastViewedByMeDate;

  /// Deprecated.
  core.DateTime? markedViewedByMeDate;

  /// An MD5 checksum for the content of this file.
  ///
  /// This field is only populated for files with content stored in Google
  /// Drive; it is not populated for Docs Editors or shortcut files.
  core.String? md5Checksum;

  /// The MIME type of the file.
  ///
  /// This is only mutable on update when uploading new content. This field can
  /// be left blank, and the mimetype will be determined from the uploaded
  /// content's MIME type.
  core.String? mimeType;

  /// Last time this file was modified by the user (formatted RFC 3339
  /// timestamp).
  ///
  /// Note that setting modifiedDate will also update the modifiedByMe date for
  /// the user which set the date.
  core.DateTime? modifiedByMeDate;

  /// Last time this file was modified by anyone (formatted RFC 3339 timestamp).
  ///
  /// This is only mutable on update when the setModifiedDate parameter is set.
  core.DateTime? modifiedDate;

  /// A map of the id of each of the user's apps to a link to open this file
  /// with that app.
  ///
  /// Only populated when the drive.apps.readonly scope is used.
  core.Map<core.String, core.String>? openWithLinks;

  /// The original filename of the uploaded content if available, or else the
  /// original value of the title field.
  ///
  /// This is only available for files with binary content in Google Drive.
  core.String? originalFilename;

  /// Whether the file is owned by the current user.
  ///
  /// Not populated for items in shared drives.
  core.bool? ownedByMe;

  /// Name(s) of the owner(s) of this file.
  ///
  /// Not populated for items in shared drives.
  core.List<core.String>? ownerNames;

  /// The owner(s) of this file.
  ///
  /// Not populated for items in shared drives.
  core.List<User>? owners;

  /// Collection of parent folders which contain this file.
  /// If not specified as part of an insert request, the file will be placed
  /// directly in the user's My Drive folder.
  ///
  /// If not specified as part of a copy request, the file will inherit any
  /// discoverable parents of the source file. Update requests can also use the
  /// addParents and removeParents parameters to modify the parents list.
  core.List<ParentReference>? parents;

  /// List of permission IDs for users with access to this file.
  core.List<core.String>? permissionIds;

  /// The list of permissions for users with access to this file.
  ///
  /// Not populated for items in shared drives.
  core.List<Permission>? permissions;

  /// The list of properties.
  core.List<Property>? properties;

  /// The number of quota bytes used by this file.
  core.String? quotaBytesUsed;

  /// A link back to this file.
  core.String? selfLink;

  /// Deprecated: use capabilities/canShare.
  core.bool? shareable;

  /// Whether the file has been shared.
  ///
  /// Not populated for items in shared drives.
  core.bool? shared;

  /// Time at which this file was shared with the user (formatted RFC 3339
  /// timestamp).
  core.DateTime? sharedWithMeDate;

  /// User that shared the item with the current user, if available.
  User? sharingUser;

  /// Shortcut file details.
  ///
  /// Only populated for shortcut files, which have the mimeType field set to
  /// application/vnd.google-apps.shortcut.
  FileShortcutDetails? shortcutDetails;

  /// The list of spaces which contain the file.
  ///
  /// Supported values are 'drive', 'appDataFolder' and 'photos'.
  core.List<core.String>? spaces;

  /// Deprecated - use driveId instead.
  core.String? teamDriveId;

  /// A thumbnail for the file.
  ///
  /// This will only be used if a standard thumbnail cannot be generated.
  FileThumbnail? thumbnail;

  /// A short-lived link to the file's thumbnail.
  ///
  /// Typically lasts on the order of hours. Only populated when the requesting
  /// app can access the file's content. If the file isn't shared publicly, the
  /// URL returned in Files.thumbnailLink must be fetched using a credentialed
  /// request.
  core.String? thumbnailLink;

  /// The thumbnail version for use in thumbnail cache invalidation.
  core.String? thumbnailVersion;

  /// The title of this file.
  ///
  /// Note that for immutable items such as the top level folders of shared
  /// drives, My Drive root folder, and Application Data folder the title is
  /// constant.
  core.String? title;

  /// The time that the item was trashed (formatted RFC 3339 timestamp).
  ///
  /// Only populated for items in shared drives.
  core.DateTime? trashedDate;

  /// If the file has been explicitly trashed, the user who trashed it.
  ///
  /// Only populated for items in shared drives.
  User? trashingUser;

  /// The permissions for the authenticated user on this file.
  Permission? userPermission;

  /// A monotonically increasing version number for the file.
  ///
  /// This reflects every change made to the file on the server, even those not
  /// visible to the requesting user.
  core.String? version;

  /// Metadata about video media.
  ///
  /// This will only be present for video types.
  FileVideoMediaMetadata? videoMediaMetadata;

  /// A link for downloading the content of the file in a browser using cookie
  /// based authentication.
  ///
  /// In cases where the content is shared publicly, the content can be
  /// downloaded without any credentials.
  core.String? webContentLink;

  /// A link only available on public folders for viewing their static web
  /// assets (HTML, CSS, JS, etc) via Google Drive's Website Hosting.
  core.String? webViewLink;

  /// Whether writers can share the document with other users.
  ///
  /// Not populated for items in shared drives.
  core.bool? writersCanShare;

  File();

  File.fromJson(core.Map _json) {
    if (_json.containsKey('alternateLink')) {
      alternateLink = _json['alternateLink'] as core.String;
    }
    if (_json.containsKey('appDataContents')) {
      appDataContents = _json['appDataContents'] as core.bool;
    }
    if (_json.containsKey('canComment')) {
      canComment = _json['canComment'] as core.bool;
    }
    if (_json.containsKey('canReadRevisions')) {
      canReadRevisions = _json['canReadRevisions'] as core.bool;
    }
    if (_json.containsKey('capabilities')) {
      capabilities = FileCapabilities.fromJson(
          _json['capabilities'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('copyable')) {
      copyable = _json['copyable'] as core.bool;
    }
    if (_json.containsKey('createdDate')) {
      createdDate = core.DateTime.parse(_json['createdDate'] as core.String);
    }
    if (_json.containsKey('defaultOpenWithLink')) {
      defaultOpenWithLink = _json['defaultOpenWithLink'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('downloadUrl')) {
      downloadUrl = _json['downloadUrl'] as core.String;
    }
    if (_json.containsKey('driveId')) {
      driveId = _json['driveId'] as core.String;
    }
    if (_json.containsKey('editable')) {
      editable = _json['editable'] as core.bool;
    }
    if (_json.containsKey('embedLink')) {
      embedLink = _json['embedLink'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
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
    if (_json.containsKey('fileSize')) {
      fileSize = _json['fileSize'] as core.String;
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
    if (_json.containsKey('indexableText')) {
      indexableText = FileIndexableText.fromJson(
          _json['indexableText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isAppAuthorized')) {
      isAppAuthorized = _json['isAppAuthorized'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = FileLabels.fromJson(
          _json['labels'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lastModifyingUser')) {
      lastModifyingUser = User.fromJson(
          _json['lastModifyingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lastModifyingUserName')) {
      lastModifyingUserName = _json['lastModifyingUserName'] as core.String;
    }
    if (_json.containsKey('lastViewedByMeDate')) {
      lastViewedByMeDate =
          core.DateTime.parse(_json['lastViewedByMeDate'] as core.String);
    }
    if (_json.containsKey('markedViewedByMeDate')) {
      markedViewedByMeDate =
          core.DateTime.parse(_json['markedViewedByMeDate'] as core.String);
    }
    if (_json.containsKey('md5Checksum')) {
      md5Checksum = _json['md5Checksum'] as core.String;
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('modifiedByMeDate')) {
      modifiedByMeDate =
          core.DateTime.parse(_json['modifiedByMeDate'] as core.String);
    }
    if (_json.containsKey('modifiedDate')) {
      modifiedDate = core.DateTime.parse(_json['modifiedDate'] as core.String);
    }
    if (_json.containsKey('openWithLinks')) {
      openWithLinks =
          (_json['openWithLinks'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('originalFilename')) {
      originalFilename = _json['originalFilename'] as core.String;
    }
    if (_json.containsKey('ownedByMe')) {
      ownedByMe = _json['ownedByMe'] as core.bool;
    }
    if (_json.containsKey('ownerNames')) {
      ownerNames = (_json['ownerNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('owners')) {
      owners = (_json['owners'] as core.List)
          .map<User>((value) =>
              User.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parents')) {
      parents = (_json['parents'] as core.List)
          .map<ParentReference>((value) => ParentReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
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
      properties = (_json['properties'] as core.List)
          .map<Property>((value) =>
              Property.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('quotaBytesUsed')) {
      quotaBytesUsed = _json['quotaBytesUsed'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('shareable')) {
      shareable = _json['shareable'] as core.bool;
    }
    if (_json.containsKey('shared')) {
      shared = _json['shared'] as core.bool;
    }
    if (_json.containsKey('sharedWithMeDate')) {
      sharedWithMeDate =
          core.DateTime.parse(_json['sharedWithMeDate'] as core.String);
    }
    if (_json.containsKey('sharingUser')) {
      sharingUser = User.fromJson(
          _json['sharingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shortcutDetails')) {
      shortcutDetails = FileShortcutDetails.fromJson(
          _json['shortcutDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spaces')) {
      spaces = (_json['spaces'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('teamDriveId')) {
      teamDriveId = _json['teamDriveId'] as core.String;
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = FileThumbnail.fromJson(
          _json['thumbnail'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('thumbnailLink')) {
      thumbnailLink = _json['thumbnailLink'] as core.String;
    }
    if (_json.containsKey('thumbnailVersion')) {
      thumbnailVersion = _json['thumbnailVersion'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('trashedDate')) {
      trashedDate = core.DateTime.parse(_json['trashedDate'] as core.String);
    }
    if (_json.containsKey('trashingUser')) {
      trashingUser = User.fromJson(
          _json['trashingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userPermission')) {
      userPermission = Permission.fromJson(
          _json['userPermission'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
    if (_json.containsKey('videoMediaMetadata')) {
      videoMediaMetadata = FileVideoMediaMetadata.fromJson(
          _json['videoMediaMetadata'] as core.Map<core.String, core.dynamic>);
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
        if (alternateLink != null) 'alternateLink': alternateLink!,
        if (appDataContents != null) 'appDataContents': appDataContents!,
        if (canComment != null) 'canComment': canComment!,
        if (canReadRevisions != null) 'canReadRevisions': canReadRevisions!,
        if (capabilities != null) 'capabilities': capabilities!.toJson(),
        if (contentRestrictions != null)
          'contentRestrictions':
              contentRestrictions!.map((value) => value.toJson()).toList(),
        if (copyRequiresWriterPermission != null)
          'copyRequiresWriterPermission': copyRequiresWriterPermission!,
        if (copyable != null) 'copyable': copyable!,
        if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
        if (defaultOpenWithLink != null)
          'defaultOpenWithLink': defaultOpenWithLink!,
        if (description != null) 'description': description!,
        if (downloadUrl != null) 'downloadUrl': downloadUrl!,
        if (driveId != null) 'driveId': driveId!,
        if (editable != null) 'editable': editable!,
        if (embedLink != null) 'embedLink': embedLink!,
        if (etag != null) 'etag': etag!,
        if (explicitlyTrashed != null) 'explicitlyTrashed': explicitlyTrashed!,
        if (exportLinks != null) 'exportLinks': exportLinks!,
        if (fileExtension != null) 'fileExtension': fileExtension!,
        if (fileSize != null) 'fileSize': fileSize!,
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
        if (indexableText != null) 'indexableText': indexableText!.toJson(),
        if (isAppAuthorized != null) 'isAppAuthorized': isAppAuthorized!,
        if (kind != null) 'kind': kind!,
        if (labels != null) 'labels': labels!.toJson(),
        if (lastModifyingUser != null)
          'lastModifyingUser': lastModifyingUser!.toJson(),
        if (lastModifyingUserName != null)
          'lastModifyingUserName': lastModifyingUserName!,
        if (lastViewedByMeDate != null)
          'lastViewedByMeDate': lastViewedByMeDate!.toIso8601String(),
        if (markedViewedByMeDate != null)
          'markedViewedByMeDate': markedViewedByMeDate!.toIso8601String(),
        if (md5Checksum != null) 'md5Checksum': md5Checksum!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (modifiedByMeDate != null)
          'modifiedByMeDate': modifiedByMeDate!.toIso8601String(),
        if (modifiedDate != null)
          'modifiedDate': modifiedDate!.toIso8601String(),
        if (openWithLinks != null) 'openWithLinks': openWithLinks!,
        if (originalFilename != null) 'originalFilename': originalFilename!,
        if (ownedByMe != null) 'ownedByMe': ownedByMe!,
        if (ownerNames != null) 'ownerNames': ownerNames!,
        if (owners != null)
          'owners': owners!.map((value) => value.toJson()).toList(),
        if (parents != null)
          'parents': parents!.map((value) => value.toJson()).toList(),
        if (permissionIds != null) 'permissionIds': permissionIds!,
        if (permissions != null)
          'permissions': permissions!.map((value) => value.toJson()).toList(),
        if (properties != null)
          'properties': properties!.map((value) => value.toJson()).toList(),
        if (quotaBytesUsed != null) 'quotaBytesUsed': quotaBytesUsed!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (shareable != null) 'shareable': shareable!,
        if (shared != null) 'shared': shared!,
        if (sharedWithMeDate != null)
          'sharedWithMeDate': sharedWithMeDate!.toIso8601String(),
        if (sharingUser != null) 'sharingUser': sharingUser!.toJson(),
        if (shortcutDetails != null)
          'shortcutDetails': shortcutDetails!.toJson(),
        if (spaces != null) 'spaces': spaces!,
        if (teamDriveId != null) 'teamDriveId': teamDriveId!,
        if (thumbnail != null) 'thumbnail': thumbnail!.toJson(),
        if (thumbnailLink != null) 'thumbnailLink': thumbnailLink!,
        if (thumbnailVersion != null) 'thumbnailVersion': thumbnailVersion!,
        if (title != null) 'title': title!,
        if (trashedDate != null) 'trashedDate': trashedDate!.toIso8601String(),
        if (trashingUser != null) 'trashingUser': trashingUser!.toJson(),
        if (userPermission != null) 'userPermission': userPermission!.toJson(),
        if (version != null) 'version': version!,
        if (videoMediaMetadata != null)
          'videoMediaMetadata': videoMediaMetadata!.toJson(),
        if (webContentLink != null) 'webContentLink': webContentLink!,
        if (webViewLink != null) 'webViewLink': webViewLink!,
        if (writersCanShare != null) 'writersCanShare': writersCanShare!,
      };
}

/// A list of files.
class FileList {
  /// The ETag of the list.
  core.String? etag;

  /// Whether the search process was incomplete.
  ///
  /// If true, then some search results may be missing, since all documents were
  /// not searched. This may occur when searching multiple drives with the
  /// "allDrives" corpora, but all corpora could not be searched. When this
  /// happens, it is suggested that clients narrow their query by choosing a
  /// different corpus such as "default" or "drive".
  core.bool? incompleteSearch;

  /// The list of files.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<File>? items;

  /// This is always drive#fileList.
  core.String? kind;

  /// A link to the next page of files.
  core.String? nextLink;

  /// The page token for the next page of files.
  ///
  /// This will be absent if the end of the files list has been reached. If the
  /// token is rejected for any reason, it should be discarded, and pagination
  /// should be restarted from the first page of results.
  core.String? nextPageToken;

  /// A link back to this list.
  core.String? selfLink;

  FileList();

  FileList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('incompleteSearch')) {
      incompleteSearch = _json['incompleteSearch'] as core.bool;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<File>((value) =>
              File.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextLink')) {
      nextLink = _json['nextLink'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (incompleteSearch != null) 'incompleteSearch': incompleteSearch!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextLink != null) 'nextLink': nextLink!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A list of generated IDs which can be provided in insert requests
class GeneratedIds {
  /// The IDs generated for the requesting user in the specified space.
  core.List<core.String>? ids;

  /// This is always drive#generatedIds
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

/// A list of a file's parents.
class ParentList {
  /// The ETag of the list.
  core.String? etag;

  /// The list of parents.
  core.List<ParentReference>? items;

  /// This is always drive#parentList.
  core.String? kind;

  /// A link back to this list.
  core.String? selfLink;

  ParentList();

  ParentList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<ParentReference>((value) => ParentReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A reference to a file's parent.
class ParentReference {
  /// The ID of the parent.
  core.String? id;

  /// Whether or not the parent is the root folder.
  core.bool? isRoot;

  /// This is always drive#parentReference.
  core.String? kind;

  /// A link to the parent.
  core.String? parentLink;

  /// A link back to this reference.
  core.String? selfLink;

  ParentReference();

  ParentReference.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('isRoot')) {
      isRoot = _json['isRoot'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('parentLink')) {
      parentLink = _json['parentLink'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (isRoot != null) 'isRoot': isRoot!,
        if (kind != null) 'kind': kind!,
        if (parentLink != null) 'parentLink': parentLink!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

class PermissionPermissionDetails {
  /// Additional roles for this user.
  ///
  /// Only commenter is currently possible, though more may be supported in the
  /// future.
  core.List<core.String>? additionalRoles;

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
  /// - reader
  core.String? role;

  PermissionPermissionDetails();

  PermissionPermissionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('additionalRoles')) {
      additionalRoles = (_json['additionalRoles'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
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
        if (additionalRoles != null) 'additionalRoles': additionalRoles!,
        if (inherited != null) 'inherited': inherited!,
        if (inheritedFrom != null) 'inheritedFrom': inheritedFrom!,
        if (permissionType != null) 'permissionType': permissionType!,
        if (role != null) 'role': role!,
      };
}

class PermissionTeamDrivePermissionDetails {
  /// Deprecated - use permissionDetails/additionalRoles instead.
  core.List<core.String>? additionalRoles;

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
    if (_json.containsKey('additionalRoles')) {
      additionalRoles = (_json['additionalRoles'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
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
        if (additionalRoles != null) 'additionalRoles': additionalRoles!,
        if (inherited != null) 'inherited': inherited!,
        if (inheritedFrom != null) 'inheritedFrom': inheritedFrom!,
        if (role != null) 'role': role!,
        if (teamDrivePermissionType != null)
          'teamDrivePermissionType': teamDrivePermissionType!,
      };
}

/// A permission for a file.
class Permission {
  /// Additional roles for this user.
  ///
  /// Only commenter is currently allowed, though more may be supported in the
  /// future.
  core.List<core.String>? additionalRoles;

  /// Deprecated.
  core.String? authKey;

  /// Whether the account associated with this permission has been deleted.
  ///
  /// This field only pertains to user and group permissions.
  core.bool? deleted;

  /// The domain name of the entity this permission refers to.
  ///
  /// This is an output-only field which is present when the permission type is
  /// user, group or domain.
  core.String? domain;

  /// The email address of the user or group this permission refers to.
  ///
  /// This is an output-only field which is present when the permission type is
  /// user or group.
  core.String? emailAddress;

  /// The ETag of the permission.
  core.String? etag;

  /// The time at which this permission will expire (RFC 3339 date-time).
  ///
  /// Expiration dates have the following restrictions:
  /// - They cannot be set on shared drive items
  /// - They can only be set on user and group permissions
  /// - The date must be in the future
  /// - The date cannot be more than a year in the future
  /// - The date can only be set on drive.permissions.update or
  /// drive.permissions.patch requests
  core.DateTime? expirationDate;

  /// The ID of the user this permission refers to, and identical to the
  /// permissionId in the About and Files resources.
  ///
  /// When making a drive.permissions.insert request, exactly one of the id or
  /// value fields must be specified unless the permission type is anyone, in
  /// which case both id and value are ignored.
  core.String? id;

  /// This is always drive#permission.
  core.String? kind;

  /// The name for this permission.
  core.String? name;

  /// Details of whether the permissions on this shared drive item are inherited
  /// or directly on this item.
  ///
  /// This is an output-only field which is present only for shared drive items.
  core.List<PermissionPermissionDetails>? permissionDetails;

  /// A link to the profile photo, if available.
  core.String? photoLink;

  /// The primary role for this user.
  ///
  /// While new values may be supported in the future, the following are
  /// currently allowed:
  /// - owner
  /// - organizer
  /// - fileOrganizer
  /// - writer
  /// - reader
  core.String? role;

  /// A link back to this permission.
  core.String? selfLink;

  /// Deprecated - use permissionDetails instead.
  core.List<PermissionTeamDrivePermissionDetails>? teamDrivePermissionDetails;

  /// The account type.
  ///
  /// Allowed values are:
  /// - user
  /// - group
  /// - domain
  /// - anyone
  core.String? type;

  /// The email address or domain name for the entity.
  ///
  /// This is used during inserts and is not populated in responses. When making
  /// a drive.permissions.insert request, exactly one of the id or value fields
  /// must be specified unless the permission type is anyone, in which case both
  /// id and value are ignored.
  core.String? value;

  /// Indicates the view for this permission.
  ///
  /// Only populated for permissions that belong to a view. published is the
  /// only supported value.
  core.String? view;

  /// Whether the link is required for this permission.
  core.bool? withLink;

  Permission();

  Permission.fromJson(core.Map _json) {
    if (_json.containsKey('additionalRoles')) {
      additionalRoles = (_json['additionalRoles'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('authKey')) {
      authKey = _json['authKey'] as core.String;
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('emailAddress')) {
      emailAddress = _json['emailAddress'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('expirationDate')) {
      expirationDate =
          core.DateTime.parse(_json['expirationDate'] as core.String);
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
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
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
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
    if (_json.containsKey('view')) {
      view = _json['view'] as core.String;
    }
    if (_json.containsKey('withLink')) {
      withLink = _json['withLink'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalRoles != null) 'additionalRoles': additionalRoles!,
        if (authKey != null) 'authKey': authKey!,
        if (deleted != null) 'deleted': deleted!,
        if (domain != null) 'domain': domain!,
        if (emailAddress != null) 'emailAddress': emailAddress!,
        if (etag != null) 'etag': etag!,
        if (expirationDate != null)
          'expirationDate': expirationDate!.toIso8601String(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (permissionDetails != null)
          'permissionDetails':
              permissionDetails!.map((value) => value.toJson()).toList(),
        if (photoLink != null) 'photoLink': photoLink!,
        if (role != null) 'role': role!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (teamDrivePermissionDetails != null)
          'teamDrivePermissionDetails': teamDrivePermissionDetails!
              .map((value) => value.toJson())
              .toList(),
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
        if (view != null) 'view': view!,
        if (withLink != null) 'withLink': withLink!,
      };
}

/// An ID for a user or group as seen in Permission items.
class PermissionId {
  /// The permission ID.
  core.String? id;

  /// This is always drive#permissionId.
  core.String? kind;

  PermissionId();

  PermissionId.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
      };
}

/// A list of permissions associated with a file.
class PermissionList {
  /// The ETag of the list.
  core.String? etag;

  /// The list of permissions.
  core.List<Permission>? items;

  /// This is always drive#permissionList.
  core.String? kind;

  /// The page token for the next page of permissions.
  ///
  /// This field will be absent if the end of the permissions list has been
  /// reached. If the token is rejected for any reason, it should be discarded,
  /// and pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// A link back to this list.
  core.String? selfLink;

  PermissionList();

  PermissionList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Permission>((value) =>
              Permission.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A key-value pair attached to a file that is either public or private to an
/// application.
/// The following limits apply to file properties:
/// - Maximum of 100 properties total per file
/// - Maximum of 30 private properties per app
/// - Maximum of 30 public properties
/// - Maximum of 124 bytes size limit on (key + value) string in UTF-8 encoding
/// for a single property.
class Property {
  /// ETag of the property.
  core.String? etag;

  /// The key of this property.
  core.String? key;

  /// This is always drive#property.
  core.String? kind;

  /// The link back to this property.
  core.String? selfLink;

  /// The value of this property.
  core.String? value;

  /// The visibility of this property.
  ///
  /// Allowed values are PRIVATE and PUBLIC. (Default: PRIVATE). Private
  /// properties can only be retrieved using an authenticated request. An
  /// authenticated request uses an access token obtained with a OAuth 2 client
  /// ID. You cannot use an API key to retrieve private properties.
  core.String? visibility;

  Property();

  Property.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
    if (_json.containsKey('visibility')) {
      visibility = _json['visibility'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (key != null) 'key': key!,
        if (kind != null) 'kind': kind!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (value != null) 'value': value!,
        if (visibility != null) 'visibility': visibility!,
      };
}

/// A collection of properties, key-value pairs that are either public or
/// private to an application.
class PropertyList {
  /// The ETag of the list.
  core.String? etag;

  /// The list of properties.
  core.List<Property>? items;

  /// This is always drive#propertyList.
  core.String? kind;

  /// The link back to this list.
  core.String? selfLink;

  PropertyList();

  PropertyList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Property>((value) =>
              Property.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A revision of a file.
class Revision {
  core.String? downloadUrl;

  /// The ETag of the revision.
  core.String? etag;

  /// Links for exporting Docs Editors files to specific formats.
  core.Map<core.String, core.String>? exportLinks;

  /// The size of the revision in bytes.
  ///
  /// This will only be populated on files with content stored in Drive.
  core.String? fileSize;

  /// The ID of the revision.
  core.String? id;

  /// This is always drive#revision.
  core.String? kind;

  /// The last user to modify this revision.
  User? lastModifyingUser;

  /// Name of the last user to modify this revision.
  core.String? lastModifyingUserName;

  /// An MD5 checksum for the content of this revision.
  ///
  /// This will only be populated on files with content stored in Drive.
  core.String? md5Checksum;

  /// The MIME type of the revision.
  core.String? mimeType;

  /// Last time this revision was modified (formatted RFC 3339 timestamp).
  core.DateTime? modifiedDate;

  /// The original filename when this revision was created.
  ///
  /// This will only be populated on files with content stored in Drive.
  core.String? originalFilename;

  /// Whether this revision is pinned to prevent automatic purging.
  ///
  /// If not set, the revision is automatically purged 30 days after newer
  /// content is uploaded. This field can only be modified on files with content
  /// stored in Drive, excluding Docs Editors files. Revisions can also be
  /// pinned when they are created through the drive.files.insert/update/copy by
  /// using the pinned query parameter. Pinned revisions are stored indefinitely
  /// using additional storage quota, up to a maximum of 200 revisions.
  core.bool? pinned;

  /// Whether subsequent revisions will be automatically republished.
  ///
  /// This is only populated and can only be modified for Docs Editors files.
  core.bool? publishAuto;

  /// Whether this revision is published.
  ///
  /// This is only populated and can only be modified for Docs Editors files.
  core.bool? published;

  /// A link to the published revision.
  ///
  /// This is only populated for Google Sites files.
  core.String? publishedLink;

  /// Whether this revision is published outside the domain.
  ///
  /// This is only populated and can only be modified for Docs Editors files.
  core.bool? publishedOutsideDomain;

  /// A link back to this revision.
  core.String? selfLink;

  Revision();

  Revision.fromJson(core.Map _json) {
    if (_json.containsKey('downloadUrl')) {
      downloadUrl = _json['downloadUrl'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
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
    if (_json.containsKey('fileSize')) {
      fileSize = _json['fileSize'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifyingUser')) {
      lastModifyingUser = User.fromJson(
          _json['lastModifyingUser'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lastModifyingUserName')) {
      lastModifyingUserName = _json['lastModifyingUserName'] as core.String;
    }
    if (_json.containsKey('md5Checksum')) {
      md5Checksum = _json['md5Checksum'] as core.String;
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('modifiedDate')) {
      modifiedDate = core.DateTime.parse(_json['modifiedDate'] as core.String);
    }
    if (_json.containsKey('originalFilename')) {
      originalFilename = _json['originalFilename'] as core.String;
    }
    if (_json.containsKey('pinned')) {
      pinned = _json['pinned'] as core.bool;
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
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (downloadUrl != null) 'downloadUrl': downloadUrl!,
        if (etag != null) 'etag': etag!,
        if (exportLinks != null) 'exportLinks': exportLinks!,
        if (fileSize != null) 'fileSize': fileSize!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastModifyingUser != null)
          'lastModifyingUser': lastModifyingUser!.toJson(),
        if (lastModifyingUserName != null)
          'lastModifyingUserName': lastModifyingUserName!,
        if (md5Checksum != null) 'md5Checksum': md5Checksum!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (modifiedDate != null)
          'modifiedDate': modifiedDate!.toIso8601String(),
        if (originalFilename != null) 'originalFilename': originalFilename!,
        if (pinned != null) 'pinned': pinned!,
        if (publishAuto != null) 'publishAuto': publishAuto!,
        if (published != null) 'published': published!,
        if (publishedLink != null) 'publishedLink': publishedLink!,
        if (publishedOutsideDomain != null)
          'publishedOutsideDomain': publishedOutsideDomain!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A list of revisions of a file.
class RevisionList {
  /// The ETag of the list.
  core.String? etag;

  /// The list of revisions.
  ///
  /// If nextPageToken is populated, then this list may be incomplete and an
  /// additional page of results should be fetched.
  core.List<Revision>? items;

  /// This is always drive#revisionList.
  core.String? kind;

  /// The page token for the next page of revisions.
  ///
  /// This field will be absent if the end of the revisions list has been
  /// reached. If the token is rejected for any reason, it should be discarded
  /// and pagination should be restarted from the first page of results.
  core.String? nextPageToken;

  /// A link back to this list.
  core.String? selfLink;

  RevisionList();

  RevisionList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Revision>((value) =>
              Revision.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (selfLink != null) 'selfLink': selfLink!,
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
  core.DateTime? createdDate;

  /// The ID of this Team Drive which is also the ID of the top level folder of
  /// this Team Drive.
  core.String? id;

  /// This is always drive#teamDrive
  core.String? kind;

  /// The name of this Team Drive.
  core.String? name;

  /// A set of restrictions that apply to this Team Drive or items inside this
  /// Team Drive.
  TeamDriveRestrictions? restrictions;

  /// The ID of the theme from which the background image and color will be set.
  ///
  /// The set of possible teamDriveThemes can be retrieved from a
  /// drive.about.get response. When not specified on a drive.teamdrives.insert
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
    if (_json.containsKey('createdDate')) {
      createdDate = core.DateTime.parse(_json['createdDate'] as core.String);
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
        if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (restrictions != null) 'restrictions': restrictions!.toJson(),
        if (themeId != null) 'themeId': themeId!,
      };
}

/// A list of Team Drives.
class TeamDriveList {
  /// The list of Team Drives.
  core.List<TeamDrive>? items;

  /// This is always drive#teamDriveList
  core.String? kind;

  /// The page token for the next page of Team Drives.
  core.String? nextPageToken;

  TeamDriveList();

  TeamDriveList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<TeamDrive>((value) =>
              TeamDrive.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The user's profile picture.
class UserPicture {
  /// A URL that points to a profile picture of this user.
  core.String? url;

  UserPicture();

  UserPicture.fromJson(core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
      };
}

/// Information about a Drive user.
class User {
  /// A plain text displayable name for this user.
  core.String? displayName;

  /// The email address of the user.
  core.String? emailAddress;

  /// Whether this user is the same as the authenticated user for whom the
  /// request was made.
  core.bool? isAuthenticatedUser;

  /// This is always drive#user.
  core.String? kind;

  /// The user's ID as visible in the permissions collection.
  core.String? permissionId;

  /// The user's profile picture.
  UserPicture? picture;

  User();

  User.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('emailAddress')) {
      emailAddress = _json['emailAddress'] as core.String;
    }
    if (_json.containsKey('isAuthenticatedUser')) {
      isAuthenticatedUser = _json['isAuthenticatedUser'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('permissionId')) {
      permissionId = _json['permissionId'] as core.String;
    }
    if (_json.containsKey('picture')) {
      picture = UserPicture.fromJson(
          _json['picture'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (emailAddress != null) 'emailAddress': emailAddress!,
        if (isAuthenticatedUser != null)
          'isAuthenticatedUser': isAuthenticatedUser!,
        if (kind != null) 'kind': kind!,
        if (permissionId != null) 'permissionId': permissionId!,
        if (picture != null) 'picture': picture!.toJson(),
      };
}

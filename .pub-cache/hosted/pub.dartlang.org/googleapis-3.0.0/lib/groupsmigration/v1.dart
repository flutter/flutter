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

/// Groups Migration API - v1
///
/// The Groups Migration API allows domain administrators to archive emails into
/// Google groups.
///
/// For more information, see
/// <https://developers.google.com/google-apps/groups-migration/>
///
/// Create an instance of [GroupsMigrationApi] to access these resources:
///
/// - [ArchiveResource]
library groupsmigration.v1;

import 'dart:async' as async;
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

/// The Groups Migration API allows domain administrators to archive emails into
/// Google groups.
class GroupsMigrationApi {
  /// Upload messages to any Google group in your domain
  static const appsGroupsMigrationScope =
      'https://www.googleapis.com/auth/apps.groups.migration';

  final commons.ApiRequester _requester;

  ArchiveResource get archive => ArchiveResource(_requester);

  GroupsMigrationApi(http.Client client,
      {core.String rootUrl = 'https://groupsmigration.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ArchiveResource {
  final commons.ApiRequester _requester;

  ArchiveResource(commons.ApiRequester client) : _requester = client;

  /// Inserts a new mail into the archive of the Google group.
  ///
  /// Request parameters:
  ///
  /// [groupId] - The group ID
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// Completes with a [Groups].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Groups> insert(
    core.String groupId, {
    core.String? $fields,
    commons.Media? uploadMedia,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url =
          'groups/v1/groups/' + commons.escapeVariable('$groupId') + '/archive';
    } else {
      _url = '/upload/groups/v1/groups/' +
          commons.escapeVariable('$groupId') +
          '/archive';
    }

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: commons.UploadOptions.defaultOptions,
    );
    return Groups.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// JSON response template for groups migration API.
class Groups {
  /// The kind of insert resource this is.
  core.String? kind;

  /// The status of the insert request.
  core.String? responseCode;

  Groups();

  Groups.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('responseCode')) {
      responseCode = _json['responseCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (responseCode != null) 'responseCode': responseCode!,
      };
}

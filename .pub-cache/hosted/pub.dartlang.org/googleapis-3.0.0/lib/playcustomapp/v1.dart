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

/// Google Play Custom App Publishing API - v1
///
/// API to create and publish custom Android apps
///
/// For more information, see
/// <https://developers.google.com/android/work/play/custom-app-api/>
///
/// Create an instance of [PlaycustomappApi] to access these resources:
///
/// - [AccountsResource]
///   - [AccountsCustomAppsResource]
library playcustomapp.v1;

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

/// API to create and publish custom Android apps
class PlaycustomappApi {
  /// View and manage your Google Play Developer account
  static const androidpublisherScope =
      'https://www.googleapis.com/auth/androidpublisher';

  final commons.ApiRequester _requester;

  AccountsResource get accounts => AccountsResource(_requester);

  PlaycustomappApi(http.Client client,
      {core.String rootUrl = 'https://playcustomapp.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountsResource {
  final commons.ApiRequester _requester;

  AccountsCustomAppsResource get customApps =>
      AccountsCustomAppsResource(_requester);

  AccountsResource(commons.ApiRequester client) : _requester = client;
}

class AccountsCustomAppsResource {
  final commons.ApiRequester _requester;

  AccountsCustomAppsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new custom app.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [account] - Developer account ID.
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
  /// Completes with a [CustomApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomApp> create(
    CustomApp request,
    core.String account, {
    core.String? $fields,
    commons.UploadOptions uploadOptions = commons.UploadOptions.defaultOptions,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'playcustomapp/v1/accounts/' +
          commons.escapeVariable('$account') +
          '/customApps';
    } else if (uploadOptions is commons.ResumableUploadOptions) {
      _url = '/resumable/upload/playcustomapp/v1/accounts/' +
          commons.escapeVariable('$account') +
          '/customApps';
    } else {
      _url = '/upload/playcustomapp/v1/accounts/' +
          commons.escapeVariable('$account') +
          '/customApps';
    }

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: uploadOptions,
    );
    return CustomApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// This resource represents a custom app.
class CustomApp {
  /// Default listing language in BCP 47 format.
  core.String? languageCode;

  /// Package name of the created Android app.
  ///
  /// Only present in the API response.
  ///
  /// Output only.
  core.String? packageName;

  /// Title for the Android app.
  core.String? title;

  CustomApp();

  CustomApp.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
        if (packageName != null) 'packageName': packageName!,
        if (title != null) 'title': title!,
      };
}

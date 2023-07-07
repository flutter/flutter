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

/// Indexing API - v3
///
/// Notifies Google when your web pages change.
///
/// For more information, see
/// <https://developers.google.com/search/apis/indexing-api/>
///
/// Create an instance of [IndexingApi] to access these resources:
///
/// - [UrlNotificationsResource]
library indexing.v3;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Notifies Google when your web pages change.
class IndexingApi {
  /// Submit data to Google for indexing
  static const indexingScope = 'https://www.googleapis.com/auth/indexing';

  final commons.ApiRequester _requester;

  UrlNotificationsResource get urlNotifications =>
      UrlNotificationsResource(_requester);

  IndexingApi(http.Client client,
      {core.String rootUrl = 'https://indexing.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class UrlNotificationsResource {
  final commons.ApiRequester _requester;

  UrlNotificationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets metadata about a Web Document.
  ///
  /// This method can _only_ be used to query URLs that were previously seen in
  /// successful Indexing API notifications. Includes the latest
  /// `UrlNotification` received via this API.
  ///
  /// Request parameters:
  ///
  /// [url] - URL that is being queried.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UrlNotificationMetadata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UrlNotificationMetadata> getMetadata({
    core.String? url,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (url != null) 'url': [url],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3/urlNotifications/metadata';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UrlNotificationMetadata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Notifies that a URL has been updated or deleted.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PublishUrlNotificationResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PublishUrlNotificationResponse> publish(
    UrlNotification request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3/urlNotifications:publish';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PublishUrlNotificationResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Output for PublishUrlNotification
class PublishUrlNotificationResponse {
  /// Description of the notification events received for this URL.
  UrlNotificationMetadata? urlNotificationMetadata;

  PublishUrlNotificationResponse();

  PublishUrlNotificationResponse.fromJson(core.Map _json) {
    if (_json.containsKey('urlNotificationMetadata')) {
      urlNotificationMetadata = UrlNotificationMetadata.fromJson(
          _json['urlNotificationMetadata']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (urlNotificationMetadata != null)
          'urlNotificationMetadata': urlNotificationMetadata!.toJson(),
      };
}

/// `UrlNotification` is the resource used in all Indexing API calls.
///
/// It describes one event in the life cycle of a Web Document.
class UrlNotification {
  /// Creation timestamp for this notification.
  ///
  /// Users should _not_ specify it, the field is ignored at the request time.
  core.String? notifyTime;

  /// The URL life cycle event that Google is being notified about.
  /// Possible string values are:
  /// - "URL_NOTIFICATION_TYPE_UNSPECIFIED" : Unspecified.
  /// - "URL_UPDATED" : The given URL (Web document) has been updated.
  /// - "URL_DELETED" : The given URL (Web document) has been deleted.
  core.String? type;

  /// The object of this notification.
  ///
  /// The URL must be owned by the publisher of this notification and, in case
  /// of `URL_UPDATED` notifications, it _must_ be crawlable by Google.
  core.String? url;

  UrlNotification();

  UrlNotification.fromJson(core.Map _json) {
    if (_json.containsKey('notifyTime')) {
      notifyTime = _json['notifyTime'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (notifyTime != null) 'notifyTime': notifyTime!,
        if (type != null) 'type': type!,
        if (url != null) 'url': url!,
      };
}

/// Summary of the most recent Indexing API notifications successfully received,
/// for a given URL.
class UrlNotificationMetadata {
  /// Latest notification received with type `URL_REMOVED`.
  UrlNotification? latestRemove;

  /// Latest notification received with type `URL_UPDATED`.
  UrlNotification? latestUpdate;

  /// URL to which this metadata refers.
  core.String? url;

  UrlNotificationMetadata();

  UrlNotificationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('latestRemove')) {
      latestRemove = UrlNotification.fromJson(
          _json['latestRemove'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('latestUpdate')) {
      latestUpdate = UrlNotification.fromJson(
          _json['latestUpdate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (latestRemove != null) 'latestRemove': latestRemove!.toJson(),
        if (latestUpdate != null) 'latestUpdate': latestUpdate!.toJson(),
        if (url != null) 'url': url!,
      };
}

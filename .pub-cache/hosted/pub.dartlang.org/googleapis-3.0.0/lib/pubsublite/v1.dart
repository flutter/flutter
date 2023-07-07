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

/// Pub/Sub Lite API - v1
///
/// For more information, see <https://cloud.google.com/pubsub/lite/docs>
///
/// Create an instance of [PubsubLiteApi] to access these resources:
///
/// - [AdminResource]
///   - [AdminProjectsResource]
///     - [AdminProjectsLocationsResource]
///       - [AdminProjectsLocationsSubscriptionsResource]
///       - [AdminProjectsLocationsTopicsResource]
///         - [AdminProjectsLocationsTopicsSubscriptionsResource]
/// - [CursorResource]
///   - [CursorProjectsResource]
///     - [CursorProjectsLocationsResource]
///       - [CursorProjectsLocationsSubscriptionsResource]
///         - [CursorProjectsLocationsSubscriptionsCursorsResource]
/// - [TopicStatsResource]
///   - [TopicStatsProjectsResource]
///     - [TopicStatsProjectsLocationsResource]
///       - [TopicStatsProjectsLocationsTopicsResource]
library pubsublite.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class PubsubLiteApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  AdminResource get admin => AdminResource(_requester);
  CursorResource get cursor => CursorResource(_requester);
  TopicStatsResource get topicStats => TopicStatsResource(_requester);

  PubsubLiteApi(http.Client client,
      {core.String rootUrl = 'https://pubsublite.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AdminResource {
  final commons.ApiRequester _requester;

  AdminProjectsResource get projects => AdminProjectsResource(_requester);

  AdminResource(commons.ApiRequester client) : _requester = client;
}

class AdminProjectsResource {
  final commons.ApiRequester _requester;

  AdminProjectsLocationsResource get locations =>
      AdminProjectsLocationsResource(_requester);

  AdminProjectsResource(commons.ApiRequester client) : _requester = client;
}

class AdminProjectsLocationsResource {
  final commons.ApiRequester _requester;

  AdminProjectsLocationsSubscriptionsResource get subscriptions =>
      AdminProjectsLocationsSubscriptionsResource(_requester);
  AdminProjectsLocationsTopicsResource get topics =>
      AdminProjectsLocationsTopicsResource(_requester);

  AdminProjectsLocationsResource(commons.ApiRequester client)
      : _requester = client;
}

class AdminProjectsLocationsSubscriptionsResource {
  final commons.ApiRequester _requester;

  AdminProjectsLocationsSubscriptionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new subscription.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent location in which to create the
  /// subscription. Structured like
  /// `projects/{project_number}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [skipBacklog] - If true, the newly created subscription will only receive
  /// messages published after the subscription was created. Otherwise, the
  /// entire message backlog will be received on the subscription. Defaults to
  /// false.
  ///
  /// [subscriptionId] - Required. The ID to use for the subscription, which
  /// will become the final component of the subscription's name. This value is
  /// structured like: `my-sub-name`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> create(
    Subscription request,
    core.String parent, {
    core.bool? skipBacklog,
    core.String? subscriptionId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (skipBacklog != null) 'skipBacklog': ['${skipBacklog}'],
      if (subscriptionId != null) 'subscriptionId': [subscriptionId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/admin/' + core.Uri.encodeFull('$parent') + '/subscriptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified subscription.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the subscription to delete.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/subscriptions/\[^/\]+$`.
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

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the subscription configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the subscription whose configuration to
  /// return.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/subscriptions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of subscriptions for the given project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent whose subscriptions are to be listed.
  /// Structured like `projects/{project_number}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of subscriptions to return. The service
  /// may return fewer than this value. If unset or zero, all subscriptions for
  /// the parent will be returned.
  ///
  /// [pageToken] - A page token, received from a previous `ListSubscriptions`
  /// call. Provide this to retrieve the subsequent page. When paginating, all
  /// other parameters provided to `ListSubscriptions` must match the call that
  /// provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSubscriptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSubscriptionsResponse> list(
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

    final _url =
        'v1/admin/' + core.Uri.encodeFull('$parent') + '/subscriptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSubscriptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates properties of the specified subscription.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the subscription. Structured like:
  /// projects/{project_number}/locations/{location}/subscriptions/{subscription_id}
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/subscriptions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A mask specifying the subscription fields to
  /// change.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> patch(
    Subscription request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdminProjectsLocationsTopicsResource {
  final commons.ApiRequester _requester;

  AdminProjectsLocationsTopicsSubscriptionsResource get subscriptions =>
      AdminProjectsLocationsTopicsSubscriptionsResource(_requester);

  AdminProjectsLocationsTopicsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new topic.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent location in which to create the topic.
  /// Structured like `projects/{project_number}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [topicId] - Required. The ID to use for the topic, which will become the
  /// final component of the topic's name. This value is structured like:
  /// `my-topic-name`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Topic].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Topic> create(
    Topic request,
    core.String parent, {
    core.String? topicId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (topicId != null) 'topicId': [topicId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/admin/' + core.Uri.encodeFull('$parent') + '/topics';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Topic.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified topic.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the topic to delete.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
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

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the topic configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the topic whose configuration to return.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Topic].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Topic> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Topic.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the partition information for the requested topic.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The topic whose partition information to return.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TopicPartitions].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TopicPartitions> getPartitions(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name') + '/partitions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TopicPartitions.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of topics for the given project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent whose topics are to be listed. Structured
  /// like `projects/{project_number}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of topics to return. The service may
  /// return fewer than this value. If unset or zero, all topics for the parent
  /// will be returned.
  ///
  /// [pageToken] - A page token, received from a previous `ListTopics` call.
  /// Provide this to retrieve the subsequent page. When paginating, all other
  /// parameters provided to `ListTopics` must match the call that provided the
  /// page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTopicsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTopicsResponse> list(
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

    final _url = 'v1/admin/' + core.Uri.encodeFull('$parent') + '/topics';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTopicsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates properties of the specified topic.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the topic. Structured like:
  /// projects/{project_number}/locations/{location}/topics/{topic_id}
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A mask specifying the topic fields to change.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Topic].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Topic> patch(
    Topic request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Topic.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdminProjectsLocationsTopicsSubscriptionsResource {
  final commons.ApiRequester _requester;

  AdminProjectsLocationsTopicsSubscriptionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the subscriptions attached to the specified topic.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the topic whose subscriptions to list.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of subscriptions to return. The service
  /// may return fewer than this value. If unset or zero, all subscriptions for
  /// the given topic will be returned.
  ///
  /// [pageToken] - A page token, received from a previous
  /// `ListTopicSubscriptions` call. Provide this to retrieve the subsequent
  /// page. When paginating, all other parameters provided to
  /// `ListTopicSubscriptions` must match the call that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTopicSubscriptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTopicSubscriptionsResponse> list(
    core.String name, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/admin/' + core.Uri.encodeFull('$name') + '/subscriptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTopicSubscriptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CursorResource {
  final commons.ApiRequester _requester;

  CursorProjectsResource get projects => CursorProjectsResource(_requester);

  CursorResource(commons.ApiRequester client) : _requester = client;
}

class CursorProjectsResource {
  final commons.ApiRequester _requester;

  CursorProjectsLocationsResource get locations =>
      CursorProjectsLocationsResource(_requester);

  CursorProjectsResource(commons.ApiRequester client) : _requester = client;
}

class CursorProjectsLocationsResource {
  final commons.ApiRequester _requester;

  CursorProjectsLocationsSubscriptionsResource get subscriptions =>
      CursorProjectsLocationsSubscriptionsResource(_requester);

  CursorProjectsLocationsResource(commons.ApiRequester client)
      : _requester = client;
}

class CursorProjectsLocationsSubscriptionsResource {
  final commons.ApiRequester _requester;

  CursorProjectsLocationsSubscriptionsCursorsResource get cursors =>
      CursorProjectsLocationsSubscriptionsCursorsResource(_requester);

  CursorProjectsLocationsSubscriptionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Updates the committed cursor.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [subscription] - The subscription for which to update the cursor.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/subscriptions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CommitCursorResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommitCursorResponse> commitCursor(
    CommitCursorRequest request,
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/cursor/' + core.Uri.encodeFull('$subscription') + ':commitCursor';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CommitCursorResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CursorProjectsLocationsSubscriptionsCursorsResource {
  final commons.ApiRequester _requester;

  CursorProjectsLocationsSubscriptionsCursorsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Returns all committed cursor information for a subscription.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The subscription for which to retrieve cursors.
  /// Structured like
  /// `projects/{project_number}/locations/{location}/subscriptions/{subscription_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/subscriptions/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of cursors to return. The service may
  /// return fewer than this value. If unset or zero, all cursors for the parent
  /// will be returned.
  ///
  /// [pageToken] - A page token, received from a previous
  /// `ListPartitionCursors` call. Provide this to retrieve the subsequent page.
  /// When paginating, all other parameters provided to `ListPartitionCursors`
  /// must match the call that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPartitionCursorsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPartitionCursorsResponse> list(
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

    final _url = 'v1/cursor/' + core.Uri.encodeFull('$parent') + '/cursors';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPartitionCursorsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TopicStatsResource {
  final commons.ApiRequester _requester;

  TopicStatsProjectsResource get projects =>
      TopicStatsProjectsResource(_requester);

  TopicStatsResource(commons.ApiRequester client) : _requester = client;
}

class TopicStatsProjectsResource {
  final commons.ApiRequester _requester;

  TopicStatsProjectsLocationsResource get locations =>
      TopicStatsProjectsLocationsResource(_requester);

  TopicStatsProjectsResource(commons.ApiRequester client) : _requester = client;
}

class TopicStatsProjectsLocationsResource {
  final commons.ApiRequester _requester;

  TopicStatsProjectsLocationsTopicsResource get topics =>
      TopicStatsProjectsLocationsTopicsResource(_requester);

  TopicStatsProjectsLocationsResource(commons.ApiRequester client)
      : _requester = client;
}

class TopicStatsProjectsLocationsTopicsResource {
  final commons.ApiRequester _requester;

  TopicStatsProjectsLocationsTopicsResource(commons.ApiRequester client)
      : _requester = client;

  /// Compute the head cursor for the partition.
  ///
  /// The head cursor's offset is guaranteed to be less than or equal to all
  /// messages which have not yet been acknowledged as published, and greater
  /// than the offset of any message whose publish has already been
  /// acknowledged. It is zero if there have never been messages in the
  /// partition.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. The topic for which we should compute the head cursor.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ComputeHeadCursorResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ComputeHeadCursorResponse> computeHeadCursor(
    ComputeHeadCursorRequest request,
    core.String topic, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/topicStats/' + core.Uri.encodeFull('$topic') + ':computeHeadCursor';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ComputeHeadCursorResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Compute statistics about a range of messages in a given topic and
  /// partition.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. The topic for which we should compute message stats.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ComputeMessageStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ComputeMessageStatsResponse> computeMessageStats(
    ComputeMessageStatsRequest request,
    core.String topic, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/topicStats/' +
        core.Uri.encodeFull('$topic') +
        ':computeMessageStats';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ComputeMessageStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Compute the corresponding cursor for a publish or event time in a topic
  /// partition.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. The topic for which we should compute the cursor.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ComputeTimeCursorResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ComputeTimeCursorResponse> computeTimeCursor(
    ComputeTimeCursorRequest request,
    core.String topic, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/topicStats/' + core.Uri.encodeFull('$topic') + ':computeTimeCursor';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ComputeTimeCursorResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// The throughput capacity configuration for each partition.
class Capacity {
  /// Publish throughput capacity per partition in MiB/s.
  ///
  /// Must be >= 4 and <= 16.
  core.int? publishMibPerSec;

  /// Subscribe throughput capacity per partition in MiB/s.
  ///
  /// Must be >= 4 and <= 32.
  core.int? subscribeMibPerSec;

  Capacity();

  Capacity.fromJson(core.Map _json) {
    if (_json.containsKey('publishMibPerSec')) {
      publishMibPerSec = _json['publishMibPerSec'] as core.int;
    }
    if (_json.containsKey('subscribeMibPerSec')) {
      subscribeMibPerSec = _json['subscribeMibPerSec'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publishMibPerSec != null) 'publishMibPerSec': publishMibPerSec!,
        if (subscribeMibPerSec != null)
          'subscribeMibPerSec': subscribeMibPerSec!,
      };
}

/// Request for CommitCursor.
class CommitCursorRequest {
  /// The new value for the committed cursor.
  Cursor? cursor;

  /// The partition for which to update the cursor.
  ///
  /// Partitions are zero indexed, so `partition` must be in the range \[0,
  /// topic.num_partitions).
  core.String? partition;

  CommitCursorRequest();

  CommitCursorRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cursor')) {
      cursor = Cursor.fromJson(
          _json['cursor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('partition')) {
      partition = _json['partition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cursor != null) 'cursor': cursor!.toJson(),
        if (partition != null) 'partition': partition!,
      };
}

/// Response for CommitCursor.
class CommitCursorResponse {
  CommitCursorResponse();

  CommitCursorResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Compute the current head cursor for a partition.
class ComputeHeadCursorRequest {
  /// The partition for which we should compute the head cursor.
  ///
  /// Required.
  core.String? partition;

  ComputeHeadCursorRequest();

  ComputeHeadCursorRequest.fromJson(core.Map _json) {
    if (_json.containsKey('partition')) {
      partition = _json['partition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (partition != null) 'partition': partition!,
      };
}

/// Response containing the head cursor for the requested topic and partition.
class ComputeHeadCursorResponse {
  /// The head cursor.
  Cursor? headCursor;

  ComputeHeadCursorResponse();

  ComputeHeadCursorResponse.fromJson(core.Map _json) {
    if (_json.containsKey('headCursor')) {
      headCursor = Cursor.fromJson(
          _json['headCursor'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (headCursor != null) 'headCursor': headCursor!.toJson(),
      };
}

/// Compute statistics about a range of messages in a given topic and partition.
class ComputeMessageStatsRequest {
  /// The exclusive end of the range.
  ///
  /// The range is empty if end_cursor <= start_cursor. Specifying a
  /// start_cursor before the first message and an end_cursor after the last
  /// message will retrieve all messages.
  Cursor? endCursor;

  /// The partition for which we should compute message stats.
  ///
  /// Required.
  core.String? partition;

  /// The inclusive start of the range.
  Cursor? startCursor;

  ComputeMessageStatsRequest();

  ComputeMessageStatsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('endCursor')) {
      endCursor = Cursor.fromJson(
          _json['endCursor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('partition')) {
      partition = _json['partition'] as core.String;
    }
    if (_json.containsKey('startCursor')) {
      startCursor = Cursor.fromJson(
          _json['startCursor'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endCursor != null) 'endCursor': endCursor!.toJson(),
        if (partition != null) 'partition': partition!,
        if (startCursor != null) 'startCursor': startCursor!.toJson(),
      };
}

/// Response containing stats for messages in the requested topic and partition.
class ComputeMessageStatsResponse {
  /// The number of quota bytes accounted to these messages.
  core.String? messageBytes;

  /// The count of messages.
  core.String? messageCount;

  /// The minimum event timestamp across these messages.
  ///
  /// For the purposes of this computation, if a message does not have an event
  /// time, we use the publish time. The timestamp will be unset if there are no
  /// messages.
  core.String? minimumEventTime;

  /// The minimum publish timestamp across these messages.
  ///
  /// Note that publish timestamps within a partition are not guaranteed to be
  /// non-decreasing. The timestamp will be unset if there are no messages.
  core.String? minimumPublishTime;

  ComputeMessageStatsResponse();

  ComputeMessageStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('messageBytes')) {
      messageBytes = _json['messageBytes'] as core.String;
    }
    if (_json.containsKey('messageCount')) {
      messageCount = _json['messageCount'] as core.String;
    }
    if (_json.containsKey('minimumEventTime')) {
      minimumEventTime = _json['minimumEventTime'] as core.String;
    }
    if (_json.containsKey('minimumPublishTime')) {
      minimumPublishTime = _json['minimumPublishTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (messageBytes != null) 'messageBytes': messageBytes!,
        if (messageCount != null) 'messageCount': messageCount!,
        if (minimumEventTime != null) 'minimumEventTime': minimumEventTime!,
        if (minimumPublishTime != null)
          'minimumPublishTime': minimumPublishTime!,
      };
}

/// Compute the corresponding cursor for a publish or event time in a topic
/// partition.
class ComputeTimeCursorRequest {
  /// The partition for which we should compute the cursor.
  ///
  /// Required.
  core.String? partition;

  /// The target publish or event time.
  ///
  /// Specifying a future time will return an unset cursor.
  ///
  /// Required.
  TimeTarget? target;

  ComputeTimeCursorRequest();

  ComputeTimeCursorRequest.fromJson(core.Map _json) {
    if (_json.containsKey('partition')) {
      partition = _json['partition'] as core.String;
    }
    if (_json.containsKey('target')) {
      target = TimeTarget.fromJson(
          _json['target'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (partition != null) 'partition': partition!,
        if (target != null) 'target': target!.toJson(),
      };
}

/// Response containing the cursor corresponding to a publish or event time in a
/// topic partition.
class ComputeTimeCursorResponse {
  /// If present, the cursor references the first message with time greater than
  /// or equal to the specified target time.
  ///
  /// If such a message cannot be found, the cursor will be unset (i.e. `cursor`
  /// is not present).
  Cursor? cursor;

  ComputeTimeCursorResponse();

  ComputeTimeCursorResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cursor')) {
      cursor = Cursor.fromJson(
          _json['cursor'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cursor != null) 'cursor': cursor!.toJson(),
      };
}

/// A cursor that describes the position of a message within a topic partition.
class Cursor {
  /// The offset of a message within a topic partition.
  ///
  /// Must be greater than or equal 0.
  core.String? offset;

  Cursor();

  Cursor.fromJson(core.Map _json) {
    if (_json.containsKey('offset')) {
      offset = _json['offset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (offset != null) 'offset': offset!,
      };
}

/// The settings for a subscription's message delivery.
class DeliveryConfig {
  /// The DeliveryRequirement for this subscription.
  /// Possible string values are:
  /// - "DELIVERY_REQUIREMENT_UNSPECIFIED" : Default value. This value is
  /// unused.
  /// - "DELIVER_IMMEDIATELY" : The server does not wait for a published message
  /// to be successfully written to storage before delivering it to subscribers.
  /// - "DELIVER_AFTER_STORED" : The server will not deliver a published message
  /// to subscribers until the message has been successfully written to storage.
  /// This will result in higher end-to-end latency, but consistent delivery.
  core.String? deliveryRequirement;

  DeliveryConfig();

  DeliveryConfig.fromJson(core.Map _json) {
    if (_json.containsKey('deliveryRequirement')) {
      deliveryRequirement = _json['deliveryRequirement'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliveryRequirement != null)
          'deliveryRequirement': deliveryRequirement!,
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

/// Response for ListPartitionCursors
class ListPartitionCursorsResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The partition cursors from this request.
  core.List<PartitionCursor>? partitionCursors;

  ListPartitionCursorsResponse();

  ListPartitionCursorsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('partitionCursors')) {
      partitionCursors = (_json['partitionCursors'] as core.List)
          .map<PartitionCursor>((value) => PartitionCursor.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (partitionCursors != null)
          'partitionCursors':
              partitionCursors!.map((value) => value.toJson()).toList(),
      };
}

/// Response for ListSubscriptions.
class ListSubscriptionsResponse {
  /// A token that can be sent as `page_token` to retrieve the next page of
  /// results.
  ///
  /// If this field is omitted, there are no more results.
  core.String? nextPageToken;

  /// The list of subscriptions in the requested parent.
  ///
  /// The order of the subscriptions is unspecified.
  core.List<Subscription>? subscriptions;

  ListSubscriptionsResponse();

  ListSubscriptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('subscriptions')) {
      subscriptions = (_json['subscriptions'] as core.List)
          .map<Subscription>((value) => Subscription.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (subscriptions != null)
          'subscriptions':
              subscriptions!.map((value) => value.toJson()).toList(),
      };
}

/// Response for ListTopicSubscriptions.
class ListTopicSubscriptionsResponse {
  /// A token that can be sent as `page_token` to retrieve the next page of
  /// results.
  ///
  /// If this field is omitted, there are no more results.
  core.String? nextPageToken;

  /// The names of subscriptions attached to the topic.
  ///
  /// The order of the subscriptions is unspecified.
  core.List<core.String>? subscriptions;

  ListTopicSubscriptionsResponse();

  ListTopicSubscriptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('subscriptions')) {
      subscriptions = (_json['subscriptions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (subscriptions != null) 'subscriptions': subscriptions!,
      };
}

/// Response for ListTopics.
class ListTopicsResponse {
  /// A token that can be sent as `page_token` to retrieve the next page of
  /// results.
  ///
  /// If this field is omitted, there are no more results.
  core.String? nextPageToken;

  /// The list of topic in the requested parent.
  ///
  /// The order of the topics is unspecified.
  core.List<Topic>? topics;

  ListTopicsResponse();

  ListTopicsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('topics')) {
      topics = (_json['topics'] as core.List)
          .map<Topic>((value) =>
              Topic.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (topics != null)
          'topics': topics!.map((value) => value.toJson()).toList(),
      };
}

/// The settings for a topic's partitions.
class PartitionConfig {
  /// The capacity configuration.
  Capacity? capacity;

  /// The number of partitions in the topic.
  ///
  /// Must be at least 1. Once a topic has been created the number of partitions
  /// can be increased but not decreased. Message ordering is not guaranteed
  /// across a topic resize. For more information see
  /// https://cloud.google.com/pubsub/lite/docs/topics#scaling_capacity
  core.String? count;

  /// DEPRECATED: Use capacity instead which can express a superset of
  /// configurations.
  ///
  /// Every partition in the topic is allocated throughput equivalent to `scale`
  /// times the standard partition throughput (4 MiB/s). This is also reflected
  /// in the cost of this topic; a topic with `scale` of 2 and count of 10 is
  /// charged for 20 partitions. This value must be in the range \[1,4\].
  core.int? scale;

  PartitionConfig();

  PartitionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('capacity')) {
      capacity = Capacity.fromJson(
          _json['capacity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
    if (_json.containsKey('scale')) {
      scale = _json['scale'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (capacity != null) 'capacity': capacity!.toJson(),
        if (count != null) 'count': count!,
        if (scale != null) 'scale': scale!,
      };
}

/// A pair of a Cursor and the partition it is for.
class PartitionCursor {
  /// The value of the cursor.
  Cursor? cursor;

  /// The partition this is for.
  core.String? partition;

  PartitionCursor();

  PartitionCursor.fromJson(core.Map _json) {
    if (_json.containsKey('cursor')) {
      cursor = Cursor.fromJson(
          _json['cursor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('partition')) {
      partition = _json['partition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cursor != null) 'cursor': cursor!.toJson(),
        if (partition != null) 'partition': partition!,
      };
}

/// The settings for a topic's message retention.
class RetentionConfig {
  /// The provisioned storage, in bytes, per partition.
  ///
  /// If the number of bytes stored in any of the topic's partitions grows
  /// beyond this value, older messages will be dropped to make room for newer
  /// ones, regardless of the value of `period`.
  core.String? perPartitionBytes;

  /// How long a published message is retained.
  ///
  /// If unset, messages will be retained as long as the bytes retained for each
  /// partition is below `per_partition_bytes`.
  core.String? period;

  RetentionConfig();

  RetentionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('perPartitionBytes')) {
      perPartitionBytes = _json['perPartitionBytes'] as core.String;
    }
    if (_json.containsKey('period')) {
      period = _json['period'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (perPartitionBytes != null) 'perPartitionBytes': perPartitionBytes!,
        if (period != null) 'period': period!,
      };
}

/// Metadata about a subscription resource.
class Subscription {
  /// The settings for this subscription's message delivery.
  DeliveryConfig? deliveryConfig;

  /// The name of the subscription.
  ///
  /// Structured like:
  /// projects/{project_number}/locations/{location}/subscriptions/{subscription_id}
  core.String? name;

  /// The name of the topic this subscription is attached to.
  ///
  /// Structured like:
  /// projects/{project_number}/locations/{location}/topics/{topic_id}
  core.String? topic;

  Subscription();

  Subscription.fromJson(core.Map _json) {
    if (_json.containsKey('deliveryConfig')) {
      deliveryConfig = DeliveryConfig.fromJson(
          _json['deliveryConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliveryConfig != null) 'deliveryConfig': deliveryConfig!.toJson(),
        if (name != null) 'name': name!,
        if (topic != null) 'topic': topic!,
      };
}

/// A target publish or event time.
///
/// Can be used for seeking to or retrieving the corresponding cursor.
class TimeTarget {
  /// Request the cursor of the first message with event time greater than or
  /// equal to `event_time`.
  ///
  /// If messages are missing an event time, the publish time is used as a
  /// fallback. As event times are user supplied, subsequent messages may have
  /// event times less than `event_time` and should be filtered by the client,
  /// if necessary.
  core.String? eventTime;

  /// Request the cursor of the first message with publish time greater than or
  /// equal to `publish_time`.
  ///
  /// All messages thereafter are guaranteed to have publish times >=
  /// `publish_time`.
  core.String? publishTime;

  TimeTarget();

  TimeTarget.fromJson(core.Map _json) {
    if (_json.containsKey('eventTime')) {
      eventTime = _json['eventTime'] as core.String;
    }
    if (_json.containsKey('publishTime')) {
      publishTime = _json['publishTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (eventTime != null) 'eventTime': eventTime!,
        if (publishTime != null) 'publishTime': publishTime!,
      };
}

/// Metadata about a topic resource.
class Topic {
  /// The name of the topic.
  ///
  /// Structured like:
  /// projects/{project_number}/locations/{location}/topics/{topic_id}
  core.String? name;

  /// The settings for this topic's partitions.
  PartitionConfig? partitionConfig;

  /// The settings for this topic's message retention.
  RetentionConfig? retentionConfig;

  Topic();

  Topic.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('partitionConfig')) {
      partitionConfig = PartitionConfig.fromJson(
          _json['partitionConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('retentionConfig')) {
      retentionConfig = RetentionConfig.fromJson(
          _json['retentionConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (partitionConfig != null)
          'partitionConfig': partitionConfig!.toJson(),
        if (retentionConfig != null)
          'retentionConfig': retentionConfig!.toJson(),
      };
}

/// Response for GetTopicPartitions.
class TopicPartitions {
  /// The number of partitions in the topic.
  core.String? partitionCount;

  TopicPartitions();

  TopicPartitions.fromJson(core.Map _json) {
    if (_json.containsKey('partitionCount')) {
      partitionCount = _json['partitionCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (partitionCount != null) 'partitionCount': partitionCount!,
      };
}

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

/// Policy Simulator API - v1
///
/// Policy Simulator is a collection of endpoints for creating, running, and
/// viewing a Replay. A `Replay` is a type of simulation that lets you see how
/// your members' access to resources might change if you changed your IAM
/// policy. During a `Replay`, Policy Simulator re-evaluates, or replays, past
/// access attempts under both the current policy and your proposed policy, and
/// compares those results to determine how your members' access might change
/// under the proposed policy.
///
/// For more information, see
/// <https://cloud.google.com/iam/docs/simulating-access>
///
/// Create an instance of [PolicySimulatorApi] to access these resources:
///
/// - [FoldersResource]
///   - [FoldersLocationsResource]
///     - [FoldersLocationsReplaysResource]
///       - [FoldersLocationsReplaysResultsResource]
/// - [OperationsResource]
/// - [OrganizationsResource]
///   - [OrganizationsLocationsResource]
///     - [OrganizationsLocationsReplaysResource]
///       - [OrganizationsLocationsReplaysResultsResource]
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsReplaysResource]
///       - [ProjectsLocationsReplaysResultsResource]
library policysimulator.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Policy Simulator is a collection of endpoints for creating, running, and
/// viewing a Replay.
///
/// A `Replay` is a type of simulation that lets you see how your members'
/// access to resources might change if you changed your IAM policy. During a
/// `Replay`, Policy Simulator re-evaluates, or replays, past access attempts
/// under both the current policy and your proposed policy, and compares those
/// results to determine how your members' access might change under the
/// proposed policy.
class PolicySimulatorApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  FoldersResource get folders => FoldersResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);
  OrganizationsResource get organizations => OrganizationsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);

  PolicySimulatorApi(http.Client client,
      {core.String rootUrl = 'https://policysimulator.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class FoldersResource {
  final commons.ApiRequester _requester;

  FoldersLocationsResource get locations =>
      FoldersLocationsResource(_requester);

  FoldersResource(commons.ApiRequester client) : _requester = client;
}

class FoldersLocationsResource {
  final commons.ApiRequester _requester;

  FoldersLocationsReplaysResource get replays =>
      FoldersLocationsReplaysResource(_requester);

  FoldersLocationsResource(commons.ApiRequester client) : _requester = client;
}

class FoldersLocationsReplaysResource {
  final commons.ApiRequester _requester;

  FoldersLocationsReplaysResultsResource get results =>
      FoldersLocationsReplaysResultsResource(_requester);

  FoldersLocationsReplaysResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates and starts a Replay using the given ReplayConfig.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource where this Replay will be
  /// created. This resource must be a project, folder, or organization with a
  /// location. Example: `projects/my-example-project/locations/global`
  /// Value must have pattern `^folders/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
    GoogleCloudPolicysimulatorV1Replay request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/replays';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the specified Replay.
  ///
  /// Each `Replay` is available for at least 7 days.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Replay to retrieve, in the following
  /// format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`,
  /// where `{resource-id}` is the ID of the project, folder, or organization
  /// that owns the `Replay`. Example:
  /// `projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/replays/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudPolicysimulatorV1Replay].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudPolicysimulatorV1Replay> get(
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
    return GoogleCloudPolicysimulatorV1Replay.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersLocationsReplaysResultsResource {
  final commons.ApiRequester _requester;

  FoldersLocationsReplaysResultsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the results of running a Replay.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Replay whose results are listed, in the following
  /// format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`
  /// Example:
  /// `projects/my-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/replays/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of ReplayResult objects to return.
  /// Defaults to 5000. The maximum value is 5000; values above 5000 are rounded
  /// down to 5000.
  ///
  /// [pageToken] - A page token, received from a previous
  /// Simulator.ListReplayResults call. Provide this token to retrieve the next
  /// page of results. When paginating, all other parameters provided to
  /// \[Simulator.ListReplayResults\[\] must match the call that provided the
  /// page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudPolicysimulatorV1ListReplayResultsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudPolicysimulatorV1ListReplayResultsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/results';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudPolicysimulatorV1ListReplayResultsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern `^operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
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
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists operations that match the specified filter in the request.
  ///
  /// If the server doesn't support this method, it returns `UNIMPLEMENTED`.
  /// NOTE: the `name` binding allows API services to override the binding to
  /// use different resource name schemes, such as `users / * /operations`. To
  /// override the binding, API services can add a binding such as
  /// `"/v1/{name=users / * }/operations"` to their service configuration. For
  /// backwards compatibility, the default name includes the operations
  /// collection id, however overriding users must ensure the name binding is
  /// the parent resource, without the operations collection id.
  ///
  /// Request parameters:
  ///
  /// [filter] - The standard list filter.
  ///
  /// [name] - The name of the operation's parent resource.
  ///
  /// [pageSize] - The standard list page size.
  ///
  /// [pageToken] - The standard list page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list({
    core.String? filter,
    core.String? name,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (name != null) 'name': [name],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsResource get locations =>
      OrganizationsLocationsResource(_requester);

  OrganizationsResource(commons.ApiRequester client) : _requester = client;
}

class OrganizationsLocationsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsReplaysResource get replays =>
      OrganizationsLocationsReplaysResource(_requester);

  OrganizationsLocationsResource(commons.ApiRequester client)
      : _requester = client;
}

class OrganizationsLocationsReplaysResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsReplaysResultsResource get results =>
      OrganizationsLocationsReplaysResultsResource(_requester);

  OrganizationsLocationsReplaysResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates and starts a Replay using the given ReplayConfig.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource where this Replay will be
  /// created. This resource must be a project, folder, or organization with a
  /// location. Example: `projects/my-example-project/locations/global`
  /// Value must have pattern `^organizations/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
    GoogleCloudPolicysimulatorV1Replay request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/replays';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the specified Replay.
  ///
  /// Each `Replay` is available for at least 7 days.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Replay to retrieve, in the following
  /// format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`,
  /// where `{resource-id}` is the ID of the project, folder, or organization
  /// that owns the `Replay`. Example:
  /// `projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/replays/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudPolicysimulatorV1Replay].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudPolicysimulatorV1Replay> get(
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
    return GoogleCloudPolicysimulatorV1Replay.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsLocationsReplaysResultsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsReplaysResultsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the results of running a Replay.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Replay whose results are listed, in the following
  /// format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`
  /// Example:
  /// `projects/my-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/replays/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of ReplayResult objects to return.
  /// Defaults to 5000. The maximum value is 5000; values above 5000 are rounded
  /// down to 5000.
  ///
  /// [pageToken] - A page token, received from a previous
  /// Simulator.ListReplayResults call. Provide this token to retrieve the next
  /// page of results. When paginating, all other parameters provided to
  /// \[Simulator.ListReplayResults\[\] must match the call that provided the
  /// page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudPolicysimulatorV1ListReplayResultsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudPolicysimulatorV1ListReplayResultsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/results';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudPolicysimulatorV1ListReplayResultsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsReplaysResource get replays =>
      ProjectsLocationsReplaysResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsReplaysResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsReplaysResultsResource get results =>
      ProjectsLocationsReplaysResultsResource(_requester);

  ProjectsLocationsReplaysResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates and starts a Replay using the given ReplayConfig.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource where this Replay will be
  /// created. This resource must be a project, folder, or organization with a
  /// location. Example: `projects/my-example-project/locations/global`
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
    GoogleCloudPolicysimulatorV1Replay request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/replays';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the specified Replay.
  ///
  /// Each `Replay` is available for at least 7 days.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Replay to retrieve, in the following
  /// format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`,
  /// where `{resource-id}` is the ID of the project, folder, or organization
  /// that owns the `Replay`. Example:
  /// `projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/replays/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudPolicysimulatorV1Replay].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudPolicysimulatorV1Replay> get(
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
    return GoogleCloudPolicysimulatorV1Replay.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsReplaysResultsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsReplaysResultsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the results of running a Replay.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Replay whose results are listed, in the following
  /// format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`
  /// Example:
  /// `projects/my-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/replays/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of ReplayResult objects to return.
  /// Defaults to 5000. The maximum value is 5000; values above 5000 are rounded
  /// down to 5000.
  ///
  /// [pageToken] - A page token, received from a previous
  /// Simulator.ListReplayResults call. Provide this token to retrieve the next
  /// page of results. When paginating, all other parameters provided to
  /// \[Simulator.ListReplayResults\[\] must match the call that provided the
  /// page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudPolicysimulatorV1ListReplayResultsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudPolicysimulatorV1ListReplayResultsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/results';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudPolicysimulatorV1ListReplayResultsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// A summary and comparison of the member's access under the current (baseline)
/// policies and the proposed (simulated) policies for a single access tuple.
class GoogleCloudPolicysimulatorV1AccessStateDiff {
  /// How the member's access, specified in the AccessState field, changed
  /// between the current (baseline) policies and proposed (simulated) policies.
  /// Possible string values are:
  /// - "ACCESS_CHANGE_TYPE_UNSPECIFIED" : The access change is unspecified.
  /// - "NO_CHANGE" : The member's access did not change. This includes the case
  /// where both baseline and simulated are UNKNOWN, but the unknown information
  /// is equivalent.
  /// - "UNKNOWN_CHANGE" : The member's access under both the current policies
  /// and the proposed policies is `UNKNOWN`, but the unknown information
  /// differs between them.
  /// - "ACCESS_REVOKED" : The member had access under the current policies
  /// (`GRANTED`), but will no longer have access after the proposed changes
  /// (`NOT_GRANTED`).
  /// - "ACCESS_GAINED" : The member did not have access under the current
  /// policies (`NOT_GRANTED`), but will have access after the proposed changes
  /// (`GRANTED`).
  /// - "ACCESS_MAYBE_REVOKED" : This result can occur for the following
  /// reasons: * The member had access under the current policies (`GRANTED`),
  /// but their access after the proposed changes is `UNKNOWN`. * The member's
  /// access under the current policies is `UNKNOWN`, but they will not have
  /// access after the proposed changes (`NOT_GRANTED`).
  /// - "ACCESS_MAYBE_GAINED" : This result can occur for the following reasons:
  /// * The member did not have access under the current policies
  /// (`NOT_GRANTED`), but their access after the proposed changes is `UNKNOWN`.
  /// * The member's access under the current policies is `UNKNOWN`, but they
  /// will have access after the proposed changes (`GRANTED`).
  core.String? accessChange;

  /// The results of evaluating the access tuple under the current (baseline)
  /// policies.
  ///
  /// If the AccessState couldn't be fully evaluated, this field explains why.
  GoogleCloudPolicysimulatorV1ExplainedAccess? baseline;

  /// The results of evaluating the access tuple under the proposed (simulated)
  /// policies.
  ///
  /// If the AccessState couldn't be fully evaluated, this field explains why.
  GoogleCloudPolicysimulatorV1ExplainedAccess? simulated;

  GoogleCloudPolicysimulatorV1AccessStateDiff();

  GoogleCloudPolicysimulatorV1AccessStateDiff.fromJson(core.Map _json) {
    if (_json.containsKey('accessChange')) {
      accessChange = _json['accessChange'] as core.String;
    }
    if (_json.containsKey('baseline')) {
      baseline = GoogleCloudPolicysimulatorV1ExplainedAccess.fromJson(
          _json['baseline'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('simulated')) {
      simulated = GoogleCloudPolicysimulatorV1ExplainedAccess.fromJson(
          _json['simulated'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessChange != null) 'accessChange': accessChange!,
        if (baseline != null) 'baseline': baseline!.toJson(),
        if (simulated != null) 'simulated': simulated!.toJson(),
      };
}

/// Information about the member, resource, and permission to check.
class GoogleCloudPolicysimulatorV1AccessTuple {
  /// The full resource name that identifies the resource.
  ///
  /// For example,
  /// `//compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/my-instance`.
  /// For examples of full resource names for Google Cloud services, see
  /// https://cloud.google.com/iam/help/troubleshooter/full-resource-names.
  ///
  /// Required.
  core.String? fullResourceName;

  /// The IAM permission to check for the specified member and resource.
  ///
  /// For a complete list of IAM permissions, see
  /// https://cloud.google.com/iam/help/permissions/reference. For a complete
  /// list of predefined IAM roles and the permissions in each role, see
  /// https://cloud.google.com/iam/help/roles/reference.
  ///
  /// Required.
  core.String? permission;

  /// The member, or principal, whose access you want to check, in the form of
  /// the email address that represents that member.
  ///
  /// For example, `alice@example.com` or
  /// `my-service-account@my-project.iam.gserviceaccount.com`. The member must
  /// be a Google Account or a service account. Other types of members are not
  /// supported.
  ///
  /// Required.
  core.String? principal;

  GoogleCloudPolicysimulatorV1AccessTuple();

  GoogleCloudPolicysimulatorV1AccessTuple.fromJson(core.Map _json) {
    if (_json.containsKey('fullResourceName')) {
      fullResourceName = _json['fullResourceName'] as core.String;
    }
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
    if (_json.containsKey('principal')) {
      principal = _json['principal'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fullResourceName != null) 'fullResourceName': fullResourceName!,
        if (permission != null) 'permission': permission!,
        if (principal != null) 'principal': principal!,
      };
}

/// Details about how a binding in a policy affects a member's ability to use a
/// permission.
class GoogleCloudPolicysimulatorV1BindingExplanation {
  /// Indicates whether _this binding_ provides the specified permission to the
  /// specified member for the specified resource.
  ///
  /// This field does _not_ indicate whether the member actually has the
  /// permission for the resource. There might be another binding that overrides
  /// this binding. To determine whether the member actually has the permission,
  /// use the `access` field in the TroubleshootIamPolicyResponse.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ACCESS_STATE_UNSPECIFIED" : The access state is not specified.
  /// - "GRANTED" : The member has the permission.
  /// - "NOT_GRANTED" : The member does not have the permission.
  /// - "UNKNOWN_CONDITIONAL" : The member has the permission only if a
  /// condition expression evaluates to `true`.
  /// - "UNKNOWN_INFO_DENIED" : The user who created the Replay does not have
  /// access to all of the policies that Policy Simulator needs to evaluate.
  core.String? access;

  /// A condition expression that prevents this binding from granting access
  /// unless the expression evaluates to `true`.
  ///
  /// To learn about IAM Conditions, see
  /// https://cloud.google.com/iam/docs/conditions-overview.
  GoogleTypeExpr? condition;

  /// Indicates whether each member in the binding includes the member specified
  /// in the request, either directly or indirectly.
  ///
  /// Each key identifies a member in the binding, and each value indicates
  /// whether the member in the binding includes the member in the request. For
  /// example, suppose that a binding includes the following members: *
  /// `user:alice@example.com` * `group:product-eng@example.com` The member in
  /// the replayed access tuple is `user:bob@example.com`. This user is a member
  /// of the group `group:product-eng@example.com`. For the first member in the
  /// binding, the key is `user:alice@example.com`, and the `membership` field
  /// in the value is set to `MEMBERSHIP_NOT_INCLUDED`. For the second member in
  /// the binding, the key is `group:product-eng@example.com`, and the
  /// `membership` field in the value is set to `MEMBERSHIP_INCLUDED`.
  core.Map<core.String,
          GoogleCloudPolicysimulatorV1BindingExplanationAnnotatedMembership>?
      memberships;

  /// The relevance of this binding to the overall determination for the entire
  /// policy.
  /// Possible string values are:
  /// - "HEURISTIC_RELEVANCE_UNSPECIFIED" : Reserved for future use.
  /// - "NORMAL" : The data point has a limited effect on the result. Changing
  /// the data point is unlikely to affect the overall determination.
  /// - "HIGH" : The data point has a strong effect on the result. Changing the
  /// data point is likely to affect the overall determination.
  core.String? relevance;

  /// The role that this binding grants.
  ///
  /// For example, `roles/compute.serviceAgent`. For a complete list of
  /// predefined IAM roles, as well as the permissions in each role, see
  /// https://cloud.google.com/iam/help/roles/reference.
  core.String? role;

  /// Indicates whether the role granted by this binding contains the specified
  /// permission.
  /// Possible string values are:
  /// - "ROLE_PERMISSION_UNSPECIFIED" : The inclusion of the permission is not
  /// specified.
  /// - "ROLE_PERMISSION_INCLUDED" : The permission is included in the role.
  /// - "ROLE_PERMISSION_NOT_INCLUDED" : The permission is not included in the
  /// role.
  /// - "ROLE_PERMISSION_UNKNOWN_INFO_DENIED" : The user who created the Replay
  /// is not allowed to access the binding.
  core.String? rolePermission;

  /// The relevance of the permission's existence, or nonexistence, in the role
  /// to the overall determination for the entire policy.
  /// Possible string values are:
  /// - "HEURISTIC_RELEVANCE_UNSPECIFIED" : Reserved for future use.
  /// - "NORMAL" : The data point has a limited effect on the result. Changing
  /// the data point is unlikely to affect the overall determination.
  /// - "HIGH" : The data point has a strong effect on the result. Changing the
  /// data point is likely to affect the overall determination.
  core.String? rolePermissionRelevance;

  GoogleCloudPolicysimulatorV1BindingExplanation();

  GoogleCloudPolicysimulatorV1BindingExplanation.fromJson(core.Map _json) {
    if (_json.containsKey('access')) {
      access = _json['access'] as core.String;
    }
    if (_json.containsKey('condition')) {
      condition = GoogleTypeExpr.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('memberships')) {
      memberships =
          (_json['memberships'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleCloudPolicysimulatorV1BindingExplanationAnnotatedMembership
              .fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('relevance')) {
      relevance = _json['relevance'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('rolePermission')) {
      rolePermission = _json['rolePermission'] as core.String;
    }
    if (_json.containsKey('rolePermissionRelevance')) {
      rolePermissionRelevance = _json['rolePermissionRelevance'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (access != null) 'access': access!,
        if (condition != null) 'condition': condition!.toJson(),
        if (memberships != null)
          'memberships': memberships!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (relevance != null) 'relevance': relevance!,
        if (role != null) 'role': role!,
        if (rolePermission != null) 'rolePermission': rolePermission!,
        if (rolePermissionRelevance != null)
          'rolePermissionRelevance': rolePermissionRelevance!,
      };
}

/// Details about whether the binding includes the member.
class GoogleCloudPolicysimulatorV1BindingExplanationAnnotatedMembership {
  /// Indicates whether the binding includes the member.
  /// Possible string values are:
  /// - "MEMBERSHIP_UNSPECIFIED" : The membership is not specified.
  /// - "MEMBERSHIP_INCLUDED" : The binding includes the member. The member can
  /// be included directly or indirectly. For example: * A member is included
  /// directly if that member is listed in the binding. * A member is included
  /// indirectly if that member is in a Google group or Google Workspace domain
  /// that is listed in the binding.
  /// - "MEMBERSHIP_NOT_INCLUDED" : The binding does not include the member.
  /// - "MEMBERSHIP_UNKNOWN_INFO_DENIED" : The user who created the Replay is
  /// not allowed to access the binding.
  /// - "MEMBERSHIP_UNKNOWN_UNSUPPORTED" : The member is an unsupported type.
  /// Only Google Accounts and service accounts are supported.
  core.String? membership;

  /// The relevance of the member's status to the overall determination for the
  /// binding.
  /// Possible string values are:
  /// - "HEURISTIC_RELEVANCE_UNSPECIFIED" : Reserved for future use.
  /// - "NORMAL" : The data point has a limited effect on the result. Changing
  /// the data point is unlikely to affect the overall determination.
  /// - "HIGH" : The data point has a strong effect on the result. Changing the
  /// data point is likely to affect the overall determination.
  core.String? relevance;

  GoogleCloudPolicysimulatorV1BindingExplanationAnnotatedMembership();

  GoogleCloudPolicysimulatorV1BindingExplanationAnnotatedMembership.fromJson(
      core.Map _json) {
    if (_json.containsKey('membership')) {
      membership = _json['membership'] as core.String;
    }
    if (_json.containsKey('relevance')) {
      relevance = _json['relevance'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (membership != null) 'membership': membership!,
        if (relevance != null) 'relevance': relevance!,
      };
}

/// Details about how a set of policies, listed in ExplainedPolicy, resulted in
/// a certain AccessState when replaying an access tuple.
class GoogleCloudPolicysimulatorV1ExplainedAccess {
  /// Whether the member in the access tuple has permission to access the
  /// resource in the access tuple under the given policies.
  /// Possible string values are:
  /// - "ACCESS_STATE_UNSPECIFIED" : The access state is not specified.
  /// - "GRANTED" : The member has the permission.
  /// - "NOT_GRANTED" : The member does not have the permission.
  /// - "UNKNOWN_CONDITIONAL" : The member has the permission only if a
  /// condition expression evaluates to `true`.
  /// - "UNKNOWN_INFO_DENIED" : The user who created the Replay does not have
  /// access to all of the policies that Policy Simulator needs to evaluate.
  core.String? accessState;

  /// If the AccessState is `UNKNOWN`, this field contains a list of errors
  /// explaining why the result is `UNKNOWN`.
  ///
  /// If the `AccessState` is `GRANTED` or `NOT_GRANTED`, this field is omitted.
  core.List<GoogleRpcStatus>? errors;

  /// If the AccessState is `UNKNOWN`, this field contains the policies that led
  /// to that result.
  ///
  /// If the `AccessState` is `GRANTED` or `NOT_GRANTED`, this field is omitted.
  core.List<GoogleCloudPolicysimulatorV1ExplainedPolicy>? policies;

  GoogleCloudPolicysimulatorV1ExplainedAccess();

  GoogleCloudPolicysimulatorV1ExplainedAccess.fromJson(core.Map _json) {
    if (_json.containsKey('accessState')) {
      accessState = _json['accessState'] as core.String;
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('policies')) {
      policies = (_json['policies'] as core.List)
          .map<GoogleCloudPolicysimulatorV1ExplainedPolicy>((value) =>
              GoogleCloudPolicysimulatorV1ExplainedPolicy.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessState != null) 'accessState': accessState!,
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (policies != null)
          'policies': policies!.map((value) => value.toJson()).toList(),
      };
}

/// Details about how a specific IAM Policy contributed to the access check.
class GoogleCloudPolicysimulatorV1ExplainedPolicy {
  /// Indicates whether _this policy_ provides the specified permission to the
  /// specified member for the specified resource.
  ///
  /// This field does _not_ indicate whether the member actually has the
  /// permission for the resource. There might be another policy that overrides
  /// this policy. To determine whether the member actually has the permission,
  /// use the `access` field in the TroubleshootIamPolicyResponse.
  /// Possible string values are:
  /// - "ACCESS_STATE_UNSPECIFIED" : The access state is not specified.
  /// - "GRANTED" : The member has the permission.
  /// - "NOT_GRANTED" : The member does not have the permission.
  /// - "UNKNOWN_CONDITIONAL" : The member has the permission only if a
  /// condition expression evaluates to `true`.
  /// - "UNKNOWN_INFO_DENIED" : The user who created the Replay does not have
  /// access to all of the policies that Policy Simulator needs to evaluate.
  core.String? access;

  /// Details about how each binding in the policy affects the member's ability,
  /// or inability, to use the permission for the resource.
  ///
  /// If the user who created the Replay does not have access to the policy,
  /// this field is omitted.
  core.List<GoogleCloudPolicysimulatorV1BindingExplanation>?
      bindingExplanations;

  /// The full resource name that identifies the resource.
  ///
  /// For example,
  /// `//compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/my-instance`.
  /// If the user who created the Replay does not have access to the policy,
  /// this field is omitted. For examples of full resource names for Google
  /// Cloud services, see
  /// https://cloud.google.com/iam/help/troubleshooter/full-resource-names.
  core.String? fullResourceName;

  /// The IAM policy attached to the resource.
  ///
  /// If the user who created the Replay does not have access to the policy,
  /// this field is empty.
  GoogleIamV1Policy? policy;

  /// The relevance of this policy to the overall determination in the
  /// TroubleshootIamPolicyResponse.
  ///
  /// If the user who created the Replay does not have access to the policy,
  /// this field is omitted.
  /// Possible string values are:
  /// - "HEURISTIC_RELEVANCE_UNSPECIFIED" : Reserved for future use.
  /// - "NORMAL" : The data point has a limited effect on the result. Changing
  /// the data point is unlikely to affect the overall determination.
  /// - "HIGH" : The data point has a strong effect on the result. Changing the
  /// data point is likely to affect the overall determination.
  core.String? relevance;

  GoogleCloudPolicysimulatorV1ExplainedPolicy();

  GoogleCloudPolicysimulatorV1ExplainedPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('access')) {
      access = _json['access'] as core.String;
    }
    if (_json.containsKey('bindingExplanations')) {
      bindingExplanations = (_json['bindingExplanations'] as core.List)
          .map<GoogleCloudPolicysimulatorV1BindingExplanation>((value) =>
              GoogleCloudPolicysimulatorV1BindingExplanation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fullResourceName')) {
      fullResourceName = _json['fullResourceName'] as core.String;
    }
    if (_json.containsKey('policy')) {
      policy = GoogleIamV1Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('relevance')) {
      relevance = _json['relevance'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (access != null) 'access': access!,
        if (bindingExplanations != null)
          'bindingExplanations':
              bindingExplanations!.map((value) => value.toJson()).toList(),
        if (fullResourceName != null) 'fullResourceName': fullResourceName!,
        if (policy != null) 'policy': policy!.toJson(),
        if (relevance != null) 'relevance': relevance!,
      };
}

/// Response message for Simulator.ListReplayResults.
class GoogleCloudPolicysimulatorV1ListReplayResultsResponse {
  /// A token that you can use to retrieve the next page of ReplayResult
  /// objects.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The results of running a Replay.
  core.List<GoogleCloudPolicysimulatorV1ReplayResult>? replayResults;

  GoogleCloudPolicysimulatorV1ListReplayResultsResponse();

  GoogleCloudPolicysimulatorV1ListReplayResultsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('replayResults')) {
      replayResults = (_json['replayResults'] as core.List)
          .map<GoogleCloudPolicysimulatorV1ReplayResult>((value) =>
              GoogleCloudPolicysimulatorV1ReplayResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (replayResults != null)
          'replayResults':
              replayResults!.map((value) => value.toJson()).toList(),
      };
}

/// A resource describing a `Replay`, or simulation.
class GoogleCloudPolicysimulatorV1Replay {
  /// The configuration used for the `Replay`.
  ///
  /// Required.
  GoogleCloudPolicysimulatorV1ReplayConfig? config;

  /// The resource name of the `Replay`, which has the following format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`,
  /// where `{resource-id}` is the ID of the project, folder, or organization
  /// that owns the Replay.
  ///
  /// Example:
  /// `projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  ///
  /// Output only.
  core.String? name;

  /// Summary statistics about the replayed log entries.
  ///
  /// Output only.
  GoogleCloudPolicysimulatorV1ReplayResultsSummary? resultsSummary;

  /// The current state of the `Replay`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The state is unspecified.
  /// - "PENDING" : The `Replay` has not started yet.
  /// - "RUNNING" : The `Replay` is currently running.
  /// - "SUCCEEDED" : The `Replay` has successfully completed.
  /// - "FAILED" : The `Replay` has finished with an error.
  core.String? state;

  GoogleCloudPolicysimulatorV1Replay();

  GoogleCloudPolicysimulatorV1Replay.fromJson(core.Map _json) {
    if (_json.containsKey('config')) {
      config = GoogleCloudPolicysimulatorV1ReplayConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('resultsSummary')) {
      resultsSummary =
          GoogleCloudPolicysimulatorV1ReplayResultsSummary.fromJson(
              _json['resultsSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (config != null) 'config': config!.toJson(),
        if (name != null) 'name': name!,
        if (resultsSummary != null) 'resultsSummary': resultsSummary!.toJson(),
        if (state != null) 'state': state!,
      };
}

/// The configuration used for a Replay.
class GoogleCloudPolicysimulatorV1ReplayConfig {
  /// The logs to use as input for the Replay.
  /// Possible string values are:
  /// - "LOG_SOURCE_UNSPECIFIED" : An unspecified log source. If the log source
  /// is unspecified, the Replay defaults to using `RECENT_ACCESSES`.
  /// - "RECENT_ACCESSES" : All access logs from the last 90 days. These logs
  /// may not include logs from the most recent 7 days.
  core.String? logSource;

  /// A mapping of the resources that you want to simulate policies for and the
  /// policies that you want to simulate.
  ///
  /// Keys are the full resource names for the resources. For example,
  /// `//cloudresourcemanager.googleapis.com/projects/my-project`. For examples
  /// of full resource names for Google Cloud services, see
  /// https://cloud.google.com/iam/help/troubleshooter/full-resource-names.
  /// Values are Policy objects representing the policies that you want to
  /// simulate. Replays automatically take into account any IAM policies
  /// inherited through the resource hierarchy, and any policies set on
  /// descendant resources. You do not need to include these policies in the
  /// policy overlay.
  core.Map<core.String, GoogleIamV1Policy>? policyOverlay;

  GoogleCloudPolicysimulatorV1ReplayConfig();

  GoogleCloudPolicysimulatorV1ReplayConfig.fromJson(core.Map _json) {
    if (_json.containsKey('logSource')) {
      logSource = _json['logSource'] as core.String;
    }
    if (_json.containsKey('policyOverlay')) {
      policyOverlay =
          (_json['policyOverlay'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleIamV1Policy.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logSource != null) 'logSource': logSource!,
        if (policyOverlay != null)
          'policyOverlay': policyOverlay!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// The difference between the results of evaluating an access tuple under the
/// current (baseline) policies and under the proposed (simulated) policies.
///
/// This difference explains how a member's access could change if the proposed
/// policies were applied.
class GoogleCloudPolicysimulatorV1ReplayDiff {
  /// A summary and comparison of the member's access under the current
  /// (baseline) policies and the proposed (simulated) policies for a single
  /// access tuple.
  ///
  /// The evaluation of the member's access is reported in the AccessState
  /// field.
  GoogleCloudPolicysimulatorV1AccessStateDiff? accessDiff;

  GoogleCloudPolicysimulatorV1ReplayDiff();

  GoogleCloudPolicysimulatorV1ReplayDiff.fromJson(core.Map _json) {
    if (_json.containsKey('accessDiff')) {
      accessDiff = GoogleCloudPolicysimulatorV1AccessStateDiff.fromJson(
          _json['accessDiff'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessDiff != null) 'accessDiff': accessDiff!.toJson(),
      };
}

/// Metadata about a Replay operation.
class GoogleCloudPolicysimulatorV1ReplayOperationMetadata {
  /// Time when the request was received.
  core.String? startTime;

  GoogleCloudPolicysimulatorV1ReplayOperationMetadata();

  GoogleCloudPolicysimulatorV1ReplayOperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (startTime != null) 'startTime': startTime!,
      };
}

/// The result of replaying a single access tuple against a simulated state.
class GoogleCloudPolicysimulatorV1ReplayResult {
  /// The access tuple that was replayed.
  ///
  /// This field includes information about the member, resource, and permission
  /// that were involved in the access attempt.
  GoogleCloudPolicysimulatorV1AccessTuple? accessTuple;

  /// The difference between the member's access under the current (baseline)
  /// policies and the member's access under the proposed (simulated) policies.
  ///
  /// This field is only included for access tuples that were successfully
  /// replayed and had different results under the current policies and the
  /// proposed policies.
  GoogleCloudPolicysimulatorV1ReplayDiff? diff;

  /// The error that caused the access tuple replay to fail.
  ///
  /// This field is only included for access tuples that were not replayed
  /// successfully.
  GoogleRpcStatus? error;

  /// The latest date this access tuple was seen in the logs.
  GoogleTypeDate? lastSeenDate;

  /// The resource name of the `ReplayResult`, in the following format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}/results/{replay-result-id}`,
  /// where `{resource-id}` is the ID of the project, folder, or organization
  /// that owns the Replay.
  ///
  /// Example:
  /// `projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36/results/1234`
  core.String? name;

  /// The Replay that the access tuple was included in.
  core.String? parent;

  GoogleCloudPolicysimulatorV1ReplayResult();

  GoogleCloudPolicysimulatorV1ReplayResult.fromJson(core.Map _json) {
    if (_json.containsKey('accessTuple')) {
      accessTuple = GoogleCloudPolicysimulatorV1AccessTuple.fromJson(
          _json['accessTuple'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diff')) {
      diff = GoogleCloudPolicysimulatorV1ReplayDiff.fromJson(
          _json['diff'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lastSeenDate')) {
      lastSeenDate = GoogleTypeDate.fromJson(
          _json['lastSeenDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessTuple != null) 'accessTuple': accessTuple!.toJson(),
        if (diff != null) 'diff': diff!.toJson(),
        if (error != null) 'error': error!.toJson(),
        if (lastSeenDate != null) 'lastSeenDate': lastSeenDate!.toJson(),
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
      };
}

/// Summary statistics about the replayed log entries.
class GoogleCloudPolicysimulatorV1ReplayResultsSummary {
  /// The number of replayed log entries with a difference between baseline and
  /// simulated policies.
  core.int? differenceCount;

  /// The number of log entries that could not be replayed.
  core.int? errorCount;

  /// The total number of log entries replayed.
  core.int? logCount;

  /// The date of the newest log entry replayed.
  GoogleTypeDate? newestDate;

  /// The date of the oldest log entry replayed.
  GoogleTypeDate? oldestDate;

  /// The number of replayed log entries with no difference between baseline and
  /// simulated policies.
  core.int? unchangedCount;

  GoogleCloudPolicysimulatorV1ReplayResultsSummary();

  GoogleCloudPolicysimulatorV1ReplayResultsSummary.fromJson(core.Map _json) {
    if (_json.containsKey('differenceCount')) {
      differenceCount = _json['differenceCount'] as core.int;
    }
    if (_json.containsKey('errorCount')) {
      errorCount = _json['errorCount'] as core.int;
    }
    if (_json.containsKey('logCount')) {
      logCount = _json['logCount'] as core.int;
    }
    if (_json.containsKey('newestDate')) {
      newestDate = GoogleTypeDate.fromJson(
          _json['newestDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('oldestDate')) {
      oldestDate = GoogleTypeDate.fromJson(
          _json['oldestDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unchangedCount')) {
      unchangedCount = _json['unchangedCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (differenceCount != null) 'differenceCount': differenceCount!,
        if (errorCount != null) 'errorCount': errorCount!,
        if (logCount != null) 'logCount': logCount!,
        if (newestDate != null) 'newestDate': newestDate!.toJson(),
        if (oldestDate != null) 'oldestDate': oldestDate!.toJson(),
        if (unchangedCount != null) 'unchangedCount': unchangedCount!,
      };
}

/// A resource describing a `Replay`, or simulation.
class GoogleCloudPolicysimulatorV1beta1Replay {
  /// The configuration used for the `Replay`.
  ///
  /// Required.
  GoogleCloudPolicysimulatorV1beta1ReplayConfig? config;

  /// The resource name of the `Replay`, which has the following format:
  /// `{projects|folders|organizations}/{resource-id}/locations/global/replays/{replay-id}`,
  /// where `{resource-id}` is the ID of the project, folder, or organization
  /// that owns the Replay.
  ///
  /// Example:
  /// `projects/my-example-project/locations/global/replays/506a5f7f-38ce-4d7d-8e03-479ce1833c36`
  ///
  /// Output only.
  core.String? name;

  /// Summary statistics about the replayed log entries.
  ///
  /// Output only.
  GoogleCloudPolicysimulatorV1beta1ReplayResultsSummary? resultsSummary;

  /// The current state of the `Replay`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The state is unspecified.
  /// - "PENDING" : The `Replay` has not started yet.
  /// - "RUNNING" : The `Replay` is currently running.
  /// - "SUCCEEDED" : The `Replay` has successfully completed.
  /// - "FAILED" : The `Replay` has finished with an error.
  core.String? state;

  GoogleCloudPolicysimulatorV1beta1Replay();

  GoogleCloudPolicysimulatorV1beta1Replay.fromJson(core.Map _json) {
    if (_json.containsKey('config')) {
      config = GoogleCloudPolicysimulatorV1beta1ReplayConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('resultsSummary')) {
      resultsSummary =
          GoogleCloudPolicysimulatorV1beta1ReplayResultsSummary.fromJson(
              _json['resultsSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (config != null) 'config': config!.toJson(),
        if (name != null) 'name': name!,
        if (resultsSummary != null) 'resultsSummary': resultsSummary!.toJson(),
        if (state != null) 'state': state!,
      };
}

/// The configuration used for a Replay.
class GoogleCloudPolicysimulatorV1beta1ReplayConfig {
  /// The logs to use as input for the Replay.
  /// Possible string values are:
  /// - "LOG_SOURCE_UNSPECIFIED" : An unspecified log source. If the log source
  /// is unspecified, the Replay defaults to using `RECENT_ACCESSES`.
  /// - "RECENT_ACCESSES" : All access logs from the last 90 days. These logs
  /// may not include logs from the most recent 7 days.
  core.String? logSource;

  /// A mapping of the resources that you want to simulate policies for and the
  /// policies that you want to simulate.
  ///
  /// Keys are the full resource names for the resources. For example,
  /// `//cloudresourcemanager.googleapis.com/projects/my-project`. For examples
  /// of full resource names for Google Cloud services, see
  /// https://cloud.google.com/iam/help/troubleshooter/full-resource-names.
  /// Values are Policy objects representing the policies that you want to
  /// simulate. Replays automatically take into account any IAM policies
  /// inherited through the resource hierarchy, and any policies set on
  /// descendant resources. You do not need to include these policies in the
  /// policy overlay.
  core.Map<core.String, GoogleIamV1Policy>? policyOverlay;

  GoogleCloudPolicysimulatorV1beta1ReplayConfig();

  GoogleCloudPolicysimulatorV1beta1ReplayConfig.fromJson(core.Map _json) {
    if (_json.containsKey('logSource')) {
      logSource = _json['logSource'] as core.String;
    }
    if (_json.containsKey('policyOverlay')) {
      policyOverlay =
          (_json['policyOverlay'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleIamV1Policy.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logSource != null) 'logSource': logSource!,
        if (policyOverlay != null)
          'policyOverlay': policyOverlay!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// Metadata about a Replay operation.
class GoogleCloudPolicysimulatorV1beta1ReplayOperationMetadata {
  /// Time when the request was received.
  core.String? startTime;

  GoogleCloudPolicysimulatorV1beta1ReplayOperationMetadata();

  GoogleCloudPolicysimulatorV1beta1ReplayOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Summary statistics about the replayed log entries.
class GoogleCloudPolicysimulatorV1beta1ReplayResultsSummary {
  /// The number of replayed log entries with a difference between baseline and
  /// simulated policies.
  core.int? differenceCount;

  /// The number of log entries that could not be replayed.
  core.int? errorCount;

  /// The total number of log entries replayed.
  core.int? logCount;

  /// The date of the newest log entry replayed.
  GoogleTypeDate? newestDate;

  /// The date of the oldest log entry replayed.
  GoogleTypeDate? oldestDate;

  /// The number of replayed log entries with no difference between baseline and
  /// simulated policies.
  core.int? unchangedCount;

  GoogleCloudPolicysimulatorV1beta1ReplayResultsSummary();

  GoogleCloudPolicysimulatorV1beta1ReplayResultsSummary.fromJson(
      core.Map _json) {
    if (_json.containsKey('differenceCount')) {
      differenceCount = _json['differenceCount'] as core.int;
    }
    if (_json.containsKey('errorCount')) {
      errorCount = _json['errorCount'] as core.int;
    }
    if (_json.containsKey('logCount')) {
      logCount = _json['logCount'] as core.int;
    }
    if (_json.containsKey('newestDate')) {
      newestDate = GoogleTypeDate.fromJson(
          _json['newestDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('oldestDate')) {
      oldestDate = GoogleTypeDate.fromJson(
          _json['oldestDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unchangedCount')) {
      unchangedCount = _json['unchangedCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (differenceCount != null) 'differenceCount': differenceCount!,
        if (errorCount != null) 'errorCount': errorCount!,
        if (logCount != null) 'logCount': logCount!,
        if (newestDate != null) 'newestDate': newestDate!.toJson(),
        if (oldestDate != null) 'oldestDate': oldestDate!.toJson(),
        if (unchangedCount != null) 'unchangedCount': unchangedCount!,
      };
}

/// Specifies the audit configuration for a service.
///
/// The configuration determines which permission types are logged, and what
/// identities, if any, are exempted from logging. An AuditConfig must have one
/// or more AuditLogConfigs. If there are AuditConfigs for both `allServices`
/// and a specific service, the union of the two AuditConfigs is used for that
/// service: the log_types specified in each AuditConfig are enabled, and the
/// exempted_members in each AuditLogConfig are exempted. Example Policy with
/// multiple AuditConfigs: { "audit_configs": \[ { "service": "allServices",
/// "audit_log_configs": \[ { "log_type": "DATA_READ", "exempted_members": \[
/// "user:jose@example.com" \] }, { "log_type": "DATA_WRITE" }, { "log_type":
/// "ADMIN_READ" } \] }, { "service": "sampleservice.googleapis.com",
/// "audit_log_configs": \[ { "log_type": "DATA_READ" }, { "log_type":
/// "DATA_WRITE", "exempted_members": \[ "user:aliya@example.com" \] } \] } \] }
/// For sampleservice, this policy enables DATA_READ, DATA_WRITE and ADMIN_READ
/// logging. It also exempts jose@example.com from DATA_READ logging, and
/// aliya@example.com from DATA_WRITE logging.
class GoogleIamV1AuditConfig {
  /// The configuration for logging of each type of permission.
  core.List<GoogleIamV1AuditLogConfig>? auditLogConfigs;

  /// Specifies a service that will be enabled for audit logging.
  ///
  /// For example, `storage.googleapis.com`, `cloudsql.googleapis.com`.
  /// `allServices` is a special value that covers all services.
  core.String? service;

  GoogleIamV1AuditConfig();

  GoogleIamV1AuditConfig.fromJson(core.Map _json) {
    if (_json.containsKey('auditLogConfigs')) {
      auditLogConfigs = (_json['auditLogConfigs'] as core.List)
          .map<GoogleIamV1AuditLogConfig>((value) =>
              GoogleIamV1AuditLogConfig.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditLogConfigs != null)
          'auditLogConfigs':
              auditLogConfigs!.map((value) => value.toJson()).toList(),
        if (service != null) 'service': service!,
      };
}

/// Provides the configuration for logging a type of permissions.
///
/// Example: { "audit_log_configs": \[ { "log_type": "DATA_READ",
/// "exempted_members": \[ "user:jose@example.com" \] }, { "log_type":
/// "DATA_WRITE" } \] } This enables 'DATA_READ' and 'DATA_WRITE' logging, while
/// exempting jose@example.com from DATA_READ logging.
class GoogleIamV1AuditLogConfig {
  /// Specifies the identities that do not cause logging for this type of
  /// permission.
  ///
  /// Follows the same format of Binding.members.
  core.List<core.String>? exemptedMembers;

  /// The log type that this config enables.
  /// Possible string values are:
  /// - "LOG_TYPE_UNSPECIFIED" : Default case. Should never be this.
  /// - "ADMIN_READ" : Admin reads. Example: CloudIAM getIamPolicy
  /// - "DATA_WRITE" : Data writes. Example: CloudSQL Users create
  /// - "DATA_READ" : Data reads. Example: CloudSQL Users list
  core.String? logType;

  GoogleIamV1AuditLogConfig();

  GoogleIamV1AuditLogConfig.fromJson(core.Map _json) {
    if (_json.containsKey('exemptedMembers')) {
      exemptedMembers = (_json['exemptedMembers'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('logType')) {
      logType = _json['logType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exemptedMembers != null) 'exemptedMembers': exemptedMembers!,
        if (logType != null) 'logType': logType!,
      };
}

/// Associates `members` with a `role`.
class GoogleIamV1Binding {
  /// The condition that is associated with this binding.
  ///
  /// If the condition evaluates to `true`, then this binding applies to the
  /// current request. If the condition evaluates to `false`, then this binding
  /// does not apply to the current request. However, a different role binding
  /// might grant the same role to one or more of the members in this binding.
  /// To learn which resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  GoogleTypeExpr? condition;

  /// Specifies the identities requesting access for a Cloud Platform resource.
  ///
  /// `members` can have the following values: * `allUsers`: A special
  /// identifier that represents anyone who is on the internet; with or without
  /// a Google account. * `allAuthenticatedUsers`: A special identifier that
  /// represents anyone who is authenticated with a Google account or a service
  /// account. * `user:{emailid}`: An email address that represents a specific
  /// Google account. For example, `alice@example.com` . *
  /// `serviceAccount:{emailid}`: An email address that represents a service
  /// account. For example, `my-other-app@appspot.gserviceaccount.com`. *
  /// `group:{emailid}`: An email address that represents a Google group. For
  /// example, `admins@example.com`. * `deleted:user:{emailid}?uid={uniqueid}`:
  /// An email address (plus unique identifier) representing a user that has
  /// been recently deleted. For example,
  /// `alice@example.com?uid=123456789012345678901`. If the user is recovered,
  /// this value reverts to `user:{emailid}` and the recovered user retains the
  /// role in the binding. * `deleted:serviceAccount:{emailid}?uid={uniqueid}`:
  /// An email address (plus unique identifier) representing a service account
  /// that has been recently deleted. For example,
  /// `my-other-app@appspot.gserviceaccount.com?uid=123456789012345678901`. If
  /// the service account is undeleted, this value reverts to
  /// `serviceAccount:{emailid}` and the undeleted service account retains the
  /// role in the binding. * `deleted:group:{emailid}?uid={uniqueid}`: An email
  /// address (plus unique identifier) representing a Google group that has been
  /// recently deleted. For example,
  /// `admins@example.com?uid=123456789012345678901`. If the group is recovered,
  /// this value reverts to `group:{emailid}` and the recovered group retains
  /// the role in the binding. * `domain:{domain}`: The G Suite domain (primary)
  /// that represents all the users of that domain. For example, `google.com` or
  /// `example.com`.
  core.List<core.String>? members;

  /// Role that is assigned to `members`.
  ///
  /// For example, `roles/viewer`, `roles/editor`, or `roles/owner`.
  core.String? role;

  GoogleIamV1Binding();

  GoogleIamV1Binding.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = GoogleTypeExpr.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (members != null) 'members': members!,
        if (role != null) 'role': role!,
      };
}

/// An Identity and Access Management (IAM) policy, which specifies access
/// controls for Google Cloud resources.
///
/// A `Policy` is a collection of `bindings`. A `binding` binds one or more
/// `members` to a single `role`. Members can be user accounts, service
/// accounts, Google groups, and domains (such as G Suite). A `role` is a named
/// list of permissions; each `role` can be an IAM predefined role or a
/// user-created custom role. For some types of Google Cloud resources, a
/// `binding` can also specify a `condition`, which is a logical expression that
/// allows access to a resource only if the expression evaluates to `true`. A
/// condition can add constraints based on attributes of the request, the
/// resource, or both. To learn which resources support conditions in their IAM
/// policies, see the
/// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
/// **JSON example:** { "bindings": \[ { "role":
/// "roles/resourcemanager.organizationAdmin", "members": \[
/// "user:mike@example.com", "group:admins@example.com", "domain:google.com",
/// "serviceAccount:my-project-id@appspot.gserviceaccount.com" \] }, { "role":
/// "roles/resourcemanager.organizationViewer", "members": \[
/// "user:eve@example.com" \], "condition": { "title": "expirable access",
/// "description": "Does not grant access after Sep 2020", "expression":
/// "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } \], "etag":
/// "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: -
/// user:mike@example.com - group:admins@example.com - domain:google.com -
/// serviceAccount:my-project-id@appspot.gserviceaccount.com role:
/// roles/resourcemanager.organizationAdmin - members: - user:eve@example.com
/// role: roles/resourcemanager.organizationViewer condition: title: expirable
/// access description: Does not grant access after Sep 2020 expression:
/// request.time < timestamp('2020-10-01T00:00:00.000Z') - etag: BwWWja0YfJA= -
/// version: 3 For a description of IAM and its features, see the
/// [IAM documentation](https://cloud.google.com/iam/docs/).
class GoogleIamV1Policy {
  /// Specifies cloud audit logging configuration for this policy.
  core.List<GoogleIamV1AuditConfig>? auditConfigs;

  /// Associates a list of `members` to a `role`.
  ///
  /// Optionally, may specify a `condition` that determines how and when the
  /// `bindings` are applied. Each of the `bindings` must contain at least one
  /// member.
  core.List<GoogleIamV1Binding>? bindings;

  /// `etag` is used for optimistic concurrency control as a way to help prevent
  /// simultaneous updates of a policy from overwriting each other.
  ///
  /// It is strongly suggested that systems make use of the `etag` in the
  /// read-modify-write cycle to perform policy updates in order to avoid race
  /// conditions: An `etag` is returned in the response to `getIamPolicy`, and
  /// systems are expected to put that etag in the request to `setIamPolicy` to
  /// ensure that their change will be applied to the same version of the
  /// policy. **Important:** If you use IAM Conditions, you must include the
  /// `etag` field whenever you call `setIamPolicy`. If you omit this field,
  /// then IAM allows you to overwrite a version `3` policy with a version `1`
  /// policy, and all of the conditions in the version `3` policy are lost.
  core.String? etag;
  core.List<core.int> get etagAsBytes => convert.base64.decode(etag!);

  set etagAsBytes(core.List<core.int> _bytes) {
    etag =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Specifies the format of the policy.
  ///
  /// Valid values are `0`, `1`, and `3`. Requests that specify an invalid value
  /// are rejected. Any operation that affects conditional role bindings must
  /// specify version `3`. This requirement applies to the following operations:
  /// * Getting a policy that includes a conditional role binding * Adding a
  /// conditional role binding to a policy * Changing a conditional role binding
  /// in a policy * Removing any role binding, with or without a condition, from
  /// a policy that includes conditions **Important:** If you use IAM
  /// Conditions, you must include the `etag` field whenever you call
  /// `setIamPolicy`. If you omit this field, then IAM allows you to overwrite a
  /// version `3` policy with a version `1` policy, and all of the conditions in
  /// the version `3` policy are lost. If a policy does not include any
  /// conditions, operations on that policy may specify any valid version or
  /// leave the field unset. To learn which resources support conditions in
  /// their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  core.int? version;

  GoogleIamV1Policy();

  GoogleIamV1Policy.fromJson(core.Map _json) {
    if (_json.containsKey('auditConfigs')) {
      auditConfigs = (_json['auditConfigs'] as core.List)
          .map<GoogleIamV1AuditConfig>((value) =>
              GoogleIamV1AuditConfig.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('bindings')) {
      bindings = (_json['bindings'] as core.List)
          .map<GoogleIamV1Binding>((value) => GoogleIamV1Binding.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditConfigs != null)
          'auditConfigs': auditConfigs!.map((value) => value.toJson()).toList(),
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (version != null) 'version': version!,
      };
}

/// The response message for Operations.ListOperations.
class GoogleLongrunningListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<GoogleLongrunningOperation>? operations;

  GoogleLongrunningListOperationsResponse();

  GoogleLongrunningListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleLongrunningOperation>((value) =>
              GoogleLongrunningOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class GoogleLongrunningOperation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  GoogleRpcStatus? error;

  /// Service-specific metadata associated with the operation.
  ///
  /// It typically contains progress information and common metadata such as
  /// create time. Some services might not provide such metadata. Any method
  /// that returns a long-running operation should document the metadata type,
  /// if any.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// The server-assigned name, which is only unique within the same service
  /// that originally returns it.
  ///
  /// If you use the default HTTP mapping, the `name` should be a resource name
  /// ending with `operations/{unique_id}`.
  core.String? name;

  /// The normal response of the operation in case of success.
  ///
  /// If the original method returns no data on success, such as `Delete`, the
  /// response is `google.protobuf.Empty`. If the original method is standard
  /// `Get`/`Create`/`Update`, the response should be the resource. For other
  /// methods, the response should have the type `XxxResponse`, where `Xxx` is
  /// the original method name. For example, if the original method name is
  /// `TakeSnapshot()`, the inferred response type is `TakeSnapshotResponse`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? response;

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('response')) {
      response = (_json['response'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (done != null) 'done': done!,
        if (error != null) 'error': error!.toJson(),
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
        if (response != null) 'response': response!,
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class GoogleRpcStatus {
  /// The status code, which should be an enum value of google.rpc.Code.
  core.int? code;

  /// A list of messages that carry the error details.
  ///
  /// There is a common set of message types for APIs to use.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? details;

  /// A developer-facing error message, which should be in English.
  ///
  /// Any user-facing error message should be localized and sent in the
  /// google.rpc.Status.details field, or localized by the client.
  core.String? message;

  GoogleRpcStatus();

  GoogleRpcStatus.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.int;
    }
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (details != null) 'details': details!,
        if (message != null) 'message': message!,
      };
}

/// Represents a whole or partial calendar date, such as a birthday.
///
/// The time of day and time zone are either specified elsewhere or are
/// insignificant. The date is relative to the Gregorian Calendar. This can
/// represent one of the following: * A full date, with non-zero year, month,
/// and day values * A month and day value, with a zero year, such as an
/// anniversary * A year on its own, with zero month and day values * A year and
/// month value, with a zero day, such as a credit card expiration date Related
/// types are google.type.TimeOfDay and `google.protobuf.Timestamp`.
class GoogleTypeDate {
  /// Day of a month.
  ///
  /// Must be from 1 to 31 and valid for the year and month, or 0 to specify a
  /// year by itself or a year and month where the day isn't significant.
  core.int? day;

  /// Month of a year.
  ///
  /// Must be from 1 to 12, or 0 to specify a year without a month and day.
  core.int? month;

  /// Year of the date.
  ///
  /// Must be from 1 to 9999, or 0 to specify a date without a year.
  core.int? year;

  GoogleTypeDate();

  GoogleTypeDate.fromJson(core.Map _json) {
    if (_json.containsKey('day')) {
      day = _json['day'] as core.int;
    }
    if (_json.containsKey('month')) {
      month = _json['month'] as core.int;
    }
    if (_json.containsKey('year')) {
      year = _json['year'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (day != null) 'day': day!,
        if (month != null) 'month': month!,
        if (year != null) 'year': year!,
      };
}

/// Represents a textual expression in the Common Expression Language (CEL)
/// syntax.
///
/// CEL is a C-like expression language. The syntax and semantics of CEL are
/// documented at https://github.com/google/cel-spec. Example (Comparison):
/// title: "Summary size limit" description: "Determines if a summary is less
/// than 100 chars" expression: "document.summary.size() < 100" Example
/// (Equality): title: "Requestor is owner" description: "Determines if
/// requestor is the document owner" expression: "document.owner ==
/// request.auth.claims.email" Example (Logic): title: "Public documents"
/// description: "Determine whether the document should be publicly visible"
/// expression: "document.type != 'private' && document.type != 'internal'"
/// Example (Data Manipulation): title: "Notification string" description:
/// "Create a notification string with a timestamp." expression: "'New message
/// received at ' + string(document.create_time)" The exact variables and
/// functions that may be referenced within an expression are determined by the
/// service that evaluates it. See the service documentation for additional
/// information.
class GoogleTypeExpr {
  /// Description of the expression.
  ///
  /// This is a longer text which describes the expression, e.g. when hovered
  /// over it in a UI.
  ///
  /// Optional.
  core.String? description;

  /// Textual representation of an expression in Common Expression Language
  /// syntax.
  core.String? expression;

  /// String indicating the location of the expression for error reporting, e.g.
  /// a file name and a position in the file.
  ///
  /// Optional.
  core.String? location;

  /// Title for the expression, i.e. a short string describing its purpose.
  ///
  /// This can be used e.g. in UIs which allow to enter the expression.
  ///
  /// Optional.
  core.String? title;

  GoogleTypeExpr();

  GoogleTypeExpr.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('expression')) {
      expression = _json['expression'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (expression != null) 'expression': expression!,
        if (location != null) 'location': location!,
        if (title != null) 'title': title!,
      };
}

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

/// Game Services API - v1
///
/// Deploy and manage infrastructure for global multiplayer gaming experiences.
///
/// For more information, see <https://cloud.google.com/solutions/gaming/>
///
/// Create an instance of [GameServicesApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsGameServerDeploymentsResource]
///       - [ProjectsLocationsGameServerDeploymentsConfigsResource]
///     - [ProjectsLocationsOperationsResource]
///     - [ProjectsLocationsRealmsResource]
///       - [ProjectsLocationsRealmsGameServerClustersResource]
library gameservices.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Deploy and manage infrastructure for global multiplayer gaming experiences.
class GameServicesApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  GameServicesApi(http.Client client,
      {core.String rootUrl = 'https://gameservices.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsGameServerDeploymentsResource get gameServerDeployments =>
      ProjectsLocationsGameServerDeploymentsResource(_requester);
  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);
  ProjectsLocationsRealmsResource get realms =>
      ProjectsLocationsRealmsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about a location.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the location.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Location].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Location> get(
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
    return Location.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists information about the supported locations for this service.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource that owns the locations collection, if applicable.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [filter] - A filter to narrow down results to a preferred subset. The
  /// filtering language accepts strings like "displayName=tokyo", and is
  /// documented in more detail in \[AIP-160\](https://google.aip.dev/160).
  ///
  /// [includeUnrevealedLocations] - If true, the returned list will include
  /// locations which are not yet revealed.
  ///
  /// [pageSize] - The maximum number of results to return. If not set, the
  /// service selects a default.
  ///
  /// [pageToken] - A page token received from the `next_page_token` field in
  /// the response. Send that page token to receive the subsequent page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLocationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLocationsResponse> list(
    core.String name, {
    core.String? filter,
    core.bool? includeUnrevealedLocations,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (includeUnrevealedLocations != null)
        'includeUnrevealedLocations': ['${includeUnrevealedLocations}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/locations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsGameServerDeploymentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsGameServerDeploymentsConfigsResource get configs =>
      ProjectsLocationsGameServerDeploymentsConfigsResource(_requester);

  ProjectsLocationsGameServerDeploymentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new game server deployment in a given project and location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [deploymentId] - Required. The ID of the game server delpoyment resource
  /// to be created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    GameServerDeployment request,
    core.String parent, {
    core.String? deploymentId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (deploymentId != null) 'deploymentId': [deploymentId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/gameServerDeployments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a single game server deployment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server delpoyment to delete, in
  /// the following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves information about the current state of the game server
  /// deployment.
  ///
  /// Gathers all the Agones fleets and Agones autoscalers, including fleets
  /// running an older version of the game server deployment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server delpoyment, in the
  /// following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FetchDeploymentStateResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FetchDeploymentStateResponse> fetchDeploymentState(
    FetchDeploymentStateRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':fetchDeploymentState';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return FetchDeploymentStateResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets details of a single game server deployment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server delpoyment to retrieve, in
  /// the following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GameServerDeployment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GameServerDeployment> get(
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
    return GameServerDeployment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [options_requestedPolicyVersion] - Optional. The policy format version to
  /// be returned. Valid values are 0, 1, and 3. Requests specifying an invalid
  /// value will be rejected. Requests for policies with any conditional
  /// bindings must specify version 3. Policies without any conditional bindings
  /// may specify any valid value or leave the field unset. To learn which
  /// resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> getIamPolicy(
    core.String resource, {
    core.int? options_requestedPolicyVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (options_requestedPolicyVersion != null)
        'options.requestedPolicyVersion': ['${options_requestedPolicyVersion}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets details a single game server deployment rollout.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server delpoyment to retrieve, in
  /// the following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/rollout`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GameServerDeploymentRollout].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GameServerDeploymentRollout> getRollout(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/rollout';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GameServerDeploymentRollout.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists game server deployments in a given project and location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - Optional. The filter to apply to list results.
  ///
  /// [orderBy] - Optional. Specifies the ordering of results following syntax
  /// at https://cloud.google.com/apis/design/design_patterns#sorting_order.
  ///
  /// [pageSize] - Optional. The maximum number of items to return. If
  /// unspecified, the server will pick an appropriate default. The server may
  /// return fewer items than requested. A caller should only rely on response's
  /// next_page_token to determine if there are more GameServerDeployments left
  /// to be queried.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a previous
  /// List request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListGameServerDeploymentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListGameServerDeploymentsResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/gameServerDeployments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListGameServerDeploymentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a game server deployment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the game server deployment, in the following
  /// form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}`.
  /// For example,
  /// `projects/my-project/locations/global/gameServerDeployments/my-deployment`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask of fields to update. At least one path must
  /// be supplied in this field. For the `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> patch(
    GameServerDeployment request,
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
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Previews the game server deployment rollout.
  ///
  /// This API does not mutate the rollout resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the game server deployment rollout, in the
  /// following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/rollout`.
  /// For example,
  /// `projects/my-project/locations/global/gameServerDeployments/my-deployment/rollout`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [previewTime] - Optional. The target timestamp to compute the preview.
  /// Defaults to the immediately after the proposed rollout completes.
  ///
  /// [updateMask] - Optional. Mask of fields to update. At least one path must
  /// be supplied in this field. For the `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PreviewGameServerDeploymentRolloutResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PreviewGameServerDeploymentRolloutResponse> previewRollout(
    GameServerDeploymentRollout request,
    core.String name, {
    core.String? previewTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (previewTime != null) 'previewTime': [previewTime],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/rollout:preview';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return PreviewGameServerDeploymentRolloutResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified resource.
  ///
  /// Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`,
  /// and `PERMISSION_DENIED` errors.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> setIamPolicy(
    SetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified resource.
  ///
  /// If the resource does not exist, this will return an empty set of
  /// permissions, not a `NOT_FOUND` error. Note: This operation is designed to
  /// be used for building permission-aware UIs and command-line tools, not for
  /// authorization checking. This operation may "fail open" without warning.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestIamPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestIamPermissionsResponse> testIamPermissions(
    TestIamPermissionsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a single game server deployment rollout.
  ///
  /// The method will not return an error if the update does not affect any
  /// existing realms. For example - if the default_game_server_config is
  /// changed but all existing realms use the override, that is valid.
  /// Similarly, if a non existing realm is explicitly called out in
  /// game_server_config_overrides field, that will also not result in an error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the game server deployment rollout, in the
  /// following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/rollout`.
  /// For example,
  /// `projects/my-project/locations/global/gameServerDeployments/my-deployment/rollout`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask of fields to update. At least one path must
  /// be supplied in this field. For the `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> updateRollout(
    GameServerDeploymentRollout request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/rollout';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsGameServerDeploymentsConfigsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsGameServerDeploymentsConfigsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Creates a new game server config in a given project, location, and game
  /// server deployment.
  ///
  /// Game server configs are immutable, and are not applied until referenced in
  /// the game server deployment rollout resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [configId] - Required. The ID of the game server config resource to be
  /// created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    GameServerConfig request,
    core.String parent, {
    core.String? configId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (configId != null) 'configId': [configId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/configs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a single game server config.
  ///
  /// The deletion will fail if the game server config is referenced in a game
  /// server deployment rollout.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server config to delete, in the
  /// following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/configs/{config}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+/configs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets details of a single game server config.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server config to retrieve, in the
  /// following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/configs/{config}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+/configs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GameServerConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GameServerConfig> get(
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
    return GameServerConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists game server configs in a given project, location, and game server
  /// deployment.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/configs
  /// / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/gameServerDeployments/\[^/\]+$`.
  ///
  /// [filter] - Optional. The filter to apply to list results.
  ///
  /// [orderBy] - Optional. Specifies the ordering of results following syntax
  /// at https://cloud.google.com/apis/design/design_patterns#sorting_order.
  ///
  /// [pageSize] - Optional. The maximum number of items to return. If
  /// unspecified, server will pick an appropriate default. Server may return
  /// fewer items than requested. A caller should only rely on response's
  /// next_page_token to determine if there are more GameServerConfigs left to
  /// be queried.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a previous
  /// list request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListGameServerConfigsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListGameServerConfigsResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/configs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListGameServerConfigsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Starts asynchronous cancellation on a long-running operation.
  ///
  /// The server makes a best effort to cancel the operation, but success is not
  /// guaranteed. If the server doesn't support this method, it returns
  /// `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation
  /// or other methods to check whether the cancellation succeeded or whether
  /// the operation completed despite cancellation. On successful cancellation,
  /// the operation is not deleted; instead, it becomes an operation with an
  /// Operation.error value with a google.rpc.Status.code of 1, corresponding to
  /// `Code.CANCELLED`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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
  async.Future<Empty> cancel(
    CancelOperationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a long-running operation.
  ///
  /// This method indicates that the client is no longer interested in the
  /// operation result. It does not cancel the operation. If the server doesn't
  /// support this method, it returns `google.rpc.Code.UNIMPLEMENTED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be deleted.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> get(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// [name] - The name of the operation's parent resource.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - The standard list filter.
  ///
  /// [pageSize] - The standard list page size.
  ///
  /// [pageToken] - The standard list page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListOperationsResponse> list(
    core.String name, {
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRealmsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRealmsGameServerClustersResource get gameServerClusters =>
      ProjectsLocationsRealmsGameServerClustersResource(_requester);

  ProjectsLocationsRealmsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new realm in a given project and location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [realmId] - Required. The ID of the realm resource to be created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    Realm request,
    core.String parent, {
    core.String? realmId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (realmId != null) 'realmId': [realmId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/realms';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a single realm.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the realm to delete, in the following form:
  /// `projects/{project}/locations/{location}/realms/{realm}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets details of a single realm.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the realm to retrieve, in the following
  /// form: `projects/{project}/locations/{location}/realms/{realm}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Realm].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Realm> get(
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
    return Realm.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists realms in a given project and location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - Optional. The filter to apply to list results.
  ///
  /// [orderBy] - Optional. Specifies the ordering of results following syntax
  /// at https://cloud.google.com/apis/design/design_patterns#sorting_order.
  ///
  /// [pageSize] - Optional. The maximum number of items to return. If
  /// unspecified, server will pick an appropriate default. Server may return
  /// fewer items than requested. A caller should only rely on response's
  /// next_page_token to determine if there are more realms left to be queried.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a previous
  /// List request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRealmsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRealmsResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/realms';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRealmsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a single realm.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the realm, in the following form:
  /// `projects/{project}/locations/{location}/realms/{realm}`. For example,
  /// `projects/my-project/locations/{location}/realms/my-realm`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The update mask applies to the resource. For the
  /// `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> patch(
    Realm request,
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
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Previews patches to a single realm.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the realm, in the following form:
  /// `projects/{project}/locations/{location}/realms/{realm}`. For example,
  /// `projects/my-project/locations/{location}/realms/my-realm`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+$`.
  ///
  /// [previewTime] - Optional. The target timestamp to compute the preview.
  ///
  /// [updateMask] - Required. The update mask applies to the resource. For the
  /// `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PreviewRealmUpdateResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PreviewRealmUpdateResponse> previewUpdate(
    Realm request,
    core.String name, {
    core.String? previewTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (previewTime != null) 'previewTime': [previewTime],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':previewUpdate';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return PreviewRealmUpdateResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRealmsGameServerClustersResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRealmsGameServerClustersResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new game server cluster in a given project and location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}/realms/{realm-id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+$`.
  ///
  /// [gameServerClusterId] - Required. The ID of the game server cluster
  /// resource to be created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    GameServerCluster request,
    core.String parent, {
    core.String? gameServerClusterId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (gameServerClusterId != null)
        'gameServerClusterId': [gameServerClusterId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/gameServerClusters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a single game server cluster.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server cluster to delete, in the
  /// following form:
  /// `projects/{project}/locations/{location}/gameServerClusters/{cluster}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+/gameServerClusters/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets details of a single game server cluster.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server cluster to retrieve, in the
  /// following form:
  /// `projects/{project}/locations/{location}/realms/{realm-id}/gameServerClusters/{cluster}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+/gameServerClusters/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GameServerCluster].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GameServerCluster> get(
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
    return GameServerCluster.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists game server clusters in a given project and location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// "projects/{project}/locations/{location}/realms/{realm}".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+$`.
  ///
  /// [filter] - Optional. The filter to apply to list results.
  ///
  /// [orderBy] - Optional. Specifies the ordering of results following syntax
  /// at https://cloud.google.com/apis/design/design_patterns#sorting_order.
  ///
  /// [pageSize] - Optional. The maximum number of items to return. If
  /// unspecified, the server will pick an appropriate default. The server may
  /// return fewer items than requested. A caller should only rely on response's
  /// next_page_token to determine if there are more GameServerClusters left to
  /// be queried.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a previous
  /// List request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListGameServerClustersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListGameServerClustersResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/gameServerClusters';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListGameServerClustersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a single game server cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the game server cluster, in the
  /// following form:
  /// `projects/{project}/locations/{location}/realms/{realm}/gameServerClusters/{cluster}`.
  /// For example,
  /// `projects/my-project/locations/{location}/realms/zanzibar/gameServerClusters/my-onprem-cluster`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+/gameServerClusters/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask of fields to update. At least one path must
  /// be supplied in this field. For the `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> patch(
    GameServerCluster request,
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
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Previews creation of a new game server cluster in a given project and
  /// location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name, in the following form:
  /// `projects/{project}/locations/{location}/realms/{realm}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+$`.
  ///
  /// [gameServerClusterId] - Required. The ID of the game server cluster
  /// resource to be created.
  ///
  /// [previewTime] - Optional. The target timestamp to compute the preview.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PreviewCreateGameServerClusterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PreviewCreateGameServerClusterResponse> previewCreate(
    GameServerCluster request,
    core.String parent, {
    core.String? gameServerClusterId,
    core.String? previewTime,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (gameServerClusterId != null)
        'gameServerClusterId': [gameServerClusterId],
      if (previewTime != null) 'previewTime': [previewTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/gameServerClusters:previewCreate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PreviewCreateGameServerClusterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Previews deletion of a single game server cluster.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the game server cluster to delete, in the
  /// following form:
  /// `projects/{project}/locations/{location}/gameServerClusters/{cluster}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+/gameServerClusters/\[^/\]+$`.
  ///
  /// [previewTime] - Optional. The target timestamp to compute the preview.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PreviewDeleteGameServerClusterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PreviewDeleteGameServerClusterResponse> previewDelete(
    core.String name, {
    core.String? previewTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (previewTime != null) 'previewTime': [previewTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':previewDelete';

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return PreviewDeleteGameServerClusterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Previews updating a GameServerCluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the game server cluster, in the
  /// following form:
  /// `projects/{project}/locations/{location}/realms/{realm}/gameServerClusters/{cluster}`.
  /// For example,
  /// `projects/my-project/locations/{location}/realms/zanzibar/gameServerClusters/my-onprem-cluster`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/realms/\[^/\]+/gameServerClusters/\[^/\]+$`.
  ///
  /// [previewTime] - Optional. The target timestamp to compute the preview.
  ///
  /// [updateMask] - Required. Mask of fields to update. At least one path must
  /// be supplied in this field. For the `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PreviewUpdateGameServerClusterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PreviewUpdateGameServerClusterResponse> previewUpdate(
    GameServerCluster request,
    core.String name, {
    core.String? previewTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (previewTime != null) 'previewTime': [previewTime],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':previewUpdate';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return PreviewUpdateGameServerClusterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
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
class AuditConfig {
  /// The configuration for logging of each type of permission.
  core.List<AuditLogConfig>? auditLogConfigs;
  core.List<core.String>? exemptedMembers;

  /// Specifies a service that will be enabled for audit logging.
  ///
  /// For example, `storage.googleapis.com`, `cloudsql.googleapis.com`.
  /// `allServices` is a special value that covers all services.
  core.String? service;

  AuditConfig();

  AuditConfig.fromJson(core.Map _json) {
    if (_json.containsKey('auditLogConfigs')) {
      auditLogConfigs = (_json['auditLogConfigs'] as core.List)
          .map<AuditLogConfig>((value) => AuditLogConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('exemptedMembers')) {
      exemptedMembers = (_json['exemptedMembers'] as core.List)
          .map<core.String>((value) => value as core.String)
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
        if (exemptedMembers != null) 'exemptedMembers': exemptedMembers!,
        if (service != null) 'service': service!,
      };
}

/// Provides the configuration for logging a type of permissions.
///
/// Example: { "audit_log_configs": \[ { "log_type": "DATA_READ",
/// "exempted_members": \[ "user:jose@example.com" \] }, { "log_type":
/// "DATA_WRITE" } \] } This enables 'DATA_READ' and 'DATA_WRITE' logging, while
/// exempting jose@example.com from DATA_READ logging.
class AuditLogConfig {
  /// Specifies the identities that do not cause logging for this type of
  /// permission.
  ///
  /// Follows the same format of Binding.members.
  core.List<core.String>? exemptedMembers;
  core.bool? ignoreChildExemptions;

  /// The log type that this config enables.
  /// Possible string values are:
  /// - "LOG_TYPE_UNSPECIFIED" : Default case. Should never be this.
  /// - "ADMIN_READ" : Admin reads. Example: CloudIAM getIamPolicy
  /// - "DATA_WRITE" : Data writes. Example: CloudSQL Users create
  /// - "DATA_READ" : Data reads. Example: CloudSQL Users list
  core.String? logType;

  AuditLogConfig();

  AuditLogConfig.fromJson(core.Map _json) {
    if (_json.containsKey('exemptedMembers')) {
      exemptedMembers = (_json['exemptedMembers'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('ignoreChildExemptions')) {
      ignoreChildExemptions = _json['ignoreChildExemptions'] as core.bool;
    }
    if (_json.containsKey('logType')) {
      logType = _json['logType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exemptedMembers != null) 'exemptedMembers': exemptedMembers!,
        if (ignoreChildExemptions != null)
          'ignoreChildExemptions': ignoreChildExemptions!,
        if (logType != null) 'logType': logType!,
      };
}

/// Authorization-related information used by Cloud Audit Logging.
class AuthorizationLoggingOptions {
  /// The type of the permission that was checked.
  /// Possible string values are:
  /// - "PERMISSION_TYPE_UNSPECIFIED" : Default. Should not be used.
  /// - "ADMIN_READ" : A read of admin (meta) data.
  /// - "ADMIN_WRITE" : A write of admin (meta) data.
  /// - "DATA_READ" : A read of standard data.
  /// - "DATA_WRITE" : A write of standard data.
  core.String? permissionType;

  AuthorizationLoggingOptions();

  AuthorizationLoggingOptions.fromJson(core.Map _json) {
    if (_json.containsKey('permissionType')) {
      permissionType = _json['permissionType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissionType != null) 'permissionType': permissionType!,
      };
}

/// Associates `members` with a `role`.
class Binding {
  core.String? bindingId;

  /// The condition that is associated with this binding.
  ///
  /// If the condition evaluates to `true`, then this binding applies to the
  /// current request. If the condition evaluates to `false`, then this binding
  /// does not apply to the current request. However, a different role binding
  /// might grant the same role to one or more of the members in this binding.
  /// To learn which resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  Expr? condition;

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

  Binding();

  Binding.fromJson(core.Map _json) {
    if (_json.containsKey('bindingId')) {
      bindingId = _json['bindingId'] as core.String;
    }
    if (_json.containsKey('condition')) {
      condition = Expr.fromJson(
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
        if (bindingId != null) 'bindingId': bindingId!,
        if (condition != null) 'condition': condition!.toJson(),
        if (members != null) 'members': members!,
        if (role != null) 'role': role!,
      };
}

/// The request message for Operations.CancelOperation.
class CancelOperationRequest {
  CancelOperationRequest();

  CancelOperationRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Write a Cloud Audit log
class CloudAuditOptions {
  /// Information used by the Cloud Audit Logging pipeline.
  AuthorizationLoggingOptions? authorizationLoggingOptions;

  /// The log_name to populate in the Cloud Audit Record.
  /// Possible string values are:
  /// - "UNSPECIFIED_LOG_NAME" : Default. Should not be used.
  /// - "ADMIN_ACTIVITY" : Corresponds to "cloudaudit.googleapis.com/activity"
  /// - "DATA_ACCESS" : Corresponds to "cloudaudit.googleapis.com/data_access"
  core.String? logName;

  CloudAuditOptions();

  CloudAuditOptions.fromJson(core.Map _json) {
    if (_json.containsKey('authorizationLoggingOptions')) {
      authorizationLoggingOptions = AuthorizationLoggingOptions.fromJson(
          _json['authorizationLoggingOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('logName')) {
      logName = _json['logName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authorizationLoggingOptions != null)
          'authorizationLoggingOptions': authorizationLoggingOptions!.toJson(),
        if (logName != null) 'logName': logName!,
      };
}

/// A condition to be met.
class Condition {
  /// Trusted attributes supplied by the IAM system.
  /// Possible string values are:
  /// - "NO_ATTR" : Default non-attribute.
  /// - "AUTHORITY" : Either principal or (if present) authority selector.
  /// - "ATTRIBUTION" : The principal (even if an authority selector is
  /// present), which must only be used for attribution, not authorization.
  /// - "SECURITY_REALM" : Any of the security realms in the IAMContext
  /// (go/security-realms). When used with IN, the condition indicates "any of
  /// the request's realms match one of the given values; with NOT_IN, "none of
  /// the realms match any of the given values". Note that a value can be: -
  /// 'self' (i.e., allow connections from clients that are in the same security
  /// realm, which is currently but not guaranteed to be campus-sized) -
  /// 'self:metro' (i.e., clients that are in the same metro) -
  /// 'self:cloud-region' (i.e., allow connections from clients that are in the
  /// same cloud region) - 'guardians' (i.e., allow connections from its
  /// guardian realms. See go/security-realms-glossary#guardian for more
  /// information.) - a realm (e.g., 'campus-abc') - a realm group (e.g.,
  /// 'realms-for-borg-cell-xx', see: go/realm-groups) A match is determined by
  /// a realm group membership check performed by a RealmAclRep object
  /// (go/realm-acl-howto). It is not permitted to grant access based on the
  /// *absence* of a realm, so realm conditions can only be used in a "positive"
  /// context (e.g., ALLOW/IN or DENY/NOT_IN).
  /// - "APPROVER" : An approver (distinct from the requester) that has
  /// authorized this request. When used with IN, the condition indicates that
  /// one of the approvers associated with the request matches the specified
  /// principal, or is a member of the specified group. Approvers can only grant
  /// additional access, and are thus only used in a strictly positive context
  /// (e.g. ALLOW/IN or DENY/NOT_IN).
  /// - "JUSTIFICATION_TYPE" : What types of justifications have been supplied
  /// with this request. String values should match enum names from
  /// security.credentials.JustificationType, e.g. "MANUAL_STRING". It is not
  /// permitted to grant access based on the *absence* of a justification, so
  /// justification conditions can only be used in a "positive" context (e.g.,
  /// ALLOW/IN or DENY/NOT_IN). Multiple justifications, e.g., a Buganizer ID
  /// and a manually-entered reason, are normal and supported.
  /// - "CREDENTIALS_TYPE" : What type of credentials have been supplied with
  /// this request. String values should match enum names from
  /// security_loas_l2.CredentialsType - currently, only CREDS_TYPE_EMERGENCY is
  /// supported. It is not permitted to grant access based on the *absence* of a
  /// credentials type, so the conditions can only be used in a "positive"
  /// context (e.g., ALLOW/IN or DENY/NOT_IN).
  /// - "CREDS_ASSERTION" : EXPERIMENTAL -- DO NOT USE. The conditions can only
  /// be used in a "positive" context (e.g., ALLOW/IN or DENY/NOT_IN).
  core.String? iam;

  /// An operator to apply the subject with.
  /// Possible string values are:
  /// - "NO_OP" : Default no-op.
  /// - "EQUALS" : DEPRECATED. Use IN instead.
  /// - "NOT_EQUALS" : DEPRECATED. Use NOT_IN instead.
  /// - "IN" : The condition is true if the subject (or any element of it if it
  /// is a set) matches any of the supplied values.
  /// - "NOT_IN" : The condition is true if the subject (or every element of it
  /// if it is a set) matches none of the supplied values.
  /// - "DISCHARGED" : Subject is discharged
  core.String? op;

  /// Trusted attributes discharged by the service.
  core.String? svc;

  /// Trusted attributes supplied by any service that owns resources and uses
  /// the IAM system for access control.
  /// Possible string values are:
  /// - "NO_ATTR" : Default non-attribute type
  /// - "REGION" : Region of the resource
  /// - "SERVICE" : Service name
  /// - "NAME" : Resource name
  /// - "IP" : IP address of the caller
  core.String? sys;

  /// The objects of the condition.
  core.List<core.String>? values;

  Condition();

  Condition.fromJson(core.Map _json) {
    if (_json.containsKey('iam')) {
      iam = _json['iam'] as core.String;
    }
    if (_json.containsKey('op')) {
      op = _json['op'] as core.String;
    }
    if (_json.containsKey('svc')) {
      svc = _json['svc'] as core.String;
    }
    if (_json.containsKey('sys')) {
      sys = _json['sys'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iam != null) 'iam': iam!,
        if (op != null) 'op': op!,
        if (svc != null) 'svc': svc!,
        if (sys != null) 'sys': sys!,
        if (values != null) 'values': values!,
      };
}

/// Increment a streamz counter with the specified metric and field names.
///
/// Metric names should start with a '/', generally be lowercase-only, and end
/// in "_count". Field names should not contain an initial slash. The actual
/// exported metric names will have "/iam/policy" prepended. Field names
/// correspond to IAM request parameters and field values are their respective
/// values. Supported field names: - "authority", which is "\[token\]" if
/// IAMContext.token is present, otherwise the value of
/// IAMContext.authority_selector if present, and otherwise a representation of
/// IAMContext.principal; or - "iam_principal", a representation of
/// IAMContext.principal even if a token or authority selector is present; or -
/// "" (empty string), resulting in a counter with no fields. Examples: counter
/// { metric: "/debug_access_count" field: "iam_principal" } ==> increment
/// counter /iam/policy/debug_access_count {iam_principal=\[value of
/// IAMContext.principal\]}
class CounterOptions {
  /// Custom fields.
  core.List<CustomField>? customFields;

  /// The field value to attribute.
  core.String? field;

  /// The metric to update.
  core.String? metric;

  CounterOptions();

  CounterOptions.fromJson(core.Map _json) {
    if (_json.containsKey('customFields')) {
      customFields = (_json['customFields'] as core.List)
          .map<CustomField>((value) => CustomField.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('field')) {
      field = _json['field'] as core.String;
    }
    if (_json.containsKey('metric')) {
      metric = _json['metric'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customFields != null)
          'customFields': customFields!.map((value) => value.toJson()).toList(),
        if (field != null) 'field': field!,
        if (metric != null) 'metric': metric!,
      };
}

/// Custom fields.
///
/// These can be used to create a counter with arbitrary field/value pairs. See:
/// go/rpcsp-custom-fields.
class CustomField {
  /// Name is the field name.
  core.String? name;

  /// Value is the field value.
  ///
  /// It is important that in contrast to the CounterOptions.field, the value
  /// here is a constant that is not derived from the IAMContext.
  core.String? value;

  CustomField();

  CustomField.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// Write a Data Access (Gin) log
class DataAccessOptions {
  ///
  /// Possible string values are:
  /// - "LOG_MODE_UNSPECIFIED" : Client is not required to write a partial Gin
  /// log immediately after the authorization check. If client chooses to write
  /// one and it fails, client may either fail open (allow the operation to
  /// continue) or fail closed (handle as a DENY outcome).
  /// - "LOG_FAIL_CLOSED" : The application's operation in the context of which
  /// this authorization check is being made may only be performed if it is
  /// successfully logged to Gin. For instance, the authorization library may
  /// satisfy this obligation by emitting a partial log entry at authorization
  /// check time and only returning ALLOW to the application if it succeeds. If
  /// a matching Rule has this directive, but the client has not indicated that
  /// it will honor such requirements, then the IAM check will result in
  /// authorization failure by setting CheckPolicyResponse.success=false.
  core.String? logMode;

  DataAccessOptions();

  DataAccessOptions.fromJson(core.Map _json) {
    if (_json.containsKey('logMode')) {
      logMode = _json['logMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logMode != null) 'logMode': logMode!,
      };
}

/// The game server cluster changes made by the game server deployment.
class DeployedClusterState {
  /// The name of the cluster.
  core.String? cluster;

  /// The details about the Agones fleets and autoscalers created in the game
  /// server cluster.
  core.List<DeployedFleetDetails>? fleetDetails;

  DeployedClusterState();

  DeployedClusterState.fromJson(core.Map _json) {
    if (_json.containsKey('cluster')) {
      cluster = _json['cluster'] as core.String;
    }
    if (_json.containsKey('fleetDetails')) {
      fleetDetails = (_json['fleetDetails'] as core.List)
          .map<DeployedFleetDetails>((value) => DeployedFleetDetails.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cluster != null) 'cluster': cluster!,
        if (fleetDetails != null)
          'fleetDetails': fleetDetails!.map((value) => value.toJson()).toList(),
      };
}

/// Agones fleet specification and details.
class DeployedFleet {
  /// The name of the Agones fleet.
  core.String? fleet;

  /// The fleet spec retrieved from the Agones fleet.
  core.String? fleetSpec;

  /// The source spec that is used to create the Agones fleet.
  ///
  /// The GameServerConfig resource may no longer exist in the system.
  SpecSource? specSource;

  /// The current status of the Agones fleet.
  ///
  /// Includes count of game servers in various states.
  DeployedFleetStatus? status;

  DeployedFleet();

  DeployedFleet.fromJson(core.Map _json) {
    if (_json.containsKey('fleet')) {
      fleet = _json['fleet'] as core.String;
    }
    if (_json.containsKey('fleetSpec')) {
      fleetSpec = _json['fleetSpec'] as core.String;
    }
    if (_json.containsKey('specSource')) {
      specSource = SpecSource.fromJson(
          _json['specSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = DeployedFleetStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fleet != null) 'fleet': fleet!,
        if (fleetSpec != null) 'fleetSpec': fleetSpec!,
        if (specSource != null) 'specSource': specSource!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// Details about the Agones autoscaler.
class DeployedFleetAutoscaler {
  /// The name of the Agones autoscaler.
  core.String? autoscaler;

  /// The autoscaler spec retrieved from Agones.
  core.String? fleetAutoscalerSpec;

  /// The source spec that is used to create the autoscaler.
  ///
  /// The GameServerConfig resource may no longer exist in the system.
  SpecSource? specSource;

  DeployedFleetAutoscaler();

  DeployedFleetAutoscaler.fromJson(core.Map _json) {
    if (_json.containsKey('autoscaler')) {
      autoscaler = _json['autoscaler'] as core.String;
    }
    if (_json.containsKey('fleetAutoscalerSpec')) {
      fleetAutoscalerSpec = _json['fleetAutoscalerSpec'] as core.String;
    }
    if (_json.containsKey('specSource')) {
      specSource = SpecSource.fromJson(
          _json['specSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoscaler != null) 'autoscaler': autoscaler!,
        if (fleetAutoscalerSpec != null)
          'fleetAutoscalerSpec': fleetAutoscalerSpec!,
        if (specSource != null) 'specSource': specSource!.toJson(),
      };
}

/// Details of the deployed Agones fleet.
class DeployedFleetDetails {
  /// Information about the Agones autoscaler for that fleet.
  DeployedFleetAutoscaler? deployedAutoscaler;

  /// Information about the Agones fleet.
  DeployedFleet? deployedFleet;

  DeployedFleetDetails();

  DeployedFleetDetails.fromJson(core.Map _json) {
    if (_json.containsKey('deployedAutoscaler')) {
      deployedAutoscaler = DeployedFleetAutoscaler.fromJson(
          _json['deployedAutoscaler'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deployedFleet')) {
      deployedFleet = DeployedFleet.fromJson(
          _json['deployedFleet'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deployedAutoscaler != null)
          'deployedAutoscaler': deployedAutoscaler!.toJson(),
        if (deployedFleet != null) 'deployedFleet': deployedFleet!.toJson(),
      };
}

/// DeployedFleetStatus has details about the Agones fleets such as how many are
/// running, how many allocated, and so on.
class DeployedFleetStatus {
  /// The number of GameServer replicas in the ALLOCATED state in this fleet.
  core.String? allocatedReplicas;

  /// The number of GameServer replicas in the READY state in this fleet.
  core.String? readyReplicas;

  /// The total number of current GameServer replicas in this fleet.
  core.String? replicas;

  /// The number of GameServer replicas in the RESERVED state in this fleet.
  ///
  /// Reserved instances won't be deleted on scale down, but won't cause an
  /// autoscaler to scale up.
  core.String? reservedReplicas;

  DeployedFleetStatus();

  DeployedFleetStatus.fromJson(core.Map _json) {
    if (_json.containsKey('allocatedReplicas')) {
      allocatedReplicas = _json['allocatedReplicas'] as core.String;
    }
    if (_json.containsKey('readyReplicas')) {
      readyReplicas = _json['readyReplicas'] as core.String;
    }
    if (_json.containsKey('replicas')) {
      replicas = _json['replicas'] as core.String;
    }
    if (_json.containsKey('reservedReplicas')) {
      reservedReplicas = _json['reservedReplicas'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allocatedReplicas != null) 'allocatedReplicas': allocatedReplicas!,
        if (readyReplicas != null) 'readyReplicas': readyReplicas!,
        if (replicas != null) 'replicas': replicas!,
        if (reservedReplicas != null) 'reservedReplicas': reservedReplicas!,
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
class Expr {
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

  Expr();

  Expr.fromJson(core.Map _json) {
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

/// Request message for GameServerDeploymentsService.FetchDeploymentState.
class FetchDeploymentStateRequest {
  FetchDeploymentStateRequest();

  FetchDeploymentStateRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response message for GameServerDeploymentsService.FetchDeploymentState.
class FetchDeploymentStateResponse {
  /// The state of the game server deployment in each game server cluster.
  core.List<DeployedClusterState>? clusterState;

  /// List of locations that could not be reached.
  core.List<core.String>? unavailable;

  FetchDeploymentStateResponse();

  FetchDeploymentStateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('clusterState')) {
      clusterState = (_json['clusterState'] as core.List)
          .map<DeployedClusterState>((value) => DeployedClusterState.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('unavailable')) {
      unavailable = (_json['unavailable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterState != null)
          'clusterState': clusterState!.map((value) => value.toJson()).toList(),
        if (unavailable != null) 'unavailable': unavailable!,
      };
}

/// Fleet configs for Agones.
class FleetConfig {
  /// Agones fleet spec.
  ///
  /// Example spec: `https://agones.dev/site/docs/reference/fleet/`.
  core.String? fleetSpec;

  /// The name of the FleetConfig.
  core.String? name;

  FleetConfig();

  FleetConfig.fromJson(core.Map _json) {
    if (_json.containsKey('fleetSpec')) {
      fleetSpec = _json['fleetSpec'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fleetSpec != null) 'fleetSpec': fleetSpec!,
        if (name != null) 'name': name!,
      };
}

/// A game server cluster resource.
class GameServerCluster {
  /// The game server cluster connection information.
  ///
  /// This information is used to manage game server clusters.
  GameServerClusterConnectionInfo? connectionInfo;

  /// The creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// Human readable description of the cluster.
  core.String? description;

  /// ETag of the resource.
  core.String? etag;

  /// The labels associated with this game server cluster.
  ///
  /// Each label is a key-value pair.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the game server cluster, in the following form:
  /// `projects/{project}/locations/{location}/realms/{realm}/gameServerClusters/{cluster}`.
  ///
  /// For example,
  /// `projects/my-project/locations/{location}/realms/zanzibar/gameServerClusters/my-onprem-cluster`.
  ///
  /// Required.
  core.String? name;

  /// The last-modified time.
  ///
  /// Output only.
  core.String? updateTime;

  GameServerCluster();

  GameServerCluster.fromJson(core.Map _json) {
    if (_json.containsKey('connectionInfo')) {
      connectionInfo = GameServerClusterConnectionInfo.fromJson(
          _json['connectionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectionInfo != null) 'connectionInfo': connectionInfo!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (etag != null) 'etag': etag!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// The game server cluster connection information.
class GameServerClusterConnectionInfo {
  /// Reference to the GKE cluster where the game servers are installed.
  GkeClusterReference? gkeClusterReference;

  /// Namespace designated on the game server cluster where the Agones game
  /// server instances will be created.
  ///
  /// Existence of the namespace will be validated during creation.
  core.String? namespace;

  GameServerClusterConnectionInfo();

  GameServerClusterConnectionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('gkeClusterReference')) {
      gkeClusterReference = GkeClusterReference.fromJson(
          _json['gkeClusterReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('namespace')) {
      namespace = _json['namespace'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gkeClusterReference != null)
          'gkeClusterReference': gkeClusterReference!.toJson(),
        if (namespace != null) 'namespace': namespace!,
      };
}

/// A game server config resource.
class GameServerConfig {
  /// The creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// The description of the game server config.
  core.String? description;

  /// FleetConfig contains a list of Agones fleet specs.
  ///
  /// Only one FleetConfig is allowed.
  core.List<FleetConfig>? fleetConfigs;

  /// The labels associated with this game server config.
  ///
  /// Each label is a key-value pair.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the game server config, in the following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/configs/{config}`.
  ///
  /// For example,
  /// `projects/my-project/locations/global/gameServerDeployments/my-game/configs/my-config`.
  core.String? name;

  /// The autoscaling settings.
  core.List<ScalingConfig>? scalingConfigs;

  /// The last-modified time.
  ///
  /// Output only.
  core.String? updateTime;

  GameServerConfig();

  GameServerConfig.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('fleetConfigs')) {
      fleetConfigs = (_json['fleetConfigs'] as core.List)
          .map<FleetConfig>((value) => FleetConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('scalingConfigs')) {
      scalingConfigs = (_json['scalingConfigs'] as core.List)
          .map<ScalingConfig>((value) => ScalingConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (fleetConfigs != null)
          'fleetConfigs': fleetConfigs!.map((value) => value.toJson()).toList(),
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (scalingConfigs != null)
          'scalingConfigs':
              scalingConfigs!.map((value) => value.toJson()).toList(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// A game server config override.
class GameServerConfigOverride {
  /// The game server config for this override.
  core.String? configVersion;

  /// Selector for choosing applicable realms.
  RealmSelector? realmsSelector;

  GameServerConfigOverride();

  GameServerConfigOverride.fromJson(core.Map _json) {
    if (_json.containsKey('configVersion')) {
      configVersion = _json['configVersion'] as core.String;
    }
    if (_json.containsKey('realmsSelector')) {
      realmsSelector = RealmSelector.fromJson(
          _json['realmsSelector'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configVersion != null) 'configVersion': configVersion!,
        if (realmsSelector != null) 'realmsSelector': realmsSelector!.toJson(),
      };
}

/// A game server deployment resource.
class GameServerDeployment {
  /// The creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// Human readable description of the game server delpoyment.
  core.String? description;

  /// ETag of the resource.
  core.String? etag;

  /// The labels associated with this game server deployment.
  ///
  /// Each label is a key-value pair.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the game server deployment, in the following form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}`.
  ///
  /// For example,
  /// `projects/my-project/locations/global/gameServerDeployments/my-deployment`.
  core.String? name;

  /// The last-modified time.
  ///
  /// Output only.
  core.String? updateTime;

  GameServerDeployment();

  GameServerDeployment.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (etag != null) 'etag': etag!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// The game server deployment rollout which represents the desired rollout
/// state.
class GameServerDeploymentRollout {
  /// The creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// The default game server config is applied to all realms unless overridden
  /// in the rollout.
  ///
  /// For example,
  /// `projects/my-project/locations/global/gameServerDeployments/my-game/configs/my-config`.
  core.String? defaultGameServerConfig;

  /// ETag of the resource.
  core.String? etag;

  /// Contains the game server config rollout overrides.
  ///
  /// Overrides are processed in the order they are listed. Once a match is
  /// found for a realm, the rest of the list is not processed.
  core.List<GameServerConfigOverride>? gameServerConfigOverrides;

  /// The resource name of the game server deployment rollout, in the following
  /// form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment}/rollout`.
  ///
  /// For example,
  /// `projects/my-project/locations/global/gameServerDeployments/my-deployment/rollout`.
  core.String? name;

  /// The last-modified time.
  ///
  /// Output only.
  core.String? updateTime;

  GameServerDeploymentRollout();

  GameServerDeploymentRollout.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('defaultGameServerConfig')) {
      defaultGameServerConfig = _json['defaultGameServerConfig'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('gameServerConfigOverrides')) {
      gameServerConfigOverrides =
          (_json['gameServerConfigOverrides'] as core.List)
              .map<GameServerConfigOverride>((value) =>
                  GameServerConfigOverride.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (defaultGameServerConfig != null)
          'defaultGameServerConfig': defaultGameServerConfig!,
        if (etag != null) 'etag': etag!,
        if (gameServerConfigOverrides != null)
          'gameServerConfigOverrides': gameServerConfigOverrides!
              .map((value) => value.toJson())
              .toList(),
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// A reference to a GKE cluster.
class GkeClusterReference {
  /// The full or partial name of a GKE cluster, using one of the following
  /// forms: * `projects/{project}/locations/{location}/clusters/{cluster}` *
  /// `locations/{location}/clusters/{cluster}` * `{cluster}` If project and
  /// location are not specified, the project and location of the
  /// GameServerCluster resource are used to generate the full name of the GKE
  /// cluster.
  core.String? cluster;

  GkeClusterReference();

  GkeClusterReference.fromJson(core.Map _json) {
    if (_json.containsKey('cluster')) {
      cluster = _json['cluster'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cluster != null) 'cluster': cluster!,
      };
}

/// The label selector, used to group labels on the resources.
class LabelSelector {
  /// Resource labels for this selector.
  core.Map<core.String, core.String>? labels;

  LabelSelector();

  LabelSelector.fromJson(core.Map _json) {
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labels != null) 'labels': labels!,
      };
}

/// Response message for GameServerClustersService.ListGameServerClusters.
class ListGameServerClustersResponse {
  /// The list of game server clusters.
  core.List<GameServerCluster>? gameServerClusters;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// List of locations that could not be reached.
  core.List<core.String>? unreachable;

  ListGameServerClustersResponse();

  ListGameServerClustersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('gameServerClusters')) {
      gameServerClusters = (_json['gameServerClusters'] as core.List)
          .map<GameServerCluster>((value) => GameServerCluster.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gameServerClusters != null)
          'gameServerClusters':
              gameServerClusters!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// Response message for GameServerConfigsService.ListGameServerConfigs.
class ListGameServerConfigsResponse {
  /// The list of game server configs.
  core.List<GameServerConfig>? gameServerConfigs;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// List of locations that could not be reached.
  core.List<core.String>? unreachable;

  ListGameServerConfigsResponse();

  ListGameServerConfigsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('gameServerConfigs')) {
      gameServerConfigs = (_json['gameServerConfigs'] as core.List)
          .map<GameServerConfig>((value) => GameServerConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gameServerConfigs != null)
          'gameServerConfigs':
              gameServerConfigs!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// Response message for GameServerDeploymentsService.ListGameServerDeployments.
class ListGameServerDeploymentsResponse {
  /// The list of game server deployments.
  core.List<GameServerDeployment>? gameServerDeployments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// List of locations that could not be reached.
  core.List<core.String>? unreachable;

  ListGameServerDeploymentsResponse();

  ListGameServerDeploymentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('gameServerDeployments')) {
      gameServerDeployments = (_json['gameServerDeployments'] as core.List)
          .map<GameServerDeployment>((value) => GameServerDeployment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gameServerDeployments != null)
          'gameServerDeployments':
              gameServerDeployments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// The response message for Locations.ListLocations.
class ListLocationsResponse {
  /// A list of locations that matches the specified filter in the request.
  core.List<Location>? locations;

  /// The standard List next-page token.
  core.String? nextPageToken;

  ListLocationsResponse();

  ListLocationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<Location>((value) =>
              Location.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locations != null)
          'locations': locations!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for Operations.ListOperations.
class ListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<Operation>? operations;

  ListOperationsResponse();

  ListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<Operation>((value) =>
              Operation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for RealmsService.ListRealms.
class ListRealmsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of realms.
  core.List<Realm>? realms;

  /// List of locations that could not be reached.
  core.List<core.String>? unreachable;

  ListRealmsResponse();

  ListRealmsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('realms')) {
      realms = (_json['realms'] as core.List)
          .map<Realm>((value) =>
              Realm.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (realms != null)
          'realms': realms!.map((value) => value.toJson()).toList(),
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// A resource that represents Google Cloud Platform location.
class Location {
  /// The friendly name for this location, typically a nearby city name.
  ///
  /// For example, "Tokyo".
  core.String? displayName;

  /// Cross-service attributes for the location.
  ///
  /// For example {"cloud.googleapis.com/region": "us-east1"}
  core.Map<core.String, core.String>? labels;

  /// The canonical id for this location.
  ///
  /// For example: `"us-east1"`.
  core.String? locationId;

  /// Service-specific metadata.
  ///
  /// For example the available capacity at the given location.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// Resource name for the location, which may vary between implementations.
  ///
  /// For example: `"projects/example-project/locations/us-east1"`
  core.String? name;

  Location();

  Location.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('locationId')) {
      locationId = _json['locationId'] as core.String;
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
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (labels != null) 'labels': labels!,
        if (locationId != null) 'locationId': locationId!,
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
      };
}

/// Specifies what kind of log the caller must write
class LogConfig {
  /// Cloud audit options.
  CloudAuditOptions? cloudAudit;

  /// Counter options.
  CounterOptions? counter;

  /// Data access options.
  DataAccessOptions? dataAccess;

  LogConfig();

  LogConfig.fromJson(core.Map _json) {
    if (_json.containsKey('cloudAudit')) {
      cloudAudit = CloudAuditOptions.fromJson(
          _json['cloudAudit'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('counter')) {
      counter = CounterOptions.fromJson(
          _json['counter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataAccess')) {
      dataAccess = DataAccessOptions.fromJson(
          _json['dataAccess'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudAudit != null) 'cloudAudit': cloudAudit!.toJson(),
        if (counter != null) 'counter': counter!.toJson(),
        if (dataAccess != null) 'dataAccess': dataAccess!.toJson(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class Operation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  Status? error;

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

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
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

/// Represents the metadata of the long-running operation.
class OperationMetadata {
  /// API version used to start the operation.
  ///
  /// Output only.
  core.String? apiVersion;

  /// The time the operation was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The time the operation finished running.
  ///
  /// Output only.
  core.String? endTime;

  /// Operation status for Game Services API operations.
  ///
  /// Operation status is in the form of key-value pairs where keys are resource
  /// IDs and the values show the status of the operation. In case of failures,
  /// the value includes an error code and error message.
  ///
  /// Output only.
  core.Map<core.String, OperationStatus>? operationStatus;

  /// Identifies whether the user has requested cancellation of the operation.
  ///
  /// Operations that have successfully been cancelled have Operation.error
  /// value with a google.rpc.Status.code of 1, corresponding to
  /// `Code.CANCELLED`.
  ///
  /// Output only.
  core.bool? requestedCancellation;

  /// Human-readable status of the operation, if any.
  ///
  /// Output only.
  core.String? statusMessage;

  /// Server-defined resource path for the target of the operation.
  ///
  /// Output only.
  core.String? target;

  /// List of Locations that could not be reached.
  ///
  /// Output only.
  core.List<core.String>? unreachable;

  /// Name of the verb executed by the operation.
  ///
  /// Output only.
  core.String? verb;

  OperationMetadata();

  OperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('operationStatus')) {
      operationStatus =
          (_json['operationStatus'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          OperationStatus.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('requestedCancellation')) {
      requestedCancellation = _json['requestedCancellation'] as core.bool;
    }
    if (_json.containsKey('statusMessage')) {
      statusMessage = _json['statusMessage'] as core.String;
    }
    if (_json.containsKey('target')) {
      target = _json['target'] as core.String;
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('verb')) {
      verb = _json['verb'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (createTime != null) 'createTime': createTime!,
        if (endTime != null) 'endTime': endTime!,
        if (operationStatus != null)
          'operationStatus': operationStatus!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (requestedCancellation != null)
          'requestedCancellation': requestedCancellation!,
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (target != null) 'target': target!,
        if (unreachable != null) 'unreachable': unreachable!,
        if (verb != null) 'verb': verb!,
      };
}

class OperationStatus {
  /// Whether the operation is done or still in progress.
  ///
  /// Output only.
  core.bool? done;

  /// The error code in case of failures.
  /// Possible string values are:
  /// - "ERROR_CODE_UNSPECIFIED"
  /// - "INTERNAL_ERROR"
  /// - "PERMISSION_DENIED"
  /// - "CLUSTER_CONNECTION"
  core.String? errorCode;

  /// The human-readable error message.
  core.String? errorMessage;

  OperationStatus();

  OperationStatus.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('errorCode')) {
      errorCode = _json['errorCode'] as core.String;
    }
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (done != null) 'done': done!,
        if (errorCode != null) 'errorCode': errorCode!,
        if (errorMessage != null) 'errorMessage': errorMessage!,
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
class Policy {
  /// Specifies cloud audit logging configuration for this policy.
  core.List<AuditConfig>? auditConfigs;

  /// Associates a list of `members` to a `role`.
  ///
  /// Optionally, may specify a `condition` that determines how and when the
  /// `bindings` are applied. Each of the `bindings` must contain at least one
  /// member.
  core.List<Binding>? bindings;

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

  core.bool? iamOwned;

  /// If more than one rule is specified, the rules are applied in the following
  /// manner: - All matching LOG rules are always applied.
  ///
  /// - If any DENY/DENY_WITH_LOG rule matches, permission is denied. Logging
  /// will be applied if one or more matching rule requires logging. -
  /// Otherwise, if any ALLOW/ALLOW_WITH_LOG rule matches, permission is
  /// granted. Logging will be applied if one or more matching rule requires
  /// logging. - Otherwise, if no rule applies, permission is denied.
  core.List<Rule>? rules;

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

  Policy();

  Policy.fromJson(core.Map _json) {
    if (_json.containsKey('auditConfigs')) {
      auditConfigs = (_json['auditConfigs'] as core.List)
          .map<AuditConfig>((value) => AuditConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('bindings')) {
      bindings = (_json['bindings'] as core.List)
          .map<Binding>((value) =>
              Binding.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('iamOwned')) {
      iamOwned = _json['iamOwned'] as core.bool;
    }
    if (_json.containsKey('rules')) {
      rules = (_json['rules'] as core.List)
          .map<Rule>((value) =>
              Rule.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
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
        if (iamOwned != null) 'iamOwned': iamOwned!,
        if (rules != null)
          'rules': rules!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Response message for
/// GameServerClustersService.PreviewCreateGameServerCluster.
class PreviewCreateGameServerClusterResponse {
  /// The ETag of the game server cluster.
  core.String? etag;

  /// The target state.
  TargetState? targetState;

  PreviewCreateGameServerClusterResponse();

  PreviewCreateGameServerClusterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('targetState')) {
      targetState = TargetState.fromJson(
          _json['targetState'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (targetState != null) 'targetState': targetState!.toJson(),
      };
}

/// Response message for
/// GameServerClustersService.PreviewDeleteGameServerCluster.
class PreviewDeleteGameServerClusterResponse {
  /// The ETag of the game server cluster.
  core.String? etag;

  /// The target state.
  TargetState? targetState;

  PreviewDeleteGameServerClusterResponse();

  PreviewDeleteGameServerClusterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('targetState')) {
      targetState = TargetState.fromJson(
          _json['targetState'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (targetState != null) 'targetState': targetState!.toJson(),
      };
}

/// Response message for PreviewGameServerDeploymentRollout.
///
/// This has details about the Agones fleet and autoscaler to be actuated.
class PreviewGameServerDeploymentRolloutResponse {
  /// ETag of the game server deployment.
  core.String? etag;

  /// The target state.
  TargetState? targetState;

  /// Locations that could not be reached on this request.
  core.List<core.String>? unavailable;

  PreviewGameServerDeploymentRolloutResponse();

  PreviewGameServerDeploymentRolloutResponse.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('targetState')) {
      targetState = TargetState.fromJson(
          _json['targetState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unavailable')) {
      unavailable = (_json['unavailable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (targetState != null) 'targetState': targetState!.toJson(),
        if (unavailable != null) 'unavailable': unavailable!,
      };
}

/// Response message for RealmsService.PreviewRealmUpdate.
class PreviewRealmUpdateResponse {
  /// ETag of the realm.
  core.String? etag;

  /// The target state.
  TargetState? targetState;

  PreviewRealmUpdateResponse();

  PreviewRealmUpdateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('targetState')) {
      targetState = TargetState.fromJson(
          _json['targetState'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (targetState != null) 'targetState': targetState!.toJson(),
      };
}

/// Response message for
/// GameServerClustersService.PreviewUpdateGameServerCluster
class PreviewUpdateGameServerClusterResponse {
  /// The ETag of the game server cluster.
  core.String? etag;

  /// The target state.
  TargetState? targetState;

  PreviewUpdateGameServerClusterResponse();

  PreviewUpdateGameServerClusterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('targetState')) {
      targetState = TargetState.fromJson(
          _json['targetState'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (targetState != null) 'targetState': targetState!.toJson(),
      };
}

/// A realm resource.
class Realm {
  /// The creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// Human readable description of the realm.
  core.String? description;

  /// ETag of the resource.
  core.String? etag;

  /// The labels associated with this realm.
  ///
  /// Each label is a key-value pair.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the realm, in the following form:
  /// `projects/{project}/locations/{location}/realms/{realm}`.
  ///
  /// For example, `projects/my-project/locations/{location}/realms/my-realm`.
  core.String? name;

  /// Time zone where all policies targeting this realm are evaluated.
  ///
  /// The value of this field must be from the IANA time zone database:
  /// https://www.iana.org/time-zones.
  ///
  /// Required.
  core.String? timeZone;

  /// The last-modified time.
  ///
  /// Output only.
  core.String? updateTime;

  Realm();

  Realm.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (etag != null) 'etag': etag!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (timeZone != null) 'timeZone': timeZone!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// The realm selector, used to match realm resources.
class RealmSelector {
  /// List of realms to match.
  core.List<core.String>? realms;

  RealmSelector();

  RealmSelector.fromJson(core.Map _json) {
    if (_json.containsKey('realms')) {
      realms = (_json['realms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (realms != null) 'realms': realms!,
      };
}

/// A rule to be applied in a Policy.
class Rule {
  /// Required
  /// Possible string values are:
  /// - "NO_ACTION" : Default no action.
  /// - "ALLOW" : Matching 'Entries' grant access.
  /// - "ALLOW_WITH_LOG" : Matching 'Entries' grant access and the caller
  /// promises to log the request per the returned log_configs.
  /// - "DENY" : Matching 'Entries' deny access.
  /// - "DENY_WITH_LOG" : Matching 'Entries' deny access and the caller promises
  /// to log the request per the returned log_configs.
  /// - "LOG" : Matching 'Entries' tell IAM.Check callers to generate logs.
  core.String? action;

  /// Additional restrictions that must be met.
  ///
  /// All conditions must pass for the rule to match.
  core.List<Condition>? conditions;

  /// Human-readable description of the rule.
  core.String? description;

  /// If one or more 'in' clauses are specified, the rule matches if the
  /// PRINCIPAL/AUTHORITY_SELECTOR is in at least one of these entries.
  core.List<core.String>? in_;

  /// The config returned to callers of tech.iam.IAM.CheckPolicy for any entries
  /// that match the LOG action.
  core.List<LogConfig>? logConfig;

  /// If one or more 'not_in' clauses are specified, the rule matches if the
  /// PRINCIPAL/AUTHORITY_SELECTOR is in none of the entries.
  ///
  /// The format for in and not_in entries can be found at in the Local IAM
  /// documentation (see go/local-iam#features).
  core.List<core.String>? notIn;

  /// A permission is a string of form '..' (e.g., 'storage.buckets.list').
  ///
  /// A value of '*' matches all permissions, and a verb part of '*' (e.g.,
  /// 'storage.buckets.*') matches all verbs.
  core.List<core.String>? permissions;

  Rule();

  Rule.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<Condition>((value) =>
              Condition.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('in')) {
      in_ = (_json['in'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('logConfig')) {
      logConfig = (_json['logConfig'] as core.List)
          .map<LogConfig>((value) =>
              LogConfig.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('notIn')) {
      notIn = (_json['notIn'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (description != null) 'description': description!,
        if (in_ != null) 'in': in_!,
        if (logConfig != null)
          'logConfig': logConfig!.map((value) => value.toJson()).toList(),
        if (notIn != null) 'notIn': notIn!,
        if (permissions != null) 'permissions': permissions!,
      };
}

/// Autoscaling config for an Agones fleet.
class ScalingConfig {
  /// Agones fleet autoscaler spec.
  ///
  /// Example spec: https://agones.dev/site/docs/reference/fleetautoscaler/
  ///
  /// Required.
  core.String? fleetAutoscalerSpec;

  /// The name of the Scaling Config
  ///
  /// Required.
  core.String? name;

  /// The schedules to which this Scaling Config applies.
  core.List<Schedule>? schedules;

  /// Labels used to identify the game server clusters to which this Agones
  /// scaling config applies.
  ///
  /// A game server cluster is subject to this Agones scaling config if its
  /// labels match any of the selector entries.
  core.List<LabelSelector>? selectors;

  ScalingConfig();

  ScalingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('fleetAutoscalerSpec')) {
      fleetAutoscalerSpec = _json['fleetAutoscalerSpec'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('schedules')) {
      schedules = (_json['schedules'] as core.List)
          .map<Schedule>((value) =>
              Schedule.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('selectors')) {
      selectors = (_json['selectors'] as core.List)
          .map<LabelSelector>((value) => LabelSelector.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fleetAutoscalerSpec != null)
          'fleetAutoscalerSpec': fleetAutoscalerSpec!,
        if (name != null) 'name': name!,
        if (schedules != null)
          'schedules': schedules!.map((value) => value.toJson()).toList(),
        if (selectors != null)
          'selectors': selectors!.map((value) => value.toJson()).toList(),
      };
}

/// The schedule of a recurring or one time event.
///
/// The event's time span is specified by start_time and end_time. If the
/// scheduled event's timespan is larger than the cron_spec + cron_job_duration,
/// the event will be recurring. If only cron_spec + cron_job_duration are
/// specified, the event is effective starting at the local time specified by
/// cron_spec, and is recurring. start_time|-------\[cron job\]-------\[cron
/// job\]-------\[cron job\]---|end_time cron job: cron spec start time +
/// duration
class Schedule {
  /// The duration for the cron job event.
  ///
  /// The duration of the event is effective after the cron job's start time.
  core.String? cronJobDuration;

  /// The cron definition of the scheduled event.
  ///
  /// See https://en.wikipedia.org/wiki/Cron. Cron spec specifies the local time
  /// as defined by the realm.
  core.String? cronSpec;

  /// The end time of the event.
  core.String? endTime;

  /// The start time of the event.
  core.String? startTime;

  Schedule();

  Schedule.fromJson(core.Map _json) {
    if (_json.containsKey('cronJobDuration')) {
      cronJobDuration = _json['cronJobDuration'] as core.String;
    }
    if (_json.containsKey('cronSpec')) {
      cronSpec = _json['cronSpec'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cronJobDuration != null) 'cronJobDuration': cronJobDuration!,
        if (cronSpec != null) 'cronSpec': cronSpec!,
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Request message for `SetIamPolicy` method.
class SetIamPolicyRequest {
  /// REQUIRED: The complete policy to be applied to the `resource`.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is a
  /// valid policy but certain Cloud Platform services (such as Projects) might
  /// reject them.
  Policy? policy;

  /// OPTIONAL: A FieldMask specifying which fields of the policy to modify.
  ///
  /// Only the fields in the mask will be modified. If no mask is provided, the
  /// following default mask is used: `paths: "bindings, etag"`
  core.String? updateMask;

  SetIamPolicyRequest();

  SetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Encapsulates Agones fleet spec and Agones autoscaler spec sources.
class SpecSource {
  /// The game server config resource.
  ///
  /// Uses the form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment_id}/configs/{config_id}`.
  core.String? gameServerConfigName;

  /// The name of the Agones leet config or Agones scaling config used to derive
  /// the Agones fleet or Agones autoscaler spec.
  core.String? name;

  SpecSource();

  SpecSource.fromJson(core.Map _json) {
    if (_json.containsKey('gameServerConfigName')) {
      gameServerConfigName = _json['gameServerConfigName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gameServerConfigName != null)
          'gameServerConfigName': gameServerConfigName!,
        if (name != null) 'name': name!,
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
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

  Status();

  Status.fromJson(core.Map _json) {
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

/// Details about the Agones resources.
class TargetDetails {
  /// Agones fleet details for game server clusters and game server deployments.
  core.List<TargetFleetDetails>? fleetDetails;

  /// The game server cluster name.
  ///
  /// Uses the form:
  /// `projects/{project}/locations/{location}/realms/{realm}/gameServerClusters/{cluster}`.
  core.String? gameServerClusterName;

  /// The game server deployment name.
  ///
  /// Uses the form:
  /// `projects/{project}/locations/{location}/gameServerDeployments/{deployment_id}`.
  core.String? gameServerDeploymentName;

  TargetDetails();

  TargetDetails.fromJson(core.Map _json) {
    if (_json.containsKey('fleetDetails')) {
      fleetDetails = (_json['fleetDetails'] as core.List)
          .map<TargetFleetDetails>((value) => TargetFleetDetails.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('gameServerClusterName')) {
      gameServerClusterName = _json['gameServerClusterName'] as core.String;
    }
    if (_json.containsKey('gameServerDeploymentName')) {
      gameServerDeploymentName =
          _json['gameServerDeploymentName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fleetDetails != null)
          'fleetDetails': fleetDetails!.map((value) => value.toJson()).toList(),
        if (gameServerClusterName != null)
          'gameServerClusterName': gameServerClusterName!,
        if (gameServerDeploymentName != null)
          'gameServerDeploymentName': gameServerDeploymentName!,
      };
}

/// Target Agones fleet specification.
class TargetFleet {
  /// The name of the Agones fleet.
  core.String? name;

  /// Encapsulates the source of the Agones fleet spec.
  ///
  /// The Agones fleet spec source.
  SpecSource? specSource;

  TargetFleet();

  TargetFleet.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('specSource')) {
      specSource = SpecSource.fromJson(
          _json['specSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (specSource != null) 'specSource': specSource!.toJson(),
      };
}

/// Target Agones autoscaler policy reference.
class TargetFleetAutoscaler {
  /// The name of the Agones autoscaler.
  core.String? name;

  /// Encapsulates the source of the Agones fleet spec.
  ///
  /// Details about the Agones autoscaler spec.
  SpecSource? specSource;

  TargetFleetAutoscaler();

  TargetFleetAutoscaler.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('specSource')) {
      specSource = SpecSource.fromJson(
          _json['specSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (specSource != null) 'specSource': specSource!.toJson(),
      };
}

/// Details of the target Agones fleet.
class TargetFleetDetails {
  /// Reference to target Agones fleet autoscaling policy.
  TargetFleetAutoscaler? autoscaler;

  /// Reference to target Agones fleet.
  TargetFleet? fleet;

  TargetFleetDetails();

  TargetFleetDetails.fromJson(core.Map _json) {
    if (_json.containsKey('autoscaler')) {
      autoscaler = TargetFleetAutoscaler.fromJson(
          _json['autoscaler'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fleet')) {
      fleet = TargetFleet.fromJson(
          _json['fleet'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoscaler != null) 'autoscaler': autoscaler!.toJson(),
        if (fleet != null) 'fleet': fleet!.toJson(),
      };
}

/// Encapsulates the Target state.
class TargetState {
  /// Details about Agones fleets.
  core.List<TargetDetails>? details;

  TargetState();

  TargetState.fromJson(core.Map _json) {
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<TargetDetails>((value) => TargetDetails.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (details != null)
          'details': details!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for `TestIamPermissions` method.
class TestIamPermissionsRequest {
  /// The set of permissions to check for the `resource`.
  ///
  /// Permissions with wildcards (such as '*' or 'storage.*') are not allowed.
  /// For more information see
  /// [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
  core.List<core.String>? permissions;

  TestIamPermissionsRequest();

  TestIamPermissionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissions != null) 'permissions': permissions!,
      };
}

/// Response message for `TestIamPermissions` method.
class TestIamPermissionsResponse {
  /// A subset of `TestPermissionsRequest.permissions` that the caller is
  /// allowed.
  core.List<core.String>? permissions;

  TestIamPermissionsResponse();

  TestIamPermissionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissions != null) 'permissions': permissions!,
      };
}

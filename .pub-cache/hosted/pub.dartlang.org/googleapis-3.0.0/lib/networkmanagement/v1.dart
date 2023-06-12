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

/// Network Management API - v1
///
/// The Network Management API provides a collection of network performance
/// monitoring and diagnostic capabilities.
///
/// For more information, see <https://cloud.google.com/>
///
/// Create an instance of [NetworkManagementApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsGlobalResource]
///       - [ProjectsLocationsGlobalConnectivityTestsResource]
///       - [ProjectsLocationsGlobalOperationsResource]
library networkmanagement.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Network Management API provides a collection of network performance
/// monitoring and diagnostic capabilities.
class NetworkManagementApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  NetworkManagementApi(http.Client client,
      {core.String rootUrl = 'https://networkmanagement.googleapis.com/',
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

  ProjectsLocationsGlobalResource get global =>
      ProjectsLocationsGlobalResource(_requester);

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

class ProjectsLocationsGlobalResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsGlobalConnectivityTestsResource get connectivityTests =>
      ProjectsLocationsGlobalConnectivityTestsResource(_requester);
  ProjectsLocationsGlobalOperationsResource get operations =>
      ProjectsLocationsGlobalOperationsResource(_requester);

  ProjectsLocationsGlobalResource(commons.ApiRequester client)
      : _requester = client;
}

class ProjectsLocationsGlobalConnectivityTestsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsGlobalConnectivityTestsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new Connectivity Test.
  ///
  /// After you create a test, the reachability analysis is performed as part of
  /// the long running operation, which completes when the analysis completes.
  /// If the endpoint specifications in `ConnectivityTest` are invalid (for
  /// example, containing non-existent resources in the network, or you don't
  /// have read permissions to the network configurations of listed projects),
  /// then the reachability result returns a value of `UNKNOWN`. If the endpoint
  /// specifications in `ConnectivityTest` are incomplete, the reachability
  /// result returns a value of AMBIGUOUS. For more information, see the
  /// Connectivity Test documentation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource of the Connectivity Test to
  /// create: `projects/{project_id}/locations/global`
  /// Value must have pattern `^projects/\[^/\]+/locations/global$`.
  ///
  /// [testId] - Required. The logical name of the Connectivity Test in your
  /// project with the following restrictions: * Must contain only lowercase
  /// letters, numbers, and hyphens. * Must start with a letter. * Must be
  /// between 1-40 characters. * Must end with a number or a letter. * Must be
  /// unique within the customer project
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
    ConnectivityTest request,
    core.String parent, {
    core.String? testId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (testId != null) 'testId': [testId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/connectivityTests';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a specific `ConnectivityTest`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Connectivity Test resource name using the form:
  /// `projects/{project_id}/locations/global/connectivityTests/{test_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/global/connectivityTests/\[^/\]+$`.
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

  /// Gets the details of a specific Connectivity Test.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. `ConnectivityTest` resource name using the form:
  /// `projects/{project_id}/locations/global/connectivityTests/{test_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/global/connectivityTests/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ConnectivityTest].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ConnectivityTest> get(
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
    return ConnectivityTest.fromJson(
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
  /// `^projects/\[^/\]+/locations/global/connectivityTests/\[^/\]+$`.
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

  /// Lists all Connectivity Tests owned by a project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource of the Connectivity Tests:
  /// `projects/{project_id}/locations/global`
  /// Value must have pattern `^projects/\[^/\]+/locations/global$`.
  ///
  /// [filter] - Lists the `ConnectivityTests` that match the filter expression.
  /// A filter expression filters the resources listed in the response. The
  /// expression must be of the form ` ` where operators: `<`, `>`, `<=`, `>=`,
  /// `!=`, `=`, `:` are supported (colon `:` represents a HAS operator which is
  /// roughly synonymous with equality). can refer to a proto or JSON field, or
  /// a synthetic field. Field names can be camelCase or snake_case. Examples: -
  /// Filter by name: name =
  /// "projects/proj-1/locations/global/connectivityTests/test-1 - Filter by
  /// labels: - Resources that have a key called `foo` labels.foo:* - Resources
  /// that have a key called `foo` whose value is `bar` labels.foo = bar
  ///
  /// [orderBy] - Field to use to sort the list.
  ///
  /// [pageSize] - Number of `ConnectivityTests` to return.
  ///
  /// [pageToken] - Page token from an earlier query, as returned in
  /// `next_page_token`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListConnectivityTestsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListConnectivityTestsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/connectivityTests';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListConnectivityTestsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the configuration of an existing `ConnectivityTest`.
  ///
  /// After you update a test, the reachability analysis is performed as part of
  /// the long running operation, which completes when the analysis completes.
  /// The Reachability state in the test resource is updated with the new
  /// result. If the endpoint specifications in `ConnectivityTest` are invalid
  /// (for example, they contain non-existent resources in the network, or the
  /// user does not have read permissions to the network configurations of
  /// listed projects), then the reachability result returns a value of UNKNOWN.
  /// If the endpoint specifications in `ConnectivityTest` are incomplete, the
  /// reachability result returns a value of `AMBIGUOUS`. See the documentation
  /// in `ConnectivityTest` for for more details.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Unique name of the resource using the form:
  /// `projects/{project_id}/locations/global/connectivityTests/{test_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/global/connectivityTests/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask of fields to update. At least one path must
  /// be supplied in this field.
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
    ConnectivityTest request,
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

  /// Rerun an existing `ConnectivityTest`.
  ///
  /// After the user triggers the rerun, the reachability analysis is performed
  /// as part of the long running operation, which completes when the analysis
  /// completes. Even though the test configuration remains the same, the
  /// reachability result may change due to underlying network configuration
  /// changes. If the endpoint specifications in `ConnectivityTest` become
  /// invalid (for example, specified resources are deleted in the network, or
  /// you lost read permissions to the network configurations of listed
  /// projects), then the reachability result returns a value of `UNKNOWN`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Connectivity Test resource name using the form:
  /// `projects/{project_id}/locations/global/connectivityTests/{test_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/global/connectivityTests/\[^/\]+$`.
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
  async.Future<Operation> rerun(
    RerunConnectivityTestRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':rerun';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// `^projects/\[^/\]+/locations/global/connectivityTests/\[^/\]+$`.
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
  /// `^projects/\[^/\]+/locations/global/connectivityTests/\[^/\]+$`.
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
}

class ProjectsLocationsGlobalOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsGlobalOperationsResource(commons.ApiRequester client)
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
  /// `^projects/\[^/\]+/locations/global/operations/\[^/\]+$`.
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
  /// `^projects/\[^/\]+/locations/global/operations/\[^/\]+$`.
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
  /// `^projects/\[^/\]+/locations/global/operations/\[^/\]+$`.
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
  /// Value must have pattern `^projects/\[^/\]+/locations/global$`.
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

/// Details of the final state "abort" and associated resource.
class AbortInfo {
  /// Causes that the analysis is aborted.
  /// Possible string values are:
  /// - "CAUSE_UNSPECIFIED" : Cause is unspecified.
  /// - "UNKNOWN_NETWORK" : Aborted due to unknown network. The reachability
  /// analysis cannot proceed because the user does not have access to the host
  /// project's network configurations, including firewall rules and routes.
  /// This happens when the project is a service project and the endpoints being
  /// traced are in the host project's network.
  /// - "UNKNOWN_IP" : Aborted because the IP address(es) are unknown.
  /// - "UNKNOWN_PROJECT" : Aborted because no project information can be
  /// derived from the test input.
  /// - "PERMISSION_DENIED" : Aborted because the user lacks the permission to
  /// access all or part of the network configurations required to run the test.
  /// - "NO_SOURCE_LOCATION" : Aborted because no valid source endpoint is
  /// derived from the input test request.
  /// - "INVALID_ARGUMENT" : Aborted because the source and/or destination
  /// endpoint specified in the test are invalid. The possible reasons that an
  /// endpoint is invalid include: malformed IP address; nonexistent instance or
  /// network URI; IP address not in the range of specified network URI; and
  /// instance not owning the network interface in the specified network.
  /// - "NO_EXTERNAL_IP" : Aborted because traffic is sent from a public IP to
  /// an instance without an external IP.
  /// - "UNINTENDED_DESTINATION" : Aborted because none of the traces matches
  /// destination information specified in the input test request.
  /// - "TRACE_TOO_LONG" : Aborted because the number of steps in the trace
  /// exceeding a certain limit which may be caused by routing loop.
  /// - "INTERNAL_ERROR" : Aborted due to internal server error.
  /// - "SOURCE_ENDPOINT_NOT_FOUND" : Aborted because the source endpoint could
  /// not be found.
  /// - "MISMATCHED_SOURCE_NETWORK" : Aborted because the source network does
  /// not match the source endpoint.
  /// - "DESTINATION_ENDPOINT_NOT_FOUND" : Aborted because the destination
  /// endpoint could not be found.
  /// - "MISMATCHED_DESTINATION_NETWORK" : Aborted because the destination
  /// network does not match the destination endpoint.
  core.String? cause;

  /// URI of the resource that caused the abort.
  core.String? resourceUri;

  AbortInfo();

  AbortInfo.fromJson(core.Map _json) {
    if (_json.containsKey('cause')) {
      cause = _json['cause'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cause != null) 'cause': cause!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
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
class AuditConfig {
  /// The configuration for logging of each type of permission.
  core.List<AuditLogConfig>? auditLogConfigs;

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
class AuditLogConfig {
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

  AuditLogConfig();

  AuditLogConfig.fromJson(core.Map _json) {
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
class Binding {
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

/// For display only.
///
/// Metadata associated with a Cloud SQL instance.
class CloudSQLInstanceInfo {
  /// Name of a Cloud SQL instance.
  core.String? displayName;

  /// External IP address of a Cloud SQL instance.
  core.String? externalIp;

  /// Internal IP address of a Cloud SQL instance.
  core.String? internalIp;

  /// URI of a Cloud SQL instance network or empty string if the instance does
  /// not have one.
  core.String? networkUri;

  /// Region in which the Cloud SQL instance is running.
  core.String? region;

  /// URI of a Cloud SQL instance.
  core.String? uri;

  CloudSQLInstanceInfo();

  CloudSQLInstanceInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('externalIp')) {
      externalIp = _json['externalIp'] as core.String;
    }
    if (_json.containsKey('internalIp')) {
      internalIp = _json['internalIp'] as core.String;
    }
    if (_json.containsKey('networkUri')) {
      networkUri = _json['networkUri'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (externalIp != null) 'externalIp': externalIp!,
        if (internalIp != null) 'internalIp': internalIp!,
        if (networkUri != null) 'networkUri': networkUri!,
        if (region != null) 'region': region!,
        if (uri != null) 'uri': uri!,
      };
}

/// A Connectivity Test for a network reachability analysis.
class ConnectivityTest {
  /// The time the test was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The user-supplied description of the Connectivity Test.
  ///
  /// Maximum of 512 characters.
  core.String? description;

  /// Destination specification of the Connectivity Test.
  ///
  /// You can use a combination of destination IP address, Compute Engine VM
  /// instance, or VPC network to uniquely identify the destination location.
  /// Even if the destination IP address is not unique, the source IP location
  /// is unique. Usually, the analysis can infer the destination endpoint from
  /// route information. If the destination you specify is a VM instance and the
  /// instance has multiple network interfaces, then you must also specify
  /// either a destination IP address or VPC network to identify the destination
  /// interface. A reachability analysis proceeds even if the destination
  /// location is ambiguous. However, the result can include endpoints that you
  /// don't intend to test.
  ///
  /// Required.
  Endpoint? destination;

  /// The display name of a Connectivity Test.
  ///
  /// Output only.
  core.String? displayName;

  /// Resource labels to represent user-provided metadata.
  core.Map<core.String, core.String>? labels;

  /// Unique name of the resource using the form:
  /// `projects/{project_id}/locations/global/connectivityTests/{test_id}`
  ///
  /// Required.
  core.String? name;

  /// IP Protocol of the test.
  ///
  /// When not provided, "TCP" is assumed.
  core.String? protocol;

  /// The reachability details of this test from the latest run.
  ///
  /// The details are updated when creating a new test, updating an existing
  /// test, or triggering a one-time rerun of an existing test.
  ///
  /// Output only.
  ReachabilityDetails? reachabilityDetails;

  /// Other projects that may be relevant for reachability analysis.
  ///
  /// This is applicable to scenarios where a test can cross project boundaries.
  core.List<core.String>? relatedProjects;

  /// Source specification of the Connectivity Test.
  ///
  /// You can use a combination of source IP address, virtual machine (VM)
  /// instance, or Compute Engine network to uniquely identify the source
  /// location. Examples: If the source IP address is an internal IP address
  /// within a Google Cloud Virtual Private Cloud (VPC) network, then you must
  /// also specify the VPC network. Otherwise, specify the VM instance, which
  /// already contains its internal IP address and VPC network information. If
  /// the source of the test is within an on-premises network, then you must
  /// provide the destination VPC network. If the source endpoint is a Compute
  /// Engine VM instance with multiple network interfaces, the instance itself
  /// is not sufficient to identify the endpoint. So, you must also specify the
  /// source IP address or VPC network. A reachability analysis proceeds even if
  /// the source location is ambiguous. However, the test result may include
  /// endpoints that you don't intend to test.
  ///
  /// Required.
  Endpoint? source;

  /// The time the test's configuration was updated.
  ///
  /// Output only.
  core.String? updateTime;

  ConnectivityTest();

  ConnectivityTest.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('destination')) {
      destination = Endpoint.fromJson(
          _json['destination'] as core.Map<core.String, core.dynamic>);
    }
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
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('reachabilityDetails')) {
      reachabilityDetails = ReachabilityDetails.fromJson(
          _json['reachabilityDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('relatedProjects')) {
      relatedProjects = (_json['relatedProjects'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('source')) {
      source = Endpoint.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (destination != null) 'destination': destination!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (protocol != null) 'protocol': protocol!,
        if (reachabilityDetails != null)
          'reachabilityDetails': reachabilityDetails!.toJson(),
        if (relatedProjects != null) 'relatedProjects': relatedProjects!,
        if (source != null) 'source': source!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Details of the final state "deliver" and associated resource.
class DeliverInfo {
  /// URI of the resource that the packet is delivered to.
  core.String? resourceUri;

  /// Target type where the packet is delivered to.
  /// Possible string values are:
  /// - "TARGET_UNSPECIFIED" : Target not specified.
  /// - "INSTANCE" : Target is a Compute Engine instance.
  /// - "INTERNET" : Target is the internet.
  /// - "GOOGLE_API" : Target is a Google API.
  /// - "GKE_MASTER" : Target is a Google Kubernetes Engine cluster master.
  /// - "CLOUD_SQL_INSTANCE" : Target is a Cloud SQL instance.
  core.String? target;

  DeliverInfo();

  DeliverInfo.fromJson(core.Map _json) {
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
    if (_json.containsKey('target')) {
      target = _json['target'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceUri != null) 'resourceUri': resourceUri!,
        if (target != null) 'target': target!,
      };
}

/// Details of the final state "drop" and associated resource.
class DropInfo {
  /// Cause that the packet is dropped.
  /// Possible string values are:
  /// - "CAUSE_UNSPECIFIED" : Cause is unspecified.
  /// - "UNKNOWN_EXTERNAL_ADDRESS" : Destination external address cannot be
  /// resolved to a known target. If the address is used in a Google Cloud
  /// project, provide the project ID as test input.
  /// - "FOREIGN_IP_DISALLOWED" : A Compute Engine instance can only send or
  /// receive a packet with a foreign IP address if ip_forward is enabled.
  /// - "FIREWALL_RULE" : Dropped due to a firewall rule, unless allowed due to
  /// connection tracking.
  /// - "NO_ROUTE" : Dropped due to no routes.
  /// - "ROUTE_BLACKHOLE" : Dropped due to invalid route. Route's next hop is a
  /// blackhole.
  /// - "ROUTE_WRONG_NETWORK" : Packet is sent to a wrong (unintended) network.
  /// Example: you trace a packet from VM1:Network1 to VM2:Network2, however,
  /// the route configured in Network1 sends the packet destined for VM2's IP
  /// addresss to Network3.
  /// - "PRIVATE_TRAFFIC_TO_INTERNET" : Packet with internal destination address
  /// sent to the internet gateway.
  /// - "PRIVATE_GOOGLE_ACCESS_DISALLOWED" : Instance with only an internal IP
  /// address tries to access Google API and services, but private Google access
  /// is not enabled.
  /// - "NO_EXTERNAL_ADDRESS" : Instance with only an internal IP address tries
  /// to access external hosts, but Cloud NAT is not enabled in the subnet,
  /// unless special configurations on a VM allow this connection. For more
  /// details, see
  /// [Special configurations for VM instances](https://cloud.google.com/vpc/docs/special-configurations).
  /// - "UNKNOWN_INTERNAL_ADDRESS" : Destination internal address cannot be
  /// resolved to a known target. If this is a shared VPC scenario, verify if
  /// the service project ID is provided as test input. Otherwise, verify if the
  /// IP address is being used in the project.
  /// - "FORWARDING_RULE_MISMATCH" : Forwarding rule's protocol and ports do not
  /// match the packet header.
  /// - "FORWARDING_RULE_NO_INSTANCES" : Forwarding rule does not have backends
  /// configured.
  /// - "FIREWALL_BLOCKING_LOAD_BALANCER_BACKEND_HEALTH_CHECK" : Firewalls block
  /// the health check probes to the backends and cause the backends to be
  /// unavailable for traffic from the load balancer. For more details, see
  /// [Health check firewall rules](https://cloud.google.com/load-balancing/docs/health-checks#firewall_rules).
  /// - "INSTANCE_NOT_RUNNING" : Packet is sent from or to a Compute Engine
  /// instance that is not in a running state.
  /// - "TRAFFIC_TYPE_BLOCKED" : The type of traffic is blocked and the user
  /// cannot configure a firewall rule to enable it. See
  /// [Always blocked traffic](https://cloud.google.com/vpc/docs/firewalls#blockedtraffic)
  /// for more details.
  /// - "GKE_MASTER_UNAUTHORIZED_ACCESS" : Access to Google Kubernetes Engine
  /// cluster master's endpoint is not authorized. See
  /// [Access to the cluster endpoints](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#access_to_the_cluster_endpoints)
  /// for more details.
  /// - "CLOUD_SQL_INSTANCE_UNAUTHORIZED_ACCESS" : Access to the Cloud SQL
  /// instance endpoint is not authorized. See
  /// [Authorizing with authorized networks](https://cloud.google.com/sql/docs/mysql/authorize-networks)
  /// for more details.
  /// - "DROPPED_INSIDE_GKE_SERVICE" : Packet was dropped inside Google
  /// Kubernetes Engine Service.
  /// - "DROPPED_INSIDE_CLOUD_SQL_SERVICE" : Packet was dropped inside Cloud SQL
  /// Service.
  /// - "GOOGLE_MANAGED_SERVICE_NO_PEERING" : Packet was dropped because there
  /// is no peering between the originating network and the Google Managed
  /// Services Network.
  /// - "CLOUD_SQL_INSTANCE_NO_IP_ADDRESS" : Packet was dropped because the
  /// Cloud SQL instance has neither a private nor a public IP address.
  core.String? cause;

  /// URI of the resource that caused the drop.
  core.String? resourceUri;

  DropInfo();

  DropInfo.fromJson(core.Map _json) {
    if (_json.containsKey('cause')) {
      cause = _json['cause'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cause != null) 'cause': cause!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
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

/// Source or destination of the Connectivity Test.
class Endpoint {
  /// A [Cloud SQL](https://cloud.google.com/sql) instance URI.
  core.String? cloudSqlInstance;

  /// A cluster URI for
  /// [Google Kubernetes Engine master](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-architecture).
  core.String? gkeMasterCluster;

  /// A Compute Engine instance URI.
  core.String? instance;

  /// The IP address of the endpoint, which can be an external or internal IP.
  ///
  /// An IPv6 address is only allowed when the test's destination is a \[global
  /// load balancer VIP\](/load-balancing/docs/load-balancing-overview).
  core.String? ipAddress;

  /// A Compute Engine network URI.
  core.String? network;

  /// Type of the network where the endpoint is located.
  ///
  /// Applicable only to source endpoint, as destination network type can be
  /// inferred from the source.
  /// Possible string values are:
  /// - "NETWORK_TYPE_UNSPECIFIED" : Default type if unspecified.
  /// - "GCP_NETWORK" : A network hosted within Google Cloud Platform. To
  /// receive more detailed output, specify the URI for the source or
  /// destination network.
  /// - "NON_GCP_NETWORK" : A network hosted outside of Google Cloud Platform.
  /// This can be an on-premises network, or a network hosted by another cloud
  /// provider.
  core.String? networkType;

  /// The IP protocol port of the endpoint.
  ///
  /// Only applicable when protocol is TCP or UDP.
  core.int? port;

  /// Project ID where the endpoint is located.
  ///
  /// The Project ID can be derived from the URI if you provide a VM instance or
  /// network URI. The following are two cases where you must provide the
  /// project ID: 1. Only the IP address is specified, and the IP address is
  /// within a GCP project. 2. When you are using Shared VPC and the IP address
  /// that you provide is from the service project. In this case, the network
  /// that the IP address resides in is defined in the host project.
  core.String? projectId;

  Endpoint();

  Endpoint.fromJson(core.Map _json) {
    if (_json.containsKey('cloudSqlInstance')) {
      cloudSqlInstance = _json['cloudSqlInstance'] as core.String;
    }
    if (_json.containsKey('gkeMasterCluster')) {
      gkeMasterCluster = _json['gkeMasterCluster'] as core.String;
    }
    if (_json.containsKey('instance')) {
      instance = _json['instance'] as core.String;
    }
    if (_json.containsKey('ipAddress')) {
      ipAddress = _json['ipAddress'] as core.String;
    }
    if (_json.containsKey('network')) {
      network = _json['network'] as core.String;
    }
    if (_json.containsKey('networkType')) {
      networkType = _json['networkType'] as core.String;
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.int;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudSqlInstance != null) 'cloudSqlInstance': cloudSqlInstance!,
        if (gkeMasterCluster != null) 'gkeMasterCluster': gkeMasterCluster!,
        if (instance != null) 'instance': instance!,
        if (ipAddress != null) 'ipAddress': ipAddress!,
        if (network != null) 'network': network!,
        if (networkType != null) 'networkType': networkType!,
        if (port != null) 'port': port!,
        if (projectId != null) 'projectId': projectId!,
      };
}

/// For display only.
///
/// The specification of the endpoints for the test. EndpointInfo is derived
/// from source and destination Endpoint and validated by the backend data plane
/// model.
class EndpointInfo {
  /// Destination IP address.
  core.String? destinationIp;

  /// URI of the network where this packet is sent to.
  core.String? destinationNetworkUri;

  /// Destination port.
  ///
  /// Only valid when protocol is TCP or UDP.
  core.int? destinationPort;

  /// IP protocol in string format, for example: "TCP", "UDP", "ICMP".
  core.String? protocol;

  /// Source IP address.
  core.String? sourceIp;

  /// URI of the network where this packet originates from.
  core.String? sourceNetworkUri;

  /// Source port.
  ///
  /// Only valid when protocol is TCP or UDP.
  core.int? sourcePort;

  EndpointInfo();

  EndpointInfo.fromJson(core.Map _json) {
    if (_json.containsKey('destinationIp')) {
      destinationIp = _json['destinationIp'] as core.String;
    }
    if (_json.containsKey('destinationNetworkUri')) {
      destinationNetworkUri = _json['destinationNetworkUri'] as core.String;
    }
    if (_json.containsKey('destinationPort')) {
      destinationPort = _json['destinationPort'] as core.int;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('sourceIp')) {
      sourceIp = _json['sourceIp'] as core.String;
    }
    if (_json.containsKey('sourceNetworkUri')) {
      sourceNetworkUri = _json['sourceNetworkUri'] as core.String;
    }
    if (_json.containsKey('sourcePort')) {
      sourcePort = _json['sourcePort'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationIp != null) 'destinationIp': destinationIp!,
        if (destinationNetworkUri != null)
          'destinationNetworkUri': destinationNetworkUri!,
        if (destinationPort != null) 'destinationPort': destinationPort!,
        if (protocol != null) 'protocol': protocol!,
        if (sourceIp != null) 'sourceIp': sourceIp!,
        if (sourceNetworkUri != null) 'sourceNetworkUri': sourceNetworkUri!,
        if (sourcePort != null) 'sourcePort': sourcePort!,
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

/// For display only.
///
/// Metadata associated with a VPC firewall rule, an implied VPC firewall rule,
/// or a hierarchical firewall policy rule.
class FirewallInfo {
  /// Possible values: ALLOW, DENY
  core.String? action;

  /// Possible values: INGRESS, EGRESS
  core.String? direction;

  /// The display name of the VPC firewall rule.
  ///
  /// This field is not applicable to hierarchical firewall policy rules.
  core.String? displayName;

  /// The firewall rule's type.
  /// Possible string values are:
  /// - "FIREWALL_RULE_TYPE_UNSPECIFIED" : Unspecified type.
  /// - "HIERARCHICAL_FIREWALL_POLICY_RULE" : Hierarchical firewall policy rule.
  /// For details, see
  /// [Hierarchical firewall policies overview](https://cloud.google.com/vpc/docs/firewall-policies).
  /// - "VPC_FIREWALL_RULE" : VPC firewall rule. For details, see
  /// [VPC firewall rules overview](https://cloud.google.com/vpc/docs/firewalls).
  /// - "IMPLIED_VPC_FIREWALL_RULE" : Implied VPC firewall rule. For details,
  /// see
  /// [Implied rules](https://cloud.google.com/vpc/docs/firewalls#default_firewall_rules).
  core.String? firewallRuleType;

  /// The URI of the VPC network that the firewall rule is associated with.
  ///
  /// This field is not applicable to hierarchical firewall policy rules.
  core.String? networkUri;

  /// The hierarchical firewall policy that this rule is associated with.
  ///
  /// This field is not applicable to VPC firewall rules.
  core.String? policy;

  /// The priority of the firewall rule.
  core.int? priority;

  /// The target service accounts specified by the firewall rule.
  core.List<core.String>? targetServiceAccounts;

  /// The target tags defined by the VPC firewall rule.
  ///
  /// This field is not applicable to hierarchical firewall policy rules.
  core.List<core.String>? targetTags;

  /// The URI of the VPC firewall rule.
  ///
  /// This field is not applicable to implied firewall rules or hierarchical
  /// firewall policy rules.
  core.String? uri;

  FirewallInfo();

  FirewallInfo.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('direction')) {
      direction = _json['direction'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('firewallRuleType')) {
      firewallRuleType = _json['firewallRuleType'] as core.String;
    }
    if (_json.containsKey('networkUri')) {
      networkUri = _json['networkUri'] as core.String;
    }
    if (_json.containsKey('policy')) {
      policy = _json['policy'] as core.String;
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.int;
    }
    if (_json.containsKey('targetServiceAccounts')) {
      targetServiceAccounts = (_json['targetServiceAccounts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('targetTags')) {
      targetTags = (_json['targetTags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (direction != null) 'direction': direction!,
        if (displayName != null) 'displayName': displayName!,
        if (firewallRuleType != null) 'firewallRuleType': firewallRuleType!,
        if (networkUri != null) 'networkUri': networkUri!,
        if (policy != null) 'policy': policy!,
        if (priority != null) 'priority': priority!,
        if (targetServiceAccounts != null)
          'targetServiceAccounts': targetServiceAccounts!,
        if (targetTags != null) 'targetTags': targetTags!,
        if (uri != null) 'uri': uri!,
      };
}

/// Details of the final state "forward" and associated resource.
class ForwardInfo {
  /// URI of the resource that the packet is forwarded to.
  core.String? resourceUri;

  /// Target type where this packet is forwarded to.
  /// Possible string values are:
  /// - "TARGET_UNSPECIFIED" : Target not specified.
  /// - "PEERING_VPC" : Forwarded to a VPC peering network.
  /// - "VPN_GATEWAY" : Forwarded to a Cloud VPN gateway.
  /// - "INTERCONNECT" : Forwarded to a Cloud Interconnect connection.
  /// - "GKE_MASTER" : Forwarded to a Google Kubernetes Engine Container cluster
  /// master.
  /// - "IMPORTED_CUSTOM_ROUTE_NEXT_HOP" : Forwarded to the next hop of a custom
  /// route imported from a peering VPC.
  /// - "CLOUD_SQL_INSTANCE" : Forwarded to a Cloud SQL instance.
  core.String? target;

  ForwardInfo();

  ForwardInfo.fromJson(core.Map _json) {
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
    if (_json.containsKey('target')) {
      target = _json['target'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceUri != null) 'resourceUri': resourceUri!,
        if (target != null) 'target': target!,
      };
}

/// For display only.
///
/// Metadata associated with a Compute Engine forwarding rule.
class ForwardingRuleInfo {
  /// Name of a Compute Engine forwarding rule.
  core.String? displayName;

  /// Port range defined in the forwarding rule that matches the test.
  core.String? matchedPortRange;

  /// Protocol defined in the forwarding rule that matches the test.
  core.String? matchedProtocol;

  /// Network URI.
  ///
  /// Only valid for Internal Load Balancer.
  core.String? networkUri;

  /// Target type of the forwarding rule.
  core.String? target;

  /// URI of a Compute Engine forwarding rule.
  core.String? uri;

  /// VIP of the forwarding rule.
  core.String? vip;

  ForwardingRuleInfo();

  ForwardingRuleInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('matchedPortRange')) {
      matchedPortRange = _json['matchedPortRange'] as core.String;
    }
    if (_json.containsKey('matchedProtocol')) {
      matchedProtocol = _json['matchedProtocol'] as core.String;
    }
    if (_json.containsKey('networkUri')) {
      networkUri = _json['networkUri'] as core.String;
    }
    if (_json.containsKey('target')) {
      target = _json['target'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
    if (_json.containsKey('vip')) {
      vip = _json['vip'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (matchedPortRange != null) 'matchedPortRange': matchedPortRange!,
        if (matchedProtocol != null) 'matchedProtocol': matchedProtocol!,
        if (networkUri != null) 'networkUri': networkUri!,
        if (target != null) 'target': target!,
        if (uri != null) 'uri': uri!,
        if (vip != null) 'vip': vip!,
      };
}

/// For display only.
///
/// Metadata associated with a Google Kubernetes Engine (GKE) cluster master.
class GKEMasterInfo {
  /// URI of a GKE cluster network.
  core.String? clusterNetworkUri;

  /// URI of a GKE cluster.
  core.String? clusterUri;

  /// External IP address of a GKE cluster master.
  core.String? externalIp;

  /// Internal IP address of a GKE cluster master.
  core.String? internalIp;

  GKEMasterInfo();

  GKEMasterInfo.fromJson(core.Map _json) {
    if (_json.containsKey('clusterNetworkUri')) {
      clusterNetworkUri = _json['clusterNetworkUri'] as core.String;
    }
    if (_json.containsKey('clusterUri')) {
      clusterUri = _json['clusterUri'] as core.String;
    }
    if (_json.containsKey('externalIp')) {
      externalIp = _json['externalIp'] as core.String;
    }
    if (_json.containsKey('internalIp')) {
      internalIp = _json['internalIp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterNetworkUri != null) 'clusterNetworkUri': clusterNetworkUri!,
        if (clusterUri != null) 'clusterUri': clusterUri!,
        if (externalIp != null) 'externalIp': externalIp!,
        if (internalIp != null) 'internalIp': internalIp!,
      };
}

/// For display only.
///
/// Metadata associated with a Compute Engine instance.
class InstanceInfo {
  /// Name of a Compute Engine instance.
  core.String? displayName;

  /// External IP address of the network interface.
  core.String? externalIp;

  /// Name of the network interface of a Compute Engine instance.
  core.String? interface;

  /// Internal IP address of the network interface.
  core.String? internalIp;

  /// Network tags configured on the instance.
  core.List<core.String>? networkTags;

  /// URI of a Compute Engine network.
  core.String? networkUri;

  /// Service account authorized for the instance.
  core.String? serviceAccount;

  /// URI of a Compute Engine instance.
  core.String? uri;

  InstanceInfo();

  InstanceInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('externalIp')) {
      externalIp = _json['externalIp'] as core.String;
    }
    if (_json.containsKey('interface')) {
      interface = _json['interface'] as core.String;
    }
    if (_json.containsKey('internalIp')) {
      internalIp = _json['internalIp'] as core.String;
    }
    if (_json.containsKey('networkTags')) {
      networkTags = (_json['networkTags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('networkUri')) {
      networkUri = _json['networkUri'] as core.String;
    }
    if (_json.containsKey('serviceAccount')) {
      serviceAccount = _json['serviceAccount'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (externalIp != null) 'externalIp': externalIp!,
        if (interface != null) 'interface': interface!,
        if (internalIp != null) 'internalIp': internalIp!,
        if (networkTags != null) 'networkTags': networkTags!,
        if (networkUri != null) 'networkUri': networkUri!,
        if (serviceAccount != null) 'serviceAccount': serviceAccount!,
        if (uri != null) 'uri': uri!,
      };
}

/// Response for the `ListConnectivityTests` method.
class ListConnectivityTestsResponse {
  /// Page token to fetch the next set of Connectivity Tests.
  core.String? nextPageToken;

  /// List of Connectivity Tests.
  core.List<ConnectivityTest>? resources;

  /// Locations that could not be reached (when querying all locations with
  /// `-`).
  core.List<core.String>? unreachable;

  ListConnectivityTestsResponse();

  ListConnectivityTestsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<ConnectivityTest>((value) => ConnectivityTest.fromJson(
              value as core.Map<core.String, core.dynamic>))
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
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
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

/// For display only.
///
/// Metadata associated with a specific load balancer backend.
class LoadBalancerBackend {
  /// Name of a Compute Engine instance or network endpoint.
  core.String? displayName;

  /// A list of firewall rule URIs allowing probes from health check IP ranges.
  core.List<core.String>? healthCheckAllowingFirewallRules;

  /// A list of firewall rule URIs blocking probes from health check IP ranges.
  core.List<core.String>? healthCheckBlockingFirewallRules;

  /// State of the health check firewall configuration.
  /// Possible string values are:
  /// - "HEALTH_CHECK_FIREWALL_STATE_UNSPECIFIED" : State is unspecified.
  /// Default state if not populated.
  /// - "CONFIGURED" : There are configured firewall rules to allow health check
  /// probes to the backend.
  /// - "MISCONFIGURED" : There are firewall rules configured to allow partial
  /// health check ranges or block all health check ranges. If a health check
  /// probe is sent from denied IP ranges, the health check to the backend will
  /// fail. Then, the backend will be marked unhealthy and will not receive
  /// traffic sent to the load balancer.
  core.String? healthCheckFirewallState;

  /// URI of a Compute Engine instance or network endpoint.
  core.String? uri;

  LoadBalancerBackend();

  LoadBalancerBackend.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('healthCheckAllowingFirewallRules')) {
      healthCheckAllowingFirewallRules =
          (_json['healthCheckAllowingFirewallRules'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('healthCheckBlockingFirewallRules')) {
      healthCheckBlockingFirewallRules =
          (_json['healthCheckBlockingFirewallRules'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('healthCheckFirewallState')) {
      healthCheckFirewallState =
          _json['healthCheckFirewallState'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (healthCheckAllowingFirewallRules != null)
          'healthCheckAllowingFirewallRules': healthCheckAllowingFirewallRules!,
        if (healthCheckBlockingFirewallRules != null)
          'healthCheckBlockingFirewallRules': healthCheckBlockingFirewallRules!,
        if (healthCheckFirewallState != null)
          'healthCheckFirewallState': healthCheckFirewallState!,
        if (uri != null) 'uri': uri!,
      };
}

/// For display only.
///
/// Metadata associated with a load balancer.
class LoadBalancerInfo {
  /// Type of load balancer's backend configuration.
  /// Possible string values are:
  /// - "BACKEND_TYPE_UNSPECIFIED" : Type is unspecified.
  /// - "BACKEND_SERVICE" : Backend Service as the load balancer's backend.
  /// - "TARGET_POOL" : Target Pool as the load balancer's backend.
  core.String? backendType;

  /// Backend configuration URI.
  core.String? backendUri;

  /// Information for the loadbalancer backends.
  core.List<LoadBalancerBackend>? backends;

  /// URI of the health check for the load balancer.
  core.String? healthCheckUri;

  /// Type of the load balancer.
  /// Possible string values are:
  /// - "LOAD_BALANCER_TYPE_UNSPECIFIED" : Type is unspecified.
  /// - "INTERNAL_TCP_UDP" : Internal TCP/UDP load balancer.
  /// - "NETWORK_TCP_UDP" : Network TCP/UDP load balancer.
  /// - "HTTP_PROXY" : HTTP(S) proxy load balancer.
  /// - "TCP_PROXY" : TCP proxy load balancer.
  /// - "SSL_PROXY" : SSL proxy load balancer.
  core.String? loadBalancerType;

  LoadBalancerInfo();

  LoadBalancerInfo.fromJson(core.Map _json) {
    if (_json.containsKey('backendType')) {
      backendType = _json['backendType'] as core.String;
    }
    if (_json.containsKey('backendUri')) {
      backendUri = _json['backendUri'] as core.String;
    }
    if (_json.containsKey('backends')) {
      backends = (_json['backends'] as core.List)
          .map<LoadBalancerBackend>((value) => LoadBalancerBackend.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('healthCheckUri')) {
      healthCheckUri = _json['healthCheckUri'] as core.String;
    }
    if (_json.containsKey('loadBalancerType')) {
      loadBalancerType = _json['loadBalancerType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backendType != null) 'backendType': backendType!,
        if (backendUri != null) 'backendUri': backendUri!,
        if (backends != null)
          'backends': backends!.map((value) => value.toJson()).toList(),
        if (healthCheckUri != null) 'healthCheckUri': healthCheckUri!,
        if (loadBalancerType != null) 'loadBalancerType': loadBalancerType!,
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

/// For display only.
///
/// Metadata associated with a Compute Engine network.
class NetworkInfo {
  /// Name of a Compute Engine network.
  core.String? displayName;

  /// The IP range that matches the test.
  core.String? matchedIpRange;

  /// URI of a Compute Engine network.
  core.String? uri;

  NetworkInfo();

  NetworkInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('matchedIpRange')) {
      matchedIpRange = _json['matchedIpRange'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (matchedIpRange != null) 'matchedIpRange': matchedIpRange!,
        if (uri != null) 'uri': uri!,
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

/// Metadata describing an Operation
class OperationMetadata {
  /// API version.
  core.String? apiVersion;

  /// Specifies if cancellation was requested for the operation.
  core.bool? cancelRequested;

  /// The time the operation was created.
  core.String? createTime;

  /// The time the operation finished running.
  core.String? endTime;

  /// Human-readable status of the operation, if any.
  core.String? statusDetail;

  /// Target of the operation - for example
  /// projects/project-1/locations/global/connectivityTests/test-1
  core.String? target;

  /// Name of the verb executed by the operation.
  core.String? verb;

  OperationMetadata();

  OperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('cancelRequested')) {
      cancelRequested = _json['cancelRequested'] as core.bool;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('statusDetail')) {
      statusDetail = _json['statusDetail'] as core.String;
    }
    if (_json.containsKey('target')) {
      target = _json['target'] as core.String;
    }
    if (_json.containsKey('verb')) {
      verb = _json['verb'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (cancelRequested != null) 'cancelRequested': cancelRequested!,
        if (createTime != null) 'createTime': createTime!,
        if (endTime != null) 'endTime': endTime!,
        if (statusDetail != null) 'statusDetail': statusDetail!,
        if (target != null) 'target': target!,
        if (verb != null) 'verb': verb!,
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

/// Results of the configuration analysis from the last run of the test.
class ReachabilityDetails {
  /// The details of a failure or a cancellation of reachability analysis.
  Status? error;

  /// The overall result of the test's configuration analysis.
  /// Possible string values are:
  /// - "RESULT_UNSPECIFIED" : No result was specified.
  /// - "REACHABLE" : Possible scenarios are: * The configuration analysis
  /// determined that a packet originating from the source is expected to reach
  /// the destination. * The analysis didn't complete because the user lacks
  /// permission for some of the resources in the trace. However, at the time
  /// the user's permission became insufficient, the trace had been successful
  /// so far.
  /// - "UNREACHABLE" : A packet originating from the source is expected to be
  /// dropped before reaching the destination.
  /// - "AMBIGUOUS" : The source and destination endpoints do not uniquely
  /// identify the test location in the network, and the reachability result
  /// contains multiple traces. For some traces, a packet could be delivered,
  /// and for others, it would not be.
  /// - "UNDETERMINED" : The configuration analysis did not complete. Possible
  /// reasons are: * A permissions error occurred--for example, the user might
  /// not have read permission for all of the resources named in the test. * An
  /// internal error occurred. * The analyzer received an invalid or unsupported
  /// argument or was unable to identify a known endpoint.
  core.String? result;

  /// Result may contain a list of traces if a test has multiple possible paths
  /// in the network, such as when destination endpoint is a load balancer with
  /// multiple backends.
  core.List<Trace>? traces;

  /// The time of the configuration analysis.
  core.String? verifyTime;

  ReachabilityDetails();

  ReachabilityDetails.fromJson(core.Map _json) {
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('result')) {
      result = _json['result'] as core.String;
    }
    if (_json.containsKey('traces')) {
      traces = (_json['traces'] as core.List)
          .map<Trace>((value) =>
              Trace.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('verifyTime')) {
      verifyTime = _json['verifyTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null) 'error': error!.toJson(),
        if (result != null) 'result': result!,
        if (traces != null)
          'traces': traces!.map((value) => value.toJson()).toList(),
        if (verifyTime != null) 'verifyTime': verifyTime!,
      };
}

/// Request for the `RerunConnectivityTest` method.
class RerunConnectivityTestRequest {
  RerunConnectivityTestRequest();

  RerunConnectivityTestRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// For display only.
///
/// Metadata associated with a Compute Engine route.
class RouteInfo {
  /// Destination IP range of the route.
  core.String? destIpRange;

  /// Name of a Compute Engine route.
  core.String? displayName;

  /// Instance tags of the route.
  core.List<core.String>? instanceTags;

  /// URI of a Compute Engine network.
  core.String? networkUri;

  /// Next hop of the route.
  core.String? nextHop;

  /// Type of next hop.
  /// Possible string values are:
  /// - "NEXT_HOP_TYPE_UNSPECIFIED" : Unspecified type. Default value.
  /// - "NEXT_HOP_IP" : Next hop is an IP address.
  /// - "NEXT_HOP_INSTANCE" : Next hop is a Compute Engine instance.
  /// - "NEXT_HOP_NETWORK" : Next hop is a VPC network gateway.
  /// - "NEXT_HOP_PEERING" : Next hop is a peering VPC.
  /// - "NEXT_HOP_INTERCONNECT" : Next hop is an interconnect.
  /// - "NEXT_HOP_VPN_TUNNEL" : Next hop is a VPN tunnel.
  /// - "NEXT_HOP_VPN_GATEWAY" : Next hop is a VPN gateway. This scenario only
  /// happens when tracing connectivity from an on-premises network to Google
  /// Cloud through a VPN. The analysis simulates a packet departing from the
  /// on-premises network through a VPN tunnel and arriving at a Cloud VPN
  /// gateway.
  /// - "NEXT_HOP_INTERNET_GATEWAY" : Next hop is an internet gateway.
  /// - "NEXT_HOP_BLACKHOLE" : Next hop is blackhole; that is, the next hop
  /// either does not exist or is not running.
  /// - "NEXT_HOP_ILB" : Next hop is the forwarding rule of an Internal Load
  /// Balancer.
  core.String? nextHopType;

  /// Priority of the route.
  core.int? priority;

  /// Type of route.
  /// Possible string values are:
  /// - "ROUTE_TYPE_UNSPECIFIED" : Unspecified type. Default value.
  /// - "SUBNET" : Route is a subnet route automatically created by the system.
  /// - "STATIC" : Static route created by the user, including the default route
  /// to the internet.
  /// - "DYNAMIC" : Dynamic route exchanged between BGP peers.
  /// - "PEERING_SUBNET" : A subnet route received from peering network.
  /// - "PEERING_STATIC" : A static route received from peering network.
  /// - "PEERING_DYNAMIC" : A dynamic route received from peering network.
  core.String? routeType;

  /// URI of a Compute Engine route.
  ///
  /// Dynamic route from cloud router does not have a URI. Advertised route from
  /// Google Cloud VPC to on-premises network also does not have a URI.
  core.String? uri;

  RouteInfo();

  RouteInfo.fromJson(core.Map _json) {
    if (_json.containsKey('destIpRange')) {
      destIpRange = _json['destIpRange'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('instanceTags')) {
      instanceTags = (_json['instanceTags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('networkUri')) {
      networkUri = _json['networkUri'] as core.String;
    }
    if (_json.containsKey('nextHop')) {
      nextHop = _json['nextHop'] as core.String;
    }
    if (_json.containsKey('nextHopType')) {
      nextHopType = _json['nextHopType'] as core.String;
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.int;
    }
    if (_json.containsKey('routeType')) {
      routeType = _json['routeType'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destIpRange != null) 'destIpRange': destIpRange!,
        if (displayName != null) 'displayName': displayName!,
        if (instanceTags != null) 'instanceTags': instanceTags!,
        if (networkUri != null) 'networkUri': networkUri!,
        if (nextHop != null) 'nextHop': nextHop!,
        if (nextHopType != null) 'nextHopType': nextHopType!,
        if (priority != null) 'priority': priority!,
        if (routeType != null) 'routeType': routeType!,
        if (uri != null) 'uri': uri!,
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

/// A simulated forwarding path is composed of multiple steps.
///
/// Each step has a well-defined state and an associated configuration.
class Step {
  /// Display information of the final state "abort" and reason.
  AbortInfo? abort;

  /// This is a step that leads to the final state Drop.
  core.bool? causesDrop;

  /// Display information of a Cloud SQL instance.
  CloudSQLInstanceInfo? cloudSqlInstance;

  /// Display information of the final state "deliver" and reason.
  DeliverInfo? deliver;

  /// A description of the step.
  ///
  /// Usually this is a summary of the state.
  core.String? description;

  /// Display information of the final state "drop" and reason.
  DropInfo? drop;

  /// Display information of the source and destination under analysis.
  ///
  /// The endpoint information in an intermediate state may differ with the
  /// initial input, as it might be modified by state like NAT, or Connection
  /// Proxy.
  EndpointInfo? endpoint;

  /// Display information of a Compute Engine firewall rule.
  FirewallInfo? firewall;

  /// Display information of the final state "forward" and reason.
  ForwardInfo? forward;

  /// Display information of a Compute Engine forwarding rule.
  ForwardingRuleInfo? forwardingRule;

  /// Display information of a Google Kubernetes Engine cluster master.
  GKEMasterInfo? gkeMaster;

  /// Display information of a Compute Engine instance.
  InstanceInfo? instance;

  /// Display information of the load balancers.
  LoadBalancerInfo? loadBalancer;

  /// Display information of a Google Cloud network.
  NetworkInfo? network;

  /// Project ID that contains the configuration this step is validating.
  core.String? projectId;

  /// Display information of a Compute Engine route.
  RouteInfo? route;

  /// Each step is in one of the pre-defined states.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified state.
  /// - "START_FROM_INSTANCE" : Initial state: packet originating from a Compute
  /// Engine instance. An InstanceInfo is populated with starting instance
  /// information.
  /// - "START_FROM_INTERNET" : Initial state: packet originating from the
  /// internet. The endpoint information is populated.
  /// - "START_FROM_PRIVATE_NETWORK" : Initial state: packet originating from a
  /// VPC or on-premises network with internal source IP. If the source is a VPC
  /// network visible to the user, a NetworkInfo is populated with details of
  /// the network.
  /// - "START_FROM_GKE_MASTER" : Initial state: packet originating from a
  /// Google Kubernetes Engine cluster master. A GKEMasterInfo is populated with
  /// starting instance information.
  /// - "START_FROM_CLOUD_SQL_INSTANCE" : Initial state: packet originating from
  /// a Cloud SQL instance. A CloudSQLInstanceInfo is populated with starting
  /// instance information.
  /// - "APPLY_INGRESS_FIREWALL_RULE" : Config checking state: verify ingress
  /// firewall rule.
  /// - "APPLY_EGRESS_FIREWALL_RULE" : Config checking state: verify egress
  /// firewall rule.
  /// - "APPLY_ROUTE" : Config checking state: verify route.
  /// - "APPLY_FORWARDING_RULE" : Config checking state: match forwarding rule.
  /// - "SPOOFING_APPROVED" : Config checking state: packet sent or received
  /// under foreign IP address and allowed.
  /// - "ARRIVE_AT_INSTANCE" : Forwarding state: arriving at a Compute Engine
  /// instance.
  /// - "ARRIVE_AT_INTERNAL_LOAD_BALANCER" : Forwarding state: arriving at a
  /// Compute Engine internal load balancer.
  /// - "ARRIVE_AT_EXTERNAL_LOAD_BALANCER" : Forwarding state: arriving at a
  /// Compute Engine external load balancer.
  /// - "ARRIVE_AT_VPN_GATEWAY" : Forwarding state: arriving at a Cloud VPN
  /// gateway.
  /// - "ARRIVE_AT_VPN_TUNNEL" : Forwarding state: arriving at a Cloud VPN
  /// tunnel.
  /// - "NAT" : Transition state: packet header translated.
  /// - "PROXY_CONNECTION" : Transition state: original connection is terminated
  /// and a new proxied connection is initiated.
  /// - "DELIVER" : Final state: packet could be delivered.
  /// - "DROP" : Final state: packet could be dropped.
  /// - "FORWARD" : Final state: packet could be forwarded to a network with an
  /// unknown configuration.
  /// - "ABORT" : Final state: analysis is aborted.
  /// - "VIEWER_PERMISSION_MISSING" : Special state: viewer of the test result
  /// does not have permission to see the configuration in this step.
  core.String? state;

  /// Display information of a Compute Engine VPN gateway.
  VpnGatewayInfo? vpnGateway;

  /// Display information of a Compute Engine VPN tunnel.
  VpnTunnelInfo? vpnTunnel;

  Step();

  Step.fromJson(core.Map _json) {
    if (_json.containsKey('abort')) {
      abort = AbortInfo.fromJson(
          _json['abort'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('causesDrop')) {
      causesDrop = _json['causesDrop'] as core.bool;
    }
    if (_json.containsKey('cloudSqlInstance')) {
      cloudSqlInstance = CloudSQLInstanceInfo.fromJson(
          _json['cloudSqlInstance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deliver')) {
      deliver = DeliverInfo.fromJson(
          _json['deliver'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('drop')) {
      drop = DropInfo.fromJson(
          _json['drop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endpoint')) {
      endpoint = EndpointInfo.fromJson(
          _json['endpoint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('firewall')) {
      firewall = FirewallInfo.fromJson(
          _json['firewall'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('forward')) {
      forward = ForwardInfo.fromJson(
          _json['forward'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('forwardingRule')) {
      forwardingRule = ForwardingRuleInfo.fromJson(
          _json['forwardingRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gkeMaster')) {
      gkeMaster = GKEMasterInfo.fromJson(
          _json['gkeMaster'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('instance')) {
      instance = InstanceInfo.fromJson(
          _json['instance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('loadBalancer')) {
      loadBalancer = LoadBalancerInfo.fromJson(
          _json['loadBalancer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('network')) {
      network = NetworkInfo.fromJson(
          _json['network'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('route')) {
      route = RouteInfo.fromJson(
          _json['route'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('vpnGateway')) {
      vpnGateway = VpnGatewayInfo.fromJson(
          _json['vpnGateway'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('vpnTunnel')) {
      vpnTunnel = VpnTunnelInfo.fromJson(
          _json['vpnTunnel'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (abort != null) 'abort': abort!.toJson(),
        if (causesDrop != null) 'causesDrop': causesDrop!,
        if (cloudSqlInstance != null)
          'cloudSqlInstance': cloudSqlInstance!.toJson(),
        if (deliver != null) 'deliver': deliver!.toJson(),
        if (description != null) 'description': description!,
        if (drop != null) 'drop': drop!.toJson(),
        if (endpoint != null) 'endpoint': endpoint!.toJson(),
        if (firewall != null) 'firewall': firewall!.toJson(),
        if (forward != null) 'forward': forward!.toJson(),
        if (forwardingRule != null) 'forwardingRule': forwardingRule!.toJson(),
        if (gkeMaster != null) 'gkeMaster': gkeMaster!.toJson(),
        if (instance != null) 'instance': instance!.toJson(),
        if (loadBalancer != null) 'loadBalancer': loadBalancer!.toJson(),
        if (network != null) 'network': network!.toJson(),
        if (projectId != null) 'projectId': projectId!,
        if (route != null) 'route': route!.toJson(),
        if (state != null) 'state': state!,
        if (vpnGateway != null) 'vpnGateway': vpnGateway!.toJson(),
        if (vpnTunnel != null) 'vpnTunnel': vpnTunnel!.toJson(),
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

/// Trace represents one simulated packet forwarding path.
///
/// * Each trace contains multiple ordered steps. * Each step is in a particular
/// state with associated configuration. * State is categorized as final or
/// non-final states. * Each final state has a reason associated. * Each trace
/// must end with a final state (the last step). ```
/// |---------------------Trace----------------------| Step1(State) Step2(State)
/// --- StepN(State(final)) ```
class Trace {
  /// Derived from the source and destination endpoints definition, and
  /// validated by the data plane model.
  ///
  /// If there are multiple traces starting from different source locations,
  /// then the endpoint_info may be different between traces.
  EndpointInfo? endpointInfo;

  /// A trace of a test contains multiple steps from the initial state to the
  /// final state (delivered, dropped, forwarded, or aborted).
  ///
  /// The steps are ordered by the processing sequence within the simulated
  /// network state machine. It is critical to preserve the order of the steps
  /// and avoid reordering or sorting them.
  core.List<Step>? steps;

  Trace();

  Trace.fromJson(core.Map _json) {
    if (_json.containsKey('endpointInfo')) {
      endpointInfo = EndpointInfo.fromJson(
          _json['endpointInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('steps')) {
      steps = (_json['steps'] as core.List)
          .map<Step>((value) =>
              Step.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endpointInfo != null) 'endpointInfo': endpointInfo!.toJson(),
        if (steps != null)
          'steps': steps!.map((value) => value.toJson()).toList(),
      };
}

/// For display only.
///
/// Metadata associated with a Compute Engine VPN gateway.
class VpnGatewayInfo {
  /// Name of a VPN gateway.
  core.String? displayName;

  /// IP address of the VPN gateway.
  core.String? ipAddress;

  /// URI of a Compute Engine network where the VPN gateway is configured.
  core.String? networkUri;

  /// Name of a Google Cloud region where this VPN gateway is configured.
  core.String? region;

  /// URI of a VPN gateway.
  core.String? uri;

  /// A VPN tunnel that is associated with this VPN gateway.
  ///
  /// There may be multiple VPN tunnels configured on a VPN gateway, and only
  /// the one relevant to the test is displayed.
  core.String? vpnTunnelUri;

  VpnGatewayInfo();

  VpnGatewayInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('ipAddress')) {
      ipAddress = _json['ipAddress'] as core.String;
    }
    if (_json.containsKey('networkUri')) {
      networkUri = _json['networkUri'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
    if (_json.containsKey('vpnTunnelUri')) {
      vpnTunnelUri = _json['vpnTunnelUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (ipAddress != null) 'ipAddress': ipAddress!,
        if (networkUri != null) 'networkUri': networkUri!,
        if (region != null) 'region': region!,
        if (uri != null) 'uri': uri!,
        if (vpnTunnelUri != null) 'vpnTunnelUri': vpnTunnelUri!,
      };
}

/// For display only.
///
/// Metadata associated with a Compute Engine VPN tunnel.
class VpnTunnelInfo {
  /// Name of a VPN tunnel.
  core.String? displayName;

  /// URI of a Compute Engine network where the VPN tunnel is configured.
  core.String? networkUri;

  /// Name of a Google Cloud region where this VPN tunnel is configured.
  core.String? region;

  /// URI of a VPN gateway at remote end of the tunnel.
  core.String? remoteGateway;

  /// Remote VPN gateway's IP address.
  core.String? remoteGatewayIp;

  /// Type of the routing policy.
  /// Possible string values are:
  /// - "ROUTING_TYPE_UNSPECIFIED" : Unspecified type. Default value.
  /// - "ROUTE_BASED" : Route based VPN.
  /// - "POLICY_BASED" : Policy based routing.
  /// - "DYNAMIC" : Dynamic (BGP) routing.
  core.String? routingType;

  /// URI of the VPN gateway at local end of the tunnel.
  core.String? sourceGateway;

  /// Local VPN gateway's IP address.
  core.String? sourceGatewayIp;

  /// URI of a VPN tunnel.
  core.String? uri;

  VpnTunnelInfo();

  VpnTunnelInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('networkUri')) {
      networkUri = _json['networkUri'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('remoteGateway')) {
      remoteGateway = _json['remoteGateway'] as core.String;
    }
    if (_json.containsKey('remoteGatewayIp')) {
      remoteGatewayIp = _json['remoteGatewayIp'] as core.String;
    }
    if (_json.containsKey('routingType')) {
      routingType = _json['routingType'] as core.String;
    }
    if (_json.containsKey('sourceGateway')) {
      sourceGateway = _json['sourceGateway'] as core.String;
    }
    if (_json.containsKey('sourceGatewayIp')) {
      sourceGatewayIp = _json['sourceGatewayIp'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (networkUri != null) 'networkUri': networkUri!,
        if (region != null) 'region': region!,
        if (remoteGateway != null) 'remoteGateway': remoteGateway!,
        if (remoteGatewayIp != null) 'remoteGatewayIp': remoteGatewayIp!,
        if (routingType != null) 'routingType': routingType!,
        if (sourceGateway != null) 'sourceGateway': sourceGateway!,
        if (sourceGatewayIp != null) 'sourceGatewayIp': sourceGatewayIp!,
        if (uri != null) 'uri': uri!,
      };
}

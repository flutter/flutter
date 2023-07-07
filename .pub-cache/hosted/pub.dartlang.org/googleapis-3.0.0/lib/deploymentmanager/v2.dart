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

/// Cloud Deployment Manager V2 API - v2
///
/// The Google Cloud Deployment Manager v2 API provides services for
/// configuring, deploying, and viewing Google Cloud services and APIs via
/// templates which specify deployments of Cloud resources.
///
/// For more information, see <https://cloud.google.com/deployment-manager>
///
/// Create an instance of [DeploymentManagerApi] to access these resources:
///
/// - [DeploymentsResource]
/// - [ManifestsResource]
/// - [OperationsResource]
/// - [ResourcesResource]
/// - [TypesResource]
library deploymentmanager.v2;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Google Cloud Deployment Manager v2 API provides services for
/// configuring, deploying, and viewing Google Cloud services and APIs via
/// templates which specify deployments of Cloud resources.
class DeploymentManagerApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View your data across Google Cloud Platform services
  static const cloudPlatformReadOnlyScope =
      'https://www.googleapis.com/auth/cloud-platform.read-only';

  /// View and manage your Google Cloud Platform management resources and
  /// deployment status information
  static const ndevCloudmanScope =
      'https://www.googleapis.com/auth/ndev.cloudman';

  /// View your Google Cloud Platform management resources and deployment status
  /// information
  static const ndevCloudmanReadonlyScope =
      'https://www.googleapis.com/auth/ndev.cloudman.readonly';

  final commons.ApiRequester _requester;

  DeploymentsResource get deployments => DeploymentsResource(_requester);
  ManifestsResource get manifests => ManifestsResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);
  ResourcesResource get resources => ResourcesResource(_requester);
  TypesResource get types => TypesResource(_requester);

  DeploymentManagerApi(http.Client client,
      {core.String rootUrl = 'https://deploymentmanager.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DeploymentsResource {
  final commons.ApiRequester _requester;

  DeploymentsResource(commons.ApiRequester client) : _requester = client;

  /// Cancels and removes the preview currently associated with the deployment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
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
  async.Future<Operation> cancelPreview(
    DeploymentsCancelPreviewRequest request,
    core.String project,
    core.String deployment, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment') +
        '/cancelPreview';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a deployment and all of the resources in the deployment.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  ///
  /// [deletePolicy] - Sets the policy to use for deleting resources.
  /// Possible string values are:
  /// - "DELETE"
  /// - "ABANDON"
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
    core.String project,
    core.String deployment, {
    core.String? deletePolicy,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (deletePolicy != null) 'deletePolicy': [deletePolicy],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets information about a specific deployment.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Deployment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Deployment> get(
    core.String project,
    core.String deployment, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Deployment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a resource.
  ///
  /// May be empty if no such policy or resource exists.
  ///
  /// Request parameters:
  ///
  /// [project] - Project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z0-9\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [resource] - Name or id of the resource for this request.
  /// Value must have pattern
  /// `\[a-z\](?:\[-a-z0-9_\]{0,61}\[a-z0-9\])?|\[1-9\]\[0-9\]{0,19}`.
  ///
  /// [optionsRequestedPolicyVersion] - Requested IAM Policy version.
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
    core.String project,
    core.String resource, {
    core.int? optionsRequestedPolicyVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (optionsRequestedPolicyVersion != null)
        'optionsRequestedPolicyVersion': ['${optionsRequestedPolicyVersion}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$resource') +
        '/getIamPolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a deployment and all of the resources described by the deployment
  /// manifest.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [createPolicy] - Sets the policy to use for creating new resources.
  /// Possible string values are:
  /// - "CREATE_OR_ACQUIRE"
  /// - "ACQUIRE"
  ///
  /// [preview] - If set to true, creates a deployment and creates "shell"
  /// resources but does not actually instantiate these resources. This allows
  /// you to preview what your deployment looks like. After previewing a
  /// deployment, you can deploy your resources by making a request with the
  /// `update()` method or you can use the `cancelPreview()` method to cancel
  /// the preview altogether. Note that the deployment will still exist after
  /// you cancel the preview and you must separately delete this deployment if
  /// you want to remove it.
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
  async.Future<Operation> insert(
    Deployment request,
    core.String project, {
    core.String? createPolicy,
    core.bool? preview,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (createPolicy != null) 'createPolicy': [createPolicy],
      if (preview != null) 'preview': ['${preview}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all deployments for a given project.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [filter] - A filter expression that filters resources listed in the
  /// response. The expression must specify the field name, a comparison
  /// operator, and the value that you want to use for filtering. The value must
  /// be a string, a number, or a boolean. The comparison operator must be
  /// either `=`, `!=`, `>`, or `<`. For example, if you are filtering Compute
  /// Engine instances, you can exclude instances named `example-instance` by
  /// specifying `name != example-instance`. You can also filter nested fields.
  /// For example, you could specify `scheduling.automaticRestart = false` to
  /// include instances only if they are not scheduled for automatic restarts.
  /// You can use filtering on nested fields to filter based on resource labels.
  /// To filter on multiple expressions, provide each separate expression within
  /// parentheses. For example: ``` (scheduling.automaticRestart = true)
  /// (cpuPlatform = "Intel Skylake") ``` By default, each expression is an
  /// `AND` expression. However, you can include `AND` and `OR` expressions
  /// explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR
  /// (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true)
  /// ```
  ///
  /// [maxResults] - The maximum number of results per page that should be
  /// returned. If the number of available results is larger than `maxResults`,
  /// Compute Engine returns a `nextPageToken` that can be used to get the next
  /// page of results in subsequent list requests. Acceptable values are `0` to
  /// `500`, inclusive. (Default: `500`)
  ///
  /// [orderBy] - Sorts list results by a certain order. By default, results are
  /// returned in alphanumerical order based on the resource name. You can also
  /// sort results in descending order based on the creation timestamp using
  /// `orderBy="creationTimestamp desc"`. This sorts results based on the
  /// `creationTimestamp` field in reverse chronological order (newest result
  /// first). Use this to sort resources like operations so that the newest
  /// operation is returned first. Currently, only sorting by `name` or
  /// `creationTimestamp desc` is supported.
  ///
  /// [pageToken] - Specifies a page token to use. Set `pageToken` to the
  /// `nextPageToken` returned by a previous list request to get the next page
  /// of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeploymentsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeploymentsListResponse> list(
    core.String project, {
    core.String? filter,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DeploymentsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a deployment and all of the resources described by the deployment
  /// manifest.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [createPolicy] - Sets the policy to use for creating new resources.
  /// Possible string values are:
  /// - "CREATE_OR_ACQUIRE"
  /// - "ACQUIRE"
  ///
  /// [deletePolicy] - Sets the policy to use for deleting resources.
  /// Possible string values are:
  /// - "DELETE"
  /// - "ABANDON"
  ///
  /// [preview] - If set to true, updates the deployment and creates and updates
  /// the "shell" resources but does not actually alter or instantiate these
  /// resources. This allows you to preview what your deployment will look like.
  /// You can use this intent to preview how an update would affect your
  /// deployment. You must provide a `target.config` with a configuration if
  /// this is set to true. After previewing a deployment, you can deploy your
  /// resources by making a request with the `update()` or you can
  /// `cancelPreview()` to remove the preview altogether. Note that the
  /// deployment will still exist after you cancel the preview and you must
  /// separately delete this deployment if you want to remove it.
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
    Deployment request,
    core.String project,
    core.String deployment, {
    core.String? createPolicy,
    core.String? deletePolicy,
    core.bool? preview,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (createPolicy != null) 'createPolicy': [createPolicy],
      if (deletePolicy != null) 'deletePolicy': [deletePolicy],
      if (preview != null) 'preview': ['${preview}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified resource.
  ///
  /// Replaces any existing policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - Project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z0-9\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [resource] - Name or id of the resource for this request.
  /// Value must have pattern
  /// `\[a-z\](?:\[-a-z0-9_\]{0,61}\[a-z0-9\])?|\[1-9\]\[0-9\]{0,19}`.
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
    GlobalSetPolicyRequest request,
    core.String project,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$resource') +
        '/setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Stops an ongoing operation.
  ///
  /// This does not roll back any work that has already been completed, but
  /// prevents any new work from being started.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
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
  async.Future<Operation> stop(
    DeploymentsStopRequest request,
    core.String project,
    core.String deployment, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment') +
        '/stop';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - Project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z0-9\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [resource] - Name or id of the resource for this request.
  /// Value must have pattern
  /// `\[a-z\](?:\[-a-z0-9_\]{0,61}\[a-z0-9\])?|\[1-9\]\[0-9\]{0,19}`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestPermissionsResponse> testIamPermissions(
    TestPermissionsRequest request,
    core.String project,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$resource') +
        '/testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a deployment and all of the resources described by the deployment
  /// manifest.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [createPolicy] - Sets the policy to use for creating new resources.
  /// Possible string values are:
  /// - "CREATE_OR_ACQUIRE"
  /// - "ACQUIRE"
  ///
  /// [deletePolicy] - Sets the policy to use for deleting resources.
  /// Possible string values are:
  /// - "DELETE"
  /// - "ABANDON"
  ///
  /// [preview] - If set to true, updates the deployment and creates and updates
  /// the "shell" resources but does not actually alter or instantiate these
  /// resources. This allows you to preview what your deployment will look like.
  /// You can use this intent to preview how an update would affect your
  /// deployment. You must provide a `target.config` with a configuration if
  /// this is set to true. After previewing a deployment, you can deploy your
  /// resources by making a request with the `update()` or you can
  /// `cancelPreview()` to remove the preview altogether. Note that the
  /// deployment will still exist after you cancel the preview and you must
  /// separately delete this deployment if you want to remove it.
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
  async.Future<Operation> update(
    Deployment request,
    core.String project,
    core.String deployment, {
    core.String? createPolicy,
    core.String? deletePolicy,
    core.bool? preview,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (createPolicy != null) 'createPolicy': [createPolicy],
      if (deletePolicy != null) 'deletePolicy': [deletePolicy],
      if (preview != null) 'preview': ['${preview}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ManifestsResource {
  final commons.ApiRequester _requester;

  ManifestsResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about a specific manifest.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [manifest] - The name of the manifest for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Manifest].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Manifest> get(
    core.String project,
    core.String deployment,
    core.String manifest, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment') +
        '/manifests/' +
        commons.escapeVariable('$manifest');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Manifest.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all manifests for a given deployment.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [filter] - A filter expression that filters resources listed in the
  /// response. The expression must specify the field name, a comparison
  /// operator, and the value that you want to use for filtering. The value must
  /// be a string, a number, or a boolean. The comparison operator must be
  /// either `=`, `!=`, `>`, or `<`. For example, if you are filtering Compute
  /// Engine instances, you can exclude instances named `example-instance` by
  /// specifying `name != example-instance`. You can also filter nested fields.
  /// For example, you could specify `scheduling.automaticRestart = false` to
  /// include instances only if they are not scheduled for automatic restarts.
  /// You can use filtering on nested fields to filter based on resource labels.
  /// To filter on multiple expressions, provide each separate expression within
  /// parentheses. For example: ``` (scheduling.automaticRestart = true)
  /// (cpuPlatform = "Intel Skylake") ``` By default, each expression is an
  /// `AND` expression. However, you can include `AND` and `OR` expressions
  /// explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR
  /// (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true)
  /// ```
  ///
  /// [maxResults] - The maximum number of results per page that should be
  /// returned. If the number of available results is larger than `maxResults`,
  /// Compute Engine returns a `nextPageToken` that can be used to get the next
  /// page of results in subsequent list requests. Acceptable values are `0` to
  /// `500`, inclusive. (Default: `500`)
  ///
  /// [orderBy] - Sorts list results by a certain order. By default, results are
  /// returned in alphanumerical order based on the resource name. You can also
  /// sort results in descending order based on the creation timestamp using
  /// `orderBy="creationTimestamp desc"`. This sorts results based on the
  /// `creationTimestamp` field in reverse chronological order (newest result
  /// first). Use this to sort resources like operations so that the newest
  /// operation is returned first. Currently, only sorting by `name` or
  /// `creationTimestamp desc` is supported.
  ///
  /// [pageToken] - Specifies a page token to use. Set `pageToken` to the
  /// `nextPageToken` returned by a previous list request to get the next page
  /// of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManifestsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManifestsListResponse> list(
    core.String project,
    core.String deployment, {
    core.String? filter,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment') +
        '/manifests';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ManifestsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about a specific operation.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [operation] - The name of the operation for this request.
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
    core.String project,
    core.String operation, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/operations/' +
        commons.escapeVariable('$operation');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all operations for a project.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [filter] - A filter expression that filters resources listed in the
  /// response. The expression must specify the field name, a comparison
  /// operator, and the value that you want to use for filtering. The value must
  /// be a string, a number, or a boolean. The comparison operator must be
  /// either `=`, `!=`, `>`, or `<`. For example, if you are filtering Compute
  /// Engine instances, you can exclude instances named `example-instance` by
  /// specifying `name != example-instance`. You can also filter nested fields.
  /// For example, you could specify `scheduling.automaticRestart = false` to
  /// include instances only if they are not scheduled for automatic restarts.
  /// You can use filtering on nested fields to filter based on resource labels.
  /// To filter on multiple expressions, provide each separate expression within
  /// parentheses. For example: ``` (scheduling.automaticRestart = true)
  /// (cpuPlatform = "Intel Skylake") ``` By default, each expression is an
  /// `AND` expression. However, you can include `AND` and `OR` expressions
  /// explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR
  /// (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true)
  /// ```
  ///
  /// [maxResults] - The maximum number of results per page that should be
  /// returned. If the number of available results is larger than `maxResults`,
  /// Compute Engine returns a `nextPageToken` that can be used to get the next
  /// page of results in subsequent list requests. Acceptable values are `0` to
  /// `500`, inclusive. (Default: `500`)
  ///
  /// [orderBy] - Sorts list results by a certain order. By default, results are
  /// returned in alphanumerical order based on the resource name. You can also
  /// sort results in descending order based on the creation timestamp using
  /// `orderBy="creationTimestamp desc"`. This sorts results based on the
  /// `creationTimestamp` field in reverse chronological order (newest result
  /// first). Use this to sort resources like operations so that the newest
  /// operation is returned first. Currently, only sorting by `name` or
  /// `creationTimestamp desc` is supported.
  ///
  /// [pageToken] - Specifies a page token to use. Set `pageToken` to the
  /// `nextPageToken` returned by a previous list request to get the next page
  /// of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OperationsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OperationsListResponse> list(
    core.String project, {
    core.String? filter,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OperationsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ResourcesResource {
  final commons.ApiRequester _requester;

  ResourcesResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about a single resource.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [resource] - The name of the resource for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Resource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Resource> get(
    core.String project,
    core.String deployment,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment') +
        '/resources/' +
        commons.escapeVariable('$resource');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Resource.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all resources in a given deployment.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [deployment] - The name of the deployment for this request.
  /// Value must have pattern `\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?`.
  ///
  /// [filter] - A filter expression that filters resources listed in the
  /// response. The expression must specify the field name, a comparison
  /// operator, and the value that you want to use for filtering. The value must
  /// be a string, a number, or a boolean. The comparison operator must be
  /// either `=`, `!=`, `>`, or `<`. For example, if you are filtering Compute
  /// Engine instances, you can exclude instances named `example-instance` by
  /// specifying `name != example-instance`. You can also filter nested fields.
  /// For example, you could specify `scheduling.automaticRestart = false` to
  /// include instances only if they are not scheduled for automatic restarts.
  /// You can use filtering on nested fields to filter based on resource labels.
  /// To filter on multiple expressions, provide each separate expression within
  /// parentheses. For example: ``` (scheduling.automaticRestart = true)
  /// (cpuPlatform = "Intel Skylake") ``` By default, each expression is an
  /// `AND` expression. However, you can include `AND` and `OR` expressions
  /// explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR
  /// (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true)
  /// ```
  ///
  /// [maxResults] - The maximum number of results per page that should be
  /// returned. If the number of available results is larger than `maxResults`,
  /// Compute Engine returns a `nextPageToken` that can be used to get the next
  /// page of results in subsequent list requests. Acceptable values are `0` to
  /// `500`, inclusive. (Default: `500`)
  ///
  /// [orderBy] - Sorts list results by a certain order. By default, results are
  /// returned in alphanumerical order based on the resource name. You can also
  /// sort results in descending order based on the creation timestamp using
  /// `orderBy="creationTimestamp desc"`. This sorts results based on the
  /// `creationTimestamp` field in reverse chronological order (newest result
  /// first). Use this to sort resources like operations so that the newest
  /// operation is returned first. Currently, only sorting by `name` or
  /// `creationTimestamp desc` is supported.
  ///
  /// [pageToken] - Specifies a page token to use. Set `pageToken` to the
  /// `nextPageToken` returned by a previous list request to get the next page
  /// of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ResourcesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ResourcesListResponse> list(
    core.String project,
    core.String deployment, {
    core.String? filter,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/deployments/' +
        commons.escapeVariable('$deployment') +
        '/resources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ResourcesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TypesResource {
  final commons.ApiRequester _requester;

  TypesResource(commons.ApiRequester client) : _requester = client;

  /// Lists all resource types for Deployment Manager.
  ///
  /// Request parameters:
  ///
  /// [project] - The project ID for this request.
  /// Value must have pattern
  /// `(?:(?:\[-a-z0-9\]{1,63}\.)*(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?):)?(?:\[0-9\]{1,19}|(?:\[a-z\](?:\[-a-z0-9\]{0,61}\[a-z0-9\])?))`.
  ///
  /// [filter] - A filter expression that filters resources listed in the
  /// response. The expression must specify the field name, a comparison
  /// operator, and the value that you want to use for filtering. The value must
  /// be a string, a number, or a boolean. The comparison operator must be
  /// either `=`, `!=`, `>`, or `<`. For example, if you are filtering Compute
  /// Engine instances, you can exclude instances named `example-instance` by
  /// specifying `name != example-instance`. You can also filter nested fields.
  /// For example, you could specify `scheduling.automaticRestart = false` to
  /// include instances only if they are not scheduled for automatic restarts.
  /// You can use filtering on nested fields to filter based on resource labels.
  /// To filter on multiple expressions, provide each separate expression within
  /// parentheses. For example: ``` (scheduling.automaticRestart = true)
  /// (cpuPlatform = "Intel Skylake") ``` By default, each expression is an
  /// `AND` expression. However, you can include `AND` and `OR` expressions
  /// explicitly. For example: ``` (cpuPlatform = "Intel Skylake") OR
  /// (cpuPlatform = "Intel Broadwell") AND (scheduling.automaticRestart = true)
  /// ```
  ///
  /// [maxResults] - The maximum number of results per page that should be
  /// returned. If the number of available results is larger than `maxResults`,
  /// Compute Engine returns a `nextPageToken` that can be used to get the next
  /// page of results in subsequent list requests. Acceptable values are `0` to
  /// `500`, inclusive. (Default: `500`)
  ///
  /// [orderBy] - Sorts list results by a certain order. By default, results are
  /// returned in alphanumerical order based on the resource name. You can also
  /// sort results in descending order based on the creation timestamp using
  /// `orderBy="creationTimestamp desc"`. This sorts results based on the
  /// `creationTimestamp` field in reverse chronological order (newest result
  /// first). Use this to sort resources like operations so that the newest
  /// operation is returned first. Currently, only sorting by `name` or
  /// `creationTimestamp desc` is supported.
  ///
  /// [pageToken] - Specifies a page token to use. Set `pageToken` to the
  /// `nextPageToken` returned by a previous list request to get the next page
  /// of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TypesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TypesListResponse> list(
    core.String project, {
    core.String? filter,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'deploymentmanager/v2/projects/' +
        commons.escapeVariable('$project') +
        '/global/types';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TypesListResponse.fromJson(
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

class ConfigFile {
  /// The contents of the file.
  core.String? content;

  ConfigFile();

  ConfigFile.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
      };
}

class Deployment {
  /// An optional user-provided description of the deployment.
  core.String? description;

  /// Provides a fingerprint to use in requests to modify a deployment, such as
  /// `update()`, `stop()`, and `cancelPreview()` requests.
  ///
  /// A fingerprint is a randomly generated value that must be provided with
  /// `update()`, `stop()`, and `cancelPreview()` requests to perform optimistic
  /// locking. This ensures optimistic concurrency so that only one request
  /// happens at a time. The fingerprint is initially generated by Deployment
  /// Manager and changes after every request to modify data. To get the latest
  /// fingerprint value, perform a `get()` request to a deployment.
  core.String? fingerprint;
  core.List<core.int> get fingerprintAsBytes =>
      convert.base64.decode(fingerprint!);

  set fingerprintAsBytes(core.List<core.int> _bytes) {
    fingerprint =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  core.String? id;

  /// Creation timestamp in RFC3339 text format.
  ///
  /// Output only.
  core.String? insertTime;

  /// Map of One Platform labels; provided by the client when the resource is
  /// created or updated.
  ///
  /// Specifically: Label keys must be between 1 and 63 characters long and must
  /// conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?`
  /// Label values must be between 0 and 63 characters long and must conform to
  /// the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`.
  core.List<DeploymentLabelEntry>? labels;

  /// URL of the manifest representing the last manifest that was successfully
  /// deployed.
  ///
  /// If no manifest has been successfully deployed, this field will be absent.
  ///
  /// Output only.
  core.String? manifest;

  /// Name of the resource; provided by the client when the resource is created.
  ///
  /// The name must be 1-63 characters long, and comply with RFC1035.
  /// Specifically, the name must be 1-63 characters long and match the regular
  /// expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character
  /// must be a lowercase letter, and all following characters must be a dash,
  /// lowercase letter, or digit, except the last character, which cannot be a
  /// dash.
  core.String? name;

  /// The Operation that most recently ran, or is currently running, on this
  /// deployment.
  ///
  /// Output only.
  Operation? operation;

  /// Server defined URL for the resource.
  ///
  /// Output only.
  core.String? selfLink;

  /// \[Input Only\] The parameters that define your deployment, including the
  /// deployment configuration and relevant templates.
  TargetConfiguration? target;

  /// If Deployment Manager is currently updating or previewing an update to
  /// this deployment, the updated configuration appears here.
  ///
  /// Output only.
  DeploymentUpdate? update;

  /// Update timestamp in RFC3339 text format.
  ///
  /// Output only.
  core.String? updateTime;

  Deployment();

  Deployment.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('fingerprint')) {
      fingerprint = _json['fingerprint'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('insertTime')) {
      insertTime = _json['insertTime'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.List)
          .map<DeploymentLabelEntry>((value) => DeploymentLabelEntry.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('manifest')) {
      manifest = _json['manifest'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operation')) {
      operation = Operation.fromJson(
          _json['operation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('target')) {
      target = TargetConfiguration.fromJson(
          _json['target'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('update')) {
      update = DeploymentUpdate.fromJson(
          _json['update'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (fingerprint != null) 'fingerprint': fingerprint!,
        if (id != null) 'id': id!,
        if (insertTime != null) 'insertTime': insertTime!,
        if (labels != null)
          'labels': labels!.map((value) => value.toJson()).toList(),
        if (manifest != null) 'manifest': manifest!,
        if (name != null) 'name': name!,
        if (operation != null) 'operation': operation!.toJson(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (target != null) 'target': target!.toJson(),
        if (update != null) 'update': update!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Label object for Deployments
class DeploymentLabelEntry {
  /// Key of the label
  core.String? key;

  /// Value of the label
  core.String? value;

  DeploymentLabelEntry();

  DeploymentLabelEntry.fromJson(core.Map _json) {
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

class DeploymentUpdate {
  /// An optional user-provided description of the deployment after the current
  /// update has been applied.
  ///
  /// Output only.
  core.String? description;

  /// Map of One Platform labels; provided by the client when the resource is
  /// created or updated.
  ///
  /// Specifically: Label keys must be between 1 and 63 characters long and must
  /// conform to the following regular expression: `[a-z]([-a-z0-9]*[a-z0-9])?`
  /// Label values must be between 0 and 63 characters long and must conform to
  /// the regular expression `([a-z]([-a-z0-9]*[a-z0-9])?)?`.
  core.List<DeploymentUpdateLabelEntry>? labels;

  /// URL of the manifest representing the update configuration of this
  /// deployment.
  ///
  /// Output only.
  core.String? manifest;

  DeploymentUpdate();

  DeploymentUpdate.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.List)
          .map<DeploymentUpdateLabelEntry>((value) =>
              DeploymentUpdateLabelEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('manifest')) {
      manifest = _json['manifest'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (labels != null)
          'labels': labels!.map((value) => value.toJson()).toList(),
        if (manifest != null) 'manifest': manifest!,
      };
}

/// Label object for DeploymentUpdate
class DeploymentUpdateLabelEntry {
  /// Key of the label
  core.String? key;

  /// Value of the label
  core.String? value;

  DeploymentUpdateLabelEntry();

  DeploymentUpdateLabelEntry.fromJson(core.Map _json) {
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

class DeploymentsCancelPreviewRequest {
  /// Specifies a fingerprint for `cancelPreview()` requests.
  ///
  /// A fingerprint is a randomly generated value that must be provided in
  /// `cancelPreview()` requests to perform optimistic locking. This ensures
  /// optimistic concurrency so that the deployment does not have conflicting
  /// requests (e.g. if someone attempts to make a new update request while
  /// another user attempts to cancel a preview, this would prevent one of the
  /// requests). The fingerprint is initially generated by Deployment Manager
  /// and changes after every request to modify a deployment. To get the latest
  /// fingerprint value, perform a `get()` request on the deployment.
  core.String? fingerprint;
  core.List<core.int> get fingerprintAsBytes =>
      convert.base64.decode(fingerprint!);

  set fingerprintAsBytes(core.List<core.int> _bytes) {
    fingerprint =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  DeploymentsCancelPreviewRequest();

  DeploymentsCancelPreviewRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fingerprint')) {
      fingerprint = _json['fingerprint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fingerprint != null) 'fingerprint': fingerprint!,
      };
}

/// A response containing a partial list of deployments and a page token used to
/// build the next request if the request has been truncated.
class DeploymentsListResponse {
  /// The deployments contained in this response.
  ///
  /// Output only.
  core.List<Deployment>? deployments;

  /// A token used to continue a truncated list request.
  ///
  /// Output only.
  core.String? nextPageToken;

  DeploymentsListResponse();

  DeploymentsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deployments')) {
      deployments = (_json['deployments'] as core.List)
          .map<Deployment>((value) =>
              Deployment.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deployments != null)
          'deployments': deployments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class DeploymentsStopRequest {
  /// Specifies a fingerprint for `stop()` requests.
  ///
  /// A fingerprint is a randomly generated value that must be provided in
  /// `stop()` requests to perform optimistic locking. This ensures optimistic
  /// concurrency so that the deployment does not have conflicting requests
  /// (e.g. if someone attempts to make a new update request while another user
  /// attempts to stop an ongoing update request, this would prevent a
  /// collision). The fingerprint is initially generated by Deployment Manager
  /// and changes after every request to modify a deployment. To get the latest
  /// fingerprint value, perform a `get()` request on the deployment.
  core.String? fingerprint;
  core.List<core.int> get fingerprintAsBytes =>
      convert.base64.decode(fingerprint!);

  set fingerprintAsBytes(core.List<core.int> _bytes) {
    fingerprint =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  DeploymentsStopRequest();

  DeploymentsStopRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fingerprint')) {
      fingerprint = _json['fingerprint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fingerprint != null) 'fingerprint': fingerprint!,
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

class GlobalSetPolicyRequest {
  /// Flatten Policy to create a backward compatible wire-format.
  ///
  /// Deprecated. Use 'policy' to specify bindings.
  core.List<Binding>? bindings;

  /// Flatten Policy to create a backward compatible wire-format.
  ///
  /// Deprecated. Use 'policy' to specify the etag.
  core.String? etag;
  core.List<core.int> get etagAsBytes => convert.base64.decode(etag!);

  set etagAsBytes(core.List<core.int> _bytes) {
    etag =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// REQUIRED: The complete policy to be applied to the 'resource'.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is
  /// in general a valid policy but certain services (like Projects) might
  /// reject them.
  Policy? policy;

  GlobalSetPolicyRequest();

  GlobalSetPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bindings')) {
      bindings = (_json['bindings'] as core.List)
          .map<Binding>((value) =>
              Binding.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (policy != null) 'policy': policy!.toJson(),
      };
}

class ImportFile {
  /// The contents of the file.
  core.String? content;

  /// The name of the file.
  core.String? name;

  ImportFile();

  ImportFile.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (name != null) 'name': name!,
      };
}

class Manifest {
  /// The YAML configuration for this manifest.
  ///
  /// Output only.
  ConfigFile? config;

  /// The fully-expanded configuration file, including any templates and
  /// references.
  ///
  /// Output only.
  core.String? expandedConfig;
  core.String? id;

  /// The imported files for this manifest.
  ///
  /// Output only.
  core.List<ImportFile>? imports;

  /// Creation timestamp in RFC3339 text format.
  ///
  /// Output only.
  core.String? insertTime;

  /// The YAML layout for this manifest.
  ///
  /// Output only.
  core.String? layout;

  /// The computed size of the fully expanded manifest.
  ///
  /// Output only.
  core.String? manifestSizeBytes;

  /// The size limit for expanded manifests in the project.
  ///
  /// Output only.
  core.String? manifestSizeLimitBytes;

  /// The name of the manifest.
  ///
  /// Output only.
  core.String? name;

  /// Self link for the manifest.
  ///
  /// Output only.
  core.String? selfLink;

  Manifest();

  Manifest.fromJson(core.Map _json) {
    if (_json.containsKey('config')) {
      config = ConfigFile.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('expandedConfig')) {
      expandedConfig = _json['expandedConfig'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('imports')) {
      imports = (_json['imports'] as core.List)
          .map<ImportFile>((value) =>
              ImportFile.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('insertTime')) {
      insertTime = _json['insertTime'] as core.String;
    }
    if (_json.containsKey('layout')) {
      layout = _json['layout'] as core.String;
    }
    if (_json.containsKey('manifestSizeBytes')) {
      manifestSizeBytes = _json['manifestSizeBytes'] as core.String;
    }
    if (_json.containsKey('manifestSizeLimitBytes')) {
      manifestSizeLimitBytes = _json['manifestSizeLimitBytes'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (config != null) 'config': config!.toJson(),
        if (expandedConfig != null) 'expandedConfig': expandedConfig!,
        if (id != null) 'id': id!,
        if (imports != null)
          'imports': imports!.map((value) => value.toJson()).toList(),
        if (insertTime != null) 'insertTime': insertTime!,
        if (layout != null) 'layout': layout!,
        if (manifestSizeBytes != null) 'manifestSizeBytes': manifestSizeBytes!,
        if (manifestSizeLimitBytes != null)
          'manifestSizeLimitBytes': manifestSizeLimitBytes!,
        if (name != null) 'name': name!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A response containing a partial list of manifests and a page token used to
/// build the next request if the request has been truncated.
class ManifestsListResponse {
  /// Manifests contained in this list response.
  ///
  /// Output only.
  core.List<Manifest>? manifests;

  /// A token used to continue a truncated list request.
  ///
  /// Output only.
  core.String? nextPageToken;

  ManifestsListResponse();

  ManifestsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('manifests')) {
      manifests = (_json['manifests'] as core.List)
          .map<Manifest>((value) =>
              Manifest.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (manifests != null)
          'manifests': manifests!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class OperationErrorErrors {
  /// The error type identifier for this error.
  ///
  /// Output only.
  core.String? code;

  /// Indicates the field in the request that caused the error.
  ///
  /// This property is optional.
  ///
  /// Output only.
  core.String? location;

  /// An optional, human-readable error message.
  ///
  /// Output only.
  core.String? message;

  OperationErrorErrors();

  OperationErrorErrors.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (location != null) 'location': location!,
        if (message != null) 'message': message!,
      };
}

/// If errors are generated during processing of the operation, this field will
/// be populated.
///
/// Output only.
class OperationError {
  /// The array of errors encountered while processing this operation.
  ///
  /// Output only.
  core.List<OperationErrorErrors>? errors;

  OperationError();

  OperationError.fromJson(core.Map _json) {
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<OperationErrorErrors>((value) => OperationErrorErrors.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
      };
}

class OperationWarningsData {
  /// A key that provides more detail on the warning being returned.
  ///
  /// For example, for warnings where there are no results in a list request for
  /// a particular zone, this key might be scope and the key value might be the
  /// zone name. Other examples might be a key indicating a deprecated resource
  /// and a suggested replacement, or a warning about invalid network settings
  /// (for example, if an instance attempts to perform IP forwarding but is not
  /// enabled for IP forwarding).
  ///
  /// Output only.
  core.String? key;

  /// A warning data value corresponding to the key.
  ///
  /// Output only.
  core.String? value;

  OperationWarningsData();

  OperationWarningsData.fromJson(core.Map _json) {
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

class OperationWarnings {
  /// A warning code, if applicable.
  ///
  /// For example, Compute Engine returns NO_RESULTS_ON_PAGE if there are no
  /// results in the response.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEPRECATED_RESOURCE_USED" : A link to a deprecated resource was
  /// created.
  /// - "NO_RESULTS_ON_PAGE" : No results are present on a particular list page.
  /// - "UNREACHABLE" : A given scope cannot be reached.
  /// - "NEXT_HOP_ADDRESS_NOT_ASSIGNED" : The route's nextHopIp address is not
  /// assigned to an instance on the network.
  /// - "NEXT_HOP_INSTANCE_NOT_FOUND" : The route's nextHopInstance URL refers
  /// to an instance that does not exist.
  /// - "NEXT_HOP_INSTANCE_NOT_ON_NETWORK" : The route's nextHopInstance URL
  /// refers to an instance that is not on the same network as the route.
  /// - "NEXT_HOP_CANNOT_IP_FORWARD" : The route's next hop instance cannot ip
  /// forward.
  /// - "NEXT_HOP_NOT_RUNNING" : The route's next hop instance does not have a
  /// status of RUNNING.
  /// - "INJECTED_KERNELS_DEPRECATED" : The operation involved use of an
  /// injected kernel, which is deprecated.
  /// - "REQUIRED_TOS_AGREEMENT" : The user attempted to use a resource that
  /// requires a TOS they have not accepted.
  /// - "DISK_SIZE_LARGER_THAN_IMAGE_SIZE" : The user created a boot disk that
  /// is larger than image size.
  /// - "RESOURCE_NOT_DELETED" : One or more of the resources set to auto-delete
  /// could not be deleted because they were in use.
  /// - "SINGLE_INSTANCE_PROPERTY_TEMPLATE" : Instance template used in instance
  /// group manager is valid as such, but its application does not make a lot of
  /// sense, because it allows only single instance in instance group.
  /// - "NOT_CRITICAL_ERROR" : Error which is not critical. We decided to
  /// continue the process despite the mentioned error.
  /// - "CLEANUP_FAILED" : Warning about failed cleanup of transient changes
  /// made by a failed operation.
  /// - "FIELD_VALUE_OVERRIDEN" : Warning that value of a field has been
  /// overridden. Deprecated unused field.
  /// - "RESOURCE_IN_USE_BY_OTHER_RESOURCE_WARNING" : Warning that a resource is
  /// in use.
  /// - "MISSING_TYPE_DEPENDENCY" : A resource depends on a missing type
  /// - "EXTERNAL_API_WARNING" : Warning that is present in an external api call
  /// - "SCHEMA_VALIDATION_IGNORED" : When a resource schema validation is
  /// ignored.
  /// - "UNDECLARED_PROPERTIES" : When undeclared properties in the schema are
  /// present
  /// - "EXPERIMENTAL_TYPE_USED" : When deploying and at least one of the
  /// resources has a type marked as experimental
  /// - "DEPRECATED_TYPE_USED" : When deploying and at least one of the
  /// resources has a type marked as deprecated
  /// - "PARTIAL_SUCCESS" : Success is reported, but some results may be missing
  /// due to errors
  /// - "LARGE_DEPLOYMENT_WARNING" : When deploying a deployment with a
  /// exceedingly large number of resources
  core.String? code;

  /// Metadata about this warning in key: value format.
  ///
  /// For example: "data": \[ { "key": "scope", "value": "zones/us-east1-d" }
  ///
  /// Output only.
  core.List<OperationWarningsData>? data;

  /// A human-readable description of the warning code.
  ///
  /// Output only.
  core.String? message;

  OperationWarnings();

  OperationWarnings.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<OperationWarningsData>((value) => OperationWarningsData.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (message != null) 'message': message!,
      };
}

/// Represents an Operation resource.
///
/// Google Compute Engine has three Operation resources: *
/// \[Global\](/compute/docs/reference/rest/{$api_version}/globalOperations) *
/// \[Regional\](/compute/docs/reference/rest/{$api_version}/regionOperations) *
/// \[Zonal\](/compute/docs/reference/rest/{$api_version}/zoneOperations) You
/// can use an operation resource to manage asynchronous API requests. For more
/// information, read Handling API responses. Operations can be global, regional
/// or zonal. - For global operations, use the `globalOperations` resource. -
/// For regional operations, use the `regionOperations` resource. - For zonal
/// operations, use the `zonalOperations` resource. For more information, read
/// Global, Regional, and Zonal Resources.
class Operation {
  /// The value of `requestId` if you provided it in the request.
  ///
  /// Not present otherwise.
  ///
  /// Output only.
  core.String? clientOperationId;

  /// This field is deprecated.
  ///
  /// Deprecated.
  core.String? creationTimestamp;

  /// A textual description of the operation, which is set when the operation is
  /// created.
  ///
  /// Output only.
  core.String? description;

  /// The time that this operation was completed.
  ///
  /// This value is in RFC3339 text format.
  ///
  /// Output only.
  core.String? endTime;

  /// If errors are generated during processing of the operation, this field
  /// will be populated.
  ///
  /// Output only.
  OperationError? error;

  /// If the operation fails, this field contains the HTTP error message that
  /// was returned, such as `NOT FOUND`.
  ///
  /// Output only.
  core.String? httpErrorMessage;

  /// If the operation fails, this field contains the HTTP error status code
  /// that was returned.
  ///
  /// For example, a `404` means the resource was not found.
  ///
  /// Output only.
  core.int? httpErrorStatusCode;

  /// The unique identifier for the operation.
  ///
  /// This identifier is defined by the server.
  ///
  /// Output only.
  core.String? id;

  /// The time that this operation was requested.
  ///
  /// This value is in RFC3339 text format.
  ///
  /// Output only.
  core.String? insertTime;

  /// Type of the resource.
  ///
  /// Always `compute#operation` for Operation resources.
  ///
  /// Output only.
  core.String? kind;

  /// Name of the operation.
  ///
  /// Output only.
  core.String? name;

  /// An ID that represents a group of operations, such as when a group of
  /// operations results from a `bulkInsert` API request.
  ///
  /// Output only.
  core.String? operationGroupId;

  /// The type of operation, such as `insert`, `update`, or `delete`, and so on.
  ///
  /// Output only.
  core.String? operationType;

  /// An optional progress indicator that ranges from 0 to 100.
  ///
  /// There is no requirement that this be linear or support any granularity of
  /// operations. This should not be used to guess when the operation will be
  /// complete. This number should monotonically increase as the operation
  /// progresses.
  ///
  /// Output only.
  core.int? progress;

  /// The URL of the region where the operation resides.
  ///
  /// Only applicable when performing regional operations.
  ///
  /// Output only.
  core.String? region;

  /// Server-defined URL for the resource.
  ///
  /// Output only.
  core.String? selfLink;

  /// The time that this operation was started by the server.
  ///
  /// This value is in RFC3339 text format.
  ///
  /// Output only.
  core.String? startTime;

  /// The status of the operation, which can be one of the following: `PENDING`,
  /// `RUNNING`, or `DONE`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PENDING"
  /// - "RUNNING"
  /// - "DONE"
  core.String? status;

  /// An optional textual description of the current status of the operation.
  ///
  /// Output only.
  core.String? statusMessage;

  /// The unique target ID, which identifies a specific incarnation of the
  /// target resource.
  ///
  /// Output only.
  core.String? targetId;

  /// The URL of the resource that the operation modifies.
  ///
  /// For operations related to creating a snapshot, this points to the
  /// persistent disk that the snapshot was created from.
  ///
  /// Output only.
  core.String? targetLink;

  /// User who requested the operation, for example: `user@example.com`.
  ///
  /// Output only.
  core.String? user;

  /// If warning messages are generated during processing of the operation, this
  /// field will be populated.
  ///
  /// Output only.
  core.List<OperationWarnings>? warnings;

  /// The URL of the zone where the operation resides.
  ///
  /// Only applicable when performing per-zone operations.
  ///
  /// Output only.
  core.String? zone;

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('clientOperationId')) {
      clientOperationId = _json['clientOperationId'] as core.String;
    }
    if (_json.containsKey('creationTimestamp')) {
      creationTimestamp = _json['creationTimestamp'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('error')) {
      error = OperationError.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('httpErrorMessage')) {
      httpErrorMessage = _json['httpErrorMessage'] as core.String;
    }
    if (_json.containsKey('httpErrorStatusCode')) {
      httpErrorStatusCode = _json['httpErrorStatusCode'] as core.int;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('insertTime')) {
      insertTime = _json['insertTime'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operationGroupId')) {
      operationGroupId = _json['operationGroupId'] as core.String;
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('progress')) {
      progress = _json['progress'] as core.int;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('statusMessage')) {
      statusMessage = _json['statusMessage'] as core.String;
    }
    if (_json.containsKey('targetId')) {
      targetId = _json['targetId'] as core.String;
    }
    if (_json.containsKey('targetLink')) {
      targetLink = _json['targetLink'] as core.String;
    }
    if (_json.containsKey('user')) {
      user = _json['user'] as core.String;
    }
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<OperationWarnings>((value) => OperationWarnings.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientOperationId != null) 'clientOperationId': clientOperationId!,
        if (creationTimestamp != null) 'creationTimestamp': creationTimestamp!,
        if (description != null) 'description': description!,
        if (endTime != null) 'endTime': endTime!,
        if (error != null) 'error': error!.toJson(),
        if (httpErrorMessage != null) 'httpErrorMessage': httpErrorMessage!,
        if (httpErrorStatusCode != null)
          'httpErrorStatusCode': httpErrorStatusCode!,
        if (id != null) 'id': id!,
        if (insertTime != null) 'insertTime': insertTime!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (operationGroupId != null) 'operationGroupId': operationGroupId!,
        if (operationType != null) 'operationType': operationType!,
        if (progress != null) 'progress': progress!,
        if (region != null) 'region': region!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (startTime != null) 'startTime': startTime!,
        if (status != null) 'status': status!,
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (targetId != null) 'targetId': targetId!,
        if (targetLink != null) 'targetLink': targetLink!,
        if (user != null) 'user': user!,
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
        if (zone != null) 'zone': zone!,
      };
}

/// A response containing a partial list of operations and a page token used to
/// build the next request if the request has been truncated.
class OperationsListResponse {
  /// A token used to continue a truncated list request.
  ///
  /// Output only.
  core.String? nextPageToken;

  /// Operations contained in this list response.
  ///
  /// Output only.
  core.List<Operation>? operations;

  OperationsListResponse();

  OperationsListResponse.fromJson(core.Map _json) {
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

class ResourceWarningsData {
  /// A key that provides more detail on the warning being returned.
  ///
  /// For example, for warnings where there are no results in a list request for
  /// a particular zone, this key might be scope and the key value might be the
  /// zone name. Other examples might be a key indicating a deprecated resource
  /// and a suggested replacement, or a warning about invalid network settings
  /// (for example, if an instance attempts to perform IP forwarding but is not
  /// enabled for IP forwarding).
  ///
  /// Output only.
  core.String? key;

  /// A warning data value corresponding to the key.
  ///
  /// Output only.
  core.String? value;

  ResourceWarningsData();

  ResourceWarningsData.fromJson(core.Map _json) {
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

class ResourceWarnings {
  /// A warning code, if applicable.
  ///
  /// For example, Compute Engine returns NO_RESULTS_ON_PAGE if there are no
  /// results in the response.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEPRECATED_RESOURCE_USED" : A link to a deprecated resource was
  /// created.
  /// - "NO_RESULTS_ON_PAGE" : No results are present on a particular list page.
  /// - "UNREACHABLE" : A given scope cannot be reached.
  /// - "NEXT_HOP_ADDRESS_NOT_ASSIGNED" : The route's nextHopIp address is not
  /// assigned to an instance on the network.
  /// - "NEXT_HOP_INSTANCE_NOT_FOUND" : The route's nextHopInstance URL refers
  /// to an instance that does not exist.
  /// - "NEXT_HOP_INSTANCE_NOT_ON_NETWORK" : The route's nextHopInstance URL
  /// refers to an instance that is not on the same network as the route.
  /// - "NEXT_HOP_CANNOT_IP_FORWARD" : The route's next hop instance cannot ip
  /// forward.
  /// - "NEXT_HOP_NOT_RUNNING" : The route's next hop instance does not have a
  /// status of RUNNING.
  /// - "INJECTED_KERNELS_DEPRECATED" : The operation involved use of an
  /// injected kernel, which is deprecated.
  /// - "REQUIRED_TOS_AGREEMENT" : The user attempted to use a resource that
  /// requires a TOS they have not accepted.
  /// - "DISK_SIZE_LARGER_THAN_IMAGE_SIZE" : The user created a boot disk that
  /// is larger than image size.
  /// - "RESOURCE_NOT_DELETED" : One or more of the resources set to auto-delete
  /// could not be deleted because they were in use.
  /// - "SINGLE_INSTANCE_PROPERTY_TEMPLATE" : Instance template used in instance
  /// group manager is valid as such, but its application does not make a lot of
  /// sense, because it allows only single instance in instance group.
  /// - "NOT_CRITICAL_ERROR" : Error which is not critical. We decided to
  /// continue the process despite the mentioned error.
  /// - "CLEANUP_FAILED" : Warning about failed cleanup of transient changes
  /// made by a failed operation.
  /// - "FIELD_VALUE_OVERRIDEN" : Warning that value of a field has been
  /// overridden. Deprecated unused field.
  /// - "RESOURCE_IN_USE_BY_OTHER_RESOURCE_WARNING" : Warning that a resource is
  /// in use.
  /// - "MISSING_TYPE_DEPENDENCY" : A resource depends on a missing type
  /// - "EXTERNAL_API_WARNING" : Warning that is present in an external api call
  /// - "SCHEMA_VALIDATION_IGNORED" : When a resource schema validation is
  /// ignored.
  /// - "UNDECLARED_PROPERTIES" : When undeclared properties in the schema are
  /// present
  /// - "EXPERIMENTAL_TYPE_USED" : When deploying and at least one of the
  /// resources has a type marked as experimental
  /// - "DEPRECATED_TYPE_USED" : When deploying and at least one of the
  /// resources has a type marked as deprecated
  /// - "PARTIAL_SUCCESS" : Success is reported, but some results may be missing
  /// due to errors
  /// - "LARGE_DEPLOYMENT_WARNING" : When deploying a deployment with a
  /// exceedingly large number of resources
  core.String? code;

  /// Metadata about this warning in key: value format.
  ///
  /// For example: "data": \[ { "key": "scope", "value": "zones/us-east1-d" }
  ///
  /// Output only.
  core.List<ResourceWarningsData>? data;

  /// A human-readable description of the warning code.
  ///
  /// Output only.
  core.String? message;

  ResourceWarnings();

  ResourceWarnings.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<ResourceWarningsData>((value) => ResourceWarningsData.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (message != null) 'message': message!,
      };
}

class Resource {
  /// The Access Control Policy set on this resource.
  ResourceAccessControl? accessControl;

  /// The evaluated properties of the resource with references expanded.
  ///
  /// Returned as serialized YAML.
  ///
  /// Output only.
  core.String? finalProperties;
  core.String? id;

  /// Creation timestamp in RFC3339 text format.
  ///
  /// Output only.
  core.String? insertTime;

  /// URL of the manifest representing the current configuration of this
  /// resource.
  ///
  /// Output only.
  core.String? manifest;

  /// The name of the resource as it appears in the YAML config.
  ///
  /// Output only.
  core.String? name;

  /// The current properties of the resource before any references have been
  /// filled in.
  ///
  /// Returned as serialized YAML.
  ///
  /// Output only.
  core.String? properties;

  /// The type of the resource, for example `compute.v1.instance`, or
  /// `cloudfunctions.v1beta1.function`.
  ///
  /// Output only.
  core.String? type;

  /// If Deployment Manager is currently updating or previewing an update to
  /// this resource, the updated configuration appears here.
  ///
  /// Output only.
  ResourceUpdate? update;

  /// Update timestamp in RFC3339 text format.
  ///
  /// Output only.
  core.String? updateTime;

  /// The URL of the actual resource.
  ///
  /// Output only.
  core.String? url;

  /// If warning messages are generated during processing of this resource, this
  /// field will be populated.
  ///
  /// Output only.
  core.List<ResourceWarnings>? warnings;

  Resource();

  Resource.fromJson(core.Map _json) {
    if (_json.containsKey('accessControl')) {
      accessControl = ResourceAccessControl.fromJson(
          _json['accessControl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('finalProperties')) {
      finalProperties = _json['finalProperties'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('insertTime')) {
      insertTime = _json['insertTime'] as core.String;
    }
    if (_json.containsKey('manifest')) {
      manifest = _json['manifest'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('properties')) {
      properties = _json['properties'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('update')) {
      update = ResourceUpdate.fromJson(
          _json['update'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<ResourceWarnings>((value) => ResourceWarnings.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessControl != null) 'accessControl': accessControl!.toJson(),
        if (finalProperties != null) 'finalProperties': finalProperties!,
        if (id != null) 'id': id!,
        if (insertTime != null) 'insertTime': insertTime!,
        if (manifest != null) 'manifest': manifest!,
        if (name != null) 'name': name!,
        if (properties != null) 'properties': properties!,
        if (type != null) 'type': type!,
        if (update != null) 'update': update!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
        if (url != null) 'url': url!,
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// The access controls set on the resource.
class ResourceAccessControl {
  /// The GCP IAM Policy to set on the resource.
  core.String? gcpIamPolicy;

  ResourceAccessControl();

  ResourceAccessControl.fromJson(core.Map _json) {
    if (_json.containsKey('gcpIamPolicy')) {
      gcpIamPolicy = _json['gcpIamPolicy'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcpIamPolicy != null) 'gcpIamPolicy': gcpIamPolicy!,
      };
}

class ResourceUpdateErrorErrors {
  /// The error type identifier for this error.
  ///
  /// Output only.
  core.String? code;

  /// Indicates the field in the request that caused the error.
  ///
  /// This property is optional.
  ///
  /// Output only.
  core.String? location;

  /// An optional, human-readable error message.
  ///
  /// Output only.
  core.String? message;

  ResourceUpdateErrorErrors();

  ResourceUpdateErrorErrors.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (location != null) 'location': location!,
        if (message != null) 'message': message!,
      };
}

/// If errors are generated during update of the resource, this field will be
/// populated.
///
/// Output only.
class ResourceUpdateError {
  /// The array of errors encountered while processing this operation.
  ///
  /// Output only.
  core.List<ResourceUpdateErrorErrors>? errors;

  ResourceUpdateError();

  ResourceUpdateError.fromJson(core.Map _json) {
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<ResourceUpdateErrorErrors>((value) =>
              ResourceUpdateErrorErrors.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
      };
}

class ResourceUpdateWarningsData {
  /// A key that provides more detail on the warning being returned.
  ///
  /// For example, for warnings where there are no results in a list request for
  /// a particular zone, this key might be scope and the key value might be the
  /// zone name. Other examples might be a key indicating a deprecated resource
  /// and a suggested replacement, or a warning about invalid network settings
  /// (for example, if an instance attempts to perform IP forwarding but is not
  /// enabled for IP forwarding).
  ///
  /// Output only.
  core.String? key;

  /// A warning data value corresponding to the key.
  ///
  /// Output only.
  core.String? value;

  ResourceUpdateWarningsData();

  ResourceUpdateWarningsData.fromJson(core.Map _json) {
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

class ResourceUpdateWarnings {
  /// A warning code, if applicable.
  ///
  /// For example, Compute Engine returns NO_RESULTS_ON_PAGE if there are no
  /// results in the response.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEPRECATED_RESOURCE_USED" : A link to a deprecated resource was
  /// created.
  /// - "NO_RESULTS_ON_PAGE" : No results are present on a particular list page.
  /// - "UNREACHABLE" : A given scope cannot be reached.
  /// - "NEXT_HOP_ADDRESS_NOT_ASSIGNED" : The route's nextHopIp address is not
  /// assigned to an instance on the network.
  /// - "NEXT_HOP_INSTANCE_NOT_FOUND" : The route's nextHopInstance URL refers
  /// to an instance that does not exist.
  /// - "NEXT_HOP_INSTANCE_NOT_ON_NETWORK" : The route's nextHopInstance URL
  /// refers to an instance that is not on the same network as the route.
  /// - "NEXT_HOP_CANNOT_IP_FORWARD" : The route's next hop instance cannot ip
  /// forward.
  /// - "NEXT_HOP_NOT_RUNNING" : The route's next hop instance does not have a
  /// status of RUNNING.
  /// - "INJECTED_KERNELS_DEPRECATED" : The operation involved use of an
  /// injected kernel, which is deprecated.
  /// - "REQUIRED_TOS_AGREEMENT" : The user attempted to use a resource that
  /// requires a TOS they have not accepted.
  /// - "DISK_SIZE_LARGER_THAN_IMAGE_SIZE" : The user created a boot disk that
  /// is larger than image size.
  /// - "RESOURCE_NOT_DELETED" : One or more of the resources set to auto-delete
  /// could not be deleted because they were in use.
  /// - "SINGLE_INSTANCE_PROPERTY_TEMPLATE" : Instance template used in instance
  /// group manager is valid as such, but its application does not make a lot of
  /// sense, because it allows only single instance in instance group.
  /// - "NOT_CRITICAL_ERROR" : Error which is not critical. We decided to
  /// continue the process despite the mentioned error.
  /// - "CLEANUP_FAILED" : Warning about failed cleanup of transient changes
  /// made by a failed operation.
  /// - "FIELD_VALUE_OVERRIDEN" : Warning that value of a field has been
  /// overridden. Deprecated unused field.
  /// - "RESOURCE_IN_USE_BY_OTHER_RESOURCE_WARNING" : Warning that a resource is
  /// in use.
  /// - "MISSING_TYPE_DEPENDENCY" : A resource depends on a missing type
  /// - "EXTERNAL_API_WARNING" : Warning that is present in an external api call
  /// - "SCHEMA_VALIDATION_IGNORED" : When a resource schema validation is
  /// ignored.
  /// - "UNDECLARED_PROPERTIES" : When undeclared properties in the schema are
  /// present
  /// - "EXPERIMENTAL_TYPE_USED" : When deploying and at least one of the
  /// resources has a type marked as experimental
  /// - "DEPRECATED_TYPE_USED" : When deploying and at least one of the
  /// resources has a type marked as deprecated
  /// - "PARTIAL_SUCCESS" : Success is reported, but some results may be missing
  /// due to errors
  /// - "LARGE_DEPLOYMENT_WARNING" : When deploying a deployment with a
  /// exceedingly large number of resources
  core.String? code;

  /// Metadata about this warning in key: value format.
  ///
  /// For example: "data": \[ { "key": "scope", "value": "zones/us-east1-d" }
  ///
  /// Output only.
  core.List<ResourceUpdateWarningsData>? data;

  /// A human-readable description of the warning code.
  ///
  /// Output only.
  core.String? message;

  ResourceUpdateWarnings();

  ResourceUpdateWarnings.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<ResourceUpdateWarningsData>((value) =>
              ResourceUpdateWarningsData.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (message != null) 'message': message!,
      };
}

class ResourceUpdate {
  /// The Access Control Policy to set on this resource after updating the
  /// resource itself.
  ResourceAccessControl? accessControl;

  /// If errors are generated during update of the resource, this field will be
  /// populated.
  ///
  /// Output only.
  ResourceUpdateError? error;

  /// The expanded properties of the resource with reference values expanded.
  ///
  /// Returned as serialized YAML.
  ///
  /// Output only.
  core.String? finalProperties;

  /// The intent of the resource: `PREVIEW`, `UPDATE`, or `CANCEL`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CREATE_OR_ACQUIRE" : The resource is scheduled to be created, or if it
  /// already exists, acquired.
  /// - "DELETE" : The resource is scheduled to be deleted.
  /// - "ACQUIRE" : The resource is scheduled to be acquired.
  /// - "UPDATE" : The resource is scheduled to be updated via the UPDATE
  /// method.
  /// - "ABANDON" : The resource is scheduled to be abandoned.
  /// - "CREATE" : The resource is scheduled to be created.
  core.String? intent;

  /// URL of the manifest representing the update configuration of this
  /// resource.
  ///
  /// Output only.
  core.String? manifest;

  /// The set of updated properties for this resource, before references are
  /// expanded.
  ///
  /// Returned as serialized YAML.
  ///
  /// Output only.
  core.String? properties;

  /// The state of the resource.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PENDING" : There are changes pending for this resource.
  /// - "IN_PROGRESS" : The service is executing changes on the resource.
  /// - "IN_PREVIEW" : The service is previewing changes on the resource.
  /// - "FAILED" : The service has failed to change the resource.
  /// - "ABORTED" : The service has aborted trying to change the resource.
  core.String? state;

  /// If warning messages are generated during processing of this resource, this
  /// field will be populated.
  ///
  /// Output only.
  core.List<ResourceUpdateWarnings>? warnings;

  ResourceUpdate();

  ResourceUpdate.fromJson(core.Map _json) {
    if (_json.containsKey('accessControl')) {
      accessControl = ResourceAccessControl.fromJson(
          _json['accessControl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('error')) {
      error = ResourceUpdateError.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('finalProperties')) {
      finalProperties = _json['finalProperties'] as core.String;
    }
    if (_json.containsKey('intent')) {
      intent = _json['intent'] as core.String;
    }
    if (_json.containsKey('manifest')) {
      manifest = _json['manifest'] as core.String;
    }
    if (_json.containsKey('properties')) {
      properties = _json['properties'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<ResourceUpdateWarnings>((value) =>
              ResourceUpdateWarnings.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessControl != null) 'accessControl': accessControl!.toJson(),
        if (error != null) 'error': error!.toJson(),
        if (finalProperties != null) 'finalProperties': finalProperties!,
        if (intent != null) 'intent': intent!,
        if (manifest != null) 'manifest': manifest!,
        if (properties != null) 'properties': properties!,
        if (state != null) 'state': state!,
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// A response containing a partial list of resources and a page token used to
/// build the next request if the request has been truncated.
class ResourcesListResponse {
  /// A token used to continue a truncated list request.
  core.String? nextPageToken;

  /// Resources contained in this list response.
  core.List<Resource>? resources;

  ResourcesListResponse();

  ResourcesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<Resource>((value) =>
              Resource.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class TargetConfiguration {
  /// The configuration to use for this deployment.
  ConfigFile? config;

  /// Specifies any files to import for this configuration.
  ///
  /// This can be used to import templates or other files. For example, you
  /// might import a text file in order to use the file in a template.
  core.List<ImportFile>? imports;

  TargetConfiguration();

  TargetConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('config')) {
      config = ConfigFile.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('imports')) {
      imports = (_json['imports'] as core.List)
          .map<ImportFile>((value) =>
              ImportFile.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (config != null) 'config': config!.toJson(),
        if (imports != null)
          'imports': imports!.map((value) => value.toJson()).toList(),
      };
}

class TestPermissionsRequest {
  /// The set of permissions to check for the 'resource'.
  ///
  /// Permissions with wildcards (such as '*' or 'storage.*') are not allowed.
  core.List<core.String>? permissions;

  TestPermissionsRequest();

  TestPermissionsRequest.fromJson(core.Map _json) {
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

class TestPermissionsResponse {
  /// A subset of `TestPermissionsRequest.permissions` that the caller is
  /// allowed.
  core.List<core.String>? permissions;

  TestPermissionsResponse();

  TestPermissionsResponse.fromJson(core.Map _json) {
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

/// A resource type supported by Deployment Manager.
class Type {
  core.String? id;

  /// Creation timestamp in RFC3339 text format.
  ///
  /// Output only.
  core.String? insertTime;

  /// Name of the type.
  core.String? name;

  /// The Operation that most recently ran, or is currently running, on this
  /// type.
  ///
  /// Output only.
  Operation? operation;

  /// Server defined URL for the resource.
  ///
  /// Output only.
  core.String? selfLink;

  Type();

  Type.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('insertTime')) {
      insertTime = _json['insertTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operation')) {
      operation = Operation.fromJson(
          _json['operation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (insertTime != null) 'insertTime': insertTime!,
        if (name != null) 'name': name!,
        if (operation != null) 'operation': operation!.toJson(),
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// A response that returns all Types supported by Deployment Manager
class TypesListResponse {
  /// A token used to continue a truncated list request.
  core.String? nextPageToken;

  /// A list of resource types supported by Deployment Manager.
  ///
  /// Output only.
  core.List<Type>? types;

  TypesListResponse();

  TypesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('types')) {
      types = (_json['types'] as core.List)
          .map<Type>((value) =>
              Type.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (types != null)
          'types': types!.map((value) => value.toJson()).toList(),
      };
}

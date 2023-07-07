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

/// Google Cloud Memorystore for Redis API - v1
///
/// Creates and manages Redis instances on the Google Cloud Platform.
///
/// For more information, see <https://cloud.google.com/memorystore/docs/redis/>
///
/// Create an instance of [CloudRedisApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsInstancesResource]
///     - [ProjectsLocationsOperationsResource]
library redis.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Creates and manages Redis instances on the Google Cloud Platform.
class CloudRedisApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  CloudRedisApi(http.Client client,
      {core.String rootUrl = 'https://redis.googleapis.com/',
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

  ProjectsLocationsInstancesResource get instances =>
      ProjectsLocationsInstancesResource(_requester);
  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);

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

class ProjectsLocationsInstancesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsInstancesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a Redis instance based on the specified tier and memory size.
  ///
  /// By default, the instance is accessible from the project's
  /// [default network](https://cloud.google.com/vpc/docs/vpc). The creation is
  /// executed asynchronously and callers may check the returned operation to
  /// track its progress. Once the operation is completed the Redis instance
  /// will be fully functional. Completed longrunning.Operation will contain the
  /// new instance object in the response field. The returned operation is
  /// automatically deleted after a few hours, so there is no need to call
  /// DeleteOperation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the instance location using the
  /// form: `projects/{project_id}/locations/{location_id}` where `location_id`
  /// refers to a GCP region.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [instanceId] - Required. The logical name of the Redis instance in the
  /// customer project with the following restrictions: * Must contain only
  /// lowercase letters, numbers, and hyphens. * Must start with a letter. *
  /// Must be between 1-40 characters. * Must end with a number or a letter. *
  /// Must be unique within the customer project / location
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
    Instance request,
    core.String parent, {
    core.String? instanceId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (instanceId != null) 'instanceId': [instanceId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/instances';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a specific Redis instance.
  ///
  /// Instance stops serving and data is deleted.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Redis instance resource name using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// where `location_id` refers to a GCP region.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
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

  /// Export Redis instance data into a Redis RDB format file in Cloud Storage.
  ///
  /// Redis will continue serving during this operation. The returned operation
  /// is automatically deleted after a few hours, so there is no need to call
  /// DeleteOperation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Redis instance resource name using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// where `location_id` refers to a GCP region.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
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
  async.Future<Operation> export(
    ExportInstanceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':export';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Initiates a failover of the primary node to current replica node for a
  /// specific STANDARD tier Cloud Memorystore for Redis instance.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Redis instance resource name using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// where `location_id` refers to a GCP region.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
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
  async.Future<Operation> failover(
    FailoverInstanceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':failover';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the details of a specific Redis instance.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Redis instance resource name using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// where `location_id` refers to a GCP region.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Instance].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Instance> get(
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
    return Instance.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the AUTH string for a Redis instance.
  ///
  /// If AUTH is not enabled for the instance the response will be empty. This
  /// information is not included in the details returned to GetInstance.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Redis instance resource name using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// where `location_id` refers to a GCP region.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InstanceAuthString].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InstanceAuthString> getAuthString(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/authString';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return InstanceAuthString.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Import a Redis RDB snapshot file from Cloud Storage into a Redis instance.
  ///
  /// Redis may stop serving during this operation. Instance state will be
  /// IMPORTING for entire operation. When complete, the instance will contain
  /// only data from the imported file. The returned operation is automatically
  /// deleted after a few hours, so there is no need to call DeleteOperation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Redis instance resource name using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// where `location_id` refers to a GCP region.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
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
  async.Future<Operation> import(
    ImportInstanceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':import';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all Redis instances owned by a project in either the specified
  /// location (region) or all locations.
  ///
  /// The location should have the following format: *
  /// `projects/{project_id}/locations/{location_id}` If `location_id` is
  /// specified as `-` (wildcard), then all regions available to the project are
  /// queried, and the results are aggregated.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the instance location using the
  /// form: `projects/{project_id}/locations/{location_id}` where `location_id`
  /// refers to a GCP region.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return. If not specified, a
  /// default value of 1000 will be used by the service. Regardless of the
  /// page_size value, the response may include a partial list and a caller
  /// should only rely on response's `next_page_token` to determine if there are
  /// more instances left to be queried.
  ///
  /// [pageToken] - The `next_page_token` value returned from a previous
  /// ListInstances request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListInstancesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListInstancesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/instances';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListInstancesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the metadata and configuration of a specific Redis instance.
  ///
  /// Completed longrunning.Operation will contain the new instance object in
  /// the response field. The returned operation is automatically deleted after
  /// a few hours, so there is no need to call DeleteOperation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Unique name of the resource in this scope including
  /// project and location using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// Note: Redis instances are managed and addressed at regional level so
  /// location_id here refers to a GCP region; however, users may choose which
  /// specific zone (or collection of zones for cross-zone instances) an
  /// instance should be provisioned in. Refer to location_id and
  /// alternative_location_id fields for more details.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask of fields to update. At least one path must
  /// be supplied in this field. The elements of the repeated paths field may
  /// only include these fields from Instance: * `displayName` * `labels` *
  /// `memorySizeGb` * `redisConfig`
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
    Instance request,
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

  /// Upgrades Redis instance to the newer Redis version specified in the
  /// request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Redis instance resource name using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// where `location_id` refers to a GCP region.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/instances/\[^/\]+$`.
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
  async.Future<Operation> upgrade(
    UpgradeInstanceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':upgrade';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
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
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
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

/// Request for Export.
class ExportInstanceRequest {
  /// Specify data to be exported.
  ///
  /// Required.
  OutputConfig? outputConfig;

  ExportInstanceRequest();

  ExportInstanceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('outputConfig')) {
      outputConfig = OutputConfig.fromJson(
          _json['outputConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (outputConfig != null) 'outputConfig': outputConfig!.toJson(),
      };
}

/// Request for Failover.
class FailoverInstanceRequest {
  /// Available data protection modes that the user can choose.
  ///
  /// If it's unspecified, data protection mode will be LIMITED_DATA_LOSS by
  /// default.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "DATA_PROTECTION_MODE_UNSPECIFIED" : Defaults to LIMITED_DATA_LOSS if a
  /// data protection mode is not specified.
  /// - "LIMITED_DATA_LOSS" : Instance failover will be protected with data loss
  /// control. More specifically, the failover will only be performed if the
  /// current replication offset diff between primary and replica is under a
  /// certain threshold.
  /// - "FORCE_DATA_LOSS" : Instance failover will be performed without data
  /// loss control.
  core.String? dataProtectionMode;

  FailoverInstanceRequest();

  FailoverInstanceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataProtectionMode')) {
      dataProtectionMode = _json['dataProtectionMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataProtectionMode != null)
          'dataProtectionMode': dataProtectionMode!,
      };
}

/// The Cloud Storage location for the output content
class GcsDestination {
  /// Data destination URI (e.g. 'gs://my_bucket/my_object').
  ///
  /// Existing files will be overwritten.
  ///
  /// Required.
  core.String? uri;

  GcsDestination();

  GcsDestination.fromJson(core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
      };
}

/// The Cloud Storage location for the input content
class GcsSource {
  /// Source data URI.
  ///
  /// (e.g. 'gs://my_bucket/my_object').
  ///
  /// Required.
  core.String? uri;

  GcsSource();

  GcsSource.fromJson(core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
      };
}

/// This location metadata represents additional configuration options for a
/// given location where a Redis instance may be created.
///
/// All fields are output only. It is returned as content of the
/// `google.cloud.location.Location.metadata` field.
class GoogleCloudRedisV1LocationMetadata {
  /// The set of available zones in the location.
  ///
  /// The map is keyed by the lowercase ID of each zone, as defined by GCE.
  /// These keys can be specified in `location_id` or `alternative_location_id`
  /// fields when creating a Redis instance.
  ///
  /// Output only.
  core.Map<core.String, GoogleCloudRedisV1ZoneMetadata>? availableZones;

  GoogleCloudRedisV1LocationMetadata();

  GoogleCloudRedisV1LocationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('availableZones')) {
      availableZones =
          (_json['availableZones'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleCloudRedisV1ZoneMetadata.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (availableZones != null)
          'availableZones': availableZones!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// Represents the v1 metadata of the long-running operation.
class GoogleCloudRedisV1OperationMetadata {
  /// API version.
  core.String? apiVersion;

  /// Specifies if cancellation was requested for the operation.
  core.bool? cancelRequested;

  /// Creation timestamp.
  core.String? createTime;

  /// End timestamp.
  core.String? endTime;

  /// Operation status details.
  core.String? statusDetail;

  /// Operation target.
  core.String? target;

  /// Operation verb.
  core.String? verb;

  GoogleCloudRedisV1OperationMetadata();

  GoogleCloudRedisV1OperationMetadata.fromJson(core.Map _json) {
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

/// Defines specific information for a particular zone.
///
/// Currently empty and reserved for future use only.
class GoogleCloudRedisV1ZoneMetadata {
  GoogleCloudRedisV1ZoneMetadata();

  GoogleCloudRedisV1ZoneMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request for Import.
class ImportInstanceRequest {
  /// Specify data to be imported.
  ///
  /// Required.
  InputConfig? inputConfig;

  ImportInstanceRequest();

  ImportInstanceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('inputConfig')) {
      inputConfig = InputConfig.fromJson(
          _json['inputConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inputConfig != null) 'inputConfig': inputConfig!.toJson(),
      };
}

/// The input content
class InputConfig {
  /// Google Cloud Storage location where input content is located.
  GcsSource? gcsSource;

  InputConfig();

  InputConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gcsSource')) {
      gcsSource = GcsSource.fromJson(
          _json['gcsSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsSource != null) 'gcsSource': gcsSource!.toJson(),
      };
}

/// A Google Cloud Redis instance.
class Instance {
  /// Only applicable to STANDARD_HA tier which protects the instance against
  /// zonal failures by provisioning it across two zones.
  ///
  /// If provided, it must be a different zone from the one provided in
  /// location_id.
  ///
  /// Optional.
  core.String? alternativeLocationId;

  /// Indicates whether OSS Redis AUTH is enabled for the instance.
  ///
  /// If set to "true" AUTH is enabled on the instance. Default value is "false"
  /// meaning AUTH is disabled.
  ///
  /// Optional.
  core.bool? authEnabled;

  /// The full name of the Google Compute Engine
  /// [network](https://cloud.google.com/vpc/docs/vpc) to which the instance is
  /// connected.
  ///
  /// If left unspecified, the `default` network will be used.
  ///
  /// Optional.
  core.String? authorizedNetwork;

  /// The network connect mode of the Redis instance.
  ///
  /// If not provided, the connect mode defaults to DIRECT_PEERING.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "CONNECT_MODE_UNSPECIFIED" : Not set.
  /// - "DIRECT_PEERING" : Connect via direct peering to the Memorystore for
  /// Redis hosted service.
  /// - "PRIVATE_SERVICE_ACCESS" : Connect your Memorystore for Redis instance
  /// using Private Service Access. Private services access provides an IP
  /// address range for multiple Google Cloud services, including Memorystore.
  core.String? connectMode;

  /// The time the instance was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The current zone where the Redis endpoint is placed.
  ///
  /// For Basic Tier instances, this will always be the same as the location_id
  /// provided by the user at creation time. For Standard Tier instances, this
  /// can be either location_id or alternative_location_id and can change after
  /// a failover event.
  ///
  /// Output only.
  core.String? currentLocationId;

  /// An arbitrary and optional user-provided name for the instance.
  core.String? displayName;

  /// Hostname or IP address of the exposed Redis endpoint used by clients to
  /// connect to the service.
  ///
  /// Output only.
  core.String? host;

  /// Resource labels to represent user provided metadata
  core.Map<core.String, core.String>? labels;

  /// The zone where the instance will be provisioned.
  ///
  /// If not provided, the service will choose a zone for the instance. For
  /// STANDARD_HA tier, instances will be created across two zones for
  /// protection against zonal failures. If alternative_location_id is also
  /// provided, it must be different from location_id.
  ///
  /// Optional.
  core.String? locationId;

  /// Redis memory size in GiB.
  ///
  /// Required.
  core.int? memorySizeGb;

  /// Unique name of the resource in this scope including project and location
  /// using the form:
  /// `projects/{project_id}/locations/{location_id}/instances/{instance_id}`
  /// Note: Redis instances are managed and addressed at regional level so
  /// location_id here refers to a GCP region; however, users may choose which
  /// specific zone (or collection of zones for cross-zone instances) an
  /// instance should be provisioned in.
  ///
  /// Refer to location_id and alternative_location_id fields for more details.
  ///
  /// Required.
  core.String? name;

  /// Cloud IAM identity used by import / export operations to transfer data
  /// to/from Cloud Storage.
  ///
  /// Format is "serviceAccount:". The value may change over time for a given
  /// instance so should be checked before each import/export operation.
  ///
  /// Output only.
  core.String? persistenceIamIdentity;

  /// The port number of the exposed Redis endpoint.
  ///
  /// Output only.
  core.int? port;

  /// Redis configuration parameters, according to
  /// http://redis.io/topics/config.
  ///
  /// Currently, the only supported parameters are: Redis version 3.2 and newer:
  /// * maxmemory-policy * notify-keyspace-events Redis version 4.0 and newer: *
  /// activedefrag * lfu-decay-time * lfu-log-factor * maxmemory-gb Redis
  /// version 5.0 and newer: * stream-node-max-bytes * stream-node-max-entries
  ///
  /// Optional.
  core.Map<core.String, core.String>? redisConfigs;

  /// The version of Redis software.
  ///
  /// If not provided, latest supported version will be used. Currently, the
  /// supported values are: * `REDIS_3_2` for Redis 3.2 compatibility *
  /// `REDIS_4_0` for Redis 4.0 compatibility (default) * `REDIS_5_0` for Redis
  /// 5.0 compatibility * `REDIS_6_X` for Redis 6.x compatibility
  ///
  /// Optional.
  core.String? redisVersion;

  /// For DIRECT_PEERING mode, the CIDR range of internal addresses that are
  /// reserved for this instance.
  ///
  /// Range must be unique and non-overlapping with existing subnets in an
  /// authorized network. For PRIVATE_SERVICE_ACCESS mode, the name of one
  /// allocated IP address ranges associated with this private service access
  /// connection. If not provided, the service will choose an unused /29 block,
  /// for example, 10.0.0.0/29 or 192.168.0.0/29.
  ///
  /// Optional.
  core.String? reservedIpRange;

  /// List of server CA certificates for the instance.
  ///
  /// Output only.
  core.List<TlsCertificate>? serverCaCerts;

  /// The current state of this instance.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Not set.
  /// - "CREATING" : Redis instance is being created.
  /// - "READY" : Redis instance has been created and is fully usable.
  /// - "UPDATING" : Redis instance configuration is being updated. Certain
  /// kinds of updates may cause the instance to become unusable while the
  /// update is in progress.
  /// - "DELETING" : Redis instance is being deleted.
  /// - "REPAIRING" : Redis instance is being repaired and may be unusable.
  /// - "MAINTENANCE" : Maintenance is being performed on this Redis instance.
  /// - "IMPORTING" : Redis instance is importing data (availability may be
  /// affected).
  /// - "FAILING_OVER" : Redis instance is failing over (availability may be
  /// affected).
  core.String? state;

  /// Additional information about the current status of this instance, if
  /// available.
  ///
  /// Output only.
  core.String? statusMessage;

  /// The service tier of the instance.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TIER_UNSPECIFIED" : Not set.
  /// - "BASIC" : BASIC tier: standalone instance
  /// - "STANDARD_HA" : STANDARD_HA tier: highly available primary/replica
  /// instances
  core.String? tier;

  /// The TLS mode of the Redis instance.
  ///
  /// If not provided, TLS is disabled for the instance.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "TRANSIT_ENCRYPTION_MODE_UNSPECIFIED" : Not set.
  /// - "SERVER_AUTHENTICATION" : Client to Server traffic encryption enabled
  /// with server authentication.
  /// - "DISABLED" : TLS is disabled for the instance.
  core.String? transitEncryptionMode;

  Instance();

  Instance.fromJson(core.Map _json) {
    if (_json.containsKey('alternativeLocationId')) {
      alternativeLocationId = _json['alternativeLocationId'] as core.String;
    }
    if (_json.containsKey('authEnabled')) {
      authEnabled = _json['authEnabled'] as core.bool;
    }
    if (_json.containsKey('authorizedNetwork')) {
      authorizedNetwork = _json['authorizedNetwork'] as core.String;
    }
    if (_json.containsKey('connectMode')) {
      connectMode = _json['connectMode'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('currentLocationId')) {
      currentLocationId = _json['currentLocationId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
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
    if (_json.containsKey('memorySizeGb')) {
      memorySizeGb = _json['memorySizeGb'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('persistenceIamIdentity')) {
      persistenceIamIdentity = _json['persistenceIamIdentity'] as core.String;
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.int;
    }
    if (_json.containsKey('redisConfigs')) {
      redisConfigs =
          (_json['redisConfigs'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('redisVersion')) {
      redisVersion = _json['redisVersion'] as core.String;
    }
    if (_json.containsKey('reservedIpRange')) {
      reservedIpRange = _json['reservedIpRange'] as core.String;
    }
    if (_json.containsKey('serverCaCerts')) {
      serverCaCerts = (_json['serverCaCerts'] as core.List)
          .map<TlsCertificate>((value) => TlsCertificate.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('statusMessage')) {
      statusMessage = _json['statusMessage'] as core.String;
    }
    if (_json.containsKey('tier')) {
      tier = _json['tier'] as core.String;
    }
    if (_json.containsKey('transitEncryptionMode')) {
      transitEncryptionMode = _json['transitEncryptionMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternativeLocationId != null)
          'alternativeLocationId': alternativeLocationId!,
        if (authEnabled != null) 'authEnabled': authEnabled!,
        if (authorizedNetwork != null) 'authorizedNetwork': authorizedNetwork!,
        if (connectMode != null) 'connectMode': connectMode!,
        if (createTime != null) 'createTime': createTime!,
        if (currentLocationId != null) 'currentLocationId': currentLocationId!,
        if (displayName != null) 'displayName': displayName!,
        if (host != null) 'host': host!,
        if (labels != null) 'labels': labels!,
        if (locationId != null) 'locationId': locationId!,
        if (memorySizeGb != null) 'memorySizeGb': memorySizeGb!,
        if (name != null) 'name': name!,
        if (persistenceIamIdentity != null)
          'persistenceIamIdentity': persistenceIamIdentity!,
        if (port != null) 'port': port!,
        if (redisConfigs != null) 'redisConfigs': redisConfigs!,
        if (redisVersion != null) 'redisVersion': redisVersion!,
        if (reservedIpRange != null) 'reservedIpRange': reservedIpRange!,
        if (serverCaCerts != null)
          'serverCaCerts':
              serverCaCerts!.map((value) => value.toJson()).toList(),
        if (state != null) 'state': state!,
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (tier != null) 'tier': tier!,
        if (transitEncryptionMode != null)
          'transitEncryptionMode': transitEncryptionMode!,
      };
}

/// Instance AUTH string details.
class InstanceAuthString {
  /// AUTH string set on the instance.
  core.String? authString;

  InstanceAuthString();

  InstanceAuthString.fromJson(core.Map _json) {
    if (_json.containsKey('authString')) {
      authString = _json['authString'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authString != null) 'authString': authString!,
      };
}

/// Response for ListInstances.
class ListInstancesResponse {
  /// A list of Redis instances in the project in the specified location, or
  /// across all locations.
  ///
  /// If the `location_id` in the parent field of the request is "-", all
  /// regions available to the project are queried, and the results aggregated.
  /// If in such an aggregated query a location is unavailable, a placeholder
  /// Redis entry is included in the response with the `name` field set to a
  /// value of the form
  /// `projects/{project_id}/locations/{location_id}/instances/`- and the
  /// `status` field set to ERROR and `status_message` field set to "location
  /// not available for ListInstances".
  core.List<Instance>? instances;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListInstancesResponse();

  ListInstancesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('instances')) {
      instances = (_json['instances'] as core.List)
          .map<Instance>((value) =>
              Instance.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (instances != null)
          'instances': instances!.map((value) => value.toJson()).toList(),
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

  /// Resource ID for the region.
  ///
  /// For example: "us-east1".
  core.String? locationId;

  /// The set of available zones in the location.
  ///
  /// The map is keyed by the lowercase ID of each zone, as defined by Compute
  /// Engine. These keys can be specified in `location_id` or
  /// `alternative_location_id` fields when creating a Redis instance.
  ///
  /// Output only.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// Full resource name for the region.
  ///
  /// For example: "projects/example-project/locations/us-east1".
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

  /// { `createTime`: The time the operation was created.
  ///
  /// `endTime`: The time the operation finished running. `target`:
  /// Server-defined resource path for the target of the operation. `verb`: Name
  /// of the verb executed by the operation. `statusDetail`: Human-readable
  /// status of the operation, if any. `cancelRequested`: Identifies whether the
  /// user has requested cancellation of the operation. Operations that have
  /// successfully been cancelled have Operation.error value with a
  /// google.rpc.Status.code of 1, corresponding to `Code.CANCELLED`.
  /// `apiVersion`: API version used to start the operation. }
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

/// The output content
class OutputConfig {
  /// Google Cloud Storage destination for output content.
  GcsDestination? gcsDestination;

  OutputConfig();

  OutputConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gcsDestination')) {
      gcsDestination = GcsDestination.fromJson(
          _json['gcsDestination'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsDestination != null) 'gcsDestination': gcsDestination!.toJson(),
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

/// TlsCertificate Resource
class TlsCertificate {
  /// PEM representation.
  core.String? cert;

  /// The time when the certificate was created in
  /// [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example
  /// `2020-05-18T00:00:00.094Z`.
  ///
  /// Output only.
  core.String? createTime;

  /// The time when the certificate expires in
  /// [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example
  /// `2020-05-18T00:00:00.094Z`.
  ///
  /// Output only.
  core.String? expireTime;

  /// Serial number, as extracted from the certificate.
  core.String? serialNumber;

  /// Sha1 Fingerprint of the certificate.
  core.String? sha1Fingerprint;

  TlsCertificate();

  TlsCertificate.fromJson(core.Map _json) {
    if (_json.containsKey('cert')) {
      cert = _json['cert'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
    }
    if (_json.containsKey('serialNumber')) {
      serialNumber = _json['serialNumber'] as core.String;
    }
    if (_json.containsKey('sha1Fingerprint')) {
      sha1Fingerprint = _json['sha1Fingerprint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cert != null) 'cert': cert!,
        if (createTime != null) 'createTime': createTime!,
        if (expireTime != null) 'expireTime': expireTime!,
        if (serialNumber != null) 'serialNumber': serialNumber!,
        if (sha1Fingerprint != null) 'sha1Fingerprint': sha1Fingerprint!,
      };
}

/// Request for UpgradeInstance.
class UpgradeInstanceRequest {
  /// Specifies the target version of Redis software to upgrade to.
  ///
  /// Required.
  core.String? redisVersion;

  UpgradeInstanceRequest();

  UpgradeInstanceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('redisVersion')) {
      redisVersion = _json['redisVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (redisVersion != null) 'redisVersion': redisVersion!,
      };
}

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

/// Cloud Datastore API - v1
///
/// Accesses the schemaless NoSQL database to provide fully managed, robust,
/// scalable storage for your application.
///
/// For more information, see <https://cloud.google.com/datastore/>
///
/// Create an instance of [DatastoreApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsIndexesResource]
///   - [ProjectsOperationsResource]
library datastore.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Accesses the schemaless NoSQL database to provide fully managed, robust,
/// scalable storage for your application.
class DatastoreApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View and manage your Google Cloud Datastore data
  static const datastoreScope = 'https://www.googleapis.com/auth/datastore';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  DatastoreApi(http.Client client,
      {core.String rootUrl = 'https://datastore.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsIndexesResource get indexes => ProjectsIndexesResource(_requester);
  ProjectsOperationsResource get operations =>
      ProjectsOperationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Allocates IDs for the given keys, which is useful for referencing an
  /// entity before it is inserted.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The ID of the project against which to make the
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AllocateIdsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AllocateIdsResponse> allocateIds(
    AllocateIdsRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':allocateIds';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AllocateIdsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Begins a new transaction.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The ID of the project against which to make the
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BeginTransactionResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BeginTransactionResponse> beginTransaction(
    BeginTransactionRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        ':beginTransaction';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BeginTransactionResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Commits a transaction, optionally creating, deleting or modifying some
  /// entities.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The ID of the project against which to make the
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CommitResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CommitResponse> commit(
    CommitRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':commit';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CommitResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Exports a copy of all or a subset of entities from Google Cloud Datastore
  /// to another storage system, such as Google Cloud Storage.
  ///
  /// Recent updates to entities may not be reflected in the export. The export
  /// occurs in the background and its progress can be monitored and managed via
  /// the Operation resource that is created. The output of an export may only
  /// be used once the associated operation is done. If an export operation is
  /// cancelled before completion it may leave partial data behind in Google
  /// Cloud Storage.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID against which to make the request.
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
  async.Future<GoogleLongrunningOperation> export(
    GoogleDatastoreAdminV1ExportEntitiesRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':export';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Imports entities into Google Cloud Datastore.
  ///
  /// Existing entities with the same key are overwritten. The import occurs in
  /// the background and its progress can be monitored and managed via the
  /// Operation resource that is created. If an ImportEntities operation is
  /// cancelled, it is possible that a subset of the data has already been
  /// imported to Cloud Datastore.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID against which to make the request.
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
  async.Future<GoogleLongrunningOperation> import(
    GoogleDatastoreAdminV1ImportEntitiesRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':import';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up entities by key.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The ID of the project against which to make the
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LookupResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LookupResponse> lookup(
    LookupRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':lookup';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LookupResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Prevents the supplied keys' IDs from being auto-allocated by Cloud
  /// Datastore.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The ID of the project against which to make the
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReserveIdsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReserveIdsResponse> reserveIds(
    ReserveIdsRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':reserveIds';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReserveIdsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Rolls back a transaction.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The ID of the project against which to make the
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RollbackResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RollbackResponse> rollback(
    RollbackRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':rollback';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RollbackResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Queries for entities.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The ID of the project against which to make the
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RunQueryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RunQueryResponse> runQuery(
    RunQueryRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':runQuery';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RunQueryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsIndexesResource {
  final commons.ApiRequester _requester;

  ProjectsIndexesResource(commons.ApiRequester client) : _requester = client;

  /// Creates the specified index.
  ///
  /// A newly created index's initial state is `CREATING`. On completion of the
  /// returned google.longrunning.Operation, the state will be `READY`. If the
  /// index already exists, the call will return an `ALREADY_EXISTS` status.
  /// During index creation, the process could result in an error, in which case
  /// the index will move to the `ERROR` state. The process can be recovered by
  /// fixing the data that caused the error, removing the index with delete,
  /// then re-creating the index with create. Indexes with a single property
  /// cannot be created.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID against which to make the request.
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
    GoogleDatastoreAdminV1Index request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + '/indexes';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an existing index.
  ///
  /// An index can only be deleted if it is in a `READY` or `ERROR` state. On
  /// successful execution of the request, the index will be in a `DELETING`
  /// state. And on completion of the returned google.longrunning.Operation, the
  /// index will be removed. During index deletion, the process could result in
  /// an error, in which case the index will move to the `ERROR` state. The
  /// process can be recovered by fixing the data that caused the error,
  /// followed by calling delete again.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID against which to make the request.
  ///
  /// [indexId] - The resource ID of the index to delete.
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
  async.Future<GoogleLongrunningOperation> delete(
    core.String projectId,
    core.String indexId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/indexes/' +
        commons.escapeVariable('$indexId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets an index.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID against which to make the request.
  ///
  /// [indexId] - The resource ID of the index to get.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleDatastoreAdminV1Index].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleDatastoreAdminV1Index> get(
    core.String projectId,
    core.String indexId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/indexes/' +
        commons.escapeVariable('$indexId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleDatastoreAdminV1Index.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the indexes that match the specified filters.
  ///
  /// Datastore uses an eventually consistent query to fetch the list of indexes
  /// and may occasionally return stale results.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID against which to make the request.
  ///
  /// [filter] - null
  ///
  /// [pageSize] - The maximum number of items to return. If zero, then all
  /// results will be returned.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleDatastoreAdminV1ListIndexesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleDatastoreAdminV1ListIndexesResponse> list(
    core.String projectId, {
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

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + '/indexes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleDatastoreAdminV1ListIndexesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsOperationsResource(commons.ApiRequester client) : _requester = client;

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
  /// Value must have pattern `^projects/\[^/\]+/operations/\[^/\]+$`.
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
  /// Value must have pattern `^projects/\[^/\]+/operations/\[^/\]+$`.
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
  /// Value must have pattern `^projects/\[^/\]+/operations/\[^/\]+$`.
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
  /// [name] - The name of the operation's parent resource.
  /// Value must have pattern `^projects/\[^/\]+$`.
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
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
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
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// The request for Datastore.AllocateIds.
class AllocateIdsRequest {
  /// A list of keys with incomplete key paths for which to allocate IDs.
  ///
  /// No key may be reserved/read-only.
  ///
  /// Required.
  core.List<Key>? keys;

  AllocateIdsRequest();

  AllocateIdsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('keys')) {
      keys = (_json['keys'] as core.List)
          .map<Key>((value) =>
              Key.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keys != null) 'keys': keys!.map((value) => value.toJson()).toList(),
      };
}

/// The response for Datastore.AllocateIds.
class AllocateIdsResponse {
  /// The keys specified in the request (in the same order), each with its key
  /// path completed with a newly allocated ID.
  core.List<Key>? keys;

  AllocateIdsResponse();

  AllocateIdsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('keys')) {
      keys = (_json['keys'] as core.List)
          .map<Key>((value) =>
              Key.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keys != null) 'keys': keys!.map((value) => value.toJson()).toList(),
      };
}

/// An array value.
class ArrayValue {
  /// Values in the array.
  ///
  /// The order of values in an array is preserved as long as all values have
  /// identical settings for 'exclude_from_indexes'.
  core.List<Value>? values;

  ArrayValue();

  ArrayValue.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<Value>((value) =>
              Value.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
      };
}

/// The request for Datastore.BeginTransaction.
class BeginTransactionRequest {
  /// Options for a new transaction.
  TransactionOptions? transactionOptions;

  BeginTransactionRequest();

  BeginTransactionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('transactionOptions')) {
      transactionOptions = TransactionOptions.fromJson(
          _json['transactionOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (transactionOptions != null)
          'transactionOptions': transactionOptions!.toJson(),
      };
}

/// The response for Datastore.BeginTransaction.
class BeginTransactionResponse {
  /// The transaction identifier (always present).
  core.String? transaction;
  core.List<core.int> get transactionAsBytes =>
      convert.base64.decode(transaction!);

  set transactionAsBytes(core.List<core.int> _bytes) {
    transaction =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  BeginTransactionResponse();

  BeginTransactionResponse.fromJson(core.Map _json) {
    if (_json.containsKey('transaction')) {
      transaction = _json['transaction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (transaction != null) 'transaction': transaction!,
      };
}

/// The request for Datastore.Commit.
class CommitRequest {
  /// The type of commit to perform.
  ///
  /// Defaults to `TRANSACTIONAL`.
  /// Possible string values are:
  /// - "MODE_UNSPECIFIED" : Unspecified. This value must not be used.
  /// - "TRANSACTIONAL" : Transactional: The mutations are either all applied,
  /// or none are applied. Learn about transactions
  /// [here](https://cloud.google.com/datastore/docs/concepts/transactions).
  /// - "NON_TRANSACTIONAL" : Non-transactional: The mutations may not apply as
  /// all or none.
  core.String? mode;

  /// The mutations to perform.
  ///
  /// When mode is `TRANSACTIONAL`, mutations affecting a single entity are
  /// applied in order. The following sequences of mutations affecting a single
  /// entity are not permitted in a single `Commit` request: - `insert` followed
  /// by `insert` - `update` followed by `insert` - `upsert` followed by
  /// `insert` - `delete` followed by `update` When mode is `NON_TRANSACTIONAL`,
  /// no two mutations may affect a single entity.
  core.List<Mutation>? mutations;

  /// The identifier of the transaction associated with the commit.
  ///
  /// A transaction identifier is returned by a call to
  /// Datastore.BeginTransaction.
  core.String? transaction;
  core.List<core.int> get transactionAsBytes =>
      convert.base64.decode(transaction!);

  set transactionAsBytes(core.List<core.int> _bytes) {
    transaction =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  CommitRequest();

  CommitRequest.fromJson(core.Map _json) {
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.String;
    }
    if (_json.containsKey('mutations')) {
      mutations = (_json['mutations'] as core.List)
          .map<Mutation>((value) =>
              Mutation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('transaction')) {
      transaction = _json['transaction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mode != null) 'mode': mode!,
        if (mutations != null)
          'mutations': mutations!.map((value) => value.toJson()).toList(),
        if (transaction != null) 'transaction': transaction!,
      };
}

/// The response for Datastore.Commit.
class CommitResponse {
  /// The number of index entries updated during the commit, or zero if none
  /// were updated.
  core.int? indexUpdates;

  /// The result of performing the mutations.
  ///
  /// The i-th mutation result corresponds to the i-th mutation in the request.
  core.List<MutationResult>? mutationResults;

  CommitResponse();

  CommitResponse.fromJson(core.Map _json) {
    if (_json.containsKey('indexUpdates')) {
      indexUpdates = _json['indexUpdates'] as core.int;
    }
    if (_json.containsKey('mutationResults')) {
      mutationResults = (_json['mutationResults'] as core.List)
          .map<MutationResult>((value) => MutationResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (indexUpdates != null) 'indexUpdates': indexUpdates!,
        if (mutationResults != null)
          'mutationResults':
              mutationResults!.map((value) => value.toJson()).toList(),
      };
}

/// A filter that merges multiple other filters using the given operator.
class CompositeFilter {
  /// The list of filters to combine.
  ///
  /// Must contain at least one filter.
  core.List<Filter>? filters;

  /// The operator for combining multiple filters.
  /// Possible string values are:
  /// - "OPERATOR_UNSPECIFIED" : Unspecified. This value must not be used.
  /// - "AND" : The results are required to satisfy each of the combined
  /// filters.
  core.String? op;

  CompositeFilter();

  CompositeFilter.fromJson(core.Map _json) {
    if (_json.containsKey('filters')) {
      filters = (_json['filters'] as core.List)
          .map<Filter>((value) =>
              Filter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('op')) {
      op = _json['op'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filters != null)
          'filters': filters!.map((value) => value.toJson()).toList(),
        if (op != null) 'op': op!,
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

/// A Datastore data object.
///
/// An entity is limited to 1 megabyte when stored. That _roughly_ corresponds
/// to a limit of 1 megabyte for the serialized form of this message.
class Entity {
  /// The entity's key.
  ///
  /// An entity must have a key, unless otherwise documented (for example, an
  /// entity in `Value.entity_value` may have no key). An entity's kind is its
  /// key path's last element's kind, or null if it has no key.
  Key? key;

  /// The entity's properties.
  ///
  /// The map's keys are property names. A property name matching regex `__.*__`
  /// is reserved. A reserved property name is forbidden in certain documented
  /// contexts. The name must not contain more than 500 characters. The name
  /// cannot be `""`.
  core.Map<core.String, Value>? properties;

  Entity();

  Entity.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = Key.fromJson(_json['key'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('properties')) {
      properties =
          (_json['properties'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          Value.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!.toJson(),
        if (properties != null)
          'properties':
              properties!.map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// The result of fetching an entity from Datastore.
class EntityResult {
  /// A cursor that points to the position after the result entity.
  ///
  /// Set only when the `EntityResult` is part of a `QueryResultBatch` message.
  core.String? cursor;
  core.List<core.int> get cursorAsBytes => convert.base64.decode(cursor!);

  set cursorAsBytes(core.List<core.int> _bytes) {
    cursor =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The resulting entity.
  Entity? entity;

  /// The version of the entity, a strictly positive number that monotonically
  /// increases with changes to the entity.
  ///
  /// This field is set for `FULL` entity results. For missing entities in
  /// `LookupResponse`, this is the version of the snapshot that was used to
  /// look up the entity, and it is always set except for eventually consistent
  /// reads.
  core.String? version;

  EntityResult();

  EntityResult.fromJson(core.Map _json) {
    if (_json.containsKey('cursor')) {
      cursor = _json['cursor'] as core.String;
    }
    if (_json.containsKey('entity')) {
      entity = Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cursor != null) 'cursor': cursor!,
        if (entity != null) 'entity': entity!.toJson(),
        if (version != null) 'version': version!,
      };
}

/// A holder for any type of filter.
class Filter {
  /// A composite filter.
  CompositeFilter? compositeFilter;

  /// A filter on a property.
  PropertyFilter? propertyFilter;

  Filter();

  Filter.fromJson(core.Map _json) {
    if (_json.containsKey('compositeFilter')) {
      compositeFilter = CompositeFilter.fromJson(
          _json['compositeFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('propertyFilter')) {
      propertyFilter = PropertyFilter.fromJson(
          _json['propertyFilter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compositeFilter != null)
          'compositeFilter': compositeFilter!.toJson(),
        if (propertyFilter != null) 'propertyFilter': propertyFilter!.toJson(),
      };
}

/// Metadata common to all Datastore Admin operations.
class GoogleDatastoreAdminV1CommonMetadata {
  /// The time the operation ended, either successfully or otherwise.
  core.String? endTime;

  /// The client-assigned labels which were provided when the operation was
  /// created.
  ///
  /// May also include additional labels.
  core.Map<core.String, core.String>? labels;

  /// The type of the operation.
  ///
  /// Can be used as a filter in ListOperationsRequest.
  /// Possible string values are:
  /// - "OPERATION_TYPE_UNSPECIFIED" : Unspecified.
  /// - "EXPORT_ENTITIES" : ExportEntities.
  /// - "IMPORT_ENTITIES" : ImportEntities.
  /// - "CREATE_INDEX" : CreateIndex.
  /// - "DELETE_INDEX" : DeleteIndex.
  core.String? operationType;

  /// The time that work began on the operation.
  core.String? startTime;

  /// The current state of the Operation.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified.
  /// - "INITIALIZING" : Request is being prepared for processing.
  /// - "PROCESSING" : Request is actively being processed.
  /// - "CANCELLING" : Request is in the process of being cancelled after user
  /// called google.longrunning.Operations.CancelOperation on the operation.
  /// - "FINALIZING" : Request has been processed and is in its finalization
  /// stage.
  /// - "SUCCESSFUL" : Request has completed successfully.
  /// - "FAILED" : Request has finished being processed, but encountered an
  /// error.
  /// - "CANCELLED" : Request has finished being cancelled after user called
  /// google.longrunning.Operations.CancelOperation.
  core.String? state;

  GoogleDatastoreAdminV1CommonMetadata();

  GoogleDatastoreAdminV1CommonMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (labels != null) 'labels': labels!,
        if (operationType != null) 'operationType': operationType!,
        if (startTime != null) 'startTime': startTime!,
        if (state != null) 'state': state!,
      };
}

/// Identifies a subset of entities in a project.
///
/// This is specified as combinations of kinds and namespaces (either or both of
/// which may be all, as described in the following examples). Example usage:
/// Entire project: kinds=\[\], namespace_ids=\[\] Kinds Foo and Bar in all
/// namespaces: kinds=\['Foo', 'Bar'\], namespace_ids=\[\] Kinds Foo and Bar
/// only in the default namespace: kinds=\['Foo', 'Bar'\], namespace_ids=\[''\]
/// Kinds Foo and Bar in both the default and Baz namespaces: kinds=\['Foo',
/// 'Bar'\], namespace_ids=\['', 'Baz'\] The entire Baz namespace: kinds=\[\],
/// namespace_ids=\['Baz'\]
class GoogleDatastoreAdminV1EntityFilter {
  /// If empty, then this represents all kinds.
  core.List<core.String>? kinds;

  /// An empty list represents all namespaces.
  ///
  /// This is the preferred usage for projects that don't use namespaces. An
  /// empty string element represents the default namespace. This should be used
  /// if the project has data in non-default namespaces, but doesn't want to
  /// include them. Each namespace in this list must be unique.
  core.List<core.String>? namespaceIds;

  GoogleDatastoreAdminV1EntityFilter();

  GoogleDatastoreAdminV1EntityFilter.fromJson(core.Map _json) {
    if (_json.containsKey('kinds')) {
      kinds = (_json['kinds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('namespaceIds')) {
      namespaceIds = (_json['namespaceIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kinds != null) 'kinds': kinds!,
        if (namespaceIds != null) 'namespaceIds': namespaceIds!,
      };
}

/// Metadata for ExportEntities operations.
class GoogleDatastoreAdminV1ExportEntitiesMetadata {
  /// Metadata common to all Datastore Admin operations.
  GoogleDatastoreAdminV1CommonMetadata? common;

  /// Description of which entities are being exported.
  GoogleDatastoreAdminV1EntityFilter? entityFilter;

  /// Location for the export metadata and data files.
  ///
  /// This will be the same value as the
  /// google.datastore.admin.v1.ExportEntitiesRequest.output_url_prefix field.
  /// The final output location is provided in
  /// google.datastore.admin.v1.ExportEntitiesResponse.output_url.
  core.String? outputUrlPrefix;

  /// An estimate of the number of bytes processed.
  GoogleDatastoreAdminV1Progress? progressBytes;

  /// An estimate of the number of entities processed.
  GoogleDatastoreAdminV1Progress? progressEntities;

  GoogleDatastoreAdminV1ExportEntitiesMetadata();

  GoogleDatastoreAdminV1ExportEntitiesMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('common')) {
      common = GoogleDatastoreAdminV1CommonMetadata.fromJson(
          _json['common'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entityFilter')) {
      entityFilter = GoogleDatastoreAdminV1EntityFilter.fromJson(
          _json['entityFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outputUrlPrefix')) {
      outputUrlPrefix = _json['outputUrlPrefix'] as core.String;
    }
    if (_json.containsKey('progressBytes')) {
      progressBytes = GoogleDatastoreAdminV1Progress.fromJson(
          _json['progressBytes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('progressEntities')) {
      progressEntities = GoogleDatastoreAdminV1Progress.fromJson(
          _json['progressEntities'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (common != null) 'common': common!.toJson(),
        if (entityFilter != null) 'entityFilter': entityFilter!.toJson(),
        if (outputUrlPrefix != null) 'outputUrlPrefix': outputUrlPrefix!,
        if (progressBytes != null) 'progressBytes': progressBytes!.toJson(),
        if (progressEntities != null)
          'progressEntities': progressEntities!.toJson(),
      };
}

/// The request for google.datastore.admin.v1.DatastoreAdmin.ExportEntities.
class GoogleDatastoreAdminV1ExportEntitiesRequest {
  /// Description of what data from the project is included in the export.
  GoogleDatastoreAdminV1EntityFilter? entityFilter;

  /// Client-assigned labels.
  core.Map<core.String, core.String>? labels;

  /// Location for the export metadata and data files.
  ///
  /// The full resource URL of the external storage location. Currently, only
  /// Google Cloud Storage is supported. So output_url_prefix should be of the
  /// form: `gs://BUCKET_NAME[/NAMESPACE_PATH]`, where `BUCKET_NAME` is the name
  /// of the Cloud Storage bucket and `NAMESPACE_PATH` is an optional Cloud
  /// Storage namespace path (this is not a Cloud Datastore namespace). For more
  /// information about Cloud Storage namespace paths, see
  /// [Object name considerations](https://cloud.google.com/storage/docs/naming#object-considerations).
  /// The resulting files will be nested deeper than the specified URL prefix.
  /// The final output URL will be provided in the
  /// google.datastore.admin.v1.ExportEntitiesResponse.output_url field. That
  /// value should be used for subsequent ImportEntities operations. By nesting
  /// the data files deeper, the same Cloud Storage bucket can be used in
  /// multiple ExportEntities operations without conflict.
  ///
  /// Required.
  core.String? outputUrlPrefix;

  GoogleDatastoreAdminV1ExportEntitiesRequest();

  GoogleDatastoreAdminV1ExportEntitiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entityFilter')) {
      entityFilter = GoogleDatastoreAdminV1EntityFilter.fromJson(
          _json['entityFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('outputUrlPrefix')) {
      outputUrlPrefix = _json['outputUrlPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityFilter != null) 'entityFilter': entityFilter!.toJson(),
        if (labels != null) 'labels': labels!,
        if (outputUrlPrefix != null) 'outputUrlPrefix': outputUrlPrefix!,
      };
}

/// The response for google.datastore.admin.v1.DatastoreAdmin.ExportEntities.
class GoogleDatastoreAdminV1ExportEntitiesResponse {
  /// Location of the output metadata file.
  ///
  /// This can be used to begin an import into Cloud Datastore (this project or
  /// another project). See
  /// google.datastore.admin.v1.ImportEntitiesRequest.input_url. Only present if
  /// the operation completed successfully.
  core.String? outputUrl;

  GoogleDatastoreAdminV1ExportEntitiesResponse();

  GoogleDatastoreAdminV1ExportEntitiesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('outputUrl')) {
      outputUrl = _json['outputUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (outputUrl != null) 'outputUrl': outputUrl!,
      };
}

/// Metadata for ImportEntities operations.
class GoogleDatastoreAdminV1ImportEntitiesMetadata {
  /// Metadata common to all Datastore Admin operations.
  GoogleDatastoreAdminV1CommonMetadata? common;

  /// Description of which entities are being imported.
  GoogleDatastoreAdminV1EntityFilter? entityFilter;

  /// The location of the import metadata file.
  ///
  /// This will be the same value as the
  /// google.datastore.admin.v1.ExportEntitiesResponse.output_url field.
  core.String? inputUrl;

  /// An estimate of the number of bytes processed.
  GoogleDatastoreAdminV1Progress? progressBytes;

  /// An estimate of the number of entities processed.
  GoogleDatastoreAdminV1Progress? progressEntities;

  GoogleDatastoreAdminV1ImportEntitiesMetadata();

  GoogleDatastoreAdminV1ImportEntitiesMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('common')) {
      common = GoogleDatastoreAdminV1CommonMetadata.fromJson(
          _json['common'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entityFilter')) {
      entityFilter = GoogleDatastoreAdminV1EntityFilter.fromJson(
          _json['entityFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inputUrl')) {
      inputUrl = _json['inputUrl'] as core.String;
    }
    if (_json.containsKey('progressBytes')) {
      progressBytes = GoogleDatastoreAdminV1Progress.fromJson(
          _json['progressBytes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('progressEntities')) {
      progressEntities = GoogleDatastoreAdminV1Progress.fromJson(
          _json['progressEntities'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (common != null) 'common': common!.toJson(),
        if (entityFilter != null) 'entityFilter': entityFilter!.toJson(),
        if (inputUrl != null) 'inputUrl': inputUrl!,
        if (progressBytes != null) 'progressBytes': progressBytes!.toJson(),
        if (progressEntities != null)
          'progressEntities': progressEntities!.toJson(),
      };
}

/// The request for google.datastore.admin.v1.DatastoreAdmin.ImportEntities.
class GoogleDatastoreAdminV1ImportEntitiesRequest {
  /// Optionally specify which kinds/namespaces are to be imported.
  ///
  /// If provided, the list must be a subset of the EntityFilter used in
  /// creating the export, otherwise a FAILED_PRECONDITION error will be
  /// returned. If no filter is specified then all entities from the export are
  /// imported.
  GoogleDatastoreAdminV1EntityFilter? entityFilter;

  /// The full resource URL of the external storage location.
  ///
  /// Currently, only Google Cloud Storage is supported. So input_url should be
  /// of the form:
  /// `gs://BUCKET_NAME[/NAMESPACE_PATH]/OVERALL_EXPORT_METADATA_FILE`, where
  /// `BUCKET_NAME` is the name of the Cloud Storage bucket, `NAMESPACE_PATH` is
  /// an optional Cloud Storage namespace path (this is not a Cloud Datastore
  /// namespace), and `OVERALL_EXPORT_METADATA_FILE` is the metadata file
  /// written by the ExportEntities operation. For more information about Cloud
  /// Storage namespace paths, see
  /// [Object name considerations](https://cloud.google.com/storage/docs/naming#object-considerations).
  /// For more information, see
  /// google.datastore.admin.v1.ExportEntitiesResponse.output_url.
  ///
  /// Required.
  core.String? inputUrl;

  /// Client-assigned labels.
  core.Map<core.String, core.String>? labels;

  GoogleDatastoreAdminV1ImportEntitiesRequest();

  GoogleDatastoreAdminV1ImportEntitiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entityFilter')) {
      entityFilter = GoogleDatastoreAdminV1EntityFilter.fromJson(
          _json['entityFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inputUrl')) {
      inputUrl = _json['inputUrl'] as core.String;
    }
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
        if (entityFilter != null) 'entityFilter': entityFilter!.toJson(),
        if (inputUrl != null) 'inputUrl': inputUrl!,
        if (labels != null) 'labels': labels!,
      };
}

/// Datastore composite index definition.
class GoogleDatastoreAdminV1Index {
  /// The index's ancestor mode.
  ///
  /// Must not be ANCESTOR_MODE_UNSPECIFIED.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ANCESTOR_MODE_UNSPECIFIED" : The ancestor mode is unspecified.
  /// - "NONE" : Do not include the entity's ancestors in the index.
  /// - "ALL_ANCESTORS" : Include all the entity's ancestors in the index.
  core.String? ancestor;

  /// The resource ID of the index.
  ///
  /// Output only.
  core.String? indexId;

  /// The entity kind to which this index applies.
  ///
  /// Required.
  core.String? kind;

  /// Project ID.
  ///
  /// Output only.
  core.String? projectId;

  /// An ordered sequence of property names and their index attributes.
  ///
  /// Required.
  core.List<GoogleDatastoreAdminV1IndexedProperty>? properties;

  /// The state of the index.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The state is unspecified.
  /// - "CREATING" : The index is being created, and cannot be used by queries.
  /// There is an active long-running operation for the index. The index is
  /// updated when writing an entity. Some index data may exist.
  /// - "READY" : The index is ready to be used. The index is updated when
  /// writing an entity. The index is fully populated from all stored entities
  /// it applies to.
  /// - "DELETING" : The index is being deleted, and cannot be used by queries.
  /// There is an active long-running operation for the index. The index is not
  /// updated when writing an entity. Some index data may exist.
  /// - "ERROR" : The index was being created or deleted, but something went
  /// wrong. The index cannot by used by queries. There is no active
  /// long-running operation for the index, and the most recently finished
  /// long-running operation failed. The index is not updated when writing an
  /// entity. Some index data may exist.
  core.String? state;

  GoogleDatastoreAdminV1Index();

  GoogleDatastoreAdminV1Index.fromJson(core.Map _json) {
    if (_json.containsKey('ancestor')) {
      ancestor = _json['ancestor'] as core.String;
    }
    if (_json.containsKey('indexId')) {
      indexId = _json['indexId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('properties')) {
      properties = (_json['properties'] as core.List)
          .map<GoogleDatastoreAdminV1IndexedProperty>((value) =>
              GoogleDatastoreAdminV1IndexedProperty.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ancestor != null) 'ancestor': ancestor!,
        if (indexId != null) 'indexId': indexId!,
        if (kind != null) 'kind': kind!,
        if (projectId != null) 'projectId': projectId!,
        if (properties != null)
          'properties': properties!.map((value) => value.toJson()).toList(),
        if (state != null) 'state': state!,
      };
}

/// Metadata for Index operations.
class GoogleDatastoreAdminV1IndexOperationMetadata {
  /// Metadata common to all Datastore Admin operations.
  GoogleDatastoreAdminV1CommonMetadata? common;

  /// The index resource ID that this operation is acting on.
  core.String? indexId;

  /// An estimate of the number of entities processed.
  GoogleDatastoreAdminV1Progress? progressEntities;

  GoogleDatastoreAdminV1IndexOperationMetadata();

  GoogleDatastoreAdminV1IndexOperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('common')) {
      common = GoogleDatastoreAdminV1CommonMetadata.fromJson(
          _json['common'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('indexId')) {
      indexId = _json['indexId'] as core.String;
    }
    if (_json.containsKey('progressEntities')) {
      progressEntities = GoogleDatastoreAdminV1Progress.fromJson(
          _json['progressEntities'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (common != null) 'common': common!.toJson(),
        if (indexId != null) 'indexId': indexId!,
        if (progressEntities != null)
          'progressEntities': progressEntities!.toJson(),
      };
}

/// A property of an index.
class GoogleDatastoreAdminV1IndexedProperty {
  /// The indexed property's direction.
  ///
  /// Must not be DIRECTION_UNSPECIFIED.
  ///
  /// Required.
  /// Possible string values are:
  /// - "DIRECTION_UNSPECIFIED" : The direction is unspecified.
  /// - "ASCENDING" : The property's values are indexed so as to support
  /// sequencing in ascending order and also query by <, >, <=, >=, and =.
  /// - "DESCENDING" : The property's values are indexed so as to support
  /// sequencing in descending order and also query by <, >, <=, >=, and =.
  core.String? direction;

  /// The property name to index.
  ///
  /// Required.
  core.String? name;

  GoogleDatastoreAdminV1IndexedProperty();

  GoogleDatastoreAdminV1IndexedProperty.fromJson(core.Map _json) {
    if (_json.containsKey('direction')) {
      direction = _json['direction'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (direction != null) 'direction': direction!,
        if (name != null) 'name': name!,
      };
}

/// The response for google.datastore.admin.v1.DatastoreAdmin.ListIndexes.
class GoogleDatastoreAdminV1ListIndexesResponse {
  /// The indexes.
  core.List<GoogleDatastoreAdminV1Index>? indexes;

  /// The standard List next-page token.
  core.String? nextPageToken;

  GoogleDatastoreAdminV1ListIndexesResponse();

  GoogleDatastoreAdminV1ListIndexesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('indexes')) {
      indexes = (_json['indexes'] as core.List)
          .map<GoogleDatastoreAdminV1Index>((value) =>
              GoogleDatastoreAdminV1Index.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (indexes != null)
          'indexes': indexes!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Measures the progress of a particular metric.
class GoogleDatastoreAdminV1Progress {
  /// The amount of work that has been completed.
  ///
  /// Note that this may be greater than work_estimated.
  core.String? workCompleted;

  /// An estimate of how much work needs to be performed.
  ///
  /// May be zero if the work estimate is unavailable.
  core.String? workEstimated;

  GoogleDatastoreAdminV1Progress();

  GoogleDatastoreAdminV1Progress.fromJson(core.Map _json) {
    if (_json.containsKey('workCompleted')) {
      workCompleted = _json['workCompleted'] as core.String;
    }
    if (_json.containsKey('workEstimated')) {
      workEstimated = _json['workEstimated'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (workCompleted != null) 'workCompleted': workCompleted!,
        if (workEstimated != null) 'workEstimated': workEstimated!,
      };
}

/// Metadata common to all Datastore Admin operations.
class GoogleDatastoreAdminV1beta1CommonMetadata {
  /// The time the operation ended, either successfully or otherwise.
  core.String? endTime;

  /// The client-assigned labels which were provided when the operation was
  /// created.
  ///
  /// May also include additional labels.
  core.Map<core.String, core.String>? labels;

  /// The type of the operation.
  ///
  /// Can be used as a filter in ListOperationsRequest.
  /// Possible string values are:
  /// - "OPERATION_TYPE_UNSPECIFIED" : Unspecified.
  /// - "EXPORT_ENTITIES" : ExportEntities.
  /// - "IMPORT_ENTITIES" : ImportEntities.
  core.String? operationType;

  /// The time that work began on the operation.
  core.String? startTime;

  /// The current state of the Operation.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified.
  /// - "INITIALIZING" : Request is being prepared for processing.
  /// - "PROCESSING" : Request is actively being processed.
  /// - "CANCELLING" : Request is in the process of being cancelled after user
  /// called google.longrunning.Operations.CancelOperation on the operation.
  /// - "FINALIZING" : Request has been processed and is in its finalization
  /// stage.
  /// - "SUCCESSFUL" : Request has completed successfully.
  /// - "FAILED" : Request has finished being processed, but encountered an
  /// error.
  /// - "CANCELLED" : Request has finished being cancelled after user called
  /// google.longrunning.Operations.CancelOperation.
  core.String? state;

  GoogleDatastoreAdminV1beta1CommonMetadata();

  GoogleDatastoreAdminV1beta1CommonMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (labels != null) 'labels': labels!,
        if (operationType != null) 'operationType': operationType!,
        if (startTime != null) 'startTime': startTime!,
        if (state != null) 'state': state!,
      };
}

/// Identifies a subset of entities in a project.
///
/// This is specified as combinations of kinds and namespaces (either or both of
/// which may be all, as described in the following examples). Example usage:
/// Entire project: kinds=\[\], namespace_ids=\[\] Kinds Foo and Bar in all
/// namespaces: kinds=\['Foo', 'Bar'\], namespace_ids=\[\] Kinds Foo and Bar
/// only in the default namespace: kinds=\['Foo', 'Bar'\], namespace_ids=\[''\]
/// Kinds Foo and Bar in both the default and Baz namespaces: kinds=\['Foo',
/// 'Bar'\], namespace_ids=\['', 'Baz'\] The entire Baz namespace: kinds=\[\],
/// namespace_ids=\['Baz'\]
class GoogleDatastoreAdminV1beta1EntityFilter {
  /// If empty, then this represents all kinds.
  core.List<core.String>? kinds;

  /// An empty list represents all namespaces.
  ///
  /// This is the preferred usage for projects that don't use namespaces. An
  /// empty string element represents the default namespace. This should be used
  /// if the project has data in non-default namespaces, but doesn't want to
  /// include them. Each namespace in this list must be unique.
  core.List<core.String>? namespaceIds;

  GoogleDatastoreAdminV1beta1EntityFilter();

  GoogleDatastoreAdminV1beta1EntityFilter.fromJson(core.Map _json) {
    if (_json.containsKey('kinds')) {
      kinds = (_json['kinds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('namespaceIds')) {
      namespaceIds = (_json['namespaceIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kinds != null) 'kinds': kinds!,
        if (namespaceIds != null) 'namespaceIds': namespaceIds!,
      };
}

/// Metadata for ExportEntities operations.
class GoogleDatastoreAdminV1beta1ExportEntitiesMetadata {
  /// Metadata common to all Datastore Admin operations.
  GoogleDatastoreAdminV1beta1CommonMetadata? common;

  /// Description of which entities are being exported.
  GoogleDatastoreAdminV1beta1EntityFilter? entityFilter;

  /// Location for the export metadata and data files.
  ///
  /// This will be the same value as the
  /// google.datastore.admin.v1beta1.ExportEntitiesRequest.output_url_prefix
  /// field. The final output location is provided in
  /// google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url.
  core.String? outputUrlPrefix;

  /// An estimate of the number of bytes processed.
  GoogleDatastoreAdminV1beta1Progress? progressBytes;

  /// An estimate of the number of entities processed.
  GoogleDatastoreAdminV1beta1Progress? progressEntities;

  GoogleDatastoreAdminV1beta1ExportEntitiesMetadata();

  GoogleDatastoreAdminV1beta1ExportEntitiesMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('common')) {
      common = GoogleDatastoreAdminV1beta1CommonMetadata.fromJson(
          _json['common'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entityFilter')) {
      entityFilter = GoogleDatastoreAdminV1beta1EntityFilter.fromJson(
          _json['entityFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outputUrlPrefix')) {
      outputUrlPrefix = _json['outputUrlPrefix'] as core.String;
    }
    if (_json.containsKey('progressBytes')) {
      progressBytes = GoogleDatastoreAdminV1beta1Progress.fromJson(
          _json['progressBytes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('progressEntities')) {
      progressEntities = GoogleDatastoreAdminV1beta1Progress.fromJson(
          _json['progressEntities'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (common != null) 'common': common!.toJson(),
        if (entityFilter != null) 'entityFilter': entityFilter!.toJson(),
        if (outputUrlPrefix != null) 'outputUrlPrefix': outputUrlPrefix!,
        if (progressBytes != null) 'progressBytes': progressBytes!.toJson(),
        if (progressEntities != null)
          'progressEntities': progressEntities!.toJson(),
      };
}

/// The response for
/// google.datastore.admin.v1beta1.DatastoreAdmin.ExportEntities.
class GoogleDatastoreAdminV1beta1ExportEntitiesResponse {
  /// Location of the output metadata file.
  ///
  /// This can be used to begin an import into Cloud Datastore (this project or
  /// another project). See
  /// google.datastore.admin.v1beta1.ImportEntitiesRequest.input_url. Only
  /// present if the operation completed successfully.
  core.String? outputUrl;

  GoogleDatastoreAdminV1beta1ExportEntitiesResponse();

  GoogleDatastoreAdminV1beta1ExportEntitiesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('outputUrl')) {
      outputUrl = _json['outputUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (outputUrl != null) 'outputUrl': outputUrl!,
      };
}

/// Metadata for ImportEntities operations.
class GoogleDatastoreAdminV1beta1ImportEntitiesMetadata {
  /// Metadata common to all Datastore Admin operations.
  GoogleDatastoreAdminV1beta1CommonMetadata? common;

  /// Description of which entities are being imported.
  GoogleDatastoreAdminV1beta1EntityFilter? entityFilter;

  /// The location of the import metadata file.
  ///
  /// This will be the same value as the
  /// google.datastore.admin.v1beta1.ExportEntitiesResponse.output_url field.
  core.String? inputUrl;

  /// An estimate of the number of bytes processed.
  GoogleDatastoreAdminV1beta1Progress? progressBytes;

  /// An estimate of the number of entities processed.
  GoogleDatastoreAdminV1beta1Progress? progressEntities;

  GoogleDatastoreAdminV1beta1ImportEntitiesMetadata();

  GoogleDatastoreAdminV1beta1ImportEntitiesMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('common')) {
      common = GoogleDatastoreAdminV1beta1CommonMetadata.fromJson(
          _json['common'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entityFilter')) {
      entityFilter = GoogleDatastoreAdminV1beta1EntityFilter.fromJson(
          _json['entityFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inputUrl')) {
      inputUrl = _json['inputUrl'] as core.String;
    }
    if (_json.containsKey('progressBytes')) {
      progressBytes = GoogleDatastoreAdminV1beta1Progress.fromJson(
          _json['progressBytes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('progressEntities')) {
      progressEntities = GoogleDatastoreAdminV1beta1Progress.fromJson(
          _json['progressEntities'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (common != null) 'common': common!.toJson(),
        if (entityFilter != null) 'entityFilter': entityFilter!.toJson(),
        if (inputUrl != null) 'inputUrl': inputUrl!,
        if (progressBytes != null) 'progressBytes': progressBytes!.toJson(),
        if (progressEntities != null)
          'progressEntities': progressEntities!.toJson(),
      };
}

/// Measures the progress of a particular metric.
class GoogleDatastoreAdminV1beta1Progress {
  /// The amount of work that has been completed.
  ///
  /// Note that this may be greater than work_estimated.
  core.String? workCompleted;

  /// An estimate of how much work needs to be performed.
  ///
  /// May be zero if the work estimate is unavailable.
  core.String? workEstimated;

  GoogleDatastoreAdminV1beta1Progress();

  GoogleDatastoreAdminV1beta1Progress.fromJson(core.Map _json) {
    if (_json.containsKey('workCompleted')) {
      workCompleted = _json['workCompleted'] as core.String;
    }
    if (_json.containsKey('workEstimated')) {
      workEstimated = _json['workEstimated'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (workCompleted != null) 'workCompleted': workCompleted!,
        if (workEstimated != null) 'workEstimated': workEstimated!,
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

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
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

/// A
/// [GQL query](https://cloud.google.com/datastore/docs/apis/gql/gql_reference).
class GqlQuery {
  /// When false, the query string must not contain any literals and instead
  /// must bind all values.
  ///
  /// For example, `SELECT * FROM Kind WHERE a = 'string literal'` is not
  /// allowed, while `SELECT * FROM Kind WHERE a = @value` is.
  core.bool? allowLiterals;

  /// For each non-reserved named binding site in the query string, there must
  /// be a named parameter with that name, but not necessarily the inverse.
  ///
  /// Key must match regex `A-Za-z_$*`, must not match regex `__.*__`, and must
  /// not be `""`.
  core.Map<core.String, GqlQueryParameter>? namedBindings;

  /// Numbered binding site @1 references the first numbered parameter,
  /// effectively using 1-based indexing, rather than the usual 0.
  ///
  /// For each binding site numbered i in `query_string`, there must be an i-th
  /// numbered parameter. The inverse must also be true.
  core.List<GqlQueryParameter>? positionalBindings;

  /// A string of the format described
  /// [here](https://cloud.google.com/datastore/docs/apis/gql/gql_reference).
  core.String? queryString;

  GqlQuery();

  GqlQuery.fromJson(core.Map _json) {
    if (_json.containsKey('allowLiterals')) {
      allowLiterals = _json['allowLiterals'] as core.bool;
    }
    if (_json.containsKey('namedBindings')) {
      namedBindings =
          (_json['namedBindings'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GqlQueryParameter.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('positionalBindings')) {
      positionalBindings = (_json['positionalBindings'] as core.List)
          .map<GqlQueryParameter>((value) => GqlQueryParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('queryString')) {
      queryString = _json['queryString'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowLiterals != null) 'allowLiterals': allowLiterals!,
        if (namedBindings != null)
          'namedBindings': namedBindings!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (positionalBindings != null)
          'positionalBindings':
              positionalBindings!.map((value) => value.toJson()).toList(),
        if (queryString != null) 'queryString': queryString!,
      };
}

/// A binding parameter for a GQL query.
class GqlQueryParameter {
  /// A query cursor.
  ///
  /// Query cursors are returned in query result batches.
  core.String? cursor;
  core.List<core.int> get cursorAsBytes => convert.base64.decode(cursor!);

  set cursorAsBytes(core.List<core.int> _bytes) {
    cursor =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// A value parameter.
  Value? value;

  GqlQueryParameter();

  GqlQueryParameter.fromJson(core.Map _json) {
    if (_json.containsKey('cursor')) {
      cursor = _json['cursor'] as core.String;
    }
    if (_json.containsKey('value')) {
      value =
          Value.fromJson(_json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cursor != null) 'cursor': cursor!,
        if (value != null) 'value': value!.toJson(),
      };
}

/// A unique identifier for an entity.
///
/// If a key's partition ID or any of its path kinds or names are
/// reserved/read-only, the key is reserved/read-only. A reserved/read-only key
/// is forbidden in certain documented contexts.
class Key {
  /// Entities are partitioned into subsets, currently identified by a project
  /// ID and namespace ID.
  ///
  /// Queries are scoped to a single partition.
  PartitionId? partitionId;

  /// The entity path.
  ///
  /// An entity path consists of one or more elements composed of a kind and a
  /// string or numerical identifier, which identify entities. The first element
  /// identifies a _root entity_, the second element identifies a _child_ of the
  /// root entity, the third element identifies a child of the second entity,
  /// and so forth. The entities identified by all prefixes of the path are
  /// called the element's _ancestors_. An entity path is always fully complete:
  /// *all* of the entity's ancestors are required to be in the path along with
  /// the entity identifier itself. The only exception is that in some
  /// documented cases, the identifier in the last path element (for the entity)
  /// itself may be omitted. For example, the last path element of the key of
  /// `Mutation.insert` may have no identifier. A path can never be empty, and a
  /// path can have at most 100 elements.
  core.List<PathElement>? path;

  Key();

  Key.fromJson(core.Map _json) {
    if (_json.containsKey('partitionId')) {
      partitionId = PartitionId.fromJson(
          _json['partitionId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('path')) {
      path = (_json['path'] as core.List)
          .map<PathElement>((value) => PathElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (partitionId != null) 'partitionId': partitionId!.toJson(),
        if (path != null) 'path': path!.map((value) => value.toJson()).toList(),
      };
}

/// A representation of a kind.
class KindExpression {
  /// The name of the kind.
  core.String? name;

  KindExpression();

  KindExpression.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
      };
}

/// An object that represents a latitude/longitude pair.
///
/// This is expressed as a pair of doubles to represent degrees latitude and
/// degrees longitude. Unless specified otherwise, this object must conform to
/// the WGS84 standard. Values must be within normalized ranges.
class LatLng {
  /// The latitude in degrees.
  ///
  /// It must be in the range \[-90.0, +90.0\].
  core.double? latitude;

  /// The longitude in degrees.
  ///
  /// It must be in the range \[-180.0, +180.0\].
  core.double? longitude;

  LatLng();

  LatLng.fromJson(core.Map _json) {
    if (_json.containsKey('latitude')) {
      latitude = (_json['latitude'] as core.num).toDouble();
    }
    if (_json.containsKey('longitude')) {
      longitude = (_json['longitude'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude!,
        if (longitude != null) 'longitude': longitude!,
      };
}

/// The request for Datastore.Lookup.
class LookupRequest {
  /// Keys of entities to look up.
  ///
  /// Required.
  core.List<Key>? keys;

  /// The options for this lookup request.
  ReadOptions? readOptions;

  LookupRequest();

  LookupRequest.fromJson(core.Map _json) {
    if (_json.containsKey('keys')) {
      keys = (_json['keys'] as core.List)
          .map<Key>((value) =>
              Key.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('readOptions')) {
      readOptions = ReadOptions.fromJson(
          _json['readOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keys != null) 'keys': keys!.map((value) => value.toJson()).toList(),
        if (readOptions != null) 'readOptions': readOptions!.toJson(),
      };
}

/// The response for Datastore.Lookup.
class LookupResponse {
  /// A list of keys that were not looked up due to resource constraints.
  ///
  /// The order of results in this field is undefined and has no relation to the
  /// order of the keys in the input.
  core.List<Key>? deferred;

  /// Entities found as `ResultType.FULL` entities.
  ///
  /// The order of results in this field is undefined and has no relation to the
  /// order of the keys in the input.
  core.List<EntityResult>? found;

  /// Entities not found as `ResultType.KEY_ONLY` entities.
  ///
  /// The order of results in this field is undefined and has no relation to the
  /// order of the keys in the input.
  core.List<EntityResult>? missing;

  LookupResponse();

  LookupResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deferred')) {
      deferred = (_json['deferred'] as core.List)
          .map<Key>((value) =>
              Key.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('found')) {
      found = (_json['found'] as core.List)
          .map<EntityResult>((value) => EntityResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('missing')) {
      missing = (_json['missing'] as core.List)
          .map<EntityResult>((value) => EntityResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deferred != null)
          'deferred': deferred!.map((value) => value.toJson()).toList(),
        if (found != null)
          'found': found!.map((value) => value.toJson()).toList(),
        if (missing != null)
          'missing': missing!.map((value) => value.toJson()).toList(),
      };
}

/// A mutation to apply to an entity.
class Mutation {
  /// The version of the entity that this mutation is being applied to.
  ///
  /// If this does not match the current version on the server, the mutation
  /// conflicts.
  core.String? baseVersion;

  /// The key of the entity to delete.
  ///
  /// The entity may or may not already exist. Must have a complete key path and
  /// must not be reserved/read-only.
  Key? delete;

  /// The entity to insert.
  ///
  /// The entity must not already exist. The entity key's final path element may
  /// be incomplete.
  Entity? insert;

  /// The entity to update.
  ///
  /// The entity must already exist. Must have a complete key path.
  Entity? update;

  /// The entity to upsert.
  ///
  /// The entity may or may not already exist. The entity key's final path
  /// element may be incomplete.
  Entity? upsert;

  Mutation();

  Mutation.fromJson(core.Map _json) {
    if (_json.containsKey('baseVersion')) {
      baseVersion = _json['baseVersion'] as core.String;
    }
    if (_json.containsKey('delete')) {
      delete =
          Key.fromJson(_json['delete'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insert')) {
      insert = Entity.fromJson(
          _json['insert'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('update')) {
      update = Entity.fromJson(
          _json['update'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('upsert')) {
      upsert = Entity.fromJson(
          _json['upsert'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (baseVersion != null) 'baseVersion': baseVersion!,
        if (delete != null) 'delete': delete!.toJson(),
        if (insert != null) 'insert': insert!.toJson(),
        if (update != null) 'update': update!.toJson(),
        if (upsert != null) 'upsert': upsert!.toJson(),
      };
}

/// The result of applying a mutation.
class MutationResult {
  /// Whether a conflict was detected for this mutation.
  ///
  /// Always false when a conflict detection strategy field is not set in the
  /// mutation.
  core.bool? conflictDetected;

  /// The automatically allocated key.
  ///
  /// Set only when the mutation allocated a key.
  Key? key;

  /// The version of the entity on the server after processing the mutation.
  ///
  /// If the mutation doesn't change anything on the server, then the version
  /// will be the version of the current entity or, if no entity is present, a
  /// version that is strictly greater than the version of any previous entity
  /// and less than the version of any possible future entity.
  core.String? version;

  MutationResult();

  MutationResult.fromJson(core.Map _json) {
    if (_json.containsKey('conflictDetected')) {
      conflictDetected = _json['conflictDetected'] as core.bool;
    }
    if (_json.containsKey('key')) {
      key = Key.fromJson(_json['key'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conflictDetected != null) 'conflictDetected': conflictDetected!,
        if (key != null) 'key': key!.toJson(),
        if (version != null) 'version': version!,
      };
}

/// A partition ID identifies a grouping of entities.
///
/// The grouping is always by project and namespace, however the namespace ID
/// may be empty. A partition ID contains several dimensions: project ID and
/// namespace ID. Partition dimensions: - May be `""`. - Must be valid UTF-8
/// bytes. - Must have values that match regex `[A-Za-z\d\.\-_]{1,100}` If the
/// value of any dimension matches regex `__.*__`, the partition is
/// reserved/read-only. A reserved/read-only partition ID is forbidden in
/// certain documented contexts. Foreign partition IDs (in which the project ID
/// does not match the context project ID ) are discouraged. Reads and writes of
/// foreign partition IDs may fail if the project is not in an active state.
class PartitionId {
  /// If not empty, the ID of the namespace to which the entities belong.
  core.String? namespaceId;

  /// The ID of the project to which the entities belong.
  core.String? projectId;

  PartitionId();

  PartitionId.fromJson(core.Map _json) {
    if (_json.containsKey('namespaceId')) {
      namespaceId = _json['namespaceId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namespaceId != null) 'namespaceId': namespaceId!,
        if (projectId != null) 'projectId': projectId!,
      };
}

/// A (kind, ID/name) pair used to construct a key path.
///
/// If either name or ID is set, the element is complete. If neither is set, the
/// element is incomplete.
class PathElement {
  /// The auto-allocated ID of the entity.
  ///
  /// Never equal to zero. Values less than zero are discouraged and may not be
  /// supported in the future.
  core.String? id;

  /// The kind of the entity.
  ///
  /// A kind matching regex `__.*__` is reserved/read-only. A kind must not
  /// contain more than 1500 bytes when UTF-8 encoded. Cannot be `""`.
  core.String? kind;

  /// The name of the entity.
  ///
  /// A name matching regex `__.*__` is reserved/read-only. A name must not be
  /// more than 1500 bytes when UTF-8 encoded. Cannot be `""`.
  core.String? name;

  PathElement();

  PathElement.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// A representation of a property in a projection.
class Projection {
  /// The property to project.
  PropertyReference? property;

  Projection();

  Projection.fromJson(core.Map _json) {
    if (_json.containsKey('property')) {
      property = PropertyReference.fromJson(
          _json['property'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (property != null) 'property': property!.toJson(),
      };
}

/// A filter on a specific property.
class PropertyFilter {
  /// The operator to filter by.
  /// Possible string values are:
  /// - "OPERATOR_UNSPECIFIED" : Unspecified. This value must not be used.
  /// - "LESS_THAN" : Less than.
  /// - "LESS_THAN_OR_EQUAL" : Less than or equal.
  /// - "GREATER_THAN" : Greater than.
  /// - "GREATER_THAN_OR_EQUAL" : Greater than or equal.
  /// - "EQUAL" : Equal.
  /// - "HAS_ANCESTOR" : Has ancestor.
  core.String? op;

  /// The property to filter by.
  PropertyReference? property;

  /// The value to compare the property to.
  Value? value;

  PropertyFilter();

  PropertyFilter.fromJson(core.Map _json) {
    if (_json.containsKey('op')) {
      op = _json['op'] as core.String;
    }
    if (_json.containsKey('property')) {
      property = PropertyReference.fromJson(
          _json['property'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('value')) {
      value =
          Value.fromJson(_json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (op != null) 'op': op!,
        if (property != null) 'property': property!.toJson(),
        if (value != null) 'value': value!.toJson(),
      };
}

/// The desired order for a specific property.
class PropertyOrder {
  /// The direction to order by.
  ///
  /// Defaults to `ASCENDING`.
  /// Possible string values are:
  /// - "DIRECTION_UNSPECIFIED" : Unspecified. This value must not be used.
  /// - "ASCENDING" : Ascending.
  /// - "DESCENDING" : Descending.
  core.String? direction;

  /// The property to order by.
  PropertyReference? property;

  PropertyOrder();

  PropertyOrder.fromJson(core.Map _json) {
    if (_json.containsKey('direction')) {
      direction = _json['direction'] as core.String;
    }
    if (_json.containsKey('property')) {
      property = PropertyReference.fromJson(
          _json['property'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (direction != null) 'direction': direction!,
        if (property != null) 'property': property!.toJson(),
      };
}

/// A reference to a property relative to the kind expressions.
class PropertyReference {
  /// The name of the property.
  ///
  /// If name includes "."s, it may be interpreted as a property name path.
  core.String? name;

  PropertyReference();

  PropertyReference.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
      };
}

/// A query for entities.
class Query {
  /// The properties to make distinct.
  ///
  /// The query results will contain the first result for each distinct
  /// combination of values for the given properties (if empty, all results are
  /// returned).
  core.List<PropertyReference>? distinctOn;

  /// An ending point for the query results.
  ///
  /// Query cursors are returned in query result batches and
  /// [can only be used to limit the same query](https://cloud.google.com/datastore/docs/concepts/queries#cursors_limits_and_offsets).
  core.String? endCursor;
  core.List<core.int> get endCursorAsBytes => convert.base64.decode(endCursor!);

  set endCursorAsBytes(core.List<core.int> _bytes) {
    endCursor =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The filter to apply.
  Filter? filter;

  /// The kinds to query (if empty, returns entities of all kinds).
  ///
  /// Currently at most 1 kind may be specified.
  core.List<KindExpression>? kind;

  /// The maximum number of results to return.
  ///
  /// Applies after all other constraints. Optional. Unspecified is interpreted
  /// as no limit. Must be >= 0 if specified.
  core.int? limit;

  /// The number of results to skip.
  ///
  /// Applies before limit, but after all other constraints. Optional. Must be
  /// >= 0 if specified.
  core.int? offset;

  /// The order to apply to the query results (if empty, order is unspecified).
  core.List<PropertyOrder>? order;

  /// The projection to return.
  ///
  /// Defaults to returning all properties.
  core.List<Projection>? projection;

  /// A starting point for the query results.
  ///
  /// Query cursors are returned in query result batches and
  /// [can only be used to continue the same query](https://cloud.google.com/datastore/docs/concepts/queries#cursors_limits_and_offsets).
  core.String? startCursor;
  core.List<core.int> get startCursorAsBytes =>
      convert.base64.decode(startCursor!);

  set startCursorAsBytes(core.List<core.int> _bytes) {
    startCursor =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  Query();

  Query.fromJson(core.Map _json) {
    if (_json.containsKey('distinctOn')) {
      distinctOn = (_json['distinctOn'] as core.List)
          .map<PropertyReference>((value) => PropertyReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('endCursor')) {
      endCursor = _json['endCursor'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = Filter.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = (_json['kind'] as core.List)
          .map<KindExpression>((value) => KindExpression.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('limit')) {
      limit = _json['limit'] as core.int;
    }
    if (_json.containsKey('offset')) {
      offset = _json['offset'] as core.int;
    }
    if (_json.containsKey('order')) {
      order = (_json['order'] as core.List)
          .map<PropertyOrder>((value) => PropertyOrder.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('projection')) {
      projection = (_json['projection'] as core.List)
          .map<Projection>((value) =>
              Projection.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startCursor')) {
      startCursor = _json['startCursor'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (distinctOn != null)
          'distinctOn': distinctOn!.map((value) => value.toJson()).toList(),
        if (endCursor != null) 'endCursor': endCursor!,
        if (filter != null) 'filter': filter!.toJson(),
        if (kind != null) 'kind': kind!.map((value) => value.toJson()).toList(),
        if (limit != null) 'limit': limit!,
        if (offset != null) 'offset': offset!,
        if (order != null)
          'order': order!.map((value) => value.toJson()).toList(),
        if (projection != null)
          'projection': projection!.map((value) => value.toJson()).toList(),
        if (startCursor != null) 'startCursor': startCursor!,
      };
}

/// A batch of results produced by a query.
class QueryResultBatch {
  /// A cursor that points to the position after the last result in the batch.
  core.String? endCursor;
  core.List<core.int> get endCursorAsBytes => convert.base64.decode(endCursor!);

  set endCursorAsBytes(core.List<core.int> _bytes) {
    endCursor =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The result type for every entity in `entity_results`.
  /// Possible string values are:
  /// - "RESULT_TYPE_UNSPECIFIED" : Unspecified. This value is never used.
  /// - "FULL" : The key and properties.
  /// - "PROJECTION" : A projected subset of properties. The entity may have no
  /// key.
  /// - "KEY_ONLY" : Only the key.
  core.String? entityResultType;

  /// The results for this batch.
  core.List<EntityResult>? entityResults;

  /// The state of the query after the current batch.
  /// Possible string values are:
  /// - "MORE_RESULTS_TYPE_UNSPECIFIED" : Unspecified. This value is never used.
  /// - "NOT_FINISHED" : There may be additional batches to fetch from this
  /// query.
  /// - "MORE_RESULTS_AFTER_LIMIT" : The query is finished, but there may be
  /// more results after the limit.
  /// - "MORE_RESULTS_AFTER_CURSOR" : The query is finished, but there may be
  /// more results after the end cursor.
  /// - "NO_MORE_RESULTS" : The query is finished, and there are no more
  /// results.
  core.String? moreResults;

  /// A cursor that points to the position after the last skipped result.
  ///
  /// Will be set when `skipped_results` != 0.
  core.String? skippedCursor;
  core.List<core.int> get skippedCursorAsBytes =>
      convert.base64.decode(skippedCursor!);

  set skippedCursorAsBytes(core.List<core.int> _bytes) {
    skippedCursor =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The number of results skipped, typically because of an offset.
  core.int? skippedResults;

  /// The version number of the snapshot this batch was returned from.
  ///
  /// This applies to the range of results from the query's `start_cursor` (or
  /// the beginning of the query if no cursor was given) to this batch's
  /// `end_cursor` (not the query's `end_cursor`). In a single transaction,
  /// subsequent query result batches for the same query can have a greater
  /// snapshot version number. Each batch's snapshot version is valid for all
  /// preceding batches. The value will be zero for eventually consistent
  /// queries.
  core.String? snapshotVersion;

  QueryResultBatch();

  QueryResultBatch.fromJson(core.Map _json) {
    if (_json.containsKey('endCursor')) {
      endCursor = _json['endCursor'] as core.String;
    }
    if (_json.containsKey('entityResultType')) {
      entityResultType = _json['entityResultType'] as core.String;
    }
    if (_json.containsKey('entityResults')) {
      entityResults = (_json['entityResults'] as core.List)
          .map<EntityResult>((value) => EntityResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('moreResults')) {
      moreResults = _json['moreResults'] as core.String;
    }
    if (_json.containsKey('skippedCursor')) {
      skippedCursor = _json['skippedCursor'] as core.String;
    }
    if (_json.containsKey('skippedResults')) {
      skippedResults = _json['skippedResults'] as core.int;
    }
    if (_json.containsKey('snapshotVersion')) {
      snapshotVersion = _json['snapshotVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endCursor != null) 'endCursor': endCursor!,
        if (entityResultType != null) 'entityResultType': entityResultType!,
        if (entityResults != null)
          'entityResults':
              entityResults!.map((value) => value.toJson()).toList(),
        if (moreResults != null) 'moreResults': moreResults!,
        if (skippedCursor != null) 'skippedCursor': skippedCursor!,
        if (skippedResults != null) 'skippedResults': skippedResults!,
        if (snapshotVersion != null) 'snapshotVersion': snapshotVersion!,
      };
}

/// Options specific to read-only transactions.
class ReadOnly {
  ReadOnly();

  ReadOnly.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The options shared by read requests.
class ReadOptions {
  /// The non-transactional read consistency to use.
  ///
  /// Cannot be set to `STRONG` for global queries.
  /// Possible string values are:
  /// - "READ_CONSISTENCY_UNSPECIFIED" : Unspecified. This value must not be
  /// used.
  /// - "STRONG" : Strong consistency.
  /// - "EVENTUAL" : Eventual consistency.
  core.String? readConsistency;

  /// The identifier of the transaction in which to read.
  ///
  /// A transaction identifier is returned by a call to
  /// Datastore.BeginTransaction.
  core.String? transaction;
  core.List<core.int> get transactionAsBytes =>
      convert.base64.decode(transaction!);

  set transactionAsBytes(core.List<core.int> _bytes) {
    transaction =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  ReadOptions();

  ReadOptions.fromJson(core.Map _json) {
    if (_json.containsKey('readConsistency')) {
      readConsistency = _json['readConsistency'] as core.String;
    }
    if (_json.containsKey('transaction')) {
      transaction = _json['transaction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (readConsistency != null) 'readConsistency': readConsistency!,
        if (transaction != null) 'transaction': transaction!,
      };
}

/// Options specific to read / write transactions.
class ReadWrite {
  /// The transaction identifier of the transaction being retried.
  core.String? previousTransaction;
  core.List<core.int> get previousTransactionAsBytes =>
      convert.base64.decode(previousTransaction!);

  set previousTransactionAsBytes(core.List<core.int> _bytes) {
    previousTransaction =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  ReadWrite();

  ReadWrite.fromJson(core.Map _json) {
    if (_json.containsKey('previousTransaction')) {
      previousTransaction = _json['previousTransaction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (previousTransaction != null)
          'previousTransaction': previousTransaction!,
      };
}

/// The request for Datastore.ReserveIds.
class ReserveIdsRequest {
  /// If not empty, the ID of the database against which to make the request.
  core.String? databaseId;

  /// A list of keys with complete key paths whose numeric IDs should not be
  /// auto-allocated.
  ///
  /// Required.
  core.List<Key>? keys;

  ReserveIdsRequest();

  ReserveIdsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('databaseId')) {
      databaseId = _json['databaseId'] as core.String;
    }
    if (_json.containsKey('keys')) {
      keys = (_json['keys'] as core.List)
          .map<Key>((value) =>
              Key.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (databaseId != null) 'databaseId': databaseId!,
        if (keys != null) 'keys': keys!.map((value) => value.toJson()).toList(),
      };
}

/// The response for Datastore.ReserveIds.
class ReserveIdsResponse {
  ReserveIdsResponse();

  ReserveIdsResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request for Datastore.Rollback.
class RollbackRequest {
  /// The transaction identifier, returned by a call to
  /// Datastore.BeginTransaction.
  ///
  /// Required.
  core.String? transaction;
  core.List<core.int> get transactionAsBytes =>
      convert.base64.decode(transaction!);

  set transactionAsBytes(core.List<core.int> _bytes) {
    transaction =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  RollbackRequest();

  RollbackRequest.fromJson(core.Map _json) {
    if (_json.containsKey('transaction')) {
      transaction = _json['transaction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (transaction != null) 'transaction': transaction!,
      };
}

/// The response for Datastore.Rollback.
///
/// (an empty message).
class RollbackResponse {
  RollbackResponse();

  RollbackResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request for Datastore.RunQuery.
class RunQueryRequest {
  /// The GQL query to run.
  GqlQuery? gqlQuery;

  /// Entities are partitioned into subsets, identified by a partition ID.
  ///
  /// Queries are scoped to a single partition. This partition ID is normalized
  /// with the standard default context partition ID.
  PartitionId? partitionId;

  /// The query to run.
  Query? query;

  /// The options for this query.
  ReadOptions? readOptions;

  RunQueryRequest();

  RunQueryRequest.fromJson(core.Map _json) {
    if (_json.containsKey('gqlQuery')) {
      gqlQuery = GqlQuery.fromJson(
          _json['gqlQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('partitionId')) {
      partitionId = PartitionId.fromJson(
          _json['partitionId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('query')) {
      query =
          Query.fromJson(_json['query'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('readOptions')) {
      readOptions = ReadOptions.fromJson(
          _json['readOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gqlQuery != null) 'gqlQuery': gqlQuery!.toJson(),
        if (partitionId != null) 'partitionId': partitionId!.toJson(),
        if (query != null) 'query': query!.toJson(),
        if (readOptions != null) 'readOptions': readOptions!.toJson(),
      };
}

/// The response for Datastore.RunQuery.
class RunQueryResponse {
  /// A batch of query results (always present).
  QueryResultBatch? batch;

  /// The parsed form of the `GqlQuery` from the request, if it was set.
  Query? query;

  RunQueryResponse();

  RunQueryResponse.fromJson(core.Map _json) {
    if (_json.containsKey('batch')) {
      batch = QueryResultBatch.fromJson(
          _json['batch'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('query')) {
      query =
          Query.fromJson(_json['query'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batch != null) 'batch': batch!.toJson(),
        if (query != null) 'query': query!.toJson(),
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

/// Options for beginning a new transaction.
///
/// Transactions can be created explicitly with calls to
/// Datastore.BeginTransaction or implicitly by setting
/// ReadOptions.new_transaction in read requests.
class TransactionOptions {
  /// The transaction should only allow reads.
  ReadOnly? readOnly;

  /// The transaction should allow both reads and writes.
  ReadWrite? readWrite;

  TransactionOptions();

  TransactionOptions.fromJson(core.Map _json) {
    if (_json.containsKey('readOnly')) {
      readOnly = ReadOnly.fromJson(
          _json['readOnly'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('readWrite')) {
      readWrite = ReadWrite.fromJson(
          _json['readWrite'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (readOnly != null) 'readOnly': readOnly!.toJson(),
        if (readWrite != null) 'readWrite': readWrite!.toJson(),
      };
}

/// A message that can hold any of the supported value types and associated
/// metadata.
class Value {
  /// An array value.
  ///
  /// Cannot contain another array value. A `Value` instance that sets field
  /// `array_value` must not set fields `meaning` or `exclude_from_indexes`.
  ArrayValue? arrayValue;

  /// A blob value.
  ///
  /// May have at most 1,000,000 bytes. When `exclude_from_indexes` is false,
  /// may have at most 1500 bytes. In JSON requests, must be base64-encoded.
  core.String? blobValue;
  core.List<core.int> get blobValueAsBytes => convert.base64.decode(blobValue!);

  set blobValueAsBytes(core.List<core.int> _bytes) {
    blobValue =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// A boolean value.
  core.bool? booleanValue;

  /// A double value.
  core.double? doubleValue;

  /// An entity value.
  ///
  /// - May have no key. - May have a key with an incomplete key path. - May
  /// have a reserved/read-only key.
  Entity? entityValue;

  /// If the value should be excluded from all indexes including those defined
  /// explicitly.
  core.bool? excludeFromIndexes;

  /// A geo point value representing a point on the surface of Earth.
  LatLng? geoPointValue;

  /// An integer value.
  core.String? integerValue;

  /// A key value.
  Key? keyValue;

  /// The `meaning` field should only be populated for backwards compatibility.
  core.int? meaning;

  /// A null value.
  /// Possible string values are:
  /// - "NULL_VALUE" : Null value.
  core.String? nullValue;

  /// A UTF-8 encoded string value.
  ///
  /// When `exclude_from_indexes` is false (it is indexed) , may have at most
  /// 1500 bytes. Otherwise, may be set to at most 1,000,000 bytes.
  core.String? stringValue;

  /// A timestamp value.
  ///
  /// When stored in the Datastore, precise only to microseconds; any additional
  /// precision is rounded down.
  core.String? timestampValue;

  Value();

  Value.fromJson(core.Map _json) {
    if (_json.containsKey('arrayValue')) {
      arrayValue = ArrayValue.fromJson(
          _json['arrayValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('blobValue')) {
      blobValue = _json['blobValue'] as core.String;
    }
    if (_json.containsKey('booleanValue')) {
      booleanValue = _json['booleanValue'] as core.bool;
    }
    if (_json.containsKey('doubleValue')) {
      doubleValue = (_json['doubleValue'] as core.num).toDouble();
    }
    if (_json.containsKey('entityValue')) {
      entityValue = Entity.fromJson(
          _json['entityValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('excludeFromIndexes')) {
      excludeFromIndexes = _json['excludeFromIndexes'] as core.bool;
    }
    if (_json.containsKey('geoPointValue')) {
      geoPointValue = LatLng.fromJson(
          _json['geoPointValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('integerValue')) {
      integerValue = _json['integerValue'] as core.String;
    }
    if (_json.containsKey('keyValue')) {
      keyValue = Key.fromJson(
          _json['keyValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('meaning')) {
      meaning = _json['meaning'] as core.int;
    }
    if (_json.containsKey('nullValue')) {
      nullValue = _json['nullValue'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
    if (_json.containsKey('timestampValue')) {
      timestampValue = _json['timestampValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arrayValue != null) 'arrayValue': arrayValue!.toJson(),
        if (blobValue != null) 'blobValue': blobValue!,
        if (booleanValue != null) 'booleanValue': booleanValue!,
        if (doubleValue != null) 'doubleValue': doubleValue!,
        if (entityValue != null) 'entityValue': entityValue!.toJson(),
        if (excludeFromIndexes != null)
          'excludeFromIndexes': excludeFromIndexes!,
        if (geoPointValue != null) 'geoPointValue': geoPointValue!.toJson(),
        if (integerValue != null) 'integerValue': integerValue!,
        if (keyValue != null) 'keyValue': keyValue!.toJson(),
        if (meaning != null) 'meaning': meaning!,
        if (nullValue != null) 'nullValue': nullValue!,
        if (stringValue != null) 'stringValue': stringValue!,
        if (timestampValue != null) 'timestampValue': timestampValue!,
      };
}

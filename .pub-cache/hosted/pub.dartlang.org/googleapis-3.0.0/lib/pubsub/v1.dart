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

/// Cloud Pub/Sub API - v1
///
/// Provides reliable, many-to-many, asynchronous messaging between
/// applications.
///
/// For more information, see <https://cloud.google.com/pubsub/docs>
///
/// Create an instance of [PubsubApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsSchemasResource]
///   - [ProjectsSnapshotsResource]
///   - [ProjectsSubscriptionsResource]
///   - [ProjectsTopicsResource]
///     - [ProjectsTopicsSnapshotsResource]
///     - [ProjectsTopicsSubscriptionsResource]
library pubsub.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Provides reliable, many-to-many, asynchronous messaging between
/// applications.
class PubsubApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View and manage Pub/Sub topics and subscriptions
  static const pubsubScope = 'https://www.googleapis.com/auth/pubsub';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  PubsubApi(http.Client client,
      {core.String rootUrl = 'https://pubsub.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsSchemasResource get schemas => ProjectsSchemasResource(_requester);
  ProjectsSnapshotsResource get snapshots =>
      ProjectsSnapshotsResource(_requester);
  ProjectsSubscriptionsResource get subscriptions =>
      ProjectsSubscriptionsResource(_requester);
  ProjectsTopicsResource get topics => ProjectsTopicsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsSchemasResource {
  final commons.ApiRequester _requester;

  ProjectsSchemasResource(commons.ApiRequester client) : _requester = client;

  /// Creates a schema.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project in which to create the
  /// schema. Format is `projects/{project-id}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [schemaId] - The ID to use for the schema, which will become the final
  /// component of the schema's resource name. See
  /// https://cloud.google.com/pubsub/docs/admin#resource_names for resource
  /// name constraints.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Schema].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Schema> create(
    Schema request,
    core.String parent, {
    core.String? schemaId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (schemaId != null) 'schemaId': [schemaId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/schemas';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Schema.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a schema.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the schema to delete. Format is
  /// `projects/{project}/schemas/{schema}`.
  /// Value must have pattern `^projects/\[^/\]+/schemas/\[^/\]+$`.
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

  /// Gets a schema.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the schema to get. Format is
  /// `projects/{project}/schemas/{schema}`.
  /// Value must have pattern `^projects/\[^/\]+/schemas/\[^/\]+$`.
  ///
  /// [view] - The set of fields to return in the response. If not set, returns
  /// a Schema with `name` and `type`, but not `definition`. Set to `FULL` to
  /// retrieve all fields.
  /// Possible string values are:
  /// - "SCHEMA_VIEW_UNSPECIFIED" : The default / unset value. The API will
  /// default to the BASIC view.
  /// - "BASIC" : Include the name and type of the schema, but not the
  /// definition.
  /// - "FULL" : Include all Schema object fields.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Schema].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Schema> get(
    core.String name, {
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Schema.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/schemas/\[^/\]+$`.
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

  /// Lists schemas in a project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project in which to list schemas.
  /// Format is `projects/{project-id}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum number of schemas to return.
  ///
  /// [pageToken] - The value returned by the last `ListSchemasResponse`;
  /// indicates that this is a continuation of a prior `ListSchemas` call, and
  /// that the system should return the next page of data.
  ///
  /// [view] - The set of Schema fields to return in the response. If not set,
  /// returns Schemas with `name` and `type`, but not `definition`. Set to
  /// `FULL` to retrieve all fields.
  /// Possible string values are:
  /// - "SCHEMA_VIEW_UNSPECIFIED" : The default / unset value. The API will
  /// default to the BASIC view.
  /// - "BASIC" : Include the name and type of the schema, but not the
  /// definition.
  /// - "FULL" : Include all Schema object fields.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSchemasResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSchemasResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/schemas';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSchemasResponse.fromJson(
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
  /// Value must have pattern `^projects/\[^/\]+/schemas/\[^/\]+$`.
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
  /// Value must have pattern `^projects/\[^/\]+/schemas/\[^/\]+$`.
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

  /// Validates a schema.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project in which to validate schemas.
  /// Format is `projects/{project-id}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ValidateSchemaResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ValidateSchemaResponse> validate(
    ValidateSchemaRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/schemas:validate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ValidateSchemaResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Validates a message against a schema.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project in which to validate schemas.
  /// Format is `projects/{project-id}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ValidateMessageResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ValidateMessageResponse> validateMessage(
    ValidateMessageRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/schemas:validateMessage';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ValidateMessageResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsSnapshotsResource {
  final commons.ApiRequester _requester;

  ProjectsSnapshotsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a snapshot from the requested subscription.
  ///
  /// Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you
  /// can set the acknowledgment state of messages in an existing subscription
  /// to the state captured by a snapshot. If the snapshot already exists,
  /// returns `ALREADY_EXISTS`. If the requested subscription doesn't exist,
  /// returns `NOT_FOUND`. If the backlog in the subscription is too old -- and
  /// the resulting snapshot would expire in less than 1 hour -- then
  /// `FAILED_PRECONDITION` is returned. See also the `Snapshot.expire_time`
  /// field. If the name is not provided in the request, the server will assign
  /// a random name for this snapshot on the same project as the subscription,
  /// conforming to the
  /// [resource name format](https://cloud.google.com/pubsub/docs/admin#resource_names).
  /// The generated name is populated in the returned Snapshot object. Note that
  /// for REST API requests, you must specify a name in the request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. User-provided name for this snapshot. If the name is
  /// not provided in the request, the server will assign a random name for this
  /// snapshot on the same project as the subscription. Note that for REST API
  /// requests, you must specify a name. See the resource name rules. Format is
  /// `projects/{project}/snapshots/{snap}`.
  /// Value must have pattern `^projects/\[^/\]+/snapshots/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Snapshot].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Snapshot> create(
    CreateSnapshotRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Snapshot.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Removes an existing snapshot.
  ///
  /// Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you
  /// can set the acknowledgment state of messages in an existing subscription
  /// to the state captured by a snapshot. When the snapshot is deleted, all
  /// messages retained in the snapshot are immediately dropped. After a
  /// snapshot is deleted, a new one may be created with the same name, but the
  /// new one has no association with the old snapshot or its subscription,
  /// unless the same subscription is specified.
  ///
  /// Request parameters:
  ///
  /// [snapshot] - Required. The name of the snapshot to delete. Format is
  /// `projects/{project}/snapshots/{snap}`.
  /// Value must have pattern `^projects/\[^/\]+/snapshots/\[^/\]+$`.
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
    core.String snapshot, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$snapshot');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the configuration details of a snapshot.
  ///
  /// Snapshots are used in Seek operations, which allow you to manage message
  /// acknowledgments in bulk. That is, you can set the acknowledgment state of
  /// messages in an existing subscription to the state captured by a snapshot.
  ///
  /// Request parameters:
  ///
  /// [snapshot] - Required. The name of the snapshot to get. Format is
  /// `projects/{project}/snapshots/{snap}`.
  /// Value must have pattern `^projects/\[^/\]+/snapshots/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Snapshot].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Snapshot> get(
    core.String snapshot, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$snapshot');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Snapshot.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/snapshots/\[^/\]+$`.
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

  /// Lists the existing snapshots.
  ///
  /// Snapshots are used in \[Seek\](
  /// https://cloud.google.com/pubsub/docs/replay-overview) operations, which
  /// allow you to manage message acknowledgments in bulk. That is, you can set
  /// the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot.
  ///
  /// Request parameters:
  ///
  /// [project] - Required. The name of the project in which to list snapshots.
  /// Format is `projects/{project-id}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum number of snapshots to return.
  ///
  /// [pageToken] - The value returned by the last `ListSnapshotsResponse`;
  /// indicates that this is a continuation of a prior `ListSnapshots` call, and
  /// that the system should return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSnapshotsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSnapshotsResponse> list(
    core.String project, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$project') + '/snapshots';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSnapshotsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing snapshot.
  ///
  /// Snapshots are used in Seek operations, which allow you to manage message
  /// acknowledgments in bulk. That is, you can set the acknowledgment state of
  /// messages in an existing subscription to the state captured by a snapshot.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the snapshot.
  /// Value must have pattern `^projects/\[^/\]+/snapshots/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Snapshot].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Snapshot> patch(
    UpdateSnapshotRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Snapshot.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/snapshots/\[^/\]+$`.
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
  /// Value must have pattern `^projects/\[^/\]+/snapshots/\[^/\]+$`.
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

class ProjectsSubscriptionsResource {
  final commons.ApiRequester _requester;

  ProjectsSubscriptionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Acknowledges the messages associated with the `ack_ids` in the
  /// `AcknowledgeRequest`.
  ///
  /// The Pub/Sub system can remove the relevant messages from the subscription.
  /// Acknowledging a message whose ack deadline has expired may succeed, but
  /// such a message may be redelivered later. Acknowledging a message more than
  /// once will not result in an error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The subscription whose message is being
  /// acknowledged. Format is `projects/{project}/subscriptions/{sub}`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
  async.Future<Empty> acknowledge(
    AcknowledgeRequest request,
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$subscription') + ':acknowledge';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a subscription to a given topic.
  ///
  /// See the
  /// [resource name rules](https://cloud.google.com/pubsub/docs/admin#resource_names).
  /// If the subscription already exists, returns `ALREADY_EXISTS`. If the
  /// corresponding topic doesn't exist, returns `NOT_FOUND`. If the name is not
  /// provided in the request, the server will assign a random name for this
  /// subscription on the same project as the topic, conforming to the
  /// [resource name format](https://cloud.google.com/pubsub/docs/admin#resource_names).
  /// The generated name is populated in the returned Subscription object. Note
  /// that for REST API requests, you must specify a name in the request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the subscription. It must have the format
  /// `"projects/{project}/subscriptions/{subscription}"`. `{subscription}` must
  /// start with a letter, and contain only letters (`[A-Za-z]`), numbers
  /// (`[0-9]`), dashes (`-`), underscores (`_`), periods (`.`), tildes (`~`),
  /// plus (`+`) or percent signs (`%`). It must be between 3 and 255 characters
  /// in length, and it must not start with `"goog"`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an existing subscription.
  ///
  /// All messages retained in the subscription are immediately dropped. Calls
  /// to `Pull` after deletion will return `NOT_FOUND`. After a subscription is
  /// deleted, a new one may be created with the same name, but the new one has
  /// no association with the old subscription or its topic unless the same
  /// topic is specified.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The subscription to delete. Format is
  /// `projects/{project}/subscriptions/{sub}`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$subscription');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Detaches a subscription from this topic.
  ///
  /// All messages retained in the subscription are dropped. Subsequent `Pull`
  /// and `StreamingPull` requests will return FAILED_PRECONDITION. If the
  /// subscription is a push subscription, pushes to the endpoint will stop.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The subscription to detach. Format is
  /// `projects/{project}/subscriptions/{subscription}`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DetachSubscriptionResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DetachSubscriptionResponse> detach(
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$subscription') + ':detach';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return DetachSubscriptionResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the configuration details of a subscription.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The name of the subscription to get. Format is
  /// `projects/{project}/subscriptions/{sub}`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$subscription');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
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
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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

  /// Lists matching subscriptions.
  ///
  /// Request parameters:
  ///
  /// [project] - Required. The name of the project in which to list
  /// subscriptions. Format is `projects/{project-id}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum number of subscriptions to return.
  ///
  /// [pageToken] - The value returned by the last `ListSubscriptionsResponse`;
  /// indicates that this is a continuation of a prior `ListSubscriptions` call,
  /// and that the system should return the next page of data.
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
    core.String project, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$project') + '/subscriptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSubscriptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Modifies the ack deadline for a specific message.
  ///
  /// This method is useful to indicate that more time is needed to process a
  /// message by the subscriber, or to make the message available for redelivery
  /// if the processing was interrupted. Note that this does not modify the
  /// subscription-level `ackDeadlineSeconds` used for subsequent messages.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The name of the subscription. Format is
  /// `projects/{project}/subscriptions/{sub}`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
  async.Future<Empty> modifyAckDeadline(
    ModifyAckDeadlineRequest request,
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$subscription') + ':modifyAckDeadline';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Modifies the `PushConfig` for a specified subscription.
  ///
  /// This may be used to change a push subscription to a pull one (signified by
  /// an empty `PushConfig`) or vice versa, or change the endpoint URL and other
  /// attributes of a push subscription. Messages will accumulate for delivery
  /// continuously through the call regardless of changes to the `PushConfig`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The name of the subscription. Format is
  /// `projects/{project}/subscriptions/{sub}`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
  async.Future<Empty> modifyPushConfig(
    ModifyPushConfigRequest request,
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$subscription') + ':modifyPushConfig';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing subscription.
  ///
  /// Note that certain properties of a subscription, such as its topic, are not
  /// modifiable.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the subscription. It must have the format
  /// `"projects/{project}/subscriptions/{subscription}"`. `{subscription}` must
  /// start with a letter, and contain only letters (`[A-Za-z]`), numbers
  /// (`[0-9]`), dashes (`-`), underscores (`_`), periods (`.`), tildes (`~`),
  /// plus (`+`) or percent signs (`%`). It must be between 3 and 255 characters
  /// in length, and it must not start with `"goog"`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
    UpdateSubscriptionRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Pulls messages from the server.
  ///
  /// The server may return `UNAVAILABLE` if there are too many concurrent pull
  /// requests pending for the given subscription.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The subscription from which messages should be
  /// pulled. Format is `projects/{project}/subscriptions/{sub}`.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PullResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PullResponse> pull(
    PullRequest request,
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$subscription') + ':pull';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PullResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Seeks an existing subscription to a point in time or to a given snapshot,
  /// whichever is provided in the request.
  ///
  /// Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you
  /// can set the acknowledgment state of messages in an existing subscription
  /// to the state captured by a snapshot. Note that both the subscription and
  /// the snapshot must be on the same topic.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [subscription] - Required. The subscription to affect.
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SeekResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SeekResponse> seek(
    SeekRequest request,
    core.String subscription, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$subscription') + ':seek';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SeekResponse.fromJson(
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
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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
  /// Value must have pattern `^projects/\[^/\]+/subscriptions/\[^/\]+$`.
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

class ProjectsTopicsResource {
  final commons.ApiRequester _requester;

  ProjectsTopicsSnapshotsResource get snapshots =>
      ProjectsTopicsSnapshotsResource(_requester);
  ProjectsTopicsSubscriptionsResource get subscriptions =>
      ProjectsTopicsSubscriptionsResource(_requester);

  ProjectsTopicsResource(commons.ApiRequester client) : _requester = client;

  /// Creates the given topic with the given name.
  ///
  /// See the
  /// [resource name rules](https://cloud.google.com/pubsub/docs/admin#resource_names).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the topic. It must have the format
  /// `"projects/{project}/topics/{topic}"`. `{topic}` must start with a letter,
  /// and contain only letters (`[A-Za-z]`), numbers (`[0-9]`), dashes (`-`),
  /// underscores (`_`), periods (`.`), tildes (`~`), plus (`+`) or percent
  /// signs (`%`). It must be between 3 and 255 characters in length, and it
  /// must not start with `"goog"`.
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
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
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Topic.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the topic with the given name.
  ///
  /// Returns `NOT_FOUND` if the topic does not exist. After a topic is deleted,
  /// a new topic may be created with the same name; this is an entirely new
  /// topic with none of the old configuration or subscriptions. Existing
  /// subscriptions to this topic are not deleted, but their `topic` field is
  /// set to `_deleted-topic_`.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. Name of the topic to delete. Format is
  /// `projects/{project}/topics/{topic}`.
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
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
    core.String topic, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$topic');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the configuration of a topic.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. The name of the topic to get. Format is
  /// `projects/{project}/topics/{topic}`.
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
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
    core.String topic, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$topic');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Topic.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
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

  /// Lists matching topics.
  ///
  /// Request parameters:
  ///
  /// [project] - Required. The name of the project in which to list topics.
  /// Format is `projects/{project-id}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum number of topics to return.
  ///
  /// [pageToken] - The value returned by the last `ListTopicsResponse`;
  /// indicates that this is a continuation of a prior `ListTopics` call, and
  /// that the system should return the next page of data.
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
    core.String project, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$project') + '/topics';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTopicsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing topic.
  ///
  /// Note that certain properties of a topic are not modifiable.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the topic. It must have the format
  /// `"projects/{project}/topics/{topic}"`. `{topic}` must start with a letter,
  /// and contain only letters (`[A-Za-z]`), numbers (`[0-9]`), dashes (`-`),
  /// underscores (`_`), periods (`.`), tildes (`~`), plus (`+`) or percent
  /// signs (`%`). It must be between 3 and 255 characters in length, and it
  /// must not start with `"goog"`.
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
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
    UpdateTopicRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Topic.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Adds one or more messages to the topic.
  ///
  /// Returns `NOT_FOUND` if the topic does not exist.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. The messages in the request will be published on this
  /// topic. Format is `projects/{project}/topics/{topic}`.
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PublishResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PublishResponse> publish(
    PublishRequest request,
    core.String topic, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$topic') + ':publish';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PublishResponse.fromJson(
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
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
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
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
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

class ProjectsTopicsSnapshotsResource {
  final commons.ApiRequester _requester;

  ProjectsTopicsSnapshotsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the names of the snapshots on this topic.
  ///
  /// Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you
  /// can set the acknowledgment state of messages in an existing subscription
  /// to the state captured by a snapshot.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. The name of the topic that snapshots are attached to.
  /// Format is `projects/{project}/topics/{topic}`.
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum number of snapshot names to return.
  ///
  /// [pageToken] - The value returned by the last `ListTopicSnapshotsResponse`;
  /// indicates that this is a continuation of a prior `ListTopicSnapshots`
  /// call, and that the system should return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTopicSnapshotsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTopicSnapshotsResponse> list(
    core.String topic, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$topic') + '/snapshots';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTopicSnapshotsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsTopicsSubscriptionsResource {
  final commons.ApiRequester _requester;

  ProjectsTopicsSubscriptionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the names of the attached subscriptions on this topic.
  ///
  /// Request parameters:
  ///
  /// [topic] - Required. The name of the topic that subscriptions are attached
  /// to. Format is `projects/{project}/topics/{topic}`.
  /// Value must have pattern `^projects/\[^/\]+/topics/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum number of subscription names to return.
  ///
  /// [pageToken] - The value returned by the last
  /// `ListTopicSubscriptionsResponse`; indicates that this is a continuation of
  /// a prior `ListTopicSubscriptions` call, and that the system should return
  /// the next page of data.
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
    core.String topic, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$topic') + '/subscriptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTopicSubscriptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Request for the Acknowledge method.
class AcknowledgeRequest {
  /// The acknowledgment ID for the messages being acknowledged that was
  /// returned by the Pub/Sub system in the `Pull` response.
  ///
  /// Must not be empty.
  ///
  /// Required.
  core.List<core.String>? ackIds;

  AcknowledgeRequest();

  AcknowledgeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('ackIds')) {
      ackIds = (_json['ackIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ackIds != null) 'ackIds': ackIds!,
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

/// Request for the `CreateSnapshot` method.
class CreateSnapshotRequest {
  /// See Creating and managing labels.
  core.Map<core.String, core.String>? labels;

  /// The subscription whose backlog the snapshot retains.
  ///
  /// Specifically, the created snapshot is guaranteed to retain: (a) The
  /// existing backlog on the subscription. More precisely, this is defined as
  /// the messages in the subscription's backlog that are unacknowledged upon
  /// the successful completion of the `CreateSnapshot` request; as well as: (b)
  /// Any messages published to the subscription's topic following the
  /// successful completion of the CreateSnapshot request. Format is
  /// `projects/{project}/subscriptions/{sub}`.
  ///
  /// Required.
  core.String? subscription;

  CreateSnapshotRequest();

  CreateSnapshotRequest.fromJson(core.Map _json) {
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('subscription')) {
      subscription = _json['subscription'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labels != null) 'labels': labels!,
        if (subscription != null) 'subscription': subscription!,
      };
}

/// Dead lettering is done on a best effort basis.
///
/// The same message might be dead lettered multiple times. If validation on any
/// of the fields fails at subscription creation/updation, the create/update
/// subscription request will fail.
class DeadLetterPolicy {
  /// The name of the topic to which dead letter messages should be published.
  ///
  /// Format is `projects/{project}/topics/{topic}`.The Cloud Pub/Sub service
  /// account associated with the enclosing subscription's parent project (i.e.,
  /// service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com) must have
  /// permission to Publish() to this topic. The operation will fail if the
  /// topic does not exist. Users should ensure that there is a subscription
  /// attached to this topic since messages published to a topic with no
  /// subscriptions are lost.
  core.String? deadLetterTopic;

  /// The maximum number of delivery attempts for any message.
  ///
  /// The value must be between 5 and 100. The number of delivery attempts is
  /// defined as 1 + (the sum of number of NACKs and number of times the
  /// acknowledgement deadline has been exceeded for the message). A NACK is any
  /// call to ModifyAckDeadline with a 0 deadline. Note that client libraries
  /// may automatically extend ack_deadlines. This field will be honored on a
  /// best effort basis. If this parameter is 0, a default value of 5 is used.
  core.int? maxDeliveryAttempts;

  DeadLetterPolicy();

  DeadLetterPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('deadLetterTopic')) {
      deadLetterTopic = _json['deadLetterTopic'] as core.String;
    }
    if (_json.containsKey('maxDeliveryAttempts')) {
      maxDeliveryAttempts = _json['maxDeliveryAttempts'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deadLetterTopic != null) 'deadLetterTopic': deadLetterTopic!,
        if (maxDeliveryAttempts != null)
          'maxDeliveryAttempts': maxDeliveryAttempts!,
      };
}

/// Response for the DetachSubscription method.
///
/// Reserved for future use.
class DetachSubscriptionResponse {
  DetachSubscriptionResponse();

  DetachSubscriptionResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// A policy that specifies the conditions for resource expiration (i.e.,
/// automatic resource deletion).
class ExpirationPolicy {
  /// Specifies the "time-to-live" duration for an associated resource.
  ///
  /// The resource expires if it is not active for a period of `ttl`. The
  /// definition of "activity" depends on the type of the associated resource.
  /// The minimum and maximum allowed values for `ttl` depend on the type of the
  /// associated resource, as well. If `ttl` is not set, the associated resource
  /// never expires.
  core.String? ttl;

  ExpirationPolicy();

  ExpirationPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('ttl')) {
      ttl = _json['ttl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ttl != null) 'ttl': ttl!,
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

/// Response for the `ListSchemas` method.
class ListSchemasResponse {
  /// If not empty, indicates that there may be more schemas that match the
  /// request; this value should be passed in a new `ListSchemasRequest`.
  core.String? nextPageToken;

  /// The resulting schemas.
  core.List<Schema>? schemas;

  ListSchemasResponse();

  ListSchemasResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('schemas')) {
      schemas = (_json['schemas'] as core.List)
          .map<Schema>((value) =>
              Schema.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (schemas != null)
          'schemas': schemas!.map((value) => value.toJson()).toList(),
      };
}

/// Response for the `ListSnapshots` method.
class ListSnapshotsResponse {
  /// If not empty, indicates that there may be more snapshot that match the
  /// request; this value should be passed in a new `ListSnapshotsRequest`.
  core.String? nextPageToken;

  /// The resulting snapshots.
  core.List<Snapshot>? snapshots;

  ListSnapshotsResponse();

  ListSnapshotsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('snapshots')) {
      snapshots = (_json['snapshots'] as core.List)
          .map<Snapshot>((value) =>
              Snapshot.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (snapshots != null)
          'snapshots': snapshots!.map((value) => value.toJson()).toList(),
      };
}

/// Response for the `ListSubscriptions` method.
class ListSubscriptionsResponse {
  /// If not empty, indicates that there may be more subscriptions that match
  /// the request; this value should be passed in a new
  /// `ListSubscriptionsRequest` to get more subscriptions.
  core.String? nextPageToken;

  /// The subscriptions that match the request.
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

/// Response for the `ListTopicSnapshots` method.
class ListTopicSnapshotsResponse {
  /// If not empty, indicates that there may be more snapshots that match the
  /// request; this value should be passed in a new `ListTopicSnapshotsRequest`
  /// to get more snapshots.
  core.String? nextPageToken;

  /// The names of the snapshots that match the request.
  core.List<core.String>? snapshots;

  ListTopicSnapshotsResponse();

  ListTopicSnapshotsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('snapshots')) {
      snapshots = (_json['snapshots'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (snapshots != null) 'snapshots': snapshots!,
      };
}

/// Response for the `ListTopicSubscriptions` method.
class ListTopicSubscriptionsResponse {
  /// If not empty, indicates that there may be more subscriptions that match
  /// the request; this value should be passed in a new
  /// `ListTopicSubscriptionsRequest` to get more subscriptions.
  core.String? nextPageToken;

  /// The names of subscriptions attached to the topic specified in the request.
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

/// Response for the `ListTopics` method.
class ListTopicsResponse {
  /// If not empty, indicates that there may be more topics that match the
  /// request; this value should be passed in a new `ListTopicsRequest`.
  core.String? nextPageToken;

  /// The resulting topics.
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

/// A policy constraining the storage of messages published to the topic.
class MessageStoragePolicy {
  /// A list of IDs of GCP regions where messages that are published to the
  /// topic may be persisted in storage.
  ///
  /// Messages published by publishers running in non-allowed GCP regions (or
  /// running outside of GCP altogether) will be routed for storage in one of
  /// the allowed regions. An empty list means that no regions are allowed, and
  /// is not a valid configuration.
  core.List<core.String>? allowedPersistenceRegions;

  MessageStoragePolicy();

  MessageStoragePolicy.fromJson(core.Map _json) {
    if (_json.containsKey('allowedPersistenceRegions')) {
      allowedPersistenceRegions =
          (_json['allowedPersistenceRegions'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedPersistenceRegions != null)
          'allowedPersistenceRegions': allowedPersistenceRegions!,
      };
}

/// Request for the ModifyAckDeadline method.
class ModifyAckDeadlineRequest {
  /// The new ack deadline with respect to the time this request was sent to the
  /// Pub/Sub system.
  ///
  /// For example, if the value is 10, the new ack deadline will expire 10
  /// seconds after the `ModifyAckDeadline` call was made. Specifying zero might
  /// immediately make the message available for delivery to another subscriber
  /// client. This typically results in an increase in the rate of message
  /// redeliveries (that is, duplicates). The minimum deadline you can specify
  /// is 0 seconds. The maximum deadline you can specify is 600 seconds (10
  /// minutes).
  ///
  /// Required.
  core.int? ackDeadlineSeconds;

  /// List of acknowledgment IDs.
  ///
  /// Required.
  core.List<core.String>? ackIds;

  ModifyAckDeadlineRequest();

  ModifyAckDeadlineRequest.fromJson(core.Map _json) {
    if (_json.containsKey('ackDeadlineSeconds')) {
      ackDeadlineSeconds = _json['ackDeadlineSeconds'] as core.int;
    }
    if (_json.containsKey('ackIds')) {
      ackIds = (_json['ackIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ackDeadlineSeconds != null)
          'ackDeadlineSeconds': ackDeadlineSeconds!,
        if (ackIds != null) 'ackIds': ackIds!,
      };
}

/// Request for the ModifyPushConfig method.
class ModifyPushConfigRequest {
  /// The push configuration for future deliveries.
  ///
  /// An empty `pushConfig` indicates that the Pub/Sub system should stop
  /// pushing messages from the given subscription and allow messages to be
  /// pulled and acknowledged - effectively pausing the subscription if `Pull`
  /// or `StreamingPull` is not called.
  ///
  /// Required.
  PushConfig? pushConfig;

  ModifyPushConfigRequest();

  ModifyPushConfigRequest.fromJson(core.Map _json) {
    if (_json.containsKey('pushConfig')) {
      pushConfig = PushConfig.fromJson(
          _json['pushConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pushConfig != null) 'pushConfig': pushConfig!.toJson(),
      };
}

/// Contains information needed for generating an
/// [OpenID Connect token](https://developers.google.com/identity/protocols/OpenIDConnect).
class OidcToken {
  /// Audience to be used when generating OIDC token.
  ///
  /// The audience claim identifies the recipients that the JWT is intended for.
  /// The audience value is a single case-sensitive string. Having multiple
  /// values (array) for the audience field is not supported. More info about
  /// the OIDC JWT token audience here:
  /// https://tools.ietf.org/html/rfc7519#section-4.1.3 Note: if not specified,
  /// the Push endpoint URL will be used.
  core.String? audience;

  /// [Service account email](https://cloud.google.com/iam/docs/service-accounts)
  /// to be used for generating the OIDC token.
  ///
  /// The caller (for CreateSubscription, UpdateSubscription, and
  /// ModifyPushConfig RPCs) must have the iam.serviceAccounts.actAs permission
  /// for the service account.
  core.String? serviceAccountEmail;

  OidcToken();

  OidcToken.fromJson(core.Map _json) {
    if (_json.containsKey('audience')) {
      audience = _json['audience'] as core.String;
    }
    if (_json.containsKey('serviceAccountEmail')) {
      serviceAccountEmail = _json['serviceAccountEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audience != null) 'audience': audience!,
        if (serviceAccountEmail != null)
          'serviceAccountEmail': serviceAccountEmail!,
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
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (version != null) 'version': version!,
      };
}

/// Request for the Publish method.
class PublishRequest {
  /// The messages to publish.
  ///
  /// Required.
  core.List<PubsubMessage>? messages;

  PublishRequest();

  PublishRequest.fromJson(core.Map _json) {
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<PubsubMessage>((value) => PubsubMessage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
      };
}

/// Response for the `Publish` method.
class PublishResponse {
  /// The server-assigned ID of each published message, in the same order as the
  /// messages in the request.
  ///
  /// IDs are guaranteed to be unique within the topic.
  core.List<core.String>? messageIds;

  PublishResponse();

  PublishResponse.fromJson(core.Map _json) {
    if (_json.containsKey('messageIds')) {
      messageIds = (_json['messageIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (messageIds != null) 'messageIds': messageIds!,
      };
}

/// A message that is published by publishers and consumed by subscribers.
///
/// The message must contain either a non-empty data field or at least one
/// attribute. Note that client libraries represent this object differently
/// depending on the language. See the corresponding
/// [client library documentation](https://cloud.google.com/pubsub/docs/reference/libraries)
/// for more information. See
/// [quotas and limits](https://cloud.google.com/pubsub/quotas) for more
/// information about message limits.
class PubsubMessage {
  /// Attributes for this message.
  ///
  /// If this field is empty, the message must contain non-empty data. This can
  /// be used to filter messages on the subscription.
  core.Map<core.String, core.String>? attributes;

  /// The message data field.
  ///
  /// If this field is empty, the message must contain at least one attribute.
  core.String? data;
  core.List<core.int> get dataAsBytes => convert.base64.decode(data!);

  set dataAsBytes(core.List<core.int> _bytes) {
    data =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// ID of this message, assigned by the server when the message is published.
  ///
  /// Guaranteed to be unique within the topic. This value may be read by a
  /// subscriber that receives a `PubsubMessage` via a `Pull` call or a push
  /// delivery. It must not be populated by the publisher in a `Publish` call.
  core.String? messageId;

  /// If non-empty, identifies related messages for which publish order should
  /// be respected.
  ///
  /// If a `Subscription` has `enable_message_ordering` set to `true`, messages
  /// published with the same non-empty `ordering_key` value will be delivered
  /// to subscribers in the order in which they are received by the Pub/Sub
  /// system. All `PubsubMessage`s published in a given `PublishRequest` must
  /// specify the same `ordering_key` value.
  core.String? orderingKey;

  /// The time at which the message was published, populated by the server when
  /// it receives the `Publish` call.
  ///
  /// It must not be populated by the publisher in a `Publish` call.
  core.String? publishTime;

  PubsubMessage();

  PubsubMessage.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes =
          (_json['attributes'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('messageId')) {
      messageId = _json['messageId'] as core.String;
    }
    if (_json.containsKey('orderingKey')) {
      orderingKey = _json['orderingKey'] as core.String;
    }
    if (_json.containsKey('publishTime')) {
      publishTime = _json['publishTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null) 'attributes': attributes!,
        if (data != null) 'data': data!,
        if (messageId != null) 'messageId': messageId!,
        if (orderingKey != null) 'orderingKey': orderingKey!,
        if (publishTime != null) 'publishTime': publishTime!,
      };
}

/// Request for the `Pull` method.
class PullRequest {
  /// The maximum number of messages to return for this request.
  ///
  /// Must be a positive integer. The Pub/Sub system may return fewer than the
  /// number specified.
  ///
  /// Required.
  core.int? maxMessages;

  /// If this field set to true, the system will respond immediately even if it
  /// there are no messages available to return in the `Pull` response.
  ///
  /// Otherwise, the system may wait (for a bounded amount of time) until at
  /// least one message is available, rather than returning no messages.
  /// Warning: setting this field to `true` is discouraged because it adversely
  /// impacts the performance of `Pull` operations. We recommend that users do
  /// not set this field.
  ///
  /// Optional.
  core.bool? returnImmediately;

  PullRequest();

  PullRequest.fromJson(core.Map _json) {
    if (_json.containsKey('maxMessages')) {
      maxMessages = _json['maxMessages'] as core.int;
    }
    if (_json.containsKey('returnImmediately')) {
      returnImmediately = _json['returnImmediately'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxMessages != null) 'maxMessages': maxMessages!,
        if (returnImmediately != null) 'returnImmediately': returnImmediately!,
      };
}

/// Response for the `Pull` method.
class PullResponse {
  /// Received Pub/Sub messages.
  ///
  /// The list will be empty if there are no more messages available in the
  /// backlog. For JSON, the response can be entirely empty. The Pub/Sub system
  /// may return fewer than the `maxMessages` requested even if there are more
  /// messages available in the backlog.
  core.List<ReceivedMessage>? receivedMessages;

  PullResponse();

  PullResponse.fromJson(core.Map _json) {
    if (_json.containsKey('receivedMessages')) {
      receivedMessages = (_json['receivedMessages'] as core.List)
          .map<ReceivedMessage>((value) => ReceivedMessage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (receivedMessages != null)
          'receivedMessages':
              receivedMessages!.map((value) => value.toJson()).toList(),
      };
}

/// Configuration for a push delivery endpoint.
class PushConfig {
  /// Endpoint configuration attributes that can be used to control different
  /// aspects of the message delivery.
  ///
  /// The only currently supported attribute is `x-goog-version`, which you can
  /// use to change the format of the pushed message. This attribute indicates
  /// the version of the data expected by the endpoint. This controls the shape
  /// of the pushed message (i.e., its fields and metadata). If not present
  /// during the `CreateSubscription` call, it will default to the version of
  /// the Pub/Sub API used to make such call. If not present in a
  /// `ModifyPushConfig` call, its value will not be changed. `GetSubscription`
  /// calls will always return a valid version, even if the subscription was
  /// created without this attribute. The only supported values for the
  /// `x-goog-version` attribute are: * `v1beta1`: uses the push format defined
  /// in the v1beta1 Pub/Sub API. * `v1` or `v1beta2`: uses the push format
  /// defined in the v1 Pub/Sub API. For example: attributes { "x-goog-version":
  /// "v1" }
  core.Map<core.String, core.String>? attributes;

  /// If specified, Pub/Sub will generate and attach an OIDC JWT token as an
  /// `Authorization` header in the HTTP request for every pushed message.
  OidcToken? oidcToken;

  /// A URL locating the endpoint to which messages should be pushed.
  ///
  /// For example, a Webhook endpoint might use `https://example.com/push`.
  core.String? pushEndpoint;

  PushConfig();

  PushConfig.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes =
          (_json['attributes'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('oidcToken')) {
      oidcToken = OidcToken.fromJson(
          _json['oidcToken'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pushEndpoint')) {
      pushEndpoint = _json['pushEndpoint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null) 'attributes': attributes!,
        if (oidcToken != null) 'oidcToken': oidcToken!.toJson(),
        if (pushEndpoint != null) 'pushEndpoint': pushEndpoint!,
      };
}

/// A message and its corresponding acknowledgment ID.
class ReceivedMessage {
  /// This ID can be used to acknowledge the received message.
  core.String? ackId;

  /// The approximate number of times that Cloud Pub/Sub has attempted to
  /// deliver the associated message to a subscriber.
  ///
  /// More precisely, this is 1 + (number of NACKs) + (number of ack_deadline
  /// exceeds) for this message. A NACK is any call to ModifyAckDeadline with a
  /// 0 deadline. An ack_deadline exceeds event is whenever a message is not
  /// acknowledged within ack_deadline. Note that ack_deadline is initially
  /// Subscription.ackDeadlineSeconds, but may get extended automatically by the
  /// client library. Upon the first delivery of a given message,
  /// `delivery_attempt` will have a value of 1. The value is calculated at best
  /// effort and is approximate. If a DeadLetterPolicy is not set on the
  /// subscription, this will be 0.
  core.int? deliveryAttempt;

  /// The message.
  PubsubMessage? message;

  ReceivedMessage();

  ReceivedMessage.fromJson(core.Map _json) {
    if (_json.containsKey('ackId')) {
      ackId = _json['ackId'] as core.String;
    }
    if (_json.containsKey('deliveryAttempt')) {
      deliveryAttempt = _json['deliveryAttempt'] as core.int;
    }
    if (_json.containsKey('message')) {
      message = PubsubMessage.fromJson(
          _json['message'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ackId != null) 'ackId': ackId!,
        if (deliveryAttempt != null) 'deliveryAttempt': deliveryAttempt!,
        if (message != null) 'message': message!.toJson(),
      };
}

/// A policy that specifies how Cloud Pub/Sub retries message delivery.
///
/// Retry delay will be exponential based on provided minimum and maximum
/// backoffs. https://en.wikipedia.org/wiki/Exponential_backoff. RetryPolicy
/// will be triggered on NACKs or acknowledgement deadline exceeded events for a
/// given message. Retry Policy is implemented on a best effort basis. At times,
/// the delay between consecutive deliveries may not match the configuration.
/// That is, delay can be more or less than configured backoff.
class RetryPolicy {
  /// The maximum delay between consecutive deliveries of a given message.
  ///
  /// Value should be between 0 and 600 seconds. Defaults to 600 seconds.
  core.String? maximumBackoff;

  /// The minimum delay between consecutive deliveries of a given message.
  ///
  /// Value should be between 0 and 600 seconds. Defaults to 10 seconds.
  core.String? minimumBackoff;

  RetryPolicy();

  RetryPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('maximumBackoff')) {
      maximumBackoff = _json['maximumBackoff'] as core.String;
    }
    if (_json.containsKey('minimumBackoff')) {
      minimumBackoff = _json['minimumBackoff'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maximumBackoff != null) 'maximumBackoff': maximumBackoff!,
        if (minimumBackoff != null) 'minimumBackoff': minimumBackoff!,
      };
}

/// A schema resource.
class Schema {
  /// The definition of the schema.
  ///
  /// This should contain a string representing the full definition of the
  /// schema that is a valid schema definition of the type specified in `type`.
  core.String? definition;

  /// Name of the schema.
  ///
  /// Format is `projects/{project}/schemas/{schema}`.
  ///
  /// Required.
  core.String? name;

  /// The type of the schema definition.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "PROTOCOL_BUFFER" : A Protocol Buffer schema definition.
  /// - "AVRO" : An Avro schema definition.
  core.String? type;

  Schema();

  Schema.fromJson(core.Map _json) {
    if (_json.containsKey('definition')) {
      definition = _json['definition'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (definition != null) 'definition': definition!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

/// Settings for validating messages published against a schema.
class SchemaSettings {
  /// The encoding of messages validated against `schema`.
  /// Possible string values are:
  /// - "ENCODING_UNSPECIFIED" : Unspecified
  /// - "JSON" : JSON encoding
  /// - "BINARY" : Binary encoding, as defined by the schema type. For some
  /// schema types, binary encoding may not be available.
  core.String? encoding;

  /// The name of the schema that messages published should be validated
  /// against.
  ///
  /// Format is `projects/{project}/schemas/{schema}`. The value of this field
  /// will be `_deleted-schema_` if the schema has been deleted.
  ///
  /// Required.
  core.String? schema;

  SchemaSettings();

  SchemaSettings.fromJson(core.Map _json) {
    if (_json.containsKey('encoding')) {
      encoding = _json['encoding'] as core.String;
    }
    if (_json.containsKey('schema')) {
      schema = _json['schema'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (encoding != null) 'encoding': encoding!,
        if (schema != null) 'schema': schema!,
      };
}

/// Request for the `Seek` method.
class SeekRequest {
  /// The snapshot to seek to.
  ///
  /// The snapshot's topic must be the same as that of the provided
  /// subscription. Format is `projects/{project}/snapshots/{snap}`.
  core.String? snapshot;

  /// The time to seek to.
  ///
  /// Messages retained in the subscription that were published before this time
  /// are marked as acknowledged, and messages retained in the subscription that
  /// were published after this time are marked as unacknowledged. Note that
  /// this operation affects only those messages retained in the subscription
  /// (configured by the combination of `message_retention_duration` and
  /// `retain_acked_messages`). For example, if `time` corresponds to a point
  /// before the message retention window (or to a point before the system's
  /// notion of the subscription creation time), only retained messages will be
  /// marked as unacknowledged, and already-expunged messages will not be
  /// restored.
  core.String? time;

  SeekRequest();

  SeekRequest.fromJson(core.Map _json) {
    if (_json.containsKey('snapshot')) {
      snapshot = _json['snapshot'] as core.String;
    }
    if (_json.containsKey('time')) {
      time = _json['time'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (snapshot != null) 'snapshot': snapshot!,
        if (time != null) 'time': time!,
      };
}

/// Response for the `Seek` method (this response is empty).
class SeekResponse {
  SeekResponse();

  SeekResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for `SetIamPolicy` method.
class SetIamPolicyRequest {
  /// REQUIRED: The complete policy to be applied to the `resource`.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is a
  /// valid policy but certain Cloud Platform services (such as Projects) might
  /// reject them.
  Policy? policy;

  SetIamPolicyRequest();

  SetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
      };
}

/// A snapshot resource.
///
/// Snapshots are used in
/// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
/// which allow you to manage message acknowledgments in bulk. That is, you can
/// set the acknowledgment state of messages in an existing subscription to the
/// state captured by a snapshot.
class Snapshot {
  /// The snapshot is guaranteed to exist up until this time.
  ///
  /// A newly-created snapshot expires no later than 7 days from the time of its
  /// creation. Its exact lifetime is determined at creation by the existing
  /// backlog in the source subscription. Specifically, the lifetime of the
  /// snapshot is `7 days - (age of oldest unacked message in the
  /// subscription)`. For example, consider a subscription whose oldest unacked
  /// message is 3 days old. If a snapshot is created from this subscription,
  /// the snapshot -- which will always capture this 3-day-old backlog as long
  /// as the snapshot exists -- will expire in 4 days. The service will refuse
  /// to create a snapshot that would expire in less than 1 hour after creation.
  core.String? expireTime;

  /// See
  /// [Creating and managing labels](https://cloud.google.com/pubsub/docs/labels).
  core.Map<core.String, core.String>? labels;

  /// The name of the snapshot.
  core.String? name;

  /// The name of the topic from which this snapshot is retaining messages.
  core.String? topic;

  Snapshot();

  Snapshot.fromJson(core.Map _json) {
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
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
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expireTime != null) 'expireTime': expireTime!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (topic != null) 'topic': topic!,
      };
}

/// A subscription resource.
class Subscription {
  /// The approximate amount of time (on a best-effort basis) Pub/Sub waits for
  /// the subscriber to acknowledge receipt before resending the message.
  ///
  /// In the interval after the message is delivered and before it is
  /// acknowledged, it is considered to be *outstanding*. During that time
  /// period, the message will not be redelivered (on a best-effort basis). For
  /// pull subscriptions, this value is used as the initial value for the ack
  /// deadline. To override this value for a given message, call
  /// `ModifyAckDeadline` with the corresponding `ack_id` if using non-streaming
  /// pull or send the `ack_id` in a `StreamingModifyAckDeadlineRequest` if
  /// using streaming pull. The minimum custom deadline you can specify is 10
  /// seconds. The maximum custom deadline you can specify is 600 seconds (10
  /// minutes). If this parameter is 0, a default value of 10 seconds is used.
  /// For push delivery, this value is also used to set the request timeout for
  /// the call to the push endpoint. If the subscriber never acknowledges the
  /// message, the Pub/Sub system will eventually redeliver the message.
  core.int? ackDeadlineSeconds;

  /// A policy that specifies the conditions for dead lettering messages in this
  /// subscription.
  ///
  /// If dead_letter_policy is not set, dead lettering is disabled. The Cloud
  /// Pub/Sub service account associated with this subscriptions's parent
  /// project (i.e.,
  /// service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com) must have
  /// permission to Acknowledge() messages on this subscription.
  DeadLetterPolicy? deadLetterPolicy;

  /// Indicates whether the subscription is detached from its topic.
  ///
  /// Detached subscriptions don't receive messages from their topic and don't
  /// retain any backlog. `Pull` and `StreamingPull` requests will return
  /// FAILED_PRECONDITION. If the subscription is a push subscription, pushes to
  /// the endpoint will not be made.
  core.bool? detached;

  /// If true, messages published with the same `ordering_key` in
  /// `PubsubMessage` will be delivered to the subscribers in the order in which
  /// they are received by the Pub/Sub system.
  ///
  /// Otherwise, they may be delivered in any order.
  core.bool? enableMessageOrdering;

  /// A policy that specifies the conditions for this subscription's expiration.
  ///
  /// A subscription is considered active as long as any connected subscriber is
  /// successfully consuming messages from the subscription or is issuing
  /// operations on the subscription. If `expiration_policy` is not set, a
  /// *default policy* with `ttl` of 31 days will be used. The minimum allowed
  /// value for `expiration_policy.ttl` is 1 day.
  ExpirationPolicy? expirationPolicy;

  /// An expression written in the Pub/Sub
  /// [filter language](https://cloud.google.com/pubsub/docs/filtering).
  ///
  /// If non-empty, then only `PubsubMessage`s whose `attributes` field matches
  /// the filter are delivered on this subscription. If empty, then no messages
  /// are filtered out.
  core.String? filter;

  /// See Creating and managing labels.
  core.Map<core.String, core.String>? labels;

  /// How long to retain unacknowledged messages in the subscription's backlog,
  /// from the moment a message is published.
  ///
  /// If `retain_acked_messages` is true, then this also configures the
  /// retention of acknowledged messages, and thus configures how far back in
  /// time a `Seek` can be done. Defaults to 7 days. Cannot be more than 7 days
  /// or less than 10 minutes.
  core.String? messageRetentionDuration;

  /// The name of the subscription.
  ///
  /// It must have the format
  /// `"projects/{project}/subscriptions/{subscription}"`. `{subscription}` must
  /// start with a letter, and contain only letters (`[A-Za-z]`), numbers
  /// (`[0-9]`), dashes (`-`), underscores (`_`), periods (`.`), tildes (`~`),
  /// plus (`+`) or percent signs (`%`). It must be between 3 and 255 characters
  /// in length, and it must not start with `"goog"`.
  ///
  /// Required.
  core.String? name;

  /// If push delivery is used with this subscription, this field is used to
  /// configure it.
  ///
  /// An empty `pushConfig` signifies that the subscriber will pull and ack
  /// messages using API methods.
  PushConfig? pushConfig;

  /// Indicates whether to retain acknowledged messages.
  ///
  /// If true, then messages are not expunged from the subscription's backlog,
  /// even if they are acknowledged, until they fall out of the
  /// `message_retention_duration` window. This must be true if you would like
  /// to \[`Seek` to a
  /// timestamp\](https://cloud.google.com/pubsub/docs/replay-overview#seek_to_a_time)
  /// in the past to replay previously-acknowledged messages.
  core.bool? retainAckedMessages;

  /// A policy that specifies how Pub/Sub retries message delivery for this
  /// subscription.
  ///
  /// If not set, the default retry policy is applied. This generally implies
  /// that messages will be retried as soon as possible for healthy subscribers.
  /// RetryPolicy will be triggered on NACKs or acknowledgement deadline
  /// exceeded events for a given message.
  RetryPolicy? retryPolicy;

  /// The name of the topic from which this subscription is receiving messages.
  ///
  /// Format is `projects/{project}/topics/{topic}`. The value of this field
  /// will be `_deleted-topic_` if the topic has been deleted.
  ///
  /// Required.
  core.String? topic;

  Subscription();

  Subscription.fromJson(core.Map _json) {
    if (_json.containsKey('ackDeadlineSeconds')) {
      ackDeadlineSeconds = _json['ackDeadlineSeconds'] as core.int;
    }
    if (_json.containsKey('deadLetterPolicy')) {
      deadLetterPolicy = DeadLetterPolicy.fromJson(
          _json['deadLetterPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('detached')) {
      detached = _json['detached'] as core.bool;
    }
    if (_json.containsKey('enableMessageOrdering')) {
      enableMessageOrdering = _json['enableMessageOrdering'] as core.bool;
    }
    if (_json.containsKey('expirationPolicy')) {
      expirationPolicy = ExpirationPolicy.fromJson(
          _json['expirationPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('messageRetentionDuration')) {
      messageRetentionDuration =
          _json['messageRetentionDuration'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pushConfig')) {
      pushConfig = PushConfig.fromJson(
          _json['pushConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('retainAckedMessages')) {
      retainAckedMessages = _json['retainAckedMessages'] as core.bool;
    }
    if (_json.containsKey('retryPolicy')) {
      retryPolicy = RetryPolicy.fromJson(
          _json['retryPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ackDeadlineSeconds != null)
          'ackDeadlineSeconds': ackDeadlineSeconds!,
        if (deadLetterPolicy != null)
          'deadLetterPolicy': deadLetterPolicy!.toJson(),
        if (detached != null) 'detached': detached!,
        if (enableMessageOrdering != null)
          'enableMessageOrdering': enableMessageOrdering!,
        if (expirationPolicy != null)
          'expirationPolicy': expirationPolicy!.toJson(),
        if (filter != null) 'filter': filter!,
        if (labels != null) 'labels': labels!,
        if (messageRetentionDuration != null)
          'messageRetentionDuration': messageRetentionDuration!,
        if (name != null) 'name': name!,
        if (pushConfig != null) 'pushConfig': pushConfig!.toJson(),
        if (retainAckedMessages != null)
          'retainAckedMessages': retainAckedMessages!,
        if (retryPolicy != null) 'retryPolicy': retryPolicy!.toJson(),
        if (topic != null) 'topic': topic!,
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

/// A topic resource.
class Topic {
  /// The resource name of the Cloud KMS CryptoKey to be used to protect access
  /// to messages published on this topic.
  ///
  /// The expected format is `projects / * /locations / * /keyRings / *
  /// /cryptoKeys / * `.
  core.String? kmsKeyName;

  /// See
  /// [Creating and managing labels](https://cloud.google.com/pubsub/docs/labels).
  core.Map<core.String, core.String>? labels;

  /// Policy constraining the set of Google Cloud Platform regions where
  /// messages published to the topic may be stored.
  ///
  /// If not present, then no constraints are in effect.
  MessageStoragePolicy? messageStoragePolicy;

  /// The name of the topic.
  ///
  /// It must have the format `"projects/{project}/topics/{topic}"`. `{topic}`
  /// must start with a letter, and contain only letters (`[A-Za-z]`), numbers
  /// (`[0-9]`), dashes (`-`), underscores (`_`), periods (`.`), tildes (`~`),
  /// plus (`+`) or percent signs (`%`). It must be between 3 and 255 characters
  /// in length, and it must not start with `"goog"`.
  ///
  /// Required.
  core.String? name;

  /// Reserved for future use.
  ///
  /// This field is set only in responses from the server; it is ignored if it
  /// is set in any requests.
  core.bool? satisfiesPzs;

  /// Settings for validating messages published against a schema.
  SchemaSettings? schemaSettings;

  Topic();

  Topic.fromJson(core.Map _json) {
    if (_json.containsKey('kmsKeyName')) {
      kmsKeyName = _json['kmsKeyName'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('messageStoragePolicy')) {
      messageStoragePolicy = MessageStoragePolicy.fromJson(
          _json['messageStoragePolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('satisfiesPzs')) {
      satisfiesPzs = _json['satisfiesPzs'] as core.bool;
    }
    if (_json.containsKey('schemaSettings')) {
      schemaSettings = SchemaSettings.fromJson(
          _json['schemaSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsKeyName != null) 'kmsKeyName': kmsKeyName!,
        if (labels != null) 'labels': labels!,
        if (messageStoragePolicy != null)
          'messageStoragePolicy': messageStoragePolicy!.toJson(),
        if (name != null) 'name': name!,
        if (satisfiesPzs != null) 'satisfiesPzs': satisfiesPzs!,
        if (schemaSettings != null) 'schemaSettings': schemaSettings!.toJson(),
      };
}

/// Request for the UpdateSnapshot method.
class UpdateSnapshotRequest {
  /// The updated snapshot object.
  ///
  /// Required.
  Snapshot? snapshot;

  /// Indicates which fields in the provided snapshot to update.
  ///
  /// Must be specified and non-empty.
  ///
  /// Required.
  core.String? updateMask;

  UpdateSnapshotRequest();

  UpdateSnapshotRequest.fromJson(core.Map _json) {
    if (_json.containsKey('snapshot')) {
      snapshot = Snapshot.fromJson(
          _json['snapshot'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (snapshot != null) 'snapshot': snapshot!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Request for the UpdateSubscription method.
class UpdateSubscriptionRequest {
  /// The updated subscription object.
  ///
  /// Required.
  Subscription? subscription;

  /// Indicates which fields in the provided subscription to update.
  ///
  /// Must be specified and non-empty.
  ///
  /// Required.
  core.String? updateMask;

  UpdateSubscriptionRequest();

  UpdateSubscriptionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('subscription')) {
      subscription = Subscription.fromJson(
          _json['subscription'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (subscription != null) 'subscription': subscription!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Request for the UpdateTopic method.
class UpdateTopicRequest {
  /// The updated topic object.
  ///
  /// Required.
  Topic? topic;

  /// Indicates which fields in the provided topic to update.
  ///
  /// Must be specified and non-empty. Note that if `update_mask` contains
  /// "message_storage_policy" but the `message_storage_policy` is not set in
  /// the `topic` provided above, then the updated value is determined by the
  /// policy configured at the project or organization level.
  ///
  /// Required.
  core.String? updateMask;

  UpdateTopicRequest();

  UpdateTopicRequest.fromJson(core.Map _json) {
    if (_json.containsKey('topic')) {
      topic =
          Topic.fromJson(_json['topic'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (topic != null) 'topic': topic!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Request for the `ValidateMessage` method.
class ValidateMessageRequest {
  /// The encoding expected for messages
  /// Possible string values are:
  /// - "ENCODING_UNSPECIFIED" : Unspecified
  /// - "JSON" : JSON encoding
  /// - "BINARY" : Binary encoding, as defined by the schema type. For some
  /// schema types, binary encoding may not be available.
  core.String? encoding;

  /// Message to validate against the provided `schema_spec`.
  core.String? message;
  core.List<core.int> get messageAsBytes => convert.base64.decode(message!);

  set messageAsBytes(core.List<core.int> _bytes) {
    message =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Name of the schema against which to validate.
  ///
  /// Format is `projects/{project}/schemas/{schema}`.
  core.String? name;

  /// Ad-hoc schema against which to validate
  Schema? schema;

  ValidateMessageRequest();

  ValidateMessageRequest.fromJson(core.Map _json) {
    if (_json.containsKey('encoding')) {
      encoding = _json['encoding'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('schema')) {
      schema = Schema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (encoding != null) 'encoding': encoding!,
        if (message != null) 'message': message!,
        if (name != null) 'name': name!,
        if (schema != null) 'schema': schema!.toJson(),
      };
}

/// Response for the `ValidateMessage` method.
///
/// Empty for now.
class ValidateMessageResponse {
  ValidateMessageResponse();

  ValidateMessageResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request for the `ValidateSchema` method.
class ValidateSchemaRequest {
  /// The schema object to validate.
  ///
  /// Required.
  Schema? schema;

  ValidateSchemaRequest();

  ValidateSchemaRequest.fromJson(core.Map _json) {
    if (_json.containsKey('schema')) {
      schema = Schema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (schema != null) 'schema': schema!.toJson(),
      };
}

/// Response for the `ValidateSchema` method.
///
/// Empty for now.
class ValidateSchemaResponse {
  ValidateSchemaResponse();

  ValidateSchemaResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

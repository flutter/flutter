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

/// Access Context Manager API - v1
///
/// An API for setting attribute based access control to requests to GCP
/// services.
///
/// For more information, see
/// <https://cloud.google.com/access-context-manager/docs/reference/rest/>
///
/// Create an instance of [AccessContextManagerApi] to access these resources:
///
/// - [AccessPoliciesResource]
///   - [AccessPoliciesAccessLevelsResource]
///   - [AccessPoliciesServicePerimetersResource]
/// - [OperationsResource]
/// - [OrganizationsResource]
///   - [OrganizationsGcpUserAccessBindingsResource]
library accesscontextmanager.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// An API for setting attribute based access control to requests to GCP
/// services.
class AccessContextManagerApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  AccessPoliciesResource get accessPolicies =>
      AccessPoliciesResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);
  OrganizationsResource get organizations => OrganizationsResource(_requester);

  AccessContextManagerApi(http.Client client,
      {core.String rootUrl = 'https://accesscontextmanager.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccessPoliciesResource {
  final commons.ApiRequester _requester;

  AccessPoliciesAccessLevelsResource get accessLevels =>
      AccessPoliciesAccessLevelsResource(_requester);
  AccessPoliciesServicePerimetersResource get servicePerimeters =>
      AccessPoliciesServicePerimetersResource(_requester);

  AccessPoliciesResource(commons.ApiRequester client) : _requester = client;

  /// Create an `AccessPolicy`.
  ///
  /// Fails if this organization already has a `AccessPolicy`. The longrunning
  /// Operation will have a successful status once the `AccessPolicy` has
  /// propagated to long-lasting storage. Syntactic and basic semantic errors
  /// will be returned in `metadata` as a BadRequest proto.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
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
    AccessPolicy request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/accessPolicies';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete an AccessPolicy by resource name.
  ///
  /// The longrunning Operation will have a successful status once the
  /// AccessPolicy has been removed from long-lasting storage.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the access policy to delete. Format
  /// `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
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

  /// Get an AccessPolicy by name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the access policy to get. Format
  /// `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccessPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccessPolicy> get(
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
    return AccessPolicy.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List all AccessPolicies under a container.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Number of AccessPolicy instances to include in the list.
  /// Default 100.
  ///
  /// [pageToken] - Next page token for the next batch of AccessPolicy
  /// instances. Defaults to the first page of results.
  ///
  /// [parent] - Required. Resource name for the container to list AccessPolicy
  /// instances from. Format: `organizations/{org_id}`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAccessPoliciesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAccessPoliciesResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? parent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parent != null) 'parent': [parent],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/accessPolicies';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAccessPoliciesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update an AccessPolicy.
  ///
  /// The longrunning Operation from this RPC will have a successful status once
  /// the changes to the AccessPolicy have propagated to long-lasting storage.
  /// Syntactic and basic semantic errors will be returned in `metadata` as a
  /// BadRequest proto.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. Resource name of the `AccessPolicy`. Format:
  /// `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask to control which fields get updated. Must be
  /// non-empty.
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
    AccessPolicy request,
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
}

class AccessPoliciesAccessLevelsResource {
  final commons.ApiRequester _requester;

  AccessPoliciesAccessLevelsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create an Access Level.
  ///
  /// The longrunning operation from this RPC will have a successful status once
  /// the Access Level has propagated to long-lasting storage. Access Levels
  /// containing errors will result in an error response for the first error
  /// encountered.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name for the access policy which owns this
  /// Access Level. Format: `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
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
    AccessLevel request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/accessLevels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete an Access Level by resource name.
  ///
  /// The longrunning operation from this RPC will have a successful status once
  /// the Access Level has been removed from long-lasting storage.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the Access Level. Format:
  /// `accessPolicies/{policy_id}/accessLevels/{access_level_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+/accessLevels/\[^/\]+$`.
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

  /// Get an Access Level by resource name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the Access Level. Format:
  /// `accessPolicies/{policy_id}/accessLevels/{access_level_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+/accessLevels/\[^/\]+$`.
  ///
  /// [accessLevelFormat] - Whether to return `BasicLevels` in the Cloud Common
  /// Expression Language rather than as `BasicLevels`. Defaults to AS_DEFINED,
  /// where Access Levels are returned as `BasicLevels` or `CustomLevels` based
  /// on how they were created. If set to CEL, all Access Levels are returned as
  /// `CustomLevels`. In the CEL case, `BasicLevels` are translated to
  /// equivalent `CustomLevels`.
  /// Possible string values are:
  /// - "LEVEL_FORMAT_UNSPECIFIED" : The format was not specified.
  /// - "AS_DEFINED" : Uses the format the resource was defined in. BasicLevels
  /// are returned as BasicLevels, CustomLevels are returned as CustomLevels.
  /// - "CEL" : Use Cloud Common Expression Language when returning the
  /// resource. Both BasicLevels and CustomLevels are returned as CustomLevels.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccessLevel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccessLevel> get(
    core.String name, {
    core.String? accessLevelFormat,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (accessLevelFormat != null) 'accessLevelFormat': [accessLevelFormat],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccessLevel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List all Access Levels for an access policy.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name for the access policy to list Access
  /// Levels from. Format: `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
  ///
  /// [accessLevelFormat] - Whether to return `BasicLevels` in the Cloud Common
  /// Expression language, as `CustomLevels`, rather than as `BasicLevels`.
  /// Defaults to returning `AccessLevels` in the format they were defined.
  /// Possible string values are:
  /// - "LEVEL_FORMAT_UNSPECIFIED" : The format was not specified.
  /// - "AS_DEFINED" : Uses the format the resource was defined in. BasicLevels
  /// are returned as BasicLevels, CustomLevels are returned as CustomLevels.
  /// - "CEL" : Use Cloud Common Expression Language when returning the
  /// resource. Both BasicLevels and CustomLevels are returned as CustomLevels.
  ///
  /// [pageSize] - Number of Access Levels to include in the list. Default 100.
  ///
  /// [pageToken] - Next page token for the next batch of Access Level
  /// instances. Defaults to the first page of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAccessLevelsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAccessLevelsResponse> list(
    core.String parent, {
    core.String? accessLevelFormat,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (accessLevelFormat != null) 'accessLevelFormat': [accessLevelFormat],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/accessLevels';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAccessLevelsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update an Access Level.
  ///
  /// The longrunning operation from this RPC will have a successful status once
  /// the changes to the Access Level have propagated to long-lasting storage.
  /// Access Levels containing errors will result in an error response for the
  /// first error encountered.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the Access Level. The `short_name`
  /// component must begin with a letter and only include alphanumeric and '_'.
  /// Format: `accessPolicies/{policy_id}/accessLevels/{short_name}`. The
  /// maximum length of the `short_name` component is 50 characters.
  /// Value must have pattern `^accessPolicies/\[^/\]+/accessLevels/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask to control which fields get updated. Must be
  /// non-empty.
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
    AccessLevel request,
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

  /// Replace all existing Access Levels in an Access Policy with the Access
  /// Levels provided.
  ///
  /// This is done atomically. The longrunning operation from this RPC will have
  /// a successful status once all replacements have propagated to long-lasting
  /// storage. Replacements containing errors will result in an error response
  /// for the first error encountered. Replacement will be cancelled on error,
  /// existing Access Levels will not be affected. Operation.response field will
  /// contain ReplaceAccessLevelsResponse. Removing Access Levels contained in
  /// existing Service Perimeters will result in error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name for the access policy which owns these
  /// Access Levels. Format: `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
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
  async.Future<Operation> replaceAll(
    ReplaceAccessLevelsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/accessLevels:replaceAll';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AccessPoliciesServicePerimetersResource {
  final commons.ApiRequester _requester;

  AccessPoliciesServicePerimetersResource(commons.ApiRequester client)
      : _requester = client;

  /// Commit the dry-run spec for all the Service Perimeters in an Access
  /// Policy.
  ///
  /// A commit operation on a Service Perimeter involves copying its `spec`
  /// field to that Service Perimeter's `status` field. Only Service Perimeters
  /// with `use_explicit_dry_run_spec` field set to true are affected by a
  /// commit operation. The longrunning operation from this RPC will have a
  /// successful status once the dry-run specs for all the Service Perimeters
  /// have been committed. If a commit fails, it will cause the longrunning
  /// operation to return an error response and the entire commit operation will
  /// be cancelled. When successful, Operation.response field will contain
  /// CommitServicePerimetersResponse. The `dry_run` and the `spec` fields will
  /// be cleared after a successful commit operation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name for the parent Access Policy which owns
  /// all Service Perimeters in scope for the commit operation. Format:
  /// `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
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
  async.Future<Operation> commit(
    CommitServicePerimetersRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/servicePerimeters:commit';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Create a Service Perimeter.
  ///
  /// The longrunning operation from this RPC will have a successful status once
  /// the Service Perimeter has propagated to long-lasting storage. Service
  /// Perimeters containing errors will result in an error response for the
  /// first error encountered.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name for the access policy which owns this
  /// Service Perimeter. Format: `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
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
    ServicePerimeter request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/servicePerimeters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a Service Perimeter by resource name.
  ///
  /// The longrunning operation from this RPC will have a successful status once
  /// the Service Perimeter has been removed from long-lasting storage.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the Service Perimeter. Format:
  /// `accessPolicies/{policy_id}/servicePerimeters/{service_perimeter_id}`
  /// Value must have pattern
  /// `^accessPolicies/\[^/\]+/servicePerimeters/\[^/\]+$`.
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

  /// Get a Service Perimeter by resource name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the Service Perimeter. Format:
  /// `accessPolicies/{policy_id}/servicePerimeters/{service_perimeters_id}`
  /// Value must have pattern
  /// `^accessPolicies/\[^/\]+/servicePerimeters/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ServicePerimeter].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ServicePerimeter> get(
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
    return ServicePerimeter.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List all Service Perimeters for an access policy.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name for the access policy to list Service
  /// Perimeters from. Format: `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
  ///
  /// [pageSize] - Number of Service Perimeters to include in the list. Default
  /// 100.
  ///
  /// [pageToken] - Next page token for the next batch of Service Perimeter
  /// instances. Defaults to the first page of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListServicePerimetersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListServicePerimetersResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/servicePerimeters';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListServicePerimetersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a Service Perimeter.
  ///
  /// The longrunning operation from this RPC will have a successful status once
  /// the changes to the Service Perimeter have propagated to long-lasting
  /// storage. Service Perimeter containing errors will result in an error
  /// response for the first error encountered.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for the ServicePerimeter. The
  /// `short_name` component must begin with a letter and only include
  /// alphanumeric and '_'. Format:
  /// `accessPolicies/{policy_id}/servicePerimeters/{short_name}`
  /// Value must have pattern
  /// `^accessPolicies/\[^/\]+/servicePerimeters/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Mask to control which fields get updated. Must be
  /// non-empty.
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
    ServicePerimeter request,
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

  /// Replace all existing Service Perimeters in an Access Policy with the
  /// Service Perimeters provided.
  ///
  /// This is done atomically. The longrunning operation from this RPC will have
  /// a successful status once all replacements have propagated to long-lasting
  /// storage. Replacements containing errors will result in an error response
  /// for the first error encountered. Replacement will be cancelled on error,
  /// existing Service Perimeters will not be affected. Operation.response field
  /// will contain ReplaceServicePerimetersResponse.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name for the access policy which owns these
  /// Service Perimeters. Format: `accessPolicies/{policy_id}`
  /// Value must have pattern `^accessPolicies/\[^/\]+$`.
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
  async.Future<Operation> replaceAll(
    ReplaceServicePerimetersRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/servicePerimeters:replaceAll';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsResource(commons.ApiRequester client) : _requester = client;

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
  /// Value must have pattern `^operations/.*$`.
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
  /// Value must have pattern `^operations/.*$`.
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
  /// Value must have pattern `^operations/.*$`.
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
  /// Value must have pattern `^operations$`.
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

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsResource {
  final commons.ApiRequester _requester;

  OrganizationsGcpUserAccessBindingsResource get gcpUserAccessBindings =>
      OrganizationsGcpUserAccessBindingsResource(_requester);

  OrganizationsResource(commons.ApiRequester client) : _requester = client;
}

class OrganizationsGcpUserAccessBindingsResource {
  final commons.ApiRequester _requester;

  OrganizationsGcpUserAccessBindingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a GcpUserAccessBinding.
  ///
  /// If the client specifies a name, the server will ignore it. Fails if a
  /// resource already exists with the same group_key. Completion of this
  /// long-running operation does not necessarily signify that the new binding
  /// is deployed onto all affected users, which may take more time.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Example: "organizations/256"
  /// Value must have pattern `^organizations/\[^/\]+$`.
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
    GcpUserAccessBinding request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/gcpUserAccessBindings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a GcpUserAccessBinding.
  ///
  /// Completion of this long-running operation does not necessarily signify
  /// that the binding deletion is deployed onto all affected users, which may
  /// take more time.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Example:
  /// "organizations/256/gcpUserAccessBindings/b3-BhcX_Ud5N"
  /// Value must have pattern
  /// `^organizations/\[^/\]+/gcpUserAccessBindings/\[^/\]+$`.
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

  /// Gets the GcpUserAccessBinding with the given name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Example:
  /// "organizations/256/gcpUserAccessBindings/b3-BhcX_Ud5N"
  /// Value must have pattern
  /// `^organizations/\[^/\]+/gcpUserAccessBindings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GcpUserAccessBinding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GcpUserAccessBinding> get(
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
    return GcpUserAccessBinding.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all GcpUserAccessBindings for a Google Cloud organization.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Example: "organizations/256"
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. Maximum number of items to return. The server may
  /// return fewer items. If left blank, the server may return any number of
  /// items.
  ///
  /// [pageToken] - Optional. If left blank, returns the first page. To
  /// enumerate all items, use the next_page_token from your previous list
  /// operation.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListGcpUserAccessBindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListGcpUserAccessBindingsResponse> list(
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
        'v1/' + core.Uri.encodeFull('$parent') + '/gcpUserAccessBindings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListGcpUserAccessBindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a GcpUserAccessBinding.
  ///
  /// Completion of this long-running operation does not necessarily signify
  /// that the changed binding is deployed onto all affected users, which may
  /// take more time.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. Assigned by the server during creation. The last
  /// segment has an arbitrary length and has only URI unreserved characters (as
  /// defined by
  /// [RFC 3986 Section 2.3](https://tools.ietf.org/html/rfc3986#section-2.3)).
  /// Should not be specified by the client during creation. Example:
  /// "organizations/256/gcpUserAccessBindings/b3-BhcX_Ud5N"
  /// Value must have pattern
  /// `^organizations/\[^/\]+/gcpUserAccessBindings/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Only the fields specified in this mask are
  /// updated. Because name and group_key cannot be changed, update_mask is
  /// required and must always be: update_mask { paths: "access_levels" }
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
    GcpUserAccessBinding request,
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
}

/// An `AccessLevel` is a label that can be applied to requests to Google Cloud
/// services, along with a list of requirements necessary for the label to be
/// applied.
class AccessLevel {
  /// A `BasicLevel` composed of `Conditions`.
  BasicLevel? basic;

  /// A `CustomLevel` written in the Common Expression Language.
  CustomLevel? custom;

  /// Description of the `AccessLevel` and its use.
  ///
  /// Does not affect behavior.
  core.String? description;

  /// Resource name for the Access Level.
  ///
  /// The `short_name` component must begin with a letter and only include
  /// alphanumeric and '_'. Format:
  /// `accessPolicies/{policy_id}/accessLevels/{short_name}`. The maximum length
  /// of the `short_name` component is 50 characters.
  ///
  /// Required.
  core.String? name;

  /// Human readable title.
  ///
  /// Must be unique within the Policy.
  core.String? title;

  AccessLevel();

  AccessLevel.fromJson(core.Map _json) {
    if (_json.containsKey('basic')) {
      basic = BasicLevel.fromJson(
          _json['basic'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('custom')) {
      custom = CustomLevel.fromJson(
          _json['custom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (basic != null) 'basic': basic!.toJson(),
        if (custom != null) 'custom': custom!.toJson(),
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (title != null) 'title': title!,
      };
}

/// `AccessPolicy` is a container for `AccessLevels` (which define the necessary
/// attributes to use Google Cloud services) and `ServicePerimeters` (which
/// define regions of services able to freely pass data within a perimeter).
///
/// An access policy is globally visible within an organization, and the
/// restrictions it specifies apply to all projects within an organization.
class AccessPolicy {
  /// An opaque identifier for the current version of the `AccessPolicy`.
  ///
  /// This will always be a strongly validated etag, meaning that two Access
  /// Polices will be identical if and only if their etags are identical.
  /// Clients should not expect this to be in any specific format.
  ///
  /// Output only.
  core.String? etag;

  /// Resource name of the `AccessPolicy`.
  ///
  /// Format: `accessPolicies/{policy_id}`
  ///
  /// Output only.
  core.String? name;

  /// The parent of this `AccessPolicy` in the Cloud Resource Hierarchy.
  ///
  /// Currently immutable once created. Format:
  /// `organizations/{organization_id}`
  ///
  /// Required.
  core.String? parent;

  /// Human readable title.
  ///
  /// Does not affect behavior.
  ///
  /// Required.
  core.String? title;

  AccessPolicy();

  AccessPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (title != null) 'title': title!,
      };
}

/// Identification for an API Operation.
class ApiOperation {
  /// API methods or permissions to allow.
  ///
  /// Method or permission must belong to the service specified by
  /// `service_name` field. A single MethodSelector entry with `*` specified for
  /// the `method` field will allow all methods AND permissions for the service
  /// specified in `service_name`.
  core.List<MethodSelector>? methodSelectors;

  /// The name of the API whose methods or permissions the IngressPolicy or
  /// EgressPolicy want to allow.
  ///
  /// A single ApiOperation with `service_name` field set to `*` will allow all
  /// methods AND permissions for all services.
  core.String? serviceName;

  ApiOperation();

  ApiOperation.fromJson(core.Map _json) {
    if (_json.containsKey('methodSelectors')) {
      methodSelectors = (_json['methodSelectors'] as core.List)
          .map<MethodSelector>((value) => MethodSelector.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (methodSelectors != null)
          'methodSelectors':
              methodSelectors!.map((value) => value.toJson()).toList(),
        if (serviceName != null) 'serviceName': serviceName!,
      };
}

/// `BasicLevel` is an `AccessLevel` using a set of recommended features.
class BasicLevel {
  /// How the `conditions` list should be combined to determine if a request is
  /// granted this `AccessLevel`.
  ///
  /// If AND is used, each `Condition` in `conditions` must be satisfied for the
  /// `AccessLevel` to be applied. If OR is used, at least one `Condition` in
  /// `conditions` must be satisfied for the `AccessLevel` to be applied.
  /// Default behavior is AND.
  /// Possible string values are:
  /// - "AND" : All `Conditions` must be true for the `BasicLevel` to be true.
  /// - "OR" : If at least one `Condition` is true, then the `BasicLevel` is
  /// true.
  core.String? combiningFunction;

  /// A list of requirements for the `AccessLevel` to be granted.
  ///
  /// Required.
  core.List<Condition>? conditions;

  BasicLevel();

  BasicLevel.fromJson(core.Map _json) {
    if (_json.containsKey('combiningFunction')) {
      combiningFunction = _json['combiningFunction'] as core.String;
    }
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<Condition>((value) =>
              Condition.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (combiningFunction != null) 'combiningFunction': combiningFunction!,
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
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

/// A request to commit dry-run specs in all Service Perimeters belonging to an
/// Access Policy.
class CommitServicePerimetersRequest {
  /// The etag for the version of the Access Policy that this commit operation
  /// is to be performed on.
  ///
  /// If, at the time of commit, the etag for the Access Policy stored in Access
  /// Context Manager is different from the specified etag, then the commit
  /// operation will not be performed and the call will fail. This field is not
  /// required. If etag is not provided, the operation will be performed as if a
  /// valid etag is provided.
  ///
  /// Optional.
  core.String? etag;

  CommitServicePerimetersRequest();

  CommitServicePerimetersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
      };
}

/// A response to CommitServicePerimetersRequest.
///
/// This will be put inside of Operation.response field.
class CommitServicePerimetersResponse {
  /// List of all the Service Perimeter instances in the Access Policy.
  core.List<ServicePerimeter>? servicePerimeters;

  CommitServicePerimetersResponse();

  CommitServicePerimetersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('servicePerimeters')) {
      servicePerimeters = (_json['servicePerimeters'] as core.List)
          .map<ServicePerimeter>((value) => ServicePerimeter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (servicePerimeters != null)
          'servicePerimeters':
              servicePerimeters!.map((value) => value.toJson()).toList(),
      };
}

/// A condition necessary for an `AccessLevel` to be granted.
///
/// The Condition is an AND over its fields. So a Condition is true if: 1) the
/// request IP is from one of the listed subnetworks AND 2) the originating
/// device complies with the listed device policy AND 3) all listed access
/// levels are granted AND 4) the request was sent at a time allowed by the
/// DateTimeRestriction.
class Condition {
  /// Device specific restrictions, all restrictions must hold for the Condition
  /// to be true.
  ///
  /// If not specified, all devices are allowed.
  DevicePolicy? devicePolicy;

  /// CIDR block IP subnetwork specification.
  ///
  /// May be IPv4 or IPv6. Note that for a CIDR IP address block, the specified
  /// IP address portion must be properly truncated (i.e. all the host bits must
  /// be zero) or the input is considered malformed. For example, "192.0.2.0/24"
  /// is accepted but "192.0.2.1/24" is not. Similarly, for IPv6,
  /// "2001:db8::/32" is accepted whereas "2001:db8::1/32" is not. The
  /// originating IP of a request must be in one of the listed subnets in order
  /// for this Condition to be true. If empty, all IP addresses are allowed.
  core.List<core.String>? ipSubnetworks;

  /// The request must be made by one of the provided user or service accounts.
  ///
  /// Groups are not supported. Syntax: `user:{emailid}`
  /// `serviceAccount:{emailid}` If not specified, a request may come from any
  /// user.
  core.List<core.String>? members;

  /// Whether to negate the Condition.
  ///
  /// If true, the Condition becomes a NAND over its non-empty fields, each
  /// field must be false for the Condition overall to be satisfied. Defaults to
  /// false.
  core.bool? negate;

  /// The request must originate from one of the provided countries/regions.
  ///
  /// Must be valid ISO 3166-1 alpha-2 codes.
  core.List<core.String>? regions;

  /// A list of other access levels defined in the same `Policy`, referenced by
  /// resource name.
  ///
  /// Referencing an `AccessLevel` which does not exist is an error. All access
  /// levels listed must be granted for the Condition to be true. Example:
  /// "`accessPolicies/MY_POLICY/accessLevels/LEVEL_NAME"`
  core.List<core.String>? requiredAccessLevels;

  Condition();

  Condition.fromJson(core.Map _json) {
    if (_json.containsKey('devicePolicy')) {
      devicePolicy = DevicePolicy.fromJson(
          _json['devicePolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ipSubnetworks')) {
      ipSubnetworks = (_json['ipSubnetworks'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('negate')) {
      negate = _json['negate'] as core.bool;
    }
    if (_json.containsKey('regions')) {
      regions = (_json['regions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('requiredAccessLevels')) {
      requiredAccessLevels = (_json['requiredAccessLevels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (devicePolicy != null) 'devicePolicy': devicePolicy!.toJson(),
        if (ipSubnetworks != null) 'ipSubnetworks': ipSubnetworks!,
        if (members != null) 'members': members!,
        if (negate != null) 'negate': negate!,
        if (regions != null) 'regions': regions!,
        if (requiredAccessLevels != null)
          'requiredAccessLevels': requiredAccessLevels!,
      };
}

/// `CustomLevel` is an `AccessLevel` using the Cloud Common Expression Language
/// to represent the necessary conditions for the level to apply to a request.
///
/// See CEL spec at: https://github.com/google/cel-spec
class CustomLevel {
  /// A Cloud CEL expression evaluating to a boolean.
  ///
  /// Required.
  Expr? expr;

  CustomLevel();

  CustomLevel.fromJson(core.Map _json) {
    if (_json.containsKey('expr')) {
      expr =
          Expr.fromJson(_json['expr'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expr != null) 'expr': expr!.toJson(),
      };
}

/// `DevicePolicy` specifies device specific restrictions necessary to acquire a
/// given access level.
///
/// A `DevicePolicy` specifies requirements for requests from devices to be
/// granted access levels, it does not do any enforcement on the device.
/// `DevicePolicy` acts as an AND over all specified fields, and each repeated
/// field is an OR over its elements. Any unset fields are ignored. For example,
/// if the proto is { os_type : DESKTOP_WINDOWS, os_type : DESKTOP_LINUX,
/// encryption_status: ENCRYPTED}, then the DevicePolicy will be true for
/// requests originating from encrypted Linux desktops and encrypted Windows
/// desktops.
class DevicePolicy {
  /// Allowed device management levels, an empty list allows all management
  /// levels.
  core.List<core.String>? allowedDeviceManagementLevels;

  /// Allowed encryptions statuses, an empty list allows all statuses.
  core.List<core.String>? allowedEncryptionStatuses;

  /// Allowed OS versions, an empty list allows all types and all versions.
  core.List<OsConstraint>? osConstraints;

  /// Whether the device needs to be approved by the customer admin.
  core.bool? requireAdminApproval;

  /// Whether the device needs to be corp owned.
  core.bool? requireCorpOwned;

  /// Whether or not screenlock is required for the DevicePolicy to be true.
  ///
  /// Defaults to `false`.
  core.bool? requireScreenlock;

  DevicePolicy();

  DevicePolicy.fromJson(core.Map _json) {
    if (_json.containsKey('allowedDeviceManagementLevels')) {
      allowedDeviceManagementLevels =
          (_json['allowedDeviceManagementLevels'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('allowedEncryptionStatuses')) {
      allowedEncryptionStatuses =
          (_json['allowedEncryptionStatuses'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('osConstraints')) {
      osConstraints = (_json['osConstraints'] as core.List)
          .map<OsConstraint>((value) => OsConstraint.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('requireAdminApproval')) {
      requireAdminApproval = _json['requireAdminApproval'] as core.bool;
    }
    if (_json.containsKey('requireCorpOwned')) {
      requireCorpOwned = _json['requireCorpOwned'] as core.bool;
    }
    if (_json.containsKey('requireScreenlock')) {
      requireScreenlock = _json['requireScreenlock'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedDeviceManagementLevels != null)
          'allowedDeviceManagementLevels': allowedDeviceManagementLevels!,
        if (allowedEncryptionStatuses != null)
          'allowedEncryptionStatuses': allowedEncryptionStatuses!,
        if (osConstraints != null)
          'osConstraints':
              osConstraints!.map((value) => value.toJson()).toList(),
        if (requireAdminApproval != null)
          'requireAdminApproval': requireAdminApproval!,
        if (requireCorpOwned != null) 'requireCorpOwned': requireCorpOwned!,
        if (requireScreenlock != null) 'requireScreenlock': requireScreenlock!,
      };
}

/// Defines the conditions under which an EgressPolicy matches a request.
///
/// Conditions based on information about the source of the request. Note that
/// if the destination of the request is also protected by a ServicePerimeter,
/// then that ServicePerimeter must have an IngressPolicy which allows access in
/// order for this request to succeed.
class EgressFrom {
  /// A list of identities that are allowed access through this
  /// \[EgressPolicy\].
  ///
  /// Should be in the format of email address. The email address should
  /// represent individual user or service account only.
  core.List<core.String>? identities;

  /// Specifies the type of identities that are allowed access to outside the
  /// perimeter.
  ///
  /// If left unspecified, then members of `identities` field will be allowed
  /// access.
  /// Possible string values are:
  /// - "IDENTITY_TYPE_UNSPECIFIED" : No blanket identity group specified.
  /// - "ANY_IDENTITY" : Authorize access from all identities outside the
  /// perimeter.
  /// - "ANY_USER_ACCOUNT" : Authorize access from all human users outside the
  /// perimeter.
  /// - "ANY_SERVICE_ACCOUNT" : Authorize access from all service accounts
  /// outside the perimeter.
  core.String? identityType;

  EgressFrom();

  EgressFrom.fromJson(core.Map _json) {
    if (_json.containsKey('identities')) {
      identities = (_json['identities'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('identityType')) {
      identityType = _json['identityType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (identities != null) 'identities': identities!,
        if (identityType != null) 'identityType': identityType!,
      };
}

/// Policy for egress from perimeter.
///
/// EgressPolicies match requests based on `egress_from` and `egress_to`
/// stanzas. For an EgressPolicy to match, both `egress_from` and `egress_to`
/// stanzas must be matched. If an EgressPolicy matches a request, the request
/// is allowed to span the ServicePerimeter boundary. For example, an
/// EgressPolicy can be used to allow VMs on networks within the
/// ServicePerimeter to access a defined set of projects outside the perimeter
/// in certain contexts (e.g. to read data from a Cloud Storage bucket or query
/// against a BigQuery dataset). EgressPolicies are concerned with the
/// *resources* that a request relates as well as the API services and API
/// actions being used. They do not related to the direction of data movement.
/// More detailed documentation for this concept can be found in the
/// descriptions of EgressFrom and EgressTo.
class EgressPolicy {
  /// Defines conditions on the source of a request causing this EgressPolicy to
  /// apply.
  EgressFrom? egressFrom;

  /// Defines the conditions on the ApiOperation and destination resources that
  /// cause this EgressPolicy to apply.
  EgressTo? egressTo;

  EgressPolicy();

  EgressPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('egressFrom')) {
      egressFrom = EgressFrom.fromJson(
          _json['egressFrom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('egressTo')) {
      egressTo = EgressTo.fromJson(
          _json['egressTo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (egressFrom != null) 'egressFrom': egressFrom!.toJson(),
        if (egressTo != null) 'egressTo': egressTo!.toJson(),
      };
}

/// Defines the conditions under which an EgressPolicy matches a request.
///
/// Conditions are based on information about the ApiOperation intended to be
/// performed on the `resources` specified. Note that if the destination of the
/// request is also protected by a ServicePerimeter, then that ServicePerimeter
/// must have an IngressPolicy which allows access in order for this request to
/// succeed. The request must match `operations` AND `resources` fields in order
/// to be allowed egress out of the perimeter.
class EgressTo {
  /// A list of ApiOperations allowed to be performed by the sources specified
  /// in the corresponding EgressFrom.
  ///
  /// A request matches if it uses an operation/service in this list.
  core.List<ApiOperation>? operations;

  /// A list of resources, currently only projects in the form `projects/`, that
  /// are allowed to be accessed by sources defined in the corresponding
  /// EgressFrom.
  ///
  /// A request matches if it contains a resource in this list. If `*` is
  /// specified for `resources`, then this EgressTo rule will authorize access
  /// to all resources outside the perimeter.
  core.List<core.String>? resources;

  EgressTo();

  EgressTo.fromJson(core.Map _json) {
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<ApiOperation>((value) => ApiOperation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
        if (resources != null) 'resources': resources!,
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

/// Restricts access to Cloud Console and Google Cloud APIs for a set of users
/// using Context-Aware Access.
class GcpUserAccessBinding {
  /// Access level that a user must have to be granted access.
  ///
  /// Only one access level is supported, not multiple. This repeated field must
  /// have exactly one element. Example:
  /// "accessPolicies/9522/accessLevels/device_trusted"
  ///
  /// Required.
  core.List<core.String>? accessLevels;

  /// Google Group id whose members are subject to this binding's restrictions.
  ///
  /// See "id" in the
  /// [G Suite Directory API's Groups resource](https://developers.google.com/admin-sdk/directory/v1/reference/groups#resource).
  /// If a group's email address/alias is changed, this resource will continue
  /// to point at the changed group. This field does not accept group email
  /// addresses or aliases. Example: "01d520gv4vjcrht"
  ///
  /// Required. Immutable.
  core.String? groupKey;

  /// Assigned by the server during creation.
  ///
  /// The last segment has an arbitrary length and has only URI unreserved
  /// characters (as defined by
  /// [RFC 3986 Section 2.3](https://tools.ietf.org/html/rfc3986#section-2.3)).
  /// Should not be specified by the client during creation. Example:
  /// "organizations/256/gcpUserAccessBindings/b3-BhcX_Ud5N"
  ///
  /// Immutable.
  core.String? name;

  GcpUserAccessBinding();

  GcpUserAccessBinding.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevels')) {
      accessLevels = (_json['accessLevels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('groupKey')) {
      groupKey = _json['groupKey'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevels != null) 'accessLevels': accessLevels!,
        if (groupKey != null) 'groupKey': groupKey!,
        if (name != null) 'name': name!,
      };
}

/// Defines the conditions under which an IngressPolicy matches a request.
///
/// Conditions are based on information about the source of the request. The
/// request must satisfy what is defined in `sources` AND identity related
/// fields in order to match.
class IngressFrom {
  /// A list of identities that are allowed access through this ingress policy.
  ///
  /// Should be in the format of email address. The email address should
  /// represent individual user or service account only.
  core.List<core.String>? identities;

  /// Specifies the type of identities that are allowed access from outside the
  /// perimeter.
  ///
  /// If left unspecified, then members of `identities` field will be allowed
  /// access.
  /// Possible string values are:
  /// - "IDENTITY_TYPE_UNSPECIFIED" : No blanket identity group specified.
  /// - "ANY_IDENTITY" : Authorize access from all identities outside the
  /// perimeter.
  /// - "ANY_USER_ACCOUNT" : Authorize access from all human users outside the
  /// perimeter.
  /// - "ANY_SERVICE_ACCOUNT" : Authorize access from all service accounts
  /// outside the perimeter.
  core.String? identityType;

  /// Sources that this IngressPolicy authorizes access from.
  core.List<IngressSource>? sources;

  IngressFrom();

  IngressFrom.fromJson(core.Map _json) {
    if (_json.containsKey('identities')) {
      identities = (_json['identities'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('identityType')) {
      identityType = _json['identityType'] as core.String;
    }
    if (_json.containsKey('sources')) {
      sources = (_json['sources'] as core.List)
          .map<IngressSource>((value) => IngressSource.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (identities != null) 'identities': identities!,
        if (identityType != null) 'identityType': identityType!,
        if (sources != null)
          'sources': sources!.map((value) => value.toJson()).toList(),
      };
}

/// Policy for ingress into ServicePerimeter.
///
/// IngressPolicies match requests based on `ingress_from` and `ingress_to`
/// stanzas. For an ingress policy to match, both the `ingress_from` and
/// `ingress_to` stanzas must be matched. If an IngressPolicy matches a request,
/// the request is allowed through the perimeter boundary from outside the
/// perimeter. For example, access from the internet can be allowed either based
/// on an AccessLevel or, for traffic hosted on Google Cloud, the project of the
/// source network. For access from private networks, using the project of the
/// hosting network is required. Individual ingress policies can be limited by
/// restricting which services and/or actions they match using the `ingress_to`
/// field.
class IngressPolicy {
  /// Defines the conditions on the source of a request causing this
  /// IngressPolicy to apply.
  IngressFrom? ingressFrom;

  /// Defines the conditions on the ApiOperation and request destination that
  /// cause this IngressPolicy to apply.
  IngressTo? ingressTo;

  IngressPolicy();

  IngressPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('ingressFrom')) {
      ingressFrom = IngressFrom.fromJson(
          _json['ingressFrom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ingressTo')) {
      ingressTo = IngressTo.fromJson(
          _json['ingressTo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ingressFrom != null) 'ingressFrom': ingressFrom!.toJson(),
        if (ingressTo != null) 'ingressTo': ingressTo!.toJson(),
      };
}

/// The source that IngressPolicy authorizes access from.
class IngressSource {
  /// An AccessLevel resource name that allow resources within the
  /// ServicePerimeters to be accessed from the internet.
  ///
  /// AccessLevels listed must be in the same policy as this ServicePerimeter.
  /// Referencing a nonexistent AccessLevel will cause an error. If no
  /// AccessLevel names are listed, resources within the perimeter can only be
  /// accessed via Google Cloud calls with request origins within the perimeter.
  /// Example: `accessPolicies/MY_POLICY/accessLevels/MY_LEVEL`. If a single `*`
  /// is specified for `access_level`, then all IngressSources will be allowed.
  core.String? accessLevel;

  /// A Google Cloud resource that is allowed to ingress the perimeter.
  ///
  /// Requests from these resources will be allowed to access perimeter data.
  /// Currently only projects are allowed. Format: `projects/{project_number}`
  /// The project may be in any Google Cloud organization, not just the
  /// organization that the perimeter is defined in. `*` is not allowed, the
  /// case of allowing all Google Cloud resources only is not supported.
  core.String? resource;

  IngressSource();

  IngressSource.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevel')) {
      accessLevel = _json['accessLevel'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevel != null) 'accessLevel': accessLevel!,
        if (resource != null) 'resource': resource!,
      };
}

/// Defines the conditions under which an IngressPolicy matches a request.
///
/// Conditions are based on information about the ApiOperation intended to be
/// performed on the target resource of the request. The request must satisfy
/// what is defined in `operations` AND `resources` in order to match.
class IngressTo {
  /// A list of ApiOperations allowed to be performed by the sources specified
  /// in corresponding IngressFrom in this ServicePerimeter.
  core.List<ApiOperation>? operations;

  /// A list of resources, currently only projects in the form `projects/`,
  /// protected by this ServicePerimeter that are allowed to be accessed by
  /// sources defined in the corresponding IngressFrom.
  ///
  /// If a single `*` is specified, then access to all resources inside the
  /// perimeter are allowed.
  core.List<core.String>? resources;

  IngressTo();

  IngressTo.fromJson(core.Map _json) {
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<ApiOperation>((value) => ApiOperation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
        if (resources != null) 'resources': resources!,
      };
}

/// A response to `ListAccessLevelsRequest`.
class ListAccessLevelsResponse {
  /// List of the Access Level instances.
  core.List<AccessLevel>? accessLevels;

  /// The pagination token to retrieve the next page of results.
  ///
  /// If the value is empty, no further results remain.
  core.String? nextPageToken;

  ListAccessLevelsResponse();

  ListAccessLevelsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevels')) {
      accessLevels = (_json['accessLevels'] as core.List)
          .map<AccessLevel>((value) => AccessLevel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevels != null)
          'accessLevels': accessLevels!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A response to `ListAccessPoliciesRequest`.
class ListAccessPoliciesResponse {
  /// List of the AccessPolicy instances.
  core.List<AccessPolicy>? accessPolicies;

  /// The pagination token to retrieve the next page of results.
  ///
  /// If the value is empty, no further results remain.
  core.String? nextPageToken;

  ListAccessPoliciesResponse();

  ListAccessPoliciesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accessPolicies')) {
      accessPolicies = (_json['accessPolicies'] as core.List)
          .map<AccessPolicy>((value) => AccessPolicy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessPolicies != null)
          'accessPolicies':
              accessPolicies!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response of ListGcpUserAccessBindings.
class ListGcpUserAccessBindingsResponse {
  /// GcpUserAccessBinding
  core.List<GcpUserAccessBinding>? gcpUserAccessBindings;

  /// Token to get the next page of items.
  ///
  /// If blank, there are no more items.
  core.String? nextPageToken;

  ListGcpUserAccessBindingsResponse();

  ListGcpUserAccessBindingsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('gcpUserAccessBindings')) {
      gcpUserAccessBindings = (_json['gcpUserAccessBindings'] as core.List)
          .map<GcpUserAccessBinding>((value) => GcpUserAccessBinding.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcpUserAccessBindings != null)
          'gcpUserAccessBindings':
              gcpUserAccessBindings!.map((value) => value.toJson()).toList(),
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

/// A response to `ListServicePerimetersRequest`.
class ListServicePerimetersResponse {
  /// The pagination token to retrieve the next page of results.
  ///
  /// If the value is empty, no further results remain.
  core.String? nextPageToken;

  /// List of the Service Perimeter instances.
  core.List<ServicePerimeter>? servicePerimeters;

  ListServicePerimetersResponse();

  ListServicePerimetersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('servicePerimeters')) {
      servicePerimeters = (_json['servicePerimeters'] as core.List)
          .map<ServicePerimeter>((value) => ServicePerimeter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (servicePerimeters != null)
          'servicePerimeters':
              servicePerimeters!.map((value) => value.toJson()).toList(),
      };
}

/// An allowed method or permission of a service specified in ApiOperation.
class MethodSelector {
  /// Value for `method` should be a valid method name for the corresponding
  /// `service_name` in ApiOperation.
  ///
  /// If `*` used as value for `method`, then ALL methods and permissions are
  /// allowed.
  core.String? method;

  /// Value for `permission` should be a valid Cloud IAM permission for the
  /// corresponding `service_name` in ApiOperation.
  core.String? permission;

  MethodSelector();

  MethodSelector.fromJson(core.Map _json) {
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (method != null) 'method': method!,
        if (permission != null) 'permission': permission!,
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

/// A restriction on the OS type and version of devices making requests.
class OsConstraint {
  /// The minimum allowed OS version.
  ///
  /// If not set, any version of this OS satisfies the constraint. Format:
  /// `"major.minor.patch"`. Examples: `"10.5.301"`, `"9.2.1"`.
  core.String? minimumVersion;

  /// The allowed OS type.
  ///
  /// Required.
  /// Possible string values are:
  /// - "OS_UNSPECIFIED" : The operating system of the device is not specified
  /// or not known.
  /// - "DESKTOP_MAC" : A desktop Mac operating system.
  /// - "DESKTOP_WINDOWS" : A desktop Windows operating system.
  /// - "DESKTOP_LINUX" : A desktop Linux operating system.
  /// - "DESKTOP_CHROME_OS" : A desktop ChromeOS operating system.
  /// - "ANDROID" : An Android operating system.
  /// - "IOS" : An iOS operating system.
  core.String? osType;

  /// Only allows requests from devices with a verified Chrome OS.
  ///
  /// Verifications includes requirements that the device is enterprise-managed,
  /// conformant to domain policies, and the caller has permission to call the
  /// API targeted by the request.
  core.bool? requireVerifiedChromeOs;

  OsConstraint();

  OsConstraint.fromJson(core.Map _json) {
    if (_json.containsKey('minimumVersion')) {
      minimumVersion = _json['minimumVersion'] as core.String;
    }
    if (_json.containsKey('osType')) {
      osType = _json['osType'] as core.String;
    }
    if (_json.containsKey('requireVerifiedChromeOs')) {
      requireVerifiedChromeOs = _json['requireVerifiedChromeOs'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minimumVersion != null) 'minimumVersion': minimumVersion!,
        if (osType != null) 'osType': osType!,
        if (requireVerifiedChromeOs != null)
          'requireVerifiedChromeOs': requireVerifiedChromeOs!,
      };
}

/// A request to replace all existing Access Levels in an Access Policy with the
/// Access Levels provided.
///
/// This is done atomically.
class ReplaceAccessLevelsRequest {
  /// The desired Access Levels that should replace all existing Access Levels
  /// in the Access Policy.
  ///
  /// Required.
  core.List<AccessLevel>? accessLevels;

  /// The etag for the version of the Access Policy that this replace operation
  /// is to be performed on.
  ///
  /// If, at the time of replace, the etag for the Access Policy stored in
  /// Access Context Manager is different from the specified etag, then the
  /// replace operation will not be performed and the call will fail. This field
  /// is not required. If etag is not provided, the operation will be performed
  /// as if a valid etag is provided.
  ///
  /// Optional.
  core.String? etag;

  ReplaceAccessLevelsRequest();

  ReplaceAccessLevelsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevels')) {
      accessLevels = (_json['accessLevels'] as core.List)
          .map<AccessLevel>((value) => AccessLevel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevels != null)
          'accessLevels': accessLevels!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
      };
}

/// A response to ReplaceAccessLevelsRequest.
///
/// This will be put inside of Operation.response field.
class ReplaceAccessLevelsResponse {
  /// List of the Access Level instances.
  core.List<AccessLevel>? accessLevels;

  ReplaceAccessLevelsResponse();

  ReplaceAccessLevelsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevels')) {
      accessLevels = (_json['accessLevels'] as core.List)
          .map<AccessLevel>((value) => AccessLevel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevels != null)
          'accessLevels': accessLevels!.map((value) => value.toJson()).toList(),
      };
}

/// A request to replace all existing Service Perimeters in an Access Policy
/// with the Service Perimeters provided.
///
/// This is done atomically.
class ReplaceServicePerimetersRequest {
  /// The etag for the version of the Access Policy that this replace operation
  /// is to be performed on.
  ///
  /// If, at the time of replace, the etag for the Access Policy stored in
  /// Access Context Manager is different from the specified etag, then the
  /// replace operation will not be performed and the call will fail. This field
  /// is not required. If etag is not provided, the operation will be performed
  /// as if a valid etag is provided.
  ///
  /// Optional.
  core.String? etag;

  /// The desired Service Perimeters that should replace all existing Service
  /// Perimeters in the Access Policy.
  ///
  /// Required.
  core.List<ServicePerimeter>? servicePerimeters;

  ReplaceServicePerimetersRequest();

  ReplaceServicePerimetersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('servicePerimeters')) {
      servicePerimeters = (_json['servicePerimeters'] as core.List)
          .map<ServicePerimeter>((value) => ServicePerimeter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (servicePerimeters != null)
          'servicePerimeters':
              servicePerimeters!.map((value) => value.toJson()).toList(),
      };
}

/// A response to ReplaceServicePerimetersRequest.
///
/// This will be put inside of Operation.response field.
class ReplaceServicePerimetersResponse {
  /// List of the Service Perimeter instances.
  core.List<ServicePerimeter>? servicePerimeters;

  ReplaceServicePerimetersResponse();

  ReplaceServicePerimetersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('servicePerimeters')) {
      servicePerimeters = (_json['servicePerimeters'] as core.List)
          .map<ServicePerimeter>((value) => ServicePerimeter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (servicePerimeters != null)
          'servicePerimeters':
              servicePerimeters!.map((value) => value.toJson()).toList(),
      };
}

/// `ServicePerimeter` describes a set of Google Cloud resources which can
/// freely import and export data amongst themselves, but not export outside of
/// the `ServicePerimeter`.
///
/// If a request with a source within this `ServicePerimeter` has a target
/// outside of the `ServicePerimeter`, the request will be blocked. Otherwise
/// the request is allowed. There are two types of Service Perimeter - Regular
/// and Bridge. Regular Service Perimeters cannot overlap, a single Google Cloud
/// project can only belong to a single regular Service Perimeter. Service
/// Perimeter Bridges can contain only Google Cloud projects as members, a
/// single Google Cloud project may belong to multiple Service Perimeter
/// Bridges.
class ServicePerimeter {
  /// Description of the `ServicePerimeter` and its use.
  ///
  /// Does not affect behavior.
  core.String? description;

  /// Resource name for the ServicePerimeter.
  ///
  /// The `short_name` component must begin with a letter and only include
  /// alphanumeric and '_'. Format:
  /// `accessPolicies/{policy_id}/servicePerimeters/{short_name}`
  ///
  /// Required.
  core.String? name;

  /// Perimeter type indicator.
  ///
  /// A single project is allowed to be a member of single regular perimeter,
  /// but multiple service perimeter bridges. A project cannot be a included in
  /// a perimeter bridge without being included in regular perimeter. For
  /// perimeter bridges, the restricted service list as well as access level
  /// lists must be empty.
  /// Possible string values are:
  /// - "PERIMETER_TYPE_REGULAR" : Regular Perimeter.
  /// - "PERIMETER_TYPE_BRIDGE" : Perimeter Bridge.
  core.String? perimeterType;

  /// Proposed (or dry run) ServicePerimeter configuration.
  ///
  /// This configuration allows to specify and test ServicePerimeter
  /// configuration without enforcing actual access restrictions. Only allowed
  /// to be set when the "use_explicit_dry_run_spec" flag is set.
  ServicePerimeterConfig? spec;

  /// Current ServicePerimeter configuration.
  ///
  /// Specifies sets of resources, restricted services and access levels that
  /// determine perimeter content and boundaries.
  ServicePerimeterConfig? status;

  /// Human readable title.
  ///
  /// Must be unique within the Policy.
  core.String? title;

  /// Use explicit dry run spec flag.
  ///
  /// Ordinarily, a dry-run spec implicitly exists for all Service Perimeters,
  /// and that spec is identical to the status for those Service Perimeters.
  /// When this flag is set, it inhibits the generation of the implicit spec,
  /// thereby allowing the user to explicitly provide a configuration ("spec")
  /// to use in a dry-run version of the Service Perimeter. This allows the user
  /// to test changes to the enforced config ("status") without actually
  /// enforcing them. This testing is done through analyzing the differences
  /// between currently enforced and suggested restrictions.
  /// use_explicit_dry_run_spec must bet set to True if any of the fields in the
  /// spec are set to non-default values.
  core.bool? useExplicitDryRunSpec;

  ServicePerimeter();

  ServicePerimeter.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('perimeterType')) {
      perimeterType = _json['perimeterType'] as core.String;
    }
    if (_json.containsKey('spec')) {
      spec = ServicePerimeterConfig.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = ServicePerimeterConfig.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('useExplicitDryRunSpec')) {
      useExplicitDryRunSpec = _json['useExplicitDryRunSpec'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (perimeterType != null) 'perimeterType': perimeterType!,
        if (spec != null) 'spec': spec!.toJson(),
        if (status != null) 'status': status!.toJson(),
        if (title != null) 'title': title!,
        if (useExplicitDryRunSpec != null)
          'useExplicitDryRunSpec': useExplicitDryRunSpec!,
      };
}

/// `ServicePerimeterConfig` specifies a set of Google Cloud resources that
/// describe specific Service Perimeter configuration.
class ServicePerimeterConfig {
  /// A list of `AccessLevel` resource names that allow resources within the
  /// `ServicePerimeter` to be accessed from the internet.
  ///
  /// `AccessLevels` listed must be in the same policy as this
  /// `ServicePerimeter`. Referencing a nonexistent `AccessLevel` is a syntax
  /// error. If no `AccessLevel` names are listed, resources within the
  /// perimeter can only be accessed via Google Cloud calls with request origins
  /// within the perimeter. Example:
  /// `"accessPolicies/MY_POLICY/accessLevels/MY_LEVEL"`. For Service Perimeter
  /// Bridge, must be empty.
  core.List<core.String>? accessLevels;

  /// List of EgressPolicies to apply to the perimeter.
  ///
  /// A perimeter may have multiple EgressPolicies, each of which is evaluated
  /// separately. Access is granted if any EgressPolicy grants it. Must be empty
  /// for a perimeter bridge.
  core.List<EgressPolicy>? egressPolicies;

  /// List of IngressPolicies to apply to the perimeter.
  ///
  /// A perimeter may have multiple IngressPolicies, each of which is evaluated
  /// separately. Access is granted if any Ingress Policy grants it. Must be
  /// empty for a perimeter bridge.
  core.List<IngressPolicy>? ingressPolicies;

  /// A list of Google Cloud resources that are inside of the service perimeter.
  ///
  /// Currently only projects are allowed. Format: `projects/{project_number}`
  core.List<core.String>? resources;

  /// Google Cloud services that are subject to the Service Perimeter
  /// restrictions.
  ///
  /// For example, if `storage.googleapis.com` is specified, access to the
  /// storage buckets inside the perimeter must meet the perimeter's access
  /// restrictions.
  core.List<core.String>? restrictedServices;

  /// Configuration for APIs allowed within Perimeter.
  VpcAccessibleServices? vpcAccessibleServices;

  ServicePerimeterConfig();

  ServicePerimeterConfig.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevels')) {
      accessLevels = (_json['accessLevels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('egressPolicies')) {
      egressPolicies = (_json['egressPolicies'] as core.List)
          .map<EgressPolicy>((value) => EgressPolicy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('ingressPolicies')) {
      ingressPolicies = (_json['ingressPolicies'] as core.List)
          .map<IngressPolicy>((value) => IngressPolicy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('restrictedServices')) {
      restrictedServices = (_json['restrictedServices'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('vpcAccessibleServices')) {
      vpcAccessibleServices = VpcAccessibleServices.fromJson(
          _json['vpcAccessibleServices']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevels != null) 'accessLevels': accessLevels!,
        if (egressPolicies != null)
          'egressPolicies':
              egressPolicies!.map((value) => value.toJson()).toList(),
        if (ingressPolicies != null)
          'ingressPolicies':
              ingressPolicies!.map((value) => value.toJson()).toList(),
        if (resources != null) 'resources': resources!,
        if (restrictedServices != null)
          'restrictedServices': restrictedServices!,
        if (vpcAccessibleServices != null)
          'vpcAccessibleServices': vpcAccessibleServices!.toJson(),
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

/// Specifies how APIs are allowed to communicate within the Service Perimeter.
class VpcAccessibleServices {
  /// The list of APIs usable within the Service Perimeter.
  ///
  /// Must be empty unless 'enable_restriction' is True. You can specify a list
  /// of individual services, as well as include the 'RESTRICTED-SERVICES'
  /// value, which automatically includes all of the services protected by the
  /// perimeter.
  core.List<core.String>? allowedServices;

  /// Whether to restrict API calls within the Service Perimeter to the list of
  /// APIs specified in 'allowed_services'.
  core.bool? enableRestriction;

  VpcAccessibleServices();

  VpcAccessibleServices.fromJson(core.Map _json) {
    if (_json.containsKey('allowedServices')) {
      allowedServices = (_json['allowedServices'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('enableRestriction')) {
      enableRestriction = _json['enableRestriction'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedServices != null) 'allowedServices': allowedServices!,
        if (enableRestriction != null) 'enableRestriction': enableRestriction!,
      };
}

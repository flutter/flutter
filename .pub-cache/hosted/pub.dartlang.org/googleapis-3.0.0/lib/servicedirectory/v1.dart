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

/// Service Directory API - v1
///
/// Service Directory is a platform for discovering, publishing, and connecting
/// services.
///
/// For more information, see <https://cloud.google.com/service-directory>
///
/// Create an instance of [ServiceDirectoryApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsNamespacesResource]
///       - [ProjectsLocationsNamespacesServicesResource]
///         - [ProjectsLocationsNamespacesServicesEndpointsResource]
library servicedirectory.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Service Directory is a platform for discovering, publishing, and connecting
/// services.
class ServiceDirectoryApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  ServiceDirectoryApi(http.Client client,
      {core.String rootUrl = 'https://servicedirectory.googleapis.com/',
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

  ProjectsLocationsNamespacesResource get namespaces =>
      ProjectsLocationsNamespacesResource(_requester);

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

class ProjectsLocationsNamespacesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsNamespacesServicesResource get services =>
      ProjectsLocationsNamespacesServicesResource(_requester);

  ProjectsLocationsNamespacesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a namespace, and returns the new namespace.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the project and location the
  /// namespace will be created in.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [namespaceId] - Required. The Resource ID must be 1-63 characters long,
  /// and comply with RFC1035. Specifically, the name must be 1-63 characters
  /// long and match the regular expression `[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?`
  /// which means the first character must be a lowercase letter, and all
  /// following characters must be a dash, lowercase letter, or digit, except
  /// the last character, which cannot be a dash.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Namespace].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Namespace> create(
    Namespace request,
    core.String parent, {
    core.String? namespaceId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (namespaceId != null) 'namespaceId': [namespaceId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/namespaces';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Namespace.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a namespace.
  ///
  /// This also deletes all services and endpoints in the namespace.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the namespace to delete.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
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

  /// Gets a namespace.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the namespace to retrieve.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Namespace].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Namespace> get(
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
    return Namespace.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the IAM Policy for a resource (namespace or service only).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
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
    GetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all namespaces.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the project and location whose
  /// namespaces you'd like to list.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - Optional. The filter to list results by. General `filter`
  /// string syntax: ` ()` * `` can be `name` or `labels.` for map field * ``
  /// can be `<`, `>`, `<=`, `>=`, `!=`, `=`, `:`. Of which `:` means `HAS`, and
  /// is roughly the same as `=` * `` must be the same data type as field * ``
  /// can be `AND`, `OR`, `NOT` Examples of valid filters: * `labels.owner`
  /// returns namespaces that have a label with the key `owner`, this is the
  /// same as `labels:owner` * `labels.owner=sd` returns namespaces that have
  /// key/value `owner=sd` *
  /// `name>projects/my-project/locations/us-east1/namespaces/namespace-c`
  /// returns namespaces that have name that is alphabetically later than the
  /// string, so "namespace-e" is returned but "namespace-a" is not *
  /// `labels.owner!=sd AND labels.foo=bar` returns namespaces that have `owner`
  /// in label key but value is not `sd` AND have key/value `foo=bar` *
  /// `doesnotexist.foo=bar` returns an empty list. Note that namespace doesn't
  /// have a field called "doesnotexist". Since the filter does not match any
  /// namespaces, it returns no results For more information about filtering,
  /// see [API Filtering](https://aip.dev/160).
  ///
  /// [orderBy] - Optional. The order to list results by. General `order_by`
  /// string syntax: ` () (,)` * `` allows value: `name` * `` ascending or
  /// descending order by ``. If this is left blank, `asc` is used Note that an
  /// empty `order_by` string results in default order, which is order by `name`
  /// in ascending order.
  ///
  /// [pageSize] - Optional. The maximum number of items to return.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a previous
  /// List request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListNamespacesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListNamespacesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/namespaces';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListNamespacesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a namespace.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. The resource name for the namespace in the format
  /// `projects / * /locations / * /namespaces / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
  ///
  /// [updateMask] - Required. List of fields to be updated in this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Namespace].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Namespace> patch(
    Namespace request,
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
    return Namespace.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the IAM Policy for a resource (namespace or service only).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
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

  /// Tests IAM permissions for a resource (namespace or service only).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
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

class ProjectsLocationsNamespacesServicesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsNamespacesServicesEndpointsResource get endpoints =>
      ProjectsLocationsNamespacesServicesEndpointsResource(_requester);

  ProjectsLocationsNamespacesServicesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a service, and returns the new service.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the namespace this service will
  /// belong to.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
  ///
  /// [serviceId] - Required. The Resource ID must be 1-63 characters long, and
  /// comply with RFC1035. Specifically, the name must be 1-63 characters long
  /// and match the regular expression `[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?` which
  /// means the first character must be a lowercase letter, and all following
  /// characters must be a dash, lowercase letter, or digit, except the last
  /// character, which cannot be a dash.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Service].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Service> create(
    Service request,
    core.String parent, {
    core.String? serviceId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (serviceId != null) 'serviceId': [serviceId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/services';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Service.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a service.
  ///
  /// This also deletes all endpoints associated with the service.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the service to delete.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
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

  /// Gets a service.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the service to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Service].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Service> get(
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
    return Service.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the IAM Policy for a resource (namespace or service only).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
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
    GetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all services belonging to a namespace.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the namespace whose services
  /// you'd like to list.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+$`.
  ///
  /// [filter] - Optional. The filter to list results by. General `filter`
  /// string syntax: ` ()` * `` can be `name` or `annotations.` for map field *
  /// `` can be `<`, `>`, `<=`, `>=`, `!=`, `=`, `:`. Of which `:` means `HAS`,
  /// and is roughly the same as `=` * `` must be the same data type as field *
  /// `` can be `AND`, `OR`, `NOT` Examples of valid filters: *
  /// `annotations.owner` returns services that have a annotation with the key
  /// `owner`, this is the same as `annotations:owner` *
  /// `annotations.protocol=gRPC` returns services that have key/value
  /// `protocol=gRPC` *
  /// `name>projects/my-project/locations/us-east1/namespaces/my-namespace/services/service-c`
  /// returns services that have name that is alphabetically later than the
  /// string, so "service-e" is returned but "service-a" is not *
  /// `annotations.owner!=sd AND annotations.foo=bar` returns services that have
  /// `owner` in annotation key but value is not `sd` AND have key/value
  /// `foo=bar` * `doesnotexist.foo=bar` returns an empty list. Note that
  /// service doesn't have a field called "doesnotexist". Since the filter does
  /// not match any services, it returns no results For more information about
  /// filtering, see [API Filtering](https://aip.dev/160).
  ///
  /// [orderBy] - Optional. The order to list results by. General `order_by`
  /// string syntax: ` () (,)` * `` allows value: `name` * `` ascending or
  /// descending order by ``. If this is left blank, `asc` is used Note that an
  /// empty `order_by` string results in default order, which is order by `name`
  /// in ascending order.
  ///
  /// [pageSize] - Optional. The maximum number of items to return.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a previous
  /// List request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListServicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListServicesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/services';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListServicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a service.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. The resource name for the service in the format
  /// `projects / * /locations / * /namespaces / * /services / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [updateMask] - Required. List of fields to be updated in this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Service].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Service> patch(
    Service request,
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
    return Service.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a service and its associated endpoints.
  ///
  /// Resolving a service is not considered an active developer method.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the service to resolve.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ResolveServiceResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ResolveServiceResponse> resolve(
    ResolveServiceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':resolve';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ResolveServiceResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the IAM Policy for a resource (namespace or service only).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
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

  /// Tests IAM permissions for a resource (namespace or service only).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
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

class ProjectsLocationsNamespacesServicesEndpointsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsNamespacesServicesEndpointsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Creates an endpoint, and returns the new endpoint.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the service that this endpoint
  /// provides.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [endpointId] - Required. The Resource ID must be 1-63 characters long, and
  /// comply with RFC1035. Specifically, the name must be 1-63 characters long
  /// and match the regular expression `[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?` which
  /// means the first character must be a lowercase letter, and all following
  /// characters must be a dash, lowercase letter, or digit, except the last
  /// character, which cannot be a dash.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Endpoint].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Endpoint> create(
    Endpoint request,
    core.String parent, {
    core.String? endpointId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (endpointId != null) 'endpointId': [endpointId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/endpoints';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Endpoint.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an endpoint.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the endpoint to delete.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+/endpoints/\[^/\]+$`.
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

  /// Gets an endpoint.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the endpoint to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+/endpoints/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Endpoint].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Endpoint> get(
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
    return Endpoint.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all endpoints.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the service whose endpoints
  /// you'd like to list.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [filter] - Optional. The filter to list results by. General `filter`
  /// string syntax: ` ()` * `` can be `name`, `address`, `port`, or
  /// `annotations.` for map field * `` can be `<`, `>`, `<=`, `>=`, `!=`, `=`,
  /// `:`. Of which `:` means `HAS`, and is roughly the same as `=` * `` must be
  /// the same data type as field * `` can be `AND`, `OR`, `NOT` Examples of
  /// valid filters: * `annotations.owner` returns endpoints that have a
  /// annotation with the key `owner`, this is the same as `annotations:owner` *
  /// `annotations.protocol=gRPC` returns endpoints that have key/value
  /// `protocol=gRPC` * `address=192.108.1.105` returns endpoints that have this
  /// address * `port>8080` returns endpoints that have port number larger than
  /// 8080 *
  /// `name>projects/my-project/locations/us-east1/namespaces/my-namespace/services/my-service/endpoints/endpoint-c`
  /// returns endpoints that have name that is alphabetically later than the
  /// string, so "endpoint-e" is returned but "endpoint-a" is not *
  /// `annotations.owner!=sd AND annotations.foo=bar` returns endpoints that
  /// have `owner` in annotation key but value is not `sd` AND have key/value
  /// `foo=bar` * `doesnotexist.foo=bar` returns an empty list. Note that
  /// endpoint doesn't have a field called "doesnotexist". Since the filter does
  /// not match any endpoints, it returns no results For more information about
  /// filtering, see [API Filtering](https://aip.dev/160).
  ///
  /// [orderBy] - Optional. The order to list results by. General `order_by`
  /// string syntax: ` () (,)` * `` allows values: `name`, `address`, `port` *
  /// `` ascending or descending order by ``. If this is left blank, `asc` is
  /// used Note that an empty `order_by` string results in default order, which
  /// is order by `name` in ascending order.
  ///
  /// [pageSize] - Optional. The maximum number of items to return.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a previous
  /// List request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListEndpointsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListEndpointsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/endpoints';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListEndpointsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an endpoint.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. The resource name for the endpoint in the format
  /// `projects / * /locations / * /namespaces / * /services / * /endpoints / *
  /// `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/namespaces/\[^/\]+/services/\[^/\]+/endpoints/\[^/\]+$`.
  ///
  /// [updateMask] - Required. List of fields to be updated in this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Endpoint].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Endpoint> patch(
    Endpoint request,
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
    return Endpoint.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
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

/// An individual endpoint that provides a service.
///
/// The service must already exist to create an endpoint.
class Endpoint {
  /// An IPv4 or IPv6 address.
  ///
  /// Service Directory rejects bad addresses like: * `8.8.8` * `8.8.8.8:53` *
  /// `test:bad:address` * `[::1]` * `[::1]:8080` Limited to 45 characters.
  ///
  /// Optional.
  core.String? address;

  /// Annotations for the endpoint.
  ///
  /// This data can be consumed by service clients. Restrictions: * The entire
  /// annotations dictionary may contain up to 512 characters, spread accoss all
  /// key-value pairs. Annotations that go beyond this limit are rejected *
  /// Valid annotation keys have two segments: an optional prefix and name,
  /// separated by a slash (/). The name segment is required and must be 63
  /// characters or less, beginning and ending with an alphanumeric character
  /// (\[a-z0-9A-Z\]) with dashes (-), underscores (_), dots (.), and
  /// alphanumerics between. The prefix is optional. If specified, the prefix
  /// must be a DNS subdomain: a series of DNS labels separated by dots (.), not
  /// longer than 253 characters in total, followed by a slash (/) Annotations
  /// that fails to meet these requirements are rejected. * The
  /// `(*.)google.com/` and `(*.)googleapis.com/` prefixes are reserved for
  /// system annotations managed by Service Directory. If the user tries to
  /// write to these keyspaces, those entries are silently ignored by the system
  /// Note: This field is equivalent to the `metadata` field in the v1beta1 API.
  /// They have the same syntax and read/write to the same location in Service
  /// Directory.
  ///
  /// Optional.
  core.Map<core.String, core.String>? annotations;

  /// The resource name for the endpoint in the format `projects / * /locations
  /// / * /namespaces / * /services / * /endpoints / * `.
  ///
  /// Immutable.
  core.String? name;

  /// Service Directory rejects values outside of `[0, 65535]`.
  ///
  /// Optional.
  core.int? port;

  Endpoint();

  Endpoint.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('annotations')) {
      annotations =
          (_json['annotations'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (annotations != null) 'annotations': annotations!,
        if (name != null) 'name': name!,
        if (port != null) 'port': port!,
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

/// Request message for `GetIamPolicy` method.
class GetIamPolicyRequest {
  /// OPTIONAL: A `GetPolicyOptions` object for specifying options to
  /// `GetIamPolicy`.
  GetPolicyOptions? options;

  GetIamPolicyRequest();

  GetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('options')) {
      options = GetPolicyOptions.fromJson(
          _json['options'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (options != null) 'options': options!.toJson(),
      };
}

/// Encapsulates settings provided to GetIamPolicy.
class GetPolicyOptions {
  /// The policy format version to be returned.
  ///
  /// Valid values are 0, 1, and 3. Requests specifying an invalid value will be
  /// rejected. Requests for policies with any conditional bindings must specify
  /// version 3. Policies without any conditional bindings may specify any valid
  /// value or leave the field unset. To learn which resources support
  /// conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// Optional.
  core.int? requestedPolicyVersion;

  GetPolicyOptions();

  GetPolicyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('requestedPolicyVersion')) {
      requestedPolicyVersion = _json['requestedPolicyVersion'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestedPolicyVersion != null)
          'requestedPolicyVersion': requestedPolicyVersion!,
      };
}

/// The response message for RegistrationService.ListEndpoints.
class ListEndpointsResponse {
  /// The list of endpoints.
  core.List<Endpoint>? endpoints;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListEndpointsResponse();

  ListEndpointsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('endpoints')) {
      endpoints = (_json['endpoints'] as core.List)
          .map<Endpoint>((value) =>
              Endpoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endpoints != null)
          'endpoints': endpoints!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
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

/// The response message for RegistrationService.ListNamespaces.
class ListNamespacesResponse {
  /// The list of namespaces.
  core.List<Namespace>? namespaces;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListNamespacesResponse();

  ListNamespacesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('namespaces')) {
      namespaces = (_json['namespaces'] as core.List)
          .map<Namespace>((value) =>
              Namespace.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namespaces != null)
          'namespaces': namespaces!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for RegistrationService.ListServices.
class ListServicesResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of services.
  core.List<Service>? services;

  ListServicesResponse();

  ListServicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<Service>((value) =>
              Service.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (services != null)
          'services': services!.map((value) => value.toJson()).toList(),
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

/// A container for services.
///
/// Namespaces allow administrators to group services together and define
/// permissions for a collection of services.
class Namespace {
  /// Resource labels associated with this namespace.
  ///
  /// No more than 64 user labels can be associated with a given resource. Label
  /// keys and values can be no longer than 63 characters.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  /// The resource name for the namespace in the format `projects / * /locations
  /// / * /namespaces / * `.
  ///
  /// Immutable.
  core.String? name;

  Namespace();

  Namespace.fromJson(core.Map _json) {
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
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
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

/// The request message for LookupService.ResolveService.
///
/// Looks up a service by its name, returns the service and its endpoints.
class ResolveServiceRequest {
  /// The filter applied to the endpoints of the resolved service.
  ///
  /// General `filter` string syntax: ` ()` * `` can be `name`, `address`,
  /// `port`, or `annotations.` for map field * `` can be `<`, `>`, `<=`, `>=`,
  /// `!=`, `=`, `:`. Of which `:` means `HAS`, and is roughly the same as `=` *
  /// `` must be the same data type as field * `` can be `AND`, `OR`, `NOT`
  /// Examples of valid filters: * `annotations.owner` returns endpoints that
  /// have a annotation with the key `owner`, this is the same as
  /// `annotations:owner` * `annotations.protocol=gRPC` returns endpoints that
  /// have key/value `protocol=gRPC` * `address=192.108.1.105` returns endpoints
  /// that have this address * `port>8080` returns endpoints that have port
  /// number larger than 8080 *
  /// `name>projects/my-project/locations/us-east1/namespaces/my-namespace/services/my-service/endpoints/endpoint-c`
  /// returns endpoints that have name that is alphabetically later than the
  /// string, so "endpoint-e" is returned but "endpoint-a" is not *
  /// `annotations.owner!=sd AND annotations.foo=bar` returns endpoints that
  /// have `owner` in annotation key but value is not `sd` AND have key/value
  /// `foo=bar` * `doesnotexist.foo=bar` returns an empty list. Note that
  /// endpoint doesn't have a field called "doesnotexist". Since the filter does
  /// not match any endpoint, it returns no results For more information about
  /// filtering, see [API Filtering](https://aip.dev/160).
  ///
  /// Optional.
  core.String? endpointFilter;

  /// The maximum number of endpoints to return.
  ///
  /// Defaults to 25. Maximum is 100. If a value less than one is specified, the
  /// Default is used. If a value greater than the Maximum is specified, the
  /// Maximum is used.
  ///
  /// Optional.
  core.int? maxEndpoints;

  ResolveServiceRequest();

  ResolveServiceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('endpointFilter')) {
      endpointFilter = _json['endpointFilter'] as core.String;
    }
    if (_json.containsKey('maxEndpoints')) {
      maxEndpoints = _json['maxEndpoints'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endpointFilter != null) 'endpointFilter': endpointFilter!,
        if (maxEndpoints != null) 'maxEndpoints': maxEndpoints!,
      };
}

/// The response message for LookupService.ResolveService.
class ResolveServiceResponse {
  Service? service;

  ResolveServiceResponse();

  ResolveServiceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('service')) {
      service = Service.fromJson(
          _json['service'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (service != null) 'service': service!.toJson(),
      };
}

/// An individual service.
///
/// A service contains a name and optional metadata. A service must exist before
/// endpoints can be added to it.
class Service {
  /// Annotations for the service.
  ///
  /// This data can be consumed by service clients. Restrictions: * The entire
  /// annotations dictionary may contain up to 2000 characters, spread accoss
  /// all key-value pairs. Annotations that go beyond this limit are rejected *
  /// Valid annotation keys have two segments: an optional prefix and name,
  /// separated by a slash (/). The name segment is required and must be 63
  /// characters or less, beginning and ending with an alphanumeric character
  /// (\[a-z0-9A-Z\]) with dashes (-), underscores (_), dots (.), and
  /// alphanumerics between. The prefix is optional. If specified, the prefix
  /// must be a DNS subdomain: a series of DNS labels separated by dots (.), not
  /// longer than 253 characters in total, followed by a slash (/). Annotations
  /// that fails to meet these requirements are rejected * The `(*.)google.com/`
  /// and `(*.)googleapis.com/` prefixes are reserved for system annotations
  /// managed by Service Directory. If the user tries to write to these
  /// keyspaces, those entries are silently ignored by the system Note: This
  /// field is equivalent to the `metadata` field in the v1beta1 API. They have
  /// the same syntax and read/write to the same location in Service Directory.
  ///
  /// Optional.
  core.Map<core.String, core.String>? annotations;

  /// Endpoints associated with this service.
  ///
  /// Returned on LookupService.ResolveService. Control plane clients should use
  /// RegistrationService.ListEndpoints.
  ///
  /// Output only.
  core.List<Endpoint>? endpoints;

  /// The resource name for the service in the format `projects / * /locations /
  /// * /namespaces / * /services / * `.
  ///
  /// Immutable.
  core.String? name;

  Service();

  Service.fromJson(core.Map _json) {
    if (_json.containsKey('annotations')) {
      annotations =
          (_json['annotations'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('endpoints')) {
      endpoints = (_json['endpoints'] as core.List)
          .map<Endpoint>((value) =>
              Endpoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotations != null) 'annotations': annotations!,
        if (endpoints != null)
          'endpoints': endpoints!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
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

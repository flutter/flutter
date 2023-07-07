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

/// Cloud Run Admin API - v1
///
/// Deploy and manage user provided container images that scale automatically
/// based on HTTP traffic.
///
/// For more information, see <https://cloud.google.com/run/>
///
/// Create an instance of [CloudRunApi] to access these resources:
///
/// - [NamespacesResource]
///   - [NamespacesAuthorizeddomainsResource]
///   - [NamespacesConfigurationsResource]
///   - [NamespacesDomainmappingsResource]
///   - [NamespacesRevisionsResource]
///   - [NamespacesRoutesResource]
///   - [NamespacesServicesResource]
/// - [ProjectsResource]
///   - [ProjectsAuthorizeddomainsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsAuthorizeddomainsResource]
///     - [ProjectsLocationsConfigurationsResource]
///     - [ProjectsLocationsDomainmappingsResource]
///     - [ProjectsLocationsRevisionsResource]
///     - [ProjectsLocationsRoutesResource]
///     - [ProjectsLocationsServicesResource]
library run.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Deploy and manage user provided container images that scale automatically
/// based on HTTP traffic.
class CloudRunApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  NamespacesResource get namespaces => NamespacesResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);

  CloudRunApi(http.Client client,
      {core.String rootUrl = 'https://run.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class NamespacesResource {
  final commons.ApiRequester _requester;

  NamespacesAuthorizeddomainsResource get authorizeddomains =>
      NamespacesAuthorizeddomainsResource(_requester);
  NamespacesConfigurationsResource get configurations =>
      NamespacesConfigurationsResource(_requester);
  NamespacesDomainmappingsResource get domainmappings =>
      NamespacesDomainmappingsResource(_requester);
  NamespacesRevisionsResource get revisions =>
      NamespacesRevisionsResource(_requester);
  NamespacesRoutesResource get routes => NamespacesRoutesResource(_requester);
  NamespacesServicesResource get services =>
      NamespacesServicesResource(_requester);

  NamespacesResource(commons.ApiRequester client) : _requester = client;
}

class NamespacesAuthorizeddomainsResource {
  final commons.ApiRequester _requester;

  NamespacesAuthorizeddomainsResource(commons.ApiRequester client)
      : _requester = client;

  /// List authorized domains.
  ///
  /// Request parameters:
  ///
  /// [parent] - Name of the parent Project resource. Example:
  /// `projects/myproject`.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum results to return per page.
  ///
  /// [pageToken] - Continuation token for fetching the next page of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAuthorizedDomainsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAuthorizedDomainsResponse> list(
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

    final _url = 'apis/domains.cloudrun.com/v1/' +
        core.Uri.encodeFull('$parent') +
        '/authorizeddomains';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAuthorizedDomainsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class NamespacesConfigurationsResource {
  final commons.ApiRequester _requester;

  NamespacesConfigurationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Get information about a configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the configuration to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/configurations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Configuration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Configuration> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Configuration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List configurations.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the configurations should be listed.
  /// For Cloud Run (fully managed), replace {namespace_id} with the project ID
  /// or number.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListConfigurationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListConfigurationsResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' +
        core.Uri.encodeFull('$parent') +
        '/configurations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListConfigurationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class NamespacesDomainmappingsResource {
  final commons.ApiRequester _requester;

  NamespacesDomainmappingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create a new domain mapping.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace in which the domain mapping should be created.
  /// For Cloud Run (fully managed), replace {namespace_id} with the project ID
  /// or number.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DomainMapping].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DomainMapping> create(
    DomainMapping request,
    core.String parent, {
    core.String? dryRun,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (dryRun != null) 'dryRun': [dryRun],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/domains.cloudrun.com/v1/' +
        core.Uri.encodeFull('$parent') +
        '/domainmappings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DomainMapping.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a domain mapping.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the domain mapping to delete. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/domainmappings/\[^/\]+$`.
  ///
  /// [apiVersion] - Cloud Run currently ignores this parameter.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [kind] - Cloud Run currently ignores this parameter.
  ///
  /// [propagationPolicy] - Specifies the propagation policy of delete. Cloud
  /// Run currently ignores this setting, and deletes in the background. Please
  /// see kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/
  /// for more information.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Status].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Status> delete(
    core.String name, {
    core.String? apiVersion,
    core.String? dryRun,
    core.String? kind,
    core.String? propagationPolicy,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (apiVersion != null) 'apiVersion': [apiVersion],
      if (dryRun != null) 'dryRun': [dryRun],
      if (kind != null) 'kind': [kind],
      if (propagationPolicy != null) 'propagationPolicy': [propagationPolicy],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/domains.cloudrun.com/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Status.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get information about a domain mapping.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the domain mapping to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/domainmappings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DomainMapping].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DomainMapping> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/domains.cloudrun.com/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DomainMapping.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List domain mappings.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the domain mappings should be listed.
  /// For Cloud Run (fully managed), replace {namespace_id} with the project ID
  /// or number.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDomainMappingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDomainMappingsResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/domains.cloudrun.com/v1/' +
        core.Uri.encodeFull('$parent') +
        '/domainmappings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDomainMappingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class NamespacesRevisionsResource {
  final commons.ApiRequester _requester;

  NamespacesRevisionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Delete a revision.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the revision to delete. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/revisions/\[^/\]+$`.
  ///
  /// [apiVersion] - Cloud Run currently ignores this parameter.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [kind] - Cloud Run currently ignores this parameter.
  ///
  /// [propagationPolicy] - Specifies the propagation policy of delete. Cloud
  /// Run currently ignores this setting, and deletes in the background. Please
  /// see kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/
  /// for more information.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Status].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Status> delete(
    core.String name, {
    core.String? apiVersion,
    core.String? dryRun,
    core.String? kind,
    core.String? propagationPolicy,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (apiVersion != null) 'apiVersion': [apiVersion],
      if (dryRun != null) 'dryRun': [dryRun],
      if (kind != null) 'kind': [kind],
      if (propagationPolicy != null) 'propagationPolicy': [propagationPolicy],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Status.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get information about a revision.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the revision to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/revisions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Revision].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Revision> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Revision.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List revisions.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the revisions should be listed. For
  /// Cloud Run (fully managed), replace {namespace_id} with the project ID or
  /// number.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRevisionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRevisionsResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' +
        core.Uri.encodeFull('$parent') +
        '/revisions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRevisionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class NamespacesRoutesResource {
  final commons.ApiRequester _requester;

  NamespacesRoutesResource(commons.ApiRequester client) : _requester = client;

  /// Get information about a route.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the route to retrieve. For Cloud Run (fully managed),
  /// replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/routes/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Route].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Route> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Route.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List routes.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the routes should be listed. For Cloud
  /// Run (fully managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRoutesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRoutesResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' +
        core.Uri.encodeFull('$parent') +
        '/routes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRoutesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class NamespacesServicesResource {
  final commons.ApiRequester _requester;

  NamespacesServicesResource(commons.ApiRequester client) : _requester = client;

  /// Create a service.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace in which the service should be created. For Cloud
  /// Run (fully managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
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
    core.String? dryRun,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (dryRun != null) 'dryRun': [dryRun],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' +
        core.Uri.encodeFull('$parent') +
        '/services';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Service.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a service.
  ///
  /// This will cause the Service to stop serving traffic and will delete the
  /// child entities like Routes, Configurations and Revisions.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the service to delete. For Cloud Run (fully managed),
  /// replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [apiVersion] - Cloud Run currently ignores this parameter.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [kind] - Cloud Run currently ignores this parameter.
  ///
  /// [propagationPolicy] - Specifies the propagation policy of delete. Cloud
  /// Run currently ignores this setting, and deletes in the background. Please
  /// see kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/
  /// for more information.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Status].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Status> delete(
    core.String name, {
    core.String? apiVersion,
    core.String? dryRun,
    core.String? kind,
    core.String? propagationPolicy,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (apiVersion != null) 'apiVersion': [apiVersion],
      if (dryRun != null) 'dryRun': [dryRun],
      if (kind != null) 'kind': [kind],
      if (propagationPolicy != null) 'propagationPolicy': [propagationPolicy],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Status.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get information about a service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the service to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/services/\[^/\]+$`.
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

    final _url = 'apis/serving.knative.dev/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Service.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List services.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the services should be listed. For
  /// Cloud Run (fully managed), replace {namespace_id} with the project ID or
  /// number.
  /// Value must have pattern `^namespaces/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
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
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' +
        core.Uri.encodeFull('$parent') +
        '/services';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListServicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Replace a service.
  ///
  /// Only the spec and metadata labels and annotations are modifiable. After
  /// the Update request, Cloud Run will work to make the 'status' match the
  /// requested 'spec'. May provide metadata.resourceVersion to enforce update
  /// from last read for optimistic concurrency control.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the service being replaced. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^namespaces/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
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
  async.Future<Service> replaceService(
    Service request,
    core.String name, {
    core.String? dryRun,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (dryRun != null) 'dryRun': [dryRun],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apis/serving.knative.dev/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Service.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsAuthorizeddomainsResource get authorizeddomains =>
      ProjectsAuthorizeddomainsResource(_requester);
  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsAuthorizeddomainsResource {
  final commons.ApiRequester _requester;

  ProjectsAuthorizeddomainsResource(commons.ApiRequester client)
      : _requester = client;

  /// List authorized domains.
  ///
  /// Request parameters:
  ///
  /// [parent] - Name of the parent Project resource. Example:
  /// `projects/myproject`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum results to return per page.
  ///
  /// [pageToken] - Continuation token for fetching the next page of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAuthorizedDomainsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAuthorizedDomainsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/authorizeddomains';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAuthorizedDomainsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAuthorizeddomainsResource get authorizeddomains =>
      ProjectsLocationsAuthorizeddomainsResource(_requester);
  ProjectsLocationsConfigurationsResource get configurations =>
      ProjectsLocationsConfigurationsResource(_requester);
  ProjectsLocationsDomainmappingsResource get domainmappings =>
      ProjectsLocationsDomainmappingsResource(_requester);
  ProjectsLocationsRevisionsResource get revisions =>
      ProjectsLocationsRevisionsResource(_requester);
  ProjectsLocationsRoutesResource get routes =>
      ProjectsLocationsRoutesResource(_requester);
  ProjectsLocationsServicesResource get services =>
      ProjectsLocationsServicesResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;

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

class ProjectsLocationsAuthorizeddomainsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAuthorizeddomainsResource(commons.ApiRequester client)
      : _requester = client;

  /// List authorized domains.
  ///
  /// Request parameters:
  ///
  /// [parent] - Name of the parent Project resource. Example:
  /// `projects/myproject`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum results to return per page.
  ///
  /// [pageToken] - Continuation token for fetching the next page of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAuthorizedDomainsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAuthorizedDomainsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/authorizeddomains';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAuthorizedDomainsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsConfigurationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsConfigurationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Get information about a configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the configuration to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/configurations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Configuration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Configuration> get(
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
    return Configuration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List configurations.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the configurations should be listed.
  /// For Cloud Run (fully managed), replace {namespace_id} with the project ID
  /// or number.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListConfigurationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListConfigurationsResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/configurations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListConfigurationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsDomainmappingsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsDomainmappingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create a new domain mapping.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace in which the domain mapping should be created.
  /// For Cloud Run (fully managed), replace {namespace_id} with the project ID
  /// or number.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DomainMapping].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DomainMapping> create(
    DomainMapping request,
    core.String parent, {
    core.String? dryRun,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (dryRun != null) 'dryRun': [dryRun],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/domainmappings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DomainMapping.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a domain mapping.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the domain mapping to delete. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/domainmappings/\[^/\]+$`.
  ///
  /// [apiVersion] - Cloud Run currently ignores this parameter.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [kind] - Cloud Run currently ignores this parameter.
  ///
  /// [propagationPolicy] - Specifies the propagation policy of delete. Cloud
  /// Run currently ignores this setting, and deletes in the background. Please
  /// see kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/
  /// for more information.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Status].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Status> delete(
    core.String name, {
    core.String? apiVersion,
    core.String? dryRun,
    core.String? kind,
    core.String? propagationPolicy,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (apiVersion != null) 'apiVersion': [apiVersion],
      if (dryRun != null) 'dryRun': [dryRun],
      if (kind != null) 'kind': [kind],
      if (propagationPolicy != null) 'propagationPolicy': [propagationPolicy],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Status.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get information about a domain mapping.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the domain mapping to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/domainmappings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DomainMapping].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DomainMapping> get(
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
    return DomainMapping.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List domain mappings.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the domain mappings should be listed.
  /// For Cloud Run (fully managed), replace {namespace_id} with the project ID
  /// or number.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDomainMappingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDomainMappingsResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/domainmappings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDomainMappingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRevisionsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRevisionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Delete a revision.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the revision to delete. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/revisions/\[^/\]+$`.
  ///
  /// [apiVersion] - Cloud Run currently ignores this parameter.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [kind] - Cloud Run currently ignores this parameter.
  ///
  /// [propagationPolicy] - Specifies the propagation policy of delete. Cloud
  /// Run currently ignores this setting, and deletes in the background. Please
  /// see kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/
  /// for more information.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Status].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Status> delete(
    core.String name, {
    core.String? apiVersion,
    core.String? dryRun,
    core.String? kind,
    core.String? propagationPolicy,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (apiVersion != null) 'apiVersion': [apiVersion],
      if (dryRun != null) 'dryRun': [dryRun],
      if (kind != null) 'kind': [kind],
      if (propagationPolicy != null) 'propagationPolicy': [propagationPolicy],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Status.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get information about a revision.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the revision to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/revisions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Revision].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Revision> get(
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
    return Revision.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List revisions.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the revisions should be listed. For
  /// Cloud Run (fully managed), replace {namespace_id} with the project ID or
  /// number.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRevisionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRevisionsResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/revisions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRevisionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRoutesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRoutesResource(commons.ApiRequester client)
      : _requester = client;

  /// Get information about a route.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the route to retrieve. For Cloud Run (fully managed),
  /// replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/routes/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Route].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Route> get(
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
    return Route.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List routes.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the routes should be listed. For Cloud
  /// Run (fully managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRoutesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRoutesResponse> list(
    core.String parent, {
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/routes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRoutesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsServicesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsServicesResource(commons.ApiRequester client)
      : _requester = client;

  /// Create a service.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace in which the service should be created. For Cloud
  /// Run (fully managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
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
    core.String? dryRun,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (dryRun != null) 'dryRun': [dryRun],
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

  /// Delete a service.
  ///
  /// This will cause the Service to stop serving traffic and will delete the
  /// child entities like Routes, Configurations and Revisions.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the service to delete. For Cloud Run (fully managed),
  /// replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [apiVersion] - Cloud Run currently ignores this parameter.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
  ///
  /// [kind] - Cloud Run currently ignores this parameter.
  ///
  /// [propagationPolicy] - Specifies the propagation policy of delete. Cloud
  /// Run currently ignores this setting, and deletes in the background. Please
  /// see kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/
  /// for more information.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Status].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Status> delete(
    core.String name, {
    core.String? apiVersion,
    core.String? dryRun,
    core.String? kind,
    core.String? propagationPolicy,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (apiVersion != null) 'apiVersion': [apiVersion],
      if (dryRun != null) 'dryRun': [dryRun],
      if (kind != null) 'kind': [kind],
      if (propagationPolicy != null) 'propagationPolicy': [propagationPolicy],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Status.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get information about a service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the service to retrieve. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/services/\[^/\]+$`.
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

  /// Get the IAM Access Control policy currently in effect for the given Cloud
  /// Run service.
  ///
  /// This result does not include any inherited policies.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/services/\[^/\]+$`.
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

  /// List services.
  ///
  /// Request parameters:
  ///
  /// [parent] - The namespace from which the services should be listed. For
  /// Cloud Run (fully managed), replace {namespace_id} with the project ID or
  /// number.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [continue_] - Optional encoded string to continue paging.
  ///
  /// [fieldSelector] - Allows to filter resources based on a specific value for
  /// a field name. Send this in a query string format. i.e.
  /// 'metadata.name%3Dlorem'. Not currently used by Cloud Run.
  ///
  /// [includeUninitialized] - Not currently used by Cloud Run.
  ///
  /// [labelSelector] - Allows to filter resources based on a label. Supported
  /// operations are =, !=, exists, in, and notIn.
  ///
  /// [limit] - The maximum number of records that should be returned.
  ///
  /// [resourceVersion] - The baseline resource version from which the list or
  /// watch operation should start. Not currently used by Cloud Run.
  ///
  /// [watch] - Flag that indicates that the client expects to watch this
  /// resource as well. Not currently used by Cloud Run.
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
    core.String? continue_,
    core.String? fieldSelector,
    core.bool? includeUninitialized,
    core.String? labelSelector,
    core.int? limit,
    core.String? resourceVersion,
    core.bool? watch,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (continue_ != null) 'continue': [continue_],
      if (fieldSelector != null) 'fieldSelector': [fieldSelector],
      if (includeUninitialized != null)
        'includeUninitialized': ['${includeUninitialized}'],
      if (labelSelector != null) 'labelSelector': [labelSelector],
      if (limit != null) 'limit': ['${limit}'],
      if (resourceVersion != null) 'resourceVersion': [resourceVersion],
      if (watch != null) 'watch': ['${watch}'],
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

  /// Replace a service.
  ///
  /// Only the spec and metadata labels and annotations are modifiable. After
  /// the Update request, Cloud Run will work to make the 'status' match the
  /// requested 'spec'. May provide metadata.resourceVersion to enforce update
  /// from last read for optimistic concurrency control.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the service being replaced. For Cloud Run (fully
  /// managed), replace {namespace_id} with the project ID or number.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/services/\[^/\]+$`.
  ///
  /// [dryRun] - Indicates that the server should validate the request and
  /// populate default values without persisting the request. Supported values:
  /// `all`
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
  async.Future<Service> replaceService(
    Service request,
    core.String name, {
    core.String? dryRun,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (dryRun != null) 'dryRun': [dryRun],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Service.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the IAM Access control policy for the specified Service.
  ///
  /// Overwrites any existing policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/services/\[^/\]+$`.
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

  /// Returns permissions that a caller has on the specified Project.
  ///
  /// There are no permissions required for making this API call.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/services/\[^/\]+$`.
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

/// Information for connecting over HTTP(s).
class Addressable {
  core.String? url;

  Addressable();

  Addressable.fromJson(core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
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

/// A domain that a user has been authorized to administer.
///
/// To authorize use of a domain, verify ownership via
/// [Webmaster Central](https://www.google.com/webmasters/verification/home).
class AuthorizedDomain {
  /// Relative name of the domain authorized for use.
  ///
  /// Example: `example.com`.
  core.String? id;

  /// Deprecated Read only.
  ///
  /// Full path to the `AuthorizedDomain` resource in the API. Example:
  /// `projects/myproject/authorizedDomains/example.com`.
  core.String? name;

  AuthorizedDomain();

  AuthorizedDomain.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
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

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// ConfigMapEnvSource selects a ConfigMap to populate the environment variables
/// with.
///
/// The contents of the target ConfigMap's Data field will represent the
/// key-value pairs as environment variables.
class ConfigMapEnvSource {
  /// This field should not be used directly as it is meant to be inlined
  /// directly into the message.
  ///
  /// Use the "name" field instead.
  LocalObjectReference? localObjectReference;

  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported The
  /// ConfigMap to select from.
  core.String? name;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Specify whether the ConfigMap must be defined
  core.bool? optional;

  ConfigMapEnvSource();

  ConfigMapEnvSource.fromJson(core.Map _json) {
    if (_json.containsKey('localObjectReference')) {
      localObjectReference = LocalObjectReference.fromJson(
          _json['localObjectReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (localObjectReference != null)
          'localObjectReference': localObjectReference!.toJson(),
        if (name != null) 'name': name!,
        if (optional != null) 'optional': optional!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// Selects a key from a ConfigMap.
class ConfigMapKeySelector {
  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported The
  /// key to select.
  core.String? key;

  /// This field should not be used directly as it is meant to be inlined
  /// directly into the message.
  ///
  /// Use the "name" field instead.
  LocalObjectReference? localObjectReference;

  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported The
  /// ConfigMap to select from.
  core.String? name;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Specify whether the ConfigMap or its key must be defined
  core.bool? optional;

  ConfigMapKeySelector();

  ConfigMapKeySelector.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('localObjectReference')) {
      localObjectReference = LocalObjectReference.fromJson(
          _json['localObjectReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (localObjectReference != null)
          'localObjectReference': localObjectReference!.toJson(),
        if (name != null) 'name': name!,
        if (optional != null) 'optional': optional!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// Adapts a ConfigMap into a volume.
///
/// The contents of the target ConfigMap's Data field will be presented in a
/// volume as files using the keys in the Data field as the file names, unless
/// the items element is populated with specific mappings of keys to paths.
class ConfigMapVolumeSource {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Mode bits to use on created files by default.
  ///
  /// Must be a value between 0 and 0777. Defaults to 0644. Directories within
  /// the path are not affected by this setting. This might be in conflict with
  /// other options that affect the file mode, like fsGroup, and the result can
  /// be other mode bits set.
  core.int? defaultMode;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported If unspecified, each key-value pair in the Data field of the
  /// referenced Secret will be projected into the volume as a file whose name
  /// is the key and content is the value.
  ///
  /// If specified, the listed keys will be projected into the specified paths,
  /// and unlisted keys will not be present. If a key is specified that is not
  /// present in the Secret, the volume setup will error unless it is marked
  /// optional.
  core.List<KeyToPath>? items;

  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
  /// Name of the config.
  core.String? name;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Specify whether the Secret or its keys must be defined.
  core.bool? optional;

  ConfigMapVolumeSource();

  ConfigMapVolumeSource.fromJson(core.Map _json) {
    if (_json.containsKey('defaultMode')) {
      defaultMode = _json['defaultMode'] as core.int;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<KeyToPath>((value) =>
              KeyToPath.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultMode != null) 'defaultMode': defaultMode!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (optional != null) 'optional': optional!,
      };
}

/// Configuration represents the "floating HEAD" of a linear history of
/// Revisions, and optionally how the containers those revisions reference are
/// built.
///
/// Users create new Revisions by updating the Configuration's spec. The "latest
/// created" revision's name is available under status, as is the "latest ready"
/// revision's name. See also:
/// https://github.com/knative/serving/blob/master/docs/spec/overview.md#configuration
class Configuration {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// The kind of resource, in this case always "Configuration".
  core.String? kind;

  /// Metadata associated with this Configuration, including name, namespace,
  /// labels, and annotations.
  ObjectMeta? metadata;

  /// Spec holds the desired state of the Configuration (from the client).
  ConfigurationSpec? spec;

  /// Status communicates the observed state of the Configuration (from the
  /// controller).
  ConfigurationStatus? status;

  Configuration();

  Configuration.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ObjectMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spec')) {
      spec = ConfigurationSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = ConfigurationStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (spec != null) 'spec': spec!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// ConfigurationSpec holds the desired state of the Configuration (from the
/// client).
class ConfigurationSpec {
  /// Template holds the latest specification for the Revision to be stamped
  /// out.
  RevisionTemplate? template;

  ConfigurationSpec();

  ConfigurationSpec.fromJson(core.Map _json) {
    if (_json.containsKey('template')) {
      template = RevisionTemplate.fromJson(
          _json['template'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (template != null) 'template': template!.toJson(),
      };
}

/// ConfigurationStatus communicates the observed state of the Configuration
/// (from the controller).
class ConfigurationStatus {
  /// Conditions communicates information about ongoing/complete reconciliation
  /// processes that bring the "spec" inline with the observed state of the
  /// world.
  core.List<GoogleCloudRunV1Condition>? conditions;

  /// LatestCreatedRevisionName is the last revision that was created from this
  /// Configuration.
  ///
  /// It might not be ready yet, for that use LatestReadyRevisionName.
  core.String? latestCreatedRevisionName;

  /// LatestReadyRevisionName holds the name of the latest Revision stamped out
  /// from this Configuration that has had its "Ready" condition become "True".
  core.String? latestReadyRevisionName;

  /// ObservedGeneration is the 'Generation' of the Configuration that was last
  /// processed by the controller.
  ///
  /// The observed generation is updated even if the controller failed to
  /// process the spec and create the Revision. Clients polling for completed
  /// reconciliation should poll until observedGeneration = metadata.generation,
  /// and the Ready condition's status is True or False.
  core.int? observedGeneration;

  ConfigurationStatus();

  ConfigurationStatus.fromJson(core.Map _json) {
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<GoogleCloudRunV1Condition>((value) =>
              GoogleCloudRunV1Condition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('latestCreatedRevisionName')) {
      latestCreatedRevisionName =
          _json['latestCreatedRevisionName'] as core.String;
    }
    if (_json.containsKey('latestReadyRevisionName')) {
      latestReadyRevisionName = _json['latestReadyRevisionName'] as core.String;
    }
    if (_json.containsKey('observedGeneration')) {
      observedGeneration = _json['observedGeneration'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (latestCreatedRevisionName != null)
          'latestCreatedRevisionName': latestCreatedRevisionName!,
        if (latestReadyRevisionName != null)
          'latestReadyRevisionName': latestReadyRevisionName!,
        if (observedGeneration != null)
          'observedGeneration': observedGeneration!,
      };
}

/// A single application container.
///
/// This specifies both the container to run, the command to run in the
/// container and the arguments to supply to it. Note that additional arguments
/// may be supplied by the system to the container at runtime.
class Container {
  /// (Optional) Cloud Run fully managed: supported Cloud Run for Anthos:
  /// supported Arguments to the entrypoint.
  ///
  /// The docker image's CMD is used if this is not provided. Variable
  /// references $(VAR_NAME) are expanded using the container's environment. If
  /// a variable cannot be resolved, the reference in the input string will be
  /// unchanged. The $(VAR_NAME) syntax can be escaped with a double $$, ie:
  /// $$(VAR_NAME). Escaped references will never be expanded, regardless of
  /// whether the variable exists or not. More info:
  /// https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell
  core.List<core.String>? args;
  core.List<core.String>? command;

  /// (Optional) Cloud Run fully managed: supported Cloud Run for Anthos:
  /// supported List of environment variables to set in the container.
  core.List<EnvVar>? env;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported List of sources to populate environment variables in the
  /// container.
  ///
  /// The keys defined within a source must be a C_IDENTIFIER. All invalid keys
  /// will be reported as an event when the container is starting. When a key
  /// exists in multiple sources, the value associated with the last source will
  /// take precedence. Values defined by an Env with a duplicate key will take
  /// precedence. Cannot be updated.
  core.List<EnvFromSource>? envFrom;

  /// Cloud Run fully managed: only supports containers from Google Container
  /// Registry Cloud Run for Anthos: supported URL of the Container image.
  ///
  /// More info: https://kubernetes.io/docs/concepts/containers/images
  core.String? image;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Image pull policy.
  ///
  /// One of Always, Never, IfNotPresent. Defaults to Always if :latest tag is
  /// specified, or IfNotPresent otherwise. More info:
  /// https://kubernetes.io/docs/concepts/containers/images#updating-images
  core.String? imagePullPolicy;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Periodic probe of container liveness.
  ///
  /// Container will be restarted if the probe fails. More info:
  /// https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
  Probe? livenessProbe;

  /// (Optional) Name of the container specified as a DNS_LABEL.
  ///
  /// Currently unused in Cloud Run. More info:
  /// https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names
  core.String? name;

  /// (Optional) List of ports to expose from the container.
  ///
  /// Only a single port can be specified. The specified ports must be listening
  /// on all interfaces (0.0.0.0) within the container to be accessible. If
  /// omitted, a port number will be chosen and passed to the container through
  /// the PORT environment variable for the container to listen on.
  core.List<ContainerPort>? ports;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Periodic probe of container service readiness.
  ///
  /// Container will be removed from service endpoints if the probe fails. More
  /// info:
  /// https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
  Probe? readinessProbe;

  /// (Optional) Cloud Run fully managed: supported Cloud Run for Anthos:
  /// supported Compute Resources required by this container.
  ///
  /// More info:
  /// https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources
  ResourceRequirements? resources;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Security options the pod should run with.
  ///
  /// More info: https://kubernetes.io/docs/concepts/policy/security-context/
  /// More info:
  /// https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
  SecurityContext? securityContext;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// not supported Startup probe of application within the container.
  ///
  /// All other probes are disabled if a startup probe is provided, until it
  /// succeeds. Container will not be added to service endpoints if the probe
  /// fails. More info:
  /// https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
  Probe? startupProbe;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Path at which the file to which the container's termination
  /// message will be written is mounted into the container's filesystem.
  ///
  /// Message written is intended to be brief final status, such as an assertion
  /// failure message. Will be truncated by the node if greater than 4096 bytes.
  /// The total message length across all containers will be limited to 12kb.
  /// Defaults to /dev/termination-log.
  core.String? terminationMessagePath;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Indicate how the termination message should be populated.
  ///
  /// File will use the contents of terminationMessagePath to populate the
  /// container status message on both success and failure.
  /// FallbackToLogsOnError will use the last chunk of container log output if
  /// the termination message file is empty and the container exited with an
  /// error. The log output is limited to 2048 bytes or 80 lines, whichever is
  /// smaller. Defaults to File. Cannot be updated.
  core.String? terminationMessagePolicy;

  /// (Optional) Cloud Run fully managed: supported Volume to mount into the
  /// container's filesystem.
  ///
  /// Only supports SecretVolumeSources. Cloud Run for Anthos: supported Pod
  /// volumes to mount into the container's filesystem.
  core.List<VolumeMount>? volumeMounts;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Container's working directory.
  ///
  /// If not specified, the container runtime's default will be used, which
  /// might be configured in the container image.
  core.String? workingDir;

  Container();

  Container.fromJson(core.Map _json) {
    if (_json.containsKey('args')) {
      args = (_json['args'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('command')) {
      command = (_json['command'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('env')) {
      env = (_json['env'] as core.List)
          .map<EnvVar>((value) =>
              EnvVar.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('envFrom')) {
      envFrom = (_json['envFrom'] as core.List)
          .map<EnvFromSource>((value) => EnvFromSource.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('image')) {
      image = _json['image'] as core.String;
    }
    if (_json.containsKey('imagePullPolicy')) {
      imagePullPolicy = _json['imagePullPolicy'] as core.String;
    }
    if (_json.containsKey('livenessProbe')) {
      livenessProbe = Probe.fromJson(
          _json['livenessProbe'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('ports')) {
      ports = (_json['ports'] as core.List)
          .map<ContainerPort>((value) => ContainerPort.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('readinessProbe')) {
      readinessProbe = Probe.fromJson(
          _json['readinessProbe'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resources')) {
      resources = ResourceRequirements.fromJson(
          _json['resources'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('securityContext')) {
      securityContext = SecurityContext.fromJson(
          _json['securityContext'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startupProbe')) {
      startupProbe = Probe.fromJson(
          _json['startupProbe'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('terminationMessagePath')) {
      terminationMessagePath = _json['terminationMessagePath'] as core.String;
    }
    if (_json.containsKey('terminationMessagePolicy')) {
      terminationMessagePolicy =
          _json['terminationMessagePolicy'] as core.String;
    }
    if (_json.containsKey('volumeMounts')) {
      volumeMounts = (_json['volumeMounts'] as core.List)
          .map<VolumeMount>((value) => VolumeMount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('workingDir')) {
      workingDir = _json['workingDir'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (args != null) 'args': args!,
        if (command != null) 'command': command!,
        if (env != null) 'env': env!.map((value) => value.toJson()).toList(),
        if (envFrom != null)
          'envFrom': envFrom!.map((value) => value.toJson()).toList(),
        if (image != null) 'image': image!,
        if (imagePullPolicy != null) 'imagePullPolicy': imagePullPolicy!,
        if (livenessProbe != null) 'livenessProbe': livenessProbe!.toJson(),
        if (name != null) 'name': name!,
        if (ports != null)
          'ports': ports!.map((value) => value.toJson()).toList(),
        if (readinessProbe != null) 'readinessProbe': readinessProbe!.toJson(),
        if (resources != null) 'resources': resources!.toJson(),
        if (securityContext != null)
          'securityContext': securityContext!.toJson(),
        if (startupProbe != null) 'startupProbe': startupProbe!.toJson(),
        if (terminationMessagePath != null)
          'terminationMessagePath': terminationMessagePath!,
        if (terminationMessagePolicy != null)
          'terminationMessagePolicy': terminationMessagePolicy!,
        if (volumeMounts != null)
          'volumeMounts': volumeMounts!.map((value) => value.toJson()).toList(),
        if (workingDir != null) 'workingDir': workingDir!,
      };
}

/// ContainerPort represents a network port in a single container.
class ContainerPort {
  /// (Optional) Port number the container listens on.
  ///
  /// This must be a valid port number, 0 < x < 65536.
  core.int? containerPort;

  /// (Optional) If specified, used to specify which protocol to use.
  ///
  /// Allowed values are "http1" and "h2c".
  core.String? name;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Protocol for port.
  ///
  /// Must be "TCP". Defaults to "TCP".
  core.String? protocol;

  ContainerPort();

  ContainerPort.fromJson(core.Map _json) {
    if (_json.containsKey('containerPort')) {
      containerPort = _json['containerPort'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containerPort != null) 'containerPort': containerPort!,
        if (name != null) 'name': name!,
        if (protocol != null) 'protocol': protocol!,
      };
}

/// Resource to hold the state and status of a user's domain mapping.
///
/// NOTE: This resource is currently in Beta.
class DomainMapping {
  /// The API version for this call such as "domains.cloudrun.com/v1".
  core.String? apiVersion;

  /// The kind of resource, in this case "DomainMapping".
  core.String? kind;

  /// Metadata associated with this BuildTemplate.
  ObjectMeta? metadata;

  /// The spec for this DomainMapping.
  DomainMappingSpec? spec;

  /// The current status of the DomainMapping.
  DomainMappingStatus? status;

  DomainMapping();

  DomainMapping.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ObjectMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spec')) {
      spec = DomainMappingSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = DomainMappingStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (spec != null) 'spec': spec!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// The desired state of the Domain Mapping.
class DomainMappingSpec {
  /// The mode of the certificate.
  /// Possible string values are:
  /// - "CERTIFICATE_MODE_UNSPECIFIED"
  /// - "NONE" : Do not provision an HTTPS certificate.
  /// - "AUTOMATIC" : Automatically provisions an HTTPS certificate via GoogleCA
  /// or LetsEncrypt.
  core.String? certificateMode;

  /// If set, the mapping will override any mapping set before this spec was
  /// set.
  ///
  /// It is recommended that the user leaves this empty to receive an error
  /// warning about a potential conflict and only set it once the respective UI
  /// has given such a warning.
  core.bool? forceOverride;

  /// The name of the Knative Route that this DomainMapping applies to.
  ///
  /// The route must exist.
  core.String? routeName;

  DomainMappingSpec();

  DomainMappingSpec.fromJson(core.Map _json) {
    if (_json.containsKey('certificateMode')) {
      certificateMode = _json['certificateMode'] as core.String;
    }
    if (_json.containsKey('forceOverride')) {
      forceOverride = _json['forceOverride'] as core.bool;
    }
    if (_json.containsKey('routeName')) {
      routeName = _json['routeName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (certificateMode != null) 'certificateMode': certificateMode!,
        if (forceOverride != null) 'forceOverride': forceOverride!,
        if (routeName != null) 'routeName': routeName!,
      };
}

/// The current state of the Domain Mapping.
class DomainMappingStatus {
  /// Array of observed DomainMappingConditions, indicating the current state of
  /// the DomainMapping.
  core.List<GoogleCloudRunV1Condition>? conditions;

  /// The name of the route that the mapping currently points to.
  core.String? mappedRouteName;

  /// ObservedGeneration is the 'Generation' of the DomainMapping that was last
  /// processed by the controller.
  ///
  /// Clients polling for completed reconciliation should poll until
  /// observedGeneration = metadata.generation and the Ready condition's status
  /// is True or False.
  core.int? observedGeneration;

  /// The resource records required to configure this domain mapping.
  ///
  /// These records must be added to the domain's DNS configuration in order to
  /// serve the application via this domain mapping.
  core.List<ResourceRecord>? resourceRecords;

  /// Cloud Run fully managed: not supported Cloud Run on GKE: supported Holds
  /// the URL that will serve the traffic of the DomainMapping.
  ///
  /// +optional
  core.String? url;

  DomainMappingStatus();

  DomainMappingStatus.fromJson(core.Map _json) {
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<GoogleCloudRunV1Condition>((value) =>
              GoogleCloudRunV1Condition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mappedRouteName')) {
      mappedRouteName = _json['mappedRouteName'] as core.String;
    }
    if (_json.containsKey('observedGeneration')) {
      observedGeneration = _json['observedGeneration'] as core.int;
    }
    if (_json.containsKey('resourceRecords')) {
      resourceRecords = (_json['resourceRecords'] as core.List)
          .map<ResourceRecord>((value) => ResourceRecord.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (mappedRouteName != null) 'mappedRouteName': mappedRouteName!,
        if (observedGeneration != null)
          'observedGeneration': observedGeneration!,
        if (resourceRecords != null)
          'resourceRecords':
              resourceRecords!.map((value) => value.toJson()).toList(),
        if (url != null) 'url': url!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// EnvFromSource represents the source of a set of ConfigMaps
class EnvFromSource {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported The ConfigMap to select from
  ConfigMapEnvSource? configMapRef;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported An optional identifier to prepend to each key in the ConfigMap.
  ///
  /// Must be a C_IDENTIFIER.
  core.String? prefix;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported The Secret to select from
  SecretEnvSource? secretRef;

  EnvFromSource();

  EnvFromSource.fromJson(core.Map _json) {
    if (_json.containsKey('configMapRef')) {
      configMapRef = ConfigMapEnvSource.fromJson(
          _json['configMapRef'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('prefix')) {
      prefix = _json['prefix'] as core.String;
    }
    if (_json.containsKey('secretRef')) {
      secretRef = SecretEnvSource.fromJson(
          _json['secretRef'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configMapRef != null) 'configMapRef': configMapRef!.toJson(),
        if (prefix != null) 'prefix': prefix!,
        if (secretRef != null) 'secretRef': secretRef!.toJson(),
      };
}

/// EnvVar represents an environment variable present in a Container.
class EnvVar {
  /// Name of the environment variable.
  ///
  /// Must be a C_IDENTIFIER.
  core.String? name;

  /// (Optional) Variable references $(VAR_NAME) are expanded using the previous
  /// defined environment variables in the container and any route environment
  /// variables.
  ///
  /// If a variable cannot be resolved, the reference in the input string will
  /// be unchanged. The $(VAR_NAME) syntax can be escaped with a double $$, ie:
  /// $$(VAR_NAME). Escaped references will never be expanded, regardless of
  /// whether the variable exists or not. Defaults to "".
  core.String? value;

  /// (Optional) Cloud Run fully managed: supported Source for the environment
  /// variable's value.
  ///
  /// Only supports secret_key_ref. Cloud Run for Anthos: supported Source for
  /// the environment variable's value. Cannot be used if value is not empty.
  EnvVarSource? valueFrom;

  EnvVar();

  EnvVar.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
    if (_json.containsKey('valueFrom')) {
      valueFrom = EnvVarSource.fromJson(
          _json['valueFrom'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
        if (valueFrom != null) 'valueFrom': valueFrom!.toJson(),
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// EnvVarSource represents a source for the value of an EnvVar.
class EnvVarSource {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Selects a key of a ConfigMap.
  ConfigMapKeySelector? configMapKeyRef;

  /// (Optional) Cloud Run fully managed: supported.
  ///
  /// Selects a key (version) of a secret in Secret Manager. Cloud Run for
  /// Anthos: supported. Selects a key of a secret in the pod's namespace.
  SecretKeySelector? secretKeyRef;

  EnvVarSource();

  EnvVarSource.fromJson(core.Map _json) {
    if (_json.containsKey('configMapKeyRef')) {
      configMapKeyRef = ConfigMapKeySelector.fromJson(
          _json['configMapKeyRef'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('secretKeyRef')) {
      secretKeyRef = SecretKeySelector.fromJson(
          _json['secretKeyRef'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configMapKeyRef != null)
          'configMapKeyRef': configMapKeyRef!.toJson(),
        if (secretKeyRef != null) 'secretKeyRef': secretKeyRef!.toJson(),
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// ExecAction describes a "run in container" action.
class ExecAction {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Command is the command line to execute inside the container, the
  /// working directory for the command is root ('/') in the container's
  /// filesystem.
  ///
  /// The command is simply exec'd, it is not run inside a shell, so traditional
  /// shell instructions ('|', etc) won't work. To use a shell, you need to
  /// explicitly call out to that shell. Exit status of 0 is treated as
  /// live/healthy and non-zero is unhealthy.
  core.List<core.String>? command;

  ExecAction();

  ExecAction.fromJson(core.Map _json) {
    if (_json.containsKey('command')) {
      command = (_json['command'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (command != null) 'command': command!,
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

/// Condition defines a generic condition for a Resource
class GoogleCloudRunV1Condition {
  /// Last time the condition transitioned from one status to another.
  ///
  /// Optional.
  core.String? lastTransitionTime;

  /// Human readable message indicating details about the current status.
  ///
  /// Optional.
  core.String? message;

  /// One-word CamelCase reason for the condition's last transition.
  ///
  /// Optional.
  core.String? reason;

  /// How to interpret failures of this condition, one of Error, Warning, Info
  ///
  /// Optional.
  core.String? severity;

  /// Status of the condition, one of True, False, Unknown.
  core.String? status;

  /// type is used to communicate the status of the reconciliation process.
  ///
  /// See also:
  /// https://github.com/knative/serving/blob/master/docs/spec/errors.md#error-conditions-and-reporting
  /// Types common to all resources include: * "Ready": True when the Resource
  /// is ready.
  core.String? type;

  GoogleCloudRunV1Condition();

  GoogleCloudRunV1Condition.fromJson(core.Map _json) {
    if (_json.containsKey('lastTransitionTime')) {
      lastTransitionTime = _json['lastTransitionTime'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastTransitionTime != null)
          'lastTransitionTime': lastTransitionTime!,
        if (message != null) 'message': message!,
        if (reason != null) 'reason': reason!,
        if (severity != null) 'severity': severity!,
        if (status != null) 'status': status!,
        if (type != null) 'type': type!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// HTTPGetAction describes an action based on HTTP Get requests.
class HTTPGetAction {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Host name to connect to, defaults to the pod IP.
  ///
  /// You probably want to set "Host" in httpHeaders instead.
  core.String? host;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Custom headers to set in the request.
  ///
  /// HTTP allows repeated headers.
  core.List<HTTPHeader>? httpHeaders;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Path to access on the HTTP server.
  core.String? path;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Scheme to use for connecting to the host.
  ///
  /// Defaults to HTTP.
  core.String? scheme;

  HTTPGetAction();

  HTTPGetAction.fromJson(core.Map _json) {
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
    }
    if (_json.containsKey('httpHeaders')) {
      httpHeaders = (_json['httpHeaders'] as core.List)
          .map<HTTPHeader>((value) =>
              HTTPHeader.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
    if (_json.containsKey('scheme')) {
      scheme = _json['scheme'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (host != null) 'host': host!,
        if (httpHeaders != null)
          'httpHeaders': httpHeaders!.map((value) => value.toJson()).toList(),
        if (path != null) 'path': path!,
        if (scheme != null) 'scheme': scheme!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// HTTPHeader describes a custom header to be used in HTTP probes
class HTTPHeader {
  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported The
  /// header field name
  core.String? name;

  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported The
  /// header field value
  core.String? value;

  HTTPHeader();

  HTTPHeader.fromJson(core.Map _json) {
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

/// Cloud Run fully managed: supported Cloud Run for Anthos: supported Maps a
/// string key to a path within a volume.
class KeyToPath {
  /// Cloud Run fully managed: supported The Cloud Secret Manager secret
  /// version.
  ///
  /// Can be 'latest' for the latest value or an integer for a specific version.
  /// Cloud Run for Anthos: supported The key to project.
  core.String? key;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Mode bits to use on this file, must be a value between 0000 and
  /// 0777.
  ///
  /// If not specified, the volume defaultMode will be used. This might be in
  /// conflict with other options that affect the file mode, like fsGroup, and
  /// the result can be other mode bits set.
  core.int? mode;

  /// Cloud Run fully managed: supported Cloud Run for Anthos: supported The
  /// relative path of the file to map the key to.
  ///
  /// May not be an absolute path. May not contain the path element '..'. May
  /// not start with the string '..'.
  core.String? path;

  KeyToPath();

  KeyToPath.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.int;
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (mode != null) 'mode': mode!,
        if (path != null) 'path': path!,
      };
}

/// A list of Authorized Domains.
class ListAuthorizedDomainsResponse {
  /// The authorized domains belonging to the user.
  core.List<AuthorizedDomain>? domains;

  /// Continuation token for fetching the next page of results.
  core.String? nextPageToken;

  ListAuthorizedDomainsResponse();

  ListAuthorizedDomainsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('domains')) {
      domains = (_json['domains'] as core.List)
          .map<AuthorizedDomain>((value) => AuthorizedDomain.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domains != null)
          'domains': domains!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// ListConfigurationsResponse is a list of Configuration resources.
class ListConfigurationsResponse {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// List of Configurations.
  core.List<Configuration>? items;

  /// The kind of this resource, in this case "ConfigurationList".
  core.String? kind;

  /// Metadata associated with this Configuration list.
  ListMeta? metadata;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListConfigurationsResponse();

  ListConfigurationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Configuration>((value) => Configuration.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ListMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// ListDomainMappingsResponse is a list of DomainMapping resources.
class ListDomainMappingsResponse {
  /// The API version for this call such as "domains.cloudrun.com/v1".
  core.String? apiVersion;

  /// List of DomainMappings.
  core.List<DomainMapping>? items;

  /// The kind of this resource, in this case "DomainMappingList".
  core.String? kind;

  /// Metadata associated with this DomainMapping list.
  ListMeta? metadata;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListDomainMappingsResponse();

  ListDomainMappingsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<DomainMapping>((value) => DomainMapping.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ListMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
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

/// ListMeta describes metadata that synthetic resources must have, including
/// lists and various status objects.
///
/// A resource may have only one of {ObjectMeta, ListMeta}.
class ListMeta {
  /// continue may be set if the user set a limit on the number of items
  /// returned, and indicates that the server has more data available.
  ///
  /// The value is opaque and may be used to issue another request to the
  /// endpoint that served this list to retrieve the next set of available
  /// objects. Continuing a list may not be possible if the server configuration
  /// has changed or more than a few minutes have passed. The resourceVersion
  /// field returned when using this continue value will be identical to the
  /// value in the first response.
  core.String? continue_;

  /// String that identifies the server's internal version of this object that
  /// can be used by clients to determine when objects have changed.
  ///
  /// Value must be treated as opaque by clients and passed unmodified back to
  /// the server. Populated by the system. Read-only. More info:
  /// https://git.k8s.io/community/contributors/devel/api-conventions.md#concurrency-control-and-consistency
  /// +optional
  core.String? resourceVersion;

  /// SelfLink is a URL representing this object.
  ///
  /// Populated by the system. Read-only. +optional
  core.String? selfLink;

  ListMeta();

  ListMeta.fromJson(core.Map _json) {
    if (_json.containsKey('continue')) {
      continue_ = _json['continue'] as core.String;
    }
    if (_json.containsKey('resourceVersion')) {
      resourceVersion = _json['resourceVersion'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (continue_ != null) 'continue': continue_!,
        if (resourceVersion != null) 'resourceVersion': resourceVersion!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// ListRevisionsResponse is a list of Revision resources.
class ListRevisionsResponse {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// List of Revisions.
  core.List<Revision>? items;

  /// The kind of this resource, in this case "RevisionList".
  core.String? kind;

  /// Metadata associated with this revision list.
  ListMeta? metadata;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListRevisionsResponse();

  ListRevisionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Revision>((value) =>
              Revision.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ListMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// ListRoutesResponse is a list of Route resources.
class ListRoutesResponse {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// List of Routes.
  core.List<Route>? items;

  /// The kind of this resource, in this case always "RouteList".
  core.String? kind;

  /// Metadata associated with this Route list.
  ListMeta? metadata;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListRoutesResponse();

  ListRoutesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Route>((value) =>
              Route.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ListMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// A list of Service resources.
class ListServicesResponse {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// List of Services.
  core.List<Service>? items;

  /// The kind of this resource, in this case "ServiceList".
  core.String? kind;

  /// Metadata associated with this Service list.
  ListMeta? metadata;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListServicesResponse();

  ListServicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Service>((value) =>
              Service.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ListMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unreachable')) {
      unreachable = (_json['unreachable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (unreachable != null) 'unreachable': unreachable!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// LocalObjectReference contains enough information to let you locate the
/// referenced object inside the same namespace.
class LocalObjectReference {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Name of the referent.
  ///
  /// More info:
  /// https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
  core.String? name;

  LocalObjectReference();

  LocalObjectReference.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
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

/// k8s.io.apimachinery.pkg.apis.meta.v1.ObjectMeta is metadata that all
/// persisted resources must have, which includes all objects users must create.
class ObjectMeta {
  /// (Optional) Annotations is an unstructured key value map stored with a
  /// resource that may be set by external tools to store and retrieve arbitrary
  /// metadata.
  ///
  /// They are not queryable and should be preserved when modifying objects.
  /// More info: http://kubernetes.io/docs/user-guide/annotations
  core.Map<core.String, core.String>? annotations;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported The name of the cluster which the object belongs to.
  ///
  /// This is used to distinguish resources with same name and namespace in
  /// different clusters. This field is not set anywhere right now and apiserver
  /// is going to ignore it if set in create or update request.
  core.String? clusterName;

  /// (Optional) CreationTimestamp is a timestamp representing the server time
  /// when this object was created.
  ///
  /// It is not guaranteed to be set in happens-before order across separate
  /// operations. Clients may not set this value. It is represented in RFC3339
  /// form and is in UTC. Populated by the system. Read-only. Null for lists.
  /// More info:
  /// https://git.k8s.io/community/contributors/devel/api-conventions.md#metadata
  core.String? creationTimestamp;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Number of seconds allowed for this object to gracefully
  /// terminate before it will be removed from the system.
  ///
  /// Only set when deletionTimestamp is also set. May only be shortened.
  /// Read-only.
  core.int? deletionGracePeriodSeconds;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported DeletionTimestamp is RFC 3339 date and time at which this
  /// resource will be deleted.
  ///
  /// This field is set by the server when a graceful deletion is requested by
  /// the user, and is not directly settable by a client. The resource is
  /// expected to be deleted (no longer visible from resource lists, and not
  /// reachable by name) after the time in this field, once the finalizers list
  /// is empty. As long as the finalizers list contains items, deletion is
  /// blocked. Once the deletionTimestamp is set, this value may not be unset or
  /// be set further into the future, although it may be shortened or the
  /// resource may be deleted prior to this time. For example, a user may
  /// request that a pod is deleted in 30 seconds. The Kubelet will react by
  /// sending a graceful termination signal to the containers in the pod. After
  /// that 30 seconds, the Kubelet will send a hard termination signal (SIGKILL)
  /// to the container and after cleanup, remove the pod from the API. In the
  /// presence of network partitions, this object may still exist after this
  /// timestamp, until an administrator or automated process can determine the
  /// resource is fully terminated. If not set, graceful deletion of the object
  /// has not been requested. Populated by the system when a graceful deletion
  /// is requested. Read-only. More info:
  /// https://git.k8s.io/community/contributors/devel/api-conventions.md#metadata
  core.String? deletionTimestamp;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Must be empty before the object is deleted from the registry.
  ///
  /// Each entry is an identifier for the responsible component that will remove
  /// the entry from the list. If the deletionTimestamp of the object is
  /// non-nil, entries in this list can only be removed. +patchStrategy=merge
  core.List<core.String>? finalizers;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported GenerateName is an optional prefix, used by the server, to
  /// generate a unique name ONLY IF the Name field has not been provided.
  ///
  /// If this field is used, the name returned to the client will be different
  /// than the name passed. This value will also be combined with a unique
  /// suffix. The provided value has the same validation rules as the Name
  /// field, and may be truncated by the length of the suffix required to make
  /// the value unique on the server. If this field is specified and the
  /// generated name exists, the server will NOT return a 409 - instead, it will
  /// either return 201 Created or 500 with Reason ServerTimeout indicating a
  /// unique name could not be found in the time allotted, and the client should
  /// retry (optionally after the time indicated in the Retry-After header).
  /// Applied only if Name is not specified. More info:
  /// https://git.k8s.io/community/contributors/devel/api-conventions.md#idempotency
  /// string generateName = 2;
  core.String? generateName;

  /// (Optional) A sequence number representing a specific generation of the
  /// desired state.
  ///
  /// Populated by the system. Read-only.
  core.int? generation;

  /// (Optional) Map of string keys and values that can be used to organize and
  /// categorize (scope and select) objects.
  ///
  /// May match selectors of replication controllers and routes. More info:
  /// http://kubernetes.io/docs/user-guide/labels
  core.Map<core.String, core.String>? labels;

  /// Name must be unique within a namespace, within a Cloud Run region.
  ///
  /// Is required when creating resources, although some resources may allow a
  /// client to request the generation of an appropriate name automatically.
  /// Name is primarily intended for creation idempotence and configuration
  /// definition. Cannot be updated. More info:
  /// http://kubernetes.io/docs/user-guide/identifiers#names +optional
  core.String? name;

  /// Namespace defines the space within each name must be unique, within a
  /// Cloud Run region.
  ///
  /// In Cloud Run the namespace must be equal to either the project ID or
  /// project number.
  core.String? namespace;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported List of objects that own this object.
  ///
  /// If ALL objects in the list have been deleted, this object will be garbage
  /// collected.
  core.List<OwnerReference>? ownerReferences;

  /// An opaque value that represents the internal version of this object that
  /// can be used by clients to determine when objects have changed.
  ///
  /// May be used for optimistic concurrency, change detection, and the watch
  /// operation on a resource or set of resources. Clients must treat these
  /// values as opaque and passed unmodified back to the server or omit the
  /// value to disable conflict-detection. They may only be valid for a
  /// particular resource or set of resources. Populated by the system.
  /// Read-only. Value must be treated as opaque by clients or omitted. More
  /// info:
  /// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency
  ///
  /// Optional.
  core.String? resourceVersion;

  /// (Optional) SelfLink is a URL representing this object.
  ///
  /// Populated by the system. Read-only. string selfLink = 4;
  core.String? selfLink;

  /// (Optional) UID is the unique in time and space value for this object.
  ///
  /// It is typically generated by the server on successful creation of a
  /// resource and is not allowed to change on PUT operations. Populated by the
  /// system. Read-only. More info:
  /// http://kubernetes.io/docs/user-guide/identifiers#uids
  core.String? uid;

  ObjectMeta();

  ObjectMeta.fromJson(core.Map _json) {
    if (_json.containsKey('annotations')) {
      annotations =
          (_json['annotations'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('clusterName')) {
      clusterName = _json['clusterName'] as core.String;
    }
    if (_json.containsKey('creationTimestamp')) {
      creationTimestamp = _json['creationTimestamp'] as core.String;
    }
    if (_json.containsKey('deletionGracePeriodSeconds')) {
      deletionGracePeriodSeconds =
          _json['deletionGracePeriodSeconds'] as core.int;
    }
    if (_json.containsKey('deletionTimestamp')) {
      deletionTimestamp = _json['deletionTimestamp'] as core.String;
    }
    if (_json.containsKey('finalizers')) {
      finalizers = (_json['finalizers'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('generateName')) {
      generateName = _json['generateName'] as core.String;
    }
    if (_json.containsKey('generation')) {
      generation = _json['generation'] as core.int;
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
    if (_json.containsKey('namespace')) {
      namespace = _json['namespace'] as core.String;
    }
    if (_json.containsKey('ownerReferences')) {
      ownerReferences = (_json['ownerReferences'] as core.List)
          .map<OwnerReference>((value) => OwnerReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resourceVersion')) {
      resourceVersion = _json['resourceVersion'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotations != null) 'annotations': annotations!,
        if (clusterName != null) 'clusterName': clusterName!,
        if (creationTimestamp != null) 'creationTimestamp': creationTimestamp!,
        if (deletionGracePeriodSeconds != null)
          'deletionGracePeriodSeconds': deletionGracePeriodSeconds!,
        if (deletionTimestamp != null) 'deletionTimestamp': deletionTimestamp!,
        if (finalizers != null) 'finalizers': finalizers!,
        if (generateName != null) 'generateName': generateName!,
        if (generation != null) 'generation': generation!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (namespace != null) 'namespace': namespace!,
        if (ownerReferences != null)
          'ownerReferences':
              ownerReferences!.map((value) => value.toJson()).toList(),
        if (resourceVersion != null) 'resourceVersion': resourceVersion!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (uid != null) 'uid': uid!,
      };
}

/// OwnerReference contains enough information to let you identify an owning
/// object.
///
/// Currently, an owning object must be in the same namespace, so there is no
/// namespace field.
class OwnerReference {
  /// API version of the referent.
  core.String? apiVersion;

  /// If true, AND if the owner has the "foregroundDeletion" finalizer, then the
  /// owner cannot be deleted from the key-value store until this reference is
  /// removed.
  ///
  /// Defaults to false. To set this field, a user needs "delete" permission of
  /// the owner, otherwise 422 (Unprocessable Entity) will be returned.
  /// +optional
  core.bool? blockOwnerDeletion;

  /// If true, this reference points to the managing controller.
  ///
  /// +optional
  core.bool? controller;

  /// Kind of the referent.
  ///
  /// More info:
  /// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
  core.String? kind;

  /// Name of the referent.
  ///
  /// More info: http://kubernetes.io/docs/user-guide/identifiers#names
  core.String? name;

  /// UID of the referent.
  ///
  /// More info: http://kubernetes.io/docs/user-guide/identifiers#uids
  core.String? uid;

  OwnerReference();

  OwnerReference.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('blockOwnerDeletion')) {
      blockOwnerDeletion = _json['blockOwnerDeletion'] as core.bool;
    }
    if (_json.containsKey('controller')) {
      controller = _json['controller'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (blockOwnerDeletion != null)
          'blockOwnerDeletion': blockOwnerDeletion!,
        if (controller != null) 'controller': controller!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (uid != null) 'uid': uid!,
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

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported Probe
/// describes a health check to be performed against a container to determine
/// whether it is alive or ready to receive traffic.
class Probe {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported One and only one of the following should be specified.
  ///
  /// Exec specifies the action to take. A field inlined from the Handler
  /// message.
  ExecAction? exec;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Minimum consecutive failures for the probe to be considered
  /// failed after having succeeded.
  ///
  /// Defaults to 3. Minimum value is 1.
  core.int? failureThreshold;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported HTTPGet specifies the http request to perform.
  ///
  /// A field inlined from the Handler message.
  HTTPGetAction? httpGet;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Number of seconds after the container has started before
  /// liveness probes are initiated.
  ///
  /// More info:
  /// https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
  core.int? initialDelaySeconds;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported How often (in seconds) to perform the probe.
  ///
  /// Default to 10 seconds. Minimum value is 1.
  core.int? periodSeconds;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Minimum consecutive successes for the probe to be considered
  /// successful after having failed.
  ///
  /// Defaults to 1. Must be 1 for liveness. Minimum value is 1.
  core.int? successThreshold;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported TCPSocket specifies an action involving a TCP port.
  ///
  /// TCP hooks not yet supported A field inlined from the Handler message.
  TCPSocketAction? tcpSocket;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Number of seconds after which the probe times out.
  ///
  /// Defaults to 1 second. Minimum value is 1. More info:
  /// https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
  core.int? timeoutSeconds;

  Probe();

  Probe.fromJson(core.Map _json) {
    if (_json.containsKey('exec')) {
      exec = ExecAction.fromJson(
          _json['exec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('failureThreshold')) {
      failureThreshold = _json['failureThreshold'] as core.int;
    }
    if (_json.containsKey('httpGet')) {
      httpGet = HTTPGetAction.fromJson(
          _json['httpGet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('initialDelaySeconds')) {
      initialDelaySeconds = _json['initialDelaySeconds'] as core.int;
    }
    if (_json.containsKey('periodSeconds')) {
      periodSeconds = _json['periodSeconds'] as core.int;
    }
    if (_json.containsKey('successThreshold')) {
      successThreshold = _json['successThreshold'] as core.int;
    }
    if (_json.containsKey('tcpSocket')) {
      tcpSocket = TCPSocketAction.fromJson(
          _json['tcpSocket'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeoutSeconds')) {
      timeoutSeconds = _json['timeoutSeconds'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exec != null) 'exec': exec!.toJson(),
        if (failureThreshold != null) 'failureThreshold': failureThreshold!,
        if (httpGet != null) 'httpGet': httpGet!.toJson(),
        if (initialDelaySeconds != null)
          'initialDelaySeconds': initialDelaySeconds!,
        if (periodSeconds != null) 'periodSeconds': periodSeconds!,
        if (successThreshold != null) 'successThreshold': successThreshold!,
        if (tcpSocket != null) 'tcpSocket': tcpSocket!.toJson(),
        if (timeoutSeconds != null) 'timeoutSeconds': timeoutSeconds!,
      };
}

/// A DNS resource record.
class ResourceRecord {
  /// Relative name of the object affected by this record.
  ///
  /// Only applicable for `CNAME` records. Example: 'www'.
  core.String? name;

  /// Data for this record.
  ///
  /// Values vary by record type, as defined in RFC 1035 (section 5) and RFC
  /// 1034 (section 3.6.1).
  core.String? rrdata;

  /// Resource record type.
  ///
  /// Example: `AAAA`.
  /// Possible string values are:
  /// - "RECORD_TYPE_UNSPECIFIED" : An unknown resource record.
  /// - "A" : An A resource record. Data is an IPv4 address.
  /// - "AAAA" : An AAAA resource record. Data is an IPv6 address.
  /// - "CNAME" : A CNAME resource record. Data is a domain name to be aliased.
  core.String? type;

  ResourceRecord();

  ResourceRecord.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('rrdata')) {
      rrdata = _json['rrdata'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (rrdata != null) 'rrdata': rrdata!,
        if (type != null) 'type': type!,
      };
}

/// ResourceRequirements describes the compute resource requirements.
class ResourceRequirements {
  /// (Optional) Cloud Run fully managed: Only memory and CPU are supported.
  ///
  /// Note: The only supported values for CPU are '1', '2', and '4'. Setting 4
  /// CPU requires at least 2Gi of memory. Cloud Run for Anthos: supported
  /// Limits describes the maximum amount of compute resources allowed. The
  /// values of the map is string form of the 'quantity' k8s type:
  /// https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/apimachinery/pkg/api/resource/quantity.go
  core.Map<core.String, core.String>? limits;

  /// (Optional) Cloud Run fully managed: Only memory and CPU are supported.
  ///
  /// Note: The only supported values for CPU are '1' and '2'. Cloud Run for
  /// Anthos: supported Requests describes the minimum amount of compute
  /// resources required. If Requests is omitted for a container, it defaults to
  /// Limits if that is explicitly specified, otherwise to an
  /// implementation-defined value. The values of the map is string form of the
  /// 'quantity' k8s type:
  /// https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/apimachinery/pkg/api/resource/quantity.go
  core.Map<core.String, core.String>? requests;

  ResourceRequirements();

  ResourceRequirements.fromJson(core.Map _json) {
    if (_json.containsKey('limits')) {
      limits = (_json['limits'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('requests')) {
      requests = (_json['requests'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (limits != null) 'limits': limits!,
        if (requests != null) 'requests': requests!,
      };
}

/// Revision is an immutable snapshot of code and configuration.
///
/// A revision references a container image. Revisions are created by updates to
/// a Configuration. See also:
/// https://github.com/knative/serving/blob/master/docs/spec/overview.md#revision
class Revision {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// The kind of this resource, in this case "Revision".
  core.String? kind;

  /// Metadata associated with this Revision, including name, namespace, labels,
  /// and annotations.
  ObjectMeta? metadata;

  /// Spec holds the desired state of the Revision (from the client).
  RevisionSpec? spec;

  /// Status communicates the observed state of the Revision (from the
  /// controller).
  RevisionStatus? status;

  Revision();

  Revision.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ObjectMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spec')) {
      spec = RevisionSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = RevisionStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (spec != null) 'spec': spec!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// RevisionSpec holds the desired state of the Revision (from the client).
class RevisionSpec {
  /// (Optional) ContainerConcurrency specifies the maximum allowed in-flight
  /// (concurrent) requests per container instance of the Revision.
  ///
  /// Cloud Run fully managed: supported, defaults to 80 Cloud Run for Anthos:
  /// supported, defaults to 0, which means concurrency to the application is
  /// not limited, and the system decides the target concurrency for the
  /// autoscaler.
  core.int? containerConcurrency;

  /// Containers holds the single container that defines the unit of execution
  /// for this Revision.
  ///
  /// In the context of a Revision, we disallow a number of fields on this
  /// Container, including: name and lifecycle. In Cloud Run, only a single
  /// container may be provided. The runtime contract is documented here:
  /// https://github.com/knative/serving/blob/master/docs/runtime-contract.md
  core.List<Container>? containers;

  /// Email address of the IAM service account associated with the revision of
  /// the service.
  ///
  /// The service account represents the identity of the running revision, and
  /// determines what permissions the revision has. If not provided, the
  /// revision will use the project's default service account.
  core.String? serviceAccountName;

  /// TimeoutSeconds holds the max duration the instance is allowed for
  /// responding to a request.
  ///
  /// Cloud Run fully managed: defaults to 300 seconds (5 minutes). Maximum
  /// allowed value is 900 seconds (15 minutes). Cloud Run for Anthos: defaults
  /// to 300 seconds (5 minutes). Maximum allowed value is configurable by the
  /// cluster operator.
  core.int? timeoutSeconds;
  core.List<Volume>? volumes;

  RevisionSpec();

  RevisionSpec.fromJson(core.Map _json) {
    if (_json.containsKey('containerConcurrency')) {
      containerConcurrency = _json['containerConcurrency'] as core.int;
    }
    if (_json.containsKey('containers')) {
      containers = (_json['containers'] as core.List)
          .map<Container>((value) =>
              Container.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceAccountName')) {
      serviceAccountName = _json['serviceAccountName'] as core.String;
    }
    if (_json.containsKey('timeoutSeconds')) {
      timeoutSeconds = _json['timeoutSeconds'] as core.int;
    }
    if (_json.containsKey('volumes')) {
      volumes = (_json['volumes'] as core.List)
          .map<Volume>((value) =>
              Volume.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containerConcurrency != null)
          'containerConcurrency': containerConcurrency!,
        if (containers != null)
          'containers': containers!.map((value) => value.toJson()).toList(),
        if (serviceAccountName != null)
          'serviceAccountName': serviceAccountName!,
        if (timeoutSeconds != null) 'timeoutSeconds': timeoutSeconds!,
        if (volumes != null)
          'volumes': volumes!.map((value) => value.toJson()).toList(),
      };
}

/// RevisionStatus communicates the observed state of the Revision (from the
/// controller).
class RevisionStatus {
  /// Conditions communicates information about ongoing/complete reconciliation
  /// processes that bring the "spec" inline with the observed state of the
  /// world.
  ///
  /// As a Revision is being prepared, it will incrementally update conditions.
  /// Revision-specific conditions include: * "ResourcesAvailable": True when
  /// underlying resources have been provisioned. * "ContainerHealthy": True
  /// when the Revision readiness check completes. * "Active": True when the
  /// Revision may receive traffic.
  core.List<GoogleCloudRunV1Condition>? conditions;

  /// ImageDigest holds the resolved digest for the image specified within
  /// .Spec.Container.Image.
  ///
  /// The digest is resolved during the creation of Revision. This field holds
  /// the digest value regardless of whether a tag or digest was originally
  /// specified in the Container object.
  core.String? imageDigest;

  /// Specifies the generated logging url for this particular revision based on
  /// the revision url template specified in the controller's config.
  ///
  /// +optional
  core.String? logUrl;

  /// ObservedGeneration is the 'Generation' of the Revision that was last
  /// processed by the controller.
  ///
  /// Clients polling for completed reconciliation should poll until
  /// observedGeneration = metadata.generation, and the Ready condition's status
  /// is True or False.
  core.int? observedGeneration;

  /// Not currently used by Cloud Run.
  core.String? serviceName;

  RevisionStatus();

  RevisionStatus.fromJson(core.Map _json) {
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<GoogleCloudRunV1Condition>((value) =>
              GoogleCloudRunV1Condition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('imageDigest')) {
      imageDigest = _json['imageDigest'] as core.String;
    }
    if (_json.containsKey('logUrl')) {
      logUrl = _json['logUrl'] as core.String;
    }
    if (_json.containsKey('observedGeneration')) {
      observedGeneration = _json['observedGeneration'] as core.int;
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (imageDigest != null) 'imageDigest': imageDigest!,
        if (logUrl != null) 'logUrl': logUrl!,
        if (observedGeneration != null)
          'observedGeneration': observedGeneration!,
        if (serviceName != null) 'serviceName': serviceName!,
      };
}

/// RevisionTemplateSpec describes the data a revision should have when created
/// from a template.
///
/// Based on:
/// https://github.com/kubernetes/api/blob/e771f807/core/v1/types.go#L3179-L3190
class RevisionTemplate {
  /// Optional metadata for this Revision, including labels and annotations.
  ///
  /// Name will be generated by the Configuration. The following annotation keys
  /// set properties of the created revision: *
  /// `autoscaling.knative.dev/minScale` sets the minimum number of instances. *
  /// `autoscaling.knative.dev/maxScale` sets the maximum number of instances. *
  /// `run.googleapis.com/cloudsql-instances` sets Cloud SQL connections.
  /// Multiple values should be comma separated. *
  /// `run.googleapis.com/vpc-access-connector` sets a Serverless VPC Access
  /// connector. * `run.googleapis.com/vpc-access-egress` sets VPC egress.
  /// Supported values are `all-traffic`, `all` (deprecated), and
  /// `private-ranges-only`. `all-traffic` and `all` provide the same
  /// functionality. `all` is deprecated but will continue to be supported.
  /// Prefer `all-traffic`.
  ObjectMeta? metadata;

  /// RevisionSpec holds the desired state of the Revision (from the client).
  RevisionSpec? spec;

  RevisionTemplate();

  RevisionTemplate.fromJson(core.Map _json) {
    if (_json.containsKey('metadata')) {
      metadata = ObjectMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spec')) {
      spec = RevisionSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (spec != null) 'spec': spec!.toJson(),
      };
}

/// Route is responsible for configuring ingress over a collection of Revisions.
///
/// Some of the Revisions a Route distributes traffic over may be specified by
/// referencing the Configuration responsible for creating them; in these cases
/// the Route is additionally responsible for monitoring the Configuration for
/// "latest ready" revision changes, and smoothly rolling out latest revisions.
/// See also:
/// https://github.com/knative/serving/blob/master/docs/spec/overview.md#route
/// Cloud Run currently supports referencing a single Configuration to
/// automatically deploy the "latest ready" Revision from that Configuration.
class Route {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// The kind of this resource, in this case always "Route".
  core.String? kind;

  /// Metadata associated with this Route, including name, namespace, labels,
  /// and annotations.
  ObjectMeta? metadata;

  /// Spec holds the desired state of the Route (from the client).
  RouteSpec? spec;

  /// Status communicates the observed state of the Route (from the controller).
  RouteStatus? status;

  Route();

  Route.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ObjectMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spec')) {
      spec = RouteSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = RouteStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (spec != null) 'spec': spec!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// RouteSpec holds the desired state of the Route (from the client).
class RouteSpec {
  /// Traffic specifies how to distribute traffic over a collection of Knative
  /// Revisions and Configurations.
  ///
  /// Cloud Run currently supports a single configurationName.
  core.List<TrafficTarget>? traffic;

  RouteSpec();

  RouteSpec.fromJson(core.Map _json) {
    if (_json.containsKey('traffic')) {
      traffic = (_json['traffic'] as core.List)
          .map<TrafficTarget>((value) => TrafficTarget.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (traffic != null)
          'traffic': traffic!.map((value) => value.toJson()).toList(),
      };
}

/// RouteStatus communicates the observed state of the Route (from the
/// controller).
class RouteStatus {
  /// Similar to url, information on where the service is available on HTTP.
  Addressable? address;

  /// Conditions communicates information about ongoing/complete reconciliation
  /// processes that bring the "spec" inline with the observed state of the
  /// world.
  core.List<GoogleCloudRunV1Condition>? conditions;

  /// ObservedGeneration is the 'Generation' of the Route that was last
  /// processed by the controller.
  ///
  /// Clients polling for completed reconciliation should poll until
  /// observedGeneration = metadata.generation and the Ready condition's status
  /// is True or False. Note that providing a trafficTarget that only has a
  /// configurationName will result in a Route that does not increment either
  /// its metadata.generation or its observedGeneration, as new "latest ready"
  /// revisions from the Configuration are processed without an update to the
  /// Route's spec.
  core.int? observedGeneration;

  /// Traffic holds the configured traffic distribution.
  ///
  /// These entries will always contain RevisionName references. When
  /// ConfigurationName appears in the spec, this will hold the
  /// LatestReadyRevisionName that we last observed.
  core.List<TrafficTarget>? traffic;

  /// URL holds the url that will distribute traffic over the provided traffic
  /// targets.
  ///
  /// It generally has the form:
  /// https://{route-hash}-{project-hash}-{cluster-level-suffix}.a.run.app
  core.String? url;

  RouteStatus();

  RouteStatus.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = Addressable.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<GoogleCloudRunV1Condition>((value) =>
              GoogleCloudRunV1Condition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('observedGeneration')) {
      observedGeneration = _json['observedGeneration'] as core.int;
    }
    if (_json.containsKey('traffic')) {
      traffic = (_json['traffic'] as core.List)
          .map<TrafficTarget>((value) => TrafficTarget.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (observedGeneration != null)
          'observedGeneration': observedGeneration!,
        if (traffic != null)
          'traffic': traffic!.map((value) => value.toJson()).toList(),
        if (url != null) 'url': url!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// SecretEnvSource selects a Secret to populate the environment variables with.
///
/// The contents of the target Secret's Data field will represent the key-value
/// pairs as environment variables.
class SecretEnvSource {
  /// This field should not be used directly as it is meant to be inlined
  /// directly into the message.
  ///
  /// Use the "name" field instead.
  LocalObjectReference? localObjectReference;

  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported The
  /// Secret to select from.
  core.String? name;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Specify whether the Secret must be defined
  core.bool? optional;

  SecretEnvSource();

  SecretEnvSource.fromJson(core.Map _json) {
    if (_json.containsKey('localObjectReference')) {
      localObjectReference = LocalObjectReference.fromJson(
          _json['localObjectReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (localObjectReference != null)
          'localObjectReference': localObjectReference!.toJson(),
        if (name != null) 'name': name!,
        if (optional != null) 'optional': optional!,
      };
}

/// Cloud Run fully managed: supported Cloud Run for Anthos: supported
/// SecretKeySelector selects a key of a Secret.
class SecretKeySelector {
  /// Cloud Run fully managed: supported A Cloud Secret Manager secret version.
  ///
  /// Must be 'latest' for the latest version or an integer for a specific
  /// version. Cloud Run for Anthos: supported The key of the secret to select
  /// from. Must be a valid secret key.
  core.String? key;

  /// This field should not be used directly as it is meant to be inlined
  /// directly into the message.
  ///
  /// Use the "name" field instead.
  LocalObjectReference? localObjectReference;

  /// Cloud Run fully managed: supported The name of the secret in Cloud Secret
  /// Manager.
  ///
  /// By default, the secret is assumed to be in the same project. If the secret
  /// is in another project, you must define an alias. An alias definition has
  /// the form: :projects//secrets/. If multiple alias definitions are needed,
  /// they must be separated by commas. The alias definitions must be set on the
  /// run.googleapis.com/secrets annotation. Cloud Run for Anthos: supported The
  /// name of the secret in the pod's namespace to select from.
  core.String? name;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Specify whether the Secret or its key must be defined
  core.bool? optional;

  SecretKeySelector();

  SecretKeySelector.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('localObjectReference')) {
      localObjectReference = LocalObjectReference.fromJson(
          _json['localObjectReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (localObjectReference != null)
          'localObjectReference': localObjectReference!.toJson(),
        if (name != null) 'name': name!,
        if (optional != null) 'optional': optional!,
      };
}

/// Cloud Run fully managed: supported The secret's value will be presented as
/// the content of a file whose name is defined in the item path.
///
/// If no items are defined, the name of the file is the secret_name. Cloud Run
/// for Anthos: supported The contents of the target Secret's Data field will be
/// presented in a volume as files using the keys in the Data field as the file
/// names.
class SecretVolumeSource {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Mode bits to use on created files by default.
  ///
  /// Must be a value between 0000 and 0777. Defaults to 0644. Directories
  /// within the path are not affected by this setting. This might be in
  /// conflict with other options that affect the file mode, like fsGroup, and
  /// the result can be other mode bits set. NOTE: This is an integer
  /// representation of the mode bits. So, the integer value should look exactly
  /// as the chmod numeric notation, i.e. Unix chmod "777" (a=rwx) should have
  /// the integer value 777.
  core.int? defaultMode;

  /// (Optional) Cloud Run fully managed: supported If unspecified, the volume
  /// will expose a file whose name is the secret_name.
  ///
  /// If specified, the key will be used as the version to fetch from Cloud
  /// Secret Manager and the path will be the name of the file exposed in the
  /// volume. When items are defined, they must specify a key and a path. Cloud
  /// Run for Anthos: supported If unspecified, each key-value pair in the Data
  /// field of the referenced Secret will be projected into the volume as a file
  /// whose name is the key and content is the value. If specified, the listed
  /// keys will be projected into the specified paths, and unlisted keys will
  /// not be present. If a key is specified that is not present in the Secret,
  /// the volume setup will error unless it is marked optional.
  core.List<KeyToPath>? items;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Specify whether the Secret or its keys must be defined.
  core.bool? optional;

  /// Cloud Run fully managed: supported The name of the secret in Cloud Secret
  /// Manager.
  ///
  /// By default, the secret is assumed to be in the same project. If the secret
  /// is in another project, you must define an alias. An alias definition has
  /// the form: :projects//secrets/. If multiple alias definitions are needed,
  /// they must be separated by commas. The alias definitions must be set on the
  /// run.googleapis.com/secrets annotation. Cloud Run for Anthos: supported
  /// Name of the secret in the container's namespace to use.
  core.String? secretName;

  SecretVolumeSource();

  SecretVolumeSource.fromJson(core.Map _json) {
    if (_json.containsKey('defaultMode')) {
      defaultMode = _json['defaultMode'] as core.int;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<KeyToPath>((value) =>
              KeyToPath.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
    if (_json.containsKey('secretName')) {
      secretName = _json['secretName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultMode != null) 'defaultMode': defaultMode!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (optional != null) 'optional': optional!,
        if (secretName != null) 'secretName': secretName!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// SecurityContext holds security configuration that will be applied to a
/// container.
///
/// Some fields are present in both SecurityContext and PodSecurityContext. When
/// both are set, the values in SecurityContext take precedence.
class SecurityContext {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported The UID to run the entrypoint of the container process.
  ///
  /// Defaults to user specified in image metadata if unspecified. May also be
  /// set in PodSecurityContext. If set in both SecurityContext and
  /// PodSecurityContext, the value specified in SecurityContext takes
  /// precedence.
  core.int? runAsUser;

  SecurityContext();

  SecurityContext.fromJson(core.Map _json) {
    if (_json.containsKey('runAsUser')) {
      runAsUser = _json['runAsUser'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (runAsUser != null) 'runAsUser': runAsUser!,
      };
}

/// Service acts as a top-level container that manages a set of Routes and
/// Configurations which implement a network service.
///
/// Service exists to provide a singular abstraction which can be access
/// controlled, reasoned about, and which encapsulates software lifecycle
/// decisions such as rollout policy and team resource ownership. Service acts
/// only as an orchestrator of the underlying Routes and Configurations (much as
/// a kubernetes Deployment orchestrates ReplicaSets). The Service's controller
/// will track the statuses of its owned Configuration and Route, reflecting
/// their statuses and conditions as its own. See also:
/// https://github.com/knative/serving/blob/master/docs/spec/overview.md#service
class Service {
  /// The API version for this call such as "serving.knative.dev/v1".
  core.String? apiVersion;

  /// The kind of resource, in this case "Service".
  core.String? kind;

  /// Metadata associated with this Service, including name, namespace, labels,
  /// and annotations.
  ///
  /// Cloud Run (fully managed) uses the following annotation keys to configure
  /// features on a Service: * `run.googleapis.com/ingress` sets the ingress
  /// settings for the Service. See \[the ingress settings
  /// documentation\](/run/docs/securing/ingress) for details on configuring
  /// ingress settings. * `run.googleapis.com/ingress-status` is output-only and
  /// contains the currently active ingress settings for the Service.
  /// `run.googleapis.com/ingress-status` may differ from
  /// `run.googleapis.com/ingress` while the system is processing a change to
  /// `run.googleapis.com/ingress` or if the system failed to process a change
  /// to `run.googleapis.com/ingress`. When the system has processed all changes
  /// successfully `run.googleapis.com/ingress-status` and
  /// `run.googleapis.com/ingress` are equal.
  ObjectMeta? metadata;

  /// Spec holds the desired state of the Service (from the client).
  ServiceSpec? spec;

  /// Status communicates the observed state of the Service (from the
  /// controller).
  ServiceStatus? status;

  Service();

  Service.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ObjectMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spec')) {
      spec = ServiceSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = ServiceStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (spec != null) 'spec': spec!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// ServiceSpec holds the desired state of the Route (from the client), which is
/// used to manipulate the underlying Route and Configuration(s).
class ServiceSpec {
  /// Template holds the latest specification for the Revision to be stamped
  /// out.
  RevisionTemplate? template;

  /// Traffic specifies how to distribute traffic over a collection of Knative
  /// Revisions and Configurations.
  core.List<TrafficTarget>? traffic;

  ServiceSpec();

  ServiceSpec.fromJson(core.Map _json) {
    if (_json.containsKey('template')) {
      template = RevisionTemplate.fromJson(
          _json['template'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('traffic')) {
      traffic = (_json['traffic'] as core.List)
          .map<TrafficTarget>((value) => TrafficTarget.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (template != null) 'template': template!.toJson(),
        if (traffic != null)
          'traffic': traffic!.map((value) => value.toJson()).toList(),
      };
}

/// The current state of the Service.
///
/// Output only.
class ServiceStatus {
  /// From RouteStatus.
  ///
  /// Similar to url, information on where the service is available on HTTP.
  Addressable? address;

  /// Conditions communicates information about ongoing/complete reconciliation
  /// processes that bring the "spec" inline with the observed state of the
  /// world.
  ///
  /// Service-specific conditions include: * "ConfigurationsReady": true when
  /// the underlying Configuration is ready. * "RoutesReady": true when the
  /// underlying Route is ready. * "Ready": true when both the underlying Route
  /// and Configuration are ready.
  core.List<GoogleCloudRunV1Condition>? conditions;

  /// From ConfigurationStatus.
  ///
  /// LatestCreatedRevisionName is the last revision that was created from this
  /// Service's Configuration. It might not be ready yet, for that use
  /// LatestReadyRevisionName.
  core.String? latestCreatedRevisionName;

  /// From ConfigurationStatus.
  ///
  /// LatestReadyRevisionName holds the name of the latest Revision stamped out
  /// from this Service's Configuration that has had its "Ready" condition
  /// become "True".
  core.String? latestReadyRevisionName;

  /// ObservedGeneration is the 'Generation' of the Route that was last
  /// processed by the controller.
  ///
  /// Clients polling for completed reconciliation should poll until
  /// observedGeneration = metadata.generation and the Ready condition's status
  /// is True or False.
  core.int? observedGeneration;

  /// From RouteStatus.
  ///
  /// Traffic holds the configured traffic distribution. These entries will
  /// always contain RevisionName references. When ConfigurationName appears in
  /// the spec, this will hold the LatestReadyRevisionName that we last
  /// observed.
  core.List<TrafficTarget>? traffic;

  /// From RouteStatus.
  ///
  /// URL holds the url that will distribute traffic over the provided traffic
  /// targets. It generally has the form
  /// https://{route-hash}-{project-hash}-{cluster-level-suffix}.a.run.app
  core.String? url;

  ServiceStatus();

  ServiceStatus.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = Addressable.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<GoogleCloudRunV1Condition>((value) =>
              GoogleCloudRunV1Condition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('latestCreatedRevisionName')) {
      latestCreatedRevisionName =
          _json['latestCreatedRevisionName'] as core.String;
    }
    if (_json.containsKey('latestReadyRevisionName')) {
      latestReadyRevisionName = _json['latestReadyRevisionName'] as core.String;
    }
    if (_json.containsKey('observedGeneration')) {
      observedGeneration = _json['observedGeneration'] as core.int;
    }
    if (_json.containsKey('traffic')) {
      traffic = (_json['traffic'] as core.List)
          .map<TrafficTarget>((value) => TrafficTarget.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (latestCreatedRevisionName != null)
          'latestCreatedRevisionName': latestCreatedRevisionName!,
        if (latestReadyRevisionName != null)
          'latestReadyRevisionName': latestReadyRevisionName!,
        if (observedGeneration != null)
          'observedGeneration': observedGeneration!,
        if (traffic != null)
          'traffic': traffic!.map((value) => value.toJson()).toList(),
        if (url != null) 'url': url!,
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

/// Status is a return value for calls that don't return other objects
class Status {
  /// Suggested HTTP return code for this status, 0 if not set.
  ///
  /// +optional
  core.int? code;

  /// Extended data associated with the reason.
  ///
  /// Each reason may define its own extended details. This field is optional
  /// and the data returned is not guaranteed to conform to any schema except
  /// that defined by the reason type. +optional
  StatusDetails? details;

  /// A human-readable description of the status of this operation.
  ///
  /// +optional
  core.String? message;

  /// Standard list metadata.
  ///
  /// More info:
  /// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
  /// +optional
  ListMeta? metadata;

  /// A machine-readable description of why this operation is in the "Failure"
  /// status.
  ///
  /// If this value is empty there is no information available. A Reason
  /// clarifies an HTTP status code but does not override it. +optional
  core.String? reason;

  /// Status of the operation.
  ///
  /// One of: "Success" or "Failure". More info:
  /// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status
  /// +optional
  core.String? status;

  Status();

  Status.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.int;
    }
    if (_json.containsKey('details')) {
      details = StatusDetails.fromJson(
          _json['details'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ListMeta.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (details != null) 'details': details!.toJson(),
        if (message != null) 'message': message!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (reason != null) 'reason': reason!,
        if (status != null) 'status': status!,
      };
}

/// StatusCause provides more information about an api.Status failure, including
/// cases when multiple errors are encountered.
class StatusCause {
  /// The field of the resource that has caused this error, as named by its JSON
  /// serialization.
  ///
  /// May include dot and postfix notation for nested attributes. Arrays are
  /// zero-indexed. Fields may appear more than once in an array of causes due
  /// to fields having multiple errors. Optional. Examples: "name" - the field
  /// "name" on the current resource "items\[0\].name" - the field "name" on the
  /// first array entry in "items" +optional
  core.String? field;

  /// A human-readable description of the cause of the error.
  ///
  /// This field may be presented as-is to a reader. +optional
  core.String? message;

  /// A machine-readable description of the cause of the error.
  ///
  /// If this value is empty there is no information available. +optional
  core.String? reason;

  StatusCause();

  StatusCause.fromJson(core.Map _json) {
    if (_json.containsKey('field')) {
      field = _json['field'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (field != null) 'field': field!,
        if (message != null) 'message': message!,
        if (reason != null) 'reason': reason!,
      };
}

/// StatusDetails is a set of additional properties that MAY be set by the
/// server to provide additional information about a response.
///
/// The Reason field of a Status object defines what attributes will be set.
/// Clients must ignore fields that do not match the defined type of each
/// attribute, and should assume that any attribute may be empty, invalid, or
/// under defined.
class StatusDetails {
  /// The Causes array includes more details associated with the StatusReason
  /// failure.
  ///
  /// Not all StatusReasons may provide detailed causes. +optional
  core.List<StatusCause>? causes;

  /// The group attribute of the resource associated with the status
  /// StatusReason.
  ///
  /// +optional
  core.String? group;

  /// The kind attribute of the resource associated with the status
  /// StatusReason.
  ///
  /// On some operations may differ from the requested resource Kind. More info:
  /// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
  /// +optional
  core.String? kind;

  /// The name attribute of the resource associated with the status StatusReason
  /// (when there is a single name which can be described).
  ///
  /// +optional
  core.String? name;

  /// If specified, the time in seconds before the operation should be retried.
  ///
  /// Some errors may indicate the client must take an alternate action - for
  /// those errors this field may indicate how long to wait before taking the
  /// alternate action. +optional
  core.int? retryAfterSeconds;

  /// UID of the resource.
  ///
  /// (when there is a single resource which can be described). More info:
  /// http://kubernetes.io/docs/user-guide/identifiers#uids +optional
  core.String? uid;

  StatusDetails();

  StatusDetails.fromJson(core.Map _json) {
    if (_json.containsKey('causes')) {
      causes = (_json['causes'] as core.List)
          .map<StatusCause>((value) => StatusCause.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('group')) {
      group = _json['group'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('retryAfterSeconds')) {
      retryAfterSeconds = _json['retryAfterSeconds'] as core.int;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (causes != null)
          'causes': causes!.map((value) => value.toJson()).toList(),
        if (group != null) 'group': group!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (retryAfterSeconds != null) 'retryAfterSeconds': retryAfterSeconds!,
        if (uid != null) 'uid': uid!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// TCPSocketAction describes an action based on opening a socket
class TCPSocketAction {
  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Optional: Host name to connect to, defaults to the pod IP.
  core.String? host;

  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
  /// Number or name of the port to access on the container.
  ///
  /// Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.
  /// This field is currently limited to integer types only because of proto's
  /// inability to properly support the IntOrString golang type.
  core.int? port;

  TCPSocketAction();

  TCPSocketAction.fromJson(core.Map _json) {
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (host != null) 'host': host!,
        if (port != null) 'port': port!,
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

/// TrafficTarget holds a single entry of the routing table for a Route.
class TrafficTarget {
  /// ConfigurationName of a configuration to whose latest revision we will send
  /// this portion of traffic.
  ///
  /// When the "status.latestReadyRevisionName" of the referenced configuration
  /// changes, we will automatically migrate traffic from the prior "latest
  /// ready" revision to the new one. This field is never set in Route's status,
  /// only its spec. This is mutually exclusive with RevisionName. Cloud Run
  /// currently supports a single ConfigurationName.
  core.String? configurationName;

  /// LatestRevision may be optionally provided to indicate that the latest
  /// ready Revision of the Configuration should be used for this traffic
  /// target.
  ///
  /// When provided LatestRevision must be true if RevisionName is empty; it
  /// must be false when RevisionName is non-empty. +optional
  core.bool? latestRevision;

  /// Percent specifies percent of the traffic to this Revision or
  /// Configuration.
  ///
  /// This defaults to zero if unspecified. Cloud Run currently requires 100
  /// percent for a single ConfigurationName TrafficTarget entry.
  core.int? percent;

  /// RevisionName of a specific revision to which to send this portion of
  /// traffic.
  ///
  /// This is mutually exclusive with ConfigurationName. Providing RevisionName
  /// in spec is not currently supported by Cloud Run.
  core.String? revisionName;

  /// Tag is optionally used to expose a dedicated url for referencing this
  /// target exclusively.
  ///
  /// +optional
  core.String? tag;

  /// URL displays the URL for accessing tagged traffic targets.
  ///
  /// URL is displayed in status, and is disallowed on spec. URL must contain a
  /// scheme (e.g. http://) and a hostname, but may not contain anything else
  /// (e.g. basic auth, url path, etc.)
  ///
  /// Output only.
  core.String? url;

  TrafficTarget();

  TrafficTarget.fromJson(core.Map _json) {
    if (_json.containsKey('configurationName')) {
      configurationName = _json['configurationName'] as core.String;
    }
    if (_json.containsKey('latestRevision')) {
      latestRevision = _json['latestRevision'] as core.bool;
    }
    if (_json.containsKey('percent')) {
      percent = _json['percent'] as core.int;
    }
    if (_json.containsKey('revisionName')) {
      revisionName = _json['revisionName'] as core.String;
    }
    if (_json.containsKey('tag')) {
      tag = _json['tag'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configurationName != null) 'configurationName': configurationName!,
        if (latestRevision != null) 'latestRevision': latestRevision!,
        if (percent != null) 'percent': percent!,
        if (revisionName != null) 'revisionName': revisionName!,
        if (tag != null) 'tag': tag!,
        if (url != null) 'url': url!,
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// Volume represents a named volume in a container.
class Volume {
  /// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
  ConfigMapVolumeSource? configMap;

  /// Cloud Run fully managed: supported Cloud Run for Anthos: supported
  /// Volume's name.
  core.String? name;

  /// Cloud Run fully managed: supported Cloud Run for Anthos: supported
  SecretVolumeSource? secret;

  Volume();

  Volume.fromJson(core.Map _json) {
    if (_json.containsKey('configMap')) {
      configMap = ConfigMapVolumeSource.fromJson(
          _json['configMap'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('secret')) {
      secret = SecretVolumeSource.fromJson(
          _json['secret'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configMap != null) 'configMap': configMap!.toJson(),
        if (name != null) 'name': name!,
        if (secret != null) 'secret': secret!.toJson(),
      };
}

/// Cloud Run fully managed: not supported Cloud Run for Anthos: supported
/// VolumeMount describes a mounting of a Volume within a container.
class VolumeMount {
  /// Cloud Run fully managed: supported Cloud Run for Anthos: supported Path
  /// within the container at which the volume should be mounted.
  ///
  /// Must not contain ':'.
  core.String? mountPath;

  /// Cloud Run fully managed: supported Cloud Run for Anthos: supported This
  /// must match the Name of a Volume.
  core.String? name;

  /// (Optional) Cloud Run fully managed: supported Cloud Run for Anthos:
  /// supported Only true is accepted.
  ///
  /// Defaults to true.
  core.bool? readOnly;

  /// (Optional) Cloud Run fully managed: not supported Cloud Run for Anthos:
  /// supported Path within the volume from which the container's volume should
  /// be mounted.
  ///
  /// Defaults to "" (volume's root).
  core.String? subPath;

  VolumeMount();

  VolumeMount.fromJson(core.Map _json) {
    if (_json.containsKey('mountPath')) {
      mountPath = _json['mountPath'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('readOnly')) {
      readOnly = _json['readOnly'] as core.bool;
    }
    if (_json.containsKey('subPath')) {
      subPath = _json['subPath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mountPath != null) 'mountPath': mountPath!,
        if (name != null) 'name': name!,
        if (readOnly != null) 'readOnly': readOnly!,
        if (subPath != null) 'subPath': subPath!,
      };
}

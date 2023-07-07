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

/// Kubernetes Engine API - v1
///
/// Builds and manages container-based applications, powered by the open source
/// Kubernetes technology.
///
/// For more information, see <https://cloud.google.com/container-engine/>
///
/// Create an instance of [ContainerApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsAggregatedResource]
///     - [ProjectsAggregatedUsableSubnetworksResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsClustersResource]
///       - [ProjectsLocationsClustersNodePoolsResource]
///       - [ProjectsLocationsClustersWellKnownResource]
///     - [ProjectsLocationsOperationsResource]
///   - [ProjectsZonesResource]
///     - [ProjectsZonesClustersResource]
///       - [ProjectsZonesClustersNodePoolsResource]
///     - [ProjectsZonesOperationsResource]
library container.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Builds and manages container-based applications, powered by the open source
/// Kubernetes technology.
class ContainerApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  ContainerApi(http.Client client,
      {core.String rootUrl = 'https://container.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsAggregatedResource get aggregated =>
      ProjectsAggregatedResource(_requester);
  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);
  ProjectsZonesResource get zones => ProjectsZonesResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsAggregatedResource {
  final commons.ApiRequester _requester;

  ProjectsAggregatedUsableSubnetworksResource get usableSubnetworks =>
      ProjectsAggregatedUsableSubnetworksResource(_requester);

  ProjectsAggregatedResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsAggregatedUsableSubnetworksResource {
  final commons.ApiRequester _requester;

  ProjectsAggregatedUsableSubnetworksResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists subnetworks that are usable for creating clusters in a project.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent project where subnetworks are usable. Specified in
  /// the format `projects / * `.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [filter] - Filtering currently only supports equality on the
  /// networkProjectId and must be in the form:
  /// "networkProjectId=\[PROJECTID\]", where `networkProjectId` is the project
  /// which owns the listed subnetworks. This defaults to the parent project ID.
  ///
  /// [pageSize] - The max number of results per page that should be returned.
  /// If the number of available results is larger than `page_size`, a
  /// `next_page_token` is returned which can be used to get the next page of
  /// results in subsequent requests. Acceptable values are 0 to 500, inclusive.
  /// (Default: 500)
  ///
  /// [pageToken] - Specifies a page token to use. Set this to the nextPageToken
  /// returned by previous list requests to get the next page of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListUsableSubnetworksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListUsableSubnetworksResponse> list(
    core.String parent, {
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

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/aggregated/usableSubnetworks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListUsableSubnetworksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsClustersResource get clusters =>
      ProjectsLocationsClustersResource(_requester);
  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;

  /// Returns configuration info about the Google Kubernetes Engine service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project and location) of the server config to get,
  /// specified in the format `projects / * /locations / * `.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) to return
  /// operations for. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ServerConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ServerConfig> getServerConfig(
    core.String name, {
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/serverConfig';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ServerConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsClustersResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsClustersNodePoolsResource get nodePools =>
      ProjectsLocationsClustersNodePoolsResource(_requester);
  ProjectsLocationsClustersWellKnownResource get wellKnown =>
      ProjectsLocationsClustersWellKnownResource(_requester);

  ProjectsLocationsClustersResource(commons.ApiRequester client)
      : _requester = client;

  /// Completes master IP rotation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster id) of the cluster to
  /// complete IP rotation. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> completeIpRotation(
    CompleteIPRotationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':completeIpRotation';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a cluster, consisting of the specified number and type of Google
  /// Compute Engine instances.
  ///
  /// By default, the cluster is created in the project's
  /// [default network](https://cloud.google.com/compute/docs/networks-and-firewalls#networks).
  /// One firewall is added for the cluster. After cluster creation, the Kubelet
  /// creates routes for each node to allow the containers on that node to
  /// communicate with all other instances in the cluster. Finally, an entry is
  /// added to the project's global metadata indicating which CIDR range the
  /// cluster is using.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent (project and location) where the cluster will be
  /// created. Specified in the format `projects / * /locations / * `.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
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
    CreateClusterRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/clusters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the cluster, including the Kubernetes endpoint and all worker
  /// nodes.
  ///
  /// Firewalls and routes that were configured during cluster creation are also
  /// deleted. Other Google Compute Engine resources that might be in use by the
  /// cluster, such as load balancer resources, are not deleted if they weren't
  /// present when the cluster was initially created.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to delete.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to delete. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
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
    core.String? clusterId,
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clusterId != null) 'clusterId': [clusterId],
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
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

  /// Gets the details of a specific cluster.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to retrieve.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to retrieve. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Cluster].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Cluster> get(
    core.String name, {
    core.String? clusterId,
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clusterId != null) 'clusterId': [clusterId],
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Cluster.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the public component of the cluster signing keys in JSON Web Key
  /// format.
  ///
  /// This API is not yet intended for general use, and is not available for all
  /// clusters.
  ///
  /// Request parameters:
  ///
  /// [parent] - The cluster (project, location, cluster id) to get keys for.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetJSONWebKeysResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetJSONWebKeysResponse> getJwks(
    core.String parent, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/jwks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetJSONWebKeysResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all clusters owned by a project in either the specified zone or all
  /// zones.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent (project and location) where the clusters will be
  /// listed. Specified in the format `projects / * /locations / * `. Location
  /// "-" matches all zones and all regions.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides, or "-" for all zones. This field has been deprecated and
  /// replaced by the parent field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListClustersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListClustersResponse> list(
    core.String parent, {
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/clusters';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListClustersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the addons for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to set
  /// addons. Specified in the format `projects / * /locations / * /clusters / *
  /// `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setAddons(
    SetAddonsConfigRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setAddons';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Enables or disables the ABAC authorization mechanism on a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster id) of the cluster to set
  /// legacy abac. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setLegacyAbac(
    SetLegacyAbacRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setLegacyAbac';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the locations for a specific cluster.
  ///
  /// Deprecated. Use
  /// [projects.locations.clusters.update](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.locations.clusters/update)
  /// instead.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to set
  /// locations. Specified in the format `projects / * /locations / * /clusters
  /// / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setLocations(
    SetLocationsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setLocations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the logging service for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to set
  /// logging. Specified in the format `projects / * /locations / * /clusters /
  /// * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setLogging(
    SetLoggingServiceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setLogging';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the maintenance policy for a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster id) of the cluster to set
  /// maintenance policy. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setMaintenancePolicy(
    SetMaintenancePolicyRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setMaintenancePolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets master auth materials.
  ///
  /// Currently supports changing the admin password or a specific cluster,
  /// either via password generation or explicitly setting the password.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to set auth.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setMasterAuth(
    SetMasterAuthRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setMasterAuth';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the monitoring service for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to set
  /// monitoring. Specified in the format `projects / * /locations / * /clusters
  /// / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setMonitoring(
    SetMonitoringServiceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setMonitoring';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Enables or disables Network Policy for a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster id) of the cluster to set
  /// networking policy. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setNetworkPolicy(
    SetNetworkPolicyRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setNetworkPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets labels on a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster id) of the cluster to set
  /// labels. Specified in the format `projects / * /locations / * /clusters / *
  /// `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> setResourceLabels(
    SetLabelsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setResourceLabels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Starts master IP rotation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster id) of the cluster to start
  /// IP rotation. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> startIpRotation(
    StartIPRotationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':startIpRotation';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the settings of a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to update.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
    UpdateClusterRequest request,
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the master for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster) of the cluster to update.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
  async.Future<Operation> updateMaster(
    UpdateMasterRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':updateMaster';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsClustersNodePoolsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsClustersNodePoolsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a node pool for a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent (project, location, cluster id) where the node pool
  /// will be created. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
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
    CreateNodePoolRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/nodePools';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a node pool from a cluster.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster, node pool id) of the node
  /// pool to delete. Specified in the format `projects / * /locations / *
  /// /clusters / * /nodePools / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+/nodePools/\[^/\]+$`.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool to delete. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
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
    core.String? clusterId,
    core.String? nodePoolId,
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clusterId != null) 'clusterId': [clusterId],
      if (nodePoolId != null) 'nodePoolId': [nodePoolId],
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
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

  /// Retrieves the requested node pool.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster, node pool id) of the node
  /// pool to get. Specified in the format `projects / * /locations / *
  /// /clusters / * /nodePools / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+/nodePools/\[^/\]+$`.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool. This field has been
  /// deprecated and replaced by the name field.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NodePool].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NodePool> get(
    core.String name, {
    core.String? clusterId,
    core.String? nodePoolId,
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clusterId != null) 'clusterId': [clusterId],
      if (nodePoolId != null) 'nodePoolId': [nodePoolId],
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return NodePool.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the node pools for a cluster.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent (project, location, cluster id) where the node pools
  /// will be listed. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the parent field.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the parent
  /// field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListNodePoolsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListNodePoolsResponse> list(
    core.String parent, {
    core.String? clusterId,
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clusterId != null) 'clusterId': [clusterId],
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/nodePools';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListNodePoolsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Rolls back a previously Aborted or Failed NodePool upgrade.
  ///
  /// This makes no changes if the last upgrade successfully completed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster, node pool id) of the node
  /// poll to rollback upgrade. Specified in the format `projects / * /locations
  /// / * /clusters / * /nodePools / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+/nodePools/\[^/\]+$`.
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
  async.Future<Operation> rollback(
    RollbackNodePoolUpgradeRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':rollback';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the autoscaling settings for the specified node pool.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster, node pool) of the node pool
  /// to set autoscaler settings. Specified in the format `projects / *
  /// /locations / * /clusters / * /nodePools / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+/nodePools/\[^/\]+$`.
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
  async.Future<Operation> setAutoscaling(
    SetNodePoolAutoscalingRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setAutoscaling';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the NodeManagement options for a node pool.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster, node pool id) of the node
  /// pool to set management properties. Specified in the format `projects / *
  /// /locations / * /clusters / * /nodePools / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+/nodePools/\[^/\]+$`.
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
  async.Future<Operation> setManagement(
    SetNodePoolManagementRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setManagement';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the size for a specific node pool.
  ///
  /// The new size will be used for all replicas, including future replicas
  /// created by modifying NodePool.locations.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster, node pool id) of the node
  /// pool to set size. Specified in the format `projects / * /locations / *
  /// /clusters / * /nodePools / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+/nodePools/\[^/\]+$`.
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
  async.Future<Operation> setSize(
    SetNodePoolSizeRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setSize';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the version and/or image type for the specified node pool.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, cluster, node pool) of the node pool
  /// to update. Specified in the format `projects / * /locations / * /clusters
  /// / * /nodePools / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+/nodePools/\[^/\]+$`.
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
    UpdateNodePoolRequest request,
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsClustersWellKnownResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsClustersWellKnownResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the OIDC discovery document for the cluster.
  ///
  /// See the
  /// [OpenID Connect Discovery 1.0 specification](https://openid.net/specs/openid-connect-discovery-1_0.html)
  /// for details. This API is not yet intended for general use, and is not
  /// available for all clusters.
  ///
  /// Request parameters:
  ///
  /// [parent] - The cluster (project, location, cluster id) to get the
  /// discovery document for. Specified in the format `projects / * /locations /
  /// * /clusters / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/clusters/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetOpenIDConfigResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetOpenIDConfigResponse> getOpenidConfiguration(
    core.String parent, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/.well-known/openid-configuration';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetOpenIDConfigResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Cancels the specified operation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, operation id) of the operation to
  /// cancel. Specified in the format `projects / * /locations / * /operations /
  /// * `.
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

  /// Gets the specified operation.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (project, location, operation id) of the operation to
  /// get. Specified in the format `projects / * /locations / * /operations / *
  /// `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [operationId] - Deprecated. The server-assigned `name` of the operation.
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
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
    core.String? operationId,
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (operationId != null) 'operationId': [operationId],
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
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

  /// Lists all operations in a project in a specific zone or all zones.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent (project and location) where the operations will be
  /// listed. Specified in the format `projects / * /locations / * `. Location
  /// "-" matches all zones and all regions.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) to return
  /// operations for, or `-` for all zones. This field has been deprecated and
  /// replaced by the parent field.
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
    core.String parent, {
    core.String? projectId,
    core.String? zone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (projectId != null) 'projectId': [projectId],
      if (zone != null) 'zone': [zone],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsZonesResource {
  final commons.ApiRequester _requester;

  ProjectsZonesClustersResource get clusters =>
      ProjectsZonesClustersResource(_requester);
  ProjectsZonesOperationsResource get operations =>
      ProjectsZonesOperationsResource(_requester);

  ProjectsZonesResource(commons.ApiRequester client) : _requester = client;

  /// Returns configuration info about the Google Kubernetes Engine service.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) to return
  /// operations for. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [name] - The name (project and location) of the server config to get,
  /// specified in the format `projects / * /locations / * `.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ServerConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ServerConfig> getServerconfig(
    core.String projectId,
    core.String zone, {
    core.String? name,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (name != null) 'name': [name],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/serverconfig';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ServerConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsZonesClustersResource {
  final commons.ApiRequester _requester;

  ProjectsZonesClustersNodePoolsResource get nodePools =>
      ProjectsZonesClustersNodePoolsResource(_requester);

  ProjectsZonesClustersResource(commons.ApiRequester client)
      : _requester = client;

  /// Sets the addons for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> addons(
    SetAddonsConfigRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/addons';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Completes master IP rotation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
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
  async.Future<Operation> completeIpRotation(
    CompleteIPRotationRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        ':completeIpRotation';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a cluster, consisting of the specified number and type of Google
  /// Compute Engine instances.
  ///
  /// By default, the cluster is created in the project's
  /// [default network](https://cloud.google.com/compute/docs/networks-and-firewalls#networks).
  /// One firewall is added for the cluster. After cluster creation, the Kubelet
  /// creates routes for each node to allow the containers on that node to
  /// communicate with all other instances in the cluster. Finally, an entry is
  /// added to the project's global metadata indicating which CIDR range the
  /// cluster is using.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the parent
  /// field.
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
    CreateClusterRequest request,
    core.String projectId,
    core.String zone, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the cluster, including the Kubernetes endpoint and all worker
  /// nodes.
  ///
  /// Firewalls and routes that were configured during cluster creation are also
  /// deleted. Other Google Compute Engine resources that might be in use by the
  /// cluster, such as load balancer resources, are not deleted if they weren't
  /// present when the cluster was initially created.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to delete. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [name] - The name (project, location, cluster) of the cluster to delete.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
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
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? name,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (name != null) 'name': [name],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the details of a specific cluster.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to retrieve. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [name] - The name (project, location, cluster) of the cluster to retrieve.
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Cluster].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Cluster> get(
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? name,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (name != null) 'name': [name],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Cluster.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Enables or disables the ABAC authorization mechanism on a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to update. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> legacyAbac(
    SetLegacyAbacRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/legacyAbac';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all clusters owned by a project in either the specified zone or all
  /// zones.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides, or "-" for all zones. This field has been deprecated and
  /// replaced by the parent field.
  ///
  /// [parent] - The parent (project and location) where the clusters will be
  /// listed. Specified in the format `projects / * /locations / * `. Location
  /// "-" matches all zones and all regions.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListClustersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListClustersResponse> list(
    core.String projectId,
    core.String zone, {
    core.String? parent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (parent != null) 'parent': [parent],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListClustersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the locations for a specific cluster.
  ///
  /// Deprecated. Use
  /// [projects.locations.clusters.update](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.locations.clusters/update)
  /// instead.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> locations(
    SetLocationsRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/locations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the logging service for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> logging(
    SetLoggingServiceRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/logging';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the master for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> master(
    UpdateMasterRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/master';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the monitoring service for a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> monitoring(
    SetMonitoringServiceRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/monitoring';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets labels on a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
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
  async.Future<Operation> resourceLabels(
    SetLabelsRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/resourceLabels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the maintenance policy for a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// [zone] - Required. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// [clusterId] - Required. The name of the cluster to update.
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
  async.Future<Operation> setMaintenancePolicy(
    SetMaintenancePolicyRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        ':setMaintenancePolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets master auth materials.
  ///
  /// Currently supports changing the admin password or a specific cluster,
  /// either via password generation or explicitly setting the password.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> setMasterAuth(
    SetMasterAuthRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        ':setMasterAuth';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Enables or disables Network Policy for a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
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
  async.Future<Operation> setNetworkPolicy(
    SetNetworkPolicyRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        ':setNetworkPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Starts master IP rotation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
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
  async.Future<Operation> startIpRotation(
    StartIPRotationRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        ':startIpRotation';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the settings of a specific cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
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
    UpdateClusterRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsZonesClustersNodePoolsResource {
  final commons.ApiRequester _requester;

  ProjectsZonesClustersNodePoolsResource(commons.ApiRequester client)
      : _requester = client;

  /// Sets the autoscaling settings for the specified node pool.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool to upgrade. This
  /// field has been deprecated and replaced by the name field.
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
  async.Future<Operation> autoscaling(
    SetNodePoolAutoscalingRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId,
    core.String nodePoolId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools/' +
        commons.escapeVariable('$nodePoolId') +
        '/autoscaling';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a node pool for a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the parent
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the parent field.
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
    CreateNodePoolRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a node pool from a cluster.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool to delete. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [name] - The name (project, location, cluster, node pool id) of the node
  /// pool to delete. Specified in the format `projects / * /locations / *
  /// /clusters / * /nodePools / * `.
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
    core.String projectId,
    core.String zone,
    core.String clusterId,
    core.String nodePoolId, {
    core.String? name,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (name != null) 'name': [name],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools/' +
        commons.escapeVariable('$nodePoolId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the requested node pool.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool. This field has been
  /// deprecated and replaced by the name field.
  ///
  /// [name] - The name (project, location, cluster, node pool id) of the node
  /// pool to get. Specified in the format `projects / * /locations / *
  /// /clusters / * /nodePools / * `.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NodePool].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NodePool> get(
    core.String projectId,
    core.String zone,
    core.String clusterId,
    core.String nodePoolId, {
    core.String? name,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (name != null) 'name': [name],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools/' +
        commons.escapeVariable('$nodePoolId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return NodePool.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the node pools for a cluster.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the parent
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster. This field has been
  /// deprecated and replaced by the parent field.
  ///
  /// [parent] - The parent (project, location, cluster id) where the node pools
  /// will be listed. Specified in the format `projects / * /locations / *
  /// /clusters / * `.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListNodePoolsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListNodePoolsResponse> list(
    core.String projectId,
    core.String zone,
    core.String clusterId, {
    core.String? parent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (parent != null) 'parent': [parent],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListNodePoolsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Rolls back a previously Aborted or Failed NodePool upgrade.
  ///
  /// This makes no changes if the last upgrade successfully completed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to rollback. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool to rollback. This
  /// field has been deprecated and replaced by the name field.
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
  async.Future<Operation> rollback(
    RollbackNodePoolUpgradeRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId,
    core.String nodePoolId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools/' +
        commons.escapeVariable('$nodePoolId') +
        ':rollback';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the NodeManagement options for a node pool.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to update. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool to update. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> setManagement(
    SetNodePoolManagementRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId,
    core.String nodePoolId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools/' +
        commons.escapeVariable('$nodePoolId') +
        '/setManagement';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the size for a specific node pool.
  ///
  /// The new size will be used for all replicas, including future replicas
  /// created by modifying NodePool.locations.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to update. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool to update. This field
  /// has been deprecated and replaced by the name field.
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
  async.Future<Operation> setSize(
    SetNodePoolSizeRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId,
    core.String nodePoolId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools/' +
        commons.escapeVariable('$nodePoolId') +
        '/setSize';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the version and/or image type for the specified node pool.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [clusterId] - Deprecated. The name of the cluster to upgrade. This field
  /// has been deprecated and replaced by the name field.
  ///
  /// [nodePoolId] - Deprecated. The name of the node pool to upgrade. This
  /// field has been deprecated and replaced by the name field.
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
    UpdateNodePoolRequest request,
    core.String projectId,
    core.String zone,
    core.String clusterId,
    core.String nodePoolId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/clusters/' +
        commons.escapeVariable('$clusterId') +
        '/nodePools/' +
        commons.escapeVariable('$nodePoolId') +
        '/update';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsZonesOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsZonesOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Cancels the specified operation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// operation resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [operationId] - Deprecated. The server-assigned `name` of the operation.
  /// This field has been deprecated and replaced by the name field.
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
    core.String projectId,
    core.String zone,
    core.String operationId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/operations/' +
        commons.escapeVariable('$operationId') +
        ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the specified operation.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides. This field has been deprecated and replaced by the name
  /// field.
  ///
  /// [operationId] - Deprecated. The server-assigned `name` of the operation.
  /// This field has been deprecated and replaced by the name field.
  ///
  /// [name] - The name (project, location, operation id) of the operation to
  /// get. Specified in the format `projects / * /locations / * /operations / *
  /// `.
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
    core.String projectId,
    core.String zone,
    core.String operationId, {
    core.String? name,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (name != null) 'name': [name],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/operations/' +
        commons.escapeVariable('$operationId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all operations in a project in a specific zone or all zones.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Deprecated. The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// [zone] - Deprecated. The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) to return
  /// operations for, or `-` for all zones. This field has been deprecated and
  /// replaced by the parent field.
  ///
  /// [parent] - The parent (project and location) where the operations will be
  /// listed. Specified in the format `projects / * /locations / * `. Location
  /// "-" matches all zones and all regions.
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
    core.String projectId,
    core.String zone, {
    core.String? parent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (parent != null) 'parent': [parent],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/zones/' +
        commons.escapeVariable('$zone') +
        '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// AcceleratorConfig represents a Hardware Accelerator request.
class AcceleratorConfig {
  /// The number of the accelerator cards exposed to an instance.
  core.String? acceleratorCount;

  /// The accelerator type resource name.
  ///
  /// List of supported accelerators
  /// [here](https://cloud.google.com/compute/docs/gpus)
  core.String? acceleratorType;

  AcceleratorConfig();

  AcceleratorConfig.fromJson(core.Map _json) {
    if (_json.containsKey('acceleratorCount')) {
      acceleratorCount = _json['acceleratorCount'] as core.String;
    }
    if (_json.containsKey('acceleratorType')) {
      acceleratorType = _json['acceleratorType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acceleratorCount != null) 'acceleratorCount': acceleratorCount!,
        if (acceleratorType != null) 'acceleratorType': acceleratorType!,
      };
}

/// Configuration for the addons that can be automatically spun up in the
/// cluster, enabling additional functionality.
class AddonsConfig {
  /// Configuration for the Cloud Run addon, which allows the user to use a
  /// managed Knative service.
  CloudRunConfig? cloudRunConfig;

  /// Configuration for the ConfigConnector add-on, a Kubernetes extension to
  /// manage hosted GCP services through the Kubernetes API
  ConfigConnectorConfig? configConnectorConfig;

  /// Configuration for NodeLocalDNS, a dns cache running on cluster nodes
  DnsCacheConfig? dnsCacheConfig;

  /// Configuration for the Compute Engine Persistent Disk CSI driver.
  GcePersistentDiskCsiDriverConfig? gcePersistentDiskCsiDriverConfig;

  /// Configuration for the horizontal pod autoscaling feature, which increases
  /// or decreases the number of replica pods a replication controller has based
  /// on the resource usage of the existing pods.
  HorizontalPodAutoscaling? horizontalPodAutoscaling;

  /// Configuration for the HTTP (L7) load balancing controller addon, which
  /// makes it easy to set up HTTP load balancers for services in a cluster.
  HttpLoadBalancing? httpLoadBalancing;

  /// Configuration for the Kubernetes Dashboard.
  ///
  /// This addon is deprecated, and will be disabled in 1.15. It is recommended
  /// to use the Cloud Console to manage and monitor your Kubernetes clusters,
  /// workloads and applications. For more information, see:
  /// https://cloud.google.com/kubernetes-engine/docs/concepts/dashboards
  KubernetesDashboard? kubernetesDashboard;

  /// Configuration for NetworkPolicy.
  ///
  /// This only tracks whether the addon is enabled or not on the Master, it
  /// does not track whether network policy is enabled for the nodes.
  NetworkPolicyConfig? networkPolicyConfig;

  AddonsConfig();

  AddonsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('cloudRunConfig')) {
      cloudRunConfig = CloudRunConfig.fromJson(
          _json['cloudRunConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('configConnectorConfig')) {
      configConnectorConfig = ConfigConnectorConfig.fromJson(
          _json['configConnectorConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dnsCacheConfig')) {
      dnsCacheConfig = DnsCacheConfig.fromJson(
          _json['dnsCacheConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gcePersistentDiskCsiDriverConfig')) {
      gcePersistentDiskCsiDriverConfig =
          GcePersistentDiskCsiDriverConfig.fromJson(
              _json['gcePersistentDiskCsiDriverConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('horizontalPodAutoscaling')) {
      horizontalPodAutoscaling = HorizontalPodAutoscaling.fromJson(
          _json['horizontalPodAutoscaling']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('httpLoadBalancing')) {
      httpLoadBalancing = HttpLoadBalancing.fromJson(
          _json['httpLoadBalancing'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kubernetesDashboard')) {
      kubernetesDashboard = KubernetesDashboard.fromJson(
          _json['kubernetesDashboard'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('networkPolicyConfig')) {
      networkPolicyConfig = NetworkPolicyConfig.fromJson(
          _json['networkPolicyConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudRunConfig != null) 'cloudRunConfig': cloudRunConfig!.toJson(),
        if (configConnectorConfig != null)
          'configConnectorConfig': configConnectorConfig!.toJson(),
        if (dnsCacheConfig != null) 'dnsCacheConfig': dnsCacheConfig!.toJson(),
        if (gcePersistentDiskCsiDriverConfig != null)
          'gcePersistentDiskCsiDriverConfig':
              gcePersistentDiskCsiDriverConfig!.toJson(),
        if (horizontalPodAutoscaling != null)
          'horizontalPodAutoscaling': horizontalPodAutoscaling!.toJson(),
        if (httpLoadBalancing != null)
          'httpLoadBalancing': httpLoadBalancing!.toJson(),
        if (kubernetesDashboard != null)
          'kubernetesDashboard': kubernetesDashboard!.toJson(),
        if (networkPolicyConfig != null)
          'networkPolicyConfig': networkPolicyConfig!.toJson(),
      };
}

/// Configuration for returning group information from authenticators.
class AuthenticatorGroupsConfig {
  /// Whether this cluster should return group membership lookups during
  /// authentication using a group of security groups.
  core.bool? enabled;

  /// The name of the security group-of-groups to be used.
  ///
  /// Only relevant if enabled = true.
  core.String? securityGroup;

  AuthenticatorGroupsConfig();

  AuthenticatorGroupsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('securityGroup')) {
      securityGroup = _json['securityGroup'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
        if (securityGroup != null) 'securityGroup': securityGroup!,
      };
}

/// AutoUpgradeOptions defines the set of options for the user to control how
/// the Auto Upgrades will proceed.
class AutoUpgradeOptions {
  /// This field is set when upgrades are about to commence with the approximate
  /// start time for the upgrades, in
  /// [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.
  ///
  /// Output only.
  core.String? autoUpgradeStartTime;

  /// This field is set when upgrades are about to commence with the description
  /// of the upgrade.
  ///
  /// Output only.
  core.String? description;

  AutoUpgradeOptions();

  AutoUpgradeOptions.fromJson(core.Map _json) {
    if (_json.containsKey('autoUpgradeStartTime')) {
      autoUpgradeStartTime = _json['autoUpgradeStartTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoUpgradeStartTime != null)
          'autoUpgradeStartTime': autoUpgradeStartTime!,
        if (description != null) 'description': description!,
      };
}

/// Autopilot is the configuration for Autopilot settings on the cluster.
class Autopilot {
  /// Enable Autopilot
  core.bool? enabled;

  Autopilot();

  Autopilot.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// AutoprovisioningNodePoolDefaults contains defaults for a node pool created
/// by NAP.
class AutoprovisioningNodePoolDefaults {
  /// The Customer Managed Encryption Key used to encrypt the boot disk attached
  /// to each node in the node pool.
  ///
  /// This should be of the form
  /// projects/\[KEY_PROJECT_ID\]/locations/\[LOCATION\]/keyRings/\[RING_NAME\]/cryptoKeys/\[KEY_NAME\].
  /// For more information about protecting resources with Cloud KMS Keys please
  /// see:
  /// https://cloud.google.com/compute/docs/disks/customer-managed-encryption
  core.String? bootDiskKmsKey;

  /// Size of the disk attached to each node, specified in GB.
  ///
  /// The smallest allowed disk size is 10GB. If unspecified, the default disk
  /// size is 100GB.
  core.int? diskSizeGb;

  /// Type of the disk attached to each node (e.g. 'pd-standard', 'pd-ssd' or
  /// 'pd-balanced') If unspecified, the default disk type is 'pd-standard'
  core.String? diskType;

  /// Specifies the node management options for NAP created node-pools.
  NodeManagement? management;

  /// Minimum CPU platform to be used for NAP created node pools.
  ///
  /// The instance may be scheduled on the specified or newer CPU platform.
  /// Applicable values are the friendly names of CPU platforms, such as
  /// minCpuPlatform: Intel Haswell or minCpuPlatform: Intel Sandy Bridge. For
  /// more information, read
  /// [how to specify min CPU platform](https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform)
  /// To unset the min cpu platform field pass "automatic" as field value.
  core.String? minCpuPlatform;

  /// Scopes that are used by NAP when creating node pools.
  core.List<core.String>? oauthScopes;

  /// The Google Cloud Platform Service Account to be used by the node VMs.
  core.String? serviceAccount;

  /// Shielded Instance options.
  ShieldedInstanceConfig? shieldedInstanceConfig;

  /// Specifies the upgrade settings for NAP created node pools
  UpgradeSettings? upgradeSettings;

  AutoprovisioningNodePoolDefaults();

  AutoprovisioningNodePoolDefaults.fromJson(core.Map _json) {
    if (_json.containsKey('bootDiskKmsKey')) {
      bootDiskKmsKey = _json['bootDiskKmsKey'] as core.String;
    }
    if (_json.containsKey('diskSizeGb')) {
      diskSizeGb = _json['diskSizeGb'] as core.int;
    }
    if (_json.containsKey('diskType')) {
      diskType = _json['diskType'] as core.String;
    }
    if (_json.containsKey('management')) {
      management = NodeManagement.fromJson(
          _json['management'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minCpuPlatform')) {
      minCpuPlatform = _json['minCpuPlatform'] as core.String;
    }
    if (_json.containsKey('oauthScopes')) {
      oauthScopes = (_json['oauthScopes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('serviceAccount')) {
      serviceAccount = _json['serviceAccount'] as core.String;
    }
    if (_json.containsKey('shieldedInstanceConfig')) {
      shieldedInstanceConfig = ShieldedInstanceConfig.fromJson(
          _json['shieldedInstanceConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('upgradeSettings')) {
      upgradeSettings = UpgradeSettings.fromJson(
          _json['upgradeSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bootDiskKmsKey != null) 'bootDiskKmsKey': bootDiskKmsKey!,
        if (diskSizeGb != null) 'diskSizeGb': diskSizeGb!,
        if (diskType != null) 'diskType': diskType!,
        if (management != null) 'management': management!.toJson(),
        if (minCpuPlatform != null) 'minCpuPlatform': minCpuPlatform!,
        if (oauthScopes != null) 'oauthScopes': oauthScopes!,
        if (serviceAccount != null) 'serviceAccount': serviceAccount!,
        if (shieldedInstanceConfig != null)
          'shieldedInstanceConfig': shieldedInstanceConfig!.toJson(),
        if (upgradeSettings != null)
          'upgradeSettings': upgradeSettings!.toJson(),
      };
}

/// Parameters for using BigQuery as the destination of resource usage export.
class BigQueryDestination {
  /// The ID of a BigQuery Dataset.
  core.String? datasetId;

  BigQueryDestination();

  BigQueryDestination.fromJson(core.Map _json) {
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetId != null) 'datasetId': datasetId!,
      };
}

/// Configuration for Binary Authorization.
class BinaryAuthorization {
  /// Enable Binary Authorization for this cluster.
  ///
  /// If enabled, all container images will be validated by Binary
  /// Authorization.
  core.bool? enabled;

  BinaryAuthorization();

  BinaryAuthorization.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// CancelOperationRequest cancels a single operation.
class CancelOperationRequest {
  /// The name (project, location, operation id) of the operation to cancel.
  ///
  /// Specified in the format `projects / * /locations / * /operations / * `.
  core.String? name;

  /// The server-assigned `name` of the operation.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? operationId;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// operation resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  CancelOperationRequest();

  CancelOperationRequest.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (operationId != null) 'operationId': operationId!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// CidrBlock contains an optional name and one CIDR block.
class CidrBlock {
  /// cidr_block must be specified in CIDR notation.
  core.String? cidrBlock;

  /// display_name is an optional field for users to identify CIDR blocks.
  core.String? displayName;

  CidrBlock();

  CidrBlock.fromJson(core.Map _json) {
    if (_json.containsKey('cidrBlock')) {
      cidrBlock = _json['cidrBlock'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cidrBlock != null) 'cidrBlock': cidrBlock!,
        if (displayName != null) 'displayName': displayName!,
      };
}

/// Configuration for client certificates on the cluster.
class ClientCertificateConfig {
  /// Issue a client certificate.
  core.bool? issueClientCertificate;

  ClientCertificateConfig();

  ClientCertificateConfig.fromJson(core.Map _json) {
    if (_json.containsKey('issueClientCertificate')) {
      issueClientCertificate = _json['issueClientCertificate'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (issueClientCertificate != null)
          'issueClientCertificate': issueClientCertificate!,
      };
}

/// Configuration options for the Cloud Run feature.
class CloudRunConfig {
  /// Whether Cloud Run addon is enabled for this cluster.
  core.bool? disabled;

  /// Which load balancer type is installed for Cloud Run.
  /// Possible string values are:
  /// - "LOAD_BALANCER_TYPE_UNSPECIFIED" : Load balancer type for Cloud Run is
  /// unspecified.
  /// - "LOAD_BALANCER_TYPE_EXTERNAL" : Install external load balancer for Cloud
  /// Run.
  /// - "LOAD_BALANCER_TYPE_INTERNAL" : Install internal load balancer for Cloud
  /// Run.
  core.String? loadBalancerType;

  CloudRunConfig();

  CloudRunConfig.fromJson(core.Map _json) {
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('loadBalancerType')) {
      loadBalancerType = _json['loadBalancerType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disabled != null) 'disabled': disabled!,
        if (loadBalancerType != null) 'loadBalancerType': loadBalancerType!,
      };
}

/// A Google Kubernetes Engine cluster.
class Cluster {
  /// Configurations for the various addons available to run in the cluster.
  AddonsConfig? addonsConfig;

  /// Configuration controlling RBAC group membership information.
  AuthenticatorGroupsConfig? authenticatorGroupsConfig;

  /// Autopilot configuration for the cluster.
  Autopilot? autopilot;

  /// Cluster-level autoscaling configuration.
  ClusterAutoscaling? autoscaling;

  /// Configuration for Binary Authorization.
  BinaryAuthorization? binaryAuthorization;

  /// The IP address range of the container pods in this cluster, in
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `10.96.0.0/14`).
  ///
  /// Leave blank to have one automatically chosen or specify a `/14` block in
  /// `10.0.0.0/8`.
  core.String? clusterIpv4Cidr;

  /// Which conditions caused the current cluster state.
  core.List<StatusCondition>? conditions;

  /// Configuration of Confidential Nodes
  ConfidentialNodes? confidentialNodes;

  /// The time the cluster was created, in
  /// [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.
  ///
  /// Output only.
  core.String? createTime;

  /// The current software version of the master endpoint.
  ///
  /// Output only.
  core.String? currentMasterVersion;

  /// The number of nodes currently in the cluster.
  ///
  /// Deprecated. Call Kubernetes API directly to retrieve node information.
  ///
  /// Output only.
  core.int? currentNodeCount;

  /// Deprecated, use
  /// [NodePools.version](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.locations.clusters.nodePools)
  /// instead.
  ///
  /// The current version of the node software components. If they are currently
  /// at multiple versions because they're in the process of being upgraded,
  /// this reflects the minimum version of all nodes.
  ///
  /// Output only.
  core.String? currentNodeVersion;

  /// Configuration of etcd encryption.
  DatabaseEncryption? databaseEncryption;

  /// The default constraint on the maximum number of pods that can be run
  /// simultaneously on a node in the node pool of this cluster.
  ///
  /// Only honored if cluster created with IP Alias support.
  MaxPodsConstraint? defaultMaxPodsConstraint;

  /// An optional description of this cluster.
  core.String? description;

  /// Kubernetes alpha features are enabled on this cluster.
  ///
  /// This includes alpha API groups (e.g. v1alpha1) and features that may not
  /// be production ready in the kubernetes version of the master and nodes. The
  /// cluster has no SLA for uptime and master/node upgrades are disabled. Alpha
  /// enabled clusters are automatically deleted thirty days after creation.
  core.bool? enableKubernetesAlpha;

  /// Enable the ability to use Cloud TPUs in this cluster.
  core.bool? enableTpu;

  /// The IP address of this cluster's master endpoint.
  ///
  /// The endpoint can be accessed from the internet at
  /// `https://username:password@endpoint/`. See the `masterAuth` property of
  /// this resource for username and password information.
  ///
  /// Output only.
  core.String? endpoint;

  /// The time the cluster will be automatically deleted in
  /// [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.
  ///
  /// Output only.
  core.String? expireTime;

  /// Unique id for the cluster.
  ///
  /// Output only.
  core.String? id;

  /// The initial Kubernetes version for this cluster.
  ///
  /// Valid versions are those found in validMasterVersions returned by
  /// getServerConfig. The version can be upgraded over time; such upgrades are
  /// reflected in currentMasterVersion and currentNodeVersion. Users may
  /// specify either explicit versions offered by Kubernetes Engine or version
  /// aliases, which have the following behavior: - "latest": picks the highest
  /// valid Kubernetes version - "1.X": picks the highest valid patch+gke.N
  /// patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in
  /// the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version -
  /// "","-": picks the default Kubernetes version
  core.String? initialClusterVersion;

  /// The number of nodes to create in this cluster.
  ///
  /// You must ensure that your Compute Engine
  /// [resource quota](https://cloud.google.com/compute/quotas) is sufficient
  /// for this number of instances. You must also have available firewall and
  /// routes quota. For requests, this field should only be used in lieu of a
  /// "node_pool" object, since this configuration (along with the
  /// "node_config") will be used to create a "NodePool" object with an
  /// auto-generated name. Do not use this and a node_pool at the same time.
  /// This field is deprecated, use node_pool.initial_node_count instead.
  core.int? initialNodeCount;

  /// Use node_pools.instance_group_urls.
  ///
  /// Deprecated.
  core.List<core.String>? instanceGroupUrls;

  /// Configuration for cluster IP allocation.
  IPAllocationPolicy? ipAllocationPolicy;

  /// The fingerprint of the set of labels for this cluster.
  core.String? labelFingerprint;

  /// Configuration for the legacy ABAC authorization mode.
  LegacyAbac? legacyAbac;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/regions-zones/regions-zones#available)
  /// or
  /// [region](https://cloud.google.com/compute/docs/regions-zones/regions-zones#available)
  /// in which the cluster resides.
  ///
  /// Output only.
  core.String? location;

  /// The list of Google Compute Engine
  /// [zones](https://cloud.google.com/compute/docs/zones#available) in which
  /// the cluster's nodes should be located.
  ///
  /// This field provides a default value if
  /// [NodePool.Locations](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.locations.clusters.nodePools#NodePool.FIELDS.locations)
  /// are not specified during node pool creation. Warning: changing cluster
  /// locations will update the
  /// [NodePool.Locations](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.locations.clusters.nodePools#NodePool.FIELDS.locations)
  /// of all node pools and will result in nodes being added and/or removed.
  core.List<core.String>? locations;

  /// The logging service the cluster should use to write logs.
  ///
  /// Currently available options: * `logging.googleapis.com/kubernetes` - The
  /// Cloud Logging service with a Kubernetes-native resource model *
  /// `logging.googleapis.com` - The legacy Cloud Logging service (no longer
  /// available as of GKE 1.15). * `none` - no logs will be exported from the
  /// cluster. If left as an empty string,`logging.googleapis.com/kubernetes`
  /// will be used for GKE 1.14+ or `logging.googleapis.com` for earlier
  /// versions.
  core.String? loggingService;

  /// Configure the maintenance policy for this cluster.
  MaintenancePolicy? maintenancePolicy;

  /// The authentication information for accessing the master endpoint.
  ///
  /// If unspecified, the defaults are used: For clusters before v1.12, if
  /// master_auth is unspecified, `username` will be set to "admin", a random
  /// password will be generated, and a client certificate will be issued.
  MasterAuth? masterAuth;

  /// The configuration options for master authorized networks feature.
  MasterAuthorizedNetworksConfig? masterAuthorizedNetworksConfig;

  /// The monitoring service the cluster should use to write metrics.
  ///
  /// Currently available options: * "monitoring.googleapis.com/kubernetes" -
  /// The Cloud Monitoring service with a Kubernetes-native resource model *
  /// `monitoring.googleapis.com` - The legacy Cloud Monitoring service (no
  /// longer available as of GKE 1.15). * `none` - No metrics will be exported
  /// from the cluster. If left as an empty
  /// string,`monitoring.googleapis.com/kubernetes` will be used for GKE 1.14+
  /// or `monitoring.googleapis.com` for earlier versions.
  core.String? monitoringService;

  /// The name of this cluster.
  ///
  /// The name must be unique within this project and location (e.g. zone or
  /// region), and can be up to 40 characters with the following restrictions: *
  /// Lowercase letters, numbers, and hyphens only. * Must start with a letter.
  /// * Must end with a number or a letter.
  core.String? name;

  /// The name of the Google Compute Engine
  /// [network](https://cloud.google.com/compute/docs/networks-and-firewalls#networks)
  /// to which the cluster is connected.
  ///
  /// If left unspecified, the `default` network will be used.
  core.String? network;

  /// Configuration for cluster networking.
  NetworkConfig? networkConfig;

  /// Configuration options for the NetworkPolicy feature.
  NetworkPolicy? networkPolicy;

  /// Parameters used in creating the cluster's nodes.
  ///
  /// For requests, this field should only be used in lieu of a "node_pool"
  /// object, since this configuration (along with the "initial_node_count")
  /// will be used to create a "NodePool" object with an auto-generated name. Do
  /// not use this and a node_pool at the same time. For responses, this field
  /// will be populated with the node configuration of the first node pool. (For
  /// configuration of each node pool, see `node_pool.config`) If unspecified,
  /// the defaults are used. This field is deprecated, use node_pool.config
  /// instead.
  NodeConfig? nodeConfig;

  /// The size of the address space on each node for hosting containers.
  ///
  /// This is provisioned from within the `container_ipv4_cidr` range. This
  /// field will only be set when cluster is in route-based network mode.
  ///
  /// Output only.
  core.int? nodeIpv4CidrSize;

  /// The node pools associated with this cluster.
  ///
  /// This field should not be set if "node_config" or "initial_node_count" are
  /// specified.
  core.List<NodePool>? nodePools;

  /// Notification configuration of the cluster.
  NotificationConfig? notificationConfig;

  /// Configuration for private cluster.
  PrivateClusterConfig? privateClusterConfig;

  /// Release channel configuration.
  ReleaseChannel? releaseChannel;

  /// The resource labels for the cluster to use to annotate any related Google
  /// Compute Engine resources.
  core.Map<core.String, core.String>? resourceLabels;

  /// Configuration for exporting resource usages.
  ///
  /// Resource usage export is disabled when this config is unspecified.
  ResourceUsageExportConfig? resourceUsageExportConfig;

  /// Server-defined URL for the resource.
  ///
  /// Output only.
  core.String? selfLink;

  /// The IP address range of the Kubernetes services in this cluster, in
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `1.2.3.4/29`).
  ///
  /// Service addresses are typically put in the last `/16` from the container
  /// CIDR.
  ///
  /// Output only.
  core.String? servicesIpv4Cidr;

  /// Shielded Nodes configuration.
  ShieldedNodes? shieldedNodes;

  /// The current status of this cluster.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Not set.
  /// - "PROVISIONING" : The PROVISIONING state indicates the cluster is being
  /// created.
  /// - "RUNNING" : The RUNNING state indicates the cluster has been created and
  /// is fully usable.
  /// - "RECONCILING" : The RECONCILING state indicates that some work is
  /// actively being done on the cluster, such as upgrading the master or node
  /// software. Details can be found in the `statusMessage` field.
  /// - "STOPPING" : The STOPPING state indicates the cluster is being deleted.
  /// - "ERROR" : The ERROR state indicates the cluster is unusable. It will be
  /// automatically deleted. Details can be found in the `statusMessage` field.
  /// - "DEGRADED" : The DEGRADED state indicates the cluster requires user
  /// action to restore full functionality. Details can be found in the
  /// `statusMessage` field.
  core.String? status;

  /// Use conditions instead.
  ///
  /// Additional information about the current status of this cluster, if
  /// available.
  ///
  /// Output only. Deprecated.
  core.String? statusMessage;

  /// The name of the Google Compute Engine
  /// [subnetwork](https://cloud.google.com/compute/docs/subnetworks) to which
  /// the cluster is connected.
  core.String? subnetwork;

  /// The IP address range of the Cloud TPUs in this cluster, in
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `1.2.3.4/29`).
  ///
  /// Output only.
  core.String? tpuIpv4CidrBlock;

  /// Cluster-level Vertical Pod Autoscaling configuration.
  VerticalPodAutoscaling? verticalPodAutoscaling;

  /// Configuration for the use of Kubernetes Service Accounts in GCP IAM
  /// policies.
  WorkloadIdentityConfig? workloadIdentityConfig;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field is deprecated, use location instead.
  ///
  /// Output only.
  core.String? zone;

  Cluster();

  Cluster.fromJson(core.Map _json) {
    if (_json.containsKey('addonsConfig')) {
      addonsConfig = AddonsConfig.fromJson(
          _json['addonsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('authenticatorGroupsConfig')) {
      authenticatorGroupsConfig = AuthenticatorGroupsConfig.fromJson(
          _json['authenticatorGroupsConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('autopilot')) {
      autopilot = Autopilot.fromJson(
          _json['autopilot'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('autoscaling')) {
      autoscaling = ClusterAutoscaling.fromJson(
          _json['autoscaling'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('binaryAuthorization')) {
      binaryAuthorization = BinaryAuthorization.fromJson(
          _json['binaryAuthorization'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clusterIpv4Cidr')) {
      clusterIpv4Cidr = _json['clusterIpv4Cidr'] as core.String;
    }
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<StatusCondition>((value) => StatusCondition.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('confidentialNodes')) {
      confidentialNodes = ConfidentialNodes.fromJson(
          _json['confidentialNodes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('currentMasterVersion')) {
      currentMasterVersion = _json['currentMasterVersion'] as core.String;
    }
    if (_json.containsKey('currentNodeCount')) {
      currentNodeCount = _json['currentNodeCount'] as core.int;
    }
    if (_json.containsKey('currentNodeVersion')) {
      currentNodeVersion = _json['currentNodeVersion'] as core.String;
    }
    if (_json.containsKey('databaseEncryption')) {
      databaseEncryption = DatabaseEncryption.fromJson(
          _json['databaseEncryption'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultMaxPodsConstraint')) {
      defaultMaxPodsConstraint = MaxPodsConstraint.fromJson(
          _json['defaultMaxPodsConstraint']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('enableKubernetesAlpha')) {
      enableKubernetesAlpha = _json['enableKubernetesAlpha'] as core.bool;
    }
    if (_json.containsKey('enableTpu')) {
      enableTpu = _json['enableTpu'] as core.bool;
    }
    if (_json.containsKey('endpoint')) {
      endpoint = _json['endpoint'] as core.String;
    }
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('initialClusterVersion')) {
      initialClusterVersion = _json['initialClusterVersion'] as core.String;
    }
    if (_json.containsKey('initialNodeCount')) {
      initialNodeCount = _json['initialNodeCount'] as core.int;
    }
    if (_json.containsKey('instanceGroupUrls')) {
      instanceGroupUrls = (_json['instanceGroupUrls'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('ipAllocationPolicy')) {
      ipAllocationPolicy = IPAllocationPolicy.fromJson(
          _json['ipAllocationPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labelFingerprint')) {
      labelFingerprint = _json['labelFingerprint'] as core.String;
    }
    if (_json.containsKey('legacyAbac')) {
      legacyAbac = LegacyAbac.fromJson(
          _json['legacyAbac'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('loggingService')) {
      loggingService = _json['loggingService'] as core.String;
    }
    if (_json.containsKey('maintenancePolicy')) {
      maintenancePolicy = MaintenancePolicy.fromJson(
          _json['maintenancePolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('masterAuth')) {
      masterAuth = MasterAuth.fromJson(
          _json['masterAuth'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('masterAuthorizedNetworksConfig')) {
      masterAuthorizedNetworksConfig = MasterAuthorizedNetworksConfig.fromJson(
          _json['masterAuthorizedNetworksConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('monitoringService')) {
      monitoringService = _json['monitoringService'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('network')) {
      network = _json['network'] as core.String;
    }
    if (_json.containsKey('networkConfig')) {
      networkConfig = NetworkConfig.fromJson(
          _json['networkConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('networkPolicy')) {
      networkPolicy = NetworkPolicy.fromJson(
          _json['networkPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nodeConfig')) {
      nodeConfig = NodeConfig.fromJson(
          _json['nodeConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nodeIpv4CidrSize')) {
      nodeIpv4CidrSize = _json['nodeIpv4CidrSize'] as core.int;
    }
    if (_json.containsKey('nodePools')) {
      nodePools = (_json['nodePools'] as core.List)
          .map<NodePool>((value) =>
              NodePool.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('notificationConfig')) {
      notificationConfig = NotificationConfig.fromJson(
          _json['notificationConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('privateClusterConfig')) {
      privateClusterConfig = PrivateClusterConfig.fromJson(
          _json['privateClusterConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('releaseChannel')) {
      releaseChannel = ReleaseChannel.fromJson(
          _json['releaseChannel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resourceLabels')) {
      resourceLabels =
          (_json['resourceLabels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('resourceUsageExportConfig')) {
      resourceUsageExportConfig = ResourceUsageExportConfig.fromJson(
          _json['resourceUsageExportConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('servicesIpv4Cidr')) {
      servicesIpv4Cidr = _json['servicesIpv4Cidr'] as core.String;
    }
    if (_json.containsKey('shieldedNodes')) {
      shieldedNodes = ShieldedNodes.fromJson(
          _json['shieldedNodes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('statusMessage')) {
      statusMessage = _json['statusMessage'] as core.String;
    }
    if (_json.containsKey('subnetwork')) {
      subnetwork = _json['subnetwork'] as core.String;
    }
    if (_json.containsKey('tpuIpv4CidrBlock')) {
      tpuIpv4CidrBlock = _json['tpuIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('verticalPodAutoscaling')) {
      verticalPodAutoscaling = VerticalPodAutoscaling.fromJson(
          _json['verticalPodAutoscaling']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('workloadIdentityConfig')) {
      workloadIdentityConfig = WorkloadIdentityConfig.fromJson(
          _json['workloadIdentityConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addonsConfig != null) 'addonsConfig': addonsConfig!.toJson(),
        if (authenticatorGroupsConfig != null)
          'authenticatorGroupsConfig': authenticatorGroupsConfig!.toJson(),
        if (autopilot != null) 'autopilot': autopilot!.toJson(),
        if (autoscaling != null) 'autoscaling': autoscaling!.toJson(),
        if (binaryAuthorization != null)
          'binaryAuthorization': binaryAuthorization!.toJson(),
        if (clusterIpv4Cidr != null) 'clusterIpv4Cidr': clusterIpv4Cidr!,
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (confidentialNodes != null)
          'confidentialNodes': confidentialNodes!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (currentMasterVersion != null)
          'currentMasterVersion': currentMasterVersion!,
        if (currentNodeCount != null) 'currentNodeCount': currentNodeCount!,
        if (currentNodeVersion != null)
          'currentNodeVersion': currentNodeVersion!,
        if (databaseEncryption != null)
          'databaseEncryption': databaseEncryption!.toJson(),
        if (defaultMaxPodsConstraint != null)
          'defaultMaxPodsConstraint': defaultMaxPodsConstraint!.toJson(),
        if (description != null) 'description': description!,
        if (enableKubernetesAlpha != null)
          'enableKubernetesAlpha': enableKubernetesAlpha!,
        if (enableTpu != null) 'enableTpu': enableTpu!,
        if (endpoint != null) 'endpoint': endpoint!,
        if (expireTime != null) 'expireTime': expireTime!,
        if (id != null) 'id': id!,
        if (initialClusterVersion != null)
          'initialClusterVersion': initialClusterVersion!,
        if (initialNodeCount != null) 'initialNodeCount': initialNodeCount!,
        if (instanceGroupUrls != null) 'instanceGroupUrls': instanceGroupUrls!,
        if (ipAllocationPolicy != null)
          'ipAllocationPolicy': ipAllocationPolicy!.toJson(),
        if (labelFingerprint != null) 'labelFingerprint': labelFingerprint!,
        if (legacyAbac != null) 'legacyAbac': legacyAbac!.toJson(),
        if (location != null) 'location': location!,
        if (locations != null) 'locations': locations!,
        if (loggingService != null) 'loggingService': loggingService!,
        if (maintenancePolicy != null)
          'maintenancePolicy': maintenancePolicy!.toJson(),
        if (masterAuth != null) 'masterAuth': masterAuth!.toJson(),
        if (masterAuthorizedNetworksConfig != null)
          'masterAuthorizedNetworksConfig':
              masterAuthorizedNetworksConfig!.toJson(),
        if (monitoringService != null) 'monitoringService': monitoringService!,
        if (name != null) 'name': name!,
        if (network != null) 'network': network!,
        if (networkConfig != null) 'networkConfig': networkConfig!.toJson(),
        if (networkPolicy != null) 'networkPolicy': networkPolicy!.toJson(),
        if (nodeConfig != null) 'nodeConfig': nodeConfig!.toJson(),
        if (nodeIpv4CidrSize != null) 'nodeIpv4CidrSize': nodeIpv4CidrSize!,
        if (nodePools != null)
          'nodePools': nodePools!.map((value) => value.toJson()).toList(),
        if (notificationConfig != null)
          'notificationConfig': notificationConfig!.toJson(),
        if (privateClusterConfig != null)
          'privateClusterConfig': privateClusterConfig!.toJson(),
        if (releaseChannel != null) 'releaseChannel': releaseChannel!.toJson(),
        if (resourceLabels != null) 'resourceLabels': resourceLabels!,
        if (resourceUsageExportConfig != null)
          'resourceUsageExportConfig': resourceUsageExportConfig!.toJson(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (servicesIpv4Cidr != null) 'servicesIpv4Cidr': servicesIpv4Cidr!,
        if (shieldedNodes != null) 'shieldedNodes': shieldedNodes!.toJson(),
        if (status != null) 'status': status!,
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (subnetwork != null) 'subnetwork': subnetwork!,
        if (tpuIpv4CidrBlock != null) 'tpuIpv4CidrBlock': tpuIpv4CidrBlock!,
        if (verticalPodAutoscaling != null)
          'verticalPodAutoscaling': verticalPodAutoscaling!.toJson(),
        if (workloadIdentityConfig != null)
          'workloadIdentityConfig': workloadIdentityConfig!.toJson(),
        if (zone != null) 'zone': zone!,
      };
}

/// ClusterAutoscaling contains global, per-cluster information required by
/// Cluster Autoscaler to automatically adjust the size of the cluster and
/// create/delete node pools based on the current needs.
class ClusterAutoscaling {
  /// The list of Google Compute Engine
  /// [zones](https://cloud.google.com/compute/docs/zones#available) in which
  /// the NodePool's nodes can be created by NAP.
  core.List<core.String>? autoprovisioningLocations;

  /// AutoprovisioningNodePoolDefaults contains defaults for a node pool created
  /// by NAP.
  AutoprovisioningNodePoolDefaults? autoprovisioningNodePoolDefaults;

  /// Enables automatic node pool creation and deletion.
  core.bool? enableNodeAutoprovisioning;

  /// Contains global constraints regarding minimum and maximum amount of
  /// resources in the cluster.
  core.List<ResourceLimit>? resourceLimits;

  ClusterAutoscaling();

  ClusterAutoscaling.fromJson(core.Map _json) {
    if (_json.containsKey('autoprovisioningLocations')) {
      autoprovisioningLocations =
          (_json['autoprovisioningLocations'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('autoprovisioningNodePoolDefaults')) {
      autoprovisioningNodePoolDefaults =
          AutoprovisioningNodePoolDefaults.fromJson(
              _json['autoprovisioningNodePoolDefaults']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enableNodeAutoprovisioning')) {
      enableNodeAutoprovisioning =
          _json['enableNodeAutoprovisioning'] as core.bool;
    }
    if (_json.containsKey('resourceLimits')) {
      resourceLimits = (_json['resourceLimits'] as core.List)
          .map<ResourceLimit>((value) => ResourceLimit.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoprovisioningLocations != null)
          'autoprovisioningLocations': autoprovisioningLocations!,
        if (autoprovisioningNodePoolDefaults != null)
          'autoprovisioningNodePoolDefaults':
              autoprovisioningNodePoolDefaults!.toJson(),
        if (enableNodeAutoprovisioning != null)
          'enableNodeAutoprovisioning': enableNodeAutoprovisioning!,
        if (resourceLimits != null)
          'resourceLimits':
              resourceLimits!.map((value) => value.toJson()).toList(),
      };
}

/// ClusterUpdate describes an update to the cluster.
///
/// Exactly one update can be applied to a cluster with each request, so at most
/// one field can be provided.
class ClusterUpdate {
  /// Configurations for the various addons available to run in the cluster.
  AddonsConfig? desiredAddonsConfig;

  /// The desired Autopilot configuration for the cluster.
  Autopilot? desiredAutopilot;

  /// The desired configuration options for the Binary Authorization feature.
  BinaryAuthorization? desiredBinaryAuthorization;

  /// Cluster-level autoscaling configuration.
  ClusterAutoscaling? desiredClusterAutoscaling;

  /// Configuration of etcd encryption.
  DatabaseEncryption? desiredDatabaseEncryption;

  /// The desired datapath provider for the cluster.
  /// Possible string values are:
  /// - "DATAPATH_PROVIDER_UNSPECIFIED" : Default value.
  /// - "LEGACY_DATAPATH" : Use the IPTables implementation based on kube-proxy.
  /// - "ADVANCED_DATAPATH" : Use the eBPF based GKE Dataplane V2 with
  /// additional features. See the
  /// [GKE Dataplane V2 documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2)
  /// for more.
  core.String? desiredDatapathProvider;

  /// The desired status of whether to disable default sNAT for this cluster.
  DefaultSnatStatus? desiredDefaultSnatStatus;

  /// The desired image type for the node pool.
  ///
  /// NOTE: Set the "desired_node_pool" field as well.
  core.String? desiredImageType;

  /// The desired config of Intra-node visibility.
  IntraNodeVisibilityConfig? desiredIntraNodeVisibilityConfig;

  /// The desired list of Google Compute Engine
  /// [zones](https://cloud.google.com/compute/docs/zones#available) in which
  /// the cluster's nodes should be located.
  ///
  /// This list must always include the cluster's primary zone. Warning:
  /// changing cluster locations will update the locations of all node pools and
  /// will result in nodes being added and/or removed.
  core.List<core.String>? desiredLocations;

  /// The logging service the cluster should use to write logs.
  ///
  /// Currently available options: * `logging.googleapis.com/kubernetes` - The
  /// Cloud Logging service with a Kubernetes-native resource model *
  /// `logging.googleapis.com` - The legacy Cloud Logging service (no longer
  /// available as of GKE 1.15). * `none` - no logs will be exported from the
  /// cluster. If left as an empty string,`logging.googleapis.com/kubernetes`
  /// will be used for GKE 1.14+ or `logging.googleapis.com` for earlier
  /// versions.
  core.String? desiredLoggingService;

  /// The desired configuration options for master authorized networks feature.
  MasterAuthorizedNetworksConfig? desiredMasterAuthorizedNetworksConfig;

  /// The Kubernetes version to change the master to.
  ///
  /// Users may specify either explicit versions offered by Kubernetes Engine or
  /// version aliases, which have the following behavior: - "latest": picks the
  /// highest valid Kubernetes version - "1.X": picks the highest valid
  /// patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid
  /// gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit
  /// Kubernetes version - "-": picks the default Kubernetes version
  core.String? desiredMasterVersion;

  /// The monitoring service the cluster should use to write metrics.
  ///
  /// Currently available options: * "monitoring.googleapis.com/kubernetes" -
  /// The Cloud Monitoring service with a Kubernetes-native resource model *
  /// `monitoring.googleapis.com` - The legacy Cloud Monitoring service (no
  /// longer available as of GKE 1.15). * `none` - No metrics will be exported
  /// from the cluster. If left as an empty
  /// string,`monitoring.googleapis.com/kubernetes` will be used for GKE 1.14+
  /// or `monitoring.googleapis.com` for earlier versions.
  core.String? desiredMonitoringService;

  /// Autoscaler configuration for the node pool specified in
  /// desired_node_pool_id.
  ///
  /// If there is only one pool in the cluster and desired_node_pool_id is not
  /// provided then the change applies to that single node pool.
  NodePoolAutoscaling? desiredNodePoolAutoscaling;

  /// The node pool to be upgraded.
  ///
  /// This field is mandatory if "desired_node_version", "desired_image_family"
  /// or "desired_node_pool_autoscaling" is specified and there is more than one
  /// node pool on the cluster.
  core.String? desiredNodePoolId;

  /// The Kubernetes version to change the nodes to (typically an upgrade).
  ///
  /// Users may specify either explicit versions offered by Kubernetes Engine or
  /// version aliases, which have the following behavior: - "latest": picks the
  /// highest valid Kubernetes version - "1.X": picks the highest valid
  /// patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid
  /// gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit
  /// Kubernetes version - "-": picks the Kubernetes master version
  core.String? desiredNodeVersion;

  /// The desired notification configuration.
  NotificationConfig? desiredNotificationConfig;

  /// The desired private cluster configuration.
  PrivateClusterConfig? desiredPrivateClusterConfig;

  /// The desired state of IPv6 connectivity to Google Services.
  /// Possible string values are:
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_UNSPECIFIED" : Default value. Same as
  /// DISABLED
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_DISABLED" : No private access to or from
  /// Google Services
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_TO_GOOGLE" : Enables private IPv6 access to
  /// Google Services from GKE
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_BIDIRECTIONAL" : Enables priate IPv6 access
  /// to and from Google Services
  core.String? desiredPrivateIpv6GoogleAccess;

  /// The desired release channel configuration.
  ReleaseChannel? desiredReleaseChannel;

  /// The desired configuration for exporting resource usage.
  ResourceUsageExportConfig? desiredResourceUsageExportConfig;

  /// Configuration for Shielded Nodes.
  ShieldedNodes? desiredShieldedNodes;

  /// Cluster-level Vertical Pod Autoscaling configuration.
  VerticalPodAutoscaling? desiredVerticalPodAutoscaling;

  /// Configuration for Workload Identity.
  WorkloadIdentityConfig? desiredWorkloadIdentityConfig;

  ClusterUpdate();

  ClusterUpdate.fromJson(core.Map _json) {
    if (_json.containsKey('desiredAddonsConfig')) {
      desiredAddonsConfig = AddonsConfig.fromJson(
          _json['desiredAddonsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredAutopilot')) {
      desiredAutopilot = Autopilot.fromJson(
          _json['desiredAutopilot'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredBinaryAuthorization')) {
      desiredBinaryAuthorization = BinaryAuthorization.fromJson(
          _json['desiredBinaryAuthorization']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredClusterAutoscaling')) {
      desiredClusterAutoscaling = ClusterAutoscaling.fromJson(
          _json['desiredClusterAutoscaling']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredDatabaseEncryption')) {
      desiredDatabaseEncryption = DatabaseEncryption.fromJson(
          _json['desiredDatabaseEncryption']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredDatapathProvider')) {
      desiredDatapathProvider = _json['desiredDatapathProvider'] as core.String;
    }
    if (_json.containsKey('desiredDefaultSnatStatus')) {
      desiredDefaultSnatStatus = DefaultSnatStatus.fromJson(
          _json['desiredDefaultSnatStatus']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredImageType')) {
      desiredImageType = _json['desiredImageType'] as core.String;
    }
    if (_json.containsKey('desiredIntraNodeVisibilityConfig')) {
      desiredIntraNodeVisibilityConfig = IntraNodeVisibilityConfig.fromJson(
          _json['desiredIntraNodeVisibilityConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredLocations')) {
      desiredLocations = (_json['desiredLocations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('desiredLoggingService')) {
      desiredLoggingService = _json['desiredLoggingService'] as core.String;
    }
    if (_json.containsKey('desiredMasterAuthorizedNetworksConfig')) {
      desiredMasterAuthorizedNetworksConfig =
          MasterAuthorizedNetworksConfig.fromJson(
              _json['desiredMasterAuthorizedNetworksConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredMasterVersion')) {
      desiredMasterVersion = _json['desiredMasterVersion'] as core.String;
    }
    if (_json.containsKey('desiredMonitoringService')) {
      desiredMonitoringService =
          _json['desiredMonitoringService'] as core.String;
    }
    if (_json.containsKey('desiredNodePoolAutoscaling')) {
      desiredNodePoolAutoscaling = NodePoolAutoscaling.fromJson(
          _json['desiredNodePoolAutoscaling']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredNodePoolId')) {
      desiredNodePoolId = _json['desiredNodePoolId'] as core.String;
    }
    if (_json.containsKey('desiredNodeVersion')) {
      desiredNodeVersion = _json['desiredNodeVersion'] as core.String;
    }
    if (_json.containsKey('desiredNotificationConfig')) {
      desiredNotificationConfig = NotificationConfig.fromJson(
          _json['desiredNotificationConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredPrivateClusterConfig')) {
      desiredPrivateClusterConfig = PrivateClusterConfig.fromJson(
          _json['desiredPrivateClusterConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredPrivateIpv6GoogleAccess')) {
      desiredPrivateIpv6GoogleAccess =
          _json['desiredPrivateIpv6GoogleAccess'] as core.String;
    }
    if (_json.containsKey('desiredReleaseChannel')) {
      desiredReleaseChannel = ReleaseChannel.fromJson(
          _json['desiredReleaseChannel']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredResourceUsageExportConfig')) {
      desiredResourceUsageExportConfig = ResourceUsageExportConfig.fromJson(
          _json['desiredResourceUsageExportConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredShieldedNodes')) {
      desiredShieldedNodes = ShieldedNodes.fromJson(
          _json['desiredShieldedNodes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredVerticalPodAutoscaling')) {
      desiredVerticalPodAutoscaling = VerticalPodAutoscaling.fromJson(
          _json['desiredVerticalPodAutoscaling']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('desiredWorkloadIdentityConfig')) {
      desiredWorkloadIdentityConfig = WorkloadIdentityConfig.fromJson(
          _json['desiredWorkloadIdentityConfig']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (desiredAddonsConfig != null)
          'desiredAddonsConfig': desiredAddonsConfig!.toJson(),
        if (desiredAutopilot != null)
          'desiredAutopilot': desiredAutopilot!.toJson(),
        if (desiredBinaryAuthorization != null)
          'desiredBinaryAuthorization': desiredBinaryAuthorization!.toJson(),
        if (desiredClusterAutoscaling != null)
          'desiredClusterAutoscaling': desiredClusterAutoscaling!.toJson(),
        if (desiredDatabaseEncryption != null)
          'desiredDatabaseEncryption': desiredDatabaseEncryption!.toJson(),
        if (desiredDatapathProvider != null)
          'desiredDatapathProvider': desiredDatapathProvider!,
        if (desiredDefaultSnatStatus != null)
          'desiredDefaultSnatStatus': desiredDefaultSnatStatus!.toJson(),
        if (desiredImageType != null) 'desiredImageType': desiredImageType!,
        if (desiredIntraNodeVisibilityConfig != null)
          'desiredIntraNodeVisibilityConfig':
              desiredIntraNodeVisibilityConfig!.toJson(),
        if (desiredLocations != null) 'desiredLocations': desiredLocations!,
        if (desiredLoggingService != null)
          'desiredLoggingService': desiredLoggingService!,
        if (desiredMasterAuthorizedNetworksConfig != null)
          'desiredMasterAuthorizedNetworksConfig':
              desiredMasterAuthorizedNetworksConfig!.toJson(),
        if (desiredMasterVersion != null)
          'desiredMasterVersion': desiredMasterVersion!,
        if (desiredMonitoringService != null)
          'desiredMonitoringService': desiredMonitoringService!,
        if (desiredNodePoolAutoscaling != null)
          'desiredNodePoolAutoscaling': desiredNodePoolAutoscaling!.toJson(),
        if (desiredNodePoolId != null) 'desiredNodePoolId': desiredNodePoolId!,
        if (desiredNodeVersion != null)
          'desiredNodeVersion': desiredNodeVersion!,
        if (desiredNotificationConfig != null)
          'desiredNotificationConfig': desiredNotificationConfig!.toJson(),
        if (desiredPrivateClusterConfig != null)
          'desiredPrivateClusterConfig': desiredPrivateClusterConfig!.toJson(),
        if (desiredPrivateIpv6GoogleAccess != null)
          'desiredPrivateIpv6GoogleAccess': desiredPrivateIpv6GoogleAccess!,
        if (desiredReleaseChannel != null)
          'desiredReleaseChannel': desiredReleaseChannel!.toJson(),
        if (desiredResourceUsageExportConfig != null)
          'desiredResourceUsageExportConfig':
              desiredResourceUsageExportConfig!.toJson(),
        if (desiredShieldedNodes != null)
          'desiredShieldedNodes': desiredShieldedNodes!.toJson(),
        if (desiredVerticalPodAutoscaling != null)
          'desiredVerticalPodAutoscaling':
              desiredVerticalPodAutoscaling!.toJson(),
        if (desiredWorkloadIdentityConfig != null)
          'desiredWorkloadIdentityConfig':
              desiredWorkloadIdentityConfig!.toJson(),
      };
}

/// CompleteIPRotationRequest moves the cluster master back into single-IP mode.
class CompleteIPRotationRequest {
  /// The name of the cluster.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster id) of the cluster to complete IP
  /// rotation.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  CompleteIPRotationRequest();

  CompleteIPRotationRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// ConfidentialNodes is configuration for the confidential nodes feature, which
/// makes nodes run on confidential VMs.
class ConfidentialNodes {
  /// Whether Confidential Nodes feature is enabled for all nodes in this
  /// cluster.
  core.bool? enabled;

  ConfidentialNodes();

  ConfidentialNodes.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Configuration options for the Config Connector add-on.
class ConfigConnectorConfig {
  /// Whether Cloud Connector is enabled for this cluster.
  core.bool? enabled;

  ConfigConnectorConfig();

  ConfigConnectorConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Parameters for controlling consumption metering.
class ConsumptionMeteringConfig {
  /// Whether to enable consumption metering for this cluster.
  ///
  /// If enabled, a second BigQuery table will be created to hold resource
  /// consumption records.
  core.bool? enabled;

  ConsumptionMeteringConfig();

  ConsumptionMeteringConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// CreateClusterRequest creates a cluster.
class CreateClusterRequest {
  /// A
  /// [cluster resource](https://cloud.google.com/container-engine/reference/rest/v1/projects.locations.clusters)
  ///
  /// Required.
  Cluster? cluster;

  /// The parent (project and location) where the cluster will be created.
  ///
  /// Specified in the format `projects / * /locations / * `.
  core.String? parent;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// Deprecated.
  core.String? zone;

  CreateClusterRequest();

  CreateClusterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cluster')) {
      cluster = Cluster.fromJson(
          _json['cluster'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cluster != null) 'cluster': cluster!.toJson(),
        if (parent != null) 'parent': parent!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// CreateNodePoolRequest creates a node pool for a cluster.
class CreateNodePoolRequest {
  /// The name of the cluster.
  ///
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The node pool to create.
  ///
  /// Required.
  NodePool? nodePool;

  /// The parent (project, location, cluster id) where the node pool will be
  /// created.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? parent;

  /// The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  ///
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the parent field.
  ///
  /// Deprecated.
  core.String? zone;

  CreateNodePoolRequest();

  CreateNodePoolRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('nodePool')) {
      nodePool = NodePool.fromJson(
          _json['nodePool'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (nodePool != null) 'nodePool': nodePool!.toJson(),
        if (parent != null) 'parent': parent!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// Time window specified for daily maintenance operations.
class DailyMaintenanceWindow {
  /// Duration of the time window, automatically chosen to be smallest possible
  /// in the given scenario.
  ///
  /// Duration will be in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) format
  /// "PTnHnMnS".
  ///
  /// Output only.
  core.String? duration;

  /// Time within the maintenance window to start the maintenance operations.
  ///
  /// Time format should be in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt)
  /// format "HH:MM", where HH : \[00-23\] and MM : \[00-59\] GMT.
  core.String? startTime;

  DailyMaintenanceWindow();

  DailyMaintenanceWindow.fromJson(core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Configuration of etcd encryption.
class DatabaseEncryption {
  /// Name of CloudKMS key to use for the encryption of secrets in etcd.
  ///
  /// Ex.
  /// projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key
  core.String? keyName;

  /// Denotes the state of etcd encryption.
  /// Possible string values are:
  /// - "UNKNOWN" : Should never be set
  /// - "ENCRYPTED" : Secrets in etcd are encrypted.
  /// - "DECRYPTED" : Secrets in etcd are stored in plain text (at etcd level) -
  /// this is unrelated to Compute Engine level full disk encryption.
  core.String? state;

  DatabaseEncryption();

  DatabaseEncryption.fromJson(core.Map _json) {
    if (_json.containsKey('keyName')) {
      keyName = _json['keyName'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keyName != null) 'keyName': keyName!,
        if (state != null) 'state': state!,
      };
}

/// DefaultSnatStatus contains the desired state of whether default sNAT should
/// be disabled on the cluster.
class DefaultSnatStatus {
  /// Disables cluster default sNAT rules.
  core.bool? disabled;

  DefaultSnatStatus();

  DefaultSnatStatus.fromJson(core.Map _json) {
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disabled != null) 'disabled': disabled!,
      };
}

/// Configuration for NodeLocal DNSCache
class DnsCacheConfig {
  /// Whether NodeLocal DNSCache is enabled for this cluster.
  core.bool? enabled;

  DnsCacheConfig();

  DnsCacheConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
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

/// Configuration for the Compute Engine PD CSI driver.
class GcePersistentDiskCsiDriverConfig {
  /// Whether the Compute Engine PD CSI driver is enabled for this cluster.
  core.bool? enabled;

  GcePersistentDiskCsiDriverConfig();

  GcePersistentDiskCsiDriverConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// GetJSONWebKeysResponse is a valid JSON Web Key Set as specififed in rfc 7517
class GetJSONWebKeysResponse {
  /// OnePlatform automatically extracts this field and uses it to set the HTTP
  /// Cache-Control header.
  HttpCacheControlResponseHeader? cacheHeader;

  /// The public component of the keys used by the cluster to sign token
  /// requests.
  core.List<Jwk>? keys;

  GetJSONWebKeysResponse();

  GetJSONWebKeysResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cacheHeader')) {
      cacheHeader = HttpCacheControlResponseHeader.fromJson(
          _json['cacheHeader'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keys')) {
      keys = (_json['keys'] as core.List)
          .map<Jwk>((value) =>
              Jwk.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cacheHeader != null) 'cacheHeader': cacheHeader!.toJson(),
        if (keys != null) 'keys': keys!.map((value) => value.toJson()).toList(),
      };
}

/// GetOpenIDConfigResponse is an OIDC discovery document for the cluster.
///
/// See the OpenID Connect Discovery 1.0 specification for details.
class GetOpenIDConfigResponse {
  /// OnePlatform automatically extracts this field and uses it to set the HTTP
  /// Cache-Control header.
  HttpCacheControlResponseHeader? cacheHeader;

  /// Supported claims.
  core.List<core.String>? claimsSupported;

  /// Supported grant types.
  core.List<core.String>? grantTypes;

  /// supported ID Token signing Algorithms.
  core.List<core.String>? idTokenSigningAlgValuesSupported;

  /// OIDC Issuer.
  core.String? issuer;

  /// JSON Web Key uri.
  core.String? jwksUri;

  /// Supported response types.
  core.List<core.String>? responseTypesSupported;

  /// Supported subject types.
  core.List<core.String>? subjectTypesSupported;

  GetOpenIDConfigResponse();

  GetOpenIDConfigResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cacheHeader')) {
      cacheHeader = HttpCacheControlResponseHeader.fromJson(
          _json['cacheHeader'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('claims_supported')) {
      claimsSupported = (_json['claims_supported'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('grant_types')) {
      grantTypes = (_json['grant_types'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('id_token_signing_alg_values_supported')) {
      idTokenSigningAlgValuesSupported =
          (_json['id_token_signing_alg_values_supported'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('issuer')) {
      issuer = _json['issuer'] as core.String;
    }
    if (_json.containsKey('jwks_uri')) {
      jwksUri = _json['jwks_uri'] as core.String;
    }
    if (_json.containsKey('response_types_supported')) {
      responseTypesSupported = (_json['response_types_supported'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('subject_types_supported')) {
      subjectTypesSupported = (_json['subject_types_supported'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cacheHeader != null) 'cacheHeader': cacheHeader!.toJson(),
        if (claimsSupported != null) 'claims_supported': claimsSupported!,
        if (grantTypes != null) 'grant_types': grantTypes!,
        if (idTokenSigningAlgValuesSupported != null)
          'id_token_signing_alg_values_supported':
              idTokenSigningAlgValuesSupported!,
        if (issuer != null) 'issuer': issuer!,
        if (jwksUri != null) 'jwks_uri': jwksUri!,
        if (responseTypesSupported != null)
          'response_types_supported': responseTypesSupported!,
        if (subjectTypesSupported != null)
          'subject_types_supported': subjectTypesSupported!,
      };
}

/// Configuration options for the horizontal pod autoscaling feature, which
/// increases or decreases the number of replica pods a replication controller
/// has based on the resource usage of the existing pods.
class HorizontalPodAutoscaling {
  /// Whether the Horizontal Pod Autoscaling feature is enabled in the cluster.
  ///
  /// When enabled, it ensures that metrics are collected into Stackdriver
  /// Monitoring.
  core.bool? disabled;

  HorizontalPodAutoscaling();

  HorizontalPodAutoscaling.fromJson(core.Map _json) {
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disabled != null) 'disabled': disabled!,
      };
}

/// RFC-2616: cache control support
class HttpCacheControlResponseHeader {
  /// 14.6 response cache age, in seconds since the response is generated
  core.String? age;

  /// 14.9 request and response directives
  core.String? directive;

  /// 14.21 response cache expires, in RFC 1123 date format
  core.String? expires;

  HttpCacheControlResponseHeader();

  HttpCacheControlResponseHeader.fromJson(core.Map _json) {
    if (_json.containsKey('age')) {
      age = _json['age'] as core.String;
    }
    if (_json.containsKey('directive')) {
      directive = _json['directive'] as core.String;
    }
    if (_json.containsKey('expires')) {
      expires = _json['expires'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (age != null) 'age': age!,
        if (directive != null) 'directive': directive!,
        if (expires != null) 'expires': expires!,
      };
}

/// Configuration options for the HTTP (L7) load balancing controller addon,
/// which makes it easy to set up HTTP load balancers for services in a cluster.
class HttpLoadBalancing {
  /// Whether the HTTP Load Balancing controller is enabled in the cluster.
  ///
  /// When enabled, it runs a small pod in the cluster that manages the load
  /// balancers.
  core.bool? disabled;

  HttpLoadBalancing();

  HttpLoadBalancing.fromJson(core.Map _json) {
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disabled != null) 'disabled': disabled!,
      };
}

/// Configuration for controlling how IPs are allocated in the cluster.
class IPAllocationPolicy {
  /// This field is deprecated, use cluster_ipv4_cidr_block.
  core.String? clusterIpv4Cidr;

  /// The IP address range for the cluster pod IPs.
  ///
  /// If this field is set, then `cluster.cluster_ipv4_cidr` must be left blank.
  /// This field is only applicable when `use_ip_aliases` is true. Set to blank
  /// to have a range chosen with the default size. Set to /netmask (e.g. `/14`)
  /// to have a range chosen with a specific netmask. Set to a
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `10.96.0.0/14`) from the RFC-1918 private networks (e.g.
  /// `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) to pick a specific range
  /// to use.
  core.String? clusterIpv4CidrBlock;

  /// The name of the secondary range to be used for the cluster CIDR block.
  ///
  /// The secondary range will be used for pod IP addresses. This must be an
  /// existing secondary range associated with the cluster subnetwork. This
  /// field is only applicable with use_ip_aliases is true and create_subnetwork
  /// is false.
  core.String? clusterSecondaryRangeName;

  /// Whether a new subnetwork will be created automatically for the cluster.
  ///
  /// This field is only applicable when `use_ip_aliases` is true.
  core.bool? createSubnetwork;

  /// This field is deprecated, use node_ipv4_cidr_block.
  core.String? nodeIpv4Cidr;

  /// The IP address range of the instance IPs in this cluster.
  ///
  /// This is applicable only if `create_subnetwork` is true. Set to blank to
  /// have a range chosen with the default size. Set to /netmask (e.g. `/14`) to
  /// have a range chosen with a specific netmask. Set to a
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `10.96.0.0/14`) from the RFC-1918 private networks (e.g.
  /// `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) to pick a specific range
  /// to use.
  core.String? nodeIpv4CidrBlock;

  /// This field is deprecated, use services_ipv4_cidr_block.
  core.String? servicesIpv4Cidr;

  /// The IP address range of the services IPs in this cluster.
  ///
  /// If blank, a range will be automatically chosen with the default size. This
  /// field is only applicable when `use_ip_aliases` is true. Set to blank to
  /// have a range chosen with the default size. Set to /netmask (e.g. `/14`) to
  /// have a range chosen with a specific netmask. Set to a
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `10.96.0.0/14`) from the RFC-1918 private networks (e.g.
  /// `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) to pick a specific range
  /// to use.
  core.String? servicesIpv4CidrBlock;

  /// The name of the secondary range to be used as for the services CIDR block.
  ///
  /// The secondary range will be used for service ClusterIPs. This must be an
  /// existing secondary range associated with the cluster subnetwork. This
  /// field is only applicable with use_ip_aliases is true and create_subnetwork
  /// is false.
  core.String? servicesSecondaryRangeName;

  /// A custom subnetwork name to be used if `create_subnetwork` is true.
  ///
  /// If this field is empty, then an automatic name will be chosen for the new
  /// subnetwork.
  core.String? subnetworkName;

  /// The IP address range of the Cloud TPUs in this cluster.
  ///
  /// If unspecified, a range will be automatically chosen with the default
  /// size. This field is only applicable when `use_ip_aliases` is true. If
  /// unspecified, the range will use the default size. Set to /netmask (e.g.
  /// `/14`) to have a range chosen with a specific netmask. Set to a
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `10.96.0.0/14`) from the RFC-1918 private networks (e.g.
  /// `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) to pick a specific range
  /// to use.
  core.String? tpuIpv4CidrBlock;

  /// Whether alias IPs will be used for pod IPs in the cluster.
  ///
  /// This is used in conjunction with use_routes. It cannot be true if
  /// use_routes is true. If both use_ip_aliases and use_routes are false, then
  /// the server picks the default IP allocation mode
  core.bool? useIpAliases;

  /// Whether routes will be used for pod IPs in the cluster.
  ///
  /// This is used in conjunction with use_ip_aliases. It cannot be true if
  /// use_ip_aliases is true. If both use_ip_aliases and use_routes are false,
  /// then the server picks the default IP allocation mode
  core.bool? useRoutes;

  IPAllocationPolicy();

  IPAllocationPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('clusterIpv4Cidr')) {
      clusterIpv4Cidr = _json['clusterIpv4Cidr'] as core.String;
    }
    if (_json.containsKey('clusterIpv4CidrBlock')) {
      clusterIpv4CidrBlock = _json['clusterIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('clusterSecondaryRangeName')) {
      clusterSecondaryRangeName =
          _json['clusterSecondaryRangeName'] as core.String;
    }
    if (_json.containsKey('createSubnetwork')) {
      createSubnetwork = _json['createSubnetwork'] as core.bool;
    }
    if (_json.containsKey('nodeIpv4Cidr')) {
      nodeIpv4Cidr = _json['nodeIpv4Cidr'] as core.String;
    }
    if (_json.containsKey('nodeIpv4CidrBlock')) {
      nodeIpv4CidrBlock = _json['nodeIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('servicesIpv4Cidr')) {
      servicesIpv4Cidr = _json['servicesIpv4Cidr'] as core.String;
    }
    if (_json.containsKey('servicesIpv4CidrBlock')) {
      servicesIpv4CidrBlock = _json['servicesIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('servicesSecondaryRangeName')) {
      servicesSecondaryRangeName =
          _json['servicesSecondaryRangeName'] as core.String;
    }
    if (_json.containsKey('subnetworkName')) {
      subnetworkName = _json['subnetworkName'] as core.String;
    }
    if (_json.containsKey('tpuIpv4CidrBlock')) {
      tpuIpv4CidrBlock = _json['tpuIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('useIpAliases')) {
      useIpAliases = _json['useIpAliases'] as core.bool;
    }
    if (_json.containsKey('useRoutes')) {
      useRoutes = _json['useRoutes'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterIpv4Cidr != null) 'clusterIpv4Cidr': clusterIpv4Cidr!,
        if (clusterIpv4CidrBlock != null)
          'clusterIpv4CidrBlock': clusterIpv4CidrBlock!,
        if (clusterSecondaryRangeName != null)
          'clusterSecondaryRangeName': clusterSecondaryRangeName!,
        if (createSubnetwork != null) 'createSubnetwork': createSubnetwork!,
        if (nodeIpv4Cidr != null) 'nodeIpv4Cidr': nodeIpv4Cidr!,
        if (nodeIpv4CidrBlock != null) 'nodeIpv4CidrBlock': nodeIpv4CidrBlock!,
        if (servicesIpv4Cidr != null) 'servicesIpv4Cidr': servicesIpv4Cidr!,
        if (servicesIpv4CidrBlock != null)
          'servicesIpv4CidrBlock': servicesIpv4CidrBlock!,
        if (servicesSecondaryRangeName != null)
          'servicesSecondaryRangeName': servicesSecondaryRangeName!,
        if (subnetworkName != null) 'subnetworkName': subnetworkName!,
        if (tpuIpv4CidrBlock != null) 'tpuIpv4CidrBlock': tpuIpv4CidrBlock!,
        if (useIpAliases != null) 'useIpAliases': useIpAliases!,
        if (useRoutes != null) 'useRoutes': useRoutes!,
      };
}

/// IntraNodeVisibilityConfig contains the desired config of the intra-node
/// visibility on this cluster.
class IntraNodeVisibilityConfig {
  /// Enables intra node visibility for this cluster.
  core.bool? enabled;

  IntraNodeVisibilityConfig();

  IntraNodeVisibilityConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Jwk is a JSON Web Key as specified in RFC 7517
class Jwk {
  /// Algorithm.
  core.String? alg;

  /// Used for ECDSA keys.
  core.String? crv;

  /// Used for RSA keys.
  core.String? e;

  /// Key ID.
  core.String? kid;

  /// Key Type.
  core.String? kty;

  /// Used for RSA keys.
  core.String? n;

  /// Permitted uses for the public keys.
  core.String? use;

  /// Used for ECDSA keys.
  core.String? x;

  /// Used for ECDSA keys.
  core.String? y;

  Jwk();

  Jwk.fromJson(core.Map _json) {
    if (_json.containsKey('alg')) {
      alg = _json['alg'] as core.String;
    }
    if (_json.containsKey('crv')) {
      crv = _json['crv'] as core.String;
    }
    if (_json.containsKey('e')) {
      e = _json['e'] as core.String;
    }
    if (_json.containsKey('kid')) {
      kid = _json['kid'] as core.String;
    }
    if (_json.containsKey('kty')) {
      kty = _json['kty'] as core.String;
    }
    if (_json.containsKey('n')) {
      n = _json['n'] as core.String;
    }
    if (_json.containsKey('use')) {
      use = _json['use'] as core.String;
    }
    if (_json.containsKey('x')) {
      x = _json['x'] as core.String;
    }
    if (_json.containsKey('y')) {
      y = _json['y'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alg != null) 'alg': alg!,
        if (crv != null) 'crv': crv!,
        if (e != null) 'e': e!,
        if (kid != null) 'kid': kid!,
        if (kty != null) 'kty': kty!,
        if (n != null) 'n': n!,
        if (use != null) 'use': use!,
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
      };
}

/// Configuration for the Kubernetes Dashboard.
class KubernetesDashboard {
  /// Whether the Kubernetes Dashboard is enabled for this cluster.
  core.bool? disabled;

  KubernetesDashboard();

  KubernetesDashboard.fromJson(core.Map _json) {
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disabled != null) 'disabled': disabled!,
      };
}

/// Configuration for the legacy Attribute Based Access Control authorization
/// mode.
class LegacyAbac {
  /// Whether the ABAC authorizer is enabled for this cluster.
  ///
  /// When enabled, identities in the system, including service accounts, nodes,
  /// and controllers, will have statically granted permissions beyond those
  /// provided by the RBAC configuration or IAM.
  core.bool? enabled;

  LegacyAbac();

  LegacyAbac.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Parameters that can be configured on Linux nodes.
class LinuxNodeConfig {
  /// The Linux kernel parameters to be applied to the nodes and all pods
  /// running on the nodes.
  ///
  /// The following parameters are supported. net.core.netdev_max_backlog
  /// net.core.rmem_max net.core.wmem_default net.core.wmem_max
  /// net.core.optmem_max net.core.somaxconn net.ipv4.tcp_rmem net.ipv4.tcp_wmem
  /// net.ipv4.tcp_tw_reuse
  core.Map<core.String, core.String>? sysctls;

  LinuxNodeConfig();

  LinuxNodeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('sysctls')) {
      sysctls = (_json['sysctls'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sysctls != null) 'sysctls': sysctls!,
      };
}

/// ListClustersResponse is the result of ListClustersRequest.
class ListClustersResponse {
  /// A list of clusters in the project in the specified zone, or across all
  /// ones.
  core.List<Cluster>? clusters;

  /// If any zones are listed here, the list of clusters returned may be missing
  /// those zones.
  core.List<core.String>? missingZones;

  ListClustersResponse();

  ListClustersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('clusters')) {
      clusters = (_json['clusters'] as core.List)
          .map<Cluster>((value) =>
              Cluster.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('missingZones')) {
      missingZones = (_json['missingZones'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusters != null)
          'clusters': clusters!.map((value) => value.toJson()).toList(),
        if (missingZones != null) 'missingZones': missingZones!,
      };
}

/// ListNodePoolsResponse is the result of ListNodePoolsRequest.
class ListNodePoolsResponse {
  /// A list of node pools for a cluster.
  core.List<NodePool>? nodePools;

  ListNodePoolsResponse();

  ListNodePoolsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nodePools')) {
      nodePools = (_json['nodePools'] as core.List)
          .map<NodePool>((value) =>
              NodePool.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nodePools != null)
          'nodePools': nodePools!.map((value) => value.toJson()).toList(),
      };
}

/// ListOperationsResponse is the result of ListOperationsRequest.
class ListOperationsResponse {
  /// If any zones are listed here, the list of operations returned may be
  /// missing the operations from those zones.
  core.List<core.String>? missingZones;

  /// A list of operations in the project in the specified zone.
  core.List<Operation>? operations;

  ListOperationsResponse();

  ListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('missingZones')) {
      missingZones = (_json['missingZones'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<Operation>((value) =>
              Operation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (missingZones != null) 'missingZones': missingZones!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// ListUsableSubnetworksResponse is the response of
/// ListUsableSubnetworksRequest.
class ListUsableSubnetworksResponse {
  /// This token allows you to get the next page of results for list requests.
  ///
  /// If the number of results is larger than `page_size`, use the
  /// `next_page_token` as a value for the query parameter `page_token` in the
  /// next request. The value will become empty when there are no more pages.
  core.String? nextPageToken;

  /// A list of usable subnetworks in the specified network project.
  core.List<UsableSubnetwork>? subnetworks;

  ListUsableSubnetworksResponse();

  ListUsableSubnetworksResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('subnetworks')) {
      subnetworks = (_json['subnetworks'] as core.List)
          .map<UsableSubnetwork>((value) => UsableSubnetwork.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (subnetworks != null)
          'subnetworks': subnetworks!.map((value) => value.toJson()).toList(),
      };
}

/// MaintenancePolicy defines the maintenance policy to be used for the cluster.
class MaintenancePolicy {
  /// A hash identifying the version of this policy, so that updates to fields
  /// of the policy won't accidentally undo intermediate changes (and so that
  /// users of the API unaware of some fields won't accidentally remove other
  /// fields).
  ///
  /// Make a `get()` request to the cluster to get the current resource version
  /// and include it with requests to set the policy.
  core.String? resourceVersion;

  /// Specifies the maintenance window in which maintenance may be performed.
  MaintenanceWindow? window;

  MaintenancePolicy();

  MaintenancePolicy.fromJson(core.Map _json) {
    if (_json.containsKey('resourceVersion')) {
      resourceVersion = _json['resourceVersion'] as core.String;
    }
    if (_json.containsKey('window')) {
      window = MaintenanceWindow.fromJson(
          _json['window'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceVersion != null) 'resourceVersion': resourceVersion!,
        if (window != null) 'window': window!.toJson(),
      };
}

/// MaintenanceWindow defines the maintenance window to be used for the cluster.
class MaintenanceWindow {
  /// DailyMaintenanceWindow specifies a daily maintenance operation window.
  DailyMaintenanceWindow? dailyMaintenanceWindow;

  /// Exceptions to maintenance window.
  ///
  /// Non-emergency maintenance should not occur in these windows.
  core.Map<core.String, TimeWindow>? maintenanceExclusions;

  /// RecurringWindow specifies some number of recurring time periods for
  /// maintenance to occur.
  ///
  /// The time windows may be overlapping. If no maintenance windows are set,
  /// maintenance can occur at any time.
  RecurringTimeWindow? recurringWindow;

  MaintenanceWindow();

  MaintenanceWindow.fromJson(core.Map _json) {
    if (_json.containsKey('dailyMaintenanceWindow')) {
      dailyMaintenanceWindow = DailyMaintenanceWindow.fromJson(
          _json['dailyMaintenanceWindow']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maintenanceExclusions')) {
      maintenanceExclusions = (_json['maintenanceExclusions']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          TimeWindow.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('recurringWindow')) {
      recurringWindow = RecurringTimeWindow.fromJson(
          _json['recurringWindow'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dailyMaintenanceWindow != null)
          'dailyMaintenanceWindow': dailyMaintenanceWindow!.toJson(),
        if (maintenanceExclusions != null)
          'maintenanceExclusions': maintenanceExclusions!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (recurringWindow != null)
          'recurringWindow': recurringWindow!.toJson(),
      };
}

/// The authentication information for accessing the master endpoint.
///
/// Authentication can be done using HTTP basic auth or using client
/// certificates.
class MasterAuth {
  /// Base64-encoded public certificate used by clients to authenticate to the
  /// cluster endpoint.
  ///
  /// Output only.
  core.String? clientCertificate;

  /// Configuration for client certificate authentication on the cluster.
  ///
  /// For clusters before v1.12, if no configuration is specified, a client
  /// certificate is issued.
  ClientCertificateConfig? clientCertificateConfig;

  /// Base64-encoded private key used by clients to authenticate to the cluster
  /// endpoint.
  ///
  /// Output only.
  core.String? clientKey;

  /// Base64-encoded public certificate that is the root of trust for the
  /// cluster.
  ///
  /// Output only.
  core.String? clusterCaCertificate;

  /// The password to use for HTTP basic authentication to the master endpoint.
  ///
  /// Because the master endpoint is open to the Internet, you should create a
  /// strong password. If a password is provided for cluster creation, username
  /// must be non-empty. Warning: basic authentication is deprecated, and will
  /// be removed in GKE control plane versions 1.19 and newer. For a list of
  /// recommended authentication methods, see:
  /// https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication
  core.String? password;

  /// The username to use for HTTP basic authentication to the master endpoint.
  ///
  /// For clusters v1.6.0 and later, basic authentication can be disabled by
  /// leaving username unspecified (or setting it to the empty string). Warning:
  /// basic authentication is deprecated, and will be removed in GKE control
  /// plane versions 1.19 and newer. For a list of recommended authentication
  /// methods, see:
  /// https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication
  core.String? username;

  MasterAuth();

  MasterAuth.fromJson(core.Map _json) {
    if (_json.containsKey('clientCertificate')) {
      clientCertificate = _json['clientCertificate'] as core.String;
    }
    if (_json.containsKey('clientCertificateConfig')) {
      clientCertificateConfig = ClientCertificateConfig.fromJson(
          _json['clientCertificateConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clientKey')) {
      clientKey = _json['clientKey'] as core.String;
    }
    if (_json.containsKey('clusterCaCertificate')) {
      clusterCaCertificate = _json['clusterCaCertificate'] as core.String;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('username')) {
      username = _json['username'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientCertificate != null) 'clientCertificate': clientCertificate!,
        if (clientCertificateConfig != null)
          'clientCertificateConfig': clientCertificateConfig!.toJson(),
        if (clientKey != null) 'clientKey': clientKey!,
        if (clusterCaCertificate != null)
          'clusterCaCertificate': clusterCaCertificate!,
        if (password != null) 'password': password!,
        if (username != null) 'username': username!,
      };
}

/// Configuration options for the master authorized networks feature.
///
/// Enabled master authorized networks will disallow all external traffic to
/// access Kubernetes master through HTTPS except traffic from the given CIDR
/// blocks, Google Compute Engine Public IPs and Google Prod IPs.
class MasterAuthorizedNetworksConfig {
  /// cidr_blocks define up to 50 external networks that could access Kubernetes
  /// master through HTTPS.
  core.List<CidrBlock>? cidrBlocks;

  /// Whether or not master authorized networks is enabled.
  core.bool? enabled;

  MasterAuthorizedNetworksConfig();

  MasterAuthorizedNetworksConfig.fromJson(core.Map _json) {
    if (_json.containsKey('cidrBlocks')) {
      cidrBlocks = (_json['cidrBlocks'] as core.List)
          .map<CidrBlock>((value) =>
              CidrBlock.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cidrBlocks != null)
          'cidrBlocks': cidrBlocks!.map((value) => value.toJson()).toList(),
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Constraints applied to pods.
class MaxPodsConstraint {
  /// Constraint enforced on the max num of pods per node.
  core.String? maxPodsPerNode;

  MaxPodsConstraint();

  MaxPodsConstraint.fromJson(core.Map _json) {
    if (_json.containsKey('maxPodsPerNode')) {
      maxPodsPerNode = _json['maxPodsPerNode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxPodsPerNode != null) 'maxPodsPerNode': maxPodsPerNode!,
      };
}

/// Progress metric is (string, int|float|string) pair.
class Metric {
  /// For metrics with floating point value.
  core.double? doubleValue;

  /// For metrics with integer value.
  core.String? intValue;

  /// Metric name, e.g., "nodes total", "percent done".
  ///
  /// Required.
  core.String? name;

  /// For metrics with custom values (ratios, visual progress, etc.).
  core.String? stringValue;

  Metric();

  Metric.fromJson(core.Map _json) {
    if (_json.containsKey('doubleValue')) {
      doubleValue = (_json['doubleValue'] as core.num).toDouble();
    }
    if (_json.containsKey('intValue')) {
      intValue = _json['intValue'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (doubleValue != null) 'doubleValue': doubleValue!,
        if (intValue != null) 'intValue': intValue!,
        if (name != null) 'name': name!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// NetworkConfig reports the relative names of network & subnetwork.
class NetworkConfig {
  /// The desired datapath provider for this cluster.
  ///
  /// By default, uses the IPTables-based kube-proxy implementation.
  /// Possible string values are:
  /// - "DATAPATH_PROVIDER_UNSPECIFIED" : Default value.
  /// - "LEGACY_DATAPATH" : Use the IPTables implementation based on kube-proxy.
  /// - "ADVANCED_DATAPATH" : Use the eBPF based GKE Dataplane V2 with
  /// additional features. See the
  /// [GKE Dataplane V2 documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2)
  /// for more.
  core.String? datapathProvider;

  /// Whether the cluster disables default in-node sNAT rules.
  ///
  /// In-node sNAT rules will be disabled when default_snat_status is disabled.
  /// When disabled is set to false, default IP masquerade rules will be applied
  /// to the nodes to prevent sNAT on cluster internal traffic.
  DefaultSnatStatus? defaultSnatStatus;

  /// Whether Intra-node visibility is enabled for this cluster.
  ///
  /// This makes same node pod to pod traffic visible for VPC network.
  core.bool? enableIntraNodeVisibility;

  /// The relative name of the Google Compute Engine
  /// network(https://cloud.google.com/compute/docs/networks-and-firewalls#networks)
  /// to which the cluster is connected.
  ///
  /// Example: projects/my-project/global/networks/my-network
  ///
  /// Output only.
  core.String? network;

  /// The desired state of IPv6 connectivity to Google Services.
  ///
  /// By default, no private IPv6 access to or from Google Services (all access
  /// will be via IPv4)
  /// Possible string values are:
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_UNSPECIFIED" : Default value. Same as
  /// DISABLED
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_DISABLED" : No private access to or from
  /// Google Services
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_TO_GOOGLE" : Enables private IPv6 access to
  /// Google Services from GKE
  /// - "PRIVATE_IPV6_GOOGLE_ACCESS_BIDIRECTIONAL" : Enables priate IPv6 access
  /// to and from Google Services
  core.String? privateIpv6GoogleAccess;

  /// The relative name of the Google Compute Engine
  /// [subnetwork](https://cloud.google.com/compute/docs/vpc) to which the
  /// cluster is connected.
  ///
  /// Example: projects/my-project/regions/us-central1/subnetworks/my-subnet
  ///
  /// Output only.
  core.String? subnetwork;

  NetworkConfig();

  NetworkConfig.fromJson(core.Map _json) {
    if (_json.containsKey('datapathProvider')) {
      datapathProvider = _json['datapathProvider'] as core.String;
    }
    if (_json.containsKey('defaultSnatStatus')) {
      defaultSnatStatus = DefaultSnatStatus.fromJson(
          _json['defaultSnatStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enableIntraNodeVisibility')) {
      enableIntraNodeVisibility =
          _json['enableIntraNodeVisibility'] as core.bool;
    }
    if (_json.containsKey('network')) {
      network = _json['network'] as core.String;
    }
    if (_json.containsKey('privateIpv6GoogleAccess')) {
      privateIpv6GoogleAccess = _json['privateIpv6GoogleAccess'] as core.String;
    }
    if (_json.containsKey('subnetwork')) {
      subnetwork = _json['subnetwork'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datapathProvider != null) 'datapathProvider': datapathProvider!,
        if (defaultSnatStatus != null)
          'defaultSnatStatus': defaultSnatStatus!.toJson(),
        if (enableIntraNodeVisibility != null)
          'enableIntraNodeVisibility': enableIntraNodeVisibility!,
        if (network != null) 'network': network!,
        if (privateIpv6GoogleAccess != null)
          'privateIpv6GoogleAccess': privateIpv6GoogleAccess!,
        if (subnetwork != null) 'subnetwork': subnetwork!,
      };
}

/// Configuration options for the NetworkPolicy feature.
///
/// https://kubernetes.io/docs/concepts/services-networking/networkpolicies/
class NetworkPolicy {
  /// Whether network policy is enabled on the cluster.
  core.bool? enabled;

  /// The selected network policy provider.
  /// Possible string values are:
  /// - "PROVIDER_UNSPECIFIED" : Not set
  /// - "CALICO" : Tigera (Calico Felix).
  core.String? provider;

  NetworkPolicy();

  NetworkPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('provider')) {
      provider = _json['provider'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
        if (provider != null) 'provider': provider!,
      };
}

/// Configuration for NetworkPolicy.
///
/// This only tracks whether the addon is enabled or not on the Master, it does
/// not track whether network policy is enabled for the nodes.
class NetworkPolicyConfig {
  /// Whether NetworkPolicy is enabled for this cluster.
  core.bool? disabled;

  NetworkPolicyConfig();

  NetworkPolicyConfig.fromJson(core.Map _json) {
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disabled != null) 'disabled': disabled!,
      };
}

/// Parameters that describe the nodes in a cluster.
class NodeConfig {
  /// A list of hardware accelerators to be attached to each node.
  ///
  /// See https://cloud.google.com/compute/docs/gpus for more information about
  /// support for GPUs.
  core.List<AcceleratorConfig>? accelerators;

  /// The Customer Managed Encryption Key used to encrypt the boot disk attached
  /// to each node in the node pool.
  ///
  /// This should be of the form
  /// projects/\[KEY_PROJECT_ID\]/locations/\[LOCATION\]/keyRings/\[RING_NAME\]/cryptoKeys/\[KEY_NAME\].
  /// For more information about protecting resources with Cloud KMS Keys please
  /// see:
  /// https://cloud.google.com/compute/docs/disks/customer-managed-encryption
  core.String? bootDiskKmsKey;

  /// Size of the disk attached to each node, specified in GB.
  ///
  /// The smallest allowed disk size is 10GB. If unspecified, the default disk
  /// size is 100GB.
  core.int? diskSizeGb;

  /// Type of the disk attached to each node (e.g. 'pd-standard', 'pd-ssd' or
  /// 'pd-balanced') If unspecified, the default disk type is 'pd-standard'
  core.String? diskType;

  /// The image type to use for this node.
  ///
  /// Note that for a given image type, the latest version of it will be used.
  core.String? imageType;

  /// Node kubelet configs.
  NodeKubeletConfig? kubeletConfig;

  /// The map of Kubernetes labels (key/value pairs) to be applied to each node.
  ///
  /// These will added in addition to any default label(s) that Kubernetes may
  /// apply to the node. In case of conflict in label keys, the applied set may
  /// differ depending on the Kubernetes version -- it's best to assume the
  /// behavior is undefined and conflicts should be avoided. For more
  /// information, including usage and the valid values, see:
  /// https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  core.Map<core.String, core.String>? labels;

  /// Parameters that can be configured on Linux nodes.
  LinuxNodeConfig? linuxNodeConfig;

  /// The number of local SSD disks to be attached to the node.
  ///
  /// The limit for this value is dependent upon the maximum number of disks
  /// available on a machine per zone. See:
  /// https://cloud.google.com/compute/docs/disks/local-ssd for more
  /// information.
  core.int? localSsdCount;

  /// The name of a Google Compute Engine
  /// [machine type](https://cloud.google.com/compute/docs/machine-types) If
  /// unspecified, the default machine type is `e2-medium`.
  core.String? machineType;

  /// The metadata key/value pairs assigned to instances in the cluster.
  ///
  /// Keys must conform to the regexp `[a-zA-Z0-9-_]+` and be less than 128
  /// bytes in length. These are reflected as part of a URL in the metadata
  /// server. Additionally, to avoid ambiguity, keys must not conflict with any
  /// other metadata keys for the project or be one of the reserved keys: -
  /// "cluster-location" - "cluster-name" - "cluster-uid" - "configure-sh" -
  /// "containerd-configure-sh" - "enable-os-login" - "gci-ensure-gke-docker" -
  /// "gci-metrics-enabled" - "gci-update-strategy" - "instance-template" -
  /// "kube-env" - "startup-script" - "user-data" - "disable-address-manager" -
  /// "windows-startup-script-ps1" - "common-psm1" - "k8s-node-setup-psm1" -
  /// "install-ssh-psm1" - "user-profile-psm1" The following keys are reserved
  /// for Windows nodes: - "serial-port-logging-enable" Values are free-form
  /// strings, and only have meaning as interpreted by the image running in the
  /// instance. The only restriction placed on them is that each value's size
  /// must be less than or equal to 32 KB. The total size of all keys and values
  /// must be less than 512 KB.
  core.Map<core.String, core.String>? metadata;

  /// Minimum CPU platform to be used by this instance.
  ///
  /// The instance may be scheduled on the specified or newer CPU platform.
  /// Applicable values are the friendly names of CPU platforms, such as
  /// `minCpuPlatform: "Intel Haswell"` or `minCpuPlatform: "Intel Sandy
  /// Bridge"`. For more information, read
  /// [how to specify min CPU platform](https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform)
  core.String? minCpuPlatform;

  /// Setting this field will assign instances of this pool to run on the
  /// specified node group.
  ///
  /// This is useful for running workloads on
  /// [sole tenant nodes](https://cloud.google.com/compute/docs/nodes/sole-tenant-nodes).
  core.String? nodeGroup;

  /// The set of Google API scopes to be made available on all of the node VMs
  /// under the "default" service account.
  ///
  /// The following scopes are recommended, but not required, and by default are
  /// not included: * `https://www.googleapis.com/auth/compute` is required for
  /// mounting persistent storage on your nodes. *
  /// `https://www.googleapis.com/auth/devstorage.read_only` is required for
  /// communicating with **gcr.io** (the
  /// [Google Container Registry](https://cloud.google.com/container-registry/)).
  /// If unspecified, no scopes are added, unless Cloud Logging or Cloud
  /// Monitoring are enabled, in which case their required scopes will be added.
  core.List<core.String>? oauthScopes;

  /// Whether the nodes are created as preemptible VM instances.
  ///
  /// See: https://cloud.google.com/compute/docs/instances/preemptible for more
  /// information about preemptible VM instances.
  core.bool? preemptible;

  /// The optional reservation affinity.
  ///
  /// Setting this field will apply the specified
  /// [Zonal Compute Reservation](https://cloud.google.com/compute/docs/instances/reserving-zonal-resources)
  /// to this node pool.
  ReservationAffinity? reservationAffinity;

  /// Sandbox configuration for this node.
  SandboxConfig? sandboxConfig;

  /// The Google Cloud Platform Service Account to be used by the node VMs.
  ///
  /// Specify the email address of the Service Account; otherwise, if no Service
  /// Account is specified, the "default" service account is used.
  core.String? serviceAccount;

  /// Shielded Instance options.
  ShieldedInstanceConfig? shieldedInstanceConfig;

  /// The list of instance tags applied to all nodes.
  ///
  /// Tags are used to identify valid sources or targets for network firewalls
  /// and are specified by the client during cluster or node pool creation. Each
  /// tag within the list must comply with RFC1035.
  core.List<core.String>? tags;

  /// List of kubernetes taints to be applied to each node.
  ///
  /// For more information, including usage and the valid values, see:
  /// https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  core.List<NodeTaint>? taints;

  /// The workload metadata configuration for this node.
  WorkloadMetadataConfig? workloadMetadataConfig;

  NodeConfig();

  NodeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('accelerators')) {
      accelerators = (_json['accelerators'] as core.List)
          .map<AcceleratorConfig>((value) => AcceleratorConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('bootDiskKmsKey')) {
      bootDiskKmsKey = _json['bootDiskKmsKey'] as core.String;
    }
    if (_json.containsKey('diskSizeGb')) {
      diskSizeGb = _json['diskSizeGb'] as core.int;
    }
    if (_json.containsKey('diskType')) {
      diskType = _json['diskType'] as core.String;
    }
    if (_json.containsKey('imageType')) {
      imageType = _json['imageType'] as core.String;
    }
    if (_json.containsKey('kubeletConfig')) {
      kubeletConfig = NodeKubeletConfig.fromJson(
          _json['kubeletConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('linuxNodeConfig')) {
      linuxNodeConfig = LinuxNodeConfig.fromJson(
          _json['linuxNodeConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('localSsdCount')) {
      localSsdCount = _json['localSsdCount'] as core.int;
    }
    if (_json.containsKey('machineType')) {
      machineType = _json['machineType'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('minCpuPlatform')) {
      minCpuPlatform = _json['minCpuPlatform'] as core.String;
    }
    if (_json.containsKey('nodeGroup')) {
      nodeGroup = _json['nodeGroup'] as core.String;
    }
    if (_json.containsKey('oauthScopes')) {
      oauthScopes = (_json['oauthScopes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('preemptible')) {
      preemptible = _json['preemptible'] as core.bool;
    }
    if (_json.containsKey('reservationAffinity')) {
      reservationAffinity = ReservationAffinity.fromJson(
          _json['reservationAffinity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sandboxConfig')) {
      sandboxConfig = SandboxConfig.fromJson(
          _json['sandboxConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('serviceAccount')) {
      serviceAccount = _json['serviceAccount'] as core.String;
    }
    if (_json.containsKey('shieldedInstanceConfig')) {
      shieldedInstanceConfig = ShieldedInstanceConfig.fromJson(
          _json['shieldedInstanceConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('taints')) {
      taints = (_json['taints'] as core.List)
          .map<NodeTaint>((value) =>
              NodeTaint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('workloadMetadataConfig')) {
      workloadMetadataConfig = WorkloadMetadataConfig.fromJson(
          _json['workloadMetadataConfig']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accelerators != null)
          'accelerators': accelerators!.map((value) => value.toJson()).toList(),
        if (bootDiskKmsKey != null) 'bootDiskKmsKey': bootDiskKmsKey!,
        if (diskSizeGb != null) 'diskSizeGb': diskSizeGb!,
        if (diskType != null) 'diskType': diskType!,
        if (imageType != null) 'imageType': imageType!,
        if (kubeletConfig != null) 'kubeletConfig': kubeletConfig!.toJson(),
        if (labels != null) 'labels': labels!,
        if (linuxNodeConfig != null)
          'linuxNodeConfig': linuxNodeConfig!.toJson(),
        if (localSsdCount != null) 'localSsdCount': localSsdCount!,
        if (machineType != null) 'machineType': machineType!,
        if (metadata != null) 'metadata': metadata!,
        if (minCpuPlatform != null) 'minCpuPlatform': minCpuPlatform!,
        if (nodeGroup != null) 'nodeGroup': nodeGroup!,
        if (oauthScopes != null) 'oauthScopes': oauthScopes!,
        if (preemptible != null) 'preemptible': preemptible!,
        if (reservationAffinity != null)
          'reservationAffinity': reservationAffinity!.toJson(),
        if (sandboxConfig != null) 'sandboxConfig': sandboxConfig!.toJson(),
        if (serviceAccount != null) 'serviceAccount': serviceAccount!,
        if (shieldedInstanceConfig != null)
          'shieldedInstanceConfig': shieldedInstanceConfig!.toJson(),
        if (tags != null) 'tags': tags!,
        if (taints != null)
          'taints': taints!.map((value) => value.toJson()).toList(),
        if (workloadMetadataConfig != null)
          'workloadMetadataConfig': workloadMetadataConfig!.toJson(),
      };
}

/// Node kubelet configs.
class NodeKubeletConfig {
  /// Enable CPU CFS quota enforcement for containers that specify CPU limits.
  ///
  /// This option is enabled by default which makes kubelet use CFS quota
  /// (https://www.kernel.org/doc/Documentation/scheduler/sched-bwc.txt) to
  /// enforce container CPU limits. Otherwise, CPU limits will not be enforced
  /// at all. Disable this option to mitigate CPU throttling problems while
  /// still having your pods to be in Guaranteed QoS class by specifying the CPU
  /// limits. The default value is 'true' if unspecified.
  core.bool? cpuCfsQuota;

  /// Set the CPU CFS quota period value 'cpu.cfs_period_us'.
  ///
  /// The string must be a sequence of decimal numbers, each with optional
  /// fraction and a unit suffix, such as "300ms". Valid time units are "ns",
  /// "us" (or "µs"), "ms", "s", "m", "h". The value must be a positive
  /// duration.
  core.String? cpuCfsQuotaPeriod;

  /// Control the CPU management policy on the node.
  ///
  /// See
  /// https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/
  /// The following values are allowed. - "none": the default, which represents
  /// the existing scheduling behavior. - "static": allows pods with certain
  /// resource characteristics to be granted increased CPU affinity and
  /// exclusivity on the node. The default value is 'none' if unspecified.
  core.String? cpuManagerPolicy;

  NodeKubeletConfig();

  NodeKubeletConfig.fromJson(core.Map _json) {
    if (_json.containsKey('cpuCfsQuota')) {
      cpuCfsQuota = _json['cpuCfsQuota'] as core.bool;
    }
    if (_json.containsKey('cpuCfsQuotaPeriod')) {
      cpuCfsQuotaPeriod = _json['cpuCfsQuotaPeriod'] as core.String;
    }
    if (_json.containsKey('cpuManagerPolicy')) {
      cpuManagerPolicy = _json['cpuManagerPolicy'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cpuCfsQuota != null) 'cpuCfsQuota': cpuCfsQuota!,
        if (cpuCfsQuotaPeriod != null) 'cpuCfsQuotaPeriod': cpuCfsQuotaPeriod!,
        if (cpuManagerPolicy != null) 'cpuManagerPolicy': cpuManagerPolicy!,
      };
}

/// NodeManagement defines the set of node management services turned on for the
/// node pool.
class NodeManagement {
  /// A flag that specifies whether the node auto-repair is enabled for the node
  /// pool.
  ///
  /// If enabled, the nodes in this node pool will be monitored and, if they
  /// fail health checks too many times, an automatic repair action will be
  /// triggered.
  core.bool? autoRepair;

  /// A flag that specifies whether node auto-upgrade is enabled for the node
  /// pool.
  ///
  /// If enabled, node auto-upgrade helps keep the nodes in your node pool up to
  /// date with the latest release version of Kubernetes.
  core.bool? autoUpgrade;

  /// Specifies the Auto Upgrade knobs for the node pool.
  AutoUpgradeOptions? upgradeOptions;

  NodeManagement();

  NodeManagement.fromJson(core.Map _json) {
    if (_json.containsKey('autoRepair')) {
      autoRepair = _json['autoRepair'] as core.bool;
    }
    if (_json.containsKey('autoUpgrade')) {
      autoUpgrade = _json['autoUpgrade'] as core.bool;
    }
    if (_json.containsKey('upgradeOptions')) {
      upgradeOptions = AutoUpgradeOptions.fromJson(
          _json['upgradeOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoRepair != null) 'autoRepair': autoRepair!,
        if (autoUpgrade != null) 'autoUpgrade': autoUpgrade!,
        if (upgradeOptions != null) 'upgradeOptions': upgradeOptions!.toJson(),
      };
}

/// NodePool contains the name and configuration for a cluster's node pool.
///
/// Node pools are a set of nodes (i.e. VM's), with a common configuration and
/// specification, under the control of the cluster master. They may have a set
/// of Kubernetes labels applied to them, which may be used to reference them
/// during pod scheduling. They may also be resized up or down, to accommodate
/// the workload.
class NodePool {
  /// Autoscaler configuration for this NodePool.
  ///
  /// Autoscaler is enabled only if a valid configuration is present.
  NodePoolAutoscaling? autoscaling;

  /// Which conditions caused the current node pool state.
  core.List<StatusCondition>? conditions;

  /// The node configuration of the pool.
  NodeConfig? config;

  /// The initial node count for the pool.
  ///
  /// You must ensure that your Compute Engine
  /// [resource quota](https://cloud.google.com/compute/quotas) is sufficient
  /// for this number of instances. You must also have available firewall and
  /// routes quota.
  core.int? initialNodeCount;

  /// The resource URLs of the
  /// [managed instance groups](https://cloud.google.com/compute/docs/instance-groups/creating-groups-of-managed-instances)
  /// associated with this node pool.
  ///
  /// Output only.
  core.List<core.String>? instanceGroupUrls;

  /// The list of Google Compute Engine
  /// [zones](https://cloud.google.com/compute/docs/zones#available) in which
  /// the NodePool's nodes should be located.
  ///
  /// If this value is unspecified during node pool creation, the
  /// [Cluster.Locations](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.locations.clusters#Cluster.FIELDS.locations)
  /// value will be used, instead. Warning: changing node pool locations will
  /// result in nodes being added and/or removed.
  core.List<core.String>? locations;

  /// NodeManagement configuration for this NodePool.
  NodeManagement? management;

  /// The constraint on the maximum number of pods that can be run
  /// simultaneously on a node in the node pool.
  MaxPodsConstraint? maxPodsConstraint;

  /// The name of the node pool.
  core.String? name;

  /// The pod CIDR block size per node in this node pool.
  ///
  /// Output only.
  core.int? podIpv4CidrSize;

  /// Server-defined URL for the resource.
  ///
  /// Output only.
  core.String? selfLink;

  /// The status of the nodes in this pool instance.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Not set.
  /// - "PROVISIONING" : The PROVISIONING state indicates the node pool is being
  /// created.
  /// - "RUNNING" : The RUNNING state indicates the node pool has been created
  /// and is fully usable.
  /// - "RUNNING_WITH_ERROR" : The RUNNING_WITH_ERROR state indicates the node
  /// pool has been created and is partially usable. Some error state has
  /// occurred and some functionality may be impaired. Customer may need to
  /// reissue a request or trigger a new update.
  /// - "RECONCILING" : The RECONCILING state indicates that some work is
  /// actively being done on the node pool, such as upgrading node software.
  /// Details can be found in the `statusMessage` field.
  /// - "STOPPING" : The STOPPING state indicates the node pool is being
  /// deleted.
  /// - "ERROR" : The ERROR state indicates the node pool may be unusable.
  /// Details can be found in the `statusMessage` field.
  core.String? status;

  /// Use conditions instead.
  ///
  /// Additional information about the current status of this node pool
  /// instance, if available.
  ///
  /// Output only. Deprecated.
  core.String? statusMessage;

  /// Upgrade settings control disruption and speed of the upgrade.
  UpgradeSettings? upgradeSettings;

  /// The version of the Kubernetes of this node.
  core.String? version;

  NodePool();

  NodePool.fromJson(core.Map _json) {
    if (_json.containsKey('autoscaling')) {
      autoscaling = NodePoolAutoscaling.fromJson(
          _json['autoscaling'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<StatusCondition>((value) => StatusCondition.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('config')) {
      config = NodeConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('initialNodeCount')) {
      initialNodeCount = _json['initialNodeCount'] as core.int;
    }
    if (_json.containsKey('instanceGroupUrls')) {
      instanceGroupUrls = (_json['instanceGroupUrls'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('management')) {
      management = NodeManagement.fromJson(
          _json['management'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maxPodsConstraint')) {
      maxPodsConstraint = MaxPodsConstraint.fromJson(
          _json['maxPodsConstraint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('podIpv4CidrSize')) {
      podIpv4CidrSize = _json['podIpv4CidrSize'] as core.int;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('statusMessage')) {
      statusMessage = _json['statusMessage'] as core.String;
    }
    if (_json.containsKey('upgradeSettings')) {
      upgradeSettings = UpgradeSettings.fromJson(
          _json['upgradeSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoscaling != null) 'autoscaling': autoscaling!.toJson(),
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
        if (config != null) 'config': config!.toJson(),
        if (initialNodeCount != null) 'initialNodeCount': initialNodeCount!,
        if (instanceGroupUrls != null) 'instanceGroupUrls': instanceGroupUrls!,
        if (locations != null) 'locations': locations!,
        if (management != null) 'management': management!.toJson(),
        if (maxPodsConstraint != null)
          'maxPodsConstraint': maxPodsConstraint!.toJson(),
        if (name != null) 'name': name!,
        if (podIpv4CidrSize != null) 'podIpv4CidrSize': podIpv4CidrSize!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (status != null) 'status': status!,
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (upgradeSettings != null)
          'upgradeSettings': upgradeSettings!.toJson(),
        if (version != null) 'version': version!,
      };
}

/// NodePoolAutoscaling contains information required by cluster autoscaler to
/// adjust the size of the node pool to the current cluster usage.
class NodePoolAutoscaling {
  /// Can this node pool be deleted automatically.
  core.bool? autoprovisioned;

  /// Is autoscaling enabled for this node pool.
  core.bool? enabled;

  /// Maximum number of nodes in the NodePool.
  ///
  /// Must be >= min_node_count. There has to enough quota to scale up the
  /// cluster.
  core.int? maxNodeCount;

  /// Minimum number of nodes in the NodePool.
  ///
  /// Must be >= 1 and <= max_node_count.
  core.int? minNodeCount;

  NodePoolAutoscaling();

  NodePoolAutoscaling.fromJson(core.Map _json) {
    if (_json.containsKey('autoprovisioned')) {
      autoprovisioned = _json['autoprovisioned'] as core.bool;
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('maxNodeCount')) {
      maxNodeCount = _json['maxNodeCount'] as core.int;
    }
    if (_json.containsKey('minNodeCount')) {
      minNodeCount = _json['minNodeCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoprovisioned != null) 'autoprovisioned': autoprovisioned!,
        if (enabled != null) 'enabled': enabled!,
        if (maxNodeCount != null) 'maxNodeCount': maxNodeCount!,
        if (minNodeCount != null) 'minNodeCount': minNodeCount!,
      };
}

/// Kubernetes taint is comprised of three fields: key, value, and effect.
///
/// Effect can only be one of three types: NoSchedule, PreferNoSchedule or
/// NoExecute. See
/// [here](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration)
/// for more information, including usage and the valid values.
class NodeTaint {
  /// Effect for taint.
  /// Possible string values are:
  /// - "EFFECT_UNSPECIFIED" : Not set
  /// - "NO_SCHEDULE" : NoSchedule
  /// - "PREFER_NO_SCHEDULE" : PreferNoSchedule
  /// - "NO_EXECUTE" : NoExecute
  core.String? effect;

  /// Key for taint.
  core.String? key;

  /// Value for taint.
  core.String? value;

  NodeTaint();

  NodeTaint.fromJson(core.Map _json) {
    if (_json.containsKey('effect')) {
      effect = _json['effect'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (effect != null) 'effect': effect!,
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

/// NotificationConfig is the configuration of notifications.
class NotificationConfig {
  /// Notification config for Pub/Sub.
  PubSub? pubsub;

  NotificationConfig();

  NotificationConfig.fromJson(core.Map _json) {
    if (_json.containsKey('pubsub')) {
      pubsub = PubSub.fromJson(
          _json['pubsub'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pubsub != null) 'pubsub': pubsub!.toJson(),
      };
}

/// This operation resource represents operations that may have happened or are
/// happening on the cluster.
///
/// All fields are output only.
class Operation {
  /// Which conditions caused the current cluster state.
  ///
  /// Deprecated. Use field error instead.
  core.List<StatusCondition>? clusterConditions;

  /// Detailed operation progress, if available.
  core.String? detail;

  /// The time the operation completed, in
  /// [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.
  ///
  /// Output only.
  core.String? endTime;

  /// The error result of the operation in case of failure.
  Status? error;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/regions-zones/regions-zones#available)
  /// or
  /// [region](https://cloud.google.com/compute/docs/regions-zones/regions-zones#available)
  /// in which the cluster resides.
  ///
  /// Output only.
  core.String? location;

  /// The server-assigned ID for the operation.
  core.String? name;

  /// Which conditions caused the current node pool state.
  ///
  /// Deprecated. Use field error instead.
  core.List<StatusCondition>? nodepoolConditions;

  /// The operation type.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Not set.
  /// - "CREATE_CLUSTER" : Cluster create.
  /// - "DELETE_CLUSTER" : Cluster delete.
  /// - "UPGRADE_MASTER" : A master upgrade.
  /// - "UPGRADE_NODES" : A node upgrade.
  /// - "REPAIR_CLUSTER" : Cluster repair.
  /// - "UPDATE_CLUSTER" : Cluster update.
  /// - "CREATE_NODE_POOL" : Node pool create.
  /// - "DELETE_NODE_POOL" : Node pool delete.
  /// - "SET_NODE_POOL_MANAGEMENT" : Set node pool management.
  /// - "AUTO_REPAIR_NODES" : Automatic node pool repair.
  /// - "AUTO_UPGRADE_NODES" : Automatic node upgrade.
  /// - "SET_LABELS" : Set labels.
  /// - "SET_MASTER_AUTH" : Set/generate master auth materials
  /// - "SET_NODE_POOL_SIZE" : Set node pool size.
  /// - "SET_NETWORK_POLICY" : Updates network policy for a cluster.
  /// - "SET_MAINTENANCE_POLICY" : Set the maintenance policy.
  core.String? operationType;

  /// Progress information for an operation.
  ///
  /// Output only.
  OperationProgress? progress;

  /// Server-defined URL for the resource.
  core.String? selfLink;

  /// The time the operation started, in
  /// [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format.
  ///
  /// Output only.
  core.String? startTime;

  /// The current status of the operation.
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Not set.
  /// - "PENDING" : The operation has been created.
  /// - "RUNNING" : The operation is currently running.
  /// - "DONE" : The operation is done, either cancelled or completed.
  /// - "ABORTING" : The operation is aborting.
  core.String? status;

  /// If an error has occurred, a textual description of the error.
  ///
  /// Deprecated. Use the field error instead.
  ///
  /// Output only.
  core.String? statusMessage;

  /// Server-defined URL for the target of the operation.
  core.String? targetLink;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// operation is taking place.
  ///
  /// This field is deprecated, use location instead.
  core.String? zone;

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('clusterConditions')) {
      clusterConditions = (_json['clusterConditions'] as core.List)
          .map<StatusCondition>((value) => StatusCondition.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nodepoolConditions')) {
      nodepoolConditions = (_json['nodepoolConditions'] as core.List)
          .map<StatusCondition>((value) => StatusCondition.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('progress')) {
      progress = OperationProgress.fromJson(
          _json['progress'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('targetLink')) {
      targetLink = _json['targetLink'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterConditions != null)
          'clusterConditions':
              clusterConditions!.map((value) => value.toJson()).toList(),
        if (detail != null) 'detail': detail!,
        if (endTime != null) 'endTime': endTime!,
        if (error != null) 'error': error!.toJson(),
        if (location != null) 'location': location!,
        if (name != null) 'name': name!,
        if (nodepoolConditions != null)
          'nodepoolConditions':
              nodepoolConditions!.map((value) => value.toJson()).toList(),
        if (operationType != null) 'operationType': operationType!,
        if (progress != null) 'progress': progress!.toJson(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (startTime != null) 'startTime': startTime!,
        if (status != null) 'status': status!,
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (targetLink != null) 'targetLink': targetLink!,
        if (zone != null) 'zone': zone!,
      };
}

/// Information about operation (or operation stage) progress.
class OperationProgress {
  /// Progress metric bundle, for example: metrics: \[{name: "nodes done",
  /// int_value: 15}, {name: "nodes total", int_value: 32}\] or metrics:
  /// \[{name: "progress", double_value: 0.56}, {name: "progress scale",
  /// double_value: 1.0}\]
  core.List<Metric>? metrics;

  /// A non-parameterized string describing an operation stage.
  ///
  /// Unset for single-stage operations.
  core.String? name;

  /// Substages of an operation or a stage.
  core.List<OperationProgress>? stages;

  /// Status of an operation stage.
  ///
  /// Unset for single-stage operations.
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Not set.
  /// - "PENDING" : The operation has been created.
  /// - "RUNNING" : The operation is currently running.
  /// - "DONE" : The operation is done, either cancelled or completed.
  /// - "ABORTING" : The operation is aborting.
  core.String? status;

  OperationProgress();

  OperationProgress.fromJson(core.Map _json) {
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('stages')) {
      stages = (_json['stages'] as core.List)
          .map<OperationProgress>((value) => OperationProgress.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (stages != null)
          'stages': stages!.map((value) => value.toJson()).toList(),
        if (status != null) 'status': status!,
      };
}

/// Configuration options for private clusters.
class PrivateClusterConfig {
  /// Whether the master's internal IP address is used as the cluster endpoint.
  core.bool? enablePrivateEndpoint;

  /// Whether nodes have internal IP addresses only.
  ///
  /// If enabled, all nodes are given only RFC 1918 private addresses and
  /// communicate with the master via private networking.
  core.bool? enablePrivateNodes;

  /// Controls master global access settings.
  PrivateClusterMasterGlobalAccessConfig? masterGlobalAccessConfig;

  /// The IP range in CIDR notation to use for the hosted master network.
  ///
  /// This range will be used for assigning internal IP addresses to the master
  /// or set of masters, as well as the ILB VIP. This range must not overlap
  /// with any other ranges in use within the cluster's network.
  core.String? masterIpv4CidrBlock;

  /// The peering name in the customer VPC used by this cluster.
  ///
  /// Output only.
  core.String? peeringName;

  /// The internal IP address of this cluster's master endpoint.
  ///
  /// Output only.
  core.String? privateEndpoint;

  /// The external IP address of this cluster's master endpoint.
  ///
  /// Output only.
  core.String? publicEndpoint;

  PrivateClusterConfig();

  PrivateClusterConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enablePrivateEndpoint')) {
      enablePrivateEndpoint = _json['enablePrivateEndpoint'] as core.bool;
    }
    if (_json.containsKey('enablePrivateNodes')) {
      enablePrivateNodes = _json['enablePrivateNodes'] as core.bool;
    }
    if (_json.containsKey('masterGlobalAccessConfig')) {
      masterGlobalAccessConfig =
          PrivateClusterMasterGlobalAccessConfig.fromJson(
              _json['masterGlobalAccessConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('masterIpv4CidrBlock')) {
      masterIpv4CidrBlock = _json['masterIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('peeringName')) {
      peeringName = _json['peeringName'] as core.String;
    }
    if (_json.containsKey('privateEndpoint')) {
      privateEndpoint = _json['privateEndpoint'] as core.String;
    }
    if (_json.containsKey('publicEndpoint')) {
      publicEndpoint = _json['publicEndpoint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enablePrivateEndpoint != null)
          'enablePrivateEndpoint': enablePrivateEndpoint!,
        if (enablePrivateNodes != null)
          'enablePrivateNodes': enablePrivateNodes!,
        if (masterGlobalAccessConfig != null)
          'masterGlobalAccessConfig': masterGlobalAccessConfig!.toJson(),
        if (masterIpv4CidrBlock != null)
          'masterIpv4CidrBlock': masterIpv4CidrBlock!,
        if (peeringName != null) 'peeringName': peeringName!,
        if (privateEndpoint != null) 'privateEndpoint': privateEndpoint!,
        if (publicEndpoint != null) 'publicEndpoint': publicEndpoint!,
      };
}

/// Configuration for controlling master global access settings.
class PrivateClusterMasterGlobalAccessConfig {
  /// Whenever master is accessible globally or not.
  core.bool? enabled;

  PrivateClusterMasterGlobalAccessConfig();

  PrivateClusterMasterGlobalAccessConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Pub/Sub specific notification config.
class PubSub {
  /// Enable notifications for Pub/Sub.
  core.bool? enabled;

  /// The desired Pub/Sub topic to which notifications will be sent by GKE.
  ///
  /// Format is `projects/{project}/topics/{topic}`.
  core.String? topic;

  PubSub();

  PubSub.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
        if (topic != null) 'topic': topic!,
      };
}

/// Represents an arbitrary window of time that recurs.
class RecurringTimeWindow {
  /// An RRULE (https://tools.ietf.org/html/rfc5545#section-3.8.5.3) for how
  /// this window reccurs.
  ///
  /// They go on for the span of time between the start and end time. For
  /// example, to have something repeat every weekday, you'd use:
  /// `FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR` To repeat some window daily (equivalent
  /// to the DailyMaintenanceWindow): `FREQ=DAILY` For the first weekend of
  /// every month: `FREQ=MONTHLY;BYSETPOS=1;BYDAY=SA,SU` This specifies how
  /// frequently the window starts. Eg, if you wanted to have a 9-5 UTC-4 window
  /// every weekday, you'd use something like: ``` start time =
  /// 2019-01-01T09:00:00-0400 end time = 2019-01-01T17:00:00-0400 recurrence =
  /// FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR ``` Windows can span multiple days. Eg,
  /// to make the window encompass every weekend from midnight Saturday till the
  /// last minute of Sunday UTC: ``` start time = 2019-01-05T00:00:00Z end time
  /// = 2019-01-07T23:59:00Z recurrence = FREQ=WEEKLY;BYDAY=SA ``` Note the
  /// start and end time's specific dates are largely arbitrary except to
  /// specify duration of the window and when it first starts. The FREQ values
  /// of HOURLY, MINUTELY, and SECONDLY are not supported.
  core.String? recurrence;

  /// The window of the first recurrence.
  TimeWindow? window;

  RecurringTimeWindow();

  RecurringTimeWindow.fromJson(core.Map _json) {
    if (_json.containsKey('recurrence')) {
      recurrence = _json['recurrence'] as core.String;
    }
    if (_json.containsKey('window')) {
      window = TimeWindow.fromJson(
          _json['window'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (recurrence != null) 'recurrence': recurrence!,
        if (window != null) 'window': window!.toJson(),
      };
}

/// ReleaseChannel indicates which release channel a cluster is subscribed to.
///
/// Release channels are arranged in order of risk. When a cluster is subscribed
/// to a release channel, Google maintains both the master version and the node
/// version. Node auto-upgrade defaults to true and cannot be disabled.
class ReleaseChannel {
  /// channel specifies which release channel the cluster is subscribed to.
  /// Possible string values are:
  /// - "UNSPECIFIED" : No channel specified.
  /// - "RAPID" : RAPID channel is offered on an early access basis for
  /// customers who want to test new releases. WARNING: Versions available in
  /// the RAPID Channel may be subject to unresolved issues with no known
  /// workaround and are not subject to any SLAs.
  /// - "REGULAR" : Clusters subscribed to REGULAR receive versions that are
  /// considered GA quality. REGULAR is intended for production users who want
  /// to take advantage of new features.
  /// - "STABLE" : Clusters subscribed to STABLE receive versions that are known
  /// to be stable and reliable in production.
  core.String? channel;

  ReleaseChannel();

  ReleaseChannel.fromJson(core.Map _json) {
    if (_json.containsKey('channel')) {
      channel = _json['channel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channel != null) 'channel': channel!,
      };
}

/// ReleaseChannelConfig exposes configuration for a release channel.
class ReleaseChannelConfig {
  /// The release channel this configuration applies to.
  /// Possible string values are:
  /// - "UNSPECIFIED" : No channel specified.
  /// - "RAPID" : RAPID channel is offered on an early access basis for
  /// customers who want to test new releases. WARNING: Versions available in
  /// the RAPID Channel may be subject to unresolved issues with no known
  /// workaround and are not subject to any SLAs.
  /// - "REGULAR" : Clusters subscribed to REGULAR receive versions that are
  /// considered GA quality. REGULAR is intended for production users who want
  /// to take advantage of new features.
  /// - "STABLE" : Clusters subscribed to STABLE receive versions that are known
  /// to be stable and reliable in production.
  core.String? channel;

  /// The default version for newly created clusters on the channel.
  core.String? defaultVersion;

  /// List of valid versions for the channel.
  core.List<core.String>? validVersions;

  ReleaseChannelConfig();

  ReleaseChannelConfig.fromJson(core.Map _json) {
    if (_json.containsKey('channel')) {
      channel = _json['channel'] as core.String;
    }
    if (_json.containsKey('defaultVersion')) {
      defaultVersion = _json['defaultVersion'] as core.String;
    }
    if (_json.containsKey('validVersions')) {
      validVersions = (_json['validVersions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channel != null) 'channel': channel!,
        if (defaultVersion != null) 'defaultVersion': defaultVersion!,
        if (validVersions != null) 'validVersions': validVersions!,
      };
}

/// [ReservationAffinity](https://cloud.google.com/compute/docs/instances/reserving-zonal-resources)
/// is the configuration of desired reservation which instances could take
/// capacity from.
class ReservationAffinity {
  /// Corresponds to the type of reservation consumption.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Default value. This should not be used.
  /// - "NO_RESERVATION" : Do not consume from any reserved capacity.
  /// - "ANY_RESERVATION" : Consume any reservation available.
  /// - "SPECIFIC_RESERVATION" : Must consume from a specific reservation. Must
  /// specify key value fields for specifying the reservations.
  core.String? consumeReservationType;

  /// Corresponds to the label key of a reservation resource.
  ///
  /// To target a SPECIFIC_RESERVATION by name, specify
  /// "googleapis.com/reservation-name" as the key and specify the name of your
  /// reservation as its value.
  core.String? key;

  /// Corresponds to the label value(s) of reservation resource(s).
  core.List<core.String>? values;

  ReservationAffinity();

  ReservationAffinity.fromJson(core.Map _json) {
    if (_json.containsKey('consumeReservationType')) {
      consumeReservationType = _json['consumeReservationType'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (consumeReservationType != null)
          'consumeReservationType': consumeReservationType!,
        if (key != null) 'key': key!,
        if (values != null) 'values': values!,
      };
}

/// Contains information about amount of some resource in the cluster.
///
/// For memory, value should be in GB.
class ResourceLimit {
  /// Maximum amount of the resource in the cluster.
  core.String? maximum;

  /// Minimum amount of the resource in the cluster.
  core.String? minimum;

  /// Resource name "cpu", "memory" or gpu-specific string.
  core.String? resourceType;

  ResourceLimit();

  ResourceLimit.fromJson(core.Map _json) {
    if (_json.containsKey('maximum')) {
      maximum = _json['maximum'] as core.String;
    }
    if (_json.containsKey('minimum')) {
      minimum = _json['minimum'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maximum != null) 'maximum': maximum!,
        if (minimum != null) 'minimum': minimum!,
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// Configuration for exporting cluster resource usages.
class ResourceUsageExportConfig {
  /// Configuration to use BigQuery as usage export destination.
  BigQueryDestination? bigqueryDestination;

  /// Configuration to enable resource consumption metering.
  ConsumptionMeteringConfig? consumptionMeteringConfig;

  /// Whether to enable network egress metering for this cluster.
  ///
  /// If enabled, a daemonset will be created in the cluster to meter network
  /// egress traffic.
  core.bool? enableNetworkEgressMetering;

  ResourceUsageExportConfig();

  ResourceUsageExportConfig.fromJson(core.Map _json) {
    if (_json.containsKey('bigqueryDestination')) {
      bigqueryDestination = BigQueryDestination.fromJson(
          _json['bigqueryDestination'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('consumptionMeteringConfig')) {
      consumptionMeteringConfig = ConsumptionMeteringConfig.fromJson(
          _json['consumptionMeteringConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enableNetworkEgressMetering')) {
      enableNetworkEgressMetering =
          _json['enableNetworkEgressMetering'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bigqueryDestination != null)
          'bigqueryDestination': bigqueryDestination!.toJson(),
        if (consumptionMeteringConfig != null)
          'consumptionMeteringConfig': consumptionMeteringConfig!.toJson(),
        if (enableNetworkEgressMetering != null)
          'enableNetworkEgressMetering': enableNetworkEgressMetering!,
      };
}

/// RollbackNodePoolUpgradeRequest rollbacks the previously Aborted or Failed
/// NodePool upgrade.
///
/// This will be an no-op if the last upgrade successfully completed.
class RollbackNodePoolUpgradeRequest {
  /// The name of the cluster to rollback.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster, node pool id) of the node poll to
  /// rollback upgrade.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / *
  /// /nodePools / * `.
  core.String? name;

  /// The name of the node pool to rollback.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? nodePoolId;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  RollbackNodePoolUpgradeRequest();

  RollbackNodePoolUpgradeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nodePoolId')) {
      nodePoolId = _json['nodePoolId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (nodePoolId != null) 'nodePoolId': nodePoolId!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SandboxConfig contains configurations of the sandbox to use for the node.
class SandboxConfig {
  /// Type of the sandbox to use for the node.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Default value. This should not be used.
  /// - "GVISOR" : Run sandbox using gvisor.
  core.String? type;

  SandboxConfig();

  SandboxConfig.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
      };
}

/// Kubernetes Engine service configuration.
class ServerConfig {
  /// List of release channel configurations.
  core.List<ReleaseChannelConfig>? channels;

  /// Version of Kubernetes the service deploys by default.
  core.String? defaultClusterVersion;

  /// Default image type.
  core.String? defaultImageType;

  /// List of valid image types.
  core.List<core.String>? validImageTypes;

  /// List of valid master versions, in descending order.
  core.List<core.String>? validMasterVersions;

  /// List of valid node upgrade target versions, in descending order.
  core.List<core.String>? validNodeVersions;

  ServerConfig();

  ServerConfig.fromJson(core.Map _json) {
    if (_json.containsKey('channels')) {
      channels = (_json['channels'] as core.List)
          .map<ReleaseChannelConfig>((value) => ReleaseChannelConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('defaultClusterVersion')) {
      defaultClusterVersion = _json['defaultClusterVersion'] as core.String;
    }
    if (_json.containsKey('defaultImageType')) {
      defaultImageType = _json['defaultImageType'] as core.String;
    }
    if (_json.containsKey('validImageTypes')) {
      validImageTypes = (_json['validImageTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('validMasterVersions')) {
      validMasterVersions = (_json['validMasterVersions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('validNodeVersions')) {
      validNodeVersions = (_json['validNodeVersions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channels != null)
          'channels': channels!.map((value) => value.toJson()).toList(),
        if (defaultClusterVersion != null)
          'defaultClusterVersion': defaultClusterVersion!,
        if (defaultImageType != null) 'defaultImageType': defaultImageType!,
        if (validImageTypes != null) 'validImageTypes': validImageTypes!,
        if (validMasterVersions != null)
          'validMasterVersions': validMasterVersions!,
        if (validNodeVersions != null) 'validNodeVersions': validNodeVersions!,
      };
}

/// SetAddonsConfigRequest sets the addons associated with the cluster.
class SetAddonsConfigRequest {
  /// The desired configurations for the various addons available to run in the
  /// cluster.
  ///
  /// Required.
  AddonsConfig? addonsConfig;

  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster) of the cluster to set addons.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetAddonsConfigRequest();

  SetAddonsConfigRequest.fromJson(core.Map _json) {
    if (_json.containsKey('addonsConfig')) {
      addonsConfig = AddonsConfig.fromJson(
          _json['addonsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addonsConfig != null) 'addonsConfig': addonsConfig!.toJson(),
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetLabelsRequest sets the Google Cloud Platform labels on a Google Container
/// Engine cluster, which will in turn set them for Google Compute Engine
/// resources used by that cluster
class SetLabelsRequest {
  /// The name of the cluster.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The fingerprint of the previous set of labels for this resource, used to
  /// detect conflicts.
  ///
  /// The fingerprint is initially generated by Kubernetes Engine and changes
  /// after every request to modify or update labels. You must always provide an
  /// up-to-date fingerprint hash when updating or changing labels. Make a
  /// `get()` request to the resource to get the latest fingerprint.
  ///
  /// Required.
  core.String? labelFingerprint;

  /// The name (project, location, cluster id) of the cluster to set labels.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The labels to set for that cluster.
  ///
  /// Required.
  core.Map<core.String, core.String>? resourceLabels;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetLabelsRequest();

  SetLabelsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('labelFingerprint')) {
      labelFingerprint = _json['labelFingerprint'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('resourceLabels')) {
      resourceLabels =
          (_json['resourceLabels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (labelFingerprint != null) 'labelFingerprint': labelFingerprint!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (resourceLabels != null) 'resourceLabels': resourceLabels!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetLegacyAbacRequest enables or disables the ABAC authorization mechanism
/// for a cluster.
class SetLegacyAbacRequest {
  /// The name of the cluster to update.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// Whether ABAC authorization will be enabled in the cluster.
  ///
  /// Required.
  core.bool? enabled;

  /// The name (project, location, cluster id) of the cluster to set legacy
  /// abac.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetLegacyAbacRequest();

  SetLegacyAbacRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (enabled != null) 'enabled': enabled!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetLocationsRequest sets the locations of the cluster.
class SetLocationsRequest {
  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The desired list of Google Compute Engine
  /// [zones](https://cloud.google.com/compute/docs/zones#available) in which
  /// the cluster's nodes should be located.
  ///
  /// Changing the locations a cluster is in will result in nodes being either
  /// created or removed from the cluster, depending on whether locations are
  /// being added or removed. This list must always include the cluster's
  /// primary zone.
  ///
  /// Required.
  core.List<core.String>? locations;

  /// The name (project, location, cluster) of the cluster to set locations.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetLocationsRequest();

  SetLocationsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (locations != null) 'locations': locations!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetLoggingServiceRequest sets the logging service of a cluster.
class SetLoggingServiceRequest {
  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The logging service the cluster should use to write logs.
  ///
  /// Currently available options: * `logging.googleapis.com/kubernetes` - The
  /// Cloud Logging service with a Kubernetes-native resource model *
  /// `logging.googleapis.com` - The legacy Cloud Logging service (no longer
  /// available as of GKE 1.15). * `none` - no logs will be exported from the
  /// cluster. If left as an empty string,`logging.googleapis.com/kubernetes`
  /// will be used for GKE 1.14+ or `logging.googleapis.com` for earlier
  /// versions.
  ///
  /// Required.
  core.String? loggingService;

  /// The name (project, location, cluster) of the cluster to set logging.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetLoggingServiceRequest();

  SetLoggingServiceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('loggingService')) {
      loggingService = _json['loggingService'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (loggingService != null) 'loggingService': loggingService!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetMaintenancePolicyRequest sets the maintenance policy for a cluster.
class SetMaintenancePolicyRequest {
  /// The name of the cluster to update.
  ///
  /// Required.
  core.String? clusterId;

  /// The maintenance policy to be set for the cluster.
  ///
  /// An empty field clears the existing maintenance policy.
  ///
  /// Required.
  MaintenancePolicy? maintenancePolicy;

  /// The name (project, location, cluster id) of the cluster to set maintenance
  /// policy.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// Required.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// Required.
  core.String? zone;

  SetMaintenancePolicyRequest();

  SetMaintenancePolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('maintenancePolicy')) {
      maintenancePolicy = MaintenancePolicy.fromJson(
          _json['maintenancePolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (maintenancePolicy != null)
          'maintenancePolicy': maintenancePolicy!.toJson(),
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetMasterAuthRequest updates the admin password of a cluster.
class SetMasterAuthRequest {
  /// The exact form of action to be taken on the master auth.
  ///
  /// Required.
  /// Possible string values are:
  /// - "UNKNOWN" : Operation is unknown and will error out.
  /// - "SET_PASSWORD" : Set the password to a user generated value.
  /// - "GENERATE_PASSWORD" : Generate a new password and set it to that.
  /// - "SET_USERNAME" : Set the username. If an empty username is provided,
  /// basic authentication is disabled for the cluster. If a non-empty username
  /// is provided, basic authentication is enabled, with either a provided
  /// password or a generated one.
  core.String? action;

  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster) of the cluster to set auth.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// A description of the update.
  ///
  /// Required.
  MasterAuth? update;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetMasterAuthRequest();

  SetMasterAuthRequest.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('update')) {
      update = MasterAuth.fromJson(
          _json['update'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (update != null) 'update': update!.toJson(),
        if (zone != null) 'zone': zone!,
      };
}

/// SetMonitoringServiceRequest sets the monitoring service of a cluster.
class SetMonitoringServiceRequest {
  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The monitoring service the cluster should use to write metrics.
  ///
  /// Currently available options: * "monitoring.googleapis.com/kubernetes" -
  /// The Cloud Monitoring service with a Kubernetes-native resource model *
  /// `monitoring.googleapis.com` - The legacy Cloud Monitoring service (no
  /// longer available as of GKE 1.15). * `none` - No metrics will be exported
  /// from the cluster. If left as an empty
  /// string,`monitoring.googleapis.com/kubernetes` will be used for GKE 1.14+
  /// or `monitoring.googleapis.com` for earlier versions.
  ///
  /// Required.
  core.String? monitoringService;

  /// The name (project, location, cluster) of the cluster to set monitoring.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetMonitoringServiceRequest();

  SetMonitoringServiceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('monitoringService')) {
      monitoringService = _json['monitoringService'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (monitoringService != null) 'monitoringService': monitoringService!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetNetworkPolicyRequest enables/disables network policy for a cluster.
class SetNetworkPolicyRequest {
  /// The name of the cluster.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster id) of the cluster to set networking
  /// policy.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// Configuration options for the NetworkPolicy feature.
  ///
  /// Required.
  NetworkPolicy? networkPolicy;

  /// The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetNetworkPolicyRequest();

  SetNetworkPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('networkPolicy')) {
      networkPolicy = NetworkPolicy.fromJson(
          _json['networkPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (networkPolicy != null) 'networkPolicy': networkPolicy!.toJson(),
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetNodePoolAutoscalingRequest sets the autoscaler settings of a node pool.
class SetNodePoolAutoscalingRequest {
  /// Autoscaling configuration for the node pool.
  ///
  /// Required.
  NodePoolAutoscaling? autoscaling;

  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster, node pool) of the node pool to set
  /// autoscaler settings.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / *
  /// /nodePools / * `.
  core.String? name;

  /// The name of the node pool to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? nodePoolId;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetNodePoolAutoscalingRequest();

  SetNodePoolAutoscalingRequest.fromJson(core.Map _json) {
    if (_json.containsKey('autoscaling')) {
      autoscaling = NodePoolAutoscaling.fromJson(
          _json['autoscaling'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nodePoolId')) {
      nodePoolId = _json['nodePoolId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoscaling != null) 'autoscaling': autoscaling!.toJson(),
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (nodePoolId != null) 'nodePoolId': nodePoolId!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetNodePoolManagementRequest sets the node management properties of a node
/// pool.
class SetNodePoolManagementRequest {
  /// The name of the cluster to update.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// NodeManagement configuration for the node pool.
  ///
  /// Required.
  NodeManagement? management;

  /// The name (project, location, cluster, node pool id) of the node pool to
  /// set management properties.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / *
  /// /nodePools / * `.
  core.String? name;

  /// The name of the node pool to update.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? nodePoolId;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetNodePoolManagementRequest();

  SetNodePoolManagementRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('management')) {
      management = NodeManagement.fromJson(
          _json['management'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nodePoolId')) {
      nodePoolId = _json['nodePoolId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (management != null) 'management': management!.toJson(),
        if (name != null) 'name': name!,
        if (nodePoolId != null) 'nodePoolId': nodePoolId!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// SetNodePoolSizeRequest sets the size of a node pool.
class SetNodePoolSizeRequest {
  /// The name of the cluster to update.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster, node pool id) of the node pool to
  /// set size.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / *
  /// /nodePools / * `.
  core.String? name;

  /// The desired node count for the pool.
  ///
  /// Required.
  core.int? nodeCount;

  /// The name of the node pool to update.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? nodePoolId;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  SetNodePoolSizeRequest();

  SetNodePoolSizeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nodeCount')) {
      nodeCount = _json['nodeCount'] as core.int;
    }
    if (_json.containsKey('nodePoolId')) {
      nodePoolId = _json['nodePoolId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (nodeCount != null) 'nodeCount': nodeCount!,
        if (nodePoolId != null) 'nodePoolId': nodePoolId!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// A set of Shielded Instance options.
class ShieldedInstanceConfig {
  /// Defines whether the instance has integrity monitoring enabled.
  ///
  /// Enables monitoring and attestation of the boot integrity of the instance.
  /// The attestation is performed against the integrity policy baseline. This
  /// baseline is initially derived from the implicitly trusted boot image when
  /// the instance is created.
  core.bool? enableIntegrityMonitoring;

  /// Defines whether the instance has Secure Boot enabled.
  ///
  /// Secure Boot helps ensure that the system only runs authentic software by
  /// verifying the digital signature of all boot components, and halting the
  /// boot process if signature verification fails.
  core.bool? enableSecureBoot;

  ShieldedInstanceConfig();

  ShieldedInstanceConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enableIntegrityMonitoring')) {
      enableIntegrityMonitoring =
          _json['enableIntegrityMonitoring'] as core.bool;
    }
    if (_json.containsKey('enableSecureBoot')) {
      enableSecureBoot = _json['enableSecureBoot'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableIntegrityMonitoring != null)
          'enableIntegrityMonitoring': enableIntegrityMonitoring!,
        if (enableSecureBoot != null) 'enableSecureBoot': enableSecureBoot!,
      };
}

/// Configuration of Shielded Nodes feature.
class ShieldedNodes {
  /// Whether Shielded Nodes features are enabled on all nodes in this cluster.
  core.bool? enabled;

  ShieldedNodes();

  ShieldedNodes.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// StartIPRotationRequest creates a new IP for the cluster and then performs a
/// node upgrade on each node pool to point to the new IP.
class StartIPRotationRequest {
  /// The name of the cluster.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster id) of the cluster to start IP
  /// rotation.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://developers.google.com/console/help/new/#projectnumber).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// Whether to rotate credentials during IP rotation.
  core.bool? rotateCredentials;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  StartIPRotationRequest();

  StartIPRotationRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('rotateCredentials')) {
      rotateCredentials = _json['rotateCredentials'] as core.bool;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (rotateCredentials != null) 'rotateCredentials': rotateCredentials!,
        if (zone != null) 'zone': zone!,
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

/// StatusCondition describes why a cluster or a node pool has a certain status
/// (e.g., ERROR or DEGRADED).
class StatusCondition {
  /// Canonical code of the condition.
  /// Possible string values are:
  /// - "OK" : Not an error; returned on success HTTP Mapping: 200 OK
  /// - "CANCELLED" : The operation was cancelled, typically by the caller. HTTP
  /// Mapping: 499 Client Closed Request
  /// - "UNKNOWN" : Unknown error. For example, this error may be returned when
  /// a `Status` value received from another address space belongs to an error
  /// space that is not known in this address space. Also errors raised by APIs
  /// that do not return enough error information may be converted to this
  /// error. HTTP Mapping: 500 Internal Server Error
  /// - "INVALID_ARGUMENT" : The client specified an invalid argument. Note that
  /// this differs from `FAILED_PRECONDITION`. `INVALID_ARGUMENT` indicates
  /// arguments that are problematic regardless of the state of the system
  /// (e.g., a malformed file name). HTTP Mapping: 400 Bad Request
  /// - "DEADLINE_EXCEEDED" : The deadline expired before the operation could
  /// complete. For operations that change the state of the system, this error
  /// may be returned even if the operation has completed successfully. For
  /// example, a successful response from a server could have been delayed long
  /// enough for the deadline to expire. HTTP Mapping: 504 Gateway Timeout
  /// - "NOT_FOUND" : Some requested entity (e.g., file or directory) was not
  /// found. Note to server developers: if a request is denied for an entire
  /// class of users, such as gradual feature rollout or undocumented allowlist,
  /// `NOT_FOUND` may be used. If a request is denied for some users within a
  /// class of users, such as user-based access control, `PERMISSION_DENIED`
  /// must be used. HTTP Mapping: 404 Not Found
  /// - "ALREADY_EXISTS" : The entity that a client attempted to create (e.g.,
  /// file or directory) already exists. HTTP Mapping: 409 Conflict
  /// - "PERMISSION_DENIED" : The caller does not have permission to execute the
  /// specified operation. `PERMISSION_DENIED` must not be used for rejections
  /// caused by exhausting some resource (use `RESOURCE_EXHAUSTED` instead for
  /// those errors). `PERMISSION_DENIED` must not be used if the caller can not
  /// be identified (use `UNAUTHENTICATED` instead for those errors). This error
  /// code does not imply the request is valid or the requested entity exists or
  /// satisfies other pre-conditions. HTTP Mapping: 403 Forbidden
  /// - "UNAUTHENTICATED" : The request does not have valid authentication
  /// credentials for the operation. HTTP Mapping: 401 Unauthorized
  /// - "RESOURCE_EXHAUSTED" : Some resource has been exhausted, perhaps a
  /// per-user quota, or perhaps the entire file system is out of space. HTTP
  /// Mapping: 429 Too Many Requests
  /// - "FAILED_PRECONDITION" : The operation was rejected because the system is
  /// not in a state required for the operation's execution. For example, the
  /// directory to be deleted is non-empty, an rmdir operation is applied to a
  /// non-directory, etc. Service implementors can use the following guidelines
  /// to decide between `FAILED_PRECONDITION`, `ABORTED`, and `UNAVAILABLE`: (a)
  /// Use `UNAVAILABLE` if the client can retry just the failing call. (b) Use
  /// `ABORTED` if the client should retry at a higher level. For example, when
  /// a client-specified test-and-set fails, indicating the client should
  /// restart a read-modify-write sequence. (c) Use `FAILED_PRECONDITION` if the
  /// client should not retry until the system state has been explicitly fixed.
  /// For example, if an "rmdir" fails because the directory is non-empty,
  /// `FAILED_PRECONDITION` should be returned since the client should not retry
  /// unless the files are deleted from the directory. HTTP Mapping: 400 Bad
  /// Request
  /// - "ABORTED" : The operation was aborted, typically due to a concurrency
  /// issue such as a sequencer check failure or transaction abort. See the
  /// guidelines above for deciding between `FAILED_PRECONDITION`, `ABORTED`,
  /// and `UNAVAILABLE`. HTTP Mapping: 409 Conflict
  /// - "OUT_OF_RANGE" : The operation was attempted past the valid range. E.g.,
  /// seeking or reading past end-of-file. Unlike `INVALID_ARGUMENT`, this error
  /// indicates a problem that may be fixed if the system state changes. For
  /// example, a 32-bit file system will generate `INVALID_ARGUMENT` if asked to
  /// read at an offset that is not in the range \[0,2^32-1\], but it will
  /// generate `OUT_OF_RANGE` if asked to read from an offset past the current
  /// file size. There is a fair bit of overlap between `FAILED_PRECONDITION`
  /// and `OUT_OF_RANGE`. We recommend using `OUT_OF_RANGE` (the more specific
  /// error) when it applies so that callers who are iterating through a space
  /// can easily look for an `OUT_OF_RANGE` error to detect when they are done.
  /// HTTP Mapping: 400 Bad Request
  /// - "UNIMPLEMENTED" : The operation is not implemented or is not
  /// supported/enabled in this service. HTTP Mapping: 501 Not Implemented
  /// - "INTERNAL" : Internal errors. This means that some invariants expected
  /// by the underlying system have been broken. This error code is reserved for
  /// serious errors. HTTP Mapping: 500 Internal Server Error
  /// - "UNAVAILABLE" : The service is currently unavailable. This is most
  /// likely a transient condition, which can be corrected by retrying with a
  /// backoff. Note that it is not always safe to retry non-idempotent
  /// operations. See the guidelines above for deciding between
  /// `FAILED_PRECONDITION`, `ABORTED`, and `UNAVAILABLE`. HTTP Mapping: 503
  /// Service Unavailable
  /// - "DATA_LOSS" : Unrecoverable data loss or corruption. HTTP Mapping: 500
  /// Internal Server Error
  core.String? canonicalCode;

  /// Machine-friendly representation of the condition Deprecated.
  ///
  /// Use canonical_code instead.
  /// Possible string values are:
  /// - "UNKNOWN" : UNKNOWN indicates a generic condition.
  /// - "GCE_STOCKOUT" : GCE_STOCKOUT indicates that Google Compute Engine
  /// resources are temporarily unavailable.
  /// - "GKE_SERVICE_ACCOUNT_DELETED" : GKE_SERVICE_ACCOUNT_DELETED indicates
  /// that the user deleted their robot service account.
  /// - "GCE_QUOTA_EXCEEDED" : Google Compute Engine quota was exceeded.
  /// - "SET_BY_OPERATOR" : Cluster state was manually changed by an SRE due to
  /// a system logic error.
  /// - "CLOUD_KMS_KEY_ERROR" : Unable to perform an encrypt operation against
  /// the CloudKMS key used for etcd level encryption. More codes TBA
  core.String? code;

  /// Human-friendly representation of the condition
  core.String? message;

  StatusCondition();

  StatusCondition.fromJson(core.Map _json) {
    if (_json.containsKey('canonicalCode')) {
      canonicalCode = _json['canonicalCode'] as core.String;
    }
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canonicalCode != null) 'canonicalCode': canonicalCode!,
        if (code != null) 'code': code!,
        if (message != null) 'message': message!,
      };
}

/// Represents an arbitrary window of time.
class TimeWindow {
  /// The time that the window ends.
  ///
  /// The end time should take place after the start time.
  core.String? endTime;

  /// The time that the window first starts.
  core.String? startTime;

  TimeWindow();

  TimeWindow.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// UpdateClusterRequest updates the settings of a cluster.
class UpdateClusterRequest {
  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The name (project, location, cluster) of the cluster to update.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// A description of the update.
  ///
  /// Required.
  ClusterUpdate? update;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  UpdateClusterRequest();

  UpdateClusterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('update')) {
      update = ClusterUpdate.fromJson(
          _json['update'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (update != null) 'update': update!.toJson(),
        if (zone != null) 'zone': zone!,
      };
}

/// UpdateMasterRequest updates the master of the cluster.
class UpdateMasterRequest {
  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The Kubernetes version to change the master to.
  ///
  /// Users may specify either explicit versions offered by Kubernetes Engine or
  /// version aliases, which have the following behavior: - "latest": picks the
  /// highest valid Kubernetes version - "1.X": picks the highest valid
  /// patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid
  /// gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit
  /// Kubernetes version - "-": picks the default Kubernetes version
  ///
  /// Required.
  core.String? masterVersion;

  /// The name (project, location, cluster) of the cluster to update.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / * `.
  core.String? name;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  UpdateMasterRequest();

  UpdateMasterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('masterVersion')) {
      masterVersion = _json['masterVersion'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (masterVersion != null) 'masterVersion': masterVersion!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
        if (zone != null) 'zone': zone!,
      };
}

/// UpdateNodePoolRequests update a node pool's image and/or version.
class UpdateNodePoolRequest {
  /// The name of the cluster to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? clusterId;

  /// The desired image type for the node pool.
  ///
  /// Required.
  core.String? imageType;

  /// Node kubelet configs.
  NodeKubeletConfig? kubeletConfig;

  /// Parameters that can be configured on Linux nodes.
  LinuxNodeConfig? linuxNodeConfig;

  /// The desired list of Google Compute Engine
  /// [zones](https://cloud.google.com/compute/docs/zones#available) in which
  /// the node pool's nodes should be located.
  ///
  /// Changing the locations for a node pool will result in nodes being either
  /// created or removed from the node pool, depending on whether locations are
  /// being added or removed.
  core.List<core.String>? locations;

  /// The name (project, location, cluster, node pool) of the node pool to
  /// update.
  ///
  /// Specified in the format `projects / * /locations / * /clusters / *
  /// /nodePools / * `.
  core.String? name;

  /// The name of the node pool to upgrade.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? nodePoolId;

  /// The Kubernetes version to change the nodes to (typically an upgrade).
  ///
  /// Users may specify either explicit versions offered by Kubernetes Engine or
  /// version aliases, which have the following behavior: - "latest": picks the
  /// highest valid Kubernetes version - "1.X": picks the highest valid
  /// patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid
  /// gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit
  /// Kubernetes version - "-": picks the Kubernetes master version
  ///
  /// Required.
  core.String? nodeVersion;

  /// The Google Developers Console
  /// [project ID or project number](https://support.google.com/cloud/answer/6158840).
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? projectId;

  /// Upgrade settings control disruption and speed of the upgrade.
  UpgradeSettings? upgradeSettings;

  /// The desired workload metadata config for the node pool.
  WorkloadMetadataConfig? workloadMetadataConfig;

  /// The name of the Google Compute Engine
  /// [zone](https://cloud.google.com/compute/docs/zones#available) in which the
  /// cluster resides.
  ///
  /// This field has been deprecated and replaced by the name field.
  ///
  /// Deprecated.
  core.String? zone;

  UpdateNodePoolRequest();

  UpdateNodePoolRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clusterId')) {
      clusterId = _json['clusterId'] as core.String;
    }
    if (_json.containsKey('imageType')) {
      imageType = _json['imageType'] as core.String;
    }
    if (_json.containsKey('kubeletConfig')) {
      kubeletConfig = NodeKubeletConfig.fromJson(
          _json['kubeletConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linuxNodeConfig')) {
      linuxNodeConfig = LinuxNodeConfig.fromJson(
          _json['linuxNodeConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nodePoolId')) {
      nodePoolId = _json['nodePoolId'] as core.String;
    }
    if (_json.containsKey('nodeVersion')) {
      nodeVersion = _json['nodeVersion'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('upgradeSettings')) {
      upgradeSettings = UpgradeSettings.fromJson(
          _json['upgradeSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('workloadMetadataConfig')) {
      workloadMetadataConfig = WorkloadMetadataConfig.fromJson(
          _json['workloadMetadataConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterId != null) 'clusterId': clusterId!,
        if (imageType != null) 'imageType': imageType!,
        if (kubeletConfig != null) 'kubeletConfig': kubeletConfig!.toJson(),
        if (linuxNodeConfig != null)
          'linuxNodeConfig': linuxNodeConfig!.toJson(),
        if (locations != null) 'locations': locations!,
        if (name != null) 'name': name!,
        if (nodePoolId != null) 'nodePoolId': nodePoolId!,
        if (nodeVersion != null) 'nodeVersion': nodeVersion!,
        if (projectId != null) 'projectId': projectId!,
        if (upgradeSettings != null)
          'upgradeSettings': upgradeSettings!.toJson(),
        if (workloadMetadataConfig != null)
          'workloadMetadataConfig': workloadMetadataConfig!.toJson(),
        if (zone != null) 'zone': zone!,
      };
}

/// UpgradeAvailableEvent is a notification sent to customers when a new
/// available version is released.
class UpgradeAvailableEvent {
  /// The release channel of the version.
  ///
  /// If empty, it means a non-channel release.
  ReleaseChannel? releaseChannel;

  /// Optional relative path to the resource.
  ///
  /// For example, the relative path of the node pool.
  core.String? resource;

  /// The resource type of the release version.
  /// Possible string values are:
  /// - "UPGRADE_RESOURCE_TYPE_UNSPECIFIED" : Default value. This shouldn't be
  /// used.
  /// - "MASTER" : Master / control plane
  /// - "NODE_POOL" : Node pool
  core.String? resourceType;

  /// The release version available for upgrade.
  core.String? version;

  UpgradeAvailableEvent();

  UpgradeAvailableEvent.fromJson(core.Map _json) {
    if (_json.containsKey('releaseChannel')) {
      releaseChannel = ReleaseChannel.fromJson(
          _json['releaseChannel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (releaseChannel != null) 'releaseChannel': releaseChannel!.toJson(),
        if (resource != null) 'resource': resource!,
        if (resourceType != null) 'resourceType': resourceType!,
        if (version != null) 'version': version!,
      };
}

/// UpgradeEvent is a notification sent to customers by the cluster server when
/// a resource is upgrading.
class UpgradeEvent {
  /// The current version before the upgrade.
  core.String? currentVersion;

  /// The operation associated with this upgrade.
  core.String? operation;

  /// The time when the operation was started.
  core.String? operationStartTime;

  /// Optional relative path to the resource.
  ///
  /// For example in node pool upgrades, the relative path of the node pool.
  core.String? resource;

  /// The resource type that is upgrading.
  /// Possible string values are:
  /// - "UPGRADE_RESOURCE_TYPE_UNSPECIFIED" : Default value. This shouldn't be
  /// used.
  /// - "MASTER" : Master / control plane
  /// - "NODE_POOL" : Node pool
  core.String? resourceType;

  /// The target version for the upgrade.
  core.String? targetVersion;

  UpgradeEvent();

  UpgradeEvent.fromJson(core.Map _json) {
    if (_json.containsKey('currentVersion')) {
      currentVersion = _json['currentVersion'] as core.String;
    }
    if (_json.containsKey('operation')) {
      operation = _json['operation'] as core.String;
    }
    if (_json.containsKey('operationStartTime')) {
      operationStartTime = _json['operationStartTime'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
    if (_json.containsKey('targetVersion')) {
      targetVersion = _json['targetVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentVersion != null) 'currentVersion': currentVersion!,
        if (operation != null) 'operation': operation!,
        if (operationStartTime != null)
          'operationStartTime': operationStartTime!,
        if (resource != null) 'resource': resource!,
        if (resourceType != null) 'resourceType': resourceType!,
        if (targetVersion != null) 'targetVersion': targetVersion!,
      };
}

/// These upgrade settings control the level of parallelism and the level of
/// disruption caused by an upgrade.
///
/// maxUnavailable controls the number of nodes that can be simultaneously
/// unavailable. maxSurge controls the number of additional nodes that can be
/// added to the node pool temporarily for the time of the upgrade to increase
/// the number of available nodes. (maxUnavailable + maxSurge) determines the
/// level of parallelism (how many nodes are being upgraded at the same time).
/// Note: upgrades inevitably introduce some disruption since workloads need to
/// be moved from old nodes to new, upgraded ones. Even if maxUnavailable=0,
/// this holds true. (Disruption stays within the limits of PodDisruptionBudget,
/// if it is configured.) Consider a hypothetical node pool with 5 nodes having
/// maxSurge=2, maxUnavailable=1. This means the upgrade process upgrades 3
/// nodes simultaneously. It creates 2 additional (upgraded) nodes, then it
/// brings down 3 old (not yet upgraded) nodes at the same time. This ensures
/// that there are always at least 4 nodes available.
class UpgradeSettings {
  /// The maximum number of nodes that can be created beyond the current size of
  /// the node pool during the upgrade process.
  core.int? maxSurge;

  /// The maximum number of nodes that can be simultaneously unavailable during
  /// the upgrade process.
  ///
  /// A node is considered available if its status is Ready.
  core.int? maxUnavailable;

  UpgradeSettings();

  UpgradeSettings.fromJson(core.Map _json) {
    if (_json.containsKey('maxSurge')) {
      maxSurge = _json['maxSurge'] as core.int;
    }
    if (_json.containsKey('maxUnavailable')) {
      maxUnavailable = _json['maxUnavailable'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxSurge != null) 'maxSurge': maxSurge!,
        if (maxUnavailable != null) 'maxUnavailable': maxUnavailable!,
      };
}

/// UsableSubnetwork resource returns the subnetwork name, its associated
/// network and the primary CIDR range.
class UsableSubnetwork {
  /// The range of internal addresses that are owned by this subnetwork.
  core.String? ipCidrRange;

  /// Network Name.
  ///
  /// Example: projects/my-project/global/networks/my-network
  core.String? network;

  /// Secondary IP ranges.
  core.List<UsableSubnetworkSecondaryRange>? secondaryIpRanges;

  /// A human readable status message representing the reasons for cases where
  /// the caller cannot use the secondary ranges under the subnet.
  ///
  /// For example if the secondary_ip_ranges is empty due to a permission issue,
  /// an insufficient permission message will be given by status_message.
  core.String? statusMessage;

  /// Subnetwork Name.
  ///
  /// Example: projects/my-project/regions/us-central1/subnetworks/my-subnet
  core.String? subnetwork;

  UsableSubnetwork();

  UsableSubnetwork.fromJson(core.Map _json) {
    if (_json.containsKey('ipCidrRange')) {
      ipCidrRange = _json['ipCidrRange'] as core.String;
    }
    if (_json.containsKey('network')) {
      network = _json['network'] as core.String;
    }
    if (_json.containsKey('secondaryIpRanges')) {
      secondaryIpRanges = (_json['secondaryIpRanges'] as core.List)
          .map<UsableSubnetworkSecondaryRange>((value) =>
              UsableSubnetworkSecondaryRange.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('statusMessage')) {
      statusMessage = _json['statusMessage'] as core.String;
    }
    if (_json.containsKey('subnetwork')) {
      subnetwork = _json['subnetwork'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ipCidrRange != null) 'ipCidrRange': ipCidrRange!,
        if (network != null) 'network': network!,
        if (secondaryIpRanges != null)
          'secondaryIpRanges':
              secondaryIpRanges!.map((value) => value.toJson()).toList(),
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (subnetwork != null) 'subnetwork': subnetwork!,
      };
}

/// Secondary IP range of a usable subnetwork.
class UsableSubnetworkSecondaryRange {
  /// The range of IP addresses belonging to this subnetwork secondary range.
  core.String? ipCidrRange;

  /// The name associated with this subnetwork secondary range, used when adding
  /// an alias IP range to a VM instance.
  core.String? rangeName;

  /// This field is to determine the status of the secondary range programmably.
  /// Possible string values are:
  /// - "UNKNOWN" : UNKNOWN is the zero value of the Status enum. It's not a
  /// valid status.
  /// - "UNUSED" : UNUSED denotes that this range is unclaimed by any cluster.
  /// - "IN_USE_SERVICE" : IN_USE_SERVICE denotes that this range is claimed by
  /// a cluster for services. It cannot be used for other clusters.
  /// - "IN_USE_SHAREABLE_POD" : IN_USE_SHAREABLE_POD denotes this range was
  /// created by the network admin and is currently claimed by a cluster for
  /// pods. It can only be used by other clusters as a pod range.
  /// - "IN_USE_MANAGED_POD" : IN_USE_MANAGED_POD denotes this range was created
  /// by GKE and is claimed for pods. It cannot be used for other clusters.
  core.String? status;

  UsableSubnetworkSecondaryRange();

  UsableSubnetworkSecondaryRange.fromJson(core.Map _json) {
    if (_json.containsKey('ipCidrRange')) {
      ipCidrRange = _json['ipCidrRange'] as core.String;
    }
    if (_json.containsKey('rangeName')) {
      rangeName = _json['rangeName'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ipCidrRange != null) 'ipCidrRange': ipCidrRange!,
        if (rangeName != null) 'rangeName': rangeName!,
        if (status != null) 'status': status!,
      };
}

/// VerticalPodAutoscaling contains global, per-cluster information required by
/// Vertical Pod Autoscaler to automatically adjust the resources of pods
/// controlled by it.
class VerticalPodAutoscaling {
  /// Enables vertical pod autoscaling.
  core.bool? enabled;

  VerticalPodAutoscaling();

  VerticalPodAutoscaling.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Configuration for the use of Kubernetes Service Accounts in GCP IAM
/// policies.
class WorkloadIdentityConfig {
  /// The workload pool to attach all Kubernetes service accounts to.
  core.String? workloadPool;

  WorkloadIdentityConfig();

  WorkloadIdentityConfig.fromJson(core.Map _json) {
    if (_json.containsKey('workloadPool')) {
      workloadPool = _json['workloadPool'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (workloadPool != null) 'workloadPool': workloadPool!,
      };
}

/// WorkloadMetadataConfig defines the metadata configuration to expose to
/// workloads on the node pool.
class WorkloadMetadataConfig {
  /// Mode is the configuration for how to expose metadata to workloads running
  /// on the node pool.
  /// Possible string values are:
  /// - "MODE_UNSPECIFIED" : Not set.
  /// - "GCE_METADATA" : Expose all Compute Engine metadata to pods.
  /// - "GKE_METADATA" : Run the GKE Metadata Server on this node. The GKE
  /// Metadata Server exposes a metadata API to workloads that is compatible
  /// with the V1 Compute Metadata APIs exposed by the Compute Engine and App
  /// Engine Metadata Servers. This feature can only be enabled if Workload
  /// Identity is enabled at the cluster level.
  core.String? mode;

  WorkloadMetadataConfig();

  WorkloadMetadataConfig.fromJson(core.Map _json) {
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mode != null) 'mode': mode!,
      };
}

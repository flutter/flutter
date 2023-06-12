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

/// Database Migration API - v1
///
/// Manage Cloud Database Migration Service resources on Google Cloud Platform.
///
/// For more information, see <https://cloud.google.com/database-migration/>
///
/// Create an instance of [DatabaseMigrationServiceApi] to access these
/// resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsConnectionProfilesResource]
///     - [ProjectsLocationsMigrationJobsResource]
///     - [ProjectsLocationsOperationsResource]
library datamigration.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Manage Cloud Database Migration Service resources on Google Cloud Platform.
class DatabaseMigrationServiceApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  DatabaseMigrationServiceApi(http.Client client,
      {core.String rootUrl = 'https://datamigration.googleapis.com/',
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

  ProjectsLocationsConnectionProfilesResource get connectionProfiles =>
      ProjectsLocationsConnectionProfilesResource(_requester);
  ProjectsLocationsMigrationJobsResource get migrationJobs =>
      ProjectsLocationsMigrationJobsResource(_requester);
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

class ProjectsLocationsConnectionProfilesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsConnectionProfilesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new connection profile in a given project and location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent, which owns this collection of connection
  /// profiles.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [connectionProfileId] - Required. The connection profile identifier.
  ///
  /// [requestId] - A unique id used to identify the request. If the server
  /// receives two requests with the same id, then the second request will be
  /// ignored. It is recommended to always set this value to a UUID. The id must
  /// contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and
  /// hyphens (-). The maximum length is 40 characters.
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
    ConnectionProfile request,
    core.String parent, {
    core.String? connectionProfileId,
    core.String? requestId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (connectionProfileId != null)
        'connectionProfileId': [connectionProfileId],
      if (requestId != null) 'requestId': [requestId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/connectionProfiles';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a single Database Migration Service connection profile.
  ///
  /// A connection profile can only be deleted if it is not in use by any active
  /// migration jobs.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the connection profile resource to delete.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/connectionProfiles/\[^/\]+$`.
  ///
  /// [force] - In case of force delete, the CloudSQL replica database is also
  /// deleted (only for CloudSQL connection profile).
  ///
  /// [requestId] - A unique id used to identify the request. If the server
  /// receives two requests with the same id, then the second request will be
  /// ignored. It is recommended to always set this value to a UUID. The id must
  /// contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and
  /// hyphens (-). The maximum length is 40 characters.
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
    core.bool? force,
    core.String? requestId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if (requestId != null) 'requestId': [requestId],
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

  /// Gets details of a single connection profile.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the connection profile resource to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/connectionProfiles/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ConnectionProfile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ConnectionProfile> get(
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
    return ConnectionProfile.fromJson(
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
  /// `^projects/\[^/\]+/locations/\[^/\]+/connectionProfiles/\[^/\]+$`.
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

  /// Retrieve a list of all connection profiles in a given project and
  /// location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent, which owns this collection of connection
  /// profiles.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - A filter expression that filters connection profiles listed in
  /// the response. The expression must specify the field name, a comparison
  /// operator, and the value that you want to use for filtering. The value must
  /// be a string, a number, or a boolean. The comparison operator must be
  /// either =, !=, >, or <. For example, list connection profiles created this
  /// year by specifying **createTime %gt; 2020-01-01T00:00:00.000000000Z**. You
  /// can also filter nested fields. For example, you could specify
  /// **mySql.username = %lt;my_username%gt;** to list all connection profiles
  /// configured to connect with a specific username.
  ///
  /// [orderBy] - the order by fields for the result.
  ///
  /// [pageSize] - The maximum number of connection profiles to return. The
  /// service may return fewer than this value. If unspecified, at most 50
  /// connection profiles will be returned. The maximum value is 1000; values
  /// above 1000 will be coerced to 1000.
  ///
  /// [pageToken] - A page token, received from a previous
  /// `ListConnectionProfiles` call. Provide this to retrieve the subsequent
  /// page. When paginating, all other parameters provided to
  /// `ListConnectionProfiles` must match the call that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListConnectionProfilesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListConnectionProfilesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/connectionProfiles';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListConnectionProfilesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update the configuration of a single connection profile.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of this connection profile resource in the form of
  /// projects/{project}/locations/{location}/connectionProfiles/{instance}.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/connectionProfiles/\[^/\]+$`.
  ///
  /// [requestId] - A unique id used to identify the request. If the server
  /// receives two requests with the same id, then the second request will be
  /// ignored. It is recommended to always set this value to a UUID. The id must
  /// contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and
  /// hyphens (-). The maximum length is 40 characters.
  ///
  /// [updateMask] - Required. Field mask is used to specify the fields to be
  /// overwritten in the connection profile resource by the update.
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
    ConnectionProfile request,
    core.String name, {
    core.String? requestId,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (requestId != null) 'requestId': [requestId],
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
  /// `^projects/\[^/\]+/locations/\[^/\]+/connectionProfiles/\[^/\]+$`.
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
  /// `^projects/\[^/\]+/locations/\[^/\]+/connectionProfiles/\[^/\]+$`.
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

class ProjectsLocationsMigrationJobsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsMigrationJobsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new migration job in a given project and location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent, which owns this collection of migration
  /// jobs.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [migrationJobId] - Required. The ID of the instance to create.
  ///
  /// [requestId] - A unique id used to identify the request. If the server
  /// receives two requests with the same id, then the second request will be
  /// ignored. It is recommended to always set this value to a UUID. The id must
  /// contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and
  /// hyphens (-). The maximum length is 40 characters.
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
    MigrationJob request,
    core.String parent, {
    core.String? migrationJobId,
    core.String? requestId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (migrationJobId != null) 'migrationJobId': [migrationJobId],
      if (requestId != null) 'requestId': [requestId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/migrationJobs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a single migration job.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the migration job resource to delete.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
  ///
  /// [force] - The destination CloudSQL connection profile is always deleted
  /// with the migration job. In case of force delete, the destination CloudSQL
  /// replica database is also deleted.
  ///
  /// [requestId] - A unique id used to identify the request. If the server
  /// receives two requests with the same id, then the second request will be
  /// ignored. It is recommended to always set this value to a UUID. The id must
  /// contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and
  /// hyphens (-). The maximum length is 40 characters.
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
    core.bool? force,
    core.String? requestId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if (requestId != null) 'requestId': [requestId],
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

  /// Generate a SSH configuration script to configure the reverse SSH
  /// connectivity.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [migrationJob] - Name of the migration job resource to generate the SSH
  /// script.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SshScript].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SshScript> generateSshScript(
    GenerateSshScriptRequest request,
    core.String migrationJob, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$migrationJob') + ':generateSshScript';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SshScript.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets details of a single migration job.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the migration job resource to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MigrationJob].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MigrationJob> get(
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
    return MigrationJob.fromJson(
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
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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

  /// Lists migration jobs in a given project and location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent, which owns this collection of
  /// migrationJobs.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - A filter expression that filters migration jobs listed in the
  /// response. The expression must specify the field name, a comparison
  /// operator, and the value that you want to use for filtering. The value must
  /// be a string, a number, or a boolean. The comparison operator must be
  /// either =, !=, >, or <. For example, list migration jobs created this year
  /// by specifying **createTime %gt; 2020-01-01T00:00:00.000000000Z.** You can
  /// also filter nested fields. For example, you could specify
  /// **reverseSshConnectivity.vmIp = "1.2.3.4"** to select all migration jobs
  /// connecting through the specific SSH tunnel bastion.
  ///
  /// [orderBy] - Sort the results based on the migration job name. Valid values
  /// are: "name", "name asc", and "name desc".
  ///
  /// [pageSize] - The maximum number of migration jobs to return. The service
  /// may return fewer than this value. If unspecified, at most 50 migration
  /// jobs will be returned. The maximum value is 1000; values above 1000 will
  /// be coerced to 1000.
  ///
  /// [pageToken] - The nextPageToken value received in the previous call to
  /// migrationJobs.list, used in the subsequent request to retrieve the next
  /// page of results. On first call this should be left blank. When paginating,
  /// all other parameters provided to migrationJobs.list must match the call
  /// that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListMigrationJobsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListMigrationJobsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/migrationJobs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListMigrationJobsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the parameters of a single migration job.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name (URI) of this migration job resource, in the form of:
  /// projects/{project}/locations/{location}/instances/{instance}.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
  ///
  /// [requestId] - A unique id used to identify the request. If the server
  /// receives two requests with the same id, then the second request will be
  /// ignored. It is recommended to always set this value to a UUID. The id must
  /// contain only letters (a-z, A-Z), numbers (0-9), underscores (_), and
  /// hyphens (-). The maximum length is 40 characters.
  ///
  /// [updateMask] - Required. Field mask is used to specify the fields to be
  /// overwritten in the migration job resource by the update.
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
    MigrationJob request,
    core.String name, {
    core.String? requestId,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (requestId != null) 'requestId': [requestId],
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

  /// Promote a migration job, stopping replication to the destination and
  /// promoting the destination to be a standalone database.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the migration job resource to promote.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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
  async.Future<Operation> promote(
    PromoteMigrationJobRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':promote';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Restart a stopped or failed migration job, resetting the destination
  /// instance to its original state and starting the migration process from
  /// scratch.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the migration job resource to restart.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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
  async.Future<Operation> restart(
    RestartMigrationJobRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':restart';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Resume a migration job that is currently stopped and is resumable (was
  /// stopped during CDC phase).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the migration job resource to resume.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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
  async.Future<Operation> resume(
    ResumeMigrationJobRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':resume';

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
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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

  /// Start an already created migration job.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the migration job resource to start.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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
  async.Future<Operation> start(
    StartMigrationJobRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':start';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Stops a running migration job.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the migration job resource to stop.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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
    StopMigrationJobRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':stop';

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
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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

  /// Verify a migration job, making sure the destination can reach the source
  /// and that all configuration and prerequisites are met.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the migration job resource to verify.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/migrationJobs/\[^/\]+$`.
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
  async.Future<Operation> verify(
    VerifyMigrationJobRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':verify';

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

/// Specifies required connection parameters, and, optionally, the parameters
/// required to create a Cloud SQL destination database instance.
class CloudSqlConnectionProfile {
  /// The Cloud SQL instance ID that this connection profile is associated with.
  ///
  /// Output only.
  core.String? cloudSqlId;

  /// The Cloud SQL database instance's private IP.
  ///
  /// Output only.
  core.String? privateIp;

  /// The Cloud SQL database instance's public IP.
  ///
  /// Output only.
  core.String? publicIp;

  /// Metadata used to create the destination Cloud SQL database.
  ///
  /// Immutable.
  CloudSqlSettings? settings;

  CloudSqlConnectionProfile();

  CloudSqlConnectionProfile.fromJson(core.Map _json) {
    if (_json.containsKey('cloudSqlId')) {
      cloudSqlId = _json['cloudSqlId'] as core.String;
    }
    if (_json.containsKey('privateIp')) {
      privateIp = _json['privateIp'] as core.String;
    }
    if (_json.containsKey('publicIp')) {
      publicIp = _json['publicIp'] as core.String;
    }
    if (_json.containsKey('settings')) {
      settings = CloudSqlSettings.fromJson(
          _json['settings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudSqlId != null) 'cloudSqlId': cloudSqlId!,
        if (privateIp != null) 'privateIp': privateIp!,
        if (publicIp != null) 'publicIp': publicIp!,
        if (settings != null) 'settings': settings!.toJson(),
      };
}

/// Settings for creating a Cloud SQL database instance.
class CloudSqlSettings {
  /// The activation policy specifies when the instance is activated; it is
  /// applicable only when the instance state is 'RUNNABLE'.
  ///
  /// Valid values: 'ALWAYS': The instance is on, and remains so even in the
  /// absence of connection requests. `NEVER`: The instance is off; it is not
  /// activated, even if a connection request arrives.
  /// Possible string values are:
  /// - "SQL_ACTIVATION_POLICY_UNSPECIFIED" : unspecified policy.
  /// - "ALWAYS" : The instance is always up and running.
  /// - "NEVER" : The instance should never spin up.
  core.String? activationPolicy;

  /// \[default: ON\] If you enable this setting, Cloud SQL checks your
  /// available storage every 30 seconds.
  ///
  /// If the available storage falls below a threshold size, Cloud SQL
  /// automatically adds additional storage capacity. If the available storage
  /// repeatedly falls below the threshold size, Cloud SQL continues to add
  /// storage until it reaches the maximum of 30 TB.
  core.bool? autoStorageIncrease;

  /// The Cloud SQL default instance level collation.
  core.String? collation;

  /// The storage capacity available to the database, in GB.
  ///
  /// The minimum (and default) size is 10GB.
  core.String? dataDiskSizeGb;

  /// The type of storage: `PD_SSD` (default) or `PD_HDD`.
  /// Possible string values are:
  /// - "SQL_DATA_DISK_TYPE_UNSPECIFIED" : Unspecified.
  /// - "PD_SSD" : SSD disk.
  /// - "PD_HDD" : HDD disk.
  core.String? dataDiskType;

  /// The database flags passed to the Cloud SQL instance at startup.
  ///
  /// An object containing a list of "key": value pairs. Example: { "name":
  /// "wrench", "mass": "1.3kg", "count": "3" }.
  core.Map<core.String, core.String>? databaseFlags;

  /// The database engine type and version.
  /// Possible string values are:
  /// - "SQL_DATABASE_VERSION_UNSPECIFIED" : Unspecified version.
  /// - "MYSQL_5_6" : MySQL 5.6.
  /// - "MYSQL_5_7" : MySQL 5.7.
  /// - "POSTGRES_9_6" : PostgreSQL 9.6.
  /// - "POSTGRES_11" : PostgreSQL 11.
  /// - "POSTGRES_10" : PostgreSQL 10.
  /// - "MYSQL_8_0" : MySQL 8.0.
  /// - "POSTGRES_12" : PostgreSQL 12.
  /// - "POSTGRES_13" : PostgreSQL 13.
  core.String? databaseVersion;

  /// The settings for IP Management.
  ///
  /// This allows to enable or disable the instance IP and manage which external
  /// networks can connect to the instance. The IPv4 address cannot be disabled.
  SqlIpConfig? ipConfig;

  /// Input only.
  ///
  /// Initial root password.
  core.String? rootPassword;

  /// Indicates If this connection profile root password is stored.
  ///
  /// Output only.
  core.bool? rootPasswordSet;

  /// The Database Migration Service source connection profile ID, in the
  /// format:
  /// `projects/my_project_name/locations/us-central1/connectionProfiles/connection_profile_ID`
  core.String? sourceId;

  /// The maximum size to which storage capacity can be automatically increased.
  ///
  /// The default value is 0, which specifies that there is no limit.
  core.String? storageAutoResizeLimit;

  /// The tier (or machine type) for this instance, for example:
  /// `db-n1-standard-1` (MySQL instances) or `db-custom-1-3840` (PostgreSQL
  /// instances).
  ///
  /// For more information, see
  /// [Cloud SQL Instance Settings](https://cloud.google.com/sql/docs/mysql/instance-settings).
  core.String? tier;

  /// The resource labels for a Cloud SQL instance to use to annotate any
  /// related underlying resources such as Compute Engine VMs.
  ///
  /// An object containing a list of "key": "value" pairs. Example: `{ "name":
  /// "wrench", "mass": "18kg", "count": "3" }`.
  core.Map<core.String, core.String>? userLabels;

  /// The Google Cloud Platform zone where your Cloud SQL datdabse instance is
  /// located.
  core.String? zone;

  CloudSqlSettings();

  CloudSqlSettings.fromJson(core.Map _json) {
    if (_json.containsKey('activationPolicy')) {
      activationPolicy = _json['activationPolicy'] as core.String;
    }
    if (_json.containsKey('autoStorageIncrease')) {
      autoStorageIncrease = _json['autoStorageIncrease'] as core.bool;
    }
    if (_json.containsKey('collation')) {
      collation = _json['collation'] as core.String;
    }
    if (_json.containsKey('dataDiskSizeGb')) {
      dataDiskSizeGb = _json['dataDiskSizeGb'] as core.String;
    }
    if (_json.containsKey('dataDiskType')) {
      dataDiskType = _json['dataDiskType'] as core.String;
    }
    if (_json.containsKey('databaseFlags')) {
      databaseFlags =
          (_json['databaseFlags'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('databaseVersion')) {
      databaseVersion = _json['databaseVersion'] as core.String;
    }
    if (_json.containsKey('ipConfig')) {
      ipConfig = SqlIpConfig.fromJson(
          _json['ipConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rootPassword')) {
      rootPassword = _json['rootPassword'] as core.String;
    }
    if (_json.containsKey('rootPasswordSet')) {
      rootPasswordSet = _json['rootPasswordSet'] as core.bool;
    }
    if (_json.containsKey('sourceId')) {
      sourceId = _json['sourceId'] as core.String;
    }
    if (_json.containsKey('storageAutoResizeLimit')) {
      storageAutoResizeLimit = _json['storageAutoResizeLimit'] as core.String;
    }
    if (_json.containsKey('tier')) {
      tier = _json['tier'] as core.String;
    }
    if (_json.containsKey('userLabels')) {
      userLabels =
          (_json['userLabels'] as core.Map<core.String, core.dynamic>).map(
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
        if (activationPolicy != null) 'activationPolicy': activationPolicy!,
        if (autoStorageIncrease != null)
          'autoStorageIncrease': autoStorageIncrease!,
        if (collation != null) 'collation': collation!,
        if (dataDiskSizeGb != null) 'dataDiskSizeGb': dataDiskSizeGb!,
        if (dataDiskType != null) 'dataDiskType': dataDiskType!,
        if (databaseFlags != null) 'databaseFlags': databaseFlags!,
        if (databaseVersion != null) 'databaseVersion': databaseVersion!,
        if (ipConfig != null) 'ipConfig': ipConfig!.toJson(),
        if (rootPassword != null) 'rootPassword': rootPassword!,
        if (rootPasswordSet != null) 'rootPasswordSet': rootPasswordSet!,
        if (sourceId != null) 'sourceId': sourceId!,
        if (storageAutoResizeLimit != null)
          'storageAutoResizeLimit': storageAutoResizeLimit!,
        if (tier != null) 'tier': tier!,
        if (userLabels != null) 'userLabels': userLabels!,
        if (zone != null) 'zone': zone!,
      };
}

/// A connection profile definition.
class ConnectionProfile {
  /// A CloudSQL database connection profile.
  CloudSqlConnectionProfile? cloudsql;

  /// The timestamp when the resource was created.
  ///
  /// A timestamp in RFC3339 UTC "Zulu" format, accurate to nanoseconds.
  /// Example: "2014-10-02T15:01:23.045123456Z".
  ///
  /// Output only.
  core.String? createTime;

  /// The connection profile display name.
  core.String? displayName;

  /// The error details in case of state FAILED.
  ///
  /// Output only.
  Status? error;

  /// The resource labels for connection profile to use to annotate any related
  /// underlying resources such as Compute Engine VMs.
  ///
  /// An object containing a list of "key": "value" pairs. Example: `{ "name":
  /// "wrench", "mass": "1.3kg", "count": "3" }`.
  core.Map<core.String, core.String>? labels;

  /// A MySQL database connection profile.
  MySqlConnectionProfile? mysql;

  /// The name of this connection profile resource in the form of
  /// projects/{project}/locations/{location}/connectionProfiles/{instance}.
  core.String? name;

  /// A PostgreSQL database connection profile.
  PostgreSqlConnectionProfile? postgresql;

  /// The database provider.
  /// Possible string values are:
  /// - "DATABASE_PROVIDER_UNSPECIFIED" : The database provider is unknown.
  /// - "CLOUDSQL" : CloudSQL runs the database.
  /// - "RDS" : RDS runs the database.
  core.String? provider;

  /// The current connection profile state (e.g. DRAFT, READY, or FAILED).
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The state of the connection profile is unknown.
  /// - "DRAFT" : The connection profile is in draft mode and fully editable.
  /// - "CREATING" : The connection profile is being created.
  /// - "READY" : The connection profile is ready.
  /// - "UPDATING" : The connection profile is being updated.
  /// - "DELETING" : The connection profile is being deleted.
  /// - "DELETED" : The connection profile has been deleted.
  /// - "FAILED" : The last action on the connection profile failed.
  core.String? state;

  /// The timestamp when the resource was last updated.
  ///
  /// A timestamp in RFC3339 UTC "Zulu" format, accurate to nanoseconds.
  /// Example: "2014-10-02T15:01:23.045123456Z".
  ///
  /// Output only.
  core.String? updateTime;

  ConnectionProfile();

  ConnectionProfile.fromJson(core.Map _json) {
    if (_json.containsKey('cloudsql')) {
      cloudsql = CloudSqlConnectionProfile.fromJson(
          _json['cloudsql'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('mysql')) {
      mysql = MySqlConnectionProfile.fromJson(
          _json['mysql'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('postgresql')) {
      postgresql = PostgreSqlConnectionProfile.fromJson(
          _json['postgresql'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('provider')) {
      provider = _json['provider'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudsql != null) 'cloudsql': cloudsql!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (error != null) 'error': error!.toJson(),
        if (labels != null) 'labels': labels!,
        if (mysql != null) 'mysql': mysql!.toJson(),
        if (name != null) 'name': name!,
        if (postgresql != null) 'postgresql': postgresql!.toJson(),
        if (provider != null) 'provider': provider!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// A message defining the database engine and provider.
class DatabaseType {
  /// The database engine.
  /// Possible string values are:
  /// - "DATABASE_ENGINE_UNSPECIFIED" : The source database engine of the
  /// migration job is unknown.
  /// - "MYSQL" : The source engine is MySQL.
  /// - "POSTGRESQL" : The source engine is PostgreSQL.
  core.String? engine;

  /// The database provider.
  /// Possible string values are:
  /// - "DATABASE_PROVIDER_UNSPECIFIED" : The database provider is unknown.
  /// - "CLOUDSQL" : CloudSQL runs the database.
  /// - "RDS" : RDS runs the database.
  core.String? provider;

  DatabaseType();

  DatabaseType.fromJson(core.Map _json) {
    if (_json.containsKey('engine')) {
      engine = _json['engine'] as core.String;
    }
    if (_json.containsKey('provider')) {
      provider = _json['provider'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (engine != null) 'engine': engine!,
        if (provider != null) 'provider': provider!,
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

/// Request message for 'GenerateSshScript' request.
class GenerateSshScriptRequest {
  /// Bastion VM Instance name to use or to create.
  ///
  /// Required.
  core.String? vm;

  /// The VM creation configuration
  VmCreationConfig? vmCreationConfig;

  /// The port that will be open on the bastion host
  core.int? vmPort;

  /// The VM selection configuration
  VmSelectionConfig? vmSelectionConfig;

  GenerateSshScriptRequest();

  GenerateSshScriptRequest.fromJson(core.Map _json) {
    if (_json.containsKey('vm')) {
      vm = _json['vm'] as core.String;
    }
    if (_json.containsKey('vmCreationConfig')) {
      vmCreationConfig = VmCreationConfig.fromJson(
          _json['vmCreationConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('vmPort')) {
      vmPort = _json['vmPort'] as core.int;
    }
    if (_json.containsKey('vmSelectionConfig')) {
      vmSelectionConfig = VmSelectionConfig.fromJson(
          _json['vmSelectionConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vm != null) 'vm': vm!,
        if (vmCreationConfig != null)
          'vmCreationConfig': vmCreationConfig!.toJson(),
        if (vmPort != null) 'vmPort': vmPort!,
        if (vmSelectionConfig != null)
          'vmSelectionConfig': vmSelectionConfig!.toJson(),
      };
}

/// Represents the metadata of the long-running operation.
class GoogleCloudClouddmsV1OperationMetadata {
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

  /// Name of the verb executed by the operation.
  ///
  /// Output only.
  core.String? verb;

  GoogleCloudClouddmsV1OperationMetadata();

  GoogleCloudClouddmsV1OperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
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
    if (_json.containsKey('verb')) {
      verb = _json['verb'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (createTime != null) 'createTime': createTime!,
        if (endTime != null) 'endTime': endTime!,
        if (requestedCancellation != null)
          'requestedCancellation': requestedCancellation!,
        if (statusMessage != null) 'statusMessage': statusMessage!,
        if (target != null) 'target': target!,
        if (verb != null) 'verb': verb!,
      };
}

/// Response message for 'ListConnectionProfiles' request.
class ListConnectionProfilesResponse {
  /// The response list of connection profiles.
  core.List<ConnectionProfile>? connectionProfiles;

  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListConnectionProfilesResponse();

  ListConnectionProfilesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('connectionProfiles')) {
      connectionProfiles = (_json['connectionProfiles'] as core.List)
          .map<ConnectionProfile>((value) => ConnectionProfile.fromJson(
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
        if (connectionProfiles != null)
          'connectionProfiles':
              connectionProfiles!.map((value) => value.toJson()).toList(),
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

/// Response message for 'ListMigrationJobs' request.
class ListMigrationJobsResponse {
  /// The list of migration jobs objects.
  core.List<MigrationJob>? migrationJobs;

  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// Locations that could not be reached.
  core.List<core.String>? unreachable;

  ListMigrationJobsResponse();

  ListMigrationJobsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('migrationJobs')) {
      migrationJobs = (_json['migrationJobs'] as core.List)
          .map<MigrationJob>((value) => MigrationJob.fromJson(
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
        if (migrationJobs != null)
          'migrationJobs':
              migrationJobs!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (unreachable != null) 'unreachable': unreachable!,
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

/// Represents a Database Migration Service migration job object.
class MigrationJob {
  /// The timestamp when the migration job resource was created.
  ///
  /// A timestamp in RFC3339 UTC "Zulu" format, accurate to nanoseconds.
  /// Example: "2014-10-02T15:01:23.045123456Z".
  ///
  /// Output only.
  core.String? createTime;

  /// The resource name (URI) of the destination connection profile.
  ///
  /// Required.
  core.String? destination;

  /// The database engine type and provider of the destination.
  DatabaseType? destinationDatabase;

  /// The migration job display name.
  core.String? displayName;

  /// The path to the dump file in Google Cloud Storage, in the format:
  /// (gs://\[BUCKET_NAME\]/\[OBJECT_NAME\]).
  core.String? dumpPath;

  /// The duration of the migration job (in seconds).
  ///
  /// A duration in seconds with up to nine fractional digits, terminated by
  /// 's'. Example: "3.5s".
  ///
  /// Output only.
  core.String? duration;

  /// If the migration job is completed, the time when it was completed.
  ///
  /// Output only.
  core.String? endTime;

  /// The error details in case of state FAILED.
  ///
  /// Output only.
  Status? error;

  /// The resource labels for migration job to use to annotate any related
  /// underlying resources such as Compute Engine VMs.
  ///
  /// An object containing a list of "key": "value" pairs. Example: `{ "name":
  /// "wrench", "mass": "1.3kg", "count": "3" }`.
  core.Map<core.String, core.String>? labels;

  /// The name (URI) of this migration job resource, in the form of:
  /// projects/{project}/locations/{location}/instances/{instance}.
  core.String? name;

  /// The current migration job phase.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PHASE_UNSPECIFIED" : The phase of the migration job is unknown.
  /// - "FULL_DUMP" : The migration job is in the full dump phase.
  /// - "CDC" : The migration job is CDC phase.
  /// - "PROMOTE_IN_PROGRESS" : The migration job is running the promote phase.
  /// - "WAITING_FOR_SOURCE_WRITES_TO_STOP" : Only RDS flow - waiting for source
  /// writes to stop
  /// - "PREPARING_THE_DUMP" : Only RDS flow - the sources writes stopped,
  /// waiting for dump to begin
  core.String? phase;

  /// The details needed to communicate to the source over Reverse SSH tunnel
  /// connectivity.
  ReverseSshConnectivity? reverseSshConnectivity;

  /// The resource name (URI) of the source connection profile.
  ///
  /// Required.
  core.String? source;

  /// The database engine type and provider of the source.
  DatabaseType? sourceDatabase;

  /// The current migration job state.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The state of the migration job is unknown.
  /// - "MAINTENANCE" : The migration job is down for maintenance.
  /// - "DRAFT" : The migration job is in draft mode and no resources are
  /// created.
  /// - "CREATING" : The migration job is being created.
  /// - "NOT_STARTED" : The migration job is created, not started and is fully
  /// editable.
  /// - "RUNNING" : The migration job is running.
  /// - "FAILED" : The migration job failed.
  /// - "COMPLETED" : The migration job has been completed.
  /// - "DELETING" : The migration job is being deleted.
  /// - "STOPPING" : The migration job is being stopped.
  /// - "STOPPED" : The migration job is currently stopped.
  /// - "DELETED" : The migration job has been deleted.
  /// - "UPDATING" : The migration job is being updated.
  /// - "STARTING" : The migration job is starting.
  /// - "RESTARTING" : The migration job is restarting.
  /// - "RESUMING" : The migration job is resuming.
  core.String? state;

  /// static ip connectivity data (default, no additional details needed).
  StaticIpConnectivity? staticIpConnectivity;

  /// The migration job type.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : The type of the migration job is unknown.
  /// - "ONE_TIME" : The migration job is a one time migration.
  /// - "CONTINUOUS" : The migration job is a continuous migration.
  core.String? type;

  /// The timestamp when the migration job resource was last updated.
  ///
  /// A timestamp in RFC3339 UTC "Zulu" format, accurate to nanoseconds.
  /// Example: "2014-10-02T15:01:23.045123456Z".
  ///
  /// Output only.
  core.String? updateTime;

  /// The details of the VPC network that the source database is located in.
  VpcPeeringConnectivity? vpcPeeringConnectivity;

  MigrationJob();

  MigrationJob.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('destinationDatabase')) {
      destinationDatabase = DatabaseType.fromJson(
          _json['destinationDatabase'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('dumpPath')) {
      dumpPath = _json['dumpPath'] as core.String;
    }
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('phase')) {
      phase = _json['phase'] as core.String;
    }
    if (_json.containsKey('reverseSshConnectivity')) {
      reverseSshConnectivity = ReverseSshConnectivity.fromJson(
          _json['reverseSshConnectivity']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('sourceDatabase')) {
      sourceDatabase = DatabaseType.fromJson(
          _json['sourceDatabase'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('staticIpConnectivity')) {
      staticIpConnectivity = StaticIpConnectivity.fromJson(
          _json['staticIpConnectivity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('vpcPeeringConnectivity')) {
      vpcPeeringConnectivity = VpcPeeringConnectivity.fromJson(
          _json['vpcPeeringConnectivity']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (destination != null) 'destination': destination!,
        if (destinationDatabase != null)
          'destinationDatabase': destinationDatabase!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (dumpPath != null) 'dumpPath': dumpPath!,
        if (duration != null) 'duration': duration!,
        if (endTime != null) 'endTime': endTime!,
        if (error != null) 'error': error!.toJson(),
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (phase != null) 'phase': phase!,
        if (reverseSshConnectivity != null)
          'reverseSshConnectivity': reverseSshConnectivity!.toJson(),
        if (source != null) 'source': source!,
        if (sourceDatabase != null) 'sourceDatabase': sourceDatabase!.toJson(),
        if (state != null) 'state': state!,
        if (staticIpConnectivity != null)
          'staticIpConnectivity': staticIpConnectivity!.toJson(),
        if (type != null) 'type': type!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (vpcPeeringConnectivity != null)
          'vpcPeeringConnectivity': vpcPeeringConnectivity!.toJson(),
      };
}

/// Error message of a verification Migration job.
class MigrationJobVerificationError {
  /// An instance of ErrorCode specifying the error that occurred.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ERROR_CODE_UNSPECIFIED" : An unknown error occurred
  /// - "CONNECTION_FAILURE" : We failed to connect to one of the connection
  /// profile.
  /// - "AUTHENTICATION_FAILURE" : We failed to authenticate to one of the
  /// connection profile.
  /// - "INVALID_CONNECTION_PROFILE_CONFIG" : One of the involved connection
  /// profiles has an invalid configuration.
  /// - "VERSION_INCOMPATIBILITY" : The versions of the source and the
  /// destination are incompatible.
  /// - "CONNECTION_PROFILE_TYPES_INCOMPATIBILITY" : The types of the source and
  /// the destination are incompatible.
  /// - "NO_PGLOGICAL_INSTALLED" : No pglogical extension installed on
  /// databases, applicable for postgres.
  /// - "PGLOGICAL_NODE_ALREADY_EXISTS" : pglogical node already exists on
  /// databases, applicable for postgres.
  /// - "INVALID_WAL_LEVEL" : The value of parameter wal_level is not set to
  /// logical.
  /// - "INVALID_SHARED_PRELOAD_LIBRARY" : The value of parameter
  /// shared_preload_libraries does not include pglogical.
  /// - "INSUFFICIENT_MAX_REPLICATION_SLOTS" : The value of parameter
  /// max_replication_slots is not sufficient.
  /// - "INSUFFICIENT_MAX_WAL_SENDERS" : The value of parameter max_wal_senders
  /// is not sufficient.
  /// - "INSUFFICIENT_MAX_WORKER_PROCESSES" : The value of parameter
  /// max_worker_processes is not sufficient.
  /// - "UNSUPPORTED_EXTENSIONS" : Extensions installed are either not supported
  /// or having unsupported versions.
  /// - "UNSUPPORTED_MIGRATION_TYPE" : Unsupported migration type.
  /// - "INVALID_RDS_LOGICAL_REPLICATION" : Invalid RDS logical replication.
  /// - "UNSUPPORTED_GTID_MODE" : The gtid_mode is not supported, applicable for
  /// MySQL.
  /// - "UNSUPPORTED_TABLE_DEFINITION" : The table definition is not support due
  /// to missing primary key or replica identity.
  /// - "UNSUPPORTED_DEFINER" : The definer is not supported.
  /// - "CANT_RESTART_RUNNING_MIGRATION" : Migration is already running at the
  /// time of restart request.
  core.String? errorCode;

  /// A specific detailed error message, if supplied by the engine.
  ///
  /// Output only.
  core.String? errorDetailMessage;

  /// A formatted message with further details about the error and a CTA.
  ///
  /// Output only.
  core.String? errorMessage;

  MigrationJobVerificationError();

  MigrationJobVerificationError.fromJson(core.Map _json) {
    if (_json.containsKey('errorCode')) {
      errorCode = _json['errorCode'] as core.String;
    }
    if (_json.containsKey('errorDetailMessage')) {
      errorDetailMessage = _json['errorDetailMessage'] as core.String;
    }
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorCode != null) 'errorCode': errorCode!,
        if (errorDetailMessage != null)
          'errorDetailMessage': errorDetailMessage!,
        if (errorMessage != null) 'errorMessage': errorMessage!,
      };
}

/// Specifies connection parameters required specifically for MySQL databases.
class MySqlConnectionProfile {
  /// If the source is a Cloud SQL database, use this field to provide the Cloud
  /// SQL instance ID of the source.
  core.String? cloudSqlId;

  /// The IP or hostname of the source MySQL database.
  ///
  /// Required.
  core.String? host;

  /// Input only.
  ///
  /// The password for the user that Database Migration Service will be using to
  /// connect to the database. This field is not returned on request, and the
  /// value is encrypted when stored in Database Migration Service.
  ///
  /// Required.
  core.String? password;

  /// Indicates If this connection profile password is stored.
  ///
  /// Output only.
  core.bool? passwordSet;

  /// The network port of the source MySQL database.
  ///
  /// Required.
  core.int? port;

  /// SSL configuration for the destination to connect to the source database.
  SslConfig? ssl;

  /// The username that Database Migration Service will use to connect to the
  /// database.
  ///
  /// The value is encrypted when stored in Database Migration Service.
  ///
  /// Required.
  core.String? username;

  MySqlConnectionProfile();

  MySqlConnectionProfile.fromJson(core.Map _json) {
    if (_json.containsKey('cloudSqlId')) {
      cloudSqlId = _json['cloudSqlId'] as core.String;
    }
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('passwordSet')) {
      passwordSet = _json['passwordSet'] as core.bool;
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.int;
    }
    if (_json.containsKey('ssl')) {
      ssl = SslConfig.fromJson(
          _json['ssl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('username')) {
      username = _json['username'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudSqlId != null) 'cloudSqlId': cloudSqlId!,
        if (host != null) 'host': host!,
        if (password != null) 'password': password!,
        if (passwordSet != null) 'passwordSet': passwordSet!,
        if (port != null) 'port': port!,
        if (ssl != null) 'ssl': ssl!.toJson(),
        if (username != null) 'username': username!,
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

/// Specifies connection parameters required specifically for PostgreSQL
/// databases.
class PostgreSqlConnectionProfile {
  /// If the source is a Cloud SQL database, use this field to provide the Cloud
  /// SQL instance ID of the source.
  core.String? cloudSqlId;

  /// The IP or hostname of the source PostgreSQL database.
  ///
  /// Required.
  core.String? host;

  /// Input only.
  ///
  /// The password for the user that Database Migration Service will be using to
  /// connect to the database. This field is not returned on request, and the
  /// value is encrypted when stored in Database Migration Service.
  ///
  /// Required.
  core.String? password;

  /// Indicates If this connection profile password is stored.
  ///
  /// Output only.
  core.bool? passwordSet;

  /// The network port of the source PostgreSQL database.
  ///
  /// Required.
  core.int? port;

  /// SSL configuration for the destination to connect to the source database.
  SslConfig? ssl;

  /// The username that Database Migration Service will use to connect to the
  /// database.
  ///
  /// The value is encrypted when stored in Database Migration Service.
  ///
  /// Required.
  core.String? username;

  PostgreSqlConnectionProfile();

  PostgreSqlConnectionProfile.fromJson(core.Map _json) {
    if (_json.containsKey('cloudSqlId')) {
      cloudSqlId = _json['cloudSqlId'] as core.String;
    }
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('passwordSet')) {
      passwordSet = _json['passwordSet'] as core.bool;
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.int;
    }
    if (_json.containsKey('ssl')) {
      ssl = SslConfig.fromJson(
          _json['ssl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('username')) {
      username = _json['username'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudSqlId != null) 'cloudSqlId': cloudSqlId!,
        if (host != null) 'host': host!,
        if (password != null) 'password': password!,
        if (passwordSet != null) 'passwordSet': passwordSet!,
        if (port != null) 'port': port!,
        if (ssl != null) 'ssl': ssl!.toJson(),
        if (username != null) 'username': username!,
      };
}

/// Request message for 'PromoteMigrationJob' request.
class PromoteMigrationJobRequest {
  PromoteMigrationJobRequest();

  PromoteMigrationJobRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for 'RestartMigrationJob' request.
class RestartMigrationJobRequest {
  RestartMigrationJobRequest();

  RestartMigrationJobRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for 'ResumeMigrationJob' request.
class ResumeMigrationJobRequest {
  ResumeMigrationJobRequest();

  ResumeMigrationJobRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The details needed to configure a reverse SSH tunnel between the source and
/// destination databases.
///
/// These details will be used when calling the generateSshScript method (see
/// https://cloud.google.com/database-migration/docs/reference/rest/v1/projects.locations.migrationJobs/generateSshScript)
/// to produce the script that will help set up the reverse SSH tunnel, and to
/// set up the VPC peering between the Cloud SQL private network and the VPC.
class ReverseSshConnectivity {
  /// The name of the virtual machine (Compute Engine) used as the bastion
  /// server for the SSH tunnel.
  core.String? vm;

  /// The IP of the virtual machine (Compute Engine) used as the bastion server
  /// for the SSH tunnel.
  ///
  /// Required.
  core.String? vmIp;

  /// The forwarding port of the virtual machine (Compute Engine) used as the
  /// bastion server for the SSH tunnel.
  ///
  /// Required.
  core.int? vmPort;

  /// The name of the VPC to peer with the Cloud SQL private network.
  core.String? vpc;

  ReverseSshConnectivity();

  ReverseSshConnectivity.fromJson(core.Map _json) {
    if (_json.containsKey('vm')) {
      vm = _json['vm'] as core.String;
    }
    if (_json.containsKey('vmIp')) {
      vmIp = _json['vmIp'] as core.String;
    }
    if (_json.containsKey('vmPort')) {
      vmPort = _json['vmPort'] as core.int;
    }
    if (_json.containsKey('vpc')) {
      vpc = _json['vpc'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vm != null) 'vm': vm!,
        if (vmIp != null) 'vmIp': vmIp!,
        if (vmPort != null) 'vmPort': vmPort!,
        if (vpc != null) 'vpc': vpc!,
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

/// An entry for an Access Control list.
class SqlAclEntry {
  /// The time when this access control entry expires in
  /// [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example:
  /// `2012-11-15T16:19:00.094Z`.
  core.String? expireTime;

  /// A label to identify this entry.
  core.String? label;

  /// Input only.
  ///
  /// The time-to-leave of this access control entry.
  core.String? ttl;

  /// The allowlisted value for the access control list.
  core.String? value;

  SqlAclEntry();

  SqlAclEntry.fromJson(core.Map _json) {
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('ttl')) {
      ttl = _json['ttl'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expireTime != null) 'expireTime': expireTime!,
        if (label != null) 'label': label!,
        if (ttl != null) 'ttl': ttl!,
        if (value != null) 'value': value!,
      };
}

/// IP Management configuration.
class SqlIpConfig {
  /// The list of external networks that are allowed to connect to the instance
  /// using the IP.
  ///
  /// See https://en.wikipedia.org/wiki/CIDR_notation#CIDR_notation, also known
  /// as 'slash' notation (e.g. `192.168.100.0/24`).
  core.List<SqlAclEntry>? authorizedNetworks;

  /// Whether the instance should be assigned an IPv4 address or not.
  core.bool? enableIpv4;

  /// The resource link for the VPC network from which the Cloud SQL instance is
  /// accessible for private IP.
  ///
  /// For example, `projects/myProject/global/networks/default`. This setting
  /// can be updated, but it cannot be removed after it is set.
  core.String? privateNetwork;

  /// Whether SSL connections over IP should be enforced or not.
  core.bool? requireSsl;

  SqlIpConfig();

  SqlIpConfig.fromJson(core.Map _json) {
    if (_json.containsKey('authorizedNetworks')) {
      authorizedNetworks = (_json['authorizedNetworks'] as core.List)
          .map<SqlAclEntry>((value) => SqlAclEntry.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('enableIpv4')) {
      enableIpv4 = _json['enableIpv4'] as core.bool;
    }
    if (_json.containsKey('privateNetwork')) {
      privateNetwork = _json['privateNetwork'] as core.String;
    }
    if (_json.containsKey('requireSsl')) {
      requireSsl = _json['requireSsl'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authorizedNetworks != null)
          'authorizedNetworks':
              authorizedNetworks!.map((value) => value.toJson()).toList(),
        if (enableIpv4 != null) 'enableIpv4': enableIpv4!,
        if (privateNetwork != null) 'privateNetwork': privateNetwork!,
        if (requireSsl != null) 'requireSsl': requireSsl!,
      };
}

/// Response message for 'GenerateSshScript' request.
class SshScript {
  /// The ssh configuration script.
  core.String? script;

  SshScript();

  SshScript.fromJson(core.Map _json) {
    if (_json.containsKey('script')) {
      script = _json['script'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (script != null) 'script': script!,
      };
}

/// SSL configuration information.
class SslConfig {
  /// Input only.
  ///
  /// The x509 PEM-encoded certificate of the CA that signed the source database
  /// server's certificate. The replica will use this certificate to verify it's
  /// connecting to the right host.
  ///
  /// Required.
  core.String? caCertificate;

  /// Input only.
  ///
  /// The x509 PEM-encoded certificate that will be used by the replica to
  /// authenticate against the source database server.If this field is used then
  /// the 'client_key' field is mandatory.
  core.String? clientCertificate;

  /// Input only.
  ///
  /// The unencrypted PKCS#1 or PKCS#8 PEM-encoded private key associated with
  /// the Client Certificate. If this field is used then the
  /// 'client_certificate' field is mandatory.
  core.String? clientKey;

  /// The ssl config type according to 'client_key', 'client_certificate' and
  /// 'ca_certificate'.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "SSL_TYPE_UNSPECIFIED" : Unspecified.
  /// - "SERVER_ONLY" : Only 'ca_certificate' specified.
  /// - "SERVER_CLIENT" : Both server ('ca_certificate'), and client
  /// ('client_key', 'client_certificate') specified.
  core.String? type;

  SslConfig();

  SslConfig.fromJson(core.Map _json) {
    if (_json.containsKey('caCertificate')) {
      caCertificate = _json['caCertificate'] as core.String;
    }
    if (_json.containsKey('clientCertificate')) {
      clientCertificate = _json['clientCertificate'] as core.String;
    }
    if (_json.containsKey('clientKey')) {
      clientKey = _json['clientKey'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (caCertificate != null) 'caCertificate': caCertificate!,
        if (clientCertificate != null) 'clientCertificate': clientCertificate!,
        if (clientKey != null) 'clientKey': clientKey!,
        if (type != null) 'type': type!,
      };
}

/// Request message for 'StartMigrationJob' request.
class StartMigrationJobRequest {
  StartMigrationJobRequest();

  StartMigrationJobRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The source database will allow incoming connections from the destination
/// database's public IP.
///
/// You can retrieve the Cloud SQL instance's public IP from the Cloud SQL
/// console or using Cloud SQL APIs. No additional configuration is required.
class StaticIpConnectivity {
  StaticIpConnectivity();

  StaticIpConnectivity.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// Request message for 'StopMigrationJob' request.
class StopMigrationJobRequest {
  StopMigrationJobRequest();

  StopMigrationJobRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// Request message for 'VerifyMigrationJob' request.
class VerifyMigrationJobRequest {
  VerifyMigrationJobRequest();

  VerifyMigrationJobRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// VM creation configuration message
class VmCreationConfig {
  /// The subnet name the vm needs to be created in.
  core.String? subnet;

  /// VM instance machine type to create.
  ///
  /// Required.
  core.String? vmMachineType;

  /// The Google Cloud Platform zone to create the VM in.
  core.String? vmZone;

  VmCreationConfig();

  VmCreationConfig.fromJson(core.Map _json) {
    if (_json.containsKey('subnet')) {
      subnet = _json['subnet'] as core.String;
    }
    if (_json.containsKey('vmMachineType')) {
      vmMachineType = _json['vmMachineType'] as core.String;
    }
    if (_json.containsKey('vmZone')) {
      vmZone = _json['vmZone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (subnet != null) 'subnet': subnet!,
        if (vmMachineType != null) 'vmMachineType': vmMachineType!,
        if (vmZone != null) 'vmZone': vmZone!,
      };
}

/// VM selection configuration message
class VmSelectionConfig {
  /// The Google Cloud Platform zone the VM is located.
  ///
  /// Required.
  core.String? vmZone;

  VmSelectionConfig();

  VmSelectionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('vmZone')) {
      vmZone = _json['vmZone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vmZone != null) 'vmZone': vmZone!,
      };
}

/// The details of the VPC where the source database is located in Google Cloud.
///
/// We will use this information to set up the VPC peering connection between
/// Cloud SQL and this VPC.
class VpcPeeringConnectivity {
  /// The name of the VPC network to peer with the Cloud SQL private network.
  core.String? vpc;

  VpcPeeringConnectivity();

  VpcPeeringConnectivity.fromJson(core.Map _json) {
    if (_json.containsKey('vpc')) {
      vpc = _json['vpc'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vpc != null) 'vpc': vpc!,
      };
}

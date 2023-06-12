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

/// Cloud Composer API - v1
///
/// Manages Apache Airflow environments on Google Cloud Platform.
///
/// For more information, see <https://cloud.google.com/composer/>
///
/// Create an instance of [CloudComposerApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsEnvironmentsResource]
///     - [ProjectsLocationsImageVersionsResource]
///     - [ProjectsLocationsOperationsResource]
library composer.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Manages Apache Airflow environments on Google Cloud Platform.
class CloudComposerApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  CloudComposerApi(http.Client client,
      {core.String rootUrl = 'https://composer.googleapis.com/',
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

  ProjectsLocationsEnvironmentsResource get environments =>
      ProjectsLocationsEnvironmentsResource(_requester);
  ProjectsLocationsImageVersionsResource get imageVersions =>
      ProjectsLocationsImageVersionsResource(_requester);
  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsEnvironmentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsEnvironmentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create a new environment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent must be of the form
  /// "projects/{projectId}/locations/{locationId}".
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
    Environment request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/environments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete an environment.
  ///
  /// Request parameters:
  ///
  /// [name] - The environment to delete, in the form:
  /// "projects/{projectId}/locations/{locationId}/environments/{environmentId}"
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/environments/\[^/\]+$`.
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

  /// Get an existing environment.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the environment to get, in the form:
  /// "projects/{projectId}/locations/{locationId}/environments/{environmentId}"
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Environment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Environment> get(
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
    return Environment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List environments.
  ///
  /// Request parameters:
  ///
  /// [parent] - List environments in the given project and location, in the
  /// form: "projects/{projectId}/locations/{locationId}"
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of environments to return.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListEnvironmentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListEnvironmentsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/environments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListEnvironmentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update an environment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the environment to update, in the
  /// form:
  /// "projects/{projectId}/locations/{locationId}/environments/{environmentId}"
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A comma-separated list of paths, relative to
  /// `Environment`, of fields to update. For example, to set the version of
  /// scikit-learn to install in the environment to 0.19.0 and to remove an
  /// existing installation of numpy, the `updateMask` parameter would include
  /// the following two `paths` values:
  /// "config.softwareConfig.pypiPackages.scikit-learn" and
  /// "config.softwareConfig.pypiPackages.numpy". The included patch environment
  /// would specify the scikit-learn version as follows: { "config":{
  /// "softwareConfig":{ "pypiPackages":{ "scikit-learn":"==0.19.0" } } } } Note
  /// that in the above example, any existing PyPI packages other than
  /// scikit-learn and numpy will be unaffected. Only one update type may be
  /// included in a single request's `updateMask`. For example, one cannot
  /// update both the PyPI packages and labels in the same request. However, it
  /// is possible to update multiple members of a map field simultaneously in
  /// the same request. For example, to set the labels "label1" and "label2"
  /// while clearing "label3" (assuming it already exists), one can provide the
  /// paths "labels.label1", "labels.label2", and "labels.label3" and populate
  /// the patch environment as follows: { "labels":{ "label1":"new-label1-value"
  /// "label2":"new-label2-value" } } Note that in the above example, any
  /// existing labels that are not included in the `updateMask` will be
  /// unaffected. It is also possible to replace an entire map field by
  /// providing the map field's path in the `updateMask`. The new value of the
  /// field will be that which is provided in the patch environment. For
  /// example, to delete all pre-existing user-specified PyPI packages and
  /// install botocore at version 1.7.14, the `updateMask` would contain the
  /// path "config.softwareConfig.pypiPackages", and the patch environment would
  /// be the following: { "config":{ "softwareConfig":{ "pypiPackages":{
  /// "botocore":"==1.7.14" } } } } **Note:** Only the following fields can be
  /// updated: *Mask* *Purpose* config.softwareConfig.pypiPackages Replace all
  /// custom custom PyPI packages. If a replacement package map is not included
  /// in `environment`, all custom PyPI packages are cleared. It is an error to
  /// provide both this mask and a mask specifying an individual package.
  /// config.softwareConfig.pypiPackages.packagename Update the custom PyPI
  /// package packagename, preserving other packages. To delete the package,
  /// include it in `updateMask`, and omit the mapping for it in
  /// `environment.config.softwareConfig.pypiPackages`. It is an error to
  /// provide both a mask of this form and the
  /// "config.softwareConfig.pypiPackages" mask. labels Replace all environment
  /// labels. If a replacement labels map is not included in `environment`, all
  /// labels are cleared. It is an error to provide both this mask and a mask
  /// specifying one or more individual labels. labels.labelName Set the label
  /// named labelName, while preserving other labels. To delete the label,
  /// include it in `updateMask` and omit its mapping in `environment.labels`.
  /// It is an error to provide both a mask of this form and the "labels" mask.
  /// config.nodeCount Horizontally scale the number of nodes in the
  /// environment. An integer greater than or equal to 3 must be provided in the
  /// `config.nodeCount` field. config.webServerNetworkAccessControl Replace the
  /// environment's current WebServerNetworkAccessControl. config.databaseConfig
  /// Replace the environment's current DatabaseConfig. config.webServerConfig
  /// Replace the environment's current WebServerConfig.
  /// config.softwareConfig.airflowConfigOverrides Replace all Apache Airflow
  /// config overrides. If a replacement config overrides map is not included in
  /// `environment`, all config overrides are cleared. It is an error to provide
  /// both this mask and a mask specifying one or more individual config
  /// overrides. config.softwareConfig.airflowConfigOverrides.section-name
  /// Override the Apache Airflow config property name in the section named
  /// section, preserving other properties. To delete the property override,
  /// include it in `updateMask` and omit its mapping in
  /// `environment.config.softwareConfig.airflowConfigOverrides`. It is an error
  /// to provide both a mask of this form and the
  /// "config.softwareConfig.airflowConfigOverrides" mask.
  /// config.softwareConfig.envVariables Replace all environment variables. If a
  /// replacement environment variable map is not included in `environment`, all
  /// custom environment variables are cleared. It is an error to provide both
  /// this mask and a mask specifying one or more individual environment
  /// variables.
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
    Environment request,
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

class ProjectsLocationsImageVersionsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsImageVersionsResource(commons.ApiRequester client)
      : _requester = client;

  /// List ImageVersions for provided location.
  ///
  /// Request parameters:
  ///
  /// [parent] - List ImageVersions in the given project and location, in the
  /// form: "projects/{projectId}/locations/{locationId}"
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [includePastReleases] - Whether or not image versions from old releases
  /// should be included.
  ///
  /// [pageSize] - The maximum number of image_versions to return.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListImageVersionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListImageVersionsResponse> list(
    core.String parent, {
    core.bool? includePastReleases,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includePastReleases != null)
        'includePastReleases': ['${includePastReleases}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/imageVersions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListImageVersionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

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

/// Allowed IP range with user-provided description.
class AllowedIpRange {
  /// User-provided description.
  ///
  /// It must contain at most 300 characters.
  ///
  /// Optional.
  core.String? description;

  /// IP address or range, defined using CIDR notation, of requests that this
  /// rule applies to.
  ///
  /// Examples: `192.168.1.1` or `192.168.0.0/16` or `2001:db8::/32` or
  /// `2001:0db8:0000:0042:0000:8a2e:0370:7334`. IP range prefixes should be
  /// properly truncated. For example, `1.2.3.4/24` should be truncated to
  /// `1.2.3.0/24`. Similarly, for IPv6, `2001:db8::1/32` should be truncated to
  /// `2001:db8::/32`.
  core.String? value;

  AllowedIpRange();

  AllowedIpRange.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (value != null) 'value': value!,
      };
}

/// The configuration of Cloud SQL instance that is used by the Apache Airflow
/// software.
class DatabaseConfig {
  /// Cloud SQL machine type used by Airflow database.
  ///
  /// It has to be one of: db-n1-standard-2, db-n1-standard-4, db-n1-standard-8
  /// or db-n1-standard-16. If not specified, db-n1-standard-2 will be used.
  ///
  /// Optional.
  core.String? machineType;

  DatabaseConfig();

  DatabaseConfig.fromJson(core.Map _json) {
    if (_json.containsKey('machineType')) {
      machineType = _json['machineType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (machineType != null) 'machineType': machineType!,
      };
}

/// Represents a whole or partial calendar date, such as a birthday.
///
/// The time of day and time zone are either specified elsewhere or are
/// insignificant. The date is relative to the Gregorian Calendar. This can
/// represent one of the following: * A full date, with non-zero year, month,
/// and day values * A month and day value, with a zero year, such as an
/// anniversary * A year on its own, with zero month and day values * A year and
/// month value, with a zero day, such as a credit card expiration date Related
/// types are google.type.TimeOfDay and `google.protobuf.Timestamp`.
class Date {
  /// Day of a month.
  ///
  /// Must be from 1 to 31 and valid for the year and month, or 0 to specify a
  /// year by itself or a year and month where the day isn't significant.
  core.int? day;

  /// Month of a year.
  ///
  /// Must be from 1 to 12, or 0 to specify a year without a month and day.
  core.int? month;

  /// Year of the date.
  ///
  /// Must be from 1 to 9999, or 0 to specify a date without a year.
  core.int? year;

  Date();

  Date.fromJson(core.Map _json) {
    if (_json.containsKey('day')) {
      day = _json['day'] as core.int;
    }
    if (_json.containsKey('month')) {
      month = _json['month'] as core.int;
    }
    if (_json.containsKey('year')) {
      year = _json['year'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (day != null) 'day': day!,
        if (month != null) 'month': month!,
        if (year != null) 'year': year!,
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

/// The encryption options for the Cloud Composer environment and its
/// dependencies.
class EncryptionConfig {
  /// Customer-managed Encryption Key available through Google's Key Management
  /// Service.
  ///
  /// Cannot be updated. If not specified, Google-managed key will be used.
  ///
  /// Optional.
  core.String? kmsKeyName;

  EncryptionConfig();

  EncryptionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('kmsKeyName')) {
      kmsKeyName = _json['kmsKeyName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsKeyName != null) 'kmsKeyName': kmsKeyName!,
      };
}

/// An environment for running orchestration tasks.
class Environment {
  /// Configuration parameters for this environment.
  EnvironmentConfig? config;

  /// The time at which this environment was created.
  ///
  /// Output only.
  core.String? createTime;

  /// User-defined labels for this environment.
  ///
  /// The labels map can contain no more than 64 entries. Entries of the labels
  /// map are UTF8 strings that comply with the following restrictions: * Keys
  /// must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to
  /// regexp: \[\p{Ll}\p{Lo}\p{N}_-\]{0,63} * Both keys and values are
  /// additionally constrained to be <= 128 bytes in size.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the environment, in the form:
  /// "projects/{projectId}/locations/{locationId}/environments/{environmentId}"
  /// EnvironmentId must start with a lowercase letter followed by up to 63
  /// lowercase letters, numbers, or hyphens, and cannot end with a hyphen.
  core.String? name;

  /// The current state of the environment.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The state of the environment is unknown.
  /// - "CREATING" : The environment is in the process of being created.
  /// - "RUNNING" : The environment is currently running and healthy. It is
  /// ready for use.
  /// - "UPDATING" : The environment is being updated. It remains usable but
  /// cannot receive additional update requests or be deleted at this time.
  /// - "DELETING" : The environment is undergoing deletion. It cannot be used.
  /// - "ERROR" : The environment has encountered an error and cannot be used.
  core.String? state;

  /// The time at which this environment was last modified.
  ///
  /// Output only.
  core.String? updateTime;

  /// The UUID (Universally Unique IDentifier) associated with this environment.
  ///
  /// This value is generated when the environment is created.
  ///
  /// Output only.
  core.String? uuid;

  Environment();

  Environment.fromJson(core.Map _json) {
    if (_json.containsKey('config')) {
      config = EnvironmentConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
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
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('uuid')) {
      uuid = _json['uuid'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (config != null) 'config': config!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (uuid != null) 'uuid': uuid!,
      };
}

/// Configuration information for an environment.
class EnvironmentConfig {
  /// The URI of the Apache Airflow Web UI hosted within this environment (see
  /// \[Airflow web
  /// interface\](/composer/docs/how-to/accessing/airflow-web-interface)).
  ///
  /// Output only.
  core.String? airflowUri;

  /// The Cloud Storage prefix of the DAGs for this environment.
  ///
  /// Although Cloud Storage objects reside in a flat namespace, a hierarchical
  /// file tree can be simulated using "/"-delimited object name prefixes. DAG
  /// objects for this environment reside in a simulated directory with the
  /// given prefix.
  ///
  /// Output only.
  core.String? dagGcsPrefix;

  /// The configuration settings for Cloud SQL instance used internally by
  /// Apache Airflow software.
  ///
  /// Optional.
  DatabaseConfig? databaseConfig;

  /// The encryption options for the Cloud Composer environment and its
  /// dependencies.
  ///
  /// Cannot be updated.
  ///
  /// Optional.
  EncryptionConfig? encryptionConfig;

  /// The Kubernetes Engine cluster used to run this environment.
  ///
  /// Output only.
  core.String? gkeCluster;

  /// The configuration used for the Kubernetes Engine cluster.
  NodeConfig? nodeConfig;

  /// The number of nodes in the Kubernetes Engine cluster that will be used to
  /// run this environment.
  core.int? nodeCount;

  /// The configuration used for the Private IP Cloud Composer environment.
  PrivateEnvironmentConfig? privateEnvironmentConfig;

  /// The configuration settings for software inside the environment.
  SoftwareConfig? softwareConfig;

  /// The configuration settings for the Airflow web server App Engine instance.
  ///
  /// Optional.
  WebServerConfig? webServerConfig;

  /// The network-level access control policy for the Airflow web server.
  ///
  /// If unspecified, no network-level access restrictions will be applied.
  ///
  /// Optional.
  WebServerNetworkAccessControl? webServerNetworkAccessControl;

  EnvironmentConfig();

  EnvironmentConfig.fromJson(core.Map _json) {
    if (_json.containsKey('airflowUri')) {
      airflowUri = _json['airflowUri'] as core.String;
    }
    if (_json.containsKey('dagGcsPrefix')) {
      dagGcsPrefix = _json['dagGcsPrefix'] as core.String;
    }
    if (_json.containsKey('databaseConfig')) {
      databaseConfig = DatabaseConfig.fromJson(
          _json['databaseConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('encryptionConfig')) {
      encryptionConfig = EncryptionConfig.fromJson(
          _json['encryptionConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gkeCluster')) {
      gkeCluster = _json['gkeCluster'] as core.String;
    }
    if (_json.containsKey('nodeConfig')) {
      nodeConfig = NodeConfig.fromJson(
          _json['nodeConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nodeCount')) {
      nodeCount = _json['nodeCount'] as core.int;
    }
    if (_json.containsKey('privateEnvironmentConfig')) {
      privateEnvironmentConfig = PrivateEnvironmentConfig.fromJson(
          _json['privateEnvironmentConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('softwareConfig')) {
      softwareConfig = SoftwareConfig.fromJson(
          _json['softwareConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webServerConfig')) {
      webServerConfig = WebServerConfig.fromJson(
          _json['webServerConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webServerNetworkAccessControl')) {
      webServerNetworkAccessControl = WebServerNetworkAccessControl.fromJson(
          _json['webServerNetworkAccessControl']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (airflowUri != null) 'airflowUri': airflowUri!,
        if (dagGcsPrefix != null) 'dagGcsPrefix': dagGcsPrefix!,
        if (databaseConfig != null) 'databaseConfig': databaseConfig!.toJson(),
        if (encryptionConfig != null)
          'encryptionConfig': encryptionConfig!.toJson(),
        if (gkeCluster != null) 'gkeCluster': gkeCluster!,
        if (nodeConfig != null) 'nodeConfig': nodeConfig!.toJson(),
        if (nodeCount != null) 'nodeCount': nodeCount!,
        if (privateEnvironmentConfig != null)
          'privateEnvironmentConfig': privateEnvironmentConfig!.toJson(),
        if (softwareConfig != null) 'softwareConfig': softwareConfig!.toJson(),
        if (webServerConfig != null)
          'webServerConfig': webServerConfig!.toJson(),
        if (webServerNetworkAccessControl != null)
          'webServerNetworkAccessControl':
              webServerNetworkAccessControl!.toJson(),
      };
}

/// Configuration for controlling how IPs are allocated in the GKE cluster
/// running the Apache Airflow software.
class IPAllocationPolicy {
  /// The IP address range used to allocate IP addresses to pods in the GKE
  /// cluster.
  ///
  /// This field is applicable only when `use_ip_aliases` is true. Set to blank
  /// to have GKE choose a range with the default size. Set to /netmask (e.g.
  /// `/14`) to have GKE choose a range with a specific netmask. Set to a
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `10.96.0.0/14`) from the RFC-1918 private networks (e.g.
  /// `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) to pick a specific range
  /// to use.
  ///
  /// Optional.
  core.String? clusterIpv4CidrBlock;

  /// The name of the GKE cluster's secondary range used to allocate IP
  /// addresses to pods.
  ///
  /// This field is applicable only when `use_ip_aliases` is true.
  ///
  /// Optional.
  core.String? clusterSecondaryRangeName;

  /// The IP address range of the services IP addresses in this GKE cluster.
  ///
  /// This field is applicable only when `use_ip_aliases` is true. Set to blank
  /// to have GKE choose a range with the default size. Set to /netmask (e.g.
  /// `/14`) to have GKE choose a range with a specific netmask. Set to a
  /// [CIDR](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
  /// notation (e.g. `10.96.0.0/14`) from the RFC-1918 private networks (e.g.
  /// `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) to pick a specific range
  /// to use.
  ///
  /// Optional.
  core.String? servicesIpv4CidrBlock;

  /// The name of the services' secondary range used to allocate IP addresses to
  /// the GKE cluster.
  ///
  /// This field is applicable only when `use_ip_aliases` is true.
  ///
  /// Optional.
  core.String? servicesSecondaryRangeName;

  /// Whether or not to enable Alias IPs in the GKE cluster.
  ///
  /// If `true`, a VPC-native cluster is created.
  ///
  /// Optional.
  core.bool? useIpAliases;

  IPAllocationPolicy();

  IPAllocationPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('clusterIpv4CidrBlock')) {
      clusterIpv4CidrBlock = _json['clusterIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('clusterSecondaryRangeName')) {
      clusterSecondaryRangeName =
          _json['clusterSecondaryRangeName'] as core.String;
    }
    if (_json.containsKey('servicesIpv4CidrBlock')) {
      servicesIpv4CidrBlock = _json['servicesIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('servicesSecondaryRangeName')) {
      servicesSecondaryRangeName =
          _json['servicesSecondaryRangeName'] as core.String;
    }
    if (_json.containsKey('useIpAliases')) {
      useIpAliases = _json['useIpAliases'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterIpv4CidrBlock != null)
          'clusterIpv4CidrBlock': clusterIpv4CidrBlock!,
        if (clusterSecondaryRangeName != null)
          'clusterSecondaryRangeName': clusterSecondaryRangeName!,
        if (servicesIpv4CidrBlock != null)
          'servicesIpv4CidrBlock': servicesIpv4CidrBlock!,
        if (servicesSecondaryRangeName != null)
          'servicesSecondaryRangeName': servicesSecondaryRangeName!,
        if (useIpAliases != null) 'useIpAliases': useIpAliases!,
      };
}

/// ImageVersion information
class ImageVersion {
  /// Whether it is impossible to create an environment with the image version.
  core.bool? creationDisabled;

  /// The string identifier of the ImageVersion, in the form:
  /// "composer-x.y.z-airflow-a.b(.c)"
  core.String? imageVersionId;

  /// Whether this is the default ImageVersion used by Composer during
  /// environment creation if no input ImageVersion is specified.
  core.bool? isDefault;

  /// The date of the version release.
  Date? releaseDate;

  /// supported python versions
  core.List<core.String>? supportedPythonVersions;

  /// Whether it is impossible to upgrade an environment running with the image
  /// version.
  core.bool? upgradeDisabled;

  ImageVersion();

  ImageVersion.fromJson(core.Map _json) {
    if (_json.containsKey('creationDisabled')) {
      creationDisabled = _json['creationDisabled'] as core.bool;
    }
    if (_json.containsKey('imageVersionId')) {
      imageVersionId = _json['imageVersionId'] as core.String;
    }
    if (_json.containsKey('isDefault')) {
      isDefault = _json['isDefault'] as core.bool;
    }
    if (_json.containsKey('releaseDate')) {
      releaseDate = Date.fromJson(
          _json['releaseDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('supportedPythonVersions')) {
      supportedPythonVersions = (_json['supportedPythonVersions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('upgradeDisabled')) {
      upgradeDisabled = _json['upgradeDisabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationDisabled != null) 'creationDisabled': creationDisabled!,
        if (imageVersionId != null) 'imageVersionId': imageVersionId!,
        if (isDefault != null) 'isDefault': isDefault!,
        if (releaseDate != null) 'releaseDate': releaseDate!.toJson(),
        if (supportedPythonVersions != null)
          'supportedPythonVersions': supportedPythonVersions!,
        if (upgradeDisabled != null) 'upgradeDisabled': upgradeDisabled!,
      };
}

/// The environments in a project and location.
class ListEnvironmentsResponse {
  /// The list of environments returned by a ListEnvironmentsRequest.
  core.List<Environment>? environments;

  /// The page token used to query for the next page if one exists.
  core.String? nextPageToken;

  ListEnvironmentsResponse();

  ListEnvironmentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('environments')) {
      environments = (_json['environments'] as core.List)
          .map<Environment>((value) => Environment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environments != null)
          'environments': environments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The ImageVersions in a project and location.
class ListImageVersionsResponse {
  /// The list of supported ImageVersions in a location.
  core.List<ImageVersion>? imageVersions;

  /// The page token used to query for the next page if one exists.
  core.String? nextPageToken;

  ListImageVersionsResponse();

  ListImageVersionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('imageVersions')) {
      imageVersions = (_json['imageVersions'] as core.List)
          .map<ImageVersion>((value) => ImageVersion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageVersions != null)
          'imageVersions':
              imageVersions!.map((value) => value.toJson()).toList(),
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

/// The configuration information for the Kubernetes Engine nodes running the
/// Apache Airflow software.
class NodeConfig {
  /// The disk size in GB used for node VMs.
  ///
  /// Minimum size is 20GB. If unspecified, defaults to 100GB. Cannot be
  /// updated.
  ///
  /// Optional.
  core.int? diskSizeGb;

  /// The configuration for controlling how IPs are allocated in the GKE
  /// cluster.
  ///
  /// Optional.
  IPAllocationPolicy? ipAllocationPolicy;

  /// The Compute Engine \[zone\](/compute/docs/regions-zones) in which to
  /// deploy the VMs used to run the Apache Airflow software, specified as a
  /// \[relative resource
  /// name\](/apis/design/resource_names#relative_resource_name).
  ///
  /// For example: "projects/{projectId}/zones/{zoneId}". This `location` must
  /// belong to the enclosing environment's project and location. If both this
  /// field and `nodeConfig.machineType` are specified, `nodeConfig.machineType`
  /// must belong to this `location`; if both are unspecified, the service will
  /// pick a zone in the Compute Engine region corresponding to the Cloud
  /// Composer location, and propagate that choice to both fields. If only one
  /// field (`location` or `nodeConfig.machineType`) is specified, the location
  /// information from the specified field will be propagated to the unspecified
  /// field.
  ///
  /// Optional.
  core.String? location;

  /// The Compute Engine \[machine type\](/compute/docs/machine-types) used for
  /// cluster instances, specified as a \[relative resource
  /// name\](/apis/design/resource_names#relative_resource_name).
  ///
  /// For example:
  /// "projects/{projectId}/zones/{zoneId}/machineTypes/{machineTypeId}". The
  /// `machineType` must belong to the enclosing environment's project and
  /// location. If both this field and `nodeConfig.location` are specified, this
  /// `machineType` must belong to the `nodeConfig.location`; if both are
  /// unspecified, the service will pick a zone in the Compute Engine region
  /// corresponding to the Cloud Composer location, and propagate that choice to
  /// both fields. If exactly one of this field and `nodeConfig.location` is
  /// specified, the location information from the specified field will be
  /// propagated to the unspecified field. The `machineTypeId` must not be a
  /// \[shared-core machine type\](/compute/docs/machine-types#sharedcore). If
  /// this field is unspecified, the `machineTypeId` defaults to
  /// "n1-standard-1".
  ///
  /// Optional.
  core.String? machineType;

  /// The Compute Engine network to be used for machine communications,
  /// specified as a \[relative resource
  /// name\](/apis/design/resource_names#relative_resource_name).
  ///
  /// For example: "projects/{projectId}/global/networks/{networkId}". If
  /// unspecified, the "default" network ID in the environment's project is
  /// used. If a \[Custom Subnet
  /// Network\](/vpc/docs/vpc#vpc_networks_and_subnets) is provided,
  /// `nodeConfig.subnetwork` must also be provided. For \[Shared
  /// VPC\](/vpc/docs/shared-vpc) subnetwork requirements, see
  /// `nodeConfig.subnetwork`.
  ///
  /// Optional.
  core.String? network;

  /// The set of Google API scopes to be made available on all node VMs.
  ///
  /// If `oauth_scopes` is empty, defaults to
  /// \["https://www.googleapis.com/auth/cloud-platform"\]. Cannot be updated.
  ///
  /// Optional.
  core.List<core.String>? oauthScopes;

  /// The Google Cloud Platform Service Account to be used by the node VMs.
  ///
  /// If a service account is not specified, the "default" Compute Engine
  /// service account is used. Cannot be updated.
  ///
  /// Optional.
  core.String? serviceAccount;

  /// The Compute Engine subnetwork to be used for machine communications,
  /// specified as a \[relative resource
  /// name\](/apis/design/resource_names#relative_resource_name).
  ///
  /// For example:
  /// "projects/{projectId}/regions/{regionId}/subnetworks/{subnetworkId}" If a
  /// subnetwork is provided, `nodeConfig.network` must also be provided, and
  /// the subnetwork must belong to the enclosing environment's project and
  /// location.
  ///
  /// Optional.
  core.String? subnetwork;

  /// The list of instance tags applied to all node VMs.
  ///
  /// Tags are used to identify valid sources or targets for network firewalls.
  /// Each tag within the list must comply with
  /// [RFC1035](https://www.ietf.org/rfc/rfc1035.txt). Cannot be updated.
  ///
  /// Optional.
  core.List<core.String>? tags;

  NodeConfig();

  NodeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('diskSizeGb')) {
      diskSizeGb = _json['diskSizeGb'] as core.int;
    }
    if (_json.containsKey('ipAllocationPolicy')) {
      ipAllocationPolicy = IPAllocationPolicy.fromJson(
          _json['ipAllocationPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('machineType')) {
      machineType = _json['machineType'] as core.String;
    }
    if (_json.containsKey('network')) {
      network = _json['network'] as core.String;
    }
    if (_json.containsKey('oauthScopes')) {
      oauthScopes = (_json['oauthScopes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('serviceAccount')) {
      serviceAccount = _json['serviceAccount'] as core.String;
    }
    if (_json.containsKey('subnetwork')) {
      subnetwork = _json['subnetwork'] as core.String;
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (diskSizeGb != null) 'diskSizeGb': diskSizeGb!,
        if (ipAllocationPolicy != null)
          'ipAllocationPolicy': ipAllocationPolicy!.toJson(),
        if (location != null) 'location': location!,
        if (machineType != null) 'machineType': machineType!,
        if (network != null) 'network': network!,
        if (oauthScopes != null) 'oauthScopes': oauthScopes!,
        if (serviceAccount != null) 'serviceAccount': serviceAccount!,
        if (subnetwork != null) 'subnetwork': subnetwork!,
        if (tags != null) 'tags': tags!,
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

/// Metadata describing an operation.
class OperationMetadata {
  /// The time the operation was submitted to the server.
  ///
  /// Output only.
  core.String? createTime;

  /// The time when the operation terminated, regardless of its success.
  ///
  /// This field is unset if the operation is still ongoing.
  ///
  /// Output only.
  core.String? endTime;

  /// The type of operation being performed.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Unused.
  /// - "CREATE" : A resource creation operation.
  /// - "DELETE" : A resource deletion operation.
  /// - "UPDATE" : A resource update operation.
  /// - "CHECK" : A resource check operation.
  core.String? operationType;

  /// The resource being operated on, as a \[relative resource name\](
  /// /apis/design/resource_names#relative_resource_name).
  ///
  /// Output only.
  core.String? resource;

  /// The UUID of the resource being operated on.
  ///
  /// Output only.
  core.String? resourceUuid;

  /// The current operation state.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unused.
  /// - "PENDING" : The operation has been created but is not yet started.
  /// - "RUNNING" : The operation is underway.
  /// - "SUCCEEDED" : The operation completed successfully.
  /// - "SUCCESSFUL"
  /// - "FAILED" : The operation is no longer running but did not succeed.
  core.String? state;

  OperationMetadata();

  OperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
    if (_json.containsKey('resourceUuid')) {
      resourceUuid = _json['resourceUuid'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (endTime != null) 'endTime': endTime!,
        if (operationType != null) 'operationType': operationType!,
        if (resource != null) 'resource': resource!,
        if (resourceUuid != null) 'resourceUuid': resourceUuid!,
        if (state != null) 'state': state!,
      };
}

/// Configuration options for the private GKE cluster in a Cloud Composer
/// environment.
class PrivateClusterConfig {
  /// If `true`, access to the public endpoint of the GKE cluster is denied.
  ///
  /// Optional.
  core.bool? enablePrivateEndpoint;

  /// The CIDR block from which IPv4 range for GKE master will be reserved.
  ///
  /// If left blank, the default value of '172.16.0.0/23' is used.
  ///
  /// Optional.
  core.String? masterIpv4CidrBlock;

  /// The IP range in CIDR notation to use for the hosted master network.
  ///
  /// This range is used for assigning internal IP addresses to the GKE cluster
  /// master or set of masters and to the internal load balancer virtual IP.
  /// This range must not overlap with any other ranges in use within the
  /// cluster's network.
  ///
  /// Output only.
  core.String? masterIpv4ReservedRange;

  PrivateClusterConfig();

  PrivateClusterConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enablePrivateEndpoint')) {
      enablePrivateEndpoint = _json['enablePrivateEndpoint'] as core.bool;
    }
    if (_json.containsKey('masterIpv4CidrBlock')) {
      masterIpv4CidrBlock = _json['masterIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('masterIpv4ReservedRange')) {
      masterIpv4ReservedRange = _json['masterIpv4ReservedRange'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enablePrivateEndpoint != null)
          'enablePrivateEndpoint': enablePrivateEndpoint!,
        if (masterIpv4CidrBlock != null)
          'masterIpv4CidrBlock': masterIpv4CidrBlock!,
        if (masterIpv4ReservedRange != null)
          'masterIpv4ReservedRange': masterIpv4ReservedRange!,
      };
}

/// The configuration information for configuring a Private IP Cloud Composer
/// environment.
class PrivateEnvironmentConfig {
  /// The CIDR block from which IP range in tenant project will be reserved for
  /// Cloud SQL.
  ///
  /// Needs to be disjoint from `web_server_ipv4_cidr_block`.
  ///
  /// Optional.
  core.String? cloudSqlIpv4CidrBlock;

  /// If `true`, a Private IP Cloud Composer environment is created.
  ///
  /// If this field is set to true, `IPAllocationPolicy.use_ip_aliases` must be
  /// set to true.
  ///
  /// Optional.
  core.bool? enablePrivateEnvironment;

  /// Configuration for the private GKE cluster for a Private IP Cloud Composer
  /// environment.
  ///
  /// Optional.
  PrivateClusterConfig? privateClusterConfig;

  /// The CIDR block from which IP range for web server will be reserved.
  ///
  /// Needs to be disjoint from `private_cluster_config.master_ipv4_cidr_block`
  /// and `cloud_sql_ipv4_cidr_block`.
  ///
  /// Optional.
  core.String? webServerIpv4CidrBlock;

  /// The IP range reserved for the tenant project's App Engine VMs.
  ///
  /// Output only.
  core.String? webServerIpv4ReservedRange;

  PrivateEnvironmentConfig();

  PrivateEnvironmentConfig.fromJson(core.Map _json) {
    if (_json.containsKey('cloudSqlIpv4CidrBlock')) {
      cloudSqlIpv4CidrBlock = _json['cloudSqlIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('enablePrivateEnvironment')) {
      enablePrivateEnvironment = _json['enablePrivateEnvironment'] as core.bool;
    }
    if (_json.containsKey('privateClusterConfig')) {
      privateClusterConfig = PrivateClusterConfig.fromJson(
          _json['privateClusterConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webServerIpv4CidrBlock')) {
      webServerIpv4CidrBlock = _json['webServerIpv4CidrBlock'] as core.String;
    }
    if (_json.containsKey('webServerIpv4ReservedRange')) {
      webServerIpv4ReservedRange =
          _json['webServerIpv4ReservedRange'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudSqlIpv4CidrBlock != null)
          'cloudSqlIpv4CidrBlock': cloudSqlIpv4CidrBlock!,
        if (enablePrivateEnvironment != null)
          'enablePrivateEnvironment': enablePrivateEnvironment!,
        if (privateClusterConfig != null)
          'privateClusterConfig': privateClusterConfig!.toJson(),
        if (webServerIpv4CidrBlock != null)
          'webServerIpv4CidrBlock': webServerIpv4CidrBlock!,
        if (webServerIpv4ReservedRange != null)
          'webServerIpv4ReservedRange': webServerIpv4ReservedRange!,
      };
}

/// Specifies the selection and configuration of software inside the
/// environment.
class SoftwareConfig {
  /// Apache Airflow configuration properties to override.
  ///
  /// Property keys contain the section and property names, separated by a
  /// hyphen, for example "core-dags_are_paused_at_creation". Section names must
  /// not contain hyphens ("-"), opening square brackets ("\["), or closing
  /// square brackets ("\]"). The property name must not be empty and must not
  /// contain an equals sign ("=") or semicolon (";"). Section and property
  /// names must not contain a period ("."). Apache Airflow configuration
  /// property names must be written in
  /// [snake_case](https://en.wikipedia.org/wiki/Snake_case). Property values
  /// can contain any character, and can be written in any lower/upper case
  /// format. Certain Apache Airflow configuration property values are
  /// \[blocked\](/composer/docs/concepts/airflow-configurations), and cannot be
  /// overridden.
  ///
  /// Optional.
  core.Map<core.String, core.String>? airflowConfigOverrides;

  /// Additional environment variables to provide to the Apache Airflow
  /// scheduler, worker, and webserver processes.
  ///
  /// Environment variable names must match the regular expression `a-zA-Z_*`.
  /// They cannot specify Apache Airflow software configuration overrides (they
  /// cannot match the regular expression `AIRFLOW__[A-Z0-9_]+__[A-Z0-9_]+`),
  /// and they cannot match any of the following reserved names: *
  /// `AIRFLOW_HOME` * `C_FORCE_ROOT` * `CONTAINER_NAME` * `DAGS_FOLDER` *
  /// `GCP_PROJECT` * `GCS_BUCKET` * `GKE_CLUSTER_NAME` * `SQL_DATABASE` *
  /// `SQL_INSTANCE` * `SQL_PASSWORD` * `SQL_PROJECT` * `SQL_REGION` *
  /// `SQL_USER`
  ///
  /// Optional.
  core.Map<core.String, core.String>? envVariables;

  /// The version of the software running in the environment.
  ///
  /// This encapsulates both the version of Cloud Composer functionality and the
  /// version of Apache Airflow. It must match the regular expression
  /// `composer-([0-9]+\.[0-9]+\.[0-9]+|latest)-airflow-[0-9]+\.[0-9]+(\.[0-9]+.*)?`.
  /// When used as input, the server also checks if the provided version is
  /// supported and denies the request for an unsupported version. The Cloud
  /// Composer portion of the version is a
  /// [semantic version](https://semver.org) or `latest`. When the patch version
  /// is omitted, the current Cloud Composer patch version is selected. When
  /// `latest` is provided instead of an explicit version number, the server
  /// replaces `latest` with the current Cloud Composer version and stores that
  /// version number in the same field. The portion of the image version that
  /// follows *airflow-* is an official Apache Airflow repository
  /// [release name](https://github.com/apache/incubator-airflow/releases). See
  /// also \[Version
  /// List\](/composer/docs/concepts/versioning/composer-versions).
  core.String? imageVersion;

  /// Custom Python Package Index (PyPI) packages to be installed in the
  /// environment.
  ///
  /// Keys refer to the lowercase package name such as "numpy" and values are
  /// the lowercase extras and version specifier such as "==1.12.0",
  /// "\[devel,gcp_api\]", or "\[devel\]>=1.8.2, <1.9.2". To specify a package
  /// without pinning it to a version specifier, use the empty string as the
  /// value.
  ///
  /// Optional.
  core.Map<core.String, core.String>? pypiPackages;

  /// The major version of Python used to run the Apache Airflow scheduler,
  /// worker, and webserver processes.
  ///
  /// Can be set to '2' or '3'. If not specified, the default is '3'. Cannot be
  /// updated.
  ///
  /// Optional.
  core.String? pythonVersion;

  SoftwareConfig();

  SoftwareConfig.fromJson(core.Map _json) {
    if (_json.containsKey('airflowConfigOverrides')) {
      airflowConfigOverrides = (_json['airflowConfigOverrides']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('envVariables')) {
      envVariables =
          (_json['envVariables'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('imageVersion')) {
      imageVersion = _json['imageVersion'] as core.String;
    }
    if (_json.containsKey('pypiPackages')) {
      pypiPackages =
          (_json['pypiPackages'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('pythonVersion')) {
      pythonVersion = _json['pythonVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (airflowConfigOverrides != null)
          'airflowConfigOverrides': airflowConfigOverrides!,
        if (envVariables != null) 'envVariables': envVariables!,
        if (imageVersion != null) 'imageVersion': imageVersion!,
        if (pypiPackages != null) 'pypiPackages': pypiPackages!,
        if (pythonVersion != null) 'pythonVersion': pythonVersion!,
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

/// The configuration settings for the Airflow web server App Engine instance.
class WebServerConfig {
  /// Machine type on which Airflow web server is running.
  ///
  /// It has to be one of: composer-n1-webserver-2, composer-n1-webserver-4 or
  /// composer-n1-webserver-8. If not specified, composer-n1-webserver-2 will be
  /// used. Value custom is returned only in response, if Airflow web server
  /// parameters were manually changed to a non-standard values.
  ///
  /// Optional.
  core.String? machineType;

  WebServerConfig();

  WebServerConfig.fromJson(core.Map _json) {
    if (_json.containsKey('machineType')) {
      machineType = _json['machineType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (machineType != null) 'machineType': machineType!,
      };
}

/// Network-level access control policy for the Airflow web server.
class WebServerNetworkAccessControl {
  /// A collection of allowed IP ranges with descriptions.
  core.List<AllowedIpRange>? allowedIpRanges;

  WebServerNetworkAccessControl();

  WebServerNetworkAccessControl.fromJson(core.Map _json) {
    if (_json.containsKey('allowedIpRanges')) {
      allowedIpRanges = (_json['allowedIpRanges'] as core.List)
          .map<AllowedIpRange>((value) => AllowedIpRange.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedIpRanges != null)
          'allowedIpRanges':
              allowedIpRanges!.map((value) => value.toJson()).toList(),
      };
}

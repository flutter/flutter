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

/// BigQuery Data Transfer API - v1
///
/// Schedule queries or transfer external data from SaaS applications to Google
/// BigQuery on a regular basis.
///
/// For more information, see <https://cloud.google.com/bigquery-transfer/>
///
/// Create an instance of [BigQueryDataTransferApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsDataSourcesResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsDataSourcesResource]
///     - [ProjectsLocationsTransferConfigsResource]
///       - [ProjectsLocationsTransferConfigsRunsResource]
///         - [ProjectsLocationsTransferConfigsRunsTransferLogsResource]
///   - [ProjectsTransferConfigsResource]
///     - [ProjectsTransferConfigsRunsResource]
///       - [ProjectsTransferConfigsRunsTransferLogsResource]
library bigquerydatatransfer.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Schedule queries or transfer external data from SaaS applications to Google
/// BigQuery on a regular basis.
class BigQueryDataTransferApi {
  /// View and manage your data in Google BigQuery
  static const bigqueryScope = 'https://www.googleapis.com/auth/bigquery';

  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View your data across Google Cloud Platform services
  static const cloudPlatformReadOnlyScope =
      'https://www.googleapis.com/auth/cloud-platform.read-only';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  BigQueryDataTransferApi(http.Client client,
      {core.String rootUrl = 'https://bigquerydatatransfer.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsDataSourcesResource get dataSources =>
      ProjectsDataSourcesResource(_requester);
  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);
  ProjectsTransferConfigsResource get transferConfigs =>
      ProjectsTransferConfigsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsDataSourcesResource {
  final commons.ApiRequester _requester;

  ProjectsDataSourcesResource(commons.ApiRequester client)
      : _requester = client;

  /// Returns true if valid credentials exist for the given data source and
  /// requesting user.
  ///
  /// Some data sources doesn't support service account, so we need to talk to
  /// them on behalf of the end user. This API just checks whether we have OAuth
  /// token for the particular user, which is a pre-requisite before user can
  /// create a transfer config.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The data source in the form:
  /// `projects/{project_id}/dataSources/{data_source_id}` or
  /// `projects/{project_id}/locations/{location_id}/dataSources/{data_source_id}`.
  /// Value must have pattern `^projects/\[^/\]+/dataSources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CheckValidCredsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CheckValidCredsResponse> checkValidCreds(
    CheckValidCredsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':checkValidCreds';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CheckValidCredsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a supported data source and returns its settings, which can be
  /// used for UI rendering.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example: `projects/{project_id}/dataSources/{data_source_id}` or
  /// `projects/{project_id}/locations/{location_id}/dataSources/{data_source_id}`
  /// Value must have pattern `^projects/\[^/\]+/dataSources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataSource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataSource> get(
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
    return DataSource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists supported data sources and returns their settings, which can be used
  /// for UI rendering.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The BigQuery project id for which data sources should
  /// be returned. Must be in the form: \`projects/{project_id}\` or
  /// \`projects/{project_id}/locations/{location_id}
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListDataSourcesRequest` list results. For multiple-page results,
  /// `ListDataSourcesResponse` outputs a `next_page` token, which can be used
  /// as the `page_token` value to request the next page of list results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDataSourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDataSourcesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/dataSources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDataSourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsDataSourcesResource get dataSources =>
      ProjectsLocationsDataSourcesResource(_requester);
  ProjectsLocationsTransferConfigsResource get transferConfigs =>
      ProjectsLocationsTransferConfigsResource(_requester);

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

class ProjectsLocationsDataSourcesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsDataSourcesResource(commons.ApiRequester client)
      : _requester = client;

  /// Returns true if valid credentials exist for the given data source and
  /// requesting user.
  ///
  /// Some data sources doesn't support service account, so we need to talk to
  /// them on behalf of the end user. This API just checks whether we have OAuth
  /// token for the particular user, which is a pre-requisite before user can
  /// create a transfer config.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The data source in the form:
  /// `projects/{project_id}/dataSources/{data_source_id}` or
  /// `projects/{project_id}/locations/{location_id}/dataSources/{data_source_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/dataSources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CheckValidCredsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CheckValidCredsResponse> checkValidCreds(
    CheckValidCredsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':checkValidCreds';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CheckValidCredsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a supported data source and returns its settings, which can be
  /// used for UI rendering.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example: `projects/{project_id}/dataSources/{data_source_id}` or
  /// `projects/{project_id}/locations/{location_id}/dataSources/{data_source_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/dataSources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataSource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataSource> get(
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
    return DataSource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists supported data sources and returns their settings, which can be used
  /// for UI rendering.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The BigQuery project id for which data sources should
  /// be returned. Must be in the form: \`projects/{project_id}\` or
  /// \`projects/{project_id}/locations/{location_id}
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListDataSourcesRequest` list results. For multiple-page results,
  /// `ListDataSourcesResponse` outputs a `next_page` token, which can be used
  /// as the `page_token` value to request the next page of list results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDataSourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDataSourcesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/dataSources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDataSourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsTransferConfigsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsTransferConfigsRunsResource get runs =>
      ProjectsLocationsTransferConfigsRunsResource(_requester);

  ProjectsLocationsTransferConfigsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new data transfer configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The BigQuery project id where the transfer
  /// configuration should be created. Must be in the format
  /// projects/{project_id}/locations/{location_id} or projects/{project_id}. If
  /// specified location and location of the destination bigquery dataset do not
  /// match - the request will fail.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [authorizationCode] - Optional OAuth2 authorization code to use with this
  /// transfer configuration. This is required if new credentials are needed, as
  /// indicated by `CheckValidCreds`. In order to obtain authorization_code,
  /// please make a request to
  /// https://www.gstatic.com/bigquerydatatransfer/oauthz/auth?client_id=&scope=&redirect_uri=
  /// * client_id should be OAuth client_id of BigQuery DTS API for the given
  /// data source returned by ListDataSources method. * data_source_scopes are
  /// the scopes returned by ListDataSources method. * redirect_uri is an
  /// optional parameter. If not specified, then authorization code is posted to
  /// the opener of authorization flow window. Otherwise it will be sent to the
  /// redirect uri. A special value of urn:ietf:wg:oauth:2.0:oob means that
  /// authorization code should be returned in the title bar of the browser,
  /// with the page text prompting the user to copy the code and paste it in the
  /// application.
  ///
  /// [serviceAccountName] - Optional service account name. If this field is
  /// set, transfer config will be created with this service account
  /// credentials. It requires that requesting user calling this API has
  /// permissions to act as this service account.
  ///
  /// [versionInfo] - Optional version info. If users want to find a very recent
  /// access token, that is, immediately after approving access, users have to
  /// set the version_info claim in the token request. To obtain the
  /// version_info, users must use the "none+gsession" response type. which be
  /// return a version_info back in the authorization response which be be put
  /// in a JWT claim in the token request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferConfig> create(
    TransferConfig request,
    core.String parent, {
    core.String? authorizationCode,
    core.String? serviceAccountName,
    core.String? versionInfo,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (authorizationCode != null) 'authorizationCode': [authorizationCode],
      if (serviceAccountName != null)
        'serviceAccountName': [serviceAccountName],
      if (versionInfo != null) 'versionInfo': [versionInfo],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/transferConfigs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TransferConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a data transfer configuration, including any associated transfer
  /// runs and logs.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example: `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+$`.
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

  /// Returns information about a data transfer config.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example: `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferConfig> get(
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
    return TransferConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns information about all data transfers in the project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The BigQuery project id for which data sources should
  /// be returned: `projects/{project_id}` or
  /// `projects/{project_id}/locations/{location_id}`
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [dataSourceIds] - When specified, only configurations of requested data
  /// sources are returned.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListTransfersRequest` list results. For multiple-page results,
  /// `ListTransfersResponse` outputs a `next_page` token, which can be used as
  /// the `page_token` value to request the next page of list results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTransferConfigsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTransferConfigsResponse> list(
    core.String parent, {
    core.List<core.String>? dataSourceIds,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (dataSourceIds != null) 'dataSourceIds': dataSourceIds,
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/transferConfigs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTransferConfigsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a data transfer configuration.
  ///
  /// All fields must be set, even if they are not updated.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the transfer config. Transfer config names
  /// have the form
  /// `projects/{project_id}/locations/{region}/transferConfigs/{config_id}`.
  /// Where `config_id` is usually a uuid, even though it is not guaranteed or
  /// required. The name is ignored when creating a transfer config.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [authorizationCode] - Optional OAuth2 authorization code to use with this
  /// transfer configuration. If it is provided, the transfer configuration will
  /// be associated with the authorizing user. In order to obtain
  /// authorization_code, please make a request to
  /// https://www.gstatic.com/bigquerydatatransfer/oauthz/auth?client_id=&scope=&redirect_uri=
  /// * client_id should be OAuth client_id of BigQuery DTS API for the given
  /// data source returned by ListDataSources method. * data_source_scopes are
  /// the scopes returned by ListDataSources method. * redirect_uri is an
  /// optional parameter. If not specified, then authorization code is posted to
  /// the opener of authorization flow window. Otherwise it will be sent to the
  /// redirect uri. A special value of urn:ietf:wg:oauth:2.0:oob means that
  /// authorization code should be returned in the title bar of the browser,
  /// with the page text prompting the user to copy the code and paste it in the
  /// application.
  ///
  /// [serviceAccountName] - Optional service account name. If this field is set
  /// and "service_account_name" is set in update_mask, transfer config will be
  /// updated to use this service account credentials. It requires that
  /// requesting user calling this API has permissions to act as this service
  /// account.
  ///
  /// [updateMask] - Required. Required list of fields to be updated in this
  /// request.
  ///
  /// [versionInfo] - Optional version info. If users want to find a very recent
  /// access token, that is, immediately after approving access, users have to
  /// set the version_info claim in the token request. To obtain the
  /// version_info, users must use the "none+gsession" response type. which be
  /// return a version_info back in the authorization response which be be put
  /// in a JWT claim in the token request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferConfig> patch(
    TransferConfig request,
    core.String name, {
    core.String? authorizationCode,
    core.String? serviceAccountName,
    core.String? updateMask,
    core.String? versionInfo,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (authorizationCode != null) 'authorizationCode': [authorizationCode],
      if (serviceAccountName != null)
        'serviceAccountName': [serviceAccountName],
      if (updateMask != null) 'updateMask': [updateMask],
      if (versionInfo != null) 'versionInfo': [versionInfo],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return TransferConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates transfer runs for a time range \[start_time, end_time\].
  ///
  /// For each date - or whatever granularity the data source supports - in the
  /// range, one transfer run is created. Note that runs are created per UTC
  /// time in the time range. DEPRECATED: use StartManualTransferRuns instead.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Transfer configuration name in the form:
  /// `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ScheduleTransferRunsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ScheduleTransferRunsResponse> scheduleRuns(
    ScheduleTransferRunsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':scheduleRuns';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ScheduleTransferRunsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Start manual transfer runs to be executed now with schedule_time equal to
  /// current time.
  ///
  /// The transfer runs can be created for a time range where the run_time is
  /// between start_time (inclusive) and end_time (exclusive), or for a specific
  /// run_time.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Transfer configuration name in the form:
  /// `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StartManualTransferRunsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StartManualTransferRunsResponse> startManualRuns(
    StartManualTransferRunsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':startManualRuns';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return StartManualTransferRunsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsTransferConfigsRunsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsTransferConfigsRunsTransferLogsResource get transferLogs =>
      ProjectsLocationsTransferConfigsRunsTransferLogsResource(_requester);

  ProjectsLocationsTransferConfigsRunsResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes the specified transfer run.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example:
  /// `projects/{project_id}/transferConfigs/{config_id}/runs/{run_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}/runs/{run_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+/runs/\[^/\]+$`.
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

  /// Returns information about the particular transfer run.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example:
  /// `projects/{project_id}/transferConfigs/{config_id}/runs/{run_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}/runs/{run_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+/runs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferRun].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferRun> get(
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
    return TransferRun.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns information about running and completed jobs.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of transfer configuration for which transfer
  /// runs should be retrieved. Format of transfer configuration resource name
  /// is: `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListTransferRunsRequest` list results. For multiple-page results,
  /// `ListTransferRunsResponse` outputs a `next_page` token, which can be used
  /// as the `page_token` value to request the next page of list results.
  ///
  /// [runAttempt] - Indicates how run attempts are to be pulled.
  /// Possible string values are:
  /// - "RUN_ATTEMPT_UNSPECIFIED" : All runs should be returned.
  /// - "LATEST" : Only latest run per day should be returned.
  ///
  /// [states] - When specified, only transfer runs with requested states are
  /// returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTransferRunsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTransferRunsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? runAttempt,
    core.List<core.String>? states,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (runAttempt != null) 'runAttempt': [runAttempt],
      if (states != null) 'states': states,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/runs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTransferRunsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsTransferConfigsRunsTransferLogsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsTransferConfigsRunsTransferLogsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Returns user facing log messages for the data transfer run.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Transfer run name in the form:
  /// `projects/{project_id}/transferConfigs/{config_id}/runs/{run_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}/runs/{run_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/transferConfigs/\[^/\]+/runs/\[^/\]+$`.
  ///
  /// [messageTypes] - Message types to return. If not populated - INFO, WARNING
  /// and ERROR messages are returned.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListTransferLogsRequest` list results. For multiple-page results,
  /// `ListTransferLogsResponse` outputs a `next_page` token, which can be used
  /// as the `page_token` value to request the next page of list results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTransferLogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTransferLogsResponse> list(
    core.String parent, {
    core.List<core.String>? messageTypes,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (messageTypes != null) 'messageTypes': messageTypes,
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/transferLogs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTransferLogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsTransferConfigsResource {
  final commons.ApiRequester _requester;

  ProjectsTransferConfigsRunsResource get runs =>
      ProjectsTransferConfigsRunsResource(_requester);

  ProjectsTransferConfigsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new data transfer configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The BigQuery project id where the transfer
  /// configuration should be created. Must be in the format
  /// projects/{project_id}/locations/{location_id} or projects/{project_id}. If
  /// specified location and location of the destination bigquery dataset do not
  /// match - the request will fail.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [authorizationCode] - Optional OAuth2 authorization code to use with this
  /// transfer configuration. This is required if new credentials are needed, as
  /// indicated by `CheckValidCreds`. In order to obtain authorization_code,
  /// please make a request to
  /// https://www.gstatic.com/bigquerydatatransfer/oauthz/auth?client_id=&scope=&redirect_uri=
  /// * client_id should be OAuth client_id of BigQuery DTS API for the given
  /// data source returned by ListDataSources method. * data_source_scopes are
  /// the scopes returned by ListDataSources method. * redirect_uri is an
  /// optional parameter. If not specified, then authorization code is posted to
  /// the opener of authorization flow window. Otherwise it will be sent to the
  /// redirect uri. A special value of urn:ietf:wg:oauth:2.0:oob means that
  /// authorization code should be returned in the title bar of the browser,
  /// with the page text prompting the user to copy the code and paste it in the
  /// application.
  ///
  /// [serviceAccountName] - Optional service account name. If this field is
  /// set, transfer config will be created with this service account
  /// credentials. It requires that requesting user calling this API has
  /// permissions to act as this service account.
  ///
  /// [versionInfo] - Optional version info. If users want to find a very recent
  /// access token, that is, immediately after approving access, users have to
  /// set the version_info claim in the token request. To obtain the
  /// version_info, users must use the "none+gsession" response type. which be
  /// return a version_info back in the authorization response which be be put
  /// in a JWT claim in the token request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferConfig> create(
    TransferConfig request,
    core.String parent, {
    core.String? authorizationCode,
    core.String? serviceAccountName,
    core.String? versionInfo,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (authorizationCode != null) 'authorizationCode': [authorizationCode],
      if (serviceAccountName != null)
        'serviceAccountName': [serviceAccountName],
      if (versionInfo != null) 'versionInfo': [versionInfo],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/transferConfigs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TransferConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a data transfer configuration, including any associated transfer
  /// runs and logs.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example: `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`
  /// Value must have pattern `^projects/\[^/\]+/transferConfigs/\[^/\]+$`.
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

  /// Returns information about a data transfer config.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example: `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`
  /// Value must have pattern `^projects/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferConfig> get(
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
    return TransferConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns information about all data transfers in the project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The BigQuery project id for which data sources should
  /// be returned: `projects/{project_id}` or
  /// `projects/{project_id}/locations/{location_id}`
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [dataSourceIds] - When specified, only configurations of requested data
  /// sources are returned.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListTransfersRequest` list results. For multiple-page results,
  /// `ListTransfersResponse` outputs a `next_page` token, which can be used as
  /// the `page_token` value to request the next page of list results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTransferConfigsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTransferConfigsResponse> list(
    core.String parent, {
    core.List<core.String>? dataSourceIds,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (dataSourceIds != null) 'dataSourceIds': dataSourceIds,
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/transferConfigs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTransferConfigsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a data transfer configuration.
  ///
  /// All fields must be set, even if they are not updated.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the transfer config. Transfer config names
  /// have the form
  /// `projects/{project_id}/locations/{region}/transferConfigs/{config_id}`.
  /// Where `config_id` is usually a uuid, even though it is not guaranteed or
  /// required. The name is ignored when creating a transfer config.
  /// Value must have pattern `^projects/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [authorizationCode] - Optional OAuth2 authorization code to use with this
  /// transfer configuration. If it is provided, the transfer configuration will
  /// be associated with the authorizing user. In order to obtain
  /// authorization_code, please make a request to
  /// https://www.gstatic.com/bigquerydatatransfer/oauthz/auth?client_id=&scope=&redirect_uri=
  /// * client_id should be OAuth client_id of BigQuery DTS API for the given
  /// data source returned by ListDataSources method. * data_source_scopes are
  /// the scopes returned by ListDataSources method. * redirect_uri is an
  /// optional parameter. If not specified, then authorization code is posted to
  /// the opener of authorization flow window. Otherwise it will be sent to the
  /// redirect uri. A special value of urn:ietf:wg:oauth:2.0:oob means that
  /// authorization code should be returned in the title bar of the browser,
  /// with the page text prompting the user to copy the code and paste it in the
  /// application.
  ///
  /// [serviceAccountName] - Optional service account name. If this field is set
  /// and "service_account_name" is set in update_mask, transfer config will be
  /// updated to use this service account credentials. It requires that
  /// requesting user calling this API has permissions to act as this service
  /// account.
  ///
  /// [updateMask] - Required. Required list of fields to be updated in this
  /// request.
  ///
  /// [versionInfo] - Optional version info. If users want to find a very recent
  /// access token, that is, immediately after approving access, users have to
  /// set the version_info claim in the token request. To obtain the
  /// version_info, users must use the "none+gsession" response type. which be
  /// return a version_info back in the authorization response which be be put
  /// in a JWT claim in the token request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferConfig> patch(
    TransferConfig request,
    core.String name, {
    core.String? authorizationCode,
    core.String? serviceAccountName,
    core.String? updateMask,
    core.String? versionInfo,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (authorizationCode != null) 'authorizationCode': [authorizationCode],
      if (serviceAccountName != null)
        'serviceAccountName': [serviceAccountName],
      if (updateMask != null) 'updateMask': [updateMask],
      if (versionInfo != null) 'versionInfo': [versionInfo],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return TransferConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates transfer runs for a time range \[start_time, end_time\].
  ///
  /// For each date - or whatever granularity the data source supports - in the
  /// range, one transfer run is created. Note that runs are created per UTC
  /// time in the time range. DEPRECATED: use StartManualTransferRuns instead.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Transfer configuration name in the form:
  /// `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`.
  /// Value must have pattern `^projects/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ScheduleTransferRunsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ScheduleTransferRunsResponse> scheduleRuns(
    ScheduleTransferRunsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':scheduleRuns';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ScheduleTransferRunsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Start manual transfer runs to be executed now with schedule_time equal to
  /// current time.
  ///
  /// The transfer runs can be created for a time range where the run_time is
  /// between start_time (inclusive) and end_time (exclusive), or for a specific
  /// run_time.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Transfer configuration name in the form:
  /// `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`.
  /// Value must have pattern `^projects/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StartManualTransferRunsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StartManualTransferRunsResponse> startManualRuns(
    StartManualTransferRunsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':startManualRuns';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return StartManualTransferRunsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsTransferConfigsRunsResource {
  final commons.ApiRequester _requester;

  ProjectsTransferConfigsRunsTransferLogsResource get transferLogs =>
      ProjectsTransferConfigsRunsTransferLogsResource(_requester);

  ProjectsTransferConfigsRunsResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes the specified transfer run.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example:
  /// `projects/{project_id}/transferConfigs/{config_id}/runs/{run_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}/runs/{run_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/transferConfigs/\[^/\]+/runs/\[^/\]+$`.
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

  /// Returns information about the particular transfer run.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The field will contain name of the resource requested,
  /// for example:
  /// `projects/{project_id}/transferConfigs/{config_id}/runs/{run_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}/runs/{run_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/transferConfigs/\[^/\]+/runs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TransferRun].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TransferRun> get(
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
    return TransferRun.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns information about running and completed jobs.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of transfer configuration for which transfer
  /// runs should be retrieved. Format of transfer configuration resource name
  /// is: `projects/{project_id}/transferConfigs/{config_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`.
  /// Value must have pattern `^projects/\[^/\]+/transferConfigs/\[^/\]+$`.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListTransferRunsRequest` list results. For multiple-page results,
  /// `ListTransferRunsResponse` outputs a `next_page` token, which can be used
  /// as the `page_token` value to request the next page of list results.
  ///
  /// [runAttempt] - Indicates how run attempts are to be pulled.
  /// Possible string values are:
  /// - "RUN_ATTEMPT_UNSPECIFIED" : All runs should be returned.
  /// - "LATEST" : Only latest run per day should be returned.
  ///
  /// [states] - When specified, only transfer runs with requested states are
  /// returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTransferRunsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTransferRunsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? runAttempt,
    core.List<core.String>? states,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (runAttempt != null) 'runAttempt': [runAttempt],
      if (states != null) 'states': states,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/runs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTransferRunsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsTransferConfigsRunsTransferLogsResource {
  final commons.ApiRequester _requester;

  ProjectsTransferConfigsRunsTransferLogsResource(commons.ApiRequester client)
      : _requester = client;

  /// Returns user facing log messages for the data transfer run.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Transfer run name in the form:
  /// `projects/{project_id}/transferConfigs/{config_id}/runs/{run_id}` or
  /// `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}/runs/{run_id}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/transferConfigs/\[^/\]+/runs/\[^/\]+$`.
  ///
  /// [messageTypes] - Message types to return. If not populated - INFO, WARNING
  /// and ERROR messages are returned.
  ///
  /// [pageSize] - Page size. The default page size is the maximum value of 1000
  /// results.
  ///
  /// [pageToken] - Pagination token, which can be used to request a specific
  /// page of `ListTransferLogsRequest` list results. For multiple-page results,
  /// `ListTransferLogsResponse` outputs a `next_page` token, which can be used
  /// as the `page_token` value to request the next page of list results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTransferLogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTransferLogsResponse> list(
    core.String parent, {
    core.List<core.String>? messageTypes,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (messageTypes != null) 'messageTypes': messageTypes,
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/transferLogs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTransferLogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// A request to determine whether the user has valid credentials.
///
/// This method is used to limit the number of OAuth popups in the user
/// interface. The user id is inferred from the API call context. If the data
/// source has the Google+ authorization type, this method returns false, as it
/// cannot be determined whether the credentials are already valid merely based
/// on the user id.
class CheckValidCredsRequest {
  CheckValidCredsRequest();

  CheckValidCredsRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A response indicating whether the credentials exist and are valid.
class CheckValidCredsResponse {
  /// If set to `true`, the credentials exist and are valid.
  core.bool? hasValidCreds;

  CheckValidCredsResponse();

  CheckValidCredsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('hasValidCreds')) {
      hasValidCreds = _json['hasValidCreds'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hasValidCreds != null) 'hasValidCreds': hasValidCreds!,
      };
}

/// Represents data source metadata.
///
/// Metadata is sufficient to render UI and request proper OAuth tokens.
class DataSource {
  /// Indicates the type of authorization.
  /// Possible string values are:
  /// - "AUTHORIZATION_TYPE_UNSPECIFIED" : Type unspecified.
  /// - "AUTHORIZATION_CODE" : Use OAuth 2 authorization codes that can be
  /// exchanged for a refresh token on the backend.
  /// - "GOOGLE_PLUS_AUTHORIZATION_CODE" : Return an authorization code for a
  /// given Google+ page that can then be exchanged for a refresh token on the
  /// backend.
  /// - "FIRST_PARTY_OAUTH" : Use First Party OAuth based on Loas Owned Clients.
  /// First Party OAuth doesn't require a refresh token to get an offline access
  /// token. Instead, it uses a client-signed JWT assertion to retrieve an
  /// access token.
  core.String? authorizationType;

  /// Data source client id which should be used to receive refresh token.
  core.String? clientId;

  /// Specifies whether the data source supports automatic data refresh for the
  /// past few days, and how it's supported.
  ///
  /// For some data sources, data might not be complete until a few days later,
  /// so it's useful to refresh data automatically.
  /// Possible string values are:
  /// - "DATA_REFRESH_TYPE_UNSPECIFIED" : The data source won't support data
  /// auto refresh, which is default value.
  /// - "SLIDING_WINDOW" : The data source supports data auto refresh, and runs
  /// will be scheduled for the past few days. Does not allow custom values to
  /// be set for each transfer config.
  /// - "CUSTOM_SLIDING_WINDOW" : The data source supports data auto refresh,
  /// and runs will be scheduled for the past few days. Allows custom values to
  /// be set for each transfer config.
  core.String? dataRefreshType;

  /// Data source id.
  core.String? dataSourceId;

  /// Default data refresh window on days.
  ///
  /// Only meaningful when `data_refresh_type` = `SLIDING_WINDOW`.
  core.int? defaultDataRefreshWindowDays;

  /// Default data transfer schedule.
  ///
  /// Examples of valid schedules include: `1st,3rd monday of month 15:30`,
  /// `every wed,fri of jan,jun 13:15`, and `first sunday of quarter 00:00`.
  core.String? defaultSchedule;

  /// User friendly data source description string.
  core.String? description;

  /// User friendly data source name.
  core.String? displayName;

  /// Url for the help document for this data source.
  core.String? helpUrl;

  /// Disables backfilling and manual run scheduling for the data source.
  core.bool? manualRunsDisabled;

  /// The minimum interval for scheduler to schedule runs.
  core.String? minimumScheduleInterval;

  /// Data source resource name.
  ///
  /// Output only.
  core.String? name;

  /// Data source parameters.
  core.List<DataSourceParameter>? parameters;

  /// Api auth scopes for which refresh token needs to be obtained.
  ///
  /// These are scopes needed by a data source to prepare data and ingest them
  /// into BigQuery, e.g., https://www.googleapis.com/auth/bigquery
  core.List<core.String>? scopes;

  /// Specifies whether the data source supports a user defined schedule, or
  /// operates on the default schedule.
  ///
  /// When set to `true`, user can override default schedule.
  core.bool? supportsCustomSchedule;

  /// This field has no effect.
  ///
  /// Deprecated.
  core.bool? supportsMultipleTransfers;

  /// This field has no effect.
  ///
  /// Deprecated.
  /// Possible string values are:
  /// - "TRANSFER_TYPE_UNSPECIFIED" : Invalid or Unknown transfer type
  /// placeholder.
  /// - "BATCH" : Batch data transfer.
  /// - "STREAMING" : Streaming data transfer. Streaming data source currently
  /// doesn't support multiple transfer configs per project.
  core.String? transferType;

  /// The number of seconds to wait for an update from the data source before
  /// the Data Transfer Service marks the transfer as FAILED.
  core.int? updateDeadlineSeconds;

  DataSource();

  DataSource.fromJson(core.Map _json) {
    if (_json.containsKey('authorizationType')) {
      authorizationType = _json['authorizationType'] as core.String;
    }
    if (_json.containsKey('clientId')) {
      clientId = _json['clientId'] as core.String;
    }
    if (_json.containsKey('dataRefreshType')) {
      dataRefreshType = _json['dataRefreshType'] as core.String;
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('defaultDataRefreshWindowDays')) {
      defaultDataRefreshWindowDays =
          _json['defaultDataRefreshWindowDays'] as core.int;
    }
    if (_json.containsKey('defaultSchedule')) {
      defaultSchedule = _json['defaultSchedule'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('helpUrl')) {
      helpUrl = _json['helpUrl'] as core.String;
    }
    if (_json.containsKey('manualRunsDisabled')) {
      manualRunsDisabled = _json['manualRunsDisabled'] as core.bool;
    }
    if (_json.containsKey('minimumScheduleInterval')) {
      minimumScheduleInterval = _json['minimumScheduleInterval'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<DataSourceParameter>((value) => DataSourceParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('scopes')) {
      scopes = (_json['scopes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('supportsCustomSchedule')) {
      supportsCustomSchedule = _json['supportsCustomSchedule'] as core.bool;
    }
    if (_json.containsKey('supportsMultipleTransfers')) {
      supportsMultipleTransfers =
          _json['supportsMultipleTransfers'] as core.bool;
    }
    if (_json.containsKey('transferType')) {
      transferType = _json['transferType'] as core.String;
    }
    if (_json.containsKey('updateDeadlineSeconds')) {
      updateDeadlineSeconds = _json['updateDeadlineSeconds'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authorizationType != null) 'authorizationType': authorizationType!,
        if (clientId != null) 'clientId': clientId!,
        if (dataRefreshType != null) 'dataRefreshType': dataRefreshType!,
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (defaultDataRefreshWindowDays != null)
          'defaultDataRefreshWindowDays': defaultDataRefreshWindowDays!,
        if (defaultSchedule != null) 'defaultSchedule': defaultSchedule!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (helpUrl != null) 'helpUrl': helpUrl!,
        if (manualRunsDisabled != null)
          'manualRunsDisabled': manualRunsDisabled!,
        if (minimumScheduleInterval != null)
          'minimumScheduleInterval': minimumScheduleInterval!,
        if (name != null) 'name': name!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (scopes != null) 'scopes': scopes!,
        if (supportsCustomSchedule != null)
          'supportsCustomSchedule': supportsCustomSchedule!,
        if (supportsMultipleTransfers != null)
          'supportsMultipleTransfers': supportsMultipleTransfers!,
        if (transferType != null) 'transferType': transferType!,
        if (updateDeadlineSeconds != null)
          'updateDeadlineSeconds': updateDeadlineSeconds!,
      };
}

/// Represents a data source parameter with validation rules, so that parameters
/// can be rendered in the UI.
///
/// These parameters are given to us by supported data sources, and include all
/// needed information for rendering and validation. Thus, whoever uses this api
/// can decide to generate either generic ui, or custom data source specific
/// forms.
class DataSourceParameter {
  /// All possible values for the parameter.
  core.List<core.String>? allowedValues;

  /// If true, it should not be used in new transfers, and it should not be
  /// visible to users.
  core.bool? deprecated;

  /// Parameter description.
  core.String? description;

  /// Parameter display name in the user interface.
  core.String? displayName;

  /// This field has no effect.
  ///
  /// Deprecated.
  core.List<DataSourceParameter>? fields;

  /// Cannot be changed after initial creation.
  core.bool? immutable;

  /// For integer and double values specifies maxminum allowed value.
  core.double? maxValue;

  /// For integer and double values specifies minimum allowed value.
  core.double? minValue;

  /// Parameter identifier.
  core.String? paramId;

  /// This field has no effect.
  ///
  /// Deprecated.
  core.bool? recurse;

  /// This field has no effect.
  ///
  /// Deprecated.
  core.bool? repeated;

  /// Is parameter required.
  core.bool? required;

  /// Parameter type.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Type unspecified.
  /// - "STRING" : String parameter.
  /// - "INTEGER" : Integer parameter (64-bits). Will be serialized to json as
  /// string.
  /// - "DOUBLE" : Double precision floating point parameter.
  /// - "BOOLEAN" : Boolean parameter.
  /// - "RECORD" : Deprecated. This field has no effect.
  /// - "PLUS_PAGE" : Page ID for a Google+ Page.
  core.String? type;

  /// Description of the requirements for this field, in case the user input
  /// does not fulfill the regex pattern or min/max values.
  core.String? validationDescription;

  /// URL to a help document to further explain the naming requirements.
  core.String? validationHelpUrl;

  /// Regular expression which can be used for parameter validation.
  core.String? validationRegex;

  DataSourceParameter();

  DataSourceParameter.fromJson(core.Map _json) {
    if (_json.containsKey('allowedValues')) {
      allowedValues = (_json['allowedValues'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('deprecated')) {
      deprecated = _json['deprecated'] as core.bool;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<DataSourceParameter>((value) => DataSourceParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('immutable')) {
      immutable = _json['immutable'] as core.bool;
    }
    if (_json.containsKey('maxValue')) {
      maxValue = (_json['maxValue'] as core.num).toDouble();
    }
    if (_json.containsKey('minValue')) {
      minValue = (_json['minValue'] as core.num).toDouble();
    }
    if (_json.containsKey('paramId')) {
      paramId = _json['paramId'] as core.String;
    }
    if (_json.containsKey('recurse')) {
      recurse = _json['recurse'] as core.bool;
    }
    if (_json.containsKey('repeated')) {
      repeated = _json['repeated'] as core.bool;
    }
    if (_json.containsKey('required')) {
      required = _json['required'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('validationDescription')) {
      validationDescription = _json['validationDescription'] as core.String;
    }
    if (_json.containsKey('validationHelpUrl')) {
      validationHelpUrl = _json['validationHelpUrl'] as core.String;
    }
    if (_json.containsKey('validationRegex')) {
      validationRegex = _json['validationRegex'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedValues != null) 'allowedValues': allowedValues!,
        if (deprecated != null) 'deprecated': deprecated!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (fields != null)
          'fields': fields!.map((value) => value.toJson()).toList(),
        if (immutable != null) 'immutable': immutable!,
        if (maxValue != null) 'maxValue': maxValue!,
        if (minValue != null) 'minValue': minValue!,
        if (paramId != null) 'paramId': paramId!,
        if (recurse != null) 'recurse': recurse!,
        if (repeated != null) 'repeated': repeated!,
        if (required != null) 'required': required!,
        if (type != null) 'type': type!,
        if (validationDescription != null)
          'validationDescription': validationDescription!,
        if (validationHelpUrl != null) 'validationHelpUrl': validationHelpUrl!,
        if (validationRegex != null) 'validationRegex': validationRegex!,
      };
}

/// Represents preferences for sending email notifications for transfer run
/// events.
class EmailPreferences {
  /// If true, email notifications will be sent on transfer run failures.
  core.bool? enableFailureEmail;

  EmailPreferences();

  EmailPreferences.fromJson(core.Map _json) {
    if (_json.containsKey('enableFailureEmail')) {
      enableFailureEmail = _json['enableFailureEmail'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableFailureEmail != null)
          'enableFailureEmail': enableFailureEmail!,
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

/// Returns list of supported data sources and their metadata.
class ListDataSourcesResponse {
  /// List of supported data sources and their transfer settings.
  core.List<DataSource>? dataSources;

  /// The next-pagination token.
  ///
  /// For multiple-page list results, this token can be used as the
  /// `ListDataSourcesRequest.page_token` to request the next page of list
  /// results.
  ///
  /// Output only.
  core.String? nextPageToken;

  ListDataSourcesResponse();

  ListDataSourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dataSources')) {
      dataSources = (_json['dataSources'] as core.List)
          .map<DataSource>((value) =>
              DataSource.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSources != null)
          'dataSources': dataSources!.map((value) => value.toJson()).toList(),
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

/// The returned list of pipelines in the project.
class ListTransferConfigsResponse {
  /// The next-pagination token.
  ///
  /// For multiple-page list results, this token can be used as the
  /// `ListTransferConfigsRequest.page_token` to request the next page of list
  /// results.
  ///
  /// Output only.
  core.String? nextPageToken;

  /// The stored pipeline transfer configurations.
  ///
  /// Output only.
  core.List<TransferConfig>? transferConfigs;

  ListTransferConfigsResponse();

  ListTransferConfigsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('transferConfigs')) {
      transferConfigs = (_json['transferConfigs'] as core.List)
          .map<TransferConfig>((value) => TransferConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (transferConfigs != null)
          'transferConfigs':
              transferConfigs!.map((value) => value.toJson()).toList(),
      };
}

/// The returned list transfer run messages.
class ListTransferLogsResponse {
  /// The next-pagination token.
  ///
  /// For multiple-page list results, this token can be used as the
  /// `GetTransferRunLogRequest.page_token` to request the next page of list
  /// results.
  ///
  /// Output only.
  core.String? nextPageToken;

  /// The stored pipeline transfer messages.
  ///
  /// Output only.
  core.List<TransferMessage>? transferMessages;

  ListTransferLogsResponse();

  ListTransferLogsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('transferMessages')) {
      transferMessages = (_json['transferMessages'] as core.List)
          .map<TransferMessage>((value) => TransferMessage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (transferMessages != null)
          'transferMessages':
              transferMessages!.map((value) => value.toJson()).toList(),
      };
}

/// The returned list of pipelines in the project.
class ListTransferRunsResponse {
  /// The next-pagination token.
  ///
  /// For multiple-page list results, this token can be used as the
  /// `ListTransferRunsRequest.page_token` to request the next page of list
  /// results.
  ///
  /// Output only.
  core.String? nextPageToken;

  /// The stored pipeline transfer runs.
  ///
  /// Output only.
  core.List<TransferRun>? transferRuns;

  ListTransferRunsResponse();

  ListTransferRunsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('transferRuns')) {
      transferRuns = (_json['transferRuns'] as core.List)
          .map<TransferRun>((value) => TransferRun.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (transferRuns != null)
          'transferRuns': transferRuns!.map((value) => value.toJson()).toList(),
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

/// Options customizing the data transfer schedule.
class ScheduleOptions {
  /// If true, automatic scheduling of data transfer runs for this configuration
  /// will be disabled.
  ///
  /// The runs can be started on ad-hoc basis using StartManualTransferRuns API.
  /// When automatic scheduling is disabled, the TransferConfig.schedule field
  /// will be ignored.
  core.bool? disableAutoScheduling;

  /// Defines time to stop scheduling transfer runs.
  ///
  /// A transfer run cannot be scheduled at or after the end time. The end time
  /// can be changed at any moment. The time when a data transfer can be
  /// trigerred manually is not limited by this option.
  core.String? endTime;

  /// Specifies time to start scheduling transfer runs.
  ///
  /// The first run will be scheduled at or after the start time according to a
  /// recurrence pattern defined in the schedule string. The start time can be
  /// changed at any moment. The time when a data transfer can be trigerred
  /// manually is not limited by this option.
  core.String? startTime;

  ScheduleOptions();

  ScheduleOptions.fromJson(core.Map _json) {
    if (_json.containsKey('disableAutoScheduling')) {
      disableAutoScheduling = _json['disableAutoScheduling'] as core.bool;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disableAutoScheduling != null)
          'disableAutoScheduling': disableAutoScheduling!,
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// A request to schedule transfer runs for a time range.
class ScheduleTransferRunsRequest {
  /// End time of the range of transfer runs.
  ///
  /// For example, `"2017-05-30T00:00:00+00:00"`.
  ///
  /// Required.
  core.String? endTime;

  /// Start time of the range of transfer runs.
  ///
  /// For example, `"2017-05-25T00:00:00+00:00"`.
  ///
  /// Required.
  core.String? startTime;

  ScheduleTransferRunsRequest();

  ScheduleTransferRunsRequest.fromJson(core.Map _json) {
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

/// A response to schedule transfer runs for a time range.
class ScheduleTransferRunsResponse {
  /// The transfer runs that were scheduled.
  core.List<TransferRun>? runs;

  ScheduleTransferRunsResponse();

  ScheduleTransferRunsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('runs')) {
      runs = (_json['runs'] as core.List)
          .map<TransferRun>((value) => TransferRun.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (runs != null) 'runs': runs!.map((value) => value.toJson()).toList(),
      };
}

/// A request to start manual transfer runs.
class StartManualTransferRunsRequest {
  /// Specific run_time for a transfer run to be started.
  ///
  /// The requested_run_time must not be in the future.
  core.String? requestedRunTime;

  /// Time range for the transfer runs that should be started.
  TimeRange? requestedTimeRange;

  StartManualTransferRunsRequest();

  StartManualTransferRunsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('requestedRunTime')) {
      requestedRunTime = _json['requestedRunTime'] as core.String;
    }
    if (_json.containsKey('requestedTimeRange')) {
      requestedTimeRange = TimeRange.fromJson(
          _json['requestedTimeRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestedRunTime != null) 'requestedRunTime': requestedRunTime!,
        if (requestedTimeRange != null)
          'requestedTimeRange': requestedTimeRange!.toJson(),
      };
}

/// A response to start manual transfer runs.
class StartManualTransferRunsResponse {
  /// The transfer runs that were created.
  core.List<TransferRun>? runs;

  StartManualTransferRunsResponse();

  StartManualTransferRunsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('runs')) {
      runs = (_json['runs'] as core.List)
          .map<TransferRun>((value) => TransferRun.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (runs != null) 'runs': runs!.map((value) => value.toJson()).toList(),
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

/// A specification for a time range, this will request transfer runs with
/// run_time between start_time (inclusive) and end_time (exclusive).
class TimeRange {
  /// End time of the range of transfer runs.
  ///
  /// For example, `"2017-05-30T00:00:00+00:00"`. The end_time must not be in
  /// the future. Creates transfer runs where run_time is in the range between
  /// start_time (inclusive) and end_time (exclusive).
  core.String? endTime;

  /// Start time of the range of transfer runs.
  ///
  /// For example, `"2017-05-25T00:00:00+00:00"`. The start_time must be
  /// strictly less than the end_time. Creates transfer runs where run_time is
  /// in the range between start_time (inclusive) and end_time (exclusive).
  core.String? startTime;

  TimeRange();

  TimeRange.fromJson(core.Map _json) {
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

/// Represents a data transfer configuration.
///
/// A transfer configuration contains all metadata needed to perform a data
/// transfer. For example, `destination_dataset_id` specifies where data should
/// be stored. When a new transfer configuration is created, the specified
/// `destination_dataset_id` is created when needed and shared with the
/// appropriate data source service account.
class TransferConfig {
  /// The number of days to look back to automatically refresh the data.
  ///
  /// For example, if `data_refresh_window_days = 10`, then every day BigQuery
  /// reingests data for \[today-10, today-1\], rather than ingesting data for
  /// just \[today-1\]. Only valid if the data source supports the feature. Set
  /// the value to 0 to use the default value.
  core.int? dataRefreshWindowDays;

  /// Data source id.
  ///
  /// Cannot be changed once data transfer is created.
  core.String? dataSourceId;

  /// Region in which BigQuery dataset is located.
  ///
  /// Output only.
  core.String? datasetRegion;

  /// The BigQuery target dataset id.
  core.String? destinationDatasetId;

  /// Is this config disabled.
  ///
  /// When set to true, no runs are scheduled for a given transfer.
  core.bool? disabled;

  /// User specified display name for the data transfer.
  core.String? displayName;

  /// Email notifications will be sent according to these preferences to the
  /// email address of the user who owns this transfer config.
  EmailPreferences? emailPreferences;

  /// The resource name of the transfer config.
  ///
  /// Transfer config names have the form
  /// `projects/{project_id}/locations/{region}/transferConfigs/{config_id}`.
  /// Where `config_id` is usually a uuid, even though it is not guaranteed or
  /// required. The name is ignored when creating a transfer config.
  core.String? name;

  /// Next time when data transfer will run.
  ///
  /// Output only.
  core.String? nextRunTime;

  /// Pub/Sub topic where notifications will be sent after transfer runs
  /// associated with this transfer config finish.
  core.String? notificationPubsubTopic;

  /// Parameters specific to each data source.
  ///
  /// For more information see the bq tab in the 'Setting up a data transfer'
  /// section for each data source. For example the parameters for Cloud Storage
  /// transfers are listed here:
  /// https://cloud.google.com/bigquery-transfer/docs/cloud-storage-transfer#bq
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? params;

  /// Data transfer schedule.
  ///
  /// If the data source does not support a custom schedule, this should be
  /// empty. If it is empty, the default value for the data source will be used.
  /// The specified times are in UTC. Examples of valid format: `1st,3rd monday
  /// of month 15:30`, `every wed,fri of jan,jun 13:15`, and `first sunday of
  /// quarter 00:00`. See more explanation about the format here:
  /// https://cloud.google.com/appengine/docs/flexible/python/scheduling-jobs-with-cron-yaml#the_schedule_format
  /// NOTE: the granularity should be at least 8 hours, or less frequent.
  core.String? schedule;

  /// Options customizing the data transfer schedule.
  ScheduleOptions? scheduleOptions;

  /// State of the most recently updated transfer run.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TRANSFER_STATE_UNSPECIFIED" : State placeholder (0).
  /// - "PENDING" : Data transfer is scheduled and is waiting to be picked up by
  /// data transfer backend (2).
  /// - "RUNNING" : Data transfer is in progress (3).
  /// - "SUCCEEDED" : Data transfer completed successfully (4).
  /// - "FAILED" : Data transfer failed (5).
  /// - "CANCELLED" : Data transfer is cancelled (6).
  core.String? state;

  /// Data transfer modification time.
  ///
  /// Ignored by server on input.
  ///
  /// Output only.
  core.String? updateTime;

  /// Unique ID of the user on whose behalf transfer is done.
  ///
  /// Deprecated.
  core.String? userId;

  TransferConfig();

  TransferConfig.fromJson(core.Map _json) {
    if (_json.containsKey('dataRefreshWindowDays')) {
      dataRefreshWindowDays = _json['dataRefreshWindowDays'] as core.int;
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('datasetRegion')) {
      datasetRegion = _json['datasetRegion'] as core.String;
    }
    if (_json.containsKey('destinationDatasetId')) {
      destinationDatasetId = _json['destinationDatasetId'] as core.String;
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('emailPreferences')) {
      emailPreferences = EmailPreferences.fromJson(
          _json['emailPreferences'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nextRunTime')) {
      nextRunTime = _json['nextRunTime'] as core.String;
    }
    if (_json.containsKey('notificationPubsubTopic')) {
      notificationPubsubTopic = _json['notificationPubsubTopic'] as core.String;
    }
    if (_json.containsKey('params')) {
      params = (_json['params'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('schedule')) {
      schedule = _json['schedule'] as core.String;
    }
    if (_json.containsKey('scheduleOptions')) {
      scheduleOptions = ScheduleOptions.fromJson(
          _json['scheduleOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataRefreshWindowDays != null)
          'dataRefreshWindowDays': dataRefreshWindowDays!,
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (datasetRegion != null) 'datasetRegion': datasetRegion!,
        if (destinationDatasetId != null)
          'destinationDatasetId': destinationDatasetId!,
        if (disabled != null) 'disabled': disabled!,
        if (displayName != null) 'displayName': displayName!,
        if (emailPreferences != null)
          'emailPreferences': emailPreferences!.toJson(),
        if (name != null) 'name': name!,
        if (nextRunTime != null) 'nextRunTime': nextRunTime!,
        if (notificationPubsubTopic != null)
          'notificationPubsubTopic': notificationPubsubTopic!,
        if (params != null) 'params': params!,
        if (schedule != null) 'schedule': schedule!,
        if (scheduleOptions != null)
          'scheduleOptions': scheduleOptions!.toJson(),
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (userId != null) 'userId': userId!,
      };
}

/// Represents a user facing message for a particular data transfer run.
class TransferMessage {
  /// Message text.
  core.String? messageText;

  /// Time when message was logged.
  core.String? messageTime;

  /// Message severity.
  /// Possible string values are:
  /// - "MESSAGE_SEVERITY_UNSPECIFIED" : No severity specified.
  /// - "INFO" : Informational message.
  /// - "WARNING" : Warning message.
  /// - "ERROR" : Error message.
  core.String? severity;

  TransferMessage();

  TransferMessage.fromJson(core.Map _json) {
    if (_json.containsKey('messageText')) {
      messageText = _json['messageText'] as core.String;
    }
    if (_json.containsKey('messageTime')) {
      messageTime = _json['messageTime'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (messageText != null) 'messageText': messageText!,
        if (messageTime != null) 'messageTime': messageTime!,
        if (severity != null) 'severity': severity!,
      };
}

/// Represents a data transfer run.
class TransferRun {
  /// Data source id.
  ///
  /// Output only.
  core.String? dataSourceId;

  /// The BigQuery target dataset id.
  ///
  /// Output only.
  core.String? destinationDatasetId;

  /// Email notifications will be sent according to these preferences to the
  /// email address of the user who owns the transfer config this run was
  /// derived from.
  ///
  /// Output only.
  EmailPreferences? emailPreferences;

  /// Time when transfer run ended.
  ///
  /// Parameter ignored by server for input requests.
  ///
  /// Output only.
  core.String? endTime;

  /// Status of the transfer run.
  Status? errorStatus;

  /// The resource name of the transfer run.
  ///
  /// Transfer run names have the form
  /// `projects/{project_id}/locations/{location}/transferConfigs/{config_id}/runs/{run_id}`.
  /// The name is ignored when creating a transfer run.
  core.String? name;

  /// Pub/Sub topic where a notification will be sent after this transfer run
  /// finishes
  ///
  /// Output only.
  core.String? notificationPubsubTopic;

  /// Parameters specific to each data source.
  ///
  /// For more information see the bq tab in the 'Setting up a data transfer'
  /// section for each data source. For example the parameters for Cloud Storage
  /// transfers are listed here:
  /// https://cloud.google.com/bigquery-transfer/docs/cloud-storage-transfer#bq
  ///
  /// Output only.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? params;

  /// For batch transfer runs, specifies the date and time of the data should be
  /// ingested.
  core.String? runTime;

  /// Describes the schedule of this transfer run if it was created as part of a
  /// regular schedule.
  ///
  /// For batch transfer runs that are scheduled manually, this is empty. NOTE:
  /// the system might choose to delay the schedule depending on the current
  /// load, so `schedule_time` doesn't always match this.
  ///
  /// Output only.
  core.String? schedule;

  /// Minimum time after which a transfer run can be started.
  core.String? scheduleTime;

  /// Time when transfer run was started.
  ///
  /// Parameter ignored by server for input requests.
  ///
  /// Output only.
  core.String? startTime;

  /// Data transfer run state.
  ///
  /// Ignored for input requests.
  /// Possible string values are:
  /// - "TRANSFER_STATE_UNSPECIFIED" : State placeholder (0).
  /// - "PENDING" : Data transfer is scheduled and is waiting to be picked up by
  /// data transfer backend (2).
  /// - "RUNNING" : Data transfer is in progress (3).
  /// - "SUCCEEDED" : Data transfer completed successfully (4).
  /// - "FAILED" : Data transfer failed (5).
  /// - "CANCELLED" : Data transfer is cancelled (6).
  core.String? state;

  /// Last time the data transfer run state was updated.
  ///
  /// Output only.
  core.String? updateTime;

  /// Unique ID of the user on whose behalf transfer is done.
  ///
  /// Deprecated.
  core.String? userId;

  TransferRun();

  TransferRun.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('destinationDatasetId')) {
      destinationDatasetId = _json['destinationDatasetId'] as core.String;
    }
    if (_json.containsKey('emailPreferences')) {
      emailPreferences = EmailPreferences.fromJson(
          _json['emailPreferences'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('errorStatus')) {
      errorStatus = Status.fromJson(
          _json['errorStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notificationPubsubTopic')) {
      notificationPubsubTopic = _json['notificationPubsubTopic'] as core.String;
    }
    if (_json.containsKey('params')) {
      params = (_json['params'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('runTime')) {
      runTime = _json['runTime'] as core.String;
    }
    if (_json.containsKey('schedule')) {
      schedule = _json['schedule'] as core.String;
    }
    if (_json.containsKey('scheduleTime')) {
      scheduleTime = _json['scheduleTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (destinationDatasetId != null)
          'destinationDatasetId': destinationDatasetId!,
        if (emailPreferences != null)
          'emailPreferences': emailPreferences!.toJson(),
        if (endTime != null) 'endTime': endTime!,
        if (errorStatus != null) 'errorStatus': errorStatus!.toJson(),
        if (name != null) 'name': name!,
        if (notificationPubsubTopic != null)
          'notificationPubsubTopic': notificationPubsubTopic!,
        if (params != null) 'params': params!,
        if (runTime != null) 'runTime': runTime!,
        if (schedule != null) 'schedule': schedule!,
        if (scheduleTime != null) 'scheduleTime': scheduleTime!,
        if (startTime != null) 'startTime': startTime!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (userId != null) 'userId': userId!,
      };
}

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

/// Cloud Search API - v1
///
/// Cloud Search provides cloud-based search capabilities over G Suite data. The
/// Cloud Search API allows indexing of non-G Suite data into Cloud Search.
///
/// For more information, see
/// <https://developers.google.com/cloud-search/docs/guides/>
///
/// Create an instance of [CloudSearchApi] to access these resources:
///
/// - [DebugResource]
///   - [DebugDatasourcesResource]
///     - [DebugDatasourcesItemsResource]
///       - [DebugDatasourcesItemsUnmappedidsResource]
///   - [DebugIdentitysourcesResource]
///     - [DebugIdentitysourcesItemsResource]
///     - [DebugIdentitysourcesUnmappedidsResource]
/// - [IndexingResource]
///   - [IndexingDatasourcesResource]
///     - [IndexingDatasourcesItemsResource]
/// - [MediaResource]
/// - [OperationsResource]
///   - [OperationsLroResource]
/// - [QueryResource]
///   - [QuerySourcesResource]
/// - [SettingsResource]
///   - [SettingsDatasourcesResource]
///   - [SettingsSearchapplicationsResource]
/// - [StatsResource]
///   - [StatsIndexResource]
///     - [StatsIndexDatasourcesResource]
///   - [StatsQueryResource]
///     - [StatsQuerySearchapplicationsResource]
///   - [StatsSessionResource]
///     - [StatsSessionSearchapplicationsResource]
///   - [StatsUserResource]
///     - [StatsUserSearchapplicationsResource]
library cloudsearch.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show
        ApiRequestError,
        DetailedApiRequestError,
        Media,
        UploadOptions,
        ResumableUploadOptions,
        DownloadOptions,
        PartialDownloadOptions,
        ByteRange;

/// Cloud Search provides cloud-based search capabilities over G Suite data.
///
/// The Cloud Search API allows indexing of non-G Suite data into Cloud Search.
class CloudSearchApi {
  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchScope =
      'https://www.googleapis.com/auth/cloud_search';

  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchDebugScope =
      'https://www.googleapis.com/auth/cloud_search.debug';

  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchIndexingScope =
      'https://www.googleapis.com/auth/cloud_search.indexing';

  /// Search your organization's data in the Cloud Search index
  static const cloudSearchQueryScope =
      'https://www.googleapis.com/auth/cloud_search.query';

  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchSettingsScope =
      'https://www.googleapis.com/auth/cloud_search.settings';

  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchSettingsIndexingScope =
      'https://www.googleapis.com/auth/cloud_search.settings.indexing';

  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchSettingsQueryScope =
      'https://www.googleapis.com/auth/cloud_search.settings.query';

  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchStatsScope =
      'https://www.googleapis.com/auth/cloud_search.stats';

  /// Index and serve your organization's data with Cloud Search
  static const cloudSearchStatsIndexingScope =
      'https://www.googleapis.com/auth/cloud_search.stats.indexing';

  final commons.ApiRequester _requester;

  DebugResource get debug => DebugResource(_requester);
  IndexingResource get indexing => IndexingResource(_requester);
  MediaResource get media => MediaResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);
  QueryResource get query => QueryResource(_requester);
  SettingsResource get settings => SettingsResource(_requester);
  StatsResource get stats => StatsResource(_requester);

  CloudSearchApi(http.Client client,
      {core.String rootUrl = 'https://cloudsearch.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DebugResource {
  final commons.ApiRequester _requester;

  DebugDatasourcesResource get datasources =>
      DebugDatasourcesResource(_requester);
  DebugIdentitysourcesResource get identitysources =>
      DebugIdentitysourcesResource(_requester);

  DebugResource(commons.ApiRequester client) : _requester = client;
}

class DebugDatasourcesResource {
  final commons.ApiRequester _requester;

  DebugDatasourcesItemsResource get items =>
      DebugDatasourcesItemsResource(_requester);

  DebugDatasourcesResource(commons.ApiRequester client) : _requester = client;
}

class DebugDatasourcesItemsResource {
  final commons.ApiRequester _requester;

  DebugDatasourcesItemsUnmappedidsResource get unmappedids =>
      DebugDatasourcesItemsUnmappedidsResource(_requester);

  DebugDatasourcesItemsResource(commons.ApiRequester client)
      : _requester = client;

  /// Checks whether an item is accessible by specified principal.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Item name, format: datasources/{source_id}/items/{item_id}
  /// Value must have pattern `^datasources/\[^/\]+/items/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CheckAccessResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CheckAccessResponse> checkAccess(
    Principal request,
    core.String name, {
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/debug/' + core.Uri.encodeFull('$name') + ':checkAccess';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CheckAccessResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Fetches the item whose viewUrl exactly matches that of the URL provided in
  /// the request.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Source name, format: datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchItemsByViewUrlResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchItemsByViewUrlResponse> searchByViewUrl(
    SearchItemsByViewUrlRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/debug/' + core.Uri.encodeFull('$name') + '/items:searchByViewUrl';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SearchItemsByViewUrlResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DebugDatasourcesItemsUnmappedidsResource {
  final commons.ApiRequester _requester;

  DebugDatasourcesItemsUnmappedidsResource(commons.ApiRequester client)
      : _requester = client;

  /// List all unmapped identities for a specific item.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the item, in the following format:
  /// datasources/{source_id}/items/{ID}
  /// Value must have pattern `^datasources/\[^/\]+/items/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [pageSize] - Maximum number of items to fetch in a request. Defaults to
  /// 100.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListUnmappedIdentitiesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListUnmappedIdentitiesResponse> list(
    core.String parent, {
    core.bool? debugOptions_enableDebugging,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/debug/' + core.Uri.encodeFull('$parent') + '/unmappedids';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListUnmappedIdentitiesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DebugIdentitysourcesResource {
  final commons.ApiRequester _requester;

  DebugIdentitysourcesItemsResource get items =>
      DebugIdentitysourcesItemsResource(_requester);
  DebugIdentitysourcesUnmappedidsResource get unmappedids =>
      DebugIdentitysourcesUnmappedidsResource(_requester);

  DebugIdentitysourcesResource(commons.ApiRequester client)
      : _requester = client;
}

class DebugIdentitysourcesItemsResource {
  final commons.ApiRequester _requester;

  DebugIdentitysourcesItemsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists names of items associated with an unmapped identity.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the identity source, in the following format:
  /// identitysources/{source_id}}
  /// Value must have pattern `^identitysources/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [groupResourceName] - null
  ///
  /// [pageSize] - Maximum number of items to fetch in a request. Defaults to
  /// 100.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [userResourceName] - null
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListItemNamesForUnmappedIdentityResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListItemNamesForUnmappedIdentityResponse>
      listForunmappedidentity(
    core.String parent, {
    core.bool? debugOptions_enableDebugging,
    core.String? groupResourceName,
    core.int? pageSize,
    core.String? pageToken,
    core.String? userResourceName,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if (groupResourceName != null) 'groupResourceName': [groupResourceName],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (userResourceName != null) 'userResourceName': [userResourceName],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/debug/' +
        core.Uri.encodeFull('$parent') +
        '/items:forunmappedidentity';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListItemNamesForUnmappedIdentityResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DebugIdentitysourcesUnmappedidsResource {
  final commons.ApiRequester _requester;

  DebugIdentitysourcesUnmappedidsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists unmapped user identities for an identity source.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the identity source, in the following format:
  /// identitysources/{source_id}
  /// Value must have pattern `^identitysources/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [pageSize] - Maximum number of items to fetch in a request. Defaults to
  /// 100.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [resolutionStatusCode] - Limit users selection to this status.
  /// Possible string values are:
  /// - "CODE_UNSPECIFIED" : Input-only value. Used to list all unmapped
  /// identities regardless of status.
  /// - "NOT_FOUND" : The unmapped identity was not found in IDaaS, and needs to
  /// be provided by the user.
  /// - "IDENTITY_SOURCE_NOT_FOUND" : The identity source associated with the
  /// identity was either not found or deleted.
  /// - "IDENTITY_SOURCE_MISCONFIGURED" : IDaaS does not understand the identity
  /// source, probably because the schema was modified in a non compatible way.
  /// - "TOO_MANY_MAPPINGS_FOUND" : The number of users associated with the
  /// external identity is too large.
  /// - "INTERNAL_ERROR" : Internal error.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListUnmappedIdentitiesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListUnmappedIdentitiesResponse> list(
    core.String parent, {
    core.bool? debugOptions_enableDebugging,
    core.int? pageSize,
    core.String? pageToken,
    core.String? resolutionStatusCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (resolutionStatusCode != null)
        'resolutionStatusCode': [resolutionStatusCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/debug/' + core.Uri.encodeFull('$parent') + '/unmappedids';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListUnmappedIdentitiesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class IndexingResource {
  final commons.ApiRequester _requester;

  IndexingDatasourcesResource get datasources =>
      IndexingDatasourcesResource(_requester);

  IndexingResource(commons.ApiRequester client) : _requester = client;
}

class IndexingDatasourcesResource {
  final commons.ApiRequester _requester;

  IndexingDatasourcesItemsResource get items =>
      IndexingDatasourcesItemsResource(_requester);

  IndexingDatasourcesResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes the schema of a data source.
  ///
  /// **Note:** This API requires an admin or service account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the data source to delete Schema. Format:
  /// datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
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
  async.Future<Operation> deleteSchema(
    core.String name, {
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + '/schema';

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the schema of a data source.
  ///
  /// **Note:** This API requires an admin or service account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the data source to get Schema. Format:
  /// datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
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
  async.Future<Schema> getSchema(
    core.String name, {
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + '/schema';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Schema.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the schema of a data source.
  ///
  /// This method does not perform incremental updates to the schema. Instead,
  /// this method updates the schema by overwriting the entire schema. **Note:**
  /// This API requires an admin or service account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the data source to update Schema. Format:
  /// datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
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
  async.Future<Operation> updateSchema(
    UpdateSchemaRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + '/schema';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class IndexingDatasourcesItemsResource {
  final commons.ApiRequester _requester;

  IndexingDatasourcesItemsResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes Item resource for the specified resource name.
  ///
  /// This API requires an admin or service account to execute. The service
  /// account used is the one whitelisted in the corresponding data source.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the item to delete. Format:
  /// datasources/{source_id}/items/{item_id}
  /// Value must have pattern `^datasources/\[^/\]+/items/\[^/\]+$`.
  ///
  /// [connectorName] - Name of connector making this call. Format:
  /// datasources/{source_id}/connectors/{ID}
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [mode] - Required. The RequestMode for this request.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Priority is not specified in the update request. Leaving
  /// priority unspecified results in an update failure.
  /// - "SYNCHRONOUS" : For real-time updates.
  /// - "ASYNCHRONOUS" : For changes that are executed after the response is
  /// sent back to the caller.
  ///
  /// [version] - Required. The incremented version of the item to delete from
  /// the index. The indexing system stores the version from the datasource as a
  /// byte string and compares the Item version in the index to the version of
  /// the queued Item using lexical ordering. Cloud Search Indexing won't delete
  /// any queued item with a version value that is less than or equal to the
  /// version of the currently indexed item. The maximum length for this field
  /// is 1024 bytes.
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
    core.String? connectorName,
    core.bool? debugOptions_enableDebugging,
    core.String? mode,
    core.String? version,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (connectorName != null) 'connectorName': [connectorName],
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if (mode != null) 'mode': [mode],
      if (version != null) 'version': [version],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes all items in a queue.
  ///
  /// This method is useful for deleting stale items. This API requires an admin
  /// or service account to execute. The service account used is the one
  /// whitelisted in the corresponding data source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the Data Source to delete items in a queue. Format:
  /// datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
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
  async.Future<Operation> deleteQueueItems(
    DeleteQueueItemsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' +
        core.Uri.encodeFull('$name') +
        '/items:deleteQueueItems';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets Item resource by item name.
  ///
  /// This API requires an admin or service account to execute. The service
  /// account used is the one whitelisted in the corresponding data source.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the item to get info. Format:
  /// datasources/{source_id}/items/{item_id}
  /// Value must have pattern `^datasources/\[^/\]+/items/\[^/\]+$`.
  ///
  /// [connectorName] - Name of connector making this call. Format:
  /// datasources/{source_id}/connectors/{ID}
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Item].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Item> get(
    core.String name, {
    core.String? connectorName,
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (connectorName != null) 'connectorName': [connectorName],
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Item.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates Item ACL, metadata, and content.
  ///
  /// It will insert the Item if it does not exist. This method does not support
  /// partial updates. Fields with no provided values are cleared out in the
  /// Cloud Search index. This API requires an admin or service account to
  /// execute. The service account used is the one whitelisted in the
  /// corresponding data source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the Item. Format: datasources/{source_id}/items/{item_id}
  /// This is a required field. The maximum length is 1536 characters.
  /// Value must have pattern `^datasources/\[^/\]+/items/\[^/\]+$`.
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
  async.Future<Operation> index(
    IndexItemRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + ':index';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all or a subset of Item resources.
  ///
  /// This API requires an admin or service account to execute. The service
  /// account used is the one whitelisted in the corresponding data source.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the Data Source to list Items. Format:
  /// datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [brief] - When set to true, the indexing system only populates the
  /// following fields: name, version, queue. metadata.hash, metadata.title,
  /// metadata.sourceRepositoryURL, metadata.objectType, metadata.createTime,
  /// metadata.updateTime, metadata.contentLanguage, metadata.mimeType,
  /// structured_data.hash, content.hash, itemType, itemStatus.code,
  /// itemStatus.processingError.code, itemStatus.repositoryError.type, If this
  /// value is false, then all the fields are populated in Item.
  ///
  /// [connectorName] - Name of connector making this call. Format:
  /// datasources/{source_id}/connectors/{ID}
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [pageSize] - Maximum number of items to fetch in a request. The max value
  /// is 1000 when brief is true. The max value is 10 if brief is false. The
  /// default value is 10
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListItemsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListItemsResponse> list(
    core.String name, {
    core.bool? brief,
    core.String? connectorName,
    core.bool? debugOptions_enableDebugging,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (brief != null) 'brief': ['${brief}'],
      if (connectorName != null) 'connectorName': [connectorName],
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + '/items';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListItemsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Polls for unreserved items from the indexing queue and marks a set as
  /// reserved, starting with items that have the oldest timestamp from the
  /// highest priority ItemStatus.
  ///
  /// The priority order is as follows: ERROR MODIFIED NEW_ITEM ACCEPTED
  /// Reserving items ensures that polling from other threads cannot create
  /// overlapping sets. After handling the reserved items, the client should put
  /// items back into the unreserved state, either by calling index, or by
  /// calling push with the type REQUEUE. Items automatically become available
  /// (unreserved) after 4 hours even if no update or push method is called.
  /// This API requires an admin or service account to execute. The service
  /// account used is the one whitelisted in the corresponding data source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the Data Source to poll items. Format:
  /// datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PollItemsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PollItemsResponse> poll(
    PollItemsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + '/items:poll';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PollItemsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Pushes an item onto a queue for later polling and updating.
  ///
  /// This API requires an admin or service account to execute. The service
  /// account used is the one whitelisted in the corresponding data source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the item to push into the indexing queue. Format:
  /// datasources/{source_id}/items/{ID} This is a required field. The maximum
  /// length is 1536 characters.
  /// Value must have pattern `^datasources/\[^/\]+/items/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Item].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Item> push(
    PushItemRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + ':push';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Item.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Unreserves all items from a queue, making them all eligible to be polled.
  ///
  /// This method is useful for resetting the indexing queue after a connector
  /// has been restarted. This API requires an admin or service account to
  /// execute. The service account used is the one whitelisted in the
  /// corresponding data source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the Data Source to unreserve all items. Format:
  /// datasources/{source_id}
  /// Value must have pattern `^datasources/\[^/\]+$`.
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
  async.Future<Operation> unreserve(
    UnreserveItemsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/indexing/' + core.Uri.encodeFull('$name') + '/items:unreserve';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates an upload session for uploading item content.
  ///
  /// For items smaller than 100 KB, it's easier to embed the content inline
  /// within an index request. This API requires an admin or service account to
  /// execute. The service account used is the one whitelisted in the
  /// corresponding data source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the Item to start a resumable upload. Format:
  /// datasources/{source_id}/items/{item_id}. The maximum length is 1536 bytes.
  /// Value must have pattern `^datasources/\[^/\]+/items/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UploadItemRef].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UploadItemRef> upload(
    StartUploadItemRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/indexing/' + core.Uri.encodeFull('$name') + ':upload';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UploadItemRef.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MediaResource {
  final commons.ApiRequester _requester;

  MediaResource(commons.ApiRequester client) : _requester = client;

  /// Uploads media for indexing.
  ///
  /// The upload endpoint supports direct and resumable upload protocols and is
  /// intended for large items that can not be
  /// [inlined during index requests](https://developers.google.com/cloud-search/docs/reference/rest/v1/indexing.datasources.items#itemcontent).
  /// To index large content: 1. Call indexing.datasources.items.upload with the
  /// item name to begin an upload session and retrieve the UploadItemRef. 1.
  /// Call media.upload to upload the content, as a streaming request, using the
  /// same resource name from the UploadItemRef from step 1. 1. Call
  /// indexing.datasources.items.index to index the item. Populate the
  /// \[ItemContent\](/cloud-search/docs/reference/rest/v1/indexing.datasources.items#ItemContent)
  /// with the UploadItemRef from step 1. For additional information, see
  /// [Create a content connector using the REST API](https://developers.google.com/cloud-search/docs/guides/content-connector#rest).
  /// **Note:** This API requires a service account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resourceName] - Name of the media that is being downloaded. See
  /// ReadRequest.resource_name.
  /// Value must have pattern `^.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// Completes with a [Media].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Media> upload(
    Media request,
    core.String resourceName, {
    core.String? $fields,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'v1/media/' + core.Uri.encodeFull('$resourceName');
    } else {
      _url = '/upload/v1/media/' + core.Uri.encodeFull('$resourceName');
    }

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: commons.UploadOptions.defaultOptions,
    );
    return Media.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsLroResource get lro => OperationsLroResource(_requester);

  OperationsResource(commons.ApiRequester client) : _requester = client;

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
}

class OperationsLroResource {
  final commons.ApiRequester _requester;

  OperationsLroResource(commons.ApiRequester client) : _requester = client;

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
  /// Value must have pattern `^operations/.*$`.
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

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/lro';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class QueryResource {
  final commons.ApiRequester _requester;

  QuerySourcesResource get sources => QuerySourcesResource(_requester);

  QueryResource(commons.ApiRequester client) : _requester = client;

  /// The Cloud Search Query API provides the search method, which returns the
  /// most relevant results from a user query.
  ///
  /// The results can come from G Suite Apps, such as Gmail or Google Drive, or
  /// they can come from data that you have indexed from a third party.
  /// **Note:** This API requires a standard end user account to execute. A
  /// service account can't perform Query API requests directly; to use a
  /// service account to perform queries, set up \[G Suite domain-wide
  /// delegation of
  /// authority\](https://developers.google.com/cloud-search/docs/guides/delegation/).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchResponse> search(
    SearchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/query/search';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SearchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Provides suggestions for autocompleting the query.
  ///
  /// **Note:** This API requires a standard end user account to execute. A
  /// service account can't perform Query API requests directly; to use a
  /// service account to perform queries, set up \[G Suite domain-wide
  /// delegation of
  /// authority\](https://developers.google.com/cloud-search/docs/guides/delegation/).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SuggestResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SuggestResponse> suggest(
    SuggestRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/query/suggest';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SuggestResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class QuerySourcesResource {
  final commons.ApiRequester _requester;

  QuerySourcesResource(commons.ApiRequester client) : _requester = client;

  /// Returns list of sources that user can use for Search and Suggest APIs.
  ///
  /// **Note:** This API requires a standard end user account to execute. A
  /// service account can't perform Query API requests directly; to use a
  /// service account to perform queries, set up \[G Suite domain-wide
  /// delegation of
  /// authority\](https://developers.google.com/cloud-search/docs/guides/delegation/).
  ///
  /// Request parameters:
  ///
  /// [pageToken] - Number of sources to return in the response.
  ///
  /// [requestOptions_debugOptions_enableDebugging] - If you are asked by Google
  /// to help with debugging, set this field. Otherwise, ignore this field.
  ///
  /// [requestOptions_languageCode] - The BCP-47 language code, such as "en-US"
  /// or "sr-Latn". For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier. For
  /// translations. Set this field using the language set in browser or for the
  /// page. In the event that the user's language preference is known, set this
  /// field to the known user language. When specified, the documents in search
  /// results are biased towards the specified language. The suggest API does
  /// not use this parameter. Instead, suggest autocompletes only based on
  /// characters in the query.
  ///
  /// [requestOptions_searchApplicationId] - The ID generated when you create a
  /// search application using the
  /// [admin console](https://support.google.com/a/answer/9043922).
  ///
  /// [requestOptions_timeZone] - Current user's time zone id, such as
  /// "America/Los_Angeles" or "Australia/Sydney". These IDs are defined by
  /// \[Unicode Common Locale Data Repository (CLDR)\](http://cldr.unicode.org/)
  /// project, and currently available in the file
  /// [timezone.xml](http://unicode.org/repos/cldr/trunk/common/bcp47/timezone.xml).
  /// This field is used to correctly interpret date and time queries. If this
  /// field is not specified, the default time zone (UTC) is used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListQuerySourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListQuerySourcesResponse> list({
    core.String? pageToken,
    core.bool? requestOptions_debugOptions_enableDebugging,
    core.String? requestOptions_languageCode,
    core.String? requestOptions_searchApplicationId,
    core.String? requestOptions_timeZone,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageToken != null) 'pageToken': [pageToken],
      if (requestOptions_debugOptions_enableDebugging != null)
        'requestOptions.debugOptions.enableDebugging': [
          '${requestOptions_debugOptions_enableDebugging}'
        ],
      if (requestOptions_languageCode != null)
        'requestOptions.languageCode': [requestOptions_languageCode],
      if (requestOptions_searchApplicationId != null)
        'requestOptions.searchApplicationId': [
          requestOptions_searchApplicationId
        ],
      if (requestOptions_timeZone != null)
        'requestOptions.timeZone': [requestOptions_timeZone],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/query/sources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListQuerySourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SettingsResource {
  final commons.ApiRequester _requester;

  SettingsDatasourcesResource get datasources =>
      SettingsDatasourcesResource(_requester);
  SettingsSearchapplicationsResource get searchapplications =>
      SettingsSearchapplicationsResource(_requester);

  SettingsResource(commons.ApiRequester client) : _requester = client;

  /// Get customer settings.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomerSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomerSettings> getCustomer({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/settings/customer';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CustomerSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update customer settings.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [updateMask] - Update mask to control which fields get updated. If you
  /// specify a field in the update_mask but don't specify its value here, that
  /// field will be cleared. If the mask is not present or empty, all fields
  /// will be updated. Currently supported field paths: vpc_settings and
  /// audit_logging_settings
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
  async.Future<Operation> updateCustomer(
    CustomerSettings request, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/settings/customer';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SettingsDatasourcesResource {
  final commons.ApiRequester _requester;

  SettingsDatasourcesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a datasource.
  ///
  /// **Note:** This API requires an admin account to execute.
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
    DataSource request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/settings/datasources';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a datasource.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the datasource. Format: datasources/{source_id}.
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
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
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/settings/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a datasource.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the datasource resource. Format: datasources/{source_id}.
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
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
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/settings/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DataSource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists datasources.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [pageSize] - Maximum number of datasources to fetch in a request. The max
  /// value is 100. The default value is 10
  ///
  /// [pageToken] - Starting index of the results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDataSourceResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDataSourceResponse> list({
    core.bool? debugOptions_enableDebugging,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/settings/datasources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDataSourceResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a datasource.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the datasource resource. Format: datasources/{source_id}.
  /// The name is ignored when creating a datasource.
  /// Value must have pattern `^datasources/\[^/\]+$`.
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
    UpdateDataSourceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/settings/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SettingsSearchapplicationsResource {
  final commons.ApiRequester _requester;

  SettingsSearchapplicationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a search application.
  ///
  /// **Note:** This API requires an admin account to execute.
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
    SearchApplication request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/settings/searchapplications';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a search application.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the search application to be deleted. Format:
  /// applications/{application_id}.
  /// Value must have pattern `^searchapplications/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
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
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/settings/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the specified search application.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the search application. Format:
  /// searchapplications/{application_id}.
  /// Value must have pattern `^searchapplications/\[^/\]+$`.
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchApplication].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchApplication> get(
    core.String name, {
    core.bool? debugOptions_enableDebugging,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/settings/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchApplication.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all search applications.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// Request parameters:
  ///
  /// [debugOptions_enableDebugging] - If you are asked by Google to help with
  /// debugging, set this field. Otherwise, ignore this field.
  ///
  /// [pageSize] - The maximum number of items to return.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any. The default value is 10
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSearchApplicationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSearchApplicationsResponse> list({
    core.bool? debugOptions_enableDebugging,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (debugOptions_enableDebugging != null)
        'debugOptions.enableDebugging': ['${debugOptions_enableDebugging}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/settings/searchapplications';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSearchApplicationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Resets a search application to default settings.
  ///
  /// This will return an empty response. **Note:** This API requires an admin
  /// account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the search application to be reset. Format:
  /// applications/{application_id}.
  /// Value must have pattern `^searchapplications/\[^/\]+$`.
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
  async.Future<Operation> reset(
    ResetSearchApplicationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/settings/' + core.Uri.encodeFull('$name') + ':reset';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a search application.
  ///
  /// **Note:** This API requires an admin account to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the Search Application. Format:
  /// searchapplications/{application_id}.
  /// Value must have pattern `^searchapplications/\[^/\]+$`.
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
    SearchApplication request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/settings/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class StatsResource {
  final commons.ApiRequester _requester;

  StatsIndexResource get index => StatsIndexResource(_requester);
  StatsQueryResource get query => StatsQueryResource(_requester);
  StatsSessionResource get session => StatsSessionResource(_requester);
  StatsUserResource get user => StatsUserResource(_requester);

  StatsResource(commons.ApiRequester client) : _requester = client;

  /// Gets indexed item statistics aggreggated across all data sources.
  ///
  /// This API only returns statistics for previous dates; it doesn't return
  /// statistics for the current day. **Note:** This API requires a standard end
  /// user account to execute.
  ///
  /// Request parameters:
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetCustomerIndexStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetCustomerIndexStatsResponse> getIndex({
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/stats/index';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetCustomerIndexStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get the query statistics for customer.
  ///
  /// **Note:** This API requires a standard end user account to execute.
  ///
  /// Request parameters:
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetCustomerQueryStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetCustomerQueryStatsResponse> getQuery({
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/stats/query';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetCustomerQueryStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get the # of search sessions, % of successful sessions with a click query
  /// statistics for customer.
  ///
  /// **Note:** This API requires a standard end user account to execute.
  ///
  /// Request parameters:
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetCustomerSessionStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetCustomerSessionStatsResponse> getSession({
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/stats/session';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetCustomerSessionStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get the users statistics for customer.
  ///
  /// **Note:** This API requires a standard end user account to execute.
  ///
  /// Request parameters:
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetCustomerUserStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetCustomerUserStatsResponse> getUser({
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/stats/user';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetCustomerUserStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StatsIndexResource {
  final commons.ApiRequester _requester;

  StatsIndexDatasourcesResource get datasources =>
      StatsIndexDatasourcesResource(_requester);

  StatsIndexResource(commons.ApiRequester client) : _requester = client;
}

class StatsIndexDatasourcesResource {
  final commons.ApiRequester _requester;

  StatsIndexDatasourcesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets indexed item statistics for a single data source.
  ///
  /// **Note:** This API requires a standard end user account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource id of the data source to retrieve statistics for, in
  /// the following format: "datasources/{source_id}"
  /// Value must have pattern `^datasources/\[^/\]+$`.
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetDataSourceIndexStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetDataSourceIndexStatsResponse> get(
    core.String name, {
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/stats/index/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetDataSourceIndexStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StatsQueryResource {
  final commons.ApiRequester _requester;

  StatsQuerySearchapplicationsResource get searchapplications =>
      StatsQuerySearchapplicationsResource(_requester);

  StatsQueryResource(commons.ApiRequester client) : _requester = client;
}

class StatsQuerySearchapplicationsResource {
  final commons.ApiRequester _requester;

  StatsQuerySearchapplicationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Get the query statistics for search application.
  ///
  /// **Note:** This API requires a standard end user account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource id of the search application query stats, in the
  /// following format: searchapplications/{application_id}
  /// Value must have pattern `^searchapplications/\[^/\]+$`.
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetSearchApplicationQueryStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetSearchApplicationQueryStatsResponse> get(
    core.String name, {
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/stats/query/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetSearchApplicationQueryStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StatsSessionResource {
  final commons.ApiRequester _requester;

  StatsSessionSearchapplicationsResource get searchapplications =>
      StatsSessionSearchapplicationsResource(_requester);

  StatsSessionResource(commons.ApiRequester client) : _requester = client;
}

class StatsSessionSearchapplicationsResource {
  final commons.ApiRequester _requester;

  StatsSessionSearchapplicationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Get the # of search sessions, % of successful sessions with a click query
  /// statistics for search application.
  ///
  /// **Note:** This API requires a standard end user account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource id of the search application session stats, in the
  /// following format: searchapplications/{application_id}
  /// Value must have pattern `^searchapplications/\[^/\]+$`.
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetSearchApplicationSessionStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetSearchApplicationSessionStatsResponse> get(
    core.String name, {
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/stats/session/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetSearchApplicationSessionStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StatsUserResource {
  final commons.ApiRequester _requester;

  StatsUserSearchapplicationsResource get searchapplications =>
      StatsUserSearchapplicationsResource(_requester);

  StatsUserResource(commons.ApiRequester client) : _requester = client;
}

class StatsUserSearchapplicationsResource {
  final commons.ApiRequester _requester;

  StatsUserSearchapplicationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Get the users statistics for search application.
  ///
  /// **Note:** This API requires a standard end user account to execute.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource id of the search application session stats, in the
  /// following format: searchapplications/{application_id}
  /// Value must have pattern `^searchapplications/\[^/\]+$`.
  ///
  /// [fromDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [fromDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [fromDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [toDate_day] - Day of month. Must be from 1 to 31 and valid for the year
  /// and month.
  ///
  /// [toDate_month] - Month of date. Must be from 1 to 12.
  ///
  /// [toDate_year] - Year of date. Must be from 1 to 9999.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetSearchApplicationUserStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetSearchApplicationUserStatsResponse> get(
    core.String name, {
    core.int? fromDate_day,
    core.int? fromDate_month,
    core.int? fromDate_year,
    core.int? toDate_day,
    core.int? toDate_month,
    core.int? toDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fromDate_day != null) 'fromDate.day': ['${fromDate_day}'],
      if (fromDate_month != null) 'fromDate.month': ['${fromDate_month}'],
      if (fromDate_year != null) 'fromDate.year': ['${fromDate_year}'],
      if (toDate_day != null) 'toDate.day': ['${toDate_day}'],
      if (toDate_month != null) 'toDate.month': ['${toDate_month}'],
      if (toDate_year != null) 'toDate.year': ['${toDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/stats/user/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetSearchApplicationUserStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Represents the settings for Cloud audit logging
class AuditLoggingSettings {
  /// Indicates whether audit logging is on/off for admin activity read APIs
  /// i.e. Get/List DataSources, Get/List SearchApplications etc.
  core.bool? logAdminReadActions;

  /// Indicates whether audit logging is on/off for data access read APIs i.e.
  /// ListItems, GetItem etc.
  core.bool? logDataReadActions;

  /// Indicates whether audit logging is on/off for data access write APIs i.e.
  /// IndexItem etc.
  core.bool? logDataWriteActions;

  /// The resource name of the GCP Project to store audit logs.
  ///
  /// Cloud audit logging will be enabled after project_name has been updated
  /// through CustomerService. Format: projects/{project_id}
  core.String? project;

  AuditLoggingSettings();

  AuditLoggingSettings.fromJson(core.Map _json) {
    if (_json.containsKey('logAdminReadActions')) {
      logAdminReadActions = _json['logAdminReadActions'] as core.bool;
    }
    if (_json.containsKey('logDataReadActions')) {
      logDataReadActions = _json['logDataReadActions'] as core.bool;
    }
    if (_json.containsKey('logDataWriteActions')) {
      logDataWriteActions = _json['logDataWriteActions'] as core.bool;
    }
    if (_json.containsKey('project')) {
      project = _json['project'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logAdminReadActions != null)
          'logAdminReadActions': logAdminReadActions!,
        if (logDataReadActions != null)
          'logDataReadActions': logDataReadActions!,
        if (logDataWriteActions != null)
          'logDataWriteActions': logDataWriteActions!,
        if (project != null) 'project': project!,
      };
}

/// Used to provide a search operator for boolean properties.
///
/// This is optional. Search operators let users restrict the query to specific
/// fields relevant to the type of item being searched.
class BooleanOperatorOptions {
  /// Indicates the operator name required in the query in order to isolate the
  /// boolean property.
  ///
  /// For example, if operatorName is *closed* and the property's name is
  /// *isClosed*, then queries like *closed:<value>* show results only where the
  /// value of the property named *isClosed* matches *<value>*. By contrast, a
  /// search that uses the same *<value>* without an operator returns all items
  /// where *<value>* matches the value of any String properties or text within
  /// the content field for the item. The operator name can only contain
  /// lowercase letters (a-z). The maximum length is 32 characters.
  core.String? operatorName;

  BooleanOperatorOptions();

  BooleanOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for boolean properties.
class BooleanPropertyOptions {
  /// If set, describes how the boolean should be used as a search operator.
  BooleanOperatorOptions? operatorOptions;

  BooleanPropertyOptions();

  BooleanPropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = BooleanOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
      };
}

class CheckAccessResponse {
  /// Returns true if principal has access.
  ///
  /// Returns false otherwise.
  core.bool? hasAccess;

  CheckAccessResponse();

  CheckAccessResponse.fromJson(core.Map _json) {
    if (_json.containsKey('hasAccess')) {
      hasAccess = _json['hasAccess'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hasAccess != null) 'hasAccess': hasAccess!,
      };
}

class CompositeFilter {
  /// The logic operator of the sub filter.
  /// Possible string values are:
  /// - "AND" : Logical operators, which can only be applied to sub filters.
  /// - "OR"
  /// - "NOT" : NOT can only be applied on a single sub filter.
  core.String? logicOperator;

  /// Sub filters.
  core.List<Filter>? subFilters;

  CompositeFilter();

  CompositeFilter.fromJson(core.Map _json) {
    if (_json.containsKey('logicOperator')) {
      logicOperator = _json['logicOperator'] as core.String;
    }
    if (_json.containsKey('subFilters')) {
      subFilters = (_json['subFilters'] as core.List)
          .map<Filter>((value) =>
              Filter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logicOperator != null) 'logicOperator': logicOperator!,
        if (subFilters != null)
          'subFilters': subFilters!.map((value) => value.toJson()).toList(),
      };
}

/// A named attribute associated with an item which can be used for influencing
/// the ranking of the item based on the context in the request.
class ContextAttribute {
  /// The name of the attribute.
  ///
  /// It should not be empty. The maximum length is 32 characters. The name must
  /// start with a letter and can only contain letters (A-Z, a-z) or numbers
  /// (0-9). The name will be normalized (lower-cased) before being matched.
  core.String? name;

  /// Text values of the attribute.
  ///
  /// The maximum number of elements is 10. The maximum length of an element in
  /// the array is 32 characters. The value will be normalized (lower-cased)
  /// before being matched.
  core.List<core.String>? values;

  ContextAttribute();

  ContextAttribute.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (values != null) 'values': values!,
      };
}

/// Aggregation of items by status code as of the specified date.
class CustomerIndexStats {
  /// Date for which statistics were calculated.
  Date? date;

  /// Number of items aggregrated by status code.
  core.List<ItemCountByStatus>? itemCountByStatus;

  CustomerIndexStats();

  CustomerIndexStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('itemCountByStatus')) {
      itemCountByStatus = (_json['itemCountByStatus'] as core.List)
          .map<ItemCountByStatus>((value) => ItemCountByStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (itemCountByStatus != null)
          'itemCountByStatus':
              itemCountByStatus!.map((value) => value.toJson()).toList(),
      };
}

class CustomerQueryStats {
  /// Date for which query stats were calculated.
  ///
  /// Stats calculated on the next day close to midnight are returned.
  Date? date;
  core.List<QueryCountByStatus>? queryCountByStatus;

  CustomerQueryStats();

  CustomerQueryStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryCountByStatus')) {
      queryCountByStatus = (_json['queryCountByStatus'] as core.List)
          .map<QueryCountByStatus>((value) => QueryCountByStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (queryCountByStatus != null)
          'queryCountByStatus':
              queryCountByStatus!.map((value) => value.toJson()).toList(),
      };
}

class CustomerSessionStats {
  /// Date for which session stats were calculated.
  ///
  /// Stats calculated on the next day close to midnight are returned.
  Date? date;

  /// The count of search sessions on the day
  core.String? searchSessionsCount;

  CustomerSessionStats();

  CustomerSessionStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('searchSessionsCount')) {
      searchSessionsCount = _json['searchSessionsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (searchSessionsCount != null)
          'searchSessionsCount': searchSessionsCount!,
      };
}

/// Represents settings at a customer level.
class CustomerSettings {
  /// Audit Logging settings for the customer.
  ///
  /// If update_mask is empty then this field will be updated based on
  /// UpdateCustomerSettings request.
  AuditLoggingSettings? auditLoggingSettings;

  /// VPC SC settings for the customer.
  ///
  /// If update_mask is empty then this field will be updated based on
  /// UpdateCustomerSettings request.
  VPCSettings? vpcSettings;

  CustomerSettings();

  CustomerSettings.fromJson(core.Map _json) {
    if (_json.containsKey('auditLoggingSettings')) {
      auditLoggingSettings = AuditLoggingSettings.fromJson(
          _json['auditLoggingSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('vpcSettings')) {
      vpcSettings = VPCSettings.fromJson(
          _json['vpcSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditLoggingSettings != null)
          'auditLoggingSettings': auditLoggingSettings!.toJson(),
        if (vpcSettings != null) 'vpcSettings': vpcSettings!.toJson(),
      };
}

class CustomerUserStats {
  /// Date for which session stats were calculated.
  ///
  /// Stats calculated on the next day close to midnight are returned.
  Date? date;

  /// The count of unique active users in the past one day
  core.String? oneDayActiveUsersCount;

  /// The count of unique active users in the past seven days
  core.String? sevenDaysActiveUsersCount;

  /// The count of unique active users in the past thirty days
  core.String? thirtyDaysActiveUsersCount;

  CustomerUserStats();

  CustomerUserStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('oneDayActiveUsersCount')) {
      oneDayActiveUsersCount = _json['oneDayActiveUsersCount'] as core.String;
    }
    if (_json.containsKey('sevenDaysActiveUsersCount')) {
      sevenDaysActiveUsersCount =
          _json['sevenDaysActiveUsersCount'] as core.String;
    }
    if (_json.containsKey('thirtyDaysActiveUsersCount')) {
      thirtyDaysActiveUsersCount =
          _json['thirtyDaysActiveUsersCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (oneDayActiveUsersCount != null)
          'oneDayActiveUsersCount': oneDayActiveUsersCount!,
        if (sevenDaysActiveUsersCount != null)
          'sevenDaysActiveUsersCount': sevenDaysActiveUsersCount!,
        if (thirtyDaysActiveUsersCount != null)
          'thirtyDaysActiveUsersCount': thirtyDaysActiveUsersCount!,
      };
}

/// Datasource is a logical namespace for items to be indexed.
///
/// All items must belong to a datasource. This is the prerequisite before items
/// can be indexed into Cloud Search.
class DataSource {
  /// If true, sets the datasource to read-only mode.
  ///
  /// In read-only mode, the Indexing API rejects any requests to index or
  /// delete items in this source. Enabling read-only mode does not stop the
  /// processing of previously accepted data.
  core.bool? disableModifications;

  /// Disable serving any search or assist results.
  core.bool? disableServing;

  /// Display name of the datasource The maximum length is 300 characters.
  ///
  /// Required.
  core.String? displayName;

  /// List of service accounts that have indexing access.
  core.List<core.String>? indexingServiceAccounts;

  /// This field restricts visibility to items at the datasource level.
  ///
  /// Items within the datasource are restricted to the union of users and
  /// groups included in this field. Note that, this does not ensure access to a
  /// specific item, as users need to have ACL permissions on the contained
  /// items. This ensures a high level access on the entire datasource, and that
  /// the individual items are not shared outside this visibility.
  core.List<GSuitePrincipal>? itemsVisibility;

  /// Name of the datasource resource.
  ///
  /// Format: datasources/{source_id}. The name is ignored when creating a
  /// datasource.
  core.String? name;

  /// IDs of the Long Running Operations (LROs) currently running for this
  /// schema.
  core.List<core.String>? operationIds;

  /// A short name or alias for the source.
  ///
  /// This value will be used to match the 'source' operator. For example, if
  /// the short name is *<value>* then queries like *source:<value>* will only
  /// return results for this source. The value must be unique across all
  /// datasources. The value must only contain alphanumeric characters
  /// (a-zA-Z0-9). The value cannot start with 'google' and cannot be one of the
  /// following: mail, gmail, docs, drive, groups, sites, calendar, hangouts,
  /// gplus, keep, people, teams. Its maximum length is 32 characters.
  core.String? shortName;

  DataSource();

  DataSource.fromJson(core.Map _json) {
    if (_json.containsKey('disableModifications')) {
      disableModifications = _json['disableModifications'] as core.bool;
    }
    if (_json.containsKey('disableServing')) {
      disableServing = _json['disableServing'] as core.bool;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('indexingServiceAccounts')) {
      indexingServiceAccounts = (_json['indexingServiceAccounts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('itemsVisibility')) {
      itemsVisibility = (_json['itemsVisibility'] as core.List)
          .map<GSuitePrincipal>((value) => GSuitePrincipal.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operationIds')) {
      operationIds = (_json['operationIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('shortName')) {
      shortName = _json['shortName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disableModifications != null)
          'disableModifications': disableModifications!,
        if (disableServing != null) 'disableServing': disableServing!,
        if (displayName != null) 'displayName': displayName!,
        if (indexingServiceAccounts != null)
          'indexingServiceAccounts': indexingServiceAccounts!,
        if (itemsVisibility != null)
          'itemsVisibility':
              itemsVisibility!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (operationIds != null) 'operationIds': operationIds!,
        if (shortName != null) 'shortName': shortName!,
      };
}

/// Aggregation of items by status code as of the specified date.
class DataSourceIndexStats {
  /// Date for which index stats were calculated.
  ///
  /// If the date of request is not the current date then stats calculated on
  /// the next day are returned. Stats are calculated close to mid night in this
  /// case. If date of request is current date, then real time stats are
  /// returned.
  Date? date;

  /// Number of items aggregrated by status code.
  core.List<ItemCountByStatus>? itemCountByStatus;

  DataSourceIndexStats();

  DataSourceIndexStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('itemCountByStatus')) {
      itemCountByStatus = (_json['itemCountByStatus'] as core.List)
          .map<ItemCountByStatus>((value) => ItemCountByStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (itemCountByStatus != null)
          'itemCountByStatus':
              itemCountByStatus!.map((value) => value.toJson()).toList(),
      };
}

/// Restriction on Datasource.
class DataSourceRestriction {
  /// Filter options restricting the results.
  ///
  /// If multiple filters are present, they are grouped by object type before
  /// joining. Filters with the same object type are joined conjunctively, then
  /// the resulting expressions are joined disjunctively. The maximum number of
  /// elements is 20. NOTE: Suggest API supports only few filters at the moment:
  /// "objecttype", "type" and "mimetype". For now, schema specific filters
  /// cannot be used to filter suggestions.
  core.List<FilterOptions>? filterOptions;

  /// The source of restriction.
  Source? source;

  DataSourceRestriction();

  DataSourceRestriction.fromJson(core.Map _json) {
    if (_json.containsKey('filterOptions')) {
      filterOptions = (_json['filterOptions'] as core.List)
          .map<FilterOptions>((value) => FilterOptions.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filterOptions != null)
          'filterOptions':
              filterOptions!.map((value) => value.toJson()).toList(),
        if (source != null) 'source': source!.toJson(),
      };
}

/// Represents a whole calendar date, for example a date of birth.
///
/// The time of day and time zone are either specified elsewhere or are not
/// significant. The date is relative to the
/// [Proleptic Gregorian Calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar).
/// The date must be a valid calendar date between the year 1 and 9999.
class Date {
  /// Day of month.
  ///
  /// Must be from 1 to 31 and valid for the year and month.
  core.int? day;

  /// Month of date.
  ///
  /// Must be from 1 to 12.
  core.int? month;

  /// Year of date.
  ///
  /// Must be from 1 to 9999.
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

/// Provides a search operator for date properties.
///
/// Search operators let users restrict the query to specific fields relevant to
/// the type of item being searched.
///
/// Optional.
class DateOperatorOptions {
  /// Indicates the operator name required in the query in order to isolate the
  /// date property using the greater-than operator.
  ///
  /// For example, if greaterThanOperatorName is *closedafter* and the
  /// property's name is *closeDate*, then queries like *closedafter:<value>*
  /// show results only where the value of the property named *closeDate* is
  /// later than *<value>*. The operator name can only contain lowercase letters
  /// (a-z). The maximum length is 32 characters.
  core.String? greaterThanOperatorName;

  /// Indicates the operator name required in the query in order to isolate the
  /// date property using the less-than operator.
  ///
  /// For example, if lessThanOperatorName is *closedbefore* and the property's
  /// name is *closeDate*, then queries like *closedbefore:<value>* show results
  /// only where the value of the property named *closeDate* is earlier than
  /// *<value>*. The operator name can only contain lowercase letters (a-z). The
  /// maximum length is 32 characters.
  core.String? lessThanOperatorName;

  /// Indicates the actual string required in the query in order to isolate the
  /// date property.
  ///
  /// For example, suppose an issue tracking schema object has a property named
  /// *closeDate* that specifies an operator with an operatorName of *closedon*.
  /// For searches on that data, queries like *closedon:<value>* show results
  /// only where the value of the *closeDate* property matches *<value>*. By
  /// contrast, a search that uses the same *<value>* without an operator
  /// returns all items where *<value>* matches the value of any String
  /// properties or text within the content field for the indexed datasource.
  /// The operator name can only contain lowercase letters (a-z). The maximum
  /// length is 32 characters.
  core.String? operatorName;

  DateOperatorOptions();

  DateOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('greaterThanOperatorName')) {
      greaterThanOperatorName = _json['greaterThanOperatorName'] as core.String;
    }
    if (_json.containsKey('lessThanOperatorName')) {
      lessThanOperatorName = _json['lessThanOperatorName'] as core.String;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (greaterThanOperatorName != null)
          'greaterThanOperatorName': greaterThanOperatorName!,
        if (lessThanOperatorName != null)
          'lessThanOperatorName': lessThanOperatorName!,
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for date properties.
class DatePropertyOptions {
  /// If set, describes how the date should be used as a search operator.
  DateOperatorOptions? operatorOptions;

  DatePropertyOptions();

  DatePropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = DateOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
      };
}

/// List of date values.
class DateValues {
  core.List<Date>? values;

  DateValues();

  DateValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<Date>((value) =>
              Date.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
      };
}

/// Shared request debug options for all cloudsearch RPC methods.
class DebugOptions {
  /// If you are asked by Google to help with debugging, set this field.
  ///
  /// Otherwise, ignore this field.
  core.bool? enableDebugging;

  DebugOptions();

  DebugOptions.fromJson(core.Map _json) {
    if (_json.containsKey('enableDebugging')) {
      enableDebugging = _json['enableDebugging'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableDebugging != null) 'enableDebugging': enableDebugging!,
      };
}

class DeleteQueueItemsRequest {
  /// Name of connector making this call.
  ///
  /// Format: datasources/{source_id}/connectors/{ID}
  core.String? connectorName;

  /// Common debug options.
  DebugOptions? debugOptions;

  /// Name of a queue to delete items from.
  core.String? queue;

  DeleteQueueItemsRequest();

  DeleteQueueItemsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('connectorName')) {
      connectorName = _json['connectorName'] as core.String;
    }
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queue')) {
      queue = _json['queue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectorName != null) 'connectorName': connectorName!,
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (queue != null) 'queue': queue!,
      };
}

/// A reference to a top-level property within the object that should be
/// displayed in search results.
///
/// The values of the chosen properties is displayed in the search results along
/// with the display label for that property if one is specified. If a display
/// label is not specified, only the values is shown.
class DisplayedProperty {
  /// The name of the top-level property as defined in a property definition for
  /// the object.
  ///
  /// If the name is not a defined property in the schema, an error is given
  /// when attempting to update the schema.
  core.String? propertyName;

  DisplayedProperty();

  DisplayedProperty.fromJson(core.Map _json) {
    if (_json.containsKey('propertyName')) {
      propertyName = _json['propertyName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (propertyName != null) 'propertyName': propertyName!,
      };
}

/// Used to provide a search operator for double properties.
///
/// This is optional. Search operators let users restrict the query to specific
/// fields relevant to the type of item being searched.
class DoubleOperatorOptions {
  /// Indicates the operator name required in the query in order to use the
  /// double property in sorting or as a facet.
  ///
  /// The operator name can only contain lowercase letters (a-z). The maximum
  /// length is 32 characters.
  core.String? operatorName;

  DoubleOperatorOptions();

  DoubleOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for double properties.
class DoublePropertyOptions {
  /// If set, describes how the double should be used as a search operator.
  DoubleOperatorOptions? operatorOptions;

  DoublePropertyOptions();

  DoublePropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = DoubleOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
      };
}

/// List of double values.
class DoubleValues {
  core.List<core.double>? values;

  DoubleValues();

  DoubleValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null) 'values': values!,
      };
}

/// Drive follow-up search restricts (e.g. "followup:suggestions").
class DriveFollowUpRestrict {
  ///
  /// Possible string values are:
  /// - "UNSPECIFIED"
  /// - "FOLLOWUP_SUGGESTIONS"
  /// - "FOLLOWUP_ACTION_ITEMS"
  core.String? type;

  DriveFollowUpRestrict();

  DriveFollowUpRestrict.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
      };
}

/// Drive location search restricts (e.g. "is:starred").
class DriveLocationRestrict {
  ///
  /// Possible string values are:
  /// - "UNSPECIFIED"
  /// - "TRASHED"
  /// - "STARRED"
  core.String? type;

  DriveLocationRestrict();

  DriveLocationRestrict.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
      };
}

/// Drive mime-type search restricts (e.g. "type:pdf").
class DriveMimeTypeRestrict {
  ///
  /// Possible string values are:
  /// - "UNSPECIFIED"
  /// - "PDF"
  /// - "DOCUMENT"
  /// - "PRESENTATION"
  /// - "SPREADSHEET"
  /// - "FORM"
  /// - "DRAWING"
  /// - "SCRIPT"
  /// - "MAP"
  /// - "IMAGE"
  /// - "AUDIO"
  /// - "VIDEO"
  /// - "FOLDER"
  /// - "ARCHIVE"
  /// - "SITE"
  core.String? type;

  DriveMimeTypeRestrict();

  DriveMimeTypeRestrict.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
      };
}

/// The time span search restrict (e.g. "after:2017-09-11 before:2017-09-12").
class DriveTimeSpanRestrict {
  ///
  /// Possible string values are:
  /// - "UNSPECIFIED"
  /// - "TODAY"
  /// - "YESTERDAY"
  /// - "LAST_7_DAYS"
  /// - "LAST_30_DAYS" : Not Enabled
  /// - "LAST_90_DAYS" : Not Enabled
  core.String? type;

  DriveTimeSpanRestrict();

  DriveTimeSpanRestrict.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
      };
}

/// A person's email address.
class EmailAddress {
  /// The email address.
  core.String? emailAddress;

  EmailAddress();

  EmailAddress.fromJson(core.Map _json) {
    if (_json.containsKey('emailAddress')) {
      emailAddress = _json['emailAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (emailAddress != null) 'emailAddress': emailAddress!,
      };
}

/// Used to provide a search operator for enum properties.
///
/// This is optional. Search operators let users restrict the query to specific
/// fields relevant to the type of item being searched. For example, if you
/// provide no operator for a *priority* enum property with possible values *p0*
/// and *p1*, a query that contains the term *p0* returns items that have *p0*
/// as the value of the *priority* property, as well as any items that contain
/// the string *p0* in other fields. If you provide an operator name for the
/// enum, such as *priority*, then search users can use that operator to refine
/// results to only items that have *p0* as this property's value, with the
/// query *priority:p0*.
class EnumOperatorOptions {
  /// Indicates the operator name required in the query in order to isolate the
  /// enum property.
  ///
  /// For example, if operatorName is *priority* and the property's name is
  /// *priorityVal*, then queries like *priority:<value>* show results only
  /// where the value of the property named *priorityVal* matches *<value>*. By
  /// contrast, a search that uses the same *<value>* without an operator
  /// returns all items where *<value>* matches the value of any String
  /// properties or text within the content field for the item. The operator
  /// name can only contain lowercase letters (a-z). The maximum length is 32
  /// characters.
  core.String? operatorName;

  EnumOperatorOptions();

  EnumOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for enum properties, which allow you to define a restricted set of
/// strings to match user queries, set rankings for those string values, and
/// define an operator name to be paired with those strings so that users can
/// narrow results to only items with a specific value.
///
/// For example, for items in a request tracking system with priority
/// information, you could define *p0* as an allowable enum value and tie this
/// enum to the operator name *priority* so that search users could add
/// *priority:p0* to their query to restrict the set of results to only those
/// items indexed with the value *p0*.
class EnumPropertyOptions {
  /// If set, describes how the enum should be used as a search operator.
  EnumOperatorOptions? operatorOptions;

  /// Used to specify the ordered ranking for the enumeration that determines
  /// how the integer values provided in the possible EnumValuePairs are used to
  /// rank results.
  ///
  /// If specified, integer values must be provided for all possible
  /// EnumValuePair values given for this property. Can only be used if
  /// isRepeatable is false.
  /// Possible string values are:
  /// - "NO_ORDER" : There is no ranking order for the property. Results aren't
  /// adjusted by this property's value.
  /// - "ASCENDING" : This property is ranked in ascending order. Lower values
  /// indicate lower ranking.
  /// - "DESCENDING" : This property is ranked in descending order. Lower values
  /// indicate higher ranking.
  core.String? orderedRanking;

  /// The list of possible values for the enumeration property.
  ///
  /// All EnumValuePairs must provide a string value. If you specify an integer
  /// value for one EnumValuePair, then all possible EnumValuePairs must provide
  /// an integer value. Both the string value and integer value must be unique
  /// over all possible values. Once set, possible values cannot be removed or
  /// modified. If you supply an ordered ranking and think you might insert
  /// additional enum values in the future, leave gaps in the initial integer
  /// values to allow adding a value in between previously registered values.
  /// The maximum number of elements is 100.
  core.List<EnumValuePair>? possibleValues;

  EnumPropertyOptions();

  EnumPropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = EnumOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('orderedRanking')) {
      orderedRanking = _json['orderedRanking'] as core.String;
    }
    if (_json.containsKey('possibleValues')) {
      possibleValues = (_json['possibleValues'] as core.List)
          .map<EnumValuePair>((value) => EnumValuePair.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
        if (orderedRanking != null) 'orderedRanking': orderedRanking!,
        if (possibleValues != null)
          'possibleValues':
              possibleValues!.map((value) => value.toJson()).toList(),
      };
}

/// The enumeration value pair defines two things: a required string value and
/// an optional integer value.
///
/// The string value defines the necessary query term required to retrieve that
/// item, such as *p0* for a priority item. The integer value determines the
/// ranking of that string value relative to other enumerated values for the
/// same property. For example, you might associate *p0* with *0* and define
/// another enum pair such as *p1* and *1*. You must use the integer value in
/// combination with ordered ranking to set the ranking of a given value
/// relative to other enumerated values for the same property name. Here, a
/// ranking order of DESCENDING for *priority* properties results in a ranking
/// boost for items indexed with a value of *p0* compared to items indexed with
/// a value of *p1*. Without a specified ranking order, the integer value has no
/// effect on item ranking.
class EnumValuePair {
  /// The integer value of the EnumValuePair which must be non-negative.
  ///
  /// Optional.
  core.int? integerValue;

  /// The string value of the EnumValuePair.
  ///
  /// The maximum length is 32 characters.
  core.String? stringValue;

  EnumValuePair();

  EnumValuePair.fromJson(core.Map _json) {
    if (_json.containsKey('integerValue')) {
      integerValue = _json['integerValue'] as core.int;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (integerValue != null) 'integerValue': integerValue!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// List of enum values.
class EnumValues {
  /// The maximum allowable length for string values is 32 characters.
  core.List<core.String>? values;

  EnumValues();

  EnumValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null) 'values': values!,
      };
}

/// Error information about the response.
class ErrorInfo {
  core.List<ErrorMessage>? errorMessages;

  ErrorInfo();

  ErrorInfo.fromJson(core.Map _json) {
    if (_json.containsKey('errorMessages')) {
      errorMessages = (_json['errorMessages'] as core.List)
          .map<ErrorMessage>((value) => ErrorMessage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorMessages != null)
          'errorMessages':
              errorMessages!.map((value) => value.toJson()).toList(),
      };
}

/// Error message per source response.
class ErrorMessage {
  core.String? errorMessage;
  Source? source;

  ErrorMessage();

  ErrorMessage.fromJson(core.Map _json) {
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// A bucket in a facet is the basic unit of operation.
///
/// A bucket can comprise either a single value OR a contiguous range of values,
/// depending on the type of the field bucketed. FacetBucket is currently used
/// only for returning the response object.
class FacetBucket {
  /// Number of results that match the bucket value.
  ///
  /// Counts are only returned for searches when count accuracy is ensured. Can
  /// be empty.
  core.int? count;

  /// Percent of results that match the bucket value.
  ///
  /// The returned value is between (0-100\], and is rounded down to an integer
  /// if fractional. If the value is not explicitly returned, it represents a
  /// percentage value that rounds to 0. Percentages are returned for all
  /// searches, but are an estimate. Because percentages are always returned,
  /// you should render percentages instead of counts.
  core.int? percentage;
  Value? value;

  FacetBucket();

  FacetBucket.fromJson(core.Map _json) {
    if (_json.containsKey('count')) {
      count = _json['count'] as core.int;
    }
    if (_json.containsKey('percentage')) {
      percentage = _json['percentage'] as core.int;
    }
    if (_json.containsKey('value')) {
      value =
          Value.fromJson(_json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (count != null) 'count': count!,
        if (percentage != null) 'percentage': percentage!,
        if (value != null) 'value': value!.toJson(),
      };
}

/// Specifies operators to return facet results for.
///
/// There will be one FacetResult for every
/// source_name/object_type/operator_name combination.
class FacetOptions {
  /// Maximum number of facet buckets that should be returned for this facet.
  ///
  /// Defaults to 10. Maximum value is 100.
  core.int? numFacetBuckets;

  /// If object_type is set, only those objects of that type will be used to
  /// compute facets.
  ///
  /// If empty, then all objects will be used to compute facets.
  core.String? objectType;

  /// Name of the operator chosen for faceting.
  ///
  /// @see cloudsearch.SchemaPropertyOptions
  core.String? operatorName;

  /// Source name to facet on.
  ///
  /// Format: datasources/{source_id} If empty, all data sources will be used.
  core.String? sourceName;

  FacetOptions();

  FacetOptions.fromJson(core.Map _json) {
    if (_json.containsKey('numFacetBuckets')) {
      numFacetBuckets = _json['numFacetBuckets'] as core.int;
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
    if (_json.containsKey('sourceName')) {
      sourceName = _json['sourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (numFacetBuckets != null) 'numFacetBuckets': numFacetBuckets!,
        if (objectType != null) 'objectType': objectType!,
        if (operatorName != null) 'operatorName': operatorName!,
        if (sourceName != null) 'sourceName': sourceName!,
      };
}

/// Source specific facet response
class FacetResult {
  /// FacetBuckets for values in response containing at least a single result.
  core.List<FacetBucket>? buckets;

  /// Object type for which facet results are returned.
  ///
  /// Can be empty.
  core.String? objectType;

  /// Name of the operator chosen for faceting.
  ///
  /// @see cloudsearch.SchemaPropertyOptions
  core.String? operatorName;

  /// Source name for which facet results are returned.
  ///
  /// Will not be empty.
  core.String? sourceName;

  FacetResult();

  FacetResult.fromJson(core.Map _json) {
    if (_json.containsKey('buckets')) {
      buckets = (_json['buckets'] as core.List)
          .map<FacetBucket>((value) => FacetBucket.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
    if (_json.containsKey('sourceName')) {
      sourceName = _json['sourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buckets != null)
          'buckets': buckets!.map((value) => value.toJson()).toList(),
        if (objectType != null) 'objectType': objectType!,
        if (operatorName != null) 'operatorName': operatorName!,
        if (sourceName != null) 'sourceName': sourceName!,
      };
}

class FieldViolation {
  /// Description of the error.
  core.String? description;

  /// Path of field with violation.
  core.String? field;

  FieldViolation();

  FieldViolation.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('field')) {
      field = _json['field'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (field != null) 'field': field!,
      };
}

/// A generic way of expressing filters in a query, which supports two
/// approaches: **1.
///
/// Setting a ValueFilter.** The name must match an operator_name defined in the
/// schema for your data source. **2. Setting a CompositeFilter.** The filters
/// are evaluated using the logical operator. The top-level operators can only
/// be either an AND or a NOT. AND can appear only at the top-most level. OR can
/// appear only under a top-level AND.
class Filter {
  CompositeFilter? compositeFilter;
  ValueFilter? valueFilter;

  Filter();

  Filter.fromJson(core.Map _json) {
    if (_json.containsKey('compositeFilter')) {
      compositeFilter = CompositeFilter.fromJson(
          _json['compositeFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('valueFilter')) {
      valueFilter = ValueFilter.fromJson(
          _json['valueFilter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compositeFilter != null)
          'compositeFilter': compositeFilter!.toJson(),
        if (valueFilter != null) 'valueFilter': valueFilter!.toJson(),
      };
}

/// Filter options to be applied on query.
class FilterOptions {
  /// Generic filter to restrict the search, such as `lang:en`, `site:xyz`.
  Filter? filter;

  /// If object_type is set, only objects of that type are returned.
  ///
  /// This should correspond to the name of the object that was registered
  /// within the definition of schema. The maximum length is 256 characters.
  core.String? objectType;

  FilterOptions();

  FilterOptions.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = Filter.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!.toJson(),
        if (objectType != null) 'objectType': objectType!,
      };
}

/// Indicates which freshness property to use when adjusting search ranking for
/// an item.
///
/// Fresher, more recent dates indicate higher quality. Use the freshness option
/// property that best works with your data. For fileshare documents, last
/// modified time is most relevant. For calendar event data, the time when the
/// event occurs is a more relevant freshness indicator. In this way, calendar
/// events that occur closer to the time of the search query are considered
/// higher quality and ranked accordingly.
class FreshnessOptions {
  /// The duration after which an object should be considered stale.
  ///
  /// The default value is 180 days (in seconds).
  core.String? freshnessDuration;

  /// This property indicates the freshness level of the object in the index.
  ///
  /// If set, this property must be a top-level property within the property
  /// definitions and it must be a timestamp type or date type. Otherwise, the
  /// Indexing API uses updateTime as the freshness indicator. The maximum
  /// length is 256 characters. When a property is used to calculate freshness,
  /// the value defaults to 2 years from the current time.
  core.String? freshnessProperty;

  FreshnessOptions();

  FreshnessOptions.fromJson(core.Map _json) {
    if (_json.containsKey('freshnessDuration')) {
      freshnessDuration = _json['freshnessDuration'] as core.String;
    }
    if (_json.containsKey('freshnessProperty')) {
      freshnessProperty = _json['freshnessProperty'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (freshnessDuration != null) 'freshnessDuration': freshnessDuration!,
        if (freshnessProperty != null) 'freshnessProperty': freshnessProperty!,
      };
}

class GSuitePrincipal {
  /// This principal represents all users of the G Suite domain of the customer.
  core.bool? gsuiteDomain;

  /// This principal references a G Suite group account
  core.String? gsuiteGroupEmail;

  /// This principal references a G Suite user account
  core.String? gsuiteUserEmail;

  GSuitePrincipal();

  GSuitePrincipal.fromJson(core.Map _json) {
    if (_json.containsKey('gsuiteDomain')) {
      gsuiteDomain = _json['gsuiteDomain'] as core.bool;
    }
    if (_json.containsKey('gsuiteGroupEmail')) {
      gsuiteGroupEmail = _json['gsuiteGroupEmail'] as core.String;
    }
    if (_json.containsKey('gsuiteUserEmail')) {
      gsuiteUserEmail = _json['gsuiteUserEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gsuiteDomain != null) 'gsuiteDomain': gsuiteDomain!,
        if (gsuiteGroupEmail != null) 'gsuiteGroupEmail': gsuiteGroupEmail!,
        if (gsuiteUserEmail != null) 'gsuiteUserEmail': gsuiteUserEmail!,
      };
}

class GetCustomerIndexStatsResponse {
  /// Summary of indexed item counts, one for each day in the requested range.
  core.List<CustomerIndexStats>? stats;

  GetCustomerIndexStatsResponse();

  GetCustomerIndexStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<CustomerIndexStats>((value) => CustomerIndexStats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

class GetCustomerQueryStatsResponse {
  core.List<CustomerQueryStats>? stats;

  GetCustomerQueryStatsResponse();

  GetCustomerQueryStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<CustomerQueryStats>((value) => CustomerQueryStats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

class GetCustomerSessionStatsResponse {
  core.List<CustomerSessionStats>? stats;

  GetCustomerSessionStatsResponse();

  GetCustomerSessionStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<CustomerSessionStats>((value) => CustomerSessionStats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

class GetCustomerUserStatsResponse {
  core.List<CustomerUserStats>? stats;

  GetCustomerUserStatsResponse();

  GetCustomerUserStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<CustomerUserStats>((value) => CustomerUserStats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

class GetDataSourceIndexStatsResponse {
  /// Summary of indexed item counts, one for each day in the requested range.
  core.List<DataSourceIndexStats>? stats;

  GetDataSourceIndexStatsResponse();

  GetDataSourceIndexStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<DataSourceIndexStats>((value) => DataSourceIndexStats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

class GetSearchApplicationQueryStatsResponse {
  core.List<SearchApplicationQueryStats>? stats;

  GetSearchApplicationQueryStatsResponse();

  GetSearchApplicationQueryStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<SearchApplicationQueryStats>((value) =>
              SearchApplicationQueryStats.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

class GetSearchApplicationSessionStatsResponse {
  core.List<SearchApplicationSessionStats>? stats;

  GetSearchApplicationSessionStatsResponse();

  GetSearchApplicationSessionStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<SearchApplicationSessionStats>((value) =>
              SearchApplicationSessionStats.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

class GetSearchApplicationUserStatsResponse {
  core.List<SearchApplicationUserStats>? stats;

  GetSearchApplicationUserStatsResponse();

  GetSearchApplicationUserStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('stats')) {
      stats = (_json['stats'] as core.List)
          .map<SearchApplicationUserStats>((value) =>
              SearchApplicationUserStats.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stats != null)
          'stats': stats!.map((value) => value.toJson()).toList(),
      };
}

/// Used to provide a search operator for html properties.
///
/// This is optional. Search operators let users restrict the query to specific
/// fields relevant to the type of item being searched.
class HtmlOperatorOptions {
  /// Indicates the operator name required in the query in order to isolate the
  /// html property.
  ///
  /// For example, if operatorName is *subject* and the property's name is
  /// *subjectLine*, then queries like *subject:<value>* show results only where
  /// the value of the property named *subjectLine* matches *<value>*. By
  /// contrast, a search that uses the same *<value>* without an operator return
  /// all items where *<value>* matches the value of any html properties or text
  /// within the content field for the item. The operator name can only contain
  /// lowercase letters (a-z). The maximum length is 32 characters.
  core.String? operatorName;

  HtmlOperatorOptions();

  HtmlOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for html properties.
class HtmlPropertyOptions {
  /// If set, describes how the property should be used as a search operator.
  HtmlOperatorOptions? operatorOptions;

  /// Indicates the search quality importance of the tokens within the field
  /// when used for retrieval.
  ///
  /// Can only be set to DEFAULT or NONE.
  RetrievalImportance? retrievalImportance;

  HtmlPropertyOptions();

  HtmlPropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = HtmlOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('retrievalImportance')) {
      retrievalImportance = RetrievalImportance.fromJson(
          _json['retrievalImportance'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
        if (retrievalImportance != null)
          'retrievalImportance': retrievalImportance!.toJson(),
      };
}

/// List of html values.
class HtmlValues {
  /// The maximum allowable length for html values is 2048 characters.
  core.List<core.String>? values;

  HtmlValues();

  HtmlValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null) 'values': values!,
      };
}

class IndexItemOptions {
  /// Specifies if the index request should allow gsuite principals that do not
  /// exist or are deleted in the index request.
  core.bool? allowUnknownGsuitePrincipals;

  IndexItemOptions();

  IndexItemOptions.fromJson(core.Map _json) {
    if (_json.containsKey('allowUnknownGsuitePrincipals')) {
      allowUnknownGsuitePrincipals =
          _json['allowUnknownGsuitePrincipals'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowUnknownGsuitePrincipals != null)
          'allowUnknownGsuitePrincipals': allowUnknownGsuitePrincipals!,
      };
}

class IndexItemRequest {
  /// Name of connector making this call.
  ///
  /// Format: datasources/{source_id}/connectors/{ID}
  core.String? connectorName;

  /// Common debug options.
  DebugOptions? debugOptions;
  IndexItemOptions? indexItemOptions;

  /// Name of the item.
  ///
  /// Format: datasources/{source_id}/items/{item_id}
  Item? item;

  /// The RequestMode for this request.
  ///
  /// Required.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Priority is not specified in the update request. Leaving
  /// priority unspecified results in an update failure.
  /// - "SYNCHRONOUS" : For real-time updates.
  /// - "ASYNCHRONOUS" : For changes that are executed after the response is
  /// sent back to the caller.
  core.String? mode;

  IndexItemRequest();

  IndexItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('connectorName')) {
      connectorName = _json['connectorName'] as core.String;
    }
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('indexItemOptions')) {
      indexItemOptions = IndexItemOptions.fromJson(
          _json['indexItemOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('item')) {
      item =
          Item.fromJson(_json['item'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectorName != null) 'connectorName': connectorName!,
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (indexItemOptions != null)
          'indexItemOptions': indexItemOptions!.toJson(),
        if (item != null) 'item': item!.toJson(),
        if (mode != null) 'mode': mode!,
      };
}

/// Used to provide a search operator for integer properties.
///
/// This is optional. Search operators let users restrict the query to specific
/// fields relevant to the type of item being searched.
class IntegerOperatorOptions {
  /// Indicates the operator name required in the query in order to isolate the
  /// integer property using the greater-than operator.
  ///
  /// For example, if greaterThanOperatorName is *priorityabove* and the
  /// property's name is *priorityVal*, then queries like
  /// *priorityabove:<value>* show results only where the value of the property
  /// named *priorityVal* is greater than *<value>*. The operator name can only
  /// contain lowercase letters (a-z). The maximum length is 32 characters.
  core.String? greaterThanOperatorName;

  /// Indicates the operator name required in the query in order to isolate the
  /// integer property using the less-than operator.
  ///
  /// For example, if lessThanOperatorName is *prioritybelow* and the property's
  /// name is *priorityVal*, then queries like *prioritybelow:<value>* show
  /// results only where the value of the property named *priorityVal* is less
  /// than *<value>*. The operator name can only contain lowercase letters
  /// (a-z). The maximum length is 32 characters.
  core.String? lessThanOperatorName;

  /// Indicates the operator name required in the query in order to isolate the
  /// integer property.
  ///
  /// For example, if operatorName is *priority* and the property's name is
  /// *priorityVal*, then queries like *priority:<value>* show results only
  /// where the value of the property named *priorityVal* matches *<value>*. By
  /// contrast, a search that uses the same *<value>* without an operator
  /// returns all items where *<value>* matches the value of any String
  /// properties or text within the content field for the item. The operator
  /// name can only contain lowercase letters (a-z). The maximum length is 32
  /// characters.
  core.String? operatorName;

  IntegerOperatorOptions();

  IntegerOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('greaterThanOperatorName')) {
      greaterThanOperatorName = _json['greaterThanOperatorName'] as core.String;
    }
    if (_json.containsKey('lessThanOperatorName')) {
      lessThanOperatorName = _json['lessThanOperatorName'] as core.String;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (greaterThanOperatorName != null)
          'greaterThanOperatorName': greaterThanOperatorName!,
        if (lessThanOperatorName != null)
          'lessThanOperatorName': lessThanOperatorName!,
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for integer properties.
class IntegerPropertyOptions {
  /// The maximum value of the property.
  ///
  /// The minimum and maximum values for the property are used to rank results
  /// according to the ordered ranking. Indexing requests with values greater
  /// than the maximum are accepted and ranked with the same weight as items
  /// indexed with the maximum value.
  core.String? maximumValue;

  /// The minimum value of the property.
  ///
  /// The minimum and maximum values for the property are used to rank results
  /// according to the ordered ranking. Indexing requests with values less than
  /// the minimum are accepted and ranked with the same weight as items indexed
  /// with the minimum value.
  core.String? minimumValue;

  /// If set, describes how the integer should be used as a search operator.
  IntegerOperatorOptions? operatorOptions;

  /// Used to specify the ordered ranking for the integer.
  ///
  /// Can only be used if isRepeatable is false.
  /// Possible string values are:
  /// - "NO_ORDER" : There is no ranking order for the property. Results are not
  /// adjusted by this property's value.
  /// - "ASCENDING" : This property is ranked in ascending order. Lower values
  /// indicate lower ranking.
  /// - "DESCENDING" : This property is ranked in descending order. Lower values
  /// indicate higher ranking.
  core.String? orderedRanking;

  IntegerPropertyOptions();

  IntegerPropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('maximumValue')) {
      maximumValue = _json['maximumValue'] as core.String;
    }
    if (_json.containsKey('minimumValue')) {
      minimumValue = _json['minimumValue'] as core.String;
    }
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = IntegerOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('orderedRanking')) {
      orderedRanking = _json['orderedRanking'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maximumValue != null) 'maximumValue': maximumValue!,
        if (minimumValue != null) 'minimumValue': minimumValue!,
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
        if (orderedRanking != null) 'orderedRanking': orderedRanking!,
      };
}

/// List of integer values.
class IntegerValues {
  core.List<core.String>? values;

  IntegerValues();

  IntegerValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null) 'values': values!,
      };
}

/// Represents an interaction between a user and an item.
class Interaction {
  /// The time when the user acted on the item.
  ///
  /// If multiple actions of the same type exist for a single user, only the
  /// most recent action is recorded.
  core.String? interactionTime;

  /// The user that acted on the item.
  Principal? principal;

  ///
  /// Possible string values are:
  /// - "UNSPECIFIED" : Invalid value.
  /// - "VIEW" : This interaction indicates the user viewed the item.
  /// - "EDIT" : This interaction indicates the user edited the item.
  core.String? type;

  Interaction();

  Interaction.fromJson(core.Map _json) {
    if (_json.containsKey('interactionTime')) {
      interactionTime = _json['interactionTime'] as core.String;
    }
    if (_json.containsKey('principal')) {
      principal = Principal.fromJson(
          _json['principal'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (interactionTime != null) 'interactionTime': interactionTime!,
        if (principal != null) 'principal': principal!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Represents a single object that is an item in the search index, such as a
/// file, folder, or a database record.
class Item {
  /// Access control list for this item.
  ItemAcl? acl;

  /// Item content to be indexed and made text searchable.
  ItemContent? content;

  /// Type for this item.
  /// Possible string values are:
  /// - "UNSPECIFIED"
  /// - "CONTENT_ITEM" : An item that is indexed for the only purpose of serving
  /// information. These items cannot be referred in containerName or
  /// inheritAclFrom fields.
  /// - "CONTAINER_ITEM" : An item that gets indexed and whose purpose is to
  /// supply other items with ACLs and/or contain other items.
  /// - "VIRTUAL_CONTAINER_ITEM" : An item that does not get indexed, but
  /// otherwise has the same purpose as CONTAINER_ITEM.
  core.String? itemType;

  /// Metadata information.
  ItemMetadata? metadata;

  /// Name of the Item.
  ///
  /// Format: datasources/{source_id}/items/{item_id} This is a required field.
  /// The maximum length is 1536 characters.
  core.String? name;

  /// Additional state connector can store for this item.
  ///
  /// The maximum length is 10000 bytes.
  core.String? payload;
  core.List<core.int> get payloadAsBytes => convert.base64.decode(payload!);

  set payloadAsBytes(core.List<core.int> _bytes) {
    payload =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Queue this item belongs to.
  ///
  /// The maximum length is 100 characters.
  core.String? queue;

  /// Status of the item.
  ///
  /// Output only field.
  ItemStatus? status;

  /// The structured data for the item that should conform to a registered
  /// object definition in the schema for the data source.
  ItemStructuredData? structuredData;

  /// The indexing system stores the version from the datasource as a byte
  /// string and compares the Item version in the index to the version of the
  /// queued Item using lexical ordering.
  ///
  /// Cloud Search Indexing won't index or delete any queued item with a version
  /// value that is less than or equal to the version of the currently indexed
  /// item. The maximum length for this field is 1024 bytes.
  ///
  /// Required.
  core.String? version;
  core.List<core.int> get versionAsBytes => convert.base64.decode(version!);

  set versionAsBytes(core.List<core.int> _bytes) {
    version =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  Item();

  Item.fromJson(core.Map _json) {
    if (_json.containsKey('acl')) {
      acl =
          ItemAcl.fromJson(_json['acl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('content')) {
      content = ItemContent.fromJson(
          _json['content'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('itemType')) {
      itemType = _json['itemType'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = ItemMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('payload')) {
      payload = _json['payload'] as core.String;
    }
    if (_json.containsKey('queue')) {
      queue = _json['queue'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = ItemStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('structuredData')) {
      structuredData = ItemStructuredData.fromJson(
          _json['structuredData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acl != null) 'acl': acl!.toJson(),
        if (content != null) 'content': content!.toJson(),
        if (itemType != null) 'itemType': itemType!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (name != null) 'name': name!,
        if (payload != null) 'payload': payload!,
        if (queue != null) 'queue': queue!,
        if (status != null) 'status': status!.toJson(),
        if (structuredData != null) 'structuredData': structuredData!.toJson(),
        if (version != null) 'version': version!,
      };
}

/// Access control list information for the item.
///
/// For more information see \[Map ACLs\](/cloud-search/docs/guides/acls).
class ItemAcl {
  /// Sets the type of access rules to apply when an item inherits its ACL from
  /// a parent.
  ///
  /// This should always be set in tandem with the inheritAclFrom field. Also,
  /// when the inheritAclFrom field is set, this field should be set to a valid
  /// AclInheritanceType.
  /// Possible string values are:
  /// - "NOT_APPLICABLE" : The default value when this item does not inherit an
  /// ACL. Use NOT_APPLICABLE when inheritAclFrom is empty. An item without ACL
  /// inheritance can still have ACLs supplied by its own readers and
  /// deniedReaders fields.
  /// - "CHILD_OVERRIDE" : During an authorization conflict, the ACL of the
  /// child item determines its read access.
  /// - "PARENT_OVERRIDE" : During an authorization conflict, the ACL of the
  /// parent item specified in the inheritAclFrom field determines read access.
  /// - "BOTH_PERMIT" : Access is granted only if this item and the parent item
  /// specified in the inheritAclFrom field both permit read access.
  core.String? aclInheritanceType;

  /// List of principals who are explicitly denied access to the item in search
  /// results.
  ///
  /// While principals are denied access by default, use denied readers to
  /// handle exceptions and override the list allowed readers. The maximum
  /// number of elements is 100.
  core.List<Principal>? deniedReaders;

  /// Name of the item to inherit the Access Permission List (ACL) from.
  ///
  /// Note: ACL inheritance *only* provides access permissions to child items
  /// and does not define structural relationships, nor does it provide
  /// convenient ways to delete large groups of items. Deleting an ACL parent
  /// from the index only alters the access permissions of child items that
  /// reference the parent in the inheritAclFrom field. The item is still in the
  /// index, but may not visible in search results. By contrast, deletion of a
  /// container item also deletes all items that reference the container via the
  /// containerName field. The maximum length for this field is 1536 characters.
  core.String? inheritAclFrom;

  /// List of owners for the item.
  ///
  /// This field has no bearing on document access permissions. It does,
  /// however, offer a slight ranking boosts items where the querying user is an
  /// owner. The maximum number of elements is 5.
  ///
  /// Optional.
  core.List<Principal>? owners;

  /// List of principals who are allowed to see the item in search results.
  ///
  /// Optional if inheriting permissions from another item or if the item is not
  /// intended to be visible, such as virtual containers. The maximum number of
  /// elements is 1000.
  core.List<Principal>? readers;

  ItemAcl();

  ItemAcl.fromJson(core.Map _json) {
    if (_json.containsKey('aclInheritanceType')) {
      aclInheritanceType = _json['aclInheritanceType'] as core.String;
    }
    if (_json.containsKey('deniedReaders')) {
      deniedReaders = (_json['deniedReaders'] as core.List)
          .map<Principal>((value) =>
              Principal.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inheritAclFrom')) {
      inheritAclFrom = _json['inheritAclFrom'] as core.String;
    }
    if (_json.containsKey('owners')) {
      owners = (_json['owners'] as core.List)
          .map<Principal>((value) =>
              Principal.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('readers')) {
      readers = (_json['readers'] as core.List)
          .map<Principal>((value) =>
              Principal.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aclInheritanceType != null)
          'aclInheritanceType': aclInheritanceType!,
        if (deniedReaders != null)
          'deniedReaders':
              deniedReaders!.map((value) => value.toJson()).toList(),
        if (inheritAclFrom != null) 'inheritAclFrom': inheritAclFrom!,
        if (owners != null)
          'owners': owners!.map((value) => value.toJson()).toList(),
        if (readers != null)
          'readers': readers!.map((value) => value.toJson()).toList(),
      };
}

/// Content of an item to be indexed and surfaced by Cloud Search.
///
/// Only UTF-8 encoded strings are allowed as inlineContent. If the content is
/// uploaded and not binary, it must be UTF-8 encoded.
class ItemContent {
  /// Upload reference ID of a previously uploaded content via write method.
  UploadItemRef? contentDataRef;

  ///
  /// Possible string values are:
  /// - "UNSPECIFIED" : Invalid value.
  /// - "HTML" : contentFormat is HTML.
  /// - "TEXT" : contentFormat is free text.
  /// - "RAW" : contentFormat is raw bytes.
  core.String? contentFormat;

  /// Hashing info calculated and provided by the API client for content.
  ///
  /// Can be used with the items.push method to calculate modified state. The
  /// maximum length is 2048 characters.
  core.String? hash;

  /// Content that is supplied inlined within the update method.
  ///
  /// The maximum length is 102400 bytes (100 KiB).
  core.String? inlineContent;
  core.List<core.int> get inlineContentAsBytes =>
      convert.base64.decode(inlineContent!);

  set inlineContentAsBytes(core.List<core.int> _bytes) {
    inlineContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  ItemContent();

  ItemContent.fromJson(core.Map _json) {
    if (_json.containsKey('contentDataRef')) {
      contentDataRef = UploadItemRef.fromJson(
          _json['contentDataRef'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentFormat')) {
      contentFormat = _json['contentFormat'] as core.String;
    }
    if (_json.containsKey('hash')) {
      hash = _json['hash'] as core.String;
    }
    if (_json.containsKey('inlineContent')) {
      inlineContent = _json['inlineContent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentDataRef != null) 'contentDataRef': contentDataRef!.toJson(),
        if (contentFormat != null) 'contentFormat': contentFormat!,
        if (hash != null) 'hash': hash!,
        if (inlineContent != null) 'inlineContent': inlineContent!,
      };
}

class ItemCountByStatus {
  /// Number of items matching the status code.
  core.String? count;

  /// Status of the items.
  /// Possible string values are:
  /// - "CODE_UNSPECIFIED" : Input-only value. Used with Items.list to list all
  /// items in the queue, regardless of status.
  /// - "ERROR" : Error encountered by Cloud Search while processing this item.
  /// Details of the error are in repositoryError.
  /// - "MODIFIED" : Item has been modified in the repository, and is out of
  /// date with the version previously accepted into Cloud Search.
  /// - "NEW_ITEM" : Item is known to exist in the repository, but is not yet
  /// accepted by Cloud Search. An item can be in this state when Items.push has
  /// been called for an item of this name that did not exist previously.
  /// - "ACCEPTED" : API has accepted the up-to-date data of this item.
  core.String? statusCode;

  ItemCountByStatus();

  ItemCountByStatus.fromJson(core.Map _json) {
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
    if (_json.containsKey('statusCode')) {
      statusCode = _json['statusCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (count != null) 'count': count!,
        if (statusCode != null) 'statusCode': statusCode!,
      };
}

/// Available metadata fields for the item.
class ItemMetadata {
  /// The name of the container for this item.
  ///
  /// Deletion of the container item leads to automatic deletion of this item.
  /// Note: ACLs are not inherited from a container item. To provide ACL
  /// inheritance for an item, use the inheritAclFrom field. The maximum length
  /// is 1536 characters.
  core.String? containerName;

  /// The BCP-47 language code for the item, such as "en-US" or "sr-Latn".
  ///
  /// For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier. The
  /// maximum length is 32 characters.
  core.String? contentLanguage;

  /// A set of named attributes associated with the item.
  ///
  /// This can be used for influencing the ranking of the item based on the
  /// context in the request. The maximum number of elements is 10.
  core.List<ContextAttribute>? contextAttributes;

  /// The time when the item was created in the source repository.
  core.String? createTime;

  /// Hashing value provided by the API caller.
  ///
  /// This can be used with the items.push method to calculate modified state.
  /// The maximum length is 2048 characters.
  core.String? hash;

  /// A list of interactions for the item.
  ///
  /// Interactions are used to improve Search quality, but are not exposed to
  /// end users. The maximum number of elements is 1000.
  core.List<Interaction>? interactions;

  /// Additional keywords or phrases that should match the item.
  ///
  /// Used internally for user generated content. The maximum number of elements
  /// is 100. The maximum length is 8192 characters.
  core.List<core.String>? keywords;

  /// The original mime-type of ItemContent.content in the source repository.
  ///
  /// The maximum length is 256 characters.
  core.String? mimeType;

  /// The type of the item.
  ///
  /// This should correspond to the name of an object definition in the schema
  /// registered for the data source. For example, if the schema for the data
  /// source contains an object definition with name 'document', then item
  /// indexing requests for objects of that type should set objectType to
  /// 'document'. The maximum length is 256 characters.
  core.String? objectType;

  /// Additional search quality metadata of the item
  SearchQualityMetadata? searchQualityMetadata;

  /// Link to the source repository serving the data.
  ///
  /// Search results apply this link to the title. Whitespace or special
  /// characters may cause Cloud Search result links to trigger a redirect
  /// notice; to avoid this, encode the URL. The maximum length is 2048
  /// characters.
  core.String? sourceRepositoryUrl;

  /// The title of the item.
  ///
  /// If given, this will be the displayed title of the Search result. The
  /// maximum length is 2048 characters.
  core.String? title;

  /// The time when the item was last modified in the source repository.
  core.String? updateTime;

  ItemMetadata();

  ItemMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('containerName')) {
      containerName = _json['containerName'] as core.String;
    }
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('contextAttributes')) {
      contextAttributes = (_json['contextAttributes'] as core.List)
          .map<ContextAttribute>((value) => ContextAttribute.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('hash')) {
      hash = _json['hash'] as core.String;
    }
    if (_json.containsKey('interactions')) {
      interactions = (_json['interactions'] as core.List)
          .map<Interaction>((value) => Interaction.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('keywords')) {
      keywords = (_json['keywords'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
    if (_json.containsKey('searchQualityMetadata')) {
      searchQualityMetadata = SearchQualityMetadata.fromJson(
          _json['searchQualityMetadata']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceRepositoryUrl')) {
      sourceRepositoryUrl = _json['sourceRepositoryUrl'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containerName != null) 'containerName': containerName!,
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (contextAttributes != null)
          'contextAttributes':
              contextAttributes!.map((value) => value.toJson()).toList(),
        if (createTime != null) 'createTime': createTime!,
        if (hash != null) 'hash': hash!,
        if (interactions != null)
          'interactions': interactions!.map((value) => value.toJson()).toList(),
        if (keywords != null) 'keywords': keywords!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (objectType != null) 'objectType': objectType!,
        if (searchQualityMetadata != null)
          'searchQualityMetadata': searchQualityMetadata!.toJson(),
        if (sourceRepositoryUrl != null)
          'sourceRepositoryUrl': sourceRepositoryUrl!,
        if (title != null) 'title': title!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// This contains item's status and any errors.
class ItemStatus {
  /// Status code.
  /// Possible string values are:
  /// - "CODE_UNSPECIFIED" : Input-only value. Used with Items.list to list all
  /// items in the queue, regardless of status.
  /// - "ERROR" : Error encountered by Cloud Search while processing this item.
  /// Details of the error are in repositoryError.
  /// - "MODIFIED" : Item has been modified in the repository, and is out of
  /// date with the version previously accepted into Cloud Search.
  /// - "NEW_ITEM" : Item is known to exist in the repository, but is not yet
  /// accepted by Cloud Search. An item can be in this state when Items.push has
  /// been called for an item of this name that did not exist previously.
  /// - "ACCEPTED" : API has accepted the up-to-date data of this item.
  core.String? code;

  /// Error details in case the item is in ERROR state.
  core.List<ProcessingError>? processingErrors;

  /// Repository error reported by connector.
  core.List<RepositoryError>? repositoryErrors;

  ItemStatus();

  ItemStatus.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('processingErrors')) {
      processingErrors = (_json['processingErrors'] as core.List)
          .map<ProcessingError>((value) => ProcessingError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('repositoryErrors')) {
      repositoryErrors = (_json['repositoryErrors'] as core.List)
          .map<RepositoryError>((value) => RepositoryError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (processingErrors != null)
          'processingErrors':
              processingErrors!.map((value) => value.toJson()).toList(),
        if (repositoryErrors != null)
          'repositoryErrors':
              repositoryErrors!.map((value) => value.toJson()).toList(),
      };
}

/// Available structured data fields for the item.
class ItemStructuredData {
  /// Hashing value provided by the API caller.
  ///
  /// This can be used with the items.push method to calculate modified state.
  /// The maximum length is 2048 characters.
  core.String? hash;

  /// The structured data object that should conform to a registered object
  /// definition in the schema for the data source.
  StructuredDataObject? object;

  ItemStructuredData();

  ItemStructuredData.fromJson(core.Map _json) {
    if (_json.containsKey('hash')) {
      hash = _json['hash'] as core.String;
    }
    if (_json.containsKey('object')) {
      object = StructuredDataObject.fromJson(
          _json['object'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hash != null) 'hash': hash!,
        if (object != null) 'object': object!.toJson(),
      };
}

class ListDataSourceResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;
  core.List<DataSource>? sources;

  ListDataSourceResponse();

  ListDataSourceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('sources')) {
      sources = (_json['sources'] as core.List)
          .map<DataSource>((value) =>
              DataSource.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (sources != null)
          'sources': sources!.map((value) => value.toJson()).toList(),
      };
}

class ListItemNamesForUnmappedIdentityResponse {
  core.List<core.String>? itemNames;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListItemNamesForUnmappedIdentityResponse();

  ListItemNamesForUnmappedIdentityResponse.fromJson(core.Map _json) {
    if (_json.containsKey('itemNames')) {
      itemNames = (_json['itemNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (itemNames != null) 'itemNames': itemNames!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListItemsResponse {
  core.List<Item>? items;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListItemsResponse();

  ListItemsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Item>((value) =>
              Item.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
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

/// List sources response.
class ListQuerySourcesResponse {
  core.String? nextPageToken;
  core.List<QuerySource>? sources;

  ListQuerySourcesResponse();

  ListQuerySourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('sources')) {
      sources = (_json['sources'] as core.List)
          .map<QuerySource>((value) => QuerySource.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (sources != null)
          'sources': sources!.map((value) => value.toJson()).toList(),
      };
}

class ListSearchApplicationsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;
  core.List<SearchApplication>? searchApplications;

  ListSearchApplicationsResponse();

  ListSearchApplicationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('searchApplications')) {
      searchApplications = (_json['searchApplications'] as core.List)
          .map<SearchApplication>((value) => SearchApplication.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (searchApplications != null)
          'searchApplications':
              searchApplications!.map((value) => value.toJson()).toList(),
      };
}

class ListUnmappedIdentitiesResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;
  core.List<UnmappedIdentity>? unmappedIdentities;

  ListUnmappedIdentitiesResponse();

  ListUnmappedIdentitiesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('unmappedIdentities')) {
      unmappedIdentities = (_json['unmappedIdentities'] as core.List)
          .map<UnmappedIdentity>((value) => UnmappedIdentity.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (unmappedIdentities != null)
          'unmappedIdentities':
              unmappedIdentities!.map((value) => value.toJson()).toList(),
      };
}

/// Matched range of a snippet \[start, end).
class MatchRange {
  /// End of the match in the snippet.
  core.int? end;

  /// Starting position of the match in the snippet.
  core.int? start;

  MatchRange();

  MatchRange.fromJson(core.Map _json) {
    if (_json.containsKey('end')) {
      end = _json['end'] as core.int;
    }
    if (_json.containsKey('start')) {
      start = _json['start'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (end != null) 'end': end!,
        if (start != null) 'start': start!,
      };
}

/// Media resource.
class Media {
  /// Name of the media resource.
  core.String? resourceName;

  Media();

  Media.fromJson(core.Map _json) {
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceName != null) 'resourceName': resourceName!,
      };
}

/// Metadata of a matched search result.
class Metadata {
  /// The creation time for this document or object in the search result.
  core.String? createTime;

  /// Options that specify how to display a structured data search result.
  ResultDisplayMetadata? displayOptions;

  /// Indexed fields in structured data, returned as a generic named property.
  core.List<NamedProperty>? fields;

  /// Mime type of the search result.
  core.String? mimeType;

  /// Object type of the search result.
  core.String? objectType;

  /// Owner (usually creator) of the document or object of the search result.
  Person? owner;

  /// The named source for the result, such as Gmail.
  Source? source;

  /// The last modified date for the object in the search result.
  ///
  /// If not set in the item, the value returned here is empty. When
  /// `updateTime` is used for calculating freshness and is not set, this value
  /// defaults to 2 years from the current time.
  core.String? updateTime;

  Metadata();

  Metadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayOptions')) {
      displayOptions = ResultDisplayMetadata.fromJson(
          _json['displayOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<NamedProperty>((value) => NamedProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
    if (_json.containsKey('owner')) {
      owner = Person.fromJson(
          _json['owner'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (displayOptions != null) 'displayOptions': displayOptions!.toJson(),
        if (fields != null)
          'fields': fields!.map((value) => value.toJson()).toList(),
        if (mimeType != null) 'mimeType': mimeType!,
        if (objectType != null) 'objectType': objectType!,
        if (owner != null) 'owner': owner!.toJson(),
        if (source != null) 'source': source!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// A metaline is a list of properties that are displayed along with the search
/// result to provide context.
class Metaline {
  /// The list of displayed properties for the metaline.
  ///
  /// The maximum number of properties is 5.
  core.List<DisplayedProperty>? properties;

  Metaline();

  Metaline.fromJson(core.Map _json) {
    if (_json.containsKey('properties')) {
      properties = (_json['properties'] as core.List)
          .map<DisplayedProperty>((value) => DisplayedProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (properties != null)
          'properties': properties!.map((value) => value.toJson()).toList(),
      };
}

/// A person's name.
class Name {
  /// The read-only display name formatted according to the locale specified by
  /// the viewer's account or the Accept-Language HTTP header.
  core.String? displayName;

  Name();

  Name.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// A typed name-value pair for structured data.
///
/// The type of the value should be the same as the registered type for the
/// `name` property in the object definition of `objectType`.
class NamedProperty {
  core.bool? booleanValue;
  DateValues? dateValues;
  DoubleValues? doubleValues;
  EnumValues? enumValues;
  HtmlValues? htmlValues;
  IntegerValues? integerValues;

  /// The name of the property.
  ///
  /// This name should correspond to the name of the property that was
  /// registered for object definition in the schema. The maximum allowable
  /// length for this property is 256 characters.
  core.String? name;
  ObjectValues? objectValues;
  TextValues? textValues;
  TimestampValues? timestampValues;

  NamedProperty();

  NamedProperty.fromJson(core.Map _json) {
    if (_json.containsKey('booleanValue')) {
      booleanValue = _json['booleanValue'] as core.bool;
    }
    if (_json.containsKey('dateValues')) {
      dateValues = DateValues.fromJson(
          _json['dateValues'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('doubleValues')) {
      doubleValues = DoubleValues.fromJson(
          _json['doubleValues'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enumValues')) {
      enumValues = EnumValues.fromJson(
          _json['enumValues'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('htmlValues')) {
      htmlValues = HtmlValues.fromJson(
          _json['htmlValues'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('integerValues')) {
      integerValues = IntegerValues.fromJson(
          _json['integerValues'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('objectValues')) {
      objectValues = ObjectValues.fromJson(
          _json['objectValues'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textValues')) {
      textValues = TextValues.fromJson(
          _json['textValues'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampValues')) {
      timestampValues = TimestampValues.fromJson(
          _json['timestampValues'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (booleanValue != null) 'booleanValue': booleanValue!,
        if (dateValues != null) 'dateValues': dateValues!.toJson(),
        if (doubleValues != null) 'doubleValues': doubleValues!.toJson(),
        if (enumValues != null) 'enumValues': enumValues!.toJson(),
        if (htmlValues != null) 'htmlValues': htmlValues!.toJson(),
        if (integerValues != null) 'integerValues': integerValues!.toJson(),
        if (name != null) 'name': name!,
        if (objectValues != null) 'objectValues': objectValues!.toJson(),
        if (textValues != null) 'textValues': textValues!.toJson(),
        if (timestampValues != null)
          'timestampValues': timestampValues!.toJson(),
      };
}

/// The definition for an object within a data source.
class ObjectDefinition {
  /// Name for the object, which then defines its type.
  ///
  /// Item indexing requests should set the objectType field equal to this
  /// value. For example, if *name* is *Document*, then indexing requests for
  /// items of type Document should set objectType equal to *Document*. Each
  /// object definition must be uniquely named within a schema. The name must
  /// start with a letter and can only contain letters (A-Z, a-z) or numbers
  /// (0-9). The maximum length is 256 characters.
  core.String? name;

  /// The optional object-specific options.
  ObjectOptions? options;

  /// The property definitions for the object.
  ///
  /// The maximum number of elements is 1000.
  core.List<PropertyDefinition>? propertyDefinitions;

  ObjectDefinition();

  ObjectDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('options')) {
      options = ObjectOptions.fromJson(
          _json['options'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('propertyDefinitions')) {
      propertyDefinitions = (_json['propertyDefinitions'] as core.List)
          .map<PropertyDefinition>((value) => PropertyDefinition.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (options != null) 'options': options!.toJson(),
        if (propertyDefinitions != null)
          'propertyDefinitions':
              propertyDefinitions!.map((value) => value.toJson()).toList(),
      };
}

/// The display options for an object.
class ObjectDisplayOptions {
  /// Defines the properties that are displayed in the metalines of the search
  /// results.
  ///
  /// The property values are displayed in the order given here. If a property
  /// holds multiple values, all of the values are displayed before the next
  /// properties. For this reason, it is a good practice to specify singular
  /// properties before repeated properties in this list. All of the properties
  /// must set is_returnable to true. The maximum number of metalines is 3.
  core.List<Metaline>? metalines;

  /// The user friendly label to display in the search result to indicate the
  /// type of the item.
  ///
  /// This is OPTIONAL; if not provided, an object label isn't displayed on the
  /// context line of the search results. The maximum length is 64 characters.
  core.String? objectDisplayLabel;

  ObjectDisplayOptions();

  ObjectDisplayOptions.fromJson(core.Map _json) {
    if (_json.containsKey('metalines')) {
      metalines = (_json['metalines'] as core.List)
          .map<Metaline>((value) =>
              Metaline.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectDisplayLabel')) {
      objectDisplayLabel = _json['objectDisplayLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metalines != null)
          'metalines': metalines!.map((value) => value.toJson()).toList(),
        if (objectDisplayLabel != null)
          'objectDisplayLabel': objectDisplayLabel!,
      };
}

/// The options for an object.
class ObjectOptions {
  /// Options that determine how the object is displayed in the Cloud Search
  /// results page.
  ObjectDisplayOptions? displayOptions;

  /// The freshness options for an object.
  FreshnessOptions? freshnessOptions;

  ObjectOptions();

  ObjectOptions.fromJson(core.Map _json) {
    if (_json.containsKey('displayOptions')) {
      displayOptions = ObjectDisplayOptions.fromJson(
          _json['displayOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('freshnessOptions')) {
      freshnessOptions = FreshnessOptions.fromJson(
          _json['freshnessOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayOptions != null) 'displayOptions': displayOptions!.toJson(),
        if (freshnessOptions != null)
          'freshnessOptions': freshnessOptions!.toJson(),
      };
}

/// Options for object properties.
class ObjectPropertyOptions {
  /// The properties of the sub-object.
  ///
  /// These properties represent a nested object. For example, if this property
  /// represents a postal address, the subobjectProperties might be named
  /// *street*, *city*, and *state*. The maximum number of elements is 1000.
  core.List<PropertyDefinition>? subobjectProperties;

  ObjectPropertyOptions();

  ObjectPropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('subobjectProperties')) {
      subobjectProperties = (_json['subobjectProperties'] as core.List)
          .map<PropertyDefinition>((value) => PropertyDefinition.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (subobjectProperties != null)
          'subobjectProperties':
              subobjectProperties!.map((value) => value.toJson()).toList(),
      };
}

/// List of object values.
class ObjectValues {
  core.List<StructuredDataObject>? values;

  ObjectValues();

  ObjectValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<StructuredDataObject>((value) => StructuredDataObject.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
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

/// This field contains information about the person being suggested.
class PeopleSuggestion {
  /// Suggested person.
  ///
  /// All fields of the person object might not be populated.
  Person? person;

  PeopleSuggestion();

  PeopleSuggestion.fromJson(core.Map _json) {
    if (_json.containsKey('person')) {
      person = Person.fromJson(
          _json['person'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (person != null) 'person': person!.toJson(),
      };
}

/// Object to represent a person.
class Person {
  /// The person's email addresses
  core.List<EmailAddress>? emailAddresses;

  /// The resource name of the person to provide information about.
  ///
  /// See People.get from Google People API.
  core.String? name;

  /// Obfuscated ID of a person.
  core.String? obfuscatedId;

  /// The person's name
  core.List<Name>? personNames;

  /// A person's read-only photo.
  ///
  /// A picture shown next to the person's name to help others recognize the
  /// person in search results.
  core.List<Photo>? photos;

  Person();

  Person.fromJson(core.Map _json) {
    if (_json.containsKey('emailAddresses')) {
      emailAddresses = (_json['emailAddresses'] as core.List)
          .map<EmailAddress>((value) => EmailAddress.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('obfuscatedId')) {
      obfuscatedId = _json['obfuscatedId'] as core.String;
    }
    if (_json.containsKey('personNames')) {
      personNames = (_json['personNames'] as core.List)
          .map<Name>((value) =>
              Name.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('photos')) {
      photos = (_json['photos'] as core.List)
          .map<Photo>((value) =>
              Photo.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (emailAddresses != null)
          'emailAddresses':
              emailAddresses!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (obfuscatedId != null) 'obfuscatedId': obfuscatedId!,
        if (personNames != null)
          'personNames': personNames!.map((value) => value.toJson()).toList(),
        if (photos != null)
          'photos': photos!.map((value) => value.toJson()).toList(),
      };
}

/// A person's photo.
class Photo {
  /// The URL of the photo.
  core.String? url;

  Photo();

  Photo.fromJson(core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
      };
}

class PollItemsRequest {
  /// Name of connector making this call.
  ///
  /// Format: datasources/{source_id}/connectors/{ID}
  core.String? connectorName;

  /// Common debug options.
  DebugOptions? debugOptions;

  /// Maximum number of items to return.
  ///
  /// The maximum value is 100 and the default value is 20.
  core.int? limit;

  /// Queue name to fetch items from.
  ///
  /// If unspecified, PollItems will fetch from 'default' queue. The maximum
  /// length is 100 characters.
  core.String? queue;

  /// Limit the items polled to the ones with these statuses.
  core.List<core.String>? statusCodes;

  PollItemsRequest();

  PollItemsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('connectorName')) {
      connectorName = _json['connectorName'] as core.String;
    }
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('limit')) {
      limit = _json['limit'] as core.int;
    }
    if (_json.containsKey('queue')) {
      queue = _json['queue'] as core.String;
    }
    if (_json.containsKey('statusCodes')) {
      statusCodes = (_json['statusCodes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectorName != null) 'connectorName': connectorName!,
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (limit != null) 'limit': limit!,
        if (queue != null) 'queue': queue!,
        if (statusCodes != null) 'statusCodes': statusCodes!,
      };
}

class PollItemsResponse {
  /// Set of items from the queue available for connector to process.
  ///
  /// These items have the following subset of fields populated: version
  /// metadata.hash structured_data.hash content.hash payload status queue
  core.List<Item>? items;

  PollItemsResponse();

  PollItemsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Item>((value) =>
              Item.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

/// Reference to a user, group, or domain.
class Principal {
  /// This principal is a group identified using an external identity.
  ///
  /// The name field must specify the group resource name with this format:
  /// identitysources/{source_id}/groups/{ID}
  core.String? groupResourceName;

  /// This principal is a GSuite user, group or domain.
  GSuitePrincipal? gsuitePrincipal;

  /// This principal is a user identified using an external identity.
  ///
  /// The name field must specify the user resource name with this format:
  /// identitysources/{source_id}/users/{ID}
  core.String? userResourceName;

  Principal();

  Principal.fromJson(core.Map _json) {
    if (_json.containsKey('groupResourceName')) {
      groupResourceName = _json['groupResourceName'] as core.String;
    }
    if (_json.containsKey('gsuitePrincipal')) {
      gsuitePrincipal = GSuitePrincipal.fromJson(
          _json['gsuitePrincipal'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userResourceName')) {
      userResourceName = _json['userResourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupResourceName != null) 'groupResourceName': groupResourceName!,
        if (gsuitePrincipal != null)
          'gsuitePrincipal': gsuitePrincipal!.toJson(),
        if (userResourceName != null) 'userResourceName': userResourceName!,
      };
}

class ProcessingError {
  /// Error code indicating the nature of the error.
  /// Possible string values are:
  /// - "PROCESSING_ERROR_CODE_UNSPECIFIED" : Input only value. Use this value
  /// in Items.
  /// - "MALFORMED_REQUEST" : Item's ACL, metadata, or content is malformed or
  /// in invalid state. FieldViolations contains more details on where the
  /// problem is.
  /// - "UNSUPPORTED_CONTENT_FORMAT" : Countent format is unsupported.
  /// - "INDIRECT_BROKEN_ACL" : Items with incomplete ACL information due to
  /// inheriting other items with broken ACL or having groups with unmapped
  /// descendants.
  /// - "ACL_CYCLE" : ACL inheritance graph formed a cycle.
  core.String? code;

  /// Description of the error.
  core.String? errorMessage;

  /// In case the item fields are invalid, this field contains the details about
  /// the validation errors.
  core.List<FieldViolation>? fieldViolations;

  ProcessingError();

  ProcessingError.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('fieldViolations')) {
      fieldViolations = (_json['fieldViolations'] as core.List)
          .map<FieldViolation>((value) => FieldViolation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (fieldViolations != null)
          'fieldViolations':
              fieldViolations!.map((value) => value.toJson()).toList(),
      };
}

/// The definition of a property within an object.
class PropertyDefinition {
  BooleanPropertyOptions? booleanPropertyOptions;
  DatePropertyOptions? datePropertyOptions;

  /// Options that determine how the property is displayed in the Cloud Search
  /// results page if it is specified to be displayed in the object's display
  /// options .
  PropertyDisplayOptions? displayOptions;
  DoublePropertyOptions? doublePropertyOptions;
  EnumPropertyOptions? enumPropertyOptions;
  HtmlPropertyOptions? htmlPropertyOptions;
  IntegerPropertyOptions? integerPropertyOptions;

  /// Indicates that the property can be used for generating facets.
  ///
  /// Cannot be true for properties whose type is object. IsReturnable must be
  /// true to set this option. Only supported for Boolean, Enum, and Text
  /// properties.
  core.bool? isFacetable;

  /// Indicates that multiple values are allowed for the property.
  ///
  /// For example, a document only has one description but can have multiple
  /// comments. Cannot be true for properties whose type is a boolean. If set to
  /// false, properties that contain more than one value cause the indexing
  /// request for that item to be rejected.
  core.bool? isRepeatable;

  /// Indicates that the property identifies data that should be returned in
  /// search results via the Query API.
  ///
  /// If set to *true*, indicates that Query API users can use matching property
  /// fields in results. However, storing fields requires more space allocation
  /// and uses more bandwidth for search queries, which impacts performance over
  /// large datasets. Set to *true* here only if the field is needed for search
  /// results. Cannot be true for properties whose type is an object.
  core.bool? isReturnable;

  /// Indicates that the property can be used for sorting.
  ///
  /// Cannot be true for properties that are repeatable. Cannot be true for
  /// properties whose type is object or user identifier. IsReturnable must be
  /// true to set this option. Only supported for Boolean, Date, Double,
  /// Integer, and Timestamp properties.
  core.bool? isSortable;

  /// Indicates that the property can be used for generating query suggestions.
  core.bool? isSuggestable;

  /// Indicates that users can perform wildcard search for this property.
  ///
  /// Only supported for Text properties. IsReturnable must be true to set this
  /// option. In a given datasource maximum of 5 properties can be marked as
  /// is_wildcard_searchable.
  core.bool? isWildcardSearchable;

  /// The name of the property.
  ///
  /// Item indexing requests sent to the Indexing API should set the property
  /// name equal to this value. For example, if name is *subject_line*, then
  /// indexing requests for document items with subject fields should set the
  /// name for that field equal to *subject_line*. Use the name as the
  /// identifier for the object property. Once registered as a property for an
  /// object, you cannot re-use this name for another property within that
  /// object. The name must start with a letter and can only contain letters
  /// (A-Z, a-z) or numbers (0-9). The maximum length is 256 characters.
  core.String? name;
  ObjectPropertyOptions? objectPropertyOptions;
  TextPropertyOptions? textPropertyOptions;
  TimestampPropertyOptions? timestampPropertyOptions;

  PropertyDefinition();

  PropertyDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('booleanPropertyOptions')) {
      booleanPropertyOptions = BooleanPropertyOptions.fromJson(
          _json['booleanPropertyOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('datePropertyOptions')) {
      datePropertyOptions = DatePropertyOptions.fromJson(
          _json['datePropertyOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayOptions')) {
      displayOptions = PropertyDisplayOptions.fromJson(
          _json['displayOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('doublePropertyOptions')) {
      doublePropertyOptions = DoublePropertyOptions.fromJson(
          _json['doublePropertyOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enumPropertyOptions')) {
      enumPropertyOptions = EnumPropertyOptions.fromJson(
          _json['enumPropertyOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('htmlPropertyOptions')) {
      htmlPropertyOptions = HtmlPropertyOptions.fromJson(
          _json['htmlPropertyOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('integerPropertyOptions')) {
      integerPropertyOptions = IntegerPropertyOptions.fromJson(
          _json['integerPropertyOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isFacetable')) {
      isFacetable = _json['isFacetable'] as core.bool;
    }
    if (_json.containsKey('isRepeatable')) {
      isRepeatable = _json['isRepeatable'] as core.bool;
    }
    if (_json.containsKey('isReturnable')) {
      isReturnable = _json['isReturnable'] as core.bool;
    }
    if (_json.containsKey('isSortable')) {
      isSortable = _json['isSortable'] as core.bool;
    }
    if (_json.containsKey('isSuggestable')) {
      isSuggestable = _json['isSuggestable'] as core.bool;
    }
    if (_json.containsKey('isWildcardSearchable')) {
      isWildcardSearchable = _json['isWildcardSearchable'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('objectPropertyOptions')) {
      objectPropertyOptions = ObjectPropertyOptions.fromJson(
          _json['objectPropertyOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textPropertyOptions')) {
      textPropertyOptions = TextPropertyOptions.fromJson(
          _json['textPropertyOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampPropertyOptions')) {
      timestampPropertyOptions = TimestampPropertyOptions.fromJson(
          _json['timestampPropertyOptions']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (booleanPropertyOptions != null)
          'booleanPropertyOptions': booleanPropertyOptions!.toJson(),
        if (datePropertyOptions != null)
          'datePropertyOptions': datePropertyOptions!.toJson(),
        if (displayOptions != null) 'displayOptions': displayOptions!.toJson(),
        if (doublePropertyOptions != null)
          'doublePropertyOptions': doublePropertyOptions!.toJson(),
        if (enumPropertyOptions != null)
          'enumPropertyOptions': enumPropertyOptions!.toJson(),
        if (htmlPropertyOptions != null)
          'htmlPropertyOptions': htmlPropertyOptions!.toJson(),
        if (integerPropertyOptions != null)
          'integerPropertyOptions': integerPropertyOptions!.toJson(),
        if (isFacetable != null) 'isFacetable': isFacetable!,
        if (isRepeatable != null) 'isRepeatable': isRepeatable!,
        if (isReturnable != null) 'isReturnable': isReturnable!,
        if (isSortable != null) 'isSortable': isSortable!,
        if (isSuggestable != null) 'isSuggestable': isSuggestable!,
        if (isWildcardSearchable != null)
          'isWildcardSearchable': isWildcardSearchable!,
        if (name != null) 'name': name!,
        if (objectPropertyOptions != null)
          'objectPropertyOptions': objectPropertyOptions!.toJson(),
        if (textPropertyOptions != null)
          'textPropertyOptions': textPropertyOptions!.toJson(),
        if (timestampPropertyOptions != null)
          'timestampPropertyOptions': timestampPropertyOptions!.toJson(),
      };
}

/// The display options for a property.
class PropertyDisplayOptions {
  /// The user friendly label for the property that is used if the property is
  /// specified to be displayed in ObjectDisplayOptions.
  ///
  /// If provided, the display label is shown in front of the property values
  /// when the property is part of the object display options. For example, if
  /// the property value is '1', the value by itself may not be useful context
  /// for the user. If the display name given was 'priority', then the user sees
  /// 'priority : 1' in the search results which provides clear context to
  /// search users. This is OPTIONAL; if not given, only the property values are
  /// displayed. The maximum length is 64 characters.
  core.String? displayLabel;

  PropertyDisplayOptions();

  PropertyDisplayOptions.fromJson(core.Map _json) {
    if (_json.containsKey('displayLabel')) {
      displayLabel = _json['displayLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayLabel != null) 'displayLabel': displayLabel!,
      };
}

/// Represents an item to be pushed to the indexing queue.
class PushItem {
  /// Content hash of the item according to the repository.
  ///
  /// If specified, this is used to determine how to modify this item's status.
  /// Setting this field and the type field results in argument error. The
  /// maximum length is 2048 characters.
  core.String? contentHash;

  /// Metadata hash of the item according to the repository.
  ///
  /// If specified, this is used to determine how to modify this item's status.
  /// Setting this field and the type field results in argument error. The
  /// maximum length is 2048 characters.
  core.String? metadataHash;

  /// Provides additional document state information for the connector, such as
  /// an alternate repository ID and other metadata.
  ///
  /// The maximum length is 8192 bytes.
  core.String? payload;
  core.List<core.int> get payloadAsBytes => convert.base64.decode(payload!);

  set payloadAsBytes(core.List<core.int> _bytes) {
    payload =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Queue to which this item belongs to.
  ///
  /// The default queue is chosen if this field is not specified. The maximum
  /// length is 512 characters.
  core.String? queue;

  /// Populate this field to store Connector or repository error details.
  ///
  /// This information is displayed in the Admin Console. This field may only be
  /// populated when the Type is REPOSITORY_ERROR.
  RepositoryError? repositoryError;

  /// Structured data hash of the item according to the repository.
  ///
  /// If specified, this is used to determine how to modify this item's status.
  /// Setting this field and the type field results in argument error. The
  /// maximum length is 2048 characters.
  core.String? structuredDataHash;

  /// The type of the push operation that defines the push behavior.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Default UNSPECIFIED. Specifies that the push operation
  /// should not modify ItemStatus
  /// - "MODIFIED" : Indicates that the repository document has been modified or
  /// updated since the previous update call. This changes status to MODIFIED
  /// state for an existing item. If this is called on a non existing item, the
  /// status is changed to NEW_ITEM.
  /// - "NOT_MODIFIED" : Item in the repository has not been modified since the
  /// last update call. This push operation will set status to ACCEPTED state.
  /// - "REPOSITORY_ERROR" : Connector is facing a repository error regarding
  /// this item. Change status to REPOSITORY_ERROR state. Item is unreserved and
  /// rescheduled at a future time determined by exponential backoff.
  /// - "REQUEUE" : Call push with REQUEUE only for items that have been
  /// reserved. This action unreserves the item and resets its available time to
  /// the wall clock time.
  core.String? type;

  PushItem();

  PushItem.fromJson(core.Map _json) {
    if (_json.containsKey('contentHash')) {
      contentHash = _json['contentHash'] as core.String;
    }
    if (_json.containsKey('metadataHash')) {
      metadataHash = _json['metadataHash'] as core.String;
    }
    if (_json.containsKey('payload')) {
      payload = _json['payload'] as core.String;
    }
    if (_json.containsKey('queue')) {
      queue = _json['queue'] as core.String;
    }
    if (_json.containsKey('repositoryError')) {
      repositoryError = RepositoryError.fromJson(
          _json['repositoryError'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('structuredDataHash')) {
      structuredDataHash = _json['structuredDataHash'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentHash != null) 'contentHash': contentHash!,
        if (metadataHash != null) 'metadataHash': metadataHash!,
        if (payload != null) 'payload': payload!,
        if (queue != null) 'queue': queue!,
        if (repositoryError != null)
          'repositoryError': repositoryError!.toJson(),
        if (structuredDataHash != null)
          'structuredDataHash': structuredDataHash!,
        if (type != null) 'type': type!,
      };
}

class PushItemRequest {
  /// Name of connector making this call.
  ///
  /// Format: datasources/{source_id}/connectors/{ID}
  core.String? connectorName;

  /// Common debug options.
  DebugOptions? debugOptions;

  /// Item to push onto the queue.
  PushItem? item;

  PushItemRequest();

  PushItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('connectorName')) {
      connectorName = _json['connectorName'] as core.String;
    }
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('item')) {
      item = PushItem.fromJson(
          _json['item'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectorName != null) 'connectorName': connectorName!,
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (item != null) 'item': item!.toJson(),
      };
}

class QueryCountByStatus {
  core.String? count;

  /// This represents the http status code.
  core.int? statusCode;

  QueryCountByStatus();

  QueryCountByStatus.fromJson(core.Map _json) {
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
    if (_json.containsKey('statusCode')) {
      statusCode = _json['statusCode'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (count != null) 'count': count!,
        if (statusCode != null) 'statusCode': statusCode!,
      };
}

class QueryInterpretation {
  ///
  /// Possible string values are:
  /// - "NONE" : Neither the natural language interpretation, nor a broader
  /// version of the query is used to fetch the search results.
  /// - "BLEND" : The results from original query are blended with other
  /// results. The reason for blending these other results with the results from
  /// original query is populated in the 'Reason' field below.
  /// - "REPLACE" : The results from original query are replaced. The reason for
  /// replacing the results from original query is populated in the 'Reason'
  /// field below.
  core.String? interpretationType;

  /// The interpretation of the query used in search.
  ///
  /// For example, queries with natural language intent like "email from john"
  /// will be interpreted as "from:john source:mail". This field will not be
  /// filled when the reason is NOT_ENOUGH_RESULTS_FOUND_FOR_USER_QUERY.
  core.String? interpretedQuery;

  /// The reason for interpretation of the query.
  ///
  /// This field will not be UNSPECIFIED if the interpretation type is not NONE.
  /// Possible string values are:
  /// - "UNSPECIFIED"
  /// - "QUERY_HAS_NATURAL_LANGUAGE_INTENT" : Natural language interpretation of
  /// the query is used to fetch the search results.
  /// - "NOT_ENOUGH_RESULTS_FOUND_FOR_USER_QUERY" : Query and document terms
  /// similarity is used to selectively broaden the query to retrieve additional
  /// search results since enough results were not found for the user query.
  /// Interpreted query will be empty for this case.
  core.String? reason;

  QueryInterpretation();

  QueryInterpretation.fromJson(core.Map _json) {
    if (_json.containsKey('interpretationType')) {
      interpretationType = _json['interpretationType'] as core.String;
    }
    if (_json.containsKey('interpretedQuery')) {
      interpretedQuery = _json['interpretedQuery'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (interpretationType != null)
          'interpretationType': interpretationType!,
        if (interpretedQuery != null) 'interpretedQuery': interpretedQuery!,
        if (reason != null) 'reason': reason!,
      };
}

/// Options to interpret user query.
class QueryInterpretationOptions {
  /// Flag to disable natural language (NL) interpretation of queries.
  ///
  /// Default is false, Set to true to disable natural language interpretation.
  /// NL interpretation only applies to predefined datasources.
  core.bool? disableNlInterpretation;

  /// Enable this flag to turn off all internal optimizations like natural
  /// language (NL) interpretation of queries, supplemental result retrieval,
  /// and usage of synonyms including custom ones.
  ///
  /// Nl interpretation will be disabled if either one of the two flags is true.
  core.bool? enableVerbatimMode;

  QueryInterpretationOptions();

  QueryInterpretationOptions.fromJson(core.Map _json) {
    if (_json.containsKey('disableNlInterpretation')) {
      disableNlInterpretation = _json['disableNlInterpretation'] as core.bool;
    }
    if (_json.containsKey('enableVerbatimMode')) {
      enableVerbatimMode = _json['enableVerbatimMode'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disableNlInterpretation != null)
          'disableNlInterpretation': disableNlInterpretation!,
        if (enableVerbatimMode != null)
          'enableVerbatimMode': enableVerbatimMode!,
      };
}

/// Information relevant only to a query entry.
class QueryItem {
  /// True if the text was generated by means other than a previous user search.
  core.bool? isSynthetic;

  QueryItem();

  QueryItem.fromJson(core.Map _json) {
    if (_json.containsKey('isSynthetic')) {
      isSynthetic = _json['isSynthetic'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (isSynthetic != null) 'isSynthetic': isSynthetic!,
      };
}

/// The definition of a operator that can be used in a Search/Suggest request.
class QueryOperator {
  /// Display name of the operator
  core.String? displayName;

  /// Potential list of values for the opeatror field.
  ///
  /// This field is only filled when we can safely enumerate all the possible
  /// values of this operator.
  core.List<core.String>? enumValues;

  /// Indicates the operator name that can be used to isolate the property using
  /// the greater-than operator.
  core.String? greaterThanOperatorName;

  /// Can this operator be used to get facets.
  core.bool? isFacetable;

  /// Indicates if multiple values can be set for this property.
  core.bool? isRepeatable;

  /// Will the property associated with this facet be returned as part of search
  /// results.
  core.bool? isReturnable;

  /// Can this operator be used to sort results.
  core.bool? isSortable;

  /// Can get suggestions for this field.
  core.bool? isSuggestable;

  /// Indicates the operator name that can be used to isolate the property using
  /// the less-than operator.
  core.String? lessThanOperatorName;

  /// Name of the object corresponding to the operator.
  ///
  /// This field is only filled for schema-specific operators, and is unset for
  /// common operators.
  core.String? objectType;

  /// The name of the operator.
  core.String? operatorName;

  /// Type of the operator.
  /// Possible string values are:
  /// - "UNKNOWN" : Invalid value.
  /// - "INTEGER"
  /// - "DOUBLE"
  /// - "TIMESTAMP"
  /// - "BOOLEAN"
  /// - "ENUM"
  /// - "DATE"
  /// - "TEXT"
  /// - "HTML"
  core.String? type;

  QueryOperator();

  QueryOperator.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('enumValues')) {
      enumValues = (_json['enumValues'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('greaterThanOperatorName')) {
      greaterThanOperatorName = _json['greaterThanOperatorName'] as core.String;
    }
    if (_json.containsKey('isFacetable')) {
      isFacetable = _json['isFacetable'] as core.bool;
    }
    if (_json.containsKey('isRepeatable')) {
      isRepeatable = _json['isRepeatable'] as core.bool;
    }
    if (_json.containsKey('isReturnable')) {
      isReturnable = _json['isReturnable'] as core.bool;
    }
    if (_json.containsKey('isSortable')) {
      isSortable = _json['isSortable'] as core.bool;
    }
    if (_json.containsKey('isSuggestable')) {
      isSuggestable = _json['isSuggestable'] as core.bool;
    }
    if (_json.containsKey('lessThanOperatorName')) {
      lessThanOperatorName = _json['lessThanOperatorName'] as core.String;
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (enumValues != null) 'enumValues': enumValues!,
        if (greaterThanOperatorName != null)
          'greaterThanOperatorName': greaterThanOperatorName!,
        if (isFacetable != null) 'isFacetable': isFacetable!,
        if (isRepeatable != null) 'isRepeatable': isRepeatable!,
        if (isReturnable != null) 'isReturnable': isReturnable!,
        if (isSortable != null) 'isSortable': isSortable!,
        if (isSuggestable != null) 'isSuggestable': isSuggestable!,
        if (lessThanOperatorName != null)
          'lessThanOperatorName': lessThanOperatorName!,
        if (objectType != null) 'objectType': objectType!,
        if (operatorName != null) 'operatorName': operatorName!,
        if (type != null) 'type': type!,
      };
}

/// List of sources that the user can search using the query API.
class QuerySource {
  /// Display name of the data source.
  core.String? displayName;

  /// List of all operators applicable for this source.
  core.List<QueryOperator>? operators;

  /// A short name or alias for the source.
  ///
  /// This value can be used with the 'source' operator.
  core.String? shortName;

  /// Name of the source
  Source? source;

  QuerySource();

  QuerySource.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('operators')) {
      operators = (_json['operators'] as core.List)
          .map<QueryOperator>((value) => QueryOperator.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shortName')) {
      shortName = _json['shortName'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (operators != null)
          'operators': operators!.map((value) => value.toJson()).toList(),
        if (shortName != null) 'shortName': shortName!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// This field does not contain anything as of now and is just used as an
/// indicator that the suggest result was a phrase completion.
class QuerySuggestion {
  QuerySuggestion();

  QuerySuggestion.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Errors when the connector is communicating to the source repository.
class RepositoryError {
  /// Message that describes the error.
  ///
  /// The maximum allowable length of the message is 8192 characters.
  core.String? errorMessage;

  /// Error codes.
  ///
  /// Matches the definition of HTTP status codes.
  core.int? httpStatusCode;

  /// Type of error.
  /// Possible string values are:
  /// - "UNKNOWN" : Unknown error.
  /// - "NETWORK_ERROR" : Unknown or unreachable host.
  /// - "DNS_ERROR" : DNS problem, such as the DNS server is not responding.
  /// - "CONNECTION_ERROR" : Cannot connect to the repository server.
  /// - "AUTHENTICATION_ERROR" : Failed authentication due to incorrect
  /// credentials.
  /// - "AUTHORIZATION_ERROR" : Service account is not authorized for the
  /// repository.
  /// - "SERVER_ERROR" : Repository server error.
  /// - "QUOTA_EXCEEDED" : Quota exceeded.
  /// - "SERVICE_UNAVAILABLE" : Server temporarily unavailable.
  /// - "CLIENT_ERROR" : Client-related error, such as an invalid request from
  /// the connector to the repository server.
  core.String? type;

  RepositoryError();

  RepositoryError.fromJson(core.Map _json) {
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('httpStatusCode')) {
      httpStatusCode = _json['httpStatusCode'] as core.int;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (httpStatusCode != null) 'httpStatusCode': httpStatusCode!,
        if (type != null) 'type': type!,
      };
}

/// Shared request options for all RPC methods.
class RequestOptions {
  /// Debug options of the request
  DebugOptions? debugOptions;

  /// The BCP-47 language code, such as "en-US" or "sr-Latn".
  ///
  /// For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier. For
  /// translations. Set this field using the language set in browser or for the
  /// page. In the event that the user's language preference is known, set this
  /// field to the known user language. When specified, the documents in search
  /// results are biased towards the specified language. The suggest API does
  /// not use this parameter. Instead, suggest autocompletes only based on
  /// characters in the query.
  core.String? languageCode;

  /// The ID generated when you create a search application using the
  /// [admin console](https://support.google.com/a/answer/9043922).
  core.String? searchApplicationId;

  /// Current user's time zone id, such as "America/Los_Angeles" or
  /// "Australia/Sydney".
  ///
  /// These IDs are defined by \[Unicode Common Locale Data Repository
  /// (CLDR)\](http://cldr.unicode.org/) project, and currently available in the
  /// file
  /// [timezone.xml](http://unicode.org/repos/cldr/trunk/common/bcp47/timezone.xml).
  /// This field is used to correctly interpret date and time queries. If this
  /// field is not specified, the default time zone (UTC) is used.
  core.String? timeZone;

  RequestOptions();

  RequestOptions.fromJson(core.Map _json) {
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('searchApplicationId')) {
      searchApplicationId = _json['searchApplicationId'] as core.String;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (languageCode != null) 'languageCode': languageCode!,
        if (searchApplicationId != null)
          'searchApplicationId': searchApplicationId!,
        if (timeZone != null) 'timeZone': timeZone!,
      };
}

class ResetSearchApplicationRequest {
  /// Common debug options.
  DebugOptions? debugOptions;

  ResetSearchApplicationRequest();

  ResetSearchApplicationRequest.fromJson(core.Map _json) {
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
      };
}

/// Debugging information about the response.
class ResponseDebugInfo {
  /// General debug info formatted for display.
  core.String? formattedDebugInfo;

  ResponseDebugInfo();

  ResponseDebugInfo.fromJson(core.Map _json) {
    if (_json.containsKey('formattedDebugInfo')) {
      formattedDebugInfo = _json['formattedDebugInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (formattedDebugInfo != null)
          'formattedDebugInfo': formattedDebugInfo!,
      };
}

/// Information relevant only to a restrict entry.
///
/// NextId: 12
class RestrictItem {
  /// LINT.ThenChange(//depot/google3/java/com/google/apps/search/quality/itemsuggest/utils/SubtypeRerankingUtils.java)
  DriveFollowUpRestrict? driveFollowUpRestrict;
  DriveLocationRestrict? driveLocationRestrict;

  /// LINT.IfChange Drive Types.
  DriveMimeTypeRestrict? driveMimeTypeRestrict;
  DriveTimeSpanRestrict? driveTimeSpanRestrict;

  /// The search restrict (e.g. "after:2017-09-11 before:2017-09-12").
  core.String? searchOperator;

  RestrictItem();

  RestrictItem.fromJson(core.Map _json) {
    if (_json.containsKey('driveFollowUpRestrict')) {
      driveFollowUpRestrict = DriveFollowUpRestrict.fromJson(
          _json['driveFollowUpRestrict']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('driveLocationRestrict')) {
      driveLocationRestrict = DriveLocationRestrict.fromJson(
          _json['driveLocationRestrict']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('driveMimeTypeRestrict')) {
      driveMimeTypeRestrict = DriveMimeTypeRestrict.fromJson(
          _json['driveMimeTypeRestrict']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('driveTimeSpanRestrict')) {
      driveTimeSpanRestrict = DriveTimeSpanRestrict.fromJson(
          _json['driveTimeSpanRestrict']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('searchOperator')) {
      searchOperator = _json['searchOperator'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (driveFollowUpRestrict != null)
          'driveFollowUpRestrict': driveFollowUpRestrict!.toJson(),
        if (driveLocationRestrict != null)
          'driveLocationRestrict': driveLocationRestrict!.toJson(),
        if (driveMimeTypeRestrict != null)
          'driveMimeTypeRestrict': driveMimeTypeRestrict!.toJson(),
        if (driveTimeSpanRestrict != null)
          'driveTimeSpanRestrict': driveTimeSpanRestrict!.toJson(),
        if (searchOperator != null) 'searchOperator': searchOperator!,
      };
}

/// Result count information
class ResultCounts {
  /// Result count information for each source with results.
  core.List<SourceResultCount>? sourceResultCounts;

  ResultCounts();

  ResultCounts.fromJson(core.Map _json) {
    if (_json.containsKey('sourceResultCounts')) {
      sourceResultCounts = (_json['sourceResultCounts'] as core.List)
          .map<SourceResultCount>((value) => SourceResultCount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sourceResultCounts != null)
          'sourceResultCounts':
              sourceResultCounts!.map((value) => value.toJson()).toList(),
      };
}

/// Debugging information about the result.
class ResultDebugInfo {
  /// General debug info formatted for display.
  core.String? formattedDebugInfo;

  ResultDebugInfo();

  ResultDebugInfo.fromJson(core.Map _json) {
    if (_json.containsKey('formattedDebugInfo')) {
      formattedDebugInfo = _json['formattedDebugInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (formattedDebugInfo != null)
          'formattedDebugInfo': formattedDebugInfo!,
      };
}

/// Display Fields for Search Results
class ResultDisplayField {
  /// The display label for the property.
  core.String? label;

  /// The operator name of the property.
  core.String? operatorName;

  /// The name value pair for the property.
  NamedProperty? property;

  ResultDisplayField();

  ResultDisplayField.fromJson(core.Map _json) {
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
    if (_json.containsKey('property')) {
      property = NamedProperty.fromJson(
          _json['property'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (label != null) 'label': label!,
        if (operatorName != null) 'operatorName': operatorName!,
        if (property != null) 'property': property!.toJson(),
      };
}

/// The collection of fields that make up a displayed line
class ResultDisplayLine {
  core.List<ResultDisplayField>? fields;

  ResultDisplayLine();

  ResultDisplayLine.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<ResultDisplayField>((value) => ResultDisplayField.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null)
          'fields': fields!.map((value) => value.toJson()).toList(),
      };
}

class ResultDisplayMetadata {
  /// The metalines content to be displayed with the result.
  core.List<ResultDisplayLine>? metalines;

  /// The display label for the object.
  core.String? objectTypeLabel;

  ResultDisplayMetadata();

  ResultDisplayMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('metalines')) {
      metalines = (_json['metalines'] as core.List)
          .map<ResultDisplayLine>((value) => ResultDisplayLine.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectTypeLabel')) {
      objectTypeLabel = _json['objectTypeLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metalines != null)
          'metalines': metalines!.map((value) => value.toJson()).toList(),
        if (objectTypeLabel != null) 'objectTypeLabel': objectTypeLabel!,
      };
}

class RetrievalImportance {
  /// Indicates the ranking importance given to property when it is matched
  /// during retrieval.
  ///
  /// Once set, the token importance of a property cannot be changed.
  /// Possible string values are:
  /// - "DEFAULT" : Treat the match like a body text match.
  /// - "HIGHEST" : Treat the match like a match against title of the item.
  /// - "HIGH" : Treat the match with higher importance than body text.
  /// - "LOW" : Treat the match with lower importance than body text.
  /// - "NONE" : Do not match against this field during retrieval. The property
  /// can still be used for operator matching, faceting, and suggest if desired.
  core.String? importance;

  RetrievalImportance();

  RetrievalImportance.fromJson(core.Map _json) {
    if (_json.containsKey('importance')) {
      importance = _json['importance'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (importance != null) 'importance': importance!,
      };
}

/// The schema definition for a data source.
class Schema {
  /// The list of top-level objects for the data source.
  ///
  /// The maximum number of elements is 10.
  core.List<ObjectDefinition>? objectDefinitions;

  /// IDs of the Long Running Operations (LROs) currently running for this
  /// schema.
  ///
  /// After modifying the schema, wait for operations to complete before
  /// indexing additional content.
  core.List<core.String>? operationIds;

  Schema();

  Schema.fromJson(core.Map _json) {
    if (_json.containsKey('objectDefinitions')) {
      objectDefinitions = (_json['objectDefinitions'] as core.List)
          .map<ObjectDefinition>((value) => ObjectDefinition.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operationIds')) {
      operationIds = (_json['operationIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectDefinitions != null)
          'objectDefinitions':
              objectDefinitions!.map((value) => value.toJson()).toList(),
        if (operationIds != null) 'operationIds': operationIds!,
      };
}

/// Scoring configurations for a source while processing a Search or Suggest
/// request.
class ScoringConfig {
  /// Whether to use freshness as a ranking signal.
  ///
  /// By default, freshness is used as a ranking signal. Note that this setting
  /// is not available in the Admin UI.
  core.bool? disableFreshness;

  /// Whether to personalize the results.
  ///
  /// By default, personal signals will be used to boost results.
  core.bool? disablePersonalization;

  ScoringConfig();

  ScoringConfig.fromJson(core.Map _json) {
    if (_json.containsKey('disableFreshness')) {
      disableFreshness = _json['disableFreshness'] as core.bool;
    }
    if (_json.containsKey('disablePersonalization')) {
      disablePersonalization = _json['disablePersonalization'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disableFreshness != null) 'disableFreshness': disableFreshness!,
        if (disablePersonalization != null)
          'disablePersonalization': disablePersonalization!,
      };
}

/// SearchApplication
class SearchApplication {
  /// Retrictions applied to the configurations.
  ///
  /// The maximum number of elements is 10.
  core.List<DataSourceRestriction>? dataSourceRestrictions;

  /// The default fields for returning facet results.
  ///
  /// The sources specified here also have been included in
  /// data_source_restrictions above.
  core.List<FacetOptions>? defaultFacetOptions;

  /// The default options for sorting the search results
  SortOptions? defaultSortOptions;

  /// Display name of the Search Application.
  ///
  /// The maximum length is 300 characters.
  core.String? displayName;

  /// Indicates whether audit logging is on/off for requests made for the search
  /// application in query APIs.
  core.bool? enableAuditLog;

  /// Name of the Search Application.
  ///
  /// Format: searchapplications/{application_id}.
  core.String? name;

  /// IDs of the Long Running Operations (LROs) currently running for this
  /// schema.
  ///
  /// Output only field.
  ///
  /// Output only.
  core.List<core.String>? operationIds;

  /// Configuration for ranking results.
  ScoringConfig? scoringConfig;

  /// Configuration for a sources specified in data_source_restrictions.
  core.List<SourceConfig>? sourceConfig;

  SearchApplication();

  SearchApplication.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceRestrictions')) {
      dataSourceRestrictions = (_json['dataSourceRestrictions'] as core.List)
          .map<DataSourceRestriction>((value) => DataSourceRestriction.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('defaultFacetOptions')) {
      defaultFacetOptions = (_json['defaultFacetOptions'] as core.List)
          .map<FacetOptions>((value) => FacetOptions.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('defaultSortOptions')) {
      defaultSortOptions = SortOptions.fromJson(
          _json['defaultSortOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('enableAuditLog')) {
      enableAuditLog = _json['enableAuditLog'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operationIds')) {
      operationIds = (_json['operationIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('scoringConfig')) {
      scoringConfig = ScoringConfig.fromJson(
          _json['scoringConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceConfig')) {
      sourceConfig = (_json['sourceConfig'] as core.List)
          .map<SourceConfig>((value) => SourceConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceRestrictions != null)
          'dataSourceRestrictions':
              dataSourceRestrictions!.map((value) => value.toJson()).toList(),
        if (defaultFacetOptions != null)
          'defaultFacetOptions':
              defaultFacetOptions!.map((value) => value.toJson()).toList(),
        if (defaultSortOptions != null)
          'defaultSortOptions': defaultSortOptions!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (enableAuditLog != null) 'enableAuditLog': enableAuditLog!,
        if (name != null) 'name': name!,
        if (operationIds != null) 'operationIds': operationIds!,
        if (scoringConfig != null) 'scoringConfig': scoringConfig!.toJson(),
        if (sourceConfig != null)
          'sourceConfig': sourceConfig!.map((value) => value.toJson()).toList(),
      };
}

class SearchApplicationQueryStats {
  /// Date for which query stats were calculated.
  ///
  /// Stats calculated on the next day close to midnight are returned.
  Date? date;
  core.List<QueryCountByStatus>? queryCountByStatus;

  SearchApplicationQueryStats();

  SearchApplicationQueryStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryCountByStatus')) {
      queryCountByStatus = (_json['queryCountByStatus'] as core.List)
          .map<QueryCountByStatus>((value) => QueryCountByStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (queryCountByStatus != null)
          'queryCountByStatus':
              queryCountByStatus!.map((value) => value.toJson()).toList(),
      };
}

class SearchApplicationSessionStats {
  /// Date for which session stats were calculated.
  ///
  /// Stats calculated on the next day close to midnight are returned.
  Date? date;

  /// The count of search sessions on the day
  core.String? searchSessionsCount;

  SearchApplicationSessionStats();

  SearchApplicationSessionStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('searchSessionsCount')) {
      searchSessionsCount = _json['searchSessionsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (searchSessionsCount != null)
          'searchSessionsCount': searchSessionsCount!,
      };
}

class SearchApplicationUserStats {
  /// Date for which session stats were calculated.
  ///
  /// Stats calculated on the next day close to midnight are returned.
  Date? date;

  /// The count of unique active users in the past one day
  core.String? oneDayActiveUsersCount;

  /// The count of unique active users in the past seven days
  core.String? sevenDaysActiveUsersCount;

  /// The count of unique active users in the past thirty days
  core.String? thirtyDaysActiveUsersCount;

  SearchApplicationUserStats();

  SearchApplicationUserStats.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('oneDayActiveUsersCount')) {
      oneDayActiveUsersCount = _json['oneDayActiveUsersCount'] as core.String;
    }
    if (_json.containsKey('sevenDaysActiveUsersCount')) {
      sevenDaysActiveUsersCount =
          _json['sevenDaysActiveUsersCount'] as core.String;
    }
    if (_json.containsKey('thirtyDaysActiveUsersCount')) {
      thirtyDaysActiveUsersCount =
          _json['thirtyDaysActiveUsersCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (oneDayActiveUsersCount != null)
          'oneDayActiveUsersCount': oneDayActiveUsersCount!,
        if (sevenDaysActiveUsersCount != null)
          'sevenDaysActiveUsersCount': sevenDaysActiveUsersCount!,
        if (thirtyDaysActiveUsersCount != null)
          'thirtyDaysActiveUsersCount': thirtyDaysActiveUsersCount!,
      };
}

class SearchItemsByViewUrlRequest {
  /// Common debug options.
  DebugOptions? debugOptions;

  /// The next_page_token value returned from a previous request, if any.
  core.String? pageToken;

  /// Specify the full view URL to find the corresponding item.
  ///
  /// The maximum length is 2048 characters.
  core.String? viewUrl;

  SearchItemsByViewUrlRequest();

  SearchItemsByViewUrlRequest.fromJson(core.Map _json) {
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('viewUrl')) {
      viewUrl = _json['viewUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (pageToken != null) 'pageToken': pageToken!,
        if (viewUrl != null) 'viewUrl': viewUrl!,
      };
}

class SearchItemsByViewUrlResponse {
  core.List<Item>? items;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  SearchItemsByViewUrlResponse();

  SearchItemsByViewUrlResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Item>((value) =>
              Item.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Additional search quality metadata of the item.
class SearchQualityMetadata {
  /// An indication of the quality of the item, used to influence search
  /// quality.
  ///
  /// Value should be between 0.0 (lowest quality) and 1.0 (highest quality).
  /// The default value is 0.0.
  core.double? quality;

  SearchQualityMetadata();

  SearchQualityMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('quality')) {
      quality = (_json['quality'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (quality != null) 'quality': quality!,
      };
}

/// The search API request.
class SearchRequest {
  /// Context attributes for the request which will be used to adjust ranking of
  /// search results.
  ///
  /// The maximum number of elements is 10.
  core.List<ContextAttribute>? contextAttributes;

  /// The sources to use for querying.
  ///
  /// If not specified, all data sources from the current search application are
  /// used.
  core.List<DataSourceRestriction>? dataSourceRestrictions;
  core.List<FacetOptions>? facetOptions;

  /// Maximum number of search results to return in one page.
  ///
  /// Valid values are between 1 and 100, inclusive. Default value is 10.
  /// Minimum value is 50 when results beyond 2000 are requested.
  core.int? pageSize;

  /// The raw query string.
  ///
  /// See supported search operators in the
  /// [Cloud search Cheat Sheet](https://support.google.com/a/users/answer/9299929)
  core.String? query;

  /// Options to interpret the user query.
  QueryInterpretationOptions? queryInterpretationOptions;

  /// Request options, such as the search application and user timezone.
  RequestOptions? requestOptions;

  /// The options for sorting the search results
  SortOptions? sortOptions;

  /// Starting index of the results.
  core.int? start;

  SearchRequest();

  SearchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('contextAttributes')) {
      contextAttributes = (_json['contextAttributes'] as core.List)
          .map<ContextAttribute>((value) => ContextAttribute.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dataSourceRestrictions')) {
      dataSourceRestrictions = (_json['dataSourceRestrictions'] as core.List)
          .map<DataSourceRestriction>((value) => DataSourceRestriction.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('facetOptions')) {
      facetOptions = (_json['facetOptions'] as core.List)
          .map<FacetOptions>((value) => FacetOptions.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('queryInterpretationOptions')) {
      queryInterpretationOptions = QueryInterpretationOptions.fromJson(
          _json['queryInterpretationOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requestOptions')) {
      requestOptions = RequestOptions.fromJson(
          _json['requestOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortOptions')) {
      sortOptions = SortOptions.fromJson(
          _json['sortOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('start')) {
      start = _json['start'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contextAttributes != null)
          'contextAttributes':
              contextAttributes!.map((value) => value.toJson()).toList(),
        if (dataSourceRestrictions != null)
          'dataSourceRestrictions':
              dataSourceRestrictions!.map((value) => value.toJson()).toList(),
        if (facetOptions != null)
          'facetOptions': facetOptions!.map((value) => value.toJson()).toList(),
        if (pageSize != null) 'pageSize': pageSize!,
        if (query != null) 'query': query!,
        if (queryInterpretationOptions != null)
          'queryInterpretationOptions': queryInterpretationOptions!.toJson(),
        if (requestOptions != null) 'requestOptions': requestOptions!.toJson(),
        if (sortOptions != null) 'sortOptions': sortOptions!.toJson(),
        if (start != null) 'start': start!,
      };
}

/// The search API response.
class SearchResponse {
  /// Debugging information about the response.
  ResponseDebugInfo? debugInfo;

  /// Error information about the response.
  ErrorInfo? errorInfo;

  /// Repeated facet results.
  core.List<FacetResult>? facetResults;

  /// Whether there are more search results matching the query.
  core.bool? hasMoreResults;

  /// Query interpretation result for user query.
  ///
  /// Empty if query interpretation is disabled.
  QueryInterpretation? queryInterpretation;

  /// The estimated result count for this query.
  core.String? resultCountEstimate;

  /// The exact result count for this query.
  core.String? resultCountExact;

  /// Expanded result count information.
  ResultCounts? resultCounts;

  /// Results from a search query.
  core.List<SearchResult>? results;

  /// Suggested spelling for the query.
  core.List<SpellResult>? spellResults;

  /// Structured results for the user query.
  ///
  /// These results are not counted against the page_size.
  core.List<StructuredResult>? structuredResults;

  SearchResponse();

  SearchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('debugInfo')) {
      debugInfo = ResponseDebugInfo.fromJson(
          _json['debugInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errorInfo')) {
      errorInfo = ErrorInfo.fromJson(
          _json['errorInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('facetResults')) {
      facetResults = (_json['facetResults'] as core.List)
          .map<FacetResult>((value) => FacetResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('hasMoreResults')) {
      hasMoreResults = _json['hasMoreResults'] as core.bool;
    }
    if (_json.containsKey('queryInterpretation')) {
      queryInterpretation = QueryInterpretation.fromJson(
          _json['queryInterpretation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resultCountEstimate')) {
      resultCountEstimate = _json['resultCountEstimate'] as core.String;
    }
    if (_json.containsKey('resultCountExact')) {
      resultCountExact = _json['resultCountExact'] as core.String;
    }
    if (_json.containsKey('resultCounts')) {
      resultCounts = ResultCounts.fromJson(
          _json['resultCounts'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<SearchResult>((value) => SearchResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('spellResults')) {
      spellResults = (_json['spellResults'] as core.List)
          .map<SpellResult>((value) => SpellResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('structuredResults')) {
      structuredResults = (_json['structuredResults'] as core.List)
          .map<StructuredResult>((value) => StructuredResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugInfo != null) 'debugInfo': debugInfo!.toJson(),
        if (errorInfo != null) 'errorInfo': errorInfo!.toJson(),
        if (facetResults != null)
          'facetResults': facetResults!.map((value) => value.toJson()).toList(),
        if (hasMoreResults != null) 'hasMoreResults': hasMoreResults!,
        if (queryInterpretation != null)
          'queryInterpretation': queryInterpretation!.toJson(),
        if (resultCountEstimate != null)
          'resultCountEstimate': resultCountEstimate!,
        if (resultCountExact != null) 'resultCountExact': resultCountExact!,
        if (resultCounts != null) 'resultCounts': resultCounts!.toJson(),
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
        if (spellResults != null)
          'spellResults': spellResults!.map((value) => value.toJson()).toList(),
        if (structuredResults != null)
          'structuredResults':
              structuredResults!.map((value) => value.toJson()).toList(),
      };
}

/// Results containing indexed information for a document.
class SearchResult {
  /// If source is clustered, provide list of clustered results.
  ///
  /// There will only be one level of clustered results. If current source is
  /// not enabled for clustering, this field will be empty.
  core.List<SearchResult>? clusteredResults;

  /// Debugging information about this search result.
  ResultDebugInfo? debugInfo;

  /// Metadata of the search result.
  Metadata? metadata;

  /// The concatenation of all snippets (summaries) available for this result.
  Snippet? snippet;

  /// Title of the search result.
  core.String? title;

  /// The URL of the search result.
  ///
  /// The URL contains a Google redirect to the actual item. This URL is signed
  /// and shouldn't be changed.
  core.String? url;

  SearchResult();

  SearchResult.fromJson(core.Map _json) {
    if (_json.containsKey('clusteredResults')) {
      clusteredResults = (_json['clusteredResults'] as core.List)
          .map<SearchResult>((value) => SearchResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('debugInfo')) {
      debugInfo = ResultDebugInfo.fromJson(
          _json['debugInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = Metadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('snippet')) {
      snippet = Snippet.fromJson(
          _json['snippet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusteredResults != null)
          'clusteredResults':
              clusteredResults!.map((value) => value.toJson()).toList(),
        if (debugInfo != null) 'debugInfo': debugInfo!.toJson(),
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (snippet != null) 'snippet': snippet!.toJson(),
        if (title != null) 'title': title!,
        if (url != null) 'url': url!,
      };
}

/// Snippet of the search result, which summarizes the content of the resulting
/// page.
class Snippet {
  /// The matched ranges in the snippet.
  core.List<MatchRange>? matchRanges;

  /// The snippet of the document.
  ///
  /// The snippet of the document. May contain escaped HTML character that
  /// should be unescaped prior to rendering.
  core.String? snippet;

  Snippet();

  Snippet.fromJson(core.Map _json) {
    if (_json.containsKey('matchRanges')) {
      matchRanges = (_json['matchRanges'] as core.List)
          .map<MatchRange>((value) =>
              MatchRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('snippet')) {
      snippet = _json['snippet'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matchRanges != null)
          'matchRanges': matchRanges!.map((value) => value.toJson()).toList(),
        if (snippet != null) 'snippet': snippet!,
      };
}

class SortOptions {
  /// Name of the operator corresponding to the field to sort on.
  ///
  /// The corresponding property must be marked as sortable.
  core.String? operatorName;

  /// Ascending is the default sort order
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  core.String? sortOrder;

  SortOptions();

  SortOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
    if (_json.containsKey('sortOrder')) {
      sortOrder = _json['sortOrder'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorName != null) 'operatorName': operatorName!,
        if (sortOrder != null) 'sortOrder': sortOrder!,
      };
}

/// Defines sources for the suggest/search APIs.
class Source {
  /// Source name for content indexed by the Indexing API.
  core.String? name;

  /// Predefined content source for Google Apps.
  /// Possible string values are:
  /// - "NONE"
  /// - "QUERY_HISTORY" : Suggests queries issued by the user in the past. Only
  /// valid when used with the suggest API. Ignored when used in the query API.
  /// - "PERSON" : Suggests people in the organization. Only valid when used
  /// with the suggest API. Results in an error when used in the query API.
  /// - "GOOGLE_DRIVE"
  /// - "GOOGLE_GMAIL"
  /// - "GOOGLE_SITES"
  /// - "GOOGLE_GROUPS"
  /// - "GOOGLE_CALENDAR"
  /// - "GOOGLE_KEEP"
  core.String? predefinedSource;

  Source();

  Source.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('predefinedSource')) {
      predefinedSource = _json['predefinedSource'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (predefinedSource != null) 'predefinedSource': predefinedSource!,
      };
}

/// Configurations for a source while processing a Search or Suggest request.
class SourceConfig {
  /// The crowding configuration for the source.
  SourceCrowdingConfig? crowdingConfig;

  /// The scoring configuration for the source.
  SourceScoringConfig? scoringConfig;

  /// The source for which this configuration is to be used.
  Source? source;

  SourceConfig();

  SourceConfig.fromJson(core.Map _json) {
    if (_json.containsKey('crowdingConfig')) {
      crowdingConfig = SourceCrowdingConfig.fromJson(
          _json['crowdingConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scoringConfig')) {
      scoringConfig = SourceScoringConfig.fromJson(
          _json['scoringConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (crowdingConfig != null) 'crowdingConfig': crowdingConfig!.toJson(),
        if (scoringConfig != null) 'scoringConfig': scoringConfig!.toJson(),
        if (source != null) 'source': source!.toJson(),
      };
}

/// Set search results crowding limits.
///
/// Crowding is a situation in which multiple results from the same source or
/// host "crowd out" other results, diminishing the quality of search for users.
/// To foster better search quality and source diversity in search results, you
/// can set a condition to reduce repetitive results by source.
class SourceCrowdingConfig {
  /// Maximum number of results allowed from a source.
  ///
  /// No limits will be set on results if this value is less than or equal to 0.
  core.int? numResults;

  /// Maximum number of suggestions allowed from a source.
  ///
  /// No limits will be set on results if this value is less than or equal to 0.
  core.int? numSuggestions;

  SourceCrowdingConfig();

  SourceCrowdingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('numResults')) {
      numResults = _json['numResults'] as core.int;
    }
    if (_json.containsKey('numSuggestions')) {
      numSuggestions = _json['numSuggestions'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (numResults != null) 'numResults': numResults!,
        if (numSuggestions != null) 'numSuggestions': numSuggestions!,
      };
}

/// Per source result count information.
class SourceResultCount {
  /// Whether there are more search results for this source.
  core.bool? hasMoreResults;

  /// The estimated result count for this source.
  core.String? resultCountEstimate;

  /// The exact result count for this source.
  core.String? resultCountExact;

  /// The source the result count information is associated with.
  Source? source;

  SourceResultCount();

  SourceResultCount.fromJson(core.Map _json) {
    if (_json.containsKey('hasMoreResults')) {
      hasMoreResults = _json['hasMoreResults'] as core.bool;
    }
    if (_json.containsKey('resultCountEstimate')) {
      resultCountEstimate = _json['resultCountEstimate'] as core.String;
    }
    if (_json.containsKey('resultCountExact')) {
      resultCountExact = _json['resultCountExact'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hasMoreResults != null) 'hasMoreResults': hasMoreResults!,
        if (resultCountEstimate != null)
          'resultCountEstimate': resultCountEstimate!,
        if (resultCountExact != null) 'resultCountExact': resultCountExact!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// Set the scoring configuration.
///
/// This allows modifying the ranking of results for a source.
class SourceScoringConfig {
  /// Importance of the source.
  /// Possible string values are:
  /// - "DEFAULT"
  /// - "LOW"
  /// - "HIGH"
  core.String? sourceImportance;

  SourceScoringConfig();

  SourceScoringConfig.fromJson(core.Map _json) {
    if (_json.containsKey('sourceImportance')) {
      sourceImportance = _json['sourceImportance'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sourceImportance != null) 'sourceImportance': sourceImportance!,
      };
}

class SpellResult {
  /// The suggested spelling of the query.
  core.String? suggestedQuery;

  SpellResult();

  SpellResult.fromJson(core.Map _json) {
    if (_json.containsKey('suggestedQuery')) {
      suggestedQuery = _json['suggestedQuery'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestedQuery != null) 'suggestedQuery': suggestedQuery!,
      };
}

/// Start upload file request.
class StartUploadItemRequest {
  /// Name of connector making this call.
  ///
  /// Format: datasources/{source_id}/connectors/{ID}
  core.String? connectorName;

  /// Common debug options.
  DebugOptions? debugOptions;

  StartUploadItemRequest();

  StartUploadItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('connectorName')) {
      connectorName = _json['connectorName'] as core.String;
    }
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectorName != null) 'connectorName': connectorName!,
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
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

/// A structured data object consisting of named properties.
class StructuredDataObject {
  /// The properties for the object.
  ///
  /// The maximum number of elements is 1000.
  core.List<NamedProperty>? properties;

  StructuredDataObject();

  StructuredDataObject.fromJson(core.Map _json) {
    if (_json.containsKey('properties')) {
      properties = (_json['properties'] as core.List)
          .map<NamedProperty>((value) => NamedProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (properties != null)
          'properties': properties!.map((value) => value.toJson()).toList(),
      };
}

/// Structured results that are returned as part of search request.
class StructuredResult {
  /// Representation of a person
  Person? person;

  StructuredResult();

  StructuredResult.fromJson(core.Map _json) {
    if (_json.containsKey('person')) {
      person = Person.fromJson(
          _json['person'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (person != null) 'person': person!.toJson(),
      };
}

/// Request of suggest API.
class SuggestRequest {
  /// The sources to use for suggestions.
  ///
  /// If not specified, the data sources are taken from the current search
  /// application. NOTE: Suggestions are only supported for the following
  /// sources: * Third-party data sources * PredefinedSource.PERSON *
  /// PredefinedSource.GOOGLE_DRIVE
  core.List<DataSourceRestriction>? dataSourceRestrictions;

  /// Partial query for which autocomplete suggestions will be shown.
  ///
  /// For example, if the query is "sea", then the server might return "season",
  /// "search", "seagull" and so on.
  core.String? query;

  /// Request options, such as the search application and user timezone.
  RequestOptions? requestOptions;

  SuggestRequest();

  SuggestRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceRestrictions')) {
      dataSourceRestrictions = (_json['dataSourceRestrictions'] as core.List)
          .map<DataSourceRestriction>((value) => DataSourceRestriction.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('requestOptions')) {
      requestOptions = RequestOptions.fromJson(
          _json['requestOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceRestrictions != null)
          'dataSourceRestrictions':
              dataSourceRestrictions!.map((value) => value.toJson()).toList(),
        if (query != null) 'query': query!,
        if (requestOptions != null) 'requestOptions': requestOptions!.toJson(),
      };
}

/// Response of the suggest API.
class SuggestResponse {
  /// List of suggestions.
  core.List<SuggestResult>? suggestResults;

  SuggestResponse();

  SuggestResponse.fromJson(core.Map _json) {
    if (_json.containsKey('suggestResults')) {
      suggestResults = (_json['suggestResults'] as core.List)
          .map<SuggestResult>((value) => SuggestResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestResults != null)
          'suggestResults':
              suggestResults!.map((value) => value.toJson()).toList(),
      };
}

/// One suggestion result.
class SuggestResult {
  /// This is present when the suggestion indicates a person.
  ///
  /// It contains more information about the person - like their email ID, name
  /// etc.
  PeopleSuggestion? peopleSuggestion;

  /// This field will be present if the suggested query is a word/phrase
  /// completion.
  QuerySuggestion? querySuggestion;

  /// The source of the suggestion.
  Source? source;

  /// The suggested query that will be used for search, when the user clicks on
  /// the suggestion
  core.String? suggestedQuery;

  SuggestResult();

  SuggestResult.fromJson(core.Map _json) {
    if (_json.containsKey('peopleSuggestion')) {
      peopleSuggestion = PeopleSuggestion.fromJson(
          _json['peopleSuggestion'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('querySuggestion')) {
      querySuggestion = QuerySuggestion.fromJson(
          _json['querySuggestion'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestedQuery')) {
      suggestedQuery = _json['suggestedQuery'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (peopleSuggestion != null)
          'peopleSuggestion': peopleSuggestion!.toJson(),
        if (querySuggestion != null)
          'querySuggestion': querySuggestion!.toJson(),
        if (source != null) 'source': source!.toJson(),
        if (suggestedQuery != null) 'suggestedQuery': suggestedQuery!,
      };
}

/// Used to provide a search operator for text properties.
///
/// This is optional. Search operators let users restrict the query to specific
/// fields relevant to the type of item being searched.
class TextOperatorOptions {
  /// If true, the text value is tokenized as one atomic value in operator
  /// searches and facet matches.
  ///
  /// For example, if the operator name is "genre" and the value is
  /// "science-fiction" the query restrictions "genre:science" and
  /// "genre:fiction" doesn't match the item; "genre:science-fiction" does.
  /// Value matching is case-sensitive and does not remove special characters.
  /// If false, the text is tokenized. For example, if the value is
  /// "science-fiction" the queries "genre:science" and "genre:fiction" matches
  /// the item.
  core.bool? exactMatchWithOperator;

  /// Indicates the operator name required in the query in order to isolate the
  /// text property.
  ///
  /// For example, if operatorName is *subject* and the property's name is
  /// *subjectLine*, then queries like *subject:<value>* show results only where
  /// the value of the property named *subjectLine* matches *<value>*. By
  /// contrast, a search that uses the same *<value>* without an operator
  /// returns all items where *<value>* matches the value of any text properties
  /// or text within the content field for the item. The operator name can only
  /// contain lowercase letters (a-z). The maximum length is 32 characters.
  core.String? operatorName;

  TextOperatorOptions();

  TextOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('exactMatchWithOperator')) {
      exactMatchWithOperator = _json['exactMatchWithOperator'] as core.bool;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exactMatchWithOperator != null)
          'exactMatchWithOperator': exactMatchWithOperator!,
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for text properties.
class TextPropertyOptions {
  /// If set, describes how the property should be used as a search operator.
  TextOperatorOptions? operatorOptions;

  /// Indicates the search quality importance of the tokens within the field
  /// when used for retrieval.
  RetrievalImportance? retrievalImportance;

  TextPropertyOptions();

  TextPropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = TextOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('retrievalImportance')) {
      retrievalImportance = RetrievalImportance.fromJson(
          _json['retrievalImportance'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
        if (retrievalImportance != null)
          'retrievalImportance': retrievalImportance!.toJson(),
      };
}

/// List of text values.
class TextValues {
  /// The maximum allowable length for text values is 2048 characters.
  core.List<core.String>? values;

  TextValues();

  TextValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null) 'values': values!,
      };
}

/// Used to provide a search operator for timestamp properties.
///
/// This is optional. Search operators let users restrict the query to specific
/// fields relevant to the type of item being searched.
class TimestampOperatorOptions {
  /// Indicates the operator name required in the query in order to isolate the
  /// timestamp property using the greater-than operator.
  ///
  /// For example, if greaterThanOperatorName is *closedafter* and the
  /// property's name is *closeDate*, then queries like *closedafter:<value>*
  /// show results only where the value of the property named *closeDate* is
  /// later than *<value>*. The operator name can only contain lowercase letters
  /// (a-z). The maximum length is 32 characters.
  core.String? greaterThanOperatorName;

  /// Indicates the operator name required in the query in order to isolate the
  /// timestamp property using the less-than operator.
  ///
  /// For example, if lessThanOperatorName is *closedbefore* and the property's
  /// name is *closeDate*, then queries like *closedbefore:<value>* show results
  /// only where the value of the property named *closeDate* is earlier than
  /// *<value>*. The operator name can only contain lowercase letters (a-z). The
  /// maximum length is 32 characters.
  core.String? lessThanOperatorName;

  /// Indicates the operator name required in the query in order to isolate the
  /// timestamp property.
  ///
  /// For example, if operatorName is *closedon* and the property's name is
  /// *closeDate*, then queries like *closedon:<value>* show results only where
  /// the value of the property named *closeDate* matches *<value>*. By
  /// contrast, a search that uses the same *<value>* without an operator
  /// returns all items where *<value>* matches the value of any String
  /// properties or text within the content field for the item. The operator
  /// name can only contain lowercase letters (a-z). The maximum length is 32
  /// characters.
  core.String? operatorName;

  TimestampOperatorOptions();

  TimestampOperatorOptions.fromJson(core.Map _json) {
    if (_json.containsKey('greaterThanOperatorName')) {
      greaterThanOperatorName = _json['greaterThanOperatorName'] as core.String;
    }
    if (_json.containsKey('lessThanOperatorName')) {
      lessThanOperatorName = _json['lessThanOperatorName'] as core.String;
    }
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (greaterThanOperatorName != null)
          'greaterThanOperatorName': greaterThanOperatorName!,
        if (lessThanOperatorName != null)
          'lessThanOperatorName': lessThanOperatorName!,
        if (operatorName != null) 'operatorName': operatorName!,
      };
}

/// Options for timestamp properties.
class TimestampPropertyOptions {
  /// If set, describes how the timestamp should be used as a search operator.
  TimestampOperatorOptions? operatorOptions;

  TimestampPropertyOptions();

  TimestampPropertyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('operatorOptions')) {
      operatorOptions = TimestampOperatorOptions.fromJson(
          _json['operatorOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorOptions != null)
          'operatorOptions': operatorOptions!.toJson(),
      };
}

/// List of timestamp values.
class TimestampValues {
  core.List<core.String>? values;

  TimestampValues();

  TimestampValues.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null) 'values': values!,
      };
}

class UnmappedIdentity {
  /// The resource name for an external user.
  Principal? externalIdentity;

  /// The resolution status for the external identity.
  /// Possible string values are:
  /// - "CODE_UNSPECIFIED" : Input-only value. Used to list all unmapped
  /// identities regardless of status.
  /// - "NOT_FOUND" : The unmapped identity was not found in IDaaS, and needs to
  /// be provided by the user.
  /// - "IDENTITY_SOURCE_NOT_FOUND" : The identity source associated with the
  /// identity was either not found or deleted.
  /// - "IDENTITY_SOURCE_MISCONFIGURED" : IDaaS does not understand the identity
  /// source, probably because the schema was modified in a non compatible way.
  /// - "TOO_MANY_MAPPINGS_FOUND" : The number of users associated with the
  /// external identity is too large.
  /// - "INTERNAL_ERROR" : Internal error.
  core.String? resolutionStatusCode;

  UnmappedIdentity();

  UnmappedIdentity.fromJson(core.Map _json) {
    if (_json.containsKey('externalIdentity')) {
      externalIdentity = Principal.fromJson(
          _json['externalIdentity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resolutionStatusCode')) {
      resolutionStatusCode = _json['resolutionStatusCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (externalIdentity != null)
          'externalIdentity': externalIdentity!.toJson(),
        if (resolutionStatusCode != null)
          'resolutionStatusCode': resolutionStatusCode!,
      };
}

class UnreserveItemsRequest {
  /// Name of connector making this call.
  ///
  /// Format: datasources/{source_id}/connectors/{ID}
  core.String? connectorName;

  /// Common debug options.
  DebugOptions? debugOptions;

  /// Name of a queue to unreserve items from.
  core.String? queue;

  UnreserveItemsRequest();

  UnreserveItemsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('connectorName')) {
      connectorName = _json['connectorName'] as core.String;
    }
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queue')) {
      queue = _json['queue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectorName != null) 'connectorName': connectorName!,
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (queue != null) 'queue': queue!,
      };
}

class UpdateDataSourceRequest {
  /// Common debug options.
  DebugOptions? debugOptions;
  DataSource? source;

  UpdateDataSourceRequest();

  UpdateDataSourceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('source')) {
      source = DataSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (source != null) 'source': source!.toJson(),
      };
}

class UpdateSchemaRequest {
  /// Common debug options.
  DebugOptions? debugOptions;

  /// The new schema for the source.
  Schema? schema;

  /// If true, the schema will be checked for validity, but will not be
  /// registered with the data source, even if valid.
  core.bool? validateOnly;

  UpdateSchemaRequest();

  UpdateSchemaRequest.fromJson(core.Map _json) {
    if (_json.containsKey('debugOptions')) {
      debugOptions = DebugOptions.fromJson(
          _json['debugOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('schema')) {
      schema = Schema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('validateOnly')) {
      validateOnly = _json['validateOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugOptions != null) 'debugOptions': debugOptions!.toJson(),
        if (schema != null) 'schema': schema!.toJson(),
        if (validateOnly != null) 'validateOnly': validateOnly!,
      };
}

/// Represents an upload session reference.
///
/// This reference is created via upload method. Updating of item content may
/// refer to this uploaded content via contentDataRef.
class UploadItemRef {
  /// Name of the content reference.
  ///
  /// The maximum length is 2048 characters.
  core.String? name;

  UploadItemRef();

  UploadItemRef.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
      };
}

class VPCSettings {
  /// The resource name of the GCP Project to be used for VPC SC policy check.
  ///
  /// VPC security settings on this project will be honored for Cloud Search
  /// APIs after project_name has been updated through CustomerService. Format:
  /// projects/{project_id}
  core.String? project;

  VPCSettings();

  VPCSettings.fromJson(core.Map _json) {
    if (_json.containsKey('project')) {
      project = _json['project'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (project != null) 'project': project!,
      };
}

/// Definition of a single value with generic type.
class Value {
  core.bool? booleanValue;
  Date? dateValue;
  core.double? doubleValue;
  core.String? integerValue;
  core.String? stringValue;
  core.String? timestampValue;

  Value();

  Value.fromJson(core.Map _json) {
    if (_json.containsKey('booleanValue')) {
      booleanValue = _json['booleanValue'] as core.bool;
    }
    if (_json.containsKey('dateValue')) {
      dateValue = Date.fromJson(
          _json['dateValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('doubleValue')) {
      doubleValue = (_json['doubleValue'] as core.num).toDouble();
    }
    if (_json.containsKey('integerValue')) {
      integerValue = _json['integerValue'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
    if (_json.containsKey('timestampValue')) {
      timestampValue = _json['timestampValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (booleanValue != null) 'booleanValue': booleanValue!,
        if (dateValue != null) 'dateValue': dateValue!.toJson(),
        if (doubleValue != null) 'doubleValue': doubleValue!,
        if (integerValue != null) 'integerValue': integerValue!,
        if (stringValue != null) 'stringValue': stringValue!,
        if (timestampValue != null) 'timestampValue': timestampValue!,
      };
}

class ValueFilter {
  /// The `operator_name` applied to the query, such as *price_greater_than*.
  ///
  /// The filter can work against both types of filters defined in the schema
  /// for your data source: 1. `operator_name`, where the query filters results
  /// by the property that matches the value. 2. `greater_than_operator_name` or
  /// `less_than_operator_name` in your schema. The query filters the results
  /// for the property values that are greater than or less than the supplied
  /// value in the query.
  core.String? operatorName;

  /// The value to be compared with.
  Value? value;

  ValueFilter();

  ValueFilter.fromJson(core.Map _json) {
    if (_json.containsKey('operatorName')) {
      operatorName = _json['operatorName'] as core.String;
    }
    if (_json.containsKey('value')) {
      value =
          Value.fromJson(_json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operatorName != null) 'operatorName': operatorName!,
        if (value != null) 'value': value!.toJson(),
      };
}

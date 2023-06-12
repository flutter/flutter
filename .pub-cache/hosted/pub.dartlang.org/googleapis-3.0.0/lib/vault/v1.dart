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

/// G Suite Vault API - v1
///
/// Retention and eDiscovery for Google Workspace. To work with Vault resources,
/// the account must have the
/// [required Vault privileges] (https://support.google.com/vault/answer/2799699)
/// and access to the matter. To access a matter, the account must have created
/// the matter, have the matter shared with them, or have the **View All
/// Matters** privilege. For example, to download an export, an account needs
/// the **Manage Exports** privilege and the matter shared with them.
///
/// For more information, see <https://developers.google.com/vault>
///
/// Create an instance of [VaultApi] to access these resources:
///
/// - [MattersResource]
///   - [MattersExportsResource]
///   - [MattersHoldsResource]
///     - [MattersHoldsAccountsResource]
///   - [MattersSavedQueriesResource]
/// - [OperationsResource]
library vault.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Retention and eDiscovery for Google Workspace.
///
/// To work with Vault resources, the account must have the
/// [required Vault privileges] (https://support.google.com/vault/answer/2799699)
/// and access to the matter. To access a matter, the account must have created
/// the matter, have the matter shared with them, or have the **View All
/// Matters** privilege. For example, to download an export, an account needs
/// the **Manage Exports** privilege and the matter shared with them.
class VaultApi {
  /// Manage your eDiscovery data
  static const ediscoveryScope = 'https://www.googleapis.com/auth/ediscovery';

  /// View your eDiscovery data
  static const ediscoveryReadonlyScope =
      'https://www.googleapis.com/auth/ediscovery.readonly';

  final commons.ApiRequester _requester;

  MattersResource get matters => MattersResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);

  VaultApi(http.Client client,
      {core.String rootUrl = 'https://vault.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class MattersResource {
  final commons.ApiRequester _requester;

  MattersExportsResource get exports => MattersExportsResource(_requester);
  MattersHoldsResource get holds => MattersHoldsResource(_requester);
  MattersSavedQueriesResource get savedQueries =>
      MattersSavedQueriesResource(_requester);

  MattersResource(commons.ApiRequester client) : _requester = client;

  /// Adds an account as a matter collaborator.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MatterPermission].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MatterPermission> addPermissions(
    AddMatterPermissionsRequest request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/matters/' + commons.escapeVariable('$matterId') + ':addPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return MatterPermission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Closes the specified matter.
  ///
  /// Returns matter with updated state.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CloseMatterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CloseMatterResponse> close(
    CloseMatterRequest request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' + commons.escapeVariable('$matterId') + ':close';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CloseMatterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Counts the artifacts within the context of a matter and returns a detailed
  /// breakdown of metrics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
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
  async.Future<Operation> count(
    CountArtifactsRequest request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' + commons.escapeVariable('$matterId') + ':count';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new matter with the given name and description.
  ///
  /// The initial state is open, and the owner is the method caller. Returns the
  /// created matter with default view.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Matter].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Matter> create(
    Matter request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/matters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Matter.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified matter.
  ///
  /// Returns matter with updated state.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Matter].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Matter> delete(
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' + commons.escapeVariable('$matterId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Matter.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the specified matter.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [view] - Specifies which parts of the Matter to return in the response.
  /// Possible string values are:
  /// - "VIEW_UNSPECIFIED" : There is no specified view.
  /// - "BASIC" : Response includes the matter_id, name, description, and state.
  /// Default choice.
  /// - "FULL" : Full representation of matter is returned. Everything above and
  /// including MatterPermissions list.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Matter].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Matter> get(
    core.String matterId, {
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' + commons.escapeVariable('$matterId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Matter.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists matters the user has access to.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - The number of matters to return in the response. Default and
  /// maximum are 100.
  ///
  /// [pageToken] - The pagination token as returned in the response.
  ///
  /// [state] - If set, list only matters with that specific state. The default
  /// is listing matters of all states.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The matter has no specified state.
  /// - "OPEN" : This matter is open.
  /// - "CLOSED" : This matter is closed.
  /// - "DELETED" : This matter is deleted.
  ///
  /// [view] - Specifies which parts of the matter to return in response.
  /// Possible string values are:
  /// - "VIEW_UNSPECIFIED" : There is no specified view.
  /// - "BASIC" : Response includes the matter_id, name, description, and state.
  /// Default choice.
  /// - "FULL" : Full representation of matter is returned. Everything above and
  /// including MatterPermissions list.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListMattersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListMattersResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? state,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (state != null) 'state': [state],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/matters';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListMattersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Removes an account as a matter collaborator.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
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
  async.Future<Empty> removePermissions(
    RemoveMatterPermissionsRequest request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        ':removePermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Reopens the specified matter.
  ///
  /// Returns matter with updated state.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReopenMatterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReopenMatterResponse> reopen(
    ReopenMatterRequest request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/matters/' + commons.escapeVariable('$matterId') + ':reopen';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReopenMatterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Undeletes the specified matter.
  ///
  /// Returns matter with updated state.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Matter].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Matter> undelete(
    UndeleteMatterRequest request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/matters/' + commons.escapeVariable('$matterId') + ':undelete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Matter.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified matter.
  ///
  /// This updates only the name and description of the matter, identified by
  /// matter ID. Changes to any other fields are ignored. Returns the default
  /// view of the matter.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Matter].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Matter> update(
    Matter request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' + commons.escapeVariable('$matterId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Matter.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class MattersExportsResource {
  final commons.ApiRequester _requester;

  MattersExportsResource(commons.ApiRequester client) : _requester = client;

  /// Creates an Export.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Export].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Export> create(
    Export request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/matters/' + commons.escapeVariable('$matterId') + '/exports';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Export.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an Export.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [exportId] - The export ID.
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
    core.String matterId,
    core.String exportId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/exports/' +
        commons.escapeVariable('$exportId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets an Export.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [exportId] - The export ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Export].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Export> get(
    core.String matterId,
    core.String exportId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/exports/' +
        commons.escapeVariable('$exportId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Export.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists Exports.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [pageSize] - The number of exports to return in the response.
  ///
  /// [pageToken] - The pagination token as returned in the response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListExportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListExportsResponse> list(
    core.String matterId, {
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
        'v1/matters/' + commons.escapeVariable('$matterId') + '/exports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListExportsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MattersHoldsResource {
  final commons.ApiRequester _requester;

  MattersHoldsAccountsResource get accounts =>
      MattersHoldsAccountsResource(_requester);

  MattersHoldsResource(commons.ApiRequester client) : _requester = client;

  /// Adds HeldAccounts to a hold.
  ///
  /// Returns a list of accounts that have been successfully added. Accounts can
  /// only be added to an existing account-based hold.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The hold ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AddHeldAccountsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AddHeldAccountsResponse> addHeldAccounts(
    AddHeldAccountsRequest request,
    core.String matterId,
    core.String holdId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId') +
        ':addHeldAccounts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AddHeldAccountsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a hold in the given matter.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Hold].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Hold> create(
    Hold request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' + commons.escapeVariable('$matterId') + '/holds';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Hold.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Removes a hold by ID.
  ///
  /// This will release any HeldAccounts on this Hold.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The hold ID.
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
    core.String matterId,
    core.String holdId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a hold by ID.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The hold ID.
  ///
  /// [view] - Specifies which parts of the Hold to return.
  /// Possible string values are:
  /// - "HOLD_VIEW_UNSPECIFIED" : There is no specified view. Defaults to
  /// FULL_HOLD.
  /// - "BASIC_HOLD" : Response includes the id, name, update time, corpus, and
  /// query.
  /// - "FULL_HOLD" : Full representation of a Hold. Response includes all
  /// fields of 'BASIC' and the entities the Hold applies to, such as accounts,
  /// or OU.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Hold].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Hold> get(
    core.String matterId,
    core.String holdId, {
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Hold.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists holds within a matter.
  ///
  /// An empty page token in ListHoldsResponse denotes no more holds to list.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [pageSize] - The number of holds to return in the response, between 0 and
  /// 100 inclusive. Leaving this empty, or as 0, is the same as page_size =
  /// 100.
  ///
  /// [pageToken] - The pagination token as returned in the response. An empty
  /// token means start from the beginning.
  ///
  /// [view] - Specifies which parts of the Hold to return.
  /// Possible string values are:
  /// - "HOLD_VIEW_UNSPECIFIED" : There is no specified view. Defaults to
  /// FULL_HOLD.
  /// - "BASIC_HOLD" : Response includes the id, name, update time, corpus, and
  /// query.
  /// - "FULL_HOLD" : Full representation of a Hold. Response includes all
  /// fields of 'BASIC' and the entities the Hold applies to, such as accounts,
  /// or OU.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListHoldsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListHoldsResponse> list(
    core.String matterId, {
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

    final _url = 'v1/matters/' + commons.escapeVariable('$matterId') + '/holds';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListHoldsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Removes HeldAccounts from a hold.
  ///
  /// Returns a list of statuses in the same order as the request. If this
  /// request leaves the hold with no held accounts, the hold will not apply to
  /// any accounts.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The hold ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemoveHeldAccountsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemoveHeldAccountsResponse> removeHeldAccounts(
    RemoveHeldAccountsRequest request,
    core.String matterId,
    core.String holdId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId') +
        ':removeHeldAccounts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RemoveHeldAccountsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the OU and/or query parameters of a hold.
  ///
  /// You cannot add accounts to a hold that covers an OU, nor can you add OUs
  /// to a hold that covers individual accounts. Accounts listed in the hold
  /// will be ignored.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The ID of the hold.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Hold].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Hold> update(
    Hold request,
    core.String matterId,
    core.String holdId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Hold.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class MattersHoldsAccountsResource {
  final commons.ApiRequester _requester;

  MattersHoldsAccountsResource(commons.ApiRequester client)
      : _requester = client;

  /// Adds a HeldAccount to a hold.
  ///
  /// Accounts can only be added to a hold that has no held_org_unit set.
  /// Attempting to add an account to an OU-based hold will result in an error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The hold ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [HeldAccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<HeldAccount> create(
    HeldAccount request,
    core.String matterId,
    core.String holdId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId') +
        '/accounts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return HeldAccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Removes a HeldAccount from a hold.
  ///
  /// If this request leaves the hold with no held accounts, the hold will not
  /// apply to any accounts.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The hold ID.
  ///
  /// [accountId] - The ID of the account to remove from the hold.
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
    core.String matterId,
    core.String holdId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId') +
        '/accounts/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists HeldAccounts for a hold.
  ///
  /// This will only list individually specified held accounts. If the hold is
  /// on an OU, then use Admin SDK to enumerate its members.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID.
  ///
  /// [holdId] - The hold ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListHeldAccountsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListHeldAccountsResponse> list(
    core.String matterId,
    core.String holdId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/holds/' +
        commons.escapeVariable('$holdId') +
        '/accounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListHeldAccountsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MattersSavedQueriesResource {
  final commons.ApiRequester _requester;

  MattersSavedQueriesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a saved query.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID of the parent matter for which the saved query
  /// is to be created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SavedQuery].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SavedQuery> create(
    SavedQuery request,
    core.String matterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/matters/' + commons.escapeVariable('$matterId') + '/savedQueries';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SavedQuery.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a saved query by Id.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID of the parent matter for which the saved query
  /// is to be deleted.
  ///
  /// [savedQueryId] - ID of the saved query to be deleted.
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
    core.String matterId,
    core.String savedQueryId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/savedQueries/' +
        commons.escapeVariable('$savedQueryId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a saved query by Id.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID of the parent matter for which the saved query
  /// is to be retrieved.
  ///
  /// [savedQueryId] - ID of the saved query to be retrieved.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SavedQuery].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SavedQuery> get(
    core.String matterId,
    core.String savedQueryId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/matters/' +
        commons.escapeVariable('$matterId') +
        '/savedQueries/' +
        commons.escapeVariable('$savedQueryId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SavedQuery.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists saved queries within a matter.
  ///
  /// An empty page token in ListSavedQueriesResponse denotes no more saved
  /// queries to list.
  ///
  /// Request parameters:
  ///
  /// [matterId] - The matter ID of the parent matter for which the saved
  /// queries are to be retrieved.
  ///
  /// [pageSize] - The maximum number of saved queries to return.
  ///
  /// [pageToken] - The pagination token as returned in the previous response.
  /// An empty token means start from the beginning.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSavedQueriesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSavedQueriesResponse> list(
    core.String matterId, {
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
        'v1/matters/' + commons.escapeVariable('$matterId') + '/savedQueries';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSavedQueriesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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

/// Count number for each account.
class AccountCount {
  /// Account owner.
  UserInfo? account;

  /// The number of artifacts found for this account.
  core.String? count;

  AccountCount();

  AccountCount.fromJson(core.Map _json) {
    if (_json.containsKey('account')) {
      account = UserInfo.fromJson(
          _json['account'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (account != null) 'account': account!.toJson(),
        if (count != null) 'count': count!,
      };
}

/// An error that occurred when querying a specific account
class AccountCountError {
  /// Account owner.
  UserInfo? account;

  /// Account query error.
  /// Possible string values are:
  /// - "ERROR_TYPE_UNSPECIFIED" : Default.
  /// - "WILDCARD_TOO_BROAD" : Permanent - prefix terms expanded to too many
  /// query terms.
  /// - "TOO_MANY_TERMS" : Permanent - query contains too many terms.
  /// - "LOCATION_UNAVAILABLE" : Transient - data in transit between storage
  /// replicas, temporarily unavailable.
  /// - "UNKNOWN" : Unrecognized error.
  /// - "DEADLINE_EXCEEDED" : Deadline exceeded when querying the account.
  core.String? errorType;

  AccountCountError();

  AccountCountError.fromJson(core.Map _json) {
    if (_json.containsKey('account')) {
      account = UserInfo.fromJson(
          _json['account'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errorType')) {
      errorType = _json['errorType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (account != null) 'account': account!.toJson(),
        if (errorType != null) 'errorType': errorType!,
      };
}

/// Accounts to search
class AccountInfo {
  /// A set of accounts to search.
  core.List<core.String>? emails;

  AccountInfo();

  AccountInfo.fromJson(core.Map _json) {
    if (_json.containsKey('emails')) {
      emails = (_json['emails'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (emails != null) 'emails': emails!,
      };
}

/// A status detailing the status of each account creation, and the HeldAccount,
/// if successful.
class AddHeldAccountResult {
  /// If present, this account was successfully created.
  HeldAccount? account;

  /// This represents the success status.
  ///
  /// If failed, check message.
  Status? status;

  AddHeldAccountResult();

  AddHeldAccountResult.fromJson(core.Map _json) {
    if (_json.containsKey('account')) {
      account = HeldAccount.fromJson(
          _json['account'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (account != null) 'account': account!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// Add a list of accounts to a hold.
class AddHeldAccountsRequest {
  /// Account IDs to identify which accounts to add.
  ///
  /// Only account_ids or only emails should be specified, but not both.
  core.List<core.String>? accountIds;

  /// Emails to identify which accounts to add.
  ///
  /// Only emails or only account_ids should be specified, but not both.
  core.List<core.String>? emails;

  AddHeldAccountsRequest();

  AddHeldAccountsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('accountIds')) {
      accountIds = (_json['accountIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('emails')) {
      emails = (_json['emails'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountIds != null) 'accountIds': accountIds!,
        if (emails != null) 'emails': emails!,
      };
}

/// Response for batch create held accounts.
class AddHeldAccountsResponse {
  /// The list of responses, in the same order as the batch request.
  core.List<AddHeldAccountResult>? responses;

  AddHeldAccountsResponse();

  AddHeldAccountsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('responses')) {
      responses = (_json['responses'] as core.List)
          .map<AddHeldAccountResult>((value) => AddHeldAccountResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (responses != null)
          'responses': responses!.map((value) => value.toJson()).toList(),
      };
}

/// Add an account with the permission specified.
///
/// The role cannot be owner. If an account already has a role in the matter, it
/// will be overwritten.
class AddMatterPermissionsRequest {
  /// Only relevant if send_emails is true.
  ///
  /// True to CC requestor in the email message. False to not CC requestor.
  core.bool? ccMe;

  /// The MatterPermission to add.
  MatterPermission? matterPermission;

  /// True to send notification email to the added account.
  ///
  /// False to not send notification email.
  core.bool? sendEmails;

  AddMatterPermissionsRequest();

  AddMatterPermissionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('ccMe')) {
      ccMe = _json['ccMe'] as core.bool;
    }
    if (_json.containsKey('matterPermission')) {
      matterPermission = MatterPermission.fromJson(
          _json['matterPermission'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sendEmails')) {
      sendEmails = _json['sendEmails'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ccMe != null) 'ccMe': ccMe!,
        if (matterPermission != null)
          'matterPermission': matterPermission!.toJson(),
        if (sendEmails != null) 'sendEmails': sendEmails!,
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

/// Close a matter by ID.
class CloseMatterRequest {
  CloseMatterRequest();

  CloseMatterRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response to a CloseMatterRequest.
class CloseMatterResponse {
  /// The updated matter, with state CLOSED.
  Matter? matter;

  CloseMatterResponse();

  CloseMatterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('matter')) {
      matter = Matter.fromJson(
          _json['matter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matter != null) 'matter': matter!.toJson(),
      };
}

/// An export file on cloud storage
class CloudStorageFile {
  /// The cloud storage bucket name of this export file.
  ///
  /// Can be used in cloud storage JSON/XML API, but not to list the bucket
  /// contents. Instead, you can get individual export files by object name.
  core.String? bucketName;

  /// The md5 hash of the file.
  core.String? md5Hash;

  /// The cloud storage object name of this export file.
  ///
  /// Can be used in cloud storage JSON/XML API.
  core.String? objectName;

  /// The size of the export file.
  core.String? size;

  CloudStorageFile();

  CloudStorageFile.fromJson(core.Map _json) {
    if (_json.containsKey('bucketName')) {
      bucketName = _json['bucketName'] as core.String;
    }
    if (_json.containsKey('md5Hash')) {
      md5Hash = _json['md5Hash'] as core.String;
    }
    if (_json.containsKey('objectName')) {
      objectName = _json['objectName'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucketName != null) 'bucketName': bucketName!,
        if (md5Hash != null) 'md5Hash': md5Hash!,
        if (objectName != null) 'objectName': objectName!,
        if (size != null) 'size': size!,
      };
}

/// Export sink for cloud storage files.
class CloudStorageSink {
  /// The exported files on cloud storage.
  ///
  /// Output only.
  core.List<CloudStorageFile>? files;

  CloudStorageSink();

  CloudStorageSink.fromJson(core.Map _json) {
    if (_json.containsKey('files')) {
      files = (_json['files'] as core.List)
          .map<CloudStorageFile>((value) => CloudStorageFile.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (files != null)
          'files': files!.map((value) => value.toJson()).toList(),
      };
}

/// Corpus specific queries.
class CorpusQuery {
  /// Details pertaining to Drive holds.
  ///
  /// If set, corpus must be Drive.
  HeldDriveQuery? driveQuery;

  /// Details pertaining to Groups holds.
  ///
  /// If set, corpus must be Groups.
  HeldGroupsQuery? groupsQuery;

  /// Details pertaining to Hangouts Chat holds.
  ///
  /// If set, corpus must be Hangouts Chat.
  HeldHangoutsChatQuery? hangoutsChatQuery;

  /// Details pertaining to mail holds.
  ///
  /// If set, corpus must be mail.
  HeldMailQuery? mailQuery;

  /// Details pertaining to Voice holds.
  ///
  /// If set, corpus must be Voice.
  HeldVoiceQuery? voiceQuery;

  CorpusQuery();

  CorpusQuery.fromJson(core.Map _json) {
    if (_json.containsKey('driveQuery')) {
      driveQuery = HeldDriveQuery.fromJson(
          _json['driveQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupsQuery')) {
      groupsQuery = HeldGroupsQuery.fromJson(
          _json['groupsQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hangoutsChatQuery')) {
      hangoutsChatQuery = HeldHangoutsChatQuery.fromJson(
          _json['hangoutsChatQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mailQuery')) {
      mailQuery = HeldMailQuery.fromJson(
          _json['mailQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('voiceQuery')) {
      voiceQuery = HeldVoiceQuery.fromJson(
          _json['voiceQuery'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (driveQuery != null) 'driveQuery': driveQuery!.toJson(),
        if (groupsQuery != null) 'groupsQuery': groupsQuery!.toJson(),
        if (hangoutsChatQuery != null)
          'hangoutsChatQuery': hangoutsChatQuery!.toJson(),
        if (mailQuery != null) 'mailQuery': mailQuery!.toJson(),
        if (voiceQuery != null) 'voiceQuery': voiceQuery!.toJson(),
      };
}

/// Long running operation metadata for CountArtifacts.
class CountArtifactsMetadata {
  /// End time of count operation.
  ///
  /// Available when operation is done.
  core.String? endTime;

  /// The matter ID of the associated matter.
  core.String? matterId;

  /// The search query from the request.
  Query? query;

  /// Creation time of count operation.
  core.String? startTime;

  CountArtifactsMetadata();

  CountArtifactsMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('matterId')) {
      matterId = _json['matterId'] as core.String;
    }
    if (_json.containsKey('query')) {
      query =
          Query.fromJson(_json['query'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (matterId != null) 'matterId': matterId!,
        if (query != null) 'query': query!.toJson(),
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Count artifacts request.
class CountArtifactsRequest {
  /// The search query.
  Query? query;

  /// Specifies the granularity of the count result returned in response.
  /// Possible string values are:
  /// - "COUNT_RESULT_VIEW_UNSPECIFIED" : Default. It works the same as
  /// TOTAL_COUNT.
  /// - "TOTAL_COUNT" : Response includes: total count, queried accounts count,
  /// matching accounts count, non-queryable accounts, queried account errors.
  /// - "ALL" : Response includes additional breakdown of account count.
  core.String? view;

  CountArtifactsRequest();

  CountArtifactsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('query')) {
      query =
          Query.fromJson(_json['query'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('view')) {
      view = _json['view'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (query != null) 'query': query!.toJson(),
        if (view != null) 'view': view!,
      };
}

/// Definition of the response for method CountArtifacts.
class CountArtifactsResponse {
  /// Count metrics of Groups.
  GroupsCountResult? groupsCountResult;

  /// Count metrics of Mail.
  MailCountResult? mailCountResult;

  /// Total count of artifacts.
  ///
  /// For mail and groups, artifacts refers to messages.
  core.String? totalCount;

  CountArtifactsResponse();

  CountArtifactsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('groupsCountResult')) {
      groupsCountResult = GroupsCountResult.fromJson(
          _json['groupsCountResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mailCountResult')) {
      mailCountResult = MailCountResult.fromJson(
          _json['mailCountResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('totalCount')) {
      totalCount = _json['totalCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupsCountResult != null)
          'groupsCountResult': groupsCountResult!.toJson(),
        if (mailCountResult != null)
          'mailCountResult': mailCountResult!.toJson(),
        if (totalCount != null) 'totalCount': totalCount!,
      };
}

/// The options for Drive export.
class DriveExportOptions {
  /// Set to true to include access level information for users with indirect
  /// access to files.
  core.bool? includeAccessInfo;

  DriveExportOptions();

  DriveExportOptions.fromJson(core.Map _json) {
    if (_json.containsKey('includeAccessInfo')) {
      includeAccessInfo = _json['includeAccessInfo'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeAccessInfo != null) 'includeAccessInfo': includeAccessInfo!,
      };
}

/// Drive search advanced options
class DriveOptions {
  /// Set to true to include shared drive.
  core.bool? includeSharedDrives;

  /// Set to true to include Team Drive.
  core.bool? includeTeamDrives;

  /// Search the versions of the Drive file as of the reference date.
  ///
  /// These timestamps are in GMT and rounded down to the given date.
  core.String? versionDate;

  DriveOptions();

  DriveOptions.fromJson(core.Map _json) {
    if (_json.containsKey('includeSharedDrives')) {
      includeSharedDrives = _json['includeSharedDrives'] as core.bool;
    }
    if (_json.containsKey('includeTeamDrives')) {
      includeTeamDrives = _json['includeTeamDrives'] as core.bool;
    }
    if (_json.containsKey('versionDate')) {
      versionDate = _json['versionDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeSharedDrives != null)
          'includeSharedDrives': includeSharedDrives!,
        if (includeTeamDrives != null) 'includeTeamDrives': includeTeamDrives!,
        if (versionDate != null) 'versionDate': versionDate!,
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

/// An export To work with Vault resources, the account must have the
/// [required Vault privileges](https://support.google.com/vault/answer/2799699)
/// and access to the matter.
///
/// To access a matter, the account must have created the matter, have the
/// matter shared with them, or have the **View All Matters** privilege.
class Export {
  /// Export sink for cloud storage files.
  ///
  /// Output only.
  CloudStorageSink? cloudStorageSink;

  /// The time when the export was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Advanced options of the export.
  ExportOptions? exportOptions;

  /// The generated export ID.
  ///
  /// Output only.
  core.String? id;

  /// The matter ID.
  ///
  /// Output only.
  core.String? matterId;

  /// The export name.
  core.String? name;

  /// The search query being exported.
  Query? query;

  /// The requester of the export.
  ///
  /// Output only.
  UserInfo? requester;

  /// Export statistics.
  ///
  /// Output only.
  ExportStats? stats;

  /// The export status.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "EXPORT_STATUS_UNSPECIFIED" : The status is unspecified.
  /// - "COMPLETED" : The export completed.
  /// - "FAILED" : The export failed.
  /// - "IN_PROGRESS" : The export is still being executed.
  core.String? status;

  Export();

  Export.fromJson(core.Map _json) {
    if (_json.containsKey('cloudStorageSink')) {
      cloudStorageSink = CloudStorageSink.fromJson(
          _json['cloudStorageSink'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('exportOptions')) {
      exportOptions = ExportOptions.fromJson(
          _json['exportOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('matterId')) {
      matterId = _json['matterId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('query')) {
      query =
          Query.fromJson(_json['query'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requester')) {
      requester = UserInfo.fromJson(
          _json['requester'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stats')) {
      stats = ExportStats.fromJson(
          _json['stats'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudStorageSink != null)
          'cloudStorageSink': cloudStorageSink!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (exportOptions != null) 'exportOptions': exportOptions!.toJson(),
        if (id != null) 'id': id!,
        if (matterId != null) 'matterId': matterId!,
        if (name != null) 'name': name!,
        if (query != null) 'query': query!.toJson(),
        if (requester != null) 'requester': requester!.toJson(),
        if (stats != null) 'stats': stats!.toJson(),
        if (status != null) 'status': status!,
      };
}

/// Export advanced options
class ExportOptions {
  /// Option available for Drive export.
  DriveExportOptions? driveOptions;

  /// Option available for groups export.
  GroupsExportOptions? groupsOptions;

  /// Option available for hangouts chat export.
  HangoutsChatExportOptions? hangoutsChatOptions;

  /// Option available for mail export.
  MailExportOptions? mailOptions;

  /// The requested export location.
  /// Possible string values are:
  /// - "EXPORT_REGION_UNSPECIFIED" : The region is unspecified. Will be treated
  /// the same as ANY.
  /// - "ANY" : Any region.
  /// - "US" : US region.
  /// - "EUROPE" : Europe region.
  core.String? region;

  /// Option available for voice export.
  VoiceExportOptions? voiceOptions;

  ExportOptions();

  ExportOptions.fromJson(core.Map _json) {
    if (_json.containsKey('driveOptions')) {
      driveOptions = DriveExportOptions.fromJson(
          _json['driveOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupsOptions')) {
      groupsOptions = GroupsExportOptions.fromJson(
          _json['groupsOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hangoutsChatOptions')) {
      hangoutsChatOptions = HangoutsChatExportOptions.fromJson(
          _json['hangoutsChatOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mailOptions')) {
      mailOptions = MailExportOptions.fromJson(
          _json['mailOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('voiceOptions')) {
      voiceOptions = VoiceExportOptions.fromJson(
          _json['voiceOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (driveOptions != null) 'driveOptions': driveOptions!.toJson(),
        if (groupsOptions != null) 'groupsOptions': groupsOptions!.toJson(),
        if (hangoutsChatOptions != null)
          'hangoutsChatOptions': hangoutsChatOptions!.toJson(),
        if (mailOptions != null) 'mailOptions': mailOptions!.toJson(),
        if (region != null) 'region': region!,
        if (voiceOptions != null) 'voiceOptions': voiceOptions!.toJson(),
      };
}

/// Stats of an export.
class ExportStats {
  /// The number of documents already processed by the export.
  core.String? exportedArtifactCount;

  /// The size of export in bytes.
  core.String? sizeInBytes;

  /// The number of documents to be exported.
  core.String? totalArtifactCount;

  ExportStats();

  ExportStats.fromJson(core.Map _json) {
    if (_json.containsKey('exportedArtifactCount')) {
      exportedArtifactCount = _json['exportedArtifactCount'] as core.String;
    }
    if (_json.containsKey('sizeInBytes')) {
      sizeInBytes = _json['sizeInBytes'] as core.String;
    }
    if (_json.containsKey('totalArtifactCount')) {
      totalArtifactCount = _json['totalArtifactCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exportedArtifactCount != null)
          'exportedArtifactCount': exportedArtifactCount!,
        if (sizeInBytes != null) 'sizeInBytes': sizeInBytes!,
        if (totalArtifactCount != null)
          'totalArtifactCount': totalArtifactCount!,
      };
}

/// Groups specific count metrics.
class GroupsCountResult {
  /// Error occurred when querying these accounts.
  core.List<AccountCountError>? accountCountErrors;

  /// Subtotal count per matching account that have more than zero messages.
  core.List<AccountCount>? accountCounts;

  /// Total number of accounts that can be queried and have more than zero
  /// messages.
  core.String? matchingAccountsCount;

  /// When data scope is HELD_DATA in the request Query, these accounts in the
  /// request are not queried because they are not on hold.
  ///
  /// For other data scope, this field is not set.
  core.List<core.String>? nonQueryableAccounts;

  /// Total number of accounts involved in this count operation.
  core.String? queriedAccountsCount;

  GroupsCountResult();

  GroupsCountResult.fromJson(core.Map _json) {
    if (_json.containsKey('accountCountErrors')) {
      accountCountErrors = (_json['accountCountErrors'] as core.List)
          .map<AccountCountError>((value) => AccountCountError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('accountCounts')) {
      accountCounts = (_json['accountCounts'] as core.List)
          .map<AccountCount>((value) => AccountCount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('matchingAccountsCount')) {
      matchingAccountsCount = _json['matchingAccountsCount'] as core.String;
    }
    if (_json.containsKey('nonQueryableAccounts')) {
      nonQueryableAccounts = (_json['nonQueryableAccounts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('queriedAccountsCount')) {
      queriedAccountsCount = _json['queriedAccountsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountCountErrors != null)
          'accountCountErrors':
              accountCountErrors!.map((value) => value.toJson()).toList(),
        if (accountCounts != null)
          'accountCounts':
              accountCounts!.map((value) => value.toJson()).toList(),
        if (matchingAccountsCount != null)
          'matchingAccountsCount': matchingAccountsCount!,
        if (nonQueryableAccounts != null)
          'nonQueryableAccounts': nonQueryableAccounts!,
        if (queriedAccountsCount != null)
          'queriedAccountsCount': queriedAccountsCount!,
      };
}

/// The options for groups export.
class GroupsExportOptions {
  /// The export format for groups export.
  /// Possible string values are:
  /// - "EXPORT_FORMAT_UNSPECIFIED" : No export format specified.
  /// - "MBOX" : MBOX as export format.
  /// - "PST" : PST as export format
  core.String? exportFormat;

  GroupsExportOptions();

  GroupsExportOptions.fromJson(core.Map _json) {
    if (_json.containsKey('exportFormat')) {
      exportFormat = _json['exportFormat'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exportFormat != null) 'exportFormat': exportFormat!,
      };
}

/// The options for hangouts chat export.
class HangoutsChatExportOptions {
  /// The export format for hangouts chat export.
  /// Possible string values are:
  /// - "EXPORT_FORMAT_UNSPECIFIED" : No export format specified.
  /// - "MBOX" : MBOX as export format.
  /// - "PST" : PST as export format
  core.String? exportFormat;

  HangoutsChatExportOptions();

  HangoutsChatExportOptions.fromJson(core.Map _json) {
    if (_json.containsKey('exportFormat')) {
      exportFormat = _json['exportFormat'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exportFormat != null) 'exportFormat': exportFormat!,
      };
}

/// Accounts to search
class HangoutsChatInfo {
  /// A set of rooms to search.
  core.List<core.String>? roomId;

  HangoutsChatInfo();

  HangoutsChatInfo.fromJson(core.Map _json) {
    if (_json.containsKey('roomId')) {
      roomId = (_json['roomId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (roomId != null) 'roomId': roomId!,
      };
}

/// Hangouts chat search advanced options
class HangoutsChatOptions {
  /// Set to true to include rooms.
  core.bool? includeRooms;

  HangoutsChatOptions();

  HangoutsChatOptions.fromJson(core.Map _json) {
    if (_json.containsKey('includeRooms')) {
      includeRooms = _json['includeRooms'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeRooms != null) 'includeRooms': includeRooms!,
      };
}

/// An account being held in a particular hold.
///
/// This structure is immutable. This can be either a single user or a google
/// group, depending on the corpus. To work with Vault resources, the account
/// must have the
/// [required Vault privileges](https://support.google.com/vault/answer/2799699)
/// and access to the matter. To access a matter, the account must have created
/// the matter, have the matter shared with them, or have the **View All
/// Matters** privilege.
class HeldAccount {
  /// The account's ID as provided by the Admin SDK.
  core.String? accountId;

  /// The primary email address of the account.
  ///
  /// If used as an input, this takes precedence over account ID.
  core.String? email;

  /// The first name of the account holder.
  ///
  /// Output only.
  core.String? firstName;

  /// When the account was put on hold.
  ///
  /// Output only.
  core.String? holdTime;

  /// The last name of the account holder.
  ///
  /// Output only.
  core.String? lastName;

  HeldAccount();

  HeldAccount.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('firstName')) {
      firstName = _json['firstName'] as core.String;
    }
    if (_json.containsKey('holdTime')) {
      holdTime = _json['holdTime'] as core.String;
    }
    if (_json.containsKey('lastName')) {
      lastName = _json['lastName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (email != null) 'email': email!,
        if (firstName != null) 'firstName': firstName!,
        if (holdTime != null) 'holdTime': holdTime!,
        if (lastName != null) 'lastName': lastName!,
      };
}

/// Query options for Drive holds.
class HeldDriveQuery {
  /// If true, include files in shared drives in the hold.
  core.bool? includeSharedDriveFiles;

  /// If true, include files in Team Drives in the hold.
  core.bool? includeTeamDriveFiles;

  HeldDriveQuery();

  HeldDriveQuery.fromJson(core.Map _json) {
    if (_json.containsKey('includeSharedDriveFiles')) {
      includeSharedDriveFiles = _json['includeSharedDriveFiles'] as core.bool;
    }
    if (_json.containsKey('includeTeamDriveFiles')) {
      includeTeamDriveFiles = _json['includeTeamDriveFiles'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeSharedDriveFiles != null)
          'includeSharedDriveFiles': includeSharedDriveFiles!,
        if (includeTeamDriveFiles != null)
          'includeTeamDriveFiles': includeTeamDriveFiles!,
      };
}

/// Query options for group holds.
class HeldGroupsQuery {
  /// The end time range for the search query.
  ///
  /// These timestamps are in GMT and rounded down to the start of the given
  /// date.
  core.String? endTime;

  /// The start time range for the search query.
  ///
  /// These timestamps are in GMT and rounded down to the start of the given
  /// date.
  core.String? startTime;

  /// The search terms for the hold.
  core.String? terms;

  HeldGroupsQuery();

  HeldGroupsQuery.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('terms')) {
      terms = _json['terms'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
        if (terms != null) 'terms': terms!,
      };
}

/// Query options for hangouts chat holds.
class HeldHangoutsChatQuery {
  /// If true, include rooms the user has participated in.
  core.bool? includeRooms;

  HeldHangoutsChatQuery();

  HeldHangoutsChatQuery.fromJson(core.Map _json) {
    if (_json.containsKey('includeRooms')) {
      includeRooms = _json['includeRooms'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeRooms != null) 'includeRooms': includeRooms!,
      };
}

/// Query options for mail holds.
class HeldMailQuery {
  /// The end time range for the search query.
  ///
  /// These timestamps are in GMT and rounded down to the start of the given
  /// date.
  core.String? endTime;

  /// The start time range for the search query.
  ///
  /// These timestamps are in GMT and rounded down to the start of the given
  /// date.
  core.String? startTime;

  /// The search terms for the hold.
  core.String? terms;

  HeldMailQuery();

  HeldMailQuery.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('terms')) {
      terms = _json['terms'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
        if (terms != null) 'terms': terms!,
      };
}

/// A organizational unit being held in a particular hold.
///
/// This structure is immutable.
class HeldOrgUnit {
  /// When the org unit was put on hold.
  ///
  /// This property is immutable.
  core.String? holdTime;

  /// The org unit's immutable ID as provided by the Admin SDK.
  core.String? orgUnitId;

  HeldOrgUnit();

  HeldOrgUnit.fromJson(core.Map _json) {
    if (_json.containsKey('holdTime')) {
      holdTime = _json['holdTime'] as core.String;
    }
    if (_json.containsKey('orgUnitId')) {
      orgUnitId = _json['orgUnitId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (holdTime != null) 'holdTime': holdTime!,
        if (orgUnitId != null) 'orgUnitId': orgUnitId!,
      };
}

/// Query options for Voice holds.
class HeldVoiceQuery {
  /// Data covered by this rule.
  ///
  /// Should be non-empty. Order does not matter and duplicates will be ignored.
  core.List<core.String>? coveredData;

  HeldVoiceQuery();

  HeldVoiceQuery.fromJson(core.Map _json) {
    if (_json.containsKey('coveredData')) {
      coveredData = (_json['coveredData'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coveredData != null) 'coveredData': coveredData!,
      };
}

/// Represents a hold within Vault.
///
/// A hold restricts purging of artifacts based on the combination of the query
/// and accounts restrictions. A hold can be configured to either apply to an
/// explicitly configured set of accounts, or can be applied to all members of
/// an organizational unit. To work with Vault resources, the account must have
/// the
/// [required Vault privileges](https://support.google.com/vault/answer/2799699)
/// and access to the matter. To access a matter, the account must have created
/// the matter, have the matter shared with them, or have the **View All
/// Matters** privilege.
class Hold {
  /// If set, the hold applies to the enumerated accounts and org_unit must be
  /// empty.
  core.List<HeldAccount>? accounts;

  /// The corpus to be searched.
  /// Possible string values are:
  /// - "CORPUS_TYPE_UNSPECIFIED" : No corpus specified.
  /// - "DRIVE" : Drive.
  /// - "MAIL" : Mail.
  /// - "GROUPS" : Groups.
  /// - "HANGOUTS_CHAT" : Hangouts Chat.
  /// - "VOICE" : Google Voice.
  core.String? corpus;

  /// The unique immutable ID of the hold.
  ///
  /// Assigned during creation.
  core.String? holdId;

  /// The name of the hold.
  core.String? name;

  /// If set, the hold applies to all members of the organizational unit and
  /// accounts must be empty.
  ///
  /// This property is mutable. For groups holds, set the accounts field.
  HeldOrgUnit? orgUnit;

  /// The corpus-specific query.
  ///
  /// If set, the corpusQuery must match corpus type.
  CorpusQuery? query;

  /// The last time this hold was modified.
  core.String? updateTime;

  Hold();

  Hold.fromJson(core.Map _json) {
    if (_json.containsKey('accounts')) {
      accounts = (_json['accounts'] as core.List)
          .map<HeldAccount>((value) => HeldAccount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('corpus')) {
      corpus = _json['corpus'] as core.String;
    }
    if (_json.containsKey('holdId')) {
      holdId = _json['holdId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('orgUnit')) {
      orgUnit = HeldOrgUnit.fromJson(
          _json['orgUnit'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('query')) {
      query = CorpusQuery.fromJson(
          _json['query'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accounts != null)
          'accounts': accounts!.map((value) => value.toJson()).toList(),
        if (corpus != null) 'corpus': corpus!,
        if (holdId != null) 'holdId': holdId!,
        if (name != null) 'name': name!,
        if (orgUnit != null) 'orgUnit': orgUnit!.toJson(),
        if (query != null) 'query': query!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// The holds for a matter.
class ListExportsResponse {
  /// The list of exports.
  core.List<Export>? exports;

  /// Page token to retrieve the next page of results in the list.
  core.String? nextPageToken;

  ListExportsResponse();

  ListExportsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('exports')) {
      exports = (_json['exports'] as core.List)
          .map<Export>((value) =>
              Export.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exports != null)
          'exports': exports!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Returns a list of held accounts for a hold.
class ListHeldAccountsResponse {
  /// The held accounts on a hold.
  core.List<HeldAccount>? accounts;

  ListHeldAccountsResponse();

  ListHeldAccountsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accounts')) {
      accounts = (_json['accounts'] as core.List)
          .map<HeldAccount>((value) => HeldAccount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accounts != null)
          'accounts': accounts!.map((value) => value.toJson()).toList(),
      };
}

/// The holds for a matter.
class ListHoldsResponse {
  /// The list of holds.
  core.List<Hold>? holds;

  /// Page token to retrieve the next page of results in the list.
  ///
  /// If this is empty, then there are no more holds to list.
  core.String? nextPageToken;

  ListHoldsResponse();

  ListHoldsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('holds')) {
      holds = (_json['holds'] as core.List)
          .map<Hold>((value) =>
              Hold.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (holds != null)
          'holds': holds!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Provides the list of matters.
class ListMattersResponse {
  /// List of matters.
  core.List<Matter>? matters;

  /// Page token to retrieve the next page of results in the list.
  core.String? nextPageToken;

  ListMattersResponse();

  ListMattersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('matters')) {
      matters = (_json['matters'] as core.List)
          .map<Matter>((value) =>
              Matter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matters != null)
          'matters': matters!.map((value) => value.toJson()).toList(),
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

/// Definition of the response for method ListSaveQuery.
class ListSavedQueriesResponse {
  /// Page token to retrieve the next page of results in the list.
  ///
  /// If this is empty, then there are no more saved queries to list.
  core.String? nextPageToken;

  /// List of output saved queries.
  core.List<SavedQuery>? savedQueries;

  ListSavedQueriesResponse();

  ListSavedQueriesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('savedQueries')) {
      savedQueries = (_json['savedQueries'] as core.List)
          .map<SavedQuery>((value) =>
              SavedQuery.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (savedQueries != null)
          'savedQueries': savedQueries!.map((value) => value.toJson()).toList(),
      };
}

/// Mail specific count metrics.
class MailCountResult {
  /// Error occurred when querying these accounts.
  core.List<AccountCountError>? accountCountErrors;

  /// Subtotal count per matching account that have more than zero messages.
  core.List<AccountCount>? accountCounts;

  /// Total number of accounts that can be queried and have more than zero
  /// messages.
  core.String? matchingAccountsCount;

  /// When data scope is HELD_DATA in the request Query, these accounts in the
  /// request are not queried because they are not on hold.
  ///
  /// For other data scope, this field is not set.
  core.List<core.String>? nonQueryableAccounts;

  /// Total number of accounts involved in this count operation.
  core.String? queriedAccountsCount;

  MailCountResult();

  MailCountResult.fromJson(core.Map _json) {
    if (_json.containsKey('accountCountErrors')) {
      accountCountErrors = (_json['accountCountErrors'] as core.List)
          .map<AccountCountError>((value) => AccountCountError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('accountCounts')) {
      accountCounts = (_json['accountCounts'] as core.List)
          .map<AccountCount>((value) => AccountCount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('matchingAccountsCount')) {
      matchingAccountsCount = _json['matchingAccountsCount'] as core.String;
    }
    if (_json.containsKey('nonQueryableAccounts')) {
      nonQueryableAccounts = (_json['nonQueryableAccounts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('queriedAccountsCount')) {
      queriedAccountsCount = _json['queriedAccountsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountCountErrors != null)
          'accountCountErrors':
              accountCountErrors!.map((value) => value.toJson()).toList(),
        if (accountCounts != null)
          'accountCounts':
              accountCounts!.map((value) => value.toJson()).toList(),
        if (matchingAccountsCount != null)
          'matchingAccountsCount': matchingAccountsCount!,
        if (nonQueryableAccounts != null)
          'nonQueryableAccounts': nonQueryableAccounts!,
        if (queriedAccountsCount != null)
          'queriedAccountsCount': queriedAccountsCount!,
      };
}

/// The options for mail export.
class MailExportOptions {
  /// The export file format.
  /// Possible string values are:
  /// - "EXPORT_FORMAT_UNSPECIFIED" : No export format specified.
  /// - "MBOX" : MBOX as export format.
  /// - "PST" : PST as export format
  core.String? exportFormat;

  /// Set to true to export confidential mode content.
  core.bool? showConfidentialModeContent;

  MailExportOptions();

  MailExportOptions.fromJson(core.Map _json) {
    if (_json.containsKey('exportFormat')) {
      exportFormat = _json['exportFormat'] as core.String;
    }
    if (_json.containsKey('showConfidentialModeContent')) {
      showConfidentialModeContent =
          _json['showConfidentialModeContent'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exportFormat != null) 'exportFormat': exportFormat!,
        if (showConfidentialModeContent != null)
          'showConfidentialModeContent': showConfidentialModeContent!,
      };
}

/// Mail search advanced options
class MailOptions {
  /// Set to true to exclude drafts.
  core.bool? excludeDrafts;

  MailOptions();

  MailOptions.fromJson(core.Map _json) {
    if (_json.containsKey('excludeDrafts')) {
      excludeDrafts = _json['excludeDrafts'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (excludeDrafts != null) 'excludeDrafts': excludeDrafts!,
      };
}

/// Represents a matter.
///
/// To work with Vault resources, the account must have the
/// [required Vault privileges](https://support.google.com/vault/answer/2799699)
/// and access to the matter. To access a matter, the account must have created
/// the matter, have the matter shared with them, or have the **View All
/// Matters** privilege.
class Matter {
  /// The description of the matter.
  core.String? description;

  /// The matter ID which is generated by the server.
  ///
  /// Should be blank when creating a new matter.
  core.String? matterId;

  /// List of users and access to the matter.
  ///
  /// Currently there is no programmer defined limit on the number of
  /// permissions a matter can have.
  core.List<MatterPermission>? matterPermissions;

  /// The name of the matter.
  core.String? name;

  /// The state of the matter.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The matter has no specified state.
  /// - "OPEN" : This matter is open.
  /// - "CLOSED" : This matter is closed.
  /// - "DELETED" : This matter is deleted.
  core.String? state;

  Matter();

  Matter.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('matterId')) {
      matterId = _json['matterId'] as core.String;
    }
    if (_json.containsKey('matterPermissions')) {
      matterPermissions = (_json['matterPermissions'] as core.List)
          .map<MatterPermission>((value) => MatterPermission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (matterId != null) 'matterId': matterId!,
        if (matterPermissions != null)
          'matterPermissions':
              matterPermissions!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (state != null) 'state': state!,
      };
}

/// Currently each matter only has one owner, and all others are collaborators.
///
/// When an account is purged, its corresponding MatterPermission resources
/// cease to exist.
class MatterPermission {
  /// The account ID, as provided by Admin SDK.
  core.String? accountId;

  /// The user's role in this matter.
  /// Possible string values are:
  /// - "ROLE_UNSPECIFIED" : No role assigned.
  /// - "COLLABORATOR" : A collaborator to the matter.
  /// - "OWNER" : The owner of the matter.
  core.String? role;

  MatterPermission();

  MatterPermission.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (role != null) 'role': role!,
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

/// Org Unit to search
class OrgUnitInfo {
  /// Org unit to search, as provided by the Admin SDK Directory API.
  core.String? orgUnitId;

  OrgUnitInfo();

  OrgUnitInfo.fromJson(core.Map _json) {
    if (_json.containsKey('orgUnitId')) {
      orgUnitId = _json['orgUnitId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (orgUnitId != null) 'orgUnitId': orgUnitId!,
      };
}

/// A query definition relevant for search & export.
class Query {
  /// When 'ACCOUNT' is chosen as search method, account_info needs to be
  /// specified.
  AccountInfo? accountInfo;

  /// The corpus to search.
  /// Possible string values are:
  /// - "CORPUS_TYPE_UNSPECIFIED" : No corpus specified.
  /// - "DRIVE" : Drive.
  /// - "MAIL" : Mail.
  /// - "GROUPS" : Groups.
  /// - "HANGOUTS_CHAT" : Hangouts Chat.
  /// - "VOICE" : Google Voice.
  core.String? corpus;

  /// The data source to search from.
  /// Possible string values are:
  /// - "DATA_SCOPE_UNSPECIFIED" : No data scope specified.
  /// - "ALL_DATA" : All available data.
  /// - "HELD_DATA" : Data on hold.
  /// - "UNPROCESSED_DATA" : Data not processed.
  core.String? dataScope;

  /// For Drive search, specify more options in this field.
  DriveOptions? driveOptions;

  /// The end time range for the search query.
  ///
  /// These timestamps are in GMT and rounded down to the start of the given
  /// date.
  core.String? endTime;

  /// When 'ROOM' is chosen as search method, hangout_chats_info needs to be
  /// specified.
  ///
  /// (read-only)
  HangoutsChatInfo? hangoutsChatInfo;

  /// For hangouts chat search, specify more options in this field.
  ///
  /// (read-only)
  HangoutsChatOptions? hangoutsChatOptions;

  /// For mail search, specify more options in this field.
  MailOptions? mailOptions;

  /// The search method to use.
  ///
  /// This field is similar to the search_method field but is introduced to
  /// support shared drives. It supports all search method types. In case the
  /// search_method is TEAM_DRIVE the response of this field will be
  /// SHARED_DRIVE only.
  /// Possible string values are:
  /// - "SEARCH_METHOD_UNSPECIFIED" : A search method must be specified. If a
  /// request does not specify a search method, it will be rejected.
  /// - "ACCOUNT" : Will search all accounts provided in account_info.
  /// - "ORG_UNIT" : Will search all accounts in the OU specified in
  /// org_unit_info.
  /// - "TEAM_DRIVE" : Will search for all accounts in the Team Drive specified
  /// in team_drive_info.
  /// - "ENTIRE_ORG" : Will search for all accounts in the organization. No need
  /// to set account_info or org_unit_info. Not all CORPUS_TYPE support this
  /// scope. Supported by MAIL.
  /// - "ROOM" : Will search in the Room specified in hangout_chats_info.
  /// (read-only)
  /// - "SHARED_DRIVE" : Will search for all accounts in the shared drive
  /// specified in shared_drive_info.
  core.String? method;

  /// When 'ORG_UNIT' is chosen as as search method, org_unit_info needs to be
  /// specified.
  OrgUnitInfo? orgUnitInfo;

  /// The search method to use.
  /// Possible string values are:
  /// - "SEARCH_METHOD_UNSPECIFIED" : A search method must be specified. If a
  /// request does not specify a search method, it will be rejected.
  /// - "ACCOUNT" : Will search all accounts provided in account_info.
  /// - "ORG_UNIT" : Will search all accounts in the OU specified in
  /// org_unit_info.
  /// - "TEAM_DRIVE" : Will search for all accounts in the Team Drive specified
  /// in team_drive_info.
  /// - "ENTIRE_ORG" : Will search for all accounts in the organization. No need
  /// to set account_info or org_unit_info. Not all CORPUS_TYPE support this
  /// scope. Supported by MAIL.
  /// - "ROOM" : Will search in the Room specified in hangout_chats_info.
  /// (read-only)
  /// - "SHARED_DRIVE" : Will search for all accounts in the shared drive
  /// specified in shared_drive_info.
  core.String? searchMethod;

  /// When 'SHARED_DRIVE' is chosen as search method, shared_drive_info needs to
  /// be specified.
  SharedDriveInfo? sharedDriveInfo;

  /// The start time range for the search query.
  ///
  /// These timestamps are in GMT and rounded down to the start of the given
  /// date.
  core.String? startTime;

  /// When 'TEAM_DRIVE' is chosen as search method, team_drive_info needs to be
  /// specified.
  TeamDriveInfo? teamDriveInfo;

  /// The corpus-specific search operators used to generate search results.
  core.String? terms;

  /// The time zone name.
  ///
  /// It should be an IANA TZ name, such as "America/Los_Angeles". For more
  /// information, see Time Zone.
  core.String? timeZone;

  /// For voice search, specify more options in this field.
  VoiceOptions? voiceOptions;

  Query();

  Query.fromJson(core.Map _json) {
    if (_json.containsKey('accountInfo')) {
      accountInfo = AccountInfo.fromJson(
          _json['accountInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('corpus')) {
      corpus = _json['corpus'] as core.String;
    }
    if (_json.containsKey('dataScope')) {
      dataScope = _json['dataScope'] as core.String;
    }
    if (_json.containsKey('driveOptions')) {
      driveOptions = DriveOptions.fromJson(
          _json['driveOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('hangoutsChatInfo')) {
      hangoutsChatInfo = HangoutsChatInfo.fromJson(
          _json['hangoutsChatInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hangoutsChatOptions')) {
      hangoutsChatOptions = HangoutsChatOptions.fromJson(
          _json['hangoutsChatOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mailOptions')) {
      mailOptions = MailOptions.fromJson(
          _json['mailOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('orgUnitInfo')) {
      orgUnitInfo = OrgUnitInfo.fromJson(
          _json['orgUnitInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('searchMethod')) {
      searchMethod = _json['searchMethod'] as core.String;
    }
    if (_json.containsKey('sharedDriveInfo')) {
      sharedDriveInfo = SharedDriveInfo.fromJson(
          _json['sharedDriveInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('teamDriveInfo')) {
      teamDriveInfo = TeamDriveInfo.fromJson(
          _json['teamDriveInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('terms')) {
      terms = _json['terms'] as core.String;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
    if (_json.containsKey('voiceOptions')) {
      voiceOptions = VoiceOptions.fromJson(
          _json['voiceOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountInfo != null) 'accountInfo': accountInfo!.toJson(),
        if (corpus != null) 'corpus': corpus!,
        if (dataScope != null) 'dataScope': dataScope!,
        if (driveOptions != null) 'driveOptions': driveOptions!.toJson(),
        if (endTime != null) 'endTime': endTime!,
        if (hangoutsChatInfo != null)
          'hangoutsChatInfo': hangoutsChatInfo!.toJson(),
        if (hangoutsChatOptions != null)
          'hangoutsChatOptions': hangoutsChatOptions!.toJson(),
        if (mailOptions != null) 'mailOptions': mailOptions!.toJson(),
        if (method != null) 'method': method!,
        if (orgUnitInfo != null) 'orgUnitInfo': orgUnitInfo!.toJson(),
        if (searchMethod != null) 'searchMethod': searchMethod!,
        if (sharedDriveInfo != null)
          'sharedDriveInfo': sharedDriveInfo!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (teamDriveInfo != null) 'teamDriveInfo': teamDriveInfo!.toJson(),
        if (terms != null) 'terms': terms!,
        if (timeZone != null) 'timeZone': timeZone!,
        if (voiceOptions != null) 'voiceOptions': voiceOptions!.toJson(),
      };
}

/// Remove a list of accounts from a hold.
class RemoveHeldAccountsRequest {
  /// Account IDs to identify HeldAccounts to remove.
  core.List<core.String>? accountIds;

  RemoveHeldAccountsRequest();

  RemoveHeldAccountsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('accountIds')) {
      accountIds = (_json['accountIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountIds != null) 'accountIds': accountIds!,
      };
}

/// Response for batch delete held accounts.
class RemoveHeldAccountsResponse {
  /// A list of statuses for deleted accounts.
  ///
  /// Results have the same order as the request.
  core.List<Status>? statuses;

  RemoveHeldAccountsResponse();

  RemoveHeldAccountsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('statuses')) {
      statuses = (_json['statuses'] as core.List)
          .map<Status>((value) =>
              Status.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (statuses != null)
          'statuses': statuses!.map((value) => value.toJson()).toList(),
      };
}

/// Remove an account as a matter collaborator.
class RemoveMatterPermissionsRequest {
  /// The account ID.
  core.String? accountId;

  RemoveMatterPermissionsRequest();

  RemoveMatterPermissionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
      };
}

/// Reopen a matter by ID.
class ReopenMatterRequest {
  ReopenMatterRequest();

  ReopenMatterRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response to a ReopenMatterRequest.
class ReopenMatterResponse {
  /// The updated matter, with state OPEN.
  Matter? matter;

  ReopenMatterResponse();

  ReopenMatterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('matter')) {
      matter = Matter.fromJson(
          _json['matter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matter != null) 'matter': matter!.toJson(),
      };
}

/// Definition of the saved query.
///
/// To work with Vault resources, the account must have the
/// [required Vault privileges](https://support.google.com/vault/answer/2799699)
/// and access to the matter. To access a matter, the account must have created
/// the matter, have the matter shared with them, or have the **View All
/// Matters** privilege.
class SavedQuery {
  /// The server generated timestamp at which saved query was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Name of the saved query.
  core.String? displayName;

  /// The matter ID of the associated matter.
  ///
  /// The server does not look at this field during create and always uses
  /// matter id in the URL.
  ///
  /// Output only.
  core.String? matterId;

  /// The underlying Query object which contains all the information of the
  /// saved query.
  Query? query;

  /// A unique identifier for the saved query.
  core.String? savedQueryId;

  SavedQuery();

  SavedQuery.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('matterId')) {
      matterId = _json['matterId'] as core.String;
    }
    if (_json.containsKey('query')) {
      query =
          Query.fromJson(_json['query'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('savedQueryId')) {
      savedQueryId = _json['savedQueryId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (matterId != null) 'matterId': matterId!,
        if (query != null) 'query': query!.toJson(),
        if (savedQueryId != null) 'savedQueryId': savedQueryId!,
      };
}

/// Shared drives to search
class SharedDriveInfo {
  /// List of Shared drive IDs, as provided by Drive API.
  core.List<core.String>? sharedDriveIds;

  SharedDriveInfo();

  SharedDriveInfo.fromJson(core.Map _json) {
    if (_json.containsKey('sharedDriveIds')) {
      sharedDriveIds = (_json['sharedDriveIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sharedDriveIds != null) 'sharedDriveIds': sharedDriveIds!,
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

/// Team Drives to search
class TeamDriveInfo {
  /// List of Team Drive IDs, as provided by Drive API.
  core.List<core.String>? teamDriveIds;

  TeamDriveInfo();

  TeamDriveInfo.fromJson(core.Map _json) {
    if (_json.containsKey('teamDriveIds')) {
      teamDriveIds = (_json['teamDriveIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (teamDriveIds != null) 'teamDriveIds': teamDriveIds!,
      };
}

/// Undelete a matter by ID.
class UndeleteMatterRequest {
  UndeleteMatterRequest();

  UndeleteMatterRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// User's information.
class UserInfo {
  /// The displayed name of the user.
  core.String? displayName;

  /// The email address of the user.
  core.String? email;

  UserInfo();

  UserInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
      };
}

/// The options for voice export.
class VoiceExportOptions {
  /// The export format for voice export.
  /// Possible string values are:
  /// - "EXPORT_FORMAT_UNSPECIFIED" : No export format specified.
  /// - "MBOX" : MBOX as export format.
  /// - "PST" : PST as export format
  core.String? exportFormat;

  VoiceExportOptions();

  VoiceExportOptions.fromJson(core.Map _json) {
    if (_json.containsKey('exportFormat')) {
      exportFormat = _json['exportFormat'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exportFormat != null) 'exportFormat': exportFormat!,
      };
}

/// Voice search options
class VoiceOptions {
  /// Datatypes to search
  core.List<core.String>? coveredData;

  VoiceOptions();

  VoiceOptions.fromJson(core.Map _json) {
    if (_json.containsKey('coveredData')) {
      coveredData = (_json['coveredData'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coveredData != null) 'coveredData': coveredData!,
      };
}
